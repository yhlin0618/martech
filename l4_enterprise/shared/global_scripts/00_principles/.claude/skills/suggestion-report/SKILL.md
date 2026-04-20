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

### Step 2: Verify Completeness (CRITICAL — do this BEFORE writing the report)

Before writing any report text, **thoroughly verify** that each issue has actually been resolved. A CLOSED issue on GitHub does NOT guarantee the fix is complete.

#### 2a. For each CLOSED issue, check for corresponding commits

```bash
# Find commits referencing this issue number
git log --all --oneline --grep="#<number>" | head -10
```

If **no commits found**, flag the issue as `⚠️ NO COMMITS — may not be implemented`.

#### 2b. For issues WITH commits, spot-check the changes

```bash
# Show files changed in the commit
git show --stat <commit_hash>
```

Check that:
- The changed files are **relevant** to the issue (not just docs/changelog)
- The changes are **substantive** (not just comments or formatting)
- For UI issues: the relevant Shiny component files were touched
- For data issues: the relevant DRV/ETL scripts were touched

#### 2c. App Live Testing (MANDATORY for UI/data issues)

If **any** issues relate to visible UI changes (labels, translations, layout, new tabs, renamed fields, new charts), you **MUST** launch the app and verify before writing the report. Reading source code alone is insufficient — the report's credibility depends on confirming the running app.

**Procedure:**

1. **Launch the app** using `/shiny-debug` for the relevant company project:
   ```
   /shiny-debug 驗證 {COMPANY_CODE} 儀表板修復
   ```

2. **Systematic verification** — walk through each affected module/tab:
   - Login works (password: `VIBE`)
   - Each modified tab loads without errors
   - Renamed fields display correct Chinese names
   - New components (charts, KPI cards, AI buttons) are visible and functional
   - No blank panels or JS errors

3. **Screenshot evidence** — take screenshots of key pages as verification artifacts

4. **Dual-track check** — after each page navigation:
   ```bash
   # Frontend: browser console errors
   agent-browser console
   # Backend: R log errors
   tail -20 .shiny-debug/shiny.log
   ```

5. **Record results** in a verification checklist:
   ```markdown
   ## App 實測結果
   - [ ] 登入正常
   - [ ] TagPilot 各 tab 正常載入
   - [ ] VitalSigns 各 tab 正常載入
   - [ ] 新增元件可見且可操作
   - [ ] 欄位名稱全中文
   - [ ] 無前端/後端錯誤
   ```

**If testing reveals issues**, flag them as `🔴 TESTING FAILED` in the verification table and **do NOT proceed to report writing** until resolved.

#### 2d. Check for OPEN issues that should have been resolved

Any issue still OPEN that the source document mentions should be flagged as `🔴 STILL OPEN`.

#### 2e. Present verification summary to user

Before proceeding to write the report, present a verification table:

```markdown
## 驗證結果

| # | Issue | 狀態 | Commits | 驗證結果 |
|---|-------|------|---------|----------|
| 1 | #254 RFM 分佈圖 | CLOSED | abc1234, def5678 | ✅ 已驗證 |
| 2 | #255 CAI 標籤顯示 | CLOSED | (none found) | ⚠️ 無對應 commit |
| 3 | #260 NES 覺醒率 | OPEN | — | 🔴 尚未完成 |

問題：
- ⚠️ #255: 未找到對應 commit，需要確認是否真的修完了
- 🔴 #260: 仍為 OPEN 狀態

要繼續產出報告嗎？還是先處理這些問題？
```

**IMPORTANT**: Only proceed to Step 3 after the user confirms. If there are `⚠️` or `🔴` items, ask the user whether to:
1. Investigate further (read the code, check if fix was bundled in another commit)
2. Skip those items in the report
3. Include them as "處理中" in the report

### Step 3: Read Issue Details + Related Code

For each issue, you MUST:

1. **Read the full issue body** — extract `**Source**:` line, summary, affected scope
2. **Read the git commits** that resolved it — use `git log --all --grep="#<number>"` or check the closing comment
3. **Read the relevant source files** that were changed — understand WHY the problem happened and HOW it was fixed
4. **Translate into plain language** — no jargon, no code snippets, no technical terms

This step is critical. The report quality depends on understanding each issue deeply enough to explain it simply.

### Step 4: Build Report

Generate a markdown report using the template below. The key difference from a technical report:

- **每個問題都要有「問題描述」「原因」「解決方式」三段式說明**
- 用老闆能理解的語言（比喻、類比都可以）
- 不要出現程式碼、函數名稱、檔案路徑
- 可以用「系統」「資料庫」「介面」「資料來源」等通用詞彙

#### Report Template

```markdown
# {Company} 儀表板修復報告

> **報告日期**：{YYYY-MM-DD}
> **來源文件**：{source_doc_name}
> **處理狀態**：{N} 個客戶問題全部解決，共關閉 {total_count} 個 GitHub Issues

> **結論**：{Company} 於 {date} 回報的 {N} 個問題已全部解決，加上修復過程中額外發現的
> {extra_count} 個問題，共計 {total_count} 個工作項目全部完成。若以 10 位一般能力的
> 工程師執行同等工作，預估總工時約 {estimated_hours} 人時。儀表板已於 {YYYY-MM-DD}
> 通過實機測試，可正常使用。

---

## 總覽

客戶於 {date} 提出的儀表板建議文件中，共包含 {N} 個問題。
目前 {resolved_count} 個已解決，{open_count} 個處理中。

修復過程中額外發現並修復了 {extra_count} 個相關問題，
總計處理 {total_count} 個問題。

### 工時估算

若以 10 位一般能力的軟體工程師進行同等規模的修改（含需求釐清、開發、測試、Code Review、Wiki 文件更新），預估**總工時約 {estimated_hours} 人時**。

---

## 客戶回報的問題

### 問題 1：{plain_language_title}

**客戶反映**：
> {直接引用 issue body 中的客戶原文，用 blockquote 格式}
> — 來源：{source_doc_name}（第 N 點）

**問題原因**：{用白話補充上下文，讓老闆理解為什麼這是一個問題}

**解決方式**：{what we did to fix it}

**目前狀態**：✅ 已解決（[#NNN](https://github.com/kiki830621/ai_martech_global_scripts/issues/NNN)）

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

### Step 5: Check for Existing Report (CREATE vs UPDATE)

Before confirming with the user, check if a report for this company/source already exists:

```bash
# Search existing discussions by title pattern
gh api graphql -f query='
query($repo: String!, $owner: String!, $query: String!) {
  search(query: $query, type: DISCUSSION, first: 5) {
    nodes {
      ... on Discussion {
        id
        number
        title
        url
        updatedAt
        body
      }
    }
  }
}' \
  -f owner="kiki830621" \
  -f repo="ai_martech_global_scripts" \
  -f query="repo:kiki830621/ai_martech_global_scripts {Company} 儀表板修復報告"
```

#### 5a. If existing report found → UPDATE mode

Present to user:

```
找到現有報告：「{title}」（{url}）
上次更新：{updatedAt}

選項：
1. 更新現有報告（推薦 — 保持單一報告持續追蹤）
2. 建立新報告（適合全新來源文件或重大里程碑）

要怎麼做？
```

#### 5b. If no existing report → CREATE mode

```
報告產出完成（{N} 個問題）。要發布到 GitHub Discussions 嗎？
```

### Step 6: Post or Update GitHub Discussions

#### CREATE mode（新建報告）

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

#### UPDATE mode（更新現有報告）

更新時，在報告最上方加入更新記錄，保留歷史：

```markdown
# 更新記錄
| 日期 | 變更摘要 |
|------|----------|
| {YYYY-MM-DD} | 新增修復 N 個問題（[#XXX](...), [#YYY](...)） |
| {previous_date} | 初始報告，處理 M 個問題 |
```

使用 GraphQL `updateDiscussion` mutation：

```bash
gh api graphql -f query='
mutation($discussionId: ID!, $body: String!) {
  updateDiscussion(input: {
    discussionId: $discussionId,
    body: $body
  }) {
    discussion {
      url
    }
  }
}' \
  -f discussionId="{existing_discussion_id}" \
  -f body="$UPDATED_REPORT_BODY"
```

**更新策略**：
- **總覽區段**：更新數字（問題總數、已解決數、工時估算）
- **已完成的問題**：保留原有內容，新增的放在最後並標記 `🆕`
- **仍在處理的問題**：更新狀態（如從 ⚠️ 變 ✅）
- **更新記錄**：每次更新在頂部加一行

### Step 7: Output Result

```
# CREATE mode
報告已發布：{discussion_url}

# UPDATE mode
報告已更新：{discussion_url}
更新內容：新增 {N} 個已解決問題，{M} 個狀態更新

摘要：
- 客戶回報問題：N 個（全部已解決 / M 個處理中）
- 額外發現問題：K 個
- 來源文件：{doc_name}
```

## Writing Guidelines

### 最高原則：引用優先，摘要為輔（MANDATORY）

**引用 issue 原文的內容永遠勝過 AI 摘要。** 摘要會丟失精確度，引用不會。

**每個問題的「客戶反映」區段必須包含 issue 原文引用**（blockquote `>` 格式）。這是為了：
- 讓讀者不用點進 issue 就能看到客戶的原始描述
- 避免 AI 摘要造成語意偏移
- 保留客戶用語的原汁原味（老闆比較容易回憶起客戶說了什麼）

撰寫流程：
1. **「客戶反映」**：先從 issue body 的 `> **原文**:` 區塊擷取客戶原文（用 blockquote），再用一句白話補充
2. **「問題原因」**：用白話解釋為什麼這是問題（不用引用）
3. **「解決方式」**：說效果，不說手段。如涉及公式，引用 issue 中的公式描述
4. **不確定的內容寧可引用原文，不要自行改寫**

**範例 — 正確做法**：
```markdown
**客戶反映**：
> 「留存率拿掉，因為流失率和留存率是倒數關係。」
> — 來源：技詮儀表板問題_20260308.docx（第 1 點）

**問題原因**：留存率與流失率互為倒數（留存率 = 1 - 流失率），同時顯示兩個指標造成資訊冗餘。

**解決方式**：已將「留存率」從介面中移除，保留流失率作為唯一指標。
```

**範例 — 錯誤做法**：
```markdown
❌ **客戶反映**：留存率這個區塊不需要，請拿掉。
   → 遺失了客戶給的理由（「倒數關係」），老闆看不出客戶的思路
```

#### 公式 / 指標 / 統計方法 — 安全閥規則（CRITICAL）

當 issue 涉及公式、指標定義、或統計方法時，**絕對禁止** AI 自行改寫或簡化：

| 行為 | 允許？ | 原因 |
|------|--------|------|
| 直接引用 issue 中的公式描述 | ✅ 必須 | 精確度最高 |
| 用白話解釋「這個指標幫你判斷什麼」 | ✅ 可以 | 幫助老闆理解用途 |
| 改寫公式的計算邏輯 | ❌ 禁止 | AI 會過度簡化（如「MLE vs WMLE」被簡化成「最近 vs 歷史」） |
| 推斷指標的方向性（高=好 or 低=好） | ❌ 禁止 | AI 傾向「越高越好」但偏差指標越低越好（如 CRI） |

**範例 — 正確做法**：
```markdown
**解決方式**：在 Wiki 補上 CAI 的完整公式。

> CAI = (MLE − WMLE) / MLE
> MLE：等權平均購買間隔；WMLE：近期加權平均購買間隔
> 正值 = 越來越活躍、接近零 = 穩定、負值 = 逐漸不活躍

白話說明：這個指標幫你看出客戶最近的購買頻率是變快還是變慢。
```

**範例 — 錯誤做法（Issue #331 的教訓）**：
```markdown
❌ 比較最近購買間隔與歷史平均間隔的變化趨勢
   → 過度簡化，丟失「兩種不同加權方式」的核心概念

❌ 數值越高代表購買節奏越穩定
   → 方向反轉，CRI 實際上越接近 0 越穩定
```

### 報告撰寫原則

1. **讀者是老闆，不是工程師** — 不要假設讀者懂程式
2. **三段式必備** — 每個問題都要有「客戶反映/問題原因/解決方式」
3. **原因要說「為什麼」，不是「什麼壞了」** — 「翻譯系統從未被啟用」比「fn_translation.R 有 bug」好
4. **解決方式要說效果，不是手段** — 「現在介面全部顯示中文」比「修改了 union_production_test.R」好
5. **量化成果** — 「修復了 10 個問題」「涵蓋 63 個檔案」讓老闆感受到工作量
6. **主動發現的問題要強調** — 這顯示工程團隊的專業度，不只是被動修 bug
7. **技術內容引用原文** — 涉及公式或指標時，用 blockquote 引用 issue 原文，再補白話說明
8. **Issue 超連結** — 報告中每次提到 issue 編號時，必須加上 GitHub 超連結（見下方規則）
9. **Wiki 超連結** — 報告中提到已更新 Wiki 文件時，必須附上 Wiki 頁面連結（見下方規則）

### Issue 超連結規則（MANDATORY）

報告中**每次引用 issue 編號時**，都必須使用完整超連結，讓老闆可以直接點擊查看詳情：

```markdown
# 正確：有超連結
[#288](https://github.com/kiki830621/ai_martech_global_scripts/issues/288)

# 錯誤：只有編號
#288
```

在「目前狀態」後面也要附上：

```markdown
**目前狀態**：✅ 已解決（[#288](https://github.com/kiki830621/ai_martech_global_scripts/issues/288)）
```

如果一個問題對應多個 issue：

```markdown
**目前狀態**：✅ 已解決（[#290](https://github.com/kiki830621/ai_martech_global_scripts/issues/290), [#291](https://github.com/kiki830621/ai_martech_global_scripts/issues/291)）
```

### Wiki 超連結規則（MANDATORY）

當報告提到「已在 Wiki 補上公式說明」或「Wiki 文件已更新」時，**必須附上 Wiki 頁面的超連結**，讓老闆可以直接點進去看。

Wiki Base URL: `https://github.com/kiki830621/ai_martech_global_scripts/wiki`

常用 Wiki 頁面對照表：

| 指標/術語 | Wiki 頁面 URL |
|----------|--------------|
| RFM | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-RFM` |
| NES | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-NES` |
| CAI | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-CAI` |
| CRI | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-CRI` |
| CLV | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-CLV` |
| IPT | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-IPT` |
| PCV | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-PCV` |
| P(alive) | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-P-alive` |
| RSV | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-RSV` |
| Marketing Strategies | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-Marketing-Strategies` |
| Glossary | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/Glossary` |
| TagPilot | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/TagPilot` |
| VitalSigns | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/VitalSigns` |
| BrandEdge | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/BrandEdge` |
| InsightForge | `https://github.com/kiki830621/ai_martech_global_scripts/wiki/InsightForge` |

**報告中的使用方式**：

```markdown
**解決方式**：在 [Wiki（CRI 術語頁）](https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-CRI) 補上完整公式說明。
```

```markdown
**解決方式**：已在 [Wiki（NES 術語頁）](https://github.com/kiki830621/ai_martech_global_scripts/wiki/Term-NES) 補上完整分類邏輯和計算公式。
```

### 工時估算方法

報告「總覽」區段需包含工時估算。

**估算情境**：以 10 位一般能力的工程師為基準。「一般能力」= 具備基本開發能力，但**不熟悉本系統**的架構、原則體系、統計/心理計量公式。不要高估一般人的能力。10 人協作的溝通成本以 +30% 計算。

**注意**：估算前提**不寫進報告**，只在內部計算時使用。報告中只呈現最終數字。

**工時對照表（一般能力工程師基準）**：

| 問題類型 | 單一問題工時（人時） | 說明 |
|----------|---------------------|------|
| UI 翻譯/改名 | 2–3h | 找到正確檔案 + 理解翻譯系統 + 改 CSV/YAML + 驗證 |
| 指標拿掉/新增 KPI 卡片 | 3–5h | 理解元件結構 + 修改 + 調整 layout + 測試 |
| 公式修正/新演算法 | 12–20h | 理解統計概念 + 查資料 + 實作 + 單元測試 + Wiki |
| 新增完整元件（圖表+互動） | 16–24h | UI + Server + 資料流 + 測試 + 整合 |
| 新 DRV 腳本（含 pipeline 整合） | 8–12h | 理解 pipeline 架構 + 核心函數 + wrapper + 驗證 |
| AI 洞察功能增強 | 8–10h | Prompt 設計 + 非同步整合 + 測試 |
| Wiki 文件補充（含公式驗證） | 3–4h | 理解公式 + 寫文件 + 交叉比對程式碼 |
| Bug 修復（資料/邏輯） | 4–6h | 定位問題 + 理解上下文 + 修復 + 迴歸測試 |
| 整體診斷 AI 功能 | 12–18h | 跨指標整合 + prompt engineering + 測試 |
| E2E 測試 / Code Review | 6–10h | 理解測試框架 + 撰寫 + 自動化驗證 |

**計算方式**：
1. 依上表為每個 issue 分配工時
2. 加總所有 issue 工時
3. 額外加 30% 的 10 人協作 overhead（溝通、整合測試、merge conflict）
4. 在估算依據中列出分類統計

**呈現方式**（用區間，不要用精確數字）：
- < 100h → 「約 {N}–{M} 人時」
- 100–500h → 「約 {N}–{M} 人時」
- > 500h → 「約 {N}–{M} 人時」

## Notes

- The `source:suggestion_docs` label must already exist on relevant issues
- When creating new issues from suggestion docs, always add the label and include `**Source**: filename` in the body
- **報告預設為更新模式**：同一份來源文件的報告只有一個 Discussion，後續修復以更新方式追加，維持單一追蹤點
- **新建報告**：僅在全新來源文件、或重大里程碑（如全部完成）時建立新 Discussion
- To add the `source:suggestion_docs` label to existing issues:
  ```bash
  gh issue edit <number> --repo kiki830621/ai_martech_global_scripts --add-label "source:suggestion_docs"
  ```
