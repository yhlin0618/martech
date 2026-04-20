---
description: "Call OpenAI Codex CLI to verify issue completion. Always uses gpt-5.4. Args: #issue [effort] e.g. '#288' or '#300 high'"
---

# /codex-review - Issue Completion Verification

## Purpose

Use OpenAI Codex CLI to verify that a GitHub issue's requirements are **fully implemented** in uncommitted changes. Primary focus: catch missed items, incomplete renames, unaddressed requirements.

**This is issue-focused**: the issue number drives the review context.

## Arguments

Format: `/codex-review #issue [effort] [custom instructions]`

- `#NNN` — **recommended** (fetches issue requirements for targeted review)
- Omit `#NNN` for a general code review of uncommitted changes

### Model

**Fixed: `gpt-5.4`** (~1M context window). No model selection needed.

### Speed modifier: `fast`

Append `fast` to enable `service_tier = "fast"` (lower latency, same model):

```
/codex-review #288 fast           # gpt-5.4 with fast tier
/codex-review #288 fast high      # fast tier, high effort
```

Implementation: add `-c 'service_tier="fast"'` to the codex command.

### Effort levels

| Level | When to use |
|-------|-------------|
| `low` | Quick sanity check, small diffs (<50 lines) |
| `medium` | Normal review, moderate diffs (50-200 lines) |
| `high` | Thorough review, large diffs (200-500 lines) |
| `xhigh` | Deep review, catch everything **(default)** |

### Effort auto-adjustment

When effort is not explicitly specified, auto-select based on diff complexity:

```
git diff --stat | tail -1 → extract insertions + deletions

< 50 lines changed   → medium
50-200 lines changed  → high
> 200 lines changed   → xhigh (default)
No diff stats         → xhigh
```

**User-specified effort always overrides auto-adjustment.**

## Execution Steps

### Step 1: Parse Arguments

Extract issue number, effort, fast modifier, and any custom instructions from the arguments.

**Parsing rules:**
- `#NNN` → issue number
- `fast` → enable `service_tier = "fast"`
- `low` / `medium` / `high` / `xhigh` → effort level
- Remaining text → custom instructions

**Defaults:**
- Model: `gpt-5.4` (fixed, not configurable)
- Effort: auto-adjusted by diff size (see above), fallback `xhigh`
- Fast: off (unless explicitly specified)

### Step 2: Fetch Issue Context

If `#NNN` is provided (recommended):

```bash
gh issue view NNN --repo kiki830621/ai_martech_global_scripts --json title,body,labels
```

Extract:
- Issue title and requirements from body
- Company label (e.g., `company:D_RACING`) → determines working directory
- Module label (e.g., `module:BrandEdge`) → adds context

### Step 3: Determine Working Directory

Find the correct company project directory. The codex review must run from a **git-tracked** company directory, not the l4_enterprise root.

```bash
# Priority order:
# 1. If issue has company label → cd to that company dir
# 2. If currently in a company dir (D_RACING, QEF_DESIGN, MAMBA, etc.) → use it
# 3. If shared/ has changes → use shared/ (it has its own .git)
# 4. Ask user which company project to review
```

Valid git-tracked directories:
- `D_RACING/`
- `QEF_DESIGN/`
- `MAMBA/`
- `WISER/`
- `kitchenMAMA/`
- `shared/` (global_scripts has its own git)

### Step 4: Check for Uncommitted Changes

```bash
cd <project_dir>
git status --short
git diff --stat
```

If no changes found, inform user and stop.

### Step 5: Build Review Prompt

Construct a review prompt with issue as the primary focus:

1. **Issue requirements** (primary — when `#NNN` provided):
   ```
   You are reviewing code changes for GitHub Issue #NNN: <title>

   Issue requirements:
   <body content>

   YOUR PRIMARY TASK:
   1. Go through EACH requirement in the issue
   2. For each requirement, determine if it is addressed in the changes
   3. List requirements that are FULLY addressed ✅
   4. List requirements that are PARTIALLY addressed ⚠️
   5. List requirements that are NOT addressed at all ❌
   6. Flag any changes that seem unrelated to the issue
   ```

2. **Code quality checks** (secondary):
   ```
   Also check for:
   - Incomplete changes (e.g. renamed in one place but not another)
   - Broken references or imports
   - Consistency issues
   ```

3. **Reply format**:
   ```
   Reply in 繁體中文.
   Structure your reply as:
   ## Issue #NNN 完成度檢查
   ### ✅ 已完成
   ### ⚠️ 部分完成
   ### ❌ 未完成
   ### 🔍 程式碼品質
   ```

4. **Custom instructions** (if provided by user)

### Step 6: Run Codex Review

**CRITICAL: `codex review` has a CLI limitation — `--uncommitted` and `[PROMPT]` are mutually exclusive.**

Use different modes depending on whether issue context is needed:

#### Mode A: Issue-focused review (with `#NNN`) — diff-inline approach

Since `--uncommitted` cannot be used with `[PROMPT]`, capture the diff and embed it in the prompt:

```bash
cd <project_dir>

# Create temp file with issue-focused prompt + diff
PROMPT_FILE=$(mktemp /tmp/codex_review_XXXXX)

{
  echo "You are reviewing code changes for GitHub Issue #NNN: <title>"
  echo ""
  echo "Issue requirements:"
  echo "<body content>"
  echo ""
  echo "YOUR PRIMARY TASK:"
  echo "1. Go through EACH requirement in the issue"
  echo "2. For each requirement, determine if it is addressed in the changes below"
  echo "3. List requirements that are FULLY addressed ✅"
  echo "4. List requirements that are PARTIALLY addressed ⚠️"
  echo "5. List requirements that are NOT addressed at all ❌"
  echo "6. Flag any changes that seem unrelated to the issue"
  echo ""
  echo "Also check for:"
  echo "- Incomplete changes (e.g. renamed in one place but not another)"
  echo "- Broken references or imports"
  echo "- Consistency issues"
  echo ""
  echo "Reply in 繁體中文."
  echo "Structure your reply as:"
  echo "## Issue #NNN 完成度檢查"
  echo "### ✅ 已完成"
  echo "### ⚠️ 部分完成"
  echo "### ❌ 未完成"
  echo "### 🔍 程式碼品質"
  echo ""
  echo "<any custom instructions>"
  echo ""
  echo "=== UNCOMMITTED CHANGES (git diff) ==="
  echo ""
  git diff
  echo ""
  echo "=== STAGED CHANGES (git diff --cached) ==="
  echo ""
  git diff --cached
  echo ""
  echo "=== UNTRACKED FILES ==="
  echo ""
  git ls-files --others --exclude-standard
} > "$PROMPT_FILE"

# Build codex command
CODEX_CMD="codex review -c 'model=\"gpt-5.4\"' -c 'model_reasoning_effort=\"<effort>\"'"
if [ "$FAST" = "true" ]; then
  CODEX_CMD="$CODEX_CMD -c 'service_tier=\"fast\"'"
fi

# Run codex review — prompt from stdin, NO --uncommitted
eval "$CODEX_CMD - < \"$PROMPT_FILE\""

rm "$PROMPT_FILE"
```

#### Mode B: Generic review (no `#NNN`) — use --uncommitted

```bash
cd <project_dir>

# Build codex command
CODEX_CMD="codex review -c 'model=\"gpt-5.4\"' -c 'model_reasoning_effort=\"<effort>\"'"
if [ "$FAST" = "true" ]; then
  CODEX_CMD="$CODEX_CMD -c 'service_tier=\"fast\"'"
fi

eval "$CODEX_CMD --uncommitted"
```

**Important notes:**
- `codex review` does NOT support `-m` flag; use `-c 'model="..."'` instead
- `--uncommitted` and `[PROMPT]` (including `-` stdin) are **mutually exclusive**
- Mode A embeds the diff directly in the prompt to work around this limitation
- Mode A still gives Codex access to the full codebase for context (it can read files)
- `-c 'service_tier="fast"'` enables lower-latency processing (same model quality)
- No `--skip-git-repo-check` needed (we're in a git repo)

### Step 7: Present Results

Display the codex output to the user with:
- Issue number and title
- Completion status summary (X/Y requirements done)
- Effort used (and whether auto-adjusted)
- Token count (from codex output)

### Step 8: Offer Follow-up

After presenting results:
- If ❌ items exist: "要繼續修正未完成的項目嗎？"
- If ⚠️ items exist: "要完善部分完成的項目嗎？"
- If all ✅: "Issue 已完成！要 commit 嗎？"

## Examples

```bash
# Verify issue #288 completion (xhigh by default)
/codex-review #288

# Quick sanity check with low effort
/codex-review #288 low

# Explicit effort override
/codex-review #300 high

# General review without issue (fallback)
/codex-review

# Custom focus on specific aspect
/codex-review #288 high 特別檢查 ui_terminology.csv 的翻譯格式

# Review shared/global_scripts changes
/codex-review #288 low shared

# Fast tier (lower latency)
/codex-review #288 fast

# Fast tier with explicit effort
/codex-review #288 fast xhigh
```

## Notes

- Codex CLI authenticates via ChatGPT Pro account (no API key needed)
- **Model: always `gpt-5.4`** (~1M context window, no model selection needed)
- `codex review --uncommitted` only works inside a git repository
- `codex review` uses `-c 'model="..."'` not `-m` for model selection
- **`--uncommitted` and `[PROMPT]` are mutually exclusive** — use diff-inline approach (Mode A) for issue-focused reviews
- `-c 'service_tier="fast"'` enables lower-latency processing (same model quality)
- No `--skip-git-repo-check` needed (we're in a git repo)
- Output includes token usage for cost awareness
- For non-git directories, falls back to `codex exec` with `--skip-git-repo-check`
