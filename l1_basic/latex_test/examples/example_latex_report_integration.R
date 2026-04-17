# =============================================================================
# Example: example_latex_report_integration
# Purpose: Demonstrate how to integrate LaTeX report module into existing app.R
# Author: Claude
# Date Created: 2025-01-27
# Related Principles: R21, R69, C01
# =============================================================================

# This example shows how to integrate the LaTeX report module into an existing
# Shiny application. It assumes you have the following modules already set up:
# - Login module (module_login.R)
# - Upload module (module_upload.R) 
# - DNA analysis module (module_dna.R)

# Load required packages
library(shiny)
library(dplyr)
library(DT)

# Source existing modules
source("modules/module_login.R")
source("modules/module_upload.R")
source("modules/module_dna.R")

# Source LaTeX report module
source("modules/module_latex_report.R")

# =============================================================================
# UI Definition
# =============================================================================

ui <- fluidPage(
  titlePanel("精準行銷分析平台 - 含 LaTeX 報告功能"),
  
  # Login UI
  loginModuleUI("login"),
  
  # Main content (only shown after login)
  conditionalPanel(
    condition = "output.logged_in == true",
    
    tabsetPanel(
      id = "main_tabs",
      
      # Data Upload Tab
      tabPanel("📁 資料上傳",
               uploadModuleUI("upload")),
      
      # DNA Analysis Tab  
      tabPanel("🧬 DNA 分析",
               dnaModuleUI("dna")),
      
      # LaTeX Report Tab
      tabPanel("📄 LaTeX 報告",
               latexReportModuleUI("latex_report")),
      
      # Settings Tab
      tabPanel("⚙️ 設定",
               h4("系統設定"),
               hr(),
               h5("LaTeX 編譯器設定"),
               textInput("latex_compiler_path", "編譯器路徑", 
                        value = "pdflatex", 
                        placeholder = "輸入 pdflatex 或 xelatex 的完整路徑"),
               actionButton("test_compiler", "測試編譯器", class = "btn-info"),
               textOutput("compiler_status"),
               hr(),
               h5("GPT API 設定"),
               passwordInput("default_api_key", "預設 API Key", 
                           placeholder = "輸入預設的 OpenAI API Key"),
               helpText("此 API Key 將作為 LaTeX 報告模組的預設值")
    )
  )
)

# =============================================================================
# Server Logic
# =============================================================================

server <- function(input, output, session) {
  
  # Database connection (mock for this example)
  con <- reactive({
    # In real application, this would be your actual database connection
    list(type = "mock", status = "connected")
  })
  
  # ===========================================================================
  # Login Module
  # ===========================================================================
  
  user_info <- loginModuleServer("login", con)
  
  # Login status for UI conditional display
  output$logged_in <- reactive({
    !is.null(user_info()) && user_info()$authenticated
  })
  outputOptions(output, "logged_in", suspendWhenHidden = FALSE)
  
  # ===========================================================================
  # Upload Module
  # ===========================================================================
  
  sales_data <- uploadModuleServer("upload", con, user_info)
  
  # ===========================================================================
  # DNA Analysis Module
  # ===========================================================================
  
  dna_results <- dnaModuleServer("dna", con, user_info, sales_data)
  
  # ===========================================================================
  # LaTeX Report Module
  # ===========================================================================
  
  # Prepare other results for LaTeX report
  other_results <- reactive({
    list(
      # Add any other analysis results here
      # customer_segments = customer_segments_data,
      # market_analysis = market_analysis_data,
      # recommendations = recommendations_data
    )
  })
  
  # Initialize LaTeX report module
  latex_report_results <- latexReportModuleServer(
    "latex_report",
    con = con,
    user_info = user_info,
    sales_data = sales_data,
    dna_results = dna_results,
    other_results = other_results
  )
  
  # ===========================================================================
  # Settings and Utilities
  # ===========================================================================
  
  # Test LaTeX compiler
  observeEvent(input$test_compiler, {
    compiler_path <- input$latex_compiler_path
    
    if (compiler_path == "") {
      output$compiler_status <- renderText("請輸入編譯器路徑")
      return()
    }
    
    # Test the compiler
    test_result <- tryCatch({
      system2(compiler_path, "--version", stdout = TRUE, stderr = TRUE)
      "編譯器測試成功！"
    }, error = function(e) {
      paste("編譯器測試失敗:", e$message)
    })
    
    output$compiler_status <- renderText(test_result)
  })
  
  # ===========================================================================
  # Reactive Observers
  # ===========================================================================
  
  # Update LaTeX report module settings when user changes them
  observe({
    req(user_info())
    
    # You can add reactive observers here to update module settings
    # based on user preferences or other app state changes
    
    # Example: Update default API key in LaTeX module
    # if (!is.null(input$default_api_key) && input$default_api_key != "") {
    #   # Update module settings
    # }
  })
  
  # ===========================================================================
  # Error Handling
  # ===========================================================================
  
  # Global error handler
  observe({
    # Handle any global errors here
    # You can add error logging, user notifications, etc.
  })
  
  # ===========================================================================
  # Session Management
  # ===========================================================================
  
  # Clean up on session end
  onStop(function() {
    # Clean up any resources, close connections, etc.
    cat("Session ended, cleaning up...\n")
  })
}

# =============================================================================
# App Launch
# =============================================================================

# Launch the application
if (FALSE) {  # Set to TRUE to run the example
  shinyApp(ui = ui, server = server)
}

# =============================================================================
# Integration Notes
# =============================================================================

# 1. Module Dependencies:
#    - The LaTeX report module depends on sales_data and dna_results
#    - Make sure these modules are initialized before the LaTeX module
#    - The module will gracefully handle missing data

# 2. Data Flow:
#    - sales_data: Upload module → LaTeX module
#    - dna_results: DNA module → LaTeX module  
#    - other_results: Any additional analysis → LaTeX module

# 3. User Experience:
#    - The LaTeX report tab is only available after login
#    - Users can configure settings in the Settings tab
#    - The module provides clear feedback on all operations

# 4. Error Handling:
#    - The module handles missing data gracefully
#    - API errors are clearly communicated to users
#    - Compilation errors show detailed logs

# 5. Performance Considerations:
#    - LaTeX compilation can be resource-intensive
#    - Consider adding progress indicators for long operations
#    - API calls should be rate-limited appropriately

# 6. Security:
#    - API keys should be stored securely
#    - Consider using environment variables for sensitive data
#    - Validate all user inputs

# =============================================================================
# Customization Examples
# =============================================================================

# Example 1: Add custom report templates
custom_report_templates <- list(
  executive_summary = list(
    name = "執行摘要",
    description = "簡潔的執行摘要報告",
    sections = c("摘要", "關鍵發現", "建議")
  ),
  detailed_analysis = list(
    name = "詳細分析",
    description = "完整的分析報告",
    sections = c("摘要", "方法論", "資料分析", "結果", "討論", "建議", "附錄")
  )
)

# Example 2: Add custom data collectors
custom_data_collector <- function(sales_data, dna_results) {
  # Add custom data processing logic here
  list(
    custom_metrics = list(
      customer_lifetime_value = calculate_clv(sales_data),
      retention_rate = calculate_retention(sales_data),
      churn_prediction = predict_churn(dna_results)
    )
  )
}

# Example 3: Add custom LaTeX templates
custom_latex_template <- function(report_data) {
  # Generate custom LaTeX based on report_data
  paste(
    "\\documentclass{article}",
    "\\usepackage{CJKutf8}",
    "\\usepackage{graphicx}",
    "\\usepackage{booktabs}",
    "\\begin{document}",
    "\\begin{CJK*}{UTF8}{gbsn}",
    "\\title{", report_data$metadata$title, "}",
    "\\author{", report_data$metadata$author, "}",
    "\\date{", report_data$metadata$date, "}",
    "\\maketitle",
    # Add custom content here
    "\\end{CJK*}",
    "\\end{document}",
    sep = "\n"
  )
} 