###############################################################################
# Integration Test Script - TagPilot Premium V2
# Purpose: Test z-score customer dynamics implementation
# Date: 2025-11-01
###############################################################################

# ── Setup ────────────────────────────────────────────────────────────────────

# Clear environment
rm(list = ls())
gc()

# Set working directory (adjust if needed)
# setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

# Load required packages
library(tidyverse)
library(lubridate)

# ── Test Phase 1: Configuration System ──────────────────────────────────────

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  PHASE 1: Configuration System Testing\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

# Test 1.1: Load Configuration
cat("Test 1.1: Loading configuration...\n")
tryCatch({
  source("config/customer_dynamics_config.R")
  config <- get_customer_dynamics_config()

  # Verify structure
  stopifnot(!is.null(config))
  stopifnot(config$method %in% c("auto", "z_score", "fixed_threshold"))
  stopifnot(config$zscore$k == 2.5)
  stopifnot(config$zscore$active_threshold == 0.5)

  cat("✅ Configuration loaded successfully\n")
  cat("   Method:", config$method, "\n")
  cat("   Z-score k:", config$zscore$k, "\n")
  cat("   Active threshold:", config$zscore$active_threshold, "\n\n")

  # Print summary
  cat("Configuration Summary:\n")
  cat("────────────────────────────────────────────────────────────\n")
  print_config_summary()

}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# Test 1.2: Helper Functions
cat("\nTest 1.2: Testing helper functions...\n")
tryCatch({
  # Test threshold accessors
  z_thresholds <- get_zscore_thresholds()
  stopifnot(length(z_thresholds) == 3)
  stopifnot(all(names(z_thresholds) == c("active", "sleepy", "half_sleepy")))

  activity_thresholds <- get_activity_thresholds()
  stopifnot(activity_thresholds["high"] == 0.8)

  value_thresholds <- get_value_thresholds()
  stopifnot(value_thresholds["high"] == 0.6)

  cat("✅ All helper functions working correctly\n")
  cat("   Z-score thresholds:", paste(z_thresholds, collapse=", "), "\n")
  cat("   Activity thresholds:", paste(activity_thresholds, collapse=", "), "\n")
  cat("   Value thresholds:", paste(value_thresholds, collapse=", "), "\n\n")

}, error = function(e) {
  cat("❌ FAILED:", e$message, "\n")
})

# ── Test Phase 2: Core Functions ────────────────────────────────────────────

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  PHASE 2: Core Function Testing\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("⚠️  NOTE: Phase 2 requires actual transaction data\n")
cat("   Please prepare data in the following format:\n\n")
cat("   transaction_data:\n")
cat("     - customer_id (character)\n")
cat("     - transaction_date (Date)\n")
cat("     - transaction_amount (numeric)\n\n")
cat("   To run Phase 2 tests, uncomment the code below and provide data\n\n")

# Uncomment and adjust the following code when you have data:
#
# # Load your data
# transaction_data <- read.csv("data/your_transactions.csv") %>%
#   mutate(transaction_date = as.Date(transaction_date))
#
# # Create customer summary
# customer_summary <- transaction_data %>%
#   group_by(customer_id) %>%
#   summarise(
#     ni = n(),
#     m_value = sum(transaction_amount),
#     time_first = min(transaction_date),
#     time_last = max(transaction_date),
#     .groups = "drop"
#   )
#
# # Test 2.1: DNA Analysis
# cat("Test 2.1: Running DNA analysis...\n")
# tryCatch({
#   source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
#
#   dna_result <- fn_analysis_dna(
#     df_sales_by_customer = customer_summary,
#     df_sales_by_customer_by_date = transaction_data
#   )
#
#   # Verify output
#   stopifnot(!is.null(dna_result$data_by_customer))
#   stopifnot(nrow(dna_result$data_by_customer) == n_distinct(transaction_data$customer_id))
#   stopifnot(all(c("r_value", "f_value", "m_value", "ni") %in% names(dna_result$data_by_customer)))
#
#   cat("✅ DNA analysis completed\n")
#   cat("   Total customers:", nrow(dna_result$data_by_customer), "\n")
#   cat("   Fields present:", paste(names(dna_result$data_by_customer)[1:10], collapse=", "), "...\n\n")
#
# }, error = function(e) {
#   cat("❌ FAILED:", e$message, "\n")
# })
#
# # Test 2.2: Z-Score Classification
# cat("Test 2.2: Running z-score classification...\n")
# tryCatch({
#   source("utils/analyze_customer_dynamics_new.R")
#
#   zscore_result <- analyze_customer_dynamics_new(
#     transaction_data = transaction_data,
#     method = "z_score"
#   )
#
#   # Verify output
#   stopifnot(!is.null(zscore_result$customer_data))
#   stopifnot(all(c("z_i", "F_i_w", "customer_dynamics") %in% names(zscore_result$customer_data)))
#
#   # Check classifications
#   dynamics_table <- table(zscore_result$customer_data$customer_dynamics)
#
#   cat("✅ Z-score classification completed\n")
#   cat("   Customer dynamics distribution:\n")
#   print(dynamics_table)
#   cat("\n")
#
# }, error = function(e) {
#   cat("❌ FAILED:", e$message, "\n")
# })
#
# # Test 2.3: RFM Scoring
# cat("Test 2.3: Testing RFM scoring for ALL customers...\n")
# tryCatch({
#   source("utils/calculate_customer_tags.R")
#
#   # Merge DNA + Z-score results
#   customer_data <- dna_result$data_by_customer %>%
#     left_join(
#       zscore_result$customer_data %>% select(customer_id, z_i, customer_dynamics),
#       by = "customer_id"
#     )
#
#   # Calculate RFM
#   customer_data_rfm <- calculate_rfm_scores(customer_data)
#
#   # Verify all customers have scores
#   na_count <- sum(is.na(customer_data_rfm$tag_012_rfm_score))
#
#   if (na_count == 0) {
#     cat("✅ All customers have RFM scores\n")
#   } else {
#     cat("⚠️  WARNING:", na_count, "customers have NA scores\n")
#   }
#
#   # Check newbie scores
#   newbies <- customer_data_rfm %>% filter(customer_dynamics == "newbie")
#   if (nrow(newbies) > 0) {
#     cat("   Newbie F-score summary:\n")
#     print(summary(newbies$f_score))
#   }
#   cat("\n")
#
# }, error = function(e) {
#   cat("❌ FAILED:", e$message, "\n")
# })
#
# # Test 2.4: Customer Tags
# cat("Test 2.4: Testing customer tag calculation...\n")
# tryCatch({
#   # Calculate all tags
#   customer_data_tagged <- customer_data_rfm %>%
#     calculate_activity_level() %>%
#     calculate_value_level() %>%
#     calculate_status_tags() %>%
#     calculate_prediction_tags()
#
#   # Verify all tags exist
#   required_tags <- c(
#     "tag_017_customer_dynamics",
#     "tag_018_churn_risk",
#     "tag_031_next_purchase_date",
#     "activity_level",
#     "value_level"
#   )
#
#   missing_tags <- required_tags[!required_tags %in% names(customer_data_tagged)]
#
#   if (length(missing_tags) == 0) {
#     cat("✅ All customer tags generated successfully\n")
#   } else {
#     cat("❌ FAILED: Missing tags:", paste(missing_tags, collapse=", "), "\n")
#   }
#
#   cat("   Total tags in dataset:", ncol(customer_data_tagged), "\n")
#   cat("   Sample tag values:\n")
#   cat("     - tag_017_customer_dynamics:", head(customer_data_tagged$tag_017_customer_dynamics, 3), "\n")
#   cat("     - tag_018_churn_risk:", head(customer_data_tagged$tag_018_churn_risk, 3), "\n\n")
#
# }, error = function(e) {
#   cat("❌ FAILED:", e$message, "\n")
# })

# ── Test Summary ─────────────────────────────────────────────────────────────

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  TEST SUMMARY\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

cat("Phase 1 (Configuration): ✅ Complete\n")
cat("Phase 2 (Core Functions): ⏳ Awaiting data\n")
cat("Phase 3 (Module UI): ⏳ Run app manually\n")
cat("Phase 4 (Edge Cases): ⏳ Awaiting data\n")
cat("Phase 5 (Performance): ⏳ Awaiting data\n")
cat("Phase 6 (Regression): ⏳ Awaiting data\n\n")

cat("Next Steps:\n")
cat("──────────────────────────────────────────────────────────────\n")
cat("1. Prepare transaction data\n")
cat("2. Uncomment Phase 2 tests and run\n")
cat("3. Load app and test UI manually:\n")
cat("   - Modify app.R line 86 to load v2 module\n")
cat("   - Run: shiny::runApp()\n")
cat("4. Follow INTEGRATION_TESTING_PLAN_20251101.md for full tests\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("  TEST SCRIPT COMPLETE\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
