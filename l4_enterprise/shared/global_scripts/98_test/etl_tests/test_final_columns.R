# Test final column names in staged table
library(DBI)
library(duckdb)

# Connect to staged database
con <- dbConnect(duckdb(), "data/local_data/staged_data.duckdb")

# Get column names
cols <- dbGetQuery(con, "SELECT * FROM df_eby_sales___staged LIMIT 1")

# Check for any remaining ORD/ORE columns
remaining <- grep("^(ORD|ORE)", names(cols), value = TRUE)

if (length(remaining) > 0) {
  cat("❌ ERROR: Still have unrenamed columns:\n")
  print(remaining)
} else {
  cat("✅ SUCCESS: All ORD/ORE columns have been properly renamed!\n")
  cat("Total columns:", ncol(cols), "\n")
  cat("\nAll column names:\n")
  print(names(cols))
  
  # Verify specific columns that were problematic
  expected_renames <- c("recipient", "street1", "street2", "city_name", 
                        "state_or_province", "postal_code", "country_name", 
                        "buyer_ebay", "product_name", "application_data",
                        "variation", "payment_status")
  
  present <- expected_renames[expected_renames %in% names(cols)]
  missing <- expected_renames[!expected_renames %in% names(cols)]
  
  cat("\n✅ Successfully renamed columns present:\n")
  print(present)
  
  if (length(missing) > 0) {
    cat("\n⚠️ Expected columns missing:\n")
    print(missing)
  }
}

# Check a sample row to verify data
sample_data <- dbGetQuery(con, "SELECT recipient, street1, city_name, buyer_ebay FROM df_eby_sales___staged LIMIT 3")
cat("\n📊 Sample data from renamed columns:\n")
print(sample_data)

dbDisconnect(con)