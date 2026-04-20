#!/usr/bin/env Rscript
################################################################################
# Phase 1: Verify eBay Prerequisites for Poisson DRV
################################################################################
#
# PURPOSE: Check if eBay time series data exists before running Poisson DRV
#
# USAGE: Rscript verify_eby_prerequisites.R
#
# CHECKS:
#   1. Database file exists
#   2. Required time series tables exist
#   3. Tables have data (not empty)
#   4. Required columns present
#
# OUTPUT:
#   - ✅ READY: Can proceed to run eBay Poisson DRV
#   - ❌ BLOCKED: Must run eBay ETL pipeline first
#
################################################################################

# Suppress package loading messages
suppressPackageStartupMessages({
  # Use base R only - no package dependencies
})

cat("\n")
cat("═══════════════════════════════════════════════════════════════════\n")
cat("Phase 1: eBay Poisson DRV Prerequisites Verification\n")
cat("═══════════════════════════════════════════════════════════════════\n\n")

# Database path
db_path <- "data/app_data/app_data.duckdb"

# Check 1: Database file exists
cat("[Check 1/4] Database file exists...\n")
if (!file.exists(db_path)) {
  cat("  ❌ BLOCKER: Database not found at:", db_path, "\n")
  cat("  → Must create database first\n\n")
  quit(status = 1)
}

cat(sprintf("  ✓ Database found: %s (%.1f MB)\n",
            db_path,
            file.info(db_path)$size / 1024^2))
cat("\n")

# Load DuckDB (try to use system library)
cat("[Check 2/4] Loading DuckDB...\n")

# Try to load packages
tryCatch({
  library(DBI, warn.conflicts = FALSE, quietly = TRUE)
  library(duckdb, warn.conflicts = FALSE, quietly = TRUE)
  cat("  ✓ DuckDB loaded successfully\n\n")
}, error = function(e) {
  cat("  ❌ BLOCKER: Cannot load DuckDB package\n")
  cat("  → Error:", conditionMessage(e), "\n")
  cat("  → Install with: install.packages('duckdb')\n\n")
  quit(status = 1)
})

# Connect to database
cat("[Check 3/4] Connecting to database...\n")
con <- NULL
tryCatch({
  con <- dbConnect(duckdb(), db_path, read_only = TRUE)
  cat("  ✓ Connected successfully\n\n")
}, error = function(e) {
  cat("  ❌ BLOCKER: Cannot connect to database\n")
  cat("  → Error:", conditionMessage(e), "\n\n")
  quit(status = 1)
})

# Check 2: Time series tables exist
cat("[Check 4/4] Checking for eBay time series tables...\n")

# Expected tables
PRODUCT_LINES <- c("alf", "irf", "pre", "rek", "tur", "wak")
expected_tables <- sprintf("df_eby_sales_complete_time_series_%s", PRODUCT_LINES)

# List all tables
all_tables <- dbListTables(con)

# Find eBay time series tables
found_tables <- intersect(expected_tables, all_tables)
missing_tables <- setdiff(expected_tables, all_tables)

cat(sprintf("  → Expected: %d tables\n", length(expected_tables)))
cat(sprintf("  → Found: %d tables\n", length(found_tables)))

if (length(found_tables) > 0) {
  cat("\n  ✓ Found tables:\n")

  # Check each table
  all_ready <- TRUE
  for (tbl in found_tables) {
    row_count <- tryCatch({
      dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
    }, error = function(e) {
      0
    })

    # Get columns
    cols <- tryCatch({
      dbListFields(con, tbl)
    }, error = function(e) {
      character(0)
    })

    # Check for required columns
    required_cols <- c("sales", "order_date")
    has_required <- all(required_cols %in% cols)

    # Product line code
    pl_code <- toupper(sub("df_eby_sales_complete_time_series_", "", tbl))

    # Status
    if (row_count == 0) {
      cat(sprintf("    ❌ %s: EMPTY (0 rows)\n", pl_code))
      all_ready <- FALSE
    } else if (!has_required) {
      cat(sprintf("    ⚠️  %s: %s rows, missing required columns\n",
                  pl_code, format(row_count, big.mark=",")))
      all_ready <- FALSE
    } else {
      cat(sprintf("    ✓ %s: %s rows, %d columns\n",
                  pl_code, format(row_count, big.mark=","), length(cols)))
    }
  }

  cat("\n")

  # Overall status
  if (length(missing_tables) == 0 && all_ready) {
    cat("═══════════════════════════════════════════════════════════════════\n")
    cat("✅ VERIFICATION PASSED - READY TO PROCEED\n")
    cat("═══════════════════════════════════════════════════════════════════\n\n")

    cat("All prerequisites met:\n")
    cat(sprintf("  ✓ %d eBay time series tables exist\n", length(found_tables)))
    cat("  ✓ All tables have data\n")
    cat("  ✓ All required columns present\n\n")

    cat("Next steps:\n")
    cat("  1. Run eBay Poisson DRV:\n")
    cat("     Rscript scripts/update_scripts/DRV/eby/eby_DRV_product_line_poisson.R\n\n")

    cat("  2. Or use orchestrator (runs both CBZ and EBY):\n")
    cat("     Rscript scripts/update_scripts/DRV/update_all_platforms_poisson.R\n\n")

    exit_code <- 0

  } else {
    cat("═══════════════════════════════════════════════════════════════════\n")
    cat("⚠️  VERIFICATION PARTIAL - SOME ISSUES DETECTED\n")
    cat("═══════════════════════════════════════════════════════════════════\n\n")

    if (length(missing_tables) > 0) {
      cat("Missing tables:\n")
      for (tbl in missing_tables) {
        pl_code <- toupper(sub("df_eby_sales_complete_time_series_", "", tbl))
        cat(sprintf("  ❌ %s: %s\n", pl_code, tbl))
      }
      cat("\n")
    }

    cat("Recommendation:\n")
    cat("  → Can proceed with partial data (only available product lines)\n")
    cat("  → Or run eBay ETL pipeline first to populate all tables\n\n")

    exit_code <- 0  # Not a blocker, just a warning
  }

} else {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════════\n")
  cat("❌ VERIFICATION FAILED - BLOCKER DETECTED\n")
  cat("═══════════════════════════════════════════════════════════════════\n\n")

  cat("Missing ALL eBay time series tables:\n")
  for (tbl in expected_tables) {
    pl_code <- toupper(sub("df_eby_sales_complete_time_series_", "", tbl))
    cat(sprintf("  ❌ %s: %s\n", pl_code, tbl))
  }
  cat("\n")

  cat("Root cause: eBay ETL pipeline has not been executed\n\n")

  cat("Required actions:\n")
  cat("  1. Check if eBay ETL scripts exist:\n")
  cat("     scripts/update_scripts/ETL/eby/\n\n")

  cat("  2. Run eBay ETL pipeline to create time series data\n\n")

  cat("  3. Re-run this verification script\n\n")

  exit_code <- 1
}

# Cleanup
dbDisconnect(con, shutdown = TRUE)

cat("Verification complete.\n\n")

# Exit with appropriate code
quit(status = exit_code)
