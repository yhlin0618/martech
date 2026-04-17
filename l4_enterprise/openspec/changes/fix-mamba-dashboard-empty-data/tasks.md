## 1. Phase 1 schema migration helper

- [x] 1.1 Write `shared/global_scripts/28_migration_scripts/fn_ensure_dna_schema.R` implementing **DNA Customer Table SHALL Maintain Single Source of Truth Schema** and **Decision 1: Idempotent ALTER TABLE migration helper** at the canonical **Decision 5: Schema migration helper location 28_migration_scripts**: read canonical column list from `fn_create_df_dna_by_customer_table.R`, compare with `app_data.df_dna_by_customer` actual columns via `DBI::dbListFields()`, emit `ALTER TABLE ... ADD COLUMN <name> DOUBLE` (or appropriate type) for each missing column, message each addition
- [x] 1.2 Local unit test for **Idempotent re-execution**: in-memory duckdb `dbConnect(duckdb::duckdb())`, create old-version `df_dna_by_customer` (drop `p_alive` and `btyd_expected_transactions` from canonical schema), run `ensure_dna_schema()`, verify columns added; run helper second time, verify no `ALTER` issued and message says "schema is up to date"
- [x] 1.3 Local unit test for **New deployment creates table with current schema**: empty in-memory duckdb, run `D00_app_data_init` via the existing init function, verify `db_describe('df_dna_by_customer')` includes `p_alive` and `btyd_expected_transactions` as DOUBLE
- [x] 1.4 Commit Phase 1 with message `[REFACTOR] Add ensure_dna_schema helper for idempotent schema migration (#376)` referencing MP154

## 2. Phase 2 D01_04 integration

- [x] 2.1 Modify `shared/global_scripts/16_derivations/fn_D01_04_core.R:99-103` `select_table_columns()` to implement **select_table_columns SHALL Warn on Silent Column Drop** per **Decision 2: select_table_columns warns instead of failing**: compute `dropped <- setdiff(names(df), target_cols)`, when `length(dropped) > 0` emit `warning(sprintf("[D01_04] select_table_columns dropped %d columns from %s: %s. Run ensure_dna_schema(con) to migrate.", length(dropped), table_name, paste(dropped, collapse = ", ")))`
- [x] 2.2 Modify `fn_D01_04_core.R` Part 2 (after connection setup, before any `select_table_columns()` call) to implement **D01_04 Projection SHALL Ensure Schema Before Writing**: `source(file.path(GLOBAL_DIR, "28_migration_scripts", "fn_ensure_dna_schema.R"))` and call `ensure_dna_schema(app_data)` before invoking `select_table_columns(app_data, "df_dna_by_customer", customer_dna)`
- [x] 2.3 Run `Rscript -e 'source("shared/global_scripts/28_migration_scripts/fn_ensure_dna_schema.R"); con <- dbConnectDuckdb(file.path("MAMBA","data","app_data","app_data.duckdb")); ensure_dna_schema(con); DBI::dbDisconnect(con)'` to migrate MAMBA `app_data.duckdb` schema in-place; verify no errors
- [x] 2.4 Verify schema after migration: `db_describe('df_dna_by_customer')` must contain `p_alive` and `btyd_expected_transactions` (per **Existing deployment with stale schema is migrated** scenario)
- [x] 2.5 Following **Decision 6: Sequential verification gate execution order**, from MAMBA `update_scripts/` run `make run TARGET=cbz_D01_02` to recompute customer DNA with BTYD into `cleansed_data`
- [x] 2.6 From MAMBA `update_scripts/`, run `make run TARGET=cbz_D01_04` to project DNA from `cleansed_data` to `app_data`; verify warnings (if any) list only stale columns, not `p_alive`
- [x] 2.7 Verify cbz `df_dna_by_customer` has `p_alive` populated: `SELECT COUNT(*) AS n, COUNT(p_alive) AS n_with_palive FROM df_dna_by_customer WHERE platform_id = 'cbz'` — column exists (cbz n=95) but values are NULL because BTYD failed for all slices (`< 2 repeat customers` — MAMBA real-data sparseness, upstream #371 issue, not a schema bug)
- [x] 2.8 Repeat 2.5-2.7 for eby (`make run TARGET=eby_D01_02`, `eby_D01_04`) — eby 18/18 rows have non-null p_alive (BTYD succeeded for eby), cbz still NULL (BTYD failed for sparse cbz data, upstream issue)
- [x] 2.9 Commit Phase 2 with message `[FIX] D01_04 invokes ensure_dna_schema; select_table_columns warns on drop (#376)` referencing MP154 + DEV_R055

## 3. Phase 3 customerRetention migration

- [x] 3.1 Read `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerRetention/customerRetention.R:172-200` and rewrite `overall_repurchase_data()` to implement **customerRetention SHALL Use dbplyr median Translation** per **Decision 3: customerRetention dbplyr median translation**: replace raw `DBI::dbGetQuery()` + `MEDIAN(CASE WHEN ...)` with `tbl2(app_connection, "df_dna_by_customer") %>% dplyr::filter(platform_id == !!plt, product_line_id_filter != "all") %>% dplyr::mutate(ipt_clean = dplyr::if_else(ni > 1 & ipt > 0, ipt, NA_real_)) %>% dplyr::group_by(product_line_id_filter) %>% dplyr::summarise(median_ipt = median(ipt_clean, na.rm = TRUE)) %>% dplyr::collect()` (preserve country_join_cte logic by adapting to dbplyr `inner_join`)
- [x] 3.2 Read `customerRetention.R:320-360` and rewrite `category_data()` reactive using same pattern as 3.1 to remove the second `MEDIAN()` raw SQL call (also migrated `dna_data()` reactive raw SQL to tbl2)
- [x] 3.3 Smoke test 3.1-3.2 against MAMBA local DuckDB — all three reactives (dna_data, overall_repurchase_data, category_data) collect successfully via dbplyr; eby 9 rows non-null p_alive (per **customerRetention runs against DuckDB local backend**): `Rscript -e 'source app.R briefly...'` or open R session and invoke the reactive functions manually with mock `cfg`; verify results contain `median_ipt` column with non-NA values
- [x] 3.4 Grep verification: `grep -n "MEDIAN\|dbGetQuery" shared/global_scripts/10_rshinyapp_components/vitalsigns/customerRetention/customerRetention.R` returns only comment references (3 lines mentioning the migration), zero raw SELECT calls
- [x] 3.5 Commit Phase 3 with message `[FIX] customerRetention uses dbplyr median for cross-driver compat (#376)` referencing DM_R023

## 4. Phase 4 mechanical migration 8 components

- [x] 4.1 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerAcquisition/customerAcquisition.R` raw `DBI::dbGetQuery()` to `tbl2() + dplyr::filter() + collect()` per **Decision 4: Mechanical 1:1 raw SQL migration for 8 components**, implementing **Shiny Components SHALL Not Use Raw dbGetQuery for Reads** for this component; smoke test reactive output matches pre-migration values when run against MAMBA local DuckDB
- [x] 4.2 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/revenuePulse/revenuePulse.R` (same pattern as 4.1); smoke test
- [x] 4.3 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/customerEngagement/customerEngagement.R` (same pattern as 4.1); smoke test
- [x] 4.4 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/comprehensiveDiagnosis/comprehensiveDiagnosis.R` (same pattern as 4.1); smoke test
- [x] 4.5 Migrate `shared/global_scripts/10_rshinyapp_components/tagpilot/comprehensiveDiagnosis/comprehensiveDiagnosis.R` (same pattern as 4.1; this is a separate file from 4.4); smoke test
- [x] 4.6 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/worldMap/worldMap.R` (same pattern as 4.1; preserve country aggregation logic in dplyr `group_by`); smoke test
- [x] 4.7 Migrate `shared/global_scripts/10_rshinyapp_components/vitalsigns/macroTrends/macroTrends.R` (same pattern as 4.1); smoke test
- [x] 4.8 Migrate `shared/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R` (same pattern as 4.1); smoke test
- [x] 4.9 Run **Grep audit confirms zero raw SELECT calls**: `grep -rn "DBI::dbGetQuery" shared/global_scripts/10_rshinyapp_components/` must show zero matches involving SELECT statements; only DELETE/UPDATE/INSERT (write) calls remain
- [x] 4.10 Commit Phase 4 in 1-3 logical commits (e.g. `[FIX] Migrate vitalsigns components from raw SQL to tbl2 (#376)`, `[FIX] Migrate tagpilot+report components from raw SQL to tbl2 (#376)`)

## 5. Phase 5 upload deploy verify

- [x] 5.1 From MAMBA root, run `make deploy-upload` (or equivalent `Rscript shared/global_scripts/23_deployment/03_deploy/upload_app_data_to_supabase.R`) to overwrite `df_dna_by_customer` and other affected tables on Supabase with the migrated local copy
- [x] 5.2 Verify Supabase schema after upload (per **Supabase schema verification**): connect to Supabase via psql or DBeaver, run `\d df_dna_by_customer`, confirm `p_alive` and `btyd_expected_transactions` columns exist
- [x] 5.3 From MAMBA root, run `make deploy-sync` then `make deploy-push` to sync R code changes and trigger Posit Connect rebuild — MAMBA deploy commit `f7462ea` pushed
- [ ] 5.4 Wait for Posit Connect to finish rebuild (~3-5 min), then open MAMBA app URL in browser, log in with `VIBE` test password
- [ ] 5.5 Manual verification per **Post-deployment manual verification**: navigate to dashboardOverview tab → confirm Latest Month Revenue / New Rate KPIs render; navigate to customerRetention tab → confirm category repurchase rate chart renders with median values; navigate to customerLifecycle tab → confirm DNA segments display; navigate to customerActivity tab → confirm customer count tile is non-zero
- [ ] 5.6 Tail Posit Connect log via `rsconnect::showLogs(...)` or download via Posit Connect UI; run `grep -E "column .* does not exist|function .* does not exist|DNA load error: $|Failed to prepare query" posit_connect_log.txt` and confirm zero matches (per **Production MAMBA Dashboard SHALL Render Without PostgreSQL Errors**)
- [ ] 5.7 Update GitHub issue #376 with verification screenshots and log excerpts; close issue with `gh issue close 376` after final review
- [ ] 5.8 If verification at step 5.5 or 5.6 fails, follow **Decision 8 Production rollback strategy** (and **Decision 9 rollback procedure for failed deploy**): `git revert` the deploy commits, push, wait for Posit Connect to rebuild on previous version, then re-investigate locally before re-attempting deploy

## 6. Phase 6 follow up housekeeping

- [ ] 6.1 Per **Decision 7: D02 D03 D05 schema audit out of scope**, open a follow-up GitHub issue tracking `select_table_columns` audit across all other derivation tables (D02 segments, D03 geo, D05 macro) as part of MP154/DEV_R055 broader rollout
- [ ] 6.2 Update `00_principles/llm/CH02_data.yaml` and `.claude/rules/02-coding.md` to reference `ensure_dna_schema` pattern as the canonical schema migration approach (per DOC_R009 triple-layer sync)
- [ ] 6.3 Verify no other companies (D_RACING, QEF_DESIGN, URBANER) need the same schema migration; if their `app_data.duckdb` was created earlier than BTYD #211 they will benefit from the next D01_04 run automatically due to ensure_dna_schema being idempotent
