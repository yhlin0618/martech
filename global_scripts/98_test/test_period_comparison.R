# ============================================================
# test_period_comparison.R
# Test Suite for Period Comparison Functionality
# Created: 2025-09-23
# Principle: R75 (Test Script Initialization), MP51 (Test Data Design)
# ============================================================

# ---- 1. Initialize Test Environment ----
library(shiny)
library(testthat)
library(DT)
library(plotly)
library(dplyr)
library(lubridate)

# Source the components
source("scripts/global_scripts/10_rshinyapp_components/periodComparison/periodComparisonUI.R")
source("scripts/global_scripts/10_rshinyapp_components/periodComparison/periodComparisonServer.R")
source("scripts/global_scripts/10_rshinyapp_components/periodComparison/periodComparisonDefaults.R")
source("scripts/global_scripts/04_utils/fn_calculate_period_comparison.R")

# ---- 2. Create Test Data (MP51) ----
create_test_sales_data <- function(start_date = "2024-01-01",
                                   end_date = "2024-12-31",
                                   trend = "growth") {
  dates <- seq.Date(as.Date(start_date), as.Date(end_date), by = "day")
  n_days <- length(dates)

  # Base values with trend
  if (trend == "growth") {
    base_revenue <- 10000 + seq(0, 5000, length.out = n_days)
    base_customers <- 100 + seq(0, 50, length.out = n_days)
  } else if (trend == "decline") {
    base_revenue <- 15000 - seq(0, 5000, length.out = n_days)
    base_customers <- 150 - seq(0, 50, length.out = n_days)
  } else {
    base_revenue <- rep(10000, n_days)
    base_customers <- rep(100, n_days)
  }

  # Add seasonality and noise
  data.frame(
    date = dates,
    revenue = base_revenue + rnorm(n_days, 0, 1000) +
              sin(seq(0, 2*pi, length.out = n_days)) * 2000,
    customers = round(base_customers + rnorm(n_days, 0, 10)),
    orders = round(base_customers * runif(n_days, 1.2, 1.8))
  )
}

# ---- 3. Test Period Comparison Calculations ----
test_that("Period comparison calculations work correctly", {
  # Create test data
  test_data <- create_test_sales_data()

  # Test monthly aggregation
  result_monthly <- calculate_period_comparison(
    test_data,
    period_type = "monthly",
    comparison_type = "period_over_period"
  )

  expect_true("period" %in% names(result_monthly))
  expect_true("revenue_prev" %in% names(result_monthly))
  expect_true("revenue_diff" %in% names(result_monthly))
  expect_true("revenue_rate" %in% names(result_monthly))

  # Check that first period has NA for previous
  expect_true(is.na(result_monthly$revenue_prev[1]))

  # Check that second period has valid comparison
  if (nrow(result_monthly) > 1) {
    expect_false(is.na(result_monthly$revenue_prev[2]))
    expect_equal(
      result_monthly$revenue_diff[2],
      result_monthly$revenue[2] - result_monthly$revenue_prev[2]
    )
  }
})

test_that("Year-over-year comparison works", {
  # Create 2 years of data
  test_data <- create_test_sales_data(
    start_date = "2023-01-01",
    end_date = "2024-12-31"
  )

  result_yoy <- calculate_period_comparison(
    test_data,
    period_type = "monthly",
    comparison_type = "year_over_year"
  )

  # Check that YoY comparison looks back 12 months
  if (nrow(result_yoy) > 12) {
    # Month 13 should compare with month 1
    expect_false(is.na(result_yoy$revenue_prev[13]))
  }
})

test_that("Different period types aggregate correctly", {
  test_data <- create_test_sales_data()

  # Test different period types
  for (period_type in c("daily", "weekly", "monthly", "quarterly", "yearly")) {
    result <- calculate_period_comparison(
      test_data,
      period_type = period_type
    )

    expect_true("period" %in% names(result))
    expect_true(nrow(result) > 0)

    # Check aggregation worked
    if (period_type != "daily") {
      expect_true(nrow(result) < nrow(test_data))
    }
  }
})

# ---- 4. Test Shiny Module ----
test_that("Period comparison module can be created", {
  # Test UI creation
  ui <- periodComparisonUI("test")
  expect_true(inherits(ui, "shiny.tag.list"))

  # Test defaults
  defaults <- periodComparisonDefaults()
  expect_true(is.list(defaults))
  expect_true("period_types" %in% names(defaults))
  expect_true("default_metrics" %in% names(defaults))
})

# ---- 5. Test App with Period Comparison ----
if (interactive()) {
  # Create test app
  test_app <- shinyApp(
    ui = fluidPage(
      titlePanel("Period Comparison Test App"),
      sidebarLayout(
        sidebarPanel(
          h3("Test Controls"),
          selectInput(
            "data_trend",
            "Data Trend:",
            choices = c("growth", "decline", "flat"),
            selected = "growth"
          ),
          actionButton("regenerate", "Regenerate Data", icon = icon("refresh"))
        ),
        mainPanel(
          periodComparisonUI("period_test")
        )
      )
    ),

    server = function(input, output, session) {
      # Create reactive test data
      test_data <- reactive({
        input$regenerate  # Trigger on button press
        create_test_sales_data(
          start_date = Sys.Date() - 365,
          end_date = Sys.Date(),
          trend = isolate(input$data_trend)
        )
      })

      # Create mock database connection
      mock_db <- list(
        data = test_data,
        type = "mock"
      )

      # Mock tbl2 function for testing
      tbl2 <- function(db, table_name) {
        if (db$type == "mock") {
          return(db$data())
        }
        stop("Only mock database supported in test")
      }

      # Call period comparison module
      comparison_result <- periodComparisonServer(
        "period_test",
        db_connection = mock_db,
        data_source = "test_sales",
        metrics = c("revenue", "customers", "orders")
      )
    }
  )

  # Run test app
  message("Running Period Comparison Test App...")
  message("This app demonstrates the period comparison functionality.")
  message("Try different period types and comparison methods.")
  runApp(test_app, launch.browser = TRUE)
}

# ---- 6. Performance Test ----
test_that("Period comparison handles large datasets efficiently", {
  # Create large dataset (3 years daily)
  large_data <- create_test_sales_data(
    start_date = "2022-01-01",
    end_date = "2024-12-31"
  )

  expect_true(nrow(large_data) > 1000)

  # Time the calculation
  start_time <- Sys.time()
  result <- calculate_period_comparison(
    large_data,
    period_type = "monthly",
    comparison_type = "period_over_period"
  )
  end_time <- Sys.time()

  time_taken <- as.numeric(end_time - start_time, units = "secs")

  # Should complete in reasonable time (< 1 second)
  expect_true(time_taken < 1)
  expect_true(nrow(result) > 0)
})

# ---- 7. Edge Cases ----
test_that("Period comparison handles edge cases", {
  # Empty data
  empty_data <- data.frame(
    date = as.Date(character()),
    revenue = numeric(),
    customers = numeric()
  )

  expect_error(
    calculate_period_comparison(empty_data),
    NA  # Should not error, just return empty
  )

  # Single day data
  single_day <- data.frame(
    date = as.Date("2024-01-01"),
    revenue = 10000,
    customers = 100
  )

  result <- calculate_period_comparison(single_day)
  expect_true(nrow(result) == 1)
  expect_true(is.na(result$revenue_prev[1]))

  # Missing values
  data_with_na <- create_test_sales_data()
  data_with_na$revenue[sample(nrow(data_with_na), 10)] <- NA

  result <- calculate_period_comparison(data_with_na)
  expect_true(nrow(result) > 0)
})

# ---- Summary ----
message("
========================================
Period Comparison Test Suite Complete
========================================
To run interactive test app, execute:
  source('scripts/global_scripts/98_test/test_period_comparison.R')
in an interactive R session.
")