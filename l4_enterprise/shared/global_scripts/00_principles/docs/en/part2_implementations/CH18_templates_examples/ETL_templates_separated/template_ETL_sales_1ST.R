# Template: {platform}_ETL_sales_1ST.R - Sales Data Staging Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 1ST (Staging): Data cleaning and standardization
# Template for creating platform-specific sales staging scripts
#
# USAGE: Copy this template and replace {platform} with actual platform_id (cbz, eby, amz, etc.)
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting {Platform} Sales ETL Staging Phase (1ST)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for sales data staging
message("INITIALIZE: 📦 Loading sales staging libraries...")
lib_start <- Sys.time()

# Standard staging libraries
library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String manipulation
library(tidyr)     # Data tidying

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source sales-specific staging functions
message("INITIALIZE: 📋 Loading sales staging functions...")
source_start <- Sys.time()

# Data type-specific staging functions (customize per platform)
if (!exists("stage_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "stage", "fn_stage_sales_data.R"))
}
if (!exists("clean_sales_encoding", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "stage", "fn_clean_sales_encoding.R"))
}
if (!exists("validate_sales_staging", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_sales_staging.R"))
}

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to databases...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = TRUE)
staged_data <- dbConnectDuckdb(db_path_list$staged_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connections established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting sales data staging processing...")
main_start_time <- Sys.time()

# Main execution function for sales staging
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read sales data from raw_data
    message("MAIN: 📥 Reading sales data from raw_data...")
    read_start <- Sys.time()
    
    raw_table_name <- sprintf("df_{platform}_sales___raw")
    sales_raw <- tbl2(raw_data, raw_table_name) %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Sales raw data read (%d records, %.2fs)", 
                    nrow(sales_raw), read_elapsed))
    
    # Step 2: Apply encoding standardization
    message("MAIN: 🔄 Standardizing encoding...")
    encoding_start <- Sys.time()
    
    sales_encoded <- clean_sales_encoding(sales_raw)
    
    encoding_elapsed <- as.numeric(Sys.time() - encoding_start, units = "secs")
    message(sprintf("MAIN: ✅ Encoding standardization completed (%.2fs)", encoding_elapsed))
    
    # Step 3: Apply staging transformations
    message("MAIN: 🔧 Applying staging transformations...")
    staging_start <- Sys.time()
    
    sales_staged <- stage_sales_data(sales_encoded, platform_id = "{platform}")
    
    staging_elapsed <- as.numeric(Sys.time() - staging_start, units = "secs")
    message(sprintf("MAIN: ✅ Staging transformations completed (%.2fs)", staging_elapsed))
    
    # Step 4: Date and time parsing
    message("MAIN: 📅 Parsing dates and timestamps...")
    date_start <- Sys.time()
    
    sales_dated <- sales_staged %>%
      mutate(
        # Parse order_date string to proper date
        order_date_parsed = case_when(
          !is.na(order_date) & order_date != "" ~ lubridate::ymd_hms(order_date, quiet = TRUE),
          TRUE ~ as.POSIXct(NA)
        ),
        # Update staging metadata
        staging_timestamp = Sys.time(),
        staging_source = "1ST_pipeline"
      )
    
    date_elapsed <- as.numeric(Sys.time() - date_start, units = "secs")
    message(sprintf("MAIN: ✅ Date parsing completed (%.2fs)", date_elapsed))
    
    # Step 5: Validate staging output
    message("MAIN: ✔️  Validating staging output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_sales_staging(sales_dated, platform_id = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Sales staging validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to staged_data database
    message("MAIN: 💾 Writing staged sales data to database...")
    write_start <- Sys.time()
    
    staged_table_name <- sprintf("df_{platform}_sales___staged")
    dbWriteTable(staged_data, staged_table_name, sales_dated, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Staged data written to %s (%.2fs)", staged_table_name, write_elapsed))
    
    # Return success result
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    result <- list(
      success = TRUE,
      records_processed = nrow(sales_dated),
      output_table = staged_table_name,
      execution_time = main_elapsed
    )
    
    message(sprintf("MAIN: 🎉 Sales staging completed successfully (%d records, %.2fs total)", 
                    result$records_processed, result$execution_time))
    
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Sales staging failed: %s", e$message))
    stop(e$message)
  })
}

# Execute main function
tryCatch({
  result <- main_execution()
  script_success <- TRUE
  
}, error = function(e) {
  main_error <- e$message
  message(sprintf("EXECUTION: ❌ Script failed: %s", e$message))
})

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Running sales staging tests...")
test_start_time <- Sys.time()

# Test execution function
test_execution <- function() {
  
  if (!script_success) {
    return(list(passed = FALSE, message = sprintf("Main execution failed: %s", main_error)))
  }
  
  # Test 1: Verify output table exists
  staged_table_name <- sprintf("df_{platform}_sales___staged")
  if (!dbExistsTable(staged_data, staged_table_name)) {
    return(list(passed = FALSE, message = sprintf("Output table %s does not exist", staged_table_name)))
  }
  
  # Test 2: Verify record count > 0
  record_count <- dbGetQuery(staged_data, sprintf("SELECT COUNT(*) as count FROM %s", staged_table_name))$count
  if (record_count == 0) {
    return(list(passed = FALSE, message = "No records in staged output"))
  }
  
  # Test 3: Verify core fields exist
  staged_fields <- dbListFields(staged_data, staged_table_name)
  required_fields <- c("order_id", "customer_id", "product_id", "platform_id", "staging_timestamp")
  missing_fields <- setdiff(required_fields, staged_fields)
  if (length(missing_fields) > 0) {
    return(list(passed = FALSE, message = sprintf("Missing required fields: %s", paste(missing_fields, collapse = ", "))))
  }
  
  # Test 4: Verify platform_id consistency
  platform_check <- dbGetQuery(staged_data, sprintf("SELECT DISTINCT platform_id FROM %s", staged_table_name))
  if (nrow(platform_check) != 1 || platform_check$platform_id[1] != "{platform}") {
    return(list(passed = FALSE, message = "Platform ID inconsistency detected"))
  }
  
  return(list(passed = TRUE, message = "All tests passed"))
}

# Execute tests
test_result <- test_execution()
test_passed <- test_result$passed
test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")

if (test_passed) {
  message(sprintf("TEST: ✅ All tests passed (%.2fs)", test_elapsed))
} else {
  message(sprintf("TEST: ❌ Tests failed: %s (%.2fs)", test_result$message, test_elapsed))
}

# ==============================================================================
# 4. RESULT
# ==============================================================================

script_end_time <- Sys.time()
total_elapsed <- as.numeric(script_end_time - script_start_time, units = "secs")

if (test_passed && script_success) {
  message(sprintf("RESULT: 🎉 {Platform} Sales ETL Staging completed successfully (%.2fs total)", total_elapsed))
  message(sprintf("RESULT: 📊 Output: df_{platform}_sales___staged"))
} else {
  error_msg <- ifelse(!script_success, main_error, test_result$message)
  message(sprintf("RESULT: ❌ {Platform} Sales ETL Staging failed: %s (%.2fs total)", error_msg, total_elapsed))
  stop(sprintf("{Platform} Sales ETL Staging (1ST) failed: %s", error_msg))
}

# Cleanup and autodeinit
autodeinit()