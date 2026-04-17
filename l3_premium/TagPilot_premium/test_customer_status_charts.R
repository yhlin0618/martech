################################################################################
# Customer Status Charts Integration Test
# Purpose: Validate data structure for all charts in module_customer_status
# Ensures charts will display correctly without "null" values
################################################################################

library(tidyverse)
library(plotly)

cat("════════════════════════════════════════════════════════════\n")
cat("  Customer Status Charts Integration Test\n")
cat("════════════════════════════════════════════════════════════\n\n")

# Source required modules
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

# ══════════════════════════════════════════════════════════════════════════
# STEP 1: Load and Prepare Test Data
# ══════════════════════════════════════════════════════════════════════════

cat("📁 STEP 1: Loading test data...\n")

test_data_dir <- "test_data/KM_eg"
files <- list.files(test_data_dir, pattern = "\\.csv$", full.names = TRUE)

all_data <- map_dfr(files, function(file) {
  read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
})

cat("  ✅ Loaded", nrow(all_data), "transactions\n\n")

# Transform to upload format (matching actual app behavior)
# ✅ FIX: Use Buyer Email not Buyer Name (Buyer Name can be empty/NA)
upload_data <- all_data %>%
  transmute(
    customer_id = `Buyer Email`,  # ✅ Buyer Email is unique identifier
    payment_time = lubridate::ymd_hms(`Payments Date`),
    lineitem_price = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(customer_id), !is.na(payment_time), !is.na(lineitem_price), lineitem_price > 0)

# Standardize column names
transaction_data <- upload_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

cat("  ✅ Standardized:", nrow(transaction_data), "transactions\n")
cat("  ✅ Unique customers:", n_distinct(transaction_data$customer_id), "\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 2: Prepare for DNA Analysis
# ══════════════════════════════════════════════════════════════════════════

cat("📊 STEP 2: Preparing data for DNA analysis...\n")

sales_by_customer_by_date <- transaction_data %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    sum_spent_by_date = sum(transaction_amount),
    count_transactions_by_date = n(),
    payment_time = min(transaction_date),
    .groups = "drop"
  )

sales_by_customer <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(transaction_amount, na.rm = TRUE),
    times = n(),
    first_purchase = min(transaction_date),
    last_purchase = max(transaction_date),
    .groups = "drop"
  ) %>%
  mutate(
    ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")), 1),
    r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
    f_value = times,
    m_value = total_spent / times,
    ni = times
  )

cat("  ✅ Prepared", nrow(sales_by_customer), "customers for analysis\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 3: Run DNA Analysis
# ══════════════════════════════════════════════════════════════════════════

cat("🧬 STEP 3: Running DNA analysis...\n")

dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date
)

customer_data <- dna_result$data_by_customer

cat("  ✅ DNA analysis complete for", nrow(customer_data), "customers\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 4: Calculate Customer Dynamics (Z-Score Method)
# ══════════════════════════════════════════════════════════════════════════

cat("📈 STEP 4: Calculating customer dynamics (z-score)...\n")

zscore_results <- analyze_customer_dynamics_new(
  transaction_data = transaction_data,
  method = "z_score",  # ✅ Correct parameter name
  cap_days = 365
)

customer_data <- zscore_results$customer_data

cat("  ✅ Customer dynamics calculated\n")
cat("  ✅ Method:", zscore_results$validation$method_used, "\n")
cat("  ✅ μ_ind:", round(zscore_results$parameters$mu_ind, 1), "days\n")
cat("  ✅ W:", zscore_results$parameters$W, "days\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 5: Calculate All Customer Tags
# ══════════════════════════════════════════════════════════════════════════

cat("🏷️  STEP 5: Calculating all customer tags...\n")

customer_data <- calculate_all_customer_tags(customer_data)

cat("  ✅ Tags calculated for", nrow(customer_data), "customers\n")
cat("  ✅ Total columns:", ncol(customer_data), "\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 6: Validate Tag Structure for Charts
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("VALIDATION: Tag Structure for Customer Status Charts\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Check required tag fields
required_tags <- c(
  "tag_017_customer_dynamics",
  "tag_018_churn_risk",
  "tag_019_days_to_churn"
)

cat("📋 Checking required tag fields...\n")
all_tags_present <- TRUE
for (tag in required_tags) {
  exists <- tag %in% names(customer_data)
  cat("  ", if(exists) "✅" else "❌", tag, ":", exists, "\n")
  if (!exists) all_tags_present <- FALSE
}

if (!all_tags_present) {
  stop("❌ FAILED: Missing required tag fields")
}
cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# TEST 1: Lifecycle Pie Chart Data Validation
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 1: Lifecycle Pie Chart (生命週期階段分布)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Expected Chinese values
expected_lifecycle_values <- c("新客", "主力客", "睡眠客", "半睡客", "沉睡客", "未知")

cat("📊 Validating tag_017_customer_dynamics values...\n")

# Get unique values
actual_values <- unique(customer_data$tag_017_customer_dynamics)
actual_values <- actual_values[!is.na(actual_values)]

cat("  Expected values (Chinese):", paste(expected_lifecycle_values, collapse = ", "), "\n")
cat("  Actual values found:", paste(actual_values, collapse = ", "), "\n\n")

# Check if all actual values are in expected set
unexpected_values <- setdiff(actual_values, expected_lifecycle_values)
missing_values <- setdiff(expected_lifecycle_values, actual_values)

if (length(unexpected_values) > 0) {
  cat("  ⚠️  WARNING: Unexpected values found:", paste(unexpected_values, collapse = ", "), "\n")
}

if (length(missing_values) > 0) {
  cat("  ℹ️  INFO: Expected values not present:", paste(missing_values, collapse = ", "), "\n")
}

# Check for NULL or NA values
null_count <- sum(is.na(customer_data$tag_017_customer_dynamics))
cat("  NULL/NA count:", null_count, "\n")

if (null_count > 0) {
  cat("  ⚠️  WARNING:", null_count, "customers have NULL/NA lifecycle stage\n")
}

# Calculate distribution
lifecycle_counts <- customer_data %>%
  count(tag_017_customer_dynamics) %>%
  arrange(desc(n)) %>%
  mutate(percentage = n / sum(n) * 100)

cat("\n📈 Lifecycle Distribution:\n")
print(lifecycle_counts, n = Inf)

# Test chart mapping (simulate what plotly will do)
cat("\n🎨 Testing color mapping...\n")

color_map <- c(
  "新客" = "#17a2b8",
  "主力客" = "#28a745",
  "睡眠客" = "#ffc107",
  "半睡客" = "#fd7e14",
  "沉睡客" = "#6c757d",
  "未知" = "#e9ecef"
)

lifecycle_counts$color <- color_map[lifecycle_counts$tag_017_customer_dynamics]
lifecycle_counts$label_zh <- lifecycle_counts$tag_017_customer_dynamics  # Already in Chinese

# Check if any colors are NULL
null_colors <- sum(is.na(lifecycle_counts$color))
if (null_colors > 0) {
  cat("  ❌ FAILED:", null_colors, "categories have NULL colors\n")
  cat("  Categories with NULL colors:\n")
  print(lifecycle_counts %>% filter(is.na(color)))
  stop("Color mapping failed - check expected_lifecycle_values")
} else {
  cat("  ✅ All categories mapped to colors successfully\n")
}

# Simulate plotly pie chart
cat("\n📊 Simulating plotly pie chart...\n")
tryCatch({
  pie_chart <- plot_ly(
    data = lifecycle_counts,
    labels = ~label_zh,
    values = ~n,
    type = "pie",
    marker = list(colors = ~color),
    textinfo = "label+percent+value"
  )
  cat("  ✅ Pie chart created successfully\n")
  cat("  ✅ Chart will display", nrow(lifecycle_counts), "segments\n")
}, error = function(e) {
  cat("  ❌ FAILED to create pie chart:", e$message, "\n")
})

cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# TEST 2: Churn Risk Bar Chart Data Validation
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 2: Churn Risk Bar Chart (流失風險分布)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Expected Chinese values for churn risk
expected_risk_values <- c("低風險", "中風險", "高風險", "新客（無法評估）")

cat("📊 Validating tag_018_churn_risk values...\n")

# Get unique values
actual_risk_values <- unique(customer_data$tag_018_churn_risk)
actual_risk_values <- actual_risk_values[!is.na(actual_risk_values)]

cat("  Expected values:", paste(expected_risk_values, collapse = ", "), "\n")
cat("  Actual values found:", paste(actual_risk_values, collapse = ", "), "\n\n")

# Calculate distribution
risk_counts <- customer_data %>%
  count(tag_018_churn_risk) %>%
  mutate(percentage = n / sum(n) * 100)

cat("📈 Churn Risk Distribution:\n")
print(risk_counts, n = Inf)

# Test color mapping
cat("\n🎨 Testing color mapping...\n")

risk_color_map <- c(
  "低風險" = "#28a745",
  "中風險" = "#ffc107",
  "高風險" = "#dc3545",
  "新客（無法評估）" = "#17a2b8"
)

risk_counts$color <- risk_color_map[risk_counts$tag_018_churn_risk]

null_colors <- sum(is.na(risk_counts$color))
if (null_colors > 0) {
  cat("  ❌ FAILED:", null_colors, "categories have NULL colors\n")
} else {
  cat("  ✅ All risk categories mapped to colors successfully\n")
}

cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# TEST 3: Lifecycle × Churn Risk Heatmap Data Validation
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 3: Lifecycle × Churn Risk Heatmap (生命週期 × 流失風險矩陣)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("📊 Creating cross-tabulation matrix...\n")

# Calculate cross-tabulation
heatmap_data <- customer_data %>%
  count(tag_017_customer_dynamics, tag_018_churn_risk) %>%
  tidyr::pivot_wider(
    names_from = tag_018_churn_risk,
    values_from = n,
    values_fill = 0
  )

cat("  ✅ Matrix created with", nrow(heatmap_data), "lifecycle stages\n")
cat("  ✅ Columns:", paste(names(heatmap_data), collapse = ", "), "\n\n")

# Ensure all risk columns exist
risk_levels <- c("低風險", "中風險", "高風險", "新客（無法評估）")
for (risk in risk_levels) {
  if (!risk %in% names(heatmap_data)) {
    heatmap_data[[risk]] <- 0
  }
}

# Order by lifecycle stages (Chinese order)
lifecycle_order <- c("新客", "主力客", "睡眠客", "半睡客", "沉睡客", "未知")

# Filter to only include expected lifecycle stages
heatmap_data <- heatmap_data %>%
  filter(tag_017_customer_dynamics %in% lifecycle_order) %>%
  arrange(match(tag_017_customer_dynamics, lifecycle_order))

cat("📈 Heatmap Matrix:\n")
print(heatmap_data, n = Inf)

# Test label mapping
cat("\n🎨 Testing lifecycle label mapping...\n")

label_map <- c(
  "新客" = "新客",
  "主力客" = "主力客",
  "睡眠客" = "睡眠客",
  "半睡客" = "半睡客",
  "沉睡客" = "沉睡客",
  "未知" = "未知"
)

heatmap_data$lifecycle_zh <- label_map[heatmap_data$tag_017_customer_dynamics]

null_labels <- sum(is.na(heatmap_data$lifecycle_zh))
if (null_labels > 0) {
  cat("  ❌ FAILED:", null_labels, "lifecycle stages have NULL labels\n")
} else {
  cat("  ✅ All lifecycle stages mapped to labels successfully\n")
}

# Check if matrix has data
total_customers_in_matrix <- sum(select(heatmap_data, any_of(risk_levels)))
cat("\n  Total customers in matrix:", total_customers_in_matrix, "\n")

if (total_customers_in_matrix == 0) {
  cat("  ❌ WARNING: Heatmap matrix is empty (no customers)\n")
} else {
  cat("  ✅ Heatmap matrix has data\n")
}

# Simulate plotly heatmap
cat("\n📊 Simulating plotly heatmap...\n")
tryCatch({
  # Select only risk level columns for z matrix
  z_matrix <- as.matrix(select(heatmap_data, any_of(c("低風險", "中風險", "高風險", "新客（無法評估）"))))

  heatmap_chart <- plot_ly(
    x = colnames(z_matrix),
    y = ~heatmap_data$lifecycle_zh,
    z = z_matrix,
    type = "heatmap",
    colorscale = list(
      c(0, "rgb(255, 255, 255)"),
      c(0.5, "rgb(255, 193, 7)"),
      c(1, "rgb(220, 53, 69)")
    )
  )
  cat("  ✅ Heatmap created successfully\n")
  cat("  ✅ Matrix dimensions:", nrow(z_matrix), "×", ncol(z_matrix), "\n")
}, error = function(e) {
  cat("  ❌ FAILED to create heatmap:", e$message, "\n")
})

cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# TEST 4: Key Metrics Validation
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 4: Key Metrics (關鍵指標)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Calculate key metrics (what appears in value boxes)
high_risk_count <- sum(customer_data$tag_018_churn_risk == "高風險", na.rm = TRUE)
active_count <- sum(customer_data$tag_017_customer_dynamics == "主力客", na.rm = TRUE)
dormant_count <- sum(customer_data$tag_017_customer_dynamics == "沉睡客", na.rm = TRUE)
avg_days_to_churn <- mean(customer_data$tag_019_days_to_churn, na.rm = TRUE)

cat("📊 Key Metrics Calculated:\n")
cat("  高風險客戶 (High Risk):", format(high_risk_count, big.mark = ","), "\n")
cat("  主力客戶 (Active):", format(active_count, big.mark = ","), "\n")
cat("  沉睡客戶 (Dormant):", format(dormant_count, big.mark = ","), "\n")
cat("  平均流失天數 (Avg Days to Churn):", format(round(avg_days_to_churn, 1), big.mark = ","), "\n")

cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# TEST 5: Customer Table Data Validation
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 5: Customer Table (客戶明細表)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("📋 Testing label mapping for table display...\n")

# Simulate table preparation
table_label_map <- c(
  "新客" = "新客",
  "主力客" = "主力客",
  "睡眠客" = "睡眠客",
  "半睡客" = "半睡客",
  "沉睡客" = "沉睡客",
  "未知" = "未知"
)

# Test mapping
test_display_data <- customer_data %>%
  mutate(
    lifecycle_display = table_label_map[tag_017_customer_dynamics]
  ) %>%
  select(customer_id, tag_017_customer_dynamics, lifecycle_display, tag_018_churn_risk, tag_019_days_to_churn) %>%
  head(10)

null_display_labels <- sum(is.na(test_display_data$lifecycle_display))
if (null_display_labels > 0) {
  cat("  ❌ FAILED:", null_display_labels, "rows have NULL display labels\n")
} else {
  cat("  ✅ All rows have valid display labels\n")
}

cat("\n📊 Sample Table Data (first 10 rows):\n")
print(test_display_data, n = 10)

cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════════════════════════

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("TEST SUMMARY\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

test_results <- list(
  total_customers = nrow(customer_data),
  tag_017_present = "tag_017_customer_dynamics" %in% names(customer_data),
  tag_018_present = "tag_018_churn_risk" %in% names(customer_data),
  tag_019_present = "tag_019_days_to_churn" %in% names(customer_data),
  lifecycle_values_valid = all(actual_values %in% expected_lifecycle_values),
  lifecycle_no_nulls = null_count == 0,
  pie_chart_colors_ok = null_colors == 0,
  heatmap_has_data = total_customers_in_matrix > 0,
  table_labels_ok = null_display_labels == 0
)

cat("✅ Total Customers Analyzed:", test_results$total_customers, "\n")
cat("✅ tag_017_customer_dynamics present:", test_results$tag_017_present, "\n")
cat("✅ tag_018_churn_risk present:", test_results$tag_018_present, "\n")
cat("✅ tag_019_days_to_churn present:", test_results$tag_019_present, "\n")
cat("✅ Lifecycle values are valid Chinese:", test_results$lifecycle_values_valid, "\n")
cat("✅ No NULL lifecycle values:", test_results$lifecycle_no_nulls, "\n")
cat("✅ Pie chart color mapping works:", test_results$pie_chart_colors_ok, "\n")
cat("✅ Heatmap has data:", test_results$heatmap_has_data, "\n")
cat("✅ Table label mapping works:", test_results$table_labels_ok, "\n")

# Overall pass/fail
all_tests_passed <- all(unlist(test_results))

cat("\n")
if (all_tests_passed) {
  cat("🎉 ALL TESTS PASSED - Charts should display correctly!\n")
} else {
  cat("❌ SOME TESTS FAILED - Charts may show 'null' or errors\n")
  cat("\nFailed tests:\n")
  failed <- names(test_results)[!unlist(test_results)]
  for (test_name in failed) {
    cat("  ❌", test_name, "\n")
  }
}

cat("\n════════════════════════════════════════════════════════════\n")
cat("  Customer Status Charts Test Complete\n")
cat("════════════════════════════════════════════════════════════\n")
