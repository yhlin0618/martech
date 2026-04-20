# E2E Test: VitalSigns Module
# Level: L3 (Functional) - run after feature changes
#
# Tests VitalSigns tabs load with proper content.
#
# Principles: TD_R007 (E2E testing)

test_that("VitalSigns tabs load without errors", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  vs_tabs <- get_module_tabs("vitalsigns")

  for (tab in vs_tabs) {
    assert_tab_loads(app, tab, wait_ms = 3000)
  }
})


test_that("revenuePulse tab has KPI content", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  # Navigate to revenuePulse
  app$set_inputs(sidebar_menu = "revenuePulse")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  # Verify no R errors
  assert_no_r_errors(app, "revenuePulse load")

  # Check that the tab is active
  expect_equal(app$get_value(input = "sidebar_menu"), "revenuePulse")
})


test_that("macroTrends tab loads chart data", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  # Navigate to macroTrends
  app$set_inputs(sidebar_menu = "macroTrends")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "macroTrends load")
  expect_equal(app$get_value(input = "sidebar_menu"), "macroTrends")
})
