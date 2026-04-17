# Test analyze_customer_dynamics_new() in Shiny context
# This mimics exactly how the Shiny app loads the function

cat("==================================================\n")
cat("TESTING IN SHINY APP CONTEXT\n")
cat("==================================================\n\n")

# Source exactly as the module does
cat("Step 1: Sourcing as module does...\n")
if (file.exists("utils/analyze_customer_dynamics_new.R")) {
  source("utils/analyze_customer_dynamics_new.R")
  cat("✓ Sourced utils/analyze_customer_dynamics_new.R\n\n")
} else {
  stop("❌ File not found!")
}

# Check function exists
cat("Step 2: Checking function exists...\n")
if (exists("analyze_customer_dynamics_new")) {
  cat("✓ Function exists\n\n")
} else {
  stop("❌ Function not found!")
}

# Create test data
cat("Step 3: Creating test data...\n")
library(dplyr)
set.seed(123)
n_customers <- 50
test_data <- data.frame(
  customer_id = rep(paste0('CUST', sprintf('%03d', 1:n_customers)), each=3),
  transaction_date = as.Date("2023-01-01") + sample(1:200, n_customers*3, replace=TRUE),
  transaction_amount = round(runif(n_customers*3, 50, 500), 2)
)
test_data$transaction_date <- as.Date(test_data$transaction_date)
cat("✓ Test data created\n\n")

# Test the function
cat("Step 4: Calling analyze_customer_dynamics_new()...\n")
cat("  Parameters:\n")
cat("    - method: auto\n")
cat("    - k: 2.5\n")
cat("    - min_window: 90\n")
cat("    - use_recency_guardrail: TRUE\n\n")

tryCatch({
  result <- analyze_customer_dynamics_new(
    test_data,
    method = "auto",
    k = 2.5,
    min_window = 90,
    use_recency_guardrail = TRUE
  )

  cat("\n✅✅✅ SUCCESS!\n\n")
  cat("Results:\n")
  cat("  Method used:", result$validation$method_used, "\n")
  cat("  Total customers:", nrow(result$customer_data), "\n")
  cat("  Dynamics distribution:\n")
  print(table(result$customer_data$customer_dynamics))

  cat("\n==================================================\n")
  cat("TEST PASSED - Function works in Shiny context!\n")
  cat("==================================================\n")

}, error = function(e) {
  cat("\n❌❌❌ FAILED!\n\n")
  cat("Error message:", e$message, "\n")
  cat("Error call:", deparse(e$call), "\n\n")

  cat("Traceback:\n")
  print(sys.calls())

  cat("\n==================================================\n")
  cat("TEST FAILED - Error in Shiny context\n")
  cat("==================================================\n")

  stop(e)
})
