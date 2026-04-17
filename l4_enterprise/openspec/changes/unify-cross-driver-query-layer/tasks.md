## 1. tbl2 Infrastructure Baseline

- [x] 1.1 Refactor tbl2.DBIConnection to pure passthrough so that tbl2.DBIConnection SHALL Be a Pure Passthrough to dplyr::tbl — delete the dot-syntax special case at `shared/global_scripts/02_db_utils/tbl2/fn_tbl2.R` lines 50-54 and replace with direct delegation to `dplyr::tbl(src, from, ...)`
- [x] 1.2 Preserve tbl2 polymorphic dispatch for non-DB sources — verify Polymorphic Dispatch SHALL Be Preserved for Non-DBI Sources by confirming tbl2.data.frame, tbl2.tbl_df, tbl2.list, tbl2.character, tbl2.function remain unchanged and their existing tests pass
- [x] 1.3 Rewrite 4 attached database test files (`test_attached_database.R`, `test_tbl2_attached.R`, `test_syntax_detection.R`, `test_simple.R`) to use `dbplyr::in_schema("schema", "table")` instead of dot-syntax string literals
- [x] 1.4 Write new PostgreSQL Integration Test SHALL Validate Cross-Driver Behavior at `shared/global_scripts/02_db_utils/tbl2/test_postgres.R` — connect to real PostgreSQL (Supabase or local container), run `tbl2()` against a fixture table, assert results match DuckDB baseline
- [x] 1.5 Run full tbl2 test suite; confirm baseline green on both DuckDB and PostgreSQL before touching Shiny components

## 2. Strengthen DM_R023 Principle (Three-Layer Sync)

- [x] 2.1 Strengthen DM_R023 instead of creating DM_R062 — upgrade DM_R023 Principle SHALL Specify tbl2 as Mandatory Read Interface by adding a `:::{.callout-critical}` block to Section 1 Core Requirement in both `docs/en/.../DM_R023_universal_dbi_approach.qmd` and `docs/zh/.../DM_R023_universal_dbi_approach.qmd`
- [x] 2.2 Add Section 5 "Exceptions & Migration" to DM_R023 documenting three allowed raw SQL categories: (a) Write Operations SHALL Use dbExecute — keep write operations on raw SQL and dbExecute (YAGNI), no `dbExecuteSafe` wrapper; (b) driver-specific introspection via helper functions (PRAGMA, information_schema, EXPLAIN — via future helpers in `02_db_utils/`); (c) transitional `dbGetQuerySafe()` during deprecation window
- [x] 2.3 Update DM_R023 revision_history to v1.2 with summary referencing issue #369 and this change
- [x] 2.4 Principle Changes SHALL Be Synchronized Across Three Layers — update `00_principles/llm/CH02_data.yaml` to reflect the strengthened DM_R023 and add a new "Database Read Pattern" section to `00_principles/.claude/rules/02-coding.md` with good/bad examples and explicit reference to DM_R023

## 3. Advisory Hook for Non-Blocking Enforcement

- [x] 3.1 Create Advisory hook for non-blocking enforcement at `.claude/hooks/check-tbl2-compliance.sh` implementing Advisory Hook SHALL Detect Raw SQL Read Patterns — detect `DBI::dbGetQuery(.*SELECT` pattern and `dbGetQuerySafe(` calls in Edit/Write content targeting `.R` files, emit advisory referencing DM_R023 and tbl2 replacement
- [x] 3.2 Register the new hook in `.claude/settings.json` as PreToolUse for Edit and Write tools, following the pattern of existing `check-wiki-sync.sh` and `check-principle-sync.sh`
- [x] 3.3 Manually verify hook fires advisory when editing a test file to add `DBI::dbGetQuery(con, "SELECT ...")` and remains silent when adding `tbl2(con, "table") %>% collect()`

## 4. Shiny Component Migration (Limit scope to Shiny components)

- [x] 4.1 Limit scope to Shiny components — confirm exactly 10 Shiny components currently using `dbGetQuerySafe()` per the Impact section of proposal.md, no new additions to this list during implementation
- [x] 4.2 Migrate `dashboardOverview.R` so Database Reads SHALL Use tbl2() (2 occurrences) — replace `dbGetQuerySafe(con, "SELECT ... WHERE x = ? AND y = ?", params = list(...))` with `tbl2(con, "table") %>% filter(x == input_x, y == input_y) %>% collect()`
- [x] 4.3 Migrate `customerLifecycle.R` to tbl2 pattern
- [x] 4.4 Migrate `customerStatus.R` to tbl2 pattern
- [x] 4.5 Migrate `customerActivity.R` to tbl2 pattern
- [x] 4.6 Migrate `customerValue.R` to tbl2 pattern
- [x] 4.7 Migrate `customerStructure.R` to tbl2 pattern
- [x] 4.8 Migrate `customerExport.R` to tbl2 pattern
- [x] 4.9 Migrate `marketingDecision.R` to tbl2 pattern
- [x] 4.10 Migrate `rsvMatrix.R` to tbl2 pattern

## 5. Deprecate dbGetQuerySafe

- [x] 5.1 Add `.Deprecated("tbl2")` to `shared/global_scripts/04_utils/fn_db_get_query_safe.R` so dbGetQuerySafe SHALL Emit Deprecation Warning on every call, while retaining the function body as a safety net during the transition period

## 6. Cross-Company End-to-End Validation

- [x] 6.1 Run MAMBA shinytest2 E2E suite — Cross-Company End-to-End Validation SHALL Cover Three Deployments, compare KPI values against baseline snapshots, flag any deviation (55/55 tab-navigation tests pass + 13/13 ai-buttons partial run)
- [ ] 6.2 Run QEF_DESIGN shinytest2 E2E suite, compare against baseline snapshots — **DEFERRED** per user decision; run in a follow-up session before final archive
- [ ] 6.3 Run D_RACING shinytest2 E2E suite, compare against baseline snapshots — **DEFERRED** per user decision; run in a follow-up session before final archive

## 7. Tracking & Production Deploy

- [x] 7.1 Open GitHub tracking issue for non-Shiny `DBI::dbGetQuery()` migration (approximately 150+ files in `04_utils/`, `16_derivations/`, `98_test/`), link to #369 and this change as parent context; mark out of scope for this change — opened as #370
- [x] 7.2 Commit to `shared/global_scripts` and run MAMBA `make deploy-sync` + `make deploy-push` to trigger Posit Connect auto-deploy, then verify production Shiny runs correctly on the PostgreSQL (Supabase) backend with no runtime SQL syntax errors — global_scripts commit `265320d`, MAMBA deploy commit `a6c75e8` pushed at 2026-04-13 20:36; Posit Connect rebuild auto-triggered; **verified that the `?` placeholder PostgreSQL syntax error no longer occurs** (the query layer refactor works). However, a separate underlying issue was exposed: Supabase schema drift (stale snapshot, missing columns and tables). Tracked separately in #371 — **NOT blocking this change's completion** since #369's acceptance criteria are about the query layer, not data operations.
