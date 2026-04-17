#!/usr/bin/env Rscript
# ==============================================================================
# Five-Part Update Script Template (PRIMARY STANDARD)
# ==============================================================================
# Template for creating standardized update scripts with the PRIMARY five-part structure
# INITIALIZE → MAIN → TEST → SUMMARIZE → DEINITIALIZE
# 
# This is the PRIMARY template for all new scripts. It completely solves the 
# autodeinit() variable access problem by separating reporting from cleanup.
#
# Implements Principles:
# - DEV_R033: Five-Part Script Structure (PRIMARY STANDARD)
# - MP104: Script Organization Evolution 
# - MP103: autodeinit() Behavior (proper handling)
# - MP036: Initialization First
# - MP038: Deinitialization Final
#
# Benefits over four-part structure:
# - ✅ No autodeinit() variable access errors
# - ✅ Clean separation of concerns
# - ✅ Return values work naturally
# - ✅ All reporting in SUMMARIZE with full variable access
# - ✅ DEINITIALIZE only does cleanup
# ==============================================================================

# [SCRIPT_NAME].R - [BRIEF_DESCRIPTION]
# Author: [YOUR_NAME]
# Date: [DATE]
# Purpose: [DETAILED_PURPOSE]

# ==============================================================================
# PART 1: INITIALIZE
# ==============================================================================
# Setup environment, load dependencies, establish connections

message("=" * 70)
message("INITIALIZE: Starting [SCRIPT_NAME]")
message("=" * 70)

# Track script timing
script_start_time <- Sys.time()
init_start_time <- Sys.time()

# Initialize execution tracking variables
main_error <- FALSE
test_passed <- FALSE
rows_processed <- 0
warnings_count <- 0

# Source appropriate initialization
# source("scripts/global_scripts/22_initializations/sc_initialization_update_mode.R")
# OR for ETL scripts:
# source("scripts/global_scripts/22_initializations/sc_initialization_etl_mode.R")

# Initialize using autoinit system if needed
# Set required dependencies before initialization
# needpackages <- c("dplyr", "tidyr", "DBI")
# autoinit()

# Establish database connections
# Example:
# if (!exists("con") || !DBI::dbIsValid(con)) {
#   con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "data.duckdb")
#   connection_created <- TRUE
#   message("  Connected to database")
# } else {
#   connection_created <- FALSE
# }

init_elapsed <- as.numeric(Sys.time() - init_start_time, units = "secs")
message(sprintf("INITIALIZE: Complete (%.2fs)", init_elapsed))

# ==============================================================================
# PART 2: MAIN
# ==============================================================================
# Core processing logic with error handling

message("-" * 70)
message("MAIN: Starting core processing...")
main_start_time <- Sys.time()

tryCatch({
  # TODO: Add your main processing logic here
  # Example ETL processing:
  # df_raw <- DBI::dbReadTable(con, "raw_data")
  # 
  # df_processed <- df_raw %>%
  #   filter(!is.na(key_field)) %>%
  #   mutate(
  #     processed_date = Sys.Date(),
  #     status = "processed"
  #   ) %>%
  #   group_by(category) %>%
  #   summarize(
  #     count = n(),
  #     total = sum(amount, na.rm = TRUE)
  #   )
  # 
  # DBI::dbWriteTable(con, "processed_data", df_processed, overwrite = TRUE)
  # rows_processed <- nrow(df_processed)
  
  message(sprintf("  Processed %d rows successfully", rows_processed))
  
}, error = function(e) {
  message("ERROR in MAIN: ", e$message)
  main_error <<- TRUE
}, warning = function(w) {
  message("WARNING in MAIN: ", w$message)
  warnings_count <<- warnings_count + 1
})

main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
message(sprintf("MAIN: Complete (%.2fs)", main_elapsed))

# ==============================================================================
# PART 3: TEST
# ==============================================================================
# Verify that changes were applied correctly

message("-" * 70)

if (!main_error) {
  message("TEST: Verifying results...")
  test_start_time <- Sys.time()
  
  tryCatch({
    # TODO: Add your verification logic here
    # Example verification:
    # table_exists <- DBI::dbExistsTable(con, "processed_data")
    # 
    # if (table_exists) {
    #   row_count <- DBI::dbGetQuery(con, 
    #     "SELECT COUNT(*) as n FROM processed_data")$n
    #   
    #   if (row_count > 0) {
    #     message(sprintf("  ✓ Table exists with %d rows", row_count))
    #     test_passed <- TRUE
    #   } else {
    #     message("  ✗ Table exists but is empty")
    #     test_passed <- FALSE
    #   }
    # } else {
    #   message("  ✗ Target table does not exist")
    #   test_passed <- FALSE
    # }
    
    # Set test result
    test_passed <- TRUE  # TODO: Set based on actual verification
    
    if (test_passed) {
      message("  ✓ All tests passed")
    } else {
      message("  ✗ Some tests failed")
    }
    
  }, error = function(e) {
    message("ERROR in TEST: ", e$message)
    test_passed <<- FALSE
  })
  
  test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
  message(sprintf("TEST: Complete (%.2fs)", test_elapsed))
  
} else {
  message("TEST: Skipped due to MAIN error")
  test_passed <- FALSE
}

# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================
# Generate reports, prepare return values, log metrics
# ALL variables are still accessible here!

message("=" * 70)
message("📊 SUMMARIZE: Generating execution summary...")
summary_start_time <- Sys.time()

# Calculate total execution time so far
total_elapsed <- as.numeric(Sys.time() - script_start_time, units = "secs")

# Compile comprehensive metrics (all variables still exist!)
final_metrics <- list(
  success = !main_error && test_passed,
  rows_processed = rows_processed,
  warnings = warnings_count,
  execution_time = total_elapsed,
  memory_used = sum(gc()[, "(Mb)"]),
  timestamp = Sys.time()
)

# Generate detailed summary report
message("=" * 70)
message("📋 SCRIPT EXECUTION SUMMARY")
message("=" * 70)
message(sprintf("  Script: %s", "[SCRIPT_NAME]"))
message(sprintf("  Status: %s", 
  ifelse(final_metrics$success, "✅ SUCCESS", "❌ FAILED")))
message(sprintf("  Rows Processed: %d", final_metrics$rows_processed))
message(sprintf("  Warnings: %d", final_metrics$warnings))
message(sprintf("  Total Time: %.2fs", final_metrics$execution_time))
message(sprintf("  Memory Used: %.1f MB", final_metrics$memory_used))
message(sprintf("  Completed: %s", 
  format(final_metrics$timestamp, "%Y-%m-%d %H:%M:%S")))

# Performance breakdown
message("-" * 70)
message("⏱️  PERFORMANCE BREAKDOWN:")
message(sprintf("  Initialize: %.2fs (%.1f%%)", 
  init_elapsed, 100 * init_elapsed / total_elapsed))
message(sprintf("  Main:       %.2fs (%.1f%%)", 
  main_elapsed, 100 * main_elapsed / total_elapsed))
if (exists("test_elapsed")) {
  message(sprintf("  Test:       %.2fs (%.1f%%)", 
    test_elapsed, 100 * test_elapsed / total_elapsed))
}
message(sprintf("  Summarize:  %.2fs", 
  as.numeric(Sys.time() - summary_start_time, units = "secs")))

# Prepare return value for pipeline orchestration
# This is SAFE because we're in SUMMARIZE, not DEINITIALIZE!
final_return_status <- final_metrics$success

# Optional: Save metrics for external monitoring
if (Sys.getenv("SAVE_METRICS", "FALSE") == "TRUE") {
  metrics_dir <- "metrics"
  if (!dir.exists(metrics_dir)) dir.create(metrics_dir)
  
  metrics_file <- file.path(metrics_dir, 
    sprintf("run_%s_%s.rds", 
      "[SCRIPT_NAME]",
      format(Sys.time(), "%Y%m%d_%H%M%S")))
  
  saveRDS(final_metrics, metrics_file)
  message(sprintf("  Metrics saved to: %s", metrics_file))
}

# Optional: Save status for ETL pipeline orchestration
if (Sys.getenv("ETL_PIPELINE", "FALSE") == "TRUE") {
  saveRDS(final_return_status, "etl_status.rds")
  message("  Pipeline status saved")
}

summary_elapsed <- as.numeric(Sys.time() - summary_start_time, units = "secs")
message(sprintf("SUMMARIZE: Complete (%.2fs)", summary_elapsed))
message("=" * 70)

# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
# MANDATORY: Only cleanup operations
# autodeinit() must be the absolute last statement
# NO variable access, NO reporting - everything was done in SUMMARIZE!

message("DEINITIALIZE: Cleaning up resources...")

# Close any connections created in this script
# if (exists("connection_created") && connection_created) {
#   if (exists("con") && DBI::dbIsValid(con)) {
#     DBI::dbDisconnect(con)
#     message("  Database connection closed")
#   }
# }

# Optional: Make cleanup conditional for debugging
cleanup_enabled <- Sys.getenv("SKIP_CLEANUP", "FALSE") != "TRUE"

if (cleanup_enabled) {
  # Final cleanup - removes ALL variables!
  # This is now SAFE because all reporting was done in SUMMARIZE
  autodeinit()
  # NO CODE AFTER THIS LINE - all variables are gone!
} else {
  message("  Cleanup skipped (debug mode)")
}

# ==============================================================================
# END OF SCRIPT
# ==============================================================================

# TODO: Replace all [PLACEHOLDER] values with actual content:
# - [SCRIPT_NAME]: Name of your script (e.g., "update_sales_data")
# - [BRIEF_DESCRIPTION]: One-line description
# - [YOUR_NAME]: Your name
# - [DATE]: Today's date
# - [DETAILED_PURPOSE]: Full description of script purpose
# 
# Benefits of this five-part structure:
# 1. No autodeinit() variable access problems
# 2. Clean separation of reporting (SUMMARIZE) and cleanup (DEINITIALIZE)
# 3. Return values work naturally
# 4. Easy to debug by skipping DEINITIALIZE
# 5. Follows PRIMARY architectural standard (MP104)