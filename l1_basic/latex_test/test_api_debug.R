# =============================================================================
# API Debug Test
# Purpose: Test API key loading and basic connectivity
# =============================================================================

# Load required packages
library(dotenv)
library(httr)
library(jsonlite)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Check API key
api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
cat("API Key loaded:", ifelse(api_key != "", "YES", "NO"), "\n")
cat("API Key length:", nchar(api_key), "\n")
cat("API Key starts with 'sk-':", grepl("^sk-", api_key), "\n")

# Test basic API connectivity
if (api_key != "" && grepl("^sk-", api_key)) {
  cat("\nTesting API connectivity...\n")
  
  tryCatch({
    response <- httr::GET(
      url = "https://api.openai.com/v1/models",
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key)
      ),
      httr::timeout(30)
    )
    
    if (response$status_code == 200) {
      cat("✓ API connection successful\n")
      models <- jsonlite::fromJSON(rawToChar(response$content))
      cat("Available models:", length(models$data), "\n")
    } else {
      cat("✗ API connection failed with status:", response$status_code, "\n")
      error_detail <- jsonlite::fromJSON(rawToChar(response$content))
      cat("Error:", error_detail$error$message, "\n")
    }
  }, error = function(e) {
    cat("✗ API connection error:", e$message, "\n")
  })
} else {
  cat("✗ Invalid API key format\n")
}

# Test environment variables
cat("\nAll environment variables:\n")
env_vars <- Sys.getenv()
openai_vars <- env_vars[grepl("OPENAI", names(env_vars))]
for (var in names(openai_vars)) {
  cat(var, ":", ifelse(openai_vars[var] != "", "SET", "NOT SET"), "\n")
} 