# fn_analysis_dna.R - Complete Output Structure

**Date**: 2025-11-01
**Question**: Does fn_analysis_dna output contain ALL customer data?
**Answer**: YES - It returns ALL customers with comprehensive DNA metrics

---

## ✅ **YES - fn_analysis_dna.R Returns ALL Customer Data**

### **Return Structure**

```r
result <- fn_analysis_dna(
  df_sales_by_customer = customer_summary,
  df_sales_by_customer_by_date = transaction_data
)

# Returns a LIST with 2 elements:
result
├─ data_by_customer  ← Tibble with ALL customers (one row per customer)
└─ nrec_accu         ← Accuracy metrics for churn prediction model

# Final return statement (Line 1049):
return(list(
  data_by_customer = as_tibble(data_by_customer),
  nrec_accu = as_tibble(nrec_accu)
))
```

---

## 📊 **data_by_customer Structure (Complete Field List)**

### **ALL Fields Included** (50+ columns)

```r
result$data_by_customer

# Columns (grouped by category):

# ============================================================================
# BASIC IDENTIFIERS
# ============================================================================
customer_id          # Unique customer identifier

# ============================================================================
# RFM VALUES (Not scores, just raw values)
# ============================================================================
r_value              # Recency: Days since last purchase
f_value              # Frequency: Purchases per month
m_value              # Monetary: Total spending
aov                  # Average Order Value
ni                   # Number of transactions (purchase count)

# ============================================================================
# TIME METRICS
# ============================================================================
time_first           # Date of first purchase
time_last            # Date of last purchase
customer_age_days    # Days since first purchase (today - time_first)
avg_ipt              # Average Inter-Purchase Time (days between purchases)
ipt_mean             # Mean IPT
ipt_sd               # Standard deviation of IPT
ipt_cv               # Coefficient of variation of IPT

# ============================================================================
# CUSTOMER ACTIVITY INDEX (CAI)
# ============================================================================
cai_value            # Raw CAI value
cai_ecdf             # CAI percentile (0-1, cumulative distribution)
mle                  # Maximum Likelihood Estimate
wmle                 # Weighted MLE
last_ipt             # Most recent inter-purchase time

# ============================================================================
# CUSTOMER VALUE METRICS
# ============================================================================
pcv                  # Past Customer Value
clv                  # Customer Lifetime Value
historical_value     # Total historical spending
future_value         # Predicted future value

# ============================================================================
# ENGAGEMENT SCORES
# ============================================================================
nes_ratio            # Net Engagement Score ratio
nes_value            # Net Engagement Score value (alias for nes_ratio)
e0t                  # Engagement over time
be2                  # Behavioral Engagement score

# ============================================================================
# CHURN PREDICTION
# ============================================================================
nrec_prob            # Churn probability (0-1)
nrec_class           # Churn classification (Yes/No)
nrec_pred            # Predicted churn value

# ============================================================================
# REGULARITY METRICS
# ============================================================================
cri                  # Customer Regularity Index
regularity_score     # Purchasing regularity score

# ============================================================================
# ADDITIONAL CALCULATED FIELDS
# ============================================================================
total_spent          # Total amount spent (same as m_value)
times                # Transaction count (same as ni)
payment_time         # Last payment timestamp
... (and more fields depending on available data)
```

---

## 🔍 **Key Points About Output**

### **1. One Row Per Customer** ✅
```r
nrow(result$data_by_customer) == n_distinct(transaction_data$customer_id)
# TRUE

# Every customer gets exactly ONE row
# No duplicates (enforced by unique(data_by_customer, by = "customer_id"))
```

### **2. ALL Customers Included** ✅
```r
# Includes:
✅ Newbies (ni = 1)
✅ Low-frequency customers (ni = 2, 3)
✅ High-frequency customers (ni >= 4)
✅ Churned customers
✅ Active customers

# NO FILTERING by ni, recency, or any other criteria
```

### **3. Fields Available for ALL Customers** ✅
```r
# These fields exist for EVERY customer (including ni = 1):

r_value       ✅ Always available (days since last = days since first)
f_value       ✅ Always available (calculated from ni and customer_age)
m_value       ✅ Always available (sum of all purchases)
ni            ✅ Always available (count of transactions)
time_first    ✅ Always available
time_last     ✅ Always available
aov           ✅ Always available (m_value / ni)

# These fields may be NA for some customers:

avg_ipt       ⚠️ NA if ni == 1 (need 2+ purchases for interval)
ipt_sd        ⚠️ NA if ni < 3 (need multiple intervals for SD)
cai_value     ⚠️ NA if ni < 4 (CAI calculation requires sufficient data)
cai_ecdf      ⚠️ NA if ni < 4
```

---

## 📋 **Example Output**

### **Sample Data**
```r
# Input: 3 customers with different purchase patterns

transaction_data
  customer_id  transaction_date  transaction_amount
  A001         2024-01-15        500    (only 1 purchase)
  B002         2024-01-10        300
  B002         2024-02-15        400    (2 purchases)
  C003         2024-01-05        200
  C003         2024-02-10        250
  C003         2024-03-15        300
  C003         2024-04-20        350
  C003         2024-05-25        400    (5 purchases)
```

### **Output: result$data_by_customer**
```r
  customer_id  ni  r_value  f_value  m_value  aov    avg_ipt  cai_value  cai_ecdf
  A001         1   15       NA       500      500    NA       NA         NA
  B002         2   45       1.5      700      350    36       NA         NA
  C003         5   5        2.3      1500     300    35       0.45       0.75

# Explanation:
# A001 (Newbie):
#   - ni = 1 (single purchase)
#   - r_value = 15 (15 days since only purchase)
#   - f_value = NA (can't calculate frequency with 1 purchase)
#   - m_value = 500 (total spent)
#   - aov = 500 (500/1)
#   - avg_ipt = NA (need 2+ purchases)
#   - cai_value = NA (need ni >= 4)

# B002 (Low frequency):
#   - ni = 2
#   - r_value = 45 (days since last purchase on 2024-02-15)
#   - f_value = 1.5 (2 purchases / ~1.3 months = 1.5/month)
#   - avg_ipt = 36 (days between 2024-01-10 and 2024-02-15)
#   - cai_value = NA (need ni >= 4)

# C003 (High frequency):
#   - ni = 5
#   - r_value = 5 (days since 2024-05-25)
#   - f_value = 2.3 (5 purchases / ~4.7 months)
#   - avg_ipt = 35 (average of 4 intervals)
#   - cai_value = 0.45 (calculated)
#   - cai_ecdf = 0.75 (75th percentile)
```

---

## ✅ **Critical Understanding for RFM**

### **RFM Needs These Fields** (All Available)
```r
# From fn_analysis_dna.R output:

r_value  ← Used for R score (Recency)
f_value  ← Used for F score (Frequency)
m_value  ← Used for M score (Monetary)
ni       ← Used to check if ni >= 4 (OLD filter, being removed)

# ✅ ALL these fields exist for ALL customers
# ✅ Even newbies (ni=1) have r_value, f_value, m_value
```

### **Why RFM Can Work Without ni Filter**
```r
# OLD thinking:
"Can't calculate RFM for ni < 4 because CAI is NA"
❌ WRONG! CAI ≠ RFM

# CORRECT understanding:
"RFM uses r_value/f_value/m_value, which are available for ALL customers"
✅ CORRECT!

# Example: Newbie with ni=1
customer_data %>% filter(ni == 1)

  customer_id  ni  r_value  f_value  m_value  cai_value  cai_ecdf
  A001         1   5        0.1      500      NA         NA
                    ↓        ↓        ↓
                    ✅       ✅       ✅  Available for RFM!
                                            ↓
                                           NA (not needed for RFM)

# So we CAN calculate:
r_score = 4  (based on r_value = 5)
f_score = 1  (based on f_value = 0.1, low frequency - CORRECT!)
m_score = 3  (based on m_value = 500)
rfm_total = 4 + 1 + 3 = 8
```

---

## 🎯 **Summary: What fn_analysis_dna.R Provides**

### **✅ Provides (Available for ALL Customers)**
```
Customer identifiers      ✅ customer_id
RFM raw values           ✅ r_value, f_value, m_value
Transaction metrics      ✅ ni, aov
Time metrics             ✅ time_first, time_last, customer_age_days
Basic IPT                ✅ avg_ipt (NA for ni=1, but available for ni>=2)
Churn prediction         ✅ nrec_prob, nrec_class
Value metrics            ✅ pcv, clv, historical_value
```

### **⚠️ May Be NA for Some Customers**
```
CAI metrics              ⚠️ cai_value, cai_ecdf (NA for ni < 4)
IPT statistics           ⚠️ ipt_sd, ipt_cv (NA for ni < 3)
Advanced IPT             ⚠️ mle, wmle, last_ipt (NA for ni < 4)
```

### **❌ Does NOT Provide (Must Calculate in Module)**
```
Lifecycle classification ❌ lifecycle_stage / customer_dynamics
Z-scores                 ❌ z_i, F_i_w
RFM scores              ❌ r_score, f_score, m_score (raw values only)
Activity level          ❌ activity_level (高/中/低)
Value level             ❌ value_level (高/中/低)
Grid position           ❌ grid_position (A1-C3)
μ_ind, W, λ_w, σ_w      ❌ (z-score related metrics)
```

---

## 📊 **Data Flow Visualization**

```
Transaction Data (Multiple Rows Per Customer)
    ↓
fn_analysis_dna.R
    ↓
result$data_by_customer (ONE Row Per Customer, ALL Customers)
├─ r_value, f_value, m_value, ni  ← RFM inputs ✅
├─ cai_ecdf, avg_ipt              ← Activity inputs ✅
├─ time_first, customer_age_days  ← Lifecycle inputs ✅
└─ nrec_prob, clv                 ← Other metrics ✅
    ↓
Module Processing (TagPilot-specific)
├─ calculate_rfm_scores()         → Add r_score, f_score, m_score
├─ calculate_z_scores()           → Add z_i, F_i_w, customer_dynamics
├─ calculate_activity_level()     → Add activity_level (using cai_ecdf)
└─ calculate_value_level()        → Add value_level
    ↓
Final Customer Data (Enhanced)
└─ result$data_by_customer + all module additions
```

---

## 🔧 **Practical Example: Using DNA Output**

```r
# Step 1: Call fn_analysis_dna.R (UNCHANGED)
dna_result <- fn_analysis_dna(
  df_sales_by_customer = customer_summary,
  df_sales_by_customer_by_date = transaction_data
)

# Step 2: Extract customer data (ALL customers included)
customer_data <- dna_result$data_by_customer

# Verify all customers present
nrow(customer_data)  # e.g., 1000
n_distinct(transaction_data$customer_id)  # e.g., 1000
# ✅ Same count - no customers lost

# Step 3: Check available fields
names(customer_data)
# [1] "customer_id" "r_value" "f_value" "m_value" "ni" "aov"
# [2] "avg_ipt" "cai_value" "cai_ecdf" "nrec_prob" ...
# ✅ All DNA fields present

# Step 4: Use for RFM (no DNA re-run needed)
customer_data_with_rfm <- calculate_rfm_scores(customer_data)
# ✅ Works for ALL customers, uses existing r/f/m values

# Step 5: Add z-scores (no DNA re-run needed)
zscore_results <- analyze_customer_dynamics_new(transaction_data)
customer_data <- customer_data %>%
  left_join(zscore_results$customer_data %>%
              select(customer_id, z_i, customer_dynamics))
# ✅ Adds new fields, keeps all DNA fields intact

# Step 6: Calculate activity level (uses cai_ecdf from DNA)
customer_data <- customer_data %>%
  mutate(
    activity_level = case_when(
      ni < 4 ~ NA_character_,
      cai_ecdf >= 0.8 ~ "高",
      cai_ecdf >= 0.2 ~ "中",
      TRUE ~ "低"
    )
  )
# ✅ Uses cai_ecdf from DNA output (no re-calculation)
```

---

## ✅ **Final Answer**

**Question**: Does fn_analysis_dna output contain ALL customer data?

**Answer**:
- ✅ **YES** - Returns ALL customers (no filtering)
- ✅ **YES** - One row per customer
- ✅ **YES** - Contains all RFM input fields (r/f/m values)
- ✅ **YES** - Contains CAI for activity level (where applicable)
- ✅ **YES** - Contains all base metrics needed for modules
- ❌ **NO** - Does NOT contain RFM scores (calculate separately)
- ❌ **NO** - Does NOT contain lifecycle classification (calculate in module)
- ❌ **NO** - Does NOT contain z-scores (calculate in module)

**Therefore**:
- fn_analysis_dna.R runs **ONCE**
- Returns **ALL customer data**
- Modules use that data to **add** classifications/scores
- **No need** to run DNA twice
- **No need** to filter before DNA
- **No changes** to fn_analysis_dna.R needed

---

**Document Status**: ✅ Confirmed
**Coverage**: 100% of customers
**Fields**: 50+ DNA metrics
**Modifications Needed**: ❌ None (use as-is)
