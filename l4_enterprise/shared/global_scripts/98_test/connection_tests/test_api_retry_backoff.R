#!/usr/bin/env Rscript
# Test script for fn_api_retry_backoff.R (Spectra change
# fix-mamba-etl-complete-capture, issue #378)
#
# Verifies the three scenarios from spec
# `mamba-etl-complete-source-capture`, requirement
# "ETL Scripts SHALL Use Shared API Retry Backoff Helper":
#
#   1. Transient HTTP 429 → retry with exponential backoff, eventually succeed
#   2. Non-retryable HTTP 401 → abort immediately, no retry
#   3. Retries exhausted on persistent HTTP 500 → abort after max_retries + 1
#
# Run from project root:
#   Rscript shared/global_scripts/98_test/connection_tests/test_api_retry_backoff.R

# ----------------------------------------------------------------------------
# Locate and source the helper
# ----------------------------------------------------------------------------
candidate_global_dirs <- c(
  "shared/global_scripts",
  file.path("scripts", "global_scripts"),
  file.path("..", "global_scripts")
)
gs_dir <- candidate_global_dirs[dir.exists(candidate_global_dirs)][1]
if (is.na(gs_dir)) {
  stop("[test] Cannot locate global_scripts directory")
}
source(file.path(gs_dir, "26_platform_apis", "fn_api_retry_backoff.R"))

# ----------------------------------------------------------------------------
# Build a fake httr-like error carrying a status code
# ----------------------------------------------------------------------------
fake_httr_error <- function(status) {
  # Mimic the structure `httr::status_code(e$response)` inspects.
  response_obj <- structure(list(status_code = status), class = "response")
  err <- structure(
    list(
      message  = sprintf("HTTP %d from fake backend", status),
      response = response_obj,
      call     = sys.call()
    ),
    class = c("simpleError", "error", "condition")
  )
  err
}

# ----------------------------------------------------------------------------
# Test 1 — Transient 429 then success
# ----------------------------------------------------------------------------
message("=== Test 1: Transient 429, succeed on 2nd attempt ===")
attempts_t1 <- 0
fn_t1 <- function() {
  attempts_t1 <<- attempts_t1 + 1
  if (attempts_t1 == 1) stop(fake_httr_error(429))
  list(status = "ok", attempts = attempts_t1)
}
res_t1 <- api_call_with_retry(fn_t1, max_retries = 5, base_delay = 0.05,
                              backoff_factor = 2)
stopifnot(res_t1$status == "ok")
stopifnot(res_t1$attempts == 2)
stopifnot(attempts_t1 == 2)
message("PASS: 2 attempts (1 retry), result status=ok\n")

# ----------------------------------------------------------------------------
# Test 2 — Non-retryable 401 aborts immediately
# ----------------------------------------------------------------------------
message("=== Test 2: Non-retryable 401 aborts immediately ===")
attempts_t2 <- 0
fn_t2 <- function() {
  attempts_t2 <<- attempts_t2 + 1
  stop(fake_httr_error(401))
}
tryCatch(
  {
    api_call_with_retry(fn_t2, max_retries = 5, base_delay = 0.05)
    stop("[test FAIL] expected abort on 401, got success")
  },
  error = function(e) {
    stopifnot(grepl("401", e$message))
  }
)
stopifnot(attempts_t2 == 1)
message("PASS: aborted after 1 attempt on 401\n")

# ----------------------------------------------------------------------------
# Test 3 — Retries exhausted on persistent 500
# ----------------------------------------------------------------------------
message("=== Test 3: Persistent 500 exhausts retries ===")
attempts_t3 <- 0
fn_t3 <- function() {
  attempts_t3 <<- attempts_t3 + 1
  stop(fake_httr_error(500))
}
tryCatch(
  {
    api_call_with_retry(fn_t3, max_retries = 2, base_delay = 0.05)
    stop("[test FAIL] expected abort on exhausted retries")
  },
  error = function(e) {
    stopifnot(grepl("500", e$message))
  }
)
stopifnot(attempts_t3 == 3)  # 1 initial + 2 retries
message(sprintf("PASS: aborted after %d attempts (1 initial + max_retries=2)\n",
                attempts_t3))

# ----------------------------------------------------------------------------
# Test 4 — Success on first attempt (no retry needed)
# ----------------------------------------------------------------------------
message("=== Test 4: Success on first attempt ===")
fn_t4 <- function() list(status = "ok", attempts = 1)
res_t4 <- api_call_with_retry(fn_t4)
stopifnot(res_t4$status == "ok")
message("PASS: first attempt returned success\n")

message("=== ALL TESTS PASSED ===")
