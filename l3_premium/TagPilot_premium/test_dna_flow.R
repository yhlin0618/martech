# Test DNA Analysis Flow
# Purpose: Verify the complete DNA analysis pipeline works correctly

library(dplyr)
library(tibble)

# Source required functions
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")

cat("=== Step 1: Generate Test Data ===\n")
set.seed(123)

# Create realistic test transaction data
n_customers <- 100
transactions <- data.frame(
  customer_id = sample(paste0('CUST', sprintf("%04d", 1:n_customers)), 500, replace = TRUE),
  transaction_date = Sys.Date() - sample(1:365, 500, replace = TRUE),
  transaction_amount = round(runif(500, 10, 500), 2)
)

cat("Generated", nrow(transactions), "transactions for", n_distinct(transactions$customer_id), "customers\n\n")

cat("=== Step 2: Prepare Data for analysis_dna() ===\n")

# Prepare df_sales_by_customer_by_date
sales_by_customer_by_date <- transactions %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    payment_time = min(transaction_date),
    .groups = "drop"
  )

cat("sales_by_customer_by_date:", nrow(sales_by_customer_by_date), "rows\n")
cat("Columns:", paste(names(sales_by_customer_by_date), collapse = ", "), "\n\n")

# Prepare df_sales_by_customer
sales_by_customer <- transactions %>%
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

cat("sales_by_customer:", nrow(sales_by_customer), "rows\n")
cat("Columns:", paste(names(sales_by_customer), collapse = ", "), "\n\n")

cat("=== Step 3: Run analysis_dna() ===\n")
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = TRUE
)

cat("\n=== Step 4: Check Output ===\n")
customer_data <- dna_result$data_by_customer

if (data.table::is.data.table(customer_data)) {
  customer_data <- as_tibble(customer_data)
}

cat("Output has", nrow(customer_data), "rows\n")
cat("Output columns:", paste(names(customer_data), collapse = ", "), "\n\n")

# Check for required fields
required_fields <- c("customer_id", "ni", "r_value", "m_value", "f_value", "cai", "cai_ecdf")
missing_fields <- setdiff(required_fields, names(customer_data))

if (length(missing_fields) > 0) {
  cat("⚠️  Missing fields:", paste(missing_fields, collapse = ", "), "\n\n")
} else {
  cat("✅ All required fields present\n\n")
}

cat("=== Step 5: Add customer_dynamics Classification ===\n")
customer_data <- customer_data %>%
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

cat("Customer Dynamics Distribution:\n")
print(table(customer_data$customer_dynamics))
cat("\n")

cat("=== Step 6: Calculate Activity Level (for ni >= 4) ===\n")
customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)

cat("Customers with ni >= 4:", nrow(customers_sufficient), "\n")
cat("Customers with ni < 4:", nrow(customers_insufficient), "\n\n")

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

  cat("Activity Level Distribution (ni >= 4):\n")
  print(table(customers_sufficient$activity_level, useNA = "ifany"))
  cat("\n")
}

if (nrow(customers_insufficient) > 0) {
  customers_insufficient <- customers_insufficient %>%
    mutate(activity_level = NA_character_)
}

# Combine back
customer_data_final <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)

cat("=== Step 7: Calculate Value Level ===\n")
customer_data_final <- customer_data_final %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
      m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
      TRUE ~ "低"
    )
  )

cat("Value Level Distribution:\n")
print(table(customer_data_final$value_level))
cat("\n")

cat("=== Final Summary ===\n")
cat("Total customers:", nrow(customer_data_final), "\n")
cat("Customers with activity level:", sum(!is.na(customer_data_final$activity_level)), "\n")
cat("Customers without activity level:", sum(is.na(customer_data_final$activity_level)), "\n\n")

cat("✅ Test completed successfully!\n")
cat("Sample output (first 5 rows):\n")
print(customer_data_final %>%
  select(customer_id, ni, customer_dynamics, value_level, activity_level, r_value, m_value) %>%
  head(5))
