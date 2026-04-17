## Context

#### 觸發事件

MAMBA 於 2026-04 部署到 Posit Connect Cloud(以 Supabase PostgreSQL 為 app_data backend)時,Shiny runtime 直接 fail:

```
ERROR: syntax error at or near "AND"
LINE 1: ...FROM df_macro_monthly_summary WHERE platform_id = ? AND produc...
```

Root cause 是 10 個 Shiny 元件使用 `DBI::dbGetQuery(con, sql, params = list(...))` 搭配 `?` positional placeholder。DuckDB(開發與舊 production 環境)接受這個語法,但 PostgreSQL 強制 `$1`/`$2` numbered placeholder,兩者不相容。

Hot-fix(issue #365)引入 `dbGetQuerySafe()` wrapper,內部用 `DBI::sqlInterpolate` 做預處理,解決了 10 個元件的 immediate fail,但沒觸及三個更深層的問題。

#### 現況盤點

| 面向 | 狀況 |
|---|---|
| `DM_R023 Universal DBI Approach` | 2025-12-25 v1.1 已規定 read 必須用 `tbl2()`,raw SQL 被禁 |
| `tbl2()` 既有實作 | 存在於 `02_db_utils/tbl2/fn_tbl2.R`,polymorphic 分派處理 DBIConnection、data.frame、list、character、function |
| `tbl2.DBIConnection` 破窗 | Lines 50-54 有 dot-syntax 特例,拼接 `SELECT * FROM ${from}` raw SQL,bypass dbplyr identifier quoting |
| `tbl2()` 使用率 | ~50 檔案 |
| `DBI::dbGetQuery()` 使用率 | ~150 檔案(含 read + write + DDL/DML 混雜) |
| `dbGetQuerySafe()` 使用率 | 10 Shiny 元件(hot-fix 引入) |
| `dbplyr::in_schema()` 使用率 | 0 檔案 |
| 既有 hook 生態 | 5 個 advisory hook(`check-wiki-sync.sh`、`check-principle-sync.sh` 等) |
| Production DB 目標 | DuckDB(本地開發、舊 production)+ PostgreSQL/Supabase(新 Posit Connect production) |

#### Stakeholders

- **開發者**: 寫新 Shiny 元件、ETL、derivation 時會被新規範影響
- **Production 使用者(客戶)**: MAMBA、QEF_DESIGN、D_RACING 三家的 Shiny app 終端使用者
- **未來的公司**: WISER、kitchenMAMA、URBANER 等 onboarding 時會受惠於已修好的 baseline

#### 限制

- **不能 breaking change `dbGetQuerySafe()`**: 10 個 Shiny 元件還在用,立即刪除會讓 MAMBA production 回到爆炸狀態
- **不能 breaking change `tbl2()` 的 polymorphic dispatch**: data.frame / list / file path 的 S3 methods 是核心 value,許多測試和 mock 基礎設施依賴
- **跨公司同步壓力**: `shared/global_scripts/` 變更會同步到三家公司,必須有 E2E 回歸保護
- **deadline 壓力**: MAMBA 客戶展示在即(Monday),不能拖太久

---

## Goals / Non-Goals

**Goals:**

- 讓 `tbl2()` 真正 cross-driver(DuckDB + PostgreSQL 都走 dbplyr 翻譯層)
- 強化既有 `DM_R023` 規範,讓它從「紙上規定」變成「runtime enforcement」
- 遷移 10 個 Shiny 元件到 `tbl2()` pattern,解除對 `dbGetQuerySafe()` 的依賴
- 建立 advisory hook 阻擋未來新增的 raw SQL read pattern
- 三家公司 E2E 驗證後才算完成

**Non-Goals:**

- **不遷移 non-Shiny 的 150+ 個 `DBI::dbGetQuery()` 呼叫**: ETL / derivation / 04_utils 等跑在 DuckDB-only 環境,沒有 cross-driver 壓力,另開 tracking issue 漸進處理
- **不做 `dbExecuteSafe()` wrapper**: write 操作(`INSERT`/`UPDATE`/`CREATE`)維持 `dbExecute()` + raw SQL,dbplyr 對寫入支援不完整,wrapper 是 YAGNI
- **不立新原則 `DM_R062`**: 強化既有 `DM_R023`,避免 principle space fragmentation
- **不做 hard error lint**: hook 只做 advisory 提醒,與既有 `check-wiki-sync.sh` 同層級,3 個月後再評估是否升級
- **不改 `tbl2()` 的 polymorphic dispatch**: `.data.frame`、`.list`、`.character`、`.function` 等 S3 methods 完全不動
- **不支援 dot-syntax 便捷寫法**: `tbl2(con, "mydb.table")` 這種寫法將不被支援,強制使用 `dbplyr::in_schema("mydb", "table")`

---

## Decisions

### Refactor tbl2.DBIConnection to pure passthrough

**Decision**: `tbl2.DBIConnection` 改寫成 `dplyr::tbl(src, from, ...)` 的純粹 passthrough,刪除 `fn_tbl2.R:50-54` 的 dot-syntax 特例。

**Rationale**:
- 現有 dot-syntax 拼接 raw SQL(`paste0("SELECT * FROM ", from)`)完全繞過 dbplyr 的 identifier quoting,不是真 cross-driver
- Audit 結果:production code 0 處使用 dot-syntax,只有 3 個 test 檔案依賴這個 path
- 讓 `tbl2()` 對 DBIConnection 的行為與 `dplyr::tbl()` 完全一致,新人不需學兩套規則

**Alternatives considered**:
- **Option B (內部 parse + `dbplyr::in_schema()`)**: 把 `"mydb.table"` 拆開後走 `in_schema()`。拒絕理由:帶入 string-parsing 副作用(例如 table 名稱含 `.` 會 silent break)、跟 `dplyr::tbl()` 行為分岔、需要處理 cascade of special cases(2-part、3-part、quoted、escaped)
- **完全刪除 `tbl2.DBIConnection`**: 讓 DBIConnection 走 `tbl2.default`。拒絕理由:破壞 polymorphic 語意(DBIConnection 應該有明確 method,不該 fall through)

### Preserve tbl2 polymorphic dispatch for non-DB sources

**Decision**: `tbl2.data.frame`、`tbl2.tbl_df`、`tbl2.list`、`tbl2.character`、`tbl2.function`、`tbl2.default` 完全不動。

**Rationale**:
- `dplyr::tbl()` 不接 data.frame,但測試 / mock 場景需要「同一個函數名既能接真 DB 也能接 df」 — 這是 tbl2 存在的 motivation
- 這些 methods 彼此獨立,跟 DBIConnection 的 dot-syntax 是 orthogonal concerns
- Universal protocol(一個函式接多種 source,語意 = 「從 src 取出 from 這個 table」)的 abstraction value 成立

**Alternatives considered**:
- **分裂成 `tbl2_lazy`(只接 DB)+ `tbl2_eager`(接 df/list/file)**: 拒絕理由:破壞既有 ~50 個 call sites,且語意統一的優點消失
- **完全移除 `tbl2()` 改用 `dplyr::tbl` + mock DuckDB**: 拒絕理由:每個測試都要建立臨時 DuckDB,開銷大於收益

### Strengthen DM_R023 instead of creating DM_R062

**Decision**: 強化既有 `DM_R023 Universal DBI Approach`(升 v1.2),不新立 `DM_R062`。

**Rationale**:
- `DM_R023` 2025-12-25 v1.1 revision 已經寫了 tbl2-only reads,這次是「執行強度升級」,不是「語意改變」
- 相關原則已有 7 條(DM_R002/003/011/012/013/014/023),新立 DM_R062 會造成 principle space fragmentation,讀者要搞清楚「哪個才是 canonical」
- Revision history 的連續性保留設計演進脈絡

**具體改動**:
- Core Requirement 區段升級為 `:::{.callout-critical}` 強制條款
- 新增 Section 5「Exceptions & Migration」,明列 3 種合法例外(DDL/DML、introspection、legacy transition)
- 新增 v1.2 revision 到 revision_history

**Alternatives considered**:
- **新立 DM_R062**: 拒絕理由見 rationale
- **不修原則只改 hook**: 拒絕理由:規範與執行必須對齊,只改執行不改規範等於承認原則可被忽略

### Advisory hook for non-blocking enforcement

**Decision**: `.claude/hooks/check-tbl2-compliance.sh` 作為 PreToolUse on Edit/Write 的 advisory hook,偵測新增 `DBI::dbGetQuery(.*SELECT` pattern 時給出提醒但不阻擋。

**Rationale**:
- 與既有 `check-wiki-sync.sh`、`check-principle-sync.sh` 同層級,開發者已熟悉這種模式
- Hard error 會阻擋 emergency hotfix(下次 production 又爆時需要時間繞過 hook 的機制)
- 3 個月觀察期後可評估是否升級為 hard error

**Alternatives considered**:
- **Hard error from day 1**: 拒絕理由:增加 dev friction,可能導致開發者集體繞過 hook
- **CI-only enforcement**: 拒絕理由:CI 回饋延遲大,問題在 PR 階段才被發現,修改成本高
- **No enforcement, rely on code review**: 拒絕理由:已證實沒用 — `DM_R023` v1.1 存在 4 個月仍有新 violation 持續出現

### Keep write operations on raw SQL and dbExecute (YAGNI)

**Decision**: 寫入操作(`INSERT`/`UPDATE`/`CREATE TABLE`)保持現狀,使用 `DBI::dbExecute()` + raw SQL,**不**做 `dbExecuteSafe()` wrapper。

**Rationale**:
- 既有 100+ 處 `dbExecute()` 使用沒有 cross-driver bug 報告
- 寫入語法的 driver 差異(DuckDB `COPY` vs PostgreSQL `COPY FROM`)通常不是 placeholder 問題,而是整段語法差異,wrapper 抽象化會遮蔽細節
- Shiny 不寫 `app_data`(寫入由 ETL/DRV pipeline 在 DuckDB-only 環境處理)
- dplyr 的 `rows_insert()`/`rows_update()` 對 dbplyr 支援仍 experimental

**Alternatives considered**:
- **做 `dbExecuteSafe()` 搭配 `sqlInterpolate`**: 拒絕理由:YAGNI,目前沒有跨 driver write 場景
- **強制所有 write 都走 dbplyr 的 `rows_*()` 函數**: 拒絕理由:dbplyr write API 仍實驗性,不適合 production

### Limit scope to Shiny components

**Decision**: 本 change 只處理 10 個 Shiny 元件的遷移。其餘 150+ 個 non-Shiny `dbGetQuery()` 呼叫(`04_utils/`、`16_derivations/`、`98_test/` 等)**另開 tracking issue 漸進處理**,不塞進這個 change。

**Rationale**:
- Shiny 元件是唯一面對 PostgreSQL 的 production path(`app_data` backend 可以是 PostgreSQL/Supabase)
- Non-Shiny 程式碼跑在 DuckDB-only 環境(ETL pipeline、`_targets` orchestration),沒有 cross-driver 壓力
- 避免 change 變成 epic,保持可交付性
- 漸進遷移可以藉由 advisory hook 的自然促進逐步收斂

**Alternatives considered**:
- **一次全部改寫**: 拒絕理由:範圍過大,可能耗時數月,change 難以 close
- **只改 Shiny 不處理 non-Shiny**: 拒絕理由:違反 DM_R023 的普遍性,需要至少有 tracking mechanism

### Driver-specific introspection via helper functions

**Decision**: PRAGMA、`information_schema`、`EXPLAIN`、`SET` 等 driver-specific introspection **不**列為 raw SQL 例外。未來需要時,在 `02_db_utils/` 新增 helper 函數(例如 `dbPragma()`、`dbColumnInfo()`),內部根據 `DBI::dbGetInfo(con)` 判斷 driver 再跑對應語法。

**Rationale**:
- 允許「raw SQL 例外」會被濫用,三個月後 codebase 會出現「這是 introspection 例外」的名義繞過規範
- Helper 函數集中 driver branching,單一修改點
- `fn_duckdb_query_patterns.R` 已有 12 個 DuckDB-specific 函數的 pattern 可參考

**本 change 不需要建立這些 helper**(Shiny 元件目前沒有 introspection 需求),只在 `DM_R023` 的 Exceptions 章節預先描述這個方向,留給未來需要時實作。

---

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| dbplyr 翻譯後的 SQL 效能不如 raw SQL | 遷移前後對每個 Shiny 元件做 KPI 載入時間 benchmark;退化 >20% 則列入例外並記錄 |
| 3 家公司 E2E 覆蓋不完整,遷移後 KPI 數字錯誤 | 逐個元件遷移 + 逐個跑 E2E,不一次改全部;使用 shinytest2 snapshot 比對 |
| `tbl2()` 在真實 PostgreSQL 上有未發現的 edge case | 新增 `test_postgres.R` integration test 先驗證再遷移 Shiny |
| Advisory hook 觀察 3 個月後 compliance 沒改善 | 評估升級為 hard error,或改為 CI block(change archive 時記錄此追蹤事項) |
| 3 個測試檔改用 `in_schema()` 後可能觸發 dbplyr 對 DuckDB ATTACH 的 corner case | 先跑測試確認 `in_schema("attached_db", "table")` 對 DuckDB 是否正確翻譯;若不行則用 `dplyr::sql()` escape hatch 並加明確註解 |
| `dbGetQuerySafe()` deprecation 期間有人繼續新加使用 | Hook 偵測 `dbGetQuerySafe` 也當作 advisory 警告,推向 `tbl2()` |
| 跨公司改動造成 MAMBA / QEF_DESIGN / D_RACING 回歸 | `shared/global_scripts/` 的每個 commit 觸發三家 E2E(手動或排程),不合格則 revert |

---

## Migration Plan

**Phase 1: Infrastructure(前置)**

1. Refactor `tbl2.DBIConnection` 為 pure passthrough(deletes 5 lines)
2. 改寫 4 個 tbl2 測試檔使用 `dbplyr::in_schema()`
3. 新增 `test_postgres.R` 驗證 tbl2 對 PostgreSQL 的行為
4. 跑所有 tbl2 測試,確認 baseline 綠燈

**Phase 2: Principle + Hook(規範層)**

5. 強化 `DM_R023.qmd`(en/zh)升 v1.2,加 callout-critical 和 Exceptions 章節
6. 同步 `llm/CH02_data.yaml` 和 `.claude/rules/02-coding.md`(DOC_R009 三層同步)
7. 建立 `.claude/hooks/check-tbl2-compliance.sh`,註冊到 `.claude/settings.json`
8. 跑測試:故意在新檔案寫 `DBI::dbGetQuery(con, "SELECT...")`,確認 hook 有 fire

**Phase 3: Shiny Migration(逐個元件)**

9. 遷移 `dashboardOverview.R`(2 occurrences)→ 跑 MAMBA E2E → 驗證 KPI 數字
10. 遷移 `customerLifecycle.R` → E2E → 驗證
11. 遷移 `customerStatus.R` → E2E → 驗證
12. 遷移 `customerActivity.R` → E2E → 驗證
13. 遷移 `customerValue.R` → E2E → 驗證
14. 遷移 `customerStructure.R` → E2E → 驗證
15. 遷移 `customerExport.R` → E2E → 驗證
16. 遷移 `marketingDecision.R` → E2E → 驗證
17. 遷移 `rsvMatrix.R` → E2E → 驗證

**Phase 4: Deprecation + Cross-company validation**

18. `fn_db_get_query_safe.R` 加 `.Deprecated("tbl2")` warning
19. 跑 MAMBA 完整 E2E suite(所有 tab)
20. 跑 QEF_DESIGN 完整 E2E suite
21. 跑 D_RACING 完整 E2E suite
22. 開 tracking issue 記錄 150+ 個 non-Shiny `dbGetQuery()` 的後續遷移

**Phase 5: Deploy**

23. Commit + push(觸發 MAMBA Posit Connect auto-deploy)
24. Posit Connect 實際驗證 Shiny 能在 PostgreSQL 上正常執行

#### Rollback Strategy

- **單一元件出問題**: `git revert <commit>` 該元件的遷移 commit,其他元件不受影響。`dbGetQuerySafe()` 仍在 deprecation 期內可用作 fallback
- **tbl2 refactor 出問題**: `git revert` tbl2 的 refactor commit,恢復 dot-syntax 特例(production 沒人用所以無副作用)
- **hook 太吵**: 直接 disable hook(從 `.claude/settings.json` 移除),不影響 production
- **規範改動要撤回**: `git revert` DM_R023 的 v1.2 commit,回到 v1.1

---

## Open Questions

(無 — 所有 open questions 已在 `/spectra-discuss` 階段對齊)

先前留下的 7 個 open questions 在 discuss 過程已逐一解決:
- Q1 `dbGetQuerySafe()` 命運 → 3 個月 deprecation 後移除
- Q2 例外清單範圍 → introspection 用 helper 函數,不開 raw SQL 後門
- Q3 Lint 嚴格度 → advisory only,3 個月後評估升級
- Q4 Write 操作策略 → YAGNI,保持 `dbExecute()` + raw SQL
- Q5 Acceptance criteria → Phase 1-4 完成 + 三家 E2E 綠燈
- Q6 跨公司同步 → MAMBA + QEF_DESIGN + D_RACING 三家都要驗
- Q7 DM_R023 vs DM_R062 → 強化既有 DM_R023,不新立
