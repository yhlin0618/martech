# ISSUE_115: Date Label System Debugging Report

## Executive Summary
**Problem**: Poisson time analysis displays unclear labels like "month_4 (3.1×)" without year context
**Root Cause**: Missing date enrichment in the ETL-to-derivation pipeline
**Solution**: Implement hierarchical date labeling system with year/month/day context

## Debugging Findings

### 1. Current Data Structure Analysis

#### Database Table: `df_cbz_poisson_analysis_all`
```csv
predictor        | incidence_rate_ratio | analysis_date
-----------------|---------------------|---------------
"year"           | 2.089                | "2025-06-10"
"month_5"        | 3.306                | "2025-06-10"
"month_6"        | NA (error)           | "2025-06-10"
```

**Key Issues Identified**:
- Predictors stored as generic labels ("month_5") without year context
- No actual date values (year/month/day) stored in the table
- Analysis date exists but not linked to the time periods being analyzed
- Many months show NA/error status indicating data quality issues

### 2. UI Component Analysis

#### Current Display Logic (poissonTimeAnalysis.R, lines 418-427)
```r
predictor_clean = case_when(
  predictor == "year" ~ "年度",
  grepl("^month_", predictor) ~ paste0("月份", gsub("month_", "", predictor)),
  predictor == "day" ~ "日期",
  # ... weekday mappings
)
```

**Problems**:
- Simple string replacement without date context
- No year information available for month labels
- Generic labels don't indicate actual time periods

### 3. Data Flow Tracing

```
Raw Data (df_cbz_orders___raw)
├─ created_at: "2025-08-28 14:31:27"  ✓ Has full timestamps
└─ Contains complete date information

↓ ETL Processing (cbz_ETL_orders_0IM)
├─ Dates preserved in raw format
└─ No date decomposition occurs

↓ Poisson Analysis (unknown derivation script)
├─ Generates generic predictors: "month_1", "month_2", etc.
└─ Loses connection to actual dates

↓ Storage (df_cbz_poisson_analysis_all)
├─ predictor: "month_5"  ✗ No year context
├─ analysis_date: "2025-06-10"  ✓ Has date but not linked
└─ No date range columns

↓ UI Display (poissonTimeAnalysis.R)
└─ Shows: "月份5 (3.3×)"  ✗ User can't identify time period
```

## Solution Implementation

### Phase 1: Database Schema Enhancement ✅
Created: `cbz_DER_poisson_time_labels.R`

**New Columns Added**:
- `analysis_year`: Actual year (e.g., 2025)
- `analysis_month`: Month number (1-12)
- `year_label`: "2025年"
- `month_label`: "2025年8月"
- `time_hierarchy`: Classification (year/month/day/weekday)
- `date_start/date_end`: Actual date ranges
- `display_order`: For proper sorting

### Phase 2: UI Component Update (Pending)

**Required Changes to poissonTimeAnalysis.R**:
1. Use enriched labels instead of generic predictor names
2. Group by time_hierarchy for organized display
3. Sort by display_order for chronological presentation

### Phase 3: Testing Results

**Database Lock Issue**: RStudio process (PID 63037) holding lock on app_data.duckdb
**Workaround**: Need to either:
1. Close RStudio before running enrichment
2. Modify script to handle locks gracefully
3. Use a separate testing database

## Validation Checklist

### Data Quality Checks
- [x] Raw data contains full timestamps
- [x] Poisson analysis table exists with data
- [ ] Enrichment script successfully runs
- [ ] New columns populated with correct values
- [ ] UI displays hierarchical labels

### Principle Compliance
- [x] **MP064**: ETL-Derivation separation maintained
- [x] **R113**: Four-part script structure implemented
- [x] **MP031**: Proper autoinit/autodeinit usage
- [x] **R092**: Universal data access pattern used
- [x] **R120**: Descriptive variable naming applied

## Next Steps

### Immediate Actions
1. **Resolve Database Lock**:
   ```bash
   # Option 1: Kill RStudio process
   kill -9 63037

   # Option 2: Use read-only for testing
   con <- dbConnect(duckdb::duckdb(),
                   "path/to/db.duckdb",
                   read_only = TRUE)
   ```

2. **Run Enrichment Script**:
   ```bash
   # After resolving lock
   Rscript scripts/update_scripts/cbz_DER_poisson_time_labels.R
   ```

3. **Update UI Component**:
   - Modify poissonTimeAnalysis.R to use new labels
   - Test with enriched data

### Expected Output After Fix

**Before**:
```
月份4 (3.1×)
月份5 (3.3×)
年度 (2.1×)
```

**After**:
```
═══ 2025年趨勢 ═══
2025年全年 (2.1×)

═══ 2025年月份分析 ═══
2025年4月 (3.1×)
2025年5月 (3.3×)
2025年6月 (資料不足)

═══ 星期效應 ═══
週一 (0.8×)
週五 (1.5×)
```

## Risk Assessment

### Identified Risks
1. **Database Lock Conflicts**: Multiple processes accessing same database
2. **Data Loss**: Overwriting existing Poisson analysis data
3. **Performance Impact**: Additional columns may slow queries

### Mitigation Strategies
1. **Backup Creation**: Script creates timestamped backup before update
2. **Graceful Error Handling**: Try-catch blocks for all database operations
3. **Index Creation**: Add indexes for new date columns

## Conclusion

The root cause has been identified as missing date context in the Poisson analysis pipeline. The solution involves:
1. Enriching existing data with hierarchical date labels (✅ Script created)
2. Updating UI to use enriched labels (⏳ Pending)
3. Testing complete flow (⏳ Blocked by database lock)

The architectural approach follows MAMBA principles and maintains backward compatibility while adding the requested functionality.

---
**Report Generated**: 2025-09-22
**Status**: Solution designed, implementation blocked by database lock
**Next Review**: After database lock resolution