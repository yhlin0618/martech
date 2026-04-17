#' Universal Data Accessor Function
#' 
#' @description
#' A flexible and robust function that can extract data from various connection types including
#' DBI database connections, reactive expressions, lists with accessor functions, and direct data
#' frames. This function provides consistent access to data regardless of source type.
#'
#' @param data_conn The data connection object, which can be:
#'   - A DBI database connection (DuckDB, SQLite, PostgreSQL, etc.)
#'   - A reactive expression returning a connection or data object
#'   - A list with data access functions (get_data, query_data, etc.)
#'   - A list with direct data references
#'   - A data frame (directly returns the data frame)
#' @param data_name The name of the data to retrieve (e.g., "customer_profile", "dna_by_customer")
#' @param query_template Optional SQL query template if using a database connection. If provided, 
#'   it will be used instead of the default "SELECT * FROM {data_name}" query.
#'   Uses glue syntax with {data_name} and any other variables in parent environment.
#'   Can be a string or a query object (see details).
#' @param query_objects Alternative to query_template for multiple queries. A list of query objects, 
#'   where each query object is a list with 'template' and 'params' elements. 
#'   Example: `list(list(template = "SELECT * FROM {table} WHERE id < {max_id}", 
#'   params = list(table = "customers", max_id = 100)))`
#' @param combine_results Logical. If TRUE and multiple queries are executed, results will be combined
#'   using dplyr::bind_rows. If FALSE, a list of results will be returned.
#' @param log_level Logging level: "TRACE", "DEBUG", "INFO", "WARN", "ERROR", or "FATAL"
#'
#' @details
#' When using query objects, each object should have:
#' - template: A string template with placeholders in {braces}
#' - params: A list of parameter values to substitute into the template
#' 
#' The data_name parameter will be available as {data_name} in the template if not overridden
#' in the params list.
#'
#' @return The requested data as a data frame, or NULL if data cannot be retrieved
#'
#' @examples
#' # Use with a list containing data frames
#' data_list <- list(customer_profile = data.frame(id = 1:3, name = c("A", "B", "C")))
#' customers <- universal_data_accessor(data_list, "customer_profile")
#'
#' # Use with a DBI database connection
#' # db_conn <- DBI::dbConnect(duckdb::duckdb(), "app_data.duckdb")
#' # customers <- universal_data_accessor(db_conn, "customer_profile")
#'
#' # Use with function-based connection
#' # fn_conn <- list(get_customer_profile = function() data.frame(id = 1:3, name = c("A", "B", "C")))
#' # customers <- universal_data_accessor(fn_conn, "customer_profile")
#'
#' # Use with a Shiny reactive expression
#' # In a Shiny app: reactive_data <- reactive({ app_connection })
#' # customers <- universal_data_accessor(reactive_data, "customer_profile")
#'
#' # Use with a query template
#' # For platform filtering:
#' # plat_id <- 5
#' # customers <- universal_data_accessor(db_conn, "customer_profile",
#' #                                     query_template = "SELECT * FROM {data_name} WHERE platform_id = {plat_id}")
#' #
#' # Use with query objects for multiple queries:
#' # queries <- list(
#' #   list(
#' #     template = "SELECT * FROM {data_name} WHERE signup_date > '{cutoff_date}'",
#' #     params = list(cutoff_date = "2023-01-01")
#' #   ),
#' #   list(
#' #     template = "SELECT id, COUNT(*) as order_count FROM {order_table} GROUP BY id",
#' #     params = list(order_table = "orders")
#' #   )
#' # )
#' # results <- universal_data_accessor(db_conn, "customer_profile", 
#' #                                   query_objects = queries,
#' #                                   combine_results = FALSE)
#'
#' @export
#' @implements MP16 Modularity 
#' @implements MP17 Separation of Concerns
#' @implements MP81 Explicit Parameter Specification
#' @implements P76 Error Handling Patterns
#' @implements P77 Performance Optimization
#' @implements R76 Module Data Connection
#' @implements R91 Universal Data Access Pattern
#' @implements R92 Universal DBI Approach
#' @implements R94 Roxygen2 Function Examples Standard
#' @implements R114 Standard Mock Database Rule
#' @implements R116 Enhanced Data Access with tbl2

universal_data_accessor <- function(data_conn, data_name,
                                   query_template = NULL,
                                   query_objects = NULL,
                                   combine_results = TRUE,
                                   log_level = "INFO") {
  # ---- Setup logging ----
  if (!requireNamespace("logger", quietly = TRUE)) {
    stop("The 'logger' package is required. Please install it: install.packages('logger')")
  }
  
  # Safe log level setup with try-catch
  tryCatch({
    # Set log threshold only if valid level is provided
    logger_level <- NULL
    
    # Try to get a valid logger level
    if (is.character(log_level)) {
      # Handle case-insensitive matching for standard levels
      valid_levels <- c("TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL")
      if (toupper(log_level) %in% valid_levels) {
        log_level <- toupper(log_level)
        logger_level <- logger::log_level(log_level)
      }
    }
    
    # Default to INFO if not set or invalid
    if (is.null(logger_level)) {
      logger_level <- logger::INFO
    }
    
    # Set threshold safely
    logger::log_threshold(logger_level)
    
    # Log start of data access
    logger::log_info("Starting data access for '{data_name}'")
  }, 
  error = function(e) {
    # Fallback if logger has issues
    message("Note: Logger initialization failed, continuing without logging")
  })

  # ---- Process query if needed ----
  process_query <- function(template = query_template, extra_params = list()) {
    if (is.null(template)) return(NULL)
    
    if (!requireNamespace("glue", quietly = TRUE)) {
      stop("The 'glue' package is required for SQL templating.")
    }
    
    # Create environment with data_name and any extra parameters
    env <- new.env(parent = parent.frame())
    env$data_name <- data_name
    
    # Add any extra parameters to the environment
    if (length(extra_params) > 0) {
      for (param_name in names(extra_params)) {
        env[[param_name]] <- extra_params[[param_name]]
      }
    }
    
    # Use glue to process the query template
    query <- glue::glue(template, .envir = env)
    tryCatch({ logger::log_debug("Processed query: {query}") }, error = function(e) {})
    return(as.character(query))
  }
  
  # ---- Process query object ----
  process_query_object <- function(query_obj) {
    if (!is.list(query_obj) || is.null(query_obj$template)) {
      stop("Invalid query object structure. Must be a list with 'template' element")
    }
    
    # Get the template
    template <- query_obj$template
    
    # Get parameters if provided
    params <- list()
    if (!is.null(query_obj$params) && is.list(query_obj$params)) {
      params <- query_obj$params
    }
    
    # Process the template with parameters
    return(process_query(template, params))
  }

  # ---- Handle query objects if provided ----
  if (!is.null(query_objects)) {
    # Check if we have a list of query objects or a single query object
    if (is.list(query_objects) && "template" %in% names(query_objects)) {
      # Single query object - convert to a list containing one object
      query_objects <- list(query_objects)
    }
    
    if (!is.list(query_objects) || !all(sapply(query_objects, is.list))) {
      stop("Invalid query_objects parameter. Expected a list of query objects.")
    }
    
    # Execute multiple queries
    tryCatch({
      results <- list()
      
      for (i in seq_along(query_objects)) {
        query_obj <- query_objects[[i]]
        
        # Process the query object into a SQL query
        sql_query <- process_query_object(query_obj)
        
        # Log the query execution
        tryCatch({ 
          logger::log_info("Executing query {i} of {length(query_objects)}") 
        }, error = function(e) {})
        
        # Execute the query
        if (inherits(data_conn, "DBIConnection")) {
          # For DBI connections, use dbGetQuery
          query_result <- DBI::dbGetQuery(data_conn, sql_query)
        } else {
          # For other connection types, fall back to legacy method
          query_result <- legacy_data_access(data_conn, data_name, sql_query)
        }
        
        # Store the result
        results[[i]] <- query_result
        
        # Log the result
        tryCatch({
          logger::log_info("Query {i} returned {nrow(query_result)} rows and {ncol(query_result)} columns")
        }, error = function(e) {})
      }
      
      # Return results based on combine_results parameter
      if (combine_results && length(results) > 0) {
        if (!requireNamespace("dplyr", quietly = TRUE)) {
          stop("The 'dplyr' package is required to combine results. Please install it.")
        }
        
        # Check if all results are data frames
        if (all(sapply(results, is.data.frame))) {
          tryCatch({
            logger::log_info("Combining {length(results)} query results")
          }, error = function(e) {})
          
          # Combine results with bind_rows
          final_result <- dplyr::bind_rows(results)
          return(final_result)
        } else {
          # If some results are not data frames, return as list
          warning("Some query results are not data frames. Returning as list.")
          return(results)
        }
      } else {
        # Return as list of results
        return(results)
      }
    }, error = function(e) {
      tryCatch({
        logger::log_error("Error executing query objects: {e$message}")
      }, error = function(err) {})
      
      # Try legacy method as fallback
      return(legacy_data_access(data_conn, data_name, query_template))
    })
  }
  
  # ---- Access data via tbl2 interface (for standard query) ----
  tryCatch({
    # Check if tbl2 function is available
    if (exists("tbl2", mode = "function") || requireNamespace("tbl2", quietly = TRUE)) {
      # Use tbl2 for enhanced data access (R116)
      tryCatch({ logger::log_info("Using tbl2 for enhanced data access") }, error = function(e) {})
      df_ref <- tbl2(data_conn, data_name)
    } else {
      # Fall back to standard tbl for backward compatibility
      tryCatch({ logger::log_info("tbl2 not available, using standard tbl") }, error = function(e) {})
      df_ref <- tbl(data_conn, data_name)
    }
    
    # Apply query if provided (for filtering)
    if (!is.null(query_template)) {
      query <- process_query()
      # For now, we don't directly support arbitrary queries through tbl/tbl2
      # This would require parsing the WHERE clause and applying it as dplyr filters
      # Instead, log that we're using the raw query
      tryCatch({ logger::log_warn("Query template provided but using tbl interface - query will be used if possible") }, error = function(e) {})
      
      # For DBI connections, we can try using dbplyr's sql() function
      if (inherits(data_conn, "DBIConnection") && requireNamespace("dbplyr", quietly = TRUE)) {
        tryCatch({ logger::log_info("Using dbplyr to execute query") }, error = function(e) {})
        df_ref <- dplyr::tbl(data_conn, dbplyr::sql(query))
      }
    }
    
    # Collect the data
    tryCatch({ logger::log_info("Collecting data from {data_name}") }, error = function(e) {})
    result <- df_ref %>% dplyr::collect()
    
    # Log results safely
    tryCatch({
      logger::log_info("Retrieved {nrow(result)} rows and {ncol(result)} columns for '{data_name}'")
    }, error = function(e) {
      # Silent fail - already handling logging errors
    })
    return(result)
  }, error = function(e) {
    tryCatch({
      logger::log_error("Error accessing data: {e$message}")
      # Fallback to legacy method
      logger::log_warn("Attempting legacy data access method")
    }, error = function(err) {
      message("Error accessing data, attempting legacy method")
    })
    return(legacy_data_access(data_conn, data_name, query_template))
  })
}

# Legacy data access method (as fallback)
legacy_data_access <- function(data_conn, data_name, query_template = NULL) {
  tryCatch({
    logger::log_info("Using legacy data access method for '{data_name}'")
  }, error = function(e) {
    message("Using legacy data access method")
  })
  
  # Special case for direct data frame with NULL data_name
  if (is.data.frame(data_conn) && is.null(data_name)) {
    return(data_conn)  # Return the data frame directly
  }
  
  # Unwrap reactive if needed
  if (inherits(data_conn, "reactiveExpr")) {
    tryCatch({ logger::log_debug("Unwrapping reactive connection") }, error = function(e) {})
    data_conn <- data_conn()
  }
  
  # Build SQL if needed
  build_sql <- function(name) {
    if (!is.null(query_template)) {
      sql <- glue::glue(query_template, data_name = name, .envir = parent.frame())
      tryCatch({ logger::log_debug("Built SQL: {sql}") }, error = function(e) {})
      return(as.character(sql))
    }
    
    # Default: SELECT * FROM best-matching table
    variants <- c(name, paste0("df_", name), paste0(name, "_dta"))
    available <- tryCatch(DBI::dbListTables(data_conn), error = function(e) NULL)
    table_match <- intersect(variants, available)
    
    if (length(table_match) > 0) {
      table_name <- table_match[[1]]
    } else {
      table_name <- name
    }
    
    sql <- paste0("SELECT * FROM ", table_name)
    tryCatch({ logger::log_debug("Default SQL: {sql}") }, error = function(e) {})
    return(sql)
  }
  
  # Determine connection type
  is_dbi <- inherits(data_conn, "DBIConnection") ||
            inherits(data_conn, "duckdb_connection") ||
            inherits(data_conn, "SQLiteConnection") ||
            inherits(data_conn, "PqConnection")
  
  # Retrieve data
  result <- NULL
  if (is_dbi) {
    sql <- build_sql(data_name)
    result <- tryCatch({
      tryCatch({ logger::log_info("Executing SQL query") }, error = function(e) {})
      DBI::dbGetQuery(data_conn, sql)
    }, error = function(e) {
      tryCatch({ logger::log_error("DBI query failed: {e$message}") }, error = function(err) {})
      NULL
    })
  } else if (is.list(data_conn)) {
    # List with possible accessors
    if (is.function(data_conn$get_data)) {
      tryCatch({ logger::log_info("Using generic get_data()") }, error = function(e) {})
      result <- tryCatch(data_conn$get_data(data_name), error = function(e) NULL)
    } else if (data_name %in% names(data_conn)) {
      tryCatch({ logger::log_info("Using direct list element '{data_name}'") }, error = function(e) {})
      result <- data_conn[[data_name]]
    } else {
      getter <- paste0("get_", data_name)
      if (is.function(data_conn[[getter]])) {
        tryCatch({ logger::log_info("Using function '{getter}()'") }, error = function(e) {})
        result <- tryCatch(data_conn[[getter]](), error = function(e) NULL)
      } else {
        tryCatch({ logger::log_warn("No accessor found for '{data_name}' in list connection") }, error = function(e) {})
      }
    }
  } else if (is.data.frame(data_conn)) {
    tryCatch({ logger::log_info("Using provided data.frame as result") }, error = function(e) {})
    result <- data_conn
  } else {
    tryCatch({ logger::log_warn("Unsupported connection type in legacy method: returning NULL") }, error = function(e) {})
  }
  
  # Validate and return
  if (is.null(result)) {
    tryCatch({ logger::log_warn("No data retrieved for '{data_name}' using legacy method") }, error = function(e) {})
    return(NULL)
  }
  if (!is.data.frame(result)) {
    tryCatch({ logger::log_debug("Converting result to data.frame") }, error = function(e) {})
    result <- tryCatch(as.data.frame(result), error = function(e) NULL)
    if (is.null(result)) {
      tryCatch({ logger::log_error("Could not convert result to data.frame") }, error = function(e) {})
      return(NULL)
    }
  }
  
  tryCatch({ logger::log_info("Legacy method retrieved {nrow(result)} rows and {ncol(result)} columns for '{data_name}'") }, error = function(e) {})
  return(result)
}

#' Provide a dplyr-like tbl interface for any data source
#'
#' This function returns a tbl reference that supports lazy operations
#' (filter, select, etc.) and collects only when needed.
#'
#' @param data_conn A data source: DBI connection, list, function-based connection,
#'   reactive expression, or data frame.
#' @param data_name The name of the table or data object to retrieve.
#' @return A lazy tbl reference supporting dplyr verbs and collect().
#' @export
#' @examples
#' # DBI:
#' # conn <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#' # DBI::dbWriteTable(conn, "mtcars", mtcars)
#' # tbl(conn, "mtcars") %>% filter(cyl == 6) %>% collect()
#'
#' # List connection:
#' # lc <- list(get_mtcars = function() mtcars)
#' # tbl(lc, "mtcars") %>% select(mpg, cyl) %>% collect()
#'
#' # Data frame directly:
#' # tbl(mtcars, NULL) %>% summarize(avg = mean(mpg)) %>% collect()

tbl <- function(data_conn, data_name = NULL) {
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Please install dplyr to use tbl().")
  }
  
  # Unwrap Shiny reactive
  if (inherits(data_conn, "reactiveExpr")) {
    data_conn <- data_conn()
  }

  # DBI connections
  if (inherits(data_conn, "DBIConnection") ||
      inherits(data_conn, "duckdb_connection") ||
      inherits(data_conn, "SQLiteConnection") ||
      inherits(data_conn, "PqConnection")) {
    table_name <- find_table_in_db(data_conn, data_name)
    return(dplyr::tbl(data_conn, table_name))
  }

  # If data_conn is a function that returns a data frame
  if (is.function(data_conn) && is.null(data_name)) {
    df <- data_conn()
    return(dplyr::as_tibble(df))
  }

  # List-based connections
  if (is.list(data_conn)) {
    # Generic accessor
    if (!is.null(data_conn$get_data) && is.function(data_conn$get_data)) {
      df <- data_conn$get_data(data_name)
      return(dplyr::as_tibble(df))
    }
    # Pattern-based getters
    getter <- paste0("get_", data_name)
    if (!is.null(data_conn[[getter]]) && is.function(data_conn[[getter]])) {
      df <- data_conn[[getter]]()
      return(dplyr::as_tibble(df))
    }
    # Direct list element
    if (!is.null(data_conn[[data_name]]) && is.data.frame(data_conn[[data_name]])) {
      return(dplyr::as_tibble(data_conn[[data_name]]))
    }
    stop(sprintf("No data accessor found for '%s' in list.", data_name))
  }

  # Direct data frame
  if (is.data.frame(data_conn)) {
    return(dplyr::as_tibble(data_conn))
  }

  stop("Unsupported connection type for tbl().")
}

# Helper: locate table name in DBI connection variants
find_table_in_db <- function(conn, name) {
  if (is.null(name)) {
    stop("data_name must be provided for DBI connections.")
  }
  variants <- c(name,
                paste0("df_", name),
                paste0(name, "_dta"))
  tables <- tryCatch(DBI::dbListTables(conn), error = function(e) NULL)
  if (!is.null(tables)) {
    match <- intersect(variants, tables)
    if (length(match) > 0) return(match[[1]])
  }
  name
}

#' Create Mock Database Connection for Testing
#' 
#' @description
#' Creates a mock database connection object for testing using the standard
#' mock_data.duckdb database located in global_scripts/30_global_data directory.
#' This function follows R114 Standard Mock Database Rule requirements.
#'
#' @param connection_type The type of mock connection to create:
#'   - "dbi": Returns a DBI connection to the mock database (default)
#'   - "list": Creates a list with data frames loaded from the mock database
#' @param custom_db_path Optional custom path to the mock database. If not provided,
#'   the standard path in global_scripts/30_global_data/mock_data.duckdb will be used.
#'
#' @return A mock connection object with the specified behavior
#'
#' @examples
#' # Create a mock DBI connection
#' mock_conn <- create_mock_connection("dbi")
#' 
#' # Use with universal_data_accessor
#' profiles <- universal_data_accessor(mock_conn, "customer_profile")
#'
#' # Use with custom database path
#' custom_conn <- create_mock_connection("dbi", custom_db_path = "path/to/test.duckdb")
#'
#' @export
#' @implements P51 Test Data Design
#' @implements R114 Standard Mock Database Rule

create_mock_connection <- function(connection_type = c("dbi", "list"), custom_db_path = NULL) {
  connection_type <- match.arg(connection_type)
  
  # Use provided custom path or calculate standard path
  if (!is.null(custom_db_path)) {
    db_path <- custom_db_path
    tryCatch({ logger::log_info("Using custom database path: {db_path}") }, error = function(e) {})
  } else {
    # Define standard path to mock database using project root finder
    root_dir <- find_project_root()
    db_path <- file.path(root_dir, "update_scripts", 
                         "global_scripts", "30_global_data", "mock_data.duckdb")
    tryCatch({ logger::log_info("Using standard mock database path (R114): {db_path}") }, error = function(e) {})
  }
  
  if (!file.exists(db_path)) {
    stop("Mock database not found at: ", db_path, 
         ". Please run sc_create_mock_duckdb.R to create it.")
  }
  
  # Create connections based on type
  if (connection_type == "dbi") {
    if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
      stop("The 'DBI' and 'duckdb' packages are required. Please install them.")
    }
    
    # Create and return DBI connection to the standard mock database
    conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
    tryCatch({ logger::log_info("Connected to standard mock database at: {db_path}") }, error = function(e) {})
    return(conn)
  } else {
    # List connection - load all tables from database into a list
    if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
      stop("The 'DBI' and 'duckdb' packages are required. Please install them.")
    }
    
    # Connect to database
    temp_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
    
    # List tables and create a data list
    tables <- DBI::dbListTables(temp_conn)
    data_list <- list()
    
    for (table_name in tables) {
      data_list[[table_name]] <- DBI::dbReadTable(temp_conn, table_name)
    }
    
    # Close connection
    DBI::dbDisconnect(temp_conn, shutdown = TRUE)
    
    # Add class for compatibility
    class(data_list) <- c("list", "mock_list_connection")
    
    tryCatch({ logger::log_info("Loaded {length(tables)} tables from standard mock database") }, error = function(e) {})
    return(data_list)
  }
}

#' Create Standard Database Connection
#' 
#' @description
#' Creates a database connection according to the application mode.
#' In development/testing mode, connects to the standard mock database
#' following R114 Standard Mock Database Rule. In production mode,
#' connects to the specified production database.
#'
#' @param mode The application mode: "development", "testing", or "production"
#' @param production_conn_params Optional parameters for production connection (a list)
#'
#' @return A DBI connection object
#'
#' @examples
#' # Development mode - connects to mock database
#' dev_conn <- db_connection_factory("development")
#' 
#' # Production mode with connection parameters
#' # prod_params <- list(host = "db.example.com", port = 5432, 
#' #                    user = "app_user", password = Sys.getenv("DB_PASSWORD"))
#' # prod_conn <- db_connection_factory("production", prod_params)
#'
#' @export
#' @implements R92 Universal DBI Approach
#' @implements R114 Standard Mock Database Rule

#' Find Project Root Directory
#' 
#' @description
#' Helper function to find the project root directory by looking for 
#' standard marker files/directories. This helps with reliable path
#' resolution regardless of the current working directory.
#'
#' @return The absolute path to the project root directory
#'
#' @examples
#' # Get the project root
#' root_dir <- find_project_root()
#' 
#' # Use it to build a path
#' db_path <- file.path(root_dir, "update_scripts", "global_scripts", "30_global_data", "mock_data.duckdb")
#'
#' @keywords internal

find_project_root <- function() {
  # Start from current directory
  current_dir <- normalizePath(getwd())
  
  # Markers that indicate project root
  root_markers <- c(
    file.path("update_scripts", "global_scripts"),
    file.path("precision_marketing_app"),
    "DESCRIPTION",
    ".Rproj",
    ".git"
  )
  
  # Check current and parent directories
  dir_to_check <- current_dir
  max_levels <- 10  # Avoid infinite loop
  
  for (i in 1:max_levels) {
    # Check for markers
    for (marker in root_markers) {
      if (file.exists(file.path(dir_to_check, marker))) {
        return(dir_to_check)
      }
    }
    
    # Move up to parent directory
    parent_dir <- dirname(dir_to_check)
    
    # If we've reached the filesystem root, stop
    if (parent_dir == dir_to_check) {
      break
    }
    
    dir_to_check <- parent_dir
  }
  
  # If root not found, fall back to working directory
  warning("Could not find project root directory. Using current working directory.")
  return(current_dir)
}

db_connection_factory <- function(mode = "development", production_conn_params = NULL) {
  if (!requireNamespace("DBI", quietly = TRUE)) {
    stop("The 'DBI' package is required. Please install it: install.packages('DBI')")
  }
  
  # Handle development and testing modes with standard mock database
  if (mode == "development" || mode == "testing") {
    if (!requireNamespace("duckdb", quietly = TRUE)) {
      stop("The 'duckdb' package is required. Please install it: install.packages('duckdb')")
    }
    
    # Use standard mock database path, using project root finder
    root_dir <- find_project_root()
    db_path <- file.path(root_dir, "update_scripts", 
                         "global_scripts", "30_global_data", "mock_data.duckdb")
    
    if (!file.exists(db_path)) {
      stop("Standard mock database not found at: ", db_path, 
           ". Please run sc_create_mock_duckdb.R to create it.")
    }
    
    # Connect in read-only mode for safety in development/testing
    read_only <- TRUE
    
    tryCatch({ logger::log_info("Connecting to standard mock database at: {db_path} (R114)") }, error = function(e) {})
    return(DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = read_only))
  }
  
  # Production mode - requires connection parameters
  if (mode == "production") {
    if (is.null(production_conn_params)) {
      stop("Production connection parameters must be provided for production mode")
    }
    
    # Implementation depends on the production database type
    # Here's a placeholder - actual implementation would use the provided parameters
    stop("Production database connection not implemented - please specify your production DB logic")
  }
  
  stop("Invalid mode: ", mode, ". Must be one of: development, testing, production")
}

#' Create Reactive Data Connection for Shiny
#'
#' @description
#' Creates a reactive data connection wrapper for use in Shiny applications.
#' This function converts various data sources into a reactive data connection
#' that can be safely used with Shiny modules implementing R76 (Module Data Connection).
#'
#' @param data_source The data source, which can be:
#'   - A DBI database connection
#'   - A list of data frames
#'   - A list with data access functions
#' @param reactive_wrapper Whether to wrap the result in a reactive expression
#'   (set to FALSE if the data_source is already reactive)
#'
#' @return A reactive data connection that can be passed to R76-compliant modules
#'
#' @examples
#' # In a Shiny app:
#' # server <- function(input, output, session) {
#' #   # Create data
#' #   test_data <- list(
#' #     customer_profile = data.frame(id = 1:3, name = c("A", "B", "C"))
#' #   )
#' #   
#' #   # Create reactive connection
#' #   data_conn <- create_reactive_data_connection(test_data)
#' #   
#' #   # Pass to module
#' #   customerModule("customer_module", data_connection = data_conn)
#' # }
#'
#' @export
#' @implements R76 Module Data Connection
#' @implements P24 Reactive Access Safety

create_reactive_data_connection <- function(data_source, reactive_wrapper = TRUE) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("This function requires shiny. Install with install.packages('shiny')")
  }
  if (reactive_wrapper && !(inherits(data_source, "reactiveExpr"))) {
    return(shiny::reactive({ data_source }))
  }
  data_source
}

# Example usage for unit testing - commented out
# This code is only for documentation purposes to show how to use these functions

# if (FALSE) {
#   # Example: Connect to standard mock database in development mode
#   conn <- db_connection_factory("development")
#   
#   # Access data using universal_data_accessor
#   customer_data <- universal_data_accessor(conn, "customer_profile")
#   
#   # Query with a template
#   query_template <- "SELECT * FROM {data_name} WHERE signup_date > '2021-06-01'"
#   filtered_customers <- universal_data_accessor(conn, "customer_profile",
#                                               query_template = query_template)
#   
#   # Use with dplyr syntax via tbl2 (R116)
#   library(dplyr)
#   customers_dplyr <- tbl2(conn, "customer_profile") %>%
#     filter(signup_date > as.Date("2021-06-01")) %>%
#     collect()
#   
#   # Clean up connection
#   if (DBI::dbIsValid(conn)) {
#     DBI::dbDisconnect(conn, shutdown = TRUE)
#   }
# }