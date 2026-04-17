#' @file fn_dbConnectTwoDatabases.R
#' @requires DBI
#' @requires duckdb
#' @depends 02_db_utils/fn_dbConnect_from_list.R
#' 
#' @title Connect to Two Databases Simultaneously
#'
#' @description
#' Establishes connections to two specified DuckDB databases simultaneously and
#' tracks connection creation status for proper error handling and cleanup.
#'
#' @param db1_name Character. The name of the first database to connect to (must exist in path_list)
#' @param db2_name Character. The name of the second database to connect to (must exist in path_list)
#' @param db1_read_only Logical. Whether to open the first database in read-only mode (defaults to FALSE)
#' @param db2_read_only Logical. Whether to open the second database in read-only mode (defaults to FALSE)
#' @param path_list List. The list of database paths (defaults to db_path_list)
#' @param verbose Logical. Whether to display information about the connections (defaults to TRUE)
#' @param ensure_connections Logical. Whether to ensure both connections are created successfully (defaults to TRUE)
#'
#' @return List containing both connection objects and tracking information
#'
#' @details
#' The function performs the following steps:
#' 1. Initializes connection tracking variables to record which connections were created
#' 2. Attempts to connect to the first database with proper error handling
#' 3. Attempts to connect to the second database with proper error handling
#' 4. Returns a list with both connections and tracking information
#'
#' If ensure_connections=TRUE and any connection fails, all successful connections
#' will be properly closed before the function returns an error.
#'
#' @note
#' - Connections are stored in the global environment with the same names as the datasets
#' - The returned tracking information enables proper cleanup with dbDisconnectTwoDatabases()
#' - This function follows the INITIALIZE section structure from R113 Update Script Structure Rule
#'
#' @examples
#' # Connect to raw_data and app_data databases
#' connections <- dbConnectTwoDatabases("raw_data", "app_data")
#'
#' # Use the connections for operations
#' tables1 <- DBI::dbListTables(connections$db1)
#' tables2 <- DBI::dbListTables(connections$db2)
#'
#' # Disconnect when done
#' dbDisconnectTwoDatabases(connections)
#'
#' @export
dbConnectTwoDatabases <- function(db1_name, db2_name, 
                                 db1_read_only = FALSE, db2_read_only = FALSE,
                                 path_list = db_path_list, 
                                 verbose = TRUE,
                                 ensure_connections = TRUE) {
  # Initialize tracking variables
  connections_created <- list(
    db1 = FALSE,
    db2 = FALSE
  )
  
  # Initialize result list
  result <- list(
    db1 = NULL,
    db2 = NULL,
    connections_created = connections_created,
    db1_name = db1_name,
    db2_name = db2_name
  )
  
  # Helper function to clean up connections on error
  cleanup_on_error <- function() {
    if (connections_created$db1) {
      if (verbose) message("Cleaning up: disconnecting from ", db1_name)
      DBI::dbDisconnect(get(db1_name, envir = .GlobalEnv), shutdown = TRUE)
      if (exists(db1_name, envir = .GlobalEnv)) {
        rm(list = db1_name, envir = .GlobalEnv)
      }
    }
    
    if (connections_created$db2) {
      if (verbose) message("Cleaning up: disconnecting from ", db2_name)
      DBI::dbDisconnect(get(db2_name, envir = .GlobalEnv), shutdown = TRUE)
      if (exists(db2_name, envir = .GlobalEnv)) {
        rm(list = db2_name, envir = .GlobalEnv)
      }
    }
  }
  
  # Try to connect to the first database
  tryCatch({
    result$db1 <- dbConnect_from_list(db1_name, path_list = path_list, 
                                     read_only = db1_read_only, verbose = verbose)
    connections_created$db1 <- TRUE
  }, error = function(e) {
    if (ensure_connections) {
      cleanup_on_error()
      stop("Failed to connect to first database (", db1_name, "): ", e$message)
    } else if (verbose) {
      warning("Failed to connect to first database (", db1_name, "): ", e$message)
    }
  })
  
  # Try to connect to the second database
  tryCatch({
    result$db2 <- dbConnect_from_list(db2_name, path_list = path_list, 
                                     read_only = db2_read_only, verbose = verbose)
    connections_created$db2 <- TRUE
  }, error = function(e) {
    if (ensure_connections) {
      cleanup_on_error()
      stop("Failed to connect to second database (", db2_name, "): ", e$message)
    } else if (verbose) {
      warning("Failed to connect to second database (", db2_name, "): ", e$message)
    }
  })
  
  # Update the tracking information
  result$connections_created <- connections_created
  
  # Check if we should ensure all connections
  if (ensure_connections && (!connections_created$db1 || !connections_created$db2)) {
    cleanup_on_error()
    stop("Could not establish all required database connections")
  }
  
  # Return the result
  return(result)
}

#' @title Disconnect from Two Databases
#'
#' @description
#' Disconnects from two databases that were connected using dbConnectTwoDatabases()
#' and cleans up the connection objects from the global environment.
#'
#' @param connections List. The connection tracking object returned by dbConnectTwoDatabases()
#' @param verbose Logical. Whether to display information about disconnection (defaults to TRUE)
#'
#' @return Logical. TRUE if all operations succeeded, FALSE otherwise
#'
#' @examples
#' # Connect to two databases
#' connections <- dbConnectTwoDatabases("raw_data", "app_data")
#' 
#' # ... perform operations ...
#' 
#' # Disconnect when done
#' dbDisconnectTwoDatabases(connections)
#'
#' @export

dbDisconnectTwoDatabases <- function(connections, verbose = TRUE) {
  # Initialize success flag
  success <- TRUE
  
  # Extract tracking information
  connections_created <- connections$connections_created
  db1_name <- connections$db1_name
  db2_name <- connections$db2_name
  
  # Disconnect from first database if it was connected
  if (connections_created$db1 && exists(db1_name, envir = .GlobalEnv)) {
    tryCatch({
      DBI::dbDisconnect(get(db1_name, envir = .GlobalEnv), shutdown = TRUE)
      rm(list = db1_name, envir = .GlobalEnv)
      if (verbose) message("Successfully disconnected from ", db1_name)
    }, error = function(e) {
      warning("Error disconnecting from ", db1_name, ": ", e$message)
      success <- FALSE
    })
  }
  
  # Disconnect from second database if it was connected
  if (connections_created$db2 && exists(db2_name, envir = .GlobalEnv)) {
    tryCatch({
      DBI::dbDisconnect(get(db2_name, envir = .GlobalEnv), shutdown = TRUE)
      rm(list = db2_name, envir = .GlobalEnv)
      if (verbose) message("Successfully disconnected from ", db2_name)
    }, error = function(e) {
      warning("Error disconnecting from ", db2_name, ": ", e$message)
      success <- FALSE
    })
  }
  
  return(success)
}

#' @note
#' This function follows R0103 (Dependency-Based Sourcing) which requires 
#' explicit dependency annotations. The dependencies are:
#' - DBI package - Required for database interface functions
#' - duckdb package - Required for DuckDB connections
#' - fn_dbConnect_from_list.R - Required for establishing individual connections
#'