# run_single_model.R
#
# Run eWOM test for a single model. Usage:
#   Rscript run_single_model.R <model_name> [effort]
#
# Examples:
#   Rscript run_single_model.R gpt-4o-mini         # all 3 efforts
#   Rscript run_single_model.R gpt-4o-mini medium   # single effort
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

# Parse CLI args
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript run_single_model.R <model> [effort]")
model_name <- args[1]
efforts <- if (length(args) >= 2) args[2] else c("low", "medium", "high")

# Hardcoded eWOM test case
review_title <- "Love it"
review_body <- paste0(
  "Finally broke down and bought this electric can opener ",
  "after realizing my arthritis no longer allows me to ",
  "manually open anything\u2026 Pleasantly surprised with how ",
  "light weight it is as well as durable\u2026 And for the price ",
  "under $20 the quality of this is outstanding\u2026 Will recommend."
)
product_name <- "can_opener"

test_statements <- list(
  list(
    id = 1L,
    statement = paste0(
      "This review describes that the customer has ",
      "enthusiasm for exploring the new product."
    )
  ),
  list(
    id = 2L,
    statement = paste0(
      "This review shows that the customer has ",
      "offered a solution"
    )
  ),
  list(
    id = 3L,
    statement = paste0(
      "This review shows that the customer ",
      "aims to educate others."
    )
  ),
  list(
    id = 4L,
    statement = paste0(
      "This review expresses that the customer has ",
      "frustration over minor issues."
    )
  )
)

# Prompt builder (eWOM ver 2025.03.18)
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

system_instruction <- "Forget any previous information."

# Run
cat(sprintf("\n=== Running %s | efforts: %s ===\n\n",
            model_name, paste(efforts, collapse = ", ")))

results <- data.frame(
  statement_id = integer(), statement_short = character(),
  model = character(), effort = character(),
  actual_score = character(), elapsed_sec = numeric(),
  response = character(), stringsAsFactors = FALSE
)

for (tc in test_statements) {
  prompt_text <- build_ewom_prompt(
    product_name, review_title, review_body, tc$statement
  )
  stmt_short <- substr(tc$statement, 1, 50)

  for (e in efforts) {
    cat(sprintf("  S%d | %-14s | effort=%-6s ... ", tc$id, model_name, e))
    start_time <- Sys.time()

    tryCatch({
      # Use reasoning only for models that support it
      reasoning_param <- if (grepl("^(gpt-5|o[0-9])", model_name)) {
        list(effort = e)
      } else {
        NULL
      }

      resp <- response_api(
        input = prompt_text,
        api_key = api_key,
        model = model_name,
        instructions = system_instruction,
        reasoning = reasoning_param,
        temperature = NULL,
        return_full = FALSE
      )

      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      actual <- parse_score(resp)

      cat(sprintf("%5.1fs | score=%s | %s\n",
                  elapsed,
                  ifelse(is.na(actual), "NaN", actual),
                  substr(resp, 1, 80)))

      results <- rbind(results, data.frame(
        statement_id = tc$id, statement_short = stmt_short,
        model = model_name, effort = e,
        actual_score = ifelse(is.na(actual), "NaN", as.character(actual)),
        elapsed_sec = round(elapsed, 2),
        response = resp, stringsAsFactors = FALSE
      ))
    }, error = function(err) {
      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      cat(sprintf("%5.1fs | ERROR: %s\n", elapsed, err$message))
      results <<- rbind(results, data.frame(
        statement_id = tc$id, statement_short = stmt_short,
        model = model_name, effort = e,
        actual_score = "ERR", elapsed_sec = round(elapsed, 2),
        response = paste0("ERROR: ", err$message),
        stringsAsFactors = FALSE
      ))
    })
    Sys.sleep(0.3)
  }
}

# Save
output_path <- file.path(
  "scripts/global_scripts/98_test/test_model_comparison",
  paste0("results_", gsub("-", "", model_name), "_",
         format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
)
write.csv(results, output_path, row.names = FALSE)
cat(sprintf("\nSaved: %s\n", output_path))
