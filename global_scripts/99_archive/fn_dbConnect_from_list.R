#' DuckDB Database Connection Manager
#' 
#' This file provides a centralized way to manage DuckDB database connections
#' across the project. It defines standard database paths and a function to
#' establish connections while handling errors and global variable assignment.
#'
#' @author Precision Marketing Team
#' @date 2024-03-26
#' @updated 2025-03-26
#'

#' Predefined Database Paths
#' 
#' A list containing paths to all databases used in the project.
#' Each database serves a specific purpose:
#' - raw_data: Original unprocessed data
#' - cleansed_data: Data after basic cleaning (deduplication, type conversion, missing values)
#' - processed_data: Fully transformed data ready for analysis
#' - sales_by_customer_date_data: Sales data aggregated by customer and date
#' - app_data: Data used by the Shiny application
#' - slowly_changing_data: Data that changes slowly over time (dimensions)
#' - comment_property_rating: Product ratings and comments
#' - global_scd_type1: Global slowly changing dimensions (type 1)
#'
get_default_db_paths <- function(base_dir = NULL) {
  # If no base directory is provided, try to detect it
  if (is.null(base_dir)) {
    # Try to use the APP_DIR if available (from two-tier structure)
    if (exists("APP_DIR")) {
      working_directory_dir <- APP_DIR
      message("Using APP_DIR for database paths")
    } else if (exists("ROOT_PATH")) {
      # Fall back to ROOT_PATH for backward compatibility
      working_directory_dir <- ROOT_PATH
      message("Using ROOT_PATH for database paths")
    } else {
      # Default to current directory
      working_directory_dir <- getwd()
      message("Using current directory for database paths")
    }
  } else {
    working_directory_dir <- base_dir
    message("Using specified base directory for database paths: ", base_dir)
  }
  
  # Always create app_data directory if it doesn't exist
  app_data_dir <- file.path(working_directory_dir, "app_data")
  if (!dir.exists(app_data_dir)) {
    dir.create(app_data_dir, recursive = TRUE, showWarnings = FALSE)
    message("Created app_data directory: ", app_data_dir)
  }
  
  # Create a list of default database paths
  # !!!AI connot change the following list but can only add ones (see it as SCD type2)
  global_scripts_path <- if (exists("APP_DIR")) {
    file.path(APP_DIR, "update_scripts", "global_scripts")
  } else {
    file.path(working_directory_dir, "update_scripts", "global_scripts")
  }
  
  return(list(
    # Application data databases in app_data directory
    raw_data = file.path(working_directory_dir, "raw_data.duckdb"),
    cleansed_data = file.path(working_directory_dir, "cleansed_data.duckdb"),
    processed_data = file.path(working_directory_dir, "processed_data.duckdb"),
    sales_by_customer_date_data = file.path(working_directory_dir, "sales_by_customer_date_data.duckdb"),
    app_data = file.path(working_directory_dir, "app_data.duckdb"),
    slowly_changing_data = file.path(working_directory_dir, "slowly_changing_data.duckdb"),
    comment_property_rating = file.path(app_data_dir, "scd_type2", "comment_property_rating.duckdb"),
    
    # Global data in the global_scripts directory
    global_scd_type1 = file.path(global_scripts_path, "30_global_data", "global_scd_type1.duckdb")
  ))
}

# Initialize the default database paths
db_path_list <- get_default_db_paths()

#' Set Custom Database Paths
#'
#' Updates the global database path list with custom paths.
#'
#' @param custom_paths List. A list of database paths to override defaults
#' @param base_dir Character. Optional base directory for relative paths (defaults to current directory)
#' @param reset Logical. Whether to reset to default paths first (defaults to FALSE)
#'
#' @return The updated database path list
#'
#' @details
#' This function allows you to customize database paths while keeping the
#' structure defined in the default path list. You can update specific paths
#' or provide a completely new set of paths.
#'
#' @examples
#' # Update specific database paths
#' set_db_paths(list(
#'   raw_data = "path/to/custom/raw_data.duckdb",
#'   processed_data = "path/to/custom/processed_data.duckdb"
#' ))
#'
#' # Reset to defaults then set custom paths
#' set_db_paths(list(
#'   raw_data = "path/to/custom/raw_data.duckdb"
#' ), reset = TRUE)
#'
#' @export
set_db_paths <- function(custom_paths, base_dir = NULL, reset = FALSE) {
  # Get reference to the global path list
  db_path_list_global <- db_path_list
  
  # Reset to defaults if requested
  if (reset) {
    db_path_list_global <- get_default_db_paths(base_dir)
  }
  
  # Update with custom paths
  for (name in names(custom_paths)) {
    db_path_list_global[[name]] <- custom_paths[[name]]
  }
  
  # Update the global path list
  assign("db_path_list", db_path_list_global, envir = .GlobalEnv)
  
  # Print information about the updated paths
  message("Database paths updated:")
  for (name in names(db_path_list_global)) {
    message("  - ", name, ": ", db_path_list_global[[name]])
  }
  
  return(invisible(db_path_list_global))
}

#' Database Connection Function with Permission Checking
#'
#' Establishes a connection to a specified DuckDB database from the predefined list
#' and stores the connection in the global environment. This function enforces
#' the Data Source Hierarchy Principle by checking permissions based on current
#' operating mode.
#'
#' @param dataset Character. The name of the database to connect to (must exist in path_list)
#' @param path_list List. The list of database paths (defaults to db_path_list)
#' @param read_only Logical. Whether to open the database in read-only mode. This can be overridden
#'        based on operating mode access permissions.
#' @param create_dir Logical. Whether to create parent directories if they don't exist (defaults to TRUE)
#' @param verbose Logical. Whether to display information about the connection (defaults to TRUE)
#' @param force_mode_check Logical. Whether to force permission checking even for custom paths (defaults to TRUE)
#'
#' @return Connection object. The established database connection
#'
#' @details
#' The function performs the following steps:
#' 1. Validates that the requested dataset exists in the path list
#' 2. Gets the database path from the list
#' 3. Determines data layer and checks permission based on operating mode
#' 4. Creates parent directories if needed and requested (if permissions allow)
#' 5. Establishes a connection to the DuckDB database with appropriate read/write permissions
#' 6. Displays all tables in the connected database if verbose is TRUE
#' 7. Assigns the connection to a global variable with the same name as the dataset
#' 8. Returns the connection object for chaining
#'
#' @note
#' - The connection is stored in the global environment with the same name as the dataset
#' - This allows other functions to access the connection without explicitly passing it
#' - Connections should be closed with dbDisconnect() when no longer needed
#' - For multiple connections, use dbDisconnect_all() to close all at once
#' - Permission checks enforce Data Source Hierarchy Principle by controlling read/write access
#'
#' @examples
#' # Connect to raw_data database - permission checks will enforce appropriate mode
#' raw_data <- dbConnect_from_list("raw_data")
#'
#' # Connect to app_data database - in APP_MODE this will enforce read_only=TRUE
#' app_data <- dbConnect_from_list("app_data", read_only = FALSE)
#'
#' # Connect with a custom path list
#' custom_paths <- list(my_db = "path/to/custom.duckdb")
#' my_db <- dbConnect_from_list("my_db", path_list = custom_paths)
#'
#' @export
dbConnect_from_list <- function(dataset, path_list = db_path_list, read_only = FALSE, 
                               create_dir = TRUE, verbose = TRUE, force_mode_check = TRUE) {
  # 檢查指定的 dataset 是否存在於 path_list 中
  if (!dataset %in% names(path_list)) {
    stop("指定的 dataset '", dataset, "' 不在清單中。請確認清單中的名稱：", paste(names(path_list), collapse = ", "))
  }
  
  # 取得指定 dataset 的資料庫路徑
  db_path <- path_list[[dataset]]
  
  # 確定資料存取層級（data layer）並檢查存取權限
  # 檢查是否已載入存取權限檢查功能 
  # 注意：如果在 APP_MODE 下，check_data_access 可能尚未載入（因為它在 11_rshinyapp_utils 中）
  has_permission_check <- exists("check_data_access", mode = "function") && 
                          exists("get_data_layer", mode = "function")
                          
  # 如果函數不存在但目前在 APP_MODE，實作簡化版的權限檢查
  if (!has_permission_check && exists("OPERATION_MODE") && OPERATION_MODE == "APP_MODE") {
    # APP_MODE 下的簡化存取規則：強制資料庫為唯讀模式
    if (!read_only) {
      if (verbose) {
        message("注意：在 APP_MODE 中，資料庫連線被強制設為唯讀模式。")
      }
      read_only <- TRUE
    }
  } else if (dataset == "cleanse_data") {
    # Handle legacy cleanse_data name
    warning("'cleanse_data' is deprecated, use 'cleansed_data' instead. Redirecting connection.")
    dataset <- "cleansed_data"
    # Update the global environment to maintain backward compatibility
    if (verbose) message("Redirecting cleanse_data to cleansed_data for compatibility")
  }
  
  # 根據資料庫名稱判斷資料層級
  data_layer <- NULL
  if (has_permission_check) {
    # 通用對應規則
    layer_mapping <- list(
      "app" = c("app_data"),
      "processing" = c("raw_data", "cleansed_data", "cleanse_data", "processed_data", "sales_by_customer_date_data", 
                      "slowly_changing_data", "comment_property_rating"),
      "global" = c("global_scd_type1")
    )
    
    # 嘗試從資料庫名稱判斷層級
    for (layer in names(layer_mapping)) {
      if (dataset %in% layer_mapping[[layer]]) {
        data_layer <- layer
        break
      }
    }
    
    # 若無法從名稱判斷，則嘗試從路徑判斷
    if (is.null(data_layer) && force_mode_check) {
      data_layer <- get_data_layer(db_path)
    }
    
    # 根據存取類型（讀/寫）檢查權限
    access_type <- if (read_only) "read" else "write"
    
    # 檢查權限
    if (!is.null(data_layer)) {
      has_permission <- check_data_access(data_layer, access_type, db_path)
      
      # 如果無寫入權限但請求寫入，則強制唯讀模式
      if (!has_permission && access_type == "write") {
        if (verbose) {
          message("注意：根據目前操作模式的存取權限，資料庫 '", dataset, "' (",
                 data_layer, " 層) 被強制設為唯讀模式。")
        }
        read_only <- TRUE
      }
      
      # 如果連讀取權限都沒有，則中止操作
      if (!has_permission && access_type == "read") {
        stop("存取被拒絕：目前操作模式下無法存取資料庫 '", dataset, "' (",
             data_layer, " 層)。")
      }
    }
  }
  
  # 檢查資料庫目錄是否存在
  db_dir <- dirname(db_path)
  if (!dir.exists(db_dir) && db_dir != ".") {
    # 創建目錄需要寫入權限，檢查是否有權限
    if (has_permission_check && !is.null(data_layer) && 
        !check_data_access(data_layer, "write", db_dir) && force_mode_check) {
      stop("無法創建資料庫目錄 '", db_dir, "' - 目前操作模式無寫入權限")
    }
    
    if (create_dir) {
      if (verbose) message("資料庫目錄 '", db_dir, "' 不存在。正在創建...")
      dir.create(db_dir, recursive = TRUE, showWarnings = FALSE)
      if (!dir.exists(db_dir)) {
        stop("無法創建資料庫目錄 '", db_dir, "'")
      } else if (verbose) {
        message("成功創建資料庫目錄 '", db_dir, "'")
      }
    } else {
      stop("資料庫目錄 '", db_dir, "' 不存在，且 create_dir=FALSE")
    }
  }
  
  # 連線到 DuckDB
  tryCatch({
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = read_only)
  }, error = function(e) {
    stop("連接到資料庫 '", dataset, "' 時發生錯誤: ", e$message, 
         "\n路徑: ", db_path, 
         "\n讀取模式: ", ifelse(read_only, "唯讀", "可寫入"))
  })
  
  if (verbose) {
    # 列印目前連線到的資料庫中的所有資料表
    table_count <- length(DBI::dbListTables(con))
    access_mode_suffix <- ""
    if (has_permission_check && !is.null(data_layer)) {
      access_mode_suffix <- paste0("（", 
                                 if (exists("OPERATION_MODE")) OPERATION_MODE else "未知模式", 
                                 "，", data_layer, " 層）")
    }
    
    message("目前連線到 '", dataset, "' 資料庫，",
            ifelse(read_only, "唯讀模式", "寫入模式"), "，",
            "包含 ", table_count, " 個資料表. ", access_mode_suffix)
    
    if (table_count > 0) {
      print(DBI::dbListTables(con))
    } else {
      message("（資料庫中沒有任何資料表）")
    }
  }
  
  # 將連線物件存入全域變數，變數名稱與 dataset 相同
  assign(dataset, con, envir = .GlobalEnv)
  
  # 回傳連線物件
  return(con)
}