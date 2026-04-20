# Complete MAMBA eBay Import Test
# Uses temporary DuckDB to avoid lock issues

library(DBI)
library(odbc)
library(duckdb)

cat("================================================================================\n")
cat("Complete MAMBA eBay Import Test\n")
cat("================================================================================\n\n")

# Create temporary DuckDB
temp_db <- tempfile(fileext = ".duckdb")
cat(sprintf("Using temporary database: %s\n", temp_db))

duck_conn <- dbConnect(duckdb::duckdb(), temp_db)
cat("✅ Connected to temporary DuckDB\n\n")

# Connect to SQL Server
cat("Connecting to SQL Server...\n")

sql_conn <- dbConnect(
  odbc::odbc(),
  .connection_string = sprintf(
    "Driver={ODBC Driver 18 for SQL Server};Server=127.0.0.1,1433;Database=%s;Uid=%s;Pwd=%s;TrustServerCertificate=yes;Encrypt=no",
    "MAMBATEK",
    "sa",
    "u3sql@2007"
  )
)

cat("✅ Connected to SQL Server\n\n")

# Import BAYORD (Orders)
cat("Importing BAYORD (Orders)...\n")
orders_query <- "
  SELECT 
    ORD001 as order_id,
    ORD003 as order_date,
    ORD009 as batch_key,
    ORD010 as recipient,
    ORD011 as street1,
    ORD012 as street2,
    ORD013 as city_name,
    ORD014 as state_or_province,
    ORD015 as postal_code,
    ORD016 as country_name,
    ORD005 as total_payment
  FROM BAYORD
  WHERE ORD003 >= '2024-01-01'
"

orders_data <- dbGetQuery(sql_conn, orders_query)
cat(sprintf("✅ Retrieved %d orders\n", nrow(orders_data)))

# Import BAYORE (Order Details)
cat("\nImporting BAYORE (Order Details)...\n")
details_query <- "
  SELECT 
    ORE001 as order_id,
    ORE013 as batch_key,
    ORE002 as line_number,
    ORE003 as product_sku,
    ORE006 as product_name,
    ORE008 as quantity,
    ORE009 as unit_price
  FROM BAYORE
  WHERE ORE001 IN (SELECT ORD001 FROM BAYORD WHERE ORD003 >= '2024-01-01')
"

details_data <- dbGetQuery(sql_conn, details_query)
cat(sprintf("✅ Retrieved %d order detail lines\n", nrow(details_data)))

# Store in DuckDB
dbWriteTable(duck_conn, "orders", orders_data, overwrite = TRUE)
dbWriteTable(duck_conn, "order_details", details_data, overwrite = TRUE)

cat("\n✅ Data stored in temporary DuckDB\n")

# Perform JOIN to create sales
cat("\nCreating sales by JOINing orders and details...\n")

sales_query <- "
  SELECT 
    o.order_id,
    o.order_date,
    o.recipient,
    o.city_name,
    o.country_name,
    d.product_sku,
    d.product_name,
    d.quantity,
    d.unit_price,
    d.quantity * d.unit_price as line_total
  FROM orders o
  INNER JOIN order_details d
    ON o.order_id = d.order_id 
    AND o.batch_key = d.batch_key
"

sales_data <- dbGetQuery(duck_conn, sales_query)
cat(sprintf("✅ Created %d sales transaction records\n", nrow(sales_data)))

# Show sample
cat("\nSample sales data:\n")
print(head(sales_data, 5))

# Calculate summary
total_revenue <- sum(sales_data$line_total, na.rm = TRUE)
unique_orders <- length(unique(sales_data$order_id))
unique_customers <- length(unique(sales_data$recipient))

cat("\n📊 Summary Statistics:\n")
cat(sprintf("  • Total Revenue: $%.2f\n", total_revenue))
cat(sprintf("  • Unique Orders: %d\n", unique_orders))
cat(sprintf("  • Unique Customers: %d\n", unique_customers))

# Cleanup
dbDisconnect(sql_conn)
dbDisconnect(duck_conn)
unlink(temp_db)

cat("\n✅ Test complete - all connections closed\n")
cat("\n💡 Note: This confirms the ETL architecture works correctly:\n")
cat("   1. Orders and OrderDetails imported separately (BASE ETLs)\n")
cat("   2. Sales created by JOINing them (DERIVED ETL)\n")
cat("   3. No encoding errors with proper SQL Server connection\n")