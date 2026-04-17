# cleanup_mp100_utf8_violations.R
# ==============================================================================
# MP100 UTF-8 Encoding Standard Systematic Cleanup Tool
# Following R113: Four-part Update Script Structure
# Following MP100: UTF-8 Encoding Standard
# Following MP095: Claude Code-Driven Changes
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

script_success <- FALSE
test_passed <- FALSE
main_error <- NULL

# Create backup directory following MAMBA file organization principles
backup_dir <- paste0("archive/utf8_cleanup_", format(Sys.time(), "%Y%m%d_%H%M%S"))

message("INITIALIZE: MP100 UTF-8 cleanup tool initialized")
message("INITIALIZE: Backup directory: ", backup_dir)

# ==============================================================================
# 2. MAIN
# ==============================================================================

tryCatch({
  message("MAIN: Starting MP100 UTF-8 encoding cleanup...")
  
  # Create backup directory
  dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Load previous scan results if available
  if (!exists("mp100_scan_results")) {
    message("MAIN: Running compliance check first...")
    source("scripts/global_scripts/98_test/test_mp100_utf8_compliance.R")
  }
  
  if (exists("mp100_scan_results") && mp100_scan_results$contaminated_files > 0) {
    message("MAIN: Found ", mp100_scan_results$contaminated_files, 
            " files requiring cleanup")
    
    # Initialize cleanup statistics
    cleanup_stats <- list(
      attempted = 0,
      successful = 0,
      failed = 0,
      backed_up = 0
    )
    
    # Function to clean a single file
    clean_file <- function(filepath) {
      tryCatch({
        # Create backup
        backup_path <- file.path(backup_dir, basename(filepath))
        counter <- 1
        while (file.exists(backup_path)) {
          backup_path <- file.path(backup_dir, 
                                  paste0(tools::file_path_sans_ext(basename(filepath)),
                                        "_", counter, ".",
                                        tools::file_ext(basename(filepath))))
          counter <- counter + 1
        }
        
        file.copy(filepath, backup_path)
        cleanup_stats$backed_up <<- cleanup_stats$backed_up + 1
        
        # Read file content
        raw_content <- readBin(filepath, "raw", n = file.info(filepath)$size)
        
        # Remove null bytes
        clean_content <- raw_content[raw_content != as.raw(0)]
        
        # Write cleaned content back
        writeBin(clean_content, filepath)
        
        # Verify cleanup
        verification <- readBin(filepath, "raw", n = file.info(filepath)$size)
        if (!any(verification == as.raw(0))) {
          message("  SUCCESS: Cleaned ", basename(filepath))
          return(TRUE)
        } else {
          message("  WARNING: Cleanup verification failed for ", basename(filepath))
          return(FALSE)
        }
        
      }, error = function(e) {
        message("  ERROR: Failed to clean ", basename(filepath), " - ", e$message)
        return(FALSE)
      })
    }
    
    # Priority cleanup: initialization files first
    priority_files <- mp100_scan_results$critical_files
    regular_files <- setdiff(mp100_scan_results$contaminated_list, priority_files)
    
    # Clean priority files first
    if (length(priority_files) > 0) {
      message("MAIN: Cleaning ", length(priority_files), " critical initialization files...")
      
      for (file_path in priority_files) {
        cleanup_stats$attempted <- cleanup_stats$attempted + 1
        
        if (clean_file(file_path)) {
          cleanup_stats$successful <- cleanup_stats$successful + 1
        } else {
          cleanup_stats$failed <- cleanup_stats$failed + 1
        }
      }
    }
    
    # Clean remaining files (batch process)
    if (length(regular_files) > 0) {
      message("MAIN: Cleaning ", length(regular_files), " additional contaminated files...")
      
      # Process in batches to avoid overwhelming the system
      batch_size <- 50
      batches <- split(regular_files, ceiling(seq_along(regular_files) / batch_size))
      
      for (i in seq_along(batches)) {
        message("MAIN: Processing batch ", i, " of ", length(batches), 
                " (", length(batches[[i]]), " files)")
        
        for (file_path in batches[[i]]) {
          cleanup_stats$attempted <- cleanup_stats$attempted + 1
          
          if (clean_file(file_path)) {
            cleanup_stats$successful <- cleanup_stats$successful + 1
          } else {
            cleanup_stats$failed <- cleanup_stats$failed + 1
          }
        }
        
        # Brief pause between batches
        if (i < length(batches)) Sys.sleep(0.1)
      }
    }
    
    # Report cleanup results
    message("MAIN: MP100 UTF-8 Cleanup Results:")
    message("  Files attempted: ", cleanup_stats$attempted)
    message("  Files cleaned successfully: ", cleanup_stats$successful)
    message("  Files failed to clean: ", cleanup_stats$failed)
    message("  Files backed up: ", cleanup_stats$backed_up)
    message("  Success rate: ", 
            round(100 * cleanup_stats$successful / cleanup_stats$attempted, 1), "%")
    
    # Store cleanup results
    assign("mp100_cleanup_stats", cleanup_stats, envir = .GlobalEnv)
    
  } else {
    message("MAIN: No contaminated files found - system is MP100 compliant")
  }
  
  script_success <- TRUE
  message("MAIN: MP100 UTF-8 cleanup completed")
  
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
    message("TEST: Verifying MP100 cleanup results...")
    
    # Re-run compliance check to verify cleanup
    message("TEST: Running post-cleanup compliance verification...")
    
    # Clear previous results
    if (exists("mp100_scan_results")) rm(mp100_scan_results)
    
    # Re-run scan
    source("scripts/global_scripts/98_test/test_mp100_utf8_compliance.R")
    
    if (exists("mp100_scan_results")) {
      remaining_contamination <- mp100_scan_results$contaminated_files
      
      if (remaining_contamination == 0) {
        test_passed <- TRUE
        message("TEST: SUCCESS - All files are now MP100 compliant")
        message("TEST: System ready for autoinit() testing")
      } else {
        test_passed <- FALSE
        message("TEST: WARNING - ", remaining_contamination, 
                " files still have encoding issues")
        
        if (length(mp100_scan_results$critical_files) == 0) {
          message("TEST: Good news: No critical initialization files remain contaminated")
          message("TEST: autoinit() should now work")
        }
      }
    } else {
      test_passed <- FALSE
      message("TEST: Could not verify cleanup results")
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
  message("DEINITIALIZE: MP100 UTF-8 cleanup completed successfully")
  message("DEINITIALIZE: Backup available at: ", backup_dir)
  return_status <- TRUE
} else if (script_success && !test_passed) {
  message("DEINITIALIZE: Cleanup completed but verification failed")
  message("DEINITIALIZE: Backup available at: ", backup_dir)
  return_status <- FALSE
} else {
  message("DEINITIALIZE: MP100 UTF-8 cleanup failed")
  if (!is.null(main_error)) {
    message("DEINITIALIZE: Error details - ", main_error$message)
  }
  return_status <- FALSE
}

message("DEINITIALIZE: MP100 cleanup tool completed")

# Return status
invisible(return_status)