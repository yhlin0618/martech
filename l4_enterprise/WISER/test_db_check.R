library(DBI)
library(duckdb)

# Connect to database
con <- dbConnect(duckdb::duckdb(), "data/app_data/app_data.duckdb")

# List all tables
cat("Available tables:\n")
tables <- dbListTables(con)
print(tables)

# Check df_position structure
if ("df_position" %in% tables) {
  cat("\n\ndf_position columns:\n")
  cols <- dbListFields(con, "df_position")
  print(cols)

  # Get first row
  cat("\n\nFirst row of df_position:\n")
  first_row <- dbGetQuery(con, "SELECT * FROM df_position LIMIT 1")
  print(names(first_row))

  # Check if item_id or product_id exists
  cat("\n\nColumn check:\n")
  if ("item_id" %in% cols) cat("✅ item_id exists\n")
  if ("product_id" %in% cols) cat("✅ product_id exists\n")
  if (!"item_id" %in% cols && !"product_id" %in% cols) cat("❌ Neither item_id nor product_id found!\n")
}

dbDisconnect(con, shutdown = TRUE)