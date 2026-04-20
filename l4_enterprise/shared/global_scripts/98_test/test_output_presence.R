#!/usr/bin/env Rscript
# Test: pipeline-smart-cache helper
#
# Validates:
#   - `make run` SHALL Detect Missing Target Outputs Before Dispatching tar_make()
#   - `make run` SHALL Support FORCE=1 Escape Hatch
#   - Smart Detection SHALL Honor Non-Interactive Sessions
#   - Smart Detection Helper SHALL Be A Standalone Reusable Function
#
# Run with: Rscript shared/global_scripts/98_test/test_output_presence.R

HELPER_PATH <- Sys.getenv("OUTPUT_PRESENCE_PATH",
  file.path(Sys.getenv("PWD"), "shared/update_scripts/orchestration/fn_output_presence.R"))

if (!file.exists(HELPER_PATH)) {
  stop("Helper not found: ", HELPER_PATH, call. = FALSE)
}

# Source helper; guard against CLI auto-run (sys.nframe() == 0 branch)
local({
  original_frames <- sys.nframe()
  source(HELPER_PATH, local = FALSE)
})

assert <- function(cond, msg) {
  if (!isTRUE(cond)) stop("ASSERT FAIL: ", msg, call. = FALSE)
  message("  ✓ ", msg)
}

# ---------- Fixture ----------

build_fake_project <- function(layers_present, layers_all = c(
  "app_data", "raw_data", "staged_data", "transformed_data",
  "processed_data", "cleansed_data"
)) {
  # layers_present: character vector of layer names whose files should exist
  root <- tempfile("qef_smart_cache_")
  dir.create(file.path(root, "scripts/global_scripts/30_global_data/parameters/scd_type1"),
             recursive = TRUE, showWarnings = FALSE)

  # Write db_paths.yaml
  yaml_lines <- c("databases:")
  for (layer in layers_all) {
    rel <- switch(layer,
      "app_data"        = "data/app_data/app_data.duckdb",
      "raw_data"        = "data/local_data/raw_data.duckdb",
      "staged_data"     = "data/local_data/staged_data.duckdb",
      "transformed_data"= "data/local_data/transformed_data.duckdb",
      "processed_data"  = "data/local_data/processed_data.duckdb",
      "cleansed_data"   = "data/local_data/cleansed_data.duckdb"
    )
    yaml_lines <- c(yaml_lines, sprintf("  %s: %s", layer, rel))
  }
  yaml_path <- file.path(root,
    "scripts/global_scripts/30_global_data/parameters/scd_type1/db_paths.yaml")
  writeLines(yaml_lines, yaml_path)

  # Touch files only for layers_present
  for (layer in layers_present) {
    rel <- switch(layer,
      "app_data"        = "data/app_data/app_data.duckdb",
      "raw_data"        = "data/local_data/raw_data.duckdb",
      "staged_data"     = "data/local_data/staged_data.duckdb",
      "transformed_data"= "data/local_data/transformed_data.duckdb",
      "processed_data"  = "data/local_data/processed_data.duckdb",
      "cleansed_data"   = "data/local_data/cleansed_data.duckdb"
    )
    full <- file.path(root, rel)
    dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
    file.create(full)
  }
  root
}

# ---------- Scenarios: pure function (Standalone Reusable) ----------

message("== test_output_presence.R ==\n")

message("[S1] check_db_layers_presence — all 6 layers present")
root1 <- build_fake_project(layers_present = c(
  "app_data", "raw_data", "staged_data",
  "transformed_data", "processed_data", "cleansed_data"
))
r1 <- check_db_layers_presence(root1)
assert(length(r1$missing) == 0, "no missing layers when all present")
assert(length(r1$present) == 6, "6 layers reported present")
message("")

message("[S2] check_db_layers_presence — 3 of 6 layers missing (QEF_DESIGN-like state)")
root2 <- build_fake_project(layers_present = c("app_data", "raw_data", "processed_data"))
r2 <- check_db_layers_presence(root2)
assert(length(r2$missing) == 3, "3 missing layers detected")
assert(all(c("staged_data", "transformed_data", "cleansed_data") %in% names(r2$missing)),
       "missing names include the 3 absent layers")
message("")

# ---------- Scenarios: orchestration with stubbed runners ----------

# Stub targets::tar_make / tar_destroy to track calls (no real R pipeline execution)
call_log <- character()
stub_make    <- function(...) { call_log <<- c(call_log, "tar_make"); invisible(NULL) }
stub_destroy <- function(...) { call_log <<- c(call_log, "tar_destroy"); invisible(NULL) }

# Monkey-patch the helpers defined in fn_output_presence.R
assignInNamespace_shim <- function() {
  # Redefine run_selective / run_nuclear to avoid real targets calls
  run_selective <<- function(target_script, store_path) {
    call_log[[length(call_log) + 1]] <<- "selective"
  }
  run_nuclear <<- function(store_path, target_script) {
    call_log[[length(call_log) + 1]] <<- "nuclear"
  }
}
assignInNamespace_shim()

message("[S3] FORCE=1 triggers nuclear")
Sys.setenv(FORCE = "1")
call_log <- character()
check_and_run(project_root = root1, store_path = "/tmp/nowhere",
              target_script = "/tmp/nowhere/_targets.R")
Sys.unsetenv("FORCE")
assert(identical(call_log, c("nuclear")), "FORCE=1 path called run_nuclear only")
message("")

message("[S4] All layers present (no FORCE) → selective mode")
call_log <- character()
check_and_run(project_root = root1, store_path = "/tmp/nowhere",
              target_script = "/tmp/nowhere/_targets.R")
assert(identical(call_log, c("selective")), "all-present path called run_selective only")
message("")

message("[S5] Missing layers + non-interactive → auto-proceed nuclear")
# isatty(stdin()) in Rscript is typically FALSE — exercises non-interactive branch
call_log <- character()
check_and_run(project_root = root2, store_path = "/tmp/nowhere",
              target_script = "/tmp/nowhere/_targets.R")
assert(identical(call_log, c("nuclear")),
       "missing + non-tty path called run_nuclear (auto-proceed)")
message("")

message("All scenarios passed ✓")
