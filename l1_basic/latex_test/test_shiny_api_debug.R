# =============================================================================
# Shiny API Debug Test
# Purpose: Test API connectivity specifically in Shiny environment
# =============================================================================

# Load required packages
library(shiny)
library(dotenv)
library(httr)
library(jsonlite)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# UI
ui <- fluidPage(
  titlePanel("Shiny API Debug Test"),
  
  fluidRow(
    column(6,
           h4("Basic API Test"),
           actionButton("test_basic", "Test Basic API", class = "btn-primary"),
           br(), br(),
           verbatimTextOutput("basic_result")
    ),
    column(6,
           h4("GPT API Test"),
           actionButton("test_gpt", "Test GPT API", class = "btn-success"),
           br(), br(),
           verbatimTextOutput("gpt_result")
    )
  ),
  
  hr(),
  
  fluidRow(
    column(12,
           h4("Environment Info"),
           verbatimTextOutput("env_info")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Environment info
  output$env_info <- renderText({
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    paste(
      "R Version:", R.version.string, "\n",
      "Shiny Version:", packageVersion("shiny"), "\n",
      "Interactive:", interactive(), "\n",
      "Reactive Domain:", !is.null(shiny::getDefaultReactiveDomain()), "\n",
      "API Key Length:", nchar(api_key), "\n",
      "API Key Format:", ifelse(grepl("^sk-", api_key), "Correct", "Incorrect"), "\n",
      "Working Directory:", getwd(), "\n",
      "SSL Certificate Path:", Sys.getenv("SSL_CERT_FILE"), "\n",
      "HTTP Proxy:", Sys.getenv("http_proxy"), "\n",
      "HTTPS Proxy:", Sys.getenv("https_proxy")
    )
  })
  
  # Basic API test
  observeEvent(input$test_basic, {
    output$basic_result <- renderText("Testing basic API connection...")
    
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    
    if (api_key == "" || !grepl("^sk-", api_key)) {
      output$basic_result <- renderText("Invalid API key")
      return()
    }
    
    tryCatch({
      # Test with different timeout values
      result <- httr::GET(
        url = "https://api.openai.com/v1/models",
        httr::add_headers(
          "Authorization" = paste("Bearer", api_key),
          "User-Agent" = "R-Shiny-Test/1.0"
        ),
        httr::timeout(30),
        httr::config(ssl_verifypeer = TRUE, ssl_verifyhost = TRUE)
      )
      
      if (result$status_code == 200) {
        models <- jsonlite::fromJSON(rawToChar(result$content))
        output$basic_result <- renderText({
          paste("✓ Basic API connection successful\n",
                "Status:", result$status_code, "\n",
                "Available models:", length(models$data), "\n",
                "Response time:", result$times["total"], "seconds")
        })
      } else {
        output$basic_result <- renderText({
          paste("✗ API failed with status:", result$status_code, "\n",
                "Response:", rawToChar(result$content))
        })
      }
    }, error = function(e) {
      output$basic_result <- renderText({
        paste("✗ API connection error:", e$message, "\n",
              "Error type:", class(e)[1])
      })
    })
  })
  
  # GPT API test
  observeEvent(input$test_gpt, {
    output$gpt_result <- renderText("Testing GPT API with simple request...")
    
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    
    if (api_key == "" || !grepl("^sk-", api_key)) {
      output$gpt_result <- renderText("Invalid API key")
      return()
    }
    
    tryCatch({
      # Simple test request
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        httr::add_headers(
          "Authorization" = paste("Bearer", api_key),
          "Content-Type" = "application/json",
          "User-Agent" = "R-Shiny-GPT-Test/1.0"
        ),
        body = list(
          model = "gpt-3.5-turbo",
          messages = list(
            list(role = "user", content = "Say 'Hello from Shiny!'")
          ),
          max_tokens = 50
        ),
        encode = "json",
        httr::timeout(60),  # Longer timeout for GPT
        httr::config(ssl_verifypeer = TRUE, ssl_verifyhost = TRUE)
      )
      
      if (response$status_code == 200) {
        result <- jsonlite::fromJSON(rawToChar(response$content))
        output$gpt_result <- renderText({
          paste("✓ GPT API connection successful\n",
                "Response:", result$choices$message$content, "\n",
                "Tokens used:", result$usage$total_tokens, "\n",
                "Response time:", response$times["total"], "seconds")
        })
      } else {
        output$gpt_result <- renderText({
          paste("✗ GPT API failed with status:", response$status_code, "\n",
                "Response:", rawToChar(response$content))
        })
      }
    }, error = function(e) {
      output$gpt_result <- renderText({
        paste("✗ GPT API connection error:", e$message, "\n",
              "Error type:", class(e)[1], "\n",
              "Error details:", toString(e))
      })
    })
  })
}

# Run app
shinyApp(ui = ui, server = server) 