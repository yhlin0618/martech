#####
# DERIVATION: {NAME}
# VERSION: 1.0
# PLATFORM: {cbz|amz|eby|all}
# GROUP: D{nn}
# SEQUENCE: {seq}
# PURPOSE: {one-line description}
# CONSUMES: {ETL output tables}
# PRODUCES: {derived tables/views}
# PRINCIPLE: MP064, DM_R042, DM_R044
#####
#P{platform_number}_D{group}_{sequence}

#' @title {Descriptive Title}
#' @description {Detailed description of derivation logic and business rules}
#' @param {parameter_name} {description} (if applicable)
#' @return List containing execution metrics and status
#' @requires DBI dplyr tidyr
#' @input_tables {list of input tables from ETL}
#' @output_tables {list of output tables produced}
#' @business_rules {documentation of business logic applied}
#' @platform {platform_id}
#' @author {original author}
#' @modified_by {modifier name}
#' @date {YYYY-MM-DD}
#' @update_log {
#'   YYYY-MM-DD: Initial creation
#'   YYYY-MM-DD: Description of changes
#' }

# ==============================================================================
# PART 1: INITIALIZE
# ==============================================================================
# Setup environment and connections

# 1.1: Environment Setup
autoinit()  # Standard initialization

# 1.2: Database Connections
# Track which connections this script creates
connection_created_processed <- FALSE
connection_created_app <- FALSE

# Connect to required databases with proper error handling
if (!exists("processed_data") || !inherits(processed_data, "DBIConnection")) {
  processed_data <- dbConnectDuckdb(db_path_list$processed_data, read_only = TRUE)
  connection_created_processed <- TRUE
  message(sprintf("[%s] Connected to processed_data database",
                 format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
}

if (!exists("app_data") || !inherits(app_data, "DBIConnection")) {
  app_data <- dbConnectDuckdb(db_path_list$app_data, read_only = FALSE)
  connection_created_app <- TRUE
  message(sprintf("[%s] Connected to app_data database",
                 format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
}

# 1.3: Load Dependencies
# Source any required utility functions
# Example: source("path/to/utility_functions.R")

# 1.4: Initialize Tracking Variables
error_occurred <- FALSE
test_passed <- FALSE
rows_processed <- 0
start_time <- Sys.time()
script_name <- basename(commandArgs()[4])

# Extract platform and derivation info from filename
platform <- substr(script_name, 1, 3)
derivation_info <- sub("^[a-z]{3}_D([0-9]{2})_([0-9]{2})\\.R$", "D\\1_\\2", script_name)

# ==============================================================================
# PART 2: MAIN
# ==============================================================================
# Core derivation logic

tryCatch({
  # 2.1: Log Processing Start
  message(sprintf("[%s] Starting derivation: %s for platform: %s",
                 format(start_time, "%Y-%m-%d %H:%M:%S"),
                 derivation_info,
                 toupper(platform)))

  # 2.2: Validate Input Tables
  # Define required input tables
  required_tables <- c(
    # Add your required ETL output tables here
    # Example: "df_{platform}_sales___standardized", "df_customer_standardized"
  )

  for (table in required_tables) {
    if (!dbExistsTable(processed_data, table)) {
      stop(sprintf("Required input table '%s' does not exist in processed_data", table))
    }

    # Check if table has data
    row_count <- tbl(processed_data, table) %>%
      summarize(n = n()) %>%
      pull(n)

    if (row_count == 0) {
      warning(sprintf("Input table '%s' is empty", table))
    } else {
      message(sprintf("  ✓ Found %d rows in %s", row_count, table))
    }
  }

  # 2.3: Load ETL Output Data
  # Example: Load and prepare input data
  # df_input <- tbl(processed_data, "df_{platform}_sales___standardized") %>%
  #   filter(platform_id == !!platform) %>%
  #   collect()

  # message(sprintf("Loaded %d rows from input table", nrow(df_input)))

  # 2.4: Apply Business Logic
  # ============================================
  # INSERT YOUR DERIVATION LOGIC HERE
  # ============================================

  # Example derivation pattern:
  # df_derived <- df_input %>%
  #   group_by(customer_id, platform_id) %>%
  #   summarize(
  #     # Add your aggregation logic
  #     .groups = "drop"
  #   ) %>%
  #   mutate(
  #     # Add calculated fields
  #   )

  # rows_processed <- nrow(df_derived)

  # 2.5: Write Derived Output
  # Example: Save results to app_data
  # dbWriteTable(
  #   app_data,
  #   "df_output_table_name",
  #   df_derived,
  #   append = FALSE,
  #   overwrite = TRUE
  # )

  # message(sprintf("Wrote %d rows to output table", rows_processed))

  # 2.6: Create Additional Views or Indexes (if needed)
  # Example: Create filtered views
  # dbExecute(app_data, "
  #   CREATE OR REPLACE VIEW v_active_customers AS
  #   SELECT * FROM df_customer_metrics
  #   WHERE days_since_last <= 30
  # ")

}, error = function(e) {
  message(sprintf("ERROR in MAIN: %s", e$message))
  error_occurred <- TRUE
})

# ==============================================================================
# PART 3: TEST
# ==============================================================================
# Verify derivation results

if (!error_occurred) {
  tryCatch({
    message("\nRunning validation tests...")

    # 3.1: Verify Output Table Exists
    # output_table <- "df_output_table_name"  # Update with your table name
    # if (!dbExistsTable(app_data, output_table)) {
    #   stop(sprintf("Output table '%s' was not created", output_table))
    # }

    # 3.2: Validate Output Structure
    # output_check <- tbl(app_data, output_table) %>%
    #   head(5) %>%
    #   collect()

    # Define expected columns
    # required_columns <- c(
    #   # List your required output columns
    # )

    # missing_columns <- setdiff(required_columns, colnames(output_check))
    # if (length(missing_columns) > 0) {
    #   stop(sprintf("Missing required columns: %s",
    #               paste(missing_columns, collapse = ", ")))
    # }

    # 3.3: Validate Business Rules
    # Add specific business rule validations
    # Example: Check for negative values, NULL constraints, etc.

    # invalid_records <- output_check %>%
    #   filter(
    #     # Add your validation conditions
    #   )

    # if (nrow(invalid_records) > 0) {
    #   warning(sprintf("Found %d records violating business rules",
    #                  nrow(invalid_records)))
    # }

    # 3.4: Check Row Counts
    # output_rows <- tbl(app_data, output_table) %>%
    #   summarize(n = n()) %>%
    #   pull(n)

    # if (output_rows != rows_processed) {
    #   warning(sprintf("Row count mismatch: processed %d, wrote %d",
    #                  rows_processed, output_rows))
    # }

    # 3.5: Data Quality Checks
    # Add specific data quality validations relevant to your derivation

    message("✅ All validation tests passed successfully")
    test_passed <- TRUE

  }, error = function(e) {
    message(sprintf("ERROR in TEST: %s", e$message))
    test_passed <- FALSE
  })
} else {
  message("Skipping tests due to error in MAIN section")
  test_passed <- FALSE
}

# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================
# Report metrics and prepare return values

# 4.1: Calculate Execution Metrics
end_time <- Sys.time()
execution_time <- difftime(end_time, start_time, units = "secs")

# 4.2: Generate Summary Report
summary_report <- list(
  script = script_name,
  platform = platform,
  derivation = derivation_info,
  start_time = start_time,
  end_time = end_time,
  execution_time_secs = as.numeric(execution_time),
  rows_processed = rows_processed,
  status = ifelse(test_passed && !error_occurred, "SUCCESS", "FAILED"),
  error_occurred = error_occurred,
  test_passed = test_passed
)

# 4.3: Log Summary
message("\n" %+% paste(rep("=", 70), collapse = ""))
message("DERIVATION EXECUTION SUMMARY")
message(paste(rep("=", 70), collapse = ""))
message(sprintf("Script:          %s", summary_report$script))
message(sprintf("Platform:        %s", toupper(summary_report$platform)))
message(sprintf("Derivation:      %s", summary_report$derivation))
message(sprintf("Status:          %s", summary_report$status))
message(sprintf("Rows Processed:  %s", format(summary_report$rows_processed, big.mark = ",")))
message(sprintf("Execution Time:  %.2f seconds", summary_report$execution_time_secs))
message(sprintf("Start Time:      %s", format(summary_report$start_time, "%Y-%m-%d %H:%M:%S")))
message(sprintf("End Time:        %s", format(summary_report$end_time, "%Y-%m-%d %H:%M:%S")))
message(paste(rep("=", 70), collapse = ""))

# 4.4: Write Execution Log (optional)
if (exists("execution_log_path") && !is.null(execution_log_path)) {
  log_entry <- data.frame(summary_report, stringsAsFactors = FALSE)
  log_file <- file.path(execution_log_path,
                       sprintf("df_log_%s_%s.csv",
                              platform,
                              format(Sys.time(), "%Y%m%d_%H%M%S")))

  tryCatch({
    write.csv(log_entry, log_file, row.names = FALSE)
    message(sprintf("Execution log written to: %s", log_file))
  }, error = function(e) {
    warning(sprintf("Could not write execution log: %s", e$message))
  })
}

# 4.5: Prepare Return Value
return_value <- summary_report

# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
# MANDATORY: Cleanup and resource deallocation ONLY

# 5.1: Close Database Connections (only those created by this script)
if (exists("connection_created_processed") && connection_created_processed) {
  if (exists("processed_data") && inherits(processed_data, "DBIConnection")) {
    tryCatch({
      dbDisconnect(processed_data)
      message("Disconnected from processed_data database")
    }, error = function(e) {
      warning(sprintf("Could not disconnect from processed_data: %s", e$message))
    })
  }
}

if (exists("connection_created_app") && connection_created_app) {
  if (exists("app_data") && inherits(app_data, "DBIConnection")) {
    tryCatch({
      dbDisconnect(app_data)
      message("Disconnected from app_data database")
    }, error = function(e) {
      warning(sprintf("Could not disconnect from app_data: %s", e$message))
    })
  }
}

# 5.2: Prepare Final Return Value
if (exists("return_value")) {
  final_status <- return_value
} else {
  final_status <- list(
    status = "INCOMPLETE",
    error = "No return value generated",
    script = ifelse(exists("script_name"), script_name, "unknown")
  )
}

# 5.3: Final Message
message(sprintf("\n[%s] Derivation %s completed with status: %s\n",
               format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
               ifelse(exists("derivation_info"), derivation_info, "unknown"),
               final_status$status))

# 5.4: Autodeinit (MUST be last statement)
autodeinit()

# Return the final status
final_status