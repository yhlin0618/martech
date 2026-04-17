# Precision Marketing DRV (Derived) Layer

**Week 2 Implementation**: MAMBA Precision Marketing ETL+DRV Redesign
**Completion Date**: 2025-11-13
**Coordinator**: principle-product-manager

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Principle Compliance](#principle-compliance)
4. [DRV Scripts](#drv-scripts)
5. [Utility Functions](#utility-functions)
6. [Database Schema](#database-schema)
7. [Usage](#usage)
8. [Validation](#validation)
9. [Troubleshooting](#troubleshooting)
10. [Future Enhancements](#future-enhancements)

---

## Overview

### Purpose

The **DRV (Derived) Layer** creates composite business entities and analytical datasets from ETL outputs. This layer aggregates, joins, and derives insights from the transformed data produced by the ETL pipeline.

### Key Differences: ETL vs DRV

```yaml
ETL Layer (0IM → 1ST → 2TR):
  purpose: "Process raw external data sources"
  stages: ["0IM (Import)", "1ST (Standardization)", "2TR (Transformation)"]
  input: "External APIs, files, databases"
  output: "raw_data.duckdb, staged_data.duckdb, transformed_data.duckdb"
  examples: "Import Google Sheets, standardize currencies, engineer features"

DRV Layer (2TR only):
  purpose: "Create derived analytical datasets"
  stages: ["2TR (Derivation)"]  # NO 0IM or 1ST
  input: "transformed_data.duckdb (from ETL)"
  output: "processed_data.duckdb"
  examples: "Aggregate features, complete time series, join multiple ETLs"
```

**CRITICAL (MP109)**: DRV layer implements ONLY 2TR stage. It reads from ETL outputs and creates derived entities for analysis.

---

## Architecture

### Visual Data Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ETL LAYER (Week 1)                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Google Sheets (Product Profiles)                                  │
│         ↓                                                           │
│    [ 0IM ] → raw_data.duckdb                                       │
│         ↓                                                           │
│    [ 1ST ] → staged_data.duckdb (R116 currency conversion)        │
│         ↓                                                           │
│    [ 2TR ] → transformed_data.duckdb (feature engineering)        │
│                                                                     │
│  6 Product Lines: alf, irf, pre, rek, tur, wak                    │
│  Tables: transformed_precision_alf, transformed_precision_irf, ... │
└─────────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         DRV LAYER (Week 2)                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [ DRV 2TR - Feature Preparation ]                                 │
│    Input:  transformed_data.duckdb (all 6 product lines)          │
│    Process: Union → Aggregate by product_line + country           │
│    Output: processed_data.duckdb/df_precision_features           │
│                                                                     │
│  [ DRV 2TR - Time Series Completion ]                             │
│    Input:  transformed_data.duckdb (sales data if available)      │
│    Process: Complete time series with R117 transparency           │
│    Output: processed_data.duckdb/df_precision_time_series        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Directory Structure

```
scripts/update_scripts/DRV/all/
├── README.md                                # This file
├── all_D04_09.R      # Aggregate features across products
├── all_D04_07.R              # Complete time series with R117 markers
└── validate_week2.R                         # Validation script

scripts/global_scripts/04_utils/
├── fn_aggregate_features.R                  # Feature aggregation utility (MP109)
└── fn_complete_time_series.R                # Time series completion utility (R117)

data/local_data/
├── transformed_data.duckdb                  # Input (from ETL)
└── processed_data.duckdb                    # Output (DRV tables)
    ├── df_precision_features               # Aggregated features
    └── df_precision_time_series            # Time series with transparency
```

---

## Principle Compliance

### Meta-Principles

#### MP109: DRV Derivation Layer

**Compliance**: DRV scripts implement ONLY 2TR stage (no 0IM or 1ST).

```yaml
mp109_compliance:
  stage_separation:
    etl_responsibilities: ["0IM Import", "1ST Standardization", "2TR Transformation"]
    df_responsibilities: ["2TR Derivation ONLY"]

  df_tasks:
    - "Aggregate features across product lines"
    - "Complete time series with transparency markers"
    - "Join multiple ETL outputs (future)"
    - "Calculate derived business metrics"

  validation:
    - "DRV scripts do NOT connect to external sources (no 0IM)"
    - "DRV scripts do NOT standardize raw data (no 1ST)"
    - "DRV scripts ONLY read from ETL outputs (transformed_data.duckdb)"
```

#### MP029: No Fake Data Principle

**Compliance**: All derived data is clearly marked, time series filling uses R117 transparency.

```yaml
mp029_compliance:
  feature_aggregation:
    - "Only aggregates REAL data from ETL outputs"
    - "No synthetic product profiles created"
    - "Aggregation metadata documents source (MP102)"

  time_series_filling:
    - "Uses R117 transparency markers (data_source column)"
    - "Clearly distinguishes 'REAL' vs 'FILLED' data"
    - "Fill rates calculated and warnings issued if >50%"
```

#### MP102: Completeness Principle

**Compliance**: All DRV tables include comprehensive metadata.

```yaml
mp102_metadata:
  df_precision_features:
    - "aggregation_level: Grouping dimensions used"
    - "aggregation_timestamp: When aggregation occurred"
    - "aggregation_method: Functions applied (mean, median, etc.)"
    - "source_table: Input data source"
    - "total_source_products: Input row count"

  df_precision_time_series:
    - "data_source: REAL or FILLED (R117)"
    - "filling_method: zero, forward, interpolate"
    - "filling_timestamp: When filling occurred"
    - "aggregation_timestamp: When processed"
```

### Rules

#### R117: Time Series Filling Transparency

**Compliance**: All time series filling explicitly marked with transparency columns.

```yaml
r117_compliance:
  required_columns:
    - "data_source: VARCHAR ('REAL' or 'FILLED')"
    - "filling_method: VARCHAR (zero_fill, forward_fill, etc.)"
    - "filling_timestamp: TIMESTAMP (when filling occurred)"

  validation:
    - "Check data_source column exists"
    - "Verify all rows marked (no NULL values)"
    - "Calculate fill_rate per product/dimension"
    - "Warn if fill_rate > 50% (data quality issue)"

  implementation:
    - "Use fn_complete_time_series() utility"
    - "Pass mark_filled = TRUE (enforced)"
    - "Document fill rates in metadata table"
```

#### R116: Currency Standardization (Inherited)

**Compliance**: DRV uses R116-standardized USD prices from ETL 1ST stage.

```yaml
r116_inheritance:
  etl_1st_output:
    - "price_usd: Standardized USD prices"
    - "original_price: Original currency amount"
    - "conversion_rate: Exchange rate applied"

  df_usage:
    - "All price aggregations use price_usd"
    - "No currency conversion in DRV (already done in ETL 1ST)"
    - "Price statistics calculated in USD only"
```

---

## DRV Scripts

### 1. all_D04_09.R

**Purpose**: Aggregate product features across all product lines for market-level analysis.

**Process Flow**:
```
1. Connect to transformed_data.duckdb (read-only)
2. Union all 6 product lines (alf, irf, pre, rek, tur, wak)
3. Identify continuous vs binary features
4. Aggregate continuous features by product_line + country
   - Calculate: mean, median, sd, min, max
5. Calculate prevalence for binary features (% of products with feature)
6. Add MP102 metadata
7. Write to processed_data.duckdb/df_precision_features
```

**Output Schema**: See [df_precision_features](#df_precision_features) below.

**Usage**:
```bash
# Run interactively
Rscript scripts/update_scripts/DRV/all/all_D04_09.R

# Or source in R session
source("scripts/update_scripts/DRV/all/all_D04_09.R")
result <- precision_drv_feature_preparation()
```

**Dependencies**:
- `fn_aggregate_features.R` utility
- `transformed_data.duckdb` with precision tables

---

### 2. all_D04_07.R

**Purpose**: Complete time series data with R117 transparency markers.

**Current Implementation**: PLACEHOLDER MODE

```yaml
placeholder_mode:
  reason: "Precision Marketing currently has PRODUCT PROFILES (static data)"
  explanation: "Time series analysis requires SALES DATA (temporal)"
  status: "Awaiting CBZ/eBay sales ETL completion"

  current_behavior:
    - "Creates R117-compliant placeholder table"
    - "Documents expected schema for future integration"
    - "Enables future sales data processing without code changes"

  future_activation:
    when: "CBZ/eBay ETLs populate transformed_data.duckdb with sales"
    action: "Re-run script - will auto-detect sales tables and process"
```

**Process Flow (when sales data available)**:
```
1. Connect to transformed_data.duckdb (read-only)
2. Check for sales-related tables (cbz_sales, eby_sales)
3. If found: Aggregate sales by date + product_line + country
4. Complete time series using fn_complete_time_series()
   - Mark REAL vs FILLED data (R117)
   - Calculate fill rates per group
   - Warn if fill_rate > 50%
5. Write to processed_data.duckdb/df_precision_time_series
```

**Output Schema**: See [df_precision_time_series](#df_precision_time_series) below.

**Usage**:
```bash
# Run interactively
Rscript scripts/update_scripts/DRV/all/all_D04_07.R

# Check mode (placeholder vs real data)
Rscript scripts/update_scripts/DRV/all/all_D04_07.R 2>&1 | grep "Mode:"
```

**Dependencies**:
- `fn_complete_time_series.R` utility
- Optional: Sales tables from CBZ/eBay ETLs

---

## Utility Functions

### fn_aggregate_features.R

**Location**: `scripts/global_scripts/04_utils/fn_aggregate_features.R`

**Purpose**: Aggregate product features for market-level analysis (MP109-compliant).

**Function Signature**:
```r
fn_aggregate_features(
  data,
  group_cols = c("product_line"),
  feature_cols,
  agg_functions = c("mean", "median", "sd", "min", "max"),
  include_prevalence = TRUE,
  add_metadata = TRUE
)
```

**Parameters**:
- `data`: Data frame with product features
- `group_cols`: Grouping columns (e.g., `c("product_line", "country")`)
- `feature_cols`: Features to aggregate (numeric columns)
- `agg_functions`: Statistics to calculate
- `include_prevalence`: Calculate prevalence for binary features (0/1)
- `add_metadata`: Add MP102 metadata columns

**Returns**: Data frame with aggregated features

**Example**:
```r
source("scripts/global_scripts/04_utils/fn_aggregate_features.R")

aggregated <- fn_aggregate_features(
  data = product_data,
  group_cols = c("product_line", "country"),
  feature_cols = c("price_usd", "rating", "review_count"),
  agg_functions = c("mean", "median", "sd")
)

# Result columns:
# - product_line, country, n_products
# - price_usd_mean, price_usd_median, price_usd_sd
# - rating_mean, rating_median, rating_sd
# - review_count_mean, review_count_median, review_count_sd
# - aggregation_level, aggregation_timestamp, aggregation_method
```

---

### fn_complete_time_series.R

**Location**: `scripts/global_scripts/04_utils/fn_complete_time_series.R`

**Purpose**: Complete missing time periods with R117 transparency markers.

**Function Signature**:
```r
fn_complete_time_series(
  data,
  date_col = "date",
  group_cols = c("product_line"),
  value_cols = c("sales", "orders"),
  fill_method = "forward",
  mark_filled = TRUE,           # MUST be TRUE per R117
  warn_threshold = 0.50,
  time_unit = "day"
)
```

**Parameters**:
- `data`: Data frame with time series data
- `date_col`: Name of date column
- `group_cols`: Grouping dimensions
- `value_cols`: Value columns to fill
- `fill_method`: "forward" (LOCF), "zero", or "interpolate"
- `mark_filled`: Add data_source column (REQUIRED by R117)
- `warn_threshold`: Warning threshold for fill rate (default 0.50)
- `time_unit`: Time granularity ("day", "week", "month")

**Returns**: List with two elements:
- `data`: Completed data frame with transparency markers
- `fill_rate_summary`: Fill rate statistics per group

**Example**:
```r
source("scripts/global_scripts/04_utils/fn_complete_time_series.R")

result <- fn_complete_time_series(
  data = sales_data,
  date_col = "date",
  group_cols = c("product_line", "country"),
  value_cols = c("sales", "revenue"),
  fill_method = "zero",          # Missing sales = 0 sales
  mark_filled = TRUE,             # R117 required
  warn_threshold = 0.50
)

completed_data <- result$data
fill_stats <- result$fill_rate_summary

# Result columns added:
# - data_source: 'REAL' or 'FILLED'
# - filling_method: 'zero'
# - filling_timestamp: when filling occurred
```

---

## Database Schema

### df_precision_features

**Purpose**: Aggregated product features by product_line and country.

**Granularity**: `product_line + country`

**Schema**:
```yaml
columns:
  # Grouping dimensions
  product_line:
    type: VARCHAR
    description: "Product line identifier (alf, irf, pre, rek, tur, wak)"
    pk: true

  country:
    type: VARCHAR
    description: "Country dimension (from R116 currency conversion)"
    pk: true

  n_products:
    type: INTEGER
    description: "Number of products in this group"

  # Price statistics (in USD per R116)
  price_usd_mean:
    type: DOUBLE
    description: "Mean price in USD"

  price_usd_median:
    type: DOUBLE
    description: "Median price in USD"

  price_usd_sd:
    type: DOUBLE
    description: "Standard deviation of price in USD"

  price_usd_min:
    type: DOUBLE
    description: "Minimum price in USD"

  price_usd_max:
    type: DOUBLE
    description: "Maximum price in USD"

  # Rating statistics
  rating_mean:
    type: DOUBLE
    description: "Mean product rating"

  rating_median:
    type: DOUBLE
    description: "Median product rating"

  rating_sd:
    type: DOUBLE
    description: "Standard deviation of rating"

  # Review statistics
  review_count_mean:
    type: DOUBLE
    description: "Mean review count per product"

  review_count_median:
    type: DOUBLE
    description: "Median review count per product"

  review_count_sum:
    type: INTEGER
    description: "Total reviews across all products"

  # Binary feature prevalence (% of products with feature)
  feature_*_prevalence:
    type: DOUBLE
    description: "Prevalence of binary feature (0.0 to 1.0)"
    example: "has_discount_prevalence = 0.35 (35% of products have discount)"

  # MP102 Metadata
  aggregation_level:
    type: VARCHAR
    description: "Grouping dimensions used"
    example: "product_line_country"

  aggregation_timestamp:
    type: TIMESTAMP
    description: "When aggregation occurred"

  aggregation_method:
    type: VARCHAR
    description: "Aggregation functions used"
    example: "mean,median,sd,min,max"

  source_table:
    type: VARCHAR
    description: "Input data source"
    example: "transformed_data.duckdb (all product lines)"

  total_source_products:
    type: INTEGER
    description: "Total products aggregated"
```

---

### df_precision_time_series

**Purpose**: Time series data with R117 transparency markers.

**Granularity**: `date + product_line + country`

**Current Status**: PLACEHOLDER (awaiting sales data)

**Schema**:
```yaml
columns:
  # Time dimension
  date:
    type: DATE
    description: "Date of observation"
    pk: true

  # Grouping dimensions
  product_line:
    type: VARCHAR
    description: "Product line identifier"
    pk: true

  country:
    type: VARCHAR
    description: "Country dimension"
    pk: true

  # Metrics (when sales data available)
  total_sales:
    type: DOUBLE
    description: "Total sales amount (USD)"

  total_orders:
    type: INTEGER
    description: "Total number of orders"

  avg_order_value:
    type: DOUBLE
    description: "Average order value (USD)"

  unique_products_sold:
    type: INTEGER
    description: "Number of unique products sold"

  # R117 Transparency markers (CRITICAL)
  data_source:
    type: VARCHAR(10)
    description: "'REAL' or 'FILLED' or 'PLACEHOLDER'"
    required: true
    r117_compliance: "MANDATORY"

  filling_method:
    type: VARCHAR
    description: "Method used for filling (zero, forward, interpolate)"
    example: "zero_fill"

  filling_timestamp:
    type: TIMESTAMP
    description: "When filling occurred"

  # Metadata
  aggregation_timestamp:
    type: TIMESTAMP
    description: "When data was processed"

  data_availability:
    type: VARCHAR
    description: "Data availability status"
    current_value: "placeholder_awaiting_sales_data"
```

---

## Usage

### Running DRV Scripts

#### Option 1: Batch Execution (Command Line)

```bash
# Run feature preparation
Rscript scripts/update_scripts/DRV/all/all_D04_09.R

# Run time series completion
Rscript scripts/update_scripts/DRV/all/all_D04_07.R

# Run both sequentially
Rscript scripts/update_scripts/DRV/all/all_D04_09.R && \
Rscript scripts/update_scripts/DRV/all/all_D04_07.R
```

#### Option 2: Interactive R Session

```r
# Source and run feature preparation
source("scripts/update_scripts/DRV/all/all_D04_09.R")
result1 <- precision_drv_feature_preparation()

# Source and run time series
source("scripts/update_scripts/DRV/all/all_D04_07.R")
result2 <- precision_drv_time_series()

# Check results
print(result1)
print(result2)
```

#### Option 3: Automated Pipeline

Create a master script for the complete DRV workflow:

```r
# run_drv_pipeline.R

# Step 1: Feature Preparation
source("scripts/update_scripts/DRV/all/all_D04_09.R")
feature_result <- precision_drv_feature_preparation()

if (!feature_result$success) {
  stop("Feature preparation failed")
}

# Step 2: Time Series Completion
source("scripts/update_scripts/DRV/all/all_D04_07.R")
timeseries_result <- precision_drv_time_series()

if (!timeseries_result$success) {
  stop("Time series processing failed")
}

# Step 3: Validation
source("scripts/update_scripts/DRV/all/validate_week2.R")
validation_code <- main()

if (validation_code != 0) {
  warning("Validation found issues - review output")
}

message("✅ Complete DRV pipeline finished successfully")
```

---

### Querying DRV Tables

#### Connect to processed_data.duckdb

```r
library(duckdb)
library(dplyr)
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")

con <- dbConnect(duckdb::duckdb(), "data/local_data/processed_data.duckdb")

# List tables
dbListTables(con)
```

#### Query aggregated features

```r
# Read features table
features <- tbl2(con, "df_precision_features") %>% collect()

# View summary
glimpse(features)

# Filter by product line
alf_features <- features %>%
  filter(product_line == "alf")

# Compare price ranges across product lines
price_summary <- features %>%
  group_by(product_line) %>%
  summarise(
    avg_price = mean(price_usd_mean, na.rm = TRUE),
    min_price = min(price_usd_min, na.rm = TRUE),
    max_price = max(price_usd_max, na.rm = TRUE)
  ) %>%
  arrange(desc(avg_price))

print(price_summary)
```

#### Query time series (when available)

```r
# Read time series table
timeseries <- tbl2(con, "df_precision_time_series") %>% collect()

# Check data availability
unique(timeseries$data_availability)

# Filter to REAL data only (R117 transparency)
real_data <- timeseries %>%
  filter(data_source == "REAL")

# Calculate fill rates
fill_rates <- timeseries %>%
  group_by(product_line, country) %>%
  summarise(
    total_days = n(),
    real_days = sum(data_source == "REAL"),
    filled_days = sum(data_source == "FILLED"),
    fill_rate = filled_days / total_days
  ) %>%
  arrange(desc(fill_rate))

print(fill_rates)
```

---

## Validation

### Running Validation Script

```bash
# Run validation
Rscript scripts/update_scripts/DRV/all/validate_week2.R

# Check exit code
echo $?  # 0 = passed, 1 = failed
```

### Validation Test Suites

The validation script runs 5 comprehensive test suites:

#### 1. File Existence
- Utility functions: `fn_complete_time_series.R`, `fn_aggregate_features.R`
- DRV scripts: Feature preparation, time series, validation, README
- Databases: `processed_data.duckdb`

#### 2. DRV Table Existence
- `df_precision_features` table
- `df_precision_time_series` table
- Row counts and column counts

#### 3. R117 Compliance (Time Series Transparency)
- `data_source` column exists
- `filling_method` column exists
- `filling_timestamp` column exists
- `data_source` values are valid ('REAL', 'FILLED', or 'PLACEHOLDER')

#### 4. Feature Aggregation Quality
- Data completeness (non-zero row count)
- Product lines present
- MP102 metadata columns
- No Inf or NaN values in aggregated statistics

#### 5. MP109 Compliance (DRV Layer)
- DRV scripts do NOT contain 0IM or 1ST stages
- DRV scripts correctly implement only 2TR (derivation)

### Expected Output

```
════════════════════════════════════════════════════════════════════
Week 2 Validation: DRV Layer Implementation
════════════════════════════════════════════════════════════════════

TEST SUITE 1: File Existence
────────────────────────────────────────────────────────────────────
✓ PASS: Utility exists: fn_complete_time_series.R
✓ PASS: Utility exists: fn_aggregate_features.R
✓ PASS: DRV script exists: all_D04_09.R
✓ PASS: DRV script exists: all_D04_07.R
✓ PASS: Database exists: processed_data.duckdb

TEST SUITE 2: DRV Table Existence and Schema
────────────────────────────────────────────────────────────────────
✓ PASS: DRV table exists: df_precision_features
✓ PASS: DRV table exists: df_precision_time_series

TEST SUITE 3: R117 Time Series Transparency Compliance
────────────────────────────────────────────────────────────────────
✓ PASS: R117 column exists: data_source
✓ PASS: R117 column exists: filling_method
✓ PASS: R117 column exists: filling_timestamp
✓ PASS: R117 data_source values

TEST SUITE 4: Feature Aggregation Quality
────────────────────────────────────────────────────────────────────
✓ PASS: Feature table has data
✓ PASS: Product lines present
✓ PASS: MP102 metadata: aggregation_level
✓ PASS: No Inf values in numeric columns

TEST SUITE 5: MP109 DRV Layer Compliance
────────────────────────────────────────────────────────────────────
✓ PASS: MP109: all_D04_09.R has no 0IM/1ST stages
✓ PASS: MP109: all_D04_07.R has no 0IM/1ST stages

════════════════════════════════════════════════════════════════════
WEEK 2 VALIDATION SUMMARY REPORT
════════════════════════════════════════════════════════════════════
Validation Date: 2025-11-13
Total Tests:     24
Passed:          24 ✓
Failed:          0 ✗
Warnings:        0 ⚠
────────────────────────────────────────────────────────────────────

✅ VALIDATION PASSED (100.0% pass rate)

Week 2 DRV implementation is READY FOR USE
════════════════════════════════════════════════════════════════════
```

---

## Troubleshooting

### Issue: "transformed_data.duckdb not found"

**Cause**: Week 1 ETL scripts haven't been run yet.

**Solution**:
```bash
# Run Week 1 ETL pipeline first
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_0IM.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_1ST.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_2TR.R

# Validate Week 1
Rscript scripts/update_scripts/ETL/precision/validate_week1.R

# Then run Week 2 DRV
Rscript scripts/update_scripts/DRV/all/all_D04_09.R
```

---

### Issue: "df_precision_features has 0 rows"

**Cause**: Transformed tables are empty (ETL ran but no data imported).

**Solution**:
```r
# Check if ETL tables have data
library(duckdb)
con <- dbConnect(duckdb::duckdb(), "data/local_data/transformed_data.duckdb")
dbListTables(con)

# Check row counts
for (tbl in c("transformed_precision_alf", "transformed_precision_irf")) {
  count <- tbl2(con, tbl) %>%
    summarise(n = dplyr::n()) %>%
    pull(n)
  print(sprintf("%s: %d rows", tbl, count))
}

# If 0 rows: Re-run ETL 0IM to import data
# If >0 rows: Re-run DRV feature preparation
```

---

### Issue: "R117 VIOLATION: mark_filled must be TRUE"

**Cause**: Attempting to use `fn_complete_time_series()` with `mark_filled = FALSE`.

**Solution**:
```r
# WRONG
result <- fn_complete_time_series(data, mark_filled = FALSE)  # Error!

# CORRECT
result <- fn_complete_time_series(data, mark_filled = TRUE)   # Required by R117
```

**Rationale**: R117 mandates transparency for all filled data. Setting `mark_filled = FALSE` would violate MP029 (No Fake Data) by presenting synthetic data as real.

---

### Issue: High fill rate warning (>50%)

**Message**: "R117 WARNING: N groups have fill_rate > 50%"

**Cause**: Time series has many missing periods (sparse data).

**Investigation**:
```r
# Review fill rate summary
result <- fn_complete_time_series(...)
fill_stats <- result$fill_rate_summary

# Identify high-fill groups
high_fill <- fill_stats %>% filter(fill_rate > 0.50)
print(high_fill)

# Questions to investigate:
# 1. Is this product actually active in this market?
# 2. Is data collection failing for this product/country?
# 3. Should this group be excluded from analysis?
# 4. Should date range be adjusted to actual activity period?
```

**Action**: Consider excluding groups with >50% fill rate from analyses requiring high data quality.

---

## Future Enhancements

### Phase 3: Sales Data Integration (Week 3)

```yaml
sales_etl_integration:
  prerequisite: "CBZ/eBay ETL implementation"

  tasks:
    - "Integrate CBZ sales data (cbz_ETL_sales_2TR.R)"
    - "Integrate eBay sales data (eby_ETL_sales_2TR.R)"
    - "Join sales with product profiles"

  df_enhancements:
    precision_DRV_time_series:
      - "Auto-detect sales tables in transformed_data.duckdb"
      - "Aggregate sales by date + product_line + country"
      - "Complete time series with R117 transparency"
      - "Calculate real vs filled percentages"

    new_drv_script:
      name: "precision_DRV_product_sales_join.R"
      purpose: "Join product features with sales performance"
      output: "df_precision_product_performance"
```

---

### Phase 4: Advanced Analytics (Week 4+)

```yaml
advanced_drv_layers:
  customer_segmentation:
    script: "precision_DRV_customer_segments.R"
    input: ["customer_data", "sales_data", "product_features"]
    output: "df_precision_customer_segments"
    methods: ["RFM analysis", "Clustering", "Behavioral segmentation"]

  market_analysis:
    script: "precision_DRV_market_insights.R"
    input: ["aggregated_features", "time_series", "external_data"]
    output: "df_precision_market_insights"
    methods: ["Trend detection", "Seasonality", "Market share"]

  recommendation_engine:
    script: "precision_DRV_recommendations.R"
    input: ["customer_segments", "product_performance", "purchase_history"]
    output: "df_precision_recommendations"
    methods: ["Collaborative filtering", "Content-based", "Hybrid"]
```

---

## References

### MAMBA Principles

- **MP108**: Base ETL Pipeline Separation (0IM → 1ST → 2TR)
- **MP109**: DRV Derivation Layer (2TR only)
- **MP029**: No Fake Data Principle
- **MP102**: Completeness Principle (metadata requirements)
- **MP064**: ETL-Derivation Separation
- **R116**: Currency Standardization in ETL 1ST
- **R117**: Time Series Filling Transparency Rule

### Documentation

- ETL Layer: `scripts/update_scripts/ETL/precision/README.md`
- Week 1 Report: `scripts/update_scripts/ETL/precision/WEEK1_COMPLETION_REPORT.md`
- Principles Index: `scripts/global_scripts/00_principles/README.md`

### Utility Functions

- Time Series: `scripts/global_scripts/04_utils/fn_complete_time_series.R`
- Feature Aggregation: `scripts/global_scripts/04_utils/fn_aggregate_features.R`

---

## Contact and Support

**Coordinator**: principle-product-manager
**Project**: MAMBA Precision Marketing ETL+DRV Redesign
**Timeline**: Days 8-14 (2025-11-19 to 2025-11-26)

For issues, questions, or enhancements, refer to the MAMBA principles documentation or consult the project coordinator.

---

**Last Updated**: 2025-11-13
**Version**: 1.0
**Status**: Week 2 Implementation Complete ✅
