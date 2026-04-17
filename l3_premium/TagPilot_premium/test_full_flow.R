# Test Full DNA Analysis Flow
# Simulates: Upload -> DNA Analysis -> Results

library(dplyr)
library(tibble)

cat("=== Testing Full DNA Analysis Flow ===\n\n")

# Step 1: Simulate uploaded data (mimics upload module output)
cat("Step 1: Simulating uploaded data...\n")
set.seed(123)
n_customers <- 100
uploaded_data <- data.frame(
  customer_id = sample(paste0('CUST', sprintf('%04d', 1:n_customers)), 500, replace = TRUE),
  payment_time = Sys.Date() - sample(1:365, 500, replace = TRUE),
  lineitem_price = round(runif(500, 10, 500), 2)
)
cat("✓ Created", nrow(uploaded_data), "transactions\n")
cat("  Columns:", paste(names(uploaded_data), collapse=", "), "\n\n")

# Step 2: Prepare for DNA analysis (mimics module_dna logic)
cat("Step 2: Preparing for DNA analysis...\n")

# Standardize column names
transaction_data <- uploaded_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

cat("✓ Standardized column names\n")
cat("  Columns:", paste(names(transaction_data), collapse=", "), "\n\n")

# Step 3: Run DNA analysis
cat("Step 3: Running DNA analysis...\n")

source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

zscore_results <- analyze_customer_dynamics_new(
  transaction_data,
  method = "auto",
  k = 2.5,
  min_window = 90,
  use_recency_guardrail = TRUE
)

customer_data <- zscore_results$customer_data

cat("✓ Analysis completed\n")
cat("  Method used:", zscore_results$validation$method_used, "\n")
cat("  Total customers:", nrow(customer_data), "\n\n")

# Calculate CAI and cai_ecdf if not present
if (!"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    mutate(
      cai = ifelse(!is.na(f_value) & !is.na(r_value) & r_value > 0,
                  f_value / r_value,
                  NA_real_)
    )
}

if (!"cai_ecdf" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    mutate(
      cai_ecdf = ifelse(!is.na(cai), ecdf(cai)(cai), NA_real_)
    )
}

cat("✓ CAI and cai_ecdf calculated\n\n")

# Step 4: Calculate value and activity levels
cat("Step 4: Calculating value and activity levels...\n")

# Value level
customer_data <- customer_data %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
      m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
      TRUE ~ "低"
    )
  )

# Activity level (only for ni >= 4)
customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)

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

cat("✓ Value and activity levels calculated\n")
cat("  Customers with ni >= 4:", nrow(customers_sufficient), "\n")
cat("  Customers with ni < 4:", nrow(customers_insufficient), "\n\n")

# Step 5: Calculate customer tags
cat("Step 5: Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Tags calculated\n\n")

# Step 6: Summary
cat("=== Final Results ===\n")
cat("Customer Dynamics Distribution:\n")
print(table(customer_data$customer_dynamics))
cat("\nValue Level Distribution:\n")
print(table(customer_data$value_level))
cat("\nActivity Level Distribution (ni >= 4 only):\n")
print(table(customer_data$activity_level, useNA = "ifany"))

cat("\n✓ Full flow test completed successfully!\n")
