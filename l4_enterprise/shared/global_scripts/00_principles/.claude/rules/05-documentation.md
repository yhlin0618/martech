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

### 雙向追溯 (IC_R009)

每個 commit **必須**引用至少一個 GitHub Issue 編號，每個 Issue **必須**有對應的 commit。**無例外** — 即使是小修正也需要 issue。

- commit message 中加入 `(#NNN)` 或 `Closes #NNN`
- 如果沒有對應 issue，先建立 issue 再 commit
- 多個小修正可共用一個 housekeeping issue

### Commit Message 格式

```
[TYPE] Brief description (#NNN)

- Detail 1
- Detail 2

Closes #NNN
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

### 何時需要更新 Wiki (DOC_R006 — Hook 自動提醒)

Wiki 是給**客戶和老闆**看的唯一文件。儀表板改了但 Wiki 沒更新 = 客戶看不懂產品。

**自動化執行**：PostToolUse hook `check-wiki-sync.sh` 會在修改下列檔案時自動提醒。

| 觸發事件 | 需要更新的頁面 |
|----------|---------------|
| 修改 `tagpilot/` 元件 | `TagPilot.md` |
| 修改 `vitalsigns/` 元件 | `VitalSigns.md` |
| 修改 `position/` 元件 | `BrandEdge.md` |
| 修改 `poisson/` 元件 | `InsightForge.md` |
| 修改 `report/` 元件 | `ReportCenter.md` |
| 修改 `fn_analysis_dna.R` | `Term-RFM.md`, `Term-NES.md`, `Term-CAI.md`, `Term-PCV.md`, `Term-CRI.md`, `Term-CLV.md`, `Term-IPT.md` |
| 修改 `fn_analysis_btyd.R` | `Term-P-alive.md` |
| 修改 `fn_rsv_classification.R` | `Term-RSV.md` |
| 修改 `fn_D01_02_core.R` | `Term-RFM.md`（DNA segments） |
| 修改 `marketing_strategies.yaml` | `Term-Marketing-Strategies.md` |
| 修改 `ui_terminology.csv` | `Glossary.md` |
| 修改 `union_production*.R` | `Home.md`, `_Sidebar.md` |
| 新增或移除 tab | 對應模組的儀表板指南頁 + `_Sidebar.md` |
| 新增指標/術語 | 新建 `Term-*.md` + 更新 `Glossary.md` + `_Sidebar.md` |
| 調整 RSV 閾值或行銷策略 | `Term-RSV.md` 或 `Term-Marketing-Strategies.md` |
| 新增儀表板模組 | 新建模組指南頁 + 更新 `Home.md` + `_Sidebar.md` |

**Hook 行為**：advisory（非阻擋），提醒哪些 Wiki 頁面可能需要更新。

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

# 1. 以 published branch 為基底同步
git checkout master
git pull origin master

# 2. 開功能分支
git checkout -b codex/wiki-{topic}

# 3. 編輯 Markdown 檔案

# 4. 提交變更
git add -A
git commit -m "docs: 更新 {說明}"

# 5. 本地 review 後合回 master
git checkout master
git pull --ff-only origin master
git merge codex/wiki-{topic}

# 6. 發布
git push origin master
```

### 分支與發布說明（重要）

- GitHub Wiki 是獨立 Git repo，但**實際發布分支固定為 `master`**
- 目前 GitHub Wiki repo **不支援一般 repository 的 GitHub PR / gh CLI PR 流程**
- 因此建議流程是：
  - 先在本地開功能分支整理修改
  - 在本地用 `git diff` / markdown 預覽完成人工 review
  - 確認後再 merge 回 `master`
  - **只有 push 到 `master` 的內容會顯示在 GitHub Wiki**

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

### 客戶視角增補方向（Wiki 後續持續加入）

為了讓 Wiki 更適合**客戶、營運團隊、非技術使用者**直接閱讀，後續重寫或擴充頁面時，應逐步補入以下內容：

- **模組頁**逐步補上：
  - 適合誰看（例如：老闆、品牌經理、CRM、業務）
  - 什麼情況下要打開這頁
  - 看完後最常見的下一步行動
- **每個 tab 說明**逐步補上：
  - 一句話商業問題（這頁到底在回答什麼）
  - 三步驟閱讀法（先看哪個 KPI、再看哪張圖、最後怎麼決策）
  - 常見誤讀提醒（避免把技術指標看反）
- **每個術語頁**逐步補上：
  - 更白話的一句話版本
  - 先講商業意義，再講公式
  - 盡量降低 `ECDF`、`quantile`、`BG/NBD` 等術語直接裸露的頻率；若必須出現，要同步給白話解釋

### 客戶視角寫法原則

- **先回答問題，再講機制**：先說「這個指標幫你判斷什麼」，再說「它怎麼算」
- **先說行動，再說模型**：先說「看到這個結果要做什麼」，再說後面的統計邏輯
- **避免開發者語氣**：不要把 Wiki 寫成程式碼註解、資料表說明或理論筆記
- **容許公式存在，但不讓公式當主角**：Glossary 可以保留公式，但每頁開頭要讓非技術讀者先看懂
- **把 branch review 視為正式步驟**：即使沒有 GitHub PR，也要先在功能分支上完成檢查，再回到 `master` 發布

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

### Wiki 數學公式語法 (DOC_R005) — KaTeX

GitHub Wiki 用 KaTeX 渲染公式。**必須遵守以下規則**，否則公式會顯示錯誤：

**關鍵：GitHub Wiki markdown 預處理器會在 `$...$` 數學區塊內消耗 `\_` 的反斜線**，因此必須用 `\\_`（雙反斜線）：
- `\_` → markdown 消耗 `\` → KaTeX 收到裸 `_`（下標）→ "Double subscripts" 錯誤
- `\\_` → markdown 消耗一個 `\` → KaTeX 收到 `\_`（字面底線）→ 正確

| 規則 | 正確 | 錯誤 | 原因 |
|------|------|------|------|
| 行內數學 | `$x$` | `\(x\)` | GitHub Wiki 不支援 `\( \)` |
| 區塊數學 | `$$` 前後空行 | `\[ \]` | GitHub Wiki 不支援 `\[ \]` |
| `\text{}` 含底線 | `\text{time}\\_\text{now}` | `\text{time_now}` | `_` 在 text mode 不合法 |
| 下標 | `\text{score}_i` | `\text{score_i}` | 下標必須在 `\text{}` 外 |

**多底線變數名**：每個英文詞獨立 `\text{}`，用 `\\_` 連接：

```latex
% 正確
\text{dna}\\_\text{r}\\_\text{score}_i

% 錯誤 — KaTeX 報錯 '_' allowed only in math mode
\text{dna_r_score}_i

% 也錯誤 — 單 escape 被 markdown 消耗，KaTeX 報錯 'Double subscripts'
\text{dna}\_\text{r}\_\text{score}_i
```

**區塊公式模板**：

```markdown
（空行）
$$
\text{RFM Score}_i = s(\text{dna}\\_\text{r}\\_\text{score}_i) + s(\text{dna}\\_\text{f}\\_\text{score}_i) + s(\text{dna}\\_\text{m}\\_\text{score}_i)
$$
（空行）
```

### Wiki Term 頁面 R 程式碼區塊 (DOC_R008)

每個 Term-*.md 頁面**必須**以「## R 程式碼實作」作為最後一個主要區塊，包含三部分：
1. **程式碼摘錄** — 從實際原始碼複製（不可改寫）
2. **白話解讀** — 3-5 點非技術語言說明
3. **程式碼來源** — blockquote 指向原始檔案

**Details**: `docs/en/part1_principles/CH19_documentation/rules/DOC_R008_wiki_term_r_code_section.qmd`

### 原則三層同步 (DOC_R009)

新增、修改、刪除任何原則時，**必須**同步更新三層：`.qmd`（權威來源）→ `llm/*.yaml`（AI 索引，含 `principle_count` 和 `hierarchy`）→ `.claude/rules/*.md`（快速參考）。順序不可顛倒。

**Details**: `docs/en/part1_principles/CH19_documentation/rules/DOC_R009_principle_triple_layer_sync.qmd`

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
- **DOC_R005**: Wiki Math Formula Syntax (Wiki 數學公式 KaTeX 語法)
- **DOC_R006**: Wiki Synchronization Trigger (儀表板改動必須同步 Wiki — Hook 自動提醒)
- **DOC_R007**: Claude Rules Writing Convention (Rules 檔案簡潔撰寫規範)
- **DOC_R008**: Wiki Term Page R Code Section (Term 頁面三段式 R 程式碼結構)
- **DOC_R009**: Principle Triple-Layer Synchronization (原則三層同步 — .qmd → llm/*.yaml → .claude/rules/*.md)
