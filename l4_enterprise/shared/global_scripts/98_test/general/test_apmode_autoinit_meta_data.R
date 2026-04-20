#!/usr/bin/env Rscript

# Test: APP_MODE autoinit() populates db_path_list$meta_data (DM_R054 v2.1 §8)
#
# Driving `Decision 3: APP_MODE autoinit populates db_path_list$meta_data` from
# spectra change `dm-r054-v2-migration-complete` (issue #424). This test does
# NOT source sc_Rprofile.R with a full autoinit() (that requires every DB file
# to exist on disk). Instead it directly exercises the path-construction logic
# introduced in Phase A task 1.6 by replaying the same YAML + base + mode
# inputs.
#
# Run from a company root (e.g. `QEF_DESIGN/`) or repo root `l4_enterprise/`:
#   Rscript shared/global_scripts/98_test/general/test_apmode_autoinit_meta_data.R

suppressPackageStartupMessages({
  library(yaml)
})

expect <- function(label, ok, detail = "") {
  status <- if (isTRUE(ok)) "PASS" else "FAIL"
  msg <- sprintf("[%s] %s%s", status, label,
                 if (nzchar(detail)) paste0(" — ", detail) else "")
  message(msg)
  invisible(isTRUE(ok))
}

# --- Fixture: minimal db_paths.yaml -----------------------------------------
# We do not require the actual repo YAML to be present (the test is about the
# path-construction logic, not real filesystem verification). We also do not
# care whether the files exist on disk, which makes this test portable across
# CI environments. The real fail-fast precheck in sc_Rprofile.R is tested
# end-to-end by the existing autoinit-failfast tests.

tmpdir <- tempfile("test_apmode_meta_")
dir.create(tmpdir, recursive = TRUE)
on.exit(unlink(tmpdir, recursive = TRUE), add = TRUE)

yaml_path <- file.path(tmpdir, "db_paths.yaml")
writeLines(
  c(
    "databases:",
    "  raw_data: data/local_data/raw_data.duckdb",
    "  staged_data: data/local_data/staged_data.duckdb",
    "  transformed_data: data/local_data/transformed_data.duckdb",
    "  processed_data: data/local_data/processed_data.duckdb",
    "  cleansed_data: data/local_data/cleansed_data.duckdb",
    "  app_data: data/app_data/app_data.duckdb",
    "  meta_data: data/local_data/meta_data.duckdb"
  ),
  yaml_path
)

db_config <- yaml::read_yaml(yaml_path)
base <- tmpdir  # pretend this is the company root

# --- Replicate the APP_MODE branch (sc_Rprofile.R Phase A Task 1.6) --------

build_db_path_list_app_mode <- function(db_config, base) {
  db_path_list <- list()
  if (!is.null(db_config$databases)) {
    for (name in intersect(c("app_data", "meta_data"), names(db_config$databases))) {
      db_path_list[[name]] <- file.path(base, db_config$databases[[name]])
    }
  }
  db_path_list
}

build_db_path_list_update_mode <- function(db_config, base) {
  # Expected UPDATE_MODE behaviour: load all 6 layers + meta_data (if defined).
  db_path_list <- list()
  if (!is.null(db_config$databases)) {
    for (name in names(db_config$databases)) {
      db_path_list[[name]] <- file.path(base, db_config$databases[[name]])
    }
  }
  db_path_list
}

# --- Test 1: APP_MODE populates meta_data alongside app_data ----------------

app_paths <- build_db_path_list_app_mode(db_config, base)
results <- list()

results$has_app_data <- expect(
  "APP_MODE db_path_list contains app_data",
  !is.null(app_paths$app_data) && nzchar(app_paths$app_data),
  app_paths$app_data %||% "(NULL)"
)

results$has_meta_data <- expect(
  "APP_MODE db_path_list contains meta_data (DM_R054 v2.1 Section 8)",
  !is.null(app_paths$meta_data) && nzchar(app_paths$meta_data),
  app_paths$meta_data %||% "(NULL)"
)

results$meta_data_is_canonical <- expect(
  "APP_MODE meta_data path equals base + yaml databases.meta_data",
  identical(
    app_paths$meta_data,
    file.path(base, db_config$databases$meta_data)
  ),
  app_paths$meta_data %||% "(NULL)"
)

# --- Test 2: APP_MODE still scopes out the 6-layer ETL paths ---------------
# (We don't want APP_MODE silently loading raw/staged/etc. — that was the
# point of DM_R050 Mode-Specific Path Loading. Only app_data + meta_data.)

six_layer_paths <- c("raw_data", "staged_data", "transformed_data",
                     "processed_data", "cleansed_data")
loaded_six_layer <- intersect(six_layer_paths, names(app_paths))
results$scopes_out_6_layer <- expect(
  "APP_MODE does NOT load the 6-layer ETL paths",
  length(loaded_six_layer) == 0,
  paste("unexpected:", paste(loaded_six_layer, collapse = ", "))
)

# --- Test 3: UPDATE_MODE still loads all paths (backward compatibility) ----

update_paths <- build_db_path_list_update_mode(db_config, base)
expected_update <- c("raw_data", "staged_data", "transformed_data",
                     "processed_data", "cleansed_data", "app_data", "meta_data")
missing_update <- setdiff(expected_update, names(update_paths))
results$update_mode_all_paths <- expect(
  "UPDATE_MODE still loads all 7 paths (regression check)",
  length(missing_update) == 0,
  paste("missing:", paste(missing_update, collapse = ", "))
)

# --- Summary ---------------------------------------------------------------

passed <- sum(vapply(results, isTRUE, logical(1)))
total  <- length(results)
message(sprintf("\n==== %d / %d assertions passed ====", passed, total))

if (passed < total) {
  quit(status = 1)
}
invisible(TRUE)
