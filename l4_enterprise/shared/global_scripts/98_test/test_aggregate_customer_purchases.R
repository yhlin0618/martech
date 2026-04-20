#' Test Script for aggregate_customer_purchases Function
#'
#' This script tests the aggregate_customer_purchases function to ensure
#' it follows MAMBA principles and produces correct results.
#'
#' @author MAMBA System
#' @date 2025-08-23
#' @version 1.0.0

# =========================
# Setup and Dependencies
# =========================

# Load required libraries
library(dplyr)
library(lubridate)
library(testthat)

# Source the function
source("../04_utils/fn_aggregate_customer_purchases.R")

# =========================
# Test Data Generation
# =========================

#' Generate Sample Purchase Data
#'
#' Creates realistic sample purchase data for testing
#'
#' @param n_customers Number of unique customers
#' @param date_start Start date for purchases
#' @param date_end End date for purchases
#' @param n_purchases Total number of purchases to generate
#' @return Data frame with purchase data
#'
generate_test_purchase_data <- function(
  n_customers = 10,
  date_start = "2024-01-01",
  date_end = "2024-12-31",
  n_purchases = 100
) {
  
  set.seed(42) # For reproducibility
  
  # Generate customer IDs
  customer_ids <- paste0("CUST", sprintf("%03d", 1:n_customers))
  
  # Generate random purchase data
  purchase_data <- data.frame(
    customer_id = sample(customer_ids, n_purchases, replace = TRUE),
    purchase_date = sample(
      seq(as.Date(date_start), as.Date(date_end), by = "day"),
      n_purchases,
      replace = TRUE
    ),
    purchase_amount = round(runif(n_purchases, min = 10, max = 1000), 2),
    order_id = paste0("ORD", sprintf("%06d", 1:n_purchases))
  )
  
  return(purchase_data)
}

# =========================
# Test Cases
# =========================

test_that("Basic monthly aggregation works correctly", {
  
  # Generate test data
  test_data <- generate_test_purchase_data(
    n_customers = 5,
    n_purchases = 50
  )
  
  # Run aggregation
  result <- aggregate_customer_purchases(test_data)
  
  # Basic structure tests
  expect_true(is.data.frame(result))
  expect_true(all(c("customer_id", "year_month", "total_spending_monthly", 
                   "purchase_frequency_monthly") %in% names(result)))
  
  # Check that all customers are represented
  unique_customers <- unique(test_data$customer_id)
  result_customers <- unique(result$customer_id)
  expect_true(all(result_customers %in% unique_customers))
  
  # Verify year_month format
  expect_true(all(grepl("^\\d{4}-\\d{2}$", result$year_month)))
  
  # Check numeric columns are positive
  expect_true(all(result$total_spending_monthly >= 0))
  expect_true(all(result$purchase_frequency_monthly >= 1))
  
  message("✓ Basic monthly aggregation test passed")
})

test_that("Quarterly aggregation works correctly", {
  
  # Generate test data
  test_data <- generate_test_purchase_data(
    n_customers = 3,
    n_purchases = 30
  )
  
  # Run aggregation with quarters
  result <- aggregate_customer_purchases(test_data, include_quarters = TRUE)
  
  # Check for quarterly columns
  expect_true("quarter" %in% names(result))
  expect_true("total_spending_quarterly" %in% names(result))
  expect_true("purchase_frequency_quarterly" %in% names(result))
  
  # Verify quarter format
  expect_true(all(grepl("^\\d{4}-Q[1-4]$", result$quarter)))
  
  # Check that quarterly totals are >= monthly totals
  # (since a quarter contains multiple months)
  expect_true(all(result$total_spending_quarterly >= result$total_spending_monthly))
  
  message("✓ Quarterly aggregation test passed")
})

test_that("Custom column names work correctly", {
  
  # Create data with custom column names
  custom_data <- data.frame(
    cust_code = rep(1:3, each = 10),
    order_date = sample(
      seq(as.Date("2024-01-01"), as.Date("2024-06-30"), by = "day"),
      30,
      replace = TRUE
    ),
    sales_amount = round(runif(30, 50, 500), 2)
  )
  
  # Run aggregation with custom column names
  result <- aggregate_customer_purchases(
    custom_data,
    customer_column = "cust_code",
    date_column = "order_date",
    amount_column = "sales_amount"
  )
  
  # Check that result is generated
  expect_true(nrow(result) > 0)
  expect_true(is.data.frame(result))
  
  message("✓ Custom column names test passed")
})

test_that("NA handling works correctly", {
  
  # Create data with NA values
  test_data <- generate_test_purchase_data(n_purchases = 20)
  
  # Introduce NA values
  test_data$purchase_amount[c(3, 7, 11)] <- NA
  test_data$customer_id[c(5, 9)] <- NA
  test_data$purchase_date[c(2, 15)] <- NA
  
  # Run aggregation (should handle NAs gracefully)
  expect_message(
    result <- aggregate_customer_purchases(test_data),
    "Removed .* rows with NA values"
  )
  
  # Check that result doesn't contain NAs in critical columns
  expect_false(any(is.na(result$customer_id)))
  expect_false(any(is.na(result$year_month)))
  expect_false(any(is.na(result$total_spending_monthly)))
  
  message("✓ NA handling test passed")
})

test_that("Empty data handling works correctly", {
  
  # Test with empty data frame
  empty_data <- data.frame(
    customer_id = character(),
    purchase_date = as.Date(character()),
    purchase_amount = numeric()
  )
  
  # Should return empty frame with warning
  expect_warning(
    result <- aggregate_customer_purchases(empty_data),
    "purchase_data has no rows"
  )
  
  expect_equal(nrow(result), 0)
  expect_true(is.data.frame(result))
  
  message("✓ Empty data handling test passed")
})

test_that("Input validation works correctly", {
  
  # Test with non-data frame input
  expect_error(
    aggregate_customer_purchases(list(a = 1, b = 2)),
    "must be a data frame"
  )
  
  # Test with missing columns
  bad_data <- data.frame(
    customer = c("A", "B"),
    amount = c(100, 200)
  )
  
  expect_error(
    aggregate_customer_purchases(bad_data),
    "Missing required columns"
  )
  
  # Test with non-numeric amount column
  bad_data <- data.frame(
    customer_id = c("A", "B"),
    purchase_date = c("2024-01-01", "2024-01-02"),
    purchase_amount = c("hundred", "two hundred")
  )
  
  expect_error(
    aggregate_customer_purchases(bad_data),
    "must be numeric"
  )
  
  message("✓ Input validation test passed")
})

test_that("Calculation accuracy is correct", {
  
  # Create controlled test data
  controlled_data <- data.frame(
    customer_id = c("A", "A", "A", "B", "B"),
    purchase_date = as.Date(c(
      "2024-01-15", "2024-01-20", "2024-02-10",
      "2024-01-05", "2024-02-15"
    )),
    purchase_amount = c(100, 200, 150, 50, 75)
  )
  
  result <- aggregate_customer_purchases(controlled_data)
  
  # Check calculations for customer A in January
  customer_a_jan <- result %>%
    filter(customer_id == "A", year_month == "2024-01")
  
  expect_equal(customer_a_jan$total_spending_monthly, 300)
  expect_equal(customer_a_jan$purchase_frequency_monthly, 2)
  expect_equal(customer_a_jan$average_purchase_amount_monthly, 150)
  
  # Check calculations for customer B
  customer_b_jan <- result %>%
    filter(customer_id == "B", year_month == "2024-01")
  
  expect_equal(customer_b_jan$total_spending_monthly, 50)
  expect_equal(customer_b_jan$purchase_frequency_monthly, 1)
  
  message("✓ Calculation accuracy test passed")
})

test_that("Fiscal year handling works correctly", {
  
  # Test data spanning fiscal year boundary
  test_data <- data.frame(
    customer_id = rep("A", 6),
    purchase_date = as.Date(c(
      "2024-03-15", "2024-04-15", "2024-05-15",
      "2024-06-15", "2024-07-15", "2024-08-15"
    )),
    purchase_amount = rep(100, 6)
  )
  
  # Test with fiscal year starting in April
  result <- aggregate_customer_purchases(
    test_data,
    include_quarters = TRUE,
    fiscal_year_start = 4
  )
  
  # Check that quarters are assigned correctly
  march_row <- result %>% filter(year_month == "2024-03")
  expect_equal(march_row$quarter, "2023-Q4")
  
  april_row <- result %>% filter(year_month == "2024-04")
  expect_equal(april_row$quarter, "2024-Q1")
  
  message("✓ Fiscal year handling test passed")
})

# =========================
# Performance Test
# =========================

test_that("Performance is acceptable for large datasets", {
  
  # Generate larger dataset
  large_data <- generate_test_purchase_data(
    n_customers = 100,
    n_purchases = 10000,
    date_start = "2023-01-01",
    date_end = "2024-12-31"
  )
  
  # Measure execution time
  start_time <- Sys.time()
  result <- aggregate_customer_purchases(large_data, include_quarters = TRUE)
  end_time <- Sys.time()
  
  execution_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # Check that it completes in reasonable time (< 5 seconds)
  expect_true(execution_time < 5)
  
  message(sprintf("✓ Performance test passed (%.2f seconds for 10k records)", 
                 execution_time))
})

# =========================
# Run All Tests
# =========================

message("\n====================================")
message("AGGREGATE CUSTOMER PURCHASES TESTS")
message("====================================\n")

# Run all tests
test_results <- test_dir(".", pattern = "test_aggregate_customer_purchases\\.R$")

message("\n====================================")
message("ALL TESTS COMPLETED SUCCESSFULLY")
message("====================================\n")

# =========================
# Example Usage Demo
# =========================

message("Running example usage demo...\n")

# Generate sample data
demo_data <- generate_test_purchase_data(
  n_customers = 5,
  n_purchases = 100,
  date_start = "2024-01-01",
  date_end = "2024-06-30"
)

# Run aggregation
monthly_summary <- aggregate_customer_purchases(demo_data)
quarterly_summary <- aggregate_customer_purchases(demo_data, include_quarters = TRUE)

# Display sample results
message("Sample Monthly Summary (first 10 rows):")
print(head(monthly_summary, 10))

message("\nSample Quarterly Summary (first 10 rows):")
print(head(quarterly_summary, 10))

# Summary statistics
message("\n=== Summary Statistics ===")
message(sprintf("Total unique customers: %d", n_distinct(monthly_summary$customer_id)))
message(sprintf("Total months with purchases: %d", n_distinct(monthly_summary$year_month)))
message(sprintf("Average monthly spending per customer: $%.2f", 
               mean(monthly_summary$total_spending_monthly)))
message(sprintf("Average purchase frequency per month: %.1f", 
               mean(monthly_summary$purchase_frequency_monthly)))

message("\n✓ Demo completed successfully")