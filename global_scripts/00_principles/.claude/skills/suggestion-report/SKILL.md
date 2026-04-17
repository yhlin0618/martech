---
description: "Generate a suggestion-docs report in GitHub Discussions (Reports category)"
argument-hint: "[company_code or source_doc_keyword]"
---

# /suggestion-report - Suggestion Docs Report Skill

## Purpose

產出給老闆看的進度匯報。從 GitHub Issues 收集所有標記 `source:suggestion_docs` 的問題，以**非技術語言**逐一說明每個問題的原因和解決方式，發布到 GitHub Discussions 的 **Reports** category。

## When to Use

- 客戶會議前：整理「客戶反映了什麼、我們做了什麼」
- Sprint review：向主管展示進度
- 定期匯報：產出特定公司的建議處理報告

## Configuration

| Key | Value |
|-----|-------|
| GitHub Repo | `kiki830621/ai_martech_global_scripts` |
| Discussion Category ID | `DIC_kwDON6xe8s4C2NWH` (Reports) |
| Source Label | `source:suggestion_docs` |

## Execution Steps

### Step 1: Determine Scope

Parse `$ARGUMENTS` to determine the report scope:

- **No arguments**: Report all `source:suggestion_docs` issues
- **Company code** (e.g., `QEF_DESIGN`): Filter by `company:<code>` + `source:suggestion_docs`
- **Keyword** (e.g., `20260209`): Filter issues whose body contains the keyword

```bash
# Default: all suggestion_docs issues
gh issue list \
  --repo kiki830621/ai_martech_global_scripts \
  --label "source:suggestion_docs" \
  --state all \
  --json number,title,state,labels,createdAt,closedAt,body \
  --limit 100
```

If a company code is provided, add `--label "company:<COMPANY_CODE>"`.

Also fetch ALL closed issues with `company:<CODE>` label (not just `source:suggestion_docs`), because fixing one client-reported issue often uncovers related engineering issues that should be included in the report.

```bash
gh issue list \
  --repo kiki830621/ai_martech_global_scripts \
  --label "company:<COMPANY_CODE>" \
  --state all \
  --json number,title,state,labels,createdAt,closedAt,body \
  --limit 100
```

### Step 2: Read Issue Details + Related Code

For each issue, you MUST:

1. **Read the full issue body** — extract `**Source**:` line, summary, affected scope
2. **Read the git commits** that resolved it — use `git log --all --grep="#<number>"` or check the closing comment
3. **Read the relevant source files** that were changed — understand WHY the problem happened and HOW it was fixed
4. **Translate into plain language** — no jargon, no code snippets, no technical terms

This step is critical. The report quality depends on understanding each issue deeply enough to explain it simply.

### Step 3: Build Report

Generate a markdown report using the template below. The key difference from a technical report:

- **每個問題都要有「問題描述」「原因」「解決方式」三段式說明**
- 用老闆能理解的語言（比喻、類比都可以）
- 不要出現程式碼、函數名稱、檔案路徑
- 可以用「系統」「資料庫」「介面」「資料來源」等通用詞彙

#### Report Template

```markdown
# {Company} 儀表板修復報告

> 報告日期：{YYYY-MM-DD}
> 來源文件：{source_doc_name}
> 處理狀態：{N} 個問題全部解決 / {N} 個已解決、{M} 個處理中

---

## 總覽

客戶於 {date} 提出的儀表板建議文件中，共包含 {N} 個問題。
目前 {resolved_count} 個已解決，{open_count} 個處理中。

修復過程中額外發現並修復了 {extra_count} 個相關問題，
總計處理 {total_count} 個問題。

---

## 客戶回報的問題

### 問題 1：{plain_language_title}

**客戶反映**：{what the client saw / complained about}

**問題原因**：{why this happened, in plain language}

**解決方式**：{what we did to fix it}

**目前狀態**：✅ 已解決

---

### 問題 2：{plain_language_title}
...

---

## 修復過程中發現的其他問題

（同樣的三段式格式，但標注「此問題為修復過程中主動發現」）

### 問題 N：{plain_language_title}

**發現經過**：{how this was discovered during the fix process}

**問題原因**：{why this happened}

**解決方式**：{what we did}

**目前狀態**：✅ 已解決

---

## 新增的防護機制

列出為了避免類似問題再次發生而建立的機制：

- {mechanism 1}: {plain language description}
- {mechanism 2}: {plain language description}

---

## 品質驗證

說明測試驗證方式和結果（用非技術語言）：

- 所有頁面逐一測試，確認功能正常
- 系統啟動過程無任何錯誤訊息
- {N} 個模組全部通過驗證
```

### Step 4: Confirm with User

Show the generated report preview and ask:

```
報告產出完成（{N} 個問題）。要發布到 GitHub Discussions 嗎？
```

### Step 5: Post to GitHub Discussions

```bash
gh api graphql -f query='
mutation($categoryId: ID!, $repositoryId: ID!, $title: String!, $body: String!) {
  createDiscussion(input: {
    repositoryId: $repositoryId,
    categoryId: $categoryId,
    title: $title,
    body: $body
  }) {
    discussion {
      url
    }
  }
}' \
  -f repositoryId="R_kgDON6xe8g" \
  -f categoryId="DIC_kwDON6xe8s4C2NWH" \
  -f title="{Company} 儀表板修復報告 — {YYYY-MM-DD}" \
  -f body="$REPORT_BODY"
```

### Step 6: Output Result

```
報告已發布：{discussion_url}

摘要：
- 客戶回報問題：N 個（全部已解決 / M 個處理中）
- 額外發現問題：K 個
- 來源文件：{doc_name}
```

## Writing Guidelines

報告撰寫的核心原則：

1. **讀者是老闆，不是工程師** — 不要假設讀者懂程式
2. **三段式必備** — 每個問題都要有「客戶反映/問題原因/解決方式」
3. **原因要說「為什麼」，不是「什麼壞了」** — 「翻譯系統從未被啟用」比「fn_translation.R 有 bug」好
4. **解決方式要說效果，不是手段** — 「現在介面全部顯示中文」比「修改了 union_production_test.R」好
5. **量化成果** — 「修復了 10 個問題」「涵蓋 63 個檔案」讓老闆感受到工作量
6. **主動發現的問題要強調** — 這顯示工程團隊的專業度，不只是被動修 bug

## Notes

- The `source:suggestion_docs` label must already exist on relevant issues
- When creating new issues from suggestion docs, always add the label and include `**Source**: filename` in the body
- Reports are append-only: each run creates a new Discussion (no overwriting)
- To add the `source:suggestion_docs` label to existing issues:
  ```bash
  gh issue edit <number> --repo kiki830621/ai_martech_global_scripts --add-label "source:suggestion_docs"
  ```
