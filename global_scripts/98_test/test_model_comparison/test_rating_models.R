# test_rating_models.R
#
# Compare OpenAI models for eWOM review rating task using hardcoded
# test cases with known expected outputs (baseline: o3-mini).
#
# Uses response_api() from fn_response_api.R (unified API wrapper).
#
# Following principles:
# - MP029: No fake data (uses real eWOM research examples)
# - MP081: Explicit Parameter Specification
# - MP123: AI Prompt Configuration Management
# ---------------------------------------------------------------------

# ==== INITIALIZE ====
library(glue)

source(
  "scripts/global_scripts/08_ai/fn_response_api.R"
)

# Load API key from .env (R-native, no shell source)
load_dotenv <- function(path = ".env") {
  if (!file.exists(path)) return(invisible(NULL))
  lines <- readLines(path, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos < 1) next
    key <- trimws(substr(line, 1, eq_pos - 1))
    val <- trimws(substr(line, eq_pos + 1, nchar(line)))
    do.call(Sys.setenv, stats::setNames(list(val), key))
  }
}
load_dotenv()

api_key <- Sys.getenv("OPENAI_API_KEY")
if (!nzchar(api_key)) stop("OPENAI_API_KEY not set. Check .env file.")

# ==== HARDCODED eWOM TEST CASES ====
# From original eWOM research (can_opener product).
# Expected outputs are baseline results from o3-mini.

review_title <- "Love it"
review_body <- paste0(
  "Finally broke down and bought this electric can opener ",
  "after realizing my arthritis no longer allows me to ",
  "manually open anything\u2026 Pleasantly surprised with how ",
  "light weight it is as well as durable\u2026 And for the price ",
  "under $20 the quality of this is outstanding\u2026 Will recommend."
)
product_name <- "can_opener"

# Test statements with expected scores (from o3-mini baseline)
test_statements <- list(
  list(
    statement = paste0(
      "This review describes that the customer has ",
      "enthusiasm for exploring the new product."
    ),
    expected_score = 3,
    expected_note = "satisfaction-driven, not exploration"
  ),
  list(
    statement = paste0(
      "This review shows that the customer has ",
      "offered a solution"
    ),
    expected_score = 4,
    expected_note = "found solution to arthritis difficulty"
  ),
  list(
    statement = paste0(
      "This review shows that the customer ",
      "aims to educate others."
    ),
    expected_score = 3,
    expected_note = "recommendation but not instructional"
  ),
  list(
    statement = paste0(
      "This review expresses that the customer has ",
      "frustration over minor issues."
    ),
    expected_score = NA,
    expected_note = "no frustration; expected [NaN,NaN]"
  )
)

# ==== PROMPT BUILDER (eWOM ver 2025.03.18) ====

build_ewom_prompt <- function(product, title, body, statement) {
  double_check <- paste0(
    "** Please double check that 'If the comment does not ",
    "demonstrate the stated characteristic in any way, reply ",
    "exactly [NaN,NaN] without additional reasoning or ",
    "explanation.'"
  )
  glue(
    "The following is a comment on a {product} product:\n",
    "Title: '{title}'\n",
    "Body: '{body}'\n",
    "Evaluate whether the statement '{statement}' is supported ",
    "by the comment. Use the following rules to respond:\n",
    "1. If the comment does not demonstrate the stated ",
    "characteristic in any way, reply exactly [NaN,NaN] ",
    "without additional reasoning or explanation.\n",
    "2. If the comment demonstrates the stated characteristic ",
    "to any degree:\n",
    "    Rate your agreement with the statement on a scale ",
    "from 1 to 5:\n",
    "    - '5' for Strongly Agree\n",
    "    - '4' for Agree\n",
    "    - '3' for Neither Agree nor Disagree\n",
    "    - '2' for Disagree\n",
    "    - '1' for Strongly Disagree\n",
    "Provide your rationale in the format: [Score, Reason].\n",
    "{double_check}\n",
    "{double_check}\n",
    "{double_check}"
  )
}

system_instruction <- "Forget any previous information."

# ==== PARSE HELPER ====

parse_score <- function(response_text) {
  txt <- trimws(response_text)
  if (grepl("^\\[NaN", txt, ignore.case = TRUE)) return(NA_real_)
  m <- regmatches(txt, regexpr("^\\[[0-9]", txt))
  if (length(m) == 1) return(as.numeric(sub("^\\[", "", m)))
  NA_real_
}

# ==== TEST MATRIX ====

models <- c("gpt-5-nano", "gpt-5-mini")
efforts <- c("low", "medium", "high")

cat("\n")
cat("========================================\n")
cat("  eWOM Model Comparison Test\n")
cat("========================================\n")
cat(sprintf("  Product: %s\n", product_name))
cat(sprintf("  Review:  \"%s\"\n", review_title))
cat(sprintf("  Models:  %s\n", paste(models, collapse = ", ")))
cat(sprintf("  Efforts: %s\n", paste(efforts, collapse = ", ")))
cat(sprintf("  Statements: %d\n", length(test_statements)))
cat("========================================\n\n")

# ==== RUN COMPARISONS ====

results <- data.frame(
  statement_id = integer(),
  statement_short = character(),
  expected_score = character(),
  model = character(),
  effort = character(),
  actual_score = character(),
  match = character(),
  elapsed_sec = numeric(),
  response = character(),
  stringsAsFactors = FALSE
)

for (si in seq_along(test_statements)) {
  tc <- test_statements[[si]]
  stmt_short <- substr(tc$statement, 1, 50)

  prompt_text <- build_ewom_prompt(
    product = product_name,
    title = review_title,
    body = review_body,
    statement = tc$statement
  )

  cat(sprintf(
    "--- Statement %d: \"%s...\" ---\n",
    si, substr(tc$statement, 40, 75)
  ))
  cat(sprintf(
    "    Expected: %s (%s)\n",
    ifelse(is.na(tc$expected_score), "NaN", tc$expected_score),
    tc$expected_note
  ))

  for (m in models) {
    for (e in efforts) {
      cat(sprintf("    %s | effort=%-6s ... ", m, e))

      start_time <- Sys.time()

      tryCatch({
        resp <- response_api(
          input = prompt_text,
          api_key = api_key,
          model = m,
          instructions = system_instruction,
          reasoning = list(effort = e),
          temperature = NULL,
          return_full = FALSE
        )

        elapsed <- as.numeric(
          difftime(Sys.time(), start_time, units = "secs")
        )

        actual <- parse_score(resp)
        expected <- tc$expected_score
        match_flag <- if (is.na(expected) && is.na(actual)) {
          "OK"
        } else if (!is.na(expected) && !is.na(actual) &&
                   expected == actual) {
          "OK"
        } else if (!is.na(expected) && !is.na(actual) &&
                   abs(expected - actual) <= 1) {
          "~1"
        } else {
          "DIFF"
        }

        cat(sprintf(
          "%5.1fs | score=%s | %s | %s\n",
          elapsed,
          ifelse(is.na(actual), "NaN", actual),
          match_flag,
          substr(resp, 1, 80)
        ))

        results <- rbind(results, data.frame(
          statement_id = si,
          statement_short = stmt_short,
          expected_score = ifelse(
            is.na(tc$expected_score), "NaN",
            as.character(tc$expected_score)
          ),
          model = m,
          effort = e,
          actual_score = ifelse(is.na(actual), "NaN",
                                as.character(actual)),
          match = match_flag,
          elapsed_sec = round(elapsed, 2),
          response = resp,
          stringsAsFactors = FALSE
        ))
      }, error = function(err) {
        elapsed <- as.numeric(
          difftime(Sys.time(), start_time, units = "secs")
        )
        cat(sprintf(
          "%5.1fs | ERROR: %s\n",
          elapsed, err$message
        ))
        results <<- rbind(results, data.frame(
          statement_id = si,
          statement_short = stmt_short,
          expected_score = ifelse(
            is.na(tc$expected_score), "NaN",
            as.character(tc$expected_score)
          ),
          model = m,
          effort = e,
          actual_score = "ERR",
          match = "ERR",
          elapsed_sec = round(elapsed, 2),
          response = paste0("ERROR: ", err$message),
          stringsAsFactors = FALSE
        ))
      })

      Sys.sleep(0.3)
    }
  }
  cat("\n")
}

# ==== SUMMARY ====

cat("\n========================================\n")
cat("  RESULTS SUMMARY\n")
cat("========================================\n\n")

cat("--- Score Comparison Table ---\n")
summary_cols <- c(
  "statement_id", "model", "effort",
  "expected_score", "actual_score", "match", "elapsed_sec"
)
print(results[, summary_cols], row.names = FALSE)

cat("\n--- Match Statistics ---\n")
n_total <- nrow(results)
n_ok <- sum(results$match == "OK")
n_close <- sum(results$match == "~1")
n_diff <- sum(results$match == "DIFF")
n_err <- sum(results$match == "ERR")
cat(sprintf(
  "  Total: %d | Exact: %d | Within-1: %d | Diff: %d | Error: %d\n",
  n_total, n_ok, n_close, n_diff, n_err
))
cat(sprintf(
  "  Accuracy (exact): %.0f%% | Accuracy (within-1): %.0f%%\n",
  100 * n_ok / n_total,
  100 * (n_ok + n_close) / n_total
))

# ==== SAVE RESULTS ====

output_path <- file.path(
  "scripts/global_scripts/98_test/test_model_comparison",
  paste0(
    "results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv"
  )
)
write.csv(results, output_path, row.names = FALSE)
cat(sprintf("\nResults saved to: %s\n", output_path))

cat("\n========== TEST COMPLETE ==========\n")
