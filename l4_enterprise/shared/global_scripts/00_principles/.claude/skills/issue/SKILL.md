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

## Post-Implementation Verification

After implementing an issue's code changes (before committing), **must** run `/codex-review` to verify all requirements are met:

```bash
/codex-review #NNN
```

This uses OpenAI Codex CLI to cross-check uncommitted changes against the issue's requirements, producing a completion checklist (✅/⚠️/❌).

### When to Run

| Timing | Action |
|--------|--------|
| After implementing code changes | `/codex-review #NNN` (default: spark model, low effort) |
| Before committing a complex issue | `/codex-review #NNN spark xhigh` (thorough check) |
| Deep review for critical changes | `/codex-review #NNN gpt54` (gpt-5.4, xhigh effort) |

### Workflow Integration (Iterative Loop — 直到零 findings)

```
1. Create issue (Steps 1-5 above)
2. Implement code changes
3. /codex-review #NNN          ← 靜態驗證
4. 有 ❌ 或 ⚠️？ → 修正 → 回到 3（重新 review）
5. 全部 ✅？ → 繼續
6. Commit with issue reference (#NNN)
```

**絕不允許在有 ❌ 或 ⚠️ 的狀態下 commit。** 每次修正後必須重新執行 `/codex-review`，直到結果全部為 ✅ 才能 commit。這不是建議，是強制要求。

### Final Testing (UI-Visible Changes)

For issues that modify **UI-visible behavior** (translations, layout, styling, component logic), static code review (`/codex-review`) is insufficient. **Must** also run runtime verification:

| Method | When to Use | Command |
|--------|-------------|---------|
| `/shiny-debug` | Interactive exploration, visual verification | `/shiny-debug 驗證 #NNN 的 UI 修改` |
| E2E test (shinytest2) | Regression testing, automated assertions | `make e2e` or `Rscript -e "testthat::test_dir('scripts/global_scripts/98_test/e2e')"` |

**判斷規則**：
- 改了 `translate()`、`names(show_df)`、`colnames`、KPI 顯示 → 需要 runtime 測試
- 改了 DRV 腳本、ETL 邏輯、原則文件 → 不需要 runtime 測試

**完整 workflow（UI 變更）**：
```
1. Implement code changes
2. /codex-review #NNN          ← 靜態驗證
3. 有 ❌ 或 ⚠️？ → 修正 → 回到 2（重新 review）
4. 全部 ✅？ → 繼續
5. /shiny-debug or E2E test    ← 執行期驗證
6. Commit with issue reference (#NNN)
```

---

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

## Closing an Issue (MANDATORY — 先留言再關閉)

**絕不直接 close issue。** 必須先在 issue 下方留一則 closing comment，說明問題狀況與解決方式，然後才 close。

### 為什麼

- Close 時只看到 ✅ 圖示，看不出**做了什麼**
- 未來回顧（自己、客戶、老闆）需要快速理解「這個問題怎麼處理的」
- 形成可搜尋的知識庫：`gh issue list --state closed` + 搜尋 comment

### Closing Comment 格式

```markdown
## 結案說明

### 問題狀況
{描述發現了什麼問題、影響範圍}

### 解決方式
{描述做了什麼修改、改了哪些檔案、關鍵邏輯}

### 驗證
{如何確認已修復：codex-review 結果、測試、截圖等}

### 相關 Commit
{commit hash 或連結}
```

### 執行指令

```bash
# Step 1: 留 closing comment
gh issue comment <number> \
  --repo kiki830621/ai_martech_global_scripts \
  --body "$(cat <<'EOF'
## 結案說明

### 問題狀況
...

### 解決方式
...

### 驗證
...

### 相關 Commit
...
EOF
)"

# Step 2: 確認 comment 已發布後，才 close
gh issue close <number> \
  --repo kiki830621/ai_martech_global_scripts
```

### 簡化版（小修正）

對於非常小的修正（如 typo、單行改動），可以用一行式 comment：

```bash
gh issue comment <number> \
  --repo kiki830621/ai_martech_global_scripts \
  --body "修正：{簡述做了什麼}。Commit: {hash}" && \
gh issue close <number> \
  --repo kiki830621/ai_martech_global_scripts
```

### Workflow 整合

完整流程更新為：

```
1. Create issue (Steps 1-5)
2. Implement code changes
3. /codex-review #NNN          ← 靜態驗證
4. 有 ❌ 或 ⚠️？ → 修正 → 回到 3
5. 全部 ✅？ → Commit with issue reference (#NNN)
6. gh issue comment #NNN       ← 留結案說明（問題狀況 + 解決方式）
7. gh issue close #NNN         ← 確認 comment 存在後才 close
```

---

## Notes

- Source of truth is GitHub issue status, not local markdown status fields.
- If `gh` is unavailable or unauthenticated, ask user to provide the issue URL/number, then continue work and document against that issue.
