# Part 3: Module Details

**Document Version**: v1.0
**Created**: 2025-11-06
**For**: logic_v20251106.md

---

## Module 0: Upload Module

**File**: `modules/module_upload.R`
**Purpose**: Handle CSV file uploads and data preprocessing

### Input
- CSV files with columns: `customer_id`, `payment_time`, `lineitem_price`

### Processing
1. Read CSV files
2. Standardize column names
3. Validate data integrity
4. Combine multiple files if provided

### Output
```r
upload_mod$dna_data()  # Reactive containing combined transaction data
upload_mod$proceed_step()  # Reactive trigger for navigation
```

### Key Features
- Multi-file support
- Date parsing with multiple formats
- Data validation and error reporting

---

## Module 1: DNA Analysis Module (Core)

**File**: `modules/module_dna_multi_premium_v2.R`
**Function**: `dnaMultiPremiumModuleServer()`
**Lines**: 1200+ lines
**Version**: v2.0 with Z-Score

### 1.1 Module Purpose

This is the **CORE MODULE** that:
1. Performs customer dynamics analysis using Z-score or fixed threshold
2. Calculates value segmentation (低/中/高)
3. Calculates activity segmentation (低/中/高)
4. Generates 9-grid positioning (A1-C3)
5. Calculates all 38+ customer tags
6. Provides visualization and export

### 1.2 Processing Steps

#### Step 1-6: Z-Score Customer Dynamics (Lines 250-389)

```r
# Call analyze_customer_dynamics_new()
zscore_results <- analyze_customer_dynamics_new(
  transaction_data = filtered_data,
  method = "auto",  # or "z_score" or "fixed_threshold"
  k = 2.5,
  min_window = 90,
  active_threshold = 0.5,
  sleepy_threshold = -1.0,
  half_sleepy_threshold = -1.5,
  use_recency_guardrail = TRUE
)

# Extract results
customer_data <- sales_by_customer %>%
  left_join(
    zscore_results$customer_data %>%
      select(customer_id, customer_dynamics, value_level),
    by = "customer_id"
  )
```

**Key Point**: This step adds `customer_dynamics` and `value_level` to customer data.

#### Step 7-12: Value Level from Z-Score (Lines 380-495)

```r
# Merge customer_dynamics and value_level from zscore_results
customer_data <- customer_data %>%
  left_join(
    zscore_results$customer_data %>% select(customer_id, customer_dynamics, value_level),
    by = "customer_id"
  )

# Check if value_level exists (from analyze_customer_dynamics_new)
if ("value_level" %in% names(customer_data)) {
  message("[DEBUG]   ✓ value_level already exists from analyze_customer_dynamics_new()")
  value_dist <- table(customer_data$value_level)
  message("[DEBUG]   Distribution: ", paste(names(value_dist), "=", value_dist, collapse = ", "))
} else {
  # Fallback: recalculate (shouldn't happen)
  m_q80 <- quantile(customer_data$m_value, 0.8, na.rm = TRUE)
  m_q20 <- quantile(customer_data$m_value, 0.2, na.rm = TRUE)

  customer_data <- customer_data %>%
    mutate(
      value_level = case_when(
        is.na(m_value) ~ "未知",
        m_value >= m_q80 ~ "高",
        m_value >= m_q20 ~ "中",
        TRUE ~ "低"
      )
    )
}
```

**Critical Fix (2025-11-06)**: The left_join now includes `value_level` to prevent recalculation.

#### Step 13-16: Activity Level Calculation (Lines 498-560)

**Split Customers by ni**:
```r
customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)
```

**For ni ≥ 4**: Use CAI-based method
```r
customers_sufficient <- customers_sufficient %>%
  mutate(
    activity_level = case_when(
      !is.na(cai_ecdf) ~ case_when(
        cai_ecdf >= 0.8 ~ "高",
        cai_ecdf >= 0.2 ~ "中",
        TRUE ~ "低"
      ),
      TRUE ~ NA_character_
    )
  )
```

**For ni < 4**: Set to NA (no degradation)
```r
customers_insufficient <- customers_insufficient %>%
  mutate(activity_level = NA_character_)
```

**Combine**:
```r
customer_data <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)
```

#### Step 17: Grid Position (Lines 563-585)

```r
customer_data <- customer_data %>%
  mutate(
    grid_position = case_when(
      is.na(activity_level) ~ "無",
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

#### Step 18: Calculate All Tags (Lines 587-596)

```r
customer_data <- calculate_all_customer_tags(customer_data)
```

Calls functions from `utils/calculate_customer_tags.R`:
1. `calculate_base_value_tags()` - tag_001, tag_003, tag_004
2. `calculate_rfm_tags()` - tag_009-013
3. `calculate_status_tags()` - tag_017-019
4. `calculate_prediction_tags()` - tag_030-031

### 1.3 Module Output

```r
# Return reactive data for downstream modules
return(reactive({ values$processed_data }))
```

**Data Structure**:
```r
customer_data:
  - customer_id
  - ni, r_value, f_value, m_value, ipt
  - customer_dynamics (newbie/active/sleepy/half_sleepy/dormant)
  - value_level (低/中/高)
  - activity_level (低/中/高/NA)
  - grid_position (A1-C3/"無")
  - z_i, F_i_w (if z-score method used)
  - tag_001 through tag_034+ (all customer tags)
```

### 1.4 UI Components

**Z-Score Metadata Display** (Lines 79-87):
```r
output$zscore_metadata <- renderUI({
  req(values$dna_results)

  if (values$dna_results$method == "z_score") {
    params <- values$dna_results$parameters
    HTML(paste0(
      "<strong>分析方法：</strong>Z-Score 統計方法<br>",
      "<strong>觀察窗口 (W)：</strong>", round(params$W, 1), " 天<br>",
      "<strong>產業中位數 (μ_ind)：</strong>", round(params$mu_ind, 1), " 天<br>",
      "<strong>活躍閾值：</strong>z > ", params$active_threshold,
      " 且 R ≤ 7 天（如啟用保護機制）"
    ))
  } else {
    HTML("<strong>分析方法：</strong>固定閾值方法 (7/14/21 天)")
  }
})
```

**Customer Dynamics Selector** (Lines 625-671):
```r
output$customer_dynamics_selector <- renderUI({
  req(values$dna_results)

  dynamics_counts <- values$dna_results$data_by_customer %>%
    count(customer_dynamics) %>%
    arrange(desc(n))

  radioButtons(
    ns("selected_dynamics"),
    label = "選擇顧客動態：",
    choices = setNames(
      dynamics_counts$customer_dynamics,
      paste0(dynamics_counts$customer_dynamics, " (", dynamics_counts$n, " 人)")
    ),
    selected = "active",
    inline = TRUE
  )
})
```

**Nine-Grid Matrix** (Lines 673-850):

Generates dynamic 3×3 grid based on selected customer_dynamics:

```r
output$grid_matrix <- renderUI({
  req(values$dna_results, input$selected_dynamics)

  filtered_data <- values$dna_results$data_by_customer %>%
    filter(customer_dynamics == input$selected_dynamics)

  # Generate 9 cards (A1-A3, B1-B3, C1-C3)
  fluidRow(
    column(4, generate_grid_card("A1", "高價值 × 高活躍", filtered_data)),
    column(4, generate_grid_card("A2", "高價值 × 中活躍", filtered_data)),
    column(4, generate_grid_card("A3", "高價值 × 低活躍", filtered_data))
  ),
  fluidRow(
    column(4, generate_grid_card("B1", "中價值 × 高活躍", filtered_data)),
    # ... B2, B3 ...
  ),
  fluidRow(
    column(4, generate_grid_card("C1", "低價值 × 高活躍", filtered_data)),
    # ... C2, C3 ...
  )
})
```

Each card shows:
- Customer count in that segment
- Average m_value and f_value
- Recommended marketing strategy
- KPI target

---

## Module 2: Customer Base Value

**File**: `modules/module_customer_base_value.R`
**Function**: `customerBaseValueServer()`

### 2.1 Purpose

Analyze three base value dimensions:
1. Purchase Cycle Segmentation (購買週期分群)
2. Past Value Segmentation (過去價值分群)
3. Average Order Value Analysis (客單價分析)

### 2.2 Input

```r
customerBaseValueServer("id", dna_module_reactive)
```

Expects data with: `customer_id`, `ipt`, `m_value`, `ni`, `customer_dynamics`

### 2.3 Calculations

#### Purchase Cycle Segmentation (Lines 196-232)

```r
# Calculate P20/P80 of ipt
p80 <- quantile(ipt_mean, 0.8, na.rm = TRUE)
p20 <- quantile(ipt_mean, 0.2, na.rm = TRUE)

df_with_ipt <- df_with_ipt %>%
  mutate(
    purchase_cycle_level = case_when(
      ipt_mean >= p80 ~ "高購買週期",  # Infrequent buyers
      ipt_mean >= p20 ~ "中購買週期",
      TRUE ~ "低購買週期"              # Frequent buyers
    )
  )
```

**Interpretation**:
- 低購買週期 = Short IPT = Frequent buyers (good retention)
- 高購買週期 = Long IPT = Infrequent buyers (risk of churn)

#### Past Value Segmentation (Lines 307-343)

```r
# Calculate P20/P80 of total m_value
p80 <- quantile(m_value, 0.8, na.rm = TRUE)
p20 <- quantile(m_value, 0.2, na.rm = TRUE)

df_with_m <- df_with_m %>%
  mutate(
    past_value_level = case_when(
      m_value >= p80 ~ "高價值顧客",
      m_value >= p20 ~ "中價值顧客",
      TRUE ~ "低價值顧客"
    )
  )
```

#### Average Order Value (AOV) (Lines 384-430)

**New vs Main Customers**:
```r
newbie_aov <- df %>%
  filter(customer_dynamics == "newbie") %>%
  summarise(
    avg_aov = mean(m_value, na.rm = TRUE),
    count = n()
  )

main_aov <- df %>%
  filter(customer_dynamics == "active") %>%
  summarise(
    avg_aov = mean(m_value, na.rm = TRUE),
    count = n()
  )
```

### 2.4 UI Output

- **Table 1**: Purchase cycle distribution (高/中/低 counts and percentages)
- **Plot 1**: Bar chart of purchase cycle segments
- **Table 2**: Past value distribution
- **Plot 2**: Bar chart of past value segments
- **ValueBox 1**: Newbie AOV
- **ValueBox 2**: Main customer AOV
- **Plot 3**: AOV comparison bar chart

---

## Module 3: RFM Value Analysis

**File**: `modules/module_customer_value_analysis.R`
**Function**: `customerValueAnalysisServer()`

### 3.1 Purpose

Detailed RFM (Recency, Frequency, Monetary) analysis with scoring and segmentation.

### 3.2 Processing (Lines 318-386)

```r
observe({
  req(customer_data())

  # Calculate RFM tags
  processed <- customer_data() %>%
    calculate_rfm_tags()  # From utils/calculate_customer_tags.R

  values$processed_data <- processed

  # Data quality checks
  issues <- list()

  # Check M value variance
  m_values <- processed$tag_011_rfm_m
  m_cv <- sd(m_values) / mean(m_values)  # Coefficient of variation
  m_p20 <- quantile(m_values, 0.2)
  m_p80 <- quantile(m_values, 0.8)

  if (m_cv < 0.15 || (m_p20 == m_p80)) {
    issues$m_low_variance <- list(
      type = "warning",
      message = "M 值變異度較低，中消費買家分群難以區分"
    )
  }

  # Check F value (single purchase rate)
  f_values <- processed$tag_010_rfm_f
  single_purchase_pct <- mean(f_values < 1.5) * 100

  if (single_purchase_pct > 90) {
    issues$f_high_single <- list(
      type = "info",
      message = sprintf("%.1f%% 客戶僅購買過一次", single_purchase_pct)
    )
  }

  values$data_quality_issues <- issues
})
```

### 3.3 RFM Score Calculation

**Function**: `calculate_rfm_scores()` in `utils/calculate_customer_tags.R`

**Logic**:
```r
# Only calculate for ni >= 4
customer_data <- customer_data %>%
  filter(ni >= 4) %>%
  mutate(
    # R score: Lower recency = higher score (1-5)
    r_score = ntile(desc(tag_009_rfm_r), 5),

    # F score: Higher frequency = higher score (1-5)
    f_score = ntile(tag_010_rfm_f, 5),

    # M score: Higher monetary = higher score (1-5)
    m_score = ntile(tag_011_rfm_m, 5),

    # Total RFM score (3-15)
    tag_012_rfm_score = r_score + f_score + m_score
  )
```

**Example**:
```
Customer A: R=5 days, F=10 times, M=2000
→ r_score=5 (very recent), f_score=4, m_score=5
→ tag_012_rfm_score = 14 (excellent customer)

Customer B: R=45 days, F=2 times, M=300
→ r_score=2, f_score=2, m_score=1
→ tag_012_rfm_score = 5 (at-risk customer)
```

### 3.4 UI Output

1. **Status Panel**: Data quality warnings (if any)
2. **RFM Distribution Plot**: 3 histograms for R, F, M
3. **Value Segment Plot**: Pie chart of 低/中/高 distribution
4. **RFM Heatmap**: Bubble plot (X=M, Y=F, size=R)
5. **Customer Table**: Detailed RFM data with sorting
6. **Download Button**: Export full dataset as CSV

---

## Module 4: Customer Activity (CAI)

**File**: `modules/module_customer_activity.R`
**Function**: `customerActivityServer()`

### 4.1 Purpose

Analyze customer activity trends using CAI (Customer Activity Index).

### 4.2 Key Metrics

**CAI Definition**: Measures whether purchase intervals are getting shorter (active) or longer (inactive).

**CAI Categories**:
- **日益活躍** (Increasingly Active): cai_ecdf >= 0.8
- **穩定** (Stable): 0.2 <= cai_ecdf < 0.8
- **逐漸不活躍** (Increasingly Inactive): cai_ecdf < 0.2

### 4.3 Calculations

```r
# Only for ni >= 4 (sufficient data for CAI)
cai_data <- customer_data %>%
  filter(ni >= 4, !is.na(cai_ecdf)) %>%
  mutate(
    cai_category = case_when(
      cai_ecdf >= 0.8 ~ "日益活躍",
      cai_ecdf >= 0.2 ~ "穩定",
      TRUE ~ "逐漸不活躍"
    )
  )
```

### 4.4 UI Output

1. **CAI Distribution**: Histogram of cai_ecdf values
2. **Category Pie Chart**: Proportion of each CAI category
3. **Lifecycle × CAI Matrix**: Cross-tabulation table
4. **Value × CAI Scatter**: Bubble plot (X=m_value, Y=cai_ecdf)

---

## Module 5: Customer Status

**File**: `modules/module_customer_status.R`
**Function**: `customerStatusServer()`

### 5.1 Purpose

Monitor customer lifecycle status and churn risk.

### 5.2 Key Tags Calculated

Already calculated in `calculate_status_tags()`:

**tag_017_customer_dynamics** (Chinese labels):
```r
tag_017_customer_dynamics = case_when(
  customer_dynamics == "newbie" ~ "新客",
  customer_dynamics == "active" ~ "主力客",
  customer_dynamics == "sleepy" ~ "睡眠客",
  customer_dynamics == "half_sleepy" ~ "半睡客",
  customer_dynamics == "dormant" ~ "沉睡客",
  TRUE ~ customer_dynamics
)
```

**tag_018_churn_risk**:
```r
tag_018_churn_risk = case_when(
  ni == 1 ~ "新客（無法評估）",
  ni < 4 ~ if_else(r_value > 30, "中風險", "低風險"),
  r_value > ipt * 2 ~ "高風險",      # Over 2× purchase cycle
  r_value > ipt * 1.5 ~ "中風險",    # Over 1.5× purchase cycle
  TRUE ~ "低風險"
)
```

**tag_019_days_to_churn** (Estimated days until churn):
```r
tag_019_days_to_churn = case_when(
  ni == 1 ~ NA_real_,   # Newbies: cannot predict
  ni < 4 ~ NA_real_,    # Insufficient data
  TRUE ~ pmax(0, ipt * 2 - r_value)  # 2×IPT - current R
)
```

**Example**:
```
Customer A: ni=5, ipt=30, r_value=20
→ tag_018_churn_risk = "低風險" (20 < 30×1.5)
→ tag_019_days_to_churn = max(0, 30×2 - 20) = 40 days

Customer B: ni=10, ipt=45, r_value=100
→ tag_018_churn_risk = "高風險" (100 > 45×2)
→ tag_019_days_to_churn = max(0, 45×2 - 100) = 0 days (already churned)
```

### 5.3 UI Output

1. **Lifecycle Distribution**: Bar chart of 新客/主力客/睡眠客/半睡客/沉睡客
2. **Churn Risk Distribution**: Pie chart of 高/中/低風險
3. **Days to Churn Histogram**: Distribution of tag_019
4. **Customer Age**: Histogram of customer_age_days
5. **Status Table**: Detailed breakdown with counts

---

## Module 6: RSV Matrix

**File**: `modules/module_rsv_matrix.R`
**Function**: `rsvMatrixServer()`

### 6.1 Purpose

3D customer classification: Risk × Stability × Value

### 6.2 Dimensions

**R (Risk)** - Based on tag_032_dormancy_risk:
- High risk: Long recency, low purchase frequency
- Low risk: Recent purchases, high frequency

**S (Stability)** - Based on tag_033_transaction_stability:
- Stable: Consistent purchase intervals (low CV of IPT)
- Unstable: Irregular purchase patterns (high CV of IPT)

**V (Value)** - Based on tag_034_customer_lifetime_value:
- High value: tag_011_rfm_m × tag_010_rfm_f
- Low value: Low M or F

### 6.3 27-Cell Matrix

```
      Low Value    Medium Value   High Value
      ────────────────────────────────────────
High  │ R3-S3-V1  │ R3-S3-V2    │ R3-S3-V3
Risk  │ R3-S2-V1  │ R3-S2-V2    │ R3-S2-V3
      │ R3-S1-V1  │ R3-S1-V2    │ R3-S1-V3
      ├───────────┼─────────────┼───────────
Mid   │ R2-S3-V1  │ R2-S3-V2    │ R2-S3-V3
Risk  │ R2-S2-V1  │ R2-S2-V2    │ R2-S2-V3
      │ R2-S1-V1  │ R2-S1-V2    │ R2-S1-V3
      ├───────────┼─────────────┼───────────
Low   │ R1-S3-V1  │ R1-S3-V2    │ R1-S3-V3
Risk  │ R1-S2-V1  │ R1-S2-V2    │ R1-S2-V3
      │ R1-S1-V1  │ R1-S1-V2    │ R1-S1-V3
```

Each cell contains specific strategies and KPIs.

### 6.4 UI Output

- **3D Scatter Plot**: Interactive plotly with R/S/V axes
- **Cell Distribution Table**: Count of customers in each RSV cell
- **Top Segments**: Most populated segments with strategies

---

## Module 7: Lifecycle Prediction

**File**: `modules/module_lifecycle_prediction.R`
**Function**: `lifecyclePredictionServer()`

### 7.1 Purpose

Predict future customer behavior:
- Next purchase amount (tag_030)
- Next purchase date (tag_031)

### 7.2 Prediction Logic

**tag_030_next_purchase_amount**:
```r
tag_030_next_purchase_amount = m_value  # Use average transaction value
```

**tag_031_next_purchase_date** (Remaining Time Algorithm):
```r
tag_031_next_purchase_date = case_when(
  # Still within cycle: today + remaining time
  remaining_time > 0 ~ as.Date(Sys.time()) + remaining_time,

  # Overdue: predict one full cycle ahead
  TRUE ~ as.Date(Sys.time()) + ipt
)

# Where:
expected_cycle = ipt
time_elapsed = r_value  # Days since last purchase
remaining_time = pmax(0, expected_cycle - time_elapsed)
```

**Example**:
```
Customer A: ipt=30, r_value=10
→ remaining_time = 30 - 10 = 20 days
→ tag_031 = today + 20 days

Customer B: ipt=30, r_value=40 (overdue)
→ remaining_time = 0
→ tag_031 = today + 30 days (next cycle)
```

### 7.3 UI Output

1. **Next Purchase Amount Distribution**: Histogram
2. **Next Purchase Date Timeline**: Gantt-style chart
3. **Expected Revenue**: Sum of all tag_030 values
4. **Purchase Calendar**: Heatmap of predicted dates

---

## Module 8: Advanced Analytics

**File**: `modules/module_advanced_analytics.R`
**Function**: `advancedAnalyticsServer()`

### 8.1 Purpose

Historical cohort analysis and trend detection (requires time-series data).

### 8.2 Features

- **Cohort Analysis**: Group customers by first purchase month
- **Retention Curves**: Track repeat purchase rates over time
- **Value Trends**: Monitor average order value changes
- **Churn Patterns**: Identify seasonal churn patterns

### 8.3 Requirements

**Minimum Data**:
- At least 12 months of historical data
- Multiple purchase cycles represented

**Note**: This module is marked "需歷史資料" (requires historical data) because single-snapshot uploads don't support trend analysis.

---

**End of Part 3**
