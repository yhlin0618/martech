# Part 2: Core Algorithms & Calculations

**Document Version**: v1.0
**Created**: 2025-11-06
**For**: logic_v20251106.md

---

## 1. Z-Score Customer Dynamics Algorithm

**File**: `utils/analyze_customer_dynamics_new.R`
**Function**: `analyze_customer_dynamics_new()`
**Lines**: 600+ lines
**Reference**: `顧客動態計算方式調整_20251025.md`

### 1.1 Algorithm Overview

The Z-score method classifies customers based on statistical analysis of purchase frequency patterns rather than fixed time thresholds.

**Key Concept**: Compare each customer's recent activity (F_i,w) against the population mean (λ_w) and standard deviation (σ_w).

### 1.2 Step-by-Step Calculation

#### Step 1: Calculate CAP (Observation Window Upper Bound)

**Location**: Lines 113-157

```r
# Calculate CAP (days from earliest to latest transaction)
first_date <- min(transaction_data$transaction_date, na.rm = TRUE)
last_date <- max(transaction_data$transaction_date, na.rm = TRUE)
cap_days <- as.numeric(difftime(last_date, first_date, units = "days"))

message("[DEBUG-FN]   CAP (observation window) = ", cap_days, " days")
message("[DEBUG-FN]   Date range: ", first_date, " to ", last_date)
```

**Example**:
```
First transaction: 2023-01-01
Last transaction:  2024-12-31
CAP = 730 days (2 years)
```

#### Step 2: Calculate μ_ind (Industry Median IPT)

**Location**: Lines 159-199

```r
# Calculate median IPT across all customers (excluding ni=1)
customer_ipt <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    ni = n(),
    time_first = min(transaction_date),
    time_last = max(transaction_date),
    .groups = "drop"
  ) %>%
  filter(ni >= 2) %>%  # Exclude newbies
  mutate(
    ipt = as.numeric(difftime(time_last, time_first, units = "days")) / (ni - 1)
  )

mu_ind <- median(customer_ipt$ipt, na.rm = TRUE)
message("[DEBUG-FN]   μ_ind (industry median IPT) = ", round(mu_ind, 2), " days")
```

**Example**:
```
Customer A: 3 purchases over 60 days → IPT = 60/(3-1) = 30 days
Customer B: 5 purchases over 120 days → IPT = 120/(5-1) = 30 days
Customer C: 2 purchases over 45 days → IPT = 45/(2-1) = 45 days
→ μ_ind = median(30, 30, 45) = 30 days
```

#### Step 3: Calculate W (Recent Activity Window)

**Location**: Lines 164-174

```r
# W = min(μ_ind + k×σ_ind, CAP)
# where k is tolerance multiplier (default 2.5)

sigma_ind <- sd(customer_ipt$ipt, na.rm = TRUE)
W <- min(mu_ind + k * sigma_ind, cap_days)

message("[DEBUG-FN]   σ_ind (SD of IPT) = ", round(sigma_ind, 2))
message("[DEBUG-FN]   k (tolerance) = ", k)
message("[DEBUG-FN]   W (window) = min(", round(mu_ind + k * sigma_ind, 2), ", ", cap_days, ") = ", W, " days")
```

**Formula**:
```
W = min(μ_ind + k×σ_ind, CAP)
```

**Example**:
```
μ_ind = 30 days
σ_ind = 10 days
k = 2.5
→ μ_ind + k×σ_ind = 30 + 2.5×10 = 55 days
CAP = 730 days
→ W = min(55, 730) = 55 days
```

#### Step 4: Calculate F_i,w (Purchase Frequency in Window W)

**Location**: Lines 202-233

```r
# Count transactions for each customer in the last W days
today <- max(transaction_data$transaction_date)
w_days_ago <- today - W

F_i_w_data <- transaction_data %>%
  filter(transaction_date >= w_days_ago) %>%
  group_by(customer_id) %>%
  summarise(
    F_i_w = n(),
    .groups = "drop"
  )

message("[DEBUG-FN]   Window: ", w_days_ago, " to ", today)
message("[DEBUG-FN]   F_i,w calculated for ", nrow(F_i_w_data), " customers")
```

**Example**:
```
Today = 2024-12-31
W = 55 days
Window = 2024-11-06 to 2024-12-31

Customer A transactions in window: 3 → F_i,w = 3
Customer B transactions in window: 1 → F_i,w = 1
Customer C transactions in window: 0 → F_i,w = 0
```

#### Step 5: Calculate Customer Summary Metrics

**Location**: Lines 238-271

```r
customer_summary <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    ni = n(),                          # Total transaction count
    time_first = min(transaction_date),
    time_last = max(transaction_date),
    r_value = as.numeric(difftime(today, max(transaction_date), units = "days")),
    m_value = sum(transaction_amount, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    customer_age_days = as.numeric(difftime(today, time_first, units = "days")),
    ipt = pmax(as.numeric(difftime(time_last, time_first, units = "days")), 1),
    f_value = ni,
    total_spent = m_value,
    m_value = m_value / ni  # Average per transaction
  ) %>%
  left_join(F_i_w_data, by = "customer_id") %>%
  mutate(F_i_w = if_else(is.na(F_i_w), 0, F_i_w))
```

**Example**:
```
Customer A:
- ni = 5 (5 transactions total)
- time_first = 2024-01-01
- time_last = 2024-12-15
- r_value = 31 - 15 = 16 days
- total_spent = 5000
- m_value = 5000 / 5 = 1000
- ipt = (2024-12-15 - 2024-01-01) / (5-1) = 349/4 = 87 days
- customer_age_days = 365 days
- F_i,w = 2 (2 purchases in last 55 days)
```

#### Step 6: Calculate λ_w and σ_w (Population Benchmarks)

**Location**: Lines 276-308

```r
# Exclude newbies (ni = 1) for benchmark calculation
non_newbie <- customer_summary %>%
  filter(ni >= 2)

lambda_w <- mean(non_newbie$F_i_w, na.rm = TRUE)
sigma_w <- sd(non_newbie$F_i_w, na.rm = TRUE)

message("[DEBUG-FN]   λ_w (mean F_i,w) = ", round(lambda_w, 2))
message("[DEBUG-FN]   σ_w (SD F_i,w) = ", round(sigma_w, 2))

# Handle edge case: sigma_w = 0
if (is.na(sigma_w) || sigma_w == 0) {
  warning("Standard deviation is 0 or NA. Falling back to fixed threshold method.")
  method <- "fixed_threshold"
  sigma_w <- 1  # Prevent division by zero
}
```

**Example**:
```
Non-newbie customers F_i,w values: [0, 1, 1, 2, 2, 3, 4, 5]
λ_w = mean = 2.25
σ_w = sd = 1.58
```

#### Step 7: Calculate Z-Score (z_i)

**Location**: Lines 313-327

```r
customer_summary <- customer_summary %>%
  mutate(
    z_i = (F_i_w - lambda_w) / sigma_w
  )

message("[DEBUG-FN]   z_i range: [",
        round(min(customer_summary$z_i, na.rm=TRUE), 2), ", ",
        round(max(customer_summary$z_i, na.rm=TRUE), 2), "]")
```

**Formula**:
```
z_i = (F_i,w - λ_w) / σ_w
```

**Example**:
```
Customer A: F_i,w = 4, λ_w = 2.25, σ_w = 1.58
z_i = (4 - 2.25) / 1.58 = 1.11

Customer B: F_i,w = 0, λ_w = 2.25, σ_w = 1.58
z_i = (0 - 2.25) / 1.58 = -1.42
```

#### Step 8: Classify customer_dynamics

**Location**: Lines 332-415

**Two Methods**:

**Method A: Z-Score Method** (Lines 361-399)
```r
customer_summary <- customer_summary %>%
  mutate(
    customer_dynamics = case_when(
      is.na(r_value) ~ "unknown",
      ni == 1 ~ "newbie",

      # Active: z_i > 0.5 AND (if guardrail enabled) r_value ≤ 7
      z_i > active_threshold &
        (!use_recency_guardrail | r_value <= 7) ~ "active",

      # Sleepy: -1.0 < z_i ≤ 0.5
      z_i > sleepy_threshold ~ "sleepy",

      # Half-sleepy: -1.5 < z_i ≤ -1.0
      z_i > half_sleepy_threshold ~ "half_sleepy",

      # Dormant: z_i ≤ -1.5
      TRUE ~ "dormant"
    )
  )
```

**Thresholds** (configurable):
- `active_threshold` = 0.5 (default)
- `sleepy_threshold` = -1.0 (default)
- `half_sleepy_threshold` = -1.5 (default)

**Method B: Fixed Threshold Method** (Lines 342-357)
```r
customer_summary <- customer_summary %>%
  mutate(
    customer_dynamics = case_when(
      is.na(r_value) ~ "unknown",
      ni == 1 ~ "newbie",
      r_value <= 7 ~ "active",
      r_value <= 14 ~ "sleepy",
      r_value <= 21 ~ "half_sleepy",
      TRUE ~ "dormant"
    )
  )
```

**Example (Z-Score Method)**:
```
Customer A: z_i = 1.11, r_value = 16
→ z_i > 0.5 but r_value > 7 → "sleepy"

Customer B: z_i = 0.8, r_value = 5
→ z_i > 0.5 AND r_value ≤ 7 → "active"

Customer C: z_i = -1.42, r_value = 60
→ z_i ≤ -1.5 → "dormant"

Customer D: ni = 1
→ "newbie" (regardless of z_i or r_value)
```

---

## 2. Value Level Calculation (P20/P80 with Edge Cases)

**File**: `utils/analyze_customer_dynamics_new.R`
**Function**: `analyze_customer_dynamics_new()` - Step 8.5
**Lines**: 419-532

### 2.1 Standard P20/P80 Method

**Formula**:
```
P20 = 20th percentile of m_value
P80 = 80th percentile of m_value

value_level = {
  "高" if m_value ≥ P80    (Top 20%)
  "中" if P20 ≤ m_value < P80    (Middle 60%)
  "低" if m_value < P20    (Bottom 20%)
}
```

**Code** (Lines 493-506):
```r
m_p20 <- quantile(m_values_valid, 0.2, na.rm = TRUE, names = FALSE)
m_p80 <- quantile(m_values_valid, 0.8, na.rm = TRUE, names = FALSE)

customer_summary <- customer_summary %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= m_p80 ~ "高",    # Top 20%
      m_value >= m_p20 ~ "中",    # Middle 60%
      TRUE ~ "低"                 # Bottom 20%
    )
  )
```

**Example**:
```
m_value distribution: [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
P20 = 280 (20th percentile)
P80 = 820 (80th percentile)

Customer A: m_value = 900 → 900 ≥ 820 → "高"
Customer B: m_value = 500 → 280 ≤ 500 < 820 → "中"
Customer C: m_value = 150 → 150 < 280 → "低"
```

### 2.2 Edge Case Handling

**Purpose**: Ensure ALWAYS three groups (低/中/高) even in degenerate data distributions.

#### Edge Case 1: All Values Same or Very Similar

**Condition**: `abs(m_max - m_min) < 0.01` OR `m_p20 == m_p80`

**Solution** (Lines 439-455):
```r
# Force equal split into 3 groups by ranking
customer_summary <- customer_summary %>%
  arrange(m_value) %>%
  mutate(
    value_rank = row_number(),
    value_level = case_when(
      is.na(m_value) ~ "未知",
      value_rank <= ceiling(n() * 0.2) ~ "低",    # Bottom 20% by rank
      value_rank <= ceiling(n() * 0.8) ~ "中",    # Middle 60% by rank
      TRUE ~ "高"                                  # Top 20% by rank
    )
  ) %>%
  select(-value_rank)
```

**Example**:
```
10 customers all with m_value = 1000 (or very close: 999-1001)
→ P20 = P80 = 1000
→ Cannot distinguish groups with percentile method
→ Force split: rank 1-2 = "低", rank 3-8 = "中", rank 9-10 = "高"
```

#### Edge Case 2: P20 Equals Minimum

**Condition**: `m_p20 == m_min`

**Problem**: Many customers at minimum value → No "低" group

**Solution** (Lines 457-473):
```r
# Force bottom 20% by rank to be "低"
customer_summary <- customer_summary %>%
  arrange(m_value) %>%
  mutate(
    value_rank = row_number(),
    value_level = case_when(
      is.na(m_value) ~ "未知",
      value_rank <= ceiling(n() * 0.2) ~ "低",    # Force bottom 20%
      m_value >= m_p80 ~ "高",
      TRUE ~ "中"
    )
  ) %>%
  select(-value_rank)
```

**Example**:
```
m_value distribution: [100, 100, 100, 100, 500, 600, 700, 800, 900, 1000]
P20 = 100 (same as min)
→ Only 2 groups would result: m_value=100 ("中") and m_value≥820 ("高")
→ Force bottom 20% (rank 1-2) = "低" to ensure 3 groups
```

#### Edge Case 3: P80 Equals Maximum

**Condition**: `m_p80 == m_max`

**Problem**: Many customers at maximum value → No "高" group

**Solution** (Lines 475-491):
```r
# Force top 20% by rank to be "高"
customer_summary <- customer_summary %>%
  arrange(desc(m_value)) %>%  # Sort descending
  mutate(
    value_rank = row_number(),
    value_level = case_when(
      is.na(m_value) ~ "未知",
      value_rank <= ceiling(n() * 0.2) ~ "高",    # Force top 20%
      m_value < m_p20 ~ "低",
      TRUE ~ "中"
    )
  ) %>%
  select(-value_rank)
```

**Example**:
```
m_value distribution: [100, 200, 300, 400, 500, 1000, 1000, 1000, 1000, 1000]
P80 = 1000 (same as max)
→ Only 2 groups would result: m_value<280 ("低") and m_value≥280 ("中")
→ Force top 20% (rank 1-2 in descending order) = "高" to ensure 3 groups
```

### 2.3 Validation

**Code** (Lines 508-520):
```r
# Show distribution
value_dist <- table(customer_summary$value_level)
message("[DEBUG-FN]   Value level distribution:")
for (i in seq_along(value_dist)) {
  message("[DEBUG-FN]     ", names(value_dist)[i], ": ", value_dist[i], " (",
          round(100 * value_dist[i] / sum(value_dist), 1), "%)")
}

# Verify 3 groups exist (excluding "未知")
non_unknown_groups <- setdiff(names(value_dist), "未知")
if (length(non_unknown_groups) < 3) {
  message("[WARN-FN]   Only ", length(non_unknown_groups),
          " groups generated: ", paste(non_unknown_groups, collapse = ", "))
}
```

**Output Example**:
```
[DEBUG-FN]   Value level distribution:
[DEBUG-FN]     低: 7670 (20.0%)
[DEBUG-FN]     中: 23010 (60.0%)
[DEBUG-FN]     高: 7670 (20.0%)
```

---

## 3. Activity Level Calculation

**File**: `modules/module_dna_multi_premium_v2.R`
**Location**: Lines 498-549

### 3.1 Two-Tier Strategy

**Strategy depends on ni (transaction count)**:

#### Tier 1: ni ≥ 4 (Sufficient Data) - Use CAI

**Method**: CAI-based percentile (cai_ecdf)

**Code** (Lines 518-530):
```r
customers_sufficient <- customers_sufficient %>%
  mutate(
    activity_level = case_when(
      !is.na(cai_ecdf) ~ case_when(
        cai_ecdf >= 0.8 ~ "高",  # 漸趨活躍戶 (Top 20%)
        cai_ecdf >= 0.2 ~ "中",  # 穩定消費 (Middle 60%)
        TRUE ~ "低"              # 漸趨靜止戶 (Bottom 20%)
      ),
      TRUE ~ NA_character_
    )
  )
```

**Logic**:
- CAI (Customer Activity Index) reflects purchase interval changes over time
- High cai_ecdf (≥0.8) = Increasingly active (intervals getting shorter)
- Low cai_ecdf (<0.2) = Increasingly inactive (intervals getting longer)

**Example**:
```
Customer A: ni = 5, cai_ecdf = 0.85
→ cai_ecdf ≥ 0.8 → activity_level = "高"

Customer B: ni = 10, cai_ecdf = 0.50
→ 0.2 ≤ cai_ecdf < 0.8 → activity_level = "中"

Customer C: ni = 8, cai_ecdf = 0.15
→ cai_ecdf < 0.2 → activity_level = "低"
```

#### Tier 2: ni < 4 (Insufficient Data) - Set to NA

**Method**: No degradation strategy - strictly NA

**Code** (Lines 537-548):
```r
customers_insufficient <- customers_insufficient %>%
  mutate(
    activity_level = NA_character_
  )
```

**Rationale**:
- CAI requires at least 3 intervals (4 transactions minimum)
- With ni < 4, no reliable activity trend can be calculated
- Previous versions used r_value-based degradation, but v2 removes this

**Example**:
```
Customer D: ni = 3
→ activity_level = NA (insufficient data)

Customer E: ni = 1 (newbie)
→ activity_level = NA (no purchase history)
```

### 3.2 CAI Calculation Logic

**CAI (Customer Activity Index)** is calculated in the legacy `fn_analysis_dna.R` function.

**High-Level Concept**:
```
CAI = f(purchase interval changes over time)

If intervals are decreasing → CAI high → Customer becoming more active
If intervals are stable → CAI medium → Customer stable
If intervals are increasing → CAI low → Customer becoming less active
```

**Requirements**:
- Minimum 4 transactions (3 intervals)
- Calculates cumulative distribution function (ecdf) across all customers

---

## 4. Grid Position Calculation

**File**: `modules/module_dna_multi_premium_v2.R`
**Location**: Lines 563-585

### 4.1 Nine-Grid Matrix (3×3)

**Formula**:
```
grid_position = value_level × activity_level
```

**Mapping**:
```
         高活躍    中活躍    低活躍
高價值     A1       A2       A3
中價值     B1       B2       B3
低價值     C1       C2       C3
```

**Code**:
```r
customer_data <- customer_data %>%
  mutate(
    grid_position = case_when(
      is.na(activity_level) ~ "無",  # ni < 4
      value_level == "高" & activity_level == "高" ~ "A1",
      value_level == "高" & activity_level == "中" ~ "A2",
      value_level == "高" & activity_level == "低" ~ "A3",
      value_level == "中" & activity_level == "高" ~ "B1",
      value_level == "中" & activity_level == "中" ~ "B2",
      value_level == "中" & activity_level == "低" ~ "B3",
      value_level == "低" & activity_level == "高" ~ "C1",
      value_level == "低" & activity_level == "中" ~ "C2",
      value_level == "低" & activity_level == "低" ~ "C3",
      TRUE ~ "其他"
    )
  )
```

**Examples**:
```
Customer A: value_level = "高", activity_level = "高" → A1
Customer B: value_level = "中", activity_level = "低" → B3
Customer C: value_level = "低", activity_level = NA → "無" (ni < 4)
```

---

**End of Part 2**
