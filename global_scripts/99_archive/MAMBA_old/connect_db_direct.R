# Direct database connection script
# This script provides a simple, reliable way to connect to the database
# without using the full initialization procedure

# Source the standalone database setup script
source(file.path("update_scripts", "global_scripts", "db_setup.R"))

# Connect to raw_data database
message("Connecting to raw_data database...")
raw_data <- dbConnect_from_list("raw_data")
message("Successfully connected to raw_data database")

# List available tables
available_tables <- dbListTables(raw_data)
message("Available tables in raw_data database:")
if (length(available_tables) > 0) {
  for (table in available_tables) {
    message(" - ", table)
  }
} else {
  message(" (No tables found)")
}

message("\nDatabase connection ready. You can now use:")
message("- dbListTables(raw_data) to list tables")
message("- dbReadTable(raw_data, 'df_ebay_sales') to read a table")
message("- dbDisconnect(raw_data) to close the connection when done")