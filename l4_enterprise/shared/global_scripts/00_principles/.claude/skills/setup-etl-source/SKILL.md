---
name: setup-etl-source
description: |
  Configure ETL data sources in app_config.yaml following DM_R037 v3.0.
  Supports rawdata (Excel/CSV) and Google Sheets sources.
  Includes intelligent tab matching for Google Sheets.
  Use when setting up, configuring, or adding ETL sources, data sources, or scanning Google Sheet tabs.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# ETL Source Configuration Skill

## Overview

This skill configures ETL data sources in `app_config.yaml` under `platforms.{platform}.etl_sources`, following DM_R037 v3.0 (Config-Driven Import). It ensures all connection parameters (file paths, sheet IDs, tab names) live in config rather than hardcoded in scripts.

## Principles

- **DM_R037 v3.0**: Config-Driven Import — filenames are standard `{platform}_ETL_{datatype}_0IM.R`, source metadata in `app_config.yaml`
- **DM_R028**: ETL Data Type Separation
- **MP029**: No fake data or placeholder values in production config
- **MP064**: ETL-Derivation Separation

## Execution Flow

### Step 1: Read Current Config

```bash
# Read existing etl_sources from app_config.yaml
```

Read `app_config.yaml` and identify:
- Which platform(s) are active
- Which `etl_sources` entries already exist
- Which entries have `source_type: "gsheets"` vs `"excel"` vs `"csv"`

### Step 2: Choose Mode

Ask the user:

**Mode A: Add/Modify Single Source**
- For adding a new data type or updating an existing one

**Mode B: Batch Scan Google Sheet**
- For scanning all tabs in a Google Sheet and auto-mapping them to etl_sources entries
- Best for initial setup or migration

### Mode A: Single Source Setup

#### A1. Collect Parameters

Ask the user:
1. **Platform**: Which platform? (e.g., amz, cbz, eby)
2. **Data type name**: The etl_sources key (e.g., `sales`, `product_profiles`, `reviews`)
3. **Source type**: `excel` / `csv` / `gsheets`

#### A2a. For Rawdata (Excel/CSV)

Ask for:
- `rawdata_pattern` (glob pattern) or `rawdata_path` (exact path)
- Pattern is relative to `RAW_DATA_DIR` from config

Write to config:
```yaml
etl_sources:
  {datatype}:
    source_type: "excel"  # or "csv"
    version: "v1"
    rawdata_pattern: "{pattern}"  # or rawdata_path
```

#### A2b. For Google Sheets

1. Ask for `sheet_id` (default: use `googlesheet.coding` from config if exists)
2. **Auto-discover tabs**: Run R to list all tab names:
   ```r
   Rscript -e '
     library(googlesheets4)
     gs4_deauth()
     tabs <- sheet_names("{sheet_id}")
     cat(tabs, sep="\n")
   '
   ```
3. **AI Smart Matching**: Present the tab list and suggest which tab(s) correspond to this data type
4. Ask for additional params based on the import function:
   - `sheet_name`: exact tab name (for single-tab sources like `competitor_ids`)
   - `sheet_name_prefix`: tab name prefix (for multi-tab sources like `product_profiles`)
   - No `sheet_name` needed if the import function derives it internally (like `comment_properties`)

Write to config:
```yaml
etl_sources:
  {datatype}:
    source_type: "gsheets"
    version: "v1"
    sheet_id: "{sheet_id}"
    sheet_name: "{tab_name}"  # if applicable
```

#### A3. Check Existing 0IM Script

Check if `{platform}_ETL_{datatype}_0IM.R` exists.

**If NOT exists** → go to A3a (Scaffold).
**If exists** → go to A3b (Compatibility Check).

#### A3a. Scaffold 0IM Script (new)

1. Read the appropriate adapter function from `scripts/global_scripts/05_etl_utils/`
2. Generate the 0IM script using the standard template structure:
   - INITIALIZE: autoinit(), get_platform_config(), read etl_profile
   - MAIN: call the adapter function with config params
   - TEST: verify data was imported
   - DEINITIALIZE: cleanup

The script MUST read ALL connection params from `src_cfg`:
```r
platform_cfg <- get_platform_config("{platform}")
src_cfg <- platform_cfg$etl_sources${datatype}
```

#### A3b. Compatibility Check (existing script)

When a 0IM script already exists, diagnose whether it can handle the new company's source:

1. **Read the script** — check which `source_type` values it supports
2. **Compare with config** — does the config `source_type` match a supported path?
3. **Decision tree** (following ETL_EXTENSIBLE + ETL_DECISION from CH11):

```
Existing 0IM script found. Can it handle this company?
│
├── source_type not supported (e.g., script only handles "excel", config says "gsheets")
│   └── EXTEND shared script — add new source_type path
│       Example: add gsheets dual-path alongside existing excel path
│
├── source_type matches, but column names differ
│   └── EXTEND col_mapping in shared script — add new column name variants
│       (Generic extension benefits all companies)
│
├── source_type matches, but sheet structure fundamentally different
│   (e.g., multi-tab vs single-tab, nested headers, pivoted layout)
│   └── CREATE ___COMPANY variant
│       File: {platform}_ETL_{datatype}_0IM___{COMPANY_CODE}.R
│
└── Requires company-specific business logic in import
    (e.g., special filtering, custom ID generation, unique validation)
    └── CREATE ___COMPANY variant
```

**Key principle**: "Generic pattern exists before creating specific?" (CH11 platform_specific_etl checklist)

- Always try to **extend the shared script first** (col_mapping, source_type paths)
- Only create `___COMPANY` variant when the difference is **structural**, not just naming

#### A3c. Creating a ___COMPANY Variant

When a company variant is needed (following ETL_EXTENSIBLE):

1. **Copy** the generic script as starting point:
   ```bash
   cp {platform}_ETL_{datatype}_0IM.R {platform}_ETL_{datatype}_0IM___{COMPANY_CODE}.R
   ```

2. **Modify** only the company-specific parts (keep shared patterns intact)

3. **Update pipeline config** — the `_targets.R` / Makefile must know to dispatch:
   - If `___COMPANY` variant exists for current company → use it
   - Otherwise → use generic script

4. **Document** why the variant was needed (comment at top of file)

#### A4. Verify (3-tier)

**Tier 1: Static Check**
- R parse check: `Rscript -e "parse('{script_path}')"`
- Confirm config entry exists and has all required fields

**Tier 2: Run 0IM + Check DB**
- Run the ETL via pipeline:
  ```bash
  cd scripts/update_scripts
  make run TARGET={platform}_ETL_{datatype}_0IM
  ```
- If pipeline completes, query the output table in raw_data.duckdb:
  ```r
  con <- DBI::dbConnect(duckdb::duckdb(), "data/database/raw_data.duckdb", read_only = TRUE)
  result <- DBI::dbGetQuery(con, "SELECT COUNT(*) as n FROM {output_table}")
  DBI::dbDisconnect(con)
  ```
- Report: `{output_table}: {n} rows imported`

**Tier 3: Product Line Coverage**
- If the output table has a `product_line_id` column, check coverage:
  ```r
  coverage <- DBI::dbGetQuery(con, "
    SELECT product_line_id, COUNT(*) as rows
    FROM {output_table}
    GROUP BY product_line_id
    ORDER BY product_line_id
  ")
  ```
- Compare against `get_active_product_lines()` — report which product lines have data and which are missing
- Present as a coverage table:
  ```
  Product Line Coverage ({datatype}):
  hsg: 136 rows ✅
  sfg: 99 rows  ✅
  sfo: 121 rows ✅
  ...
  Missing: (none)
  ```

**If any tier fails**, stop and report the error. Don't proceed to the next tier.

---

### Mode B: Batch Scan Google Sheet

#### B1. Read Sheet Tabs

```r
Rscript -e '
  library(googlesheets4)
  gs4_deauth()
  sheet_id <- "{sheet_id_from_config}"
  tabs <- sheet_names(sheet_id)
  cat(tabs, sep="\n")
'
```

#### B2. Read Current etl_sources

Identify gsheets entries that:
- Already have `sheet_id` but no `sheet_name` → need mapping
- Don't exist yet → potential new entries

#### B3. AI Smart Matching

For each tab in the Google Sheet:

1. **Read first 3 rows** of the tab to understand its structure:
   ```r
   Rscript -e '
     library(googlesheets4)
     gs4_deauth()
     data <- read_sheet("{sheet_id}", sheet = "{tab_name}", n_max = 3)
     cat("Columns:", paste(names(data), collapse = ", "), "\n")
   '
   ```

2. **Semantic matching** — compare tab content against known data type signatures:

   | Data Type | Signature Columns | Tab Pattern |
   |-----------|-------------------|-------------|
   | `product_profiles` | ASIN/SKU, brand, product attributes (0/1 coded) | Product line Chinese names |
   | `competitor_ids` | product_line, brand, ASIN/product_number | "競爭者", "產品對照表" |
   | `comment_properties` | property_id, property_name, levels | "水準表" suffix tabs |
   | `keys` | SKU, ASIN, cost data | "SKU to ASIN" |
   | `product_line` | product_line_id, name_chinese, name_english | "Product Line" |

3. **Present mapping** to user:
   ```
   Tab Discovery Results:

   1. "安全眼鏡＿hunting-safety-glasses"
      → Matches: product_profiles (has ASIN, brand, 0/1 attributes)

   2. "安全眼鏡＿hunting-safety-glasses水準表"
      → Matches: comment_properties (has property_id, property_name, levels)

   3. "產品對照表"
      → Matches: competitor_ids (has product_line columns with ASIN)

   4. "SKU to ASIN"
      → Matches: keys (has SKU, cost data)

   5. "Product Line"
      → Matches: product_line metadata

   6. "產品類別彙整表" — summary table, not directly importable
   7. "進度表" — tracking table, skip

   Confirm mapping?
   ```

4. Tabs that end with `_原` (original) are backup copies → skip by default

#### B4. Update Config

For confirmed mappings, update `app_config.yaml`:
- Add `sheet_id` to each gsheets entry
- Add `sheet_name` or `sheet_name_prefix` as appropriate
- Add comments explaining the tab structure

#### B5. Update 0IM Scripts

For each gsheets entry:
- Replace any hardcoded sheet IDs with `src_cfg$sheet_id`
- Replace any hardcoded tab names with `src_cfg$sheet_name`
- Ensure retry logic exists for Google API timeouts

#### B6. Verify All

```bash
# No hardcoded sheet IDs remain
grep -rn "16-k48xx\|app_configs\$googlesheet" scripts/update_scripts/ETL/amz/*_0IM.R

# All read from etl_sources
grep -rn "src_cfg\$sheet_id\|etl_sources" scripts/update_scripts/ETL/amz/*_0IM.R

# R parse check
for f in scripts/update_scripts/ETL/amz/*_0IM.R; do
  Rscript -e "parse('$f')" && echo "OK: $f"
done
```

---

## Config Schema Reference

### Rawdata Source (Excel)
```yaml
{datatype}:
  source_type: "excel"
  version: "v1"
  rawdata_pattern: "subfolder/**/*.xlsx"  # glob relative to RAW_DATA_DIR
  # OR
  rawdata_path: "FILENAME.xlsx"           # exact file relative to RAW_DATA_DIR
```

### Rawdata Source (CSV)
```yaml
{datatype}:
  source_type: "csv"
  version: "v1"
  rawdata_pattern: "subfolder/*.csv"
```

### Google Sheets Source
```yaml
{datatype}:
  source_type: "gsheets"
  version: "v1"
  sheet_id: "1abc..."                     # Google Sheet ID
  sheet_name: "exact_tab_name"            # For single-tab sources
  # OR
  sheet_name_prefix: "prefix"             # For multi-tab sources (prefix_productline)
  # OR omit sheet_name if the import function derives it from df_product_line
```

---

## 0IM Script Template (for scaffold)

```r
# {platform}_ETL_{datatype}_0IM.R - {Platform} {Datatype} Import
# Following DM_R028, DM_R037 v3.0: Config-Driven Import
# ETL {datatype} Phase 0IM: Import from {source_description}
# Output: raw_data.duckdb -> {output_table}

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

sql_read_candidates <- c(
  file.path("scripts", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "..", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "..", "..", "global_scripts", "02_db_utils", "fn_sql_read.R")
)
sql_read_path <- sql_read_candidates[file.exists(sql_read_candidates)][1]
if (is.na(sql_read_path)) stop("fn_sql_read.R not found in expected paths")
source(sql_read_path)
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL

# Set required dependencies before initialization
# needgoogledrive <- TRUE  # Uncomment for gsheets sources

autoinit()

# Read ETL profile from config (DM_R037 v3.0)
source(file.path(GLOBAL_DIR, "04_utils", "fn_get_platform_config.R"))
platform_cfg <- get_platform_config("{platform}")
src_cfg <- platform_cfg$etl_sources${datatype}
message(sprintf("PROFILE: source_type=%s, version=%s",
                src_cfg$source_type, src_cfg$version))

raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)

message("INITIALIZE: {Platform} {datatype} import initialized")

# ==============================================================================
# 2. MAIN
# ==============================================================================

tryCatch({
  message("MAIN: Starting {datatype} import...")

  # TODO: Call appropriate adapter function with src_cfg params
  # import_result <- import_{datatype}(
  #   db_connection = raw_data,
  #   ...params from src_cfg...
  # )

  script_success <- TRUE
  message("MAIN: {datatype} import completed successfully")

}, error = function(e) {
  main_error <<- e
  script_success <<- FALSE
  message("MAIN ERROR: ", e$message)
})

# ==============================================================================
# 3. TEST
# ==============================================================================

if (script_success) {
  tryCatch({
    message("TEST: Verifying {datatype} import...")
    # TODO: Verify output tables exist and have data
    test_passed <- TRUE
    message("TEST: Verification successful")
  }, error = function(e) {
    test_passed <<- FALSE
    message("TEST ERROR: ", e$message)
  })
} else {
  message("TEST: Skipped due to main script failure")
}

# ==============================================================================
# 4. DEINITIALIZE
# ==============================================================================

if (script_success && test_passed) {
  message("DEINITIALIZE: Script completed successfully with verification")
  return_status <- TRUE
} else if (script_success && !test_passed) {
  message("DEINITIALIZE: Script completed but verification failed")
  return_status <- FALSE
} else {
  message("DEINITIALIZE: Script failed during execution")
  if (!is.null(main_error)) message("DEINITIALIZE: Error - ", main_error$message)
  return_status <- FALSE
}

DBI::dbDisconnect(raw_data)
autodeinit()
message("DEINITIALIZE: {platform}_ETL_{datatype}_0IM.R completed")
```

## Notes

- Google Sheets require `gs4_deauth()` for public sheets or proper auth for private ones
- Set `needgoogledrive <- TRUE` before `autoinit()` for gsheets sources
- Always add `options(gargle_timeout = 60)` and retry logic for gsheets to handle API timeouts
- Tab names with `＿` (fullwidth underscore) are common in Chinese Google Sheets
