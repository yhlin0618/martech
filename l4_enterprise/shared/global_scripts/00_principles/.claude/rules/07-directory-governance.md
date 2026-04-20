# 建立新目錄或檔案時

**使用時機**: 需要建立新目錄或檔案時

**詳細規範**: `docs/en/part1_principles/CH01_structure_organization/principles/SO_P018_governance_spec.yaml`

---

## 核心原則 (SO_P018)

**嚴格禁止**在 `00_principles/` 或 `global_scripts/` 隨意建立新目錄或檔案。

---

## 00_principles/ 允許的目錄

```
.claude/        # Claude 配置
CHANGELOG/      # 變更記錄 (reports/, archive/; issues/ 僅 legacy)
archive/        # 歸檔
docs/           # 文檔 (en/, zh/, wiki/ — Wiki 為獨立 Git repo，已 .gitignore)
llm/            # LLM 優化格式
```

**禁止建立**: `utils/`, `templates/`, `scripts/`, 或任何其他目錄

---

## 00_principles/ 允許的根目錄檔案

| 類別 | 檔案 |
|------|------|
| **系統** | `.gitignore`, `.quartoignore` |
| **Quarto** | `_quarto.yml`, `_quarto-en.yml`, `_quarto-zh.yml`, `index.qmd`, `styles.css`, `parameters.yaml` |
| **文件** | `INDEX.md`, `README.md`, `QUICK_REFERENCE.md`, `NAVIGATION.md` |

---

## 00_principles/ 禁止的檔案模式

| 模式 | 應放位置 |
|------|----------|
| `ISSUE_*.md` | GitHub Issues（不要在本地新建 issue 檔） |
| `*_REPORT.md` | `CHANGELOG/reports/` |
| `*_DEBUG*.md` | `CHANGELOG/reports/`（並連結對應 GitHub issue） |
| `MIGRATION_*.md` | `CHANGELOG/migrations/` |
| `README_*.md` | `archive/` |
| `*.yaml` (非允許清單) | `llm/` |

---

## global_scripts/ 允許的目錄

| 編號 | 目錄 | 用途 |
|------|------|------|
| 00 | principles | 原則系統 |
| 01 | db | 資料庫連線 |
| 02 | db_utils | 資料庫工具 |
| 03 | config | 配置載入 |
| 04 | utils | **通用工具 (放這裡!)** |
| 05 | etl_utils | ETL 工具 |
| 10 | rshinyapp_components | Shiny 元件 |
| 11 | rshinyapp_utils | Shiny 工具 |
| 22 | initializations | 初始化 |
| 23 | deployment | 部署 |
| 27 | company_info | 公司 metadata(brand_name, env defaults 等) |
| 28 | migration_scripts | Schema migrations |
| **29** | **company_examples** | **公司專用 code cookbook(見下方特別規則)** |
| 30 | global_data | 全域參數、資料 |
| 98 | test | 測試 |
| 99 | archive | 歸檔 |

---

## Chapter 29: Company Examples Cookbook(特別規則)

`29_company_examples/` 是**公司專用 code 的 cookbook**,不是 shared library。

### 結構

```
29_company_examples/
├── README.md                ← cookbook vs library 設計哲學
├── _template/               ← 新公司 onboarding 起家樣板
├── {company_lowercase}/     ← 每家公司獨立 namespace
│   ├── README.md            ← 必要 — 公司特殊性說明
│   ├── notes/               ← lessons-learned(YYYY-MM-DD_topic.md)
│   └── {numbered_chapter}/  ← 鏡射根層 numbered chapter(e.g. 02_db_utils/)
```

### 規則

- **Namespace 鏡射**: 公司專用 `fn_ensure_tunnel.R` 放 `mamba/02_db_utils/` 而不是 flat `mamba/`
- **禁止跨公司 source()**: X 公司的 script 禁止 `source("29_company_examples/Y/...")`,違反要 copy + adapt 到自己 namespace 或 promote 到 generic chapter
- **Promotion path**: 2+ 公司有類似 helper 時,走 rule of three promote 到 generic chapter(e.g. `02_db_utils/`)
- **新公司 onboarding**: `/new-company` skill 自動 copy `_template/` 建立新 namespace

### 何時用 29 vs 其他 chapter

| 情境 | 放哪 |
|---|---|
| 所有公司都能用的 util | `04_utils/` |
| 所有公司都能用的 db helper | `02_db_utils/` |
| **只有一家公司用,預期其他公司會參考** | **`29_company_examples/{company}/`** |
| 一家公司用的 metadata(brand、config defaults) | `27_company_info/` |
| 一家公司用的 ETL script | `update_scripts/ETL/{platform}/` (不在 global_scripts,在 update_scripts subrepo) |

### 相關原則

- **SO_P018**: Directory Governance — chapter 29 的正式定義
- **MP122**: Penta-Track Subrepo Architecture — 29 在 Track 1(Framework)

---

## 檔案放置決策樹

```
需要放新檔案？
├── 是工具函數(通用)？ → 04_utils/fn_*.R
├── 是公司專用程式(預期他公司會參考)？ → 29_company_examples/{company}/{chapter}/
├── 是 Shiny 元件？ → 10_rshinyapp_components/{name}/
├── 是 ETL 輔助？ → 05_etl_utils/
├── 是測試？ → 98_test/
├── 是原則文件？ → 00_principles/docs/en/part1_principles/
├── 是範本？ → templates/TEMPLATE_*.md
├── 是 Issue（追蹤/狀態）？ → GitHub Issues
├── 是 Issue 相關執行報告？ → 00_principles/changelog/reports/
├── 是遷移指南？ → 00_principles/changelog/migrations/
└── 都不是？ → 詢問使用者應放哪裡
```

---

## 建立新目錄的流程

1. **先檢查**現有目錄是否已滿足需求
2. **如果需要新目錄**，必須：
   - 更新 SO_P018 原則
   - 更新 SO_P018_governance_spec.yaml
   - 建立 CHANGELOG 記錄
   - 取得明確批准
3. **絕不**自行決定建立新目錄

---

## 常見錯誤

| 錯誤做法 | 正確做法 |
|----------|----------|
| 建立 `00_principles/utils/` | 放到 `04_utils/` |
| 建立 `00_principles/templates/` | 放到 `templates/` |
| 建立 `global_scripts/helpers/` | 放到 `04_utils/` |
| 建立無編號目錄 | 使用現有編號目錄 |
| 在 repo 建立本地 issue 檔 | 改在 GitHub Issues 建立 |
| 在根目錄放 `*.yaml` | 放到 `llm/` |
