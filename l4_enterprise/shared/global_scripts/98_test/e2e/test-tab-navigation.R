# E2E Test: Tab Navigation
# Level: L2 (Navigation) - run on every commit
#
# Tests that every sidebar tab can be switched to without R errors.
# Uses a single logged-in AppDriver for efficiency.
#
# Principles: TD_R007 (E2E testing)

test_that("all sidebar tabs can be navigated without R errors", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  # Verify login worked
  assert_logged_in(app)

  all_tabs <- get_all_tab_names()

  for (tab in all_tabs) {
    # Switch to tab and verify no errors
    app$set_inputs(sidebar_menu = tab)
    app$wait_for_idle(timeout = 10000)
    Sys.sleep(1)

    # Get logs and check for errors
    logs <- app$get_logs()
    recent_errors <- logs[
      logs$type == "shiny" &
      grepl("error", logs$message, ignore.case = TRUE),
    ]

    expect_equal(
      nrow(recent_errors), 0,
      label = paste0("Tab '", tab, "' should load without R errors"),
      info = if (nrow(recent_errors) > 0) {
        paste(recent_errors$message, collapse = "\n")
      }
    )

    # Verify tab is active
    current <- app$get_value(input = "sidebar_menu")
    expect_equal(current, tab,
      label = paste0("sidebar_menu should be '", tab, "' after clicking")
    )
  }
})
