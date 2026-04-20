# run_batch_scaling_test.R
#
# Test how gpt-5-nano and gpt-5-mini handle increasing batch sizes
# using Structured Outputs (JSON Schema) for eWOM rating.
#
# Design:
#   - 1 review (Review A) x 60 statements
#   - Batch sizes: 10, 20, 30, 40, 50, 60
#   - Models: gpt-5-nano, gpt-5-mini
#   - Efforts: low, medium, high
#   - Baseline: Claude Opus 4.6 expected scores
#   - Total: 6 x 2 x 3 = 36 API calls
#
# Usage: Rscript run_batch_scaling_test.R
# ---------------------------------------------------------------------

library(glue)
library(jsonlite)

source("scripts/global_scripts/08_ai/fn_response_api.R")

# Load .env
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
if (!nzchar(api_key)) stop("OPENAI_API_KEY not set.")

# ==== REVIEW ====

review_title <- "Love it"
review_body <- paste0(
  "Finally broke down and bought this electric can opener ",
  "after realizing my arthritis no longer allows me to ",
  "manually open anything\u2026 Pleasantly surprised with how ",
  "light weight it is as well as durable\u2026 And for the price ",
  "under $20 the quality of this is outstanding\u2026 Will recommend."
)
product_name <- "can_opener"

# ==== 60 STATEMENTS WITH CLAUDE OPUS 4.6 EXPECTED SCORES ====
# Score: 1-5 integer or NA (= null in JSON = NaN in original format)
#
# Design: cover full range with realistic eWOM dimensions.
# ~25% scored (15 statements), ~75% NaN (45 statements).
# This ratio is realistic: most dimensions don't apply to any given review.

stmts <- data.frame(
  id = 1:60,
  statement = c(
    # --- Scored: 5 (strong match) ---
    "This review shows satisfaction with the purchase price.",                  # 1: 5
    "This review indicates the customer found the product to be a good value.", # 2: 5
    # --- Scored: 4 (agree) ---
    "This review shows that the customer has offered a solution",              # 3: 4
    "This review shares personal health or lifestyle context.",                # 4: 4
    "This review expresses surprise or exceeded expectations.",                # 5: 4
    "This review discusses product accessibility for disabled users.",         # 6: 4
    # --- Scored: 3 (neutral/mild) ---
    "This review shows that the customer aims to educate others.",             # 7: 3
    "This review provides a brief description of product features.",           # 8: 3
    "This review recommends the product for a specific audience.",             # 9: 3
    "This review describes initial skepticism before purchase.",               # 10: 3
    "This review provides a comparative cost assessment.",                     # 11: 3
    "This review expresses mixed emotions about a necessity purchase.",        # 12: 3
    # --- Scored: 2 (disagree) ---
    "This review describes enthusiasm for exploring the new product.",         # 13: 2
    "This review shows emotional attachment to the product.",                  # 14: 2
    "This review provides specific quantitative data about the product.",      # 15: 2
    # --- NaN (not present at all) ---
    "This review expresses frustration over minor issues.",                    # 16
    "This review discusses willingness to repurchase the product.",            # 17
    "This review compares this product with other brands.",                    # 18
    "This review expresses concern about product durability.",                 # 19
    "This review describes impulse buying behavior.",                          # 20
    "This review acknowledges product limitations.",                           # 21
    "This review provides usage tips or advice.",                              # 22
    "This review demonstrates brand loyalty.",                                 # 23
    "This review discusses a return or exchange experience.",                  # 24
    "This review comments on packaging or presentation.",                      # 25
    "This review expresses environmental concerns.",                           # 26
    "This review exhibits social influence seeking behavior.",                 # 27
    "This review expresses gratitude toward the seller.",                      # 28
    "This review discusses product safety concerns.",                          # 29
    "This review shares experience with customer service.",                    # 30
    "This review provides a technical specifications review.",                 # 31
    "This review expresses concern about product authenticity.",               # 32
    "This review describes a gift-giving experience.",                         # 33
    "This review comments on shipping or delivery experience.",                # 34
    "This review expresses nostalgia or personal memories.",                   # 35
    "This review demonstrates expertise in the product category.",             # 36
    "This review acknowledges bias or disclosure of receiving a free product.",# 37
    "This review expresses frustration with false advertising.",               # 38
    "This review provides long-term usage feedback.",                          # 39
    "This review expresses concern about environmental impact.",               # 40
    "This review discusses product compatibility with other items.",           # 41
    "This review shares unexpected product uses.",                             # 42
    "This review expresses disappointment with customer support.",             # 43
    "This review seeks validation from other reviewers.",                      # 44
    "This review uses sarcasm or irony about the product.",                    # 45
    "This review provides a balanced pros and cons analysis.",                 # 46
    "This review discusses the product in cultural context.",                  # 47
    "This review shares a story about product failure.",                       # 48
    "This review compares online vs in-store purchase experience.",            # 49
    "This review expresses trust in the brand.",                               # 50
    "This review provides advice on product maintenance.",                     # 51
    "This review makes vague or ambiguous claims about quality.",              # 52
    "This review expresses passive-aggressive satisfaction.",                  # 53
    "This review uses humor to mask genuine complaints.",                      # 54
    "This review provides hearsay or secondhand information.",                 # 55
    "This review comments on product aesthetics.",                             # 56
    "This review discusses the influence of other reviews on purchase.",       # 57
    "This review expresses commitment to trying alternatives next time.",      # 58
    "This review shares a professional perspective on the product.",           # 59
    "This review expresses wishful thinking about product improvements."       # 60
  ),
  expected = c(
    5, 5,                                        # 1-2:  strong match
    4, 4, 4, 4,                                  # 3-6:  agree
    3, 3, 3, 3, 3, 3,                            # 7-12: neutral/mild
    2, 2, 2,                                     # 13-15: disagree
    rep(NA_integer_, 45)                         # 16-60: NaN
  ),
  stringsAsFactors = FALSE
)

# ==== JSON SCHEMA FOR STRUCTURED OUTPUT ====

build_json_schema <- function(n_items) {
  list(
    type = "json_schema",
    name = "ewom_batch_ratings",
    strict = TRUE,
    schema = list(
      type = "object",
      properties = list(
        ratings = list(
          type = "array",
          items = list(
            type = "object",
            properties = list(
              id = list(type = "integer"),
              score = list(
                type = I(c("integer", "null")),
                description = "1-5 Likert or null if not present"
              ),
              reason = list(type = "string")
            ),
            required = I(c("id", "score", "reason")),
            additionalProperties = FALSE
          )
        )
      ),
      required = I(c("ratings")),
      additionalProperties = FALSE
    )
  )
}

# ==== PROMPT BUILDER ====

build_batch_prompt <- function(product, title, body, stmt_subset) {
  stmt_lines <- paste(
    sprintf("%d. %s", stmt_subset$id, stmt_subset$statement),
    collapse = "\n"
  )

  glue(
    "The following is a comment on a {product} product:\n",
    "Title: '{title}'\n",
    "Body: '{body}'\n\n",
    "For each statement below, evaluate whether it is supported by the comment.\n",
    "Rules:\n",
    "1. If the comment does NOT demonstrate the stated characteristic ",
    "in any way, set score to null.\n",
    "2. If the comment demonstrates the stated characteristic to any degree, ",
    "rate your agreement from 1 to 5:\n",
    "   5 = Strongly Agree, 4 = Agree, 3 = Neither Agree nor Disagree, ",
    "2 = Disagree, 1 = Strongly Disagree\n",
    "3. Provide a brief reason for each rating.\n\n",
    "Statements:\n{stmt_lines}"
  )
}

# ==== PARSE STRUCTURED OUTPUT ====

parse_batch_response <- function(resp_text) {
  tryCatch({
    parsed <- fromJSON(resp_text, simplifyDataFrame = TRUE)
    if (!is.null(parsed$ratings)) {
      df <- parsed$ratings
      # Normalize score: JSON null -> NA
      df$score <- ifelse(is.na(df$score) | is.null(df$score), NA_integer_,
                         as.integer(df$score))
      return(df)
    }
    NULL
  }, error = function(e) {
    message("  JSON parse error: ", e$message)
    NULL
  })
}

# ==== SCORING ====

score_match <- function(actual, expected) {
  if (is.na(expected) && is.na(actual)) return("OK")
  if (is.na(expected) || is.na(actual)) return("DIFF")
  if (actual == expected) return("OK")
  if (abs(actual - expected) <= 1) return("~1")
  "DIFF"
}

# ==== TEST MATRIX ====

batch_sizes <- c(10, 20, 30, 40, 50, 60)
models <- c("gpt-5-nano", "gpt-5-mini")
efforts <- c("low", "medium", "high")
system_instruction <- "Forget any previous information."

n_calls <- length(batch_sizes) * length(models) * length(efforts)

cat("\n")
cat("=====================================================\n")
cat("  Batch Scaling Test: Structured Outputs\n")
cat("=====================================================\n")
cat(sprintf("  Batch sizes: %s\n", paste(batch_sizes, collapse = ", ")))
cat(sprintf("  Models:      %s\n", paste(models, collapse = ", ")))
cat(sprintf("  Efforts:     %s\n", paste(efforts, collapse = ", ")))
cat(sprintf("  Total calls: %d\n", n_calls))
cat("=====================================================\n\n")

# ==== RUN ====

results <- data.frame(
  batch_size = integer(), model = character(), effort = character(),
  n_exact = integer(), n_within1 = integer(), n_diff = integer(),
  n_nan_correct = integer(), n_nan_false_pos = integer(),
  n_scored_items = integer(),
  pct_exact = numeric(), pct_within1 = numeric(),
  nan_recall = numeric(),
  elapsed_sec = numeric(), sec_per_stmt = numeric(),
  stringsAsFactors = FALSE
)

detail_rows <- list()

for (bs in batch_sizes) {
  stmt_subset <- stmts[1:bs, ]
  prompt_text <- build_batch_prompt(
    product_name, review_title, review_body, stmt_subset
  )
  json_schema <- build_json_schema(bs)

  for (m in models) {
    for (e in efforts) {
      cat(sprintf("  batch=%2d | %-14s | effort=%-6s ... ", bs, m, e))
      start_time <- Sys.time()

      tryCatch({
        resp <- response_api(
          input = prompt_text,
          api_key = api_key,
          model = m,
          instructions = system_instruction,
          reasoning = list(effort = e),
          text = list(format = json_schema),
          temperature = NULL,
          timeout_sec = 600,
          return_full = FALSE
        )

        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

        parsed <- parse_batch_response(resp)

        if (is.null(parsed) || nrow(parsed) < bs) {
          cat(sprintf("%5.1fs | PARSE_FAIL (got %d/%d items)\n",
            elapsed,
            if (is.null(parsed)) 0 else nrow(parsed),
            bs
          ))
          results <- rbind(results, data.frame(
            batch_size = bs, model = m, effort = e,
            n_exact = NA, n_within1 = NA, n_diff = NA,
            n_nan_correct = NA, n_nan_false_pos = NA,
            n_scored_items = NA,
            pct_exact = NA, pct_within1 = NA,
            nan_recall = NA,
            elapsed_sec = round(elapsed, 2),
            sec_per_stmt = round(elapsed / bs, 2),
            stringsAsFactors = FALSE
          ))
          next
        }

        # Match scores to expected
        matches <- character(bs)
        for (i in seq_len(bs)) {
          actual <- parsed$score[parsed$id == i]
          if (length(actual) == 0) actual <- NA
          expected <- stmt_subset$expected[i]
          matches[i] <- score_match(actual, expected)
        }

        # NaN analysis
        nan_expected <- is.na(stmt_subset$expected)
        nan_actual <- is.na(parsed$score[match(1:bs, parsed$id)])
        n_nan_correct <- sum(nan_expected & nan_actual)
        n_nan_false_pos <- sum(nan_expected & !nan_actual)
        nan_recall <- if (sum(nan_expected) > 0) {
          round(n_nan_correct / sum(nan_expected), 3)
        } else { 1.0 }

        n_exact <- sum(matches == "OK")
        n_w1 <- sum(matches == "~1")
        n_diff <- sum(matches == "DIFF")
        n_scored <- sum(!nan_expected)

        cat(sprintf(
          "%5.1fs | Exact=%2d/%d (%2.0f%%) ~1=%2.0f%% NaN_recall=%.0f%% | %.2fs/stmt\n",
          elapsed, n_exact, bs, 100 * n_exact / bs,
          100 * (n_exact + n_w1) / bs,
          100 * nan_recall,
          elapsed / bs
        ))

        results <- rbind(results, data.frame(
          batch_size = bs, model = m, effort = e,
          n_exact = n_exact, n_within1 = n_w1, n_diff = n_diff,
          n_nan_correct = n_nan_correct,
          n_nan_false_pos = n_nan_false_pos,
          n_scored_items = n_scored,
          pct_exact = round(100 * n_exact / bs, 1),
          pct_within1 = round(100 * (n_exact + n_w1) / bs, 1),
          nan_recall = round(100 * nan_recall, 1),
          elapsed_sec = round(elapsed, 2),
          sec_per_stmt = round(elapsed / bs, 3),
          stringsAsFactors = FALSE
        ))

        # Save detailed scores
        for (i in seq_len(bs)) {
          actual <- parsed$score[parsed$id == i]
          if (length(actual) == 0) actual <- NA
          reason <- parsed$reason[parsed$id == i]
          if (length(reason) == 0) reason <- ""
          detail_rows[[length(detail_rows) + 1]] <- data.frame(
            batch_size = bs, model = m, effort = e,
            stmt_id = i,
            expected = ifelse(is.na(stmt_subset$expected[i]),
                              "null", stmt_subset$expected[i]),
            actual = ifelse(is.na(actual), "null", actual),
            match = matches[i],
            reason = substr(reason, 1, 80),
            stringsAsFactors = FALSE
          )
        }

      }, error = function(err) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        cat(sprintf("%5.1fs | ERROR: %s\n", elapsed, substr(err$message, 1, 80)))
        results <<- rbind(results, data.frame(
          batch_size = bs, model = m, effort = e,
          n_exact = NA, n_within1 = NA, n_diff = NA,
          n_nan_correct = NA, n_nan_false_pos = NA,
          n_scored_items = NA,
          pct_exact = NA, pct_within1 = NA,
          nan_recall = NA,
          elapsed_sec = round(elapsed, 2),
          sec_per_stmt = round(elapsed / bs, 2),
          stringsAsFactors = FALSE
        ))
      })
      Sys.sleep(0.5)
    }
  }
  cat("\n")
}

# ==== SUMMARY ====

cat("=====================================================\n")
cat("  SCALING SUMMARY\n")
cat("=====================================================\n\n")

cat(sprintf("  %-6s  %-14s  %-6s  %6s  %6s  %8s  %6s  %8s\n",
  "Batch", "Model", "Effort", "Exact%", "~1%", "NaN_Rec%", "Time", "s/stmt"
))
cat(sprintf("  %-6s  %-14s  %-6s  %6s  %6s  %8s  %6s  %8s\n",
  "-----", "-----------", "------", "------", "------", "--------",
  "------", "------"
))
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  cat(sprintf("  %4d    %-14s  %-6s  %5.1f%%  %5.1f%%  %6.1f%%  %5.1fs  %5.3fs\n",
    r$batch_size, r$model, r$effort,
    r$pct_exact, r$pct_within1, r$nan_recall,
    r$elapsed_sec, r$sec_per_stmt
  ))
}

# Cross-model comparison by batch size
cat("\n--- Model Comparison by Batch Size (effort=medium) ---\n")
med <- results[results$effort == "medium", ]
for (bs in batch_sizes) {
  sub <- med[med$batch_size == bs, ]
  cat(sprintf("  Batch %2d:", bs))
  for (i in seq_len(nrow(sub))) {
    r <- sub[i, ]
    cat(sprintf("  %s: Exact=%2.0f%% ~1=%2.0f%% NaN=%.0f%%",
      r$model, r$pct_exact, r$pct_within1, r$nan_recall
    ))
  }
  cat("\n")
}

# ==== SAVE ====

ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
output_dir <- "scripts/global_scripts/98_test/test_model_comparison"

write.csv(results,
  file.path(output_dir, paste0("results_batch_scaling_", ts, ".csv")),
  row.names = FALSE)

details <- do.call(rbind, detail_rows)
write.csv(details,
  file.path(output_dir, paste0("results_batch_detail_", ts, ".csv")),
  row.names = FALSE)

cat(sprintf("\nSaved: results_batch_scaling_%s.csv\n", ts))
cat(sprintf("Saved: results_batch_detail_%s.csv\n", ts))
cat("\n========== BATCH SCALING TEST COMPLETE ==========\n")
