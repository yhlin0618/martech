## ADDED Requirements

### Requirement: DNA Customer Table SHALL Maintain Single Source of Truth Schema

The `df_dna_by_customer` table in `app_data` SHALL maintain a schema identical to the canonical definition in `shared/global_scripts/01_db/fn_create_df_dna_by_customer_table.R`. All columns declared in the canonical schema (including `p_alive`, `btyd_expected_transactions`, `nrec_prob`, `nrec`, `nes_value`, `cai`, and DNA score columns) SHALL be present in every deployed instance regardless of when the database was originally created.

#### Scenario: New deployment creates table with current schema

- **WHEN** `D00_app_data_init` runs against an empty `app_data` database
- **THEN** the resulting `df_dna_by_customer` table SHALL contain every column listed in `fn_create_df_dna_by_customer_table.R`
- **AND** `db_describe('df_dna_by_customer')` SHALL include `p_alive` and `btyd_expected_transactions` as `DOUBLE` columns

#### Scenario: Existing deployment with stale schema is migrated

- **WHEN** `ensure_dna_schema()` runs against an `app_data` database whose `df_dna_by_customer` table was created before column `p_alive` was added to the canonical schema
- **THEN** the function SHALL execute `ALTER TABLE df_dna_by_customer ADD COLUMN p_alive DOUBLE` (and any other missing columns)
- **AND** the function SHALL emit a `message()` listing each column that was added
- **AND** subsequent calls to `db_describe('df_dna_by_customer')` SHALL include the newly added columns

#### Scenario: Idempotent re-execution

- **WHEN** `ensure_dna_schema()` is called twice in succession on the same database
- **THEN** the second call SHALL detect that all canonical columns are already present
- **AND** the function SHALL emit a `message()` indicating "schema is up to date"
- **AND** the function SHALL NOT execute any `ALTER TABLE` statements on the second call

### Requirement: D01_04 Projection SHALL Ensure Schema Before Writing

`fn_D01_04_core.R` `run_D01_04()` SHALL call `ensure_dna_schema()` (and equivalent helpers for other tables it writes to) before invoking `select_table_columns()` to project DNA derivation outputs into `app_data`. This guarantees that any new derivation columns added to the canonical schema are propagated to the projection target before the row data is written.

#### Scenario: D01_04 runs against schema-drifted app_data

- **WHEN** `run_D01_04(platform_id = "cbz")` runs against an `app_data` database whose `df_dna_by_customer` table is missing `p_alive`
- **THEN** the function SHALL invoke `ensure_dna_schema(app_data)` before writing `customer_dna`
- **AND** the resulting `df_dna_by_customer` table SHALL contain the `p_alive` column populated from the `customer_dna` data frame

#### Scenario: D01_04 runs against schema-current app_data

- **WHEN** `run_D01_04(platform_id = "cbz")` runs against an `app_data` database whose schema already matches the canonical definition
- **THEN** `ensure_dna_schema()` SHALL be called (idempotent no-op) and `run_D01_04` SHALL complete without warnings about column drops

### Requirement: select_table_columns SHALL Warn on Silent Column Drop

`fn_D01_04_core.R` `select_table_columns()` SHALL emit an R `warning()` whenever the input data frame contains columns that are not present in the target table. The warning message SHALL list every dropped column name and SHALL recommend running the appropriate `ensure_<table>_schema()` migration helper. The function SHALL still drop the unmatched columns to avoid breaking the immediate write, but the warning ensures schema drift is no longer silent.

#### Scenario: Input has extra columns missing from target

- **WHEN** `select_table_columns(con, "df_dna_by_customer", df)` is called with a data frame containing column `p_alive` but the target table does not have `p_alive`
- **THEN** R SHALL emit a `warning()` containing the literal column name `p_alive`
- **AND** the warning SHALL contain the literal string "ensure_dna_schema"
- **AND** the function SHALL still return the data frame restricted to the intersection of column names

#### Scenario: Input columns are subset of target

- **WHEN** `select_table_columns(con, "df_dna_by_customer", df)` is called with a data frame whose columns are all present in the target table (no drops needed)
- **THEN** the function SHALL NOT emit any warning
- **AND** the returned data frame SHALL be identical to the input

### Requirement: customerRetention SHALL Use dbplyr median Translation

The `customerRetention.R` Shiny component SHALL NOT use raw `DBI::dbGetQuery()` calls containing the `MEDIAN()` SQL function (which is DuckDB-only). Instead, the component SHALL use `tbl2() %>% dplyr::group_by() %>% dplyr::summarise(... = median(..., na.rm = TRUE)) %>% dplyr::collect()` so that dbplyr translates `median()` into the appropriate driver-specific SQL function (DuckDB `MEDIAN()` or PostgreSQL `percentile_cont(0.5) WITHIN GROUP`).

#### Scenario: customerRetention runs against DuckDB local backend

- **WHEN** the `customerRetention` component is rendered with `app_connection` pointing to a local DuckDB `app_data.duckdb`
- **THEN** the `overall_repurchase_data()` and `category_data()` reactives SHALL return non-NULL data frames containing `median_ipt` values
- **AND** no R error SHALL be raised about `MEDIAN` or `dbGetQuery`

#### Scenario: customerRetention runs against PostgreSQL Supabase backend

- **WHEN** the `customerRetention` component is rendered with `app_connection` pointing to a Supabase PostgreSQL connection
- **THEN** the `overall_repurchase_data()` and `category_data()` reactives SHALL return non-NULL data frames containing `median_ipt` values computed via `percentile_cont(0.5) WITHIN GROUP`
- **AND** no PostgreSQL error SHALL be raised about `function median(double precision) does not exist`

### Requirement: Shiny Components SHALL Not Use Raw dbGetQuery for Reads

All Shiny components in `shared/global_scripts/10_rshinyapp_components/` SHALL NOT use `DBI::dbGetQuery()` for SELECT operations. Database reads SHALL use `tbl2()` followed by `dplyr` verbs, with `dplyr::collect()` to materialize results. This requirement applies to the nine components currently violating this rule: `customerRetention`, `customerAcquisition`, `revenuePulse`, `customerEngagement`, `comprehensiveDiagnosis` (both `tagpilot/` and `vitalsigns/` copies), `worldMap`, `macroTrends`, and `reportIntegration`.

#### Scenario: Component uses tbl2 for filter and collect

- **WHEN** any of the nine listed components fetches data from `app_connection`
- **THEN** the source code SHALL contain `tbl2(app_connection, ...)` followed by dplyr verbs
- **AND** the source code SHALL NOT contain `DBI::dbGetQuery(app_connection, ...)` for SELECT statements

#### Scenario: Grep audit confirms zero raw SELECT calls

- **WHEN** `grep -rn "DBI::dbGetQuery" shared/global_scripts/10_rshinyapp_components/` is executed against the affected components after migration
- **THEN** the output SHALL NOT contain any line matching `DBI::dbGetQuery(.*SELECT` for the nine listed components
- **AND** any remaining `DBI::dbGetQuery` calls SHALL be confined to write operations (DELETE/UPDATE/INSERT) which are explicitly permitted

### Requirement: Production MAMBA Dashboard SHALL Render Without PostgreSQL Errors

After deployment, the MAMBA Posit Connect dashboard SHALL render the following components without producing any PostgreSQL errors in the application log: `dashboardOverview`, `customerRetention`, `customerLifecycle`, `customerActivity`, `customerValue`, `revenuePulse`, `customerAcquisition`. Specifically, the log SHALL NOT contain entries matching `column .* does not exist` or `function .* does not exist`.

#### Scenario: Post-deployment manual verification

- **WHEN** an operator opens the MAMBA Posit Connect URL after deploying this change and logs in with the `VIBE` test password
- **AND** navigates to dashboardOverview, customerRetention, customerLifecycle, customerActivity in sequence
- **THEN** each component SHALL render its primary KPIs and charts without displaying "No data" placeholders for the `all` product line slice
- **AND** the Posit Connect application log SHALL NOT contain any `[customerRetention] Data load error: Failed to prepare query` entries
- **AND** the Posit Connect application log SHALL NOT contain any `[dashboardOverview] DNA load error:` entries with empty error messages

#### Scenario: Supabase schema verification

- **WHEN** an operator queries the Supabase `df_dna_by_customer` table for column names after deployment
- **THEN** the result SHALL include both `p_alive` and `btyd_expected_transactions` columns
- **AND** these columns SHALL contain non-NULL values for at least one row per `platform_id` value present in the table
