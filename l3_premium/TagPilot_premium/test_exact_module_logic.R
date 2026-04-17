# Test Exact Module Logic with Real Data
# Purpose: Use realistic_customer_data.csv to test exact module flow

library(dplyr)
library(tibble)

cat("=== Testing Exact Module Logic with Real Data ===\n\n")

# Load real data
cat("Loading realistic_customer_data.csv...\n")
transaction_data <- read.csv("test_data/realistic_customer_data.csv", stringsAsFactors = FALSE)
transaction_data$transaction_date <- as.Date(transaction_data$transaction_date)

cat("✓ Loaded", nrow(transaction_data), "transactions\n")
cat("  Date range:", min(transaction_data$transaction_date), "to", max(transaction_data$transaction_date), "\n")
cat("  Unique customers:", length(unique(transaction_data$customer_id)), "\n\n")

# Source required functions
cat("Sourcing required functions...\n")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")
cat("✓ Functions sourced\n\n")

# EXACT MODULE LOGIC STARTS HERE
cat("========================================\n")
cat("EXACT MODULE LOGIC (lines 254-432)\n")
cat("========================================\n\n")

# Prepare df_sales_by_customer_by_date (lines 254-263)
cat("[Line 254-263] Preparing sales_by_customer_by_date...\n")
sales_by_customer_by_date <- transaction_data %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    payment_time = min(transaction_date),
    sum_spent_by_date = sum(transaction_amount, na.rm = TRUE),
    count_transactions_by_date = n(),
    .groups = "drop"
  )
cat("✓ Rows:", nrow(sales_by_customer_by_date), "\n\n")

# Prepare df_sales_by_customer (lines 265-278)
cat("[Line 265-278] Preparing sales_by_customer...\n")
sales_by_customer <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(transaction_amount, na.rm = TRUE),
    times = n(),
    ni = n(),
    first_purchase = min(transaction_date),
    last_purchase = max(transaction_date),
    .groups = "drop"
  ) %>%
  mutate(
    ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")), 1)
  )
cat("✓ Rows:", nrow(sales_by_customer), "\n\n")

# Call analysis_dna() (lines 281-288)
cat("[Line 281-288] Calling analysis_dna() with skip_within_subject = TRUE...\n")
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = FALSE
)
cat("✓ analysis_dna() completed\n\n")

customer_data <- dna_result$data_by_customer %>%
  as_tibble()
cat("[Line 290-293] Converted to tibble, rows:", nrow(customer_data), "\n")
cat("  Columns:", paste(head(names(customer_data), 10), collapse=", "), "...\n\n")

# Call analyze_customer_dynamics_new() (lines 296-314)
cat("[Line 296-314] Calling analyze_customer_dynamics_new()...\n")
zscore_results <- analyze_customer_dynamics_new(
  transaction_data,
  method = "auto",
  k = 2.5,
  min_window = 90,
  use_recency_guardrail = TRUE
)
cat("✓ analyze_customer_dynamics_new() completed\n")
cat("  Method used:", zscore_results$validation$method_used, "\n\n")

customer_data <- customer_data %>%
  left_join(
    zscore_results$customer_data %>% select(customer_id, customer_dynamics),
    by = "customer_id"
  )
cat("  Merge completed, rows:", nrow(customer_data), "\n\n")

# Rename cai_value to cai (lines 342-348)
cat("[Line 342-348] Renaming cai_value to cai...\n")
cat("  Columns before:", paste(head(names(customer_data), 15), collapse=", "), "...\n")
if ("cai_value" %in% names(customer_data) && !"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    rename(cai = cai_value)
  cat("✓ Renamed cai_value to cai\n\n")
} else {
  cat("⚠️  cai_value not found or cai already exists\n\n")
}

# Ensure correct types (lines 351-363)
cat("[Line 351-363] Converting data types...\n")
cat("  m_value class before:", class(customer_data$m_value), "\n")
cat("  m_value sample:", paste(head(customer_data$m_value, 3), collapse=", "), "\n")

customer_data <- customer_data %>%
  mutate(
    m_value = as.numeric(m_value),
    r_value = as.numeric(r_value),
    f_value = as.numeric(f_value),
    cai = as.numeric(cai),
    cai_ecdf = as.numeric(cai_ecdf),
    ni = as.integer(ni)
  )

cat("  m_value class after:", class(customer_data$m_value), "\n")
cat("  m_value sample after:", paste(head(customer_data$m_value, 3), collapse=", "), "\n")
cat("  m_value has NA:", sum(is.na(customer_data$m_value)), "\n\n")

# Calculate quantiles (lines 370-377)
cat("[Line 370-377] Calculating quantiles...\n")
cat("  Attempting m_q80...\n")
m_q80 <- quantile(customer_data$m_value, 0.8, na.rm = TRUE)
cat("  m_q80 =", m_q80, "\n")

cat("  Attempting m_q20...\n")
m_q20 <- quantile(customer_data$m_value, 0.2, na.rm = TRUE)
cat("  m_q20 =", m_q20, "\n\n")

# Calculate value_level (lines 380-389)
cat("[Line 380-389] Calculating value_level...\n")
customer_data <- customer_data %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= m_q80 ~ "高",
      m_value >= m_q20 ~ "中",
      TRUE ~ "低"
    )
  )
cat("✓ value_level calculated\n\n")

# Split by ni >= 4 (lines 393-397)
cat("[Line 393-397] Splitting by ni >= 4...\n")
customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)
cat("  ni >= 4:", nrow(customers_sufficient), "\n")
cat("  ni < 4:", nrow(customers_insufficient), "\n\n")

# Calculate activity_level for ni >= 4 (lines 400-417)
if (nrow(customers_sufficient) > 0) {
  cat("[Line 400-417] Calculating activity_level for ni >= 4...\n")
  cat("  cai_ecdf class:", class(customers_sufficient$cai_ecdf), "\n")
  cat("  cai_ecdf sample:", paste(head(customers_sufficient$cai_ecdf, 3), collapse=", "), "\n")

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
  cat("✓ activity_level calculated for ni >= 4\n\n")
}

# Set activity_level NA for ni < 4 (lines 420-426)
if (nrow(customers_insufficient) > 0) {
  cat("[Line 420-426] Setting activity_level to NA for ni < 4...\n")
  customers_insufficient <- customers_insufficient %>%
    mutate(activity_level = NA_character_)
  cat("✓ activity_level set to NA\n\n")
}

# Combine (line 429)
cat("[Line 429] Combining customers...\n")
customer_data <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)
cat("✓ Combined rows:", nrow(customer_data), "\n\n")

# Calculate grid_position
cat("Calculating grid_position...\n")
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
cat("✓ grid_position calculated\n\n")

# Calculate tags
cat("Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Tags calculated\n\n")

cat("========================================\n")
cat("VALIDATION RESULTS\n")
cat("========================================\n\n")

cat("Customer Dynamics Distribution:\n")
print(table(customer_data$customer_dynamics))
cat("\nValue Level Distribution:\n")
print(table(customer_data$value_level))
cat("\nActivity Level Distribution (ni >= 4):\n")
print(table(customer_data$activity_level, useNA = "ifany"))
cat("\nGrid Position Distribution:\n")
print(table(customer_data$grid_position))

cat("\n\n")
cat("Summary Statistics:\n")
cat("  Total customers:", nrow(customer_data), "\n")
cat("  ni >= 4:", sum(customer_data$ni >= 4), "\n")
cat("  ni < 4:", sum(customer_data$ni < 4), "\n")
cat("  With activity level:", sum(!is.na(customer_data$activity_level)), "\n")
cat("  Without activity level:", sum(is.na(customer_data$activity_level)), "\n\n")

cat("✅✅✅ EXACT MODULE LOGIC TEST PASSED ✅✅✅\n")
cat("All steps executed successfully with real data.\n")
