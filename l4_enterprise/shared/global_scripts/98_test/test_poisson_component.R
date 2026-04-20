# Test Poisson Component Diagnosis
# This script tests if the component can access the database correctly

# Simulating app initialization
if (file.exists(".Rprofile")) {
  source(".Rprofile")
}
autoinit()

library(dplyr)
library(DBI)
library(duckdb)

# Check if tbl2 is loaded
cat("=== tbl2 FUNCTION CHECK ===\n")
cat("tbl2 exists:", exists("tbl2"), "\n")
if (exists("tbl2")) {
  cat("tbl2 is a function:", is.function(tbl2), "\n")
}

# Get database connection
cat("\n=== DATABASE CONNECTION ===\n")
db_path <- file.path("data", "app_data", "app_data.duckdb")
cat("Database path:", db_path, "\n")
cat("File exists:", file.exists(db_path), "\n")

app_data_connection <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
cat("Connection class:", class(app_data_connection), "\n")

# Test tbl2 with connection
cat("\n=== TESTING tbl2() WITH DATABASE ===\n")
table_name <- "df_cbz_poisson_analysis_all"

tryCatch({
  # Test 1: Basic tbl2 query
  cat("Test 1: Basic tbl2 query\n")
  result1 <- tbl2(app_data_connection, table_name)
  cat("  ✓ tbl2 query succeeded\n")
  cat("  Result class:", class(result1), "\n")

  # Test 2: With filter and collect
  cat("\nTest 2: Filter and collect\n")
  result2 <- tbl2(app_data_connection, table_name) %>%
    filter((is.na(predictor_type) | predictor_type != "time_feature") &
           convergence == TRUE) %>%
    collect()
  cat("  ✓ Filter and collect succeeded\n")
  cat("  Rows:", nrow(result2), "\n")
  cat("  Columns:", ncol(result2), "\n")
  cat("  Column names:\n")
  print(names(result2))
  cat("\n  Has 'coefficient' column:", "coefficient" %in% names(result2), "\n")

  # Test 3: The problematic filter from positive_data
  cat("\nTest 3: Positive data filter\n")
  result3 <- result2 %>%
    filter(!is.na(coefficient) & !is.na(p_value) &
           !grepl("rating", predictor, ignore.case = TRUE) &
           abs(coefficient) <= 10)
  cat("  ✓ Positive data filter succeeded\n")
  cat("  Filtered rows:", nrow(result3), "\n")

  cat("\n🎉 ALL TESTS PASSED!\n")
  cat("\nConclusion: The database, tbl2, and filters work correctly.\n")
  cat("Issue must be in the component's reactive context or data flow.\n")

}, error = function(e) {
  cat("\n❌ ERROR:\n")
  cat(e$message, "\n")
  cat("\nThis indicates the actual problem location.\n")
})

# Cleanup
dbDisconnect(app_data_connection, shutdown = TRUE)
cat("\n=== TEST COMPLETE ===\n")
