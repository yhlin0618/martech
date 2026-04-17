# 營收脈能模組 (Revenue Pulse Module)（整合 Hint & Prompt 系統）
# 量化收入規模、單客價值與獲利韌性

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)
library(tidyr)
library(markdown)

# 載入提示和prompt系統
source("utils/hint_system.R")
source("utils/prompt_manager.R")
# 載入 AI 載入管理器
if(file.exists("utils/ai_loading_manager.R")) {
  source("utils/ai_loading_manager.R")
}
# 載入 reactive 載入助手
if(file.exists("utils/reactive_loading.R")) {
  source("utils/reactive_loading.R")
}

# UI Function
revenuePulseModuleUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  tagList(
    # 初始化 AI 載入管理器
    if(exists("init_ai_loading_manager")) init_ai_loading_manager() else NULL,
    
    fluidRow(
      # 上方 KPI 卡片
      column(3,
        bs4ValueBox(
          value = textOutput(ns("total_revenue")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "銷售額 (美金) ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "revenue_pulse_sales", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "銷售額 (美金)"
          },
          icon = icon("dollar-sign"),
          color = "primary",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("arpu")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "人均購買金額 (美金) ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "revenue_pulse_arpu", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "人均購買金額 (美金)"
          },
          icon = icon("dollar"),
          color = "success",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("avg_clv")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "平均顧客終生價值 (美金) ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "revenue_pulse_clv", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "平均顧客終生價值 (美金)"
          },
          icon = icon("chart-line"),
          color = "info",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("transaction_consistency")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "交易穩定度 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = "檢視整體顧客是否會穩定交易：Top 20%為穩定交易客戶，Bottom 20%為高風險群",
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            tags$span(
              "交易穩定度 ",
              tags$small("(檢視整體顧客是否會穩定交易)", style = "color: #6c757d;")
            )
          },
          icon = icon("balance-scale"),
          color = "warning",
          width = 12
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 左側：客單價分析
      column(6,
        bs4Card(
          title = "客單價分析",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("aov_analysis")),
          hr(),
          h6("🤖 AI 客群分析", style = "color: #2c3e50; font-weight: bold;"),
          uiOutput(ns("ai_aov_insights"))
        )
      ),
      
      # 右側：CLV 分布
      column(6,
        bs4Card(
          title = "顧客終生價值分布 (80/20法則)",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("clv_distribution")),
          hr(),
          h6("🤖 AI 價值分群建議", style = "color: #2c3e50; font-weight: bold;"),
          uiOutput(ns("ai_clv_insights")),
          br(),
          downloadButton(ns("download_clv_segments"), "下載客戶名單", class = "btn-sm btn-secondary")
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 收入趨勢分析
      column(12,
        bs4Card(
          title = "收入成長曲線",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("revenue_trend")),
          hr(),
          h6("🤖 AI 趨勢分析", style = "color: #2c3e50; font-weight: bold;"),
          uiOutput(ns("ai_trend_insights"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 詳細數據表
      column(12,
        bs4Card(
          title = "營收指標明細",
          status = "secondary",
          solidHeader = TRUE,
          collapsible = TRUE,
          width = 12,
          div(
            style = "margin-bottom: 10px;",
            downloadButton(ns("download_revenue_details"), "📥 下載完整客戶名單", 
                          class = "btn-success btn-sm")
          ),
          DTOutput(ns("revenue_details"))
        )
      )
    )
  )
}

# Server Function
revenuePulseModuleServer <- function(id, con, user_info, dna_module_result, time_series_data = NULL, enable_hints = TRUE, enable_gpt = TRUE, chat_api = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # 載入 prompt 管理器
    if(enable_gpt) {
      prompts_df <- load_prompts()
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
    
    # 計算營收指標
    revenue_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      
      # 基本指標計算
      metrics <- list(
        total_revenue = sum(data$total_spent, na.rm = TRUE),
        customer_count = nrow(data),
        arpu = mean(data$total_spent, na.rm = TRUE),
        avg_clv = mean(data$clv, na.rm = TRUE),
        
        # 新客單價 (首購客 N)
        new_customer_aov = data %>%
          filter(nes_status == "N") %>%
          summarise(aov = mean(m_value, na.rm = TRUE)) %>%
          pull(aov),
        
        # 主力客單價 (E0)
        core_customer_aov = data %>%
          filter(nes_status == "E0") %>%
          summarise(aov = mean(m_value, na.rm = TRUE)) %>%
          pull(aov),
        
        # 交易穩定度 (使用 CRI - Customer Regularity Index)
        transaction_consistency = mean(data$cri, na.rm = TRUE)
      )
      
      return(metrics)
    })
    
    # KPI 顯示
    output$total_revenue <- renderText({
      metrics <- revenue_metrics()
      paste0("$", format(round(metrics$total_revenue, 0), big.mark = ","))
    })
    
    output$arpu <- renderText({
      metrics <- revenue_metrics()
      paste0("$", format(round(metrics$arpu, 2), big.mark = ","))
    })
    
    output$avg_clv <- renderText({
      metrics <- revenue_metrics()
      paste0("$", format(round(metrics$avg_clv, 2), big.mark = ","))
    })
    
    output$transaction_consistency <- renderText({
      metrics <- revenue_metrics()
      if (is.na(metrics$transaction_consistency)) {
        "N/A"
      } else {
        paste0(round(metrics$transaction_consistency * 100, 1), "%")
      }
    })
    
    # 客單價分析圖表
    output$aov_analysis <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      metrics <- revenue_metrics()
      
      # 準備數據
      aov_data <- data.frame(
        Category = c("全體平均", "新客", "主力客"),
        AOV = c(
          metrics$arpu,
          metrics$new_customer_aov,
          metrics$core_customer_aov
        )
      )
      
      # 過濾掉 NA 值
      aov_data <- aov_data[!is.na(aov_data$AOV), ]
      
      plot_ly(aov_data, 
              x = ~Category, 
              y = ~AOV, 
              type = 'bar',
              marker = list(color = c('#3498db', '#2ecc71', '#f39c12')),
              text = ~paste0("$", format(round(AOV, 2), big.mark = ",")),
              textposition = "outside",
              hovertemplate = "%{x}<br>平均客單價: $%{y:,.2f}<extra></extra>") %>%
        layout(
          title = list(text = "不同客群平均客單價比較", font = list(size = 16)),
          xaxis = list(title = "客戶類型"),
          yaxis = list(title = "平均客單價 ($)", tickformat = ",.0f"),
          showlegend = FALSE
        )
    })
    
    # CLV 分布圖 (散點圖)
    output$clv_distribution <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # CLV 分組 (80/20法則 - 三群)
      clv_groups <- data %>%
        filter(!is.na(clv)) %>%
        arrange(desc(clv)) %>%
        mutate(
          cum_revenue = cumsum(clv),
          total_revenue = sum(clv),
          revenue_pct = cum_revenue / total_revenue,
          clv_group = case_when(
            revenue_pct <= 0.8 ~ "高價值客戶",
            revenue_pct <= 0.95 ~ "中價值客戶",
            TRUE ~ "低價值客戶"
          ),
          # 為散點圖加入位置變數
          x_position = case_when(
            clv_group == "低價值客戶" ~ 1,
            clv_group == "中價值客戶" ~ 2,
            TRUE ~ 3
          )
        )
      
      # 計算每組統計
      clv_summary <- clv_groups %>%
        group_by(clv_group) %>%
        summarise(
          count = n(),
          avg_clv = mean(clv),
          median_clv = median(clv),
          min_clv = min(clv),
          max_clv = max(clv),
          q1_clv = quantile(clv, 0.25),
          q3_clv = quantile(clv, 0.75),
          .groups = "drop"
        ) %>%
        mutate(
          x_position = case_when(
            clv_group == "低價值客戶" ~ 1,
            clv_group == "中價值客戶" ~ 2,
            TRUE ~ 3
          )
        )
      
      # 為每個客戶群加入一些隨機抖動（jitter）
      clv_groups <- clv_groups %>%
        mutate(
          x_jittered = x_position + runif(n(), -0.3, 0.3)
        )
      
      # 建立散點圖
      plot_ly() %>%
        # 加入散點（每個客戶）
        add_trace(
          data = clv_groups,
          x = ~x_jittered,
          y = ~clv,
          type = 'scatter',
          mode = 'markers',
          marker = list(
            size = 4,
            opacity = 0.4,
            color = ~x_position,
            colorscale = list(
              c(0, "#e74c3c"),
              c(0.5, "#f39c12"),
              c(1, "#27ae60")
            ),
            showscale = FALSE
          ),
          hovertemplate = "客戶ID: %{text}<br>CLV: $%{y:,.0f}<extra></extra>",
          text = ~customer_id,
          showlegend = FALSE
        ) %>%
        # 加入盒鬚圖的統計線
        add_trace(
          data = clv_summary,
          x = ~x_position,
          y = ~median_clv,
          type = 'scatter',
          mode = 'lines+markers',
          name = '中位數',
          line = list(color = '#2c3e50', width = 2),
          marker = list(size = 12, color = '#2c3e50'),
          hovertemplate = "%{x}<br>中位數: $%{y:,.0f}<extra></extra>"
        ) %>%
        # 加入平均值線
        add_trace(
          data = clv_summary,
          x = ~x_position,
          y = ~avg_clv,
          type = 'scatter',
          mode = 'markers',
          name = '平均值',
          marker = list(
            size = 10,
            color = '#e74c3c',
            symbol = 'diamond'
          ),
          hovertemplate = "%{x}<br>平均值: $%{y:,.0f}<extra></extra>"
        ) %>%
        # 加入四分位範圍（透明矩形）
        add_trace(
          data = clv_summary,
          x = ~x_position,
          y = ~q1_clv,
          type = 'scatter',
          mode = 'lines',
          line = list(color = 'transparent'),
          showlegend = FALSE,
          hoverinfo = 'skip'
        ) %>%
        add_trace(
          data = clv_summary,
          x = ~x_position,
          y = ~q3_clv,
          type = 'scatter',
          mode = 'lines',
          fill = 'tonexty',
          fillcolor = 'rgba(44, 62, 80, 0.1)',
          line = list(color = 'transparent'),
          showlegend = FALSE,
          hoverinfo = 'skip'
        ) %>%
        layout(
          title = list(text = "CLV 分布 (80/20法則)", font = list(size = 16)),
          xaxis = list(
            title = "客戶分群",
            tickmode = "array",
            tickvals = c(1, 2, 3),
            ticktext = c("低價值\n(Bottom 20%)", "中價值\n(Middle 60%)", "高價值\n(Top 20%)")
          ),
          yaxis = list(
            title = "顧客終生價值 ($)",
            tickformat = ",.0f"
          ),
          legend = list(x = 0.8, y = 0.95),
          annotations = list(
            list(
              x = 0.5,
              y = 1.1,
              xref = "paper",
              yref = "paper",
              text = paste0(
                "📊 高價值客戶貢獻 80% 營收 | ",
                "🔶 中位數 | 🔹 平均值 | ",
                "灰色區域: 四分位範圍 (Q1-Q3)"
              ),
              showarrow = FALSE,
              font = list(size = 11, color = "#7f8c8d")
            )
          )
        )
    })
    
    # 收入趨勢分析（使用時間序列數據）
    output$revenue_trend <- renderPlotly({
      # 檢查是否有時間序列數據
      if (!is.null(time_series_data)) {
        # 取得月度數據
        monthly_data <- time_series_data$monthly_data()
        
        if (!is.null(monthly_data) && nrow(monthly_data) > 0) {
          # 確保日期格式正確
          monthly_data$period_date <- as.Date(monthly_data$period_date)
          
          # 創建趨勢圖
          plot_ly(monthly_data, x = ~period_date) %>%
            add_trace(
              y = ~revenue,
              type = 'scatter',
              mode = 'lines+markers',
              name = '月度收入',
              line = list(color = '#3498db', width = 3),
              marker = list(size = 8),
              hovertemplate = "%{x|%Y-%m}<br>收入: $%{y:,.0f}<extra></extra>"
            ) %>%
            add_trace(
              y = ~revenue_growth,
              type = 'bar',
              name = '成長率 (%)',
              yaxis = 'y2',
              marker = list(
                color = ~ifelse(revenue_growth >= 0, '#2ecc71', '#e74c3c')
              ),
              hovertemplate = "%{x|%Y-%m}<br>成長率: %{y:.1f}%<extra></extra>"
            ) %>%
            layout(
              title = list(text = "月度收入趨勢與成長率", font = list(size = 16)),
              xaxis = list(
                title = "月份",
                type = "date",
                tickformat = "%Y-%m",
                dtick = "M1",
                tickangle = -45,
                range = c(min(monthly_data$period_date) - 15, max(monthly_data$period_date) + 15)
              ),
              yaxis = list(
                title = "收入 ($)",
                side = 'left',
                tickformat = ",.0f"
              ),
              yaxis2 = list(
                title = '成長率 (%)',
                overlaying = 'y',
                side = 'right'
              ),
              legend = list(x = 0.1, y = 0.95),
              hovermode = 'x unified'
            )
        } else {
          # 沒有數據時顯示提示
          plot_ly() %>%
            add_annotations(
              text = "時間序列數據不足\n需要更多交易記錄",
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 16, color = "#7f8c8d")
            ) %>%
            layout(
              xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
              yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
            )
        }
      } else {
        # 沒有時間序列模組時顯示提示
        plot_ly() %>%
          add_annotations(
            text = "收入趨勢分析需要時間序列數據\n請確保上傳資料包含詳細交易時間",
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(size = 16, color = "#7f8c8d")
          ) %>%
          layout(
            xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
            yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
          )
      }
    })
    
    # 詳細數據表
    output$revenue_details <- renderDT({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備顯示數據
      display_data <- data %>%
        select(
          customer_id,
          total_spent,
          m_value,
          clv,
          nes_status,
          times
        ) %>%
        rename(
          "客戶ID" = customer_id,
          "總消費金額" = total_spent,
          "平均單次消費" = m_value,
          "顧客終生價值" = clv,
          "客戶狀態" = nes_status,
          "購買次數" = times
        ) %>%
        mutate(
          across(c("總消費金額", "平均單次消費", "顧客終生價值"), 
                 ~round(., 2))
        )
      
      datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(2, 'desc')),  # 按總消費金額降序
          dom = 'frtip',  # 移除 B (buttons)
          columnDefs = list(
            list(className = 'dt-right', targets = c(1, 2, 3, 5))
          )
        ),
        rownames = FALSE
      ) %>%
        formatCurrency(c("總消費金額", "平均單次消費", "顧客終生價值"), "$")
    })
    
    # 下載客戶詳細資料
    output$download_revenue_details <- downloadHandler(
      filename = function() {
        paste0("revenue_customer_details_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(dna_results())
        data <- dna_results()$data_by_customer
        
        # 準備完整資料
        export_data <- data %>%
          select(
            customer_id,
            total_spent,
            m_value,
            clv,
            nes_status,
            times,
            r_value,
            f_value
          ) %>%
          rename(
            "客戶ID" = customer_id,
            "總消費金額" = total_spent,
            "平均單次消費" = m_value,
            "顧客終生價值" = clv,
            "客戶狀態" = nes_status,
            "購買次數" = times,
            "最近購買天數" = r_value,
            "購買頻率" = f_value
          )
        
        write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # ========== AI 分析功能 ==========
    
    # AI 客單價分析 (整合 GPT 分析)
    ai_aov_analysis <- reactive({
      req(revenue_metrics())
      metrics <- revenue_metrics()
      
      # 基礎分析
      analysis <- list(
        new_vs_core = if(!is.na(metrics$new_customer_aov) && !is.na(metrics$core_customer_aov)) {
          ratio <- round(metrics$core_customer_aov / metrics$new_customer_aov, 2)
          if(ratio > 1.5) {
            paste0("✅ 主力客單價是新客的 ", ratio, " 倍，建議加強新客轉換策略")
          } else if(ratio < 0.8) {
            paste0("⚠️ 主力客單價偏低（只有新客的 ", ratio, " 倍），需要提升忠誠客戶價值")
          } else {
            paste0("📊 主力客單價與新客比值適中（", ratio, " 倍）")
          }
        } else {
          "📊 資料不足，無法比較新客與主力客"
        }
      )
      
      # 嘗試使用 GPT 加強分析
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          # 準備 GPT 分析資料
          gpt_result <- execute_gpt_request(
            var_id = "revenue_pulse_aov_analysis",
            variables = list(
              new_customer_aov = metrics$new_customer_aov,
              core_customer_aov = metrics$core_customer_aov,
              overall_arpu = metrics$arpu,
              customer_count = metrics$customer_count
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(gpt_result)) {
            analysis$recommendation <- gpt_result
          } else {
            # 使用預設建議
            analysis$recommendation <- if(!is.na(metrics$new_customer_aov) && !is.na(metrics$arpu)) {
              if(metrics$new_customer_aov < metrics$arpu * 0.7) {
                "🎯 新客策略：提供首購優惠，搭配滿額贈品，提升初次購買價值"
              } else if(metrics$core_customer_aov > metrics$arpu * 1.5) {
                "🎯 主力客策略：VIP 專屬優惠、限量商品、會員積分加倍"
              } else {
                "🎯 平衡策略：提供階梯式優惠，鼓勵消費升級"
              }
            } else {
              "📌 建議收集更多交易資料進行分析"
            }
          }
        }, error = function(e) {
          # GPT 失敗時使用預設建議
          analysis$recommendation <- "🎯 持續優化客戶分群策略，提升整體價值"
        })
      } else {
        # 沒有 GPT 時使用預設建議
        analysis$recommendation <- if(!is.na(metrics$new_customer_aov) && !is.na(metrics$arpu)) {
          if(metrics$new_customer_aov < metrics$arpu * 0.7) {
            "🎯 新客策略：提供首購優惠，搭配滿額贈品，提升初次購買價值"
          } else if(metrics$core_customer_aov > metrics$arpu * 1.5) {
            "🎯 主力客策略：VIP 專屬優惠、限量商品、會員積分加倍"
          } else {
            "🎯 平衡策略：提供階梯式優惠，鼓勵消費升級"
          }
        } else {
          "📌 建議收集更多交教資料進行分析"
        }
      }
      
      return(analysis)
    })
    
    # AI CLV 分群分析
    ai_clv_analysis <- reactive({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # CLV 分群 (80/20法則)
      clv_segments <- data %>%
        filter(!is.na(clv)) %>%
        arrange(desc(clv)) %>%
        mutate(
          cum_revenue = cumsum(clv),
          total_revenue = sum(clv),
          revenue_pct = cum_revenue / total_revenue,
          clv_segment = case_when(
            revenue_pct <= 0.8 ~ "高價值",
            revenue_pct <= 0.95 ~ "中價值",
            TRUE ~ "低價值"
          )
        )
      
      # 各群統計
      segment_stats <- clv_segments %>%
        group_by(clv_segment) %>%
        summarise(
          count = n(),
          avg_clv = mean(clv),
          total_clv = sum(clv),
          pct_of_customers = n() / nrow(clv_segments) * 100,
          pct_of_revenue = sum(clv) / sum(clv_segments$clv) * 100
        )
      
      # 準備 GPT 分析資料
      high_stats <- segment_stats[segment_stats$clv_segment == "高價值", ]
      mid_stats <- segment_stats[segment_stats$clv_segment == "中價值", ]
      low_stats <- segment_stats[segment_stats$clv_segment == "低價值", ]
      
      # 嘗試使用 GPT 分析
      recommendations <- NULL
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          gpt_result <- execute_gpt_request(
            var_id = "revenue_pulse_clv_analysis",
            variables = list(
              high_value_count = if(nrow(high_stats) > 0) high_stats$count else 0,
              high_value_pct = if(nrow(high_stats) > 0) round(high_stats$pct_of_customers, 1) else 0,
              high_value_revenue_pct = if(nrow(high_stats) > 0) round(high_stats$pct_of_revenue, 1) else 0,
              high_value_avg_clv = if(nrow(high_stats) > 0) round(high_stats$avg_clv, 0) else 0,
              mid_value_count = if(nrow(mid_stats) > 0) mid_stats$count else 0,
              mid_value_pct = if(nrow(mid_stats) > 0) round(mid_stats$pct_of_customers, 1) else 0,
              mid_value_revenue_pct = if(nrow(mid_stats) > 0) round(mid_stats$pct_of_revenue, 1) else 0,
              mid_value_avg_clv = if(nrow(mid_stats) > 0) round(mid_stats$avg_clv, 0) else 0,
              low_value_count = if(nrow(low_stats) > 0) low_stats$count else 0,
              low_value_pct = if(nrow(low_stats) > 0) round(low_stats$pct_of_customers, 1) else 0,
              low_value_revenue_pct = if(nrow(low_stats) > 0) round(low_stats$pct_of_revenue, 1) else 0,
              low_value_avg_clv = if(nrow(low_stats) > 0) round(low_stats$avg_clv, 0) else 0
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(gpt_result)) {
            # 如果 GPT 成功，使用 GPT 結果
            recommendations <- list(
              gpt_analysis = gpt_result,
              high = "🎆 高價值客戶：深度經營策略",
              mid = "🎯 中價值客戶：提升策略",
              low = "💡 低價值客戶：激活策略"
            )
          }
        }, error = function(e) {
          # GPT 失敗，使用預設
          cat("CLV GPT 分析失敗:", e$message, "\n")
        })
      }
      
      # 如果沒有 GPT 結果，使用預設建議
      if(is.null(recommendations)) {
        recommendations <- list(
          high = "🎆 高價值客戶：VIP 專屬服務、優先預購權、定制化產品、生日特殊優惠",
          mid = "🎯 中價值客戶：會員積分計劃、滿額贈品、季度優惠券、推薦獎勵",
          low = "💡 低價值客戶：首購優惠、入門產品推廣、限時特價、免運費活動"
        )
      }
      
      return(list(
        segments = clv_segments,
        stats = segment_stats,
        recommendations = recommendations
      ))
    })
    
    # AI 趨勢分析
    ai_trend_analysis <- reactive({
      if (!is.null(time_series_data)) {
        monthly_data <- time_series_data$monthly_data()
        
        if (!is.null(monthly_data) && nrow(monthly_data) > 0) {
          # 計算趨勢
          avg_growth <- mean(monthly_data$revenue_growth, na.rm = TRUE)
          recent_growth <- tail(monthly_data$revenue_growth, 3)
          recent_avg <- mean(recent_growth, na.rm = TRUE)
          
          # 處理 NA 值避免錯誤
          trend_direction <- if(!is.na(recent_avg) && !is.na(avg_growth)) {
            if(recent_avg > avg_growth) "上升" else "下降"
          } else {
            "穩定"
          }
          
          max_growth <- max(monthly_data$revenue_growth, na.rm = TRUE)
          min_growth <- min(monthly_data$revenue_growth, na.rm = TRUE)
          
          # 確保數值不是 NA
          avg_growth <- if(is.na(avg_growth)) 0 else avg_growth
          recent_avg <- if(is.na(recent_avg)) 0 else recent_avg
          max_growth <- if(is.na(max_growth) || is.infinite(max_growth)) 0 else max_growth
          min_growth <- if(is.na(min_growth) || is.infinite(min_growth)) 0 else min_growth
          
          # 嘗試使用 GPT 分析
          analysis <- NULL
          if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
            tryCatch({
              gpt_result <- execute_gpt_request(
                var_id = "revenue_pulse_trend_analysis",
                variables = list(
                  avg_growth = round(avg_growth, 1),
                  recent_growth = round(recent_avg, 1),
                  trend_direction = trend_direction,
                  max_growth = round(max_growth, 1),
                  min_growth = round(min_growth, 1)
                ),
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              if(!is.null(gpt_result)) {
                analysis <- gpt_result
              }
            }, error = function(e) {
              cat("趨勢 GPT 分析失敗:", e$message, "\n")
            })
          }
          
          # 如果沒有 GPT 結果，使用預設分析
          if(is.null(analysis)) {
            analysis <- paste0(
              "📈 最近三個月平均成長率：", round(recent_avg, 1), "%\n",
              "📊 整體趨勢：", trend_direction, "\n",
              if(trend_direction == "上升") {
                "✅ 建議：加大行銷投入，擴大市場佔有率"
              } else if(trend_direction == "下降") {
                "⚠️ 建議：調整產品策略，加強客戶留存"
              } else {
                "📌 建議：持續監控市場變化，準備應對策略"
              }
            )
          }
          
          return(analysis)
        }
      }
      
      return("📊 需要更多時間序列資料進行趨勢分析")
    })
    
    # 輸出 AI 分析結果
    output$ai_aov_insights <- renderUI({
      analysis <- ai_aov_analysis()
      
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px;",
        p(analysis$new_vs_core, style = "margin-bottom: 10px;"),
        # 檢查是否為 HTML 格式（GPT 回應通常包含 markdown）
        if(!is.null(analysis$recommendation)) {
          # 檢查是否包含 Markdown 格式
          has_markdown <- grepl("\\*\\*", analysis$recommendation) || 
                         grepl("##", analysis$recommendation) || 
                         grepl("\n\n", analysis$recommendation)
          
          if(has_markdown) {
            HTML(markdown::markdownToHTML(text = analysis$recommendation, fragment.only = TRUE))
          } else {
            p(analysis$recommendation, style = "margin-bottom: 0; font-weight: bold; color: #2c3e50;")
          }
        } else {
          p("分析中...", style = "margin-bottom: 0; color: #6c757d;")
        }
      )
    })
    
    output$ai_clv_insights <- renderUI({
      # 使用更優雅的載入效果
      if(exists("create_pulse_loading")) {
        # 檢查分析狀態
        analysis <- ai_clv_analysis()
        
        # 如果分析還未完成，顯示脈動載入動畫
        if(is.null(analysis) || is.null(analysis$stats)) {
          invalidateLater(500)  # 每0.5秒檢查一次
          return(create_pulse_loading(
            message = "正在分析客戶價值分群...",
            icon_name = "chart-pie"
          ))
        }
      } else if(exists("create_simple_ai_loading")) {
        # 使用簡單載入動畫作為備用
        analysis <- ai_clv_analysis()
        
        if(is.null(analysis) || is.null(analysis$stats)) {
          invalidateLater(500)
          return(create_simple_ai_loading("🤖 正在分析客戶終生價值..."))
        }
      } else {
        # 沒有載入管理器時的備用方案
        analysis <- ai_clv_analysis()
      }
      
      # 確保分析存在
      req(analysis)
      stats <- analysis$stats
      
      # 檢查是否有 GPT 分析結果
      if(!is.null(analysis$recommendations$gpt_analysis)) {
        # 使用 GPT 分析結果，轉換 Markdown
        gpt_content <- analysis$recommendations$gpt_analysis
        # 檢查是否包含 Markdown 格式
        if(grepl("\\*\\*|##|\\n\\n|^[0-9]+\\.|^-\\s", gpt_content)) {
          html_content <- markdownToHTML(text = gpt_content, fragment.only = TRUE)
        } else {
          html_content <- gpt_content
        }
        div(
          style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px;",
          HTML(html_content)
        )
      } else {
        # 使用預設格式
        div(
          style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px;",
          
          # 統計摘要
          p(paste0(
            "📊 80/20分析：",
            round(stats$pct_of_customers[stats$clv_segment == "高價值"], 1), "% 的客戶貢獻了 ",
            round(stats$pct_of_revenue[stats$clv_segment == "高價值"], 1), "% 的營收"
          ), style = "font-weight: bold; margin-bottom: 15px;"),
          
          # 各群建議
          div(
            h6("🎯 行銷建議：", style = "color: #2c3e50; margin-bottom: 10px;"),
            tags$ul(
              style = "margin-bottom: 0;",
              tags$li(analysis$recommendations$high, style = "margin-bottom: 5px;"),
              tags$li(analysis$recommendations$mid, style = "margin-bottom: 5px;"),
              tags$li(analysis$recommendations$low)
            )
          )
        )
      }
    })
    
    output$ai_trend_insights <- renderUI({
      # 使用更優雅的載入效果
      if(exists("create_pulse_loading")) {
        # 檢查分析狀態
        analysis <- ai_trend_analysis()
        
        # 如果分析還未完成，顯示脈動載入動畫
        if(is.null(analysis)) {
          invalidateLater(500)  # 每0.5秒檢查一次
          return(create_pulse_loading(
            message = "正在分析營收趨勢...",
            icon_name = "chart-line"
          ))
        }
      } else if(exists("create_simple_ai_loading")) {
        # 使用簡單載入動畫作為備用
        analysis <- ai_trend_analysis()
        
        if(is.null(analysis)) {
          invalidateLater(500)
          return(create_simple_ai_loading("📈 正在分析收入趨勢..."))
        }
      } else {
        # 沒有載入管理器時的備用方案
        analysis <- ai_trend_analysis()
      }
      
      # 檢查分析內容並轉換 Markdown
      if(!is.null(analysis)) {
        # 檢查是否包含 Markdown 格式
        if(grepl("\\*\\*|##|\\n\\n|^[0-9]+\\.|^-\\s", analysis)) {
          # 轉換 Markdown 為 HTML
          html_content <- markdownToHTML(text = analysis, fragment.only = TRUE)
          content_display <- HTML(html_content)
        } else {
          # 純文字使用 pre 標籤保留格式
          content_display <- pre(analysis, style = "margin-bottom: 0; white-space: pre-wrap; font-family: inherit;")
        }
      } else {
        content_display <- p("分析中...", style = "color: #6c757d;")
      }
      
      div(
        style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px;",
        content_display
      )
    })
    
    # 下載 CLV 分群名單
    output$download_clv_segments <- downloadHandler(
      filename = function() {
        paste0("clv_segments_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        analysis <- ai_clv_analysis()
        segments_data <- analysis$segments %>%
          select(customer_id, clv, clv_segment) %>%
          rename(
            "客戶ID" = customer_id,
            "顧客終生價值" = clv,
            "價值分群" = clv_segment
          ) %>%
          arrange(desc(clv))
        
        write.csv(segments_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
  })
}