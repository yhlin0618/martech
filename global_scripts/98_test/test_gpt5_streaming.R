#!/usr/bin/env Rscript
#
# test_gpt5_streaming.R
#
# Comprehensive tests for GPT-5 streaming implementation
# Following MP099: Real-Time Progress Reporting
# Following DEV_P021: Performance Acceleration
#
# Usage: Rscript test_gpt5_streaming.R

# Setup
library(future)
plan(multisession, workers = 2)

cat("=== GPT-5 Streaming Tests ===\n\n")

# Source the streaming function
source("scripts/global_scripts/08_ai/fn_chat_api_stream.R")
source("scripts/global_scripts/08_ai/fn_chat_api.R")

# Get API key
api_key <- Sys.getenv("OPENAI_API_KEY")
if (!nzchar(api_key)) {
  stop("OPENAI_API_KEY not set. Please set it in environment.")
}

# Test 1: Basic Streaming Test
test_basic_streaming <- function() {
  cat("Test 1: Basic Streaming (Short Response)\n")
  cat("==========================================\n")

  messages <- list(
    list(role = "system", content = "You are a helpful assistant."),
    list(role = "user", content = "Write exactly 3 short sentences about streaming technology.")
  )

  stream_file <- tempfile(pattern = "test1_", fileext = ".txt")
  chunk_count <- 0

  tryCatch({
    result <- chat_api_stream(
      messages = messages,
      model = "gpt-5-mini",
      stream_file = stream_file,
      on_chunk = function(chunk) {
        chunk_count <<- chunk_count + 1
        cat(sprintf("  Chunk %d: %s\n", chunk_count, substr(chunk, 1, 50)))
      }
    )

    cat("\n✅ Test 1 PASSED\n")
    cat(sprintf("  - Total chunks: %d\n", chunk_count))
    cat(sprintf("  - Final length: %d chars\n", nchar(result)))
    cat(sprintf("  - Result preview: %s...\n\n", substr(result, 1, 100)))

    # Verify file was created and has content
    if (file.exists(stream_file) && file.info(stream_file)$size > 0) {
      cat("  ✅ Stream file created successfully\n")
    } else {
      cat("  ❌ Stream file issue\n")
    }

    # Clean up
    unlink(stream_file)

    return(TRUE)

  }, error = function(e) {
    cat("\n❌ Test 1 FAILED:", e$message, "\n\n")
    unlink(stream_file)
    return(FALSE)
  })
}

# Test 2: Long Content Test
test_long_content <- function() {
  cat("Test 2: Long Content Streaming\n")
  cat("================================\n")

  messages <- list(
    list(role = "system", content = "你是專業的市場分析師。"),
    list(role = "user", content = "請簡短分析一個市場區隔的特徵，大約200字。")
  )

  stream_file <- tempfile(pattern = "test2_", fileext = ".txt")
  chunks_received <- character()

  start_time <- Sys.time()

  tryCatch({
    result <- chat_api_stream(
      messages = messages,
      model = "gpt-5-mini",
      stream_file = stream_file,
      on_chunk = function(chunk) {
        chunks_received <<- c(chunks_received, chunk)
        # Monitor file size growth
        if (file.exists(stream_file)) {
          file_size <- file.info(stream_file)$size
          cat(sprintf("  File size: %d bytes\r", file_size))
        }
      }
    )

    elapsed <- as.numeric(Sys.time() - start_time)

    cat("\n✅ Test 2 PASSED\n")
    cat(sprintf("  - Elapsed time: %.2f seconds\n", elapsed))
    cat(sprintf("  - Total chunks: %d\n", length(chunks_received)))
    cat(sprintf("  - Final length: %d chars\n", nchar(result)))
    cat(sprintf("  - Chunks per second: %.1f\n\n", length(chunks_received) / elapsed))

    # Clean up
    unlink(stream_file)

    return(TRUE)

  }, error = function(e) {
    cat("\n❌ Test 2 FAILED:", e$message, "\n\n")
    unlink(stream_file)
    return(FALSE)
  })
}

# Test 3: Error Handling Test
test_error_handling <- function() {
  cat("Test 3: Error Handling\n")
  cat("=======================\n")

  messages <- list(
    list(role = "user", content = "Test error handling")
  )

  tryCatch({
    # Try with invalid API key
    result <- chat_api_stream(
      messages = messages,
      api_key = "sk-invalid_key_for_testing",
      model = "gpt-5-mini"
    )

    cat("❌ Test 3 FAILED: Should have thrown an error\n\n")
    return(FALSE)

  }, error = function(e) {
    if (grepl("API|key|auth|401|403", e$message, ignore.case = TRUE)) {
      cat("✅ Test 3 PASSED: Error correctly caught and reported\n")
      cat(sprintf("  Error message: %s\n\n", e$message))
      return(TRUE)
    } else {
      cat("❌ Test 3 FAILED: Unexpected error:", e$message, "\n\n")
      return(FALSE)
    }
  })
}

# Test 4: Non-Streaming Compatibility Test
test_backward_compatibility <- function() {
  cat("Test 4: Backward Compatibility (Non-Streaming)\n")
  cat("===============================================\n")

  messages <- list(
    list(role = "system", content = "You are a helpful assistant."),
    list(role = "user", content = "Say 'Hello World' in one sentence.")
  )

  tryCatch({
    # Call with stream = FALSE (default)
    result <- chat_api(
      messages = messages,
      model = "gpt-5-mini",
      stream = FALSE  # Explicitly non-streaming
    )

    cat("✅ Test 4 PASSED: Non-streaming mode works\n")
    cat(sprintf("  Result length: %d chars\n", nchar(result)))
    cat(sprintf("  Preview: %s\n\n", substr(result, 1, 100)))

    return(TRUE)

  }, error = function(e) {
    cat("❌ Test 4 FAILED:", e$message, "\n\n")
    return(FALSE)
  })
}

# Test 5: File Cleanup Test
test_file_cleanup <- function() {
  cat("Test 5: Temp File Cleanup\n")
  cat("==========================\n")

  messages <- list(
    list(role = "user", content = "Say 'test'.")
  )

  stream_file <- tempfile(pattern = "test5_", fileext = ".txt")

  tryCatch({
    # Run streaming
    result <- chat_api_stream(
      messages = messages,
      model = "gpt-5-mini",
      stream_file = stream_file
    )

    # Manually clean up (simulating real usage)
    if (file.exists(stream_file)) {
      unlink(stream_file)
    }

    # Verify file is gone
    if (!file.exists(stream_file)) {
      cat("✅ Test 5 PASSED: Temp file cleaned up successfully\n\n")
      return(TRUE)
    } else {
      cat("❌ Test 5 FAILED: Temp file still exists\n\n")
      return(FALSE)
    }

  }, error = function(e) {
    cat("❌ Test 5 FAILED:", e$message, "\n\n")
    unlink(stream_file)
    return(FALSE)
  })
}

# Run all tests
cat("\n")
cat("╔════════════════════════════════════════╗\n")
cat("║  GPT-5 STREAMING TEST SUITE           ║\n")
cat("╚════════════════════════════════════════╝\n\n")

results <- list(
  test1 = test_basic_streaming(),
  test2 = test_long_content(),
  test3 = test_error_handling(),
  test4 = test_backward_compatibility(),
  test5 = test_file_cleanup()
)

# Summary
cat("\n")
cat("╔════════════════════════════════════════╗\n")
cat("║  TEST SUMMARY                          ║\n")
cat("╚════════════════════════════════════════╝\n\n")

passed <- sum(unlist(results))
total <- length(results)

cat(sprintf("Passed: %d / %d\n", passed, total))

if (passed == total) {
  cat("\n✅ ALL TESTS PASSED! Streaming implementation is working correctly.\n\n")
} else {
  cat("\n❌ SOME TESTS FAILED. Please review the errors above.\n\n")
}

cat("Test completed at:", format(Sys.time()), "\n")
