# mamba-etl-complete-source-capture Specification

## Purpose

TBD - created by archiving change 'fix-mamba-etl-complete-capture'. Update Purpose after archive.

## Requirements

### Requirement: cbz ETL 0IM SHALL Iterate All Pages Until Exhaustion

The cbz ETL 0IM scripts (`cbz_ETL_orders_0IM.R`, `cbz_ETL_sales_0IM.R`, `cbz_ETL_customers_0IM.R`, `cbz_ETL_products_0IM.R`) SHALL iterate the Cyberbiz REST API pagination using a `while (has_more)` loop that continues until a page response contains fewer rows than `per_page`, indicating the last page has been reached. Each script SHALL NOT impose a `MAX_PAGES_PER_ENDPOINT` hard cap below 10000, and the safety ceiling of 10000 SHALL only exist as an infinite-loop guard.

#### Scenario: API has more rows than per_page × 20

- **WHEN** cbz_ETL_orders_0IM.R is run against a Cyberbiz account with 1,500 orders using `per_page = 50`
- **THEN** the script SHALL make 30 successful API calls (pages 1-30) plus 1 final call returning fewer than 50 rows
- **AND** the resulting `df_cbz_orders___raw` SHALL contain 1,500 rows
- **AND** the script SHALL log the total page count at completion

#### Scenario: API returns empty page at end

- **WHEN** cbz_ETL_orders_0IM.R reaches a page that returns 0 rows or fewer than `per_page` rows
- **THEN** the iteration SHALL terminate gracefully
- **AND** `has_more` SHALL be set to FALSE

#### Scenario: Runaway API returns infinite pages (safety guard)

- **WHEN** the script has executed 10000 iterations without termination
- **THEN** the script SHALL abort with an error message indicating a likely API misbehavior


<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->

---
### Requirement: ETL Scripts SHALL Use Shared API Retry Backoff Helper

All MAMBA ETL 0IM scripts making REST API calls SHALL use the shared function `api_call_with_retry()` located at `shared/global_scripts/26_platform_apis/fn_api_retry_backoff.R`. The helper SHALL accept a function reference, retry up to a configurable maximum number of attempts on retryable HTTP statuses (429, 500, 502, 503, 504), and apply exponential backoff delay between attempts.

#### Scenario: Transient HTTP 429 Too Many Requests

- **WHEN** `api_call_with_retry(fn, max_retries = 5, base_delay = 1, backoff_factor = 2)` is called and the first attempt returns HTTP 429
- **THEN** the helper SHALL wait 1 second, then retry
- **AND** if the second attempt returns HTTP 429, the helper SHALL wait 2 seconds, then retry
- **AND** on successful response, the helper SHALL return the response without further retries

#### Scenario: Non-retryable HTTP 401 Unauthorized

- **WHEN** `api_call_with_retry(fn)` is called and the attempt returns HTTP 401
- **THEN** the helper SHALL raise an error immediately without retrying
- **AND** the error message SHALL include the HTTP status and response body

#### Scenario: Retries exhausted

- **WHEN** `api_call_with_retry(fn, max_retries = 5)` is called and all 6 attempts (1 initial + 5 retries) fail with HTTP 500
- **THEN** the helper SHALL raise an error after the 6th attempt with message indicating retries exhausted


<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->

---
### Requirement: cbz ETL 0IM SHALL Emit Smoke-Assertion on Minimum Customer Count

Each cbz 0IM script SHALL emit a terminal `stopifnot` assertion checking that the resulting raw table contains at least a minimum number of distinct entities, to catch silent under-capture bugs. For `cbz_ETL_orders_0IM.R` and `cbz_ETL_customers_0IM.R`, the assertion SHALL check unique `customer_id` count is greater than 100.

#### Scenario: Raw table has enough customers

- **WHEN** cbz_ETL_orders_0IM.R completes and `df_cbz_orders___raw` has 800 unique `customer_id`
- **THEN** the assertion `stopifnot(...)` SHALL pass without error
- **AND** the script SHALL complete with exit code 0

#### Scenario: Raw table has too few customers (under-capture)

- **WHEN** cbz_ETL_orders_0IM.R completes but `df_cbz_orders___raw` has only 47 unique `customer_id`
- **THEN** the assertion SHALL raise an error indicating under-capture
- **AND** the pipeline SHALL NOT proceed to 1ST / 2TR stages until the issue is resolved


<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->

---
### Requirement: eby ETL 1ST SHALL Not Drop More Than Documented Rate

The eby ETL 1ST scripts (`eby_ETL_orders_1ST___MAMBA.R`, `eby_ETL_sales_1ST___MAMBA.R`) SHALL NOT drop more than a documented ratio of rows between raw and staged tables. If a drop occurs due to legitimate business logic (e.g. order-line aggregation, dedup), the script SHALL log the transformation clearly and the expected drop ratio SHALL be documented inline.

#### Scenario: Raw-to-staged ratio is within documented range

- **WHEN** eby_ETL_orders_1ST___MAMBA.R processes 33,895 rows from raw `df_eby_orders___raw___MAMBA`
- **AND** the documented transformation is "order headers; 1:1 ratio (no aggregation)"
- **THEN** the output `df_eby_orders___staged___MAMBA` SHALL have row count greater than or equal to 33,895 times 0.8 (allowing 20% for dedup / invalid rows)

#### Scenario: Raw-to-staged drop exceeds documented ratio

- **WHEN** eby_ETL_orders_1ST___MAMBA.R reduces 33,895 raw rows to 3,701 staged rows without documented aggregation justifying a 10x drop
- **THEN** the script SHALL emit a `warning()` indicating unexpected row drop ratio
- **AND** the script SHALL log the transformation step-by-step row count diagnostic

#### Scenario: Row count diagnostic in logs

- **WHEN** eby_ETL_orders_1ST___MAMBA.R is run with instrumentation enabled
- **THEN** the log SHALL contain a message after each dplyr verb showing `rows=<count>` for traceability


<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->

---
### Requirement: Pipeline Re-Run SHALL Produce Minimum Customer Coverage in app_data

After a full ETL re-run from 0IM through D01_04 for both cbz and eby platforms, the `df_dna_by_customer` table in MAMBA `app_data` SHALL contain at least 800 distinct `customer_id` values combined across `platform_id = 'cbz'` and `platform_id = 'eby'`.

#### Scenario: Post-rerun verification of customer coverage

- **WHEN** the MAMBA pipeline runs end-to-end after the ETL fixes from this change
- **THEN** `SELECT COUNT(DISTINCT customer_id) FROM df_dna_by_customer WHERE product_line_id_filter = 'all'` SHALL return a value greater than or equal to 800
- **AND** the breakdown per platform SHALL show `cbz` customers substantially greater than 47 and `eby` customers substantially greater than 9

#### Scenario: Dashboard reflects full customer pool

- **WHEN** an operator opens the MAMBA Posit Connect dashboard and navigates to the customerAcquisition or dashboardOverview tab
- **THEN** the displayed total customer count SHALL be 800 or greater
- **AND** MoM/YoY growth rate indicators SHALL be computed from non-sparse historical data


<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->

---
### Requirement: Orphan Legacy Tables SHALL Be Removed Only After Verification

Legacy orphan tables in `data/local_data/staged_data.duckdb` (e.g. `df_cbz_sales_staged`, `df_eby_sales___staged___MAMBA`, `df_eby_orders___staged___MAMBA`) SHALL be DROP-ed only after the new ETL pipeline re-run has been verified to produce the required customer coverage and after a grep of the entire codebase confirms no active scripts reference these tables.

#### Scenario: Successful verification precedes cleanup

- **WHEN** the MAMBA ETL re-run has passed the Post-rerun verification scenario above
- **AND** a codebase grep for each orphan table name returns zero active (non-archived, non-documentation) hits
- **THEN** the orphan tables SHALL be DROP-ed via `DBI::dbRemoveTable()`
- **AND** the cleanup operation SHALL be logged with table name and row count at time of removal

#### Scenario: Active reference found during grep

- **WHEN** a codebase grep for orphan table `df_cbz_sales_staged` finds an active reference in an R script
- **THEN** the orphan table SHALL NOT be DROP-ed
- **AND** a follow-up issue SHALL be opened to migrate the active reference to the new naming convention

<!-- @trace
source: fix-mamba-etl-complete-capture
updated: 2026-04-14
code:
  - AGENTS.md
  - MAMBA
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/nsql
  - shared/update_scripts
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .agents/skills/spectra-archive/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - QEF_DESIGN
  - shared/global_scripts
  - shared/handbook
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
-->