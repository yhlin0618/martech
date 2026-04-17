# Complete Flow Test - Mimics Exact App Behavior
# Tests: Upload -> DNA Analysis -> Customer Value Display

library(dplyr)
library(tibble)

cat("=== Complete Flow Test ===\n\n")

# Step 1: Simulate uploaded data (from upload module)
cat("Step 1: Simulating uploaded data...\n")
set.seed(123)
n_customers <- 100
uploaded_data <- data.frame(
  customer_id = sample(paste0('CUST', sprintf('%04d', 1:n_customers)), 500, replace = TRUE),
  payment_time = Sys.Date() - sample(1:365, 500, replace = TRUE),
  lineitem_price = round(runif(500, 10, 500), 2)
)
cat("✓ Created", nrow(uploaded_data), "transactions\n\n")

# Step 2: DNA Module Processing (exact logic from module_dna_multi_premium_v2.R)
cat("Step 2: DNA Module Processing...\n")

# Standardize column names (line 116-120 in module)
transaction_data <- uploaded_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

# Source required functions
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

# Prepare data for analysis_dna() (lines 290-314)
sales_by_customer_by_date <- transaction_data %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    payment_time = min(transaction_date),
    sum_spent_by_date = sum(transaction_amount, na.rm = TRUE),
    count_transactions_by_date = n(),
    .groups = "drop"
  )

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

cat("  Prepared data for analysis_dna\n")

# Call analysis_dna() (lines 316-322)
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = FALSE
)

customer_data <- dna_result$data_by_customer %>%
  as_tibble()

cat("✓ analysis_dna() completed\n")
cat("  Columns from DNA:", paste(names(customer_data), collapse=", "), "\n\n")

# Add customer_dynamics (lines 327-341)
zscore_results <- analyze_customer_dynamics_new(
  transaction_data,
  method = "auto",
  k = 2.5,
  min_window = 90,
  use_recency_guardrail = TRUE
)

customer_data <- customer_data %>%
  left_join(
    zscore_results$customer_data %>% select(customer_id, customer_dynamics),
    by = "customer_id"
  )

cat("✓ customer_dynamics added\n")
cat("  Method used:", zscore_results$validation$method_used, "\n\n")

# Rename cai_value to cai for consistency (lines 368-372)
if ("cai_value" %in% names(customer_data) && !"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    rename(cai = cai_value)
  cat("✓ Renamed cai_value to cai\n\n")
}

# Step 3: Calculate value and activity levels (lines 374-407)
cat("Step 3: Calculating value and activity levels...\n")

customer_data <- customer_data %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
      m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
      TRUE ~ "低"
    )
  )

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

cat("✓ Value and activity levels calculated\n\n")

# Step 4: Calculate grid position (lines 409-424)
cat("Step 4: Calculating grid positions...\n")

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

cat("✓ Grid positions calculated\n\n")

# Step 5: Calculate customer tags (line 407)
cat("Step 5: Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Customer tags calculated\n\n")

# Step 6: Validation
cat("=== Validation Results ===\n\n")

# Check required fields
required_fields <- c(
  "customer_id", "ni", "r_value", "m_value", "f_value",
  "cai", "cai_ecdf", "customer_dynamics", "value_level",
  "activity_level", "grid_position"
)

missing_fields <- setdiff(required_fields, names(customer_data))
if (length(missing_fields) > 0) {
  cat("❌ FAIL: Missing required fields:\n")
  cat("  ", paste(missing_fields, collapse=", "), "\n\n")
  stop("Test failed: missing required fields")
} else {
  cat("✅ All required fields present\n\n")
}

# Check customer dynamics distribution
cat("Customer Dynamics Distribution:\n")
dynamics_table <- table(customer_data$customer_dynamics)
print(dynamics_table)
cat("\n")

expected_dynamics <- c("active", "sleepy", "half_sleepy", "dormant", "newbie")
missing_dynamics <- setdiff(expected_dynamics, names(dynamics_table))
if (length(missing_dynamics) > 0) {
  cat("⚠️  WARNING: Missing customer dynamics types:", paste(missing_dynamics, collapse=", "), "\n")
  cat("   This may be OK if data doesn't have these types\n\n")
}

# Check value level distribution
cat("Value Level Distribution:\n")
print(table(customer_data$value_level))
cat("\n")

# Check activity level distribution
cat("Activity Level Distribution (ni >= 4):\n")
activity_table <- table(customer_data$activity_level, useNA = "ifany")
print(activity_table)
cat("\n")

# Check grid position distribution
cat("Grid Position Distribution:\n")
grid_table <- table(customer_data$grid_position)
print(grid_table)
cat("\n")

# Summary statistics
cat("=== Summary Statistics ===\n")
cat("Total customers:", nrow(customer_data), "\n")
cat("Customers with ni >= 4:", sum(customer_data$ni >= 4), "\n")
cat("Customers with ni < 4:", sum(customer_data$ni < 4), "\n")
cat("Customers with activity level:", sum(!is.na(customer_data$activity_level)), "\n")
cat("Customers without activity level:", sum(is.na(customer_data$activity_level)), "\n\n")

# Check for NA values in critical fields
critical_fields <- c("r_value", "m_value", "f_value", "customer_dynamics")
cat("Checking for NA values in critical fields:\n")
for (field in critical_fields) {
  na_count <- sum(is.na(customer_data[[field]]))
  if (na_count > 0) {
    cat("  ⚠️ ", field, ":", na_count, "NA values\n")
  } else {
    cat("  ✅", field, ": No NA values\n")
  }
}
cat("\n")

# Sample output
cat("=== Sample Output (First 5 Rows) ===\n")
sample_output <- customer_data %>%
  select(customer_id, ni, customer_dynamics, value_level, activity_level,
         grid_position, r_value, m_value, f_value, cai, cai_ecdf) %>%
  head(5)
print(sample_output)
cat("\n")

cat("✅✅✅ COMPLETE FLOW TEST PASSED ✅✅✅\n")
