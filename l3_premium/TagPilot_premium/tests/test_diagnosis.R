################################################################################
# Quick Diagnosis Script
# Purpose: 診斷預測金額和 RSV 矩陣問題
# Date: 2025-11-11
################################################################################

library(dplyr)
library(readr)
library(lubridate)

setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

source("utils/calculate_customer_tags.R")
source("utils/analyze_customer_dynamics_new.R")

cat("=== Quick Diagnosis ===\n\n")

# ==============================================================================
# Load KM_eg Data
# ==============================================================================

cat("Loading KM_eg data...\n")
test_data_path <- "test_data/KM_eg"
csv_files <- list.files(test_data_path, pattern = "\\.csv$", full.names = TRUE)

all_data <- lapply(csv_files, function(file) {
  read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
}) %>% bind_rows()

cat(sprintf("Loaded %s rows\n\n", format(nrow(all_data), big.mark = ",")))

# ==============================================================================
# Prepare Transaction Data
# ==============================================================================

cat("Preparing transaction data...\n")

customer_transactions <- all_data %>%
  filter(!is.na(`Buyer Email`), !is.na(`Purchase Date`), !is.na(`Item Price`)) %>%
  mutate(
    customer_id = `Buyer Email`,
    # Parse ISO 8601 date format
    transaction_date = as.Date(ymd_hms(`Purchase Date`)),
    transaction_amount = as.numeric(`Item Price`)  # Use transaction_amount, not amount
  ) %>%
  filter(!is.na(transaction_date), !is.na(transaction_amount), transaction_amount > 0) %>%
  select(customer_id, transaction_date, transaction_amount) %>%
  arrange(customer_id, transaction_date)

cat(sprintf("Transactions: %s\n", format(nrow(customer_transactions), big.mark = ",")))
cat(sprintf("Unique customers: %s\n\n", format(n_distinct(customer_transactions$customer_id), big.mark = ",")))

# ==============================================================================
# Run DNA Analysis
# ==============================================================================

cat("Running DNA analysis...\n")
analysis_date <- max(customer_transactions$transaction_date)
cat(sprintf("Analysis date: %s\n\n", analysis_date))

# Use the actual function signature - it only takes transaction_data
dna_analysis_result <- analyze_customer_dynamics_new(
  transaction_data = customer_transactions
)

# Extract customer data from the list result
dna_result <- dna_analysis_result$customer_data

cat(sprintf("DNA result: %s customers\n\n", format(nrow(dna_result), big.mark = ",")))

# ==============================================================================
# Calculate Tags
# ==============================================================================

cat("Calculating tags...\n")
customer_data_with_tags <- dna_result %>%
  calculate_all_customer_tags()

cat(sprintf("Tags calculated: %s customers\n\n", format(nrow(customer_data_with_tags), big.mark = ",")))

# ==============================================================================
# DIAGNOSIS 1: Prediction Amount
# ==============================================================================

cat("=== DIAGNOSIS 1: Prediction Amount ===\n\n")

prediction_check <- customer_data_with_tags %>%
  summarise(
    total = n(),
    has_prediction = sum(!is.na(tag_030_next_purchase_amount)),
    prediction_pct = round(has_prediction / total * 100, 1),
    ni_1 = sum(ni == 1),
    ni_2_plus = sum(ni >= 2),
    avg_aov = mean(tag_030_next_purchase_amount, na.rm = TRUE),
    avg_m_value = mean(m_value, na.rm = TRUE),
    avg_ni = mean(ni, na.rm = TRUE)
  )

print(prediction_check)

cat("\nSample customers with/without prediction:\n")
sample_data <- customer_data_with_tags %>%
  select(customer_id, ni, m_value, tag_030_next_purchase_amount) %>%
  arrange(desc(ni)) %>%
  head(10)
print(sample_data)

cat("\nCustomers WITHOUT prediction:\n")
no_prediction <- customer_data_with_tags %>%
  filter(is.na(tag_030_next_purchase_amount)) %>%
  select(customer_id, ni, m_value, tag_030_next_purchase_amount) %>%
  head(5)
print(no_prediction)

# ==============================================================================
# DIAGNOSIS 2: RSV Matrix
# ==============================================================================

cat("\n=== DIAGNOSIS 2: RSV Matrix Distribution ===\n\n")

# Check CLV calculation
clv_check <- customer_data_with_tags %>%
  mutate(
    clv = m_value,  # Should be m_value, not m_value * ni
    clv_wrong = m_value * ni  # What was wrong before
  ) %>%
  summarise(
    avg_m_value = mean(m_value, na.rm = TRUE),
    avg_ni = mean(ni, na.rm = TRUE),
    avg_clv_correct = mean(clv, na.rm = TRUE),
    avg_clv_wrong = mean(clv_wrong, na.rm = TRUE),
    ratio = avg_clv_wrong / avg_clv_correct
  )

cat("CLV Calculation Check:\n")
print(clv_check)

# Check R/S/V distribution
cat("\nTransaction count distribution:\n")
ni_dist <- customer_data_with_tags %>%
  count(ni) %>%
  arrange(desc(n)) %>%
  head(10)
print(ni_dist)

cat("\nChecking CV availability:\n")
cv_check <- customer_data_with_tags %>%
  summarise(
    total = n(),
    ni_gt_1 = sum(ni > 1),
    has_cv = sum(!is.na(tag_014_cv)),
    pct_has_cv = round(has_cv / total * 100, 1)
  )
print(cv_check)

# Sample S×R calculation (only for customers with ni > 1)
rsv_sample <- customer_data_with_tags %>%
  filter(ni > 1, !is.na(tag_014_cv)) %>%
  mutate(clv = m_value) %>%
  {
    df <- .

    if (nrow(df) == 0) {
      cat("\n⚠️ 無法計算 RSV 分布：沒有客戶有多筆交易\n")
      return(data.frame())
    }

    # R (Dormancy Risk)
    r_p20 <- quantile(df$r_value, 0.2, na.rm = TRUE)
    r_p80 <- quantile(df$r_value, 0.8, na.rm = TRUE)

    # S (Transaction Stability) - using CV
    s_p20 <- quantile(df$tag_014_cv, 0.2, na.rm = TRUE)
    s_p80 <- quantile(df$tag_014_cv, 0.8, na.rm = TRUE)

    # V (Value)
    v_p20 <- quantile(df$clv, 0.2, na.rm = TRUE)
    v_p80 <- quantile(df$clv, 0.8, na.rm = TRUE)

    cat(sprintf("\nQuantile Thresholds (for ni > 1 customers only, n=%d):\n", nrow(df)))
    cat(sprintf("  R (Dormancy): P20=%.1f, P80=%.1f\n", r_p20, r_p80))
    cat(sprintf("  S (Stability CV): P20=%.3f, P80=%.3f\n", s_p20, s_p80))
    cat(sprintf("  V (CLV): P20=%.1f, P80=%.1f\n", v_p20, v_p80))

    df %>%
      mutate(
        r_level = case_when(
          r_value <= r_p20 ~ "低",
          r_value <= r_p80 ~ "中",
          TRUE ~ "高"
        ),
        s_level = case_when(
          tag_014_cv <= s_p20 ~ "高",  # Low CV = High stability
          tag_014_cv <= s_p80 ~ "中",
          TRUE ~ "低"
        ),
        v_level = case_when(
          clv <= v_p20 ~ "低",
          clv <= v_p80 ~ "中",
          TRUE ~ "高"
        )
      ) %>%
      count(s_level, r_level, name = "count") %>%
      arrange(desc(count))
  }

if (nrow(rsv_sample) > 0) {
  cat("\nS×R Distribution (ni > 1 only):\n")
  print(rsv_sample)
}

cat("\n=== Diagnosis Complete ===\n")
