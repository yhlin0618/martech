#!/usr/bin/env Rscript
# Verify actual database state vs documented state

library(DBI)
library(duckdb)

# Find database directories
db_paths <- c(
  "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/data/local_data",
  "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/data"
)

cat("=============================================================\n")
cat("DATABASE VERIFICATION REPORT\n")
cat("Generated:", Sys.time(), "\n")
cat("=============================================================\n\n")

# List of databases to check
databases <- c(
  "raw_data.duckdb",
  "staged_data.duckdb",
  "transformed_data.duckdb",
  "processed_data.duckdb",
  "app_data.duckdb"
)

results <- list()
total_tables <- 0
total_rows <- 0
total_size_mb <- 0

for (db_name in databases) {
  cat("=== ", db_name, " ===\n", sep = "")

  # Find database file
  db_path <- NULL
  for (path_prefix in db_paths) {
    test_path <- file.path(path_prefix, db_name)
    if (file.exists(test_path)) {
      db_path <- test_path
      break
    }
    # Also check app_data subdirectory
    if (db_name == "app_data.duckdb") {
      test_path <- file.path(path_prefix, "app_data", db_name)
      if (file.exists(test_path)) {
        db_path <- test_path
        break
      }
    }
  }

  if (is.null(db_path)) {
    cat("  STATUS: NOT FOUND\n\n")
    results[[db_name]] <- list(exists = FALSE)
    next
  }

  # Get file info
  file_info <- file.info(db_path)
  cat("  Path:", db_path, "\n")
  cat("  Size:", round(file_info$size / 1024 / 1024, 2), "MB\n")
  cat("  Modified:", as.character(file_info$mtime), "\n")

  # Connect and check tables
  tryCatch({
    con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)

    # List tables
    tables <- dbListTables(con)
    cat("  Tables:", length(tables), "\n")

    if (length(tables) > 0) {
      cat("\n  Table Details:\n")
      table_info <- list()

      for (tbl in sort(tables)) {
        tryCatch({
          count_query <- paste0("SELECT COUNT(*) as n FROM \"", tbl, "\"")
          count <- dbGetQuery(con, count_query)$n

          # Get column count
          col_query <- paste0("SELECT * FROM \"", tbl, "\" LIMIT 0")
          cols <- ncol(dbGetQuery(con, col_query))

          cat("    -", tbl, ":", format(count, big.mark = ","), "rows,", cols, "columns\n")
          table_info[[tbl]] <- list(rows = count, columns = cols)
        }, error = function(e) {
          cat("    -", tbl, ": ERROR -", e$message, "\n")
          table_info[[tbl]] <- list(rows = NA, columns = NA, error = e$message)
        })
      }

      results[[db_name]] <- list(
        exists = TRUE,
        path = db_path,
        size_mb = round(file_info$size / 1024 / 1024, 2),
        modified = as.character(file_info$mtime),
        table_count = length(tables),
        tables = table_info
      )

      # Update totals
      total_tables <- total_tables + length(tables)
      total_rows <- total_rows + sum(sapply(table_info, function(x) ifelse(is.na(x$rows), 0, x$rows)))
      total_size_mb <- total_size_mb + round(file_info$size / 1024 / 1024, 2)

    } else {
      cat("  WARNING: Database exists but contains NO TABLES\n")
      results[[db_name]] <- list(
        exists = TRUE,
        path = db_path,
        size_mb = round(file_info$size / 1024 / 1024, 2),
        modified = as.character(file_info$mtime),
        table_count = 0,
        tables = list()
      )
    }

    dbDisconnect(con, shutdown = TRUE)
  }, error = function(e) {
    cat("  ERROR:", e$message, "\n")
    results[[db_name]] <- list(exists = TRUE, path = db_path, error = e$message)
  })

  cat("\n")
}

# Generate summary report
cat("=============================================================\n")
cat("SUMMARY STATISTICS\n")
cat("=============================================================\n\n")

for (db_name in names(results)) {
  info <- results[[db_name]]
  if (info$exists && !is.null(info$tables)) {
    cat(db_name, ":\n", sep = "")
    cat("  Tables:", info$table_count, "\n")
    if (length(info$tables) > 0) {
      total_db_rows <- sum(sapply(info$tables, function(x) ifelse(is.na(x$rows), 0, x$rows)))
      cat("  Total rows:", format(total_db_rows, big.mark = ","), "\n")
    }
    cat("  Size:", info$size_mb, "MB\n")
    cat("  Modified:", info$modified, "\n\n")
  }
}

cat("GRAND TOTAL:\n")
cat("  Databases found:", sum(sapply(results, function(x) x$exists)), "/", length(databases), "\n")
cat("  Total tables:", total_tables, "\n")
cat("  Total rows:", format(total_rows, big.mark = ","), "\n")
cat("  Total size:", round(total_size_mb, 2), "MB\n\n")

# CBZ-specific verification
cat("=============================================================\n")
cat("CBZ ETL VERIFICATION\n")
cat("=============================================================\n\n")

cbz_tables_expected <- c(
  "df_cbz_sales___raw",
  "df_cbz_customers___raw",
  "df_cbz_products___raw",
  "df_cbz_orders___raw"
)

cat("Expected CBZ tables in raw_data.duckdb:\n")
for (tbl in cbz_tables_expected) {
  if (!is.null(results$raw_data.duckdb$tables[[tbl]])) {
    cat("  [FOUND]", tbl, ":", format(results$raw_data.duckdb$tables[[tbl]]$rows, big.mark = ","), "rows\n")
  } else {
    cat("  [MISSING]", tbl, "\n")
  }
}

# DRV verification
cat("\n=============================================================\n")
cat("DRV SCRIPT VERIFICATION\n")
cat("=============================================================\n\n")

df_tables_expected <- c(
  "df_cbz_product_features",
  "df_cbz_time_series",
  "df_cbz_poisson_analysis"
)

cat("Expected DRV tables in processed_data.duckdb:\n")
for (tbl in df_tables_expected) {
  if (!is.null(results$processed_data.duckdb$tables[[tbl]])) {
    cat("  [FOUND]", tbl, ":", format(results$processed_data.duckdb$tables[[tbl]]$rows, big.mark = ","), "rows\n")
  } else {
    cat("  [MISSING]", tbl, "\n")
  }
}

# Save results
output_file <- "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/database_verification_results.rds"
saveRDS(results, output_file)
cat("\n=============================================================\n")
cat("Results saved to:", output_file, "\n")
cat("=============================================================\n")
