# Test with Real Uploaded Data
# Purpose: Test exact module flow with actual uploaded data structure

library(dplyr)
library(tibble)
library(readxl)

cat("=== Testing with Real Data Structure ===\n\n")

# Check if there's uploaded data
data_files <- list.files(".", pattern = "\\.xlsx$|\\.csv$", full.names = TRUE)
if (length(data_files) == 0) {
  cat("⚠️  No data files found. Creating test data...\n\n")

  # Create test data
  set.seed(123)
  n_customers <- 100
  uploaded_data <- data.frame(
    customer_id = sample(paste0('CUST', sprintf('%04d', 1:n_customers)), 500, replace = TRUE),
    payment_time = Sys.Date() - sample(1:365, 500, replace = TRUE),
    lineitem_price = round(runif(500, 10, 500), 2)
  )
} else {
  cat("Found data file:", data_files[1], "\n")
  cat("Reading data...\n")

  ext <- tolower(tools::file_ext(data_files[1]))
  if (ext == "csv") {
    uploaded_data <- read.csv(data_files[1], stringsAsFactors = FALSE)
  } else {
    uploaded_data <- as.data.frame(read_excel(data_files[1]))
  }
  cat("✓ Loaded", nrow(uploaded_data), "rows\n\n")
}

cat("Uploaded data columns:", paste(names(uploaded_data), collapse=", "), "\n\n")

# Standardize column names (like upload module does)
cat("Standardizing column names...\n")
transaction_data <- uploaded_data

# Detect and rename columns
cols <- tolower(names(transaction_data))

# Customer ID
customer_field <- NULL
email_patterns <- c("buyer email", "buyer_email", "email")
id_patterns <- c("customer_id", "customer", "buyer_id", "user_id")

for (pattern in email_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    customer_field <- names(transaction_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

if (is.null(customer_field)) {
  for (pattern in id_patterns) {
    if (any(grepl(pattern, cols, fixed = TRUE))) {
      customer_field <- names(transaction_data)[grepl(pattern, cols, fixed = TRUE)][1]
      break
    }
  }
}

# Time field
time_field <- NULL
time_patterns <- c("purchase date", "payments date", "payment_time", "date", "time", "datetime")
for (pattern in time_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    time_field <- names(transaction_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

# Amount field
amount_field <- NULL
amount_patterns <- c("item price", "lineitem_price", "amount", "sales", "price", "total")
for (pattern in amount_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    amount_field <- names(transaction_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

cat("Detected fields:\n")
cat("  Customer ID:", customer_field, "\n")
cat("  Time:", time_field, "\n")
cat("  Amount:", amount_field, "\n\n")

if (is.null(customer_field) || is.null(time_field) || is.null(amount_field)) {
  stop("❌ Cannot detect required fields")
}

# Rename
names(transaction_data)[names(transaction_data) == customer_field] <- "customer_id"
names(transaction_data)[names(transaction_data) == time_field] <- "transaction_date"
names(transaction_data)[names(transaction_data) == amount_field] <- "transaction_amount"

cat("✓ Columns renamed\n")
cat("  Standardized columns:", paste(names(transaction_data), collapse=", "), "\n\n")

# Source required functions
cat("Sourcing required functions...\n")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")
cat("✓ Functions sourced\n\n")

# Prepare data for analysis_dna()
cat("Preparing data for analysis_dna()...\n")

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

cat("✓ Data prepared\n\n")

# Call analysis_dna() with skip_within_subject = TRUE
cat("Calling analysis_dna() with skip_within_subject = TRUE...\n")
dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date,
  skip_within_subject = TRUE,
  verbose = FALSE
)
cat("✓ analysis_dna() completed\n\n")

customer_data <- dna_result$data_by_customer %>%
  as_tibble()

cat("Columns from analysis_dna():\n")
cat("  ", paste(names(customer_data), collapse=", "), "\n\n")

# Add customer_dynamics
cat("Calling analyze_customer_dynamics_new()...\n")
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

# Rename cai_value to cai
cat("Renaming cai_value to cai...\n")
if ("cai_value" %in% names(customer_data) && !"cai" %in% names(customer_data)) {
  customer_data <- customer_data %>%
    rename(cai = cai_value)
  cat("✓ Renamed\n\n")
}

# Ensure correct types
cat("Converting data types...\n")
cat("  m_value class before:", class(customer_data$m_value), "\n")

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
cat("  m_value sample:", paste(head(customer_data$m_value, 3), collapse=", "), "\n\n")

# Calculate value level
cat("Calculating value level...\n")
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
cat("✓ value_level calculated\n\n")

# Calculate activity level
cat("Calculating activity level...\n")
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
  cat("✓ activity_level for ni >= 4\n")
}

if (nrow(customers_insufficient) > 0) {
  customers_insufficient <- customers_insufficient %>%
    mutate(activity_level = NA_character_)
  cat("✓ activity_level NA for ni < 4\n")
}

customer_data <- bind_rows(customers_sufficient, customers_insufficient) %>%
  arrange(customer_id)

cat("\n")

# Calculate grid position
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

# Calculate customer tags
cat("Calculating customer tags...\n")
customer_data <- calculate_all_customer_tags(customer_data)
cat("✓ Tags calculated\n\n")

# Validation
cat("=== VALIDATION RESULTS ===\n\n")

cat("Customer Dynamics:\n")
print(table(customer_data$customer_dynamics))
cat("\nValue Level:\n")
print(table(customer_data$value_level))
cat("\nActivity Level (ni >= 4):\n")
print(table(customer_data$activity_level, useNA = "ifany"))
cat("\nGrid Position:\n")
print(table(customer_data$grid_position))

cat("\n✅✅✅ REAL DATA TEST PASSED ✅✅✅\n")
cat("Total customers:", nrow(customer_data), "\n")
cat("With activity level:", sum(!is.na(customer_data$activity_level)), "\n")
