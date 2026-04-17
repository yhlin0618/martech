# D01_P07_00.R
# Implementation of D01 step 00 (Import External Raw Data) for Cyberbiz platform (07/CBZ)
#
# This script implements the platform-specific version of the D01_00 derivation step
# as defined in D01_dna_analysis.md.
#
# Platform: Cyberbiz (07/CBZ) per R38 Platform Numbering Convention

# Initialize the environment and load all necessary scripts
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))

# Connect to the raw_data database
dbConnect_from_list("raw_data", read_only = FALSE)

# Log script start with platform_id alias per R38
message("Starting D01_P07_00: Importing external_raw_data.cyberbiz_sales to raw_data.df_cyberbiz_sales")

# Function to create or replace the cyberbiz_sales_dta table structure
create_or_replace_df_cyberbiz_sales <- function(conn, example_location = NULL) {
  message("Creating or replacing df_cyberbiz_sales table structure")
  
  # Define table schema based on Cyberbiz sales data structure
  if (!is.null(example_location) && file.exists(example_location)) {
    # Read example file to infer schema
    if (grepl("\\.csv$", example_location)) {
      sample_data <- read.csv(example_location, nrows = 5)
    } else if (grepl("\\.(xlsx|xls)$", example_location)) {
      sample_data <- readxl::read_excel(example_location, n_max = 5)
    } else if (grepl("\\.RDS$", example_location, ignore.case = TRUE)) {
      sample_data <- readRDS(example_location)
      if (is.data.frame(sample_data)) {
        sample_data <- head(sample_data, 5)
      } else {
        stop("RDS file does not contain a data frame")
      }
    } else {
      stop("Unsupported file format for structure inference")
    }
    
    # Handle list columns by converting them to JSON strings
    list_cols <- sapply(sample_data, is.list)
    if (any(list_cols)) {
      sample_data <- as.data.frame(sample_data)
      for (col in names(sample_data)[list_cols]) {
        sample_data[[col]] <- sapply(sample_data[[col]], function(x) {
          if (is.null(x)) return(NA_character_)
          jsonlite::toJSON(x, auto_unbox = TRUE)
        })
      }
    }
    
    # Create table using sample data structure
    DBI::dbExecute(conn, "DROP TABLE IF EXISTS df_cyberbiz_sales")
    DBI::dbCreateTable(conn, "df_cyberbiz_sales", sample_data)
    DBI::dbExecute(conn, "DELETE FROM df_cyberbiz_sales")
  } else {
    # Create default structure if no example file is available
    query <- "
    CREATE OR REPLACE TABLE df_cyberbiz_sales (
      id TEXT,
      order_id TEXT,
      customer_id TEXT,
      created_at TIMESTAMP,
      updated_at TIMESTAMP,
      status TEXT,
      price NUMERIC,
      total_price NUMERIC,
      discount NUMERIC,
      shipping_fee NUMERIC,
      payment_method TEXT,
      payment_status TEXT,
      shipping_method TEXT,
      shipping_status TEXT,
      recipient_name TEXT,
      recipient_phone TEXT,
      recipient_address TEXT,
      recipient_city TEXT,
      recipient_state TEXT,
      recipient_country TEXT,
      recipient_zip TEXT,
      note TEXT,
      tags TEXT,
      line_products TEXT,
      imported_at TIMESTAMP
    )
    "
    DBI::dbExecute(conn, query)
  }
  
  message("Table df_cyberbiz_sales structure created successfully")
  return(TRUE)
}

# Function to import Cyberbiz sales data from RDS files
import_df_cyberbiz_sales_from_rds <- function(rds_file, conn) {
  message("Importing Cyberbiz sales data from ", rds_file)
  
  if (!file.exists(rds_file)) {
    warning("RDS file not found: ", rds_file)
    return(NULL)
  }
  
  # Read the RDS file
  data <- readRDS(rds_file)
  
  # Handle list columns by converting them to JSON strings
  list_cols <- sapply(data, is.list)
  if (any(list_cols)) {
    data <- as.data.frame(data)
    for (col in names(data)[list_cols]) {
      data[[col]] <- sapply(data[[col]], function(x) {
        if (is.null(x)) return(NA_character_)
        jsonlite::toJSON(x, auto_unbox = TRUE)
      })
    }
  }
  
  # Add import timestamp
  data$imported_at <- Sys.time()
  
  # Clean column names to ensure compatibility with database
  names(data) <- make.names(names(data), unique = TRUE)
  
  # Append data to the table
  DBI::dbWriteTable(conn, "df_cyberbiz_sales", data, append = TRUE)
  
  # Count imported rows
  rows_imported <- nrow(data)
  message("Imported ", rows_imported, " rows from ", basename(rds_file))
  
  return(rows_imported)
}

# Create or replace the df_cyberbiz_sales table structure
# Use the order.RDS file as reference
cyberbiz_api_dir <- "/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_MAMBA/cyberbiz_api"
order_rds_file <- file.path(cyberbiz_api_dir, "order.RDS")

if (file.exists(order_rds_file)) {
  message("Using ", order_rds_file, " as structure reference")
  create_or_replace_df_cyberbiz_sales(raw_data, example_location = order_rds_file)
} else {
  # Fallback to creating the structure without a reference file
  message("No example file found. Creating table with default structure.")
  create_or_replace_df_cyberbiz_sales(raw_data)
}

# Import Cyberbiz sales data from RDS file
message("Importing data from ", order_rds_file)
import_result <- import_df_cyberbiz_sales_from_rds(order_rds_file, raw_data)

# Verify import success
if (is.null(import_result) || import_result == 0) {
  warning("No Cyberbiz sales data was imported. Please check source files.")
} else {
  # Report the number of records imported
  row_count <- tbl(raw_data, "df_cyberbiz_sales") %>% count() %>% pull()
  message(sprintf("Successfully imported %d records into raw_data.df_cyberbiz_sales", row_count))
  
  # Display a sample of the data for verification
  sample_data <- tbl(raw_data, "df_cyberbiz_sales") %>% head(5) %>% collect()
  print(sample_data)
}

# Clean up resources and close connections
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_deinitialization_update_mode.R"))