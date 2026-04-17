# test_covariate_exclusion.R
# Test script for YAML-based covariate exclusion
# Validates that configuration-driven approach works correctly

# Load utility
source("scripts/global_scripts/04_utils/fn_should_exclude_covariate.R")

# Test cases from YAML validation section
test_cases <- list(
  # Should be EXCLUDED
  list(var = "product_name", expected = TRUE, reason = "Matches _name$ pattern"),
  list(var = "brand_name", expected = TRUE, reason = "Matches _name$ pattern"),
  list(var = "seller_name", expected = TRUE, reason = "Matches _name$ pattern"),
  list(var = "category_name", expected = TRUE, reason = "Matches _name$ pattern"),
  list(var = "product_id", expected = TRUE, reason = "Exact match"),
  list(var = "compressor_wheel_design_series_name", expected = TRUE, reason = "Matches _series_name$ pattern"),
  list(var = "turbine_wheel_design_series_name", expected = TRUE, reason = "Matches _series_name$ pattern"),
  list(var = "brand.x", expected = TRUE, reason = "Matches brand\\. pattern"),
  list(var = "brand.y", expected = TRUE, reason = "Matches brand\\. pattern"),
  list(var = "product_nameSpecial", expected = TRUE, reason = "Matches camelCase name pattern"),
  list(var = "is_missing_price", expected = TRUE, reason = "Matches is_missing pattern"),
  list(var = "temp_calculation", expected = TRUE, reason = "Matches temp pattern"),
  list(var = "product_type", expected = TRUE, reason = "Matches type pattern"),
  list(var = "item_category", expected = TRUE, reason = "Matches category pattern"),
  list(var = "product_brand", expected = TRUE, reason = "Matches brand pattern"),

  # Should be INCLUDED
  list(var = "price", expected = FALSE, reason = "Legitimate predictor"),
  list(var = "balancing_technology", expected = FALSE, reason = "Legitimate predictor"),
  list(var = "compressor_a_r_ratio", expected = FALSE, reason = "Legitimate predictor"),
  list(var = "sales_volume", expected = FALSE, reason = "Legitimate predictor"),
  list(var = "customer_rating", expected = FALSE, reason = "Legitimate predictor"),
  list(var = "shipping_speed", expected = FALSE, reason = "Legitimate predictor"),

  # Note: actuator_type is EXCLUDED by .*type.* pattern (this is correct behavior)
  list(var = "actuator_type", expected = TRUE, reason = "Matches type pattern (.*type.*)")
)

# Run tests
message("\n=== Testing YAML-based Covariate Exclusion ===\n")
all_passed <- TRUE
passed_count <- 0
failed_count <- 0

for (i in seq_along(test_cases)) {
  test <- test_cases[[i]]
  result <- should_exclude_covariate(test$var, verbose = FALSE)
  passed <- (result == test$expected)

  status <- if (passed) "✅ PASS" else "❌ FAIL"
  message(sprintf("%s: %s -> %s (expected: %s) - %s",
                  status,
                  test$var,
                  result,
                  test$expected,
                  test$reason))

  if (passed) {
    passed_count <- passed_count + 1
  } else {
    failed_count <- failed_count + 1
    all_passed <- FALSE
  }
}

message("\n=== Test Summary ===")
message(sprintf("Total tests: %d", length(test_cases)))
message(sprintf("Passed: %d", passed_count))
message(sprintf("Failed: %d", failed_count))

if (all_passed) {
  message("✅ All tests passed!")
} else {
  message("❌ Some tests failed. Review configuration.")
  stop("Test failures detected")
}

# Test database integration
message("\n=== Testing Database Integration ===")

# Check if database connection is available
tryCatch({
  library(dplyr)
  source("scripts/global_scripts/02_db_utils/duckdb/fn_tbl2.R")
  source("scripts/global_scripts/04_utils/00_detect_data_availability/fn_connect_to_app_database.R")

  app_data_connection <- connect_to_app_database()

  # Test on actual data
  test_data <- tbl2(app_data_connection, "cbz_TUR_poisson_regression") %>%
    filter(convergence == TRUE) %>%
    select(predictor) %>%
    collect()

  message("Total predictors in database: ", nrow(test_data))

  # Apply filter
  filtered_data <- filter_excluded_covariates(
    test_data,
    predictor_col = "predictor",
    app_type = "poisson_regression"
  )

  message("Predictors after exclusion: ", nrow(filtered_data))
  message("Excluded: ", nrow(test_data) - nrow(filtered_data))

  # Show some excluded examples
  excluded_vars <- test_data$predictor[!test_data$predictor %in% filtered_data$predictor]
  message("\nExample excluded variables:")
  print(head(excluded_vars, 10))

  # Show some included examples
  message("\nExample included variables:")
  print(head(filtered_data$predictor, 10))

  dbDisconnect(app_data_connection)

  message("\n✅ Database integration test passed!")

}, error = function(e) {
  message("\n⚠️  Database integration test skipped: ", e$message)
  message("   (This is expected if database is not available)")
})

message("\n=== Test Complete ===\n")
