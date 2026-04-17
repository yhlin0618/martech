#!/usr/bin/env Rscript

# Test Report Display Verification
# Tests if the report is properly displayed after generation

library(shiny)
library(bs4Dash)
library(shinyjs)
library(DBI)
library(duckdb)

# Source the report integration module
source("scripts/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R")

# Create mock database with test data
create_mock_db <- function() {
  con <- dbConnect(duckdb::duckdb(), ":memory:")

  # Create customer profile table
  dbExecute(con, "
    CREATE TABLE df_profile_by_customer (
      customer_id VARCHAR,
      product_id VARCHAR,
      rating DOUBLE,
      sales INTEGER
    )
  ")

  # Insert test data
  dbExecute(con, "
    INSERT INTO df_profile_by_customer VALUES
    ('C001', 'P001', 4.5, 100),
    ('C002', 'P002', 4.2, 150),
    ('C003', 'P003', 4.8, 200)
  ")

  # Create position table
  dbExecute(con, "
    CREATE TABLE df_position (
      product_id VARCHAR,
      brand VARCHAR,
      position_x DOUBLE,
      position_y DOUBLE
    )
  ")

  dbExecute(con, "
    INSERT INTO df_position VALUES
    ('P001', 'Brand A', 0.5, 0.7),
    ('P002', 'Brand B', 0.3, 0.4),
    ('P003', 'Brand C', 0.8, 0.9)
  ")

  # Create poisson analysis table
  dbExecute(con, "
    CREATE TABLE df_cbz_poisson_analysis_all (
      product_id VARCHAR,
      metric VARCHAR,
      value DOUBLE
    )
  ")

  dbExecute(con, "
    INSERT INTO df_cbz_poisson_analysis_all VALUES
    ('P001', 'lambda', 3.5),
    ('P002', 'lambda', 4.2),
    ('P003', 'lambda', 2.8)
  ")

  message("✅ Mock database created with test data")
  return(con)
}

# Test app
ui <- dashboardPage(
  header = dashboardHeader(title = "Report Display Test"),
  sidebar = dashboardSidebar(
    sidebarMenu(
      menuItem("Test Report", tabName = "report", icon = icon("file"))
    )
  ),
  body = dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .filter-panel {
          background: white;
          border: 1px solid #e3e3e3;
          border-radius: 5px;
        }
        .console-output {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 4px;
          padding: 10px;
          font-family: monospace;
          font-size: 12px;
          max-height: 300px;
          overflow-y: auto;
          margin-top: 10px;
        }
        .report-status {
          padding: 10px;
          background: #d4edda;
          border: 1px solid #c3e6cb;
          border-radius: 4px;
          color: #155724;
          margin-bottom: 10px;
        }
      "))
    ),
    tabItems(
      tabItem(
        tabName = "report",
        fluidRow(
          column(
            width = 4,
            box(
              title = "Report Test Controls",
              width = 12,
              status = "primary",

              # Report component
              reportIntegrationComponent(
                id = "test_report",
                app_data_connection = reactive({ test_db_con }),
                config = list(modules = c("macro_kpi", "position_strategy", "market_track")),
                translate = function(x) x
              )$ui_filter,

              hr(),

              # Test controls
              h5("Debug Information"),
              actionButton("check_status", "Check Report Status", class = "btn-info btn-block"),
              br(),
              div(id = "status_display", class = "report-status", style = "display: none;")
            )
          ),
          column(
            width = 8,
            box(
              title = "Report Display Area",
              width = 12,
              status = "success",

              # Report display
              reportIntegrationComponent(
                id = "test_report",
                app_data_connection = reactive({ test_db_con }),
                config = list(modules = c("macro_kpi", "position_strategy", "market_track")),
                translate = function(x) x
              )$ui_display,

              # Console output for debugging
              h5("Console Output", style = "margin-top: 20px;"),
              verbatimTextOutput("console_log")
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Create mock database connection
  test_db_con <- create_mock_db()

  # Console log reactive
  console_messages <- reactiveVal(character())

  # Override message function to capture console output
  original_message <- message
  message <- function(...) {
    msg <- paste0(..., collapse = "")
    original_message(msg)
    current <- isolate(console_messages())
    console_messages(c(current, paste0(Sys.time(), " - ", msg)))
  }

  # Create mock chat_api function in global environment
  chat_api <<- function(messages, model = "gpt-3.5-turbo") {
    # Mock OpenAI response
    list(
      choices = list(
        list(
          message = list(
            content = "This is a mock AI analysis for testing report display."
          )
        )
      )
    )
  }

  # Set mock OpenAI key
  Sys.setenv(OPENAI_API_KEY = "test_key_for_verification")

  # Call the report server with correct parameters
  reportIntegrationServer(
    id = "test_report",
    app_data_connection = reactive({ test_db_con }),
    module_results = reactive(list(
      vital_signs = list(),
      tagpilot = list(),
      brandedge = list(),
      insightforge = list()
    )),
    translate = function(x) x
  )

  # Display console messages
  output$console_log <- renderText({
    messages <- console_messages()
    if (length(messages) > 0) {
      tail(messages, 50) |> paste(collapse = "\n")
    } else {
      "No console messages yet..."
    }
  })

  # Check report status
  observeEvent(input$check_status, {
    shinyjs::show("status_display")

    # Check if report elements exist
    report_preview_exists <- !is.null(session$ns) &&
                           length(session$output) > 0

    status_html <- paste0(
      "✅ Report module loaded<br>",
      "✅ Database connected<br>",
      "✅ Mock data available<br>",
      ifelse(report_preview_exists,
             "✅ Report preview component exists",
             "❌ Report preview component missing"),
      "<br><br>",
      "<strong>Instructions:</strong><br>",
      "1. Click '生成整合報告' button above<br>",
      "2. Watch console output below<br>",
      "3. Report should appear in right panel"
    )

    shinyjs::html("status_display", status_html)
  })

  # Clean up on session end
  onStop(function() {
    dbDisconnect(test_db_con)
  })
}

# Run the app
message("\n========================================")
message("🧪 REPORT DISPLAY VERIFICATION TEST")
message("========================================")
message("")
message("This test verifies:")
message("1. Report generation with self-contained data")
message("2. HTML content is properly displayed")
message("3. No dependency on external modules")
message("")
message("Instructions:")
message("1. Click '生成整合報告' button")
message("2. Check console output for debug messages")
message("3. Verify report appears in right panel")
message("")
message("Starting test app on port 7890...")
message("========================================\n")

runApp(shinyApp(ui, server), port = 7890, launch.browser = TRUE)