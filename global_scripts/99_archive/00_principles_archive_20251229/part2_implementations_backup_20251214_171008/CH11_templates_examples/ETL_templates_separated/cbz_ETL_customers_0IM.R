# cbz_ETL_customers_0IM.R - Cyberbiz Customer Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Customer Pipeline Phase 0IM (Import): Pure data extraction for customer profiles
# Cyberbiz-specific customer import implementation
#
# Cyberbiz API Integration: Handles member profiles with VIP tiers and loyalty data
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Cyberbiz Customer ETL Import Phase (0IM)")
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

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source customer-specific ETL functions
message("INITIALIZE: 📋 Loading customer ETL functions...")
source_start <- Sys.time()

# Cyberbiz customer-specific functions
if (!exists("process_customers_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "cbz", "import", "fn_process_customers_import.R"))
}
if (!exists("fetch_cbz_customers_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "cbz", "import", "fn_fetch_cbz_customers_data.R"))
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

message("MAIN: 🚀 Starting Cyberbiz customer data import processing...")
main_start_time <- Sys.time()

# Main execution function for Cyberbiz customer import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch customer data from Cyberbiz API
    message("MAIN: 📥 Fetching customer data from Cyberbiz API...")
    fetch_start <- Sys.time()
    
    # Cyberbiz-specific customer data fetching
    customers_raw_data <- fetch_cbz_customers_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz customer data fetched (%d records, %.2fs)", 
                    nrow(customers_raw_data), fetch_elapsed))
    
    # Step 2: Apply customer-specific import processing  
    message("MAIN: 🔄 Processing Cyberbiz customer import data...")
    process_start <- Sys.time()
    
    customers_processed <- process_customers_import(customers_raw_data, platform_code = "cbz")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz customer import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Apply MP102 standardization for Cyberbiz customer data
    message("MAIN: 📋 Applying MP102 standardization for Cyberbiz...")
    standardize_start <- Sys.time()
    
    customers_standardized <- customers_processed %>%
      mutate(
        # Core fields (required by MP102)
        customer_id = as.character(customer_id),
        customer_email = as.character(customer_email),
        customer_name = as.character(customer_name),
        registration_date = as.character(registration_date),
        platform_code = "cbz",
        import_timestamp = Sys.time(),
        import_source = "API",
        
        # Cyberbiz-specific extensions (preserving unique customer data)
        cbz_member_level = as.character(member_tier),
        cbz_vip_status = as.character(vip_level),
        cbz_loyalty_points = as.numeric(total_points),
        cbz_referral_source = as.character(referral_channel),
        cbz_marketing_consent = as.logical(email_opt_in),
        cbz_phone_number = as.character(phone),
        cbz_birth_month = as.character(birth_month),
        cbz_gender = as.character(gender_code),
        cbz_last_login = as.character(last_login_date),
        cbz_registration_store = as.character(registration_store_id)
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 4: Validate customer import output
    message("MAIN: ✔️  Validating Cyberbiz customer import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_customers_import(customers_standardized, platform_code = "cbz")
    
    if (!validation_result$valid) {
      stop(sprintf("Cyberbiz customer import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 5: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing Cyberbiz customer data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- "df_cbz_customers___raw"
    write_etl_output(raw_data, table_name, customers_standardized,
                     platform = "cbz", datatype = "customers", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz customer data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(customers_standardized),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "cbz",
      datatype = "customers",
      phase = "0IM"
    )
    
    message(sprintf("MAIN: 🎉 Cyberbiz customer import completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Cyberbiz customer import failed: %s", e$message))
    stop(sprintf("Cyberbiz Customer ETL 0IM failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Cyberbiz customer import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if Cyberbiz customer table was created...")
    table_name <- "df_cbz_customers___raw"
    
    if (!DBI::dbExistsTable(raw_data, table_name)) {
      stop(sprintf("Cyberbiz customer table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying Cyberbiz customer record count...")
    record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Cyberbiz customer table is empty")
    }
    
    message(sprintf("TEST: ✅ Cyberbiz customer table contains %d records", record_count))
    
    # Test 3: Verify core schema compliance (MP102)
    message("TEST: 📋 Verifying MP102 core schema compliance...")
    table_info <- DBI::dbGetQuery(raw_data, sprintf("PRAGMA table_info(%s)", table_name))
    required_fields <- c("customer_id", "customer_email", "customer_name", "registration_date",
                         "platform_code", "import_timestamp")
    
    actual_fields <- table_info$name
    missing_fields <- setdiff(required_fields, actual_fields)
    
    if (length(missing_fields) > 0) {
      stop(sprintf("Missing required fields in Cyberbiz customer table: %s", paste(missing_fields, collapse = ", ")))
    }
    
    message("TEST: ✅ All required core fields present")
    
    # Test 4: Verify platform_id consistency
    message("TEST: 🏷️  Verifying Cyberbiz platform_id consistency...")
    platform_codes <- DBI::dbGetQuery(raw_data,
      sprintf("SELECT DISTINCT platform_code FROM %s", table_name))$platform_code
    
    if (length(platform_codes) != 1 || platform_codes[1] != "cbz") {
      stop(sprintf("Platform ID inconsistent. Expected: cbz, Found: %s", 
                   paste(platform_codes, collapse = ", ")))
    }
    
    message(sprintf("TEST: ✅ Platform ID consistent: %s", platform_codes[1]))
    
    # Test 5: Verify Cyberbiz-specific fields
    message("TEST: 🏪 Verifying Cyberbiz-specific customer extensions...")
    cbz_fields <- c("cbz_member_level", "cbz_vip_status", "cbz_loyalty_points", "cbz_marketing_consent")
    cbz_missing <- setdiff(cbz_fields, actual_fields)
    
    if (length(cbz_missing) > 0) {
      warning(sprintf("Missing Cyberbiz customer extension fields: %s", paste(cbz_missing, collapse = ", ")))
    } else {
      message("TEST: ✅ Cyberbiz customer extension fields present")
    }
    
    # Test 6: Verify email format (basic validation)
    message("TEST: 📧 Verifying customer email formats...")
    sample_emails <- DBI::dbGetQuery(raw_data, 
      sprintf("SELECT customer_email FROM %s WHERE customer_email IS NOT NULL LIMIT 10", table_name))$customer_email
    
    invalid_emails <- sample_emails[!grepl("@", sample_emails)]
    if (length(invalid_emails) > 0) {
      warning(sprintf("Found %d potentially invalid email addresses", length(invalid_emails)))
    }
    
    message("TEST: ✅ Email format validation completed")
    
    # Test 7: Check for duplicate customer IDs
    message("TEST: 🔍 Checking for duplicate Cyberbiz customer IDs...")
    duplicate_check <- DBI::dbGetQuery(raw_data, sprintf(
      "SELECT customer_id, COUNT(*) as count FROM %s GROUP BY customer_id HAVING COUNT(*) > 1 LIMIT 5", 
      table_name))
    
    if (nrow(duplicate_check) > 0) {
      warning(sprintf("Found %d duplicate customer IDs", nrow(duplicate_check)))
    }
    
    message("TEST: ✅ Duplicate check completed")
    
    # Test 8: Verify loyalty points are numeric
    message("TEST: 💎 Verifying Cyberbiz loyalty points...")
    points_check <- DBI::dbGetQuery(raw_data, sprintf(
      "SELECT cbz_loyalty_points FROM %s WHERE cbz_loyalty_points IS NOT NULL AND cbz_loyalty_points < 0 LIMIT 5", 
      table_name))
    
    if (nrow(points_check) > 0) {
      warning("Found negative loyalty points values")
    }
    
    message("TEST: ✅ Loyalty points validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Cyberbiz customer import tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Cyberbiz customer import test failed: %s", e$message))
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

message("RESULT: 📊 Cyberbiz Customer ETL Import (0IM) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ Cyberbiz Customer ETL Import (0IM) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Cyberbiz Customer ETL Import (0IM) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()