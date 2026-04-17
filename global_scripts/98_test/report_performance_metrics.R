#' Performance Metrics Report
#'
#' @description
#' Generates a lightweight report for startup time and cache hit rate.
#'
#' Usage:
#'   Rscript scripts/global_scripts/98_test/report_performance_metrics.R
#'
#' @created 2026-01-26

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
})

write_cache_stats <- function(stats_df, base_path) {
  if (is.null(stats_df) || nrow(stats_df) == 0) return(invisible(NULL))

  json_path <- paste0(base_path, ".json")
  csv_path <- paste0(base_path, ".csv")

  if (requireNamespace("jsonlite", quietly = TRUE)) {
    jsonlite::write_json(stats_df, json_path, pretty = TRUE, auto_unbox = TRUE)
    cat("Cache stats JSON:", json_path, "\n")
  } else {
    cat("SKIP JSON: jsonlite not installed\n")
  }

  utils::write.csv(stats_df, csv_path, row.names = FALSE)
  cat("Cache stats CSV:", csv_path, "\n")
}

cat("\n=== MAMBA Performance Metrics Report ===\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# -----------------------------------------------------------------------------
# Startup time measurement
# -----------------------------------------------------------------------------
startup_time_secs <- function() {
  if (!file.exists("app.R")) {
    cat("SKIP: app.R not found\n")
    return(NA_real_)
  }

  start <- Sys.time()
  tryCatch({
    source("app.R", local = new.env())
  }, error = function(e) {
    cat("ERROR sourcing app.R:", e$message, "\n")
  })
  as.numeric(difftime(Sys.time(), start, units = "secs"))
}

cat("--- Startup Time ---\n")
startup_secs <- startup_time_secs()
if (!is.na(startup_secs)) {
  cat("Startup:", round(startup_secs, 3), "seconds\n")
}

# -----------------------------------------------------------------------------
# Memory usage
# -----------------------------------------------------------------------------
cat("\n--- Memory Usage ---\n")
if (requireNamespace("pryr", quietly = TRUE)) {
  mem_used <- pryr::mem_used()
  cat("Memory used:", format(mem_used), "\n")
} else {
  cat("SKIP: pryr not installed\n")
}

# -----------------------------------------------------------------------------
# Cache hit rate measurement
# -----------------------------------------------------------------------------
cat("\n--- Cache Hit Rate ---\n")

if (!file.exists("scripts/global_scripts/04_utils/fn_cached_data_access.R")) {
  cat("SKIP: fn_cached_data_access.R not found\n")
} else {
  source("scripts/global_scripts/04_utils/fn_cached_data_access.R")

  db_path <- file.path("data", "app_data", "app_data.duckdb")
  if (!file.exists(db_path)) {
    cat("SKIP: DuckDB not found at", db_path, "\n")
  } else {
    con <- DBI::dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    on.exit(DBI::dbDisconnect(con), add = TRUE)

    # Warm cache
    try(load_dna_distribution_summary_cached(con, "eby", "m_value"), silent = TRUE)
    try(load_dna_distribution_summary_cached(con, "eby", "m_value"), silent = TRUE)
    try(load_dna_category_counts_cached(con, "eby", "nes_status"), silent = TRUE)
    try(load_dna_category_counts_cached(con, "eby", "nes_status"), silent = TRUE)
    try(load_customer_dropdown_options_cached(con, "eby", limit = 50), silent = TRUE)
    try(load_customer_dropdown_options_cached(con, "eby", limit = 50), silent = TRUE)

    stats <- tryCatch(get_cache_stats(), error = function(e) data.frame())
    if (is.null(stats) || nrow(stats) == 0) {
      cat("No cache stats available (memoise/cachem may be missing).\n")
    } else {
      print(stats)
      avg_hit_rate <- mean(stats$hit_rate, na.rm = TRUE)
      cat("Average hit rate:", round(avg_hit_rate, 3), "\n")

      ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
      base_path <- file.path("validation", paste0("cache_stats_", ts))
      write_cache_stats(stats, base_path)
    }
  }
}

cat("\n=== End of Report ===\n")
