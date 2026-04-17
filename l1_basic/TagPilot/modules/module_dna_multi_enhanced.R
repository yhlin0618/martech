# Enhanced Multi-File DNA Analysis Module with Customer Details
# Supports Amazon sales data and general transaction files with detailed customer information

library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(plotly)
library(readxl)
library(later)
library(openxlsx)

# Helper functions from microDNADistribution component
`%+%` <- function(x, y) paste0(x, y)
`%||%` <- function(x, y) if (is.null(x)) y else x
nrow2 <- function(x) {
  if (is.null(x)) return(0)
  if (!is.data.frame(x) && !is.matrix(x)) return(0)
  return(nrow(x))
}

# Source DNA analysis function
if (file.exists("scripts/global_scripts/04_utils/fn_analysis_dna.R")) {
  source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
  source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
  source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
}

# Enhanced UI Function with customer details
dnaMultiEnhancedModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    h3("Value × Activity 九宮格分析", style = "text-align: center; margin: 20px 0;"),
    
    # 控制面板
    fluidRow(
      column(12,
        bs4Card(
          title = "分析控制",
          status = "info",
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          fluidRow(
            column(4,
              radioButtons(ns("view_mode"), 
                          "顯示模式:",
                          choices = list("統計摘要" = "summary", 
                                       "客戶明細" = "details"),
                          selected = "summary",
                          inline = TRUE)
            ),
            column(4,
              selectInput(ns("selected_segment"),
                         "選擇區隔查看:",
                         choices = list(
                           "高價值×高活躍" = "high_high",
                           "高價值×中活躍" = "high_mid",
                           "高價值×低活躍" = "high_low",
                           "中價值×高活躍" = "mid_high",
                           "中價值×中活躍" = "mid_mid",
                           "中價值×低活躍" = "mid_low",
                           "低價值×高活躍" = "low_high",
                           "低價值×中活躍" = "low_mid",
                           "低價值×低活躍" = "low_low"
                         ),
                         selected = "high_high")
            ),
            column(4,
              conditionalPanel(
                condition = "input.view_mode == 'details'",
                ns = ns,
                br(),
                downloadButton(ns("download_segment_csv"), "下載 CSV", 
                             class = "btn-success btn-sm"),
                downloadButton(ns("download_segment_excel"), "下載 Excel", 
                             class = "btn-info btn-sm",
                             style = "margin-left: 10px;")
              )
            )
          )
        )
      )
    ),
    
    # 九宮格分析或詳細表格
    conditionalPanel(
      condition = "input.view_mode == 'summary'",
      ns = ns,
      # 九宮格顯示
      fluidRow(
        # 高價值客戶
        column(4,
          bs4Card(
            title = "高價值 × 高活躍度",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("high_value_high_activity")),
            footer = actionButton(ns("view_high_high"), "查看明細", 
                                class = "btn-sm btn-outline-success")
          )
        ),
        column(4,
          bs4Card(
            title = "高價值 × 中活躍度",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("high_value_mid_activity")),
            footer = actionButton(ns("view_high_mid"), "查看明細", 
                                class = "btn-sm btn-outline-success")
          )
        ),
        column(4,
          bs4Card(
            title = "高價值 × 低活躍度",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("high_value_low_activity")),
            footer = actionButton(ns("view_high_low"), "查看明細", 
                                class = "btn-sm btn-outline-success")
          )
        )
      ),
      fluidRow(
        # 中價值客戶
        column(4,
          bs4Card(
            title = "中價值 × 高活躍度",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("mid_value_high_activity")),
            footer = actionButton(ns("view_mid_high"), "查看明細", 
                                class = "btn-sm btn-outline-warning")
          )
        ),
        column(4,
          bs4Card(
            title = "中價值 × 中活躍度",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("mid_value_mid_activity")),
            footer = actionButton(ns("view_mid_mid"), "查看明細", 
                                class = "btn-sm btn-outline-warning")
          )
        ),
        column(4,
          bs4Card(
            title = "中價值 × 低活躍度",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("mid_value_low_activity")),
            footer = actionButton(ns("view_mid_low"), "查看明細", 
                                class = "btn-sm btn-outline-warning")
          )
        )
      ),
      fluidRow(
        # 低價值客戶
        column(4,
          bs4Card(
            title = "低價值 × 高活躍度",
            status = "danger",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("low_value_high_activity")),
            footer = actionButton(ns("view_low_high"), "查看明細", 
                                class = "btn-sm btn-outline-danger")
          )
        ),
        column(4,
          bs4Card(
            title = "低價值 × 中活躍度",
            status = "danger",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("low_value_mid_activity")),
            footer = actionButton(ns("view_low_mid"), "查看明細", 
                                class = "btn-sm btn-outline-danger")
          )
        ),
        column(4,
          bs4Card(
            title = "低價值 × 低活躍度",
            status = "danger",
            width = 12,
            solidHeader = TRUE,
            uiOutput(ns("low_value_low_activity")),
            footer = actionButton(ns("view_low_low"), "查看明細", 
                                class = "btn-sm btn-outline-danger")
          )
        )
      )
    ),
    
    # 客戶明細表格
    conditionalPanel(
      condition = "input.view_mode == 'details'",
      ns = ns,
      fluidRow(
        column(12,
          bs4Card(
            title = textOutput(ns("detail_title")),
            status = "primary",
            width = 12,
            solidHeader = TRUE,
            maximizable = TRUE,
            DT::dataTableOutput(ns("customer_details"))
          )
        )
      )
    ),
    
    # 統計摘要
    fluidRow(
      column(12,
        bs4Card(
          title = "整體統計",
          status = "info",
          width = 12,
          collapsible = TRUE,
          collapsed = TRUE,
          fluidRow(
            bs4ValueBox(
              value = textOutput(ns("total_customers")),
              subtitle = "總客戶數",
              color = "primary",
              width = 3,
              icon = icon("users")
            ),
            bs4ValueBox(
              value = textOutput(ns("avg_value")),
              subtitle = "平均客戶價值",
              color = "success",
              width = 3,
              icon = icon("dollar-sign")
            ),
            bs4ValueBox(
              value = textOutput(ns("retention_rate")),
              subtitle = "留存率",
              color = "warning",
              width = 3,
              icon = icon("percentage")
            ),
            bs4ValueBox(
              value = textOutput(ns("high_value_ratio")),
              subtitle = "高價值客戶佔比",
              color = "danger",
              width = 3,
              icon = icon("crown")
            )
          )
        )
      )
    )
  )
}

# Enhanced Server Function with customer details
dnaMultiEnhancedModuleServer <- function(id, con, user_info, sales_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive: DNA分析結果
    dna_results <- reactive({
      req(sales_data())
      
      tryCatch({
        data <- sales_data()
        
        # 確保有必要的欄位
        if (!all(c("customer_id", "time", "product_sales") %in% names(data))) {
          # 嘗試建立必要欄位
          if ("ship_postal_code" %in% names(data)) {
            data$customer_id <- data$ship_postal_code
          }
          if ("date" %in% names(data)) {
            data$time <- as.Date(data$date)
          }
          if ("sales" %in% names(data)) {
            data$product_sales <- data$sales
          }
        }
        
        # 執行DNA分析
        if (exists("fn_analysis_dna")) {
          result <- fn_analysis_dna(data)
        } else {
          # 簡化的DNA分析
          # 先處理時間欄位
          if ("time" %in% names(data)) {
            # 嘗試不同的日期格式轉換
            data$time_date <- tryCatch({
              as.Date(data$time)
            }, error = function(e) {
              tryCatch({
                as.Date(data$time, format = "%Y-%m-%d")
              }, error = function(e2) {
                tryCatch({
                  as.Date(data$time, format = "%m/%d/%Y")
                }, error = function(e3) {
                  # 如果都失敗，使用當前日期
                  rep(Sys.Date(), nrow(data))
                })
              })
            })
          } else {
            data$time_date <- Sys.Date()
          }
          
          result <- data %>%
            group_by(customer_id) %>%
            summarise(
              last_purchase = max(time_date, na.rm = TRUE),
              frequency = n(),
              monetary = sum(as.numeric(product_sales), na.rm = TRUE),
              .groups = 'drop'
            ) %>%
            mutate(
              recency = as.numeric(Sys.Date() - last_purchase),
              # 處理可能的 NA 或無限值
              recency = ifelse(is.na(recency) | is.infinite(recency), 365, recency),
              frequency = ifelse(is.na(frequency), 0, frequency),
              monetary = ifelse(is.na(monetary), 0, monetary)
            ) %>%
            mutate(
              value_segment = case_when(
                monetary <= 0 ~ "低價值",
                monetary > quantile(monetary[monetary > 0], 0.67, na.rm = TRUE) ~ "高價值",
                monetary > quantile(monetary[monetary > 0], 0.33, na.rm = TRUE) ~ "中價值",
                TRUE ~ "低價值"
              ),
              activity_segment = case_when(
                frequency <= 0 ~ "低活躍",
                frequency > quantile(frequency[frequency > 0], 0.67, na.rm = TRUE) ~ "高活躍",
                frequency > quantile(frequency[frequency > 0], 0.33, na.rm = TRUE) ~ "中活躍",
                TRUE ~ "低活躍"
              ),
              segment = paste0(value_segment, "×", activity_segment)
            ) %>%
            select(-last_purchase)  # 移除暫時欄位
        }
        
        # 加入額外的客戶資訊
        if ("ship_city" %in% names(data)) {
          customer_info <- data %>%
            group_by(customer_id) %>%
            summarise(
              city = first(ship_city),
              state = first(ship_state),
              .groups = 'drop'
            )
          result <- left_join(result, customer_info, by = "customer_id")
        }
        
        # 加入email (如果有的話)
        if ("email" %in% names(data)) {
          email_info <- data %>%
            group_by(customer_id) %>%
            summarise(email = first(email), .groups = 'drop')
          result <- left_join(result, email_info, by = "customer_id")
        } else {
          # 產生範例email
          result$email <- paste0("customer_", seq_len(nrow(result)), "@example.com")
        }
        
        return(result)
        
      }, error = function(e) {
        showNotification(
          paste("DNA分析錯誤:", e$message),
          type = "error",
          duration = 5
        )
        return(data.frame())
      })
    })
    
    # 各區隔的客戶資料
    segment_data <- reactive({
      data <- dna_results()
      if (is.null(data) || nrow(data) == 0) return(list())
      
      tryCatch({
        list(
          high_high = filter(data, value_segment == "高價值", activity_segment == "高活躍"),
          high_mid = filter(data, value_segment == "高價值", activity_segment == "中活躍"),
          high_low = filter(data, value_segment == "高價值", activity_segment == "低活躍"),
          mid_high = filter(data, value_segment == "中價值", activity_segment == "高活躍"),
          mid_mid = filter(data, value_segment == "中價值", activity_segment == "中活躍"),
          mid_low = filter(data, value_segment == "中價值", activity_segment == "低活躍"),
          low_high = filter(data, value_segment == "低價值", activity_segment == "高活躍"),
          low_mid = filter(data, value_segment == "低價值", activity_segment == "中活躍"),
          low_low = filter(data, value_segment == "低價值", activity_segment == "低活躍")
        )
      }, error = function(e) {
        showNotification(
          paste("區隔資料錯誤:", e$message),
          type = "warning",
          duration = 5
        )
        return(list())
      })
    })
    
    # 生成各區隔的摘要UI
    create_segment_summary <- function(segment_data) {
      if (is.null(segment_data) || nrow(segment_data) == 0) {
        return(div(
          p("無客戶", style = "text-align: center; color: #999;")
        ))
      }
      
      # 安全計算統計值
      avg_monetary <- tryCatch({
        round(mean(segment_data$monetary, na.rm = TRUE), 2)
      }, error = function(e) 0)
      
      avg_frequency <- tryCatch({
        round(mean(segment_data$frequency, na.rm = TRUE), 1)
      }, error = function(e) 0)
      
      avg_recency <- tryCatch({
        round(mean(segment_data$recency, na.rm = TRUE), 0)
      }, error = function(e) 0)
      
      div(
        h4(paste0(nrow(segment_data), " 位客戶"), 
           style = "text-align: center; margin: 10px 0;"),
        p(paste0("平均消費: $", format(avg_monetary, big.mark = ",")),
          style = "margin: 5px 0;"),
        p(paste0("平均購買頻率: ", avg_frequency, " 次"),
          style = "margin: 5px 0;"),
        p(paste0("平均最近購買: ", avg_recency, " 天前"),
          style = "margin: 5px 0;")
      )
    }
    
    # 更新九宮格顯示
    observe({
      segments <- segment_data()
      
      output$high_value_high_activity <- renderUI(create_segment_summary(segments$high_high))
      output$high_value_mid_activity <- renderUI(create_segment_summary(segments$high_mid))
      output$high_value_low_activity <- renderUI(create_segment_summary(segments$high_low))
      output$mid_value_high_activity <- renderUI(create_segment_summary(segments$mid_high))
      output$mid_value_mid_activity <- renderUI(create_segment_summary(segments$mid_mid))
      output$mid_value_low_activity <- renderUI(create_segment_summary(segments$mid_low))
      output$low_value_high_activity <- renderUI(create_segment_summary(segments$low_high))
      output$low_value_mid_activity <- renderUI(create_segment_summary(segments$low_mid))
      output$low_value_low_activity <- renderUI(create_segment_summary(segments$low_low))
    })
    
    # 處理查看明細按鈕
    observeEvent(input$view_high_high, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "high_high")
    })
    observeEvent(input$view_high_mid, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "high_mid")
    })
    observeEvent(input$view_high_low, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "high_low")
    })
    observeEvent(input$view_mid_high, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "mid_high")
    })
    observeEvent(input$view_mid_mid, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "mid_mid")
    })
    observeEvent(input$view_mid_low, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "mid_low")
    })
    observeEvent(input$view_low_high, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "low_high")
    })
    observeEvent(input$view_low_mid, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "low_mid")
    })
    observeEvent(input$view_low_low, {
      updateRadioButtons(session, "view_mode", selected = "details")
      updateSelectInput(session, "selected_segment", selected = "low_low")
    })
    
    # 當前選擇的區隔資料
    current_segment_data <- reactive({
      segments <- segment_data()
      if (length(segments) == 0) return(data.frame())
      
      segment_key <- input$selected_segment
      if (segment_key %in% names(segments)) {
        segments[[segment_key]]
      } else {
        data.frame()
      }
    })
    
    # 顯示區隔標題
    output$detail_title <- renderText({
      segment_names <- list(
        high_high = "高價值 × 高活躍度 客戶明細",
        high_mid = "高價值 × 中活躍度 客戶明細",
        high_low = "高價值 × 低活躍度 客戶明細",
        mid_high = "中價值 × 高活躍度 客戶明細",
        mid_mid = "中價值 × 中活躍度 客戶明細",
        mid_low = "中價值 × 低活躍度 客戶明細",
        low_high = "低價值 × 高活躍度 客戶明細",
        low_mid = "低價值 × 中活躍度 客戶明細",
        low_low = "低價值 × 低活躍度 客戶明細"
      )
      segment_names[[input$selected_segment]]
    })
    
    # 顯示客戶明細表格
    output$customer_details <- DT::renderDataTable({
      data <- current_segment_data()
      
      if (nrow(data) == 0) {
        return(DT::datatable(data.frame(訊息 = "此區隔無客戶資料")))
      }
      
      # 選擇要顯示的欄位
      display_cols <- c("customer_id", "email", "recency", "frequency", "monetary", "segment")
      if ("city" %in% names(data)) display_cols <- c(display_cols, "city")
      if ("state" %in% names(data)) display_cols <- c(display_cols, "state")
      
      display_data <- data[, display_cols[display_cols %in% names(data)]]
      
      # 重新命名欄位為中文
      col_names <- names(display_data)
      col_names[col_names == "customer_id"] <- "客戶ID"
      col_names[col_names == "email"] <- "Email"
      col_names[col_names == "recency"] <- "最近購買(天)"
      col_names[col_names == "frequency"] <- "購買次數"
      col_names[col_names == "monetary"] <- "總消費金額"
      col_names[col_names == "segment"] <- "區隔"
      col_names[col_names == "city"] <- "城市"
      col_names[col_names == "state"] <- "州/省"
      names(display_data) <- col_names
      
      DT::datatable(
        display_data,
        options = list(
          pageLength = 25,
          lengthMenu = c(10, 25, 50, 100),
          scrollX = TRUE,
          language = list(
            url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese-traditional.json"
          ),
          dom = 'Bfrtip',
          buttons = c('copy', 'print')
        ),
        rownames = FALSE,
        class = "display nowrap"
      ) %>%
        DT::formatCurrency("總消費金額", currency = "$", digits = 2)
    })
    
    # 下載CSV
    output$download_segment_csv <- downloadHandler(
      filename = function() {
        segment_name <- gsub("_", "-", input$selected_segment)
        paste0("customers_", segment_name, "_", Sys.Date(), ".csv")
      },
      content = function(file) {
        data <- current_segment_data()
        write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 下載Excel
    output$download_segment_excel <- downloadHandler(
      filename = function() {
        segment_name <- gsub("_", "-", input$selected_segment)
        paste0("customers_", segment_name, "_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        data <- current_segment_data()
        openxlsx::write.xlsx(data, file)
      }
    )
    
    # 統計資訊
    output$total_customers <- renderText({
      format(nrow(dna_results()), big.mark = ",")
    })
    
    output$avg_value <- renderText({
      data <- dna_results()
      if (nrow(data) > 0) {
        paste0("$", format(round(mean(data$monetary, na.rm = TRUE), 2), big.mark = ","))
      } else {
        "$0"
      }
    })
    
    output$retention_rate <- renderText({
      data <- dna_results()
      if (nrow(data) > 0) {
        active <- sum(data$recency <= 90, na.rm = TRUE)
        rate <- (active / nrow(data)) * 100
        paste0(round(rate, 1), "%")
      } else {
        "0%"
      }
    })
    
    output$high_value_ratio <- renderText({
      data <- dna_results()
      if (nrow(data) > 0) {
        high_value <- sum(data$value_segment == "高價值", na.rm = TRUE)
        ratio <- (high_value / nrow(data)) * 100
        paste0(round(ratio, 1), "%")
      } else {
        "0%"
      }
    })
    
    # 返回分析結果供其他模組使用
    return(list(
      dna_results = dna_results,
      segment_data = segment_data,
      current_segment = reactive(input$selected_segment)
    ))
  })
}