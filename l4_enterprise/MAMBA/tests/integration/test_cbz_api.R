# Test Cyberbiz API Response Structure
# Debug script to understand why DuckDB fails

# Initialize
autoinit()

library(httr)
library(jsonlite)
library(dplyr)

# Get API credentials
api_token <- Sys.getenv("CBZ_API_TOKEN")
api_base_url <- "https://app-store-api.cyberbiz.io/v1"

message("Testing Cyberbiz API with token: ", substr(api_token, 1, 20), "...")

# Test /customers endpoint
message("\n=== Testing /customers endpoint ===")
response <- httr::GET(
  paste0(api_base_url, "/customers"),
  httr::add_headers(
    "Authorization" = paste("Bearer", api_token),
    "Content-Type" = "application/json",
    "Accept" = "application/json"
  ),
  query = list(page = 1, per_page = 2),
  httr::timeout(30)
)

status_code <- httr::status_code(response)
message("Response status: ", status_code)

if (status_code == 200) {
  # Parse response
  content <- httr::content(response, "text", encoding = "UTF-8")
  
  # Try different parsing approaches
  message("\nParsing with flatten = TRUE:")
  tryCatch({
    result <- jsonlite::fromJSON(content, flatten = TRUE)
    message("Success! Data structure:")
    str(result, max.level = 2)
    
    # Check data types
    if (is.data.frame(result)) {
      message("\nColumn types:")
      sapply(result, class)
    }
    
    # Try writing to DuckDB
    message("\nTrying to write to DuckDB...")
    raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
    
    # Add metadata columns
    result_with_meta <- result %>%
      mutate(
        import_source = "API_TEST",
        import_timestamp = Sys.time(),
        platform_id = "cbz"
      )
    
    dbWriteTable(raw_data, "test_customers", result_with_meta, overwrite = TRUE)
    message("Successfully wrote to DuckDB!")
    
    # Check what was written
    count <- dbGetQuery(raw_data, "SELECT COUNT(*) as n FROM test_customers")$n
    message("Records written: ", count)
    
    DBI::dbDisconnect(raw_data)
    
  }, error = function(e) {
    message("Error with flatten = TRUE: ", e$message)
  })
  
  message("\nParsing with flatten = FALSE:")
  tryCatch({
    result <- jsonlite::fromJSON(content, flatten = FALSE)
    message("Success! Data structure:")
    str(result, max.level = 2)
  }, error = function(e) {
    message("Error with flatten = FALSE: ", e$message)
  })
  
  # Show raw JSON structure (first 500 chars)
  message("\nRaw JSON (first 500 chars):")
  cat(substr(content, 1, 500))
  
} else {
  # Show error
  error_content <- httr::content(response, "text", encoding = "UTF-8")
  message("API Error: ", error_content)
}

# Test /orders endpoint
message("\n\n=== Testing /orders endpoint ===")
response <- httr::GET(
  paste0(api_base_url, "/orders"),
  httr::add_headers(
    "Authorization" = paste("Bearer", api_token),
    "Content-Type" = "application/json",
    "Accept" = "application/json"
  ),
  query = list(page = 1, per_page = 2),
  httr::timeout(30)
)

status_code <- httr::status_code(response)
message("Response status: ", status_code)

if (status_code == 200) {
  content <- httr::content(response, "text", encoding = "UTF-8")
  
  tryCatch({
    result <- jsonlite::fromJSON(content, flatten = TRUE)
    message("Success! Data structure:")
    str(result, max.level = 2)
    
    # Check for nested structures
    if (is.data.frame(result)) {
      message("\nColumn types:")
      col_types <- sapply(result, class)
      print(col_types)
      
      # Check for list columns
      list_cols <- names(result)[sapply(result, is.list)]
      if (length(list_cols) > 0) {
        message("\nList columns found: ", paste(list_cols, collapse = ", "))
        message("These need special handling for DuckDB")
      }
    }
    
  }, error = function(e) {
    message("Error: ", e$message)
  })
  
  # Show raw JSON structure (first 500 chars)
  message("\nRaw JSON (first 500 chars):")
  cat(substr(content, 1, 500))
  
} else {
  error_content <- httr::content(response, "text", encoding = "UTF-8")
  message("API Error: ", error_content)
}

autodeinit()

message("\n=== Test completed ===")