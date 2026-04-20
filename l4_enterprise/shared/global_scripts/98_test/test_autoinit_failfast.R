#!/usr/bin/env Rscript
# Test: autoinit-failfast-policy
#
# Validates three spec requirements:
#   1. `autoinit()` SHALL Verify All Required DB Files Exist Before Initialization
#   2. `autoinit()` Error Message SHALL Be Actionable
#   3. `autoinit()` SHALL Remain Idempotent After Guard Check
#
# Run with: Rscript shared/global_scripts/98_test/test_autoinit_failfast.R

# ---------- Minimal fixture: build a fake project tree in tempdir ----------

build_fake_project <- function(root, db_layers) {
  # db_layers: named list like list(app_data = "data/app_data/app_data.duckdb", ...)
  # Creates parent dirs but only touches files listed in db_layers with value != NA.

  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "scripts", "global_scripts", "22_initializations"),
             recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "scripts", "global_scripts", "30_global_data",
                       "parameters", "scd_type1"),
             recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(root, "data", "app_data"), recursive = TRUE, showWarnings = FALSE)

  # .here sentinel so here::here() pins to this fake root (not real repo)
  file.create(file.path(root, ".here"))

  # Write minimal db_paths.yaml
  db_yaml_path <- file.path(root, "scripts", "global_scripts", "30_global_data",
                            "parameters", "scd_type1", "db_paths.yaml")
  yaml_lines <- c("databases:")
  for (name in names(db_layers)) {
    yaml_lines <- c(yaml_lines, sprintf("  %s: %s", name, db_layers[[name]]))
  }
  writeLines(yaml_lines, db_yaml_path)

  # Write empty init scripts (autoinit sources these after db_path_list is built)
  for (f in c("sc_initialization_app_mode.R", "sc_initialization_update_mode.R")) {
    writeLines("# stub init script\n", file.path(root, "scripts", "global_scripts",
                                                 "22_initializations", f))
  }

  # Touch DB files that should exist (value = TRUE means create file)
  for (name in names(db_layers)) {
    rel <- db_layers[[name]]
    full <- file.path(root, rel)
    if (!is.na(rel) && identical(attr(db_layers[[name]], "exists"), TRUE)) {
      dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
      file.create(full)
    }
  }

  invisible(root)
}

# Helper: mark a DB entry as "should exist on disk"
present <- function(rel) { attr(rel, "exists") <- TRUE; rel }
# Helper: mark as "configured but missing"
absent  <- function(rel) { attr(rel, "exists") <- FALSE; rel }

# ---------- Run a fresh autoinit() inside a temp project ----------

run_autoinit_in_fixture <- function(db_layers, mode = "UPDATE_MODE") {
  root <- tempfile("qef_autoinit_fixture_")
  build_fake_project(root, db_layers)
  saved <- getwd()
  on.exit(setwd(saved), add = TRUE)
  setwd(root)

  # Fresh R env so .InitEnv$mode is NULL
  sc_path <- file.path(Sys.getenv("SC_RPROFILE_PATH"))
  if (!nzchar(sc_path) || !file.exists(sc_path)) {
    stop("SC_RPROFILE_PATH env var must point to sc_Rprofile.R under test")
  }

  .InitEnv <<- NULL  # force re-source
  source(sc_path, local = FALSE)

  # Pin APP_DIR to fake root (bypasses here::here() which has package-level cache
  # that would otherwise leak S1's fixture path into S2).
  .InitEnv$APP_DIR              <- root
  .InitEnv$COMPANY_DIR          <- dirname(root)
  .InitEnv$GLOBAL_DIR           <- file.path(root, "scripts", "global_scripts")
  .InitEnv$GLOBAL_DATA_DIR      <- file.path(root, "scripts", "global_scripts", "30_global_data")
  .InitEnv$GLOBAL_PARAMETER_DIR <- file.path(root, "scripts", "global_scripts", "30_global_data", "parameters")
  .InitEnv$CONFIG_PATH          <- file.path(root, "app_config.yaml")
  .InitEnv$APP_DATA_DIR         <- file.path(root, "data", "app_data")
  .InitEnv$APP_PARAMETER_DIR    <- file.path(root, "data", "app_data", "parameters")
  .InitEnv$LOCAL_DATA_DIR       <- file.path(root, "data", "local_data")

  # Set OPERATION_MODE explicitly to bypass detect_script_path (which looks at
  # call stack and would pick APP_MODE for this test driver).
  assign("OPERATION_MODE", mode, envir = .GlobalEnv)

  # Invoke — expect either success or stop()
  tryCatch({
    autoinit()
    list(ok = TRUE, err = NULL)
  }, error = function(e) {
    list(ok = FALSE, err = conditionMessage(e))
  })
}

# ---------- Assertions ----------

`%||%` <- function(a, b) if (is.null(a)) b else a

assert <- function(cond, msg) {
  if (!isTRUE(cond)) stop("ASSERT FAIL: ", msg, call. = FALSE)
  message("  ✓ ", msg)
}

# ---------- Scenarios ----------

main <- function() {
  message("== test_autoinit_failfast.R ==")
  message("")

  # Scenario 1: All required DB files present -> autoinit should NOT stop
  message("[S1] All required DB files present")
  r1 <- run_autoinit_in_fixture(list(
    app_data       = present("data/app_data/app_data.duckdb"),
    raw_data       = present("data/raw_data.duckdb"),
    staged_data    = present("data/staged_data/staged.duckdb"),
    transformed_data = present("data/transformed_data/transformed.duckdb"),
    processed_data = present("data/processed_data/processed.duckdb"),
    cleansed_data  = present("data/cleansed_data/cleansed.duckdb")
  ))
  assert(r1$ok, "autoinit succeeded when all DB files exist")
  message("")

  # Scenario 2: Missing transformed_data -> autoinit should stop with actionable message
  message("[S2] Missing transformed_data")
  r2 <- run_autoinit_in_fixture(list(
    app_data       = present("data/app_data/app_data.duckdb"),
    raw_data       = present("data/raw_data.duckdb"),
    staged_data    = present("data/staged_data/staged.duckdb"),
    transformed_data = absent("data/transformed_data/transformed.duckdb"),
    processed_data = absent("data/processed_data/processed.duckdb"),
    cleansed_data  = absent("data/cleansed_data/cleansed.duckdb")
  ))
  assert(isFALSE(r2$ok), "autoinit stopped when files missing")
  assert(grepl("transformed_data", r2$err, fixed = TRUE),
         "error message names missing file (transformed_data)")
  assert(grepl("make run", r2$err, fixed = TRUE),
         "error message includes remediation command (`make run`)")
  message("")

  # Scenario 3: Idempotent — back-to-back autoinit() calls must both succeed
  # when all files present (no false positive from precheck on second pass)
  message("[S3] Idempotent re-call (both calls must succeed when files present)")
  r3a <- run_autoinit_in_fixture(list(
    app_data = present("data/app_data/app_data.duckdb")
  ), mode = "APP_MODE")
  assert(r3a$ok, "first autoinit() succeeded")
  # Second call in same R session: .InitEnv and .GlobalEnv still populated.
  # autoinit() should complete without re-triggering precheck-related stop().
  r3b <- tryCatch({
    autoinit()
    list(ok = TRUE)
  }, error = function(e) list(ok = FALSE, err = conditionMessage(e)))
  assert(r3b$ok, "second autoinit() in same session also succeeded (idempotent)")
  message("")

  message("All scenarios passed ✓")
  invisible(TRUE)
}

main()
