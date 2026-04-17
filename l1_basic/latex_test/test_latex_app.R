# =============================================================================
# Test App: test_latex_app
# Purpose: Minimal app to test LaTeX report module functionality
# Author: Claude
# Date Created: 2025-01-27
# Related Principles: R21, R69, C01
# =============================================================================
#
# .env 檔案用法：
# 請在專案根目錄建立 .env 檔，內容格式如下：
# OPENAI_API_KEY=sk-xxxxxxx
#
# LaTeX 中文 PDF 產生：
# 報告將自動使用 template.tex 的 xeCJK/中文字型設定產生中文 PDF
# =============================================================================

# Load required packages
library(shiny)
library(dplyr)
library(DT)
library(readr)
# 新增 dotenv 支援
if (!require(dotenv)) install.packages("dotenv")
library(dotenv)

# 載入 .env 取得 API key
dotenv::load_dot_env(file = ".env")
OPENAI_API_KEY <- Sys.getenv("OPENAI_API_KEY_LIN")

# Source the LaTeX report module
source("modules/module_latex_report.R")

# =============================================================================
# UI Definition
# =============================================================================

ui <- fluidPage(
  titlePanel("📄 LaTeX 報告模組測試"),
  
  # Main content
  fluidRow(
    column(12,
           h4("這是一個最小化的測試應用程式，用於驗證 LaTeX 報告模組功能"),
           hr()
    )
  ),
  
  # Data upload section
  fluidRow(
    column(6,
           h5("📁 測試資料上傳"),
           fileInput("upload_file", "選擇 CSV 檔案",
                    accept = c(".csv", ".txt"),
                    placeholder = "選擇包含銷售資料的 CSV 檔案"),
           helpText("檔案應包含：customer_id, lineitem_price, payment_time 等欄位"),
           hr(),
           h5("📊 資料預覽"),
           DTOutput("data_preview")
    ),
    column(6,
           h5("🔧 快速設定"),
           # 刪除 API key 輸入框
           # textInput("api_key", "OpenAI API Key", placeholder = "輸入您的 OpenAI API Key"),
           selectInput("compiler", "LaTeX 編譯器",
                      choices = c("pdflatex" = "pdflatex", "xelatex" = "xelatex"),
                      selected = "xelatex"),
           actionButton("test_compiler", "測試編譯器", class = "btn-info"),
           textOutput("compiler_status"),
           hr(),
           h5("📋 測試資料生成"),
           actionButton("generate_test_data", "生成測試資料", class = "btn-success"),
           helpText("如果沒有上傳檔案，可以生成測試資料")
    )
  ),
  
  hr(),
  
  # LaTeX report module
  fluidRow(
    column(12,
           latexReportModuleUI("latex_report")
    )
  )
)

# =============================================================================
# Server Logic
# =============================================================================

server <- function(input, output, session) {
  
  # Mock database connection
  con <- reactive({
    list(type = "test", status = "connected")
  })
  
  # Mock user info
  user_info <- reactive({
    list(user = "test_user", authenticated = TRUE, role = "admin")
  })
  
  # ===========================================================================
  # Data Management
  # ===========================================================================
  
  # Reactive sales data
  sales_data <- reactive({
    req(input$upload_file)
    
    tryCatch({
      # Read uploaded file
      data <- read_csv(input$upload_file$datapath, show_col_types = FALSE)
      
      # Validate required columns
      required_cols <- c("customer_id", "lineitem_price", "payment_time")
      missing_cols <- setdiff(required_cols, names(data))
      
      if (length(missing_cols) > 0) {
        showNotification(
          paste("缺少必要欄位:", paste(missing_cols, collapse = ", ")),
          type = "warning"
        )
        return(NULL)
      }
      
      # Convert data types
      data %>%
        mutate(
          customer_id = as.character(customer_id),
          lineitem_price = as.numeric(lineitem_price),
          payment_time = as.POSIXct(payment_time)
        ) %>%
        filter(!is.na(customer_id), !is.na(lineitem_price), !is.na(payment_time))
      
    }, error = function(e) {
      showNotification(paste("檔案讀取錯誤:", e$message), type = "warning")
      return(NULL)
    })
  })
  
  # Generate test data
  test_sales_data <- reactive({
    # Create sample sales data
    set.seed(123)
    
    customers <- paste0("customer_", 1:50)
    dates <- seq(as.POSIXct("2024-01-01"), as.POSIXct("2024-12-31"), by = "day")
    
    data.frame(
      customer_id = sample(customers, 200, replace = TRUE),
      lineitem_price = round(runif(200, 50, 500), 2),
      payment_time = sample(dates, 200, replace = TRUE),
      product_name = sample(c("產品A", "產品B", "產品C", "產品D"), 200, replace = TRUE),
      platform = sample(c("amazon", "ebay", "shopify"), 200, replace = TRUE)
    ) %>%
      arrange(customer_id, payment_time)
  })
  
  # Combined sales data (uploaded or generated)
  final_sales_data <- reactive({
    if (!is.null(sales_data()) && nrow(sales_data()) > 0) {
      sales_data()
    } else if (input$generate_test_data > 0) {
      test_sales_data()
    } else {
      NULL
    }
  })
  
  # ===========================================================================
  # Mock DNA Results
  # ===========================================================================
  
  # Generate mock DNA analysis results
  dna_results <- reactive({
    req(final_sales_data())
    
    # Calculate basic DNA metrics
    dna_data <- final_sales_data() %>%
      group_by(customer_id) %>%
      summarise(
        total_transactions = n(),
        total_spent = sum(lineitem_price, na.rm = TRUE),
        avg_transaction = mean(lineitem_price, na.rm = TRUE),
        first_purchase = min(payment_time, na.rm = TRUE),
        last_purchase = max(payment_time, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        # Mock DNA calculations
        m_value = total_spent,
        r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
        f_value = total_transactions,
        ipt_value = as.numeric(difftime(last_purchase, first_purchase, units = "days")) / pmax(total_transactions - 1, 1),
        # NES status based on total spent
        nes_status = case_when(
          total_spent >= 1000 ~ "High",
          total_spent >= 500 ~ "Medium",
          TRUE ~ "Low"
        )
      )
    
    return(dna_data)
  })
  
  # ===========================================================================
  # UI Outputs
  # ===========================================================================
  
  # Data preview
  output$data_preview <- renderDT({
    req(final_sales_data())
    
    datatable(
      final_sales_data() %>% head(10),
      options = list(
        pageLength = 5,
        scrollX = TRUE
      ),
      caption = "資料預覽（前 10 筆）"
    )
  })
  
  # Compiler test
  observeEvent(input$test_compiler, {
    compiler <- input$compiler
    
    if (compiler == "") {
      output$compiler_status <- renderText("請選擇編譯器")
      return()
    }
    
    # Test the compiler
    test_result <- tryCatch({
      result <- system2(compiler, "--version", stdout = TRUE, stderr = TRUE)
      if (length(result) > 0) {
        paste("✓", compiler, "可用")
      } else {
        paste("✗", compiler, "不可用")
      }
    }, error = function(e) {
      paste("✗", compiler, "測試失敗:", e$message)
    })
    
    output$compiler_status <- renderText(test_result)
  })
  
  # ===========================================================================
  # LaTeX Report Module
  # ===========================================================================
  
  # Initialize LaTeX report module
  latex_report_results <- latexReportModuleServer(
    "latex_report",
    con = con,
    user_info = user_info,
    sales_data = final_sales_data,
    dna_results = dna_results,
    other_results = reactive(list())  # Empty for this test
  )
  
  # ===========================================================================
  # Observers and Notifications
  # ===========================================================================
  
  # 設定預設編譯器（模組內部會自動從環境變數讀取 API key）
  observe({
    # 設定預設編譯器為 xelatex（如果模組有這個設定）
    if (!is.null(input$`latex_report-latex_compiler`)) {
      updateTextInput(session, "latex_report-latex_compiler", value = "xelatex")
    }
  })
  
  # Show notifications for data status
  observe({
    if (!is.null(final_sales_data()) && nrow(final_sales_data()) > 0) {
      showNotification(
        paste("資料已載入:", nrow(final_sales_data()), "筆記錄"),
        type = "default"
      )
    }
  })
  
  # Show notifications for DNA results
  observe({
    if (!is.null(dna_results()) && nrow(dna_results()) > 0) {
      showNotification(
        paste("DNA 分析完成:", nrow(dna_results()), "位客戶"),
        type = "default"
      )
    }
  })
  
  # ===========================================================================
  # Session Management
  # ===========================================================================
  
  # Clean up on session end
  onStop(function() {
    cat("測試應用程式結束，清理資源...\n")
  })
}

# =============================================================================
# App Launch
# =============================================================================

# Launch the test application
shinyApp(ui = ui, server = server) 