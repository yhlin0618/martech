# Test script to find the date parsing issue
library(DBI)
library(duckdb)
library(data.table)

# Connect to raw database
raw_conn <- dbConnect(duckdb(), "data/local_data/raw_data.duckdb")

# Read a sample of raw data
df_raw <- dbGetQuery(raw_conn, "SELECT ORD003 as order_date FROM df_eby_sales___raw LIMIT 10")

message("Sample order_date values from raw data:")
print(df_raw)

# Check data type
message("\nData type of order_date:")
print(class(df_raw$order_date))

# Try the date parsing that fails
dt_test <- as.data.table(df_raw)
message("\nTrying to parse dates:")
tryCatch({
  dt_test[, order_year := year(as.Date(order_date))]
  message("SUCCESS: Date parsing worked")
  print(dt_test)
}, error = function(e) {
  message("ERROR: Date parsing failed")
  message("Error message: ", e$message)
  
  # Try to understand the date format
  message("\nSample date values:")
  print(head(df_raw$order_date, 10))
})

dbDisconnect(raw_conn)