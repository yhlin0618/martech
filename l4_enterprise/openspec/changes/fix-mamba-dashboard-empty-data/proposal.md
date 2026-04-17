## Why

MAMBA Posit Connect production dashboard 在部署 #371/#374 後出現 **7+ 元件呈現空白資料** 加 **2 個 PostgreSQL 不相容錯誤**(`column d.p_alive does not exist`、`function median(double precision) does not exist`),客戶看不到任何有意義的內容。

根因不只是「漏跑某個 derivation」,而是 **3 個結構性問題**疊加(完整診斷見 issue #376):

1. **Schema migration 從未完成** — `app_data.df_dna_by_customer` 是 BTYD #211 之前建立的 schema,沒有 `p_alive` / `btyd_expected_transactions` 兩欄。新版 DRV 想要寫入這兩欄時被 `select_table_columns()` **靜默 drop**(violation of MP154),pipeline 看似成功實則資料不完整。
2. **Silent column drop pattern** 仍存在 — `fn_D01_04_core.R:99-103` 用 `intersect(names(df), target_cols)` 過濾欄位,沒有任何 warning。這是 MP154 違規,也是上述 schema migration 失敗無聲的元兇。
3. **Cross-driver migration 未完整** — #369 把 4 個 Shiny components 改寫成 tbl2,但留下 **9 個元件還在用 raw `DBI::dbGetQuery()`**,其中 `customerRetention.R` 還用 DuckDB-only 的 `MEDIAN()`,導致 PostgreSQL 環境炸開。其他 8 個元件雖然不報錯,但也在違反 DM_R023 v1.2 的 raw SQL 禁令,任何一個 DuckDB-only 函數都會是下個地雷。

「完整修復」不是只修 `p_alive` 一個 column,而是把這三層全部補齊,讓 MAMBA dashboard 在 Supabase 後端真的能用,且未來再次發生 schema 變更時不會再 silent drop。

## What Changes

### 緊急修復(unblock production)

- **修復 MAMBA app_data schema**:DROP `df_dna_by_customer` → 重跑 `D00_app_data_init`(用最新 `fn_create_df_dna_by_customer_table.R` 含 `p_alive` / `btyd_expected_transactions` 兩欄)→ 重跑 `D01_02`(compute BTYD 寫入 cleansed_data)→ 重跑 `D01_04`(投影到 app_data,驗證 `p_alive` 進得去)
- **重新 upload `df_dna_by_customer` 到 Supabase**,driver-agnostic schema 才會讓 production 元件能讀
- **遷移 `customerRetention.R` raw SQL → tbl2 + dbplyr**,2 處 `MEDIAN()` 改用 R `median()`(讓 dbplyr 翻譯成 driver-specific SQL,DuckDB 用 MEDIAN、PostgreSQL 用 percentile_cont)

### 治本(防止再次發生 — 結構性修復)

- **遷移其餘 8 個 Shiny components 的 raw `DBI::dbGetQuery()` → tbl2 + dbplyr**:`customerAcquisition`、`revenuePulse`、`customerEngagement`、`comprehensiveDiagnosis`(tagpilot + vitalsigns 各一)、`worldMap`、`macroTrends`、`reportIntegration`。完成 #369 / #370 在 Shiny 層的 backlog
- **修復 `select_table_columns()` silent drop pattern**(`fn_D01_04_core.R:99-103`):當 `customer_dna` 的欄位不在 target table 中,**必須** emit `warning()` 列出被 drop 的欄位、提示應該跑 D00 重建 schema 或加 ALTER TABLE migration script。違反 MP154 的修正
- **新增 schema migration helper**(`28_migration_scripts/fn_ensure_dna_schema.R`):idempotent 函數,負責在 D01_04 寫入前檢查 `app_data.df_dna_by_customer` 是否有所有 expected columns,缺欄位時 ALTER TABLE 加入,而不是依靠下游元件靜默忽略
- **更新 `D01_04_core` 在投影前先呼叫 schema migration helper**,確保未來再次新增 derivation 欄位時不會再 silent drop

### 驗證

- **本地驗證**:重跑 pipeline 後 `db_describe('df_dna_by_customer')` 必須包含 `p_alive` / `btyd_expected_transactions` 兩欄;customerRetention 在 DuckDB 環境必須跑得出 median 數字
- **production 驗證**:deploy 後在 Posit Connect 上手動驗 dashboardOverview / customerRetention / customerLifecycle 三個高優先元件,確認沒有 PostgreSQL error
- **MP154 audit**:grep 整份 `shared/global_scripts/` 找其他類似 `intersect(.*column` silent drop pattern,記錄到本 change 的 design

## Non-Goals

- **不在本 change 範圍**:
  - **E2E test infrastructure 設定**:user 提到「我不知道這用 E2E test 會不會好一點」,Supabase test profile + shinytest2 staging 是另一個 SDD,需獨立 spec(本 change 已經夠大了)
  - **MAMBA 客戶資料量稀疏的根因**(`df_dna_by_customer` 只有 113 unique customers):屬於上游 ETL 修復(#371 範圍),本 change 只負責 schema + 元件層
  - **`product_line_id_filter == "tur"` 只有 1 customer 的 UI 友善訊息**:屬於 UX 改進,獨立 issue
  - **Non-Shiny `DBI::dbGetQuery()` migration**(`04_utils/`、`16_derivations/`、`98_test/` 約 150+ 檔案):#370 已追蹤,本 change 只處理 `10_rshinyapp_components/` 下的 9 個元件
  - **DuckDB → PostgreSQL 函數對照表 / cross-driver helper library**:short term 用 dbplyr 翻譯就夠,long term 抽 helper 是另一個 refactor

- **拒絕的方案**:
  - **只修 `p_alive` 一個欄位 + 只修 `customerRetention` 一個元件**(緊急 minimal fix):會 unblock production 但治本問題 (silent drop) 還在,下一次 schema 變更又會踩。User 明確要求「盡量修改的完整」。
  - **直接改 Supabase 上的 schema (`ALTER TABLE` SQL)**:不可重現、不在 source control、其他公司部署時還會踩同樣坑。應該從 D00 + D01_04 source of truth 修起。
  - **把 `customerRetention.R` 的 SQL 改成 PostgreSQL 專用語法 `percentile_cont`**:會破壞 driver-agnostic 原則,本地 DuckDB 開發環境就會不能跑。應該用 dbplyr 讓 driver 自己翻譯。

## Capabilities

### New Capabilities

- `dashboard-postgres-restoration`: MAMBA Shiny dashboard 在 PostgreSQL/Supabase 後端的完整可運作性。包括 (1) `df_dna_by_customer` schema migration discipline(D00 必須是 idempotent source of truth、D01_04 投影前必須 ensure schema)、(2) 9 個 Shiny components 的 raw SQL → tbl2 遷移、(3) `select_table_columns()` 的 MP154 sentinel pattern fix、(4) 部署後的 schema 驗證 contract

### Modified Capabilities

(none)

## Impact

**Affected code**:

- `shared/global_scripts/16_derivations/fn_D01_04_core.R` — 修 `select_table_columns()` 加 warning;在 customer_dna 投影前呼叫 schema migration helper
- `shared/global_scripts/28_migration_scripts/fn_ensure_dna_schema.R` — **新增** schema migration helper(idempotent ALTER TABLE)
- `shared/global_scripts/01_db/fn_create_df_dna_by_customer_table.R` — 確認 schema 含 `p_alive` / `btyd_expected_transactions`(目前已包含,但作為 source of truth 對照)
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerRetention/customerRetention.R` — 2 處 raw SQL → tbl2,`MEDIAN()` → R `median()`
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerAcquisition/customerAcquisition.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/revenuePulse/revenuePulse.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerEngagement/customerEngagement.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/comprehensiveDiagnosis/comprehensiveDiagnosis.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/tagpilot/comprehensiveDiagnosis/comprehensiveDiagnosis.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/worldMap/worldMap.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/vitalsigns/macroTrends/macroTrends.R` — raw SQL → tbl2
- `shared/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R` — raw SQL → tbl2

**Affected pipelines**:

- MAMBA `update_scripts/DRV/cbz/cbz_D00_01.R` / `cbz_D01_02.R` / `cbz_D01_04.R` 重跑(資料層,非程式碼變更)
- MAMBA `update_scripts/DRV/eby/eby_D01_*.R` 重跑
- MAMBA Supabase upload via `upload_app_data_to_supabase.R`(`df_dna_by_customer` 表 overwrite)

**Affected production**:

- MAMBA Posit Connect dashboard 重新部署(unblock 7+ 空白元件)

**Related issues**:

- `#376` — 本 change 直接對應的 issue
- `#369` — `cross-driver-query-layer` change(已 archive,本 change 完成它在 Shiny 層的剩餘 9 個元件)
- `#370` — Non-Shiny `dbGetQuery()` migration tracking(out of scope,但 design 中需參照)
- `#371` — MAMBA pipeline restoration(已修,但 schema migration 沒包含)
- `#374` — Complete derivation coverage(已 archive,但沒覆蓋到 schema migration discipline)
- `#211` — BG/NBD P(alive) integration(p_alive 欄位的源頭)
