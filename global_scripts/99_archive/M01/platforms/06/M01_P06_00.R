# M01_P06_00.R
# Implementation of M01 (External Raw Data Connection) for eBay platform (06/EBY)
#
# ⚠️ SECURITY WARNING: This archived file contains hardcoded passwords
# This is a historical archive and should NOT be used in production
# For current secure implementations, see scripts/global_scripts/02_db_utils/
#
# This script implements the platform-specific version of the M01 module
# as defined in M01/M01.md.
#
# Platform: eBay (06/EBY) per R38 Platform Numbering Convention
# Company: MAMBA

#' Create an SSH tunnel for SQL Server connection
#'
#' Creates an SSH tunnel to securely connect to a SQL Server database through
#' an intermediary server when direct connection is not possible
#'
#' @param local_port Local port to forward from
#' @param remote_host Remote SQL Server host IP
#' @param remote_port Remote SQL Server port
#' @param ssh_host SSH intermediary server host IP
#' @param ssh_user SSH username
#' @param ssh_password SSH password (optional, will prompt if NULL)
#' @param background Run SSH in background mode
#' @param verbose Print detailed information
#'
#' @return Process ID of SSH tunnel if background=TRUE, otherwise TRUE for success
#'
create_ssh_tunnel <- function(local_port = 1433, 
                             remote_host = "125.227.84.85", 
                             remote_port = 1433,
                             ssh_host = "163.47.8.236", 
                             ssh_user = "root",
                             ssh_password = NULL,
                             background = TRUE,
                             verbose = TRUE) {
  
  if(verbose) message("Creating SSH tunnel for SQL Server connection...")
  
  # Construct SSH command
  ssh_options <- c()
  
  # Background mode
  if(background) {
    ssh_options <- c(ssh_options, "-f", "-N")
  }
  
  # Port forwarding
  forwarding <- paste0(local_port, ":", remote_host, ":", remote_port)
  ssh_options <- c(ssh_options, "-L", forwarding)
  
  # SSH destination
  ssh_destination <- paste0(ssh_user, "@", ssh_host)
  
  # Full SSH command
  ssh_cmd <- c("ssh", ssh_options, ssh_destination)
  ssh_cmd_display <- paste(ssh_cmd, collapse = " ")
  
  if(verbose) {
    message("SSH tunnel command: ", ssh_cmd_display)
    message("This will forward localhost:", local_port, " → ", ssh_host, 
            " → ", remote_host, ":", remote_port)
  }
  
  tryCatch({
    # Execute SSH command
    if(!is.null(ssh_password)) {
      # Using password (requires sshpass or similar)
      warning("Providing password on command line is not secure. Consider using SSH keys.")
      
      # This is not a secure method and is just for demonstration
      # In production, SSH keys should be used instead
      if(verbose) message("Executing SSH command with password...")
      
      # This is intentionally commented out as we shouldn't use password this way
      # system2("sshpass", c("-p", ssh_password, ssh_cmd))
      
      message("SSH command with password in command line is disabled for security reasons.")
      message("Please use SSH keys or enter password when prompted.")
      
      # Execute without password (will prompt)
      system2("ssh", ssh_options, ssh_destination)
    } else {
      # Execute without password (will prompt or use SSH keys)
      if(verbose) message("Executing SSH command (you may be prompted for password)...")
      system2("ssh", c(ssh_options, ssh_destination))
    }
    
    # Wait a moment for tunnel to establish
    Sys.sleep(1)
    
    if(verbose) message("SSH tunnel created successfully")
    
    # Return process ID if running in background
    if(background) {
      # Get the PID of the SSH process
      pid_cmd <- paste0("pgrep -f 'ssh.*", local_port, ":", remote_host, ":", remote_port, "'")
      pid <- system(pid_cmd, intern = TRUE)
      
      if(length(pid) > 0) {
        if(verbose) message("SSH tunnel running with PID: ", pid[1])
        return(pid[1])
      } else {
        if(verbose) message("SSH tunnel created, but unable to determine PID")
        return(TRUE)
      }
    } else {
      return(TRUE)
    }
  }, error = function(e) {
    message("Error creating SSH tunnel: ", e$message)
    return(FALSE)
  })
}

#' Close an active SSH tunnel
#'
#' @param pid Process ID of SSH tunnel, or NULL to find by port
#' @param local_port Local port to identify tunnel if pid is NULL
#' @param remote_host Remote host to identify tunnel if pid is NULL
#' @param remote_port Remote port to identify tunnel if pid is NULL
#' @param verbose Print detailed information
#'
#' @return TRUE if successful, FALSE otherwise
#'
close_ssh_tunnel <- function(pid = NULL, 
                            local_port = 1433, 
                            remote_host = "125.227.84.85", 
                            remote_port = 1433,
                            verbose = TRUE) {
  
  if(verbose) message("Closing SSH tunnel...")
  
  # If no PID provided, try to find it
  if(is.null(pid)) {
    if(verbose) message("No PID provided, searching for SSH tunnel process...")
    
    # Construct search pattern
    pid_cmd <- paste0("pgrep -f 'ssh.*", local_port, ":", remote_host, ":", remote_port, "'")
    pid <- system(pid_cmd, intern = TRUE)
    
    if(length(pid) == 0) {
      message("No active SSH tunnel found for the specified ports")
      return(FALSE)
    }
  }
  
  tryCatch({
    # Kill the SSH process
    if(verbose) message("Terminating SSH tunnel with PID: ", pid)
    system2("kill", pid)
    
    # Verify process is gone
    Sys.sleep(1)
    process_check <- system(paste0("ps -p ", pid, " > /dev/null 2>&1; echo $?"), intern = TRUE)
    
    if(process_check == "1") {
      if(verbose) message("SSH tunnel closed successfully")
      return(TRUE)
    } else {
      if(verbose) message("Failed to close SSH tunnel, attempting force kill...")
      system2("kill", c("-9", pid))
      return(TRUE)
    }
  }, error = function(e) {
    message("Error closing SSH tunnel: ", e$message)
    return(FALSE)
  })
}

#' Connect to eBay SQL Server database via SSH tunnel
#'
#' @param credentials Named list with sql_user, sql_password
#' @param config_path Path to configuration file (optional)
#' @param use_tunnel Use SSH tunneling for connection
#' @param verbose Print detailed information
#'
#' @return DBI connection object if successful, otherwise NULL
#'
connect_to_external_source <- function(credentials = NULL, 
                                     config_path = NULL,
                                     use_tunnel = TRUE, 
                                     verbose = TRUE) {
  
  if(verbose) message("Connecting to eBay SQL Server database...")
  
  # Default connection parameters
  conn_params <- list(
    sql_host = "localhost",     # When using tunnel
    sql_port = 1433,
    sql_user = "sa",
    sql_password = "u3sql@2007",
    sql_database = "eBay_Sales",
    remote_host = "125.227.84.85",
    remote_port = 1433,
    ssh_host = "163.47.8.236",
    ssh_user = "root",
    ssh_password = "xedsox-hugcy4-Toqnep",
    use_tunnel = use_tunnel
  )
  
  # Load parameters from config file if provided
  if(!is.null(config_path)) {
    if(file.exists(config_path)) {
      if(verbose) message("Loading configuration from file: ", config_path)
      
      # Load YAML config
      if(!requireNamespace("yaml", quietly = TRUE)) {
        stop("Package 'yaml' is required to load configuration file")
      }
      
      config <- yaml::read_yaml(config_path)
      
      # Update connection parameters
      for(param in names(config)) {
        conn_params[[param]] <- config[[param]]
      }
    } else {
      warning("Config file not found: ", config_path)
    }
  }
  
  # Override with provided credentials
  if(!is.null(credentials)) {
    for(param in names(credentials)) {
      conn_params[[param]] <- credentials[[param]]
    }
  }
  
  # Create SSH tunnel if needed
  if(conn_params$use_tunnel) {
    if(verbose) message("Setting up SSH tunnel for database connection...")
    
    tunnel_result <- create_ssh_tunnel(
      local_port = conn_params$sql_port,
      remote_host = conn_params$remote_host,
      remote_port = conn_params$remote_port,
      ssh_host = conn_params$ssh_host,
      ssh_user = conn_params$ssh_user,
      ssh_password = conn_params$ssh_password,
      background = TRUE,
      verbose = verbose
    )
    
    if(!tunnel_result) {
      message("Failed to create SSH tunnel")
      return(NULL)
    }
    
    # Store tunnel PID for later disconnection
    conn_params$tunnel_pid <- if(is.character(tunnel_result)) tunnel_result else NULL
    
    # When using tunnel, connect to localhost
    conn_params$sql_host <- "localhost"
  } else {
    # Direct connection (not using tunnel)
    conn_params$sql_host <- conn_params$remote_host
  }
  
  # Connect to SQL Server
  tryCatch({
    if(verbose) message("Connecting to SQL Server at ", conn_params$sql_host, ":", conn_params$sql_port)
    
    # Check for required packages
    if(!requireNamespace("DBI", quietly = TRUE)) {
      stop("Package 'DBI' is required for database connection")
    }
    
    if(!requireNamespace("odbc", quietly = TRUE)) {
      stop("Package 'odbc' is required for ODBC connection to SQL Server")
    }
    
    # Create connection
    conn <- DBI::dbConnect(
      odbc::odbc(),
      Driver = "SQL Server",
      Server = paste0(conn_params$sql_host, ",", conn_params$sql_port),
      Database = conn_params$sql_database,
      UID = conn_params$sql_user,
      PWD = conn_params$sql_password
    )
    
    # Add connection metadata
    attr(conn, "conn_params") <- conn_params
    attr(conn, "connection_time") <- Sys.time()
    
    if(verbose) message("Successfully connected to eBay SQL Server database")
    
    return(conn)
  }, error = function(e) {
    message("Error connecting to SQL Server: ", e$message)
    
    # Close tunnel if it was created
    if(conn_params$use_tunnel && !is.null(conn_params$tunnel_pid)) {
      close_ssh_tunnel(conn_params$tunnel_pid, verbose = verbose)
    }
    
    return(NULL)
  })
}

#' Disconnect from eBay SQL Server database
#'
#' @param conn DBI connection object
#' @param verbose Print detailed information
#'
#' @return TRUE if successful, FALSE otherwise
#'
disconnect_from_external_source <- function(conn, verbose = TRUE) {
  if(is.null(conn)) {
    warning("Connection is NULL, nothing to disconnect")
    return(FALSE)
  }
  
  if(verbose) message("Disconnecting from eBay SQL Server database...")
  
  # Get connection parameters
  conn_params <- attr(conn, "conn_params")
  tunnel_pid <- if(!is.null(conn_params)) conn_params$tunnel_pid else NULL
  
  tryCatch({
    # Close database connection
    DBI::dbDisconnect(conn)
    
    if(verbose) message("Database connection closed successfully")
    
    # Close SSH tunnel if it exists
    if(!is.null(tunnel_pid)) {
      close_ssh_tunnel(tunnel_pid, verbose = verbose)
    } else if(!is.null(conn_params) && conn_params$use_tunnel) {
      # Try to close based on ports if PID not available
      close_ssh_tunnel(
        local_port = conn_params$sql_port,
        remote_host = conn_params$remote_host,
        remote_port = conn_params$remote_port,
        verbose = verbose
      )
    }
    
    return(TRUE)
  }, error = function(e) {
    message("Error during disconnection: ", e$message)
    return(FALSE)
  })
}

#' Test connection to eBay SQL Server database
#'
#' @param conn Existing connection, or NULL to create new connection
#' @param credentials Named list with connection parameters
#' @param config_path Path to configuration file
#' @param verbose Print detailed information
#'
#' @return TRUE if connection test successful, FALSE otherwise
#'
test_external_connection <- function(conn = NULL, 
                                   credentials = NULL, 
                                   config_path = NULL, 
                                   verbose = TRUE) {
  
  if(verbose) message("Testing connection to eBay SQL Server database...")
  
  # Create connection if not provided
  close_after <- FALSE
  if(is.null(conn)) {
    if(verbose) message("No connection provided, creating new connection...")
    conn <- connect_to_external_source(credentials, config_path, verbose = verbose)
    close_after <- TRUE
    
    if(is.null(conn)) {
      message("Failed to create connection for testing")
      return(FALSE)
    }
  }
  
  # Test connection with a simple query
  tryCatch({
    if(verbose) message("Executing test query...")
    test_result <- DBI::dbGetQuery(conn, "SELECT @@VERSION as version")
    
    if(nrow(test_result) > 0) {
      if(verbose) {
        message("Connection test successful")
        message("SQL Server version: ", test_result$version[1])
      }
      test_status <- TRUE
    } else {
      if(verbose) message("Connection test failed: No version information returned")
      test_status <- FALSE
    }
    
    # Close connection if we created it
    if(close_after) {
      disconnect_from_external_source(conn, verbose = verbose)
    }
    
    return(test_status)
  }, error = function(e) {
    message("Connection test failed: ", e$message)
    
    # Close connection if we created it
    if(close_after) {
      disconnect_from_external_source(conn, verbose = verbose)
    }
    
    return(FALSE)
  })
}

#' Execute a query against the eBay SQL Server database
#'
#' @param query SQL query to execute
#' @param conn Existing connection, or NULL to create new connection
#' @param credentials Named list with connection parameters
#' @param config_path Path to configuration file
#' @param verbose Print detailed information
#'
#' @return Data frame with query results if successful, NULL otherwise
#'
execute_query <- function(query, 
                         conn = NULL, 
                         credentials = NULL, 
                         config_path = NULL, 
                         verbose = TRUE) {
  
  if(verbose) message("Executing SQL query on eBay database...")
  
  # Create connection if not provided
  close_after <- FALSE
  if(is.null(conn)) {
    if(verbose) message("No connection provided, creating new connection...")
    conn <- connect_to_external_source(credentials, config_path, verbose = verbose)
    close_after <- TRUE
    
    if(is.null(conn)) {
      message("Failed to create connection for query execution")
      return(NULL)
    }
  }
  
  # Execute query
  tryCatch({
    if(verbose) message("Executing query...")
    result <- DBI::dbGetQuery(conn, query)
    
    if(verbose) message("Query executed successfully, returned ", nrow(result), " rows")
    
    # Close connection if we created it
    if(close_after) {
      disconnect_from_external_source(conn, verbose = verbose)
    }
    
    return(result)
  }, error = function(e) {
    message("Query execution failed: ", e$message)
    
    # Close connection if we created it
    if(close_after) {
      disconnect_from_external_source(conn, verbose = verbose)
    }
    
    return(NULL)
  })
}

#' Simple test of the module that doesn't require actual connections
#'
#' @param verbose Print detailed information
#'
#' @return TRUE always
#'
test_module_functionality <- function(verbose = TRUE) {
  if(verbose) {
    message("Testing M01_P06_00.R module functionality")
    message("Module for eBay (P06) external data connection is loaded correctly")
    message("Functions available:")
    message("- connect_to_external_source()")
    message("- disconnect_from_external_source()")
    message("- test_external_connection()")
    message("- execute_query()")
    message("- create_ssh_tunnel() and close_ssh_tunnel()")
  }
  return(TRUE)
}

# Example usage
if(FALSE) {
  # This won't run automatically but demonstrates how to use the functions
  
  # Test module without connections
  test_module_functionality(verbose = TRUE)
  
  # Create connection
  conn <- connect_to_external_source(verbose = TRUE)
  
  # Test connection
  test_external_connection(conn, verbose = TRUE)
  
  # Execute a query
  sales_data <- execute_query(
    "SELECT TOP 10 * FROM Orderproducts ORDER BY OrderDate DESC", 
    conn = conn, 
    verbose = TRUE
  )
  
  # Disconnect when done
  disconnect_from_external_source(conn, verbose = TRUE)
}