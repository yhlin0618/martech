################################################################################
# Customer Dynamics Table Display Investigation
# Purpose: Diagnose why table shows empty customer dynamics column
################################################################################

library(tidyverse)
library(lubridate)

cat("🔍 Customer Dynamics Table Display Investigation\n")
cat("==========================================\n\n")

# Load functions
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

# ══════════════════════════════════════════════════════════════════════════
# STEP 1: Load and Process Data (same as test script)
# ══════════════════════════════════════════════════════════════════════════

files <- list.files('test_data/KM_eg', pattern = '.csv$', full.names = TRUE)
all_data <- map_dfr(files, function(file) {
  read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
})

upload_data <- all_data %>%
  transmute(
    customer_id = `Buyer Email`,
    payment_time = ymd_hms(`Payments Date`),
    lineitem_price = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(customer_id), !is.na(payment_time), !is.na(lineitem_price), lineitem_price > 0)

transaction_data <- upload_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

cat("✅ Loaded", nrow(transaction_data), "transactions\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 2: DNA Analysis
# ══════════════════════════════════════════════════════════════════════════

dna_result <- analysis_dna(transaction_data)
customer_data <- dna_result$customer_summary

cat("✅ DNA analysis complete:", nrow(customer_data), "customers\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 3: Calculate Customer Dynamics
# ══════════════════════════════════════════════════════════════════════════

zscore_results <- analyze_customer_dynamics_new(
  transaction_data = transaction_data,
  method = "z_score",
  cap_days = 365
)

customer_data <- zscore_results$customer_data

cat("✅ Customer dynamics calculated\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 4: Calculate All Tags
# ══════════════════════════════════════════════════════════════════════════

customer_data <- calculate_all_customer_tags(customer_data)

cat("✅ All tags calculated\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 5: Check tag_017_customer_dynamics
# ══════════════════════════════════════════════════════════════════════════

cat("🔍 Checking tag_017_customer_dynamics values:\n")
cat("==========================================\n\n")

cat("Column exists?", "tag_017_customer_dynamics" %in% names(customer_data), "\n\n")

if ("tag_017_customer_dynamics" %in% names(customer_data)) {
  cat("Data type:", class(customer_data$tag_017_customer_dynamics), "\n")
  cat("Number of NAs:", sum(is.na(customer_data$tag_017_customer_dynamics)), "\n")
  cat("Number of NULLs:", sum(is.null(customer_data$tag_017_customer_dynamics)), "\n")
  cat("Number of empty strings:", sum(customer_data$tag_017_customer_dynamics == "", na.rm = TRUE), "\n\n")

  cat("Unique values:\n")
  print(table(customer_data$tag_017_customer_dynamics, useNA = "always"))
  cat("\n")

  cat("First 10 values:\n")
  print(head(customer_data$tag_017_customer_dynamics, 10))
  cat("\n")
}

# ══════════════════════════════════════════════════════════════════════════
# STEP 6: Simulate Table Display Logic
# ══════════════════════════════════════════════════════════════════════════

cat("🔍 Simulating table display logic:\n")
cat("==========================================\n\n")

# This is the exact code from module_customer_status.R lines 424-446
label_map <- c(
  "新客" = "新客",
  "主力客" = "主力客",
  "睡眠客" = "睡眠客",
  "半睡客" = "半睡客",
  "沉睡客" = "沉睡客",
  "未知" = "未知"
)

# Check if mapping works
cat("Testing label mapping:\n")
test_values <- unique(customer_data$tag_017_customer_dynamics)
cat("Unique tag_017 values:", paste(test_values, collapse = ", "), "\n\n")

for (val in test_values[1:5]) {
  mapped <- label_map[val]
  cat(sprintf("  '%s' -> '%s' (NA: %s)\n", val, mapped, is.na(mapped)))
}
cat("\n")

# Create display data
display_data <- customer_data %>%
  mutate(
    客戶動態_中文 = label_map[tag_017_customer_dynamics]
  ) %>%
  select(
    customer_id,
    購買次數 = ni,
    tag_017_customer_dynamics,
    客戶動態_中文 = 客戶動態_中文,
    流失風險 = tag_018_churn_risk,
    預估流失天數 = tag_019_days_to_churn
  ) %>%
  head(20)

cat("Sample display data (first 20 rows):\n")
cat("==========================================\n")
print(as.data.frame(display_data), row.names = FALSE)
cat("\n")

# Check for NAs in mapped column
na_count <- sum(is.na(display_data$客戶動態_中文))
cat("NAs in 客戶動態_中文:", na_count, "(", round(na_count/nrow(display_data)*100, 1), "%)\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 7: Identify Issue
# ══════════════════════════════════════════════════════════════════════════

cat("⚠️  ISSUE DIAGNOSIS:\n")
cat("==========================================\n\n")

if (na_count > 0) {
  cat("❌ Issue Found: label_map produces NA values\n")
  cat("   Reason: tag_017 values don't match label_map keys\n\n")

  cat("   tag_017 values:", paste(unique(display_data$tag_017_customer_dynamics), collapse = ", "), "\n")
  cat("   label_map keys:", paste(names(label_map), collapse = ", "), "\n\n")

  cat("   Solution: Update label_map OR ensure tag_017 uses correct values\n")
} else {
  cat("✅ No issue found: Mapping works correctly\n")
  cat("   Possible UI rendering issue instead\n")
}

cat("\n✅ Investigation complete!\n")
