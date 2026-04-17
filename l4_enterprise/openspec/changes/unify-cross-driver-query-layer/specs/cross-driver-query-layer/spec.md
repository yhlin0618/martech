## ADDED Requirements

### Requirement: Database Reads SHALL Use tbl2()

All database read operations in Shiny components, derivations, and utility functions SHALL use `tbl2()` combined with dplyr verbs (`filter`, `select`, `summarize`, etc.) terminated by `collect()`. Raw SQL string queries with positional placeholders (`?`) via `DBI::dbGetQuery(con, sql, params = list(...))` SHALL NOT be used for read operations.

#### Scenario: Shiny component reads filtered data using tbl2

- **WHEN** a Shiny component needs to read rows from `df_macro_monthly_summary` filtered by `platform_id` and `product_line_id`
- **THEN** the component SHALL call `tbl2(con, "df_macro_monthly_summary") %>% filter(platform_id == input_platform, product_line_id == input_line) %>% collect()` instead of `DBI::dbGetQuery(con, "SELECT * FROM df_macro_monthly_summary WHERE platform_id = ? AND product_line_id = ?", params = list(...))`

#### Scenario: Migrated component produces identical results across drivers

- **WHEN** a migrated Shiny component runs against DuckDB (local development) and PostgreSQL (Supabase production) with the same underlying data
- **THEN** the component SHALL return identical row sets and KPI values in both environments

---

### Requirement: tbl2.DBIConnection SHALL Be a Pure Passthrough to dplyr::tbl

The `tbl2.DBIConnection` S3 method SHALL delegate directly to `dplyr::tbl(src, from, ...)` without any string parsing, dot-syntax detection, or raw SQL construction. The method SHALL NOT construct SQL strings via `paste0("SELECT * FROM ", from)` or similar concatenation.

#### Scenario: Simple table name delegates directly to dplyr::tbl

- **WHEN** code calls `tbl2(con, "customers")` where `con` is a `DBIConnection`
- **THEN** the call SHALL be equivalent to `dplyr::tbl(con, "customers")`

#### Scenario: Table name containing a dot does not trigger special handling

- **WHEN** code calls `tbl2(con, "v1.2")` where `"v1.2"` is a literal table name containing a dot
- **THEN** the call SHALL delegate to `dplyr::tbl(con, "v1.2")` without parsing the dot and SHALL NOT construct `SELECT * FROM v1.2` via string concatenation

#### Scenario: Schema-qualified access uses dbplyr::in_schema explicitly

- **WHEN** code needs to access a schema-qualified table such as `transformed_data.df_amz_review___transformed`
- **THEN** the caller SHALL pass `dbplyr::in_schema("transformed_data", "df_amz_review___transformed")` as the `from` argument, not a dot-separated string

---

### Requirement: Polymorphic Dispatch SHALL Be Preserved for Non-DBI Sources

The `tbl2()` function SHALL retain its S3 polymorphic dispatch for non-`DBIConnection` source types, including `data.frame`, `tbl_df`, `list`, `character` (file paths), and `function` sources. The existing methods `tbl2.data.frame`, `tbl2.tbl_df`, `tbl2.list`, `tbl2.character`, and `tbl2.function` SHALL NOT be modified by this change.

#### Scenario: data.frame input returns a tibble without requiring from argument

- **WHEN** code calls `tbl2(my_df)` where `my_df` is a `data.frame`
- **THEN** the call SHALL return a tibble via `dplyr::as_tibble(my_df)` without requiring a `from` argument

#### Scenario: list of tables supports keyed lookup

- **WHEN** code calls `tbl2(mock_tables, "customers")` where `mock_tables` is a named list containing a `customers` data.frame
- **THEN** the call SHALL return the `customers` element converted to a tibble, supporting test and mock scenarios

---

### Requirement: Write Operations SHALL Use dbExecute

Data modification operations (`INSERT`, `UPDATE`, `DELETE`, `CREATE TABLE`, `DROP TABLE`, `ALTER TABLE`) SHALL use `DBI::dbExecute()` with explicit raw SQL strings. Write operations SHALL NOT be routed through `tbl2()` or `dbGetQuerySafe()`.

#### Scenario: Creating a table uses dbExecute

- **WHEN** an ETL script needs to create a new table
- **THEN** the script SHALL use `DBI::dbExecute(con, "CREATE TABLE ...")` rather than `tbl2()` or `DBI::dbGetQuery()`

#### Scenario: Batch inserting rows uses dbExecute or dbWriteTable

- **WHEN** a derivation script needs to insert rows into a target table
- **THEN** the script SHALL use `DBI::dbExecute()` for parameterized insert statements or `DBI::dbWriteTable()` for bulk writes, and SHALL NOT use `tbl2()`

---

### Requirement: dbGetQuerySafe SHALL Emit Deprecation Warning

The `dbGetQuerySafe()` helper function SHALL emit a deprecation warning via `.Deprecated("tbl2")` on every invocation. The function body SHALL continue to operate correctly during the transition period to avoid breaking production code that has not yet been migrated.

#### Scenario: Calling dbGetQuerySafe emits warning and returns result

- **WHEN** code calls `dbGetQuerySafe(con, sql, params)` during the transition period
- **THEN** the function SHALL emit a deprecation warning naming `tbl2` as the replacement AND SHALL return the query result correctly

#### Scenario: Deprecation warning references the tbl2 replacement

- **WHEN** the deprecation warning is displayed to the user
- **THEN** the warning text SHALL include the string `tbl2` so developers know which function to migrate to

---

### Requirement: Advisory Hook SHALL Detect Raw SQL Read Patterns

A Claude Code `PreToolUse` hook SHALL inspect `Edit` and `Write` tool invocations targeting `.R` files. When the new content introduces a `DBI::dbGetQuery(.*SELECT` pattern or a `dbGetQuerySafe(` call, the hook SHALL emit an advisory notice pointing to `DM_R023` and the `tbl2()` replacement. The hook SHALL NOT block the tool invocation.

#### Scenario: Adding raw SQL SELECT triggers advisory

- **WHEN** a developer uses `Edit` or `Write` to add `DBI::dbGetQuery(con, "SELECT * FROM customers")` to a `.R` file
- **THEN** the hook SHALL emit an advisory message referencing `DM_R023` and suggesting `tbl2(con, "customers") %>% collect()`

#### Scenario: Adding tbl2 call does not trigger advisory

- **WHEN** a developer uses `Edit` or `Write` to add `tbl2(con, "customers") %>% filter(...) %>% collect()` to a `.R` file
- **THEN** the hook SHALL remain silent

#### Scenario: Hook is advisory and does not block the write

- **WHEN** the hook detects a raw SQL read pattern
- **THEN** the `Edit` or `Write` tool invocation SHALL complete successfully, with the advisory message displayed as a non-blocking notice

---

### Requirement: PostgreSQL Integration Test SHALL Validate Cross-Driver Behavior

The test suite SHALL include a PostgreSQL integration test at `02_db_utils/tbl2/test_postgres.R` that connects to a real PostgreSQL database (Supabase or local container) and verifies that `tbl2()` returns equivalent results to DuckDB for the same query.

#### Scenario: PostgreSQL test verifies simple tbl2 read

- **WHEN** `test_postgres.R` runs against a PostgreSQL test database with known fixture data
- **THEN** the test SHALL call `tbl2(pg_con, "fixture_table") %>% collect()` AND SHALL assert the returned row count and values match the expected fixture

#### Scenario: PostgreSQL test verifies filtered query translation

- **WHEN** `test_postgres.R` runs a filtered query such as `tbl2(pg_con, "fixture_table") %>% filter(id > 10) %>% collect()`
- **THEN** the test SHALL assert that dbplyr translates the filter to correct PostgreSQL SQL AND the returned rows match the expected subset

---

### Requirement: DM_R023 Principle SHALL Specify tbl2 as Mandatory Read Interface

The `DM_R023 Universal DBI Approach` principle document SHALL contain a `callout-critical` block stating that database reads use `tbl2()` and raw SQL string queries for reads are forbidden. The principle SHALL also define an explicit exceptions section listing DDL/DML operations via `dbExecute()` and driver-specific introspection via helper functions.

#### Scenario: DM_R023 contains callout-critical for tbl2 mandate

- **WHEN** a developer reads `DM_R023_universal_dbi_approach.qmd`
- **THEN** the document SHALL contain a `:::{.callout-critical}` block that states database reads SHALL use `tbl2()` AND SHALL forbid raw SQL read queries

#### Scenario: DM_R023 exceptions section lists allowed raw SQL patterns

- **WHEN** a developer reads the Exceptions section of `DM_R023`
- **THEN** the document SHALL list exactly three allowed raw SQL usage categories: DDL/DML via `dbExecute()`, driver-specific introspection via helper functions, and the transitional `dbGetQuerySafe()` deprecation window

---

### Requirement: Principle Changes SHALL Be Synchronized Across Three Layers

Any modification to `DM_R023_universal_dbi_approach.qmd` SHALL be synchronized to `00_principles/llm/CH02_data.yaml` (AI index) and `00_principles/.claude/rules/02-coding.md` (Claude quick reference) in the same change, per `DOC_R009` three-layer synchronization.

#### Scenario: Strengthening DM_R023 updates llm index

- **WHEN** `DM_R023_universal_dbi_approach.qmd` is revised to add the `callout-critical` block and Exceptions section
- **THEN** `llm/CH02_data.yaml` SHALL be updated in the same change to reflect the strengthened requirements

#### Scenario: Strengthening DM_R023 updates Claude rules file

- **WHEN** `DM_R023_universal_dbi_approach.qmd` is revised
- **THEN** `00_principles/.claude/rules/02-coding.md` SHALL be updated in the same change to include a new database read section that references `DM_R023` and shows good and bad examples

---

### Requirement: Cross-Company End-to-End Validation SHALL Cover Three Deployments

The migration SHALL be validated by running end-to-end test suites against three deployed company projects: `MAMBA`, `QEF_DESIGN`, and `D_RACING`. The change SHALL NOT be considered complete until all three suites pass.

#### Scenario: MAMBA E2E suite passes after migration

- **WHEN** all ten Shiny components are migrated and `tbl2()` refactor is merged
- **THEN** running the `MAMBA` shinytest2 E2E suite SHALL produce zero failures AND all KPI values SHALL match baseline snapshots

#### Scenario: QEF_DESIGN E2E suite passes after migration

- **WHEN** the migration is merged
- **THEN** running the `QEF_DESIGN` shinytest2 E2E suite SHALL produce zero failures

#### Scenario: D_RACING E2E suite passes after migration

- **WHEN** the migration is merged
- **THEN** running the `D_RACING` shinytest2 E2E suite SHALL produce zero failures
