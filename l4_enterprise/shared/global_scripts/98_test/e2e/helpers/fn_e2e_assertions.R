#' E2E Test Helper: Common Assertions
#'
#' Shared assertion functions for E2E tests.
#' Principles: TD_R007 (E2E testing)

#' Assert that the app has no R errors in its log
#'
#' @param app shinytest2::AppDriver object
#' @param context Description of what was being tested (for error messages)
assert_no_r_errors <- function(app, context = "operation") {
  logs <- app$get_logs()
  # Use specific patterns to avoid false positives from business content (e.g., "error rate")
  # Patterns: R errors (^Error, Error in, error in, ERROR:) + component errors ([*] *error:)
  # Also matches bracketed format [ERROR] used by modules like reportIntegration.R (#345)
  error_logs <- logs[logs$type == "shiny" & grepl("^Error\\b|\\bERROR:|\\[ERROR\\]|error in |Error in |\\] Error: |\\b\\w+ error: ", logs$message, perl = TRUE, ignore.case = TRUE), ]
  if (nrow(error_logs) > 0) {
    error_msgs <- paste(error_logs$message, collapse = "\n  ")
    testthat::fail(paste0(
      "R errors found after ", context, ":\n  ", error_msgs
    ))
  }
}


#' Assert that login was successful (main_app is visible)
#'
#' @param app shinytest2::AppDriver object
assert_logged_in <- function(app) {
  # After login, login_page should be hidden and main_app visible
  # We check by trying to get a value from the sidebar_menu
  sidebar_value <- app$get_value(input = "sidebar_menu")
  testthat::expect_true(
    !is.null(sidebar_value),
    label = "sidebar_menu should have a value after login"
  )
}


#' Assert that a tab loaded successfully (no errors, content present)
#'
#' @param app shinytest2::AppDriver object
#' @param tab_name The tabName value to navigate to
#' @param wait_ms Additional wait time in ms after tab switch
assert_tab_loads <- function(app, tab_name, wait_ms = 3000) {
  # Switch to the tab
  app$set_inputs(sidebar_menu = tab_name)
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(wait_ms / 1000)

  # Check no R errors
  assert_no_r_errors(app, context = paste0("switching to tab '", tab_name, "'"))

  # Verify the tab is now active
  current_tab <- app$get_value(input = "sidebar_menu")
  testthat::expect_equal(
    current_tab, tab_name,
    label = paste0("sidebar_menu should be '", tab_name, "'")
  )
}


#' Get all available tab names from the sidebar menu
#'
#' @return Character vector of all tab names defined in union_production_test.R
get_all_tab_names <- function() {
  c(
    # Dashboard Overview
    "dashboardOverview",
    # TagPilot
    "customerValue", "customerActivity", "customerStatus",
    "customerStructure", "customerLifecycle", "rsvMatrix",
    "marketingDecision", "customerExport", "tpComprehensiveDiagnosis",
    # VitalSigns
    "revenuePulse", "customerAcquisition", "customerRetention",
    "customerEngagement", "worldMap", "macroTrends",
    "vsComprehensiveDiagnosis",
    # BrandEdge
    "position", "positionDNA", "positionMS",
    "positionKFE", "positionIdealRate", "positionStrategy",
    # InsightForge
    "poissonComment", "poissonTime", "poissonFeature",
    # Report Center
    "reportCenter"
  )
}


#' Get AI button tab-to-module_id mapping
#'
#' Returns a named list: tab_name -> module_id for all 13 AI insight buttons.
#' The button input ID pattern is: "{module_id}-generate_ai_insight"
#'
#' @return Named list of tab_name = module_id
get_ai_button_tabs <- function() {
  list(
    # TagPilot (6 buttons)
    customerValue     = "customer_value",
    customerActivity  = "customer_activity",
    customerStatus    = "customer_status",
    customerStructure = "customer_structure",
    customerLifecycle = "customer_lifecycle",
    tpComprehensiveDiagnosis = "tp_comprehensive_diagnosis",
    # VitalSigns (7 buttons)
    revenuePulse      = "revenue_pulse",
    customerAcquisition = "customer_acquisition",
    customerRetention = "customer_retention",
    customerEngagement = "customer_engagement",
    worldMap          = "world_map",
    macroTrends       = "macro_trends",
    vsComprehensiveDiagnosis = "vs_comprehensive_diagnosis"
  )
}


#' Assert that an AI insight button can be clicked and template vars build OK
#'
#' Navigates to the tab, clicks the AI button, waits briefly, then checks
#' R logs for errors. In DEBUG_MODE, also verifies template vars were logged.
#' Does NOT wait for OpenAI API response (too slow for E2E).
#'
#' @param app shinytest2::AppDriver object
#' @param tab_name The tabName to navigate to
#' @param module_id The module ID (used to build button input ID)
#' @param wait_ms Time to wait after clicking button (default: 3000)
assert_ai_button_works <- function(app, tab_name, module_id, wait_ms = 3000) {
  # Navigate to the tab
  app$set_inputs(sidebar_menu = tab_name)
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(1)

  # Build the button input ID: "{module_id}-generate_ai_insight"
  button_id <- paste0(module_id, "-generate_ai_insight")

  # Guard: if OPENAI_API_KEY is set, skip to avoid real API calls (#334).
  # setup.R sets OPENAI_API_KEY="" and create_logged_in_app() hides .env (#345).
  if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    testthat::skip("Skipping AI button click: OPENAI_API_KEY is set (would trigger real API call)")
  }

  # Click the AI insight button.
  # In no-key environment, setup_ai_insight_server() disables the button
  # before binding get_template_vars() / task$invoke(). So "disabled" means:
  #   ✅ Button exists (component registered correctly)
  #   ✅ No-key guard works (shinyjs::disable fired)
  #   ⚠️ Execution chain NOT tested (get_template_vars, API call)
  # We assert presence + disable-guard, then move on. (#345)
  # IMPORTANT: Do NOT use testthat::skip() here — it ends the entire
  # test_that() block, preventing subsequent buttons from being tested.
  click_result <- "not_found"
  last_error <- NULL
  for (attempt in seq_len(5)) {
    filter_html <- tryCatch(
      app$get_html("#dynamic_filter"),
      error = function(e) ""
    )
    has_button <- grepl(button_id, as.character(filter_html), fixed = TRUE)
    if (!has_button) {
      app$wait_for_idle(timeout = 10000)
      Sys.sleep(1)
      next
    }

    click_result <- tryCatch({
      app$click(button_id)
      "clicked"
    }, error = function(e) {
      last_error <<- e$message
      if (grepl("disabled", e$message, ignore.case = TRUE)) {
        return("disabled")
      }
      if (grepl("Cannot find HTML element", e$message, fixed = TRUE)) {
        return("not_found")
      }
      testthat::fail(paste0(
        "AI button interaction failed for '", button_id, "' on tab '", tab_name, "': ",
        e$message
      ))
      "failed"
    })

    if (click_result %in% c("clicked", "disabled", "failed")) break
    app$wait_for_idle(timeout = 10000)
    Sys.sleep(1)
  }

  if (identical(click_result, "not_found")) {
    testthat::fail(paste0(
      "Could not find AI button '", button_id, "' on tab '", tab_name, "' after retries: ",
      last_error
    ))
  }

  if (click_result == "disabled") {
    # Button exists but is disabled — expected in no-key environment.
    # This verifies: (1) button rendered, (2) no-key guard works.
    # Execution chain (template vars → API call) is NOT tested here.
    message(
      "[E2E] AI button '", button_id, "' exists but disabled on tab '",
      tab_name, "' (expected: no API key) — presence + guard verified"
    )
    return(invisible(NULL))
  }

  # If we got here, button was clicked (key is set — shouldn't happen in E2E).
  # Wait for template vars to build (DB query + processing)
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(wait_ms / 1000)

  # Check for R errors after clicking
  # Log messages may use camelCase tab_name (e.g. [customerValue]) or
  # snake_case module_id (e.g. customer_value) — match either (#333)
  # Also catch non-"error" failure patterns from AI insight async (#342):
  #   - "Failed to build template vars" (fn_ai_insight_async.R line 138)
  #   - "AI insight task failed" (fn_ai_insight_async.R line 206)
  # NOTE: Pattern must be specific to avoid false positives from DEBUG_MODE
  # logs that include business data text (e.g. "failure rate", "failed campaign")
  logs <- app$get_logs()
  failure_pattern <- "error|Failed to build template vars|AI insight task failed"
  error_logs <- logs[logs$type == "shiny" &
                       grepl(failure_pattern, logs$message, ignore.case = TRUE) &
                       (grepl(module_id, logs$message, fixed = TRUE) |
                        grepl(tab_name, logs$message, fixed = TRUE)), ]

  if (nrow(error_logs) > 0) {
    error_msgs <- paste(error_logs$message, collapse = "\n  ")
    testthat::fail(paste0(
      "R errors after clicking AI button on tab '", tab_name,
      "' (module: ", module_id, "):\n  ", error_msgs
    ))
  }
}


#' Get tab names for a specific module
#'
#' @param module One of "tagpilot", "vitalsigns", "brandedge", "insightforge"
#' @return Character vector of tab names
get_module_tabs <- function(module) {
  switch(module,
    tagpilot = c("customerValue", "customerActivity", "customerStatus",
                 "customerStructure", "customerLifecycle", "rsvMatrix",
                 "marketingDecision", "customerExport", "tpComprehensiveDiagnosis"),
    vitalsigns = c("revenuePulse", "customerAcquisition", "customerRetention",
                   "customerEngagement", "worldMap", "macroTrends",
                   "vsComprehensiveDiagnosis"),
    brandedge = c("position", "positionDNA", "positionMS",
                  "positionKFE", "positionIdealRate", "positionStrategy"),
    insightforge = c("poissonComment", "poissonTime", "poissonFeature"),
    stop("Unknown module: ", module)
  )
}


# ===========================================================================
# TD_P010: L2 Data Verification Helpers
# ===========================================================================

#' Select a product line in the global filter
#'
#' @param app shinytest2::AppDriver object
#' @param product_line_id Character. e.g. "its", "blb", "sfo"
#' @param wait_ms Additional wait time after selection (default: 3000)
select_product_line <- function(app, product_line_id, wait_ms = 3000) {
  # The global filter uses radio buttons with name dynamic_filter-product_line_id_chosen
  tryCatch({
    app$set_inputs(`dynamic_filter-product_line_id_chosen` = product_line_id)
    app$wait_for_idle(timeout = 10000)
    Sys.sleep(wait_ms / 1000)
  }, error = function(e) {
    # Fallback: try clicking the radio button directly via JS
    js <- sprintf(
      "document.querySelector('input[type=\"radio\"][value=\"%s\"]').click()",
      product_line_id
    )
    app$run_js(js)
    app$wait_for_idle(timeout = 10000)
    Sys.sleep(wait_ms / 1000)
  })
}


#' Assert that a DataTable on the current tab has data rows
#'
#' Checks the DT info text (e.g., "Showing 1 to 10 of 14 entries")
#' to verify the table contains data.
#'
#' @param app shinytest2::AppDriver object
#' @param tab_name Character. For error messages.
#' @param min_rows Integer. Minimum expected rows (default: 1).
assert_datatable_has_rows <- function(app, tab_name, min_rows = 1) {
  # DT info div contains "Showing X to Y of Z entries"
  info_text <- tryCatch(
    app$get_text(".dataTables_info"),
    error = function(e) ""
  )

  if (nchar(info_text) == 0) {
    # Fallback: count <tr> in table body
    html <- tryCatch(app$get_html(".dataTable"), error = function(e) "")
    row_count <- length(gregexpr("<tr[^>]*>", html)[[1]])
    # Subtract header row
    row_count <- max(0, row_count - 1)
  } else {
    # Parse "Showing 1 to 10 of 14 entries"
    m <- regmatches(info_text, regexpr("of ([0-9,]+) entries", info_text))
    row_count <- if (length(m) > 0) {
      as.integer(gsub("[^0-9]", "", sub("of ", "", sub(" entries", "", m))))
    } else {
      0L
    }
  }

  testthat::expect_gte(
    row_count, min_rows,
    label = paste0("DataTable on '", tab_name, "' should have ≥", min_rows, " data rows")
  )

  invisible(row_count)
}


#' Assert that a Plotly chart has been rendered on the current tab
#'
#' @param app shinytest2::AppDriver object
#' @param tab_name Character. For error messages.
assert_plotly_rendered <- function(app, tab_name) {
  has_plotly <- tryCatch(
    app$get_js("!!document.querySelector('.js-plotly-plot')"),
    error = function(e) FALSE
  )

  testthat::expect_true(
    isTRUE(has_plotly),
    label = paste0("Plotly chart should be rendered on '", tab_name, "'")
  )
}


#' Assert that a tab has visible content (not empty/loading)
#'
#' Checks that the main card body has non-trivial text content.
#'
#' @param app shinytest2::AppDriver object
#' @param tab_name Character. For error messages.
#' @param min_chars Integer. Minimum text length to consider "has content" (default: 10).
assert_tab_has_content <- function(app, tab_name, min_chars = 10) {
  # Get text from the active tab's card body
  content <- tryCatch(
    app$get_text(".tab-pane.active .card-body"),
    error = function(e) ""
  )

  content_length <- as.integer(nchar(trimws(content)))

  testthat::expect_true(
    content_length >= min_chars,
    label = paste0("Tab '", tab_name, "' should have visible content (got ", content_length, " chars)")
  )
}
