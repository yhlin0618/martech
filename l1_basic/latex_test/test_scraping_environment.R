# =============================================================================
# Test Script for Scraping Environment
# This script tests the environment without actually scraping Amazon
# =============================================================================

cat("🧪 Testing Scraping Environment\n")
cat("=", rep("=", 50), "\n")

# Test 1: Check R and packages
cat("📊 R Version:", R.version.string, "\n")

required_packages <- c("httr", "rvest", "jsonlite", "stringr", "dplyr", "DT", "readr", "dotenv")
missing_packages <- c()

for (package in required_packages) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    missing_packages <- c(missing_packages, package)
  }
}

if (length(missing_packages) > 0) {
  cat("❌ Missing packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("   Run setup_scraping_environment.R to install missing packages\n")
} else {
  cat("✅ All required packages are available\n")
}

# Test 2: Check .env file
env_file <- ".env"
if (file.exists(env_file)) {
  cat("✅ .env file exists\n")
  
  # Check API key
  dotenv::load_dot_env(file = env_file)
  api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
  
  if (api_key == "" || api_key == "your_openai_api_key_here") {
    cat("⚠️  OpenAI API key not configured in .env file\n")
  } else {
    cat("✅ OpenAI API key is configured\n")
  }
} else {
  cat("❌ .env file not found\n")
  cat("   Run setup_scraping_environment.R to create .env file\n")
}

# Test 3: Test HTTP connectivity
cat("\n🌐 Testing HTTP connectivity...\n")
tryCatch({
  test_response <- httr::GET("https://httpbin.org/get", httr::timeout(10))
  if (httr::status_code(test_response) == 200) {
    cat("✅ HTTP requests working\n")
  } else {
    cat("⚠️  HTTP requests returned status:", httr::status_code(test_response), "\n")
  }
}, error = function(e) {
  cat("❌ HTTP requests failed:", e$message, "\n")
})

# Test 4: Test JSON handling
cat("\n📄 Testing JSON handling...\n")
tryCatch({
  test_data <- list(
    waterproof = 0,
    bluetooth = 1,
    battery_included = 1,
    smart_device = 0
  )
  json_string <- jsonlite::toJSON(test_data, auto_unbox = TRUE)
  parsed_data <- jsonlite::fromJSON(json_string)
  
  if (identical(test_data, parsed_data)) {
    cat("✅ JSON handling working correctly\n")
  } else {
    cat("⚠️  JSON handling may have issues\n")
  }
}, error = function(e) {
  cat("❌ JSON handling failed:", e$message, "\n")
})

# Test 5: Test string manipulation
cat("\n🔤 Testing string manipulation...\n")
tryCatch({
  test_string <- "Hello World"
  upper_string <- stringr::str_to_upper(test_string)
  lower_string <- stringr::str_to_lower(test_string)
  
  if (upper_string == "HELLO WORLD" && lower_string == "hello world") {
    cat("✅ String manipulation working correctly\n")
  } else {
    cat("⚠️  String manipulation may have issues\n")
  }
}, error = function(e) {
  cat("❌ String manipulation failed:", e$message, "\n")
})

# Test 6: Test HTML parsing (with a simple test)
cat("\n🔍 Testing HTML parsing...\n")
tryCatch({
  test_html <- "<html><body><h1>Test Title</h1><p>Test content</p></body></html>"
  parsed_html <- rvest::read_html(test_html)
  
  title <- parsed_html %>% rvest::html_node("h1") %>% rvest::html_text()
  content <- parsed_html %>% rvest::html_node("p") %>% rvest::html_text()
  
  if (title == "Test Title" && content == "Test content") {
    cat("✅ HTML parsing working correctly\n")
  } else {
    cat("⚠️  HTML parsing may have issues\n")
  }
}, error = function(e) {
  cat("❌ HTML parsing failed:", e$message, "\n")
})

# Test 7: Test OpenAI API (if key is configured)
api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
if (api_key != "" && api_key != "your_openai_api_key_here") {
  cat("\n🤖 Testing OpenAI API...\n")
  tryCatch({
    test_body <- list(
      model = "gpt-3.5-turbo",
      messages = list(
        list(role = "user", content = "Say 'Hello World'")
      ),
      max_tokens = 10
    )
    
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(Authorization = paste("Bearer", api_key)),
      httr::content_type_json(),
      body = test_body,
      encode = "json",
      httr::timeout(30)
    )
    
    if (httr::status_code(response) == 200) {
      cat("✅ OpenAI API working correctly\n")
    } else {
      cat("⚠️  OpenAI API returned status:", httr::status_code(response), "\n")
      cat("   Response:", httr::content(response, as = "text"), "\n")
    }
  }, error = function(e) {
    cat("❌ OpenAI API test failed:", e$message, "\n")
  })
} else {
  cat("\n🤖 Skipping OpenAI API test (no valid API key)\n")
}

# Summary
cat("\n" + rep("=", 50), "\n")
cat("📋 Environment Test Summary\n")
cat("=", rep("=", 50), "\n")

if (length(missing_packages) == 0 && file.exists(env_file)) {
  cat("✅ Environment appears to be ready for scraping\n")
  cat("   You can now run: scrapping_understanding_fixed.R\n")
} else {
  cat("⚠️  Environment needs setup\n")
  cat("   Run: setup_scraping_environment.R\n")
}

cat("\n💡 Tips:\n")
cat("- If you see any ❌ errors, fix them before running the main script\n")
cat("- Make sure your OpenAI API key is valid and has credits\n")
cat("- Amazon may block automated requests - this is normal\n")
cat("- Consider using a VPN or proxy for production scraping\n") 

