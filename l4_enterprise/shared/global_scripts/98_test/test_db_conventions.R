#!/usr/bin/env Rscript

# Script to test database connection functions with proper naming conventions
# This script follows the proper function naming principles defined in R01

# Enhanced path resolution for app directory
get_app_dir <- function() {
  # Try to get script path first
  script_path <- NULL
  
  # The script path approach will only work if running via Rscript
  tryCatch({
    script_path <- normalizePath(commandArgs(trailingOnly = FALSE)[grep("--file=", commandArgs(trailingOnly = FALSE), fixed=TRUE)[1]])
    script_path <- sub("^--file=", "", script_path)
  }, error = function(e) {
    # If that fails, we'll fall back to working directory
    message("Could not determine script path: ", e$message)
  })
  
  # If we found the script path, use it to determine APP_DIR
  if(!is.null(script_path) && file.exists(script_path)) {
    # Extract precision_marketing_app path from script path
    if(grepl("precision_marketing_app", script_path, fixed=TRUE)) {
      app_dir <- sub("(.*precision_marketing_app).*", "\\1", script_path)
      return(app_dir)
    } else {
      # Script is not in precision_marketing_app
      message("Script is not in precision_marketing_app directory")
    }
  }
  
  # If script path doesn't work, try working directory
  current_path <- getwd()
  
  # Check if we're in update_scripts or some subdirectory
  if(grepl("update_scripts", current_path)) {
    # Extract path up to precision_marketing_app
    app_dir <- sub("(.*precision_marketing_app).*", "\\1", current_path)
    if(app_dir != current_path) {
      return(app_dir)
    }
  }
  
  # Check if current directory contains precision_marketing_app
  if(grepl("precision_marketing_app", current_path)) {
    # Extract path up to precision_marketing_app
    app_dir <- sub("(.*precision_marketing_app).*", "\\1", current_path)
    if(app_dir != current_path) {
      return(app_dir)
    }
  }
  
  # If we can't find precision_marketing_app in the path, try to construct it
  # IMPORTANT: This is a last resort and will only work in specific environments
  precision_marketing_path <- file.path("/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_MAMBA/precision_marketing_app")
  if(dir.exists(precision_marketing_path)) {
    message("Using hard-coded path as fallback")
    return(precision_marketing_path)
  }
  
  # If all else fails, assume we're in the app directory
  message("WARNING: Could not determine APP_DIR - using current directory as fallback")
  return(current_path)
}

# Set APP_DIR for proper path resolution
APP_DIR <- get_app_dir()
cat("Using APP_DIR:", APP_DIR, "\n")

# Initialize the update environment
init_path <- file.path(APP_DIR, "update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R")
if(file.exists(init_path)) {
  cat("Sourcing initialization file from:", init_path, "\n")
  source(init_path)
} else {
  cat("Initialization file not found at:", init_path, "\n")
  
  # Try a relative path as fallback
  fallback_path <- file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R")
  if(file.exists(fallback_path)) {
    cat("Sourcing initialization file from fallback path:", fallback_path, "\n")
    source(fallback_path)
  } else {
    cat("Initialization file not found at fallback path either\n")
  }
}

# Set operation mode if not already set
if(!exists("OPERATION_MODE")) {
  OPERATION_MODE <- "UPDATE_MODE"
  cat("OPERATION_MODE was not set, manually set to:", OPERATION_MODE, "\n")
} else {
  cat("Operation mode:", OPERATION_MODE, "\n")
}
cat("\n")

# Define paths to check for db_utils.R
possible_paths <- c(
  file.path(APP_DIR, "update_scripts", "global_scripts", "02_db_utils", "db_utils.R"),
  file.path("update_scripts", "global_scripts", "02_db_utils", "db_utils.R"),
  file.path(getwd(), "update_scripts", "global_scripts", "02_db_utils", "db_utils.R")
)

# Check if fn_dbConnect_from_list exists 
cat("Checking function availability...\n")
if(exists("fn_dbConnect_from_list")) {
  cat("fn_dbConnect_from_list function exists\n")
  # Try to find the file where the function is defined
  if(exists("find.package.source") && is.function(find.package.source)) {
    fn_path <- find.package.source("fn_dbConnect_from_list")
    if(!is.null(fn_path)) {
      cat("Function found at:", fn_path, "\n")
    }
  } else {
    cat("find.package.source not available, can't determine function source\n")
  }
  
  # Check function arguments
  args <- formals(fn_dbConnect_from_list)
  cat("Function parameters:", paste(names(args), collapse=", "), "\n")
  
  # Check if read_only is a valid parameter
  has_read_only <- "read_only" %in% names(args)
  cat("Has read_only parameter:", has_read_only, "\n\n")
} else {
  cat("fn_dbConnect_from_list function not found - attempting to source db_utils.R\n\n")
  
  # Try to source the individual function files directly
  db_utils_found <- FALSE
  
  # Get the db_utils directory
  db_utils_dir <- file.path(APP_DIR, "update_scripts", "global_scripts", "02_db_utils")
  if(dir.exists(db_utils_dir)) {
    cat("Found db_utils directory at:", db_utils_dir, "\n")
    
    # Look for the fn_dbConnect_from_list.R file
    fn_path <- file.path(db_utils_dir, "fn_dbConnect_from_list.R")
    if(file.exists(fn_path)) {
      cat("Found fn_dbConnect_from_list.R, sourcing directly...\n")
      tryCatch({
        source(fn_path)
        db_utils_found <- TRUE
        cat("Successfully sourced fn_dbConnect_from_list.R\n")
      }, error = function(e) {
        cat("Error sourcing fn_dbConnect_from_list.R:", e$message, "\n")
      })
    } else {
      cat("fn_dbConnect_from_list.R not found at", fn_path, "\n")
    }
  } else {
    cat("db_utils directory not found at:", db_utils_dir, "\n")
    
    # Try using db_utils.R as fallback
    for(path in possible_paths) {
      if(file.exists(path)) {
        cat("Found db_utils.R at:", path, "\n")
        cat("Sourcing...\n")
        tryCatch({
          source(path)
          db_utils_found <- TRUE
          cat("Successfully sourced db_utils.R\n")
          break
        }, error = function(e) {
          cat("Error sourcing db_utils.R from", path, ":", e$message, "\n")
        })
      }
    }
  }
  
  if(!db_utils_found) {
    cat("db_utils.R not found at any expected paths\n")
    
    # Check if DBI and duckdb are loaded for function to work
    required_packages <- c("DBI", "duckdb")
    missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
    
    if(length(missing_packages) > 0) {
      cat("Warning: Missing required packages for database functions:", paste(missing_packages, collapse=", "), "\n")
      cat("Attempting to load packages...\n")
      for(pkg in missing_packages) {
        install_result <- tryCatch({
          if(!requireNamespace(pkg, quietly = TRUE)) {
            install.packages(pkg)
          }
          library(pkg, character.only = TRUE)
          cat("Successfully loaded package:", pkg, "\n")
          TRUE
        }, error = function(e) {
          cat("Error loading package", pkg, ":", e$message, "\n")
          FALSE
        })
        if(!install_result) {
          cat("Cannot continue without required package:", pkg, "\n")
        }
      }
    }
    
    # Try to directly source the function file as a last resort
    fn_path <- file.path(APP_DIR, "update_scripts", "global_scripts", "02_db_utils", "fn_dbConnect_from_list.R")
    if(file.exists(fn_path)) {
      cat("Found fn_dbConnect_from_list.R directly, sourcing...\n")
      tryCatch({
        source(fn_path)
        cat("Successfully sourced fn_dbConnect_from_list.R directly\n")
      }, error = function(e) {
        cat("Error sourcing fn_dbConnect_from_list.R:", e$message, "\n")
      })
    } else {
      cat("fn_dbConnect_from_list.R not found at expected path\n")
      
      # Create a simple fallback implementation for testing
      cat("Creating fallback implementation for testing\n")
      fn_dbConnect_from_list <- function(dataset, path_list = list(), read_only = FALSE, 
                                      create_dir = TRUE, verbose = TRUE, force_mode_check = TRUE) {
        # This is a simplified implementation for testing only
        if(verbose) cat("Using fallback implementation of fn_dbConnect_from_list\n")
        
        # Ensure path_list has at least the requested dataset
        if(!dataset %in% names(path_list)) {
          path_list[[dataset]] <- file.path("data", paste0(dataset, ".duckdb"))
          if(verbose) cat("Added", dataset, "to path_list with path:", path_list[[dataset]], "\n")
        }
        
        # Get the database path
        db_path <- path_list[[dataset]]
        
        # Create directory if needed and requested
        db_dir <- dirname(db_path)
        if(!dir.exists(db_dir) && create_dir) {
          if(verbose) cat("Creating directory:", db_dir, "\n")
          dir.create(db_dir, recursive = TRUE, showWarnings = FALSE)
        }
        
        # Connect to the database
        if(verbose) cat("Connecting to database:", db_path, "with read_only =", read_only, "\n")
        con <- tryCatch({
          DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = read_only)
        }, error = function(e) {
          stop("Error connecting to database: ", e$message)
        })
        
        # Store connection in global environment
        assign(dataset, con, envir = .GlobalEnv)
        
        # Return the connection
        return(con)
      }
      
      # Also create the alias
      dbConnect_from_list <- fn_dbConnect_from_list
      cat("Created fallback fn_dbConnect_from_list function\n")
    }
  }
  
  # Check again
  if(exists("fn_dbConnect_from_list")) {
    cat("fn_dbConnect_from_list function now available\n")
    args <- formals(fn_dbConnect_from_list)
    cat("Function parameters:", paste(names(args), collapse=", "), "\n")
    has_read_only <- "read_only" %in% names(args)
    cat("Has read_only parameter:", has_read_only, "\n\n")
  } else {
    cat("Function still not available after sourcing\n\n")
    
    # Check for old name as fallback
    if(exists("dbConnect_from_list")) {
      cat("Found legacy function dbConnect_from_list\n")
      args <- formals(dbConnect_from_list)
      cat("Legacy function parameters:", paste(names(args), collapse=", "), "\n")
      has_read_only <- "read_only" %in% names(args)
      cat("Legacy function has read_only parameter:", has_read_only, "\n\n")
      
      # Create alias for testing
      cat("Creating alias fn_dbConnect_from_list to point to dbConnect_from_list\n")
      fn_dbConnect_from_list <- dbConnect_from_list
    }
  }
}

# Test connection with appropriate parameters
cat("=== Testing database connection function with appropriate parameters ===\n")
tryCatch({
  # Check if db_path_list exists
  if(!exists("db_path_list")) {
    cat("db_path_list not found, creating it...\n")
    if(exists("fn_get_default_db_paths")) {
      db_path_list <- fn_get_default_db_paths()
    } else {
      db_path_list <- list(
        "raw_data" = file.path("data", "raw_data.duckdb")
      )
    }
    cat("Using db_path_list:\n")
    print(db_path_list)
  }
  
  # Ensure data directory exists
  data_dir <- "data"
  if(!dir.exists(data_dir)) {
    cat("Creating data directory...\n")
    dir.create(data_dir, recursive = TRUE)
  }
  
  # Determine which function to use and parameters to pass
  if(exists("fn_dbConnect_from_list")) {
    # Try with proper function name following convention
    cat("Using fn_dbConnect_from_list...\n")
    
    # Determine if read_only parameter is supported
    if(has_read_only) {
      cat("Using with read_only=FALSE parameter...\n")
      con <- fn_dbConnect_from_list("raw_data", read_only = FALSE)
    } else {
      cat("Using without read_only parameter...\n")
      con <- fn_dbConnect_from_list("raw_data")
    }
  } else {
    # Fallback
    cat("Function not found, cannot continue\n")
    stop("Required function fn_dbConnect_from_list not available")
  }
  
  # Check connection properties
  cat("Connection successful\n")
  if(inherits(con, "DBIConnection")) {
    is_readonly <- tryCatch({
      DBI::dbIsReadOnly(con)
    }, error = function(e) {
      cat("Error checking read-only status:", e$message, "\n")
      return(NA)
    })
    
    cat("Is read-only:", is_readonly, "\n")
    
    tables <- tryCatch({
      DBI::dbListTables(con)
    }, error = function(e) {
      cat("Error listing tables:", e$message, "\n")
      return(character(0))
    })
    
    cat("Tables:", paste(tables, collapse=", "), ifelse(length(tables) == 0, "(none)", ""), "\n")
    
    # Try to write to test write access
    cat("Testing write access...\n")
    write_result <- tryCatch({
      DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS test_write_access (id INTEGER, value TEXT)")
      DBI::dbExecute(con, "INSERT INTO test_write_access VALUES (1, 'test')")
      DBI::dbExecute(con, "DROP TABLE IF EXISTS test_write_access")
      TRUE
    }, error = function(e) {
      cat("Write test failed:", e$message, "\n")
      FALSE
    })
    
    cat("Write access test:", ifelse(write_result, "Successful", "Failed"), "\n")
    
    # Close the connection
    if(DBI::dbIsValid(con)) {
      DBI::dbDisconnect(con)
      cat("Connection closed\n")
    }
  } else {
    cat("Connection object is not a DBIConnection\n")
  }
}, error = function(e) {
  cat("Error testing database connection:", e$message, "\n")
})

# Clean up environment
cat("\nTest script completed\n")