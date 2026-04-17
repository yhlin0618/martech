# Part 5: Complete Display Calculations & Visualizations

**Document Version**: v1.0
**Created**: 2025-11-06
**Purpose**: Document EVERY number, figure, and visualization in the UI with exact calculation formulas

---

## Overview

This section documents **every single number and visualization** displayed in the TagPilot Premium UI, including:
- How each number is calculated
- Where the data comes from
- Exact formulas and code
- Example calculations

---

## Module 1: DNA Analysis & Nine-Grid

### Display 1.1: Z-Score Metadata Panel

**Location**: DNA Analysis page, top panel
**Code**: `module_dna_multi_premium_v2.R:79-87`

**Numbers Displayed**:

1. **觀察窗口 (W)**
   ```r
   # Source: analyze_customer_dynamics_new() parameters
   W = min(μ_ind + k×σ_ind, CAP)
   # Display: Round to 1 decimal
   format: round(params$W, 1), " 天"
   # Example: "55.0 天"
   ```

2. **產業中位數 (μ_ind)**
   ```r
   # Source: Median IPT of all non-newbie customers
   μ_ind = median(ipt_values where ni >= 2)
   # Display: Round to 1 decimal
   format: round(params$mu_ind, 1), " 天"
   # Example: "30.0 天"
   ```

3. **活躍閾值**
   ```r
   # Source: Configuration parameter
   active_threshold = 0.5 (default)
   # Display: "z > 0.5 且 R ≤ 7 天"
   ```

### Display 1.2: Customer Dynamics Selector (Radio Buttons)

**Code**: `module_dna_multi_premium_v2.R:625-671`

**Numbers Displayed**: Customer count per lifecycle stage

```r
# Calculation
dynamics_counts <- data_by_customer %>%
  count(customer_dynamics) %>%
  arrange(desc(n))

# Display format
choices = paste0(customer_dynamics, " (", n, " 人)")
# Example: "active (1234 人)"
```

**All 5 Options**:
```r
newbie (XXX 人)      # ni = 1
active (XXX 人)      # z_i > 0.5 AND r_value ≤ 7
sleepy (XXX 人)      # -1.0 < z_i ≤ 0.5
half_sleepy (XXX 人) # -1.5 < z_i ≤ -1.0
dormant (XXX 人)     # z_i ≤ -1.5
```

### Display 1.3: Nine-Grid Cell Cards (A1-C3)

**Code**: `module_dna_multi_premium_v2.R:673-850`

**For EACH of 9 cells**, the following numbers are calculated:

#### Number 1: Customer Count
```r
# Filter customers in this grid cell
cell_customers <- data %>%
  filter(
    value_level == cell_value_level &
    activity_level == cell_activity_level &
    customer_dynamics == selected_dynamics
  )

customer_count = nrow(cell_customers)
# Display: "{count} 位客戶"
# Example: "234 位客戶"
```

#### Number 2: Average M Value (平均M值)
```r
avg_m = mean(cell_customers$m_value, na.rm = TRUE)
# Display: format(round(avg_m, 0), big.mark = ","), " 元"
# Example: "1,234 元"
```

#### Number 3: Average F Value (平均F值)
```r
avg_f = mean(cell_customers$f_value, na.rm = TRUE)
# Display: round(avg_f, 1), " 次"
# Example: "5.3 次"
```

**Total Numbers per Grid**: 9 cells × 3 numbers = **27 numbers**
**Total per Lifecycle**: 27 numbers × 5 lifecycles = **135 numbers**

---

## Module 2: Customer Base Value

### Display 2.1: Purchase Cycle Segmentation Table

**Code**: `module_customer_base_value.R:196-232`

**Numbers Displayed**:

#### Calculation Logic
```r
# Step 1: Calculate P20 and P80 of IPT
p80 <- quantile(ipt_mean, 0.8, na.rm = TRUE)
p20 <- quantile(ipt_mean, 0.2, na.rm = TRUE)

# Step 2: Classify
purchase_cycle_level = case_when(
  ipt_mean >= p80 ~ "高購買週期",
  ipt_mean >= p20 ~ "中購買週期",
  TRUE ~ "低購買週期"
)

# Step 3: Count and calculate percentages
cycle_counts <- df %>%
  count(purchase_cycle_level) %>%
  mutate(
    percentage = round(100 * n / sum(n), 1)
  )
```

**Table Output**:
```
購買週期  | 客戶數 | 佔比
----------|--------|------
低購買週期 | 7,670  | 20.0%
中購買週期 | 23,010 | 60.0%
高購買週期 | 7,670  | 20.0%
```

**Formulas**:
- Customer Count: `count(purchase_cycle_level)`
- Percentage: `round(100 * count / total_count, 1)` + "%"

### Display 2.2: Purchase Cycle Bar Chart

**Code**: `module_customer_base_value.R:234-278`

```r
plot_ly(
  data = cycle_counts,
  x = ~purchase_cycle_level,
  y = ~n,
  type = "bar",
  marker = list(color = c("#28a745", "#ffc107", "#dc3545")),
  text = ~paste0(n, " 人 (", percentage, "%)"),
  textposition = "outside"
)
```

**Chart Elements**:
- X-axis: 低/中/高購買週期 (categories)
- Y-axis: Customer count (numeric)
- Bar labels: "{count} 人 ({percentage}%)"
- Colors: Green(低), Yellow(中), Red(高)

### Display 2.3: Past Value Segmentation Table

**Code**: `module_customer_base_value.R:307-343`

**Calculation**:
```r
# Step 1: Calculate P20 and P80 of m_value
p80 <- quantile(m_value, 0.8, na.rm = TRUE)
p20 <- quantile(m_value, 0.2, na.rm = TRUE)

# Step 2: Classify
past_value_level = case_when(
  m_value >= p80 ~ "高價值顧客",
  m_value >= p20 ~ "中價值顧客",
  TRUE ~ "低價值顧客"
)

# Step 3: Calculate statistics
value_summary <- df %>%
  group_by(past_value_level) %>%
  summarise(
    customer_count = n(),
    avg_m_value = mean(m_value, na.rm = TRUE),
    total_sales = sum(m_value, na.rm = TRUE),
    percentage = round(100 * n() / nrow(df), 1)
  )
```

**Table Output**:
```
價值等級   | 客戶數 | 平均消費    | 總銷售額      | 佔比
-----------|--------|-------------|---------------|------
高價值顧客 | 7,670  | $15,234     | $116,844,180  | 20.0%
中價值顧客 | 23,010 | $5,678      | $130,658,780  | 60.0%
低價值顧客 | 7,670  | $1,234      | $9,464,980    | 20.0%
```

### Display 2.4: AOV Analysis - ValueBoxes

**Code**: `module_customer_base_value.R:432-520`

#### ValueBox 1: Newbie AOV
```r
# Calculation
newbie_data <- df %>%
  filter(customer_dynamics == "newbie") %>%
  mutate(aov = m_value / ni)

newbie_avg_aov = mean(newbie_data$aov, na.rm = TRUE)

# Display
bs4ValueBox(
  value = paste0("$", format(round(newbie_avg_aov, 0), big.mark = ",")),
  subtitle = "新客平均客單價"
)
```

**Formula**: `AOV_newbie = mean(m_value / ni) for newbie customers`
**Example**: "$1,234"

#### ValueBox 2: Active Customer AOV
```r
# Calculation
active_data <- df %>%
  filter(customer_dynamics == "active") %>%
  mutate(aov = m_value / ni)

active_avg_aov = mean(active_data$aov, na.rm = TRUE)

# Display
bs4ValueBox(
  value = paste0("$", format(round(active_avg_aov, 0), big.mark = ",")),
  subtitle = "主力客平均客單價"
)
```

**Formula**: `AOV_active = mean(m_value / ni) for active customers`
**Example**: "$2,456"

#### ValueBox 3: AOV Difference
```r
# Calculation
diff_amount = active_avg_aov - newbie_avg_aov
diff_percent = round((diff_amount / newbie_avg_aov) * 100, 1)

# Display
bs4ValueBox(
  value = paste0(diff_percent, "%"),
  subtitle = "主力客相對新客提升"
)
```

**Formula**: `Diff% = ((AOV_active - AOV_newbie) / AOV_newbie) × 100`
**Example**: "+99.0%" (if active=$2,456, newbie=$1,234 → (2456-1234)/1234 = 99.0%)

### Display 2.5: AOV Comparison Bar Chart

**Code**: `module_customer_base_value.R:522-570`

```r
# Data preparation
aov_comparison <- summary_data %>%
  select(stage_name, avg_aov)

# Plot
plot_ly(
  data = aov_comparison,
  x = ~stage_name,
  y = ~avg_aov,
  type = "bar",
  marker = list(
    color = c("#28a745", "#007bff")  # Green for newbie, Blue for active
  ),
  text = ~paste0("$", format(avg_aov, big.mark = ",")),
  textposition = "outside"
) %>%
  layout(
    xaxis = list(title = "客戶類型"),
    yaxis = list(title = "平均客單價 (元)")
  )
```

**Chart Elements**:
- X-axis: 新客, 主力客
- Y-axis: Average AOV (numeric, dollars)
- Bar labels: "$X,XXX"
- Colors: Green(newbie), Blue(active)

---

## Module 3: RFM Value Analysis

### Display 3.1: Status Panel - Quality Warnings

**Code**: `module_customer_value_analysis.R:332-386`

**Warning 1: Low M Value Variance**

```r
# Trigger condition
m_values <- processed$tag_011_rfm_m
m_cv = sd(m_values) / mean(m_values)  # Coefficient of Variation
m_p20 = quantile(m_values, 0.2)
m_p80 = quantile(m_values, 0.8)

if (m_cv < 0.15 || m_p20 == m_p80) {
  # Show warning
  message <- sprintf(
    "您的資料中有大量客戶的平均消費金額集中在 %s 元附近（變異係數: %.2f）",
    format(round(median(m_values), 0), big.mark = ","),
    m_cv
  )
}
```

**Numbers Displayed**:
- Median M value: `format(round(median(m_values), 0), big.mark = ",")`
- CV: `round(m_cv, 2)`

**Warning 2: High Single Purchase Rate**

```r
# Calculation
f_values <- processed$tag_010_rfm_f
single_purchase_pct = mean(f_values < 1.5) * 100

if (single_purchase_pct > 90) {
  message <- sprintf(
    "您的資料中有 %.1f%% 的客戶僅購買過一次",
    single_purchase_pct
  )
}
```

**Number Displayed**: `round(single_purchase_pct, 1)` + "%"

### Display 3.2: RFM Distribution - 3 Histograms

**Code**: `module_customer_value_analysis.R:443-520`

#### Histogram 1: R Value Distribution
```r
plot_ly(
  x = ~tag_009_rfm_r,
  type = "histogram",
  marker = list(color = "#007bff"),
  nbinsx = 30,
  name = "R值（天）"
) %>%
  layout(
    xaxis = list(title = "最近購買天數 (R)"),
    yaxis = list(title = "客戶數")
  )
```

**X-axis**: R value (days since last purchase)
**Y-axis**: Count of customers
**Bins**: 30 bins

#### Histogram 2: F Value Distribution
```r
plot_ly(
  x = ~tag_010_rfm_f,
  type = "histogram",
  marker = list(color = "#28a745"),
  nbinsx = 20,
  name = "F值（次）"
) %>%
  layout(
    xaxis = list(title = "購買頻率 (F) - 次"),
    yaxis = list(title = "客戶數")
  )
```

**X-axis**: F value (transaction count)
**Y-axis**: Count of customers
**Bins**: 20 bins

#### Histogram 3: M Value Distribution
```r
plot_ly(
  x = ~tag_011_rfm_m,
  type = "histogram",
  marker = list(color = "#dc3545"),
  nbinsx = 30,
  name = "M值（元）"
) %>%
  layout(
    xaxis = list(title = "購買金額 (M)"),
    yaxis = list(title = "客戶數")
  )
```

**X-axis**: M value (monetary value in dollars)
**Y-axis**: Count of customers
**Bins**: 30 bins

### Display 3.3: Value Segment Pie Chart

**Code**: `module_customer_value_analysis.R:522-560`

```r
# Data calculation
segment_counts <- processed %>%
  filter(!is.na(tag_013_value_segment)) %>%
  count(tag_013_value_segment) %>%
  mutate(
    percentage = round(100 * n / sum(n), 1)
  )

# Plot
plot_ly(
  data = segment_counts,
  labels = ~tag_013_value_segment,
  values = ~n,
  type = "pie",
  marker = list(
    colors = c("低" = "#dc3545", "中" = "#ffc107", "高" = "#28a745")
  ),
  textinfo = "label+percent",
  hovertext = ~paste0(tag_013_value_segment, "<br>",
                      "客戶數: ", n, " (", percentage, "%)")
)
```

**Segments Displayed**:
- 低 (Low): {count} customers, {percentage}%
- 中 (Mid): {count} customers, {percentage}%
- 高 (High): {count} customers, {percentage}%

**Formulas**:
- Count: `count(tag_013_value_segment)`
- Percentage: `round(100 * count / total, 1)`

### Display 3.4: RFM Heatmap (Bubble Plot)

**Code**: `module_customer_value_analysis.R:562-605`

```r
plot_ly(
  data = plot_data,
  x = ~tag_011_rfm_m,              # X-axis: Monetary
  y = ~tag_010_rfm_f,              # Y-axis: Frequency
  size = ~tag_009_rfm_r,           # Bubble size: Recency
  color = ~tag_013_value_segment,  # Color: Value segment
  colors = c("低" = "#dc3545", "中" = "#ffc107", "高" = "#28a745"),
  text = ~paste0(
    "Customer: ", customer_id, "<br>",
    "M值（購買金額）: $", format(round(tag_011_rfm_m, 0), big.mark = ","), "<br>",
    "F值（頻率）: ", tag_010_rfm_f, " 次<br>",
    "R值（新近度）: ", tag_009_rfm_r, " 天<br>",
    "RFM總分: ", tag_012_rfm_score
  ),
  type = "scatter",
  mode = "markers"
)
```

**Chart Elements**:
- **X-axis**: M value (monetary, dollars)
- **Y-axis**: F value (frequency, count)
- **Bubble size**: R value (recency, days) - larger = longer recency
- **Bubble color**: Value segment (低/中/高)
- **Hover info**: All RFM details + customer ID + RFM score

**Example Tooltip**:
```
Customer: CUST001
M值（購買金額）: $2,345
F值（頻率）: 8 次
R值（新近度）: 15 天
RFM總分: 12
```

### Display 3.5: Customer Table

**Code**: `module_customer_value_analysis.R:609-678`

**Columns Displayed**:

1. **客戶ID**: `customer_id` (character)
2. **R值（天）**: `tag_009_rfm_r` (numeric, days)
3. **F值（次）**: `tag_010_rfm_f` (numeric, count)
4. **M值（元）**: `format(round(tag_011_rfm_m, 0), big.mark = ",")` (formatted currency)
5. **RFM總分**: `tag_012_rfm_score` (numeric, 3-15 range)
6. **價值分群**: `tag_013_value_segment` (character, 低/中/高)

**Sorting**: Default sort by `tag_012_rfm_score` descending (highest scores first)

**Display**: Top 100 customers

**Pagination**: 10 rows per page

---

## Module 4: Customer Activity (CAI)

### Display 4.1: CAI Distribution Histogram

**Code**: `module_customer_activity.R:200-250`

```r
# Filter data (only ni >= 4)
cai_data <- customer_data %>%
  filter(ni >= 4, !is.na(cai_ecdf))

# Plot
plot_ly(
  x = cai_data$cai_ecdf,
  type = "histogram",
  marker = list(color = "#17a2b8"),
  nbinsx = 30
) %>%
  layout(
    xaxis = list(title = "CAI 百分位數 (0-1)"),
    yaxis = list(title = "客戶數"),
    title = "CAI 分佈"
  )
```

**X-axis**: cai_ecdf values (0 to 1 scale)
**Y-axis**: Count of customers
**Bins**: 30 bins
**Note**: Only includes customers with ni ≥ 4

### Display 4.2: CAI Category Pie Chart

**Code**: `module_customer_activity.R:252-300`

```r
# Classify CAI
cai_classified <- cai_data %>%
  mutate(
    cai_category = case_when(
      cai_ecdf >= 0.8 ~ "日益活躍",
      cai_ecdf >= 0.2 ~ "穩定",
      TRUE ~ "逐漸不活躍"
    )
  )

# Count
cai_counts <- cai_classified %>%
  count(cai_category) %>%
  mutate(percentage = round(100 * n / sum(n), 1))

# Plot
plot_ly(
  data = cai_counts,
  labels = ~cai_category,
  values = ~n,
  type = "pie",
  marker = list(
    colors = c(
      "日益活躍" = "#28a745",
      "穩定" = "#ffc107",
      "逐漸不活躍" = "#dc3545"
    )
  ),
  textinfo = "label+percent"
)
```

**Categories**:
- 日益活躍 (Increasingly Active): cai_ecdf ≥ 0.8
- 穩定 (Stable): 0.2 ≤ cai_ecdf < 0.8
- 逐漸不活躍 (Increasingly Inactive): cai_ecdf < 0.2

**Numbers**: Count and percentage for each category

### Display 4.3: Lifecycle × CAI Cross-Tab Matrix

**Code**: `module_customer_activity.R:302-360`

```r
# Cross-tabulation
cross_tab <- cai_classified %>%
  count(customer_dynamics, cai_category) %>%
  pivot_wider(
    names_from = cai_category,
    values_from = n,
    values_fill = 0
  )

# Display as table
datatable(
  cross_tab,
  options = list(pageLength = 10),
  rownames = FALSE
)
```

**Table Structure**:
```
客戶動態   | 日益活躍 | 穩定  | 逐漸不活躍
-----------|----------|-------|------------
newbie     | 0        | 0     | 0
active     | 234      | 567   | 89
sleepy     | 45       | 123   | 234
half_sleepy| 12       | 67    | 189
dormant    | 5        | 23    | 345
```

**Note**: Newbies typically show 0 because they have ni=1 (no CAI calculated)

---

## Module 5: Customer Status

### Display 5.1: Lifecycle Distribution Bar Chart

**Code**: `module_customer_status.R:289-371`

```r
# Count by lifecycle
lifecycle_counts <- processed_data %>%
  count(tag_017_customer_dynamics) %>%
  mutate(
    percentage = round(100 * n / sum(n), 1),
    label = paste0(tag_017_customer_dynamics, "\n", n, " 人 (", percentage, "%)")
  )

# Plot
plot_ly(
  data = lifecycle_counts,
  x = ~tag_017_customer_dynamics,
  y = ~n,
  type = "bar",
  marker = list(
    color = c(
      "新客" = "#28a745",
      "主力客" = "#007bff",
      "睡眠客" = "#ffc107",
      "半睡客" = "#fd7e14",
      "沉睡客" = "#dc3545"
    )[tag_017_customer_dynamics]
  ),
  text = ~label,
  textposition = "outside"
) %>%
  layout(
    xaxis = list(title = "生命週期階段"),
    yaxis = list(title = "客戶數")
  )
```

**X-axis**: 5 lifecycle stages (Chinese labels)
**Y-axis**: Customer count
**Bar labels**: "{stage}\n{count} 人 ({percentage}%)"
**Colors**: Green→Blue→Yellow→Orange→Red (reflecting risk level)

**Example Labels**:
- "新客\n1,234 人 (12.3%)"
- "主力客\n5,678 人 (56.7%)"
- "沉睡客\n910 人 (9.1%)"

### Display 5.2: Churn Risk Pie Chart

**Code**: `module_customer_status.R:373-425`

```r
# Count by risk level
risk_counts <- processed_data %>%
  filter(!is.na(tag_018_churn_risk)) %>%
  count(tag_018_churn_risk) %>%
  mutate(percentage = round(100 * n / sum(n), 1))

# Plot
plot_ly(
  data = risk_counts,
  labels = ~tag_018_churn_risk,
  values = ~n,
  type = "pie",
  marker = list(
    colors = c(
      "高風險" = "#dc3545",
      "中風險" = "#ffc107",
      "低風險" = "#28a745",
      "新客（無法評估）" = "#6c757d"
    )[tag_018_churn_risk]
  ),
  textinfo = "label+percent",
  hovertext = ~paste0(tag_018_churn_risk, "<br>",
                      "客戶數: ", n, " (", percentage, "%)")
)
```

**Categories**:
- 高風險 (High Risk): r_value > ipt × 2
- 中風險 (Mid Risk): r_value > ipt × 1.5
- 低風險 (Low Risk): r_value ≤ ipt × 1.5
- 新客（無法評估）: ni = 1

**Numbers**: Count and percentage for each risk level

### Display 5.3: Days to Churn Histogram

**Code**: `module_customer_status.R:427-470`

```r
# Filter out NA (newbies and ni<4)
churn_data <- processed_data %>%
  filter(!is.na(tag_019_days_to_churn))

# Plot
plot_ly(
  x = churn_data$tag_019_days_to_churn,
  type = "histogram",
  marker = list(color = "#dc3545"),
  nbinsx = 30
) %>%
  layout(
    xaxis = list(title = "預測多少天後"),
    yaxis = list(title = "會流失多少客戶數"),
    title = ""
  )
```

**X-axis**: Days until predicted churn (tag_019_days_to_churn)
**Y-axis**: Count of customers
**Bins**: 30 bins
**Color**: Red (#dc3545) to emphasize urgency

**Formula for tag_019**:
```r
tag_019_days_to_churn = case_when(
  ni == 1 ~ NA_real_,   # Newbies
  ni < 4 ~ NA_real_,    # Insufficient data
  TRUE ~ pmax(0, ipt * 2 - r_value)  # 2×IPT - current R
)
```

**Example**:
- Customer A: ipt=30, r_value=20 → days_to_churn = 30×2 - 20 = 40 days
- Customer B: ipt=30, r_value=70 → days_to_churn = max(0, 60-70) = 0 days (overdue)

### Display 5.4: Customer Age Distribution

**Code**: `module_customer_status.R:472-515`

```r
# Calculate customer age
age_data <- processed_data %>%
  mutate(
    customer_age_days = as.numeric(
      difftime(Sys.Date(), time_first, units = "days")
    )
  )

# Plot
plot_ly(
  x = age_data$customer_age_days,
  type = "histogram",
  marker = list(color = "#17a2b8"),
  nbinsx = 30
) %>%
  layout(
    xaxis = list(title = "客戶入店資歷（天）"),
    yaxis = list(title = "客戶數"),
    title = "客戶年齡分佈"
  )
```

**X-axis**: Customer age in days (time since first purchase)
**Y-axis**: Count of customers
**Bins**: 30 bins

**Formula**: `customer_age_days = today - time_first`

---

## Module 6: RSV Matrix

### Display 6.1: 3D Scatter Plot (R × S × V)

**Code**: `module_rsv_matrix.R:250-350`

```r
plot_ly(
  data = rsv_data,
  x = ~tag_032_dormancy_risk,     # X-axis: Risk
  y = ~tag_033_transaction_stability,  # Y-axis: Stability
  z = ~tag_034_customer_lifetime_value,  # Z-axis: Value
  type = "scatter3d",
  mode = "markers",
  marker = list(
    size = 5,
    color = ~tag_034_customer_lifetime_value,  # Color by CLV
    colorscale = "Viridis",
    showscale = TRUE
  ),
  text = ~paste0(
    "Customer: ", customer_id, "<br>",
    "Risk: ", round(tag_032_dormancy_risk, 2), "<br>",
    "Stability: ", round(tag_033_transaction_stability, 2), "<br>",
    "Value: $", format(round(tag_034_customer_lifetime_value, 0), big.mark = ",")
  )
)
```

**Axes**:
- **X-axis (Risk)**: tag_032_dormancy_risk (0-1 scale, higher = more risk)
- **Y-axis (Stability)**: tag_033_transaction_stability (0-1 scale, higher = more stable)
- **Z-axis (Value)**: tag_034_customer_lifetime_value (dollars, higher = more valuable)

**Point color**: Gradient based on CLV (Viridis colorscale)

**Hover tooltip**: Customer ID + R/S/V values

### Display 6.2: RSV Cell Distribution Table

**Code**: `module_rsv_matrix.R:352-420`

```r
# Classify into 27 cells (3×3×3)
rsv_classified <- rsv_data %>%
  mutate(
    risk_level = case_when(
      tag_032_dormancy_risk >= 0.67 ~ "高風險",
      tag_032_dormancy_risk >= 0.33 ~ "中風險",
      TRUE ~ "低風險"
    ),
    stability_level = case_when(
      tag_033_transaction_stability >= 0.67 ~ "高穩定",
      tag_033_transaction_stability >= 0.33 ~ "中穩定",
      TRUE ~ "低穩定"
    ),
    value_level = case_when(
      tag_034_customer_lifetime_value >= quantile(tag_034_customer_lifetime_value, 0.67) ~ "高價值",
      tag_034_customer_lifetime_value >= quantile(tag_034_customer_lifetime_value, 0.33) ~ "中價值",
      TRUE ~ "低價值"
    ),
    rsv_cell = paste(risk_level, stability_level, value_level, sep = " × ")
  )

# Count
cell_counts <- rsv_classified %>%
  count(rsv_cell) %>%
  arrange(desc(n))

# Display table
datatable(
  cell_counts,
  colnames = c("RSV分類", "客戶數"),
  options = list(pageLength = 27)  # Show all 27 cells
)
```

**27 Cells Format**: "{Risk} × {Stability} × {Value}"

**Examples**:
- "低風險 × 高穩定 × 高價值": 234 customers (ideal segment)
- "高風險 × 低穩定 × 低價值": 89 customers (at-risk segment)

---

## Module 7: Lifecycle Prediction

### Display 7.1: Next Purchase Amount Distribution

**Code**: `module_lifecycle_prediction.R:180-230`

```r
# Data (tag_030 already calculated)
prediction_data <- customer_data %>%
  filter(!is.na(tag_030_next_purchase_amount))

# Plot
plot_ly(
  x = prediction_data$tag_030_next_purchase_amount,
  type = "histogram",
  marker = list(color = "#28a745"),
  nbinsx = 30
) %>%
  layout(
    xaxis = list(title = "預測下次購買金額 (元)"),
    yaxis = list(title = "客戶數")
  )
```

**X-axis**: Predicted next purchase amount (tag_030)
**Y-axis**: Count of customers
**Bins**: 30 bins

**Formula**: `tag_030_next_purchase_amount = m_value` (average transaction value)

### Display 7.2: Expected Revenue ValueBox

**Code**: `module_lifecycle_prediction.R:232-260`

```r
# Calculate total expected revenue
total_expected_revenue = sum(
  prediction_data$tag_030_next_purchase_amount,
  na.rm = TRUE
)

# Display
bs4ValueBox(
  value = paste0("$", format(
    round(total_expected_revenue, 0),
    big.mark = ","
  )),
  subtitle = "預期總收入（所有預測購買）",
  icon = icon("dollar-sign"),
  color = "success"
)
```

**Formula**: `Total Expected Revenue = Σ tag_030_next_purchase_amount`

**Example**: "$12,345,678"

### Display 7.3: Next Purchase Date Timeline

**Code**: `module_lifecycle_prediction.R:262-340`

```r
# Prepare timeline data
timeline_data <- prediction_data %>%
  mutate(
    days_until_purchase = as.numeric(
      difftime(tag_031_next_purchase_date, Sys.Date(), units = "days")
    )
  ) %>%
  arrange(tag_031_next_purchase_date)

# Create timeline plot (Gantt-style)
plot_ly(
  data = timeline_data %>% head(100),  # Show top 100
  x = ~tag_031_next_purchase_date,
  y = ~customer_id,
  type = "scatter",
  mode = "markers",
  marker = list(
    size = 10,
    color = ~tag_030_next_purchase_amount,
    colorscale = "Greens",
    showscale = TRUE,
    colorbar = list(title = "預測金額")
  ),
  text = ~paste0(
    "Customer: ", customer_id, "<br>",
    "預測日期: ", tag_031_next_purchase_date, "<br>",
    "預測金額: $", format(round(tag_030_next_purchase_amount, 0), big.mark = ","), "<br>",
    "剩餘天數: ", round(days_until_purchase, 0), " 天"
  )
) %>%
  layout(
    xaxis = list(title = "預測購買日期"),
    yaxis = list(title = "客戶ID", showticklabels = FALSE)
  )
```

**X-axis**: Predicted purchase date (tag_031)
**Y-axis**: Customer ID (each row = one customer)
**Point color**: Predicted amount (gradient)
**Hover info**: Customer ID + date + amount + days remaining

### Display 7.4: Purchase Calendar Heatmap

**Code**: `module_lifecycle_prediction.R:342-410`

```r
# Aggregate by date
daily_predictions <- prediction_data %>%
  group_by(tag_031_next_purchase_date) %>%
  summarise(
    customer_count = n(),
    total_amount = sum(tag_030_next_purchase_amount, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    date_label = format(tag_031_next_purchase_date, "%Y-%m-%d")
  )

# Create calendar heatmap
plot_ly(
  data = daily_predictions,
  x = ~tag_031_next_purchase_date,
  y = ~customer_count,
  type = "bar",
  marker = list(
    color = ~total_amount,
    colorscale = "Blues",
    showscale = TRUE,
    colorbar = list(title = "預期收入")
  ),
  text = ~paste0(
    "日期: ", date_label, "<br>",
    "預測購買人數: ", customer_count, "<br>",
    "預期總收入: $", format(round(total_amount, 0), big.mark = ",")
  )
) %>%
  layout(
    xaxis = list(title = "日期"),
    yaxis = list(title = "預測購買客戶數")
  )
```

**X-axis**: Date (calendar dates)
**Y-axis**: Count of customers predicted to purchase on that date
**Bar color**: Total expected revenue for that date (gradient)
**Hover info**: Date + customer count + total expected revenue

---

## Summary: Total Numbers Displayed

### By Module

| Module | UI Elements | Numbers/Metrics |
|--------|-------------|-----------------|
| DNA Analysis | Z-score metadata, Dynamics selector, 9-grid (9 cells × 5 lifecycles) | 3 + 5 + 135 = **143 numbers** |
| Base Value | 3 tables, 3 charts, 3 ValueBoxes | **~50 numbers** |
| RFM Analysis | Quality warnings, 3 histograms, pie chart, heatmap, table | **~80 numbers** |
| Customer Activity | 2 histograms, pie chart, cross-tab matrix | **~40 numbers** |
| Customer Status | 3 charts, 1 table | **~30 numbers** |
| RSV Matrix | 3D plot, 27-cell table | **~30 numbers** |
| Lifecycle Prediction | 3 charts, 1 ValueBox, calendar | **~25 numbers** |
| Advanced Analytics | Cohort analysis | **~20 numbers** |

**Total Unique Numbers Displayed**: **~418 numbers across all modules**

---

**End of Part 5**
