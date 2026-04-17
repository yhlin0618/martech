# mamba-derivation-coverage Specification

## Purpose

TBD - created by archiving change 'mamba-complete-derivation-coverage'. Update Purpose after archive.

## Requirements

### Requirement: D03 Geographic Aggregation SHALL Preserve Cross-Platform Data

The `fn_D03_01_core.R` core function SHALL write geographic aggregation tables (`df_geo_sales_by_country`, `df_geo_sales_by_state`, `df_customer_country_map`) using a preserve-other-platforms merge pattern instead of `dbWriteTable(overwrite = TRUE)`. When called sequentially for multiple platforms (e.g., cbz then eby via `all_D03_01.R` loop), each invocation SHALL retain rows for platforms not currently being processed.

#### Scenario: Sequential platform writes preserve earlier platform data

- **WHEN** `run_D03_01("cbz")` writes `df_geo_sales_by_country` with 50 cbz rows, then `run_D03_01("eby")` writes 30 eby rows
- **THEN** the resulting `df_geo_sales_by_country` table SHALL contain 80 rows (50 cbz + 30 eby)
- **AND** the `app_data` connection SHALL emit log message `[eby] Merged: 30 new + 50 preserved from other platforms`

#### Scenario: Schema mismatch between platforms emits warning instead of silent drop

- **WHEN** the existing rows have a different schema than the new platform's data such that `bind_rows` fails
- **THEN** the function SHALL emit an explicit `WARNING` listing the affected platforms whose rows are dropped
- **AND** the function SHALL preserve only the new platform's data
- **AND** the function SHALL NOT silently lose data without warning


<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->

---
### Requirement: all_D03_01 Script SHALL Loop Over Multiple Active Platforms

The `all_D03_01.R` orchestration script SHALL iterate over all active non-aggregate platforms and call `run_D03_01(platform_id)` for each. The pre-check that aborts on multiple platforms SHALL be removed.

#### Scenario: Two-platform MAMBA pipeline runs both cbz and eby through D03_01

- **WHEN** `MAMBA/app_config.yaml` enables both `cbz` and `eby` platforms with `drv_groups` containing `D03`
- **WHEN** `make run TARGET=all_D03_01` executes
- **THEN** the script SHALL call `run_D03_01("cbz")` followed by `run_D03_01("eby")`
- **AND** the script SHALL NOT abort with "2 platforms detected" error
- **AND** the resulting `df_geo_sales_by_country` SHALL contain rows for both cbz and eby


<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->

---
### Requirement: D05 Macro Monthly Summary SHALL Have Per-Platform Scripts for cbz and eby

The MAMBA pipeline SHALL include three new D05 scripts: `cbz_D05_01.R`, `eby_D05_01.R`, and `all_D05_01.R`. The platform-specific scripts SHALL set `platform_id` to their respective platform code and source `fn_D05_01_core.R`. The `all_D05_01.R` orchestrator SHALL loop over active non-aggregate platforms.

#### Scenario: cbz_D05_01 script exists and runs successfully

- **WHEN** `make run TARGET=cbz_D05_01` executes
- **THEN** the script `shared/update_scripts/DRV/cbz/cbz_D05_01.R` SHALL exist
- **AND** running it SHALL call `run_D05_01("cbz")` from `fn_D05_01_core.R`
- **AND** SHALL produce or update `app_data.df_macro_monthly_summary` with cbz rows
- **AND** SHALL exit successfully

#### Scenario: eby_D05_01 script exists and runs successfully

- **WHEN** `make run TARGET=eby_D05_01` executes
- **THEN** the script `shared/update_scripts/DRV/eby/eby_D05_01.R` SHALL exist
- **AND** SHALL produce or update `app_data.df_macro_monthly_summary` with eby rows

#### Scenario: all_D05_01 script loops over active platforms

- **WHEN** `make run TARGET=all_D05_01` executes with cbz and eby both active
- **THEN** the script SHALL call `run_D05_01("cbz")` followed by `run_D05_01("eby")`
- **AND** the resulting `df_macro_monthly_summary` SHALL contain rows for both cbz and eby


<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->

---
### Requirement: fn_D05_01_core SHALL Use Cross-Platform-Safe Write Pattern

The `fn_D05_01_core.R` core function SHALL write `df_macro_monthly_summary` using the same preserve-other-platforms merge pattern as `fn_D03_01_core.R`, ensuring that loop-based execution across multiple platforms does not silently lose earlier platform data.

#### Scenario: Cross-platform write preserves earlier platform rows

- **WHEN** `run_D05_01("cbz")` writes `df_macro_monthly_summary` with cbz monthly aggregates, then `run_D05_01("eby")` writes eby aggregates
- **THEN** the resulting table SHALL contain rows for both cbz and eby
- **AND** the function SHALL emit a `Merged:` log message identifying preserved row counts


<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->

---
### Requirement: MAMBA Pipeline Config SHALL Enable D03 and D05 for All Active Platforms

The `MAMBA/app_config.yaml` `pipeline.platforms` section SHALL include D03 and D05 in the `drv_groups` list for `cbz`, `eby`, and `all`. The `all.drv_groups` list MUST include D03 and D05 (in addition to existing D01).

#### Scenario: cbz drv_groups includes D03 and D05

- **WHEN** the merged `_targets_config.yaml` is generated via `make config-full`
- **THEN** `platforms.cbz.drv_groups` SHALL contain at least `D00`, `D01`, `D03`, `D05`

#### Scenario: eby drv_groups includes D03 and D05

- **WHEN** the merged `_targets_config.yaml` is generated
- **THEN** `platforms.eby.drv_groups` SHALL contain at least `D00`, `D01`, `D03`, `D05`

#### Scenario: all drv_groups includes D03 and D05

- **WHEN** the merged `_targets_config.yaml` is generated
- **THEN** `platforms.all.drv_groups` SHALL contain at least `D01`, `D03`, `D05`
- **AND** SHALL NOT include `D02` (not a real group; was a YAML list-collapse workaround)


<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->

---
### Requirement: Pipeline Health Check SHALL Confirm Coverage After Migration

After this change is applied, the `pipeline-health` skill SHALL report that all critical app_data tables exist with rows for both cbz and eby active platforms.

#### Scenario: All critical app_data tables present with cross-platform rows

- **WHEN** `pipeline-health` skill runs against the MAMBA company directory after `make run` completes
- **THEN** `app_data.df_dna_by_customer` SHALL exist with rows for both cbz and eby
- **AND** `app_data.df_macro_monthly_summary` SHALL exist with rows for both cbz and eby
- **AND** `app_data.df_geo_sales_by_country` SHALL exist with rows for both cbz and eby
- **AND** `app_data.df_geo_sales_by_state` SHALL exist with rows for both cbz and eby
- **AND** `app_data.df_customer_country_map` SHALL exist
- **AND** `app_data.df_rsv_classified` SHALL exist with rows for both cbz and eby

#### Scenario: No new errors in targets metadata after pipeline run

- **WHEN** `make run` completes after this change is applied
- **WHEN** `targets::tar_meta()` is queried for the MAMBA `_targets` store
- **THEN** the count of rows with non-empty `error` field SHALL be zero
- **AND** stale errors from prior runs (such as `eby_etl_sales_2TR` and `all_D03_01` from earlier failed retries) SHALL be cleared

<!-- @trace
source: mamba-complete-derivation-coverage
updated: 2026-04-13
code:
  - shared/global_scripts
  - .agents/skills/spectra-discuss/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - CLAUDE.md
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - shared/handbook
  - .agents/skills/spectra-ask/SKILL.md
  - .agents/skills/spectra-ingest/SKILL.md
  - shared/update_scripts
  - shared/nsql
  - .claude
  - .spectra.yaml
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - MAMBA
  - QEF_DESIGN
  - .agents/skills/spectra-archive/SKILL.md
  - AGENTS.md
-->