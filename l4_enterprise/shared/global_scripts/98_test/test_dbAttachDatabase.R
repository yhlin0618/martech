# Test script for dbAttachDatabase functionality
# This script follows the R113 four-part script structure

# 1. INITIALIZE
# Load required packages
library(DBI)
library(duckdb)

# Source the db_utils module which includes our database functions
source("../02_db_utils/db_utils.R")

# Define test databases
test_main_db_name <- "test_main_db"
test_second_db_name <- "test_second_db"

# Create temporary test databases in the current directory
test_path_list <- list(
  test_main_db = file.path(tempdir(), "test_main_db.duckdb"),
  test_second_db = file.path(tempdir(), "test_second_db.duckdb")
)

# 2. MAIN
# Test 1: Connect to main database and attach second database
cat("\n=== Test 1: Connect and attach database ===\n")
connection <- tryCatch({
  dbAttachDatabase(test_main_db_name, test_second_db_name, 
                 path_list = test_path_list,
                 verbose = TRUE)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(connection)) {
  cat("Successfully connected to main database and attached second database\n")
  
  # Create test table in main database
  dbExecute(connection$con, "CREATE TABLE main_table (id INTEGER, name VARCHAR)")
  
  # Create test table in attached database
  dbExecute(connection$con, "CREATE TABLE second_db.second_table (id INTEGER, value DOUBLE)")
  
  # Insert test data
  dbExecute(connection$con, "INSERT INTO main_table VALUES (1, 'Test1'), (2, 'Test2')")
  dbExecute(connection$con, "INSERT INTO second_db.second_table VALUES (1, 10.5), (2, 20.75)")
  
  # Test querying from both databases
  cat("\nData from main database:\n")
  print(dbGetQuery(connection$con, "SELECT * FROM main_table"))
  
  cat("\nData from attached database:\n")
  print(dbGetQuery(connection$con, "SELECT * FROM second_db.second_table"))
  
  # Test joining tables across databases
  cat("\nJoined data from both databases:\n")
  print(dbGetQuery(connection$con, 
          "SELECT m.id, m.name, s.value 
           FROM main_table m 
           JOIN second_db.second_table s ON m.id = s.id"))
  
  # Test 2: Detach database and disconnect
  cat("\n=== Test 2: Detach database and disconnect ===\n")
  detach_result <- dbDetachDatabase(connection)
  
  if (detach_result) {
    cat("Successfully detached second database and disconnected from main database\n")
  } else {
    cat("Error detaching database or disconnecting\n")
  }
}

# Test 3: Error handling with non-existent database
cat("\n=== Test 3: Error handling with non-existent database ===\n")
bad_path_list <- list(
  test_main_db = file.path(tempdir(), "test_main_db.duckdb"),
  nonexistent_db = "/path/that/does/not/exist/nonexistent.duckdb"
)

error_test <- tryCatch({
  dbAttachDatabase("test_main_db", "nonexistent_db", 
                 path_list = bad_path_list,
                 verbose = TRUE)
  TRUE
}, error = function(e) {
  cat("Expected error caught:", e$message, "\n")
  cat("Error handling works as expected\n")
  FALSE
})

if (error_test) {
  cat("TEST FAILED: Error was not caught properly\n")
  # Make sure to clean up
  if (exists("test_main_db", envir = .GlobalEnv)) {
    dbDisconnect(test_main_db, shutdown = TRUE)
    rm(test_main_db, envir = .GlobalEnv)
  }
}

# 3. TEST
# Define test status based on results
if (exists("test_main_db", envir = .GlobalEnv)) {
  test_passed <- FALSE
  cat("\nTEST FAILED: Database connections were not properly closed\n")
} else if (error_test) {
  test_passed <- FALSE
  cat("\nTEST FAILED: Error handling did not work as expected\n")
} else {
  test_passed <- TRUE
  cat("\nTEST PASSED: All tests completed successfully\n")
}

# 4. DEINITIALIZE
# First set final status
final_status <- test_passed

# Clean up test databases
if (file.exists(test_path_list$test_main_db)) {
  file.remove(test_path_list$test_main_db)
}
if (file.exists(test_path_list$test_second_db)) {
  file.remove(test_path_list$test_second_db)
}

cat("\nTest script execution completed\n")