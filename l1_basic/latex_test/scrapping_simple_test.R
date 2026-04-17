# =============================================================================
# Simple Test Script for GPT API Integration
# This script tests the GPT API call separately from web scraping
# =============================================================================

# Load required packages
library(httr)
library(jsonlite)
library(dotenv)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Get API key
gpt_api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
if (gpt_api_key == "" || gpt_api_key == "your_openai_api_key_here") {
  cat("❌ OpenAI API key not configured. Please set OPENAI_API_KEY_LIN in .env file\n")
  stop("API key required")
}

# Test product data (from your successful scrape)
test_product_data <- list(
  title = "Kitchen Mama Auto Electric Can Opener: Open Your Cans with A Simple Press of Button - Automatic, Hands Free, Smooth Edge, Battery Operated, YES YOU CAN (Red)",
  features = "Effortless Can Opening: Hands-free operation, smoothly opens cans with minimal effort; Easy Operation: Simple one-button operation",
  description = "Description not found"
)

# Simplified GPT API function
test_gpt_api <- function(product_data, api_key) {
  cat("🤖 Testing GPT API with simplified approach...\n")
  
  # Create prompt for GPT
  gpt_prompt <- paste0("
根據以下 Amazon 商品敘述與特色，請根據這些特徵進行 dummy coding，輸出為 JSON 格式，值為 0 或 1：

特徵：
1. 是否防水 (waterproof)
2. 是否具備藍牙 (bluetooth)
3. 是否內建電池 (battery included)
4. 是否為智慧裝置 (smart device)

商品標題：", product_data$title, "
商品特色：", product_data$features, "
商品描述：", product_data$description, "

請只回傳 JSON 格式，不要其他文字：
")

  # Prepare API request
  body <- list(
    model = "gpt-3.5-turbo",  # Using 3.5-turbo for faster response
    messages = list(
      list(role = "user", content = gpt_prompt)
    ),
    temperature = 0.1
  )

  tryCatch({
    cat("   📡 Making API request...\n")
    
    # Make API request
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(Authorization = paste("Bearer", api_key)),
      httr::content_type_json(),
      body = body,
      encode = "json",
      httr::timeout(60)
    )
    
    cat("   📊 Response status:", httr::status_code(response), "\n")
    
    if (httr::status_code(response) != 200) {
      error_content <- httr::content(response, as = "text")
      cat("   ❌ API Error Response:", error_content, "\n")
      stop(paste("API request failed with status:", httr::status_code(response)))
    }
    
    # Get response content
    result <- httr::content(response, as = "text", encoding = "UTF-8")
    cat("   📄 Raw response length:", nchar(result), "characters\n")
    
    # Parse JSON response
    parsed_response <- jsonlite::fromJSON(result)
    cat("   🔍 Response structure:", paste(names(parsed_response), collapse = ", "), "\n")
    
    # Extract content step by step
    if (is.null(parsed_response$choices) || length(parsed_response$choices) == 0) {
      stop("No choices in API response")
    }
    
    first_choice <- parsed_response$choices[[1]]
    cat("   🔍 First choice structure:", paste(names(first_choice), collapse = ", "), "\n")
    
    if (is.null(first_choice$message) || is.null(first_choice$message$content)) {
      stop("No message content in API response")
    }
    
    content <- first_choice$message$content
    cat("   ✅ Successfully extracted content\n")
    cat("   📝 Content preview:", substr(content, 1, 100), "...\n")
    
    return(content)
    
  }, error = function(e) {
    cat("❌ Error in GPT API call:", e$message, "\n")
    return(NULL)
  })
}

# Test the API
cat("🚀 Starting GPT API Test\n")
cat("=", rep("=", 50), "\n")

result <- test_gpt_api(test_product_data, gpt_api_key)

if (!is.null(result)) {
  cat("\n🔍 API Response:\n")
  cat(result, "\n")
  
  # Try to parse the JSON result
  tryCatch({
    parsed_result <- jsonlite::fromJSON(result)
    cat("\n📊 Parsed JSON Result:\n")
    print(parsed_result)
  }, error = function(e) {
    cat("\n⚠️  JSON parsing failed:", e$message, "\n")
    cat("Raw result:", result, "\n")
  })
} else {
  cat("\n❌ API test failed\n")
}

cat("\n✅ Test completed\n") 