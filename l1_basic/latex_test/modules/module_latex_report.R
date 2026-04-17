################################################################################
# LaTeX Report Module                                                           #
# Purpose: Convert app outputs to JSON, send to GPT for LaTeX generation,      #
#          compile locally and provide download                                 #
################################################################################

# Load required packages
library(dplyr)
library(jsonlite)
library(httr)
library(rmarkdown)
library(tools)

# Source utility functions
if (file.exists("scripts/global_scripts/04_utils/fn_latex_report_utils.R")) {
  source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")
} else {
  warning("LaTeX report utilities not found. Please check the global_scripts path.")
}

#' LaTeX Report Module – UI
#'
#' @param id Module namespace
#' @return UI elements for LaTeX report generation
latexReportModuleUI <- function(id) {
  ns <- NS(id)
  
  div(id = ns("latex_report_box"),
      h4("📄 LaTeX 報告生成器"),
      
      fluidRow(
        column(6,
               h5("🔧 報告設定"),
               textInput(ns("report_title"), "報告標題", value = "精準行銷分析報告"),
               textInput(ns("report_author"), "報告作者", value = "分析師"),
               textInput(ns("report_date"), "報告日期", value = format(Sys.Date(), "%Y年%m月%d日")),
               selectInput(ns("report_template"), "報告模板",
                          choices = c("標準報告" = "standard",
                                    "簡潔報告" = "simple",
                                    "詳細報告" = "detailed"),
                          selected = "standard"),
               textAreaInput(ns("custom_instructions"), "自訂指令 (可選)",
                           placeholder = "請描述您希望報告包含的特定內容或格式要求...",
                           rows = 3),
               br(),
               actionButton(ns("generate_report"), "📄 生成 LaTeX 報告", 
                          class = "btn-primary btn-lg"),
               br(), br(),
               textOutput(ns("generation_status"))
        ),
        column(6,
               h5("📊 包含的資料"),
               checkboxInput(ns("include_dna_analysis"), "DNA 分析結果", value = TRUE),
               checkboxInput(ns("include_sales_summary"), "銷售摘要", value = TRUE),
               checkboxInput(ns("include_customer_segments"), "客戶分群", value = TRUE),
               checkboxInput(ns("include_visualizations"), "視覺化圖表", value = TRUE),
               checkboxInput(ns("include_recommendations"), "策略建議", value = TRUE),
               br(),
               h5("📋 報告預覽"),
               verbatimTextOutput(ns("report_preview"))
        )
      ),
      
      hr(),
      
      # 報告生成結果
      conditionalPanel(
        condition = paste0("output['", ns("show_results"), "'] == true"),
        fluidRow(
          column(12,
                 h5("📄 生成的報告"),
                 tabsetPanel(
                   id = ns("report_tabs"),
                   tabPanel("📝 LaTeX 原始碼",
                            verbatimTextOutput(ns("latex_source")),
                            br(),
                            downloadButton(ns("download_tex"), "📥 下載 .tex 檔案")
                   ),
                   tabPanel("📊 編譯狀態",
                            verbatimTextOutput(ns("compilation_log")),
                            br(),
                            actionButton(ns("compile_report"), "🔄 重新編譯", 
                                       class = "btn-warning"),
                            br(), br(),
                            conditionalPanel(
                              condition = paste0("output['", ns("pdf_ready"), "'] == true"),
                              downloadButton(ns("download_pdf"), "📥 下載 PDF 報告", 
                                           class = "btn-success btn-lg")
                            )
                   ),
                   tabPanel("⚙️ 設定",
                            h6("GPT API 設定"),
                            selectInput(ns("gpt_model"), "模型",
                                      choices = c("gpt-4" = "gpt-4",
                                                "gpt-3.5-turbo" = "gpt-3.5-turbo"),
                                      selected = "gpt-4"),
                            numericInput(ns("gpt_temperature"), "創意度 (0-2)", 
                                       value = 0.7, min = 0, max = 2, step = 0.1),
                            br(),
                            h6("LaTeX 編譯設定"),
                            textInput(ns("latex_compiler"), "編譯器路徑", 
                                    value = "pdflatex", 
                                    placeholder = "pdflatex 或 xelatex 路徑"),
                            checkboxInput(ns("auto_compile"), "自動編譯", value = TRUE)
                   )
                 )
          )
        )
      )
  )
}

#' LaTeX Report Module – Server
#'
#' @param id Module namespace
#' @param con Database connection
#' @param user_info User information from login module
#' @param sales_data Sales data from upload module
#' @param dna_results DNA analysis results (optional)
#' @param other_results Other analysis results (optional)
#' @return Reactive values containing report generation results
latexReportModuleServer <- function(id, con, user_info, sales_data, 
                                   dna_results = NULL, other_results = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive values
    report_data <- reactiveVal(NULL)
    latex_source <- reactiveVal(NULL)
    compilation_status <- reactiveVal(NULL)
    pdf_path <- reactiveVal(NULL)
    
    # Show results flag
    output$show_results <- reactive({
      !is.null(latex_source())
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)
    
    # PDF ready flag
    output$pdf_ready <- reactive({
      !is.null(pdf_path()) && file.exists(pdf_path())
    })
    outputOptions(output, "pdf_ready", suspendWhenHidden = FALSE)
    
    # ---- 收集報告資料 ----
    collect_report_data <- function() {
      req(sales_data())
      
      # Prepare metadata
      metadata <- list(
        title = input$report_title,
        author = input$report_author,
        date = input$report_date,
        template = input$report_template,
        custom_instructions = input$custom_instructions
      )
      
      # Prepare include options
      include_options <- list(
        sales_summary = input$include_sales_summary,
        dna_analysis = input$include_dna_analysis,
        customer_segments = input$include_customer_segments,
        visualizations = input$include_visualizations,
        recommendations = input$include_recommendations
      )
      
      # Use utility function to collect data
      fn_collect_report_data(
        sales_data = sales_data(),
        dna_results = dna_results,
        other_results = other_results,
        metadata = metadata,
        include_options = include_options,
        verbose = FALSE
      )
    }
    
    # ---- 生成 LaTeX 報告 ----
    generate_latex_report <- function(report_data) {
      # Get API key from environment
      api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
      if (api_key == "" || api_key == "your_openai_api_key_here") {
        return(list(error = "請設定有效的 OpenAI API Key"))
      }
      
      # Use utility function to generate LaTeX via GPT with better error handling
      tryCatch({
        result <- fn_generate_latex_via_gpt(
          report_data = report_data,
          api_key = api_key,
          model = input$gpt_model,
          temperature = input$gpt_temperature,
          max_tokens = 2000,  # Reduced for faster response
          verbose = FALSE
        )
        
        if (!is.null(result$error)) {
          # If API fails, generate fallback content
          cat("API failed, using fallback content\n")
          return(generate_fallback_latex(report_data))
        }
        
        return(result)
      }, error = function(e) {
        # If any error occurs, generate fallback content
        cat("Error occurred, using fallback content:", e$message, "\n")
        return(generate_fallback_latex(report_data))
      })
    }
    
    # ---- 生成備用 LaTeX 內容 ----
    generate_fallback_latex <- function(report_data) {
      # Generate basic LaTeX content without API
      content <- c()
      
      # Sales summary section
      if (!is.null(report_data$sales_summary) && !is.null(report_data$sales_summary$total_transactions)) {
        content <- c(content,
          "\\section{銷售摘要}",
          paste0("本次分析包含 ", report_data$sales_summary$total_transactions, " 筆交易，"),
          paste0("涉及 ", report_data$sales_summary$unique_customers, " 位獨特客戶，"),
          paste0("總收入為 ", round(report_data$sales_summary$total_revenue, 2), " 元。"),
          paste0("平均每筆交易價值為 ", round(report_data$sales_summary$avg_transaction_value, 2), " 元。"),
          "",
          "\\subsection{交易統計}",
          "\\begin{itemize}",
          paste0("\\item 總交易筆數：", report_data$sales_summary$total_transactions, "筆"),
          paste0("\\item 獨立客戶數：", report_data$sales_summary$unique_customers, "位"),
          paste0("\\item 總收入：", round(report_data$sales_summary$total_revenue, 2), "元"),
          paste0("\\item 平均交易金額：", round(report_data$sales_summary$avg_transaction_value, 2), "元"),
          "\\end{itemize}"
        )
      }
      
      # DNA analysis section
      if (!is.null(report_data$dna_analysis) && !is.null(report_data$dna_analysis$customer_count)) {
        content <- c(content,
          "",
          "\\section{DNA分析}",
          paste0("我們對 ", report_data$dna_analysis$customer_count, " 位客戶進行了 DNA 分析。"),
          "",
          "\\subsection{客戶分佈}",
          "\\begin{itemize}"
        )
        
        if (!is.null(report_data$dna_analysis$nes_distribution)) {
          for (status in names(report_data$dna_analysis$nes_distribution)) {
            count <- report_data$dna_analysis$nes_distribution[[status]]
            content <- c(content, paste0("\\item ", status, " 客戶：", count, "位"))
          }
        }
        
        content <- c(content, "\\end{itemize}")
      }
      
      # Add timestamp
      content <- c(content,
        "",
        "\\section{報告生成資訊}",
        paste0("報告生成時間：", format(Sys.time(), "%Y年%m月%d日 %H時%M分%S秒")),
        "\\textit{注意：此報告使用備用模式生成，API 連線失敗。}"
      )
      
      return(list(
        success = TRUE,
        latex = paste(content, collapse = "\n"),
        tokens_used = 0,
        model_used = "fallback"
      ))
    }
    
    # ---- 生成完整 LaTeX 文檔 ----
    generate_complete_latex_document <- function(latex_content, report_data) {
      # Read template
      template_path <- "template.tex"
      if (!file.exists(template_path)) {
        return(paste("錯誤：找不到 template.tex 檔案\n\n", latex_content))
      }
      
      template_content <- readLines(template_path, warn = FALSE)
      
      # Find the position to insert content (after \maketitle)
      maketitle_pos <- which(grepl("\\\\maketitle", template_content))
      if (length(maketitle_pos) == 0) {
        return(paste("錯誤：模板中找不到 \\maketitle 標記\n\n", latex_content))
      }
      
      # Update template metadata if provided
      updated_template <- template_content
      
      # Update title if provided in metadata
      if (!is.null(report_data$metadata$title)) {
        title_pos <- which(grepl("\\\\title\\{", updated_template))
        if (length(title_pos) > 0) {
          updated_template[title_pos] <- paste0("\\title{", report_data$metadata$title, "}")
        }
      }
      
      # Update author if provided in metadata
      if (!is.null(report_data$metadata$author)) {
        author_pos <- which(grepl("\\\\author\\{", updated_template))
        if (length(author_pos) > 0) {
          updated_template[author_pos] <- paste0("\\author{", report_data$metadata$author, "}")
        }
      }
      
      # Update date if provided in metadata
      if (!is.null(report_data$metadata$date)) {
        date_pos <- which(grepl("\\\\date\\{", updated_template))
        if (length(date_pos) > 0) {
          updated_template[date_pos] <- paste0("\\date{", report_data$metadata$date, "}")
        }
      }
      
      # Insert content after \maketitle
      final_content <- c(
        updated_template[1:maketitle_pos],
        "",  # Add empty line
        latex_content,  # Insert generated content
        "",  # Add empty line
        updated_template[(maketitle_pos + 1):length(updated_template)]
      )
      
      return(paste(final_content, collapse = "\n"))
    }
    
    # ---- 編譯 LaTeX 報告 ----
    compile_latex_report <- function(latex_source, report_data, output_dir = "reports") {
      # Use utility function to compile LaTeX
      fn_compile_latex_report(
        latex_source = latex_source,
        output_dir = output_dir,
        compiler = input$latex_compiler,
        filename_prefix = "report",
        report_data = report_data,
        verbose = FALSE
      )
    }
    
    # ---- 事件處理 ----
    
    # 生成報告按鈕
    observeEvent(input$generate_report, {
      # 更新狀態
      output$generation_status <- renderText("正在收集資料...")
      
      # 收集資料
      data <- collect_report_data()
      report_data(data)
      
      # 更新預覽
      output$report_preview <- renderText({
        paste("報告標題:", data$metadata$title, "\n",
              "包含項目:", 
              ifelse(!is.null(data$sales_summary), "銷售摘要 ", ""),
              ifelse(!is.null(data$dna_analysis), "DNA分析 ", ""),
              ifelse(!is.null(data$customer_segments), "客戶分群", ""))
      })
      
      # 生成 LaTeX
      output$generation_status <- renderText("正在生成 LaTeX 報告...")
      result <- generate_latex_report(data)
      
      if (!is.null(result$error)) {
        output$generation_status <- renderText(paste("錯誤:", result$error))
        return()
      }
      
      latex_source(result$latex)
      output$generation_status <- renderText("LaTeX 報告生成完成！")
      
      # 生成完整的 LaTeX 文檔（包含 preamble）
      complete_latex <- generate_complete_latex_document(result$latex, data)
      
      # 顯示完整的 LaTeX 原始碼
      output$latex_source <- renderText(complete_latex)
      
      # 自動編譯（如果啟用）
      if (input$auto_compile) {
        output$compilation_log <- renderText("正在編譯 PDF...")
        compile_result <- compile_latex_report(result$latex, data)
        
        if (!is.null(compile_result$error)) {
          compilation_status(compile_result$error)
          output$compilation_log <- renderText(paste("編譯失敗:", compile_result$error))
        } else {
          compilation_status("編譯成功")
          pdf_path(compile_result$pdf_path)
          output$compilation_log <- renderText("PDF 編譯成功！")
        }
      }
    })
    
    # 重新編譯按鈕
    observeEvent(input$compile_report, {
      req(latex_source())
      req(report_data())
      
      output$compilation_log <- renderText("正在重新編譯...")
      compile_result <- compile_latex_report(latex_source(), report_data())
      
      if (!is.null(compile_result$error)) {
        compilation_status(compile_result$error)
        output$compilation_log <- renderText(paste("編譯失敗:", compile_result$error))
      } else {
        compilation_status("編譯成功")
        pdf_path(compile_result$pdf_path)
        output$compilation_log <- renderText("PDF 重新編譯成功！")
      }
    })
    
    # ---- 下載處理 ----
    
    # 下載 .tex 檔案
    output$download_tex <- downloadHandler(
      filename = function() {
        paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".tex")
      },
      content = function(file) {
        req(latex_source())
        req(report_data())
        # Generate complete document for download
        complete_latex <- generate_complete_latex_document(latex_source(), report_data())
        writeLines(complete_latex, file, useBytes = TRUE)
      }
    )
    
    # 下載 PDF 檔案
    output$download_pdf <- downloadHandler(
      filename = function() {
        paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf")
      },
      content = function(file) {
        req(pdf_path())
        file.copy(pdf_path(), file)
      }
    )
    
    # ---- 返回結果 ----
    return(list(
      report_data = report_data,
      latex_source = latex_source,
      compilation_status = compilation_status,
      pdf_path = pdf_path
    ))
  })
} 