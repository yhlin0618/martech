# Test the simplified database initialization

# Source the simplified initialization script
message("Sourcing simplified database initialization...")
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_init_db_only.R"))

# Test database connection
message("\nTesting database connection...")
if (exists("dbConnect_from_list") && exists("db_path_list")) {
  raw_data <- dbConnect_from_list("raw_data")
  message("Connected to raw_data database")
  message("Tables: ", paste(dbListTables(raw_data), collapse=", "))
  dbDisconnect(raw_data)
} else {
  message("Database functions not properly initialized")
}

message("\nTest completed")