# E2E Test Setup
# Loaded automatically by testthat before running tests in this directory.
#
# Prerequisites:
#   - Run from company project root (e.g., D_RACING/)
#   - app.R must exist in working directory
#   - data/app_data/app_data.duckdb must exist
#
# Principles: TD_R007 (E2E testing), MP029 (no fake data)

library(testthat)
library(shinytest2)

# Enable DEBUG_MODE for E2E tests — logs all dashboard outputs to console
Sys.setenv(SHINY_DEBUG_MODE = "TRUE")

# Explicitly unset OPENAI_API_KEY to prevent real API calls in subprocess (#345)
# The AppDriver subprocess inherits env vars from the test process; company .env
# files may set OPENAI_API_KEY, which would trigger real (slow, costly) API calls.
Sys.setenv(OPENAI_API_KEY = "")

resolve_e2e_project_root <- function(start_dir = getwd()) {
  candidates <- c(
    getOption("e2e.project_root", ""),
    Sys.getenv("E2E_PROJECT_ROOT", ""),
    Sys.getenv("PWD", ""),
    normalizePath(start_dir, mustWork = FALSE),
    normalizePath(file.path(start_dir, ".."), mustWork = FALSE),
    normalizePath(file.path(start_dir, "..", ".."), mustWork = FALSE),
    normalizePath(file.path(start_dir, "..", "..", ".."), mustWork = FALSE),
    normalizePath(file.path(start_dir, "..", "..", "..", ".."), mustWork = FALSE)
  )

  for (dir in unique(candidates[nzchar(candidates)])) {
    if (file.exists(file.path(dir, "app.R")) &&
        dir.exists(file.path(dir, "scripts", "global_scripts", "98_test", "e2e", "helpers"))) {
      return(dir)
    }
  }

  stop(
    "Could not resolve company project root from: ", start_dir, "\n",
    "Expected to find app.R and scripts/global_scripts/98_test/e2e/helpers/"
  )
}

e2e_project_root <- resolve_e2e_project_root()
options(e2e.project_root = e2e_project_root)

# Source helper functions
e2e_helpers_dir <- file.path(
  e2e_project_root, "scripts", "global_scripts", "98_test", "e2e", "helpers"
)

source(file.path(e2e_helpers_dir, "fn_e2e_app_driver.R"))
source(file.path(e2e_helpers_dir, "fn_e2e_assertions.R"))

# Verify we're in a company project root
if (!file.exists(file.path(e2e_project_root, "app.R"))) {
  stop(
    "E2E tests must be run from a company project root directory ",
    "(where app.R exists).\n",
    "Resolved project root: ", e2e_project_root, "\n",
    "Example: cd D_RACING && Rscript -e \"testthat::test_dir('scripts/global_scripts/98_test/e2e')\""
  )
}

# Verify database exists
db_path <- file.path(e2e_project_root, "data", "app_data", "app_data.duckdb")
if (!file.exists(db_path)) {
  stop(
    "Database not found: ", db_path, "\n",
    "Run the ETL/DRV pipeline first: cd scripts/update_scripts && make run"
  )
}

message("[E2E] Setup complete. Project: ", basename(e2e_project_root))
