# ISSUE_115: Date Label System Restructuring

## Problem Analysis

### Current State
The Poisson time analysis component currently displays unclear labels like "month_4 (3.1×)" without year context. The data structure shows:
- Predictors stored as: "year", "month_1" through "month_12", "day", weekdays
- No actual date information (year/month/day values) stored
- Labels are generic month numbers without year context
- The "(3.1×)" represents the incidence_rate_ratio but lacks context

### Root Causes (Principle Violations)
1. **MP064 Violation**: Business logic (date extraction) missing from ETL layers
2. **R120 Violation**: Poor variable naming ("month_5" instead of descriptive date labels)
3. **MP093 Violation**: Data visualization not showing actual dates from source data
4. **MP099 Violation**: No clear temporal hierarchy in the display

### Data Flow Analysis
```
Raw Data (df_cbz_orders___raw)
  ├─ created_at: "2025-08-28 14:31:27"  [Has full date information]
  └─ order_date fields available
           ↓
ETL Processing (cbz_ETL_orders_0IM)
  └─ Date fields preserved but not decomposed
           ↓
Poisson Analysis (df_cbz_poisson_analysis_all)
  ├─ predictor: "month_5"  [Lost year context]
  ├─ predictor_type: "time_feature"
  └─ No actual date values stored
           ↓
UI Display (poissonTimeAnalysis.R)
  └─ Shows: "月份5 (3.3×)"  [Unclear what time period]
```

## Solution Design

### 1. Enhanced Database Schema
```sql
-- Add columns to track actual time periods
ALTER TABLE df_cbz_poisson_analysis_all ADD COLUMN IF NOT EXISTS (
  -- Time period identification
  analysis_year INTEGER,           -- e.g., 2024, 2025
  analysis_month INTEGER,          -- 1-12
  analysis_day INTEGER,            -- 1-31
  analysis_week INTEGER,           -- 1-53 (ISO week)
  analysis_quarter INTEGER,        -- 1-4

  -- Date range for the analysis period
  date_start DATE,                 -- Start of period analyzed
  date_end DATE,                   -- End of period analyzed
  period_days INTEGER,             -- Number of days in period

  -- Hierarchical labels
  year_label VARCHAR(20),          -- "2025年"
  month_label VARCHAR(30),         -- "2025年8月"
  day_label VARCHAR(40),           -- "2025年8月28日"
  week_label VARCHAR(50),          -- "2025年第34週"
  quarter_label VARCHAR(30),       -- "2025年Q3"

  -- Time hierarchy type
  time_hierarchy VARCHAR(10),      -- 'year', 'month', 'day', 'week', 'quarter'
  time_granularity VARCHAR(20),    -- 'yearly', 'monthly', 'daily', 'weekly'

  -- Context information
  is_complete_period BOOLEAN,      -- TRUE if full period data available
  data_coverage_pct NUMERIC        -- Percentage of period with data
);

-- Create index for efficient time-based queries
CREATE INDEX idx_poisson_time_hierarchy ON df_cbz_poisson_analysis_all(
  analysis_year, analysis_month, analysis_day
);
```

### 2. ETL Enhancement (Following MP064)
Create new derivation script: `cbz_DER_poisson_time_labels.R`

```r
# cbz_DER_poisson_time_labels.R
# Following: MP064 (ETL-Derivation Separation), R113 (Four-part structure)

# INITIALIZE --------------------------------------------------------------
autoinit()
con <- dbConnectDuckdb(db_path_list$app_data)

# MAIN -------------------------------------------------------------------
message("DER: Enriching Poisson analysis with time labels")

# Get order date ranges for context
date_ranges <- tbl2(con, "df_cbz_orders___raw") %>%
  summarise(
    min_date = min(created_at, na.rm = TRUE),
    max_date = max(created_at, na.rm = TRUE)
  ) %>%
  collect()

# Enrich Poisson analysis with actual dates
poisson_enriched <- tbl2(con, "df_cbz_poisson_analysis_all") %>%
  collect() %>%
  mutate(
    # Extract actual time values from predictor names
    analysis_year = case_when(
      predictor == "year" ~ year(date_ranges$max_date),
      TRUE ~ NA_integer_
    ),
    analysis_month = case_when(
      grepl("^month_", predictor) ~ as.integer(gsub("month_", "", predictor)),
      TRUE ~ NA_integer_
    ),

    # Generate hierarchical labels with actual years
    year_label = case_when(
      predictor == "year" ~ paste0(year(date_ranges$max_date), "年"),
      TRUE ~ NA_character_
    ),
    month_label = case_when(
      grepl("^month_", predictor) ~ paste0(
        year(date_ranges$max_date), "年",
        as.integer(gsub("month_", "", predictor)), "月"
      ),
      TRUE ~ NA_character_
    ),

    # Set time hierarchy
    time_hierarchy = case_when(
      predictor == "year" ~ "year",
      grepl("^month_", predictor) ~ "month",
      predictor == "day" ~ "day",
      predictor %in% c("monday", "tuesday", "wednesday", "thursday",
                      "friday", "saturday", "sunday") ~ "weekday",
      TRUE ~ "other"
    ),

    # Calculate date ranges
    date_start = case_when(
      grepl("^month_", predictor) ~ as.Date(paste0(
        year(date_ranges$max_date), "-",
        sprintf("%02d", as.integer(gsub("month_", "", predictor))), "-01"
      )),
      TRUE ~ NA_Date_
    ),
    date_end = case_when(
      grepl("^month_", predictor) ~ ceiling_date(date_start, "month") - days(1),
      TRUE ~ NA_Date_
    )
  )

# Write back enriched data
dbWriteTable(con, "df_cbz_poisson_analysis_all",
            poisson_enriched, overwrite = TRUE)

# TEST -------------------------------------------------------------------
test_results <- tbl2(con, "df_cbz_poisson_analysis_all") %>%
  filter(!is.na(month_label)) %>%
  select(predictor, month_label, date_start, date_end) %>%
  collect()

stopifnot(nrow(test_results) > 0)
stopifnot(all(!is.na(test_results$month_label)))
message("TEST: Time labels successfully added")

# DEINITIALIZE ----------------------------------------------------------
dbDisconnect(con)
autodeinit()
```

### 3. UI Component Updates
Modify `poissonTimeAnalysis.R` to use the new labels:

```r
# In poissonTimeAnalysis.R, line 418-427
predictor_clean = case_when(
  !is.na(year_label) ~ year_label,           # Use actual year label
  !is.na(month_label) ~ month_label,         # Use year+month label
  !is.na(day_label) ~ day_label,             # Use full date label
  predictor == "year" ~ "年度趨勢",
  predictor == "day" ~ "每月日期效應",
  predictor %in% weekdays ~ recode(predictor,
    "monday" = "週一", "tuesday" = "週二", "wednesday" = "週三",
    "thursday" = "週四", "friday" = "週五",
    "saturday" = "週六", "sunday" = "週日"
  ),
  TRUE ~ predictor
)
```

### 4. Display Enhancement
Add hierarchical grouping to the UI:

```r
# Group data by hierarchy
grouped_data <- filtered_data() %>%
  arrange(time_hierarchy, analysis_year, analysis_month, analysis_day) %>%
  group_by(time_hierarchy) %>%
  mutate(
    group_label = case_when(
      time_hierarchy == "year" ~ "年度趨勢",
      time_hierarchy == "month" ~ "月份季節性",
      time_hierarchy == "day" ~ "日期模式",
      time_hierarchy == "weekday" ~ "星期效應",
      TRUE ~ "其他"
    )
  )
```

## Implementation Steps

### Phase 1: Database Schema Update (Immediate)
1. Run schema modification to add new columns
2. Create indexes for performance
3. Test with existing data

### Phase 2: ETL Enhancement (Day 1)
1. Create `cbz_DER_poisson_time_labels.R`
2. Add to update sequence after Poisson analysis
3. Test with real date extraction
4. Validate enriched data

### Phase 3: UI Updates (Day 2)
1. Update `poissonTimeAnalysis.R` to use new labels
2. Add hierarchical grouping
3. Improve visualization with proper date context
4. Test all display modes

### Phase 4: Testing & Validation (Day 3)
1. Run full pipeline with test data
2. Verify all date labels show correctly
3. Check performance with indexes
4. Document any edge cases

## Expected Outcome

### Before
```
月份4 (3.1×)    [No year context]
月份5 (3.3×)    [Unclear period]
年度 (2.1×)     [Which year?]
```

### After
```
═══ 2025年趨勢 ═══
2025年全年 (2.1×)

═══ 2025年月份分析 ═══
2025年4月 (3.1×)
2025年5月 (3.3×)
2025年6月 (2.8×)

═══ 每月日期模式 ═══
月初 (1-10日): 1.2×
月中 (11-20日): 0.9×
月底 (21-31日): 1.4×

═══ 星期效應 ═══
週一 (0.8×)
週五 (1.5×)
週六 (1.8×)
```

## Principles Applied
- **MP064**: Proper ETL-Derivation separation
- **MP093**: Clear data visualization with S02 exports
- **MP099**: Real-time progress with hierarchical display
- **R113**: Four-part script structure for derivation
- **R120**: Descriptive variable naming
- **R092**: Universal data access patterns
- **MP031**: Proper autoinit/autodeinit usage

## Migration Strategy

1. **Backward Compatibility**: Keep existing columns while adding new ones
2. **Gradual Rollout**: Test with one platform (cbz) first
3. **Data Validation**: Compare old vs new labels for consistency
4. **Performance Monitoring**: Check query performance with new indexes

## Risk Mitigation

- **Risk**: Breaking existing visualizations
  - **Mitigation**: Keep old predictor column, add new label columns

- **Risk**: Performance impact from additional columns
  - **Mitigation**: Use proper indexes, lazy loading

- **Risk**: Date extraction errors
  - **Mitigation**: Fallback to generic labels if dates unavailable

## Success Metrics

1. All time labels show with year context
2. Users can identify exact time periods
3. No performance degradation
4. Zero breaking changes to existing functionality

## Next Steps

1. Review and approve design
2. Create test environment
3. Implement Phase 1 (Schema)
4. Proceed with phased rollout

---
**Status**: Design Complete, Awaiting Implementation
**Priority**: High
**Estimated Effort**: 3 days
**Dependencies**: Database write access, ETL pipeline access