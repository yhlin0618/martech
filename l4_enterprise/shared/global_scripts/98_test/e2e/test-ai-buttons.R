# E2E Test: AI Insight Buttons
# Level: L3 (Functional) - verifies all 13 AI buttons trigger correctly
#
# Tests that clicking each AI insight button:
# 1. Does not cause R errors
# 2. Successfully builds template vars (verified via DEBUG_MODE logs)
# 3. Triggers the ExtendedTask (or shows "Data not ready" notification)
#
# NOTE: Does NOT test OpenAI API response (requires API key + is slow).
#       Uses SHINY_DEBUG_MODE=TRUE (set in setup.R) for enhanced logging.
#
# Principles: TD_R007 (E2E testing), MP029 (no fake data)

test_that("All TagPilot AI buttons trigger without errors", {
  ai_tabs <- get_ai_button_tabs()

  # TagPilot tabs (6 buttons)
  tp_tabs <- c("customerValue", "customerActivity", "customerStatus",
               "customerStructure", "customerLifecycle",
               "tpComprehensiveDiagnosis")

  for (tab in tp_tabs) {
    module_id <- ai_tabs[[tab]]
    message("[E2E] Testing AI button: tab=", tab, " module=", module_id)
    app <- create_logged_in_app()
    on.exit(stop_app_safely(app), add = TRUE)
    assert_logged_in(app)
    assert_ai_button_works(app, tab, module_id, wait_ms = 3000)
    stop_app_safely(app)
  }
})


test_that("All VitalSigns AI buttons trigger without errors", {
  ai_tabs <- get_ai_button_tabs()

  # VitalSigns tabs (7 buttons)
  vs_tabs <- c("revenuePulse", "customerAcquisition", "customerRetention",
               "customerEngagement", "worldMap", "macroTrends",
               "vsComprehensiveDiagnosis")

  for (tab in vs_tabs) {
    module_id <- ai_tabs[[tab]]
    message("[E2E] Testing AI button: tab=", tab, " module=", module_id)
    app <- create_logged_in_app()
    on.exit(stop_app_safely(app), add = TRUE)
    assert_logged_in(app)
    assert_ai_button_works(app, tab, module_id, wait_ms = 3000)
    stop_app_safely(app)
  }
})
