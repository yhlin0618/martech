# Test with KM_eg Real Data
# Purpose: Test complete flow with actual KM Amazon data

library(dplyr)
library(tibble)

cat("=== Testing with KM_eg Real Data ===\n\n")

# Load all CSV files from KM_eg directory
data_dir <- "test_data/KM_eg"
csv_files <- list.files(data_dir, pattern = "\\.csv$", full.names = TRUE)

cat("Found", length(csv_files), "CSV files:\n")
for (f in csv_files) {
  cat("  -", basename(f), "\n")
}
cat("\n")

# Read and combine all files
all_data <- list()
for (i in seq_along(csv_files)) {
  cat("Reading file", i, "of", length(csv_files), "...\n")
  dat <- read.csv(csv_files[i], stringsAsFactors = FALSE, check.names = FALSE)
  all_data[[i]] <- dat
}

# Merge all data
cat("\nCombining all files...\n")
all_columns <- unique(unlist(lapply(all_data, names)))
for (i in seq_along(all_data)) {
  missing_cols <- setdiff(all_columns, names(all_data[[i]]))
  for (col in missing_cols) {
    all_data[[i]][[col]] <- NA
  }
  all_data[[i]] <- all_data[[i]][all_columns]
}

combined_data <- do.call(rbind, all_data)
cat("✓ Combined", nrow(combined_data), "rows\n")
cat("  Columns:", paste(head(names(combined_data), 5), collapse=", "), "...\n\n")

# Standardize column names (like upload module does)
cat("Standardizing column names...\n")
names(combined_data)[names(combined_data) == "Buyer Email"] <- "customer_id"
names(combined_data)[names(combined_data) == "Payments Date"] <- "transaction_date"
names(combined_data)[names(combined_data) == "Item Price"] <- "transaction_amount"

transaction_data <- combined_data %>%
  select(customer_id, transaction_date, transaction_amount) %>%
  filter(!is.na(customer_id), !is.na(transaction_date), !is.na(transaction_amount))

# Parse transaction_date
transaction_data$transaction_date <- as.Date(substr(transaction_data$transaction_date, 1, 10))
transaction_data$transaction_amount <- as.numeric(transaction_data$transaction_amount)

cat("✓ Standardized and cleaned\n")
cat("  Final rows:", nrow(transaction_data), "\n")
cat("  Unique customers:", length(unique(transaction_data$customer_id)), "\n")
cat("  Date range:", min(transaction_data$transaction_date), "to", max(transaction_data$transaction_date), "\n\n")

# Source required functions
cat("Sourcing required functions...\n")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")
cat("✓ Functions sourced\n\n")

cat("========================================\n")
cat("EXACT MODULE LOGIC\n")
cat("========================================\n\n")

# Prepare data for analysis_dna()
cat("[1] Preparing sales_by_customer_by_date...\n")
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

cat("[2] Preparing sales_by_customer...\n")
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

# Call analysis_dna()
cat("[3] Calling analysis_dna() with skip_within_subject = TRUE...\n")
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = FALSE
)
cat("✓ analysis_dna() completed\n\n")

customer_data <- dna_result$data_by_customer %>%
  as_tibble()
cat("  Converted to tibble, rows:", nrow(customer_data), "\n\n")

# Call analyze_customer_dynamics_new()
cat("[4] Calling analyze_customer_dynamics_new()...\n")
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
    zscore_results$customer_data %>% select(customer_id, customer_dynamics, value_level),
    by = "customer_id"
  )

# Rename cai_value to cai
cat("[5] Renaming cai_value to cai...\n")
if ("cai_value" %in% names(customer_data) && !"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    rename(cai = cai_value)
  cat("✓ Renamed\n\n")
}

# Ensure correct types
cat("[6] Converting data types...\n")
customer_data <- customer_data %>%
  mutate(
    m_value = as.numeric(m_value),
    r_value = as.numeric(r_value),
    f_value = as.numeric(f_value),
    cai = as.numeric(cai),
    cai_ecdf = as.numeric(cai_ecdf),
    ni = as.integer(ni)
  )
cat("✓ Types converted\n\n")

# ✅ IMPORTANT: Use value_level from analyze_customer_dynamics_new()
# DON'T recalculate - it already has proper edge case handling
cat("[7] Using value_level from analyze_customer_dynamics_new()...\n")
if ("value_level" %in% names(customer_data)) {
  cat("✓ value_level exists from zscore_results\n")
  cat("  Distribution:\n")
  print(table(customer_data$value_level))
  cat("\n")
} else {
  cat("⚠️  value_level NOT found, recalculating (this shouldn't happen)...\n")
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
  cat("✓ value_level recalculated\n\n")
}

# Calculate activity level
cat("[8] Calculating activity level...\n")
customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)
cat("  ni >= 4:", nrow(customers_sufficient), "\n")
cat("  ni < 4:", nrow(customers_insufficient), "\n")

if (nrow(customers_sufficient) > 0) {
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
}

if (nrow(customers_insufficient) > 0) {
  customers_insufficient <- customers_insufficient %>%
    mutate(activity_level = NA_character_)
}

customer_data <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)
cat("✓ activity_level calculated\n\n")

# Calculate grid_position
cat("[9] Calculating grid_position...\n")
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
cat("[10] Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Tags calculated\n\n")

cat("========================================\n")
cat("VALIDATION RESULTS\n")
cat("========================================\n\n")

cat("Customer Dynamics Distribution:\n")
print(table(customer_data$customer_dynamics))
cat("\nValue Level Distribution:\n")
print(table(customer_data$value_level))
cat("\nActivity Level Distribution:\n")
print(table(customer_data$activity_level, useNA = "ifany"))
cat("\nGrid Position Distribution:\n")
print(table(customer_data$grid_position))

cat("\n\nSummary Statistics:\n")
cat("  Total customers:", nrow(customer_data), "\n")
cat("  ni >= 4:", sum(customer_data$ni >= 4), "\n")
cat("  ni < 4:", sum(customer_data$ni < 4), "\n")
cat("  With activity level:", sum(!is.na(customer_data$activity_level)), "\n")

cat("\n✅✅✅ KM_EG DATA TEST PASSED ✅✅✅\n")
