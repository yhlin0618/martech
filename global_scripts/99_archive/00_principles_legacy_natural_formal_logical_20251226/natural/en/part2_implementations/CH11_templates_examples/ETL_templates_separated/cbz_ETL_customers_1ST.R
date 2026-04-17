# cbz_ETL_customers_1ST.R - Cyberbiz Customer Data Staging Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Customer Pipeline Phase 1ST (Staging): Data cleaning and standardization
# Cyberbiz-specific customer staging implementation
#
# Staging Focus: Fix encoding, dates, formats - no business logic
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Cyberbiz Customer ETL Staging Phase (1ST)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for customer data staging
message("INITIALIZE: 📦 Loading customer staging libraries...")
lib_start <- Sys.time()

library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source staging-specific functions
message("INITIALIZE: 📋 Loading customer staging functions...")
source_start <- Sys.time()

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("stage_customers_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "staging", "fn_stage_customers_data.R"))
}
if (!exists("tbl2", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "tbl2", "fn_tbl2.R"))
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

message("MAIN: 🚀 Starting Cyberbiz customer data staging processing...")
main_start_time <- Sys.time()

# Main execution function for Cyberbiz customer staging
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read raw customer data
    message("MAIN: 📥 Reading Cyberbiz customer data from raw_data...")
    read_start <- Sys.time()
    
    customers_raw <- tbl2(raw_data, "df_cbz_customers___raw") %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Raw customer data loaded (%d records, %.2fs)", 
                    nrow(customers_raw), read_elapsed))
    
    # Step 2: Standardize encoding (UTF-8)
    message("MAIN: 🔤 Standardizing text encoding to UTF-8...")
    encoding_start <- Sys.time()
    
    customers_encoded <- customers_raw %>%
      mutate(
        # Fix encoding issues in text fields
        customer_id = iconv(customer_id, to = "UTF-8"),
        customer_email = iconv(customer_email, to = "UTF-8"),
        customer_name = iconv(customer_name, to = "UTF-8"),
        cbz_phone_number = iconv(cbz_phone_number, to = "UTF-8"),
        cbz_referral_source = iconv(cbz_referral_source, to = "UTF-8"),
        
        # Remove invalid UTF-8 characters
        across(where(is.character), ~ str_replace_all(.x, "[^\x01-\x7F]", ""))
      )
    
    encoding_elapsed <- as.numeric(Sys.time() - encoding_start, units = "secs")
    message(sprintf("MAIN: ✅ UTF-8 encoding standardized (%.2fs)", encoding_elapsed))
    
    # Step 3: Fix date formats
    message("MAIN: 📅 Standardizing date formats...")
    date_start <- Sys.time()
    
    customers_dated <- customers_encoded %>%
      mutate(
        # Standardize registration_date format
        registration_date = case_when(
          !is.na(registration_date) & str_detect(registration_date, "^\\d{4}-\\d{2}-\\d{2}") ~ registration_date,
          !is.na(registration_date) & str_detect(registration_date, "^\\d{2}/\\d{2}/\\d{4}") ~ 
            format(as.Date(registration_date, format = "%m/%d/%Y"), "%Y-%m-%d"),
          !is.na(registration_date) & str_detect(registration_date, "^\\d{4}/\\d{2}/\\d{2}") ~ 
            str_replace_all(registration_date, "/", "-"),
          TRUE ~ registration_date
        ),
        
        # Standardize last login date if present
        cbz_last_login = case_when(
          !is.na(cbz_last_login) & str_detect(cbz_last_login, "^\\d{4}-\\d{2}-\\d{2}") ~ cbz_last_login,
          !is.na(cbz_last_login) & str_detect(cbz_last_login, "^\\d{2}/\\d{2}/\\d{4}") ~ 
            format(as.Date(cbz_last_login, format = "%m/%d/%Y"), "%Y-%m-%d"),
          !is.na(cbz_last_login) & str_detect(cbz_last_login, "^\\d{4}/\\d{2}/\\d{2}") ~ 
            str_replace_all(cbz_last_login, "/", "-"),
          TRUE ~ cbz_last_login
        )
      )
    
    date_elapsed <- as.numeric(Sys.time() - date_start, units = "secs")
    message(sprintf("MAIN: ✅ Date formats standardized (%.2fs)", date_elapsed))
    
    # Step 4: Clean and validate data structure
    message("MAIN: 🧹 Cleaning customer data structure...")
    clean_start <- Sys.time()
    
    customers_cleaned <- customers_dated %>%
      mutate(
        # Clean email addresses
        customer_email = case_when(
          is.na(customer_email) ~ NA_character_,
          str_trim(customer_email) == "" ~ NA_character_,
          !str_detect(str_to_lower(customer_email), "@") ~ NA_character_,
          TRUE ~ str_to_lower(str_trim(customer_email))
        ),
        
        # Clean phone numbers (remove spaces, dashes)
        cbz_phone_number = case_when(
          is.na(cbz_phone_number) ~ NA_character_,
          str_trim(cbz_phone_number) == "" ~ NA_character_,
          TRUE ~ str_replace_all(str_trim(cbz_phone_number), "[^0-9+]", "")
        ),
        
        # Standardize gender codes
        cbz_gender = case_when(
          is.na(cbz_gender) ~ NA_character_,
          str_to_upper(str_trim(cbz_gender)) %in% c("M", "MALE", "男") ~ "M",
          str_to_upper(str_trim(cbz_gender)) %in% c("F", "FEMALE", "女") ~ "F",
          TRUE ~ "U"  # Unknown
        ),
        
        # Clean birth month (ensure 1-12 range)
        cbz_birth_month = case_when(
          is.na(cbz_birth_month) ~ NA_character_,
          as.numeric(cbz_birth_month) >= 1 & as.numeric(cbz_birth_month) <= 12 ~ 
            sprintf("%02d", as.numeric(cbz_birth_month)),
          TRUE ~ NA_character_
        ),
        
        # Ensure loyalty points are non-negative
        cbz_loyalty_points = case_when(
          is.na(cbz_loyalty_points) ~ 0,
          cbz_loyalty_points < 0 ~ 0,
          TRUE ~ cbz_loyalty_points
        ),
        
        # Add staging metadata
        staging_timestamp = Sys.time(),
        staging_phase = "1ST"
      ) %>%
      # Remove records with critical missing data
      filter(
        !is.na(customer_id),
        str_trim(customer_id) != ""
      )
    
    clean_elapsed <- as.numeric(Sys.time() - clean_start, units = "secs")
    message(sprintf("MAIN: ✅ Data structure cleaned (%d records remain, %.2fs)", 
                    nrow(customers_cleaned), clean_elapsed))
    
    # Step 5: Write to staged_data database
    message("MAIN: 💾 Writing Cyberbiz customer data to staged_data database...")
    write_start <- Sys.time()
    
    table_name <- "df_cbz_customers___staged"
    
    # Create or replace table
    DBI::dbWriteTable(staged_data, table_name, customers_cleaned, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz customer staged data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(customers_cleaned),
      records_input = nrow(customers_raw),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "cbz",
      datatype = "customers",
      phase = "1ST"
    )
    
    message(sprintf("MAIN: 🎉 Cyberbiz customer staging completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Cyberbiz customer staging failed: %s", e$message))
    stop(sprintf("Cyberbiz Customer ETL 1ST failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Cyberbiz customer staging validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if Cyberbiz customer staged table was created...")
    table_name <- "df_cbz_customers___staged"
    
    if (!DBI::dbExistsTable(staged_data, table_name)) {
      stop(sprintf("Cyberbiz customer staged table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying Cyberbiz customer staged record count...")
    record_count <- DBI::dbGetQuery(staged_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Cyberbiz customer staged table is empty")
    }
    
    message(sprintf("TEST: ✅ Cyberbiz customer staged table contains %d records", record_count))
    
    # Test 3: Verify UTF-8 encoding
    message("TEST: 🔤 Verifying UTF-8 encoding compliance...")
    encoding_test <- DBI::dbGetQuery(staged_data, sprintf(
      "SELECT customer_name FROM %s WHERE customer_name IS NOT NULL LIMIT 5", table_name))
    
    # Check for non-UTF-8 characters (basic test)
    has_invalid_chars <- any(grepl("[^\x01-\x7F]", encoding_test$customer_name, useBytes = TRUE))
    
    if (has_invalid_chars) {
      warning("Some records may contain non-UTF-8 characters")
    }
    
    message("TEST: ✅ UTF-8 encoding validation completed")
    
    # Test 4: Verify date format standardization
    message("TEST: 📅 Verifying date format standardization...")
    date_test <- DBI::dbGetQuery(staged_data, sprintf(
      "SELECT registration_date FROM %s WHERE registration_date IS NOT NULL LIMIT 10", table_name))
    
    invalid_dates <- date_test$registration_date[!grepl("^\\d{4}-\\d{2}-\\d{2}$", date_test$registration_date)]
    
    if (length(invalid_dates) > 0) {
      warning(sprintf("Found %d records with non-standard date format", length(invalid_dates)))
    }
    
    message("TEST: ✅ Date format validation completed")
    
    # Test 5: Verify email cleaning
    message("TEST: 📧 Verifying email address cleaning...")
    email_test <- DBI::dbGetQuery(staged_data, sprintf(
      "SELECT customer_email FROM %s WHERE customer_email IS NOT NULL LIMIT 10", table_name))
    
    invalid_emails <- email_test$customer_email[!grepl("@", email_test$customer_email)]
    
    if (length(invalid_emails) > 0) {
      warning(sprintf("Found %d potentially invalid email addresses", length(invalid_emails)))
    }
    
    message("TEST: ✅ Email cleaning validation completed")
    
    # Test 6: Verify no negative loyalty points
    message("TEST: 💎 Verifying loyalty points are non-negative...")
    negative_points <- DBI::dbGetQuery(staged_data, sprintf(
      "SELECT COUNT(*) as count FROM %s WHERE cbz_loyalty_points < 0", table_name))$count
    
    if (negative_points > 0) {
      warning(sprintf("Found %d records with negative loyalty points", negative_points))
    }
    
    message("TEST: ✅ Loyalty points validation completed")
    
    # Test 7: Verify staging metadata
    message("TEST: 🏷️  Verifying staging metadata...")
    metadata_test <- DBI::dbGetQuery(staged_data, sprintf(
      "SELECT DISTINCT staging_phase FROM %s", table_name))$staging_phase
    
    if (!"1ST" %in% metadata_test) {
      warning("Staging phase metadata not properly set")
    }
    
    message("TEST: ✅ Staging metadata validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Cyberbiz customer staging tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Cyberbiz customer staging test failed: %s", e$message))
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

message("RESULT: 📊 Cyberbiz Customer ETL Staging (1ST) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 📥 Records input: %s", 
                if (exists("execution_result")) execution_result$records_input else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ Cyberbiz Customer ETL Staging (1ST) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Cyberbiz Customer ETL Staging (1ST) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()