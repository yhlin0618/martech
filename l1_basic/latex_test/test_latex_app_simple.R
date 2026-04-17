# =============================================================================
# Simple LaTeX Test App
# Purpose: Minimal app to test API connectivity in Shiny environment
# =============================================================================

# Load required packages
library(shiny)
library(dotenv)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Source utility functions
source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")

# UI
ui <- fluidPage(
  titlePanel("Simple LaTeX Test"),
  
  fluidRow(
    column(6,
           h4("API Test"),
           actionButton("test_api", "Test API Connection", class = "btn-primary"),
           br(), br(),
           verbatimTextOutput("api_result")
    ),
    column(6,
           h4("Data Test"),
           actionButton("test_data", "Test Data Collection", class = "btn-success"),
           br(), br(),
           verbatimTextOutput("data_result")
    )
  ),
  
  hr(),
  
  fluidRow(
    column(12,
           h4("Full Module Test"),
           actionButton("test_module", "Test Full Module", class = "btn-warning"),
           br(), br(),
           verbatimTextOutput("module_result")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Test API connection
  observeEvent(input$test_api, {
    output$api_result <- renderText({
      "Testing API connection..."
    })
    
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    
    if (api_key == "" || !grepl("^sk-", api_key)) {
      output$api_result <- renderText("Invalid API key")
      return()
    }
    
    tryCatch({
      response <- httr::GET(
        url = "https://api.openai.com/v1/models",
        httr::add_headers(
          "Authorization" = paste("Bearer", api_key)
        ),
        httr::timeout(30)
      )
      
      if (response$status_code == 200) {
        output$api_result <- renderText("✓ API connection successful")
      } else {
        output$api_result <- renderText(paste("✗ API failed:", response$status_code))
      }
    }, error = function(e) {
      output$api_result <- renderText(paste("✗ API error:", e$message))
    })
  })
  
  # Test data collection
  observeEvent(input$test_data, {
    output$data_result <- renderText({
      "Testing data collection..."
    })
    
    # Create test data
    test_data <- data.frame(
      customer_id = paste0("customer_", 1:5),
      lineitem_price = c(100, 200, 300, 400, 500),
      payment_time = Sys.time()
    )
    
    tryCatch({
      result <- fn_collect_report_data(
        sales_data = test_data,
        verbose = FALSE
      )
      
      output$data_result <- renderText({
        paste("✓ Data collection successful\n",
              "Transactions:", result$sales_summary$total_transactions,
              "Revenue:", result$sales_summary$total_revenue)
      })
    }, error = function(e) {
      output$data_result <- renderText(paste("✗ Data error:", e$message))
    })
  })
  
  # Test full module
  observeEvent(input$test_module, {
    output$module_result <- renderText({
      "Testing full module..."
    })
    
    # Create test data
    test_data <- data.frame(
      customer_id = paste0("customer_", 1:5),
      lineitem_price = c(100, 200, 300, 400, 500),
      payment_time = Sys.time()
    )
    
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    
    if (api_key == "" || !grepl("^sk-", api_key)) {
      output$module_result <- renderText("Invalid API key")
      return()
    }
    
    tryCatch({
      # Collect data
      report_data <- fn_collect_report_data(
        sales_data = test_data,
        verbose = FALSE
      )
      
      # Generate LaTeX
      result <- fn_generate_latex_via_gpt(
        report_data = report_data,
        api_key = api_key,
        model = "gpt-3.5-turbo",
        temperature = 0.7,
        max_tokens = 500,
        verbose = FALSE
      )
      
      if (!is.null(result$error)) {
        output$module_result <- renderText(paste("✗ Module error:", result$error))
      } else {
        output$module_result <- renderText({
          paste("✓ Module successful\n",
                "LaTeX length:", nchar(result$latex), "characters\n",
                "First 100 chars:", substr(result$latex, 1, 100))
        })
      }
    }, error = function(e) {
      output$module_result <- renderText(paste("✗ Module error:", e$message))
    })
  })
}

# Run app
shinyApp(ui = ui, server = server) 