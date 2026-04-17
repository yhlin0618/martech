#!/usr/bin/env Rscript

# Test WAL cleanup when backups exist (P16)

# Set working directory to script location
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("--file=", args, value = TRUE)
if (length(file_arg)) {
  script_dir <- dirname(normalizePath(sub("--file=", "", file_arg)))
  setwd(script_dir)
}

# Load the dbDisconnect_all function directly
source(file.path("..", "02_db_utils", "fn_dbDisconnect_all.R"))

# Create temporary DuckDB database
wal_db <- tempfile(fileext = ".duckdb")
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = wal_db)

# Write data to generate WAL
DBI::dbExecute(con, "CREATE TABLE test(id INTEGER)")
DBI::dbExecute(con, "INSERT INTO test VALUES (1)")

# Path to WAL file
wal_path <- sub("\\.duckdb$", ".duckdb.wal", wal_db)
cat("WAL exists before disconnect:", file.exists(wal_path), "\n")

# Expose connection for dbDisconnect_all
assign("wal_con", con, envir = .GlobalEnv)

# Disconnect and cleanup
dbDisconnect_all(create_backups = TRUE, cleanup_wal = TRUE, keep_backups = FALSE)

# Verify WAL removal
if (!file.exists(wal_path)) {
  cat("WAL cleanup successful\n")
} else {
  cat("WAL cleanup FAILED\n")
}

# Remove backup files if any
bk_files <- Sys.glob(paste0(wal_db, "_bak*"))
if (length(bk_files)) unlink(bk_files)
if (file.exists(wal_db)) unlink(wal_db)
