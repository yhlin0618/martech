## Why

MAMBA 在 Posit Connect Cloud 部署時觸發 PostgreSQL runtime error(`syntax error at or near "AND"`,issue #365)。Root cause 是 Shiny 元件使用 `DBI::dbGetQuery(con, sql, params = list(...))` 的 `?` positional placeholder,DuckDB 吃這個語法但 PostgreSQL 必須用 `$1`/`$2`,導致在 Supabase PostgreSQL 後端直接執行時 runtime 爆炸。

Diagnose 之後發現真正問題是三個互相疊加的斷層,單純修 placeholder 無法解決:

1. **規範已存在但未被執行**: `DM_R023 Universal DBI Approach` 早在 2025-12-25 就規定「database reads must use `tbl2()`; raw SQL string queries are disallowed」,但 codebase 仍有 150+ 個 raw `DBI::dbGetQuery()` 呼叫,新寫的 code 也持續違反,純靠 code review 人力 barrier 擋不住
2. **`tbl2()` 本身有 DuckDB-specific 破窗**: `tbl2.DBIConnection` 在 `fn_tbl2.R:50-54` 有 dot-syntax 特例 `grepl("\\.", from) → paste0("SELECT * FROM ", from)`,這條 raw SQL 字串拼接 path 完全 bypass 了 dbplyr 的 identifier quoting,讓 `tbl2()` 本身就不是真正的 cross-driver。dplyr 作者反對這種寫法,canonical 的做法是 `dbplyr::in_schema()`
3. **無自動強制機制**: 沒有 lint / hook / CI 阻擋新寫的 `DBI::dbGetQuery(con, "...")` 進 codebase,規範是紙上規範

Issue #365 的 hot-fix(`dbGetQuerySafe()` wrapper 包 `DBI::sqlInterpolate`)只是治標 — 它讓 10 個 Shiny 元件能在 PostgreSQL 上執行,但 tbl2 破窗沒修、規範沒 enforce、剩下 150+ 個檔案隨時可能下一個爆炸。本次 change 處理底層問題,讓「跨 driver 統一查詢層」這件事從紙上規範落地到 runtime + enforcement。

## What Changes

1. **Refactor `tbl2.DBIConnection` 為 pure passthrough**: 刪除 `fn_tbl2.R:50-54` 的 dot-syntax 特例,改成 `dplyr::tbl(src, from, ...)`。其他 S3 methods(`.default`、`.data.frame`、`.tbl_df`、`.list`、`.character`、`.function`)完全不動,保留 universal protocol 的多型分派價值
2. **改寫 3 個 attached database 測試**: `test_attached_database.R`、`test_tbl2_attached.R`、`test_syntax_detection.R` 把 `tbl2(con, "mydb.table")` 改用 `tbl2(con, dbplyr::in_schema("mydb", "table"))`
3. **新增 PostgreSQL integration test**: `02_db_utils/tbl2/test_postgres.R`,用真實 PostgreSQL connection 驗證 `tbl2()` 的 cross-driver 行為,避免未來 regression
4. **遷移 10 個 Shiny 元件**: 從 `dbGetQuerySafe()` 改成 `tbl2() %>% filter() %>% collect()`,具體檔案見 Impact
5. **Deprecate `dbGetQuerySafe()`**: 函式 body 保留(避免立即 breaking),加 `.Deprecated("tbl2")` warning,宣告 3 個月後移除
6. **強化 `DM_R023`**: Core Requirement 升級為 `:::{.callout-critical}` 強制條款;新增 Section 5「Exceptions & Migration」列出允許 raw SQL 的情境(DDL/DML 用 `dbExecute()`、introspection 用 helper);revision_history 加 v1.2
7. **DOC_R009 三層同步**: `DM_R023.qmd`(en/zh 雙語)→ `llm/CH02_data.yaml` → `shared/global_scripts/00_principles/.claude/rules/02-coding.md` 新增「資料庫讀取規範」區段,引用 DM_R023 並給好/壞範例
8. **新增 Claude hook** `.claude/hooks/check-tbl2-compliance.sh`: PreToolUse on Edit/Write,偵測新增 `DBI::dbGetQuery(.*SELECT` pattern → advisory 提醒(non-blocking,與既有 `check-wiki-sync.sh`、`check-principle-sync.sh` 同層級)
9. **跨公司 E2E 驗證**: MAMBA、QEF_DESIGN、D_RACING 三家在遷移完成後都要跑一輪 E2E,比對 KPI 數字確保語意不變

## Capabilities

### New Capabilities

- `cross-driver-query-layer`: 定義 Shiny 和 Derivation 程式碼透過 `tbl2()` 與 dbplyr 存取資料庫的契約。這個 capability 描述:(a) `tbl2()` 的 universal protocol 與 DBIConnection passthrough 語意、(b) 禁止的 pattern(raw SQL with positional placeholders for reads)、(c) 允許 raw SQL 的 exception 清單(DDL/DML 透過 `dbExecute()`、driver-specific introspection 透過 helper 函式)、(d) enforcement 機制(Claude hook advisory + `DM_R023` 原則)、(e) 支援的 driver 範圍(DuckDB、PostgreSQL,未來可擴充)

### Modified Capabilities

(none — 無既有 capability 與此重疊)

## Impact

**Affected source code(Shiny 遷移)**:

- `shared/global_scripts/10_rshinyapp_components/macro/dashboardOverview/dashboardOverview.R`(2 occurrences)
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerLifecycle/customerLifecycle.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerStatus/customerStatus.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerActivity/customerActivity.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerValue/customerValue.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerStructure/customerStructure.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/customerExport/customerExport.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/marketingDecision/marketingDecision.R`
- `shared/global_scripts/10_rshinyapp_components/tagpilot/rsvMatrix/rsvMatrix.R`

**Affected infrastructure**:

- `shared/global_scripts/02_db_utils/tbl2/fn_tbl2.R` — `tbl2.DBIConnection` 改寫
- `shared/global_scripts/02_db_utils/tbl2/test_attached_database.R` — 改用 `in_schema()`
- `shared/global_scripts/02_db_utils/tbl2/test_tbl2_attached.R` — 改用 `in_schema()`
- `shared/global_scripts/02_db_utils/tbl2/test_syntax_detection.R` — 改用 `in_schema()`
- `shared/global_scripts/02_db_utils/tbl2/test_simple.R` — 改用 `in_schema()`
- `shared/global_scripts/02_db_utils/tbl2/test_postgres.R` — **新建** PostgreSQL integration test
- `shared/global_scripts/04_utils/fn_db_get_query_safe.R` — 加 `.Deprecated()` warning

**Affected principles(三層同步)**:

- `shared/global_scripts/00_principles/docs/en/part1_principles/CH02_data_management/rules/DM_R023_universal_dbi_approach.qmd` — 強化為 callout-critical + 新增 Exceptions 章節
- `shared/global_scripts/00_principles/docs/zh/part1_principles/CH02_data_management/rules/DM_R023_universal_dbi_approach.qmd` — 中文同步
- `shared/global_scripts/00_principles/llm/CH02_data.yaml` — AI 索引同步
- `shared/global_scripts/00_principles/.claude/rules/02-coding.md` — 新增「資料庫讀取規範」區段

**Affected automation**:

- `.claude/hooks/check-tbl2-compliance.sh` — **新建** PreToolUse advisory hook
- `.claude/settings.json` 或等效 hook 註冊檔 — 註冊新 hook

**Affected repositories(跨公司 E2E)**:

- `MAMBA/` — E2E validation(PostgreSQL production target)
- `QEF_DESIGN/` — E2E validation
- `D_RACING/` — E2E validation

**Affected issues**:

- #369 — 本 change 的 motivation issue
- #365 — 觸發事件的 MAMBA 部署復原
- 新開 tracking issue(change archive 時建立)— 150+ 個 non-Shiny `DBI::dbGetQuery()` 的漸進遷移,**不在本 change 範圍**

**Affected users**:

- 開發者:寫新 R 檔時會被 hook advisory 提醒;遷移期間 `dbGetQuerySafe()` 會出現 deprecation warning
- Production Shiny 使用者(MAMBA/QEF_DESIGN/D_RACING):行為不變,只是 driver 相容性提升

**Rollback path**:

- 若遷移後某個 Shiny 元件 KPI 數字異常,單獨 revert 該元件的 tbl2 改寫(`git revert <commit>`),其他元件不受影響
- `dbGetQuerySafe()` 在 3 個月 deprecation 期內仍可用作 fallback,不會立即刪除
