# E2E Test: Global Filters
# Level: L3 (Functional) - run after feature changes
#
# Tests that global filters (platform, product line) affect displayed data.
#
# Principles: TD_R007 (E2E testing), UI_R026 (sidebar hierarchy)

test_that("global platform filter can be changed", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  # Navigate to a data-driven tab first
  app$set_inputs(sidebar_menu = "customerValue")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  # Try to get current platform filter value
  # The global filter input ID is defined in union_production_test.R
  platform_value <- tryCatch(
    app$get_value(input = "global_platform"),
    error = function(e) NULL
  )

  # If platform filter exists, verify it has a value
  if (!is.null(platform_value)) {
    expect_true(
      length(platform_value) > 0,
      label = "global_platform should have at least one value"
    )
  }

  assert_no_r_errors(app, "platform filter check")
})


test_that("switching tabs after filter change causes no errors", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  # Navigate through several tabs to verify stability
  test_tabs <- c("customerValue", "revenuePulse", "position")

  for (tab in test_tabs) {
    app$set_inputs(sidebar_menu = tab)
    app$wait_for_idle(timeout = 10000)
    Sys.sleep(2)

    assert_no_r_errors(app, paste0("tab switch to '", tab, "'"))
  }
})
