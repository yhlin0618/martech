# 記錄變更時

**使用時機**: 記錄變更、寫 commit 時

---

## 快速參考

### Changelog 記錄位置

| 目錄 | 用途 |
|------|------|
| `changelog/reports/` | 所有報告（規劃文件、ADR、實施報告、Issue 實作摘要）|

### reports/ 檔案類型

| 命名模式 | 類型 | 說明 |
|----------|------|------|
| `YYYY-MM-DD_PLAN_xxx.md` | 規劃文件 | Plan Mode 自動存檔 |
| `YYYY-MM-DD_xxx.md` | 實施報告 | 已完成的工作報告 |
| `ADR-NNN_xxx.md` | 架構決策 | Architecture Decision Record |
| `YYYY-MM-DD_issue-<number>_xxx.md` | Issue 實作報告 | 對應 GitHub Issue 的本地執行記錄 |

### Issue 追蹤（重要）

- **唯一真實來源 (source of truth)**: GitHub Issues（`global_scripts` repo）
- **禁止**再建立新的 `changelog/issues/open/*.md` 或 `changelog/issues/closed/*.md` 作為 issue tracker
- `changelog/issues/` 僅作歷史遺留資料（legacy）保留，不作新增追蹤用途
- 本地只保留「執行報告」到 `changelog/reports/`，並在檔名或內容註明 GitHub issue 編號（例如 `#148`）
- 範圍分類使用：
  - 公司：`company:<COMPANY_CODE>`
  - 模組：`module:<ModuleName>`（例如 `module:BrandEdge`）
- 來源追溯使用：
  - `source:suggestion_docs` — Issue 來自客戶建議文件（如 `向創儀表板建議_20260209.docx`）
  - Issue body 中應註明 `**Source**: 文件名稱`，方便匯報時回溯
  - 匯報用途：篩選 `source:suggestion_docs` label 即可列出所有來自客戶建議的 issues 及處理狀態
- GitHub Project 是容器，不等於公司；每個 `company:*` / `module:*` scope 可有對應看板，issue 建立後需加入對應看板

### Plan Mode 自動存檔

每次 Plan Mode 結束（ExitPlanMode）時，規劃文件自動存檔到：
```
changelog/reports/YYYY-MM-DD_PLAN_{topic}.md
```

存檔內容包含：
- 原始規劃文件
- 時間戳和來源 metadata
- 狀態標記 (status: planned)

**排除存檔**：在 plan 頂端加 `<!-- NO_ARCHIVE -->`

### Commit Message 格式

```
[TYPE] Brief description

- Detail 1
- Detail 2

Principles: MP064, DM_R028
```

### TYPE 標籤

| 標籤 | 用途 |
|------|------|
| `[ETL]` | ETL 相關變更 |
| `[DRV]` | Derivation 相關變更 |
| `[FIX]` | Bug 修復 |
| `[FEAT]` | 新功能 |
| `[DOCS]` | 文件更新 |
| `[REFACTOR]` | 重構 |
| `[PRINCIPLE]` | 原則更新 |

---

## GitHub Wiki 文件系統（面向非技術人員）

### 概述

GitHub Wiki 是給**客戶和非技術團隊成員**閱讀的文件系統，包含儀表板操作指南和術語詞彙表。

- **Wiki URL**: `https://github.com/kiki830621/ai_martech_global_scripts/wiki`
- **Git repo**: `git@github.com:kiki830621/ai_martech_global_scripts.wiki.git`

### 頁面結構

| 類別 | 頁面 | 說明 |
|------|------|------|
| 導覽 | `Home.md`, `_Sidebar.md` | 首頁和側邊欄 |
| 儀表板指南 | `TagPilot.md`, `VitalSigns.md`, `BrandEdge.md`, `InsightForge.md`, `ReportCenter.md` | 每個模組的 tab 說明 |
| 術語詞彙表 | `Term-{NAME}.md`（13 頁）+ `Glossary.md` | 指標定義、公式、範例 |

### 何時需要更新 Wiki

| 觸發事件 | 需要更新的頁面 |
|----------|---------------|
| 新增或移除 tab | 對應模組的儀表板指南頁 + `_Sidebar.md`（如有新術語） |
| 修改指標計算公式 | 對應的 `Term-*.md` + `Glossary.md` |
| 新增指標/術語 | 新建 `Term-*.md` + 更新 `Glossary.md` + `_Sidebar.md` |
| 調整 RSV 閾值或行銷策略 | `Term-RSV.md` 或 `Term-Marketing-Strategies.md` |
| 新增儀表板模組 | 新建模組指南頁 + 更新 `Home.md` + `_Sidebar.md` |

### 本地位置

Wiki repo 已 clone 到 `00_principles/` 內，方便本地瀏覽和編輯：

```
00_principles/docs/wiki/    ← Wiki 的本地副本（獨立 Git repo）
```

- 此目錄已加入 `.gitignore`，不會被 global_scripts 的 Git 追蹤
- Wiki 有自己的 Git 歷史（`docs/wiki/.git/`）

### 編輯流程

```bash
# 進入 Wiki 目錄
cd 00_principles/docs/wiki

# 1. 同步最新版本
git pull

# 2. 編輯 Markdown 檔案

# 3. 提交並推送
git add -A
git commit -m "docs: 更新 {說明}"
git push
```

### 首次設定（如果 docs/wiki/ 不存在）

```bash
cd 00_principles/docs
git clone git@github.com:kiki830621/ai_martech_global_scripts.wiki.git wiki
```

### 撰寫原則

- **語言**：繁體中文（遵循 UI_R025 臺灣正體中文用語），術語名稱保留英文
- **公式**：使用 LaTeX 記法，**必須與程式碼一致**（交叉比對 `04_utils/fn_analysis_dna.R` 等）
- **每個術語頁必須包含**：定義、數學公式、變數說明、範例、儀表板位置
- **每個 tab 說明必須包含**：顯示內容、操作方式、看懂重點（回答什麼商業問題）
- **禁止假資料**（MP029）：範例中的數字應合理但不需來自真實客戶

### Wiki 連結語法（重要！）

GitHub Wiki 的連結語法是 `[[顯示文字|頁面名稱]]`，**不是** `[[頁面名稱|顯示文字]]`。

| 位置 | 語法 | 範例 |
|------|------|------|
| 一般文字 / blockquote | `[[顯示文字\|頁面名稱]]` | `[[RFM\|Term-RFM]]` → 顯示 "RFM"，連到 Term-RFM 頁 |
| Markdown 表格內 | `[顯示文字](頁面名稱)` | `[RFM](Term-RFM)` |
| 無需自訂顯示文字 | `[[頁面名稱]]` | `[[TagPilot]]` → 顯示 "TagPilot" |

**為什麼表格內不用 `[[]]`？**
- `[[A|B]]` 的 `|` 會被 Markdown 表格解析器誤判為欄位分隔符
- 表格內必須用標準 Markdown 連結 `[text](page)` 避免衝突

**常見錯誤**：

| 錯誤 | 正確 | 問題 |
|------|------|------|
| `[[Term-RFM\|RFM]]` | `[[RFM\|Term-RFM]]` | 順序反了：第一個是顯示文字，第二個是頁面 |
| 表格內用 `[[RFM\|Term-RFM]]` | 表格內用 `[RFM](Term-RFM)` | pipe 衝突 |

### 公式來源對照表

更新公式時，必須從以下程式碼檔案驗證：

| 公式 | 程式碼檔案 |
|------|-----------|
| RFM, NES, IPT, CAI, PCV, CLV, CRI | `04_utils/fn_analysis_dna.R` |
| P(alive) / BG-NBD | `04_utils/fn_analysis_btyd.R` |
| DNA segments (M1-M4, F1-F3, R1-R4) | `16_derivations/fn_D01_02_core.R` |
| RSV classification | `10_rshinyapp_components/tagpilot/fn_rsv_classification.R` |
| Poisson regression | `docs/.../SCHEMA_001_poisson_analysis.R` |

---

## 匯報 Skills

### `/suggestion-report` — 客戶建議修復報告

當需要向老闆匯報客戶建議的處理進度時使用：

```
/suggestion-report QEF_DESIGN    # 向創的修復報告
/suggestion-report D_RACING      # 技詮的修復報告
/suggestion-report               # 所有公司的報告
```

- 從 GitHub Issues（`source:suggestion_docs` label）收集資料
- 以非技術語言產出三段式報告（客戶反映/問題原因/解決方式）
- 發布到 GitHub Discussions 的 Reports category

---

## 完整規範參考

詳細的文件規範請參考：

| 主題 | 位置 |
|------|------|
| Issue Tracker 系統 | GitHub Issues（`global_scripts` repository） |
| 原則修訂標準 | `docs/en/part1_principles/CH00_meta/` |
| Changelog 格式詳細 | `llm/index.yaml` > scenarios |
| 版本號規則 | `docs/en/part1_principles/CH00_meta/` |
| Wiki 文件（儀表板指南 + 術語） | `https://github.com/kiki830621/ai_martech_global_scripts/wiki` |
| Wiki 更新 scenario | `llm/index.yaml` > scenarios > `updating_wiki` |

---

## 相關原則

- **MP030**: Archive Immutability (存檔不可變性)
- **SO_P018**: Directory Governance (目錄治理)
- **DOC_P001**: Documentation System Architecture (文件系統架構)
- **DOC_R001**: Wiki Link Syntax (Wiki 連結語法)
- **DOC_R002**: Wiki Content Standards (Wiki 內容標準)
- **DOC_R003**: Formula Cross-Verification (公式交叉驗證)
- **DOC_R004**: Changelog and Reporting Format (Changelog 與報告格式)
