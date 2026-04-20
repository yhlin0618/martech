#!/usr/bin/env Rscript

# Test file for debugging initialization with verbose mode

# Set verbose mode to true to show detailed loading information
VERBOSE_INITIALIZATION <- TRUE

# Source the revised initialization script
tryCatch({
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))
  cat("Successfully completed full initialization\n")
}, error = function(e) {
  cat("ERROR in initialization:", e$message, "\n")
})

# Check if key functions are available
cat("\nTesting if key functions are available...\n")

tryCatch({
  if(exists("create_or_replace_amazon_sales_dta2")) {
    cat("✓ create_or_replace_amazon_sales_dta2 function is available\n")
  } else {
    cat("✗ create_or_replace_amazon_sales_dta2 function is NOT available\n")
  }
  
  if(exists("import_amazon_sales_dta")) {
    cat("✓ import_amazon_sales_dta function is available\n")
  } else {
    cat("✗ import_amazon_sales_dta function is NOT available\n")
  }
  
  if(exists("process_amazon_sales")) {
    cat("✓ process_amazon_sales function is available\n")
  } else {
    cat("✗ process_amazon_sales function is NOT available\n")
  }
}, error = function(e) {
  cat("ERROR checking function availability:", e$message, "\n")
})

# Output completion message
cat("\nTest completed\n")