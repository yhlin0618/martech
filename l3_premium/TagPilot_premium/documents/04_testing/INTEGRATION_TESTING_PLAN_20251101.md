# Integration Testing Plan - TagPilot Premium Z-Score Revision

**Date**: 2025-11-01
**Status**: Ready for Execution
**Estimated Time**: 4-6 hours

---

## Overview

This document outlines the comprehensive integration testing plan for the z-score based customer dynamics implementation in TagPilot Premium.

---

## Pre-Testing Checklist

### Environment Setup

- [ ] R and RStudio installed
- [ ] All required packages installed
- [ ] Database connection configured (if using PostgreSQL)
- [ ] Sample data available
- [ ] app.R configured to load v2 module

### Files to Verify Exist

- [ ] `modules/module_dna_multi_premium_v2.R` (v2 module)
- [ ] `config/customer_dynamics_config.R` (configuration)
- [ ] `utils/calculate_customer_tags.R` (updated utilities)
- [ ] `utils/analyze_customer_dynamics_new.R` (z-score function)
- [ ] `scripts/global_scripts/04_utils/fn_analysis_dna.R` (core DNA)

---

## Test Phases

### Phase 1: Configuration System Testing (30 min)

#### Test 1.1: Load Configuration
```r
# Load config
source("config/customer_dynamics_config.R")
config <- get_customer_dynamics_config()

# Verify structure
stopifnot(!is.null(config))
stopifnot(config$method %in% c("auto", "z_score", "fixed_threshold"))
stopifnot(config$zscore$k == 2.5)
stopifnot(config$zscore$active_threshold == 0.5)

# Print summary
print_config_summary()
```

**Expected**: Configuration loads without errors, prints readable summary

**Status**: [ ]

---

#### Test 1.2: Helper Functions
```r
# Test threshold accessors
z_thresholds <- get_zscore_thresholds()
stopifnot(length(z_thresholds) == 3)
stopifnot(names(z_thresholds) == c("active", "sleepy", "half_sleepy"))

activity_thresholds <- get_activity_thresholds()
stopifnot(activity_thresholds["high"] == 0.8)

value_thresholds <- get_value_thresholds()
stopifnot(value_thresholds["high"] == 0.6)
```

**Expected**: All helper functions return correct values

**Status**: [ ]

---

#### Test 1.3: Data Validation
```r
# Load sample data
load("data/sample_transactions.RData")

# Validate
validation <- validate_zscore_data(
  transaction_data = sample_transactions,
  customer_data = sample_customers
)

# Check results
print(validation$passed)
print(validation$issues)
print(validation$recommendations)
```

**Expected**: Validation runs, provides clear feedback

**Status**: [ ]

---

### Phase 2: Core Function Testing (1 hour)

#### Test 2.1: DNA Analysis (Unchanged)
```r
# Load core function
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")

# Run DNA analysis
dna_result <- fn_analysis_dna(
  df_sales_by_customer = customer_summary,
  df_sales_by_customer_by_date = transaction_data
)

# Verify output structure
stopifnot(!is.null(dna_result$data_by_customer))
stopifnot(nrow(dna_result$data_by_customer) == n_distinct(transaction_data$customer_id))
stopifnot(all(c("r_value", "f_value", "m_value", "ni") %in% names(dna_result$data_by_customer)))
```

**Expected**: DNA analysis runs unchanged, returns all customers

**Status**: [ ]

---

#### Test 2.2: Z-Score Classification
```r
# Load z-score function
source("utils/analyze_customer_dynamics_new.R")

# Run z-score analysis
zscore_result <- analyze_customer_dynamics_new(
  transaction_data = transaction_data,
  method = "z_score"
)

# Verify output
stopifnot(!is.null(zscore_result$customer_data))
stopifnot(all(c("z_i", "F_i_w", "customer_dynamics") %in% names(zscore_result$customer_data)))

# Check classifications
table(zscore_result$customer_data$customer_dynamics)
# Should see: newbie, active, sleepy, half_sleepy, dormant
```

**Expected**: Z-score classification works, all 5 dynamics present

**Status**: [ ]

---

#### Test 2.3: RFM Scoring (All Customers)
```r
# Load utilities
source("utils/calculate_customer_tags.R")

# Merge DNA + Z-score results
customer_data <- dna_result$data_by_customer %>%
  left_join(
    zscore_result$customer_data %>% select(customer_id, z_i, customer_dynamics),
    by = "customer_id"
  )

# Calculate RFM
customer_data_rfm <- calculate_rfm_scores(customer_data)

# Verify all customers have scores
stopifnot(all(!is.na(customer_data_rfm$r_score)))
stopifnot(all(!is.na(customer_data_rfm$f_score)))
stopifnot(all(!is.na(customer_data_rfm$m_score)))

# Check newbie scores
newbies <- customer_data_rfm %>% filter(customer_dynamics == "newbie")
summary(newbies$f_score)  # Should be mostly low (1-2)
```

**Expected**: All customers get RFM scores, newbies have low F

**Status**: [ ]

---

#### Test 2.4: Customer Tags
```r
# Calculate all tags
customer_data_tagged <- customer_data_rfm %>%
  calculate_activity_level() %>%
  calculate_value_level() %>%
  calculate_status_tags() %>%
  calculate_prediction_tags()

# Verify all tags exist
required_tags <- c(
  "tag_017_customer_dynamics",
  "tag_018_churn_risk",
  "tag_031_next_purchase_date",
  "activity_level",
  "value_level"
)

stopifnot(all(required_tags %in% names(customer_data_tagged)))
```

**Expected**: All customer tags generated successfully

**Status**: [ ]

---

### Phase 3: Module UI Testing (2 hours)

#### Test 3.1: Load App with V2 Module
```r
# Modify app.R to load v2 module
# Change line:
# source("modules/module_dna_multi_premium.R")
# To:
# source("modules/module_dna_multi_premium_v2.R")

# Run app
shiny::runApp()
```

**Expected**: App loads without errors

**Status**: [ ]

---

#### Test 3.2: Module 1 - DNA Multi V2

**UI Tests**:
- [ ] Upload sample CSV
- [ ] Click "開始分析"
- [ ] Wait for analysis to complete
- [ ] Select customer dynamics dropdown (newbie/active/sleepy/half_sleepy/dormant)
- [ ] Verify grid displays correctly

**Specific Checks**:

1. **Newbie Display**:
   - [ ] Shows 3 value-based cards (A3N, B3N, C3N)
   - [ ] Shows "新客：尚無活動力評分" warning
   - [ ] Cards display correctly with colors

2. **Non-Newbie Grid** (select "active", "sleepy", "half_sleepy", or "dormant"):
   - [ ] Shows 9-grid matrix (3×3)
   - [ ] Each cell shows:
     - Grid position (A1-C3)
     - Customer count
     - Percentage
     - Avg M value
     - Avg F value
     - Strategy recommendation
     - KPI indicator
   - [ ] Color coding by dynamics (green/amber/pink/gray)
   - [ ] Border colors match dynamics

3. **ni < 4 Warning**:
   - [ ] If non-newbie customers with ni < 4 exist, warning displays
   - [ ] Warning shows count of affected customers

**Expected**: All visualizations render correctly, no errors

**Status**: [ ]

---

#### Test 3.3: Module 2 - Customer Status

**UI Tests**:
- [ ] Navigate to Module 2
- [ ] Upload same data
- [ ] Click analyze
- [ ] Check key metrics display

**Specific Checks**:

1. **Key Metrics**:
   - [ ] High risk count displays
   - [ ] Active count displays (using `tag_017_customer_dynamics`)
   - [ ] Dormant count displays (using `tag_017_customer_dynamics`)
   - [ ] Avg days to churn displays

2. **Pie Chart**:
   - [ ] Displays customer dynamics distribution
   - [ ] Uses `tag_017_customer_dynamics` field
   - [ ] Chinese labels show correctly (新客/活躍/輕度睡眠/半睡眠/沉睡)
   - [ ] Colors match config

3. **Heatmap**:
   - [ ] Cross-tabulates customer dynamics × churn risk
   - [ ] All cells display correctly
   - [ ] Hover shows details

4. **Detail Table**:
   - [ ] Shows top 100 customers
   - [ ] Columns: customer_id, 購買次數, 客戶動態, 流失風險, 預估流失天數
   - [ ] Uses `tag_017_customer_dynamics` (not old name)
   - [ ] Sorting works

5. **CSV Export**:
   - [ ] Download button works
   - [ ] CSV contains `tag_017_customer_dynamics` column
   - [ ] Data is complete

**Expected**: All visualizations use new field names, no errors

**Status**: [ ]

---

#### Test 3.4: Module 3 - Customer Base Value

**UI Tests**:
- [ ] Navigate to Module 3
- [ ] Upload data
- [ ] Check AOV analysis

**Specific Checks**:

1. **AOV Analysis**:
   - [ ] Filters by `customer_dynamics` (not old field)
   - [ ] Shows newbie vs active comparison
   - [ ] Calculations correct

**Expected**: AOV analysis works with new field

**Status**: [ ]

---

### Phase 4: Edge Case Testing (1 hour)

#### Test 4.1: Newbie-Only Dataset
```r
# Create dataset with only ni == 1 customers
newbie_only <- transaction_data %>%
  group_by(customer_id) %>%
  filter(n() == 1) %>%
  ungroup()

# Run analysis
# Should handle gracefully
```

**Expected**: No errors, all classified as newbie

**Status**: [ ]

---

#### Test 4.2: Small Dataset (< 100 customers)
```r
# Create small dataset
small_data <- transaction_data %>%
  filter(customer_id %in% sample(unique(customer_id), 50))

# Run analysis
# Should show validation warning, use fixed thresholds
```

**Expected**: Validation warning, falls back to fixed method

**Status**: [ ]

---

#### Test 4.3: No Repeat Customers
```r
# All customers have ni == 1
# μ_ind cannot be calculated
```

**Expected**: Graceful fallback or clear error message

**Status**: [ ]

---

#### Test 4.4: Missing Values
```r
# Introduce NAs in critical fields
test_data <- transaction_data
test_data$transaction_amount[sample(1:nrow(test_data), 10)] <- NA
```

**Expected**: Handles NAs gracefully, reports affected rows

**Status**: [ ]

---

### Phase 5: Performance Testing (1 hour)

#### Test 5.1: Medium Dataset (1,000 customers)
```r
# Time the analysis
system.time({
  result <- fn_analysis_dna(customer_summary, transaction_data)
})

system.time({
  zscore <- analyze_customer_dynamics_new(transaction_data)
})
```

**Expected**: < 5 seconds total

**Status**: [ ]

---

#### Test 5.2: Large Dataset (10,000 customers)
```r
# Generate or use large dataset
# Time analysis
```

**Expected**: < 30 seconds total

**Status**: [ ]

---

#### Test 5.3: Memory Usage
```r
# Monitor memory during analysis
gc()
mem_before <- gc()[1,2]

# Run analysis
result <- fn_analysis_dna(customer_summary, transaction_data)

mem_after <- gc()[1,2]
mem_used <- mem_after - mem_before
print(paste("Memory used:", mem_used, "MB"))
```

**Expected**: < 500 MB for 10K customers

**Status**: [ ]

---

### Phase 6: Regression Testing (30 min)

#### Test 6.1: Backward Compatibility
```r
# Load old data exports (if available)
# old_export <- read.csv("old_customer_export.csv")

# Verify:
# - Can still classify customers
# - Results are comparable (allowing for methodology change)
# - No critical functionality broken
```

**Expected**: No breaking changes in core functionality

**Status**: [ ]

---

#### Test 6.2: Module Switching
```r
# Test switching between v1 and v2 modules
# Should be able to toggle in app.R without errors
```

**Expected**: Clean switch between versions

**Status**: [ ]

---

## Test Data Requirements

### Minimum Test Dataset

```r
# Sample structure:
transaction_data <- data.frame(
  customer_id = character(),
  transaction_date = Date(),
  transaction_amount = numeric()
)

# Should include:
# - At least 100 unique customers
# - Mix of newbies (ni == 1): 20-30%
# - Mix of repeat customers (ni >= 2): 70-80%
# - Some high-frequency customers (ni >= 10): 10-15%
# - Date range: At least 1 year
# - Amount range: Realistic values
```

### Test Scenarios to Cover

1. **Newbie scenarios**:
   - Recent newbie (< 7 days)
   - Old newbie (> 30 days)

2. **Active customers**:
   - High value + high activity (A1)
   - Medium value + high activity (B1)
   - Low value + high activity (C1)

3. **Dormant customers**:
   - Was active, now dormant
   - Always low frequency

4. **Edge cases**:
   - ni == 1 (newbie)
   - ni == 2 (just became repeat)
   - ni == 3 (still low data)
   - ni >= 4 (full data)

---

## Bug Tracking Template

When bugs are found:

```markdown
### Bug #[number]

**Title**: [Brief description]

**Severity**: Critical / High / Medium / Low

**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happens]

**Error Message** (if any):
```
[Error text]
```

**Affected Files**:
- [file1.R]
- [file2.R]

**Fix Status**: [ ] Not started / [ ] In progress / [ ] Fixed / [ ] Verified
```

---

## Success Criteria

### Must Pass (Blocking Issues)

- [ ] App loads without errors
- [ ] All modules display correctly
- [ ] No console errors during normal usage
- [ ] Data processing completes successfully
- [ ] All visualizations render
- [ ] CSV exports work correctly

### Should Pass (Important)

- [ ] Performance acceptable (< 5s for 1K customers)
- [ ] Edge cases handled gracefully
- [ ] Validation messages clear and helpful
- [ ] All customer dynamics classifications present
- [ ] RFM scores for all customers

### Nice to Have (Optional)

- [ ] Performance excellent (< 30s for 10K customers)
- [ ] Memory usage minimal
- [ ] UI polish and refinements
- [ ] Helpful tooltips and documentation

---

## Test Execution Checklist

### Before Testing:
- [ ] Back up current working version
- [ ] Create git branch for testing
- [ ] Prepare test data
- [ ] Set up clean R environment

### During Testing:
- [ ] Document all issues immediately
- [ ] Take screenshots of errors
- [ ] Note performance metrics
- [ ] Test systematically (don't skip tests)

### After Testing:
- [ ] Compile bug list
- [ ] Prioritize fixes
- [ ] Update documentation
- [ ] Create fix plan

---

## Next Steps After Testing

### If All Tests Pass:
1. Update status to 95% complete
2. Create deployment documentation
3. Prepare for user acceptance testing
4. Schedule final review

### If Critical Bugs Found:
1. Document all issues
2. Create fix priority list
3. Implement fixes
4. Re-test affected areas
5. Iterate until pass

---

## Estimated Timeline

| Phase | Time | Status |
|-------|------|--------|
| Phase 1: Configuration | 30 min | [ ] |
| Phase 2: Core Functions | 1 hour | [ ] |
| Phase 3: Module UI | 2 hours | [ ] |
| Phase 4: Edge Cases | 1 hour | [ ] |
| Phase 5: Performance | 1 hour | [ ] |
| Phase 6: Regression | 30 min | [ ] |
| **Total** | **6 hours** | - |

---

**Document Status**: ✅ Ready for Execution
**Prepared By**: Development Team
**Date**: 2025-11-01

**Start Testing**: ⏳ Ready
