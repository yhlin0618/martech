# cbz_ETL_customers_2TR.R - Cyberbiz Customer Data Transform Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Customer Pipeline Phase 2TR (Transform): Schema standardization and enrichment
# Cyberbiz-specific customer transform implementation
#
# Transform Focus: Schema mapping, type conversions, reference joins - no business calculations
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Cyberbiz Customer ETL Transform Phase (2TR)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for customer data transformation
message("INITIALIZE: 📦 Loading customer transform libraries...")
lib_start <- Sys.time()

library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source transform-specific functions
message("INITIALIZE: 📋 Loading customer transform functions...")
source_start <- Sys.time()

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("transform_customers_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "transform", "fn_transform_customers_data.R"))
}
if (!exists("tbl2", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "tbl2", "fn_tbl2.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to databases...")
db_start <- Sys.time()
staged_data <- dbConnectDuckdb(db_path_list$staged_data, read_only = TRUE)
transformed_data <- dbConnectDuckdb(db_path_list$transformed_data, read_only = FALSE)
reference_data <- dbConnectDuckdb(db_path_list$reference_data, read_only = TRUE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connections established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting Cyberbiz customer data transform processing...")
main_start_time <- Sys.time()

# Main execution function for Cyberbiz customer transform
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read staged customer data
    message("MAIN: 📥 Reading Cyberbiz staged customer data...")
    read_start <- Sys.time()
    
    customers_staged <- tbl2(staged_data, "df_cbz_customers___staged") %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Staged customer data loaded (%d records, %.2fs)", 
                    nrow(customers_staged), read_elapsed))
    
    # Step 2: Apply schema standardization
    message("MAIN: 📋 Applying standardized schema transformations...")
    schema_start <- Sys.time()
    
    customers_schema <- customers_staged %>%
      mutate(
        # Convert dates to proper Date type
        registration_date_final = ymd(registration_date),
        last_login_date_final = ymd(cbz_last_login),
        
        # Standardize member levels to common tiers
        customer_tier_std = case_when(
          str_detect(str_to_lower(cbz_member_level), "vip|premium|gold|diamond") ~ "premium",
          str_detect(str_to_lower(cbz_member_level), "silver|member|standard") ~ "standard",
          str_detect(str_to_lower(cbz_member_level), "bronze|basic|new") ~ "basic",
          TRUE ~ "unknown"
        ),
        
        # Standardize VIP status to boolean
        is_vip_customer = case_when(
          str_detect(str_to_lower(cbz_vip_status), "vip|true|yes|1") ~ TRUE,
          str_detect(str_to_lower(cbz_vip_status), "false|no|0|regular") ~ FALSE,
          TRUE ~ FALSE
        ),
        
        # Standardize referral sources to categories
        referral_category_std = case_when(
          str_detect(str_to_lower(cbz_referral_source), "google|search|seo") ~ "search_engine",
          str_detect(str_to_lower(cbz_referral_source), "facebook|fb|social") ~ "social_media",
          str_detect(str_to_lower(cbz_referral_source), "email|newsletter|edm") ~ "email_marketing",
          str_detect(str_to_lower(cbz_referral_source), "friend|referral|word") ~ "word_of_mouth",
          str_detect(str_to_lower(cbz_referral_source), "direct|bookmark|url") ~ "direct",
          str_detect(str_to_lower(cbz_referral_source), "ad|advertisement|campaign") ~ "paid_advertising",
          TRUE ~ "other"
        ),
        
        # Create standardized loyalty tier based on points
        loyalty_tier_std = case_when(
          cbz_loyalty_points >= 10000 ~ "platinum",
          cbz_loyalty_points >= 5000 ~ "gold",
          cbz_loyalty_points >= 1000 ~ "silver",
          cbz_loyalty_points > 0 ~ "bronze",
          TRUE ~ "none"
        ),
        
        # Create derived fields for analytics (structural only, no business logic)
        registration_year = year(registration_date_final),
        registration_month = month(registration_date_final),
        registration_quarter = quarter(registration_date_final),
        
        # Customer age category based on birth month (if available)
        birth_month_numeric = as.numeric(cbz_birth_month),
        
        # Marketing consent standardization
        marketing_consent_std = case_when(
          is.na(cbz_marketing_consent) ~ FALSE,
          cbz_marketing_consent == TRUE ~ TRUE,
          cbz_marketing_consent == FALSE ~ FALSE,
          str_to_lower(as.character(cbz_marketing_consent)) %in% c("yes", "true", "1") ~ TRUE,
          TRUE ~ FALSE
        ),
        
        # Phone number validity indicator
        has_valid_phone = case_when(
          is.na(cbz_phone_number) ~ FALSE,
          str_length(cbz_phone_number) >= 8 ~ TRUE,
          TRUE ~ FALSE
        ),
        
        # Email domain extraction for analytics
        email_domain = case_when(
          is.na(customer_email) ~ NA_character_,
          !str_detect(customer_email, "@") ~ NA_character_,
          TRUE ~ str_extract(customer_email, "(?<=@)[^.]+\\.[a-z]{2,}")
        )
      )
    
    schema_elapsed <- as.numeric(Sys.time() - schema_start, units = "secs")
    message(sprintf("MAIN: ✅ Schema standardization completed (%.2fs)", schema_elapsed))
    
    # Step 3: Join with reference data
    message("MAIN: 🔗 Joining with reference data...")
    join_start <- Sys.time()
    
    # Try to join with store reference data if available
    customers_enriched <- customers_schema
    
    # Check if store reference table exists
    if (DBI::dbExistsTable(reference_data, "ref_stores")) {
      message("MAIN: 🏪 Joining with store reference data...")
      stores_ref <- tbl2(reference_data, "ref_stores") %>% collect()
      
      customers_enriched <- customers_enriched %>%
        left_join(
          stores_ref %>% select(store_id, store_name, store_region, store_type),
          by = c("cbz_registration_store" = "store_id")
        ) %>%
        rename(
          registration_store_name = store_name,
          registration_store_region = store_region,
          registration_store_type = store_type
        )
    }
    
    # Check if demographics reference table exists
    if (DBI::dbExistsTable(reference_data, "ref_demographics")) {
      message("MAIN: 👥 Joining with demographics reference data...")
      demographics_ref <- tbl2(reference_data, "ref_demographics") %>% collect()
      
      customers_enriched <- customers_enriched %>%
        left_join(
          demographics_ref %>% select(birth_month, zodiac_sign, birth_season),
          by = c("birth_month_numeric" = "birth_month")
        )
    }
    
    join_elapsed <- as.numeric(Sys.time() - join_start, units = "secs")
    message(sprintf("MAIN: ✅ Reference data joins completed (%.2fs)", join_elapsed))
    
    # Step 4: Final schema compliance and cleanup
    message("MAIN: 🧹 Applying final schema compliance...")
    final_start <- Sys.time()
    
    customers_final <- customers_enriched %>%
      # Ensure all required fields are present
      mutate(
        # Add transform metadata
        transform_timestamp = Sys.time(),
        transform_phase = "2TR",
        schema_version = "1.0",
        
        # Ensure consistent data types for DuckDB
        customer_id = as.character(customer_id),
        customer_email = as.character(customer_email),
        customer_name = as.character(customer_name),
        platform_code = as.character(platform_code),
        cbz_loyalty_points = as.numeric(cbz_loyalty_points)
      ) %>%
      # Select final output columns in standardized order
      select(
        # Core customer identifiers
        customer_id, customer_email, customer_name,
        
        # Key dates
        registration_date_final, last_login_date_final,
        
        # Standardized categories
        customer_tier_std, is_vip_customer, referral_category_std, loyalty_tier_std,
        
        # Original Cyberbiz fields (preserved)
        starts_with("cbz_"),
        
        # Derived analytics fields
        registration_year, registration_month, registration_quarter,
        birth_month_numeric, marketing_consent_std, has_valid_phone, email_domain,
        
        # Reference data joins (if available)
        starts_with("registration_store_"), zodiac_sign, birth_season,
        
        # Metadata fields
        platform_code, import_timestamp, import_source,
        staging_timestamp, staging_phase,
        transform_timestamp, transform_phase, schema_version
      )
    
    final_elapsed <- as.numeric(Sys.time() - final_start, units = "secs")
    message(sprintf("MAIN: ✅ Final schema compliance applied (%.2fs)", final_elapsed))
    
    # Step 5: Write to transformed_data database
    message("MAIN: 💾 Writing Cyberbiz customer data to transformed_data database...")
    write_start <- Sys.time()
    
    table_name <- "df_cbz_customers___transformed"
    
    # Create or replace table
    DBI::dbWriteTable(transformed_data, table_name, customers_final, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Cyberbiz customer transformed data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(customers_final),
      records_input = nrow(customers_staged),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "cbz",
      datatype = "customers",
      phase = "2TR"
    )
    
    message(sprintf("MAIN: 🎉 Cyberbiz customer transform completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Cyberbiz customer transform failed: %s", e$message))
    stop(sprintf("Cyberbiz Customer ETL 2TR failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Cyberbiz customer transform validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if Cyberbiz customer transformed table was created...")
    table_name <- "df_cbz_customers___transformed"
    
    if (!DBI::dbExistsTable(transformed_data, table_name)) {
      stop(sprintf("Cyberbiz customer transformed table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying Cyberbiz customer transformed record count...")
    record_count <- DBI::dbGetQuery(transformed_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Cyberbiz customer transformed table is empty")
    }
    
    message(sprintf("TEST: ✅ Cyberbiz customer transformed table contains %d records", record_count))
    
    # Test 3: Verify standardized customer tiers
    message("TEST: 🏆 Verifying customer tier standardization...")
    tier_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT DISTINCT customer_tier_std FROM %s WHERE customer_tier_std IS NOT NULL", table_name))
    
    valid_tiers <- c("premium", "standard", "basic", "unknown")
    invalid_tiers <- setdiff(tier_test$customer_tier_std, valid_tiers)
    
    if (length(invalid_tiers) > 0) {
      warning(sprintf("Found invalid customer tiers: %s", paste(invalid_tiers, collapse = ", ")))
    }
    
    message("TEST: ✅ Customer tier standardization validation completed")
    
    # Test 4: Verify referral category standardization
    message("TEST: 📊 Verifying referral category standardization...")
    referral_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT DISTINCT referral_category_std FROM %s WHERE referral_category_std IS NOT NULL", table_name))
    
    valid_categories <- c("search_engine", "social_media", "email_marketing", "word_of_mouth", "direct", "paid_advertising", "other")
    invalid_categories <- setdiff(referral_test$referral_category_std, valid_categories)
    
    if (length(invalid_categories) > 0) {
      warning(sprintf("Found invalid referral categories: %s", paste(invalid_categories, collapse = ", ")))
    }
    
    message("TEST: ✅ Referral category standardization validation completed")
    
    # Test 5: Verify loyalty tier consistency
    message("TEST: 💎 Verifying loyalty tier consistency...")
    loyalty_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT loyalty_tier_std, MIN(cbz_loyalty_points) as min_points, MAX(cbz_loyalty_points) as max_points FROM %s GROUP BY loyalty_tier_std", table_name))
    
    # Check that platinum tier has points >= 10000
    platinum_check <- loyalty_test[loyalty_test$loyalty_tier_std == "platinum", ]
    if (nrow(platinum_check) > 0 && platinum_check$min_points < 10000) {
      warning("Platinum tier customers found with less than 10000 points")
    }
    
    message("TEST: ✅ Loyalty tier consistency validation completed")
    
    # Test 6: Verify date conversion
    message("TEST: 📅 Verifying date field conversion...")
    date_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT COUNT(*) as count FROM %s WHERE registration_date_final IS NOT NULL", table_name))$count
    
    if (date_test == 0) {
      warning("No valid registration dates found after conversion")
    }
    
    message("TEST: ✅ Date conversion validation completed")
    
    # Test 7: Verify VIP status boolean conversion
    message("TEST: ⭐ Verifying VIP status boolean conversion...")
    vip_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT DISTINCT is_vip_customer FROM %s WHERE is_vip_customer IS NOT NULL", table_name))
    
    if (!all(vip_test$is_vip_customer %in% c(TRUE, FALSE))) {
      warning("VIP status field contains non-boolean values")
    }
    
    message("TEST: ✅ VIP status validation completed")
    
    # Test 8: Verify transform metadata
    message("TEST: 🏷️  Verifying transform metadata...")
    metadata_test <- DBI::dbGetQuery(transformed_data, sprintf(
      "SELECT DISTINCT transform_phase, schema_version FROM %s", table_name))
    
    if (!"2TR" %in% metadata_test$transform_phase) {
      warning("Transform phase metadata not properly set")
    }
    if (!"1.0" %in% metadata_test$schema_version) {
      warning("Schema version metadata not properly set")
    }
    
    message("TEST: ✅ Transform metadata validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Cyberbiz customer transform tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Cyberbiz customer transform test failed: %s", e$message))
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

message("RESULT: 📊 Cyberbiz Customer ETL Transform (2TR) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 📥 Records input: %s", 
                if (exists("execution_result")) execution_result$records_input else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ Cyberbiz Customer ETL Transform (2TR) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Cyberbiz Customer ETL Transform (2TR) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()