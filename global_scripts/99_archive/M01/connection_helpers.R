# connection_helpers.R
# Helper functions for the M01 (External Raw Data Connection) module
#
# This file contains common utility functions that can be used across
# different platform implementations of the M01 module.

#' Load connection configuration from file
#'
#' @param config_path Path to configuration file (YAML format)
#' @param verbose Print detailed information
#'
#' @return Named list with connection parameters
#'
load_connection_config <- function(config_path, verbose = FALSE) {
  if(verbose) message("Loading connection configuration from: ", config_path)
  
  if(!file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }
  
  # Check for yaml package
  if(!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to load configuration file")
  }
  
  # Load and parse YAML config
  tryCatch({
    config <- yaml::read_yaml(config_path)
    
    if(verbose) {
      message("Configuration loaded successfully")
      message("Parameters found: ", paste(names(config), collapse = ", "))
    }
    
    return(config)
  }, error = function(e) {
    stop("Error parsing configuration file: ", e$message)
  })
}

#' Securely mask credentials for display
#'
#' @param credentials Named list with credential parameters
#' @param mask_char Character to use for masking (default: "*")
#' @param show_chars Number of characters to show at the beginning (default: 0)
#'
#' @return Named list with masked credential values
#'
mask_credentials <- function(credentials, mask_char = "*", show_chars = 0) {
  if(!is.list(credentials)) {
    stop("Credentials must be provided as a named list")
  }
  
  # Define sensitive parameter names (case-insensitive)
  sensitive_params <- c(
    "password", "pwd", "secret", "key", "token", "apikey", "api_key",
    "access_key", "secret_key", "ssh_password", "sql_password"
  )
  
  masked_creds <- credentials
  
  # Mask sensitive parameters
  for(param in names(credentials)) {
    # Check if this is a sensitive parameter
    is_sensitive <- any(sapply(sensitive_params, function(s) {
      grepl(s, param, ignore.case = TRUE)
    }))
    
    if(is_sensitive && is.character(credentials[[param]])) {
      val <- credentials[[param]]
      if(nchar(val) > 0) {
        # Show first few characters if requested
        if(show_chars > 0 && nchar(val) > show_chars) {
          prefix <- substr(val, 1, show_chars)
          masked_creds[[param]] <- paste0(prefix, strrep(mask_char, nchar(val) - show_chars))
        } else {
          # Mask entire value
          masked_creds[[param]] <- strrep(mask_char, nchar(val))
        }
      }
    }
  }
  
  return(masked_creds)
}

#' Format connection parameters for logging
#'
#' @param conn_params Named list with connection parameters
#' @param mask_sensitive Mask sensitive information like passwords
#' @param include_prefix Include prefix in parameter names
#' @param prefix Prefix to add to parameter names
#'
#' @return Character string with formatted connection parameters
#'
format_connection_params <- function(conn_params, 
                                    mask_sensitive = TRUE, 
                                    include_prefix = FALSE,
                                    prefix = "    ") {
  if(!is.list(conn_params)) {
    return("No connection parameters available")
  }
  
  # Mask sensitive information if requested
  if(mask_sensitive) {
    conn_params <- mask_credentials(conn_params)
  }
  
  # Format each parameter
  param_strings <- sapply(names(conn_params), function(param) {
    val <- conn_params[[param]]
    
    # Format value based on type
    if(is.null(val)) {
      val_str <- "NULL"
    } else if(is.character(val)) {
      val_str <- paste0('"', val, '"')
    } else if(is.logical(val)) {
      val_str <- ifelse(val, "TRUE", "FALSE")
    } else {
      val_str <- as.character(val)
    }
    
    # Construct parameter string
    if(include_prefix) {
      return(paste0(prefix, param, " = ", val_str))
    } else {
      return(paste0(param, " = ", val_str))
    }
  })
  
  # Join parameter strings
  return(paste(param_strings, collapse = "\n"))
}

#' Log connection details to a file
#'
#' @param conn Database connection object
#' @param log_path Path to log file
#' @param append Append to existing log file
#' @param include_connection_time Include connection timestamp
#' @param mask_sensitive Mask sensitive information
#'
#' @return TRUE if successful, FALSE otherwise
#'
log_connection_details <- function(conn, 
                                  log_path = "connection_log.txt", 
                                  append = TRUE,
                                  include_connection_time = TRUE,
                                  mask_sensitive = TRUE) {
  # Get connection parameters
  conn_params <- attr(conn, "conn_params")
  conn_time <- attr(conn, "connection_time")
  
  # Build log message
  log_parts <- c()
  
  # Add timestamp
  log_parts <- c(log_parts, paste0("CONNECTION LOG [", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "]"))
  log_parts <- c(log_parts, paste0("Connection type: ", class(conn)[1]))
  
  # Add connection time if available and requested
  if(include_connection_time && !is.null(conn_time)) {
    log_parts <- c(log_parts, paste0("Connected at: ", format(conn_time, "%Y-%m-%d %H:%M:%S")))
  }
  
  # Add connection parameters if available
  if(!is.null(conn_params)) {
    log_parts <- c(log_parts, "Connection parameters:")
    log_parts <- c(log_parts, format_connection_params(conn_params, 
                                                     mask_sensitive = mask_sensitive,
                                                     include_prefix = TRUE))
  } else {
    log_parts <- c(log_parts, "No connection parameters available")
  }
  
  # Add validation status
  if(!is.null(conn)) {
    valid <- tryCatch({
      DBI::dbIsValid(conn)
    }, error = function(e) {
      FALSE
    })
    log_parts <- c(log_parts, paste0("Connection valid: ", valid))
  }
  
  # Add separator
  log_parts <- c(log_parts, paste0(rep("-", 80), collapse = ""))
  
  # Join log parts
  log_message <- paste(log_parts, collapse = "\n")
  
  # Write to log file
  tryCatch({
    write(log_message, file = log_path, append = append)
    return(TRUE)
  }, error = function(e) {
    warning("Failed to write to log file: ", e$message)
    return(FALSE)
  })
}

#' Create a default configuration file template
#'
#' @param output_path Path to write the configuration file
#' @param platform Platform identifier (e.g., "01" for Amazon)
#' @param overwrite Overwrite existing file
#'
#' @return TRUE if successful, FALSE otherwise
#'
create_config_template <- function(output_path, platform, overwrite = FALSE) {
  if(file.exists(output_path) && !overwrite) {
    warning("Configuration file already exists. Use overwrite = TRUE to replace it.")
    return(FALSE)
  }
  
  # Check for yaml package
  if(!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required to create configuration file")
  }
  
  # Create platform-specific template
  if(platform == "01") {
    # Amazon (01/AMZ)
    template <- list(
      platform = "01",
      platform_name = "Amazon",
      connection_type = "aws_api",
      region = "us-east-1",
      aws_access_key_id = "YOUR_ACCESS_KEY",
      aws_secret_access_key = "YOUR_SECRET_KEY",
      marketplace_id = "MARKETPLACE_ID",
      refresh_token = "REFRESH_TOKEN",
      client_id = "CLIENT_ID",
      client_secret = "CLIENT_SECRET",
      use_iam_role = FALSE,
      timeout = 30,
      max_retries = 3
    )
  } else if(platform == "06") {
    # eBay (06/EBY)
    template <- list(
      platform = "06",
      platform_name = "eBay",
      connection_type = "sql_server",
      use_tunnel = TRUE,
      sql_host = "localhost",
      sql_port = 1433,
      sql_user = "username",
      sql_password = "password",
      sql_database = "eBay_Sales",
      remote_host = "remote.database.server",
      remote_port = 1433,
      ssh_host = "ssh.tunnel.server",
      ssh_user = "ssh_username",
      ssh_password = "ssh_password",
      timeout = 30
    )
  } else if(platform == "07") {
    # Cyberbiz (07/CBZ)
    template <- list(
      platform = "07",
      platform_name = "Cyberbiz",
      connection_type = "rest_api",
      api_base_url = "https://api.cyberbiz.com",
      api_key = "YOUR_API_KEY",
      api_secret = "YOUR_API_SECRET",
      store_id = "YOUR_STORE_ID",
      timeout = 30,
      max_retries = 3
    )
  } else {
    # Generic template
    template <- list(
      platform = platform,
      platform_name = "Unknown",
      connection_type = "generic",
      host = "connection.host",
      port = 1234,
      username = "username",
      password = "password",
      database = "database_name",
      timeout = 30
    )
  }
  
  # Add documentation
  template$`_documentation` <- paste(
    "This is a configuration file for the M01 External Raw Data Connection module.",
    "Replace placeholder values with actual connection parameters.",
    "For security, it is recommended to use environment variables for sensitive information.",
    paste0("Platform: ", template$platform_name, " (", template$platform, ")"),
    sep = "\n"
  )
  
  # Write to file
  tryCatch({
    yaml::write_yaml(template, output_path)
    message("Configuration template created at: ", output_path)
    return(TRUE)
  }, error = function(e) {
    warning("Failed to write configuration template: ", e$message)
    return(FALSE)
  })
}