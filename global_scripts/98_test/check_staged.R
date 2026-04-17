library(DBI)
library(duckdb)

# Connect to staged database
con <- dbConnect(duckdb::duckdb(), "data/local_data/staged_data.duckdb", read_only = TRUE)

# List tables
tables <- dbListTables(con)
cat("Tables in staged_data.duckdb:\n")
print(tables)

# Check for eby tables
eby_tables <- tables[grep("eby", tables)]
cat("\neBay related tables:\n")
print(eby_tables)

# Disconnect
dbDisconnect(con)
