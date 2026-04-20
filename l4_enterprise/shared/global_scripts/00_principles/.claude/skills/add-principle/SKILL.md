---
name: add-principle
description: |
  新增或修改原則（Meta-Principle、Principle、Rule），自動執行 DOC_R009 三層同步。
  當用戶說「新增 principle」「加一條規則」「建立 MP/P/R」「add principle」
  「寫一個新的 rule」「這應該變成原則」時觸發。
argument-hint: "[ID 名稱] e.g. 'MP154 副作用防禦' or 'UI_R028 元件Filter排他性'"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(gh:*)
  - AskUserQuestion
---

# Add Principle — DOC_R009 三層同步

新增或修改一條原則，自動同步到三個層級。

## 為什麼需要這個 Skill？

原則散在三個地方，手動同步容易漏：
1. `.qmd`（權威來源）— 完整內容
2. `llm/*.yaml`（AI 索引）— 結構化摘要
3. `.claude/rules/*.md`（快速參考）— 一行摘要

DOC_R009 規定：新增/修改/刪除原則時，三層必須同步，順序不可顛倒。

## Execution Steps

### Step 1: 解析輸入

從 $ARGUMENTS 或對話中提取：

| 欄位 | 範例 | 必要？ |
|------|------|--------|
| ID | MP154, UI_R028, DEV_R055 | 必要 |
| 名稱 | Side Effect Defense | 必要 |
| 類型 | meta-principle / principle / rule | 必要 |
| 觸發原因 | Issue #340 | 建議 |

ID 前綴決定類型和位置：

| 前綴 | 類型 | .qmd 路徑 | llm/*.yaml |
|------|------|-----------|------------|
| MP | Meta-Principle | CH00_fundamental_principles/ | CH00_meta.yaml |
| DEV_P/DEV_R | Development | CH03_development_methodology/ | CH03_development.yaml |
| UI_P/UI_R | UI | CH04_ui_ux/ | CH04_ui.yaml |
| UX_P/UX_R | UX | CH07_ux/ | CH07_ux.yaml |
| DM_P/DM_R | Data Management | CH02_data_management/ | CH02_data.yaml |
| DP_P/DP_R | Data Presentation | CH08_data_presentation/ | CH08_data_presentation.yaml |
| SO_P/SO_R | Structure | CH01_structure_organization/ | CH01_structure.yaml |
| IC_P/IC_R | Integration | CH06_ic/ | CH06_ic.yaml |
| TD_P/TD_R | Testing | CH05_testing_deployment/ | CH05_testing.yaml |
| DOC_P/DOC_R | Documentation | CH19_documentation/ | CH19_documentation.yaml |

### Step 2: 確認下一個可用編號

```bash
# 例如要加 MP，找目前最大的 MP 編號
grep -oE 'MP[0-9]+' 00_principles/llm/CH00_meta.yaml | sort -t'P' -k2 -n | tail -1
```

如果用戶已指定 ID（如 MP154），確認沒有重複。

### Step 3: 問使用者內容（如果不夠）

用 AskUserQuestion 確認：
- one_liner（一句話描述）
- 動機/觸發原因
- rule_natural（自然語言規則描述）
- violations（違規範例）
- compliant（正確範例）
- derived_from（如果是 Rule，它實作哪個 Principle？）

如果對話中已經有足夠的脈絡（例如剛解完一個 bug），直接從對話中提取，呈現給使用者確認。

### Step 4: Layer 1 — 建立 .qmd 檔案

路徑：`00_principles/docs/en/part1_principles/{CHAPTER}/{type}/{ID}_{snake_case_name}.qmd`

```markdown
---
title: "{ID}: {Display Name}"
subtitle: "{one_liner}"
category: "{Meta-Principle|Principle|Rule}"
type: "{Meta-Principle|Principle|Rule}"
id: "{ID}"
created: "{YYYY-MM-DD}"
triggered_by: "{Issue #NNN or description}"
---

## Summary

{one_liner expanded}

## Motivation

{why this principle exists}

## {Principle Statement | Rule}

{rule_natural content}

## Application

{violations and compliant examples}
```

### Step 5: Layer 2 — 更新 llm/*.yaml

讀取對應的 `llm/CH{NN}_{name}.yaml`，在 `principles:` 區塊末尾新增 entry：

```yaml
  - id: {ID}
    type: {meta_principle|principle|rule}
    name: {snake_case_name}
    display_name: "{Display Name}"
    one_liner: "{one_liner}"
    file_path: "{relative path to .qmd}"

    rule_natural: |
      {natural language rule}

    rule_formal: |
      RULE {ID}_{UPPER_NAME}:
      {formal rule}

    violations:
      - "{violation 1}"
    compliant:
      - "{compliant 1}"
```

同時更新 yaml 檔案頂部的 `principle_count` 和 `Contains` 註解。

如果有 dependencies，也加到 `internal_dependencies:` 區塊。

### Step 6: Layer 3 — 更新 .claude/rules/*.md

找到對應的 rules 快速參考檔案，加一行摘要：

| ID 前綴 | Rules 檔案 |
|---------|-----------|
| MP | 01-always.md |
| DEV | 02-coding.md |
| UI/UX | 10-ui-layout.md |
| DM | 02-coding.md 或 03-data-queries.md |
| DOC | 05-documentation.md |

格式：`- **{ID}**: {Display Name} - {one_liner}`

### Step 7: 建立 GitHub Issue

```bash
gh issue create \
  --repo kiki830621/ai_martech_global_scripts \
  --title "[PRINCIPLE] {ID} {Display Name}" \
  --body "## New Principle

{ID}: {Display Name}
Type: {type}

{one_liner}

### Files
- .qmd: {path}
- llm/: {yaml file}
- .claude/rules/: {rules file}

Triggered by: {trigger}
"
```

### Step 8: Commit + Push

```bash
git add {.qmd file} {llm yaml} {rules md}
git commit -m "[PRINCIPLE] {ID} {Display Name} (#{issue_number})

{one_liner}

Triple-layer sync (DOC_R009):
- Layer 1: .qmd (authority)
- Layer 2: llm/{yaml}
- Layer 3: .claude/rules/{md}

Closes #{issue_number}
"
git push origin main
```

### Step 9: 確認

輸出：
```
原則已建立：{ID} {Display Name}

三層同步完成：
- Layer 1: {.qmd path} ✅
- Layer 2: {yaml file} ✅
- Layer 3: {rules file} ✅
- GitHub Issue: #{number} ✅
- Commit: {hash} ✅
```

## 修改現有原則

如果用戶說「修改 MP029」或「更新 UI_R026」：

1. 讀取現有的 .qmd
2. 呈現目前內容，問使用者要改什麼
3. 更新 .qmd（Layer 1）
4. 同步更新 llm/*.yaml（Layer 2）
5. 同步更新 .claude/rules/*.md（Layer 3）
6. Commit（引用 issue 如果有）

## Notes

- DOC_R009 順序：.qmd → llm/*.yaml → .claude/rules/*.md（不可顛倒）
- 程式碼註解只用 ASCII + 基本中文（MP100）
- 如果是 Rule，必須有 derived_from 指向 Principle 或 Meta-Principle
