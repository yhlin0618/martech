#' Performance Optimization Test Script
#'
#' @description
#' Tests the performance improvements from the 2026-01-26 optimization:
#' - SQL-level column selection
#' - Cached data access
#' - Memory usage reduction
#'
#' @principles
#' - P77: Performance Optimization
#' - TD_R001: Test Coverage Requirements
#'
#' @created 2026-01-26
#' @author Claude Code

# Initialize
suppressPackageStartupMessages({
  library(dplyr)
  library(DBI)
  library(duckdb)
})

# Get project root
project_root <- here::here()
setwd(project_root)

# Source required functions
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")
source("scripts/global_scripts/04_utils/fn_cached_data_access.R")

cat("\n=== MAMBA Performance Optimization Test ===\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# -----------------------------------------------------------------------------
# Test 1: Compare data loading with and without column selection
# -----------------------------------------------------------------------------
test_column_selection <- function() {
  cat("--- Test 1: Column Selection Performance ---\n")

  # Get database path
  db_path <- file.path(project_root, "data", "app_data", "app_data.duckdb")

  if (!file.exists(db_path)) {
    cat("SKIP: Database not found at", db_path, "\n")
    return(NULL)
  }

  # Connect to database
  conn <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
  on.exit(dbDisconnect(conn), add = TRUE)

  # Check if table exists
  if (!dbExistsTable(conn, "df_dna_by_customer")) {
    cat("SKIP: Table df_dna_by_customer not found\n")
    return(NULL)
  }

  # Test 1a: Full table load (old method)
  cat("Loading full table...\n")
  gc()
  mem_before_full <- pryr::mem_used()
  start_full <- Sys.time()

  df_full <- tbl2(conn, "df_dna_by_customer") %>%
    collect()

  end_full <- Sys.time()
  mem_after_full <- pryr::mem_used()
  time_full <- as.numeric(difftime(end_full, start_full, units = "secs"))

  cat("  Rows:", nrow(df_full), "\n")
  cat("  Columns:", ncol(df_full), "\n")
  cat("  Time:", round(time_full, 3), "seconds\n")
  cat("  Memory delta:", format(mem_after_full - mem_before_full), "\n")

  # Clean up
  rm(df_full)
  gc()

  # Test 1b: Optimized load (new method)
  cat("\nLoading with column selection...\n")
  viz_columns <- c("m_value", "r_value", "f_value", "ipt_mean", "nes_status")

  gc()
  mem_before_opt <- pryr::mem_used()
  start_opt <- Sys.time()

  df_opt <- tbl2(conn, "df_dna_by_customer") %>%
    select(any_of(viz_columns)) %>%
    collect()

  end_opt <- Sys.time()
  mem_after_opt <- pryr::mem_used()
  time_opt <- as.numeric(difftime(end_opt, start_opt, units = "secs"))

  cat("  Rows:", nrow(df_opt), "\n")
  cat("  Columns:", ncol(df_opt), "\n")
  cat("  Time:", round(time_opt, 3), "seconds\n")
  cat("  Memory delta:", format(mem_after_opt - mem_before_opt), "\n")

  # Calculate improvement
  time_improvement <- (time_full - time_opt) / time_full * 100
  cat("\n  Time improvement:", round(time_improvement, 1), "%\n")

  # Clean up
  rm(df_opt)
  gc()

  list(
    time_full = time_full,
    time_opt = time_opt,
    improvement = time_improvement
  )
}

# -----------------------------------------------------------------------------
# Test 2: Cached data access performance
# -----------------------------------------------------------------------------
test_cached_access <- function() {
  cat("\n--- Test 2: Cached Data Access ---\n")

  # Get database path
  db_path <- file.path(project_root, "data", "app_data", "app_data.duckdb")

  if (!file.exists(db_path)) {
    cat("SKIP: Database not found at", db_path, "\n")
    return(NULL)
  }

  # Connect to database
  conn <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
  on.exit(dbDisconnect(conn), add = TRUE)

  # Clear cache first
  clear_app_cache()

  # Test first call (uncached)
  cat("First call (uncached)...\n")
  start1 <- Sys.time()
  result1 <- load_dna_distribution_summary_cached(conn, "eby", "m_value")
  end1 <- Sys.time()
  time1 <- as.numeric(difftime(end1, start1, units = "secs"))
  cat("  Time:", round(time1, 3), "seconds\n")
  cat("  Rows returned:", nrow(result1), "\n")

  # Test second call (cached)
  cat("\nSecond call (cached)...\n")
  start2 <- Sys.time()
  result2 <- load_dna_distribution_summary_cached(conn, "eby", "m_value")
  end2 <- Sys.time()
  time2 <- as.numeric(difftime(end2, start2, units = "secs"))
  cat("  Time:", round(time2, 3), "seconds\n")

  # Calculate cache speedup
  if (time1 > 0) {
    speedup <- time1 / max(time2, 0.001)
    cat("\n  Cache speedup:", round(speedup, 1), "x\n")
  }

  # Check cache info
  cache_info <- get_cache_info()
  cat("  Cache type:", cache_info$type, "\n")

  list(
    time_uncached = time1,
    time_cached = time2,
    cache_type = cache_info$type
  )
}

# -----------------------------------------------------------------------------
# Test 3: Summary statistics at SQL level
# -----------------------------------------------------------------------------
test_sql_aggregation <- function() {
  cat("\n--- Test 3: SQL-Level Aggregation ---\n")

  # Get database path
  db_path <- file.path(project_root, "data", "app_data", "app_data.duckdb")

  if (!file.exists(db_path)) {
    cat("SKIP: Database not found at", db_path, "\n")
    return(NULL)
  }

  # Connect to database
  conn <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
  on.exit(dbDisconnect(conn), add = TRUE)

  # Method 1: Load all then aggregate in R (old way)
  cat("Method 1: Load then aggregate in R...\n")
  start1 <- Sys.time()
  df_all <- tbl2(conn, "df_dna_by_customer") %>%
    collect()
  counts1 <- df_all %>%
    group_by(nes_status) %>%
    summarise(count = n())
  end1 <- Sys.time()
  time1 <- as.numeric(difftime(end1, start1, units = "secs"))
  cat("  Time:", round(time1, 3), "seconds\n")

  rm(df_all)
  gc()

  # Method 2: Aggregate at SQL level (new way)
  cat("\nMethod 2: Aggregate at SQL level...\n")
  start2 <- Sys.time()
  counts2 <- load_dna_category_counts(conn, "all", "nes_status")
  end2 <- Sys.time()
  time2 <- as.numeric(difftime(end2, start2, units = "secs"))
  cat("  Time:", round(time2, 3), "seconds\n")
  cat("  Categories returned:", nrow(counts2), "\n")

  # Calculate improvement
  improvement <- (time1 - time2) / time1 * 100
  cat("\n  Improvement:", round(improvement, 1), "%\n")

  list(
    time_r_agg = time1,
    time_sql_agg = time2,
    improvement = improvement
  )
}

# -----------------------------------------------------------------------------
# Run all tests
# -----------------------------------------------------------------------------
run_all_tests <- function() {
  results <- list()

  results$column_selection <- tryCatch(
    test_column_selection(),
    error = function(e) {
      cat("ERROR:", e$message, "\n")
      NULL
    }
  )

  results$cached_access <- tryCatch(
    test_cached_access(),
    error = function(e) {
      cat("ERROR:", e$message, "\n")
      NULL
    }
  )

  results$sql_aggregation <- tryCatch(
    test_sql_aggregation(),
    error = function(e) {
      cat("ERROR:", e$message, "\n")
      NULL
    }
  )

  cat("\n=== Summary ===\n")
  if (!is.null(results$column_selection)) {
    cat("Column selection improvement:", round(results$column_selection$improvement, 1), "%\n")
  }
  if (!is.null(results$sql_aggregation)) {
    cat("SQL aggregation improvement:", round(results$sql_aggregation$improvement, 1), "%\n")
  }
  if (!is.null(results$cached_access)) {
    cat("Caching available:", results$cached_access$cache_type, "\n")
  }

  invisible(results)
}

# Run if executed directly
if (!interactive() || identical(Sys.getenv("RUN_TESTS"), "TRUE")) {
  results <- run_all_tests()
}
