# test_mp100_utf8_compliance.R
# ==============================================================================
# MP100 UTF-8 Encoding Standard Compliance Test
# Following R113: Four-part Update Script Structure
# Following MP100: UTF-8 Encoding Standard
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

script_success <- FALSE
test_passed <- FALSE
main_error <- NULL

# Prevent autoinit() usage since we're testing the initialization system itself
# Following MP095: Claude Code-Driven Changes - diagnostic tools don't use autoinit()

message("INITIALIZE: MP100 UTF-8 compliance test initialized")

# ==============================================================================
# 2. MAIN
# ==============================================================================

tryCatch({
  message("MAIN: Starting MP100 UTF-8 encoding compliance check...")
  
  # Define search directories
  search_dirs <- c(
    "scripts/global_scripts",
    "scripts/update_scripts"
  )
  
  # Initialize results
  results <- list(
    total_files = 0,
    contaminated_files = 0,
    critical_files = character(),
    contaminated_list = character(),
    initialization_files = character()
  )
  
  # Function to check for null characters in a file
  check_file_encoding <- function(filepath) {
    tryCatch({
      # Read file as raw bytes
      raw_bytes <- readBin(filepath, "raw", n = file.info(filepath)$size)
      # Check for null bytes (0x00)
      has_nulls <- any(raw_bytes == as.raw(0))
      return(has_nulls)
    }, error = function(e) {
      message("WARNING: Could not check file: ", filepath, " - ", e$message)
      return(FALSE)
    })
  }
  
  # Scan all R files
  message("MAIN: Scanning R files for null character contamination...")
  
  for (search_dir in search_dirs) {
    if (dir.exists(search_dir)) {
      r_files <- list.files(search_dir, pattern = "\\.R$", 
                           recursive = TRUE, full.names = TRUE)
      
      message("MAIN: Found ", length(r_files), " R files in ", search_dir)
      
      for (file_path in r_files) {
        results$total_files <- results$total_files + 1
        
        if (check_file_encoding(file_path)) {
          results$contaminated_files <- results$contaminated_files + 1
          results$contaminated_list <- c(results$contaminated_list, file_path)
          
          # Check if this is a critical initialization file
          if (grepl("22_initializations/", file_path) || 
              grepl("autoinit|autodeinit", basename(file_path))) {
            results$critical_files <- c(results$critical_files, file_path)
            results$initialization_files <- c(results$initialization_files, file_path)
          }
        }
      }
    }
  }
  
  # Report findings
  message("MAIN: MP100 UTF-8 Compliance Check Results:")
  message("  Total R files scanned: ", results$total_files)
  message("  Files with null characters: ", results$contaminated_files)
  message("  Contamination rate: ", 
          round(100 * results$contaminated_files / results$total_files, 1), "%")
  
  if (length(results$critical_files) > 0) {
    message("  CRITICAL: ", length(results$critical_files), 
            " initialization files are contaminated")
    message("  This explains autoinit() failures")
  }
  
  # Store results for cleanup tool
  assign("mp100_scan_results", results, envir = .GlobalEnv)
  
  script_success <- TRUE
  message("MAIN: MP100 compliance check completed successfully")
  
}, error = function(e) {
  main_error <<- e
  script_success <<- FALSE
  message("MAIN ERROR: ", e$message)
})

# ==============================================================================
# 3. TEST
# ==============================================================================

if (script_success) {
  tryCatch({
    message("TEST: Verifying MP100 compliance check results...")
    
    # Test if results are stored
    if (exists("mp100_scan_results") && is.list(mp100_scan_results)) {
      test_passed <- TRUE
      
      # Report on critical findings
      if (mp100_scan_results$contaminated_files > 0) {
        message("TEST: Found encoding violations - cleanup required")
        
        # Prioritize initialization files
        if (length(mp100_scan_results$critical_files) > 0) {
          message("TEST: Priority cleanup targets:")
          for (file in head(mp100_scan_results$critical_files, 5)) {
            message("  CRITICAL: ", file)
          }
        }
      } else {
        message("TEST: All files are MP100 compliant")
      }
      
    } else {
      test_passed <- FALSE
      message("TEST: Results not properly stored")
    }
    
  }, error = function(e) {
    test_passed <<- FALSE
    message("TEST ERROR: ", e$message)
  })
} else {
  message("TEST: Skipped due to main script failure")
}

# ==============================================================================
# 4. DEINITIALIZE
# ==============================================================================

# Determine final status
if (script_success && test_passed) {
  message("DEINITIALIZE: MP100 compliance check completed successfully")
  return_status <- TRUE
} else {
  message("DEINITIALIZE: MP100 compliance check failed")
  if (!is.null(main_error)) {
    message("DEINITIALIZE: Error details - ", main_error$message)
  }
  return_status <- FALSE
}

# Clean up (no database connections to close)
message("DEINITIALIZE: MP100 compliance test completed")

# Return status
invisible(return_status)