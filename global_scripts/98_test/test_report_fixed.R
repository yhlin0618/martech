# =============================================================================
# test_report_fixed.R
# Test script for fixed Report Integration module
# =============================================================================
# @principle MP099 Real-time progress reporting and monitoring
# @principle MP106 Console Output Transparency
# @principle R113 Four-part script structure
# =============================================================================

# SECTION 1: INITIALIZE -------------------------------------------------------

message("=== Testing Fixed Report Integration Module ===")
message("This test verifies:")
message("1. Debug logs appear in console only (MP106)")
message("2. Progress bar shows in bottom-right (MP099)")
message("3. Report displays correctly after generation")
message("4. No debug panels in UI")
message("")

# Load required libraries
library(shiny)
library(bs4Dash)
library(shinyjs)

# Source the fixed report module
source("scripts/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R")

# SECTION 2: MAIN -------------------------------------------------------------

# Create mock module results for testing
create_mock_module_results <- function() {
  # Create mock data matching real module structure
  mock_kpi_data <- reactive({
    data.frame(
      revenue = runif(10, 1000, 10000),
      rating = runif(10, 3, 5),
      sales = sample(100:1000, 10)
    )
  })

  mock_position_data <- reactive({
    data.frame(
      product_id = c("P001", "P002", "P003", "Ideal"),
      brand = c("Brand A", "Brand B", "Brand C", "Ideal"),
      rating = c(4.2, 4.5, 3.8, 5.0)
    )
  })

  # Mock AI analysis text
  mock_ai_text <- reactive({
    "### 策略分析結果\n\n**關鍵發現：**\n- 品牌定位強勢\n- 市場份額穩定成長\n- 客戶滿意度提升\n\n**建議行動：**\n1. 持續優化產品線\n2. 擴大市場推廣"
  })

  mock_comment_text <- reactive({
    "### 市場賽道分析\n\n**競爭態勢：**\n- 市場集中度提高\n- 新進入者威脅低\n- 替代品威脅中等"
  })

  # Return reactive structure
  reactive({
    list(
      vital_signs = list(
        micro_macro_kpi = list(
          kpi_data = mock_kpi_data
        ),
        dna_distribution = list(
          data = reactive(data.frame(dna_type = c("A", "B", "C"), count = c(10, 20, 30)))
        )
      ),
      tagpilot = list(
        customer_dna = list(
          data = reactive(data.frame(customer_id = 1:5, dna_score = runif(5, 0, 100)))
        )
      ),
      brandedge = list(
        position_strategy = list(
          ai_analysis_result = mock_ai_text
        ),
        position_table = list(
          position_data = mock_position_data
        )
      ),
      insightforge = list(
        poisson_comment = mock_comment_text
      )
    )
  })
}

# Create test application
test_ui <- bs4DashPage(
  title = "Fixed Report Integration Test",
  header = bs4DashNavbar(
    title = "Report Module Test - Console Logs Only",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        "Watch console for debug messages",
        style = "color: #fff; padding: 15px;"
      )
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    shinyjs::useShinyjs(),

    # Instructions
    fluidRow(
      column(
        width = 12,
        bs4Card(
          title = "Test Instructions",
          status = "info",
          width = 12,
          solidHeader = TRUE,
          tags$ol(
            tags$li("Click 'Generate Report' button below"),
            tags$li("Watch the console/terminal for debug messages (MP106)"),
            tags$li("Watch bottom-right corner for progress bar (MP099)"),
            tags$li("Report should display after generation completes"),
            tags$li("No debug panels should appear in UI")
          )
        )
      )
    ),

    # Report module
    fluidRow(
      column(
        width = 3,
        bs4Card(
          title = "Report Controls",
          status = "primary",
          width = 12,
          solidHeader = TRUE,
          actionButton(
            "report-generate_report",
            "Generate Report",
            icon = icon("magic"),
            class = "btn-primary btn-block"
          ),
          hr(),
          tags$small(
            "Debug logs should appear in console only",
            style = "color: #666;"
          )
        )
      ),
      column(
        width = 9,
        bs4Card(
          title = "Report Display",
          status = "success",
          width = 12,
          solidHeader = TRUE,
          reportIntegrationUI("report")
        )
      )
    )
  )
)

test_server <- function(input, output, session) {
  # Create mock module results
  mock_results <- create_mock_module_results()

  # Initialize report module
  report_module <- reportIntegrationServer(
    "report",
    app_data_connection = NULL,
    module_results = mock_results
  )

  # Add observer to monitor report generation
  observeEvent(report_module$report_html(), {
    if (!is.null(report_module$report_html())) {
      message("\n=== REPORT HTML GENERATED SUCCESSFULLY ===")
      message(sprintf("Report length: %d characters", nchar(report_module$report_html())))
    }
  })

  observeEvent(report_module$data_loaded(), {
    if (report_module$data_loaded()) {
      message("\n=== MODULE DATA LOADED SUCCESSFULLY ===")
    }
  })
}

# SECTION 3: TEST -------------------------------------------------------------

# Create and run test app
message("\n=== Starting Test Application ===")
message("The app will open in your browser.")
message("Console messages will appear here.\n")

test_app <- shinyApp(
  ui = test_ui,
  server = test_server
)

# SECTION 4: DEINITIALIZE -----------------------------------------------------

# Run the app
runApp(test_app, port = 8899, launch.browser = TRUE)

message("\n=== Test Complete ===")
message("If the test was successful, you should have seen:")
message("1. Debug messages in console only")
message("2. Progress bar in bottom-right corner")
message("3. Report displayed after generation")
message("4. No debug panels in UI")