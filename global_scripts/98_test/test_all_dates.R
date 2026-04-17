# Check all date columns format
library(DBI)
library(duckdb)

# Connect to raw database
raw_conn <- dbConnect(duckdb(), "data/local_data/raw_data.duckdb")

# Check date columns
df_dates <- dbGetQuery(raw_conn, "SELECT ORD003 as order_date, ORD004 as payment_date, ORE012 as purchase_date FROM df_eby_sales___raw LIMIT 5")

message("Sample date values:")
print(df_dates)

dbDisconnect(raw_conn)