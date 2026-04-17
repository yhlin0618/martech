# Direct test of MAMBA SQL Server import
# Bypasses autoinit to avoid DuckDB lock issues

library(DBI)
library(odbc)
library(duckdb)

cat("================================================================================\n")
cat("Direct MAMBA SQL Server Import Test\n")
cat("================================================================================\n\n")

# Test SQL Server connection
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

cat("✅ Connected to SQL Server\n")

# Query BAYORD table
cat("Querying BAYORD table...\n")
query <- "
  SELECT TOP 10
    ORD001, ORD003, ORD010, ORD016
  FROM BAYORD
  WHERE ORD003 >= '2024-01-01'
  ORDER BY ORD003 DESC
"

sample_data <- dbGetQuery(sql_conn, query)
cat(sprintf("✅ Retrieved %d sample orders\n", nrow(sample_data)))

print(sample_data)

# Check encoding
cat("\nChecking encoding of ORD010 (recipient):\n")
for(i in 1:min(3, nrow(sample_data))) {
  val <- sample_data$ORD010[i]
  cat(sprintf("  Row %d: '%s' (nchar=%d)\n", i, val, nchar(val)))
}

# Disconnect
dbDisconnect(sql_conn)
cat("\n✅ Test complete\n")