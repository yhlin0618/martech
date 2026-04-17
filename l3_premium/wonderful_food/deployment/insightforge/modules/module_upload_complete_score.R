################################################################################
# module_upload_complete_score.R - 上傳已完成評分的資料模組
################################################################################

# 載入必要的資料存取工具
source("utils/data_access.R")  # 包含 tbl2 函數

#' Upload Complete Score Module - UI
#' 
#' 允許使用者上傳已經完成屬性評分的資料，並選擇對應欄位
uploadCompleteScoreUI <- function(id) {
  ns <- NS(id)
  div(id = ns("upload_complete_box"),
      h4("步驟 1：上傳已評分資料"),
      
      # 評分資料上傳區
      div(
        h5("1.1 上傳產品屬性評分資料"),
        div(
          style = "background: #d1ecf1; border: 1px solid #bee5eb; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
          icon("info-circle"),
          " 請上傳包含產品ID、產品名稱及各屬性評分的CSV或Excel檔案"
        ),
        fileInput(ns("score_file"), 
                  "選擇屬性評分檔案", 
                  multiple = FALSE, 
                  accept = c(".xlsx", ".xls", ".csv")),
        
        # 欄位選擇區 - 評分資料
        conditionalPanel(
          condition = "output.score_file_uploaded == true",
          ns = ns,
          br(),
          h5("選擇評分資料欄位"),
          fluidRow(
            column(6,
                   selectInput(ns("product_id_col"), 
                               "產品ID欄位 (ASIN/SKU):",
                               choices = NULL,
                               selected = NULL)
            ),
            column(6,
                   selectInput(ns("product_name_col"), 
                               "產品名稱欄位:",
                               choices = NULL,
                               selected = NULL)
            )
          ),
          br(),
          h5("選擇屬性評分欄位"),
          div(
            style = "background: #f8f9fa; padding: 10px; border-radius: 5px;",
            p("請勾選所有屬性評分欄位（數值型欄位）："),
            uiOutput(ns("attribute_columns_ui"))
          )
        ),
        br()
      ),
      
      # 銷售資料上傳區
      div(
        h5("1.2 上傳銷售資料 (選填)"),
        div(
          style = "background: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
          icon("info-circle"),
          " 請上傳包含產品ID、時間、銷售數量等資料的檔案"
        ),
        fileInput(ns("sales_file"), 
                  "選擇銷售資料檔案", 
                  multiple = TRUE, 
                  accept = c(".xlsx", ".xls", ".csv")),
        
        # 欄位選擇區 - 銷售資料
        conditionalPanel(
          condition = "output.sales_file_uploaded == true",
          ns = ns,
          br(),
          h5("選擇銷售資料欄位"),
          fluidRow(
            column(4,
                   selectInput(ns("sales_product_id_col"), 
                               "產品ID欄位:",
                               choices = NULL,
                               selected = NULL)
            ),
            column(4,
                   selectInput(ns("sales_time_col"), 
                               "時間欄位:",
                               choices = NULL,
                               selected = NULL)
            ),
            column(4,
                   selectInput(ns("sales_quantity_col"), 
                               "銷售數量欄位:",
                               choices = NULL,
                               selected = NULL)
            )
          ),
          # 可選欄位
          fluidRow(
            column(4,
                   selectInput(ns("sales_price_col"), 
                               "價格欄位 (選填):",
                               choices = NULL,
                               selected = NULL)
            ),
            column(4,
                   selectInput(ns("sales_revenue_col"), 
                               "營收欄位 (選填):",
                               choices = NULL,
                               selected = NULL)
            ),
            column(4,
                   selectInput(ns("sales_period_col"), 
                               "期間欄位 (選填):",
                               choices = NULL,
                               selected = NULL)
            )
          )
        ),
        br()
      ),
      
      # 處理按鈕
      actionButton(ns("process_btn"), "處理並預覽資料", class = "btn-success", icon = icon("cogs")),
      br(), br(),
      
      # 錯誤訊息顯示
      uiOutput(ns("upload_msg")),
      
      # 資料預覽區
      conditionalPanel(
        condition = "output.data_processed == true",
        ns = ns,
        h4("資料預覽"),
        tabsetPanel(
          tabPanel("評分資料", 
                   br(),
                   div(
                     style = "margin-bottom: 10px;",
                     verbatimTextOutput(ns("score_summary"))
                   ),
                   DTOutput(ns("score_preview"))
          ),
          tabPanel("銷售資料", 
                   br(),
                   div(
                     style = "margin-bottom: 10px;",
                     verbatimTextOutput(ns("sales_summary"))
                   ),
                   DTOutput(ns("sales_preview"))
          ),
          tabPanel("屬性統計",
                   br(),
                   plotOutput(ns("attribute_stats"), height = "400px")
          )
        ),
        br(),
        actionButton(ns("confirm_data"), "確認資料，進行下一步", class = "btn-info", icon = icon("arrow-right"))
      )
  )
}

#' Upload Complete Score Module - Server
uploadCompleteScoreServer <- function(id, user_id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      score_data = NULL,
      sales_data = NULL,
      score_columns = NULL,
      sales_columns = NULL,
      processed_score = NULL,
      processed_sales = NULL,
      attribute_columns = NULL,
      score_file_uploaded = FALSE,
      sales_file_uploaded = FALSE,
      data_processed = FALSE
    )
    
    # 處理評分檔案上傳
    observeEvent(input$score_file, {
      req(input$score_file)
      
      tryCatch({
        # 讀取檔案
        file_ext <- tools::file_ext(input$score_file$datapath)
        if (file_ext %in% c("xlsx", "xls")) {
          values$score_data <- readxl::read_excel(input$score_file$datapath)
        } else if (file_ext == "csv") {
          # 嘗試不同的編碼
          values$score_data <- tryCatch(
            read.csv(input$score_file$datapath, stringsAsFactors = FALSE),
            error = function(e) {
              read.csv(input$score_file$datapath, stringsAsFactors = FALSE, 
                       fileEncoding = "UTF-8")
            }
          )
        }
        
        # 取得欄位名稱
        values$score_columns <- names(values$score_data)
        values$score_file_uploaded <- TRUE
        
        # 更新欄位選擇器
        updateSelectInput(session, "product_id_col",
                          choices = c("", values$score_columns),
                          selected = intersect(c("product_id", "ASIN", "SKU", "asin"), 
                                               values$score_columns)[1])
        
        updateSelectInput(session, "product_name_col",
                          choices = c("", values$score_columns),
                          selected = intersect(c("product_name", "name", "產品名稱"), 
                                               values$score_columns)[1])
        
        showNotification("評分檔案上傳成功！", type = "message")
        
      }, error = function(e) {
        showNotification(paste("評分檔案讀取失敗:", e$message), type = "error")
      })
    })
    
    # 動態生成屬性欄位選擇器
    output$attribute_columns_ui <- renderUI({
      req(values$score_columns)
      
      # 找出可能的數值型欄位
      numeric_cols <- c()
      for (col in values$score_columns) {
        # 嘗試轉換為數值，檢查是否為數值型
        sample_values <- head(values$score_data[[col]], 100)
        if (!all(is.na(suppressWarnings(as.numeric(sample_values))))) {
          numeric_cols <- c(numeric_cols, col)
        }
      }
      
      # 排除明顯的ID和名稱欄位
      exclude_patterns <- c("id", "ID", "name", "名稱", "total", "avg", "sum", "count")
      potential_attrs <- numeric_cols[!grepl(paste(exclude_patterns, collapse = "|"), 
                                              numeric_cols, ignore.case = TRUE)]
      
      # 生成checkbox群組
      checkboxGroupInput(ns("selected_attributes"),
                         label = NULL,
                         choices = numeric_cols,
                         selected = potential_attrs,
                         inline = FALSE)
    })
    
    # 處理銷售檔案上傳
    observeEvent(input$sales_file, {
      req(input$sales_file)
      
      tryCatch({
        # 支援多檔案合併
        all_sales <- list()
        
        for (i in seq_len(nrow(input$sales_file))) {
          file_path <- input$sales_file$datapath[i]
          file_ext <- tools::file_ext(file_path)
          
          if (file_ext %in% c("xlsx", "xls")) {
            temp_data <- readxl::read_excel(file_path)
          } else if (file_ext == "csv") {
            temp_data <- tryCatch(
              read.csv(file_path, stringsAsFactors = FALSE),
              error = function(e) {
                read.csv(file_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
              }
            )
          }
          all_sales[[i]] <- temp_data
        }
        
        # 合併所有銷售資料
        values$sales_data <- do.call(rbind, all_sales)
        values$sales_columns <- names(values$sales_data)
        values$sales_file_uploaded <- TRUE
        
        # 自動識別欄位
        updateSelectInput(session, "sales_product_id_col",
                          choices = c("", values$sales_columns),
                          selected = intersect(c("product_id", "ASIN", "SKU", "asin"), 
                                               values$sales_columns)[1])
        
        updateSelectInput(session, "sales_time_col",
                          choices = c("", values$sales_columns),
                          selected = intersect(c("created_at", "date", "time", "Time", "period"), 
                                               values$sales_columns)[1])
        
        updateSelectInput(session, "sales_quantity_col",
                          choices = c("", values$sales_columns),
                          selected = intersect(c("quantity", "sales", "Sales", "數量"), 
                                               values$sales_columns)[1])
        
        updateSelectInput(session, "sales_price_col",
                          choices = c("無", values$sales_columns),
                          selected = intersect(c("price", "sale_price", "價格"), 
                                               values$sales_columns)[1])
        
        updateSelectInput(session, "sales_revenue_col",
                          choices = c("無", values$sales_columns),
                          selected = intersect(c("revenue", "total_amount", "營收"), 
                                               values$sales_columns)[1])
        
        updateSelectInput(session, "sales_period_col",
                          choices = c("無", values$sales_columns),
                          selected = intersect(c("period", "month", "week"), 
                                               values$sales_columns)[1])
        
        showNotification(paste("成功上傳", nrow(input$sales_file), "個銷售檔案"), 
                         type = "message")
        
      }, error = function(e) {
        showNotification(paste("銷售檔案讀取失敗:", e$message), type = "error")
      })
    })
    
    # 處理資料
    observeEvent(input$process_btn, {
      req(values$score_data)
      req(input$product_id_col, input$product_name_col, input$selected_attributes)
      
      tryCatch({
        # 處理評分資料
        score_cols <- c(input$product_id_col, input$product_name_col, input$selected_attributes)
        values$processed_score <- values$score_data[, score_cols]
        
        # 重新命名欄位
        names(values$processed_score)[1:2] <- c("product_id", "product_name")
        values$attribute_columns <- input$selected_attributes
        
        # 計算統計資訊
        attr_scores <- values$processed_score[, values$attribute_columns]
        values$processed_score$avg_score <- rowMeans(attr_scores, na.rm = TRUE)
        values$processed_score$total_score <- rowSums(attr_scores, na.rm = TRUE)
        
        # 處理銷售資料（如果有）
        if (!is.null(values$sales_data) && input$sales_product_id_col != "") {
          sales_cols <- c(input$sales_product_id_col, 
                          input$sales_time_col,
                          input$sales_quantity_col)
          
          # 加入可選欄位
          if (input$sales_price_col != "無") {
            sales_cols <- c(sales_cols, input$sales_price_col)
          }
          if (input$sales_revenue_col != "無") {
            sales_cols <- c(sales_cols, input$sales_revenue_col)
          }
          if (input$sales_period_col != "無") {
            sales_cols <- c(sales_cols, input$sales_period_col)
          }
          
          values$processed_sales <- values$sales_data[, sales_cols]
          
          # 重新命名必要欄位
          names(values$processed_sales)[1:3] <- c("product_id", "Time", "Sales")
        }
        
        values$data_processed <- TRUE
        showNotification("資料處理成功！", type = "message")
        
      }, error = function(e) {
        showNotification(paste("資料處理失敗:", e$message), type = "error")
      })
    })
    
    # 輸出控制顯示
    output$score_file_uploaded <- reactive({ values$score_file_uploaded })
    output$sales_file_uploaded <- reactive({ values$sales_file_uploaded })
    output$data_processed <- reactive({ values$data_processed })
    outputOptions(output, "score_file_uploaded", suspendWhenHidden = FALSE)
    outputOptions(output, "sales_file_uploaded", suspendWhenHidden = FALSE)
    outputOptions(output, "data_processed", suspendWhenHidden = FALSE)
    
    # 評分資料預覽
    output$score_preview <- renderDT({
      req(values$processed_score)
      datatable(
        values$processed_score,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip'
        )
      ) %>%
        formatRound(columns = c(values$attribute_columns, "avg_score"), digits = 2)
    })
    
    # 評分資料摘要
    output$score_summary <- renderPrint({
      req(values$processed_score)
      cat("產品數量:", nrow(values$processed_score), "\n")
      cat("屬性數量:", length(values$attribute_columns), "\n")
      cat("屬性名稱:", paste(values$attribute_columns, collapse = ", "), "\n")
      cat("\n屬性評分統計:\n")
      summary(values$processed_score[, values$attribute_columns])
    })
    
    # 銷售資料預覽
    output$sales_preview <- renderDT({
      req(values$processed_sales)
      datatable(
        head(values$processed_sales, 1000),
        options = list(
          pageLength = 10,
          scrollX = TRUE
        )
      )
    })
    
    # 銷售資料摘要
    output$sales_summary <- renderPrint({
      req(values$processed_sales)
      cat("銷售記錄數:", nrow(values$processed_sales), "\n")
      cat("產品數量:", length(unique(values$processed_sales$product_id)), "\n")
      cat("\n銷售數量統計:\n")
      summary(values$processed_sales$Sales)
    })
    
    # 屬性統計圖表
    output$attribute_stats <- renderPlot({
      req(values$processed_score, values$attribute_columns)
      
      # 計算每個屬性的平均分
      attr_means <- colMeans(values$processed_score[, values$attribute_columns], na.rm = TRUE)
      attr_df <- data.frame(
        attribute = names(attr_means),
        mean_score = attr_means
      )
      
      # 排序
      attr_df <- attr_df[order(attr_df$mean_score, decreasing = TRUE), ]
      
      # 繪製條形圖
      par(mar = c(8, 4, 2, 2))
      barplot(
        attr_df$mean_score,
        names.arg = attr_df$attribute,
        col = colorRampPalette(c("#3498db", "#2ecc71"))(nrow(attr_df)),
        las = 2,
        main = "各屬性平均評分",
        ylab = "平均分數",
        ylim = c(0, max(attr_df$mean_score) * 1.1)
      )
      abline(h = mean(attr_df$mean_score), col = "red", lty = 2, lwd = 2)
      legend("topright", "整體平均", lty = 2, col = "red", bty = "n")
    })
    
    # 錯誤訊息
    output$upload_msg <- renderUI({
      if (values$data_processed) {
        div(
          class = "alert alert-success",
          icon("check-circle"),
          " 資料處理完成，請檢視預覽結果"
        )
      }
    })
    
    # 返回處理後的資料和欄位映射資訊
    return(list(
      score_data = reactive({ values$processed_score }),
      sales_data = reactive({ values$processed_sales }),
      attribute_columns = reactive({ values$attribute_columns }),
      data_ready = reactive({ values$data_processed }),
      confirm = reactive({ input$confirm_data }),
      # 新增欄位映射資訊
      field_mapping = reactive({
        list(
          # 評分資料欄位映射
          score = list(
            product_id_col = input$product_id_col,
            product_name_col = input$product_name_col,
            selected_attributes = input$selected_attributes
          ),
          # 銷售資料欄位映射
          sales = list(
            product_id_col = input$sales_product_id_col,
            time_col = input$sales_time_col,
            quantity_col = input$sales_quantity_col,
            price_col = input$sales_price_col,
            revenue_col = input$sales_revenue_col,
            period_col = input$sales_period_col
          )
        )
      })
    ))
  })
}