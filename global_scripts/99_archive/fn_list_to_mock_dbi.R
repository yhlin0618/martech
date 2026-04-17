#' Convert a List of Data Frames to a Mock DBI Connection
#' 
#' @description
#' Converts a list of data frames into a mock DBI connection that can be used
#' for testing and development. The resulting connection object can be used
#' with standard DBI functions like dbGetQuery, making it easy to simulate
#' database interactions without an actual database.
#'
#' @param data_list A list of data frames, where names are used as table names
#' @param table_prefix Prefix to add to tables (e.g., "df_" for "df_customer_profile")
#' @param mapping Optional named list to map data frame names to database table names
#' @param include_metadata Whether to include metadata in the mock connection
#'
#' @return A mock DBI connection object with table query capabilities
#'
#' @examples
#' # Create data frames
#' customer_data <- data.frame(id = 1:3, name = c("A", "B", "C"))
#' order_data <- data.frame(order_id = 101:103, customer_id = c(1, 2, 1))
#'
#' # Create a list of data frames
#' data_list <- list(
#'   customers = customer_data,
#'   orders = order_data
#' )
#'
#' # Convert to mock DBI connection
#' mock_conn <- list_to_mock_dbi(data_list)
#'
#' # Use with DBI-style queries
#' result <- DBI::dbGetQuery(mock_conn, "SELECT * FROM customers")
#'
#' @export
#' @implements R91 Universal Data Access Pattern
list_to_mock_dbi <- function(data_list, 
                           table_prefix = "",
                           mapping = NULL,
                           include_metadata = TRUE) {
  # Validate input
  if (!is.list(data_list)) {
    stop("data_list must be a list")
  }
  
  # Apply table prefix if specified
  if (nchar(table_prefix) > 0) {
    names(data_list) <- paste0(table_prefix, names(data_list))
  }
  
  # Apply custom mapping if provided
  if (!is.null(mapping) && is.list(mapping)) {
    for (orig_name in names(mapping)) {
      if (orig_name %in% names(data_list)) {
        new_name <- mapping[[orig_name]]
        data_list[[new_name]] <- data_list[[orig_name]]
        data_list[[orig_name]] <- NULL
      }
    }
  }
  
  # Ensure all elements are data frames
  for (name in names(data_list)) {
    if (!is.data.frame(data_list[[name]])) {
      warning("Converting non-data.frame '", name, "' to data.frame")
      data_list[[name]] <- as.data.frame(data_list[[name]])
    }
  }
  
  # Create the mock DBI connection
  conn <- list(
    # Tables storage
    tables = data_list,
    
    # Method to get available tables
    dbListTables = function() {
      return(names(data_list))
    },
    
    # Method to get table fields
    dbListFields = function(table_name) {
      if (table_name %in% names(data_list)) {
        return(names(data_list[[table_name]]))
      } else {
        stop("Table not found: ", table_name)
      }
    },
    
    # Main query method - Basic SQL parser for simple queries
    query = function(sql) {
      # Extract table name from basic SELECT query
      select_pattern <- "SELECT\\s+\\*\\s+FROM\\s+([\\w_]+)"
      select_match <- regexec(select_pattern, sql, ignore.case = TRUE)
      
      if (select_match[[1]][1] > 0) {
        # Handle SELECT * FROM table
        table_name <- regmatches(sql, select_match)[[1]][2]
        
        if (table_name %in% names(data_list)) {
          return(data_list[[table_name]])
        } else {
          stop("Table not found: ", table_name)
        }
      }
      
      # Extract table name and WHERE condition
      where_pattern <- "SELECT\\s+\\*\\s+FROM\\s+([\\w_]+)\\s+WHERE\\s+(.+)"
      where_match <- regexec(where_pattern, sql, ignore.case = TRUE)
      
      if (where_match[[1]][1] > 0) {
        # Handle SELECT * FROM table WHERE condition
        matches <- regmatches(sql, where_match)[[1]]
        table_name <- matches[2]
        condition <- matches[3]
        
        if (table_name %in% names(data_list)) {
          # Very basic condition parser for simple equality
          # e.g., "customer_id = 1"
          equal_pattern <- "([\\w_]+)\\s*=\\s*([\\w'\"]+)"
          equal_match <- regexec(equal_pattern, condition, ignore.case = TRUE)
          
          if (equal_match[[1]][1] > 0) {
            eq_matches <- regmatches(condition, equal_match)[[1]]
            field_name <- eq_matches[2]
            field_value <- eq_matches[3]
            
            # Remove quotes if present
            field_value <- gsub("^['\"]|['\"]$", "", field_value)
            
            # Try to convert to numeric if it looks like a number
            if (grepl("^[0-9]+$", field_value)) {
              field_value <- as.numeric(field_value)
            }
            
            # Filter the data
            if (field_name %in% names(data_list[[table_name]])) {
              filtered <- data_list[[table_name]][data_list[[table_name]][[field_name]] == field_value, ]
              return(filtered)
            } else {
              stop("Field not found: ", field_name)
            }
          }
        } else {
          stop("Table not found: ", table_name)
        }
      }
      
      # Handle JOIN queries (very basic implementation)
      join_pattern <- "SELECT\\s+\\*\\s+FROM\\s+([\\w_]+)\\s+JOIN\\s+([\\w_]+)\\s+ON\\s+([\\w_]+)\\.([\\w_]+)\\s*=\\s*([\\w_]+)\\.([\\w_]+)"
      join_match <- regexec(join_pattern, sql, ignore.case = TRUE)
      
      if (join_match[[1]][1] > 0) {
        matches <- regmatches(sql, join_match)[[1]]
        table1 <- matches[2]
        table2 <- matches[3]
        table1_alias <- matches[4]
        field1 <- matches[5]
        table2_alias <- matches[6]
        field2 <- matches[7]
        
        if (table1 %in% names(data_list) && table2 %in% names(data_list)) {
          # Simple implementation - assuming table aliases match table names
          df1 <- data_list[[table1]]
          df2 <- data_list[[table2]]
          
          # Basic join
          result <- merge(df1, df2, by.x = field1, by.y = field2)
          return(result)
        } else {
          missing_tables <- c()
          if (!(table1 %in% names(data_list))) missing_tables <- c(missing_tables, table1)
          if (!(table2 %in% names(data_list))) missing_tables <- c(missing_tables, table2)
          stop("Tables not found: ", paste(missing_tables, collapse = ", "))
        }
      }
      
      # If no patterns matched, return error
      stop("Unsupported SQL query format: ", sql)
    },
    
    # DBI style interface
    dbGetQuery = function(statement) {
      return(conn$query(statement))
    },
    
    # No-op disconnect method
    dbDisconnect = function() {
      invisible(NULL)
    },
    
    # Check connection is valid - always returns TRUE for mock
    dbIsValid = function() {
      return(TRUE)
    }
  )
  
  # Add metadata if requested
  if (include_metadata) {
    conn$connection_type <- "mock_dbi_connection"
    conn$is_mock_connection <- TRUE
    conn$created_at <- Sys.time()
    conn$available_tables <- names(data_list)
    conn$table_summary <- lapply(data_list, function(df) {
      list(rows = nrow(df), columns = ncol(df), column_names = names(df))
    })
  }
  
  # Set class for S3 method dispatch
  class(conn) <- c("mock_dbi_connection", "DBIConnection", "list")
  
  return(conn)
}

#' Extend a Mock DBI Connection with Additional Data
#'
#' @description
#' Adds new data frames to an existing mock DBI connection or 
#' updates existing tables with new data.
#'
#' @param conn The mock DBI connection to extend
#' @param additional_data A list of additional data frames to add or update
#' @param overwrite Whether to overwrite existing tables (TRUE) or merge them (FALSE)
#'
#' @return The updated mock DBI connection
#'
#' @examples
#' # Create initial mock connection
#' mock_conn <- list_to_mock_dbi(list(customers = data.frame(id = 1:3)))
#'
#' # Add new data
#' mock_conn <- extend_mock_dbi(mock_conn, 
#'                             list(orders = data.frame(id = 101:103)))
#'
#' @export
#' @implements R91 Universal Data Access Pattern
extend_mock_dbi <- function(conn, additional_data, overwrite = TRUE) {
  # Validate input
  if (!inherits(conn, "mock_dbi_connection")) {
    stop("conn must be a mock_dbi_connection")
  }
  
  if (!is.list(additional_data)) {
    stop("additional_data must be a list")
  }
  
  # Ensure all elements are data frames
  for (name in names(additional_data)) {
    if (!is.data.frame(additional_data[[name]])) {
      warning("Converting non-data.frame '", name, "' to data.frame")
      additional_data[[name]] <- as.data.frame(additional_data[[name]])
    }
  }
  
  # Add or update tables
  for (name in names(additional_data)) {
    if (name %in% names(conn$tables) && !overwrite) {
      # Merge with existing table if not overwriting
      existing_cols <- names(conn$tables[[name]])
      new_cols <- names(additional_data[[name]])
      
      # Find common columns for merge
      common_cols <- intersect(existing_cols, new_cols)
      
      if (length(common_cols) > 0) {
        # Use first column as key if no obvious key exists
        key_col <- common_cols[1]
        
        # Attempt to find ID column for better merging
        id_candidates <- c("id", paste0(sub("s$", "", name), "_id"), "key")
        for (candidate in id_candidates) {
          if (candidate %in% common_cols) {
            key_col <- candidate
            break
          }
        }
        
        # Merge data
        conn$tables[[name]] <- merge(
          conn$tables[[name]], 
          additional_data[[name]], 
          by = key_col, 
          all = TRUE
        )
      } else {
        # No common columns, so just append
        conn$tables[[name]] <- rbind(
          conn$tables[[name]],
          additional_data[[name]]
        )
      }
    } else {
      # Add as new table or replace existing
      conn$tables[[name]] <- additional_data[[name]]
    }
  }
  
  # Update metadata if it exists
  if (!is.null(conn$available_tables)) {
    conn$available_tables <- names(conn$tables)
  }
  
  if (!is.null(conn$table_summary)) {
    conn$table_summary <- lapply(conn$tables, function(df) {
      list(rows = nrow(df), columns = ncol(df), column_names = names(df))
    })
  }
  
  return(conn)
}

#' Query a Mock DBI Connection
#'
#' @description
#' A convenience wrapper for executing queries against a mock DBI connection.
#' This provides a more familiar interface for working with mock connections.
#'
#' @param conn The mock DBI connection
#' @param sql The SQL query to execute
#'
#' @return The query result as a data frame
#'
#' @examples
#' # Create mock connection
#' mock_conn <- list_to_mock_dbi(list(
#'   customers = data.frame(id = 1:3, name = c("A", "B", "C"))
#' ))
#'
#' # Execute query
#' query_mock_dbi(mock_conn, "SELECT * FROM customers")
#'
#' @export
#' @implements R91 Universal Data Access Pattern
query_mock_dbi <- function(conn, sql) {
  if (!inherits(conn, "mock_dbi_connection")) {
    stop("conn must be a mock_dbi_connection")
  }
  
  tryCatch({
    return(conn$dbGetQuery(sql))
  }, error = function(e) {
    message("Query error: ", e$message)
    message("Available tables: ", paste(conn$dbListTables(), collapse = ", "))
    return(NULL)
  })
}

#' Check if an Object is a Mock DBI Connection
#'
#' @description
#' Tests whether an object is a mock DBI connection created by list_to_mock_dbi.
#'
#' @param x The object to test
#'
#' @return TRUE if the object is a mock DBI connection, FALSE otherwise
#'
#' @examples
#' # Create mock connection
#' mock_conn <- list_to_mock_dbi(list(customers = data.frame(id = 1:3)))
#'
#' # Test if it's a mock connection
#' is_mock_dbi(mock_conn)  # Returns TRUE
#'
#' @export
#' @implements R91 Universal Data Access Pattern
is_mock_dbi <- function(x) {
  inherits(x, "mock_dbi_connection")
}

#' Create a Dynamic Mock DBI Connection from Various Sources
#'
#' @description
#' Creates a dynamic mock DBI connection that can be populated from various sources.
#' This is useful for testing with real-world data sources while still using a mock connection.
#'
#' @param ... Named data frames or lists of data frames to include in the connection
#' @param source_type Optional source type to load additional data:
#'  - "csv_dir": loads CSVs from a directory
#'  - "rds_dir": loads RDS files from a directory
#'  - "excel": loads sheets from an Excel file
#' @param source_path Path to the source for additional data loading
#' @param mapping Optional table name mapping
#'
#' @return A mock DBI connection object
#'
#' @examples
#' # Create from inline data frames
#' conn <- create_dynamic_mock_dbi(
#'   customers = data.frame(id = 1:3, name = c("A", "B", "C")),
#'   orders = data.frame(id = 101:103, customer_id = c(1, 2, 1))
#' )
#'
#' # Create from CSV directory
#' # conn <- create_dynamic_mock_dbi(source_type = "csv_dir", source_path = "data/csv/")
#'
#' @export
#' @implements R91 Universal Data Access Pattern
create_dynamic_mock_dbi <- function(..., source_type = NULL, source_path = NULL, mapping = NULL) {
  # Collect data frames from ... arguments
  data_list <- list(...)
  
  # If no data frames provided, initialize with empty list
  if (length(data_list) == 0) {
    data_list <- list()
  }
  
  # Load data from external source if specified
  if (!is.null(source_type) && !is.null(source_path)) {
    if (source_type == "csv_dir") {
      # Load all CSV files from directory
      if (dir.exists(source_path)) {
        csv_files <- list.files(source_path, pattern = "\\.csv$", full.names = TRUE)
        for (file in csv_files) {
          table_name <- tools::file_path_sans_ext(basename(file))
          data_list[[table_name]] <- read.csv(file, stringsAsFactors = FALSE)
        }
      } else {
        warning("Directory not found: ", source_path)
      }
    } else if (source_type == "rds_dir") {
      # Load all RDS files from directory
      if (dir.exists(source_path)) {
        rds_files <- list.files(source_path, pattern = "\\.rds$", full.names = TRUE)
        for (file in rds_files) {
          table_name <- tools::file_path_sans_ext(basename(file))
          data_list[[table_name]] <- readRDS(file)
        }
      } else {
        warning("Directory not found: ", source_path)
      }
    } else if (source_type == "excel") {
      # Load Excel sheets (requires readxl package)
      if (file.exists(source_path)) {
        if (!requireNamespace("readxl", quietly = TRUE)) {
          warning("readxl package is required to load Excel files. Install with install.packages('readxl')")
        } else {
          sheet_names <- readxl::excel_sheets(source_path)
          for (sheet in sheet_names) {
            table_name <- sheet
            data_list[[table_name]] <- readxl::read_excel(source_path, sheet = sheet)
          }
        }
      } else {
        warning("Excel file not found: ", source_path)
      }
    } else {
      warning("Unknown source_type: ", source_type)
    }
  }
  
  # Create the mock DBI connection
  conn <- list_to_mock_dbi(data_list, mapping = mapping)
  
  # Add source information to metadata
  if (!is.null(source_type) && !is.null(source_path)) {
    conn$source_type <- source_type
    conn$source_path <- source_path
  }
  
  return(conn)
}