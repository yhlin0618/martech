# =============================================================================
# Setup Script for Amazon Scraping Environment
# This script helps set up the required environment for web scraping
# =============================================================================

cat("🔧 Setting up Amazon Scraping Environment\n")
cat("=", rep("=", 50), "\n")

# Check R version
cat("📊 R Version:", R.version.string, "\n")

# Required packages for scraping
required_packages <- c(
  "httr",      # HTTP requests
  "rvest",     # Web scraping
  "jsonlite",  # JSON handling
  "stringr",   # String manipulation
  "dplyr",     # Data manipulation
  "DT",        # Data tables
  "readr",     # Reading data
  "dotenv"     # Environment variables
)

# Function to check and install packages
setup_packages <- function(packages) {
  cat("📦 Checking and installing required packages...\n")
  
  for (package in packages) {
    cat("   Checking", package, "...")
    
    if (!require(package, character.only = TRUE, quietly = TRUE)) {
      cat(" Installing...\n")
      tryCatch({
        install.packages(package, dependencies = TRUE, quiet = TRUE)
        library(package, character.only = TRUE)
        cat("   ✅", package, "installed successfully\n")
      }, error = function(e) {
        cat("   ❌ Failed to install", package, ":", e$message, "\n")
      })
    } else {
      cat(" Already installed\n")
    }
  }
}

# Install packages
setup_packages(required_packages)

# Create .env file if it doesn't exist
env_file <- ".env"
if (!file.exists(env_file)) {
  cat("\n📝 Creating .env file...\n")
  env_content <- c(
    "# OpenAI API Configuration",
    "# Replace 'your_openai_api_key_here' with your actual OpenAI API key",
    "OPENAI_API_KEY_LIN=your_openai_api_key_here",
    "",
    "# Amazon Scraping Configuration",
    "USER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "",
    "# Optional: Proxy configuration (if needed)",
    "# PROXY_URL=http://your-proxy-server:port",
    "# PROXY_USERNAME=your_username",
    "# PROXY_PASSWORD=your_password"
  )
  writeLines(env_content, env_file)
  cat("✅ .env file created\n")
  cat("⚠️  IMPORTANT: Please edit .env file and add your OpenAI API key\n")
} else {
  cat("✅ .env file already exists\n")
}

# Test basic functionality
cat("\n🧪 Testing basic functionality...\n")

# Test HTTP request capability
tryCatch({
  test_response <- httr::GET("https://httpbin.org/get", httr::timeout(10))
  if (httr::status_code(test_response) == 200) {
    cat("✅ HTTP requests working\n")
  } else {
    cat("⚠️  HTTP requests may have issues\n")
  }
}, error = function(e) {
  cat("❌ HTTP requests failed:", e$message, "\n")
})

# Test JSON handling
tryCatch({
  test_json <- jsonlite::toJSON(list(test = "data"))
  parsed_json <- jsonlite::fromJSON(test_json)
  cat("✅ JSON handling working\n")
}, error = function(e) {
  cat("❌ JSON handling failed:", e$message, "\n")
})

# Test string manipulation
tryCatch({
  test_string <- "Hello World"
  result <- stringr::str_to_upper(test_string)
  if (result == "HELLO WORLD") {
    cat("✅ String manipulation working\n")
  } else {
    cat("⚠️  String manipulation may have issues\n")
  }
}, error = function(e) {
  cat("❌ String manipulation failed:", e$message, "\n")
})

cat("\n🎉 Setup completed!\n")
cat("\n📋 Next steps:\n")
cat("1. Edit .env file and add your OpenAI API key\n")
cat("2. Run scrapping_understanding_fixed.R\n")
cat("3. If you encounter Amazon blocking, consider using a proxy\n")
cat("\n💡 Tips:\n")
cat("- Amazon may block automated requests\n")
cat("- Consider using rotating proxies for production use\n")
cat("- Respect robots.txt and rate limits\n")
cat("- Test with different ASINs to verify functionality\n") 