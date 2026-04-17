# =============================================================================
# Amazon Product Scraping and Feature Analysis Script
# Fixed version with comprehensive error handling and configuration
# =============================================================================

# Check if required packages are installed and install if needed
required_packages <- c("httr", "rvest", "jsonlite", "stringr", "dplyr", "DT", "readr", "dotenv")

# Function to install missing packages
install_if_missing <- function(packages) {
  for (package in packages) {
    if (!require(package, character.only = TRUE, quietly = TRUE)) {
      cat("Installing package:", package, "\n")
      install.packages(package, dependencies = TRUE)
      library(package, character.only = TRUE)
    } else {
      library(package, character.only = TRUE)
    }
  }
}

# Install and load required packages
tryCatch({
  install_if_missing(required_packages)
  cat("✅ All required packages loaded successfully\n")
}, error = function(e) {
  cat("❌ Error loading packages:", e$message, "\n")
  stop("Please install required packages manually")
})

# =============================================================================
# Configuration Section
# =============================================================================

# Check for .env file and create if missing
env_file <- ".env"
if (!file.exists(env_file)) {
  cat("📝 Creating .env file...\n")
  env_content <- "# OpenAI API Configuration\nOPENAI_API_KEY_LIN=your_openai_api_key_here\n\n# Amazon Scraping Configuration\nUSER_AGENT=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36\n"
  writeLines(env_content, env_file)
  cat("⚠️  Please edit .env file and add your OpenAI API key\n")
}

# Load environment variables
tryCatch({
  dotenv::load_dot_env(file = env_file)
  cat("✅ Environment variables loaded\n")
}, error = function(e) {
  cat("⚠️  Could not load .env file:", e$message, "\n")
})

# Configuration
asin <- "B07FVQLBL3"  # Amazon product ASIN
url <- paste0("https://www.amazon.com/dp/", asin)

# Get API key
gpt_api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
if (gpt_api_key == "" || gpt_api_key == "your_openai_api_key_here") {
  cat("❌ OpenAI API key not configured. Please set OPENAI_API_KEY_LIN in .env file\n")
  stop("API key required")
}

# =============================================================================
# Web Scraping Function with Error Handling
# =============================================================================

scrape_amazon_product <- function(asin) {
  cat("🔍 Scraping Amazon product:", asin, "\n")
  
  url <- paste0("https://www.amazon.com/dp/", asin)
  
  # Enhanced headers to avoid detection
  headers <- c(
    `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    `Accept-Language` = "en-US,en;q=0.5",
    `Accept-Encoding` = "gzip, deflate",
    `Connection` = "keep-alive",
    `Upgrade-Insecure-Requests` = "1"
  )
  
  tryCatch({
    # Make request with retry logic
    response <- NULL
    for (attempt in 1:3) {
      cat("   Attempt", attempt, "of 3...\n")
      
      response <- httr::GET(url, httr::add_headers(.headers = headers), 
                           httr::timeout(30))
      
      if (httr::status_code(response) == 200) {
        cat("   ✅ Successfully retrieved page\n")
        break
      } else {
        cat("   ⚠️  Attempt", attempt, "failed with status:", httr::status_code(response), "\n")
        if (attempt < 3) {
          Sys.sleep(2)  # Wait before retry
        }
      }
    }
    
    if (is.null(response) || httr::status_code(response) != 200) {
      stop("Failed to retrieve page after 3 attempts")
    }
    
    # Parse HTML
    page <- rvest::read_html(response)
    
    # Extract product information with error handling
    product_data <- list()
    
    # Product title
    title_node <- page %>% rvest::html_node("#productTitle")
    if (!is.na(title_node)) {
      product_data$title <- title_node %>% rvest::html_text(trim = TRUE)
    } else {
      product_data$title <- "Title not found"
      cat("   ⚠️  Could not find product title\n")
    }
    
    # Product features
    features_nodes <- page %>% rvest::html_nodes("#feature-bullets li span")
    if (length(features_nodes) > 0) {
      product_data$features <- features_nodes %>% 
        rvest::html_text(trim = TRUE) %>% 
        paste(collapse = "; ")
    } else {
      product_data$features <- "Features not found"
      cat("   ⚠️  Could not find product features\n")
    }
    
    # Product description
    desc_node <- page %>% rvest::html_node("#productDescription")
    if (!is.na(desc_node)) {
      product_data$description <- desc_node %>% rvest::html_text(trim = TRUE)
    } else {
      product_data$description <- "Description not found"
      cat("   ⚠️  Could not find product description\n")
    }
    
    # Product images
    img_nodes <- page %>% rvest::html_nodes("img")
    if (length(img_nodes) > 0) {
      img_links <- img_nodes %>% rvest::html_attr("src")
      product_data$images <- unique(img_links[stringr::str_detect(img_links, "media-amazon")])
    } else {
      product_data$images <- character(0)
      cat("   ⚠️  Could not find product images\n")
    }
    
    return(product_data)
    
  }, error = function(e) {
    cat("❌ Error scraping product:", e$message, "\n")
    return(NULL)
  })
}

# =============================================================================
# GPT API Function for Feature Analysis (FIXED)
# =============================================================================

analyze_features_with_gpt <- function(product_data, api_key) {
  cat("🤖 Analyzing features with GPT...\n")
  
  if (is.null(product_data)) {
    cat("❌ No product data to analyze\n")
    return(NULL)
  }
  
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
    model = "gpt-4",
    messages = list(
      list(role = "user", content = gpt_prompt)
    ),
    temperature = 0.1  # Low temperature for consistent output
  )

  tryCatch({
    # Make API request
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(Authorization = paste("Bearer", api_key)),
      httr::content_type_json(),
      body = body,
      encode = "json",
      httr::timeout(60)
    )
    
    if (httr::status_code(response) != 200) {
      stop(paste("API request failed with status:", httr::status_code(response)))
    }
    
    # Parse response with better error handling
    result <- httr::content(response, as = "text", encoding = "UTF-8")
    
    # Debug: Print raw response for troubleshooting
    cat("   🔍 Raw API response length:", nchar(result), "characters\n")
    
    # Parse JSON response
    parsed_response <- jsonlite::fromJSON(result)
    
    # Debug: Check response structure
    cat("   🔍 Response structure keys:", paste(names(parsed_response), collapse = ", "), "\n")
    
    # Check if response has expected structure
    if (!"choices" %in% names(parsed_response)) {
      stop("API response does not contain 'choices' field")
    }
    
    if (length(parsed_response$choices) == 0) {
      stop("API response has empty choices array")
    }
    
    if (!"message" %in% names(parsed_response$choices)) {
      stop("API response choice does not contain 'message' field")
    }
    
    if (!"content" %in% names(parsed_response$choices$message)) {
      stop("API response message does not contain 'content' field")
    }
    
    # Extract content safely

    json_output <- parsed_response$choices$message$content
    
    # Debug: Print extracted content
    cat("   🔍 Extracted content length:", nchar(json_output), "characters\n")
    cat("   🔍 Content preview:", substr(json_output, 1, 100), "...\n")
    
    cat("✅ Feature analysis completed\n")
    return(json_output)
    
  }, error = function(e) {
    cat("❌ Error calling GPT API:", e$message, "\n")
    
    # Additional debugging information
    if (exists("result")) {
      cat("   🔍 Raw response preview:", substr(result, 1, 200), "...\n")
    }
    
    return(NULL)
  })
}

# =============================================================================
# Main Execution
# =============================================================================

cat("🚀 Starting Amazon Product Scraping and Analysis\n")
cat("=", rep("=", 50), "\n")

# Step 1: Scrape product data
product_data <- scrape_amazon_product(asin)

if (!is.null(product_data)) {
  cat("\n📋 Product Information:\n")
  cat("Title:", product_data$title, "\n")
  cat("Features:", substr(product_data$features, 1, 100), "...\n")
  cat("Description:", substr(product_data$description, 1, 100), "...\n")
  cat("Images found:", length(product_data$images), "\n")
  
  # Step 2: Analyze features with GPT
  analysis_result <- analyze_features_with_gpt(product_data, gpt_api_key)
  
  if (!is.null(analysis_result)) {
    cat("\n🔍 Feature Analysis Results:\n")
    cat(analysis_result, "\n")
    
    # Try to parse JSON result
    tryCatch({
      parsed_result <- jsonlite::fromJSON(analysis_result)
      cat("\n📊 Parsed Features:\n")
      print(parsed_result)
    }, error = function(e) {
      cat("⚠️  Could not parse JSON result:", e$message, "\n")
      cat("   Raw result:", analysis_result, "\n")
    })
  }
} else {
  cat("❌ Failed to scrape product data\n")
}

cat("\n✅ Script execution completed\n") 
