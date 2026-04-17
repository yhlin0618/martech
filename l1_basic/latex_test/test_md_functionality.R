# =============================================================================
# Test Markdown Functionality
# Purpose: Test the markdown generation and PDF compilation functionality
# =============================================================================

# Load required packages
library(dotenv)
library(dplyr)
library(httr)
library(jsonlite)
library(rmarkdown)
library(markdown)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Test GPT API connection
test_gpt_connection <- function() {
  cat("Testing GPT API connection...\n")
  
  api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
  if (is.null(api_key) || api_key == "") {
    cat("✗ API key not found in environment variables\n")
    return(FALSE)
  }
  
  # Simple test call
  response <- httr::POST(
    url = "https://api.openai.com/v1/chat/completions",
    httr::add_headers(
      "Authorization" = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ),
    body = jsonlite::toJSON(list(
      model = "gpt-3.5-turbo",
      messages = list(
        list(role = "user", content = "Say 'Hello World'")
      ),
      max_tokens = 10
    ), auto_unbox = TRUE),
    timeout(10)
  )
  
  if (httr::status_code(response) == 200) {
    cat("✓ GPT API connection successful\n")
    return(TRUE)
  } else {
    cat("✗ GPT API connection failed:", httr::status_code(response), "\n")
    return(FALSE)
  }
}

# Test markdown generation
test_markdown_generation <- function() {
  cat("\nTesting markdown generation...\n")
  
  # Sample data
  data_summary <- "Total Revenue: $15,000\nAverage Transaction: $300\nUnique Customers: 10\nTotal Transactions: 50"
  
  report_config <- list(
    title = "Test Report",
    author = "Test User",
    date = "2025-01-27",
    include_summary = TRUE,
    include_charts = FALSE,
    include_recommendations = TRUE
  )
  
  # Call GPT function (from the app)
  call_gpt_for_markdown <- function(data_summary, report_config) {
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    if (is.null(api_key) || api_key == "") {
      stop("OpenAI API key not found in environment variables")
    }
    
    prompt <- paste0(
      "Generate a professional Markdown report based on the following data and requirements:\n\n",
      "Data Summary:\n",
      data_summary, "\n\n",
      "Report Configuration:\n",
      "- Title: ", report_config$title, "\n",
      "- Author: ", report_config$author, "\n",
      "- Date: ", report_config$date, "\n",
      "- Include Summary: ", report_config$include_summary, "\n",
      "- Include Charts: ", report_config$include_charts, "\n",
      "- Include Recommendations: ", report_config$include_recommendations, "\n\n",
      "Requirements:\n",
      "1. Use proper Markdown syntax\n",
      "2. Include headers, lists, and formatting\n",
      "3. Make it professional and readable\n",
      "4. Include data insights and analysis\n",
      "5. If charts are requested, include placeholders with descriptions\n",
      "6. If recommendations are requested, provide actionable insights\n\n",
      "Generate only the Markdown content, no additional text."
    )
    
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = jsonlite::toJSON(list(
        model = "gpt-3.5-turbo",
        messages = list(
          list(role = "system", content = "You are a professional data analyst who creates clear, well-formatted Markdown reports."),
          list(role = "user", content = prompt)
        ),
        max_tokens = 1000,
        temperature = 0.7
      ), auto_unbox = TRUE),
      timeout(30)
    )
    
    if (httr::status_code(response) == 200) {
      result <- jsonlite::fromJSON(httr::content(response, "text"))
      return(result$choices$message$content)
    } else {
      error_msg <- paste("API call failed:", httr::status_code(response))
      cat(error_msg, "\n")
      return(NULL)
    }
  }
  
  markdown_content <- call_gpt_for_markdown(data_summary, report_config)
  
  if (!is.null(markdown_content)) {
    cat("✓ Markdown generated successfully\n")
    cat("Content length:", nchar(markdown_content), "characters\n")
    cat("First 200 characters:\n")
    cat(substr(markdown_content, 1, 200), "...\n")
    return(markdown_content)
  } else {
    cat("✗ Markdown generation failed\n")
    return(NULL)
  }
}

# Test PDF compilation
test_pdf_compilation <- function(markdown_content) {
  if (is.null(markdown_content)) {
    cat("\nSkipping PDF compilation test (no markdown content)\n")
    return(FALSE)
  }
  
  cat("\nTesting PDF compilation...\n")
  
  tryCatch({
    # Create test markdown file
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    md_file <- file.path("test_reports", paste0("test_md_", timestamp, ".md"))
    pdf_file <- file.path("test_reports", paste0("test_md_", timestamp, ".pdf"))
    
    # Ensure directory exists
    if (!dir.exists("test_reports")) {
      dir.create("test_reports", recursive = TRUE)
    }
    
    # Write markdown content
    writeLines(markdown_content, md_file)
    cat("✓ Markdown file created:", md_file, "\n")
    
    # Compile to PDF
    rmarkdown::render(
      input = md_file,
      output_format = "pdf_document",
      output_file = pdf_file,
      quiet = TRUE
    )
    
    if (file.exists(pdf_file)) {
      file_size <- file.size(pdf_file)
      cat("✓ PDF compiled successfully:", pdf_file, "\n")
      cat("PDF file size:", file_size, "bytes\n")
      
      # Clean up
      file.remove(md_file, pdf_file)
      return(TRUE)
    } else {
      cat("✗ PDF compilation failed - file not created\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("✗ PDF compilation error:", e$message, "\n")
    return(FALSE)
  })
}

# Test markdown preview
test_markdown_preview <- function(markdown_content) {
  if (is.null(markdown_content)) {
    cat("\nSkipping markdown preview test (no content)\n")
    return(FALSE)
  }
  
  cat("\nTesting markdown preview...\n")
  
  tryCatch({
    html_content <- markdown::renderMarkdown(text = markdown_content)
    cat("✓ Markdown preview generated successfully\n")
    cat("HTML content length:", nchar(html_content), "characters\n")
    return(TRUE)
  }, error = function(e) {
    cat("✗ Markdown preview error:", e$message, "\n")
    return(FALSE)
  })
}

# Run all tests
main_test <- function() {
  cat("=== Markdown App Functionality Test ===\n\n")
  
  # Test 1: GPT API connection
  api_ok <- test_gpt_connection()
  
  # Test 2: Markdown generation
  markdown_content <- NULL
  if (api_ok) {
    markdown_content <- test_markdown_generation()
  } else {
    cat("\nSkipping markdown generation due to API failure\n")
  }
  
  # Test 3: Markdown preview
  test_markdown_preview(markdown_content)
  
  # Test 4: PDF compilation
  test_pdf_compilation(markdown_content)
  
  cat("\n=== Test Summary ===\n")
  cat("API Connection:", ifelse(api_ok, "✓ PASS", "✗ FAIL"), "\n")
  cat("Markdown Generation:", ifelse(!is.null(markdown_content), "✓ PASS", "✗ FAIL"), "\n")
  cat("PDF Compilation: Tested\n")
  cat("Markdown Preview: Tested\n")
  
  cat("\nTo run the full app, use: runApp('test_md_app.R')\n")
}

# Run the test
main_test() 