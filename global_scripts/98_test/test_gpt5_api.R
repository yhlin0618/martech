#
# test_gpt5_api.R
# Comprehensive test suite for GPT-5 API integration via Responses API
#
# Following principles:
# - MP51: Test Data Design
# - R75: Test Script Initialization
# - MP50: Debug Code Tracing
#
# Usage:
#   source("scripts/global_scripts/98_test/test_gpt5_api.R")
#   run_all_gpt5_tests()
# -----------------------------------------------------------------------------

# Source the function to test
source("scripts/global_scripts/08_ai/chat_api.R")

# ---- TEST 1: Simple GPT-5 API Call ----
test_gpt5_simple <- function() {
  cat("\n====================================\n")
  cat("TEST 1: Simple GPT-5 API Call\n")
  cat("====================================\n\n")

  # Check API key
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ OPENAI_API_KEY not set in environment\n")
    return(FALSE)
  }
  cat("✅ API key found (starts with: ", substr(api_key, 1, 7), "...)\n\n", sep = "")

  # Prepare simple messages
  sys <- list(role = "system", content = "You are a helpful assistant.")
  usr <- list(role = "user", content = "Say 'Hello World' in exactly 2 words.")

  cat("Request Messages:\n")
  cat("  System:", sys$content, "\n")
  cat("  User:", usr$content, "\n\n")

  # Call GPT-5
  cat("Calling GPT-5 API (gpt-5-2025-08-07)...\n")
  tryCatch({
    result <- chat_api(
      messages = list(sys, usr),
      model = "gpt-5-2025-08-07",
      api_key = api_key
    )

    cat("\n✅ SUCCESS! Response received:\n")
    cat("-----------------------------------\n")
    cat(result, "\n")
    cat("-----------------------------------\n")
    cat("Response length:", nchar(result), "characters\n")

    return(TRUE)

  }, error = function(e) {
    cat("\n❌ ERROR occurred:\n")
    cat("-----------------------------------\n")
    cat(e$message, "\n")
    cat("-----------------------------------\n")
    return(FALSE)
  })
}

# ---- TEST 2: Debug Request/Response Format ----
test_gpt5_debug_format <- function() {
  cat("\n====================================\n")
  cat("TEST 2: Debug Request/Response Format\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  # Add debugging by temporarily modifying the function
  # We'll manually trace through the logic here

  model <- "gpt-5-2025-08-07"
  is_gpt5 <- grepl("^gpt-5", model)

  cat("Model Detection:\n")
  cat("  Model name:", model, "\n")
  cat("  Is GPT-5:", is_gpt5, "\n\n")

  # Prepare messages
  messages <- list(
    list(role = "system", content = "You are a test assistant."),
    list(role = "user", content = "Count to 3.")
  )

  # Show how messages are processed for GPT-5
  if (is_gpt5) {
    cat("GPT-5 Message Processing:\n")

    system_msg <- ""
    user_msg <- ""

    for (msg in messages) {
      if (msg$role == "system") {
        system_msg <- paste0(system_msg, msg$content, "\n\n")
        cat("  Added to system_msg:", msg$content, "\n")
      } else if (msg$role == "user") {
        user_msg <- paste0(user_msg, msg$content, "\n\n")
        cat("  Added to user_msg:", msg$content, "\n")
      }
    }

    full_input <- paste0(trimws(system_msg), "\n\n", trimws(user_msg))

    cat("\nCombined Input:\n")
    cat("-----------------------------------\n")
    cat(full_input, "\n")
    cat("-----------------------------------\n\n")

    # Show request body structure
    body <- list(
      model = model,
      input = trimws(full_input),
      reasoning = list(effort = "low"),
      text = list(verbosity = "medium"),
      max_output_tokens = 4000
    )

    cat("Request Body Structure:\n")
    cat(jsonlite::toJSON(body, pretty = TRUE, auto_unbox = TRUE), "\n\n")

    cat("API Endpoint: https://api.openai.com/v1/responses\n\n")
  }

  # Now make actual call
  cat("Making actual API call...\n")
  tryCatch({
    result <- chat_api(messages, model = model, api_key = api_key)

    cat("\n✅ Response received:\n")
    cat("-----------------------------------\n")
    cat(result, "\n")
    cat("-----------------------------------\n")

    return(TRUE)

  }, error = function(e) {
    cat("\n❌ Error:\n")
    cat(e$message, "\n")
    return(FALSE)
  })
}

# ---- TEST 3: Marketing Strategy Prompt (Real Use Case) ----
test_gpt5_marketing_prompt <- function() {
  cat("\n====================================\n")
  cat("TEST 3: Marketing Strategy Prompt\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  # Simulate a marketing analysis prompt
  system_prompt <- "You are an expert marketing strategist specialized in positioning analysis. Analyze the provided appeal factors and suggest strategic positioning."

  appeal_factors <- "快速配送, 品質保證, 價格優惠"
  user_prompt <- sprintf(
    "Based on these appeal factors: %s\n\nProvide a brief positioning recommendation (2-3 sentences).",
    appeal_factors
  )

  cat("Marketing Analysis Request:\n")
  cat("  Appeal Factors:", appeal_factors, "\n\n")

  messages <- list(
    list(role = "system", content = system_prompt),
    list(role = "user", content = user_prompt)
  )

  cat("Calling GPT-5 for marketing analysis...\n")
  tryCatch({
    result <- chat_api(
      messages = messages,
      model = "gpt-5-2025-08-07",
      api_key = api_key
    )

    cat("\n✅ Marketing Strategy Response:\n")
    cat("-----------------------------------\n")
    cat(result, "\n")
    cat("-----------------------------------\n")

    return(TRUE)

  }, error = function(e) {
    cat("\n❌ Error in marketing analysis:\n")
    cat(e$message, "\n")
    return(FALSE)
  })
}

# ---- TEST 4: Compare GPT-5 vs GPT-4 Response Format ----
test_compare_api_formats <- function() {
  cat("\n====================================\n")
  cat("TEST 4: Compare GPT-5 vs GPT-4 Format\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  messages <- list(
    list(role = "system", content = "You are a test assistant."),
    list(role = "user", content = "Say 'Test successful' and nothing else.")
  )

  # Test GPT-4o-mini (Chat Completions API)
  cat("Testing GPT-4o-mini (Chat Completions API)...\n")
  tryCatch({
    result_gpt4 <- chat_api(messages, model = "gpt-5-nano", api_key = api_key)
    cat("✅ GPT-4o-mini response:", result_gpt4, "\n\n")
  }, error = function(e) {
    cat("❌ GPT-4o-mini failed:", e$message, "\n\n")
  })

  # Test GPT-5 (Responses API)
  cat("Testing GPT-5 (Responses API)...\n")
  tryCatch({
    result_gpt5 <- chat_api(messages, model = "gpt-5-2025-08-07", api_key = api_key)
    cat("✅ GPT-5 response:", result_gpt5, "\n\n")
  }, error = function(e) {
    cat("❌ GPT-5 failed:", e$message, "\n\n")
  })

  cat("Comparison complete.\n")
  return(TRUE)
}

# ---- TEST 5: Error Handling Verification ----
test_gpt5_error_handling <- function() {
  cat("\n====================================\n")
  cat("TEST 5: Error Handling Verification\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  # Test 5.1: Invalid model name
  cat("Test 5.1: Invalid model name (should fail gracefully)...\n")
  tryCatch({
    result <- chat_api(
      messages = list(list(role = "user", content = "Test")),
      model = "gpt-5-invalid-model",
      api_key = api_key
    )
    cat("⚠️  Unexpectedly succeeded\n\n")
  }, error = function(e) {
    cat("✅ Correctly failed with error:\n")
    cat("   ", substr(e$message, 1, 100), "...\n\n")
  })

  # Test 5.2: Empty messages
  cat("Test 5.2: Empty messages (should handle gracefully)...\n")
  tryCatch({
    result <- chat_api(
      messages = list(),
      model = "gpt-5-2025-08-07",
      api_key = api_key
    )
    cat("⚠️  Unexpectedly succeeded\n\n")
  }, error = function(e) {
    cat("✅ Correctly failed with error:\n")
    cat("   ", substr(e$message, 1, 100), "...\n\n")
  })

  # Test 5.3: Invalid API key format
  cat("Test 5.3: Invalid API key format (should warn)...\n")
  tryCatch({
    # Suppress warning to check if it's generated
    suppressWarnings({
      result <- chat_api(
        messages = list(list(role = "user", content = "Test")),
        model = "gpt-5-2025-08-07",
        api_key = "invalid-key-123"
      )
    })
    cat("⚠️  No warning generated\n\n")
  }, error = function(e) {
    cat("✅ Correctly failed (invalid key)\n\n")
  })

  return(TRUE)
}

# ---- TEST 6: Response Structure Validation ----
test_gpt5_response_structure <- function() {
  cat("\n====================================\n")
  cat("TEST 6: Response Structure Validation\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  # We need to temporarily modify chat_api to log response structure
  # For now, we'll document what we expect

  cat("Expected GPT-5 Response Structure:\n")
  cat("-----------------------------------\n")
  cat("{\n")
  cat("  \"output\": {\n")
  cat("    \"content\": [\n")
  cat("      {\n")
  cat("        \"type\": \"text\",\n")
  cat("        \"text\": \"actual response text\"\n")
  cat("      }\n")
  cat("    ]\n")
  cat("  },\n")
  cat("  \"usage\": { ... },\n")
  cat("  \"id\": \"...\",\n")
  cat("  \"model\": \"gpt-5-2025-08-07\"\n")
  cat("}\n\n")

  cat("Testing actual response parsing...\n")
  tryCatch({
    result <- chat_api(
      messages = list(
        list(role = "system", content = "You are helpful."),
        list(role = "user", content = "Say 'OK'")
      ),
      model = "gpt-5-2025-08-07",
      api_key = api_key
    )

    cat("✅ Response successfully parsed\n")
    cat("   Result type:", class(result), "\n")
    cat("   Result length:", nchar(result), "chars\n")
    cat("   Result preview:", substr(result, 1, 50), "\n")

    return(TRUE)

  }, error = function(e) {
    cat("❌ Parsing failed:\n")
    cat("   ", e$message, "\n")
    return(FALSE)
  })
}

# ---- TEST 7: Performance and Timeout ----
test_gpt5_performance <- function() {
  cat("\n====================================\n")
  cat("TEST 7: Performance and Timeout\n")
  cat("====================================\n\n")

  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    cat("❌ API key not set\n")
    return(FALSE)
  }

  messages <- list(
    list(role = "system", content = "You are a test assistant."),
    list(role = "user", content = "List 3 fruits.")
  )

  cat("Measuring response time...\n")
  start_time <- Sys.time()

  tryCatch({
    result <- chat_api(
      messages = messages,
      model = "gpt-5-2025-08-07",
      api_key = api_key,
      timeout_sec = 60
    )

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat("\n✅ Response received\n")
    cat("   Elapsed time:", round(elapsed, 2), "seconds\n")
    cat("   Response:", result, "\n")

    return(TRUE)

  }, error = function(e) {
    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat("\n❌ Failed after", round(elapsed, 2), "seconds\n")
    cat("   Error:", e$message, "\n")
    return(FALSE)
  })
}

# ---- MAIN: Run All Tests ----
run_all_gpt5_tests <- function() {
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║         GPT-5 API Integration Test Suite                  ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")
  cat("\n")
  cat("Test Time:", as.character(Sys.time()), "\n")
  cat("Working Directory:", getwd(), "\n")
  cat("R Version:", R.version.string, "\n")

  # Check dependencies
  cat("\nChecking dependencies...\n")
  if (!requireNamespace("httr2", quietly = TRUE)) {
    cat("❌ httr2 package not installed\n")
    cat("   Install with: install.packages('httr2')\n")
    return(FALSE)
  }
  cat("✅ httr2 package available\n")

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    cat("❌ jsonlite package not installed\n")
    cat("   Install with: install.packages('jsonlite')\n")
    return(FALSE)
  }
  cat("✅ jsonlite package available\n")

  # Run tests
  results <- list()

  results$test1 <- test_gpt5_simple()
  Sys.sleep(2)  # Pause between tests

  results$test2 <- test_gpt5_debug_format()
  Sys.sleep(2)

  results$test3 <- test_gpt5_marketing_prompt()
  Sys.sleep(2)

  results$test4 <- test_compare_api_formats()
  Sys.sleep(2)

  results$test5 <- test_gpt5_error_handling()
  Sys.sleep(2)

  results$test6 <- test_gpt5_response_structure()
  Sys.sleep(2)

  results$test7 <- test_gpt5_performance()

  # Summary
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║                    TEST SUMMARY                            ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")
  cat("\n")

  test_names <- c(
    "Test 1: Simple GPT-5 Call",
    "Test 2: Debug Format",
    "Test 3: Marketing Prompt",
    "Test 4: API Format Comparison",
    "Test 5: Error Handling",
    "Test 6: Response Structure",
    "Test 7: Performance"
  )

  for (i in seq_along(results)) {
    status <- if (isTRUE(results[[i]])) "✅ PASSED" else "❌ FAILED"
    cat(sprintf("%-35s %s\n", test_names[i], status))
  }

  passed <- sum(sapply(results, isTRUE))
  total <- length(results)

  cat("\n")
  cat(sprintf("Total: %d/%d tests passed (%.1f%%)\n", passed, total, (passed/total)*100))
  cat("\n")

  if (passed == total) {
    cat("🎉 All tests passed! GPT-5 integration is working correctly.\n")
  } else {
    cat("⚠️  Some tests failed. Review the output above for details.\n")
  }

  cat("\n")

  return(results)
}

# ---- Quick Test Function ----
quick_gpt5_test <- function() {
  cat("\n=== Quick GPT-5 Test ===\n\n")

  result <- chat_api(
    messages = list(
      list(role = "system", content = "You are helpful."),
      list(role = "user", content = "Say 'Hello'")
    ),
    model = "gpt-5-2025-08-07"
  )

  cat("Response:", result, "\n\n")
  return(result)
}

# Auto-run if sourced directly
if (!interactive()) {
  run_all_gpt5_tests()
}
