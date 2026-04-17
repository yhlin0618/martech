# Verify the fix works
# This script tests if analyze_customer_dynamics_new() is fixed

library(dplyr)

cat("==================================================\n")
cat("VERIFYING ANALYZE_CUSTOMER_DYNAMICS_NEW FIX\n")
cat("==================================================\n\n")

# Force reload the function
cat("Step 1: Loading analyze_customer_dynamics_new()...\n")
source("utils/analyze_customer_dynamics_new.R")
cat("✓ Function loaded\n\n")

# Create test data
cat("Step 2: Creating test data...\n")
set.seed(123)
n_customers <- 50
test_data <- data.frame(
  customer_id = rep(paste0('CUST', sprintf('%03d', 1:n_customers)), each=3),
  transaction_date = as.Date("2023-01-01") + sample(1:200, n_customers*3, replace=TRUE),
  transaction_amount = round(runif(n_customers*3, 50, 500), 2)
)
cat("✓ Test data created:", nrow(test_data), "rows\n\n")

# Test the function
cat("Step 3: Testing analyze_customer_dynamics_new()...\n")
cat("  Calling with use_recency_guardrail = TRUE...\n")

tryCatch({
  result <- analyze_customer_dynamics_new(
    test_data,
    method = "auto",
    k = 2.5,
    min_window = 90,
    use_recency_guardrail = TRUE
  )

  cat("\n✅✅✅ SUCCESS! Function works correctly!\n\n")
  cat("Results:\n")
  cat("  Method used:", result$validation$method_used, "\n")
  cat("  Total customers:", nrow(result$customer_data), "\n")
  cat("  Customer dynamics:\n")
  print(table(result$customer_data$customer_dynamics))
  cat("\n==================================================\n")
  cat("VERIFICATION PASSED - Fix is working!\n")
  cat("==================================================\n")

}, error = function(e) {
  cat("\n❌❌❌ FAILED! Error still exists!\n")
  cat("Error message:", e$message, "\n\n")
  cat("==================================================\n")
  cat("VERIFICATION FAILED - Fix did not work\n")
  cat("==================================================\n")
})
