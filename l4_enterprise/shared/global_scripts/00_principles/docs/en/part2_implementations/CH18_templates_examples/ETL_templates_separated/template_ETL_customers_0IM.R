# Template: {platform}_ETL_customers_0IM.R - Customer Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Customer Pipeline Phase 0IM (Import): Pure data extraction for customer profiles
# Template for creating platform-specific customer import scripts
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

message("INITIALIZE: ⚡ Starting {Platform} Customer ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for customer data import
message("INITIALIZE: 📦 Loading customer ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls
library(jsonlite)  # JSON handling  
library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing for customer data

# Platform-specific libraries (customize per platform)
# library(RCurl)   # For platforms requiring special HTTP handling
# library(XML)     # For XML-based APIs

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source customer-specific ETL functions
message("INITIALIZE: 📋 Loading customer ETL functions...")
source_start <- Sys.time()

# Data type-specific functions (customize per platform)
if (!exists("process_customers_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_process_customers_import.R"))
}
if (!exists("fetch_{platform}_customers_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_fetch_{platform}_customers_data.R"))
}
if (!exists("validate_customers_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_customers_import.R"))
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

# Establish database connections
message("INITIALIZE: 🔗 Connecting to raw_data database...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connection established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting customer data import processing...")
main_start_time <- Sys.time()

# Main execution function for customer import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch customer data from platform-specific source
    message("MAIN: 📥 Fetching customer data from {Platform} source...")
    fetch_start <- Sys.time()
    
    # Platform-specific data fetching (customize per platform)
    customers_raw_data <- fetch_{platform}_customers_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Customer data fetched (%d records, %.2fs)", 
                    nrow(customers_raw_data), fetch_elapsed))
    
    # Step 2: Apply customer-specific import processing  
    message("MAIN: 🔄 Processing customer import data...")
    process_start <- Sys.time()
    
    customers_processed <- process_customers_import(customers_raw_data, platform_id = "{platform}")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Customer import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Apply MP102 standardization for customer data
    message("MAIN: 📋 Applying MP102 standardization...")
    standardize_start <- Sys.time()
    
    customers_standardized <- customers_processed %>%
      mutate(
        # Core fields (required by MP102)
        customer_id = as.character(customer_id),
        customer_email = as.character(customer_email),
        customer_name = as.character(customer_name),
        registration_date = as.character(registration_date),
        platform_id = "{platform}",
        import_timestamp = Sys.time(),
        import_source = "API",  # or "FILE" depending on source
        
        # Platform-specific extensions (customize per platform)
        {platform}_member_level = as.character({platform}_member_level),
        {platform}_customer_group = as.character({platform}_customer_group),
        {platform}_loyalty_points = as.numeric({platform}_loyalty_points),
        {platform}_marketing_consent = as.logical({platform}_marketing_consent)
        # Add more platform-specific fields as needed
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 4: Validate customer import output
    message("MAIN: ✔️  Validating customer import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_customers_import(customers_standardized, platform_id = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Customer import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 5: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing customer data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- sprintf("df_{platform}_customers___raw")
    write_etl_output(raw_data, table_name, customers_standardized,
                     platform = "{platform}", datatype = "customers", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Customer data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(customers_standardized),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "{platform}",
      datatype = "customers",
      phase = "0IM"
    )
    
    message(sprintf("MAIN: 🎉 Customer import completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Customer import failed: %s", e$message))
    stop(sprintf("{Platform} Customer ETL 0IM failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting customer import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if customer table was created...")
    table_name <- sprintf("df_{platform}_customers___raw")
    
    if (!DBI::dbExistsTable(raw_data, table_name)) {
      stop(sprintf("Customer table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying customer record count...")
    record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Customer table is empty")
    }
    
    message(sprintf("TEST: ✅ Customer table contains %d records", record_count))
    
    # Test 3: Verify core schema compliance (MP102)
    message("TEST: 📋 Verifying MP102 core schema compliance...")
    table_info <- DBI::dbGetQuery(raw_data, sprintf("PRAGMA table_info(%s)", table_name))
    required_fields <- c("customer_id", "customer_email", "customer_name", "registration_date",
                         "platform_id", "import_timestamp")
    
    actual_fields <- table_info$name
    missing_fields <- setdiff(required_fields, actual_fields)
    
    if (length(missing_fields) > 0) {
      stop(sprintf("Missing required fields in customer table: %s", paste(missing_fields, collapse = ", ")))
    }
    
    message("TEST: ✅ All required core fields present")
    
    # Test 4: Verify platform_id consistency
    message("TEST: 🏷️  Verifying platform_id consistency...")
    platform_ids <- DBI::dbGetQuery(raw_data,
      sprintf("SELECT DISTINCT platform_id FROM %s", table_name))$platform_id
    
    if (length(platform_ids) != 1 || platform_ids[1] != "{platform}") {
      stop(sprintf("Platform ID inconsistent. Expected: {platform}, Found: %s", 
                   paste(platform_ids, collapse = ", ")))
    }
    
    message(sprintf("TEST: ✅ Platform ID consistent: %s", platform_ids[1]))
    
    # Test 5: Verify email format (basic validation)
    message("TEST: 📧 Verifying customer email formats...")
    sample_emails <- DBI::dbGetQuery(raw_data, 
      sprintf("SELECT customer_email FROM %s WHERE customer_email IS NOT NULL LIMIT 10", table_name))$customer_email
    
    invalid_emails <- sample_emails[!grepl("@", sample_emails)]
    if (length(invalid_emails) > 0) {
      warning(sprintf("Found %d potentially invalid email addresses", length(invalid_emails)))
    }
    
    message("TEST: ✅ Email format validation completed")
    
    # Test 6: Check for duplicate customer IDs
    message("TEST: 🔍 Checking for duplicate customer IDs...")
    duplicate_check <- DBI::dbGetQuery(raw_data, sprintf(
      "SELECT customer_id, COUNT(*) as count FROM %s GROUP BY customer_id HAVING COUNT(*) > 1 LIMIT 5", 
      table_name))
    
    if (nrow(duplicate_check) > 0) {
      warning(sprintf("Found %d duplicate customer IDs", nrow(duplicate_check)))
    }
    
    message("TEST: ✅ Duplicate check completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All customer import tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Customer import test failed: %s", e$message))
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

message("RESULT: 📊 Customer ETL Import (0IM) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ {Platform} Customer ETL Import (0IM) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("{Platform} Customer ETL Import (0IM) failed. Script success: %s, Test passed: %s", 
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
#    - Implement fetch_{platform}_customers_data() for your platform's API/file format
#    - Handle platform-specific authentication, customer data endpoints
#
# 3. Customize the processing function:
#    - Implement process_customers_import() for platform-specific data transformations
#    - Handle customer-specific data formats, privacy considerations, field mappings
#
# 4. Add platform-specific fields:
#    - Replace {platform}_member_level, {platform}_customer_group with actual field names
#    - Add customer-specific fields like loyalty programs, preferences, demographics
#
# 5. Update validation rules:
#    - Implement validate_customers_import() for customer-specific validation logic
#    - Add privacy compliance checks, email format validation, required field checks
#
# 6. Consider privacy and compliance:
#    - Ensure compliance with GDPR, CCPA, and other privacy regulations
#    - Implement data anonymization if required
#    - Add consent tracking fields if needed
#
# Example for Cyberbiz:
# - File name: cbz_ETL_customers_0IM.R
# - Function: fetch_cbz_customers_data()
# - Fields: cbz_member_level, cbz_vip_status, cbz_referral_source
# - Table: df_cbz_customers___raw