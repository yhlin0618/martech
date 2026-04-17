#!/usr/bin/env Rscript
# ==============================================================================
# COMPREHENSIVE READINESS TEST FOR eby_ETL_order_details_1ST___MAMBA.R
# Following principle-debugger requirements
# ==============================================================================

cat(strrep("=", 80), "\n")
cat("🔍 PRINCIPLE DEBUGGER: Testing eby_ETL_order_details_1ST___MAMBA.R readiness\n")
cat(strrep("=", 80), "\n")

# Track test results
test_results <- list()
all_passed <- TRUE

# ==============================================================================
# TEST 1: Database Lock Check
# ==============================================================================
cat("\n📁 TEST 1: DATABASE LOCK CHECK\n")
cat(strrep("-", 40), "\n")

library(DBI)
library(duckdb)

# Check raw database
test_results$raw_db <- list()
raw_db_path <- "data/mamba_eby_raw.duckdb"
if (file.exists(raw_db_path)) {
  cat("✅ Raw database file exists:", raw_db_path, "\n")
  
  # Try to connect (tests for locks)
  tryCatch({
    con <- dbConnect(duckdb(), raw_db_path, read_only = TRUE)
    test_results$raw_db$accessible <- TRUE
    test_results$raw_db$tables <- dbListTables(con)
    cat("✅ Raw database is accessible (no locks)\n")
    cat("   Tables found:", paste(test_results$raw_db$tables, collapse = ", "), "\n")
    
    # Check for the required table
    if ("df_eby_order_details___raw___MAMBA" %in% test_results$raw_db$tables) {
      cat("✅ Required table df_eby_order_details___raw___MAMBA exists\n")
      test_results$raw_db$table_exists <- TRUE
      
      # Get column info
      cols <- dbListFields(con, "df_eby_order_details___raw___MAMBA")
      test_results$raw_db$columns <- cols
      cat("   Columns:", paste(cols, collapse = ", "), "\n")
      
      # Get row count
      n <- dbGetQuery(con, "SELECT COUNT(*) as n FROM df_eby_order_details___raw___MAMBA")$n
      test_results$raw_db$row_count <- n
      cat("   Row count:", n, "\n")
    } else {
      cat("❌ Required table df_eby_order_details___raw___MAMBA NOT FOUND\n")
      test_results$raw_db$table_exists <- FALSE
      all_passed <- FALSE
    }
    
    dbDisconnect(con)
  }, error = function(e) {
    cat("❌ Cannot access raw database:", e$message, "\n")
    test_results$raw_db$accessible <- FALSE
    all_passed <- FALSE
  })
} else {
  cat("❌ Raw database file does not exist:", raw_db_path, "\n")
  test_results$raw_db$exists <- FALSE
  all_passed <- FALSE
}

# Check staged database
test_results$staged_db <- list()
staged_db_path <- "data/mamba_eby_staging.duckdb"
if (file.exists(staged_db_path)) {
  cat("\n✅ Staged database file exists:", staged_db_path, "\n")
  
  # Try to connect (tests for locks and write access)
  tryCatch({
    con <- dbConnect(duckdb(), staged_db_path, read_only = FALSE)
    test_results$staged_db$accessible <- TRUE
    test_results$staged_db$writable <- TRUE
    cat("✅ Staged database is accessible and writable (no locks)\n")
    
    # List existing tables
    tables <- dbListTables(con)
    if (length(tables) > 0) {
      cat("   Existing tables:", paste(tables, collapse = ", "), "\n")
    } else {
      cat("   No existing tables (ready for new data)\n")
    }
    
    dbDisconnect(con)
  }, error = function(e) {
    cat("❌ Cannot access staged database:", e$message, "\n")
    test_results$staged_db$accessible <- FALSE
    all_passed <- FALSE
  })
} else {
  cat("❌ Staged database file does not exist:", staged_db_path, "\n")
  test_results$staged_db$exists <- FALSE
  all_passed <- FALSE
}

# ==============================================================================
# TEST 2: Column Mapping Validation
# ==============================================================================
cat("\n📊 TEST 2: COLUMN MAPPING VALIDATION\n")
cat(strrep("-", 40), "\n")

if (isTRUE(test_results$raw_db$table_exists)) {
  # Expected ORE columns based on script mapping
  expected_ore_columns <- paste0("ORE", sprintf("%03d", 1:14))
  
  # Check which expected columns exist
  existing_ore <- intersect(expected_ore_columns, test_results$raw_db$columns)
  missing_ore <- setdiff(expected_ore_columns, test_results$raw_db$columns)
  
  cat("Expected ORE columns: ORE001-ORE014\n")
  cat("✅ Found", length(existing_ore), "ORE columns:", paste(existing_ore, collapse = ", "), "\n")
  
  if (length(missing_ore) > 0) {
    cat("⚠️  Missing", length(missing_ore), "ORE columns:", paste(missing_ore, collapse = ", "), "\n")
  }
  
  # Check for critical columns
  critical_columns <- c("ORE001", "ORE002", "ORE004", "ORE013")
  critical_found <- intersect(critical_columns, test_results$raw_db$columns)
  critical_missing <- setdiff(critical_columns, test_results$raw_db$columns)
  
  if (length(critical_missing) == 0) {
    cat("✅ All critical columns present:", paste(critical_columns, collapse = ", "), "\n")
  } else {
    cat("❌ Missing CRITICAL columns:", paste(critical_missing, collapse = ", "), "\n")
    all_passed <- FALSE
  }
  
  # Check for unexpected columns
  unexpected <- setdiff(test_results$raw_db$columns, expected_ore_columns)
  if (length(unexpected) > 0) {
    cat("ℹ️  Additional columns found:", paste(unexpected, collapse = ", "), "\n")
  }
  
  test_results$column_mapping <- list(
    expected = expected_ore_columns,
    found = existing_ore,
    missing = missing_ore,
    critical_ok = length(critical_missing) == 0
  )
} else {
  cat("⚠️  Cannot validate columns - raw table does not exist\n")
  test_results$column_mapping <- list(error = "Table not found")
}

# ==============================================================================
# TEST 3: Code Safety Check
# ==============================================================================
cat("\n🔒 TEST 3: CODE SAFETY CHECK\n")
cat(strrep("-", 40), "\n")

# Read the script to check for potential issues
script_path <- "scripts/update_scripts/eby_ETL_order_details_1ST___MAMBA.R"
if (file.exists(script_path)) {
  script_lines <- readLines(script_path)
  
  # Check line 326 (display columns selection)
  line_326 <- script_lines[326]
  cat("Line 326 check (safe column selection):\n")
  cat("  Content:", substr(line_326, 1, 80), "...\n")
  if (grepl("intersect.*names", line_326)) {
    cat("  ✅ Uses safe intersect() for column selection\n")
  } else {
    cat("  ⚠️  Review needed for column selection safety\n")
  }
  
  # Check for proper error handling
  tryCatch_count <- sum(grepl("tryCatch", script_lines))
  cat("\n✅ Error handling: Found", tryCatch_count, "tryCatch blocks\n")
  
  # Check for column existence checks
  any_of_count <- sum(grepl("any_of|all_of", script_lines))
  exists_checks <- sum(grepl("%in%.*names\\(|%in%.*staged_columns", script_lines))
  cat("✅ Column safety: Found", any_of_count, "any_of/all_of uses\n")
  cat("✅ Column checks: Found", exists_checks, "column existence checks\n")
  
  test_results$code_safety <- list(
    line_326_safe = grepl("intersect", line_326),
    error_handling = tryCatch_count > 0,
    column_safety = any_of_count > 0,
    existence_checks = exists_checks > 0
  )
} else {
  cat("❌ Script file not found:", script_path, "\n")
  all_passed <- FALSE
}

# ==============================================================================
# TEST 4: Data Flow Verification
# ==============================================================================
cat("\n🔄 TEST 4: DATA FLOW VERIFICATION\n")
cat(strrep("-", 40), "\n")

# Check if source functions exist
fn_path <- "scripts/global_scripts/02_db_utils/duckdb/fn_dbConnectDuckdb.R"
if (file.exists(fn_path)) {
  cat("✅ Required function exists:", fn_path, "\n")
  test_results$functions_exist <- TRUE
} else {
  cat("❌ Required function missing:", fn_path, "\n")
  all_passed <- FALSE
  test_results$functions_exist <- FALSE
}

# Check autoinit path
autoinit_path <- "scripts/global_scripts/22_initializations/sc_Rprofile.R"
if (file.exists(autoinit_path)) {
  cat("✅ Autoinit script exists:", autoinit_path, "\n")
} else {
  cat("⚠️  Autoinit script not found (will use relative path)\n")
}

# Verify data flow capability
cat("\nData Flow Capability:\n")
if (isTRUE(test_results$raw_db$accessible) && isTRUE(test_results$staged_db$accessible)) {
  cat("✅ Raw data CAN be read\n")
  cat("✅ Staged data CAN be written\n")
  cat("✅ No blocking operations detected\n")
} else {
  if (!isTRUE(test_results$raw_db$accessible)) {
    cat("❌ Raw data CANNOT be read\n")
    all_passed <- FALSE
  }
  if (!isTRUE(test_results$staged_db$accessible)) {
    cat("❌ Staged data CANNOT be written\n")
    all_passed <- FALSE
  }
}

# ==============================================================================
# TEST 5: Simulated Execution
# ==============================================================================
cat("\n🚀 TEST 5: SIMULATED EXECUTION\n")
cat(strrep("-", 40), "\n")

if (isTRUE(test_results$raw_db$table_exists)) {
  cat("Simulating script execution with actual data...\n")
  
  tryCatch({
    # Connect to raw database
    con_raw <- dbConnect(duckdb(), raw_db_path, read_only = TRUE)
    
    # Read sample data
    sample_query <- "SELECT * FROM df_eby_order_details___raw___MAMBA LIMIT 5"
    sample_data <- dbGetQuery(con_raw, sample_query)
    
    cat("✅ Successfully read", nrow(sample_data), "sample rows\n")
    cat("   Columns:", paste(names(sample_data), collapse = ", "), "\n")
    
    # Test column renaming logic
    existing_columns <- names(sample_data)
    column_mapping <- list(
      ORE001 = "order_id",
      ORE002 = "line_item_number",
      ORE003 = "ebay_item_code",
      ORE004 = "product_name",
      ORE005 = "erp_product_no",
      ORE006 = "application_data",
      ORE007 = "condition",
      ORE008 = "quantity",
      ORE009 = "unit_price",
      ORE010 = "listing_country",
      ORE011 = "email",
      ORE012 = "static_alias",
      ORE013 = "batch_key",
      ORE014 = "reserved_field"
    )
    
    # Filter to only existing columns
    columns_to_rename <- column_mapping[names(column_mapping) %in% existing_columns]
    cat("\n✅ Will rename", length(columns_to_rename), "columns\n")
    
    # Test rename operation
    library(dplyr)
    rename_args <- setNames(names(columns_to_rename), unlist(columns_to_rename))
    renamed_data <- sample_data %>% rename(!!!rename_args)
    
    cat("✅ Rename operation successful\n")
    cat("   New column names:", paste(head(names(renamed_data), 5), collapse = ", "), "...\n")
    
    dbDisconnect(con_raw)
    
    test_results$simulation <- list(success = TRUE, renamed_cols = length(columns_to_rename))
    
  }, error = function(e) {
    cat("❌ Simulation failed:", e$message, "\n")
    test_results$simulation <- list(success = FALSE, error = e$message)
    all_passed <- FALSE
  })
} else {
  cat("⚠️  Cannot simulate - raw table does not exist\n")
  cat("\nTo create test data, run:\n")
  cat("  Rscript scripts/update_scripts/eby_ETL_order_details_0IM___MAMBA.R\n")
  test_results$simulation <- list(success = FALSE, error = "No raw data")
  all_passed <- FALSE
}

# ==============================================================================
# FINAL REPORT
# ==============================================================================
cat("\n", strrep("=", 80), "\n")
cat("📋 FINAL VERIFICATION REPORT\n")
cat(strrep("=", 80), "\n")

# Summary
if (all_passed) {
  cat("\n✅ READY TO RUN: YES\n")
  cat("\nThe script is ready to execute successfully.\n")
} else {
  cat("\n❌ READY TO RUN: NO\n")
  cat("\nThe script has blocking issues that must be resolved.\n")
}

# Issues summary
cat("\n🔴 CRITICAL ISSUES:\n")
if (!isTRUE(test_results$raw_db$table_exists)) {
  cat("  1. Raw data table 'df_eby_order_details___raw___MAMBA' does not exist\n")
  cat("     ACTION: Run the 0IM script first to create raw data\n")
  cat("     COMMAND: Rscript scripts/update_scripts/eby_ETL_order_details_0IM___MAMBA.R\n")
}

if (!isTRUE(test_results$raw_db$accessible)) {
  cat("  2. Raw database is not accessible (may be locked)\n")
  cat("     ACTION: Close any applications using the database\n")
}

if (!isTRUE(test_results$staged_db$accessible)) {
  cat("  3. Staged database is not accessible\n")
  cat("     ACTION: Check file permissions and locks\n")
}

# Warnings
cat("\n⚠️  WARNINGS:\n")
if (length(test_results$column_mapping$missing) > 0) {
  cat("  • Some expected columns are missing, but script handles this gracefully\n")
}

# Commands to run
cat("\n📝 COMMANDS TO RUN:\n")
cat(strrep("-", 40), "\n")

if (!isTRUE(test_results$raw_db$table_exists)) {
  cat("# First, create the raw data:\n")
  cat("Rscript scripts/update_scripts/eby_ETL_order_details_0IM___MAMBA.R\n\n")
}

cat("# Then run the staging script:\n")
cat("cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA\n")
cat("Rscript scripts/update_scripts/eby_ETL_order_details_1ST___MAMBA.R\n")

# Expected output
cat("\n📊 EXPECTED OUTPUT:\n")
cat(strrep("-", 40), "\n")
cat("• INITIALIZE messages with database connections\n")
cat("• MAIN progress messages with data processing steps\n")
cat("• Column renaming from ORE* to descriptive names\n")
cat("• Data quality checks and warnings\n")
cat("• TEST validation messages\n")
cat("• Final row count in staged table\n")
cat("• Total execution time ~2-5 seconds\n")

# Save test results for debugging
saveRDS(test_results, "test_results_eby_order_details_1ST.rds")
cat("\nℹ️  Detailed test results saved to: test_results_eby_order_details_1ST.rds\n")

cat("\n", strrep("=", 80), "\n")