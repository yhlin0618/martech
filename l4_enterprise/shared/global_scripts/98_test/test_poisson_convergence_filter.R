# Integration Test: Poisson Component Convergence Filter
# Prevents regression of convergence boolean vs string bug

# Test both IF and ELSE paths in analysis_data() reactive

library(testthat)
library(DBI)
library(duckdb)
library(dplyr)

# Initialize app environment
if (file.exists(".Rprofile")) {
  source(".Rprofile")
}
autoinit()

test_that("Database convergence column is boolean type", {
  # Connect to database
  db_path <- file.path("data", "app_data", "app_data.duckdb")
  con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

  # Get sample data
  table_name <- "df_cbz_poisson_analysis_all"
  sample <- dbGetQuery(con, paste0("SELECT * FROM ", table_name, " LIMIT 1"))

  # Test: convergence must be boolean
  expect_true("convergence" %in% names(sample), "convergence column must exist")
  expect_true(is.logical(sample$convergence), "convergence must be boolean type")

  dbDisconnect(con, shutdown = TRUE)
})

test_that("tbl2 filter with convergence == TRUE returns data", {
  # Connect to database
  db_path <- file.path("data", "app_data", "app_data.duckdb")
  con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

  table_name <- "df_cbz_poisson_analysis_all"

  # Test: Filter with boolean TRUE
  data <- tbl2(con, table_name) %>%
    filter((is.na(predictor_type) | predictor_type != "time_feature") &
           convergence == TRUE) %>%
    collect()

  # Verify results
  expect_gt(nrow(data), 0, "Must return at least one row")
  expect_true("coefficient" %in% names(data), "Must have coefficient column")
  expect_true("p_value" %in% names(data), "Must have p_value column")

  dbDisconnect(con, shutdown = TRUE)
})

test_that("tbl2 filter with convergence == 'converged' returns zero rows", {
  # This test documents the BUG behavior
  # If this test FAILS (returns > 0 rows), the database schema has changed

  db_path <- file.path("data", "app_data", "app_data.duckdb")
  con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

  table_name <- "df_cbz_poisson_analysis_all"

  # Test: Filter with string "converged" (WRONG)
  tryCatch({
    data <- tbl2(con, table_name) %>%
      filter(convergence == "converged") %>%
      collect()

    # Expect ZERO rows because convergence is boolean, not string
    expect_equal(nrow(data), 0,
                 "String comparison with boolean should return zero rows")
  }, error = function(e) {
    # If error occurs, it's also acceptable (type mismatch)
    expect_true(TRUE, "Type mismatch error is expected")
  })

  dbDisconnect(con, shutdown = TRUE)
})

test_that("positive_data filter works on analysis_data output", {
  # Simulate the reactive chain: analysis_data() -> positive_data()

  db_path <- file.path("data", "app_data", "app_data.duckdb")
  con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

  table_name <- "df_cbz_poisson_analysis_all"

  # Step 1: Simulate analysis_data()
  analysis_data <- tbl2(con, table_name) %>%
    filter((is.na(predictor_type) | predictor_type != "time_feature") &
           convergence == TRUE) %>%
    collect()

  expect_gt(nrow(analysis_data), 0, "analysis_data must return rows")

  # Step 2: Simulate positive_data() filter
  positive_data <- analysis_data %>%
    filter(!is.na(coefficient) & !is.na(p_value) &
           !grepl("rating", predictor, ignore.case = TRUE) &
           abs(coefficient) <= 10)

  # Verify: positive_data should work without errors
  expect_true(is.data.frame(positive_data), "Must return a dataframe")
  expect_true("coefficient" %in% names(positive_data), "Must preserve coefficient column")

  # If we got here, the filter chain works correctly
  cat("✅ Reactive chain test passed\n")
  cat("   analysis_data rows:", nrow(analysis_data), "\n")
  cat("   positive_data rows:", nrow(positive_data), "\n")

  dbDisconnect(con, shutdown = TRUE)
})

test_that("All Poisson tables have boolean convergence", {
  db_path <- file.path("data", "app_data", "app_data.duckdb")
  con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

  # List all Poisson tables
  tables <- dbListTables(con)
  poisson_tables <- tables[grepl("poisson_analysis", tables)]

  for (table in poisson_tables) {
    # Check if convergence exists and is boolean
    sample <- dbGetQuery(con, paste0("SELECT * FROM ", table, " LIMIT 1"))

    if ("convergence" %in% names(sample)) {
      expect_true(is.logical(sample$convergence),
                  info = paste(table, "convergence must be boolean"))
    }
  }

  dbDisconnect(con, shutdown = TRUE)
})

# Run tests
test_results <- test_file(
  path = "scripts/global_scripts/98_test/test_poisson_convergence_filter.R",
  reporter = "summary"
)

if (any(test_results$failed > 0)) {
  stop("❌ Tests failed! Check convergence filter implementation.")
} else {
  cat("✅ All convergence filter tests passed!\n")
}
