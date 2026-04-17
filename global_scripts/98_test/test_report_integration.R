#' @title Test Report Integration Module
#' @description Test script to validate that report integration properly collects data from all modules
#' @principle MP56 Connected Component Principle
#' @principle R091 Universal Data Access Pattern
#' @principle MP81 Explicit Parameter Specification

# Load required libraries
library(shiny)
library(bs4Dash)
library(dplyr)

# Source required components
source("scripts/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R")

# Test the extract_reactive_value function
test_extract_reactive_value <- function() {
  cat("\n=== Testing extract_reactive_value function ===\n")

  # Test 1: Extract from normal value
  test1 <- extract_reactive_value(42)
  cat("Test 1 (normal value):", test1, "\n")
  stopifnot(test1 == 42)

  # Test 2: Extract from reactive
  test_reactive <- reactive({ "reactive_value" })
  test2 <- extract_reactive_value(test_reactive)
  cat("Test 2 (reactive):", test2, "\n")
  stopifnot(test2 == "reactive_value")

  # Test 3: Extract from list with field
  test_list <- list(data = "list_data", value = "list_value")
  test3 <- extract_reactive_value(test_list, "data")
  cat("Test 3 (list with field):", test3, "\n")
  stopifnot(test3 == "list_data")

  # Test 4: Extract from nested reactive in list
  test_nested <- list(
    ai_analysis_result = reactive({ "AI analysis text" })
  )
  test4 <- extract_reactive_value(test_nested$ai_analysis_result)
  cat("Test 4 (nested reactive):", test4, "\n")
  stopifnot(test4 == "AI analysis text")

  # Test 5: Handle NULL gracefully
  test5 <- extract_reactive_value(NULL)
  cat("Test 5 (NULL):", is.null(test5), "\n")
  stopifnot(is.null(test5))

  cat("✅ All extract_reactive_value tests passed!\n\n")
}

# Test the report integration with mock module results
test_report_integration <- function() {
  cat("\n=== Testing Report Integration Module ===\n")

  # Create a test app with mock module results
  ui <- bs4DashPage(
    header = bs4DashNavbar(title = "Report Integration Test"),
    sidebar = bs4DashSidebar(
      bs4SidebarMenu(
        id = "sidebar_menu",
        bs4SidebarMenuItem("Report Center", tabName = "reportCenter", icon = icon("file-alt"))
      )
    ),
    body = bs4DashBody(
      bs4TabItems(
        bs4TabItem(
          tabName = "reportCenter",
          fluidRow(
            column(3, uiOutput("filter")),
            column(9, uiOutput("display"))
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    # Create mock module results
    module_results <- reactive({
      list(
        vital_signs = list(
          micro_macro_kpi = list(
            kpi_data = reactive({
              data.frame(
                metric = c("Revenue", "Growth", "Retention"),
                value = c(100000, 15.3, 87.2)
              )
            })
          ),
          dna_distribution = list(
            distribution_data = reactive({
              data.frame(
                segment = c("A", "B", "C"),
                count = c(100, 200, 150)
              )
            })
          )
        ),
        tagpilot = list(
          customer_dna = list(
            analysis_result = reactive({
              "Customer DNA analysis completed"
            })
          )
        ),
        brandedge = list(
          position_strategy = list(
            ai_analysis_result = reactive({
              "品牌定位策略：\n1. 強化差異化優勢\n2. 聚焦目標市場\n3. 提升品牌價值"
            }),
            strategy_result = reactive({
              data.frame(
                quadrant = c("Q1", "Q2", "Q3", "Q4"),
                strategy = c("Differentiate", "Focus", "Cost", "Stuck")
              )
            })
          ),
          position_ms = list(
            segment_data = reactive({
              data.frame(
                segment = c("Premium", "Value", "Budget"),
                size = c(30, 50, 20)
              )
            })
          ),
          position_kfe = list(
            key_factors = reactive({
              data.frame(
                factor = c("Quality", "Price", "Service"),
                weight = c(0.4, 0.3, 0.3)
              )
            })
          )
        ),
        insightforge = list(
          poisson_comment = reactive({
            "市場賽道分析：產品在高評分賽道表現優異，建議持續強化品質優勢。"
          }),
          poisson_time = list(
            trend_data = reactive({
              data.frame(
                period = c("Morning", "Afternoon", "Evening"),
                sales = c(1000, 2000, 1500)
              )
            })
          ),
          poisson_feature = list(
            precision_data = reactive({
              data.frame(
                feature = c("Size", "Color", "Material"),
                impact = c(0.8, 0.6, 0.9)
              )
            })
          )
        )
      )
    })

    # Initialize report component
    report_comp <- reportIntegrationComponent("report")

    # Render UI
    output$filter <- renderUI({
      report_comp$ui$filter
    })

    output$display <- renderUI({
      report_comp$ui$display
    })

    # Initialize server with module results
    report_res <- report_comp$server(input, output, session, module_results)

    # Test data extraction
    observe({
      cat("\n--- Testing Module Results Extraction ---\n")

      mod_res <- module_results()

      # Test KPI data extraction
      kpi_data <- extract_reactive_value(mod_res$vital_signs$micro_macro_kpi, "kpi_data")
      if (!is.null(kpi_data)) {
        cat("✅ KPI data extracted successfully\n")
        print(head(kpi_data, 2))
      } else {
        cat("❌ Failed to extract KPI data\n")
      }

      # Test AI analysis extraction
      ai_text <- extract_reactive_value(mod_res$brandedge$position_strategy, "ai_analysis_result")
      if (!is.null(ai_text) && nzchar(ai_text)) {
        cat("✅ AI analysis extracted successfully\n")
        cat("  Preview:", substr(ai_text, 1, 50), "...\n")
      } else {
        cat("❌ Failed to extract AI analysis\n")
      }

      # Test market track extraction
      comment_text <- extract_reactive_value(mod_res$insightforge$poisson_comment)
      if (!is.null(comment_text) && nzchar(comment_text)) {
        cat("✅ Market track analysis extracted successfully\n")
        cat("  Preview:", substr(comment_text, 1, 50), "...\n")
      } else {
        cat("❌ Failed to extract market track analysis\n")
      }

      cat("\n✅ Module results extraction test completed!\n")
    })
  }

  # Create and return the test app
  shinyApp(ui, server)
}

# Run tests if executed directly
if (sys.nframe() == 0) {
  cat("====================================\n")
  cat("Report Integration Module Test Suite\n")
  cat("====================================\n")

  # Run unit tests
  test_extract_reactive_value()

  # Instructions for interactive test
  cat("\nTo test the full report integration:\n")
  cat("1. Run: app <- test_report_integration()\n")
  cat("2. Click on 'Report Center' in the sidebar\n")
  cat("3. Click '生成整合報告' button in the left filter panel\n")
  cat("4. Verify that the report includes data from all modules\n")
  cat("5. Check that all sections are properly populated\n\n")

  # Optional: Auto-run the app for interactive testing
  if (interactive()) {
    app <- test_report_integration()
    runApp(app)
  }
}