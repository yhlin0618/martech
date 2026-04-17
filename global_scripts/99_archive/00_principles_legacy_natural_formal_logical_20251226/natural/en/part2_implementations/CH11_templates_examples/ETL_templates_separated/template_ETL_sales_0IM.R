# Template: {platform}_ETL_sales_0IM.R - Sales Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 0IM (Import): Pure data extraction for sales transactions
# Template for creating platform-specific sales import scripts
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

message("INITIALIZE: ⚡ Starting {Platform} Sales ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
# Following principle: Use autoinit/autodeinit for consistent initialization
autoinit()

# Load required libraries for sales data import
message("INITIALIZE: 📦 Loading sales ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls
library(jsonlite)  # JSON handling
library(dplyr)     # Data manipulation
library(lubridate) # Date handling

# Platform-specific libraries (customize per platform)
# library(RCurl)   # For platforms requiring special HTTP handling
# library(XML)     # For XML-based APIs
# library(rvest)   # For web scraping if needed

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source sales-specific ETL functions
message("INITIALIZE: 📋 Loading sales ETL functions...")
source_start <- Sys.time()

# Data type-specific functions (customize per platform)
if (!exists("process_sales_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_process_sales_import.R"))
}
if (!exists("fetch_{platform}_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_fetch_{platform}_sales_data.R"))
}
if (!exists("validate_sales_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_sales_import.R"))
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

message("MAIN: 🚀 Starting sales data import processing...")
main_start_time <- Sys.time()

# Main execution function for sales import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch sales data from platform-specific source
    message("MAIN: 📥 Fetching sales data from {Platform} source...")
    fetch_start <- Sys.time()
    
    # Platform-specific data fetching (customize per platform)
    sales_raw_data <- fetch_{platform}_sales_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Sales data fetched (%d records, %.2fs)", 
                    nrow(sales_raw_data), fetch_elapsed))
    
    # Step 2: Apply sales-specific import processing
    message("MAIN: 🔄 Processing sales import data...")
    process_start <- Sys.time()
    
    sales_processed <- process_sales_import(sales_raw_data, platform_code = "{platform}")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Sales import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Apply MP102 standardization for sales data
    message("MAIN: 📋 Applying MP102 standardization...")
    standardize_start <- Sys.time()
    
    sales_standardized <- sales_processed %>%
      mutate(
        # Core fields (required by MP102)
        order_id = as.character(order_id),
        customer_id = as.character(customer_id),
        order_date = as.character(order_date),
        product_id = as.character(product_id),
        quantity = as.integer(quantity),
        unit_price = as.numeric(unit_price),
        total_amount = as.numeric(total_amount),
        platform_code = "{platform}",
        import_timestamp = Sys.time(),
        import_source = "API",  # or "FILE" depending on source
        
        # Platform-specific extensions (customize per platform)
        {platform}_specific_field1 = as.character({platform}_field1),
        {platform}_specific_field2 = as.numeric({platform}_field2)
        # Add more platform-specific fields as needed
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 4: Validate sales import output
    message("MAIN: ✔️  Validating sales import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_sales_import(sales_standardized, platform_code = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Sales import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 5: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing sales data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- sprintf("df_{platform}_sales___raw")
    write_etl_output(raw_data, table_name, sales_standardized, 
                     platform = "{platform}", datatype = "sales", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Sales data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(sales_standardized),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "{platform}",
      datatype = "sales",
      phase = "0IM"
    )
    
    message(sprintf("MAIN: 🎉 Sales import completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Sales import failed: %s", e$message))
    stop(sprintf("{Platform} Sales ETL 0IM failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting sales import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if sales table was created...")
    table_name <- sprintf("df_{platform}_sales___raw")
    
    if (!DBI::dbExistsTable(raw_data, table_name)) {
      stop(sprintf("Sales table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying sales record count...")
    record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Sales table is empty")
    }
    
    message(sprintf("TEST: ✅ Sales table contains %d records", record_count))
    
    # Test 3: Verify core schema compliance (MP102)
    message("TEST: 📋 Verifying MP102 core schema compliance...")
    table_info <- DBI::dbGetQuery(raw_data, sprintf("PRAGMA table_info(%s)", table_name))
    required_fields <- c("order_id", "customer_id", "order_date", "product_id", 
                         "quantity", "unit_price", "total_amount", "platform_code", 
                         "import_timestamp", "import_source")
    
    actual_fields <- table_info$name
    missing_fields <- setdiff(required_fields, actual_fields)
    
    if (length(missing_fields) > 0) {
      stop(sprintf("Missing required fields in sales table: %s", paste(missing_fields, collapse = ", ")))
    }
    
    message("TEST: ✅ All required core fields present")
    
    # Test 4: Verify platform_id consistency
    message("TEST: 🏷️  Verifying platform_id consistency...")
    platform_codes <- DBI::dbGetQuery(raw_data, 
      sprintf("SELECT DISTINCT platform_code FROM %s", table_name))$platform_code
    
    if (length(platform_codes) != 1 || platform_codes[1] != "{platform}") {
      stop(sprintf("Platform ID inconsistent. Expected: {platform}, Found: %s", 
                   paste(platform_codes, collapse = ", ")))
    }
    
    message(sprintf("TEST: ✅ Platform ID consistent: %s", platform_codes[1]))
    
    # Test 5: Verify data types
    message("TEST: 🔧 Verifying data types...")
    sample_data <- DBI::dbGetQuery(raw_data, sprintf("SELECT * FROM %s LIMIT 5", table_name))
    
    # Check for obvious data type issues
    if (any(is.na(sample_data$order_id))) {
      warning("Some order_id values are NA")
    }
    if (any(is.na(sample_data$customer_id))) {
      warning("Some customer_id values are NA") 
    }
    if (!is.numeric(sample_data$total_amount)) {
      warning("total_amount is not numeric")
    }
    
    message("TEST: ✅ Data type validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All sales import tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Sales import test failed: %s", e$message))
    return(FALSE)
  })
}

# Execute test function
test_result <- test_execution()

# ==============================================================================
# 4. RESULT
# ==============================================================================

script_end_time <- Sys.time()
total_elapsed <- as.numeric(script_end_time - script_start_time, units = "secs")

message("RESULT: 📊 Sales ETL Import (0IM) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ {Platform} Sales ETL Import (0IM) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("{Platform} Sales ETL Import (0IM) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()

# ==============================================================================
# TEMPLATE CUSTOMIZATION NOTES
# ==============================================================================

# To use this template for a specific platform:
# 
# 1. Replace all instances of "{platform}" with the actual 3-letter platform_id:
#    - {platform} -> cbz (for Cyberbiz)
#    - {platform} -> eby (for eBay) 
#    - {platform} -> amz (for Amazon)
#    - {Platform} -> Cyberbiz, eBay, Amazon (for display names)
#
# 2. Customize the data fetching function:
#    - Implement fetch_{platform}_sales_data() for your platform's API/file format
#    - Handle platform-specific authentication, pagination, rate limiting
#
# 3. Customize the processing function:
#    - Implement process_sales_import() for platform-specific data transformations
#    - Handle platform-specific data formats, encoding issues, field mappings
#
# 4. Add platform-specific fields:
#    - Replace {platform}_specific_field1, {platform}_specific_field2 with actual field names
#    - Add more platform-specific fields as needed following the naming pattern
#
# 5. Update library imports:
#    - Add any platform-specific libraries required for API access or data parsing
#
# 6. Customize validation rules:
#    - Implement validate_sales_import() for platform-specific validation logic
#    - Add business rules specific to the platform's data characteristics
#
# 7. Update file paths:
#    - Ensure ETL utility function paths match your platform's directory structure
#
# Example for Cyberbiz:
# - File name: cbz_ETL_sales_0IM.R
# - Function: fetch_cbz_sales_data()
# - Fields: cbz_shop_id, cbz_payment_id, cbz_member_level
# - Table: df_cbz_sales___raw