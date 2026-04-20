#!/usr/bin/env Rscript

# Test: fn_load_product_lines no-fallback behaviour (DM_R054 v2.1 §6 + §7)
#
# Driving `Decision 2: fn_load_product_lines gains stop() with actionable
# message, no fallback` from spectra change `dm-r054-v2-migration-complete`
# (issue #424). Written BEFORE the fn_load_product_lines.R refactor per TDD.
#
# Run: Rscript shared/global_scripts/98_test/general/test_fn_load_product_lines_no_fallback.R

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
})

# Locate repo root (this file lives at shared/global_scripts/98_test/general/)
this_file <- tryCatch(
  normalizePath(sys.frames()[[1]]$ofile %||% commandArgs(trailingOnly = FALSE)[4],
                mustWork = FALSE),
  error = function(e) NA_character_
)
if (!is.na(this_file) && nzchar(this_file)) {
  repo_root <- normalizePath(file.path(dirname(this_file), "..", "..", "..", ".."))
} else {
  repo_root <- getwd()
}

source_file <- file.path(repo_root, "shared", "global_scripts", "04_utils",
                         "fn_load_product_lines.R")
if (!file.exists(source_file)) {
  # Fallback — relative to cwd (e.g., when run from a company dir via symlink)
  candidates <- c(
    file.path("shared", "global_scripts", "04_utils", "fn_load_product_lines.R"),
    file.path("scripts", "global_scripts", "04_utils", "fn_load_product_lines.R")
  )
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) == 0) {
    stop("Cannot locate fn_load_product_lines.R. Run this test from repo root ",
         "(l4_enterprise/) or a company directory with scripts/global_scripts symlink.")
  }
  source_file <- candidates[1]
}

# Provide a minimal read_csvxlsx stub if not loaded (helper expects it).
if (!exists("read_csvxlsx", mode = "function")) {
  read_csvxlsx <- function(path, ...) {
    if (grepl("\\.csv$", path, ignore.case = TRUE)) {
      utils::read.csv(path, stringsAsFactors = FALSE)
    } else {
      stop("read_csvxlsx stub: only .csv handled in this test")
    }
  }
}

# `%||%` is base-R only in R >= 4.4; define locally for older R.
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(a, b) if (is.null(a)) b else a
}

source(source_file)

# --- Test fixtures ----------------------------------------------------------

tmpdir <- tempfile("fn_load_test_")
dir.create(tmpdir, recursive = TRUE)
on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)

missing_meta  <- file.path(tmpdir, "meta_data_does_not_exist.duckdb")
missing_csv   <- file.path(tmpdir, "df_product_line_does_not_exist.csv")
sqlite_conn   <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
on.exit(try(DBI::dbDisconnect(sqlite_conn, shutdown = TRUE), silent = TRUE), add = TRUE)

expect <- function(label, ok, detail = "") {
  status <- if (isTRUE(ok)) "PASS" else "FAIL"
  msg <- sprintf("[%s] %s%s", status, label,
                 if (nzchar(detail)) paste0(" — ", detail) else "")
  message(msg)
  invisible(isTRUE(ok))
}

results <- list()

# --- Test 1: meta_data.duckdb missing → must stop() with actionable message

test1 <- tryCatch(
  {
    load_product_lines(
      conn = sqlite_conn,
      meta_data_path = missing_meta,
      csv_path       = missing_csv
    )
    list(raised = FALSE, msg = "(no error raised)")
  },
  error = function(e) list(raised = TRUE, msg = conditionMessage(e))
)

results$meta_missing_raises <- expect(
  "meta_data.duckdb missing → stop() raised",
  isTRUE(test1$raised),
  test1$msg
)
results$meta_missing_mentions_bootstrap <- expect(
  "stop() message names the bootstrap ETL (actionable)",
  isTRUE(test1$raised) &&
    grepl("all_ETL_meta_init_0IM", test1$msg, fixed = TRUE),
  substr(test1$msg, 1, 160)
)
# The message SHOULD explicitly say "no fallback" (the contract) and MUST NOT
# offer a CSV fallback path as a remediation ("falling back to CSV",
# "CSV fallback:" line, "or place a valid CSV", etc.).
promises_csv_fallback <- isTRUE(test1$raised) && (
  grepl("falling back to csv", test1$msg, ignore.case = TRUE) ||
  grepl("csv fallback *:", test1$msg, ignore.case = TRUE) ||
  grepl("or place a valid csv", test1$msg, ignore.case = TRUE)
)
results$meta_missing_no_csv_fallback <- expect(
  "stop() message does NOT promise a CSV fallback path",
  isTRUE(test1$raised) && !promises_csv_fallback &&
    grepl("no fallback", test1$msg, ignore.case = TRUE),
  substr(test1$msg, 1, 200)
)

# --- Test 2: meta_data path NULL + csv_path exists → still must stop()
# (v2.1 §6: CSV seeds are producer-only; runtime MUST NOT consume them.)

seed_csv <- file.path(tmpdir, "df_product_line_seed.csv")
utils::write.csv(
  data.frame(
    product_line_id            = c("blb", "oth"),
    product_line_name_english  = c("Blueberry", "Other"),
    product_line_name_chinese  = c("\u85cd\u8393", "\u5176\u4ed6"),  # 藍莓, 其他
    stringsAsFactors = FALSE
  ),
  seed_csv,
  row.names = FALSE
)

test2 <- tryCatch(
  {
    load_product_lines(
      conn = sqlite_conn,
      meta_data_path = NULL,
      csv_path       = seed_csv
    )
    list(raised = FALSE, msg = "(no error raised — fallback still active!)")
  },
  error = function(e) list(raised = TRUE, msg = conditionMessage(e))
)

results$null_meta_path_refuses_csv <- expect(
  "meta_data_path NULL + CSV seed exists → MUST still stop() (no CSV fallback)",
  isTRUE(test2$raised),
  test2$msg
)

# --- Test 3: meta_data.duckdb exists but no df_product_line table → stop()

meta_empty <- file.path(tmpdir, "meta_empty.duckdb")
ec <- DBI::dbConnect(duckdb::duckdb(), meta_empty, read_only = FALSE)
DBI::dbDisconnect(ec, shutdown = TRUE)   # empty duckdb file
# Verify file exists on disk
results$empty_meta_file_created <- expect(
  "empty meta_data.duckdb fixture created",
  file.exists(meta_empty)
)

test3 <- tryCatch(
  {
    result <- load_product_lines(
      conn = sqlite_conn,
      meta_data_path = meta_empty,
      csv_path       = missing_csv
    )
    list(raised = FALSE, rows = if (is.data.frame(result)) nrow(result) else NA_integer_)
  },
  error = function(e) list(raised = TRUE, msg = conditionMessage(e))
)

# Acceptable outcomes in this corner case:
#   (a) stop() with helpful message (preferred), OR
#   (b) returns 0-row tibble AND does NOT fall back to CSV.
# What we refuse: silently falling back to `read.csv(missing_csv)` (which would
# itself blow up with a cryptic file-not-found — the OLD fallback behaviour).
results$empty_meta_no_csv_fallback <- expect(
  "empty meta_data.duckdb → reader does NOT attempt CSV fallback",
  isTRUE(test3$raised) ||
    (is.list(test3) && identical(test3$rows, 0L)) ||
    (is.list(test3) && is.numeric(test3$rows) && test3$rows == 0),
  if (isTRUE(test3$raised)) substr(test3$msg, 1, 160) else
    paste("rows =", test3$rows)
)

# --- Summary -----------------------------------------------------------------

passed <- sum(vapply(results, isTRUE, logical(1)))
total  <- length(results)
message(sprintf("\n==== %d / %d assertions passed ====", passed, total))

if (passed < total) {
  quit(status = 1)
}
invisible(TRUE)
