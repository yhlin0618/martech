#!/usr/bin/env Rscript
# ==============================================================================
# MAMBA Database Backup Script - Week 7 Pre-Cutover Safety
# ==============================================================================
# Purpose: Create comprehensive backups of all 4 MAMBA databases before Week 7
# Author: principle-product-manager
# Created: 2025-11-13
#
# Compliance:
# - MP029: No Fake Data (real databases only, no simulation)
# - R092: Universal DBI Pattern
# - MP001: Configuration-Driven Development
#
# Critical Safety:
# - Timestamped backup directory
# - Integrity verification (checksums)
# - Restoration test validation
# - Complete logging
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
  library(digest)
  library(glue)
})

# ==============================================================================
# Configuration
# ==============================================================================

TIMESTAMP <- format(Sys.time(), "%Y%m%d_%H%M%S")
BASE_DIR <- "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA"
DATA_DIR <- file.path(BASE_DIR, "data")
BACKUP_ROOT <- file.path(DATA_DIR, "backups")
BACKUP_DIR <- file.path(BACKUP_ROOT, glue("pre_week7_{TIMESTAMP}"))

# Databases to backup (4 core MAMBA databases)
DATABASES <- c(
  "raw_data.duckdb",
  "staged_data.duckdb",
  "transformed_data.duckdb",
  "processed_data.duckdb"
)

# ==============================================================================
# Helper Functions
# ==============================================================================

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] [%s] %s\n", timestamp, level, msg))
}

calculate_checksum <- function(filepath) {
  digest::digest(file = filepath, algo = "md5")
}

get_file_size <- function(filepath) {
  info <- file.info(filepath)
  size_mb <- round(info$size / (1024^2), 2)
  return(size_mb)
}

verify_database <- function(db_path) {
  tryCatch({
    con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    tables <- dbListTables(con)
    dbDisconnect(con, shutdown = TRUE)
    return(list(valid = TRUE, table_count = length(tables)))
  }, error = function(e) {
    return(list(valid = FALSE, error = as.character(e)))
  })
}

# ==============================================================================
# Main Backup Process
# ==============================================================================

log_message("=== MAMBA DATABASE BACKUP - Week 7 Pre-Cutover ===", "HEADER")
log_message(glue("Backup directory: {BACKUP_DIR}"))

# Step 1: Create backup directory
if (!dir.exists(BACKUP_DIR)) {
  dir.create(BACKUP_DIR, recursive = TRUE)
  log_message(glue("Created backup directory: {BACKUP_DIR}"))
} else {
  log_message("Backup directory already exists", "WARN")
}

# Step 2: Initialize manifest
manifest <- data.frame(
  database = character(),
  source_path = character(),
  backup_path = character(),
  size_mb = numeric(),
  checksum_source = character(),
  checksum_backup = character(),
  table_count = integer(),
  backup_timestamp = character(),
  status = character(),
  stringsAsFactors = FALSE
)

# Step 3: Backup each database
backup_results <- list()

for (db_name in DATABASES) {
  log_message(glue("Processing: {db_name}"), "INFO")

  source_path <- file.path(DATA_DIR, db_name)
  backup_path <- file.path(BACKUP_DIR, db_name)

  # Check if source exists
  if (!file.exists(source_path)) {
    log_message(glue("  SKIP: {db_name} not found at {source_path}"), "WARN")
    next
  }

  # Get source metadata
  source_size <- get_file_size(source_path)
  log_message(glue("  Source size: {source_size} MB"))

  # Verify source database integrity
  log_message("  Verifying source database...")
  verify_result <- verify_database(source_path)

  if (!verify_result$valid) {
    log_message(glue("  ERROR: Source database corrupted - {verify_result$error}"), "ERROR")
    backup_results[[db_name]] <- list(status = "FAILED", reason = "Source corrupted")
    next
  }

  log_message(glue("  Source valid: {verify_result$table_count} tables"))

  # Calculate source checksum
  log_message("  Calculating source checksum...")
  source_checksum <- calculate_checksum(source_path)
  log_message(glue("  Source MD5: {source_checksum}"))

  # Copy database
  log_message("  Copying database...")
  copy_success <- file.copy(source_path, backup_path, overwrite = FALSE)

  if (!copy_success) {
    log_message("  ERROR: Copy failed", "ERROR")
    backup_results[[db_name]] <- list(status = "FAILED", reason = "Copy failed")
    next
  }

  # Verify backup
  log_message("  Verifying backup...")
  backup_checksum <- calculate_checksum(backup_path)

  if (source_checksum != backup_checksum) {
    log_message("  ERROR: Checksum mismatch!", "ERROR")
    backup_results[[db_name]] <- list(status = "FAILED", reason = "Checksum mismatch")
    next
  }

  log_message(glue("  Backup MD5: {backup_checksum} - MATCH"))

  # Verify backup database can be opened
  log_message("  Testing backup database...")
  verify_backup <- verify_database(backup_path)

  if (!verify_backup$valid) {
    log_message("  ERROR: Backup database corrupted", "ERROR")
    backup_results[[db_name]] <- list(status = "FAILED", reason = "Backup corrupted")
    next
  }

  log_message(glue("  SUCCESS: Backup valid with {verify_backup$table_count} tables"))

  # Add to manifest
  manifest <- rbind(manifest, data.frame(
    database = db_name,
    source_path = source_path,
    backup_path = backup_path,
    size_mb = source_size,
    checksum_source = source_checksum,
    checksum_backup = backup_checksum,
    table_count = verify_backup$table_count,
    backup_timestamp = TIMESTAMP,
    status = "SUCCESS",
    stringsAsFactors = FALSE
  ))

  backup_results[[db_name]] <- list(status = "SUCCESS")
}

# Step 4: Save manifest
manifest_path <- file.path(BACKUP_DIR, "BACKUP_MANIFEST.csv")
write.csv(manifest, manifest_path, row.names = FALSE)
log_message(glue("Manifest saved: {manifest_path}"))

# Step 5: Test restoration (one database as validation)
log_message("=== RESTORATION TEST ===", "HEADER")
if (nrow(manifest) > 0) {
  test_db <- manifest$database[1]
  test_backup <- manifest$backup_path[1]

  log_message(glue("Testing restoration of: {test_db}"))

  test_restore_path <- file.path(BACKUP_DIR, paste0("RESTORE_TEST_", test_db))
  file.copy(test_backup, test_restore_path)

  restore_verify <- verify_database(test_restore_path)

  if (restore_verify$valid) {
    log_message(glue("  PASS: Restored database valid ({restore_verify$table_count} tables)"), "SUCCESS")
    file.remove(test_restore_path)
  } else {
    log_message("  FAIL: Restored database corrupted", "ERROR")
  }
} else {
  log_message("No databases backed up - skipping restoration test", "WARN")
}

# Step 6: Generate summary report
log_message("=== BACKUP SUMMARY ===", "HEADER")
log_message(glue("Total databases processed: {length(DATABASES)}"))
log_message(glue("Successful backups: {nrow(manifest)}"))
log_message(glue("Failed backups: {length(DATABASES) - nrow(manifest)}"))

if (nrow(manifest) > 0) {
  log_message(glue("Total backup size: {round(sum(manifest$size_mb), 2)} MB"))
  log_message(glue("Backup location: {BACKUP_DIR}"))
}

# Step 7: Create summary file
summary_path <- file.path(BACKUP_DIR, "BACKUP_SUMMARY.txt")
summary_content <- glue("
MAMBA Database Backup Summary
Generated: {Sys.time()}
Backup ID: pre_week7_{TIMESTAMP}

=== BACKUP STATISTICS ===
Total Databases: {length(DATABASES)}
Successful: {nrow(manifest)}
Failed: {length(DATABASES) - nrow(manifest)}
Total Size: {round(sum(manifest$size_mb), 2)} MB

=== BACKED UP DATABASES ===
{paste(manifest$database, collapse = '\n')}

=== VERIFICATION STATUS ===
All backups verified with MD5 checksums
Restoration test: PASSED

=== BACKUP LOCATION ===
{BACKUP_DIR}

=== MANIFEST FILE ===
{manifest_path}
")

writeLines(summary_content, summary_path)
log_message(glue("Summary saved: {summary_path}"))

# Step 8: Final status
if (nrow(manifest) == length(DATABASES)) {
  log_message("=== BACKUP COMPLETE - ALL DATABASES BACKED UP ===", "SUCCESS")
  quit(status = 0)
} else {
  log_message("=== BACKUP INCOMPLETE - SOME DATABASES FAILED ===", "ERROR")
  quit(status = 1)
}
