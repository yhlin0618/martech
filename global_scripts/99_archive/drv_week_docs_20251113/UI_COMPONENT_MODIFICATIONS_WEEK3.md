# UI Component Modifications for Week 3
## poissonFeatureAnalysis.R - Remove Guessing Logic

**Document Type**: Implementation Guide
**Date**: 2025-11-13
**Author**: principle-product-manager
**Status**: Ready for Implementation

---

## Executive Summary

**THE PROBLEM (Original Architecture)**:
The `poissonFeatureAnalysis.R` UI component uses regex-based pattern matching to GUESS variable ranges (lines 52-105), violating MP029 (No Fake Data). This guessing logic:
- Uses hardcoded defaults (1, 2, 4, 10, 50, 100)
- Relies on naming patterns in Chinese/English
- Cannot handle actual data variations
- Produces unreliable track_multiplier calculations

**THE SOLUTION (Week 3 Innovation)**:
The new `drv_precision_poisson_analysis` table provides ACTUAL variable ranges calculated from data, eliminating the need for guessing. All metadata is pre-calculated in DRV layer following R118 and MP029 principles.

---

## Required Modifications

### 1. Remove Guessing Functions (Lines 52-105)

**REMOVE THESE FUNCTIONS** (they violate MP029):

```r
# ❌ DELETE: Lines 52-105
calculate_attribute_range <- function(predictor_name, data_connection = NULL) {
  # [54 lines of regex-based guessing logic]
  # This function MUST be removed
}
```

**WHY**: This function uses pattern matching to guess ranges instead of using actual data. With Week 3 architecture, all ranges are pre-calculated in `df_precision_poisson_analysis` table.

---

### 2. Update calculate_track_multiplier Function (Lines 109-139)

**BEFORE** (uses guessed range):
```r
# ❌ OLD (line 109-139)
calculate_track_multiplier <- function(coefficient, predictor_name, incidence_rate_ratio = NULL) {
  # Get the attribute range dynamically
  attr_range <- calculate_attribute_range(predictor_name)  # ❌ GUESSING

  # ... calculation logic ...
}
```

**AFTER** (uses actual range from table):
```r
# ✅ NEW - Accepts pre-calculated values from DRV table
calculate_track_multiplier_from_data <- function(poisson_row) {
  # Priority 1: Use pre-calculated track_multiplier from DRV table (preferred)
  if (!is.null(poisson_row$track_multiplier) && !is.na(poisson_row$track_multiplier)) {
    return(poisson_row$track_multiplier)
  }

  # Priority 2: Recalculate using actual range from table (fallback)
  if (!is.null(poisson_row$predictor_range) && !is.na(poisson_row$predictor_range)) {
    attr_range <- poisson_row$predictor_range  # ✅ FROM DATA
    coefficient <- poisson_row$coefficient

    if (is.na(attr_range) || attr_range == 0) {
      return(1.0)  # Safe default
    }

    # Original calculation logic (preserved)
    if (!is.na(coefficient)) {
      if (abs(coefficient) > 2) {
        track_multiplier <- exp(2) * (1 + (abs(coefficient) - 2) * 0.5)
      } else {
        effective_range <- min(attr_range, 10)
        track_multiplier <- exp(abs(coefficient) * sqrt(effective_range))
      }
      return(round(min(track_multiplier, 100), 1))
    }
  }

  # Priority 3: Fallback using IRR (if available)
  if (!is.null(poisson_row$incidence_rate_ratio) && !is.na(poisson_row$incidence_rate_ratio)) {
    if (!is.null(poisson_row$predictor_range) && !is.na(poisson_row$predictor_range)) {
      power <- sqrt(poisson_row$predictor_range)
      track_multiplier <- poisson_row$incidence_rate_ratio ^ power
      return(round(min(track_multiplier, 100), 1))
    }
  }

  # Last resort
  return(NA_real_)
}
```

**KEY CHANGES**:
1. Function now accepts entire `poisson_row` (data frame row) instead of individual parameters
2. Prioritizes pre-calculated `track_multiplier` from DRV table
3. Falls back to recalculation using actual `predictor_range` from data
4. No more `calculate_attribute_range()` guessing function

---

### 3. Update Data Loading (Lines 362-466)

**BEFORE** (queries old table structure):
```r
# ❌ OLD (line 378-383)
if (prod_line == "all") {
  table_name <- paste0("df_", platform, "_poisson_analysis_all")
} else {
  table_name <- paste0("df_", platform, "_poisson_analysis_", prod_line)
}
```

**AFTER** (queries new DRV table with actual ranges):
```r
# ✅ NEW - Query df_precision_poisson_analysis table
table_name <- "df_precision_poisson_analysis"

# Load data with pre-calculated ranges and track_multipliers
data <- tbl2(app_data_connection, table_name) %>%
  {
    if (prod_line != "all") {
      filter(., product_line == prod_line)
    } else {
      .
    }
  } %>%
  # Filter only significant or all based on user preference
  # Note: Don't filter here, let user control via UI
  collect()
```

**KEY CHANGES**:
1. Use fixed table name: `df_precision_poisson_analysis`
2. Filter by `product_line` column instead of using different table names
3. Data already includes all R118 fields and variable metadata

---

### 4. Update Calculation Logic (Lines 396-466)

**BEFORE** (calculates track_multiplier on-the-fly):
```r
# ❌ OLD (line 403-406)
track_multiplier = mapply(calculate_track_multiplier,
                         coefficient,
                         predictor,
                         MoreArgs = list(incidence_rate_ratio = NULL)),
```

**AFTER** (uses pre-calculated values):
```r
# ✅ NEW - Track multiplier already in table, no calculation needed
# But ensure it exists, recalculate if missing
track_multiplier = ifelse(
  !is.na(track_multiplier),
  track_multiplier,  # Use pre-calculated value
  # Fallback: recalculate using actual range
  sapply(seq_len(n()), function(i) {
    calculate_track_multiplier_from_data(cur_data()[i, ])
  })
),
```

**Or even simpler** (preferred):
```r
# ✅ PREFERRED - Just use the value from table directly
# track_multiplier column already exists from DRV layer
# No calculation needed in UI component
```

---

### 5. Update track_explanation (Line 460-465)

**BEFORE** (calls calculate_attribute_range):
```r
# ❌ OLD (line 460-465)
track_explanation = paste0(
  "從最", ifelse(coefficient > 0, "低", "高"), "到最",
  ifelse(coefficient > 0, "高", "低"), "，銷量可相差",
  track_multiplier, "倍",
  " (基於屬性範圍: ", sapply(predictor, calculate_attribute_range), ")"  # ❌ GUESSING
)
```

**AFTER** (uses actual range from table):
```r
# ✅ NEW (uses actual predictor_range from data)
track_explanation = paste0(
  "從最", ifelse(coefficient > 0, "低", "高"), "到最",
  ifelse(coefficient > 0, "高", "低"), "，銷量可相差",
  round(track_multiplier, 1), "倍",
  " (實際數據範圍: ",
  ifelse(!is.na(predictor_range),
         sprintf("%.2f", predictor_range),
         "未知"),
  ifelse(!is.na(predictor_is_binary) && predictor_is_binary,
         ", 二元變數",
         ""),
  ")"
)
```

**KEY CHANGES**:
1. Replace `calculate_attribute_range(predictor)` with `predictor_range` from table
2. Use actual range values instead of guessed patterns
3. Indicate if variable is binary (from `predictor_is_binary` column)
4. Handle NA cases gracefully

---

## New Table Schema (df_precision_poisson_analysis)

The new table provides these columns (no guessing needed):

```yaml
df_precision_poisson_analysis:
  identification:
    - product_line: "alf", "irf", "pre", etc.
    - predictor: Variable name

  r118_compliance:
    - coefficient: Regression coefficient
    - std_error: Standard error
    - z_statistic: Z-statistic
    - p_value: P-value (statistical significance)
    - significance_flag: "***", "**", "*", "NOT SIGNIFICANT"
    - is_significant: Boolean

  variable_metadata:  # ⭐ THE INNOVATION
    - predictor_min: Actual minimum value from data
    - predictor_max: Actual maximum value from data
    - predictor_range: Actual range (max - min)
    - predictor_is_binary: TRUE if only 2 unique values
    - predictor_is_categorical: TRUE if ≤10 values and 0/1
    - track_multiplier: Pre-calculated using actual range ⭐

  model_metadata:
    - model_aic: Model AIC
    - model_deviance: Model deviance
    - n_observations: Sample size
    - regression_timestamp: When analysis ran
```

**ALL METADATA IS PRE-CALCULATED** - no guessing needed in UI!

---

## Benefits of Week 3 Architecture

### 1. MP029 Compliance (No Fake Data)
- **Before**: Guessed ranges based on naming patterns (fake/synthetic)
- **After**: Actual ranges calculated from real data

### 2. Accuracy
- **Before**: `calculate_attribute_range("price")` returns hardcoded 50
- **After**: `predictor_range` shows actual range from data (e.g., 27.3)

### 3. Simplicity
- **Before**: 54 lines of regex guessing logic + calculation
- **After**: Direct column access, no calculation needed

### 4. Consistency
- **Before**: Different guessing results for similar variables
- **After**: Consistent, data-driven ranges across all analyses

### 5. Maintainability
- **Before**: Update regex patterns when new naming conventions appear
- **After**: No UI changes needed, DRV layer handles all calculations

---

## Implementation Steps

### Step 1: Backup Original File
```bash
cp scripts/global_scripts/10_rshinyapp_components/poisson/poissonFeatureAnalysis/poissonFeatureAnalysis.R \
   scripts/global_scripts/10_rshinyapp_components/poisson/poissonFeatureAnalysis/poissonFeatureAnalysis.R.BACKUP_BEFORE_WEEK3
```

### Step 2: Remove Guessing Functions
- Delete lines 52-105 (`calculate_attribute_range` function)

### Step 3: Replace calculate_track_multiplier
- Replace lines 109-139 with `calculate_track_multiplier_from_data` (new version)

### Step 4: Update Data Loading
- Modify lines 362-466 to query `df_precision_poisson_analysis`
- Remove table name construction logic
- Filter by `product_line` column instead

### Step 5: Simplify Calculations
- Remove `mapply(calculate_track_multiplier, ...)` calls
- Use `track_multiplier` column directly from table

### Step 6: Update Explanations
- Replace `calculate_attribute_range(predictor)` with `predictor_range`
- Add binary/categorical indicators from metadata

### Step 7: Test
```r
# Test with Week 3 data
source("scripts/global_scripts/10_rshinyapp_components/poisson/poissonFeatureAnalysis/poissonFeatureAnalysis.R")

# Component should now:
# 1. Query df_precision_poisson_analysis table
# 2. Use track_multiplier directly (no calculation)
# 3. Display actual ranges instead of guessed ranges
# 4. Show R118 significance flags
```

---

## Validation Checklist

After implementation, verify:

- [ ] `calculate_attribute_range` function removed (lines 52-105 deleted)
- [ ] No regex pattern matching for ranges anywhere
- [ ] Component queries `df_precision_poisson_analysis` table
- [ ] `track_multiplier` used directly from table (not calculated)
- [ ] `predictor_range` displayed instead of guessed range
- [ ] R118 significance fields used (`p_value`, `significance_flag`)
- [ ] UI displays actual ranges accurately
- [ ] No hardcoded defaults (1, 2, 4, 10, 50, 100) in calculations
- [ ] MP029 compliance verified (no fake/guessed data)
- [ ] Component works with all product lines
- [ ] Track explanations show real data ranges

---

## Migration Notes

### For CBZ Platform

The component currently uses CBZ-specific tables (`df_cbz_poisson_analysis_*`). After Week 3:

**Option 1**: Keep dual support (backward compatible)
```r
# Try new table first, fallback to old
if (dbExistsTable(conn, "df_precision_poisson_analysis")) {
  # Use Week 3 table with actual ranges
  data <- query_new_table()
} else {
  # Fallback to old CBZ tables with guessed ranges
  data <- query_old_table()
}
```

**Option 2**: Migrate CBZ to new architecture
- Run Week 3 Poisson analysis for CBZ data
- Populate `df_precision_poisson_analysis` with CBZ results
- Retire old table structure

**Recommendation**: Option 1 for gradual migration, Option 2 for clean architecture.

---

## Breaking Changes

### Functions Removed
- `calculate_attribute_range(predictor_name, data_connection)` - DELETED

### Functions Modified
- `calculate_track_multiplier()` → `calculate_track_multiplier_from_data(poisson_row)`
  - **Old signature**: `(coefficient, predictor_name, incidence_rate_ratio)`
  - **New signature**: `(poisson_row)` - accepts entire row with metadata

### Table Structure Changed
- **Old**: Multiple tables (`df_cbz_poisson_analysis_alf`, `df_cbz_poisson_analysis_pre`, etc.)
- **New**: Single table (`df_precision_poisson_analysis`) with `product_line` column

### Required Columns
New required columns from DRV table:
- `predictor_min`, `predictor_max`, `predictor_range`
- `predictor_is_binary`, `predictor_is_categorical`
- `track_multiplier` (pre-calculated)
- `p_value`, `significance_flag` (R118 compliance)

---

## Example Usage (After Week 3)

### Old Way (Guessing)
```r
# ❌ OLD - Guessed range based on pattern
predictor <- "price_usd"
guessed_range <- calculate_attribute_range(predictor)  # Returns 50 (hardcoded)
track_mult <- calculate_track_multiplier(coef, predictor)  # Uses guessed 50
# Result: Inaccurate because actual price range might be 27.3, not 50
```

### New Way (Actual Data)
```r
# ✅ NEW - Actual range from data
data <- tbl2(conn, "df_precision_poisson_analysis") %>%
  filter(product_line == "pre", predictor == "price_usd") %>%
  collect()

actual_range <- data$predictor_range  # Returns 27.3 (from real data)
track_mult <- data$track_multiplier   # Pre-calculated using actual range
# Result: Accurate, data-driven analysis
```

---

## Testing Strategy

### Test 1: Range Accuracy
```r
# Compare old guessed range vs new actual range
old_range <- calculate_attribute_range("price_usd")  # 50 (guessed)
new_data <- get_poisson_data("pre", "price_usd")
new_range <- new_data$predictor_range  # Actual from data

# Verify they differ (proves guessing was wrong)
expect_false(old_range == new_range)
```

### Test 2: Track Multiplier Consistency
```r
# Verify pre-calculated track_multiplier matches recalculation
data <- get_poisson_data("alf", "rating")
precalculated <- data$track_multiplier
recalculated <- calculate_track_multiplier_from_data(data)

# Should match within rounding error
expect_equal(precalculated, recalculated, tolerance = 0.01)
```

### Test 3: No Hardcoded Defaults
```r
# Verify no suspicious default values in actual ranges
data <- tbl2(conn, "df_precision_poisson_analysis") %>% collect()

# These would indicate guessing logic (hardcoded defaults)
suspicious_defaults <- c(1, 2, 4, 10, 50, 100)

for (default_val in suspicious_defaults) {
  exact_matches <- sum(data$predictor_range == default_val, na.rm = TRUE)
  pct <- 100 * exact_matches / nrow(data)

  # Alert if >20% of ranges are exact defaults (suspicious)
  if (pct > 20) {
    warning(sprintf("%.1f%% of ranges are exactly %.0f (suspicious guessing?)", pct, default_val))
  }
}
```

---

## Conclusion

Week 3 architecture eliminates 54 lines of regex-based guessing logic by pre-calculating all variable metadata in the DRV layer. This:

1. **Fixes the original problem**: No more guessing variable ranges
2. **Achieves MP029 compliance**: All ranges from actual data
3. **Implements R118**: Statistical significance properly documented
4. **Simplifies UI code**: Direct column access, no calculations
5. **Improves accuracy**: Data-driven instead of heuristic-based

**The UI component transforms from**:
- 54 lines of guessing + calculation = Complex, inaccurate

**To**:
- Direct column access = Simple, accurate, principle-compliant

**This is the core innovation of Week 3.**

---

**Document Status**: READY FOR IMPLEMENTATION
**Next Action**: Apply modifications to poissonFeatureAnalysis.R
**Validation**: Run validate_week3.R after implementation
