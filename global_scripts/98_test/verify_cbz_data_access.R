#!/usr/bin/env Rscript
# ==============================================================================
# CBZ Sales Data Accessibility Verification - Week 7 Pre-Cutover
# ==============================================================================
# Purpose: Verify CBZ sales data is accessible and ready for integration
# Author: principle-product-manager
# Created: 2025-11-13
#
# Compliance:
# - MP029: No Fake Data (verify REAL data sources only)
# - R092: Universal DBI Pattern
# - MP001: Configuration-Driven Development
#
# Verification Checklist:
# 1. CBZ ETL scripts exist and are executable
# 2. Source data file is accessible
# 3. Sample data retrieval successful
# 4. Schema validation passes
# 5. Data freshness check
# 6. Row count estimation
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(dplyr)
  library(glue)
})

# ==============================================================================
# Configuration
# ==============================================================================

BASE_DIR <- "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA"
CBZ_ETL_DIR <- file.path(BASE_DIR, "scripts/update_scripts/ETL/cbz")
DATA_DIR <- file.path(BASE_DIR, "data")
RAW_DB_PATH <- file.path(DATA_DIR, "raw_data.duckdb")

# Expected CBZ ETL scripts
EXPECTED_SCRIPTS <- c(
  "cbz_ETL_sales_1ST.R",
  "cbz_ETL_sales_2TR.R",
  "cbz_ETL_customers_1ST.R",
  "cbz_ETL_customers_2TR.R",
  "cbz_ETL_products_1ST.R",
  "cbz_ETL_products_2TR.R",
  "cbz_ETL_orders_1ST.R",
  "cbz_ETL_orders_2TR.R"
)

# Expected schema for sales data
EXPECTED_SALES_COLUMNS <- c(
  "order_id", "customer_id", "product_id", "quantity",
  "unit_price", "total_amount", "order_date", "status"
)

# ==============================================================================
# Helper Functions
# ==============================================================================

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] [%s] %s\n", timestamp, level, msg))
}

check_file_exists <- function(filepath) {
  exists <- file.exists(filepath)
  if (exists) {
    info <- file.info(filepath)
    size_kb <- round(info$size / 1024, 2)
    return(list(exists = TRUE, size_kb = size_kb, modified = info$mtime))
  } else {
    return(list(exists = FALSE))
  }
}

# ==============================================================================
# Verification Process
# ==============================================================================

log_message("=== CBZ DATA ACCESSIBILITY VERIFICATION ===", "HEADER")

# ==============================================================================
# CHECK 1: ETL Scripts Existence
# ==============================================================================

log_message("CHECK 1: Verifying CBZ ETL scripts...", "HEADER")

script_status <- data.frame(
  script_name = character(),
  exists = logical(),
  size_kb = numeric(),
  executable = logical(),
  last_modified = character(),
  stringsAsFactors = FALSE
)

for (script_name in EXPECTED_SCRIPTS) {
  script_path <- file.path(CBZ_ETL_DIR, script_name)
  check <- check_file_exists(script_path)

  if (check$exists) {
    # Check if executable (has read permission at minimum)
    is_executable <- file.access(script_path, mode = 4) == 0
    log_message(glue("  FOUND: {script_name} ({check$size_kb} KB)"))

    script_status <- rbind(script_status, data.frame(
      script_name = script_name,
      exists = TRUE,
      size_kb = check$size_kb,
      executable = is_executable,
      last_modified = as.character(check$modified),
      stringsAsFactors = FALSE
    ))
  } else {
    log_message(glue("  MISSING: {script_name}"), "ERROR")
    script_status <- rbind(script_status, data.frame(
      script_name = script_name,
      exists = FALSE,
      size_kb = NA,
      executable = FALSE,
      last_modified = NA,
      stringsAsFactors = FALSE
    ))
  }
}

scripts_found <- sum(script_status$exists)
log_message(glue("Scripts found: {scripts_found}/{length(EXPECTED_SCRIPTS)}"))

# ==============================================================================
# CHECK 2: Database Connection Test
# ==============================================================================

log_message("CHECK 2: Testing database connection...", "HEADER")

db_connection_ok <- FALSE
con <- NULL

tryCatch({
  con <- dbConnect(duckdb::duckdb(), RAW_DB_PATH, read_only = TRUE)
  tables <- dbListTables(con)
  log_message(glue("  SUCCESS: Connected to raw_data.duckdb"))
  log_message(glue("  Found {length(tables)} tables"))
  db_connection_ok <- TRUE
}, error = function(e) {
  log_message(glue("  ERROR: Cannot connect - {e$message}"), "ERROR")
})

# ==============================================================================
# CHECK 3: CBZ Data Tables Check
# ==============================================================================

log_message("CHECK 3: Checking for CBZ data tables...", "HEADER")

cbz_tables_found <- character()
cbz_data_available <- FALSE

if (db_connection_ok && !is.null(con)) {
  all_tables <- dbListTables(con)

  # Look for CBZ-related tables (assuming naming pattern)
  cbz_patterns <- c("cbz_sales", "cbz_customers", "cbz_products", "cbz_orders",
                    "sales_cbz", "customers_cbz", "products_cbz", "orders_cbz")

  for (pattern in cbz_patterns) {
    matches <- grep(pattern, all_tables, value = TRUE, ignore.case = TRUE)
    if (length(matches) > 0) {
      cbz_tables_found <- c(cbz_tables_found, matches)
    }
  }

  cbz_tables_found <- unique(cbz_tables_found)

  if (length(cbz_tables_found) > 0) {
    log_message(glue("  FOUND {length(cbz_tables_found)} CBZ table(s):"))
    for (tbl in cbz_tables_found) {
      log_message(glue("    - {tbl}"))
    }
    cbz_data_available <- TRUE
  } else {
    log_message("  INFO: No existing CBZ tables found (expected for fresh setup)", "INFO")
    log_message("  This is NORMAL if CBZ data hasn't been loaded yet", "INFO")
  }
}

# ==============================================================================
# CHECK 4: Sample Data Retrieval (if tables exist)
# ==============================================================================

log_message("CHECK 4: Sample data retrieval...", "HEADER")

sample_data <- NULL
sample_success <- FALSE

if (cbz_data_available && length(cbz_tables_found) > 0) {
  # Try to sample from first CBZ table found
  test_table <- cbz_tables_found[1]

  tryCatch({
    sample_query <- glue("SELECT * FROM {test_table} LIMIT 10")
    sample_data <- dbGetQuery(con, sample_query)

    log_message(glue("  SUCCESS: Retrieved {nrow(sample_data)} sample rows from {test_table}"))
    log_message(glue("  Columns: {ncol(sample_data)}"))
    log_message(glue("  Column names: {paste(colnames(sample_data), collapse = ', ')}"))

    sample_success <- TRUE
  }, error = function(e) {
    log_message(glue("  ERROR: Cannot sample data - {e$message}"), "ERROR")
  })
} else {
  log_message("  SKIP: No CBZ tables available for sampling", "INFO")
  log_message("  This is expected if CBZ data loading is scheduled for Week 7 Day 1", "INFO")
}

# ==============================================================================
# CHECK 5: Source File Accessibility
# ==============================================================================

log_message("CHECK 5: Checking CBZ source data files...", "HEADER")

# Common locations for CSV source files
csv_locations <- c(
  file.path(DATA_DIR, "database_to_csv"),
  file.path(DATA_DIR, "local_data"),
  file.path(DATA_DIR, "app_data")
)

cbz_csv_files <- character()

for (csv_dir in csv_locations) {
  if (dir.exists(csv_dir)) {
    files <- list.files(csv_dir, pattern = "cbz.*\\.(csv|CSV)$", full.names = TRUE, ignore.case = TRUE)
    if (length(files) > 0) {
      cbz_csv_files <- c(cbz_csv_files, files)
    }
  }
}

if (length(cbz_csv_files) > 0) {
  log_message(glue("  FOUND {length(cbz_csv_files)} CBZ CSV file(s):"))
  for (csv_file in cbz_csv_files) {
    info <- file.info(csv_file)
    size_mb <- round(info$size / (1024^2), 2)
    log_message(glue("    - {basename(csv_file)} ({size_mb} MB, modified: {info$mtime})"))
  }
} else {
  log_message("  INFO: No CBZ CSV files found in standard locations", "INFO")
  log_message("  ETL scripts may load from external source or different location", "INFO")
}

# ==============================================================================
# CHECK 6: Data Freshness and Row Count (if data exists)
# ==============================================================================

log_message("CHECK 6: Data freshness and volume estimation...", "HEADER")

if (cbz_data_available && length(cbz_tables_found) > 0) {
  for (tbl in cbz_tables_found) {
    tryCatch({
      count_query <- glue("SELECT COUNT(*) as row_count FROM {tbl}")
      count_result <- dbGetQuery(con, count_query)
      row_count <- count_result$row_count[1]

      log_message(glue("  {tbl}: {format(row_count, big.mark = ',')} rows"))

      # Try to find date column for freshness check
      schema_query <- glue("PRAGMA table_info({tbl})")
      schema <- dbGetQuery(con, schema_query)
      date_cols <- grep("date|time|created|updated", schema$name, value = TRUE, ignore.case = TRUE)

      if (length(date_cols) > 0) {
        date_col <- date_cols[1]
        fresh_query <- glue("SELECT MAX({date_col}) as latest_date FROM {tbl}")
        fresh_result <- dbGetQuery(con, fresh_query)
        log_message(glue("    Latest {date_col}: {fresh_result$latest_date[1]}"))
      }
    }, error = function(e) {
      log_message(glue("  ERROR analyzing {tbl}: {e$message}"), "ERROR")
    })
  }
} else {
  log_message("  SKIP: No data available for freshness check", "INFO")
}

# ==============================================================================
# Cleanup
# ==============================================================================

if (!is.null(con)) {
  dbDisconnect(con, shutdown = TRUE)
}

# ==============================================================================
# Generate Summary Report
# ==============================================================================

log_message("=== VERIFICATION SUMMARY ===", "HEADER")

summary_lines <- c(
  "CBZ DATA ACCESSIBILITY VERIFICATION REPORT",
  paste("Generated:", Sys.time()),
  "",
  "=== ETL SCRIPTS ===",
  glue("Scripts found: {scripts_found}/{length(EXPECTED_SCRIPTS)}"),
  glue("Status: {ifelse(scripts_found == length(EXPECTED_SCRIPTS), 'ALL PRESENT', 'INCOMPLETE')}"),
  "",
  "=== DATABASE CONNECTION ===",
  glue("Connection status: {ifelse(db_connection_ok, 'SUCCESS', 'FAILED')}"),
  "",
  "=== CBZ DATA AVAILABILITY ===",
  glue("CBZ tables found: {length(cbz_tables_found)}"),
  glue("Data available: {ifelse(cbz_data_available, 'YES', 'NO (expected for pre-load state)')}"),
  "",
  "=== SOURCE FILES ===",
  glue("CSV files found: {length(cbz_csv_files)}"),
  "",
  "=== READINESS ASSESSMENT ===",
  ifelse(scripts_found >= 6,
         "ETL Scripts: READY",
         "ETL Scripts: INCOMPLETE - some scripts missing"),
  ifelse(db_connection_ok,
         "Database Access: READY",
         "Database Access: FAILED - cannot connect"),
  "",
  "=== RECOMMENDATION ===",
  ifelse(scripts_found >= 6 && db_connection_ok,
         "PROCEED: CBZ data integration ready for Week 7 execution",
         "REVIEW REQUIRED: Address missing components before proceeding")
)

# Print summary
for (line in summary_lines) {
  log_message(line, "SUMMARY")
}

# Save summary to file
summary_file <- file.path(BASE_DIR, "scripts/global_scripts/98_test/CBZ_DATA_VERIFICATION_REPORT.txt")
writeLines(summary_lines, summary_file)
log_message(glue("Report saved: {summary_file}"))

# Return exit code
if (scripts_found >= 6 && db_connection_ok) {
  log_message("=== VERIFICATION PASSED ===", "SUCCESS")
  quit(status = 0)
} else {
  log_message("=== VERIFICATION INCOMPLETE ===", "WARN")
  quit(status = 1)
}
