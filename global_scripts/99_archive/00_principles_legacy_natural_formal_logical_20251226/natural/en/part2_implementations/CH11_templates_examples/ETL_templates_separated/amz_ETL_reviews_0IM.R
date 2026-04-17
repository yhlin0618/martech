# amz_ETL_reviews_0IM.R - Amazon Reviews Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Reviews Pipeline Phase 0IM (Import): Pure data extraction for product reviews
# Amazon-specific reviews import implementation
#
# Amazon Reviews Integration: Handles review data from various Amazon sources
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Amazon Reviews ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for Amazon reviews processing
message("INITIALIZE: 📦 Loading Amazon reviews ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls if available
library(jsonlite)  # JSON handling
library(readr)     # CSV file handling  
library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing
library(tidyr)     # Data tidying

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source Amazon-specific ETL functions
message("INITIALIZE: 📋 Loading Amazon reviews ETL functions...")
source_start <- Sys.time()

# Amazon reviews-specific functions
if (!exists("process_reviews_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "amz", "import", "fn_process_reviews_import.R"))
}
if (!exists("fetch_amz_reviews_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "amz", "import", "fn_fetch_amz_reviews_data.R"))
}
if (!exists("parse_amz_review_text", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "amz", "import", "fn_parse_amz_review_text.R"))
}
if (!exists("validate_reviews_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_reviews_import.R"))
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

message("MAIN: 🚀 Starting Amazon reviews data import processing...")
main_start_time <- Sys.time()

# Main execution function for Amazon reviews import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch Amazon reviews data
    message("MAIN: 📥 Fetching Amazon reviews data...")
    fetch_start <- Sys.time()
    
    # Amazon-specific data fetching (could be API, files, or scraping)
    reviews_raw_data <- fetch_amz_reviews_data()
    
    if (nrow(reviews_raw_data) == 0) {
      stop("No Amazon reviews data retrieved")
    }
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Amazon reviews data fetched (%d records, %.2fs)", 
                    nrow(reviews_raw_data), fetch_elapsed))
    
    # Step 2: Apply reviews-specific import processing
    message("MAIN: 🔄 Processing Amazon reviews import data...")
    process_start <- Sys.time()
    
    reviews_processed <- process_reviews_import(reviews_raw_data, platform_code = "amz")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Amazon reviews import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Parse and clean review text data
    message("MAIN: 📝 Parsing Amazon review text content...")
    text_start <- Sys.time()
    
    reviews_parsed <- reviews_processed %>%
      mutate(
        # Parse review text for key features
        review_length = str_length(review_text),
        review_word_count = str_count(review_text, "\\w+"),
        
        # Extract key sentiment indicators (basic)
        has_positive_words = str_detect(str_to_lower(review_text), 
                                       "good|great|excellent|amazing|love|perfect|recommend"),
        has_negative_words = str_detect(str_to_lower(review_text), 
                                       "bad|terrible|awful|hate|worst|horrible|disappointed"),
        
        # Extract product mentions
        mentions_price = str_detect(str_to_lower(review_text), 
                                   "price|cost|expensive|cheap|value|money"),
        mentions_quality = str_detect(str_to_lower(review_text), 
                                     "quality|build|material|durable|sturdy"),
        mentions_shipping = str_detect(str_to_lower(review_text), 
                                      "shipping|delivery|arrived|fast|slow"),
        
        # Clean and standardize text
        review_text_clean = str_trim(review_text),
        review_text_clean = str_replace_all(review_text_clean, "\\s+", " ")
      )
    
    text_elapsed <- as.numeric(Sys.time() - text_start, units = "secs")
    message(sprintf("MAIN: ✅ Review text parsing completed (%.2fs)", text_elapsed))
    
    # Step 4: Apply MP102 standardization for Amazon reviews data
    message("MAIN: 📋 Applying MP102 standardization for Amazon reviews...")
    standardize_start <- Sys.time()
    
    reviews_standardized <- reviews_parsed %>%
      mutate(
        # Core fields (required by MP102)
        review_id = as.character(review_id),
        product_id = as.character(product_id),
        customer_id = as.character(customer_id),
        rating = as.numeric(rating),
        review_date = as.character(review_date),
        review_text = as.character(review_text_clean),
        platform_code = "amz",
        import_timestamp = Sys.time(),
        import_source = "API",  # or "FILE" or "SCRAPING" depending on source
        
        # Amazon-specific extensions (preserving unique data)
        amz_asin = as.character(asin),
        amz_marketplace_id = as.character(marketplace_id),
        amz_reviewer_name = as.character(reviewer_name),
        amz_verified_purchase = as.logical(verified_purchase),
        amz_helpful_votes = as.integer(helpful_votes),
        amz_total_votes = as.integer(total_votes),
        amz_review_title = as.character(review_title),
        amz_variant_info = as.character(variant_info),
        
        # Text analysis features (derived)
        review_length = as.integer(review_length),
        review_word_count = as.integer(review_word_count),
        has_positive_sentiment = as.logical(has_positive_words),
        has_negative_sentiment = as.logical(has_negative_words),
        mentions_price = as.logical(mentions_price),
        mentions_quality = as.logical(mentions_quality),
        mentions_shipping = as.logical(mentions_shipping)
      ) %>%
      # Remove intermediate columns
      select(-review_text_clean, -has_positive_words, -has_negative_words)
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Amazon reviews standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 5: Validate reviews import output
    message("MAIN: ✔️  Validating Amazon reviews import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_reviews_import(reviews_standardized, platform_code = "amz")
    
    if (!validation_result$valid) {
      stop(sprintf("Amazon reviews import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing Amazon reviews data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- "df_amz_reviews___raw"
    write_etl_output(raw_data, table_name, reviews_standardized, 
                     platform = "amz", datatype = "reviews", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Amazon reviews data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(reviews_standardized),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "amz",
      datatype = "reviews",
      phase = "0IM",
      
      # Additional review-specific metrics
      avg_rating = round(mean(reviews_standardized$rating, na.rm = TRUE), 2),
      avg_review_length = round(mean(reviews_standardized$review_length, na.rm = TRUE), 0),
      verified_purchase_pct = round(mean(reviews_standardized$amz_verified_purchase, na.rm = TRUE) * 100, 1),
      positive_sentiment_pct = round(mean(reviews_standardized$has_positive_sentiment, na.rm = TRUE) * 100, 1)
    )
    
    message(sprintf("MAIN: 🎉 Amazon reviews import completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    message(sprintf("MAIN: 📊 Review metrics - Avg rating: %.2f, Avg length: %d chars, %g%% verified", 
                    result$avg_rating, result$avg_review_length, result$verified_purchase_pct))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Amazon reviews import failed: %s", e$message))
    stop(sprintf("Amazon Reviews ETL 0IM failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Amazon reviews import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if Amazon reviews table was created...")
    table_name <- "df_amz_reviews___raw"
    
    if (!DBI::dbExistsTable(raw_data, table_name)) {
      stop(sprintf("Amazon reviews table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying Amazon reviews record count...")
    record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("Amazon reviews table is empty")
    }
    
    message(sprintf("TEST: ✅ Amazon reviews table contains %d records", record_count))
    
    # Test 3: Verify core schema compliance (MP102)
    message("TEST: 📋 Verifying MP102 core schema compliance...")
    table_info <- DBI::dbGetQuery(raw_data, sprintf("PRAGMA table_info(%s)", table_name))
    required_fields <- c("review_id", "product_id", "customer_id", "rating", 
                         "review_date", "review_text", "platform_code", 
                         "import_timestamp", "import_source")
    
    actual_fields <- table_info$name
    missing_fields <- setdiff(required_fields, actual_fields)
    
    if (length(missing_fields) > 0) {
      stop(sprintf("Missing required fields in Amazon reviews table: %s", paste(missing_fields, collapse = ", ")))
    }
    
    message("TEST: ✅ All required core fields present")
    
    # Test 4: Verify platform_id consistency
    message("TEST: 🏷️  Verifying Amazon platform_id consistency...")
    platform_codes <- DBI::dbGetQuery(raw_data, 
      sprintf("SELECT DISTINCT platform_code FROM %s", table_name))$platform_code
    
    if (length(platform_codes) != 1 || platform_codes[1] != "amz") {
      stop(sprintf("Platform ID inconsistent. Expected: amz, Found: %s", 
                   paste(platform_codes, collapse = ", ")))
    }
    
    message(sprintf("TEST: ✅ Platform ID consistent: %s", platform_codes[1]))
    
    # Test 5: Verify Amazon-specific fields
    message("TEST: 🏪 Verifying Amazon-specific extensions...")
    amz_fields <- c("amz_asin", "amz_marketplace_id", "amz_reviewer_name", "amz_verified_purchase")
    amz_missing <- setdiff(amz_fields, actual_fields)
    
    if (length(amz_missing) > 0) {
      warning(sprintf("Missing Amazon extension fields: %s", paste(amz_missing, collapse = ", ")))
    } else {
      message("TEST: ✅ Amazon extension fields present")
    }
    
    # Test 6: Verify rating data quality
    message("TEST: ⭐ Verifying review rating data quality...")
    rating_stats <- DBI::dbGetQuery(raw_data, sprintf("
      SELECT 
        MIN(rating) as min_rating,
        MAX(rating) as max_rating,
        AVG(rating) as avg_rating,
        COUNT(*) as total_reviews,
        COUNT(rating) as reviews_with_rating
      FROM %s", table_name))
    
    rating_completeness <- rating_stats$reviews_with_rating / rating_stats$total_reviews
    
    if (rating_completeness < 0.8) {
      warning(sprintf("Low rating completeness: %.1f%%", rating_completeness * 100))
    }
    
    if (rating_stats$min_rating < 1 || rating_stats$max_rating > 5) {
      warning(sprintf("Rating values out of expected range (1-5): %.1f to %.1f", 
                     rating_stats$min_rating, rating_stats$max_rating))
    } else {
      message(sprintf("TEST: ✅ Rating data quality good (%.1f avg, %.1f%% complete)", 
                     rating_stats$avg_rating, rating_completeness * 100))
    }
    
    # Test 7: Verify text analysis features
    message("TEST: 📝 Verifying text analysis features...")
    text_stats <- DBI::dbGetQuery(raw_data, sprintf("
      SELECT 
        AVG(review_length) as avg_length,
        AVG(review_word_count) as avg_words,
        SUM(CASE WHEN has_positive_sentiment THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as positive_pct,
        SUM(CASE WHEN has_negative_sentiment THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as negative_pct
      FROM %s", table_name))
    
    if (text_stats$avg_length < 10) {
      warning("Reviews seem very short - possible parsing issue")
    } else {
      message(sprintf("TEST: ✅ Text analysis complete (avg: %.0f chars, %.1f%% positive, %.1f%% negative)", 
                     text_stats$avg_length, text_stats$positive_pct, text_stats$negative_pct))
    }
    
    # Test 8: Verify data types
    message("TEST: 🔧 Verifying data types...")
    sample_data <- DBI::dbGetQuery(raw_data, sprintf("SELECT * FROM %s LIMIT 5", table_name))
    
    # Check for obvious data type issues
    if (any(is.na(sample_data$review_id))) {
      warning("Some review_id values are NA")
    }
    if (any(is.na(sample_data$product_id))) {
      warning("Some product_id values are NA") 
    }
    if (!is.numeric(sample_data$rating)) {
      warning("rating is not numeric")
    }
    
    message("TEST: ✅ Data type validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Amazon reviews import tests completed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Amazon reviews import test failed: %s", e$message))
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

message("RESULT: 📊 Amazon Reviews ETL Import (0IM) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (exists("execution_result")) {
  message(sprintf("RESULT: ⭐ Average rating: %.2f", execution_result$avg_rating))
  message(sprintf("RESULT: 📝 Average review length: %d characters", execution_result$avg_review_length))
  message(sprintf("RESULT: ✅ Verified purchases: %.1f%%", execution_result$verified_purchase_pct))
}

if (test_passed && script_success) {
  message("RESULT: ✅ Amazon Reviews ETL Import (0IM) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Amazon Reviews ETL Import (0IM) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()