# E2E Test: BrandEdge Module
# Level: L2 (Data) + L3 (Functional)
#
# Tests that BrandEdge tabs load with data and charts render.
# Requires df_position in app_data with at least one product line.
#
# Principles: TD_R007 (E2E testing), TD_P010 (Shiny App Testing Pyramid)


# --- L1: All BrandEdge tabs load without R errors ---

test_that("all BrandEdge tabs load without R errors", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  brandedge_tabs <- get_module_tabs("brandedge")

  for (tab in brandedge_tabs) {
    assert_tab_loads(app, tab, wait_ms = 3000)
  }
})


# --- L2: Position table has data after selecting product line ---

test_that("position tab shows DataTable with data for sfo", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)

  # Select product line with most data
  select_product_line(app, "sfo")

  # Navigate to position tab
  app$set_inputs(sidebar_menu = "position")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "position tab with sfo")
  assert_datatable_has_rows(app, "position", min_rows = 1)
})


test_that("position tab shows DataTable with data for blb", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "blb")

  app$set_inputs(sidebar_menu = "position")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "position tab with blb")
  assert_datatable_has_rows(app, "position", min_rows = 1)
})


# --- L2: Plotly charts render ---

test_that("positionDNA tab renders plotly chart", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "sfo")

  app$set_inputs(sidebar_menu = "positionDNA")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(5)  # Plotly needs extra time

  assert_no_r_errors(app, "positionDNA tab")
  assert_plotly_rendered(app, "positionDNA")
})


test_that("positionMS tab renders chart", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "sfo")

  app$set_inputs(sidebar_menu = "positionMS")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(5)

  assert_no_r_errors(app, "positionMS tab")
  # MS (Market Segmentation) may require cluster analysis data not yet available
  # Only assert no error for now; content verification added when cluster pipeline is ready
})


# --- L2: Analysis tabs have content ---

test_that("positionKFE tab has analysis content", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "sfo")

  app$set_inputs(sidebar_menu = "positionKFE")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "positionKFE tab")
  assert_tab_has_content(app, "positionKFE")
})


test_that("positionIdealRate tab has content", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "sfo")

  app$set_inputs(sidebar_menu = "positionIdealRate")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "positionIdealRate tab")
  assert_tab_has_content(app, "positionIdealRate")
})


test_that("positionStrategy tab loads without errors", {
  app <- create_logged_in_app()
  on.exit(stop_app_safely(app), add = TRUE)

  assert_logged_in(app)
  select_product_line(app, "sfo")

  app$set_inputs(sidebar_menu = "positionStrategy")
  app$wait_for_idle(timeout = 10000)
  Sys.sleep(3)

  assert_no_r_errors(app, "positionStrategy tab")
})
