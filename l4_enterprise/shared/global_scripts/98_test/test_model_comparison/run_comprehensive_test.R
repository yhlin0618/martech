# run_comprehensive_test.R
#
# Comprehensive eWOM model comparison with multiple reviews
# designed to cover the full score range (NaN, 1-5).
#
# 5 reviews x 4 statements = 20 test cases per model.
# 3 models x effort=medium = 60 API calls total.
#
# Usage: Rscript run_comprehensive_test.R
# ---------------------------------------------------------------------

library(glue)

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

# ==== 4 STATEMENTS (same as eWOM research) ====

statements <- list(
  list(id = "S1", text = paste0(
    "This review describes that the customer has ",
    "enthusiasm for exploring the new product."
  )),
  list(id = "S2", text = paste0(
    "This review shows that the customer has ",
    "offered a solution"
  )),
  list(id = "S3", text = paste0(
    "This review shows that the customer ",
    "aims to educate others."
  )),
  list(id = "S4", text = paste0(
    "This review expresses that the customer has ",
    "frustration over minor issues."
  ))
)

# ==== 5 REVIEWS (designed to span full score range) ====
#
# Claude Opus 4.6 expected scores per review x statement:
#
#   Review    S1   S2   S3   S4
#   A (orig)   2    4    3  NaN   <- necessity-driven positive
#   B (angry) NaN  NaN    3  NaN   <- major issues, not minor
#   C (edu)    4    5    5  NaN   <- systematic comparison
#   D (min)  NaN  NaN  NaN  NaN   <- zero information
#   E (mixed) NaN  NaN    3    4   <- minor annoyances

reviews <- list(
  list(
    id = "A",
    label = "necessity-driven positive",
    product = "can_opener",
    title = "Love it",
    body = paste0(
      "Finally broke down and bought this electric can opener ",
      "after realizing my arthritis no longer allows me to ",
      "manually open anything\u2026 Pleasantly surprised with how ",
      "light weight it is as well as durable\u2026 And for the price ",
      "under $20 the quality of this is outstanding\u2026 Will recommend."
    ),
    expected = c(S1 = "2", S2 = "4", S3 = "3", S4 = "NaN")
  ),
  list(
    id = "B",
    label = "angry major issues",
    product = "can_opener",
    title = "WORST PURCHASE EVER",
    body = paste0(
      "DO NOT BUY THIS. The motor died after one week. ",
      "The blade is dull and can barely cut through a can. ",
      "I cut my finger trying to manually finish what this ",
      "garbage started. Returning immediately for a refund. ",
      "Absolute waste of money."
    ),
    expected = c(S1 = "NaN", S2 = "NaN", S3 = "3", S4 = "NaN")
  ),
  list(
    id = "C",
    label = "educational comparison",
    product = "can_opener",
    title = "Detailed comparison after testing 3 models",
    body = paste0(
      "I have been comparing electric can openers for 6 months. ",
      "Here is what you need to know: (1) Look for models with ",
      "magnetic lid holders, they prevent lids from falling in ",
      "your food. (2) Rechargeable batteries last about 50 cans ",
      "per charge. (3) Side-cut is safer than top-cut. This model ",
      "does all three well. For reference I also tried Brand X ",
      "(too loud) and Brand Y (battery died fast). This one is the ",
      "clear winner for the price."
    ),
    expected = c(S1 = "4", S2 = "5", S3 = "5", S4 = "NaN")
  ),
  list(
    id = "D",
    label = "minimal zero-info",
    product = "can_opener",
    title = "ok",
    body = "It works.",
    expected = c(S1 = "NaN", S2 = "NaN", S3 = "NaN", S4 = "NaN")
  ),
  list(
    id = "E",
    label = "mixed minor annoyances",
    product = "can_opener",
    title = "Decent but a few small gripes",
    body = paste0(
      "Opens cans just fine and the motor is strong. However the ",
      "instruction manual is in tiny font and nearly impossible ",
      "to read, and the power button is a bit stiff. Also the lid ",
      "on the battery compartment does not close flush, which bugs ",
      "me. Small annoyances but overall it does the job for the price."
    ),
    expected = c(S1 = "NaN", S2 = "NaN", S3 = "3", S4 = "4")
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

parse_score <- function(response_text) {
  txt <- trimws(response_text)
  if (grepl("^\\[NaN", txt, ignore.case = TRUE)) return(NA_real_)
  m <- regmatches(txt, regexpr("^\\[[0-9]", txt))
  if (length(m) == 1) return(as.numeric(sub("^\\[", "", m)))
  NA_real_
}

match_score <- function(actual_str, expected_str) {
  if (expected_str == "NaN" && actual_str == "NaN") return("OK")
  if (expected_str == "NaN" || actual_str == "NaN") return("DIFF")
  a <- as.numeric(actual_str)
  e <- as.numeric(expected_str)
  if (is.na(a) || is.na(e)) return("DIFF")
  if (a == e) return("OK")
  if (abs(a - e) <= 1) return("~1")
  "DIFF"
}

system_instruction <- "Forget any previous information."

# ==== TEST MATRIX ====

models <- c("gpt-4o-mini", "gpt-5-nano", "gpt-5-mini")
effort <- "medium"

n_cases <- length(reviews) * length(statements)
n_calls <- n_cases * length(models)

cat("\n")
cat("=====================================================\n")
cat("  Comprehensive eWOM Model Comparison\n")
cat("=====================================================\n")
cat(sprintf("  Reviews:    %d\n", length(reviews)))
cat(sprintf("  Statements: %d\n", length(statements)))
cat(sprintf("  Models:     %s\n", paste(models, collapse = ", ")))
cat(sprintf("  Effort:     %s\n", effort))
cat(sprintf("  Total calls: %d\n", n_calls))
cat("=====================================================\n\n")

# ==== RUN ====

results <- data.frame(
  review_id = character(), review_label = character(),
  stmt_id = character(), model = character(),
  expected = character(), actual = character(),
  match = character(), elapsed_sec = numeric(),
  response = character(), stringsAsFactors = FALSE
)

for (rev in reviews) {
  cat(sprintf("--- Review %s: %s ---\n", rev$id, rev$label))

  for (stmt in statements) {
    prompt_text <- build_ewom_prompt(
      rev$product, rev$title, rev$body, stmt$text
    )
    exp <- rev$expected[[stmt$id]]

    for (m in models) {
      cat(sprintf("  %s-%s | %-14s ... ", rev$id, stmt$id, m))
      start_time <- Sys.time()

      tryCatch({
        reasoning_param <- if (grepl("^(gpt-5|o[0-9])", m)) {
          list(effort = effort)
        } else {
          NULL
        }

        resp <- response_api(
          input = prompt_text,
          api_key = api_key,
          model = m,
          instructions = system_instruction,
          reasoning = reasoning_param,
          temperature = NULL,
          return_full = FALSE
        )

        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        actual <- parse_score(resp)
        actual_str <- ifelse(is.na(actual), "NaN", as.character(actual))
        mflag <- match_score(actual_str, exp)

        cat(sprintf("%5.1fs | exp=%3s act=%3s %4s | %s\n",
          elapsed, exp, actual_str, mflag,
          substr(resp, 1, 60)
        ))

        results <- rbind(results, data.frame(
          review_id = rev$id, review_label = rev$label,
          stmt_id = stmt$id, model = m,
          expected = exp, actual = actual_str,
          match = mflag, elapsed_sec = round(elapsed, 2),
          response = resp, stringsAsFactors = FALSE
        ))
      }, error = function(err) {
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        cat(sprintf("%5.1fs | ERROR: %s\n", elapsed, err$message))
        results <<- rbind(results, data.frame(
          review_id = rev$id, review_label = rev$label,
          stmt_id = stmt$id, model = m,
          expected = exp, actual = "ERR",
          match = "ERR", elapsed_sec = round(elapsed, 2),
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

cat("=====================================================\n")
cat("  RESULTS SUMMARY\n")
cat("=====================================================\n\n")

for (m in models) {
  sub <- results[results$model == m, ]
  n <- nrow(sub)
  n_ok <- sum(sub$match == "OK")
  n_w1 <- sum(sub$match == "~1")
  n_diff <- sum(sub$match == "DIFF")
  avg_t <- round(mean(sub$elapsed_sec), 1)

  cat(sprintf("  %-14s  Exact=%2d/%d (%2d%%)  Within-1=%2d%%  Diff=%d  Avg=%.1fs\n",
    m, n_ok, n, round(100 * n_ok / n),
    round(100 * (n_ok + n_w1) / n), n_diff, avg_t
  ))
}

cat("\n--- Score Distribution (expected vs actual) ---\n")
cat(sprintf("  %-6s  %-5s  %-14s  %-14s  %-14s\n",
  "Case", "Exp", models[1], models[2], models[3]
))
for (i in seq_len(nrow(results) / length(models))) {
  idx <- ((i - 1) * length(models) + 1):(i * length(models))
  row1 <- results[idx[1], ]
  scores <- results$actual[idx]
  cat(sprintf("  %s-%-3s  %3s    %-14s  %-14s  %-14s\n",
    row1$review_id, row1$stmt_id, row1$expected,
    scores[1], scores[2], scores[3]
  ))
}

# ==== SAVE ====

output_path <- file.path(
  "scripts/global_scripts/98_test/test_model_comparison",
  paste0("results_comprehensive_",
    format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
)
write.csv(results, output_path, row.names = FALSE)
cat(sprintf("\nSaved: %s\n", output_path))
cat("\n========== TEST COMPLETE ==========\n")
