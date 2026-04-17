---
description: "Create and manage issues in GitHub Issues (source of truth)"
---

# /issue - GitHub Issue Skill

## Purpose

Track bugs, requests, and investigations in **GitHub Issues**.

`changelog/issues/` is legacy history only. Do not create new local issue files for tracking.

## When to Use

- User reports a bug/problem
- User asks to open or update an issue
- Work needs formal tracking and status visibility

## Execution Steps

### Step 0: Read Source Document (if `.docx`)

When the input is a `.docx` file, **must** use `che-word-mcp` MCP tools to read content and extract images:

```
mcp__che-word-mcp__read_docx(path)      # Read text content
mcp__che-word-mcp__extract_images(path)  # Extract embedded images
```

**Do NOT** use `pandoc`, `document-skills:docx`, or other methods to read `.docx` files.

### Step 1: Gather Required Info

Ask user if missing:
1. **Title**
2. **Priority** (`P0` / `P1` / `P2` / `P3`)
3. **Description** (repro, expected, actual, impact)

### Step 2: Create GitHub Issue

Prefer GitHub CLI:

```bash
gh issue create \
  --title "<title>" \
  --body "<markdown body>" \
  --label "bug" \
  --label "priority:P1" \
  --label "company:<COMPANY_CODE>"
```

Body template:

```markdown
## Problem

> **Original text (原文)**:
> 「...paste exact original text from source document here...」
> — Source: {document_name}

{AI interpretation of the problem in plain language}

## Reproduction
1. ...
2. ...

## Expected
...

## Actual
...

## Impact
...
```

> **IMPORTANT**: When issues originate from a source document (e.g., customer suggestion docs), you MUST include the **exact original text** (原文) in the Problem section, quoted verbatim. This prevents misinterpretation — AI may misunderstand the original meaning, and having the original text allows reviewers to verify the correct scope of the issue.

### Step 2.1: Attach Images (If Applicable)

When the issue includes screenshots, error captures, or diagrams:

1. **Upload image to the `attachments` release**:

```bash
gh release upload attachments <local_image_path> \
  --repo kiki830621/ai_martech_global_scripts \
  --clobber
```

2. **Naming convention**: `issue_<number>_<description>.png`

Example: `issue_198_broken_sidebar.png`

3. **Reference in issue body** using the download URL:

```markdown
![description](https://github.com/kiki830621/ai_martech_global_scripts/releases/download/attachments/issue_198_broken_sidebar.png)
```

4. **Workflow when creating with image**:

Since the issue number isn't known until creation, use this order:
  1. Create the issue first (without image in body)
  2. Note the returned issue number
  3. Rename and upload the image with the issue number
  4. Edit the issue body to add the image link:

```bash
# Upload with issue number in filename
cp screenshot.png /tmp/issue_<number>_<description>.png
gh release upload attachments /tmp/issue_<number>_<description>.png \
  --repo kiki830621/ai_martech_global_scripts --clobber

# Add image to issue body
gh issue edit <number> --repo kiki830621/ai_martech_global_scripts \
  --body "$(gh issue view <number> --repo kiki830621/ai_martech_global_scripts --json body -q .body)

## Screenshot
![<description>](https://github.com/kiki830621/ai_martech_global_scripts/releases/download/attachments/issue_<number>_<description>.png)"
```

> The `attachments` release (tag: `attachments`) is a permanent asset store — not a versioned release. Use `--clobber` to overwrite if re-uploading.

### Step 3: Record Local Implementation Report (Optional)

If code changes are implemented, add a report in:

`scripts/global_scripts/00_principles/changelog/reports/`

Recommended filename:

`YYYY-MM-DD_issue-<github-number>_<short-title>.md`

### Step 4: Link Issue to Company Project Board

In `global_scripts`, maintain one GitHub Project board per company context.

```bash
gh project item-add <project_number> \
  --owner kiki830621 \
  --url "https://github.com/kiki830621/ai_martech_global_scripts/issues/<number>"
```

Board selection rule:
- GitHub Project is a container, not a scope type by itself
- Find issue scope from `company:<COMPANY_CODE>` or `module:<ModuleName>` label
- Add to the matching scope board

### Step 5: Confirm Back to User

Return:
- GitHub issue number and URL
- Labels/priority used
- Project board linked
- Whether a local implementation report was created

## Source Document Rule (CRITICAL)

When creating issues from a source document (e.g., customer suggestion docs like `技詮儀表板問題_20260302.docx`):

### One Point = One Issue (絕不合併、絕不省略)

- **每一個要點都必須建立獨立的 issue**，即使內容看似相關
- **絕不合併**：兩個要點即使主題相近（如都是「改中文」），仍分開建立，因為涉及不同元件
- **絕不省略**：即使某個要點與已存在的 issue 重複，仍然建立新 issue 並在 body 中標註 Related Issues
- **事後核銷即可**：如果某個 issue 確認是重複的，之後關閉並標記 duplicate 就好；但漏建 issue 會導致客戶反映被遺忘

### Counting Checklist

處理完文件後，必須確認：
```
文件要點數 = 建立的 issue 數
```

如果不相等，回去逐點對照找出漏建的。

## Notes

- Source of truth is GitHub issue status, not local markdown status fields.
- If `gh` is unavailable or unauthenticated, ask user to provide the issue URL/number, then continue work and document against that issue.
