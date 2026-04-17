## Context

MAMBA Posit Connect production dashboard 在 #371/#374 部署後出現多重故障:7+ 元件呈現空白資料,2 個明確的 PostgreSQL 不相容錯誤。Issue #376 的 diagnosis 證實這不是單一 bug,而是三層結構性問題疊加。

**現況**:

- `app_data.df_dna_by_customer` 在 MAMBA 本地 schema 缺 `p_alive` 和 `btyd_expected_transactions` 兩欄(用 `db_describe` 直接驗證,從 `cri` 跳到 `nrec_prob` → `nrec` → `nes_value`,中間缺漏)
- `fn_create_df_dna_by_customer_table.R:41` 的 source-of-truth schema **包含**這兩欄,但 MAMBA 的 `app_data.duckdb` 是在 BTYD #211 整合**之前**建立的
- `fn_D01_04_core.R:99-103` 的 `select_table_columns()` 用 `intersect(names(df), target_cols)` 把 `customer_dna` 投影到 `app_data` 表,新欄位被**靜默 drop**
- Pipeline 跑「成功」,沒有任何 warning;upload 到 Supabase 也無聲帶走 broken schema
- `customerRetention.R` line 175、329 用 `DBI::dbGetQuery()` 寫 raw SQL,呼叫 `MEDIAN()`(DuckDB-only,PostgreSQL 沒有 native median)
- 還有 8 個 Shiny components(`customerAcquisition`、`revenuePulse`、`customerEngagement`、`comprehensiveDiagnosis × 2`、`worldMap`、`macroTrends`、`reportIntegration`)還在用 raw `DBI::dbGetQuery()`,違反 DM_R023 v1.2,任何 DuckDB-only 函數都會是下個 production 地雷

**約束**:

- Production unblock 是緊急優先,但「我想要盡量修改的完整」要求治本同時做
- DM_R023 v1.2 強制禁止 raw SQL 讀取(non-Shiny migration 是 #370,但 Shiny 元件**已經**在 #369 範圍且必須完成)
- MP154 Side Effect Defense:操作不可靜默改變資料語意 — silent column drop 是這條原則的直接違反
- Driver-agnostic 是核心要求:本地 DuckDB 開發 + Posit Connect Supabase production 都必須能跑同一份程式碼
- 不可以用「DROP table 直接 SQL ALTER」hack — 必須從 source-of-truth (D00 init + fn_create_*.R) 修起,讓其他公司部署時不會踩同樣坑

**Stakeholders**:

- MAMBA 老闆 / 客戶(看不到 dashboard,production blocking)
- 開發團隊(future schema 變更時不想再被 silent drop 咬)
- D_RACING、QEF_DESIGN、URBANER 等其他公司部署(同樣會繼承 fix)

## Goals / Non-Goals

**Goals:**

1. **Unblock MAMBA production dashboard** — `dashboardOverview`、`customerRetention`、`customerLifecycle`、`customerActivity` 等 7+ 元件在 Supabase 後端能正常顯示資料(無 PostgreSQL error)
2. **D01_04 投影層加上 schema migration discipline** — 投影前先 ensure target table schema 含所有 expected columns,缺欄位時 ALTER TABLE 加入(idempotent)
3. **`select_table_columns()` 變成 defensive function** — 偵測到 `customer_dna` 有 column 不在 target table 時 emit warning + 列出被影響的欄位,讓未來 schema drift 不再 silent
4. **完成 #369 在 Shiny 層的 raw SQL → tbl2 migration** — 9 個元件全數遷移,完整滿足 DM_R023 v1.2
5. **driver-agnostic 翻譯** — `customerRetention.R` 的 `MEDIAN()` 用 R `median()` 透過 dbplyr 翻譯,DuckDB 和 PostgreSQL 都能跑

**Non-Goals:**

- E2E test infrastructure(Supabase test profile + shinytest2 staging)— 另開 spec
- 上游 ETL 客戶資料量稀疏問題 — `df_dna_by_customer` 只有 113 unique customers 是上游問題,屬於 #371 範圍
- Non-Shiny `dbGetQuery()` migration(150+ files in `04_utils/`、`16_derivations/`、`98_test/`)— #370 範圍
- 一般化的 cross-driver helper library(例如 `cross_driver_median()`)— short term 用 dbplyr 就夠,long term 是另一個 refactor
- D02 / D03 / D05 的 schema migration 一致性 audit — 本 change 只 focus `df_dna_by_customer`,但 design 中會記錄 audit 為 follow-up
- UI 改善「資料量不足」友善 message — 屬於 UX 改進,獨立 issue

## Decisions

### Decision 1: Idempotent ALTER TABLE migration helper

**選擇**:在 D01_04 投影之前呼叫 `ensure_dna_schema()` helper,該函數讀取 `fn_create_df_dna_by_customer_table.R` 的 source-of-truth schema,跟 `app_data.df_dna_by_customer` 現有 schema 比對,缺欄位時 `ALTER TABLE ... ADD COLUMN` 加入(預設 NULL)。

**Rationale**:

- DROP + recreate 會丟失資料(其他平台的 rows),需要先 backup + restore,複雜且容易出錯
- ALTER TABLE 是 idempotent — 第一次跑會加欄位,之後跑都是 no-op
- 跟 `select_table_columns()` 的修改互相加固:即使 helper 沒被呼叫,select_table_columns 還是會 warn
- 適用於未來任何 schema 變更:新增 derivation 欄位時只要更新 `fn_create_*.R` source-of-truth,helper 自動同步

**Alternatives considered**:

- (a) **DROP + recreate**:資料丟失風險、不安全
- (b) **手動 SQL migration script in 28_migration_scripts/**:每次 schema 變更要手寫 script,容易遺漏。idempotent helper 自動化更安全
- (c) **完全不改 D01_04,只在 D00 init 加 ALTER TABLE**:D00 通常只在 cold-start 跑,無法捕捉 production 已部署的 instances。應該在 D01_04 每次跑時 ensure schema,才是真的 self-healing

### Decision 2: select_table_columns warns instead of failing

**選擇**:`select_table_columns()` 在 `intersect()` 之後檢查是否有欄位被 drop,若有則 `warning()` 列出被 drop 的欄位名稱、提示 "this likely indicates schema drift; run ensure_<table>_schema() to migrate"。**不 stop()**,不 fail pipeline。

**Rationale**:

- 完全 fail (stop) 會讓 D01_04 立刻 broken,即使 schema migration helper 已經會自動修。warning 給予 self-healing 機會
- Silent skip 是現況,違反 MP154 — 必須改
- Warning 會出現在 pipeline log + Posit Connect log,容易發現
- 配合 Decision 1 的 `ensure_dna_schema()`,雙保險:helper 應該已經把欄位補齊,如果 warning 還出現代表 helper 沒被呼叫或 source-of-truth 跟 helper 不一致

**Alternatives considered**:

- (a) **`stop()` on schema drift**:太激烈,會 block production pipeline。應該讓 `ensure_dna_schema()` 是 primary fix,warning 是 last-line defence
- (b) **Auto ALTER TABLE in `select_table_columns()`**:把 schema-altering 邏輯放進 projection helper 違反單一職責,而且 `select_table_columns` 沒有 source-of-truth schema 的 reference

### Decision 3: customerRetention dbplyr median translation

**選擇**:把 `customerRetention.R:172-200` 和 `:320-360` 的 raw SQL 改寫成 `tbl2() %>% group_by() %>% summarise(median_ipt = median(ipt, na.rm = TRUE)) %>% collect()`。讓 dbplyr 自動翻譯成 driver-specific SQL(DuckDB 用 `MEDIAN()`,PostgreSQL 用 `percentile_cont(0.5) WITHIN GROUP (ORDER BY ipt)`)。

**Rationale**:

- 這正是 dbplyr / DM_R023 v1.2 的核心目的:R 語意層 → driver-specific SQL
- 完全 driver-agnostic,本地 + production 用同一份 R code
- 自動處理 NULL handling、CASE WHEN 等子句(原本 raw SQL 用 `MEDIAN(CASE WHEN ni > 1 AND ipt > 0 THEN ipt END)`,在 dplyr 寫法是 `median(ifelse(ni > 1 & ipt > 0, ipt, NA), na.rm = TRUE)` 或先 filter)

**Alternatives considered**:

- (a) **改成 PostgreSQL 專用 `percentile_cont`**:破壞 driver-agnostic 原則,本地 DuckDB 開發環境會出錯
- (b) **建一個 cross-driver `db_median()` helper**:over-engineering,dbplyr 已經在做這件事
- (c) **保留 raw SQL 但加 driver detection 寫雙版本**:醜、難維護、違反 DM_R023

### Decision 4: Mechanical 1:1 raw SQL migration for 8 components

**選擇**:其餘 8 個 components(`customerAcquisition`、`revenuePulse`、`customerEngagement`、`comprehensiveDiagnosis × 2`、`worldMap`、`macroTrends`、`reportIntegration`)的 raw SQL 改寫**只是 mechanical translation**,不重新設計 query 邏輯。先把 SELECT/JOIN/WHERE/GROUP BY 用 tbl2 + dplyr 表達,先讓本地 DuckDB 跑出與舊版相同的結果,再 deploy 到 Posit Connect。

**Rationale**:

- 這 8 個元件的 SQL 不是本 change 的 root cause,只是預防地雷
- 重設計 query 會讓本 change scope 失控
- Mechanical 改寫降低 regression 風險
- 跟 `customerRetention` 一樣,任何 DuckDB-only 函數透過 dbplyr 自動翻譯

**Alternatives considered**:

- (a) **延後 8 個元件遷移到後續 issue**:user 明確要求「盡量修改的完整」,而且這些元件已經是 #369 的 backlog,不應再延
- (b) **先做 audit 列出所有 DuckDB-only 函數**:over-engineering,直接遷移更快

### Decision 5: Schema migration helper location 28_migration_scripts

**選擇**:`fn_ensure_dna_schema.R` 放在 `shared/global_scripts/28_migration_scripts/`,跟其他 schema migration 工具同處。

**Rationale**:

- `28_migration_scripts/` 在 SO_P018 governance 是專門放 schema migration 的目錄
- 跟 `01_db/`(table creation source-of-truth)分開:01_db 定義 schema,28 負責讓現有 instance 對齊 schema
- 跟 `02_db_utils/`(generic db utilities)分開:這個 helper 是針對 `df_dna_by_customer` 特定的,不是 generic util

**Alternatives considered**:

- (a) **放 `01_db/dna_by_customer/`**:跟 `fn_create_df_dna_by_customer.R` 同處,但 01_db 應該只負責定義,不負責 migration
- (b) **放 `02_db_utils/`**:這是針對特定 table 的 helper,不夠 generic
- (c) **放 `04_utils/`**:跟一般工具混在一起會難找

### Decision 6: Sequential verification gate execution order

**選擇**:本 change 的執行順序嚴格規定為:

1. 寫程式碼變更(D01_04 + select_table_columns + ensure_dna_schema + 9 個 components)
2. 本地測試 helper 的 idempotency(空 db + 已部分 migrate 的 db 都應該 OK)
3. 對 MAMBA app_data.duckdb 跑 `ensure_dna_schema()` 一次,verify `db_describe` 含 `p_alive`
4. 重跑 cbz_D01_02 + cbz_D01_04(eby 同),verify `df_dna_by_customer` 有 `p_alive` 數據
5. 對 `customerRetention.R` 在本地跑 smoke test(直接 source 函數,call response_data() 等 reactive)
6. Upload 到 Supabase
7. Deploy 到 Posit Connect(`make deploy-sync` + `make deploy-push`)
8. 在 Posit Connect 手動驗 dashboardOverview / customerRetention / customerLifecycle 三個元件

**Rationale**:

- 每一步都有 verification gate,失敗就停下不繼續
- 順序確保「程式碼 OK → 本地 OK → upload OK → production OK」的 fail-fast 鏈
- 避免 "改了一堆東西,deploy 後在 production 才發現某個 component 還在報錯" 的窘況

### Decision 7: D02 D03 D05 schema audit out of scope

**選擇**:本 change 只 focus `df_dna_by_customer` schema,不 audit 其他 derivation tables(`df_segments_by_customer`、`df_macro_monthly_summary`、`df_geo_*`)是否也有同樣 silent drop 問題。

**Rationale**:

- 範圍控制 — user 要求「盡量完整」但也要確保本 change 能在合理時間內完成
- `select_table_columns()` 的 warning fix 是 cross-cutting 的,任何呼叫該函數的 derivation 都會自動受益
- 其他 tables 的 schema audit 是 follow-up issue(本 design 會記錄)

**Alternatives considered**:

- (a) **同時 audit 所有 derivation tables**:scope 失控,可能膨脹到 30+ tasks
- (b) **完全不 audit**:留下 known unknown,未來再次踩坑

### Decision 8 Production rollback strategy

**選擇**:若 Step 8 deploy 後 production 出現 regression,rollback 策略為:

1. **Code rollback**:`git revert` 回 #376 修復前的 commit,push to main
2. **Data rollback**:重新 upload 上一版的 `df_dna_by_customer`(從 git diff 找到上次 successful upload 的時間,從 archive 取)
3. **Schema rollback**:`ALTER TABLE df_dna_by_customer DROP COLUMN p_alive, DROP COLUMN btyd_expected_transactions`(危險,只在最後手段)

**Rationale**:

- Code rollback 是最安全的(分鐘級)
- Data rollback 是中等(可能 10 分鐘 upload)
- Schema rollback 是最危險(會丟資料,只有 schema 本身有 bug 才用)

## Risks / Trade-offs

| Risk | Likelihood | Mitigation |
|---|---|---|
| `ensure_dna_schema()` ALTER TABLE 在 production Supabase 失敗(權限不足) | Medium | 先用 `pg_user` connection 測試 ALTER TABLE 權限;若 Supabase 不允許,改為 DROP + reupload 路線 |
| `select_table_columns()` warning 過度噪音(每跑 D01_04 都 warn) | Low | warning 只在偵測到 mismatch 時觸發。配合 helper 補齊 schema 後就不會再 warn |
| dbplyr 把 R `median()` 翻譯成 PostgreSQL `percentile_cont` 時行為跟 DuckDB `MEDIAN()` 不一致 | Medium | 設定 unit test,本地 DuckDB + production-like Postgres 都驗證結果 |
| 9 個 raw SQL 元件 mechanical migration 引入 regression(SQL 邏輯複雜) | High | 每個元件 migration 後跑 manual smoke test,對比舊版輸出 |
| MAMBA `app_data.duckdb` schema migration 中途失敗,留下 inconsistent state | Medium | helper 是 idempotent,可重跑;失敗時保留原 table 不破壞 |
| Sub-task 4 的 8 個元件 scope 太大,本 change 變成大型 PR | High | 拆 design 中 tasks 為 4 個 phase,每 phase commit 一次,可分批 review |
| Other derivation tables 也有 silent drop 問題,本 change 沒處理 | Medium | Design 中明確標記 follow-up,不在本 change 處理 |
| Upload 到 Supabase 期間 MAMBA dashboard 服務中斷 | Low | upload 是 single-table overwrite,期間 customerRetention 仍會掛但其他元件正常 |
| Posit Connect deploy 時 R package version 不一致,dbplyr 翻譯行為不同 | Low | 確認 `renv.lock` 或 `manifest.json` 的 dbplyr 版本固定 |

## Migration Plan

### Phase 1 schema migration helper

1. 寫 `28_migration_scripts/fn_ensure_dna_schema.R`
2. 本地 unit test:用 in-memory duckdb 建立舊版 schema(沒 `p_alive`)→ 跑 helper → verify 新 schema 含 `p_alive`
3. 在 in-memory duckdb 跑第二次 helper → verify no-op(idempotent)
4. Commit

### Phase 2 D01_04 integration

1. 修 `fn_D01_04_core.R:99-103` `select_table_columns()` 加 warning
2. 在 `fn_D01_04_core.R` Part 2 開頭加 `source(ensure_dna_schema.R)` + 呼叫
3. 對 MAMBA app_data 跑 `ensure_dna_schema()` 一次(out-of-band,或讓 D01_04 第一次跑時自動執行)
4. 重跑 `cbz_D01_02` + `cbz_D01_04`,verify `db_describe('df_dna_by_customer')` 含 `p_alive`
5. 同樣 for eby
6. Commit

### Phase 3 customerRetention migration

1. 重寫 `customerRetention.R:172-200` `overall_repurchase_data()` 用 tbl2 + dbplyr `median()`
2. 重寫 `customerRetention.R:320-360` `category_data()` 用 tbl2 + dbplyr
3. 本地 source customerRetention,跑 reactive 驗證輸出
4. Commit

### Phase 4 mechanical migration 8 components

1. `customerAcquisition` → tbl2
2. `revenuePulse` → tbl2
3. `customerEngagement` → tbl2
4. `comprehensiveDiagnosis × 2` → tbl2
5. `worldMap` → tbl2
6. `macroTrends` → tbl2
7. `reportIntegration` → tbl2
8. 每個 commit 後 source 元件,跑 reactive smoke test

### Phase 5 upload deploy verify

1. 重新 upload `df_dna_by_customer` + 受影響的 tables 到 Supabase
2. `make deploy-sync` + `make deploy-push` MAMBA
3. 等 Posit Connect 自動 rebuild
4. 手動驗證 production:打開 MAMBA app,登入,切換到 dashboardOverview / customerRetention / customerLifecycle / customerActivity,確認沒有 PostgreSQL error 且資料顯示
5. 看 Posit Connect log,確認沒有 `column does not exist` 或 `function median does not exist`

### Decision 9 rollback procedure for failed deploy

若 Phase 5 失敗:

1. **Code rollback**:`git revert <commit>` to all phases, push,Posit Connect 自動 rebuild 回前一版
2. **Schema 不需 rollback**(`p_alive` column 加進去無害,舊 code 不會 reference)
3. 若 dbplyr median 翻譯有問題:臨時 patch 用 Sys.getenv("R_DRIVER") 分支寫雙版本 SQL(技術債,但 production-first)

## Open Questions

1. **`ensure_dna_schema()` 在 Supabase 上能否執行 ALTER TABLE?** — 需先用 `pg_user` 測 Supabase service role 是否有 DDL 權限。若沒,fallback 為 DROP + recreate(危險)或手動先去 Supabase 加欄位
2. **`fn_create_df_dna_by_customer_table.R` 是否就是 source-of-truth?** — 確認所有 D01 derivations 都從這個檔案讀 schema,而不是各自寫死
3. **dbplyr 對 `customerRetention` 複雜 CASE WHEN + median 的翻譯是否正確?** — 需 prototype 驗證
4. **8 個元件是否每個都有 platform_id filter?** — Sub-task 4 的 mechanical migration 需確認 pattern 一致
5. **要不要在本 change 同時加 `nrec` ENUM 或其他 BTYD-related fields?** — 如果加,scope 變大;如果不加,下次 D01_02 schema 變更又要做一次。建議 source-of-truth 一次補齊,避免 future migration
