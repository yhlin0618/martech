# test_s02_export.R - S02 sequence without autoinit
# Following MP093: Data Visualization Debugging through S02 sequence exports

# ==============================================================================
# 1. INITIALIZE (Minimal)
# ==============================================================================

message("S02_00: Starting database export for inspection")

# Load essential libraries
suppressMessages({
  library(here)
  library(DBI)
  library(duckdb)
})

# Set paths
APP_DIR <- here::here()
export_destination <- file.path(APP_DIR, "data", "database_to_csv")

# Clean and create export directory
if (dir.exists(export_destination)) {
  unlink(export_destination, recursive = TRUE, force = TRUE)
}
dir.create(export_destination, recursive = TRUE, showWarnings = FALSE)

# ==============================================================================
# 2. MAIN EXPORT
# ==============================================================================

# Define database paths manually (since autoinit is broken)
db_paths <- list(
  raw_data = file.path(APP_DIR, "data", "local_data", "raw_data.duckdb"),
  app_data = file.path(APP_DIR, "data", "app_data", "app_data.duckdb"),
  staged_data = file.path(APP_DIR, "data", "local_data", "staged_data.duckdb"),
  cleansed_data = file.path(APP_DIR, "data", "local_data", "cleansed_data.duckdb")
)

message("S02_00: Found ", length(db_paths), " databases to check")

for (db_name in names(db_paths)) {
  db_path <- db_paths[[db_name]]
  
  if (!file.exists(db_path)) {
    message("S02_00: Skipping ", db_name, " - file doesn't exist: ", db_path)
    next
  }
  
  message("S02_00: Exporting ", db_name, " database...")
  
  tryCatch({
    # Create database-specific subdirectory
    db_export_dir <- file.path(export_destination, db_name)
    dir.create(db_export_dir, recursive = TRUE, showWarnings = FALSE)
    
    # Connect to database (read-only)
    db_conn <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    
    # Get all tables
    tables <- dbListTables(db_conn)
    message("S02_00: Found ", length(tables), " tables in ", db_name)
    
    if (length(tables) > 0) {
      for (table_name in tables) {
        tryCatch({
          # Export each table to CSV
          table_data <- dbReadTable(db_conn, table_name)
          csv_path <- file.path(db_export_dir, paste0(table_name, ".csv"))
          write.csv(table_data, csv_path, row.names = FALSE)
          message("S02_00: Exported ", table_name, " (", nrow(table_data), " rows)")
        }, error = function(e) {
          message("S02_00: Failed to export table ", table_name, ": ", e$message)
        })
      }
    }
    
    # Disconnect
    dbDisconnect(db_conn)
    message("S02_00: Successfully exported ", db_name, " to ", db_export_dir)
    
  }, error = function(e) {
    message("S02_00: Failed to export ", db_name, ": ", e$message)
  })
}

# ==============================================================================
# 3. COMPLETION
# ==============================================================================

message("S02_00: Database export completed")
message("S02_00: Exported data available at: ", export_destination)

# List what was exported
if (dir.exists(export_destination)) {
  subdirs <- list.dirs(export_destination, recursive = FALSE)
  if (length(subdirs) > 0) {
    message("S02_00: Export summary:")
    for (subdir in subdirs) {
      csv_files <- list.files(subdir, pattern = "\\.csv$")
      message("  ", basename(subdir), ": ", length(csv_files), " tables")
    }
  }
}