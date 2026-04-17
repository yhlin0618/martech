# 活躍轉化模組 (Engagement Flow Module)
# 掌握互動 → 再購 → 喚醒的節奏深度

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
engagementFlowModuleUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  tagList(
    # 初始化提示系統
    if(enable_hints) init_hint_system() else NULL,
    fluidRow(
      # KPI 卡片
      column(3,
        bs4ValueBox(
          value = textOutput(ns("avg_cai")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客活躍度 (CAI) ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_conversion_cai", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客活躍度 (CAI)"
          },
          icon = icon("fire"),
          color = "danger",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("conversion_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客轉化率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_conversion_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客轉化率"
          },
          icon = icon("arrow-trend-up"),
          color = "success",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("avg_frequency")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "購買頻率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_purchase_frequency", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "平均購買頻率"
          },
          icon = icon("shopping-cart"),
          color = "info",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("avg_ipt")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "平均再購時間(天) ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_inter_purchase_time", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "平均再購時間(天)"
          },
          icon = icon("clock"),
          color = "warning",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("reactivation_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "喚醒率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_reactivation_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "喚醒率"
          },
          icon = icon("bell"),
          color = "warning",
          width = 12
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 客戶活躍度分布
      column(6,
        bs4Card(
          title = tags$span(
            "客戶活躍度分布",
            if(enable_hints && !is.null(hints_df)) {
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d; margin-left: 8px;",
                title = hints_df[hints_df$var_id == "activity_distribution_chart", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            }
          ),
          status = "danger",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("cai_distribution"))
        )
      ),
      
      # 轉化率分析
      column(6,
        bs4Card(
          title = tags$span(
            "轉化率分析",
            if(enable_hints && !is.null(hints_df)) {
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d; margin-left: 8px;",
                title = hints_df[hints_df$var_id == "conversion_funnel_chart", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            }
          ),
          status = "success",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("conversion_analysis"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 購買頻率與週期分析
      column(12,
        bs4Card(
          title = "購買頻率與週期分析",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("frequency_cycle_analysis"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 喚醒機會分析
      column(6,
        bs4Card(
          title = "客戶喚醒機會分析",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          helpText("提示：顯示需要喚醒的客戶群體"),
          plotlyOutput(ns("reactivation_opportunities")),
          br(),
          downloadButton(ns("download_reactivation_csv"), "匯出需喚醒客戶清單", class = "btn-warning")
        )
      ),
      
      # 忠誠度階梯
      column(6,
        bs4Card(
          title = "忠誠度階梯",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("loyalty_ladder")),
          br(),
          downloadButton(ns("download_loyalty_csv"), "匯出忠誠度階梯分析", class = "btn-primary")
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 詳細數據表
      column(12,
        bs4Card(
          title = "活躍轉化指標明細",
          status = "secondary",
          solidHeader = TRUE,
          collapsible = TRUE,
          width = 12,
          DTOutput(ns("engagement_details"))
        )
      )
    ),
    
    br(),
    
    # AI 智能分析區域
    fluidRow(
      column(12,
        bs4Card(
          title = "AI 智能分析",
          status = "info",
          solidHeader = TRUE,
          collapsible = TRUE,
          width = 12,
          tabsetPanel(
            id = ns("ai_analysis_tabs"),
            type = "tabs",
            tabPanel(
              "購買頻率分析",
              br(),
              actionButton(ns("analyze_frequency"), "分析購買頻率意義", class = "btn-info"),
              br(), br(),
              htmlOutput(ns("frequency_analysis_output"))
            ),
            tabPanel(
              "喚醒機會分析",
              br(),
              actionButton(ns("analyze_reactivation"), "分析客戶喚醒機會", class = "btn-warning"),
              br(), br(),
              htmlOutput(ns("reactivation_analysis_output"))
            ),
            tabPanel(
              "忠誠度階梯分析",
              br(),
              actionButton(ns("analyze_loyalty"), "分析忠誠度階梯策略", class = "btn-primary"),
              br(), br(),
              htmlOutput(ns("loyalty_analysis_output"))
            ),
            tabPanel(
              "喚醒客戶清單分析",
              br(),
              actionButton(ns("analyze_reactivation_list"), "分析需喚醒客戶清單", class = "btn-secondary"),
              br(), br(),
              htmlOutput(ns("reactivation_list_output"))
            )
          )
        )
      )
    )
  )
}

# Server Function
engagementFlowModuleServer <- function(id, con, user_info, dna_module_result, enable_hints = TRUE) {
  moduleServer(id, function(input, output, session) {
    
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
    
    # 計算活躍轉化指標
    engagement_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      
      # 基本指標計算
      metrics <- list(
        # 顧客活躍度 (CAI)
        avg_cai = mean(data$cai_value, na.rm = TRUE),
        
        # 再購率（購買2次以上的客戶比例）
        repeat_rate = (sum(data$times >= 2, na.rm = TRUE) / nrow(data)) * 100,
        
        # 平均購買頻率
        avg_frequency = mean(data$f_value, na.rm = TRUE),
        
        # 平均再購時間
        avg_ipt = mean(data$ipt_mean, na.rm = TRUE),
        
        # 轉化率（從新客到主力客）
        conversion_rate = (sum(data$nes_status == "E0", na.rm = TRUE) / 
                          sum(data$nes_status %in% c("N", "E0"), na.rm = TRUE)) * 100,
        
        # 喚醒機會（S1, S2 客戶）
        reactivation_targets = sum(data$nes_status %in% c("S1", "S2"), na.rm = TRUE),
        
        # 活躍度分組
        cai_groups = data %>%
          filter(!is.na(cai_value)) %>%
          mutate(cai_group = case_when(
            cai_value < 0.1 ~ "漸趨靜止",
            cai_value < 0.9 ~ "穩定消費",
            TRUE ~ "漸趨活躍"
          )) %>%
          group_by(cai_group) %>%
          summarise(count = n())
      )
      
      # 計算喚醒率（此處為示例，實際需要時間序列數據）
      metrics$reactivation_rate <- NA  # 需要歷史數據計算
      
      return(metrics)
    })
    
    # KPI 顯示
    output$avg_cai <- renderText({
      metrics <- engagement_metrics()
      if (is.na(metrics$avg_cai)) {
        "N/A"
      } else {
        paste0(round(metrics$avg_cai * 100, 1), "%")
      }
    })
    
    output$conversion_rate <- renderText({
      metrics <- engagement_metrics()
      paste0(round(metrics$conversion_rate, 1), "%")
    })
    
    output$reactivation_rate <- renderText({
      metrics <- engagement_metrics()
      if (is.na(metrics$reactivation_rate)) {
        "待評估"
      } else {
        paste0(round(metrics$reactivation_rate, 1), "%")
      }
    })
    
    output$avg_frequency <- renderText({
      metrics <- engagement_metrics()
      round(metrics$avg_frequency, 1)
    })
    
    output$avg_ipt <- renderText({
      metrics <- engagement_metrics()
      if (is.na(metrics$avg_ipt)) {
        "N/A"
      } else {
        round(metrics$avg_ipt, 0)
      }
    })
    
    # 客戶活躍度分布圖
    output$cai_distribution <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 活躍度分布
      cai_data <- data %>%
        filter(!is.na(cai_value)) %>%
        mutate(cai_percentage = cai_value * 100)
      
      if (nrow(cai_data) == 0) {
        plot_ly() %>%
          add_annotations(
            text = "活躍度數據不足\n需要更多交易記錄",
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(size = 16, color = "#7f8c8d")
          ) %>%
          layout(
            xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
            yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
          )
      } else {
        plot_ly(cai_data,
                x = ~cai_percentage,
                type = "histogram",
                nbinsx = 20,
                marker = list(color = "#e74c3c"),
                hovertemplate = "活躍度: %{x:.1f}%<br>客戶數: %{y}<extra></extra>") %>%
          layout(
            title = list(text = "客戶活躍度指數分布", font = list(size = 16)),
            xaxis = list(title = "活躍度 (%)", range = c(0, 100)),
            yaxis = list(title = "客戶數"),
            showlegend = FALSE
          )
      }
    })
    
    # 轉化率分析
    output$conversion_analysis <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 計算各階段轉化
      conversion_data <- data.frame(
        Stage = c("所有客戶", "購買≥2次", "購買≥5次", "主力客戶(E0)"),
        Count = c(
          nrow(data),
          sum(data$times >= 2, na.rm = TRUE),
          sum(data$times >= 5, na.rm = TRUE),
          sum(data$nes_status == "E0", na.rm = TRUE)
        )
      )
      
      conversion_data$Rate <- round(conversion_data$Count / conversion_data$Count[1] * 100, 1)
      
      plot_ly(conversion_data,
              x = ~Stage,
              y = ~Rate,
              type = 'scatter',
              mode = 'lines+markers',
              line = list(color = '#2ecc71', width = 3),
              marker = list(size = 12, color = '#27ae60'),
              text = ~paste0(Rate, "%"),
              textposition = "top center",
              hovertemplate = "%{x}<br>轉化率: %{y}%<br>客戶數: %{customdata}<extra></extra>",
              customdata = ~Count) %>%
        layout(
          title = list(text = "客戶轉化漏斗", font = list(size = 16)),
          xaxis = list(title = "客戶階段"),
          yaxis = list(title = "轉化率 (%)", range = c(0, 110)),
          showlegend = FALSE
        )
    })
    
    # 購買頻率與週期分析
    output$frequency_cycle_analysis <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備散點圖數據
      scatter_data <- data %>%
        filter(!is.na(f_value) & !is.na(ipt_mean) & f_value > 0 & ipt_mean > 0) %>%
        mutate(
          customer_group = case_when(
            nes_status == "N" ~ "新客戶",
            nes_status == "E0" ~ "主力客戶",
            nes_status %in% c("S1", "S2") ~ "需喚醒客戶",
            nes_status == "S3" ~ "沉睡客戶",
            TRUE ~ "其他"
          )
        )
      
      plot_ly(scatter_data,
              x = ~f_value,
              y = ~ipt_mean,
              color = ~customer_group,
              colors = c("新客戶" = "#3498db", 
                        "主力客戶" = "#2ecc71", 
                        "需喚醒客戶" = "#f39c12",
                        "沉睡客戶" = "#e74c3c",
                        "其他" = "#95a5a6"),
              type = 'scatter',
              mode = 'markers',
              marker = list(size = 8, opacity = 0.6),
              hovertemplate = "%{color}<br>購買頻率: %{x}<br>平均購買週期: %{y:.0f}天<extra></extra>") %>%
        layout(
          title = list(text = "購買頻率 vs 購買週期", font = list(size = 16)),
          xaxis = list(title = "購買頻率 (次)", type = "log"),
          yaxis = list(title = "平均購買週期 (天)", type = "log"),
          legend = list(x = 0.7, y = 0.9)
        )
    })
    
    # 喚醒機會分析
    output$reactivation_opportunities <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 識別需要喚醒的客戶群
      reactivation_data <- data %>%
        filter(nes_status %in% c("S1", "S2")) %>%
        mutate(
          days_inactive = round(r_value, 0),
          urgency = case_when(
            days_inactive > 180 ~ "緊急",
            days_inactive > 90 ~ "重要",
            TRUE ~ "一般"
          )
        ) %>%
        group_by(urgency) %>%
        summarise(
          count = n(),
          avg_clv = mean(clv, na.rm = TRUE),
          total_potential = sum(clv, na.rm = TRUE)
        ) %>%
        mutate(urgency = factor(urgency, levels = c("緊急", "重要", "一般")))
      
      if (nrow(reactivation_data) == 0) {
        plot_ly() %>%
          add_annotations(
            text = "暫無需要喚醒的客戶",
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(size = 16, color = "#2ecc71")
          ) %>%
          layout(
            xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
            yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
          )
      } else {
        plot_ly(reactivation_data,
                x = ~urgency,
                y = ~count,
                type = 'bar',
                name = '客戶數',
                marker = list(color = c("#e74c3c", "#f39c12", "#3498db")),
                text = ~count,
                textposition = "outside",
                hovertemplate = "%{x}<br>客戶數: %{y}<br>潛在價值: $%{customdata:,.0f}<extra></extra>",
                customdata = ~total_potential) %>%
          layout(
            title = list(text = "客戶喚醒優先級", font = list(size = 16)),
            xaxis = list(title = "緊急程度"),
            yaxis = list(title = "客戶數"),
            showlegend = FALSE
          )
      }
    })
    
    # 忠誠度階梯
    output$loyalty_ladder <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 創建忠誠度階梯數據
      loyalty_data <- data %>%
        mutate(
          loyalty_level = case_when(
            times == 1 ~ "1. 初次購買",
            times >= 2 & times <= 3 ~ "2. 偶爾購買",
            times >= 4 & times <= 6 ~ "3. 常客",
            times >= 7 & times <= 10 ~ "4. 忠誠客戶",
            times > 10 ~ "5. 品牌大使",
            TRUE ~ "0. 潛在客戶"
          )
        ) %>%
        group_by(loyalty_level) %>%
        summarise(
          count = n(),
          avg_value = mean(total_spent, na.rm = TRUE)
        ) %>%
        arrange(loyalty_level)
      
      plot_ly(loyalty_data,
              y = ~loyalty_level,
              x = ~count,
              type = 'bar',
              orientation = 'h',
              marker = list(
                color = ~avg_value,
                colorscale = 'Blues',
                showscale = TRUE,
                colorbar = list(title = "平均消費")
              ),
              text = ~paste0(count, " 人"),
              textposition = "outside",
              hovertemplate = "%{y}<br>客戶數: %{x}<br>平均消費: $%{marker.color:,.0f}<extra></extra>") %>%
        layout(
          title = list(text = "客戶忠誠度階梯", font = list(size = 16)),
          xaxis = list(title = "客戶數"),
          yaxis = list(title = "忠誠度等級", categoryorder = "trace"),
          showlegend = FALSE
        )
    })
    
    # 詳細數據表
    output$engagement_details <- renderDT({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備顯示數據
      display_data <- data %>%
        select(customer_id, cai_value, f_value, ipt_mean, nes_status, times, total_spent) %>%
        mutate(
          activity_score = round(cai_value * 100, 1),
          avg_cycle_days = round(ipt_mean, 0),
          engagement_level = case_when(
            cai_value >= 0.9 ~ "高度活躍",
            cai_value >= 0.1 ~ "穩定活躍",
            is.na(cai_value) ~ "待評估",
            TRUE ~ "低活躍度"
          ),
          needs_reactivation = ifelse(nes_status %in% c("S1", "S2"), "是", "否")
        ) %>%
        select(
          customer_id,
          engagement_level,
          activity_score,
          f_value,
          avg_cycle_days,
          times,
          total_spent,
          needs_reactivation
        ) %>%
        rename(
          "客戶ID" = customer_id,
          "活躍程度" = engagement_level,
          "活躍度分數(%)" = activity_score,
          "購買頻率" = f_value,
          "平均週期(天)" = avg_cycle_days,
          "總購買次數" = times,
          "總消費金額" = total_spent,
          "需要喚醒" = needs_reactivation
        )
      
      datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(2, 'desc')),  # 按活躍度分數降序
          columnDefs = list(
            list(className = 'dt-right', targets = c(2, 3, 4, 5, 6))
          )
        ),
        rownames = FALSE
      ) %>%
        formatCurrency("總消費金額", "$") %>%
        formatStyle(
          "需要喚醒",
          backgroundColor = styleEqual(
            c("是", "否"),
            c("#fee5d9", "#d4edda")
          )
        )
    })
    
    # CSV 下載功能
    output$download_reactivation_csv <- downloadHandler(
      filename = function() {
        paste("reactivation_customers_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(dna_results())
        data <- dna_results()$data_by_customer
        
        # 識別需要喚醒的客戶
        reactivation_customers <- data %>%
          filter(nes_status %in% c("S1", "S2")) %>%
          mutate(
            days_inactive = round(r_value, 0),
            urgency = case_when(
              days_inactive > 180 ~ "緊急",
              days_inactive > 90 ~ "重要",
              TRUE ~ "一般"
            )
          ) %>%
          select(
            customer_id, 
            nes_status, 
            days_inactive, 
            urgency,
            times,
            total_spent,
            clv,
            f_value,
            ipt_mean
          ) %>%
          rename(
            "客戶ID" = customer_id,
            "狀態" = nes_status,
            "沉睡天數" = days_inactive,
            "緊急程度" = urgency,
            "購買次數" = times,
            "總消費金額" = total_spent,
            "客戶終身價值" = clv,
            "購買頻率" = f_value,
            "平均再購間隔" = ipt_mean
          )
        
        write.csv(reactivation_customers, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    output$download_loyalty_csv <- downloadHandler(
      filename = function() {
        paste("loyalty_ladder_analysis_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(dna_results())
        data <- dna_results()$data_by_customer
        
        # 忠誠度階梯數據
        loyalty_data <- data %>%
          mutate(
            loyalty_level = case_when(
              times == 1 ~ "1. 初次購買",
              times >= 2 & times <= 3 ~ "2. 偶爾購買",
              times >= 4 & times <= 6 ~ "3. 常客",
              times >= 7 & times <= 10 ~ "4. 忠誠客戶",
              times > 10 ~ "5. 品牌大使",
              TRUE ~ "0. 潛在客戶"
            )
          ) %>%
          select(
            customer_id,
            loyalty_level,
            times,
            total_spent,
            clv,
            nes_status,
            cai_value,
            f_value
          ) %>%
          rename(
            "客戶ID" = customer_id,
            "忠誠度等級" = loyalty_level,
            "購買次數" = times,
            "總消費金額" = total_spent,
            "客戶終身價值" = clv,
            "客戶狀態" = nes_status,
            "活躍度" = cai_value,
            "購買頻率" = f_value
          )
        
        write.csv(loyalty_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # AI 分析功能
    observeEvent(input$analyze_frequency, {
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備購買頻率數據
      frequency_data <- list(
        avg_frequency = round(mean(data$f_value, na.rm = TRUE), 2),
        frequency_distribution = paste(summary(data$f_value), collapse = ", "),
        high_frequency_ratio = round(sum(data$f_value >= 5, na.rm = TRUE) / nrow(data) * 100, 1),
        one_time_ratio = round(sum(data$times == 1, na.rm = TRUE) / nrow(data) * 100, 1)
      )
      
      # 獲取 prompt 並替換變數
      prompts_df <- load_prompts()
      prompt_text <- prompts_df[prompts_df$var_id == "activity_purchase_frequency_analysis", "prompt"]
      
      # 替換變數
      prompt_filled <- glue::glue(prompt_text, 
        avg_frequency = frequency_data$avg_frequency,
        frequency_distribution = frequency_data$frequency_distribution,
        high_frequency_ratio = frequency_data$high_frequency_ratio,
        one_time_ratio = frequency_data$one_time_ratio
      )
      
      # 調用 OpenAI API
      result <- tryCatch({
        call_openai_api(prompt_filled)
      }, error = function(e) {
        paste("分析過程中發生錯誤:", e$message)
      })
      
      # 渲染為 HTML
      output$frequency_analysis_output <- renderUI({
        HTML(markdown::markdownToHTML(text = result, fragment.only = TRUE))
      })
    })
    
    observeEvent(input$analyze_reactivation, {
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備喚醒數據
      reactivation_data <- data %>%
        filter(nes_status %in% c("S1", "S2")) %>%
        mutate(
          days_inactive = round(r_value, 0),
          urgency = case_when(
            days_inactive > 180 ~ "緊急",
            days_inactive > 90 ~ "重要",
            TRUE ~ "一般"
          )
        ) %>%
        group_by(urgency) %>%
        summarise(
          count = n(),
          total_value = sum(clv, na.rm = TRUE)
        )
      
      reactivation_analysis <- list(
        total_reactivation_targets = sum(reactivation_data$count),
        urgent_count = reactivation_data$count[reactivation_data$urgency == "緊急"],
        urgent_value = reactivation_data$total_value[reactivation_data$urgency == "緊急"],
        important_count = reactivation_data$count[reactivation_data$urgency == "重要"],
        important_value = reactivation_data$total_value[reactivation_data$urgency == "重要"],
        normal_count = reactivation_data$count[reactivation_data$urgency == "一般"],
        normal_value = reactivation_data$total_value[reactivation_data$urgency == "一般"]
      )
      
      # 替換 NA 值
      reactivation_analysis <- lapply(reactivation_analysis, function(x) ifelse(is.na(x) | length(x) == 0, 0, x))
      
      prompts_df <- load_prompts()
      prompt_text <- prompts_df[prompts_df$var_id == "activity_reactivation_opportunity", "prompt"]
      
      prompt_filled <- glue::glue(prompt_text, 
        total_reactivation_targets = reactivation_analysis$total_reactivation_targets,
        urgent_count = reactivation_analysis$urgent_count,
        urgent_value = reactivation_analysis$urgent_value,
        important_count = reactivation_analysis$important_count,
        important_value = reactivation_analysis$important_value,
        normal_count = reactivation_analysis$normal_count,
        normal_value = reactivation_analysis$normal_value
      )
      
      result <- tryCatch({
        call_openai_api(prompt_filled)
      }, error = function(e) {
        paste("分析過程中發生錯誤:", e$message)
      })
      
      output$reactivation_analysis_output <- renderUI({
        HTML(markdown::markdownToHTML(text = result, fragment.only = TRUE))
      })
    })
    
    observeEvent(input$analyze_loyalty, {
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 忠誠度階梯數據
      loyalty_levels <- data %>%
        mutate(
          loyalty_level = case_when(
            times == 1 ~ "初次購買",
            times >= 2 & times <= 3 ~ "偶爾購買",
            times >= 4 & times <= 6 ~ "常客",
            times >= 7 & times <= 10 ~ "忠誠客戶",
            times > 10 ~ "品牌大使",
            TRUE ~ "潛在客戶"
          )
        ) %>%
        group_by(loyalty_level) %>%
        summarise(
          count = n(),
          avg_value = mean(total_spent, na.rm = TRUE)
        )
      
      loyalty_analysis <- list(
        loyalty_levels = paste(loyalty_levels$loyalty_level, collapse = ", "),
        level_distribution = paste(paste(loyalty_levels$loyalty_level, loyalty_levels$count, sep = ": "), collapse = "; "),
        promotion_rates = "待計算", # 需要歷史數據
        avg_value_diff = paste(round(loyalty_levels$avg_value, 0), collapse = ", ")
      )
      
      prompts_df <- load_prompts()
      prompt_text <- prompts_df[prompts_df$var_id == "activity_loyalty_ladder_analysis", "prompt"]
      
      prompt_filled <- glue::glue(prompt_text,
        loyalty_levels = loyalty_analysis$loyalty_levels,
        level_distribution = loyalty_analysis$level_distribution,
        promotion_rates = loyalty_analysis$promotion_rates,
        avg_value_diff = loyalty_analysis$avg_value_diff
      )
      
      result <- tryCatch({
        call_openai_api(prompt_filled)
      }, error = function(e) {
        paste("分析過程中發生錯誤:", e$message)
      })
      
      output$loyalty_analysis_output <- renderUI({
        HTML(markdown::markdownToHTML(text = result, fragment.only = TRUE))
      })
    })
    
    observeEvent(input$analyze_reactivation_list, {
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 需喚醒客戶清單數據
      reactivation_customers <- data %>%
        filter(nes_status %in% c("S1", "S2"))
      
      if(nrow(reactivation_customers) > 0) {
        list_analysis <- list(
          customer_count = nrow(reactivation_customers),
          avg_dormant_days = round(mean(reactivation_customers$r_value, na.rm = TRUE), 0),
          total_historical_value = sum(reactivation_customers$total_spent, na.rm = TRUE),
          avg_order_value = round(mean(reactivation_customers$total_spent / reactivation_customers$times, na.rm = TRUE), 0),
          last_purchase_distribution = paste(summary(reactivation_customers$r_value), collapse = ", ")
        )
      } else {
        list_analysis <- list(
          customer_count = 0,
          avg_dormant_days = 0,
          total_historical_value = 0,
          avg_order_value = 0,
          last_purchase_distribution = "無數據"
        )
      }
      
      prompts_df <- load_prompts()
      prompt_text <- prompts_df[prompts_df$var_id == "activity_reactivation_list_analysis", "prompt"]
      
      prompt_filled <- glue::glue(prompt_text,
        customer_count = list_analysis$customer_count,
        avg_dormant_days = list_analysis$avg_dormant_days,
        total_historical_value = list_analysis$total_historical_value,
        avg_order_value = list_analysis$avg_order_value,
        last_purchase_distribution = list_analysis$last_purchase_distribution
      )
      
      result <- tryCatch({
        call_openai_api(prompt_filled)
      }, error = function(e) {
        paste("分析過程中發生錯誤:", e$message)
      })
      
      output$reactivation_list_output <- renderUI({
        HTML(markdown::markdownToHTML(text = result, fragment.only = TRUE))
      })
    })
    
  })
}