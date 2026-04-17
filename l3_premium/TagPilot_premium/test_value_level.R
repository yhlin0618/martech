# Test value_level calculation edge cases
library(dplyr)

source("utils/analyze_customer_dynamics_new.R")

cat("=== Testing value_level calculation ===\n\n")

# Test Case 1: Normal distribution
cat("Test 1: Normal distribution (50 customers)\n")
set.seed(123)
test_data_1 <- data.frame(
  customer_id = paste0("C", 1:50),
  transaction_date = as.Date("2023-01-01") + sample(1:100, 50, replace = TRUE),
  transaction_amount = runif(50, 100, 1000)
)

result_1 <- analyze_customer_dynamics_new(test_data_1, method = "auto")
value_dist_1 <- table(result_1$customer_data$value_level)
cat("Distribution:\n")
print(value_dist_1)
cat("\n")

# Test Case 2: All same values (edge case)
cat("Test 2: All same m_value (edge case)\n")
test_data_2 <- data.frame(
  customer_id = paste0("C", 1:50),
  transaction_date = as.Date("2023-01-01"),
  transaction_amount = rep(100, 50)  # All same amount
)

result_2 <- analyze_customer_dynamics_new(test_data_2, method = "auto")
value_dist_2 <- table(result_2$customer_data$value_level)
cat("Distribution:\n")
print(value_dist_2)
cat("\n")

# Test Case 3: Only 2 distinct values
cat("Test 3: Only 2 distinct m_values\n")
test_data_3 <- data.frame(
  customer_id = paste0("C", 1:50),
  transaction_date = as.Date("2023-01-01"),
  transaction_amount = rep(c(100, 200), each = 25)
)

result_3 <- analyze_customer_dynamics_new(test_data_3, method = "auto")
value_dist_3 <- table(result_3$customer_data$value_level)
cat("Distribution:\n")
print(value_dist_3)
cat("\n")

cat("=== Summary ===\n")
cat("Test 1 has", length(value_dist_1), "groups\n")
cat("Test 2 has", length(value_dist_2), "groups\n")
cat("Test 3 has", length(value_dist_3), "groups\n")

if (length(value_dist_1) == 3 && length(value_dist_2) == 3 && length(value_dist_3) == 3) {
  cat("\n✅ ALL TESTS PASSED - Always produces 3 groups\n")
} else {
  cat("\n❌ TESTS FAILED - Not always producing 3 groups\n")
}
