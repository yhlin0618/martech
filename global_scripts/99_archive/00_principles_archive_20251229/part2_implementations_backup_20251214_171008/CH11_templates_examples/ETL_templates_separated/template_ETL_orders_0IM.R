# Template: {platform}_ETL_orders_0IM.R - Orders Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Orders Pipeline Phase 0IM (Import): Pure data extraction for order headers
# Template for creating platform-specific order import scripts
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

message("INITIALIZE: ⚡ Starting {Platform} Orders ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for orders data import
message("INITIALIZE: 📦 Loading orders ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls
library(jsonlite)  # JSON handling
library(dplyr)     # Data manipulation
library(lubridate) # Date handling

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source orders-specific ETL functions
message("INITIALIZE: 📋 Loading orders ETL functions...")
source_start <- Sys.time()

# Data type-specific functions (customize per platform)
if (!exists("process_orders_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_process_orders_import.R"))
}
if (!exists("fetch_{platform}_orders_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_fetch_{platform}_orders_data.R"))
}
if (!exists("validate_orders_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_orders_import.R"))
}

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("write_etl_output", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "output", "fn_write_etl_output.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections using dbConnectDuckdb
message("INITIALIZE: 🔗 Connecting to raw_data database...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connection established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting orders data import processing...")
main_start_time <- Sys.time()

# Main execution function for orders import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch orders data from platform-specific source
    message("MAIN: 📥 Fetching orders data from {Platform} source...")
    fetch_start <- Sys.time()
    
    # Platform-specific data fetching (customize per platform)
    orders_raw_data <- fetch_{platform}_orders_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Orders data fetched (%d records, %.2fs)", 
                    nrow(orders_raw_data), fetch_elapsed))
    
    # Step 2: Apply orders-specific import processing
    message("MAIN: 🔄 Processing orders import data...")
    process_start <- Sys.time()
    
    orders_processed <- process_orders_import(orders_raw_data, platform_code = "{platform}")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Orders import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Apply MP102 standardization for orders data
    message("MAIN: 📋 Applying MP102 standardization...")
    standardize_start <- Sys.time()
    
    orders_standardized <- orders_processed %>%
      mutate(
        # Core fields (MP102 standard - adapt for orders)
        order_id = as.character(order_id),
        customer_id = as.character(customer_id),
        order_date = as.character(order_date),
        order_status = as.character(order_status),
        total_amount = as.numeric(total_amount),
        shipping_amount = as.numeric(shipping_amount),
        tax_amount = as.numeric(tax_amount),
        discount_amount = as.numeric(discount_amount),
        payment_method = as.character(payment_method),
        shipping_address = as.character(shipping_address),
        platform_code = "{platform}",
        import_timestamp = Sys.time(),
        import_source = "API",  # or "FILE" depending on source
        
        # Platform-specific extensions (customize per platform)
        {platform}_order_type = as.character({platform}_order_type),
        {platform}_priority = as.character({platform}_priority),
        {platform}_channel = as.character({platform}_channel)
        # Add more platform-specific fields as needed
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 4: Validate orders import output
    message("MAIN: ✔️  Validating orders import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_orders_import(orders_standardized, platform_code = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Orders import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 5: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing orders data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- sprintf("df_{platform}_orders___raw")
    write_etl_output(raw_data, table_name, orders_standardized, 
                     platform = "{platform}", datatype = "orders", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Orders data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return success result
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    result <- list(
      success = TRUE,
      records_processed = nrow(orders_standardized),
      output_table = table_name,
      execution_time = main_elapsed
    )
    
    message(sprintf("MAIN: 🎉 Orders import completed successfully (%d records, %.2fs total)", 
                    result$records_processed, result$execution_time))
    
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Orders import failed: %s", e$message))
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

message("TEST: 🧪 Running orders import tests...")
test_start_time <- Sys.time()

# Test execution function
test_execution <- function() {
  
  if (!script_success) {
    return(list(passed = FALSE, message = sprintf("Main execution failed: %s", main_error)))
  }
  
  # Test 1: Verify output table exists
  table_name <- sprintf("df_{platform}_orders___raw")
  if (!dbExistsTable(raw_data, table_name)) {
    return(list(passed = FALSE, message = sprintf("Output table %s does not exist", table_name)))
  }
  
  # Test 2: Verify record count > 0
  record_count <- dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
  if (record_count == 0) {
    return(list(passed = FALSE, message = "No records in imported output"))
  }
  
  # Test 3: Verify core fields exist
  imported_fields <- dbListFields(raw_data, table_name)
  required_fields <- c("order_id", "customer_id", "order_status", "total_amount", "platform_code", "import_timestamp")
  missing_fields <- setdiff(required_fields, imported_fields)
  if (length(missing_fields) > 0) {
    return(list(passed = FALSE, message = sprintf("Missing required fields: %s", paste(missing_fields, collapse = ", "))))
  }
  
  # Test 4: Verify platform_id consistency
  platform_check <- dbGetQuery(raw_data, sprintf("SELECT DISTINCT platform_code FROM %s", table_name))
  if (nrow(platform_check) != 1 || platform_check$platform_code[1] != "{platform}") {
    return(list(passed = FALSE, message = "Platform ID inconsistency detected"))
  }
  
  # Test 5: Verify import timestamp is recent
  timestamp_check <- dbGetQuery(raw_data, sprintf("SELECT MAX(import_timestamp) as latest FROM %s", table_name))
  time_diff <- as.numeric(Sys.time() - as.POSIXct(timestamp_check$latest), units = "mins")
  if (time_diff > 60) {  # More than 1 hour old
    return(list(passed = FALSE, message = "Import timestamp is not recent"))
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
  message(sprintf("RESULT: 🎉 {Platform} Orders ETL Import completed successfully (%.2fs total)", total_elapsed))
  message(sprintf("RESULT: 📊 Output: df_{platform}_orders___raw"))
} else {
  error_msg <- ifelse(!script_success, main_error, test_result$message)
  message(sprintf("RESULT: ❌ {Platform} Orders ETL Import failed: %s (%.2fs total)", error_msg, total_elapsed))
  stop(sprintf("{Platform} Orders ETL Import (0IM) failed: %s", error_msg))
}

# Cleanup and autodeinit
autodeinit()