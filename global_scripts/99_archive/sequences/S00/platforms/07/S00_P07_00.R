# S00_P07_00.R
# Implementation of S00 step 00 (Pre-processing Raw Data) for Cyberbiz platform (07/CBZ)
#
# This script implements the pre-processing step for Cyberbiz API data
# before it's imported to the regular raw_data pipeline.
#
# Platform: Cyberbiz (07/CBZ) per R38 Platform Numbering Convention

# Initialize the environment and load all necessary scripts
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))

# Load required libraries
library(httr)
library(jsonlite)
library(data.table)
library(tidyverse)

# Log script start
message("Starting S00_P07_00: Pre-processing Cyberbiz API data and storing in preraw_data.duckdb")

# Function to create the preraw_data database connection
dbConnect_preraw_data <- function(read_only = TRUE, verbose = FALSE) {
  # Define the database path
  db_path <- file.path(Sys.getenv("HOME"), "Library", "CloudStorage", "Dropbox", 
                       "precision_marketing", "precision_marketing_MAMBA", "preraw_data.duckdb")
  
  # Create database connection
  connection_params <- list(
    drv = duckdb::duckdb(),
    dbdir = db_path,
    read_only = read_only
  )
  
  # Attempt to connect with the specified parameters
  conn <- NULL
  tryCatch({
    conn <- do.call(DBI::dbConnect, connection_params)
    if (verbose) message("Successfully connected to preraw_data database at: ", db_path)
  }, error = function(e) {
    stop("Failed to connect to preraw_data database: ", e$message)
  })
  
  # Register the connection to be closed at the end of the R session
  reg.finalizer(environment(), function(...) {
    if (!is.null(conn) && DBI::dbIsValid(conn)) {
      DBI::dbDisconnect(conn, shutdown = TRUE)
    }
  }, onexit = TRUE)
  
  # Return the connection
  return(conn)
}

# Connect to the preraw_data database
preraw_data <- dbConnect_preraw_data(read_only = FALSE, verbose = TRUE)

# Connect to the raw_data database for later
raw_data <- dbConnect_from_list("raw_data", read_only = FALSE)

# Function to create or replace the cyberbiz_orders table in preraw_data
create_or_replace_cyberbiz_orders <- function(conn, data = NULL) {
  message("Creating or replacing cyberbiz_orders table structure in preraw_data")
  
  if (!is.null(data) && is.data.frame(data)) {
    # Create table using provided data structure
    DBI::dbExecute(conn, "DROP TABLE IF EXISTS cyberbiz_orders")
    DBI::dbCreateTable(conn, "cyberbiz_orders", data)
    DBI::dbExecute(conn, "DELETE FROM cyberbiz_orders")
    
    message("Table cyberbiz_orders structure created successfully in preraw_data")
    return(TRUE)
  } else {
    warning("No data provided to infer table structure")
    return(FALSE)
  }
}

# Function to create or replace the cyberbiz_customers table in preraw_data
create_or_replace_cyberbiz_customers <- function(conn, data = NULL) {
  message("Creating or replacing cyberbiz_customers table structure in preraw_data")
  
  if (!is.null(data) && is.data.frame(data)) {
    # Create table using provided data structure
    DBI::dbExecute(conn, "DROP TABLE IF EXISTS cyberbiz_customers")
    DBI::dbCreateTable(conn, "cyberbiz_customers", data)
    DBI::dbExecute(conn, "DELETE FROM cyberbiz_customers")
    
    message("Table cyberbiz_customers structure created successfully in preraw_data")
    return(TRUE)
  } else {
    warning("No data provided to infer table structure")
    return(FALSE)
  }
}

# Function to load data from Cyberbiz API into preraw_data
load_cyberbiz_api_data <- function() {
  # Define paths to RDS files
  cyberbiz_api_dir <- "/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_MAMBA/cyberbiz_api"
  orders_rds_file <- file.path(cyberbiz_api_dir, "order.RDS")
  customers_rds_file <- file.path(cyberbiz_api_dir, "customers.RDS")
  
  # Process orders data
  if (file.exists(orders_rds_file)) {
    message("Processing orders data from ", orders_rds_file)
    orders_data <- readRDS(orders_rds_file)
    
    # Convert list columns to JSON strings for database compatibility
    orders_data_clean <- as.data.frame(orders_data)
    list_cols <- sapply(orders_data_clean, is.list)
    for (col in names(orders_data_clean)[list_cols]) {
      orders_data_clean[[col]] <- sapply(orders_data_clean[[col]], function(x) {
        if (is.null(x)) return(NA_character_)
        jsonlite::toJSON(x, auto_unbox = TRUE)
      })
    }
    
    # Create table and insert data
    create_or_replace_cyberbiz_orders(preraw_data, orders_data_clean)
    DBI::dbWriteTable(preraw_data, "cyberbiz_orders", orders_data_clean, append = TRUE)
    message("Imported ", nrow(orders_data_clean), " order records to preraw_data")
  } else {
    warning("Orders RDS file not found: ", orders_rds_file)
  }
  
  # Process customers data
  if (file.exists(customers_rds_file)) {
    message("Processing customers data from ", customers_rds_file)
    customers_data <- readRDS(customers_rds_file)
    
    # Convert list columns to JSON strings for database compatibility
    customers_data_clean <- as.data.frame(customers_data)
    list_cols <- sapply(customers_data_clean, is.list)
    for (col in names(customers_data_clean)[list_cols]) {
      customers_data_clean[[col]] <- sapply(customers_data_clean[[col]], function(x) {
        if (is.null(x)) return(NA_character_)
        jsonlite::toJSON(x, auto_unbox = TRUE)
      })
    }
    
    # Create table and insert data
    create_or_replace_cyberbiz_customers(preraw_data, customers_data_clean)
    DBI::dbWriteTable(preraw_data, "cyberbiz_customers", customers_data_clean, append = TRUE)
    message("Imported ", nrow(customers_data_clean), " customer records to preraw_data")
  } else {
    warning("Customers RDS file not found: ", customers_rds_file)
  }
}

# Function to join orders and customers data and prepare for raw_data
prepare_combined_cyberbiz_data <- function() {
  message("Joining orders and customers data to create combined dataset")
  
  # Verify that tables exist in preraw_data
  if (!DBI::dbExistsTable(preraw_data, "cyberbiz_orders")) {
    warning("cyberbiz_orders table does not exist in preraw_data")
    return(FALSE)
  }
  
  if (!DBI::dbExistsTable(preraw_data, "cyberbiz_customers")) {
    warning("cyberbiz_customers table does not exist in preraw_data")
    return(FALSE)
  }
  
  # Create the joined cyberbiz_sales table in raw_data
  join_query <- "
  CREATE OR REPLACE TABLE df_cyberbiz_sales AS
  SELECT
    o.id AS order_id,
    o.created_at,
    o.updated_at,
    o.status,
    o.total_price,
    o.shipping_fee,
    o.payment_method,
    o.payment_status,
    o.shipping_method,
    o.shipping_status,
    o.recipient_name,
    o.recipient_phone,
    o.recipient_address,
    o.recipient_city,
    o.recipient_state,
    o.recipient_country,
    o.recipient_zip,
    c.id AS customer_id,
    c.name AS customer_name,
    c.email AS customer_email,
    c.phone AS customer_phone,
    c.address AS customer_address,
    c.city AS customer_city,
    c.state AS customer_state,
    c.country AS customer_country,
    c.zipcode AS customer_zipcode,
    o.line_products,
    CURRENT_TIMESTAMP AS imported_at
  FROM
    cyberbiz_orders o
  LEFT JOIN
    cyberbiz_customers c ON o.customer_id = c.id
  "
  
  # Execute the join and store the result in raw_data
  tryCatch({
    DBI::dbExecute(raw_data, join_query)
    message("Successfully created df_cyberbiz_sales table in raw_data")
    
    # Count the records
    row_count <- tbl(raw_data, "df_cyberbiz_sales") %>% count() %>% pull()
    message(sprintf("Combined dataset contains %d records", row_count))
    
    return(TRUE)
  }, error = function(e) {
    warning("Failed to create combined cyberbiz_sales table: ", e$message)
    return(FALSE)
  })
}

# Execute the data loading process
load_cyberbiz_api_data()

# Prepare combined data for raw_data
prepare_combined_cyberbiz_data()

# Verify the combined data
row_count <- tbl(raw_data, "df_cyberbiz_sales") %>% count() %>% pull()
if (row_count > 0) {
  message(sprintf("Successfully prepared %d records in raw_data.df_cyberbiz_sales", row_count))
  
  # Display a sample of the data for verification
  sample_data <- tbl(raw_data, "df_cyberbiz_sales") %>% head(5) %>% collect()
  print(sample_data)
} else {
  warning("No records were created in raw_data.df_cyberbiz_sales")
}

# Clean up resources and close connections
DBI::dbDisconnect(preraw_data, shutdown = TRUE)
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_deinitialization_update_mode.R"))