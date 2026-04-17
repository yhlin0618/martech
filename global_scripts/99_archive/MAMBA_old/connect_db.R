# Simple database connection script
# Run this script with source("connect_db.R") to connect to databases

# Basic check for DBI and duckdb packages
if(!requireNamespace("DBI", quietly = TRUE)) install.packages("DBI")
if(!requireNamespace("duckdb", quietly = TRUE)) install.packages("duckdb")
library(DBI)
library(duckdb)

# Source required utility functions directly
source(file.path("update_scripts", "global_scripts", "02_db_utils", "fn_get_default_db_paths.R"))
source(file.path("update_scripts", "global_scripts", "02_db_utils", "fn_dbConnect_from_list.R"))

# Initialize database paths
db_path_list <- get_default_db_paths()
message("Database paths initialized:")
print(names(db_path_list))

# Create dbConnect_from_list alias if it doesn't exist (for legacy compatibility)
if(!exists("dbConnect_from_list") && exists("fn_dbConnect_from_list")) {
  dbConnect_from_list <- fn_dbConnect_from_list
  message("Created alias: dbConnect_from_list -> fn_dbConnect_from_list")
}

message("Database connection functions ready - you can now use:")
message("raw_data <- dbConnect_from_list(\"raw_data\")")
message("processed_data <- dbConnect_from_list(\"processed_data\")")