# import_amazon_sales

Source: `05_data_processing/import_amazon_sales.R`

## Functions

**Function List:**
- [import_amazon_sales_dta](#import-amazon-sales-dta)
- [process_amazon_sales](#process-amazon-sales)

### import_amazon_sales_dta

Import Amazon Sales Data from Excel Files

This function imports Amazon sales data from Excel files into the DuckDB database.
It processes all Excel files in a specified folder and its subfolders, 
performs basic data cleaning and validation, and appends the data to 
the amazon_sales_dta table.


## Parameters

- **folder_path Character string. Path to the folder containing Amazon sales Excel files.**
- **connection DBI connection object. An active connection to a DuckDB database.**
- **clean_columns Logical. Whether to apply standardized column name cleaning. Default is TRUE.**
- **overwrite Logical. Whether to overwrite the existing table or append to it. Default is FALSE (append).**
- **verbose Logical. Whether to print detailed processing information. Default is TRUE.**


## Return Value

The database connection object for chaining operations.


## Details


The function finds all Excel files (.xlsx or .xls) in the provided folder and its subfolders,
then attempts to read and process each file. It performs the following operations:
1. Standardizes column names to snake_case
2. Validates that required columns (sku, purchase_date) exist
3. Converts date columns to proper date/time format
4. Appends or overwrites data to the amazon_sales_dta table

If errors occur during processing, warning messages are displayed but the function continues
with the next file.


## Examples

```r
\dontrun{
# Connect to a DuckDB database
con <- dbConnect(duckdb::duckdb(), dbdir = "path/to/database.duckdb")

# Import Amazon sales data
import_amazon_sales_dta("path/to/amazon_sales_files", con)

# Import and overwrite existing data
import_amazon_sales_dta("path/to/amazon_sales_files", con, overwrite = TRUE)
}

```

## Export



---


### process_amazon_sales

Process Amazon sales data

Processes raw Amazon sales data from the database, performs transformations,
and writes the processed data to a destination table.


## Parameters

- **raw_data DBI connection. Connection to the database containing raw data.**
- **Data DBI connection. Connection to the database where processed data will be stored.**
- **verbose Logical. Whether to display progress messages. Default is TRUE.**


## Return Value

Invisibly returns the Data connection for chaining.


## Details


This function performs the following operations:
1. Filters records with valid email addresses
2. Extracts customer_id from buyer_email
3. Renames columns for consistency
4. Joins with product_property_dictionary for additional product information
5. Filters for US-only orders and required fields
6. Writes the processed data to the destination database


## Examples

```r
\dontrun{
# Connect to raw and processed data databases
raw_con <- dbConnect(duckdb::duckdb(), dbdir = "raw_data.duckdb")
proc_con <- dbConnect(duckdb::duckdb(), dbdir = "processed_data.duckdb")

# Process Amazon sales data
process_amazon_sales(raw_con, proc_con)
}

```

## Export



---

