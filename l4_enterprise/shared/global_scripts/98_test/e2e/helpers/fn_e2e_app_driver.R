#' E2E Test Helper: AppDriver Factory
#'
#' Creates a shinytest2 AppDriver with login already completed.
#' Must be executed from the COMPANY PROJECT ROOT (e.g., D_RACING/).
#'
#' Principles: TD_R001 (real data), TD_R007 (E2E testing)

#' Create an AppDriver that is already logged in
#'
#' @param app_dir Path to company project root (default: current working dir)
#' @param port Port for the test app (default: random available)
#' @param timeout Timeout for Shiny actions in ms (default: 30000)
#' @param load_timeout Timeout for app loading in ms (default: 60000)
#' @return shinytest2::AppDriver object, logged in and ready
create_logged_in_app <- function(app_dir = getOption("e2e.project_root", getwd()),
                                 port = NULL,
                                 timeout = 30000,
                                 load_timeout = 60000) {
  if (!requireNamespace("shinytest2", quietly = TRUE)) {
    stop("shinytest2 is required for E2E tests. Install with: install.packages('shinytest2')")
  }

  # Verify app.R exists in app_dir
  app_r_path <- file.path(app_dir, "app.R")
  if (!file.exists(app_r_path)) {
    stop("app.R not found in: ", app_dir,
         "\nE2E tests must be run from the company project root directory.")
  }

  # Sanitize .env: keep APP_PASSWORD (needed for login) but strip
  # OPENAI_API_KEY to prevent real API calls. The subprocess runs
  # sc_initialization_app_mode.R which calls dotenv::load_dot_env(),
  # overriding any env vars set in the parent. (#345)
  env_path <- file.path(app_dir, ".env")
  env_bak <- paste0(env_path, ".e2e_backup")
  has_env <- file.exists(env_path)
  if (has_env) {
    file.copy(env_path, env_bak, overwrite = TRUE)
    # Read, strip OPENAI_API_KEY lines, write back sanitized version
    env_lines <- readLines(env_path, warn = FALSE)
    sanitized <- env_lines[!grepl("^\\s*OPENAI_API_KEY\\s*=", env_lines)]
    writeLines(sanitized, env_path)
    message("[E2E] Sanitized .env: stripped OPENAI_API_KEY, kept other vars (e.g. APP_PASSWORD)")
  }
  # Restore original .env on exit (even if AppDriver creation fails)
  on.exit({
    if (has_env && file.exists(env_bak)) {
      file.copy(env_bak, env_path, overwrite = TRUE)
      file.remove(env_bak)
      message("[E2E] Restored original .env")
    }
  }, add = TRUE)

  # Build AppDriver arguments
  driver_args <- list(
    app_dir = app_dir,
    name = paste0("e2e-", basename(app_dir)),
    timeout = timeout,
    load_timeout = load_timeout,
    seed = 12345,
    height = 900,
    width = 1400
  )
  if (!is.null(port)) {
    driver_args$options <- list(shiny.port = port)
  }

  # Create AppDriver
  app <- do.call(shinytest2::AppDriver$new, driver_args)

  # Wait for login page to render
  Sys.sleep(2)

  # Login with password-only mode
  # Module namespace: "auth", input: "password" -> "auth-password"
  # Submit button: "auth-submit_btn"
  app$set_inputs(`auth-password` = "VIBE")
  app$click("auth-submit_btn")

  # Wait for main app to load after login
  app$wait_for_idle(timeout = 15000)
  Sys.sleep(2)  # Extra wait for bs4Dash to initialize


  return(app)
}


#' Safely stop an AppDriver
#'
#' @param app shinytest2::AppDriver object
stop_app_safely <- function(app) {
  tryCatch(
    app$stop(),
    error = function(e) {
      message("[E2E] AppDriver stop warning: ", e$message)
    }
  )
}
