################################################################################
# Test Script: KM_eg Data Validation
# Purpose: 驗證需求 #12 (AOV邏輯) 和 #14 (預測圖表資料)
# Date: 2025-11-10
################################################################################

library(dplyr)
library(readr)
library(lubridate)

# Set working directory to project root
setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

# Source required utilities
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/calculate_customer_tags.R")
source("utils/analyze_customer_dynamics_new.R")

cat("=== TagPilot Premium - KM_eg Data Validation Test ===\n\n")

# ==============================================================================
# Step 1: Load and Combine KM_eg Data
# ==============================================================================

cat("Step 1: Loading KM_eg test data...\n")

test_data_path <- "test_data/KM_eg"
csv_files <- list.files(test_data_path, pattern = "\\.csv$", full.names = TRUE)

cat(sprintf("Found %d CSV files:\n", length(csv_files)))
for (f in csv_files) {
  cat(sprintf("  - %s\n", basename(f)))
}

# Load and combine all CSV files (force all columns to character first)
all_data <- lapply(csv_files, function(file) {
  tryCatch({
    read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
  }, error = function(e) {
    cat(sprintf("Error reading %s: %s\n", basename(file), e$message))
    return(NULL)
  })
}) %>%
  bind_rows()

cat(sprintf("\nTotal rows loaded: %s\n", format(nrow(all_data), big.mark = ",")))
cat(sprintf("Total columns: %d\n\n", ncol(all_data)))

# ==============================================================================
# Step 2: Prepare Data for DNA Analysis
# ==============================================================================

cat("Step 2: Preparing data for DNA analysis...\n")

# Check required columns
required_cols <- c("Buyer Email", "Purchase Date", "Item Price")
missing_cols <- setdiff(required_cols, names(all_data))

if (length(missing_cols) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
}

# Prepare customer transaction data
customer_transactions <- all_data %>%
  filter(!is.na(`Buyer Email`), !is.na(`Purchase Date`), !is.na(`Item Price`)) %>%
  mutate(
    customer_id = `Buyer Email`,
    transaction_date = as.Date(parse_date_time(`Purchase Date`, orders = c("ymd HMS", "mdy HMS"))),
    amount = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(transaction_date), !is.na(amount), amount > 0) %>%
  select(customer_id, transaction_date, amount) %>%
  arrange(customer_id, transaction_date)

cat(sprintf("Prepared transactions: %s\n", format(nrow(customer_transactions), big.mark = ",")))
cat(sprintf("Unique customers: %s\n\n", format(n_distinct(customer_transactions$customer_id), big.mark = ",")))

# ==============================================================================
# Step 3: Run DNA Analysis
# ==============================================================================

cat("Step 3: Running DNA analysis...\n")

# Set analysis date to end of data period
analysis_date <- max(customer_transactions$transaction_date)
cat(sprintf("Analysis date: %s\n\n", analysis_date))

# Run DNA analysis
dna_result <- analyze_customer_dynamics_custom(
  customer_data = customer_transactions,
  customer_id_col = "customer_id",
  trans_date_col = "transaction_date",
  amount_col = "amount",
  analysis_date = analysis_date
)

cat(sprintf("DNA analysis complete. Customers analyzed: %s\n\n",
            format(nrow(dna_result), big.mark = ",")))

# ==============================================================================
# Step 4: Calculate Customer Tags
# ==============================================================================

cat("Step 4: Calculating customer tags...\n")

customer_data_with_tags <- dna_result %>%
  calculate_all_customer_tags()

cat(sprintf("Tags calculated for %s customers\n\n",
            format(nrow(customer_data_with_tags), big.mark = ",")))

# ==============================================================================
# Step 5: TEST 需求 #12 - AOV Logic Analysis
# ==============================================================================

cat("=== TEST: 需求 #12 - AOV 邏輯異常調查 ===\n\n")

# Analyze AOV by customer dynamics
aov_by_dynamics <- customer_data_with_tags %>%
  group_by(tag_017_customer_dynamics) %>%
  summarise(
    customer_count = n(),
    avg_aov = mean(tag_004_avg_order_value, na.rm = TRUE),
    median_aov = median(tag_004_avg_order_value, na.rm = TRUE),
    min_aov = min(tag_004_avg_order_value, na.rm = TRUE),
    max_aov = max(tag_004_avg_order_value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_aov))

cat("AOV by Customer Dynamics:\n")
print(aov_by_dynamics)
cat("\n")

# Check if 主力客 AOV is lower than 新客
newbie_aov <- aov_by_dynamics %>% filter(tag_017_customer_dynamics == "新客") %>% pull(avg_aov)
active_aov <- aov_by_dynamics %>% filter(tag_017_customer_dynamics == "主力客") %>% pull(avg_aov)

if (length(newbie_aov) > 0 && length(active_aov) > 0) {
  cat(sprintf("新客 平均AOV: $%.2f\n", newbie_aov))
  cat(sprintf("主力客 平均AOV: $%.2f\n", active_aov))

  if (active_aov < newbie_aov) {
    cat("\n⚠️ 異常：主力客 AOV ($%.2f) < 新客 AOV ($%.2f)\n", active_aov, newbie_aov)
    cat("   差異: $%.2f (%.1f%%)\n", newbie_aov - active_aov,
        ((newbie_aov - active_aov) / newbie_aov * 100))
  } else {
    cat("\n✅ 正常：主力客 AOV ($%.2f) >= 新客 AOV ($%.2f)\n", active_aov, newbie_aov)
  }
} else {
  cat("\n⚠️ 警告：無法比較（缺少新客或主力客資料）\n")
}

cat("\n")

# ==============================================================================
# Step 6: TEST 需求 #14 - Prediction Chart Data Analysis
# ==============================================================================

cat("=== TEST: 需求 #14 - 預測購買金額圖表資料缺失 ===\n\n")

# Check prediction data availability
prediction_summary <- customer_data_with_tags %>%
  summarise(
    total_customers = n(),
    has_prediction_amount = sum(!is.na(tag_030_next_purchase_amount)),
    has_prediction_date = sum(!is.na(tag_031_next_purchase_date)),
    pct_with_prediction = round(sum(!is.na(tag_030_next_purchase_amount)) / n() * 100, 1)
  )

cat("Prediction Data Summary:\n")
cat(sprintf("  Total customers: %s\n", format(prediction_summary$total_customers, big.mark = ",")))
cat(sprintf("  With prediction amount: %s (%.1f%%)\n",
            format(prediction_summary$has_prediction_amount, big.mark = ","),
            prediction_summary$pct_with_prediction))
cat(sprintf("  With prediction date: %s\n\n",
            format(prediction_summary$has_prediction_date, big.mark = ",")))

if (prediction_summary$pct_with_prediction < 90) {
  cat(sprintf("⚠️ 警告：僅 %.1f%% 客戶有預測資料（預期應接近 100%%）\n",
              prediction_summary$pct_with_prediction))

  # Analyze why prediction is missing
  missing_prediction <- customer_data_with_tags %>%
    filter(is.na(tag_030_next_purchase_amount)) %>%
    group_by(tag_017_customer_dynamics) %>%
    summarise(count = n(), .groups = "drop")

  cat("\n缺少預測資料的客戶分布：\n")
  print(missing_prediction)
} else {
  cat(sprintf("✅ 正常：%.1f%% 客戶有預測資料\n", prediction_summary$pct_with_prediction))
}

cat("\n")

# ==============================================================================
# Step 7: Summary Report
# ==============================================================================

cat("=== Validation Test Summary ===\n\n")

cat("✅ 測試完成\n\n")

cat("需求 #12 (AOV邏輯):\n")
if (length(newbie_aov) > 0 && length(active_aov) > 0) {
  if (active_aov < newbie_aov) {
    cat("  ⚠️ 發現異常：主力客 AOV 低於新客 AOV\n")
    cat("     建議：檢查資料來源或業務模型\n")
  } else {
    cat("  ✅ 正常：AOV 符合預期（主力客 >= 新客）\n")
  }
} else {
  cat("  ⚠️ 無法驗證（資料不足）\n")
}

cat("\n需求 #14 (預測圖表):\n")
if (prediction_summary$pct_with_prediction < 90) {
  cat(sprintf("  ⚠️ 發現問題：僅 %.1f%% 客戶有預測資料\n", prediction_summary$pct_with_prediction))
  cat("     建議：檢查預測演算法或資料完整性\n")
} else {
  cat(sprintf("  ✅ 正常：%.1f%% 客戶有預測資料\n", prediction_summary$pct_with_prediction))
}

cat("\n=== Test Script Complete ===\n")
