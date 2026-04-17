#!/usr/bin/env Rscript
# ==============================================================================
# MAMBA Connection Debugging Script
# Purpose: Diagnose and fix SSH tunnel hanging issues
# Following MP099: Real-time Progress Reporting
# Following MP106: Console Output Transparency
# ==============================================================================

message("\n")
message("="*80)
message("🔍 MAMBA CONNECTION DEBUGGING TOOL")
message("="*80)
message("This script will help diagnose why fn_connect_mamba_sql is hanging")
message("="*80)
message("\n")

# Load required libraries
suppressPackageStartupMessages({
  library(DBI)
  library(odbc)
})

# Source both versions for comparison
message("📦 Loading function versions...")
message("  1. Original version: fn_ensure_mamba_tunnel.R")
message("  2. Enhanced version: fn_ensure_mamba_tunnel_enhanced.R")

# Test 1: Environment check
message("\n" %+% "="*80)
message("TEST 1: ENVIRONMENT VARIABLES CHECK")
message("="*80)

check_env <- function() {
  vars <- list(
    SSH = c("EBY_SSH_HOST", "EBY_SSH_USER", "EBY_SSH_PASSWORD"),
    SQL = c("EBY_SQL_HOST", "EBY_SQL_PORT", "EBY_SQL_DATABASE", 
            "EBY_SQL_USER", "EBY_SQL_PASSWORD"),
    LOCAL = c("EBY_LOCAL_PORT")
  )
  
  all_ok <- TRUE
  
  for (category in names(vars)) {
    message(sprintf("\n%s Configuration:", category))
    for (var in vars[[category]]) {
      val <- Sys.getenv(var)
      if (val == "") {
        message(sprintf("  ❌ %s: NOT SET", var))
        all_ok <- FALSE
      } else {
        # Mask passwords
        if (grepl("PASSWORD", var)) {
          message(sprintf("  ✅ %s: ****** (length: %d)", var, nchar(val)))
        } else {
          message(sprintf("  ✅ %s: %s", var, val))
        }
      }
    }
  }
  
  return(all_ok)
}

env_ok <- check_env()

if (!env_ok) {
  message("\n⚠️  Some environment variables are missing!")
  message("Add them to your .env file or set them in your environment")
  message("\nExample .env file:")
  message("EBY_SSH_HOST=220.128.138.146")
  message("EBY_SSH_USER=your_username")
  message("EBY_SSH_PASSWORD=your_password")
  message("EBY_SQL_HOST=125.227.84.85")
  message("EBY_SQL_PORT=1433")
  message("EBY_SQL_DATABASE=your_database")
  message("EBY_SQL_USER=your_sql_user")
  message("EBY_SQL_PASSWORD=your_sql_password")
  message("EBY_LOCAL_PORT=1433")
}

# Test 2: Network connectivity
message("\n" %+% "="*80)
message("TEST 2: NETWORK CONNECTIVITY")
message("="*80)

test_network <- function() {
  ssh_host <- Sys.getenv("EBY_SSH_HOST")
  
  if (ssh_host != "") {
    message(sprintf("\nTesting connectivity to SSH host: %s", ssh_host))
    
    # Test ping
    message("  Testing ping...")
    ping_cmd <- sprintf("ping -c 1 -W 2 %s 2>&1", ssh_host)
    ping_result <- system(ping_cmd, intern = TRUE)
    
    if (any(grepl("1 packets transmitted, 1", ping_result))) {
      message("  ✅ Ping successful")
    } else {
      message("  ❌ Ping failed")
      message("     Output: ", ping_result[1])
    }
    
    # Test SSH port
    message("  Testing SSH port 22...")
    nc_cmd <- sprintf("nc -z -v -w5 %s 22 2>&1", ssh_host)
    nc_result <- system(nc_cmd, intern = TRUE)
    
    if (any(grepl("succeeded|open", nc_result, ignore.case = TRUE))) {
      message("  ✅ SSH port 22 is open")
    } else {
      message("  ❌ SSH port 22 is not accessible")
      message("     This could be a firewall issue")
    }
  }
}

test_network()

# Test 3: SSH tools
message("\n" %+% "="*80)
message("TEST 3: SSH TOOLS AVAILABILITY")
message("="*80)

test_ssh_tools <- function() {
  tools <- c("ssh", "sshpass", "nc", "telnet")
  
  for (tool in tools) {
    which_result <- system(sprintf("which %s", tool), 
                          ignore.stdout = TRUE, ignore.stderr = TRUE)
    if (which_result == 0) {
      path <- system(sprintf("which %s", tool), intern = TRUE)
      message(sprintf("✅ %s: %s", tool, path))
    } else {
      message(sprintf("❌ %s: NOT FOUND", tool))
      if (tool == "sshpass") {
        message("   Install with: brew install hudochenkov/sshpass/sshpass")
      }
    }
  }
}

test_ssh_tools()

# Test 4: Check for existing tunnels
message("\n" %+% "="*80)
message("TEST 4: EXISTING SSH TUNNELS")
message("="*80)

check_tunnels <- function() {
  message("\nChecking for existing SSH tunnels...")
  
  # Check for any SSH tunnel processes
  ssh_processes <- system("ps aux | grep -E 'ssh.*[0-9]+:[0-9]' | grep -v grep", 
                          intern = TRUE, ignore.stderr = TRUE)
  
  if (length(ssh_processes) > 0) {
    message(sprintf("Found %d SSH tunnel process(es):", length(ssh_processes)))
    for (i in 1:min(3, length(ssh_processes))) {
      # Extract and display key info
      parts <- strsplit(ssh_processes[i], "\\s+")[[1]]
      pid <- parts[2]
      cmd_start <- paste(parts[11:min(15, length(parts))], collapse = " ")
      message(sprintf("  PID %s: %s...", pid, substr(cmd_start, 1, 60)))
    }
    
    # Check specifically for MAMBA tunnel
    mamba_tunnel <- system("ps aux | grep -E 'ssh.*1433.*125.227.84.85' | grep -v grep",
                          intern = TRUE, ignore.stderr = TRUE)
    if (length(mamba_tunnel) > 0) {
      message("\n✅ MAMBA tunnel is already running!")
      return(TRUE)
    } else {
      message("\n⚠️  Other SSH tunnels found but not the MAMBA tunnel")
    }
  } else {
    message("No SSH tunnels currently running")
  }
  
  return(FALSE)
}

tunnel_exists <- check_tunnels()

# Test 5: ODBC drivers
message("\n" %+% "="*80)
message("TEST 5: ODBC DRIVERS")
message("="*80)

test_odbc <- function() {
  message("\nChecking installed ODBC drivers...")
  
  drivers <- odbc::odbcListDrivers()
  
  if (nrow(drivers) == 0) {
    message("❌ No ODBC drivers installed!")
    message("Install SQL Server driver with:")
    message("  brew install microsoft/mssql-release/msodbcsql18")
  } else {
    sql_drivers <- drivers[grepl("SQL Server", drivers$name, ignore.case = TRUE), ]
    
    if (nrow(sql_drivers) > 0) {
      message("✅ SQL Server ODBC drivers found:")
      for (i in 1:nrow(sql_drivers)) {
        message(sprintf("  - %s (%s)", sql_drivers$name[i], sql_drivers$attribute[i]))
      }
    } else {
      message("⚠️  ODBC drivers found but no SQL Server driver")
      message("Available drivers:")
      for (i in 1:min(5, nrow(drivers))) {
        message(sprintf("  - %s", drivers$name[i]))
      }
    }
  }
}

test_odbc()

# Test 6: Try to create tunnel with debugging
message("\n" %+% "="*80)
message("TEST 6: SSH TUNNEL CREATION TEST")
message("="*80)

test_tunnel_creation <- function() {
  
  if (tunnel_exists) {
    message("Skipping tunnel creation test (tunnel already exists)")
    return(TRUE)
  }
  
  message("\n⚠️  About to test SSH tunnel creation")
  message("This may prompt for a password if sshpass fails")
  
  response <- readline("Continue with tunnel test? (y/n): ")
  
  if (tolower(response) != "y") {
    message("Skipping tunnel test")
    return(FALSE)
  }
  
  # Load and test enhanced version
  message("\nTesting enhanced tunnel function...")
  source("scripts/global_scripts/02_db_utils/fn_ensure_mamba_tunnel_enhanced.R")
  
  # Run the test function
  fn_test_mamba_connection()
  
  # Try to establish tunnel
  message("\nAttempting to establish tunnel...")
  result <- tryCatch({
    fn_ensure_mamba_tunnel(verbose = TRUE, max_retries = 1, connection_timeout = 5)
  }, error = function(e) {
    message("❌ Error during tunnel creation: ", e$message)
    return(FALSE)
  })
  
  return(result)
}

# Ask user if they want to test tunnel creation
if (env_ok) {
  test_tunnel_creation()
}

# Test 7: Manual SSH test command
message("\n" %+% "="*80)
message("TEST 7: MANUAL TESTING COMMANDS")
message("="*80)

message("\nIf automated tests fail, try these manual commands:")
message("\n1. Test basic SSH connection:")
message(sprintf("   ssh %s@%s", 
               Sys.getenv("EBY_SSH_USER"), 
               Sys.getenv("EBY_SSH_HOST")))

message("\n2. Create tunnel manually:")
message(sprintf("   ssh -N -L %s:%s:%s %s@%s",
               Sys.getenv("EBY_LOCAL_PORT", "1433"),
               Sys.getenv("EBY_SQL_HOST"),
               Sys.getenv("EBY_SQL_PORT", "1433"),
               Sys.getenv("EBY_SSH_USER"),
               Sys.getenv("EBY_SSH_HOST")))

message("\n3. Test with sshpass:")
message(sprintf("   sshpass -p 'YOUR_PASSWORD' ssh -o ConnectTimeout=5 %s@%s 'echo Connected'",
               Sys.getenv("EBY_SSH_USER"),
               Sys.getenv("EBY_SSH_HOST")))

message("\n4. Test SQL Server connection (after tunnel is up):")
message("   telnet 127.0.0.1 1433")

message("\n" %+% "="*80)
message("🏁 DEBUGGING COMPLETE")
message("="*80)

# Summary
message("\n📊 SUMMARY OF FINDINGS:")
message("="*80)

if (env_ok) {
  message("✅ Environment variables are configured")
} else {
  message("❌ Environment variables need configuration")
}

if (tunnel_exists) {
  message("✅ SSH tunnel is already running")
} else {
  message("⚠️  No SSH tunnel currently active")
}

message("\n💡 MOST LIKELY CAUSES OF HANGING:")
message("1. SSH waiting for password input (sshpass not working)")
message("2. Network timeout without proper error handling")
message("3. Firewall blocking SSH or SQL Server ports")
message("4. SSH host key verification prompt")
message("\n📝 RECOMMENDED SOLUTION:")
message("Use the enhanced version: fn_ensure_mamba_tunnel_enhanced.R")
message("It includes timeout handling and better error reporting")

message("\n" %+% "="*80)
message("End of diagnostic report")
message("="*80)