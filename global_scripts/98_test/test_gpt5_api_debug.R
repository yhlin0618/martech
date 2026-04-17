#
# test_gpt5_api_debug.R
# Deep debugging for GPT-5 response structure
#
# Usage: source("scripts/global_scripts/98_test/test_gpt5_api_debug.R")
# -----------------------------------------------------------------------------

# Test with full response logging
test_gpt5_raw_response <- function() {
  cat("\n====================================\n")
  cat("DEEP DEBUG: GPT-5 Raw Response\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(NULL)
  }

  library(httr2)
  library(jsonlite)

  # Prepare request
  model <- "gpt-5-2025-08-07"
  full_input <- "You are a helpful assistant.\n\nSay 'Hello World' in exactly 2 words."

  body <- list(
    model = model,
    input = trimws(full_input),
    reasoning = list(effort = "low"),
    text = list(verbosity = "medium"),
    max_output_tokens = 4000
  )

  api_url <- "https://api.openai.com/v1/responses"

  cat("Sending request to:", api_url, "\n")
  cat("Model:", model, "\n\n")

  cat("Request Body:\n")
  cat("-----------------------------------\n")
  cat(jsonlite::toJSON(body, pretty = TRUE, auto_unbox = TRUE), "\n")
  cat("-----------------------------------\n\n")

  # Make request
  req <- httr2::request(api_url) |>
    httr2::req_auth_bearer_token(api_key) |>
    httr2::req_headers(`Content-Type` = "application/json") |>
    httr2::req_body_json(body) |>
    httr2::req_timeout(60)

  cat("Executing request...\n")
  resp <- httr2::req_perform(req)

  # Check status
  status <- httr2::resp_status(resp)
  cat("Response Status:", status, "\n\n")

  if (status >= 400) {
    cat("❌ HTTP Error\n")
    cat("Response Body:\n")
    cat(httr2::resp_body_string(resp), "\n")
    return(NULL)
  }

  # Parse response
  cat("✅ Response received successfully\n\n")

  content <- httr2::resp_body_json(resp)

  cat("Response Structure Analysis:\n")
  cat("-----------------------------------\n")
  cat("Top-level keys:", paste(names(content), collapse = ", "), "\n\n")

  # Check each key
  for (key in names(content)) {
    cat("Key '", key, "':\n", sep = "")
    cat("  Type:", class(content[[key]]), "\n")

    if (is.list(content[[key]]) && !is.null(names(content[[key]]))) {
      cat("  Sub-keys:", paste(names(content[[key]]), collapse = ", "), "\n")
    }

    if (key == "output" && !is.null(content$output$content)) {
      cat("  output$content type:", class(content$output$content), "\n")
      cat("  output$content length:", length(content$output$content), "\n")

      if (length(content$output$content) > 0) {
        cat("  First content item keys:", paste(names(content$output$content[[1]]), collapse = ", "), "\n")
      }
    }

    cat("\n")
  }

  cat("-----------------------------------\n\n")

  # Pretty print full response
  cat("Full JSON Response:\n")
  cat("-----------------------------------\n")
  cat(jsonlite::toJSON(content, pretty = TRUE, auto_unbox = TRUE), "\n")
  cat("-----------------------------------\n\n")

  # Try to extract text
  cat("Attempting text extraction...\n")

  if (!is.null(content$output) && !is.null(content$output$content)) {
    cat("✅ content$output$content exists\n")

    if (length(content$output$content) > 0) {
      cat("✅ Content array has", length(content$output$content), "item(s)\n")

      # Check first item
      first_item <- content$output$content[[1]]
      cat("First item keys:", paste(names(first_item), collapse = ", "), "\n")

      if (!is.null(first_item$text)) {
        cat("✅ first_item$text exists:\n")
        cat("   '", first_item$text, "'\n", sep = "")
      } else {
        cat("❌ first_item$text is NULL\n")
        cat("First item structure:\n")
        print(str(first_item))
      }

    } else {
      cat("❌ Content array is empty\n")
    }

  } else {
    cat("❌ content$output or content$output$content is NULL\n")

    if (!is.null(content$output)) {
      cat("content$output keys:", paste(names(content$output), collapse = ", "), "\n")
    }
  }

  return(content)
}

# Test with curl for comparison
test_gpt5_curl_comparison <- function() {
  cat("\n====================================\n")
  cat("CURL Comparison Test\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(NULL)
  }

  # Create temp file for request body
  request_body <- '{
  "model": "gpt-5-2025-08-07",
  "input": "You are a helpful assistant.\\n\\nSay Hello World in exactly 2 words.",
  "reasoning": {"effort": "low"},
  "text": {"verbosity": "medium"},
  "max_output_tokens": 4000
}'

  tmp_file <- tempfile(fileext = ".json")
  writeLines(request_body, tmp_file)

  cat("Request body saved to:", tmp_file, "\n\n")
  cat("Testing with curl...\n")

  # Use curl to test
  curl_cmd <- sprintf(
    'curl -s -w "\\nHTTP_STATUS:%%{http_code}" https://api.openai.com/v1/responses -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d @%s',
    api_key,
    tmp_file
  )

  cat("Executing curl command...\n\n")

  result <- system(curl_cmd, intern = TRUE)

  cat("Curl Response:\n")
  cat("-----------------------------------\n")
  cat(paste(result, collapse = "\n"), "\n")
  cat("-----------------------------------\n\n")

  # Clean up
  unlink(tmp_file)

  return(result)
}

# Run all debug tests
run_debug_tests <- function() {
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║         GPT-5 Response Structure Debug                    ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")
  cat("\n")

  # Test 1: Raw response structure
  response <- test_gpt5_raw_response()

  # Wait between tests
  Sys.sleep(2)

  # Test 2: Curl comparison
  curl_result <- test_gpt5_curl_comparison()

  cat("\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║                    DEBUG COMPLETE                          ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")
  cat("\n")

  return(list(
    response = response,
    curl = curl_result
  ))
}

# Auto-run if sourced
if (!interactive()) {
  run_debug_tests()
}
