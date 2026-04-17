# Test Module DNA Analysis Flow
# Purpose: Exactly replicate the module's analysis logic

library(dplyr)
library(tibble)

cat("=== Testing Module DNA Analysis Flow ===\n\n")

# Step 1: Simulate uploaded data
cat("Step 1: Simulating uploaded data...\n")
set.seed(123)
n_customers <- 100
uploaded_data <- data.frame(
  customer_id = sample(paste0('CUST', sprintf('%04d', 1:n_customers)), 500, replace = TRUE),
  payment_time = Sys.Date() - sample(1:365, 500, replace = TRUE),
  lineitem_price = round(runif(500, 10, 500), 2)
)
cat("✓ Created", nrow(uploaded_data), "transactions\n\n")

# Step 2: Standardize column names (like upload module does)
cat("Step 2: Standardizing column names...\n")
transaction_data <- uploaded_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )
cat("✓ Columns standardized\n\n")

# Step 3: Source required functions
cat("Step 3: Sourcing required functions...\n")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")
cat("✓ Functions sourced\n\n")

# Step 4: Prepare data for analysis_dna() (EXACT MODULE LOGIC - lines 254-278)
cat("Step 4: Preparing data for analysis_dna()...\n")

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

cat("✓ Data prepared\n")
cat("  sales_by_customer:", nrow(sales_by_customer), "rows\n")
cat("  sales_by_customer_by_date:", nrow(sales_by_customer_by_date), "rows\n\n")

# Step 5: Call analysis_dna() (EXACT MODULE LOGIC - lines 280-289)
cat("Step 5: Running analysis_dna()...\n")
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = FALSE
)

customer_data <- dna_result$data_by_customer %>%
  as_tibble()

cat("✓ analysis_dna() completed\n")
cat("  Columns:", paste(names(customer_data), collapse=", "), "\n\n")

# Step 6: Add customer_dynamics (EXACT MODULE LOGIC - lines 291-305)
cat("Step 6: Adding customer_dynamics classification...\n")
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

use_zscore_method <- (zscore_results$validation$method_used == "z_score")
cat("✓ customer_dynamics added\n")
cat("  Method used:", zscore_results$validation$method_used, "\n\n")

# Step 7: Rename cai_value to cai (EXACT MODULE LOGIC - lines 332-336)
cat("Step 7: Renaming cai_value to cai...\n")
if ("cai_value" %in% names(customer_data) && !"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    rename(cai = cai_value)
  cat("✓ Renamed cai_value to cai\n\n")
} else {
  cat("⚠️  cai already exists or cai_value not found\n\n")
}

# Step 8: Ensure correct types (EXACT MODULE LOGIC - lines 338-347)
cat("Step 8: Ensuring correct data types...\n")
customer_data <- customer_data %>%
  mutate(
    m_value = as.numeric(m_value),
    r_value = as.numeric(r_value),
    f_value = as.numeric(f_value),
    cai = as.numeric(cai),
    cai_ecdf = as.numeric(cai_ecdf),
    ni = as.integer(ni)
  )
cat("✓ Data types ensured\n")
cat("  m_value class:", class(customer_data$m_value), "\n")
cat("  cai_ecdf class:", class(customer_data$cai_ecdf), "\n\n")

# Step 9: Calculate value level (EXACT MODULE LOGIC - lines 349-361)
cat("Step 9: Calculating value level...\n")
m_q80 <- quantile(customer_data$m_value, 0.8, na.rm = TRUE)
m_q20 <- quantile(customer_data$m_value, 0.2, na.rm = TRUE)

cat("  m_q80:", m_q80, "\n")
cat("  m_q20:", m_q20, "\n")

customer_data <- customer_data %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= m_q80 ~ "高",
      m_value >= m_q20 ~ "中",
      TRUE ~ "低"
    )
  )
cat("✓ Value level calculated\n\n")

# Step 10: Calculate activity level (EXACT MODULE LOGIC - lines 363-420)
cat("Step 10: Calculating activity level (ni >= 4 only)...\n")

customers_sufficient <- customer_data %>% filter(ni >= 4)
customers_insufficient <- customer_data %>% filter(ni < 4)

cat("  Customers with ni >= 4:", nrow(customers_sufficient), "\n")
cat("  Customers with ni < 4:", nrow(customers_insufficient), "\n")

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
  cat("✓ Activity level calculated for ni >= 4\n")
}

if (nrow(customers_insufficient) > 0) {
  customers_insufficient <- customers_insufficient %>%
    mutate(activity_level = NA_character_)
  cat("✓ Activity level set to NA for ni < 4\n")
}

customer_data <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)

cat("\n")

# Step 11: Calculate grid position (EXACT MODULE LOGIC - lines 422-440)
cat("Step 11: Calculating grid position...\n")
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
cat("✓ Grid position calculated\n\n")

# Step 12: Calculate customer tags
cat("Step 12: Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Customer tags calculated\n\n")

# Step 13: Validation
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

if (length(dynamics_table) < 2) {
  cat("❌ FAIL: Only", length(dynamics_table), "customer dynamics type(s) found\n")
  cat("   Expected at least 2-3 types\n\n")
  stop("Test failed: insufficient customer dynamics types")
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

cat("✅✅✅ MODULE FLOW TEST PASSED ✅✅✅\n")
cat("All steps completed successfully with correct data types and values.\n")
