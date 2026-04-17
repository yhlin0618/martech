#' Database Connection Factory
#' 
#' @description
#' Creates and manages database connections for the application, providing a consistent
#' interface regardless of whether using a real database or mock data. This factory
#' implements the Universal DBI Approach (R92) which standardizes data access throughout
#' the application.
#'
#' @param mode Connection mode: "production", "development", or "test"
#' @param config Connection configuration (if needed)
#' @param mock_data_list List of data frames for mock connections (development/test mode)
#' @param mock_source Directory with mock data files (CSV/RDS/Excel)
#' @param mock_source_type Type of mock data source: "csv_dir", "rds_dir", or "excel"
#'
#' @return A database connection object (real or mock)
#'
#' @examples
#' # Production mode with real database
#' conn <- db_connection_factory("production")
#'
#' # Development mode with mock data
#' test_data <- list(
#'   customer_profile = data.frame(id = 1:3, name = c("A", "B", "C")),
#'   dna_by_customer = data.frame(customer_id = 1:3, value = 10:12)
#' )
#' conn <- db_connection_factory("development", mock_data_list = test_data)
#'
#' @export
#' @implements R92 Universal DBI Approach
db_connection_factory <- function(mode = "development", 
                                 config = NULL,
                                 mock_data_list = NULL,
                                 mock_source = NULL,
                                 mock_source_type = NULL) {
  # Load dependencies
  if (!exists("list_to_mock_dbi")) {
    source_file <- "scripts/global_scripts/00_principles/02_db_utils/fn_list_to_mock_dbi.R"
    if (file.exists(source_file)) {
      source(source_file)
    } else {
      stop("Required utility 'fn_list_to_mock_dbi.R' not found")
    }
  }
  
  if (mode == "production") {
    # Production mode: Use real database connection
    if (!requireNamespace("DBI", quietly = TRUE)) {
      stop("DBI package is required for production database connection")
    }
    
    # Default to DuckDB if no specific config provided
    if (is.null(config)) {
      if (!requireNamespace("duckdb", quietly = TRUE)) {
        stop("duckdb package is required for default database connection")
      }
      
      # Use default DuckDB database
      db_path <- "app_data/app_data.duckdb"
      message("Connecting to production database: ", db_path)
      
      # Connect to database
      tryCatch({
        conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
        
        # Add app-specific metadata
        attr(conn, "connection_type") <- "production_duckdb"
        attr(conn, "connection_time") <- Sys.time()
        
        return(conn)
      }, error = function(e) {
        warning("Failed to connect to production database: ", e$message)
        warning("Falling back to mock database")
        # Fall back to development mode if production connection fails
        return(db_connection_factory("development", mock_data_list = mock_data_list))
      })
    } else {
      # Use custom configuration
      if (!is.list(config)) {
        stop("Config must be a list with connection parameters")
      }
      
      # Check which database type is configured
      if (!is.null(config$duckdb)) {
        # DuckDB configuration
        if (!requireNamespace("duckdb", quietly = TRUE)) {
          stop("duckdb package is required for configured database connection")
        }
        
        db_path <- config$duckdb$dbdir
        message("Connecting to configured DuckDB database: ", db_path)
        
        conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
        attr(conn, "connection_type") <- "production_duckdb_configured"
        return(conn)
        
      } else if (!is.null(config$sqlite)) {
        # SQLite configuration
        if (!requireNamespace("RSQLite", quietly = TRUE)) {
          stop("RSQLite package is required for SQLite connection")
        }
        
        db_path <- config$sqlite$dbname
        message("Connecting to SQLite database: ", db_path)
        
        conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
        attr(conn, "connection_type") <- "production_sqlite"
        return(conn)
        
      } else if (!is.null(config$postgresql)) {
        # PostgreSQL configuration
        if (!requireNamespace("RPostgres", quietly = TRUE)) {
          stop("RPostgres package is required for PostgreSQL connection")
        }
        
        message("Connecting to PostgreSQL database: ", config$postgresql$dbname)
        
        conn <- DBI::dbConnect(
          RPostgres::Postgres(),
          dbname = config$postgresql$dbname,
          host = config$postgresql$host,
          port = config$postgresql$port,
          user = config$postgresql$user,
          password = config$postgresql$password
        )
        attr(conn, "connection_type") <- "production_postgresql"
        return(conn)
        
      } else {
        stop("Unknown database configuration")
      }
    }
  } else if (mode == "development" || mode == "test") {
    # Development/Test mode: Use mock database connection
    message("Creating mock database connection for ", mode, " mode")
    
    # If mock data is provided directly, use it
    if (!is.null(mock_data_list)) {
      conn <- list_to_mock_dbi(mock_data_list)
      attr(conn, "connection_type") <- paste0("mock_dbi_", mode)
      return(conn)
    }
    
    # If mock source is provided, load data from files
    if (!is.null(mock_source)) {
      if (is.null(mock_source_type)) {
        # Try to determine source type from directory structure
        if (dir.exists(mock_source)) {
          csv_files <- list.files(mock_source, pattern = "\\.csv$")
          rds_files <- list.files(mock_source, pattern = "\\.rds$")
          
          if (length(csv_files) > 0) {
            mock_source_type <- "csv_dir"
          } else if (length(rds_files) > 0) {
            mock_source_type <- "rds_dir"
          }
        } else if (file.exists(mock_source) && grepl("\\.(xlsx|xls)$", mock_source)) {
          mock_source_type <- "excel"
        }
      }
      
      if (!is.null(mock_source_type)) {
        conn <- create_dynamic_mock_dbi(source_type = mock_source_type, source_path = mock_source)
        attr(conn, "connection_type") <- paste0("mock_dbi_", mode, "_", mock_source_type)
        return(conn)
      } else {
        warning("Could not determine mock data source type, using empty mock connection")
      }
    }
    
    # If no mock data is provided, create a minimal mock connection
    minimal_data <- list(
      # Minimal customer data
      customer_profile = data.frame(
        customer_id = 1:3,
        buyer_name = c("Test User 1", "Test User 2", "Test User 3"),
        email = paste0("test", 1:3, "@example.com"),
        stringsAsFactors = FALSE
      ),
      
      # Minimal DNA data
      dna_by_customer = data.frame(
        customer_id = 1:2,
        time_first = as.Date(c("2024-01-01", "2024-02-01")),
        time_first_to_now = c(100, 70),
        r_label = c("近期", "一般"),
        r_value = c(10, 30),
        f_label = c("高", "一般"),
        f_value = c(8, 4),
        m_label = c("高", "一般"),
        m_value = c(5000, 2500),
        cai_label = c("活躍", "一般活躍"),
        cai = c(0.75, 0.4),
        stringsAsFactors = FALSE
      )
    )
    
    conn <- list_to_mock_dbi(minimal_data)
    attr(conn, "connection_type") <- paste0("mock_dbi_", mode, "_minimal")
    return(conn)
  } else {
    stop("Unknown connection mode: ", mode)
  }
}

#' Is Production Database Connection
#'
#' @description
#' Checks if a connection is a production database connection versus a mock/development connection.
#'
#' @param conn The database connection to check
#'
#' @return TRUE if the connection is a production database, FALSE otherwise
#'
#' @examples
#' conn <- db_connection_factory("production")
#' is_production_db(conn)  # Returns TRUE
#'
#' @export
#' @implements R92 Universal DBI Approach
is_production_db <- function(conn) {
  if (is.null(conn)) return(FALSE)
  
  # Check class and attributes
  conn_type <- attr(conn, "connection_type")
  
  if (!is.null(conn_type)) {
    return(grepl("^production_", conn_type))
  }
  
  # If no connection_type attribute, check class
  if (inherits(conn, "duckdb_connection") || 
      inherits(conn, "SQLiteConnection") || 
      inherits(conn, "PqConnection")) {
    return(TRUE)
  }
  
  if (inherits(conn, "mock_dbi_connection")) {
    return(FALSE)
  }
  
  # If we can't determine, assume it's not production to be safe
  return(FALSE)
}

#' Get Connection Information
#'
#' @description
#' Returns detailed information about a database connection.
#'
#' @param conn The database connection
#'
#' @return A list with connection details
#'
#' @examples
#' conn <- db_connection_factory("development")
#' get_connection_info(conn)
#'
#' @export
#' @implements R92 Universal DBI Approach
get_connection_info <- function(conn) {
  if (is.null(conn)) {
    return(list(
      status = "NULL",
      type = "none",
      valid = FALSE,
      tables = character(0)
    ))
  }
  
  # Base information
  info <- list(
    status = "unknown",
    type = class(conn)[1],
    valid = TRUE,
    created_at = attr(conn, "connection_time")
  )
  
  # Try to get connection type
  if (!is.null(attr(conn, "connection_type"))) {
    info$connection_type <- attr(conn, "connection_type")
  }
  
  # Try to get tables
  tryCatch({
    if (inherits(conn, "DBIConnection") || is.function(conn$dbListTables)) {
      tables <- if (is.function(conn$dbListTables)) {
        conn$dbListTables()
      } else if (requireNamespace("DBI", quietly = TRUE)) {
        DBI::dbListTables(conn)
      } else {
        character(0)
      }
      info$tables <- tables
      info$table_count <- length(tables)
    }
    
    # Add status information
    if (is_production_db(conn)) {
      info$status <- "production"
    } else if (inherits(conn, "mock_dbi_connection")) {
      info$status <- "mock"
      info$is_mock <- TRUE
    } else {
      info$status <- "development"
    }
    
    # Check validity for real connections
    if (!inherits(conn, "mock_dbi_connection") && requireNamespace("DBI", quietly = TRUE)) {
      if (is.function(conn$dbIsValid)) {
        info$valid <- conn$dbIsValid()
      } else {
        tryCatch({
          info$valid <- DBI::dbIsValid(conn)
        }, error = function(e) {
          info$valid <- FALSE
          info$error <- e$message
        })
      }
    }
  }, error = function(e) {
    info$error <- e$message
    info$valid <- FALSE
  })
  
  return(info)
}

#' Initialize App Database Connection
#'
#' @description
#' Initializes the application-wide database connection based on configuration.
#' This is typically called from app.R to establish the connection for the entire app.
#'
#' @param config Configuration options
#' @param environment_vars Environment variables to check for configuration
#'
#' @return A database connection object
#'
#' @examples
#' # In app.R:
#' app_db_conn <- initialize_app_db_connection()
#'
#' @export
#' @implements R92 Universal DBI Approach
initialize_app_db_connection <- function(config = NULL, environment_vars = NULL) {
  # Determine mode from environment
  app_mode <- Sys.getenv("APP_MODE", "development")
  
  # Override from config if provided
  if (!is.null(config) && !is.null(config$mode)) {
    app_mode <- config$mode
  }
  
  # Create connection factory configuration
  factory_config <- list()
  
  # Check for mock data path
  mock_path <- Sys.getenv("MOCK_DATA_PATH", NULL)
  mock_type <- Sys.getenv("MOCK_DATA_TYPE", NULL)
  
  if (!is.null(config) && !is.null(config$mock_data_path)) {
    mock_path <- config$mock_data_path
  }
  
  if (!is.null(config) && !is.null(config$mock_data_type)) {
    mock_type <- config$mock_data_type
  }
  
  # Check for database config
  if (!is.null(config) && !is.null(config$database)) {
    factory_config <- config$database
  }
  
  # Create connection
  conn <- db_connection_factory(
    mode = app_mode,
    config = factory_config,
    mock_source = mock_path,
    mock_source_type = mock_type
  )
  
  # Register in global environment (for app-wide access)
  app_db_connection <<- conn
  
  # Log connection info
  conn_info <- get_connection_info(conn)
  message("Initialized ", conn_info$status, " database connection with ", 
          length(conn_info$tables), " tables")
  
  return(conn)
}