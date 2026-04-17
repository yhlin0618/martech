# =============================================================================
# test_report_auto_loading.R
# Test script for enhanced Report Integration with auto-loading
# =============================================================================
# @principle MP099 Real-time progress reporting and monitoring
# @principle MP106 Console Output Transparency
# @principle R116 Enhanced Data Access with tbl2
# @principle MP052 Unidirectional Data Flow
# =============================================================================

# Initialize test environment -------------------------------------------------
cat("Initializing test environment for Report Auto-Loading...\n")

# Source the required components
source("scripts/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R")

# Create a minimal test app ---------------------------------------------------
library(shiny)
library(bs4Dash)
library(shinyjs)

# Create mock module results structure
create_mock_module_results <- function() {
  # Create mock data for each module
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

  mock_ai_analysis <- reactive({
    "This is a mock AI analysis text for testing purposes."
  })

  # Return reactive structure matching real module results
  reactive({
    list(
      vital_signs = list(
        micro_macro_kpi = list(
          kpi_data = mock_kpi_data,
          component_status = reactive("ready")
        ),
        dna_distribution = list(
          data = reactive(data.frame(dna_type = c("A", "B", "C"), count = c(10, 20, 30))),
          component_status = reactive("ready")
        )
      ),
      tagpilot = list(
        customer_dna = list(
          data = reactive(data.frame(customer_id = 1:5, dna_score = runif(5, 0, 100))),
          component_status = reactive("ready")
        )
      ),
      brandedge = list(
        position_strategy = list(
          ai_analysis_result = mock_ai_analysis,
          component_status = reactive("ready")
        ),
        position_table = list(
          position_data = mock_position_data,
          component_status = reactive("ready")
        )
      ),
      insightforge = list(
        poisson_comment = list(
          result = mock_ai_analysis,
          component_status = reactive("ready")
        )
      )
    )
  })
}

# Test UI
test_ui <- bs4DashPage(
  title = "Report Auto-Loading Test",
  header = bs4DashNavbar(
    title = "Test Report Integration"
  ),
  sidebar = bs4DashSidebar(
    disable = TRUE
  ),
  body = bs4DashBody(
    shinyjs::useShinyjs(),

    fluidRow(
      column(
        width = 4,
        bs4Card(
          title = "Report Controls",
          status = "primary",
          solidHeader = TRUE,
          width = 12,

          # Report component filter UI
          reportIntegrationComponent("report")$ui$filter,

          hr(),

          # Test controls
          h5("Test Controls"),
          actionButton(
            "check_modules",
            "Check Module Status",
            class = "btn-info btn-block"
          ),
          br(),
          verbatimTextOutput("module_check_output")
        )
      ),

      column(
        width = 8,
        bs4Card(
          title = "Report Output",
          status = "success",
          solidHeader = TRUE,
          width = 12,

          # Report component display UI
          reportIntegrationComponent("report")$ui$display
        )
      )
    )
  )
)

# Test Server
test_server <- function(input, output, session) {

  # Create mock module results
  mock_module_results <- create_mock_module_results()

  # Initialize report component with mock data
  report_results <- reportIntegrationComponent("report")$server(
    input, output, session,
    module_results = mock_module_results
  )

  # Check module status
  output$module_check_output <- renderText({
    req(input$check_modules)

    isolate({
      status_text <- "Module Status Check:\n"
      status_text <- paste0(status_text, "===================\n")

      # Check if module results are accessible
      if (!is.null(mock_module_results)) {
        mod_res <- mock_module_results()

        # Check each module category
        status_text <- paste0(status_text,
          "✓ Vital Signs: ",
          ifelse(!is.null(mod_res$vital_signs), "Available", "Missing"), "\n")

        status_text <- paste0(status_text,
          "✓ TagPilot: ",
          ifelse(!is.null(mod_res$tagpilot), "Available", "Missing"), "\n")

        status_text <- paste0(status_text,
          "✓ BrandEdge: ",
          ifelse(!is.null(mod_res$brandedge), "Available", "Missing"), "\n")

        status_text <- paste0(status_text,
          "✓ InsightForge: ",
          ifelse(!is.null(mod_res$insightforge), "Available", "Missing"), "\n")

        status_text <- paste0(status_text, "\n")

        # Check report component status
        if (!is.null(report_results)) {
          status_text <- paste0(status_text, "Report Component Status:\n")

          if (!is.null(report_results$data_loaded)) {
            loaded <- report_results$data_loaded()
            status_text <- paste0(status_text,
              "- Data Loaded: ", ifelse(loaded, "Yes", "No"), "\n")
          }

          if (!is.null(report_results$module_loading_status)) {
            loading_status <- report_results$module_loading_status()
            if (length(loading_status) > 0) {
              status_text <- paste0(status_text, "- Loading Status:\n")
              for (module in names(loading_status)) {
                status_text <- paste0(status_text,
                  "  ", module, ": ", loading_status[[module]], "\n")
              }
            }
          }
        }
      } else {
        status_text <- paste0(status_text, "ERROR: No module results available\n")
      }

      status_text
    })
  })

  # Add observer for debugging
  observe({
    if (!is.null(report_results$debug_messages)) {
      debug_msg <- report_results$debug_messages()
      if (nzchar(debug_msg)) {
        cat("=== Report Debug Output ===\n")
        cat(debug_msg)
        cat("===========================\n")
      }
    }
  })
}

# Run test app -----------------------------------------------------------------
cat("\n")
cat("========================================\n")
cat("Report Auto-Loading Test Instructions:\n")
cat("========================================\n")
cat("1. Click 'Check Module Status' to verify mock modules are available\n")
cat("2. Click '生成整合報告' (Generate Report) to test auto-loading\n")
cat("3. Watch the loading status indicators update automatically\n")
cat("4. Verify that data loads without navigating to other modules\n")
cat("5. Check console output for debug messages\n")
cat("\n")

# Create and run the app
app <- shinyApp(ui = test_ui, server = test_server)

# Try to run the app
tryCatch({
  runApp(app, port = 8765, launch.browser = TRUE)
}, error = function(e) {
  cat("Error running test app: ", e$message, "\n")
  cat("You may need to run this script interactively in RStudio\n")
})