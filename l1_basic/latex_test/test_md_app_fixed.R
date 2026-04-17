# =============================================================================
# Test Markdown App (Fixed Version)
# Purpose: Generate Markdown content using GPT and compile to HTML/PDF
# =============================================================================

library(shiny)
library(dotenv)
library(dplyr)
library(httr)
library(jsonlite)
library(rmarkdown)
library(knitr)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# UI
ui <- fluidPage(
  titlePanel("Markdown Report Generator (資料上傳/分析/報告產生)"),
  
  fluidRow(
    column(6,
           h5("📁 資料上傳/產生"),
           fileInput("upload_file", "上傳 CSV 檔案", accept = c(".csv", ".txt")),
           actionButton("generate_test_data", "產生測試資料", class = "btn-success"),
           hr(),
           h5("📊 資料預覽"),
           DT::DTOutput("data_preview")
    ),
    column(6,
           h5("🔧 報告設定"),
           textInput("report_title", "Report Title", "Sales Analysis Report"),
           textInput("report_author", "Author", "Analyst"),
           dateInput("report_date", "Report Date", value = Sys.Date()),
           checkboxInput("include_summary", "Include Summary", value = TRUE),
           checkboxInput("include_charts", "Include Charts", value = FALSE),
           checkboxInput("include_recommendations", "Include Recommendations", value = TRUE),
           actionButton("generate_md", "產生 Markdown", class = "btn-primary"),
           actionButton("compile_html", "編譯 HTML", class = "btn-success"),
           actionButton("compile_pdf", "編譯 PDF", class = "btn-warning"),
           hr(),
           verbatimTextOutput("status")
    )
  ),
  hr(),
  tabsetPanel(
    tabPanel("Generated Markdown", verbatimTextOutput("markdown_content")),
    tabPanel("Preview", htmlOutput("preview")),
    tabPanel("Download", 
             downloadButton("download_md", "Download Markdown"), 
             downloadButton("download_html", "Download HTML"),
             downloadButton("download_pdf", "Download PDF"))
  )
)

# Server
server <- function(input, output, session) {
  library(DT)
  library(readr)
  
  # Reactive values
  rv <- reactiveValues(
    markdown_content = NULL,
    pdf_path = NULL,
    html_path = NULL,
    status = "Ready",
    data = NULL
  )

  # 讀取上傳或產生的資料
  observeEvent(input$upload_file, {
    tryCatch({
      data <- read_csv(input$upload_file$datapath, show_col_types = FALSE)
      rv$data <- data
      rv$status <- "資料已上傳"
    }, error = function(e) {
      rv$status <- paste("檔案讀取錯誤:", e$message)
      rv$data <- NULL
    })
  })
  
  observeEvent(input$generate_test_data, {
    set.seed(123)
    customers <- paste0("customer_", 1:20)
    dates <- seq(as.POSIXct("2024-01-01"), as.POSIXct("2024-12-31"), by = "day")
    data <- data.frame(
      customer_id = sample(customers, 50, replace = TRUE),
      lineitem_price = round(runif(50, 50, 500), 2),
      payment_time = sample(dates, 50, replace = TRUE),
      product_name = sample(c("產品A", "產品B", "產品C"), 50, replace = TRUE)
    )
    rv$data <- data
    rv$status <- "已產生測試資料"
  })

  # 資料預覽
  output$data_preview <- DT::renderDT({
    req(rv$data)
    DT::datatable(rv$data %>% head(10), options = list(pageLength = 5, scrollX = TRUE), caption = "資料預覽（前 10 筆）")
  })

  # 分析摘要
  get_data_summary <- reactive({
    req(rv$data)
    data <- rv$data
    total_revenue <- sum(data$lineitem_price, na.rm = TRUE)
    avg_transaction <- mean(data$lineitem_price, na.rm = TRUE)
    unique_customers <- length(unique(data$customer_id))
    total_transactions <- nrow(data)
    date_range <- paste(format(min(data$payment_time), "%Y-%m-%d"), "to", format(max(data$payment_time), "%Y-%m-%d"))
    paste0(
      "Total Revenue: $", format(total_revenue, big.mark = ","), "\n",
      "Average Transaction: $", round(avg_transaction, 2), "\n",
      "Unique Customers: ", unique_customers, "\n",
      "Total Transactions: ", total_transactions, "\n",
      "Date Range: ", date_range
    )
  })

  # 產生 Markdown
  observeEvent(input$generate_md, {
    if (is.null(rv$data)) {
      rv$status <- "請先上傳或產生資料"
      return()
    }
    rv$status <- "呼叫 GPT 產生 Markdown..."
    report_config <- list(
      title = input$report_title,
      author = input$report_author,
      date = as.character(input$report_date),
      include_summary = input$include_summary,
      include_charts = input$include_charts,
      include_recommendations = input$include_recommendations
    )
    data_summary <- get_data_summary()
    markdown_content <- NULL
    
    # GPT 產生 markdown
    tryCatch({
      markdown_content <- call_gpt_for_markdown(data_summary, report_config)
    }, error = function(e) {
      rv$status <- paste("GPT 產生失敗:", e$message)
    })
    
    # Fallback
    if (is.null(markdown_content)) {
      recommendations_md <- ""
      if (input$include_recommendations) {
        recommendations_md <- paste0(
          "## Recommendations\n\n",
          "1. Focus on customer retention strategies\n",
          "2. Consider upselling opportunities\n",
          "3. Analyze seasonal trends for better planning\n\n"
        )
      }
      markdown_content <- paste0(
        "# ", input$report_title, "\n\n",
        "**Author:** ", input$report_author, "\n",
        "**Date:** ", as.character(input$report_date), "\n\n",
        "## Executive Summary\n\n",
        "This report analyzes sales data for ", length(unique(rv$data$customer_id)), " customers across ", 
        nrow(rv$data), " transactions.\n\n",
        "## Key Findings\n\n",
        "- Total Revenue: $", format(sum(rv$data$lineitem_price), big.mark = ","), "\n",
        "- Average Transaction: $", round(mean(rv$data$lineitem_price), 2), "\n",
        "- Unique Customers: ", length(unique(rv$data$customer_id)), "\n",
        "- Total Transactions: ", nrow(rv$data), "\n\n",
        "## Analysis\n\n",
        "The data shows ", ifelse(mean(rv$data$lineitem_price) > 200, "strong", "moderate"), 
        " performance with an average transaction value of $", round(mean(rv$data$lineitem_price), 2), ".\n\n",
        recommendations_md,
        "---\n",
        "*Report generated on ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*"
      )
    }
    
    # 最簡化的 YAML header，避免任何套件依賴
    yaml_header <- paste0(
      "---\n",
      "title: \"", input$report_title, "\"\n",
      "author: \"", input$report_author, "\"\n",
      "date: \"", as.character(input$report_date), "\"\n",
      "---\n\n"
    )
    rv$markdown_content <- paste0(yaml_header, markdown_content)
    rv$status <- "Markdown 已產生"
  })

  # 編譯 HTML (主要輸出格式)
  observeEvent(input$compile_html, {
    if (is.null(rv$markdown_content)) {
      rv$status <- "請先產生 Markdown"
      return()
    }
    rv$status <- "編譯 HTML..."
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    md_file <- file.path("test_reports", paste0("report_", timestamp, ".md"))
    html_file <- file.path("test_reports", paste0("report_", timestamp, ".html"))
    
    if (!dir.exists("test_reports")) dir.create("test_reports", recursive = TRUE)
    
    # 寫入 markdown 檔案
    writeLines(rv$markdown_content, md_file, useBytes = TRUE)
    cat("Markdown file created:", md_file, "\n")
    
    tryCatch({
      cat("Compiling HTML...\n")
      # Save current working directory
      original_wd <- getwd()
      # Change to the directory containing the markdown file
      setwd(dirname(md_file))
      
      result <- rmarkdown::render(
        input = basename(md_file),
        output_format = rmarkdown::html_document(
          toc = FALSE,
          number_sections = FALSE,
          highlight = NULL,
          css = NULL,
          theme = NULL
        ),
        output_file = basename(html_file),
        quiet = FALSE
      )
      
      # Restore original working directory
      setwd(original_wd)
      
      # Check multiple possible file locations
      possible_files <- c(
        html_file,
        result,  # rmarkdown::render returns the actual output file path
        file.path("test_reports", paste0("report_", timestamp, ".html")),
        file.path(dirname(md_file), paste0("report_", timestamp, ".html")),
        # Check for double directory issue
        file.path("test_reports", "test_reports", paste0("report_", timestamp, ".html")),
        file.path(dirname(md_file), "test_reports", paste0("report_", timestamp, ".html"))
      )
      
      html_file_found <- NULL
      for (file_path in possible_files) {
        if (file.exists(file_path)) {
          html_file_found <- file_path
          break
        }
      }
      
      if (!is.null(html_file_found)) {
        rv$status <- paste("HTML 編譯成功:", basename(html_file_found))
        rv$html_path <- html_file_found
        file_size <- file.size(html_file_found)
        cat("HTML file found at:", html_file_found, "\n")
        cat("HTML file size:", file_size, "bytes\n")
      } else {
        rv$status <- "HTML 編譯失敗 - 找不到輸出檔案"
        cat("Expected HTML file not found. Checked paths:\n")
        for (path in possible_files) {
          cat("  -", path, ":", ifelse(file.exists(path), "EXISTS", "NOT FOUND"), "\n")
        }
        
        # List all files in test_reports directory for debugging
        if (dir.exists("test_reports")) {
          cat("Files in test_reports directory:\n")
          files_in_dir <- list.files("test_reports", full.names = TRUE)
          for (file in files_in_dir) {
            cat("  -", file, "\n")
          }
        }
      }
    }, error = function(e) {
      rv$status <- paste("HTML compilation error:", e$message)
      cat("HTML compilation error details:", e$message, "\n")
    })
  })

  # 編譯 PDF (備用格式，可能失敗)
  observeEvent(input$compile_pdf, {
    if (is.null(rv$markdown_content)) {
      rv$status <- "請先產生 Markdown"
      return()
    }
    rv$status <- "編譯 PDF (可能失敗，建議使用 HTML)..."
    
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    md_file <- file.path("test_reports", paste0("report_", timestamp, ".md"))
    pdf_file <- file.path("test_reports", paste0("report_", timestamp, ".pdf"))
    log_file <- file.path("test_reports", paste0("report_", timestamp, ".log"))
    
    if (!dir.exists("test_reports")) dir.create("test_reports", recursive = TRUE)
    
    # 寫入 markdown 檔案
    writeLines(rv$markdown_content, md_file, useBytes = TRUE)
    cat("Markdown file created:", md_file, "\n")
    
    # 嘗試 PDF 編譯
    tryCatch({
      cat("Trying PDF compilation...\n")
      rmarkdown::render(
        input = md_file,
        output_format = rmarkdown::pdf_document(
          latex_engine = "pdflatex",
          toc = FALSE,
          number_sections = FALSE,
          highlight = NULL,
          pandoc_args = c("--pdf-engine=pdflatex")
        ),
        output_file = pdf_file,
        quiet = FALSE
      )
      if (file.exists(pdf_file)) {
        rv$status <- paste("PDF 編譯成功:", basename(pdf_file))
        rv$pdf_path <- pdf_file
        file_size <- file.size(pdf_file)
        cat("PDF file size:", file_size, "bytes\n")
        if (file_size < 1000) {
          rv$status <- paste(rv$status, " (警告: PDF 檔案很小，可能內容有問題)")
        }
      } else {
        rv$status <- "PDF 編譯失敗 - 建議使用 HTML 格式"
      }
    }, error = function(e) {
      rv$status <- paste("PDF 編譯失敗:", e$message, "- 建議使用 HTML 格式")
      cat("PDF compilation error details:", e$message, "\n")
      
      # 檢查是否有 log 檔案
      if (file.exists(log_file)) {
        log_content <- readLines(log_file, warn = FALSE)
        cat("LaTeX log content:\n")
        cat(paste(log_content, collapse = "\n"), "\n")
      }
    })
  })

  # GPT 產生 markdown function
  call_gpt_for_markdown <- function(data_summary, report_config) {
    api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
    if (is.null(api_key) || api_key == "") {
      stop("OpenAI API key not found in environment variables")
    }
    prompt <- paste0(
      "Generate a professional Markdown report based on the following data and requirements:\n\n",
      "Data Summary:\n",
      data_summary, "\n\n",
      "Report Configuration:\n",
      "- Title: ", report_config$title, "\n",
      "- Author: ", report_config$author, "\n",
      "- Date: ", report_config$date, "\n",
      "- Include Summary: ", report_config$include_summary, "\n",
      "- Include Charts: ", report_config$include_charts, "\n",
      "- Include Recommendations: ", report_config$include_recommendations, "\n\n",
      "Requirements:\n",
      "1. Use proper Markdown syntax\n",
      "2. Include headers, lists, and formatting\n",
      "3. Make it professional and readable\n",
      "4. Include data insights and analysis\n",
      "5. If charts are requested, include placeholders with descriptions\n",
      "6. If recommendations are requested, provide actionable insights\n\n",
      "Generate only the Markdown content, no additional text."
    )
    response <- httr::POST(
      url = "https://api.openai.com/v1/chat/completions",
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key),
        "Content-Type" = "application/json"
      ),
      body = jsonlite::toJSON(list(
        model = "gpt-3.5-turbo",
        messages = list(
          list(role = "system", content = "You are a professional data analyst who creates clear, well-formatted Markdown reports."),
          list(role = "user", content = prompt)
        ),
        max_tokens = 2000,
        temperature = 0.7
      ), auto_unbox = TRUE),
      timeout(30)
    )
    if (httr::status_code(response) == 200) {
      result <- jsonlite::fromJSON(httr::content(response, "text"))
      return(result$choices$message$content)
    } else {
      error_msg <- paste("API call failed:", httr::status_code(response))
      cat(error_msg, "\n")
      return(NULL)
    }
  }

  # 預覽/下載
  output$markdown_content <- renderText({
    if (is.null(rv$markdown_content)) {
      "No markdown content generated yet. Click '產生 Markdown' to start."
    } else {
      rv$markdown_content
    }
  })
  
  output$preview <- renderUI({
    if (is.null(rv$markdown_content)) {
      HTML("<p>No content to preview</p>")
    } else {
      HTML(markdown::renderMarkdown(text = rv$markdown_content))
    }
  })
  
  output$status <- renderText({ rv$status })
  
  output$download_md <- downloadHandler(
    filename = function() { paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".md") },
    content = function(file) { if (!is.null(rv$markdown_content)) writeLines(rv$markdown_content, file) }
  )
  
  output$download_html <- downloadHandler(
    filename = function() { paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".html") },
    content = function(file) { if (!is.null(rv$html_path) && file.exists(rv$html_path)) file.copy(rv$html_path, file) }
  )
  
  output$download_pdf <- downloadHandler(
    filename = function() { paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf") },
    content = function(file) { if (!is.null(rv$pdf_path) && file.exists(rv$pdf_path)) file.copy(rv$pdf_path, file) }
  )
}

shinyApp(ui = ui, server = server) 