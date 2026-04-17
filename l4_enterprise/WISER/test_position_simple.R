#!/usr/bin/env Rscript

cat("=== SIMPLE POSITION TABLE TEST ===\n\n")

# Set operation mode BEFORE any other code
OPERATION_MODE <- "APP_MODE"

# Load required packages
library(dplyr)
library(DBI)
library(duckdb)

# Source tbl2 function
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")

# Connect directly to app database
cat("🔗 Connecting to database...\n")
app_data <- dbConnect(duckdb::duckdb(), "data/app_data/app_data.duckdb")
cat("✅ Connected\n\n")

# Source the position functions
cat("📚 Loading position functions...\n")
source("scripts/global_scripts/11_rshinyapp_utils/fn_get_position_complete_case.R")
cat("✅ Functions loaded\n\n")

# Test the function
cat("🧪 TEST: Fetching position data...\n")
tryCatch({
  position_data <- fn_get_position_complete_case(
    app_data_connection = app_data,
    product_line_id = "jew",
    include_special_rows = TRUE,
    apply_type_filter = FALSE
  )

  cat("✅ Data fetched successfully!\n")
  cat("  - Rows: ", nrow(position_data), "\n")
  cat("  - Columns: ", ncol(position_data), "\n\n")

  # Check critical columns
  cat("📋 Column Check:\n")
  if ("product_id" %in% names(position_data)) {
    cat("  ✅ product_id column exists\n")
    cat("    Sample IDs: ", paste(head(unique(position_data$product_id), 3), collapse=", "), "\n")
  } else {
    cat("  ❌ product_id column MISSING!\n")
  }

  if ("item_id" %in% names(position_data)) {
    cat("  ⚠️ item_id column still exists (should be renamed)\n")
  } else {
    cat("  ✅ item_id properly renamed\n")
  }

  if ("brand" %in% names(position_data)) {
    cat("  ✅ brand column exists\n")
  }

  cat("\n📊 First few columns:\n")
  cat("  ", paste(names(position_data)[1:10], collapse=", "), "\n")

}, error = function(e) {
  cat("❌ Error: ", e$message, "\n")
  traceback()
})

# Disconnect
dbDisconnect(app_data, shutdown = TRUE)
cat("\n✅ Test complete!\n")