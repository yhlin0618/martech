# Module Revision Implementation Notes

**Date**: 2025-11-01
**Purpose**: Step-by-step guide for completing module revisions
**Status**: In Progress

---

## ✅ Completed

1. Created `module_dna_multi_premium_v2.R` with z-score foundation
2. Organized implementation files into proper folders:
   - `documents/02_architecture/implementation/new_customer_dynamics_implementation.R`
   - `documents/01_planning/revision_plans/APP_REVISION_PLAN_20251101.md`
   - `documents/01_planning/revision_plans/REVISION_SUMMARY_20251101.md`

---

## 🔧 Remaining Tasks

### Task 1: Complete module_dna_multi_premium_v2.R

The current v2 file needs completion in these areas:

#### A. Grid Matrix Visualization (Lines ~650-900)
**Location**: `output$grid_matrix <- renderUI({...})`

**Current Status**: Placeholder comment
**Action Required**: Copy from original `module_dna_multi_premium.R` lines 653-913

**Key Updates Needed**:
1. Change `input$lifecycle_stage` → `input$customer_dynamics`
2. Update `lifecycle_stage` variable references → `customer_dynamics`
3. Update warning messages for ni < 4 (no degradation strategy)

```r
# Example update:
# OLD:
req(values$dna_results, input$lifecycle_stage)
df <- df[df$lifecycle_stage == input$lifecycle_stage, ]

# NEW:
req(values$dna_results, input$customer_dynamics)
df <- df[df$customer_dynamics == input$customer_dynamics, ]
```

#### B. Newbie Special Handling (Lines ~783-913)
**Current logic**: Displays A3N/B3N/C3N strategy cards for newbies

**Updates Required**:
1. Filter condition: `filter(customer_dynamics == "newbie")` (was lifecycle_stage)
2. Update all text references from "生命週期" to "顧客動態"
3. Keep the 3-card newbie strategy layout (no functional changes)

#### C. Add Z-Score Diagnostic Plots (NEW Feature)
**Location**: After grid matrix, before customer table

```r
# NEW: Z-Score distribution plot
output$zscore_distribution <- renderPlotly({
  req(values$dna_results, values$zscore_metadata)

  if (values$zscore_metadata$method != "z_score") return(NULL)

  df <- values$dna_results$data_by_customer %>%
    filter(!is.na(z_i))

  plot_ly(df, x = ~z_i, color = ~customer_dynamics, type = "histogram",
          colors = c("newbie" = "#17a2b8", "active" = "#28a745",
                     "sleepy" = "#ffc107", "half_sleepy" = "#fd7e14",
                     "dormant" = "#dc3545")) %>%
    layout(
      title = "Z-Score 分佈 (依顧客動態)",
      xaxis = list(title = "Z-Score"),
      yaxis = list(title = "客戶數量"),
      barmode = "stack"
    ) %>%
    add_lines(x = c(-1.5, -1.5), y = c(0, Inf),
              name = "半睡閾值", line = list(dash = "dash", color = "red")) %>%
    add_lines(x = c(-1.0, -1.0), y = c(0, Inf),
              name = "瞌睡閾值", line = list(dash = "dash", color = "orange")) %>%
    add_lines(x = c(0.5, 0.5), y = c(0, Inf),
              name = "主力閾值", line = list(dash = "dash", color = "green"))
})
```

**Add to UI**: In `dnaMultiPremiumModuleUI()`, after grid matrix:

```r
# NEW: Z-Score diagnostics
conditionalPanel(
  condition = paste0("output['", ns("show_zscore_diagnostics"), "'] == true"),
  h4("📈 Z-Score 診斷圖", style = "text-align: center; margin: 20px 0;"),
  plotlyOutput(ns("zscore_distribution"))
)
```

---

### Task 2: Update module_customer_value_analysis.R (RFM)

**File**: `modules/module_customer_value_analysis.R`
**Change**: Remove `ni >= 4` restriction from RFM calculation

**Current Code** (approx Line 608-620):
```r
calculate_rfm_scores <- function(customer_data) {
  # ❌ OLD: Filter ni >= 4
  customer_data_filtered <- customer_data %>% filter(ni >= 4)

  # Calculate RFM scores...
}
```

**Updated Code**:
```r
calculate_rfm_scores <- function(customer_data) {
  # ✅ NEW: No filtering, calculate for all customers

  customer_data %>%
    mutate(
      # Quintile-based scoring (all customers)
      r_score = ntile(desc(r_value), 5),
      f_score = ntile(ni, 5),
      m_score = ntile(m_value, 5),
      rfm_total_score = r_score + f_score + m_score
    )
}
```

**Additional Updates**:
1. Update documentation comments (Lines ~755-780)
2. Change tag_012 description from "僅 ni ≥ 4" to "所有客戶"
3. Update UI warning message (if exists)

**Testing**:
- Verify newbies get low F scores (expected, correct behavior)
- Check that all customers have rfm_total_score

---

### Task 3: Update module_lifecycle_prediction.R

**File**: `modules/module_lifecycle_prediction.R`
**Change**: Implement "remaining time" algorithm for next purchase prediction

**Current Code** (approx Line 1274-1320):
```r
tag_031_next_purchase_date = as.Date(Sys.time()) + avg_ipt
```

**Updated Code**:
```r
calculate_next_purchase_date <- function(customer_data) {
  customer_data %>%
    mutate(
      # Time elapsed since last purchase
      time_elapsed = r_value,  # recency

      # Expected cycle (use customer's own avg_ipt if available, else μ_ind)
      expected_cycle = ifelse(!is.na(avg_ipt), avg_ipt, mu_ind),

      # Remaining time in current cycle
      remaining_time = pmax(0, expected_cycle - time_elapsed),

      # Predicted next purchase date
      tag_031_next_purchase_date = case_when(
        # Still within cycle: today + remaining time
        remaining_time > 0 ~ as.Date(Sys.time()) + remaining_time,

        # Overdue: predict one full cycle ahead
        TRUE ~ as.Date(Sys.time()) + expected_cycle
      ),

      # Add explanation
      tag_031_explanation = case_when(
        remaining_time > 0 ~ paste0(
          "預計 ", round(remaining_time), " 天後 ",
          "(週期剩餘時間)"
        ),
        TRUE ~ paste0(
          "已逾期 ", round(time_elapsed - expected_cycle), " 天，",
          "預計 ", round(expected_cycle), " 天後 (下個週期)"
        )
      )
    )
}
```

**Integration Point**:
- Find the section that calculates tag_027 through tag_032
- Replace tag_031 calculation with the new function
- Ensure `mu_ind` is available (pass from DNA module metadata)

---

### Task 4: Terminology Updates (Global Search & Replace)

**Files to Update**: All modules + UI text

**Search & Replace Pairs**:
1. `生命週期階段` → `顧客動態`
2. `lifecycle_stage` → `customer_dynamics` (in variable names)
3. `逐漸活躍` → `漸趨活躍戶`
4. `逐漸不活躍` → `漸趨靜止戶`
5. `DNA分析` → `SDNA分析` (optional, based on branding decision)

**Tools**:
```bash
# Use sed for bulk replacement (backup first!)
cd /path/to/modules

# Backup all modules
cp module_*.R module_*.R.backup_20251101

# Replace in all modules
sed -i '' 's/生命週期階段/顧客動態/g' module_*.R
sed -i '' 's/逐漸活躍/漸趨活躍戶/g' module_*.R
sed -i '' 's/逐漸不活躍/漸趨靜止戶/g' module_*.R
```

**Manual Review Required**:
- Check context for `lifecycle_stage` → some may need to stay (like column names in DB)
- Verify UI text makes sense after replacement
- Update help documentation

---

### Task 5: Update app.R Integration

**File**: `app.R`

**Changes Required**:

#### A. Source the new module (Line 86)
```r
# OLD:
source("modules/module_dna_multi_premium.R")

# NEW (for testing):
source("modules/module_dna_multi_premium_v2.R")  # Use v2

# OR (after testing):
# Rename v2 to replace original, then keep same source line
```

#### B. Update UI call (Line ~207)
```r
# Should remain the same (backward compatible)
dnaMultiPremiumModuleUI("dna_multi1")
```

#### C. Update Server call (Line ~400)
```r
# Should remain the same (backward compatible)
dna_mod <- dnaMultiPremiumModuleServer(
  "dna_multi1",
  con_global,
  user_info,
  upload_mod$dna_data
)
```

#### D. Add configuration loading (NEW, Line ~15)
```r
# After loading packages
source("config/customer_dynamics_config.R")  # Load z-score parameters
```

---

### Task 6: Create Configuration File

**File**: `config/customer_dynamics_config.R`

```r
# Customer Dynamics Configuration
# Controls z-score calculation parameters

CUSTOMER_DYNAMICS_CONFIG <- list(
  # Method selection
  method = "auto",  # Options: "z_score", "fixed_threshold", "auto"

  # Z-score parameters
  zscore = list(
    k = 2.5,                     # Tolerance multiplier for W calculation
    min_window = 90,             # Minimum observation window (days)
    use_recency_guardrail = TRUE # Apply recency check for active customers
  ),

  # Fixed threshold parameters (fallback/legacy)
  fixed = list(
    active_threshold = 7,
    sleepy_threshold = 14,
    half_sleepy_threshold = 21
  ),

  # Data validation thresholds
  validation = list(
    min_observation_days = 365,
    min_customers = 100,
    min_repeat_customers = 30,
    min_transactions = 500,
    warn_only = TRUE  # If TRUE, show warning but continue; if FALSE, block
  ),

  # Behavior when validation fails
  fallback_behavior = "warn_and_continue"  # Options: "warn_and_continue", "error", "use_fixed"
)

# Export configuration
get_customer_dynamics_config <- function() {
  CUSTOMER_DYNAMICS_CONFIG
}
```

**Usage in module**:
```r
# In module server
config <- get_customer_dynamics_config()

use_zscore <- if (config$method == "auto") {
  values$data_validation$all_passed
} else if (config$method == "z_score") {
  TRUE
} else {
  FALSE
}
```

---

### Task 7: Update Downstream Modules

These modules consume `lifecycle_stage` from DNA module and need updates:

#### A. module_customer_base_value.R
- **No changes required** (uses ni, avg_ipt, m_value, aov - all still available)

#### B. module_customer_status.R (Line ~80-100)
```r
# OLD:
tag_020_lifecycle_status = case_when(
  lifecycle_stage == "newbie" ~ "新客戶",
  lifecycle_stage == "active" ~ "活躍客戶",
  ...
)

# NEW:
tag_020_customer_dynamics = case_when(
  customer_dynamics == "newbie" ~ "新客戶",
  customer_dynamics == "active" ~ "活躍客戶",
  ...
)
```

#### C. module_rsv_matrix.R
- **Minimal changes** (primarily uses r_value, ni, m_value)
- Update any references to `lifecycle_stage` in filtering/grouping

#### D. module_lifecycle_prediction.R
- Already covered in Task 3
- Update any `lifecycle_stage` references to `customer_dynamics`

#### E. module_advanced_analytics.R
- Update cohort/lifecycle transition analysis
- Change `group_by(lifecycle_stage)` → `group_by(customer_dynamics)`

---

### Task 8: Testing Protocol

#### Unit Tests
Create `tests/test_customer_dynamics_v2.R`:

```r
library(testthat)

test_that("Z-score calculation works correctly", {
  # Test data
  test_data <- data.frame(
    customer_id = 1:10,
    transaction_date = seq(as.Date("2024-01-01"), by = "30 days", length.out = 10),
    transaction_amount = runif(10, 50, 500)
  )

  # Run analysis
  result <- analyze_customer_dynamics_new(test_data)

  # Assertions
  expect_true("z_i" %in% names(result$customer_data))
  expect_true(!is.null(result$metadata$mu_ind))
  expect_true(!is.null(result$metadata$W))
})

test_that("Fallback to fixed thresholds works", {
  # Insufficient data (< 365 days)
  test_data <- data.frame(
    customer_id = 1:5,
    transaction_date = seq(as.Date("2024-10-01"), by = "10 days", length.out = 5),
    transaction_amount = runif(5, 50, 500)
  )

  # Should trigger fallback
  # ... test logic
})

test_that("Activity level is NA for ni < 4", {
  # Test that customers with ni < 4 have activity_level = NA
  # ... test logic
})

test_that("RFM scores calculated for all customers", {
  # Verify RFM works without ni >= 4 filter
  # ... test logic
})
```

#### Integration Test
1. Load test CSV data
2. Run full analysis pipeline
3. Verify all modules execute without error
4. Check output data structure
5. Validate grid assignments

#### User Acceptance Test
1. Upload real client data (anonymized)
2. Compare old vs new classification
3. Review classification changes with business team
4. Validate strategies make sense

---

## 📋 Checklist Before Deployment

- [ ] All modules updated with terminology changes
- [ ] Z-score implementation tested with sample data
- [ ] RFM module works for all customers (ni < 4 included)
- [ ] Lifecycle prediction uses remaining time algorithm
- [ ] Configuration file created and tested
- [ ] Data validation warnings display correctly
- [ ] Grid visualization handles ni < 4 gracefully
- [ ] Newbie special handling still works
- [ ] Downstream modules receive correct data structure
- [ ] UI text updated (生命週期 → 顧客動態)
- [ ] Help documentation updated
- [ ] Performance tested with 10,000+ customers
- [ ] Edge cases handled (σ_w = 0, no repeat customers, etc.)

---

## 🚨 Known Issues & TODOs

### Issue 1: Incomplete v2 Module
**Status**: In Progress
**Action**: Complete grid matrix and table sections (copy from v1 with updates)

### Issue 2: Missing Grid Visualization for ni < 4
**Status**: Design Needed
**Options**:
- A: Show "無" grid position with explanation
- B: Create separate view for ni < 4 customers
- C: Hide from grid, show in table only

**Recommendation**: Option A (simplest, maintains consistency)

### Issue 3: Z-Score Explanation for Users
**Status**: Design Needed
**Action**: Add tooltip/help modal explaining z-scores in plain language

### Issue 4: Performance Optimization
**Status**: Future Enhancement
**Action**: Cache μ_ind and W calculations, add progress bars for large datasets

---

## 📞 Next Steps

1. **Immediate**: Complete `module_dna_multi_premium_v2.R` (grid matrix + table)
2. **Week 1**: Update RFM and prediction modules
3. **Week 1**: Global terminology search & replace
4. **Week 2**: Integration testing
5. **Week 2**: User acceptance testing
6. **Week 3**: Deploy to staging with feature flag
7. **Week 4**: Production rollout (gradual)

---

**Document Status**: Living Document
**Last Updated**: 2025-11-01
**Maintained By**: Development Team
