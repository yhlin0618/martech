################################################################################
# Test Grid Position and Customer Type Labels
# Purpose: 驗證 grid_position 計算邏輯和客戶類型標籤
# Date: 2025-11-11
################################################################################

library(dplyr)
library(readr)
library(lubridate)

setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")

cat("=== Grid Position Logic Test ===\n\n")

# ==============================================================================
# Load Sample Data
# ==============================================================================

cat("Loading sample KM_eg data...\n")
test_data <- read_csv("test_data/KM_eg/2_1_23, 12_00 AM - 2_7_23, 11_59 PM.csv",
                      show_col_types = FALSE) %>%
  mutate(
    customer_id = `Buyer Email`,
    transaction_date = as.Date(ymd_hms(`Purchase Date`)),
    transaction_amount = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(transaction_date), !is.na(transaction_amount), transaction_amount > 0) %>%
  select(customer_id, transaction_date, transaction_amount)

cat(sprintf("Loaded %s transactions, %s customers\n\n",
            format(nrow(test_data), big.mark = ","),
            format(n_distinct(test_data$customer_id), big.mark = ",")))

# ==============================================================================
# Run DNA Analysis
# ==============================================================================

cat("Running DNA analysis...\n")
dna_result <- analyze_customer_dynamics_new(transaction_data = test_data)
customer_data <- dna_result$customer_data

cat(sprintf("DNA analysis completed: %s customers\n\n",
            format(nrow(customer_data), big.mark = ",")))

# ==============================================================================
# Simulate Module Logic
# ==============================================================================

cat("=== Simulating Module Logic ===\n\n")

# Step 1: Calculate value_level and activity_level (from DNA analysis)
cat("Step 1: Check value_level and activity_level from DNA\n")
cat(sprintf("  value_level available: %s\n", "value_level" %in% names(customer_data)))
cat(sprintf("  activity_level available: %s\n", "activity_level" %in% names(customer_data)))

# Calculate activity_level if not present
if (!"activity_level" %in% names(customer_data)) {
  cat("  → Calculating activity_level (need ni >= 4 for valid activity)\n")
  customer_data <- customer_data %>%
    mutate(
      activity_level = case_when(
        ni < 4 ~ NA_character_,  # Not enough data
        TRUE ~ "高"  # Simplified for testing
      )
    )
}

# Show value and activity distribution
cat("\nValue level distribution:\n")
print(table(customer_data$value_level, useNA = "ifany"))

cat("\nActivity level distribution:\n")
print(table(customer_data$activity_level, useNA = "ifany"))

cat("\nCustomer dynamics distribution:\n")
print(table(customer_data$customer_dynamics, useNA = "ifany"))

# Step 2: Calculate grid_position (same logic as module)
cat("\n\nStep 2: Calculating grid_position...\n")
customer_data <- customer_data %>%
  mutate(
    # First calculate base grid position (A1-C3)
    grid_base = case_when(
      is.na(activity_level) ~ "無",  # ni < 4
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
    ),
    # Then add lifecycle suffix based on customer_dynamics
    # Note: customer_dynamics from DNA analysis is in English
    lifecycle_suffix = case_when(
      customer_dynamics == "newbie" ~ "N",
      customer_dynamics == "active" ~ "C",
      customer_dynamics == "sleepy" ~ "S",
      customer_dynamics == "half_sleepy" ~ "H",
      customer_dynamics == "dormant" ~ "D",
      TRUE ~ ""
    ),
    # Combine to create full grid_position
    grid_position = if_else(
      grid_base == "無" | grid_base == "其他",
      grid_base,
      paste0(grid_base, lifecycle_suffix)
    )
  )

cat("\nGrid base distribution:\n")
print(table(customer_data$grid_base, useNA = "ifany"))

cat("\nLifecycle suffix distribution:\n")
print(table(customer_data$lifecycle_suffix, useNA = "ifany"))

cat("\nFinal grid_position distribution:\n")
print(table(customer_data$grid_position, useNA = "ifany"))

# Step 3: Get strategy for each grid_position
cat("\n\nStep 3: Testing get_strategy() function...\n")

# Load the get_strategy function from the module
cat("  Loading get_strategy from module...\n")
module_code <- readLines("modules/module_dna_multi_premium_v2.R")
get_strategy_start <- which(grepl("^get_strategy <- function", module_code))
get_strategy_end <- which(grepl("^}", module_code) &
                           seq_along(module_code) > get_strategy_start[1])[1]

cat(sprintf("  Found get_strategy at lines %d-%d\n", get_strategy_start, get_strategy_end))

# Source the function
eval(parse(text = paste(module_code[get_strategy_start:get_strategy_end], collapse = "\n")))

# Test get_strategy on unique grid_positions
unique_positions <- unique(customer_data$grid_position)
cat(sprintf("\n  Testing %d unique grid positions:\n", length(unique_positions)))

strategy_results <- data.frame(
  grid_position = character(),
  title = character(),
  action = character(),
  stringsAsFactors = FALSE
)

for (pos in unique_positions) {
  result <- get_strategy(pos)
  if (is.null(result)) {
    strategy_results <- rbind(strategy_results,
                              data.frame(grid_position = pos,
                                       title = NA_character_,
                                       action = NA_character_))
    cat(sprintf("    %s: NULL (hidden or undefined)\n", pos))
  } else {
    strategy_results <- rbind(strategy_results,
                              data.frame(grid_position = pos,
                                       title = result$title,
                                       action = result$action))
    cat(sprintf("    %s: %s - %s\n", pos, result$title, result$action))
  }
}

# Step 4: Apply strategy to customer data
cat("\n\nStep 4: Applying strategy to customer data...\n")
customer_data <- customer_data %>%
  rowwise() %>%
  mutate(
    strategy_data = list(get_strategy(grid_position)),
    customer_type = if(!is.null(strategy_data)) strategy_data$title else NA_character_,
    strategy = if(!is.null(strategy_data)) strategy_data$action else NA_character_
  ) %>%
  ungroup()

# Check results
cat("\nCustomer type (title) distribution:\n")
type_dist <- customer_data %>%
  count(customer_type) %>%
  arrange(desc(n))
print(type_dist)

cat("\nSample customers with their labels:\n")
sample_customers <- customer_data %>%
  select(customer_id, ni, customer_dynamics, value_level, activity_level,
         grid_position, customer_type, strategy) %>%
  head(10)
print(sample_customers, width = 200)

# ==============================================================================
# Diagnosis
# ==============================================================================

cat("\n\n=== DIAGNOSIS ===\n\n")

# Count customers without customer_type
no_type <- sum(is.na(customer_data$customer_type))
total <- nrow(customer_data)

cat(sprintf("Total customers: %d\n", total))
cat(sprintf("Customers WITHOUT type label: %d (%.1f%%)\n",
            no_type, no_type/total*100))
cat(sprintf("Customers WITH type label: %d (%.1f%%)\n",
            total - no_type, (total - no_type)/total*100))

if (no_type > 0) {
  cat("\nCustomers without type label - breakdown:\n")
  no_type_breakdown <- customer_data %>%
    filter(is.na(customer_type)) %>%
    count(grid_position, customer_dynamics, value_level, activity_level) %>%
    arrange(desc(n))
  print(no_type_breakdown)

  cat("\n⚠️ PROBLEM IDENTIFIED:\n")
  cat("  Some grid_position values don't have corresponding strategies in get_strategy()\n")
  cat("  This is why customer_type shows as NA in the table\n")
}

cat("\n=== Test Complete ===\n")
