# Test the date parsing with sapply
library(data.table)
library(lubridate)

# Sample data
dates <- c("20250529 015637", "20250529 071545", NA, "", "20250530 110857")

# Helper function to parse MAMBA date format
parse_mamba_date <- function(date_str) {
  if (is.na(date_str) || nchar(date_str) < 8) return(NA)
  date_part <- substr(date_str, 1, 8)
  return(as.Date(date_part, format = "%Y%m%d"))
}

# Test with sapply
message("Testing date parsing with sapply:")
result <- sapply(dates, parse_mamba_date)
print(result)

# Convert to character
result_char <- as.character(result)
print(result_char)

# Now test in data.table context
dt_test <- data.table(order_date = dates)
message("\nTesting in data.table context:")
tryCatch({
  dt_test[, order_date := as.character(sapply(order_date, parse_mamba_date))]
  message("SUCCESS")
  print(dt_test)
}, error = function(e) {
  message("ERROR: ", e$message)
})