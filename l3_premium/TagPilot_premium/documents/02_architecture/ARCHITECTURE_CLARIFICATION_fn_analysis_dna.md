# Architecture Clarification: fn_analysis_dna.R Remains Unchanged

**Date**: 2025-11-01
**Critical Decision**: Do NOT modify `fn_analysis_dna.R`
**Reason**: Shared across multiple apps, must remain backward compatible

---

## ✅ **IMPORTANT: fn_analysis_dna.R is NOT Changed**

### **Your Concern is 100% Correct**

You are absolutely right to ask this question. `fn_analysis_dna.R` is a **critical shared function** used across:
- ✅ L1 Basic apps (VitalSigns, positioning_app, etc.)
- ✅ L2 Professional apps
- ✅ L3 Premium apps (TagPilot, BrandEdge, etc.)
- ✅ L4 Enterprise apps

**Location**: `/global_scripts/04_utils/fn_analysis_dna.R`

**⚠️ NEVER MODIFY THIS FILE** without updating all dependent apps.

---

## 🏗️ **Architecture Design: Layered Approach**

### **Layer 1: Core DNA Analysis (Unchanged)**
```
fn_analysis_dna.R  ← STAYS THE SAME
├─ Calculates: R, F, M, IPT, CAI, ni, etc.
├─ Returns: Standard DNA metrics
└─ Used by: ALL apps across L1/L2/L3/L4
```

**This function provides**:
- ✅ `r_value` (recency)
- ✅ `ni` (transaction count)
- ✅ `m_value` (monetary value)
- ✅ `avg_ipt` (average inter-purchase time)
- ✅ `cai_ecdf` (CAI percentile)
- ✅ All other standard DNA metrics

**What it DOES NOT do**:
- ❌ Classify lifecycle stage (newbie/active/dormant)
- ❌ Calculate z-scores
- ❌ Implement industry-specific logic

### **Layer 2: Module-Specific Classification (NEW - TagPilot Only)**
```
module_dna_multi_premium_v2.R  ← NEW LOGIC HERE
├─ Calls: fn_analysis_dna.R (unchanged)
├─ Gets: Standard DNA metrics
├─ Adds: Z-score calculation
├─ Adds: Customer dynamics classification
└─ Returns: Enhanced results for TagPilot Premium
```

**This module adds**:
- ✅ μ_ind calculation (median purchase interval)
- ✅ W calculation (observation window)
- ✅ Z-score computation
- ✅ Customer dynamics classification (newbie/active/sleepy/etc.)
- ✅ Industry-adaptive thresholds

---

## 📋 **Complete Data Flow**

### **Step-by-Step Process**

```r
# ============================================================================
# STEP 1: Call Standard DNA Analysis (UNCHANGED)
# ============================================================================

dna_result <- fn_analysis_dna(
  sales_data = transaction_data,
  customer_id_col = "customer_id",
  date_col = "transaction_date",
  amount_col = "transaction_amount"
)

# ✅ Returns standard metrics:
# - data_by_customer: r_value, ni, m_value, avg_ipt, cai_ecdf, etc.
# - NO lifecycle classification included

# ============================================================================
# STEP 2: Add Z-Score Calculation (NEW - TagPilot Only)
# ============================================================================

# Get standard DNA results
customer_data <- dna_result$data_by_customer

# Calculate μ_ind from transaction data (NEW)
mu_result <- calculate_median_purchase_interval(transaction_data)
mu_ind <- mu_result$mu_ind

# Calculate W (NEW)
w_result <- calculate_active_window(transaction_data, mu_ind)
W <- w_result$W

# Count purchases in window W (NEW)
customer_data <- customer_data %>%
  mutate(F_i_w = count_purchases_in_window(transaction_date, W))

# Calculate z-scores (NEW)
non_newbies <- customer_data %>%
  filter(!(ni == 1 & customer_age_days <= mu_ind))

lambda_w <- mean(non_newbies$F_i_w)
sigma_w <- sd(non_newbies$F_i_w)

customer_data <- customer_data %>%
  mutate(z_i = (F_i_w - lambda_w) / sigma_w)

# ============================================================================
# STEP 3: Classify Customer Dynamics (NEW - TagPilot Only)
# ============================================================================

customer_data <- customer_data %>%
  mutate(
    customer_dynamics = case_when(
      ni == 1 & customer_age_days <= mu_ind ~ "newbie",
      z_i >= 0.5 & r_value <= mu_ind ~ "active",
      z_i >= -1.0 ~ "sleepy",
      z_i >= -1.5 ~ "half_sleepy",
      TRUE ~ "dormant"
    )
  )

# ============================================================================
# STEP 4: Calculate Activity Level (Uses CAI from DNA - UNCHANGED)
# ============================================================================

customer_data <- customer_data %>%
  mutate(
    # ✅ Uses cai_ecdf from fn_analysis_dna.R (unchanged)
    activity_level = case_when(
      ni < 4 ~ NA_character_,
      cai_ecdf >= 0.8 ~ "高",
      cai_ecdf >= 0.2 ~ "中",
      TRUE ~ "低"
    )
  )
```

---

## 🔍 **What fn_analysis_dna.R Returns (Unchanged)**

### **Output Structure**
```r
result <- fn_analysis_dna(...)

result$data_by_customer
├─ customer_id
├─ r_value          # Recency (days since last purchase)
├─ ni               # Number of transactions
├─ m_value          # Total monetary value
├─ aov              # Average order value
├─ avg_ipt          # Average inter-purchase time
├─ cai_value        # Customer Activity Index (raw)
├─ cai_ecdf         # CAI percentile (0-1)
├─ time_first       # First purchase date
├─ time_last        # Last purchase date
├─ customer_age_days # Days since first purchase
└─ ... (many other fields)

# ❌ DOES NOT INCLUDE:
# - lifecycle_stage / customer_dynamics
# - z_i (z-score)
# - F_i_w (purchases in window)
# - μ_ind, W, λ_w, σ_w
```

### **What We ADD in Module (NEW)**
```r
# Added by module_dna_multi_premium_v2.R:
customer_data$z_i                # Z-score
customer_data$F_i_w              # Purchases in window W
customer_data$customer_dynamics  # Classification (newbie/active/etc.)
customer_data$value_level        # 高/中/低
customer_data$activity_level     # 高/中/低/NA
customer_data$grid_position      # A1-C3
```

---

## 📊 **Comparison: Old vs New Module Logic**

### **Old Module (module_dna_multi_premium.R)**
```r
observeEvent(input$analyze_uploaded, {

  # Step 1: Call DNA analysis (UNCHANGED)
  dna_result <- fn_analysis_dna(...)
  customer_data <- dna_result$data_by_customer

  # Step 2: CLASSIFY lifecycle stage (FIXED THRESHOLDS)
  customer_data <- customer_data %>%
    mutate(
      lifecycle_stage = case_when(
        ni == 1 ~ "newbie",
        r_value <= 7 ~ "active",      # ❌ Fixed
        r_value <= 14 ~ "sleepy",     # ❌ Fixed
        r_value <= 21 ~ "half_sleepy", # ❌ Fixed
        TRUE ~ "dormant"
      )
    )

  # Step 3: Calculate activity_level (uses CAI from DNA)
  customer_data <- customer_data %>%
    mutate(
      activity_level = case_when(
        ni < 4 ~ use_r_value_degradation(),  # ❌ Degradation
        cai_ecdf >= 0.8 ~ "高",
        cai_ecdf >= 0.2 ~ "中",
        TRUE ~ "低"
      )
    )
})
```

### **New Module (module_dna_multi_premium_v2.R)**
```r
observeEvent(input$analyze_uploaded, {

  # Step 1: Call DNA analysis (✅ STILL UNCHANGED)
  dna_result <- fn_analysis_dna(...)
  customer_data <- dna_result$data_by_customer

  # Step 2: Calculate μ_ind, W, z-scores (✅ NEW LAYER)
  zscore_results <- analyze_customer_dynamics_new(transaction_data)
  customer_data <- zscore_results$customer_data

  # Step 3: CLASSIFY customer_dynamics (✅ Z-SCORE BASED)
  # (Already done in analyze_customer_dynamics_new)
  # customer_dynamics = case_when(
  #   ni == 1 & age <= μ_ind ~ "newbie",
  #   z_i >= 0.5 ~ "active",           # ✅ Statistical
  #   z_i >= -1.0 ~ "sleepy",          # ✅ Statistical
  #   z_i >= -1.5 ~ "half_sleepy",     # ✅ Statistical
  #   TRUE ~ "dormant"
  # )

  # Step 4: Calculate activity_level (✅ STRICT ni >= 4)
  customer_data <- customer_data %>%
    mutate(
      activity_level = case_when(
        ni < 4 ~ NA_character_,  # ✅ No degradation
        cai_ecdf >= 0.8 ~ "高",  # ✅ Still uses CAI from DNA
        cai_ecdf >= 0.2 ~ "中",
        TRUE ~ "低"
      )
    )
})
```

---

## ✅ **Key Principle: Separation of Concerns**

### **What fn_analysis_dna.R Does (UNCHANGED)**
```
┌─────────────────────────────────────┐
│  fn_analysis_dna.R                 │
│  (Shared, Core, Immutable)         │
├─────────────────────────────────────┤
│  Input:  Transaction data          │
│  Output: Standard DNA metrics      │
│          (R, F, M, CAI, IPT, etc.) │
│                                     │
│  ✅ Used by ALL apps               │
│  ✅ Backward compatible            │
│  ✅ Well-tested                    │
│  ✅ No business logic              │
└─────────────────────────────────────┘
```

### **What Module Does (NEW LOGIC)**
```
┌─────────────────────────────────────┐
│  module_dna_multi_premium_v2.R     │
│  (TagPilot-specific, Flexible)     │
├─────────────────────────────────────┤
│  Input:  DNA metrics + Trans data  │
│  Output: Customer dynamics +       │
│          Z-scores + Classifications│
│                                     │
│  ✅ App-specific business logic    │
│  ✅ Can change freely              │
│  ✅ Industry-adaptive              │
│  ✅ Builds on top of DNA           │
└─────────────────────────────────────┘
```

---

## 🎯 **Why This Architecture?**

### **Benefits**

1. **Backward Compatibility** ✅
   - Other apps (L1/L2/L4) continue working unchanged
   - fn_analysis_dna.R remains stable and tested
   - No risk of breaking existing functionality

2. **Flexibility** ✅
   - TagPilot can implement z-score logic
   - Other apps can implement different logic
   - Each app's needs are independent

3. **Maintainability** ✅
   - Clear separation of core vs app-specific logic
   - Easy to debug (know where logic lives)
   - Can update module without touching core

4. **Testing** ✅
   - fn_analysis_dna.R has existing tests
   - Module can be tested independently
   - Reduced risk of regression

### **Design Pattern**

```
Core Layer (Immutable)
    ↓
Application Layer (Flexible)
    ↓
UI Layer (Presentation)
```

This follows the **Open/Closed Principle**:
- Open for extension (add new modules)
- Closed for modification (don't change core)

---

## 📝 **Summary: What Changes & What Doesn't**

### **✅ UNCHANGED (Don't Touch)**
- ❌ `fn_analysis_dna.R` in `/global_scripts/04_utils/`
- ❌ Input parameters to `fn_analysis_dna()`
- ❌ Output structure of `fn_analysis_dna()`
- ❌ CAI calculation logic
- ❌ R/F/M calculation logic
- ❌ IPT calculation logic

### **✅ NEW (TagPilot Module Only)**
- ✅ `new_customer_dynamics_implementation.R` (new functions)
- ✅ `module_dna_multi_premium_v2.R` (enhanced module)
- ✅ Z-score calculation (μ_ind, W, z_i)
- ✅ Customer dynamics classification
- ✅ Industry-adaptive thresholds

### **✅ MODIFIED (Module Level Only)**
- ✅ Activity level logic (remove degradation)
- ✅ RFM filtering (remove ni >= 4 restriction)
- ✅ Lifecycle prediction (remaining time algorithm)
- ✅ Terminology (lifecycle_stage → customer_dynamics)

---

## 🔧 **Testing Strategy**

### **Test 1: DNA Function Unchanged**
```r
# Before and after should give IDENTICAL results
old_result <- fn_analysis_dna(test_data)
new_result <- fn_analysis_dna(test_data)  # Called from new module

# Assert equality
all.equal(old_result, new_result)  # Should be TRUE
```

### **Test 2: Module Enhancement**
```r
# Module adds new fields, doesn't modify existing DNA fields
dna_fields <- names(fn_analysis_dna(test_data)$data_by_customer)
module_result <- dnaMultiPremiumModuleServer(...)

# Check all DNA fields present and unchanged
for (field in dna_fields) {
  expect_equal(
    module_result[[field]],
    dna_result$data_by_customer[[field]]
  )
}

# Check new fields added
expect_true("z_i" %in% names(module_result))
expect_true("customer_dynamics" %in% names(module_result))
```

---

## 🎓 **Developer Guidelines**

### **Rule 1: Never Modify fn_analysis_dna.R**
If you need different DNA calculations, create a NEW function:
- `fn_analysis_dna_premium.R` (app-specific)
- `fn_analysis_dna_v2.R` (experimental)

### **Rule 2: Module Logic is Free to Change**
Modules can:
- Add new calculations
- Change classification logic
- Implement app-specific features

### **Rule 3: Always Call fn_analysis_dna.R First**
Every module should:
1. Call `fn_analysis_dna.R` to get base metrics
2. Add app-specific enhancements on top
3. Return combined results

---

## 📞 **Contact for Questions**

If you need to modify `fn_analysis_dna.R`:
1. **STOP** - Consult team first
2. Document all dependent apps
3. Create comprehensive test suite
4. Plan coordinated rollout across all apps

**Better approach**: Create module-specific wrapper functions instead.

---

**Document Status**: ✅ Confirmed
**Architecture Principle**: Core Immutable, Modules Flexible
**Risk Level**: ✅ Low (fn_analysis_dna.R untouched)
**Backward Compatibility**: ✅ 100% Maintained
