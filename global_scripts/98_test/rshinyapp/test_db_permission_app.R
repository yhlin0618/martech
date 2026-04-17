# Test Application for Database Connection Permission System
# --------------------------------------------------------
# This test app validates the database connection permission enhancement
# that enforces access controls based on operation mode.

# Set working directory to the project root (important for proper path resolution)
# setwd("/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_WISER/precision_marketing_app")

# Load required libraries
library(shiny)
library(bslib)
library(dplyr)
library(DBI)
library(duckdb)

# Initialize APP_MODE environment - default starting mode
if(exists("INITIALIZATION_COMPLETED")) {
  # Reset initialization flags to allow re-initialization
  rm(INITIALIZATION_COMPLETED, envir = .GlobalEnv)
}

# Use platform-neutral path construction (Platform-Neutral Code Principle)
init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                            "sc_initialization_app_mode.R")
source(init_script_path)

# Make sure we have the DB paths list initialized
if(!exists("db_path_list")) {
  # Use platform-neutral path construction (Platform-Neutral Code Principle)
  db_utils_path <- file.path("update_scripts", "global_scripts", "02_db_utils", 
                          "db_utils.R")
  source(db_utils_path)
}

# Initialize databases if they don't exist
initialize_test_databases <- function() {
  # Check if databases exist and create minimal test databases if needed
  for(db_name in c("app_data", "processed_data", "global_scd_type1")) {
    db_path <- db_path_list[[db_name]]
    db_dir <- dirname(db_path)
    
    # Create directory if it doesn't exist
    if(!dir.exists(db_dir) && db_dir != ".") {
      message("Creating directory: ", db_dir)
      dir.create(db_dir, recursive = TRUE, showWarnings = FALSE)
    }
    
    # Create a minimal database if it doesn't exist
    if(!file.exists(db_path)) {
      message("Creating test database: ", db_path)
      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
      DBI::dbExecute(con, "CREATE TABLE test (id INTEGER, value TEXT)")
      DBI::dbAppendTable(con, "test", data.frame(id = 1:3, value = c("test1", "test2", "test3")))
      DBI::dbDisconnect(con)
    }
  }
}

# Initialize test databases
initialize_test_databases()

# Define UI
ui <- page_fluid(
  theme = bs_theme(version = 5, bootswatch = "yeti"),
  
  h1("Database Permission Test Application"),
  
  # Mode selector
  selectInput("operation_mode", "Select Operation Mode:",
              choices = c("APP_MODE", "UPDATE_MODE", "GLOBAL_MODE"),
              selected = "APP_MODE"),
  
  # Action buttons for testing different scenarios
  fluidRow(
    column(4, actionButton("test_app_data", "Test App Data Connection", 
                         class = "btn-primary btn-block")),
    column(4, actionButton("test_processing_data", "Test Processing Data Connection", 
                         class = "btn-warning btn-block")),
    column(4, actionButton("test_30_global_data", "Test Global Data Connection", 
                         class = "btn-info btn-block"))
  ),
  
  # Results panel
  br(),
  wellPanel(
    h3("Test Results"),
    verbatimTextOutput("connection_results")
  ),
  
  # Explanation panel
  br(),
  wellPanel(
    h3("Expected Behavior by Mode"),
    
    h4("APP_MODE"),
    tags$ul(
      tags$li("App Data: Read-only access (forced)"),
      tags$li("Processing Data: No access"),
      tags$li("Global Data: Read-only access")
    ),
    
    h4("UPDATE_MODE"),
    tags$ul(
      tags$li("App Data: Read-write access"),
      tags$li("Processing Data: Read-write access"),
      tags$li("Global Data: Read-only access")
    ),
    
    h4("GLOBAL_MODE"),
    tags$ul(
      tags$li("App Data: Read-write access"),
      tags$li("Processing Data: Read-write access"),
      tags$li("Global Data: Read-write access")
    )
  )
)

# Define server
server <- function(input, output, session) {
  
  # React to operation mode changes
  observeEvent(input$operation_mode, {
    # Clean up current connections first
    close_all_connections()
    
    # Reset initialization flag to allow reinitialization
    if(exists("INITIALIZATION_COMPLETED")) {
      rm(INITIALIZATION_COMPLETED, envir = .GlobalEnv)
    }
    
    # Source the appropriate initialization script based on mode
    # Use platform-neutral path construction (Platform-Neutral Code Principle)
    script_path <- switch(input$operation_mode,
                        "APP_MODE" = file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"),
                        "UPDATE_MODE" = file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"),
                        "GLOBAL_MODE" = file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_global_mode.R"))
    
    # Capture messages during initialization
    output$connection_results <- renderText({
      capture.output({
        source(script_path, local = FALSE)
        message(paste("Changed operation mode to:", OPERATION_MODE))
        # Re-initialize database paths if needed
        if(!exists("db_path_list")) {
          source("update_scripts/global_scripts/02_db_utils/db_utils.R", local = FALSE)
        }
      })
    })
  })
  
  # Function to close all database connections
  close_all_connections <- function() {
    if (exists("dbDisconnect_all") && is.function(get("dbDisconnect_all"))) {
      dbDisconnect_all()
    } else {
      # Fallback if the function doesn't exist
      for (con_name in c("app_data", "processed_data", "global_scd_type1")) {
        if (exists(con_name)) {
          tryCatch({
            con <- get(con_name)
            if (inherits(con, "DBIConnection")) {
              DBI::dbDisconnect(con)
            }
            rm(list = con_name, envir = .GlobalEnv)
          }, error = function(e) {
            message(paste("Error disconnecting from", con_name, ":", e$message))
          })
        }
      }
    }
    # Allow some time for connections to close properly
    Sys.sleep(0.5)
  }
  
  # Test App Data Connection
  observeEvent(input$test_app_data, {
    close_all_connections()
    
    results <- capture.output({
      tryCatch({
        cat("Current operation mode:", OPERATION_MODE, "\n")
        cat("Attempting to connect to app_data database in WRITE mode...\n")
        
        # Track if dbConnect_from_list exists
        if (!exists("dbConnect_from_list")) {
          cat("Function dbConnect_from_list not found. Sourcing database utilities...\n")
          # Use platform-neutral path construction (Platform-Neutral Code Principle)
          db_utils_path <- file.path("update_scripts", "global_scripts", "02_db_utils", 
                                   "db_utils.R")
          source(db_utils_path, local = FALSE)
        }
        
        # Track if check_data_access exists (for debugging)
        if (exists("check_data_access")) {
          cat("Permission checking system (check_data_access) is available.\n")
        } else {
          cat("Permission checking system not found - basic APP_MODE protection will be used.\n")
        }
        
        # Connect to database
        app_data <- dbConnect_from_list("app_data", read_only = FALSE, verbose = FALSE)
        cat("Connection established.\n")
        cat("Tables in database:", paste(DBI::dbListTables(app_data), collapse = ", "), "\n")
        cat("Is read-only?", DBI::dbIsReadOnly(app_data), "\n")
        
        # Test write operation
        write_test <- tryCatch({
          dbExecute(app_data, "CREATE TABLE IF NOT EXISTS test_permissions (id INTEGER, value TEXT)")
          dbAppendTable(app_data, "test_permissions", data.frame(id = 1, value = "test"))
          "Write operation succeeded (table created and data inserted)"
        }, error = function(e) {
          paste("Write operation failed:", e$message)
        })
        cat(write_test, "\n")
        
      }, error = function(e) {
        cat("ERROR:", e$message, "\n")
      })
    })
    
    # Update output
    output$connection_results <- renderText({
      paste(results, collapse = "\n")
    })
  })
  
  # Test Processing Data Connection
  observeEvent(input$test_processing_data, {
    close_all_connections()
    
    results <- capture.output({
      tryCatch({
        cat("Current operation mode:", OPERATION_MODE, "\n")
        cat("Attempting to connect to processed_data database in WRITE mode...\n")
        
        # Track if dbConnect_from_list exists
        if (!exists("dbConnect_from_list")) {
          cat("Function dbConnect_from_list not found. Sourcing database utilities...\n")
          # Use platform-neutral path construction (Platform-Neutral Code Principle)
          db_utils_path <- file.path("update_scripts", "global_scripts", "02_db_utils", 
                                   "db_utils.R")
          source(db_utils_path, local = FALSE)
        }
        
        # Track if check_data_access exists (for debugging)
        if (exists("check_data_access")) {
          cat("Permission checking system (check_data_access) is available.\n")
        } else {
          cat("Permission checking system not found - basic APP_MODE protection will be used.\n")
        }
        
        # Connect to database
        processed_data <- dbConnect_from_list("processed_data", read_only = FALSE, verbose = FALSE)
        cat("Connection established.\n")
        cat("Tables in database:", paste(DBI::dbListTables(processed_data), collapse = ", "), "\n")
        cat("Is read-only?", DBI::dbIsReadOnly(processed_data), "\n")
        
        # Test write operation
        write_test <- tryCatch({
          dbExecute(processed_data, "CREATE TABLE IF NOT EXISTS test_permissions (id INTEGER, value TEXT)")
          dbAppendTable(processed_data, "test_permissions", data.frame(id = 1, value = "test"))
          "Write operation succeeded (table created and data inserted)"
        }, error = function(e) {
          paste("Write operation failed:", e$message)
        })
        cat(write_test, "\n")
        
      }, error = function(e) {
        cat("ERROR:", e$message, "\n")
      })
    })
    
    # Update output
    output$connection_results <- renderText({
      paste(results, collapse = "\n")
    })
  })
  
  # Test Global Data Connection
  observeEvent(input$test_30_global_data, {
    close_all_connections()
    
    results <- capture.output({
      tryCatch({
        cat("Current operation mode:", OPERATION_MODE, "\n")
        cat("Attempting to connect to global_scd_type1 database in WRITE mode...\n")
        
        # Track if dbConnect_from_list exists
        if (!exists("dbConnect_from_list")) {
          cat("Function dbConnect_from_list not found. Sourcing database utilities...\n")
          # Use platform-neutral path construction (Platform-Neutral Code Principle)
          db_utils_path <- file.path("update_scripts", "global_scripts", "02_db_utils", 
                                   "db_utils.R")
          source(db_utils_path, local = FALSE)
        }
        
        # Track if check_data_access exists (for debugging)
        if (exists("check_data_access")) {
          cat("Permission checking system (check_data_access) is available.\n")
        } else {
          cat("Permission checking system not found - basic APP_MODE protection will be used.\n")
        }
        
        # Connect to database
        global_scd_type1 <- dbConnect_from_list("global_scd_type1", read_only = FALSE, verbose = FALSE)
        cat("Connection established.\n")
        cat("Tables in database:", paste(DBI::dbListTables(global_scd_type1), collapse = ", "), "\n")
        cat("Is read-only?", DBI::dbIsReadOnly(global_scd_type1), "\n")
        
        # Test write operation
        write_test <- tryCatch({
          dbExecute(global_scd_type1, "CREATE TABLE IF NOT EXISTS test_permissions (id INTEGER, value TEXT)")
          dbAppendTable(global_scd_type1, "test_permissions", data.frame(id = 1, value = "test"))
          "Write operation succeeded (table created and data inserted)"
        }, error = function(e) {
          paste("Write operation failed:", e$message)
        })
        cat(write_test, "\n")
        
      }, error = function(e) {
        cat("ERROR:", e$message, "\n")
      })
    })
    
    # Update output
    output$connection_results <- renderText({
      paste(results, collapse = "\n")
    })
  })
  
  # Clean up connections when app closes
  onSessionEnded(function() {
    close_all_connections()
  })
}

# Run the app
shinyApp(ui = ui, server = server)