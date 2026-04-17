################################################################################
# DNA Output Inspection Script
# Purpose: Examine the actual data structure after DNA analysis and tag calculation
################################################################################

library(tidyverse)
library(readr)

# Source required modules
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

cat("════════════════════════════════════════════════════════════\n")
cat("  DNA Output Inspection - Understanding Data Structure\n")
cat("════════════════════════════════════════════════════════════\n\n")

# Load test data (same as integration test)
test_data_dir <- "test_data/KM_eg"
files <- list.files(test_data_dir, pattern = "\\.csv$", full.names = TRUE)

all_data <- map_dfr(files, function(file) {
  read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
})

cat("📊 Loaded", nrow(all_data), "transactions\n\n")

# Transform to upload format
upload_data <- all_data %>%
  transmute(
    customer_id = `Buyer Name`,
    payment_time = lubridate::ymd_hms(`Payments Date`),  # Use lubridate for ISO8601 dates
    lineitem_price = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(payment_time), !is.na(lineitem_price), lineitem_price > 0)

# Standardize column names
transaction_data <- upload_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

cat("📊 Standardized data:", nrow(transaction_data), "transactions\n\n")

# Prepare for DNA analysis
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

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 1: DNA Analysis Output\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date
)

customer_data <- dna_result$data_by_customer

cat("📋 DNA Output Columns (", ncol(customer_data), "total):\n")
print(names(customer_data))

cat("\n📊 Sample Data (first 5 customers):\n")
print(customer_data %>% select(customer_id, ni, r_value, f_value, m_value, ipt) %>% head(5))

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 2: Customer Dynamics Classification (Fixed Threshold)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

customer_data_with_dynamics <- customer_data %>%
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

cat("📋 Customer Dynamics Distribution (English):\n")
print(table(customer_data_with_dynamics$customer_dynamics, useNA = "ifany"))

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 3: Calculate ALL Customer Tags\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Add value_level first (required by tag calculation)
customer_data_with_dynamics <- customer_data_with_dynamics %>%
  mutate(
    value_level = case_when(
      is.na(m_value) ~ "未知",
      m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
      m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
      TRUE ~ "低"
    )
  )

cat("📋 Columns before tag calculation:\n")
cat(paste(names(customer_data_with_dynamics), collapse = ", "), "\n\n")

# Calculate all tags
customer_data_with_tags <- calculate_all_customer_tags(customer_data_with_dynamics)

cat("📋 Columns after tag calculation (", ncol(customer_data_with_tags), "total):\n")
print(names(customer_data_with_tags))

# Find all tag columns
tag_cols <- names(customer_data_with_tags)[grepl("^tag_", names(customer_data_with_tags))]
cat("\n🏷️  Tag Columns (", length(tag_cols), "total):\n")
print(tag_cols)

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 4: Inspect tag_017_customer_dynamics (CRITICAL)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

if ("tag_017_customer_dynamics" %in% names(customer_data_with_tags)) {
  cat("✅ tag_017_customer_dynamics EXISTS\n\n")

  cat("📊 Distribution:\n")
  tag_dist <- table(customer_data_with_tags$tag_017_customer_dynamics, useNA = "ifany")
  print(tag_dist)

  cat("\n📋 Unique Values:\n")
  print(unique(customer_data_with_tags$tag_017_customer_dynamics))

  cat("\n📋 Sample Data (first 10 customers):\n")
  sample_data <- customer_data_with_tags %>%
    select(customer_id, ni, customer_dynamics, tag_017_customer_dynamics, tag_018_churn_risk) %>%
    head(10)
  print(sample_data)

  cat("\n📊 Cross-tabulation: customer_dynamics vs tag_017_customer_dynamics:\n")
  crosstab <- table(
    English = customer_data_with_tags$customer_dynamics,
    Chinese = customer_data_with_tags$tag_017_customer_dynamics,
    useNA = "ifany"
  )
  print(crosstab)

} else {
  cat("❌ tag_017_customer_dynamics MISSING!\n")
}

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 5: Inspect tag_018_churn_risk\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

if ("tag_018_churn_risk" %in% names(customer_data_with_tags)) {
  cat("✅ tag_018_churn_risk EXISTS\n\n")

  cat("📊 Distribution:\n")
  risk_dist <- table(customer_data_with_tags$tag_018_churn_risk, useNA = "ifany")
  print(risk_dist)

  cat("\n📋 Unique Values:\n")
  print(unique(customer_data_with_tags$tag_018_churn_risk))

} else {
  cat("❌ tag_018_churn_risk MISSING!\n")
}

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("STEP 6: Check what customer_status module expects\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("🔍 Checking for Chinese values:\n")
cat("  - 主力客 count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "主力客", na.rm = TRUE), "\n")
cat("  - 睡眠客 count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "睡眠客", na.rm = TRUE), "\n")
cat("  - 半睡客 count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "半睡客", na.rm = TRUE), "\n")
cat("  - 沉睡客 count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "沉睡客", na.rm = TRUE), "\n")
cat("  - 新客 count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "新客", na.rm = TRUE), "\n")

cat("\n🔍 Checking for English values (should be 0):\n")
cat("  - active count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "active", na.rm = TRUE), "\n")
cat("  - sleepy count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "sleepy", na.rm = TRUE), "\n")
cat("  - dormant count:", sum(customer_data_with_tags$tag_017_customer_dynamics == "dormant", na.rm = TRUE), "\n")

cat("\n🔍 Checking churn risk values:\n")
cat("  - 高風險 count:", sum(customer_data_with_tags$tag_018_churn_risk == "高風險", na.rm = TRUE), "\n")
cat("  - 中風險 count:", sum(customer_data_with_tags$tag_018_churn_risk == "中風險", na.rm = TRUE), "\n")
cat("  - 低風險 count:", sum(customer_data_with_tags$tag_018_churn_risk == "低風險", na.rm = TRUE), "\n")
cat("  - 新客（無法評估） count:", sum(customer_data_with_tags$tag_018_churn_risk == "新客（無法評估）", na.rm = TRUE), "\n")

cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("SUMMARY\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("✅ Total Customers:", nrow(customer_data_with_tags), "\n")
cat("✅ Total Columns:", ncol(customer_data_with_tags), "\n")
cat("✅ Total Tags:", length(tag_cols), "\n")
cat("✅ tag_017_customer_dynamics:", if("tag_017_customer_dynamics" %in% names(customer_data_with_tags)) "EXISTS" else "MISSING", "\n")
cat("✅ tag_018_churn_risk:", if("tag_018_churn_risk" %in% names(customer_data_with_tags)) "EXISTS" else "MISSING", "\n\n")

cat("🎯 Key Findings:\n")
cat("   - customer_dynamics uses ENGLISH values (newbie, active, etc.)\n")
cat("   - tag_017_customer_dynamics should use CHINESE values (新客, 主力客, etc.)\n")
cat("   - Customer status module should count by CHINESE values\n\n")

cat("════════════════════════════════════════════════════════════\n")
cat("  Inspection Complete\n")
cat("════════════════════════════════════════════════════════════\n")
