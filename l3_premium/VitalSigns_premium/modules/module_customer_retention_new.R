# 客戶留存模組 (Customer Retention Module) - 改進版
# 衡量基盤穩定度與流失風險

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)
library(markdown)

# 載入提示和prompt系統
source("utils/hint_system.R")
source("utils/prompt_manager.R")

# UI Function
customerRetentionModuleUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  tagList(
    # 初始化提示系統
    if(enable_hints) init_hint_system() else NULL,
    
    # 第一排：主要KPI（4個）
    fluidRow(
      column(3,
        bs4ValueBox(
          value = textOutput(ns("retention_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客留存率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_retention_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客留存率"
          },
          icon = icon("user-check"),
          color = "success",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("churn_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客流失率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_churn_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客流失率"
          },
          icon = icon("user-times"),
          color = "danger",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("at_risk_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "流失風險客戶 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "at_risk_customers", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "流失風險客戶"
          },
          icon = icon("exclamation-triangle"),
          color = "warning",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("core_ratio")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "主力客比率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "core_customer_ratio", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "主力客比率"
          },
          icon = icon("star"),
          color = "primary",
          width = 12
        )
      )
    ),
    
    br(),
    
    # 第二排：客戶狀態細分（5個）
    fluidRow(
      column(2,
        bs4ValueBox(
          value = textOutput(ns("dormant_prediction")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "靜止戶預測 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "dormant_prediction", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "靜止戶預測"
          },
          icon = icon("clock"),
          color = "secondary",
          width = 12,
          footer = tags$small("30天內預測")
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("new_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "首購客 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "new_customers", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "首購客(N)"
          },
          icon = icon("user-plus"),
          color = "info",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("core_customers")),
          subtitle = "主力客(E0)",
          icon = icon("crown"),
          color = "success",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("drowsy_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "瞌睡客 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "drowsy_customers", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "瞌睡客(S1)"
          },
          icon = icon("bed"),
          color = "warning",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("semi_sleeping")),
          subtitle = "半睡客(S2)",
          icon = icon("moon"),
          color = "orange",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("sleeping_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "沉睡客 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "sleeping_customers", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "沉睡客(S3)"
          },
          icon = icon("user-slash"),
          color = "danger",
          width = 12
        )
      )
    ),
    
    br(),
    
    # 圖表區
    fluidRow(
      # 客戶狀態結構
      column(6,
        bs4Card(
          title = "客戶狀態結構",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          footer = downloadButton(ns("download_structure"), "下載CSV", class = "btn-sm"),
          plotlyOutput(ns("customer_structure"))
        )
      ),
      
      # 流失風險分析
      column(6,
        bs4Card(
          title = "流失風險分析",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          footer = downloadButton(ns("download_risk"), "下載CSV", class = "btn-sm"),
          plotlyOutput(ns("churn_risk_analysis"))
        )
      )
    ),
    
    br(),
    
    # AI 分析建議集中區
    fluidRow(
      column(12,
        bs4Card(
          title = "🤖 AI 智能分析與建議",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          
          # 使用 tabsetPanel 替代
          tabsetPanel(
            type = "tabs",
            
            tabPanel(
              title = "留存分析",
              icon = icon("chart-line"),
              br(),
              uiOutput(ns("ai_retention_analysis"))
            ),
            
            tabPanel(
              title = "首購客策略",
              icon = icon("user-plus"),
              br(),
              uiOutput(ns("ai_new_customer"))
            ),
            
            tabPanel(
              title = "主力客深化",
              icon = icon("crown"),
              br(),
              uiOutput(ns("ai_core_customer"))
            ),
            
            tabPanel(
              title = "瞌睡客喚醒",
              icon = icon("bell"),
              br(),
              uiOutput(ns("ai_drowsy_customer"))
            ),
            
            tabPanel(
              title = "半睡客挽留",
              icon = icon("exclamation-circle"),
              br(),
              uiOutput(ns("ai_semi_dormant_customer"))
            ),
            
            tabPanel(
              title = "沉睡客激活",
              icon = icon("redo"),
              br(),
              uiOutput(ns("ai_sleeping_customer"))
            ),
            
            tabPanel(
              title = "結構優化",
              icon = icon("project-diagram"),
              br(),
              uiOutput(ns("ai_structure_analysis"))
            )
          )
        )
      )
    )
  )
}

# Server Function
customerRetentionModuleServer <- function(id, con, user_info, dna_module_result, 
                                         enable_hints = TRUE, enable_gpt = FALSE, 
                                         chat_api = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # 載入 prompt 管理器
    prompts_df <- NULL
    if(enable_gpt) {
      prompts_df <- load_prompts()
    }
    
    # 輔助函數：處理 AI 結果的 Markdown 轉換
    render_ai_result <- function(result) {
      if(!is.null(result)) {
        # 檢查是否包含 Markdown 格式
        if(grepl("\\*\\*|##|\\n\\n|^[0-9]+\\.|^-\\s", result)) {
          # 轉換 Markdown 為 HTML
          html_content <- markdownToHTML(text = result, fragment.only = TRUE)
          return(HTML(html_content))
        } else {
          # 純文字直接返回
          return(HTML(result))
        }
      }
      return(NULL)
    }
    
    # 如果啟用提示，定期觸發提示初始化
    if(enable_hints) {
      observe({
        trigger_hint_init(session)
      })
    }
    
    # 取得 DNA 分析結果
    dna_results <- reactive({
      req(dna_module_result)
      result <- dna_module_result()
      if (!is.null(result) && !is.null(result$dna_results)) {
        return(result$dna_results)
      }
      return(NULL)
    })
    
    # 計算留存指標
    retention_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      
      # 修正 NES 狀態順序
      status_order <- c("N", "E0", "S1", "S2", "S3")
      
      # 計算各狀態客戶數
      status_counts <- data %>%
        mutate(nes_status = factor(nes_status, levels = status_order)) %>%
        group_by(nes_status) %>%
        summarise(count = n()) %>%
        complete(nes_status = status_order, fill = list(count = 0))
      
      # 基本指標
      total_customers <- nrow(data)
      active_customers <- sum(data$nes_status %in% c("N", "E0"), na.rm = TRUE)
      churned_customers <- sum(data$nes_status == "S3", na.rm = TRUE)
      at_risk <- sum(data$nes_status %in% c("S1", "S2"), na.rm = TRUE)
      
      # 計算率
      metrics <- list(
        retention_rate = (active_customers / total_customers) * 100,
        churn_rate = (churned_customers / total_customers) * 100,
        at_risk_count = at_risk,
        core_ratio = (sum(data$nes_status == "E0", na.rm = TRUE) / total_customers) * 100,
        
        # 各狀態數量
        new_count = sum(data$nes_status == "N", na.rm = TRUE),
        core_count = sum(data$nes_status == "E0", na.rm = TRUE),
        drowsy_count = sum(data$nes_status == "S1", na.rm = TRUE),
        semi_sleeping_count = sum(data$nes_status == "S2", na.rm = TRUE),
        sleeping_count = sum(data$nes_status == "S3", na.rm = TRUE),
        
        # 靜止戶預測（基於行為趨勢）
        dormant_prediction = sum(data$nes_status == "S1", na.rm = TRUE) * 0.3 +
                            sum(data$nes_status == "S2", na.rm = TRUE) * 0.5,
        
        # 狀態分布
        status_distribution = status_counts,
        
        # 原始數據（用於下載）
        raw_data = data
      )
      
      return(metrics)
    })
    
    # KPI 顯示
    output$retention_rate <- renderText({
      metrics <- retention_metrics()
      paste0(round(metrics$retention_rate, 1), "%")
    })
    
    output$churn_rate <- renderText({
      metrics <- retention_metrics()
      paste0(round(metrics$churn_rate, 1), "%")
    })
    
    output$at_risk_customers <- renderText({
      metrics <- retention_metrics()
      format(metrics$at_risk_count, big.mark = ",")
    })
    
    output$core_ratio <- renderText({
      metrics <- retention_metrics()
      paste0(round(metrics$core_ratio, 1), "%")
    })
    
    output$dormant_prediction <- renderText({
      metrics <- retention_metrics()
      format(round(metrics$dormant_prediction), big.mark = ",")
    })
    
    output$new_customers <- renderText({
      metrics <- retention_metrics()
      format(metrics$new_count, big.mark = ",")
    })
    
    output$core_customers <- renderText({
      metrics <- retention_metrics()
      format(metrics$core_count, big.mark = ",")
    })
    
    output$drowsy_customers <- renderText({
      metrics <- retention_metrics()
      format(metrics$drowsy_count, big.mark = ",")
    })
    
    output$semi_sleeping <- renderText({
      metrics <- retention_metrics()
      format(metrics$semi_sleeping_count, big.mark = ",")
    })
    
    output$sleeping_customers <- renderText({
      metrics <- retention_metrics()
      format(metrics$sleeping_count, big.mark = ",")
    })
    
    # 客戶狀態結構圖
    output$customer_structure <- renderPlotly({
      req(retention_metrics())
      
      distribution <- retention_metrics()$status_distribution
      
      # 定義顏色和標籤
      colors <- c("N" = "#17a2b8", "E0" = "#28a745", 
                  "S1" = "#ffc107", "S2" = "#fd7e14", "S3" = "#dc3545")
      labels <- c("N" = "首購客", "E0" = "主力客", 
                  "S1" = "瞌睡客", "S2" = "半睡客", "S3" = "沉睡客")
      
      plot_ly(distribution,
              x = ~nes_status,
              y = ~count,
              type = 'bar',
              text = ~paste0(count, " (", round(count/sum(count)*100, 1), "%)"),
              textposition = "outside",
              marker = list(color = colors[distribution$nes_status]),
              hovertemplate = "%{x}<br>客戶數: %{y}<br>占比: %{text}<extra></extra>") %>%
        layout(
          title = list(text = "客戶狀態分布 (N→E0→S1→S2→S3)", font = list(size = 14)),
          xaxis = list(
            title = "客戶狀態",
            ticktext = labels,
            tickvals = names(labels)
          ),
          yaxis = list(title = "客戶數"),
          showlegend = FALSE
        )
    })
    
    # 流失風險分析圖
    output$churn_risk_analysis <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 計算風險分數
      risk_data <- data %>%
        mutate(
          risk_score = case_when(
            nes_status == "N" ~ 10,
            nes_status == "E0" ~ 5,
            nes_status == "S1" ~ 40,
            nes_status == "S2" ~ 70,
            nes_status == "S3" ~ 95,
            TRUE ~ 50
          ),
          risk_level = case_when(
            risk_score <= 20 ~ "低風險",
            risk_score <= 50 ~ "中風險",
            risk_score <= 80 ~ "高風險",
            TRUE ~ "極高風險"
          )
        ) %>%
        group_by(nes_status, risk_level) %>%
        summarise(
          count = n(),
          avg_value = mean(total_spent, na.rm = TRUE)
        ) %>%
        mutate(nes_status = factor(nes_status, levels = c("N", "E0", "S1", "S2", "S3")))
      
      labels <- c("N" = "首購客", "E0" = "主力客", 
                  "S1" = "瞌睡客", "S2" = "半睡客", "S3" = "沉睡客")
      
      plot_ly(risk_data,
              x = ~nes_status,
              y = ~count,
              color = ~risk_level,
              colors = c("低風險" = "#28a745", "中風險" = "#ffc107", 
                        "高風險" = "#fd7e14", "極高風險" = "#dc3545"),
              type = 'bar',
              text = ~paste0(count, "人"),
              hovertemplate = "%{x}<br>%{color}<br>客戶數: %{y}<extra></extra>") %>%
        layout(
          title = list(text = "流失風險評估", font = list(size = 14)),
          xaxis = list(
            title = "客戶狀態",
            ticktext = labels,
            tickvals = names(labels)
          ),
          yaxis = list(title = "客戶數"),
          barmode = 'stack'
        )
    })
    
    # CSV 下載功能
    output$download_structure <- downloadHandler(
      filename = function() {
        paste0("customer_structure_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        data <- retention_metrics()$status_distribution
        data$status_name <- c("首購客", "主力客", "瞌睡客", "半睡客", "沉睡客")[
          match(data$nes_status, c("N", "E0", "S1", "S2", "S3"))
        ]
        data$percentage <- round(data$count / sum(data$count) * 100, 2)
        
        write.csv(data[, c("nes_status", "status_name", "count", "percentage")], 
                  file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    output$download_risk <- downloadHandler(
      filename = function() {
        paste0("churn_risk_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        data <- dna_results()$data_by_customer %>%
          mutate(
            risk_score = case_when(
              nes_status == "N" ~ 10,
              nes_status == "E0" ~ 5,
              nes_status == "S1" ~ 40,
              nes_status == "S2" ~ 70,
              nes_status == "S3" ~ 95,
              TRUE ~ 50
            ),
            risk_level = case_when(
              risk_score <= 20 ~ "低風險",
              risk_score <= 50 ~ "中風險",
              risk_score <= 80 ~ "高風險",
              TRUE ~ "極高風險"
            )
          ) %>%
          select(customer_id, nes_status, risk_score, risk_level, total_spent, times)
        
        write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # =====================================================================
    # AI 分析功能區塊
    # =====================================================================
    
    # AI 留存分析
    output$ai_retention_analysis <- renderUI({
      req(retention_metrics())
      metrics <- retention_metrics()
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          result <- execute_gpt_request(
            var_id = "customer_retention_analysis",
            variables = list(
              retention_rate = round(metrics$retention_rate, 1),
              churn_rate = round(metrics$churn_rate, 1),
              core_ratio = round(metrics$core_ratio, 1),
              at_risk_count = metrics$at_risk_count,
              active_count = metrics$new_count + metrics$core_count
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(result)) {
            return(div(
              style = "padding: 15px; background: #f8f9fa; border-radius: 8px;",
              render_ai_result(result)
            ))
          }
        }, error = function(e) {
          cat("留存 AI 分析失敗:", e$message, "\n")
        })
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #f8f9fa; border-radius: 8px;",
        h5("📊 留存健康度評估", style = "color: #2c3e50;"),
        p(paste0("當前留存率 ", round(metrics$retention_rate, 1), "%，",
                ifelse(metrics$retention_rate > 70, "表現優異", "需要改善"))),
        h5("💡 建議策略", style = "color: #2c3e50; margin-top: 15px;"),
        tags$ul(
          tags$li("優先關注", metrics$at_risk_count, "位風險客戶"),
          tags$li("強化主力客戶經營，提升忠誠度"),
          tags$li("建立客戶流失預警機制")
        )
      )
    })
    
    # AI 首購客分析
    output$ai_new_customer <- renderUI({
      req(retention_metrics(), dna_results())
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      new_customer_data <- data[data$nes_status == "N", ]
      
      if(nrow(new_customer_data) > 0) {
        avg_aov <- mean(new_customer_data$m_value, na.rm = TRUE)
        avg_days <- mean(new_customer_data$r_value, na.rm = TRUE)
        
        if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
          tryCatch({
            result <- execute_gpt_request(
              var_id = "new_customer_analysis",
              variables = list(
                new_count = metrics$new_count,
                new_ratio = round((metrics$new_count / nrow(data)) * 100, 1),
                new_aov = round(avg_aov, 0),
                days_since = round(avg_days, 0)
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            if(!is.null(result)) {
              return(div(
                style = "padding: 15px; background: #e3f2fd; border-radius: 8px;",
                render_ai_result(result)
              ))
            }
          }, error = function(e) {
            cat("首購客 AI 分析失敗:", e$message, "\n")
          })
        }
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #e3f2fd; border-radius: 8px;",
        h5("🆕 首購客特徵", style = "color: #1976d2;"),
        p(paste0("共 ", metrics$new_count, " 位首購客戶")),
        h5("🎯 二購提升策略", style = "color: #1976d2; margin-top: 15px;"),
        tags$ul(
          tags$li("首購後 7-14 天發送感謝信與優惠券"),
          tags$li("推薦相關產品，提升客單價"),
          tags$li("建立新客專屬社群，增加黏著度")
        )
      )
    })
    
    # AI 主力客分析
    output$ai_core_customer <- renderUI({
      req(retention_metrics(), dna_results())
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      core_data <- data[data$nes_status == "E0", ]
      
      if(nrow(core_data) > 0) {
        avg_frequency <- mean(core_data$f_value, na.rm = TRUE)
        avg_monetary <- mean(core_data$m_value, na.rm = TRUE)
        revenue_contribution <- sum(core_data$m_value * core_data$f_value, na.rm = TRUE) / 
                               sum(data$m_value * data$f_value, na.rm = TRUE) * 100
        
        if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
          tryCatch({
            result <- execute_gpt_request(
              var_id = "core_customer_strategy",
              variables = list(
                core_count = metrics$core_count,
                core_ratio = round((metrics$core_count / nrow(data)) * 100, 1),
                avg_frequency = round(avg_frequency, 1),
                avg_monetary = round(avg_monetary, 2),
                revenue_contribution = round(revenue_contribution, 1)
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            if(!is.null(result)) {
              return(div(
                style = "padding: 15px; background: #e8f5e9; border-radius: 8px;",
                render_ai_result(result)
              ))
            }
          }, error = function(e) {
            cat("主力客 AI 分析失敗:", e$message, "\n")
          })
        }
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #e8f5e9; border-radius: 8px;",
        h5("🏆 主力客戶分析", style = "color: #2e7d32;"),
        p(paste0("共 ", metrics$core_count, " 位主力客戶")),
        h5("💎 VIP經營策略", style = "color: #2e7d32; margin-top: 15px;"),
        tags$ul(
          tags$li("建立VIP會員制度與專屬權益"),
          tags$li("提供個人化服務與優先支援"),
          tags$li("定期舉辦專屬活動增強黏著度"),
          tags$li("推薦高價值產品提升客單價")
        )
      )
    })
    
    # AI 半睡客分析
    output$ai_semi_dormant_customer <- renderUI({
      req(retention_metrics(), dna_results())
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      semi_dormant_data <- data[data$nes_status == "S2", ]
      
      if(nrow(semi_dormant_data) > 0) {
        avg_sleep_days <- mean(semi_dormant_data$r_value, na.rm = TRUE)
        avg_spend <- mean(semi_dormant_data$total_spent, na.rm = TRUE)
        last_purchase_cycle <- ifelse(mean(semi_dormant_data$f_value, na.rm = TRUE) > 0,
                                     avg_sleep_days / mean(semi_dormant_data$f_value, na.rm = TRUE),
                                     avg_sleep_days)
        
        if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
          tryCatch({
            result <- execute_gpt_request(
              var_id = "semi_dormant_customer_strategy",
              variables = list(
                semi_dormant_count = metrics$semi_sleeping_count,
                semi_dormant_ratio = round((metrics$semi_sleeping_count / nrow(data)) * 100, 1),
                avg_sleep_days = round(avg_sleep_days, 0),
                avg_spend = round(avg_spend, 0),
                last_purchase_cycle = round(last_purchase_cycle, 0)
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            if(!is.null(result)) {
              return(div(
                style = "padding: 15px; background: #fff8e1; border-radius: 8px;",
                render_ai_result(result)
              ))
            }
          }, error = function(e) {
            cat("半睡客 AI 分析失敗:", e$message, "\n")
          })
        }
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #fff8e1; border-radius: 8px;",
        h5("😴 半睡客戶分析", style = "color: #f9a825;"),
        p(paste0("共 ", metrics$semi_sleeping_count, " 位半睡客戶")),
        h5("⚡ 深度喚醒策略", style = "color: #f9a825; margin-top: 15px;"),
        tags$ul(
          tags$li("提供大額折扣券刺激回購"),
          tags$li("推出買一送一或滿額贈活動"),
          tags$li("多管道觸達提醒未結帳商品"),
          tags$li("問卷調查了解流失原因並改善")
        )
      )
    })
    
    # AI 瞌睡客分析
    output$ai_drowsy_customer <- renderUI({
      req(retention_metrics(), dna_results())
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      drowsy_data <- data[data$nes_status == "S1", ]
      
      if(nrow(drowsy_data) > 0) {
        avg_days <- mean(drowsy_data$r_value, na.rm = TRUE)
        avg_spend <- mean(drowsy_data$total_spent, na.rm = TRUE)
        
        if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
          tryCatch({
            result <- execute_gpt_request(
              var_id = "drowsy_customer_strategy",
              variables = list(
                drowsy_count = metrics$drowsy_count,
                drowsy_ratio = round((metrics$drowsy_count / nrow(data)) * 100, 1),
                avg_days = round(avg_days, 0),
                avg_spend = round(avg_spend, 0)
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            if(!is.null(result)) {
              return(div(
                style = "padding: 15px; background: #fff3e0; border-radius: 8px;",
                render_ai_result(result)
              ))
            }
          }, error = function(e) {
            cat("瞌睡客 AI 分析失敗:", e$message, "\n")
          })
        }
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #fff3e0; border-radius: 8px;",
        h5("😴 瞌睡客診斷", style = "color: #f57c00;"),
        p(paste0("共 ", metrics$drowsy_count, " 位瞌睡客戶")),
        h5("🔔 喚醒策略", style = "color: #f57c00; margin-top: 15px;"),
        tags$ul(
          tags$li("發送個人化關懷訊息"),
          tags$li("提供限時獨家優惠"),
          tags$li("推薦新品或熱銷商品")
        )
      )
    })
    
    # AI 沉睡客分析
    output$ai_sleeping_customer <- renderUI({
      req(retention_metrics(), dna_results())
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      sleeping_data <- data[data$nes_status == "S3", ]
      
      if(nrow(sleeping_data) > 0) {
        avg_sleep_days <- mean(sleeping_data$r_value, na.rm = TRUE)
        total_value <- sum(sleeping_data$total_spent, na.rm = TRUE)
        
        if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
          tryCatch({
            result <- execute_gpt_request(
              var_id = "sleeping_customer_strategy",
              variables = list(
                sleeping_count = metrics$sleeping_count,
                sleeping_ratio = round((metrics$sleeping_count / nrow(data)) * 100, 1),
                avg_sleep_days = round(avg_sleep_days, 0),
                total_value = round(total_value, 0)
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            if(!is.null(result)) {
              return(div(
                style = "padding: 15px; background: #ffebee; border-radius: 8px;",
                render_ai_result(result)
              ))
            }
          }, error = function(e) {
            cat("沉睡客 AI 分析失敗:", e$message, "\n")
          })
        }
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #ffebee; border-radius: 8px;",
        h5("💤 沉睡客分析", style = "color: #c62828;"),
        p(paste0("共 ", metrics$sleeping_count, " 位沉睡客戶")),
        h5("♻️ 激活策略", style = "color: #c62828; margin-top: 15px;"),
        tags$ul(
          tags$li("發送「我們想念您」主題郵件"),
          tags$li("提供大幅折扣或贈品"),
          tags$li("重新介紹品牌價值與改進")
        )
      )
    })
    
    # AI 結構分析
    output$ai_structure_analysis <- renderUI({
      req(retention_metrics())
      metrics <- retention_metrics()
      distribution <- metrics$status_distribution
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          result <- execute_gpt_request(
            var_id = "customer_status_analysis",
            variables = list(
              n_count = distribution$count[distribution$nes_status == "N"],
              n_ratio = round(distribution$count[distribution$nes_status == "N"] / sum(distribution$count) * 100, 1),
              e0_count = distribution$count[distribution$nes_status == "E0"],
              e0_ratio = round(distribution$count[distribution$nes_status == "E0"] / sum(distribution$count) * 100, 1),
              s1_count = distribution$count[distribution$nes_status == "S1"],
              s1_ratio = round(distribution$count[distribution$nes_status == "S1"] / sum(distribution$count) * 100, 1),
              s2_count = distribution$count[distribution$nes_status == "S2"],
              s2_ratio = round(distribution$count[distribution$nes_status == "S2"] / sum(distribution$count) * 100, 1),
              s3_count = distribution$count[distribution$nes_status == "S3"],
              s3_ratio = round(distribution$count[distribution$nes_status == "S3"] / sum(distribution$count) * 100, 1)
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(result)) {
            return(div(
              style = "padding: 15px; background: #f5f5f5; border-radius: 8px;",
              render_ai_result(result)
            ))
          }
        }, error = function(e) {
          cat("結構 AI 分析失敗:", e$message, "\n")
        })
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #f5f5f5; border-radius: 8px;",
        h5("📊 結構健康度", style = "color: #424242;"),
        p("客戶結構分析顯示當前狀態分布"),
        h5("🎯 優化目標", style = "color: #424242; margin-top: 15px;"),
        tags$ul(
          tags$li("提升主力客比率至 30% 以上"),
          tags$li("降低沉睡客比率至 20% 以下"),
          tags$li("維持新客獲取與流失的平衡")
        )
      )
    })
    
  })
}