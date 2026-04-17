# 客戶增長模組 (Customer Acquisition & Coverage Module)
# 監測客戶池擴張速度與結構健康

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)
library(lubridate)

# 載入提示和prompt系統
source("utils/hint_system.R")
source("utils/prompt_manager.R")

# UI Function
customerAcquisitionModuleUI <- function(id, enable_hints = TRUE) {
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
          value = textOutput(ns("active_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客總數 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_acquisition_total", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客總數"
          },
          icon = icon("users"),
          color = "primary",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("cumulative_customers")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "累積顧客數 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_acquisition_cumulative", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "累積顧客數"
          },
          icon = icon("user-plus"),
          color = "success",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("acquisition_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客新增率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_acquisition_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客新增率"
          },
          icon = icon("chart-line"),
          color = "info",
          width = 12
        )
      ),
      column(3,
        bs4ValueBox(
          value = textOutput(ns("net_change_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客變動率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_change_rate", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客變動率"
          },
          icon = icon("exchange-alt"),
          color = "warning",
          width = 12
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 客戶池結構分析
      column(6,
        bs4Card(
          title = "客戶池結構分析",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("customer_structure"))
        )
      ),
      
      # 獲客漏斗分析
      column(6,
        bs4Card(
          title = "獲客漏斗分析",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("acquisition_funnel"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 客戶增長趨勢
      column(12,
        bs4Card(
          title = "客戶增長趨勢",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          helpText("注意：趨勢分析需要時間序列數據，目前顯示為靜態分析"),
          plotlyOutput(ns("growth_trend"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # AI 分析建議
      column(12,
        bs4Card(
          title = "🤖 AI 客戶增長分析",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          h5("顧客新增率分析", style = "color: #2c3e50; font-weight: bold;"),
          uiOutput(ns("ai_acquisition_analysis")),
          hr(),
          h5("顧客變動率分析", style = "color: #2c3e50; font-weight: bold;"),
          uiOutput(ns("ai_change_rate_analysis"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 詳細數據表
      column(12,
        bs4Card(
          title = "客戶增長指標明細",
          status = "secondary",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = TRUE,
          width = 12,
          div(
            style = "margin-bottom: 10px;",
            downloadButton(ns("download_acquisition_details"), "📥 下載完整客戶名單", 
                          class = "btn-success btn-sm")
          ),
          DTOutput(ns("acquisition_details"))
        )
      )
    )
  )
}

# Server Function
customerAcquisitionModuleServer <- function(id, con, user_info, dna_module_result, time_series_data = NULL, enable_hints = TRUE, enable_gpt = TRUE, chat_api = NULL) {
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
    
    # 計算客戶增長指標
    acquisition_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      
      # 基本指標
      total_customers <- nrow(data)
      
      # 新客戶數（首購客 N）
      new_customers <- sum(data$nes_status == "N", na.rm = TRUE)
      
      # 活躍客戶數（非沉睡客 S3）
      active_customers <- sum(data$nes_status != "S3", na.rm = TRUE)
      
      # 計算率
      metrics <- list(
        active_customers = active_customers,
        cumulative_customers = total_customers,
        new_customers = new_customers,
        acquisition_rate = (new_customers / total_customers) * 100,
        
        # 淨變動率（活躍客戶比例）
        net_change_rate = (active_customers / total_customers) * 100,
        
        # 客戶結構
        customer_structure = data %>%
          group_by(nes_status) %>%
          summarise(count = n()) %>%
          mutate(percentage = count / sum(count) * 100)
      )
      
      return(metrics)
    })
    
    # KPI 顯示
    output$active_customers <- renderText({
      metrics <- acquisition_metrics()
      format(metrics$active_customers, big.mark = ",")
    })
    
    output$cumulative_customers <- renderText({
      metrics <- acquisition_metrics()
      format(metrics$cumulative_customers, big.mark = ",")
    })
    
    output$acquisition_rate <- renderText({
      metrics <- acquisition_metrics()
      paste0(round(metrics$acquisition_rate, 1), "%")
    })
    
    output$net_change_rate <- renderText({
      metrics <- acquisition_metrics()
      paste0(round(metrics$net_change_rate, 1), "%")
    })
    
    # 客戶池結構圖
    output$customer_structure <- renderPlotly({
      req(acquisition_metrics())
      
      structure <- acquisition_metrics()$customer_structure
      
      # 定義顏色和標籤
      structure <- structure %>%
        mutate(
          label = case_when(
            nes_status == "N" ~ "新客戶",
            nes_status == "E0" ~ "主力客戶",
            nes_status == "S1" ~ "瞌睡客戶",
            nes_status == "S2" ~ "半睡客戶",
            nes_status == "S3" ~ "沉睡客戶",
            TRUE ~ "其他"
          ),
          color = case_when(
            nes_status == "N" ~ "#3498db",
            nes_status == "E0" ~ "#2ecc71",
            nes_status == "S1" ~ "#f39c12",
            nes_status == "S2" ~ "#e67e22",
            nes_status == "S3" ~ "#e74c3c",
            TRUE ~ "#95a5a6"
          )
        )
      
      plot_ly(structure,
              labels = ~label,
              values = ~count,
              type = 'pie',
              marker = list(colors = ~color),
              textposition = 'inside',
              textinfo = 'label+percent',
              hovertemplate = "%{label}<br>客戶數: %{value}<br>占比: %{percent}<extra></extra>") %>%
        layout(
          title = list(text = "客戶狀態分布", font = list(size = 16)),
          showlegend = TRUE,
          legend = list(x = 1, y = 0.5)
        )
    })
    
    # 獲客漏斗分析（移除潛在客戶）
    output$acquisition_funnel <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 創建漏斗數據（不包含潛在客戶）
      funnel_data <- data.frame(
        Stage = c("首次購買", "再次購買", "多次購買", "主力客戶"),
        Count = c(
          sum(data$times >= 1, na.rm = TRUE),  # 至少購買一次
          sum(data$times >= 2, na.rm = TRUE),  # 至少購買兩次
          sum(data$times >= 5, na.rm = TRUE),  # 至少購買五次
          sum(data$nes_status == "E0", na.rm = TRUE)  # 主力客戶
        )
      )
      
      funnel_data$Percentage <- round(funnel_data$Count / funnel_data$Count[1] * 100, 1)
      
      plot_ly(funnel_data,
              type = "funnel",
              y = ~Stage,
              x = ~Count,
              textposition = "inside",
              text = ~paste0(Count, " (", Percentage, "%)"),
              marker = list(color = c("#3498db", "#2ecc71", "#f39c12", "#e74c3c")),
              hovertemplate = "%{y}<br>客戶數: %{x}<br>轉化率: %{text}<extra></extra>") %>%
        layout(
          title = list(text = "客戶轉化漏斗", font = list(size = 16)),
          yaxis = list(categoryorder = "trace")
        )
    })
    
    # 客戶增長趨勢
    output$growth_trend <- renderPlotly({
      # 優先使用時間序列數據
      if (!is.null(time_series_data)) {
        monthly_data <- time_series_data$monthly_data()
        
        if (!is.null(monthly_data) && nrow(monthly_data) > 0) {
          # 顯示客戶數量的時間趨勢
          plot_ly(monthly_data, x = ~period_date) %>%
            add_trace(
              y = ~customers,
              type = 'scatter',
              mode = 'lines+markers',
              name = '月度客戶數',
              line = list(color = '#3498db', width = 3),
              marker = list(size = 8),
              hovertemplate = "%{x|%Y-%m}<br>客戶數: %{y:,.0f}<extra></extra>"
            ) %>%
            add_trace(
              y = ~customer_growth,
              type = 'bar',
              name = '成長率 (%)',
              yaxis = 'y2',
              marker = list(
                color = ~ifelse(customer_growth >= 0, '#2ecc71', '#e74c3c')
              ),
              hovertemplate = "%{x|%Y-%m}<br>成長率: %{y:.1f}%<extra></extra>"
            ) %>%
            layout(
              title = list(text = "月度客戶增長趨勢", font = list(size = 16)),
              xaxis = list(
                title = "月份",
                tickformat = "%Y-%m"
              ),
              yaxis = list(
                title = "客戶數",
                side = 'left'
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
          # 沒有時間序列數據時顯示靜態分析
          display_static_analysis()
        }
      } else {
        # 沒有時間序列模組時顯示靜態分析
        display_static_analysis()
      }
    })
    
    # 輔助函數：顯示靜態分析
    display_static_analysis <- function() {
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 按購買次數分組
      growth_data <- data %>%
        mutate(purchase_group = case_when(
          times == 1 ~ "1次",
          times == 2 ~ "2次",
          times >= 3 & times <= 5 ~ "3-5次",
          times >= 6 & times <= 10 ~ "6-10次",
          times > 10 ~ "10次以上"
        )) %>%
        group_by(purchase_group) %>%
        summarise(count = n()) %>%
        mutate(purchase_group = factor(purchase_group, 
                                     levels = c("1次", "2次", "3-5次", "6-10次", "10次以上")))
      
      plot_ly(growth_data,
              x = ~purchase_group,
              y = ~count,
              type = 'bar',
              marker = list(color = '#3498db'),
              text = ~count,
              textposition = "outside",
              hovertemplate = "%{x}<br>客戶數: %{y}<extra></extra>") %>%
        layout(
          title = list(text = "客戶購買頻次分布", font = list(size = 16)),
          xaxis = list(title = "購買次數"),
          yaxis = list(title = "客戶數"),
          showlegend = FALSE
        )
    }
    
    # 詳細數據表
    output$acquisition_details <- renderDT({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備顯示數據
      display_data <- data %>%
        select(customer_id, nes_status, times, total_spent, r_value) %>%
        mutate(
          customer_type = case_when(
            nes_status == "N" ~ "新客戶",
            nes_status == "E0" ~ "主力客戶",
            nes_status == "S1" ~ "瞌睡客戶",
            nes_status == "S2" ~ "半睡客戶",
            nes_status == "S3" ~ "沉睡客戶",
            TRUE ~ "其他"
          ),
          days_since_last = round(r_value, 0)
        ) %>%
        select(
          customer_id,
          customer_type,
          times,
          total_spent,
          days_since_last
        ) %>%
        rename(
          "客戶ID" = customer_id,
          "客戶類型" = customer_type,
          "購買次數" = times,
          "總消費金額" = total_spent,
          "距上次購買天數" = days_since_last
        )
      
      datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(2, 'desc')),  # 按購買次數降序
          dom = 'frtip',  # 移除 B (buttons)
          columnDefs = list(
            list(className = 'dt-right', targets = c(2, 3, 4))
          )
        ),
        rownames = FALSE
      ) %>%
        formatCurrency("總消費金額", "$") %>%
        formatRound("距上次購買天數", 0)
    })
    
    # 下載客戶詳細資料
    output$download_acquisition_details <- downloadHandler(
      filename = function() {
        paste0("customer_acquisition_details_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(dna_results())
        data <- dna_results()$data_by_customer
        
        # 準備完整資料
        export_data <- data %>%
          select(customer_id, nes_status, times, total_spent, r_value, f_value, m_value) %>%
          mutate(
            customer_type = case_when(
              nes_status == "N" ~ "新客戶",
              nes_status == "E0" ~ "主力客戶",
              nes_status == "S1" ~ "瞌睡客戶",
              nes_status == "S2" ~ "半睡客戶",
              nes_status == "S3" ~ "沉睡客戶",
              TRUE ~ "其他"
            ),
            days_since_last = round(r_value, 0)
          ) %>%
          select(
            customer_id,
            customer_type,
            times,
            total_spent,
            days_since_last,
            f_value,
            m_value
          ) %>%
          rename(
            "客戶ID" = customer_id,
            "客戶類型" = customer_type,
            "購買次數" = times,
            "總消費金額" = total_spent,
            "距上次購買天數" = days_since_last,
            "購買頻率" = f_value,
            "平均單次消費" = m_value
          )
        
        write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # =====================================================================
    # AI 分析功能區塊
    # =====================================================================
    
    # AI 分析：顧客新增率
    ai_acquisition_analysis <- reactive({
      req(acquisition_metrics())
      
      if(enable_gpt && !is.null(chat_api)) {
        metrics <- acquisition_metrics()
        
        # 準備 AI 分析數據
        analysis_data <- sprintf(
          "新客戶數量：%d
總客戶數：%d
顧客新增率：%.1f%%
活躍客戶數：%d",
          metrics$new_customers,
          metrics$cumulative_customers,
          metrics$acquisition_rate,
          metrics$active_customers
        )
        
        # 獲取 prompt
        prompt_template <- prompts_df[prompts_df$var_id == "customer_acquisition_rate_analysis", "prompt"][1]
        
        if(!is.na(prompt_template) && nchar(prompt_template) > 0) {
          # 替換模板變數
          prompt <- gsub("\\{new_customers\\}", as.character(metrics$new_customers), prompt_template)
          prompt <- gsub("\\{total_customers\\}", as.character(metrics$cumulative_customers), prompt)
          prompt <- gsub("\\{acquisition_rate\\}", sprintf("%.1f", metrics$acquisition_rate), prompt)
          prompt <- gsub("\\{active_customers\\}", as.character(metrics$active_customers), prompt)
          
          # 呼叫 AI API
          tryCatch({
            response <- chat_api(prompt)
            return(response)
          }, error = function(e) {
            return(paste("AI 分析發生錯誤:", e$message))
          })
        }
      }
      
      # 預設分析（無 GPT 時）
      metrics <- acquisition_metrics()
      analysis <- sprintf(
        "<div style='padding: 15px; background: #f8f9fa; border-radius: 8px;'>
        <h6 style='color: #2c3e50; margin-bottom: 10px;'>📊 新客獲取效率評估</h6>
        <ul style='margin: 0; padding-left: 20px;'>
          <li>新客戶數量：<strong>%d 位</strong></li>
          <li>顧客新增率：<strong>%.1f%%</strong></li>
          <li>行業基準：一般電商新客率 15-25%%</li>
          <li>評估：%s</li>
        </ul>
        <h6 style='color: #2c3e50; margin-top: 15px; margin-bottom: 10px;'>💡 策略建議</h6>
        <ul style='margin: 0; padding-left: 20px;'>
          <li>%s</li>
          <li>%s</li>
        </ul>
        </div>",
        metrics$new_customers,
        metrics$acquisition_rate,
        ifelse(metrics$acquisition_rate < 15, "低於行業平均，需要加強獲客",
               ifelse(metrics$acquisition_rate > 25, "高於行業平均，表現優異", "符合行業水準")),
        ifelse(metrics$acquisition_rate < 15,
               "建議增加行銷預算，擴大獲客管道",
               "維持現有獲客策略，持續優化"),
        ifelse(metrics$acquisition_rate < 15,
               "考慮推出新客專屬優惠，提升轉化率",
               "聚焦提升客戶終身價值")
      )
      
      return(HTML(analysis))
    })
    
    # AI 分析：顧客變動率
    ai_change_rate_analysis <- reactive({
      req(acquisition_metrics())
      
      if(enable_gpt && !is.null(chat_api)) {
        metrics <- acquisition_metrics()
        
        # 準備客戶結構數據
        structure_text <- paste(
          sapply(1:nrow(metrics$customer_structure), function(i) {
            row <- metrics$customer_structure[i,]
            status_name <- switch(row$nes_status,
                                "N" = "新客戶",
                                "E0" = "主力客戶",
                                "S1" = "瞌睡客戶",
                                "S2" = "半睡客戶",
                                "S3" = "沉睡客戶",
                                "其他")
            sprintf("%s: %d位 (%.1f%%)", status_name, row$count, row$percentage)
          }),
          collapse = ", "
        )
        
        # 準備 AI 分析數據
        analysis_data <- sprintf(
          "活躍客戶數：%d
總客戶數：%d
顧客變動率：%.1f%%
客戶結構：%s",
          metrics$active_customers,
          metrics$cumulative_customers,
          metrics$net_change_rate,
          structure_text
        )
        
        # 獲取 prompt
        prompt_template <- prompts_df[prompts_df$var_id == "customer_change_rate_analysis", "prompt"][1]
        
        if(!is.na(prompt_template) && nchar(prompt_template) > 0) {
          # 替換模板變數
          prompt <- gsub("\\{active_customers\\}", as.character(metrics$active_customers), prompt_template)
          prompt <- gsub("\\{total_customers\\}", as.character(metrics$cumulative_customers), prompt)
          prompt <- gsub("\\{net_change_rate\\}", sprintf("%.1f", metrics$net_change_rate), prompt)
          prompt <- gsub("\\{customer_structure\\}", structure_text, prompt)
          
          # 呼叫 AI API
          tryCatch({
            response <- chat_api(prompt)
            return(response)
          }, error = function(e) {
            return(paste("AI 分析發生錯誤:", e$message))
          })
        }
      }
      
      # 預設分析（無 GPT 時）
      metrics <- acquisition_metrics()
      health_status <- ifelse(metrics$net_change_rate > 70, "健康",
                            ifelse(metrics$net_change_rate > 50, "警示", "危險"))
      
      analysis <- sprintf(
        "<div style='padding: 15px; background: #fff3e0; border-radius: 8px;'>
        <h6 style='color: #e65100; margin-bottom: 10px;'>🔍 客戶池健康度診斷</h6>
        <ul style='margin: 0; padding-left: 20px;'>
          <li>活躍率：<strong>%.1f%%</strong></li>
          <li>健康狀態：<strong>%s</strong></li>
          <li>沉睡客戶占比：<strong>%.1f%%</strong></li>
        </ul>
        <h6 style='color: #e65100; margin-top: 15px; margin-bottom: 10px;'>🛡️ 風險預防措施</h6>
        <ul style='margin: 0; padding-left: 20px;'>
          <li>%s</li>
          <li>%s</li>
          <li>%s</li>
        </ul>
        </div>",
        metrics$net_change_rate,
        health_status,
        100 - metrics$net_change_rate,
        ifelse(metrics$net_change_rate < 50,
               "立即啟動客戶喚醒計劃",
               "定期監控客戶活躍度"),
        ifelse(metrics$net_change_rate < 50,
               "針對沉睡客戶推出專屬優惠",
               "強化客戶互動頻率"),
        "建立客戶流失預警機制"
      )
      
      return(HTML(analysis))
    })
    
    # 輸出 AI 分析結果
    output$ai_acquisition_analysis <- renderUI({
      ai_acquisition_analysis()
    })
    
    output$ai_change_rate_analysis <- renderUI({
      ai_change_rate_analysis()
    })
    
  })
}