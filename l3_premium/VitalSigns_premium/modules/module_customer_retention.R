# 客戶留存模組 (Customer Retention Module)
# 衡量基盤穩定度與流失風險

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)

# 載入提示和prompt系統
source("utils/hint_system.R")
source("utils/prompt_manager.R")
source("utils/gpt_utils.R")

# UI Function
customerRetentionModuleUI <- function(id, enable_hints = TRUE) {
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
          value = textOutput(ns("retention_rate")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客留存率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_retention_tab", "description"][1],
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
                title = hints_df[hints_df$var_id == "customer_retention_tab", "description"][1],
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
                title = hints_df[hints_df$var_id == "customer_retention_tab", "description"][1],
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
          value = textOutput(ns("core_customer_ratio")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "主力客比率 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 12px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "customer_retention_tab", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "主力客比率"
          },
          icon = icon("star"),
          color = "info",
          width = 12
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 客戶狀態結構分析
      column(6,
        bs4Card(
          title = "客戶狀態結構 (N/E0/S1-S3)",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("customer_state_structure"))
        )
      ),
      
      # 流失風險分析
      column(6,
        bs4Card(
          title = "流失風險分析",
          status = "danger",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("churn_risk_analysis"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # AI 智能分析與建議
      column(12,
        bs4Card(
          title = "🤖 AI 客戶狀態智能分析與行銷建議",
          status = "success",
          solidHeader = TRUE,
          collapsible = TRUE,
          width = 12,
          actionButton(ns("run_ai_retention_analysis"), "🎯 執行 AI 分析", 
                      class = "btn-primary", style = "margin-bottom: 15px;"),
          uiOutput(ns("ai_analysis_recommendations"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # RFM 分析熱力圖
      column(12,
        bs4Card(
          title = "RFM 客戶分群熱力圖",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("rfm_heatmap"))
        )
      )
    ),
    
    br(),
    
    fluidRow(
      # 詳細數據表
      column(12,
        bs4Card(
          title = "客戶留存指標明細",
          status = "secondary",
          solidHeader = TRUE,
          collapsible = TRUE,
          width = 12,
          div(
            style = "margin-bottom: 10px;",
            downloadButton(ns("download_retention_details"), "📥 下載完整客戶名單", 
                          class = "btn-success btn-sm")
          ),
          DTOutput(ns("retention_details"))
        )
      )
    )
  )
}

# Server Function
customerRetentionModuleServer <- function(id, con, user_info, dna_module_result, enable_hints = TRUE) {
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
    
    # 計算留存指標
    retention_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      nrec_data <- dna_results()$nrec_accu
      
      # 基本統計
      total_customers <- nrow(data)
      
      # 客戶狀態統計
      status_counts <- data %>%
        group_by(nes_status) %>%
        summarise(count = n()) %>%
        mutate(ratio = count / total_customers * 100)
      
      # 提取各狀態比率
      get_ratio <- function(status) {
        status_counts %>%
          filter(nes_status == status) %>%
          pull(ratio) %>%
          {if(length(.) == 0) 0 else .}
      }
      
      # 留存相關指標
      metrics <- list(
        # 留存率（非沉睡客戶比例）
        retention_rate = 100 - get_ratio("S3"),
        
        # 流失率（沉睡客戶比例）
        churn_rate = get_ratio("S3"),
        
        # 風險客戶（S1 + S2）
        at_risk_customers = sum(data$nes_status %in% c("S1", "S2"), na.rm = TRUE),
        at_risk_ratio = get_ratio("S1") + get_ratio("S2"),
        
        # 各狀態比率
        first_time_ratio = get_ratio("N"),
        core_ratio = get_ratio("E0"),
        sleepy_ratio = get_ratio("S1"),
        half_idle_ratio = get_ratio("S2"),
        dormant_ratio = get_ratio("S3"),
        
        # 靜止戶預測準確度
        prediction_accuracy = nrec_data$nrec_accu,
        
        # 狀態統計表
        status_summary = status_counts
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
      paste0(format(metrics$at_risk_customers, big.mark = ","), 
             " (", round(metrics$at_risk_ratio, 1), "%)")
    })
    
    output$core_customer_ratio <- renderText({
      metrics <- retention_metrics()
      paste0(round(metrics$core_ratio, 1), "%")
    })
    
    # 客戶狀態結構圖
    output$customer_state_structure <- renderPlotly({
      req(retention_metrics())
      
      status_data <- data.frame(
        Status = c("首購客(N)", "主力客(E0)", "瞌睡客(S1)", "半睡客(S2)", "沉睡客(S3)"),
        Ratio = c(
          retention_metrics()$first_time_ratio,
          retention_metrics()$core_ratio,
          retention_metrics()$sleepy_ratio,
          retention_metrics()$half_idle_ratio,
          retention_metrics()$dormant_ratio
        ),
        Color = c("#3498db", "#2ecc71", "#f39c12", "#e67e22", "#e74c3c")
      )
      
      # 按比率排序
      status_data <- status_data %>%
        arrange(desc(Ratio))
      
      plot_ly(status_data,
              x = ~reorder(Status, Ratio),
              y = ~Ratio,
              type = 'bar',
              marker = list(color = ~Color),
              text = ~paste0(round(Ratio, 1), "%"),
              textposition = "outside",
              hovertemplate = "%{x}<br>比率: %{y:.1f}%<extra></extra>") %>%
        layout(
          title = list(text = "客戶狀態分布", font = list(size = 16)),
          xaxis = list(title = "客戶狀態"),
          yaxis = list(title = "比率 (%)", range = c(0, max(status_data$Ratio) * 1.2)),
          showlegend = FALSE
        )
    })
    
    # 流失風險分析
    output$churn_risk_analysis <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 根據 nrec (churn prediction) 分析風險
      risk_data <- data %>%
        filter(!is.na(nrec)) %>%
        group_by(nrec, nes_status) %>%
        summarise(count = n(), .groups = "drop") %>%
        mutate(
          risk_label = ifelse(nrec == "rec", "預測留存", "預測流失"),
          status_label = case_when(
            nes_status == "N" ~ "新客戶",
            nes_status == "E0" ~ "主力客戶",
            nes_status == "S1" ~ "瞌睡客戶",
            nes_status == "S2" ~ "半睡客戶",
            nes_status == "S3" ~ "沉睡客戶",
            TRUE ~ "其他"
          )
        )
      
      # 如果沒有預測數據，顯示基於狀態的風險分析
      if (nrow(risk_data) == 0) {
        risk_summary <- data %>%
          mutate(
            risk_level = case_when(
              nes_status == "S3" ~ "高風險",
              nes_status %in% c("S1", "S2") ~ "中風險",
              nes_status == "E0" ~ "低風險",
              nes_status == "N" ~ "新客戶",
              TRUE ~ "未知"
            )
          ) %>%
          group_by(risk_level) %>%
          summarise(count = n()) %>%
          mutate(
            risk_level = factor(risk_level, 
                              levels = c("高風險", "中風險", "低風險", "新客戶", "未知"))
          )
        
        plot_ly(risk_summary,
                labels = ~risk_level,
                values = ~count,
                type = 'pie',
                marker = list(colors = c("#e74c3c", "#f39c12", "#2ecc71", "#3498db", "#95a5a6")),
                textposition = 'inside',
                textinfo = 'label+percent',
                hovertemplate = "%{label}<br>客戶數: %{value}<br>占比: %{percent}<extra></extra>") %>%
          layout(
            title = list(text = "客戶流失風險分布", font = list(size = 16))
          )
      } else {
        # 有預測數據時的圖表
        plot_ly(risk_data,
                x = ~status_label,
                y = ~count,
                color = ~risk_label,
                type = 'bar',
                colors = c("預測留存" = "#2ecc71", "預測流失" = "#e74c3c"),
                hovertemplate = "%{x}<br>%{color}<br>客戶數: %{y}<extra></extra>") %>%
          layout(
            title = list(text = "流失預測分析", font = list(size = 16)),
            xaxis = list(title = "客戶狀態"),
            yaxis = list(title = "客戶數"),
            barmode = 'stack'
          )
      }
    })
    
    # RFM 熱力圖
    output$rfm_heatmap <- renderPlotly({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 將 ordered factor 轉換為普通字符串，避免類型衝突
      data <- data %>%
        mutate(
          r_label = as.character(r_label),
          f_label = as.character(f_label)
        )
      
      # 創建 RFM 分組矩陣
      rfm_matrix <- data %>%
        filter(!is.na(r_label) & !is.na(f_label)) %>%
        group_by(r_label, f_label) %>%
        summarise(
          count = n(),
          avg_m = mean(m_value, na.rm = TRUE),
          .groups = "drop"
        )
      
      # 獲取唯一的標籤值
      r_levels <- sort(unique(data$r_label[!is.na(data$r_label)]))
      f_levels <- sort(unique(data$f_label[!is.na(data$f_label)]))
      
      # 創建完整的矩陣（包括空值）
      complete_matrix <- expand.grid(
        r_label = r_levels,
        f_label = f_levels,
        stringsAsFactors = FALSE
      ) %>%
        left_join(rfm_matrix, by = c("r_label", "f_label")) %>%
        replace_na(list(count = 0, avg_m = 0))
      
      # 轉換為矩陣格式
      z_matrix <- complete_matrix %>%
        select(r_label, f_label, count) %>%
        pivot_wider(names_from = f_label, values_from = count) %>%
        select(-r_label) %>%
        as.matrix()
      
      plot_ly(
        z = z_matrix,
        x = f_levels,
        y = r_levels,
        type = "heatmap",
        colorscale = "Blues",
        hovertemplate = "最近購買: %{y}<br>購買頻率: %{x}<br>客戶數: %{z}<extra></extra>"
      ) %>%
        layout(
          title = list(text = "RFM 客戶分群分布", font = list(size = 16)),
          xaxis = list(title = "購買頻率 (F)"),
          yaxis = list(title = "最近購買時間 (R)")
        )
    })
    
    # 詳細數據表
    output$retention_details <- renderDT({
      req(dna_results())
      data <- dna_results()$data_by_customer
      
      # 準備顯示數據
      display_data <- data %>%
        select(customer_id, nes_status, r_value, f_value, m_value, cai_value, nrec, nrec_prob) %>%
        mutate(
          status_label = case_when(
            nes_status == "N" ~ "首購客",
            nes_status == "E0" ~ "主力客",
            nes_status == "S1" ~ "瞌睡客",
            nes_status == "S2" ~ "半睡客",
            nes_status == "S3" ~ "沉睡客",
            TRUE ~ "其他"
          ),
          churn_risk = case_when(
            is.na(nrec_prob) ~ "未預測",
            nrec_prob > 0.7 ~ "高風險",
            nrec_prob > 0.3 ~ "中風險",
            TRUE ~ "低風險"
          ),
          activity_index = round(cai_value * 100, 1)
        ) %>%
        select(
          customer_id,
          status_label,
          r_value,
          f_value,
          m_value,
          activity_index,
          churn_risk
        ) %>%
        rename(
          "客戶ID" = customer_id,
          "客戶狀態" = status_label,
          "最近購買(天)" = r_value,
          "購買頻率" = f_value,
          "平均金額" = m_value,
          "活躍度(%)" = activity_index,
          "流失風險" = churn_risk
        )
      
      dt <- datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(2, 'asc')),  # 按最近購買天數升序
          dom = 'frtip',  # 移除 B (buttons)
          columnDefs = list(
            list(className = 'dt-right', targets = c(2, 3, 4, 5))
          )
        ),
        rownames = FALSE
      )
      
      # 檢查欄位存在後再格式化
      if("最近購買(天)" %in% names(display_data)) {
        dt <- dt %>% formatRound("最近購買(天)", 0)
      }
      if("購買頻率" %in% names(display_data)) {
        dt <- dt %>% formatRound("購買頻率", 0)
      }
      if("平均金額" %in% names(display_data)) {
        dt <- dt %>% formatCurrency("平均金額", "$")
      }
      if("流失風險" %in% names(display_data)) {
        dt <- dt %>% formatStyle(
          "流失風險",
          backgroundColor = styleEqual(
            c("高風險", "中風險", "低風險"),
            c("#fee5d9", "#fcbba1", "#a1d99b")
          )
        )
      }
      
      dt
    })
    
    # 讀選器：AI 分析結果
    ai_results <- reactiveValues(
      analysis = NULL,
      loading = FALSE
    )
    
    # 處理 AI 分析按鈕
    observeEvent(input$run_ai_retention_analysis, {
      req(retention_metrics())
      
      # 設定載入狀態
      ai_results$loading <- TRUE
      ai_results$analysis <- NULL
      
      # 載入 prompt
      prompts_df <- load_prompts()
      
      # 檢查 GPT API 設定
      if(is.null(prompts_df) || Sys.getenv("OPENAI_API_KEY") == "") {
        showNotification("請先設定 OpenAI API Key", type = "error")
        ai_results$loading <- FALSE
        return()
      }
      
      # 準備分析數據
      metrics <- retention_metrics()
      data <- dna_results()$data_by_customer
      
      # 初始化結果儲存
      all_recommendations <- list()
      
      # 分析五種客戶狀態與對應的 prompt ID
      customer_segments <- list(
        list(
          name = "首購客戶 (N)",
          status = "N",
          ratio = metrics$first_time_ratio,
          prompt_id = "new_customer_analysis"
        ),
        list(
          name = "主力客戶 (E0)", 
          status = "E0",
          ratio = metrics$core_ratio,
          prompt_id = "core_customer_strategy"
        ),
        list(
          name = "瞌睡客戶 (S1)",
          status = "S1",
          ratio = metrics$sleepy_ratio,
          prompt_id = "drowsy_customer_strategy"
        ),
        list(
          name = "半睡客戶 (S2)",
          status = "S2",
          ratio = metrics$half_idle_ratio,
          prompt_id = "semi_dormant_customer_strategy"
        ),
        list(
          name = "沉睡客戶 (S3)",
          status = "S3",
          ratio = metrics$dormant_ratio,
          prompt_id = "sleeping_customer_strategy"
        )
      )
      
      # 逐一分析每個客群
      for(segment in customer_segments) {
        # 檢查比率是否存在且大於0
        ratio_value <- if(is.null(segment$ratio) || is.na(segment$ratio)) 0 else segment$ratio
        
        # 記錄所有客群，包括沒有客戶的
        if(ratio_value <= 0) {
          # 當沒有客戶時，也要記錄
          all_recommendations[[segment$name]] <- list(
            name = segment$name,
            ratio = 0,
            count = 0,
            recommendations = paste0(
              "## 客群狀態\n",
              "目前沒有", segment$name, "。\n\n",
              "## 策略建議\n",
              if(segment$status == "E0") {
                "### 建立主力客戶基礎\n",
                "1. 加強現有客戶的維護和升級計劃\n",
                "2. 推出VIP會員制度吸引高價值客戶\n",
                "3. 建立客戶忠誠度獎勵機制\n",
                "4. 提供專屬服務提升客戶黏著度"
              } else if(segment$status == "S2") {
                "### 預防半睡客戶產生\n",
                "1. 建立客戶風險預警系統\n",
                "2. 加強瞌睡客戶的挽留力度\n",
                "3. 優化客戶觸達頻率和內容\n",
                "4. 定期檢視客戶滿意度"
              } else if(segment$status == "N") {
                "### 拓展新客戶\n",
                "1. 加強新客戶獲取管道\n",
                "2. 優化首購體驗\n",
                "3. 建立新客戶歡迎流程\n",
                "4. 提升品牌知名度"
              } else if(segment$status == "S1") {
                "### 降低瞌睡客戶比例\n",
                "1. 優化客戶互動頻率\n",
                "2. 提升產品吸引力\n",
                "3. 加強客戶關懷措施\n",
                "4. 定期推出促銷活動"
              } else if(segment$status == "S3") {
                "### 減少沉睡客戶\n",
                "1. 分析客戶流失原因\n",
                "2. 優化產品和服務品質\n",
                "3. 建立客戶挽回機制\n",
                "4. 提升整體客戶體驗"
              } else {
                "- 持續監控客戶狀態變化\n",
                "- 優化現有行銷策略\n",
                "- 提升客戶滿意度"
              }
            )
          )
        } else {
          # 篩選該客群數據
          segment_data <- data[data$nes_status == segment$status, ]
          
          if(nrow(segment_data) > 0) {
            # 計算統計指標
            segment_stats <- segment_data %>%
              summarise(
                count = n(),
                avg_r = mean(r_value, na.rm = TRUE),
                avg_f = mean(f_value, na.rm = TRUE),
                avg_m = mean(m_value, na.rm = TRUE),
                total_revenue = sum(m_value * f_value, na.rm = TRUE)
              )
            
            # 使用 GPT 生成建議
            tryCatch({
              # 根據不同客群準備不同的 prompt 變數
              if(segment$status == "N") {
                # 首購客戶
                prompt_vars <- list(
                  new_count = segment_stats$count,
                  new_ratio = round(segment$ratio, 1),
                  new_aov = round(segment_stats$avg_m, 2),
                  days_since = round(segment_stats$avg_r, 0)
                )
              } else if(segment$status == "E0") {
                # 主力客戶
                prompt_vars <- list(
                  core_count = segment_stats$count,
                  core_ratio = round(segment$ratio, 1),
                  avg_frequency = round(segment_stats$avg_f, 1),
                  avg_monetary = round(segment_stats$avg_m, 2),
                  revenue_contribution = round(segment_stats$total_revenue / sum(data$m_value * data$f_value, na.rm = TRUE) * 100, 1)
                )
              } else if(segment$status == "S1") {
                # 瞌睡客戶
                prompt_vars <- list(
                  drowsy_count = segment_stats$count,
                  drowsy_ratio = round(segment$ratio, 1),
                  avg_days = round(segment_stats$avg_r, 0),
                  avg_spend = round(segment_stats$avg_m, 2)
                )
              } else if(segment$status == "S2") {
                # 半睡客戶
                prompt_vars <- list(
                  semi_dormant_count = segment_stats$count,
                  semi_dormant_ratio = round(segment$ratio, 1),
                  avg_sleep_days = round(segment_stats$avg_r, 0),
                  avg_spend = round(segment_stats$avg_m, 2),
                  last_purchase_cycle = round(segment_stats$avg_r / segment_stats$avg_f, 0)
                )
              } else if(segment$status == "S3") {
                # 沉睡客戶
                prompt_vars <- list(
                  sleeping_count = segment_stats$count,
                  sleeping_ratio = round(segment$ratio, 1),
                  avg_sleep_days = round(segment_stats$avg_r, 0),
                  total_value = round(segment_stats$total_revenue, 0)
                )
              } else {
                # 預設變數（通用）
                prompt_vars <- list(
                  segment_name = segment$name,
                  customer_count = segment_stats$count,
                  customer_ratio = paste0(round(segment$ratio, 1), "%"),
                  avg_recency = paste0(round(segment_stats$avg_r, 1), "天"),
                  avg_frequency = paste0(round(segment_stats$avg_f, 1), "次"),
                  avg_monetary = paste0("$", round(segment_stats$avg_m, 2)),
                  total_revenue = paste0("$", format(round(segment_stats$total_revenue, 0), big.mark = ","))
                )
              }
              
              # 執行 GPT 請求 - 使用對應的專用 prompt
              ai_result <- execute_gpt_request(
                var_id = segment$prompt_id,
                variables = prompt_vars,
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              # 如果失敗，使用通用的客戶留存分群 prompt
              if(is.null(ai_result) || nchar(ai_result) == 0) {
                # 使用通用變數
                prompt_vars <- list(
                  segment_name = segment$name,
                  customer_count = segment_stats$count,
                  customer_ratio = paste0(round(segment$ratio, 1), "%"),
                  avg_recency = paste0(round(segment_stats$avg_r, 1), "天"),
                  avg_frequency = paste0(round(segment_stats$avg_f, 1), "次"),
                  avg_monetary = paste0("$", round(segment_stats$avg_m, 2)),
                  total_revenue = paste0("$", format(round(segment_stats$total_revenue, 0), big.mark = ","))
                )
                
                ai_result <- execute_gpt_request(
                  var_id = "customer_retention_segment",
                  variables = prompt_vars,
                  chat_api_function = chat_api,
                  model = "gpt-4o-mini",
                  prompts_df = prompts_df
                )
              }
              
              # 儲存結果
              if(!is.null(ai_result) && nchar(ai_result) > 0) {
                all_recommendations[[segment$name]] <- list(
                  name = segment$name,
                  ratio = segment$ratio,
                  count = segment_stats$count,
                  recommendations = ai_result
                )
              }
              
            }, error = function(e) {
              # 如果 AI 失敗，使用預設建議
              all_recommendations[[segment$name]] <- list(
                name = segment$name,
                ratio = segment$ratio,
                count = segment_stats$count,
                recommendations = paste0(
                  "針對", segment$name, "的行銷建議：\n",
                  "1. 根據客戶特徵制定專屬優惠\n",
                  "2. 建立個人化溝通策略\n",
                  "3. 追蹤行銷效果並持續優化"
                )
              )
            })
          }
        }  # 結束 if(nrow(segment_data) > 0)
      }  # 結束 for 迴圈
      
      # 儲存完整結果
      ai_results$analysis <- all_recommendations
      ai_results$loading <- FALSE
      
      # 顯示分析結果數量
      analysis_count <- length(all_recommendations)
      showNotification(
        paste0("✅ AI 分析完成！共分析 ", analysis_count, " 個客群"), 
        type = "success", 
        duration = 3
      )
    })
    
    # 顯示 AI 分析結果
    output$ai_analysis_recommendations <- renderUI({
      if(ai_results$loading) {
        return(
          div(
            style = "text-align: center; padding: 40px;",
            icon("spinner", class = "fa-spin fa-2x"),
            h4("正在進行 AI 分析...", style = "margin-top: 20px;")
          )
        )
      }
      
      if(is.null(ai_results$analysis)) {
        return(
          div(
            style = "text-align: center; padding: 40px; background: #f8f9fa; border-radius: 8px;",
            icon("robot", style = "font-size: 48px; color: #6c757d;"),
            h4("請點擊「執行 AI 分析」按鈕", style = "margin-top: 20px; color: #6c757d;"),
            p("系統將針對五種客戶狀態提供智能行銷建議", style = "color: #6c757d;")
          )
        )
      }
      
      # 準備有序的客群列表
      segment_order <- c("主力客戶 (E0)", "首購客戶 (N)", 
                        "瞌睡客戶 (S1)", "半睡客戶 (S2)", "沉睡客戶 (S3)")
      chinese_numbers <- c("一", "二", "三", "四", "五")
      
      # 確保所有 5 個客群都顯示（即使沒有數據）
      existing_segments <- names(ai_results$analysis)
      
      # 為缺失的客群加入預設內容
      for(seg in segment_order) {
        if(!(seg %in% existing_segments)) {
          ai_results$analysis[[seg]] <- list(
            name = seg,
            ratio = 0,
            count = 0,
            recommendations = paste0(
              "## 客群狀態\n",
              "目前沒有", seg, "。\n\n",
              "## 策略建議\n",
              "請參考其他客群的行銷策略，並持續監控客戶狀態變化。"
            )
          )
        }
      }
      
      # 排序客群
      sorted_segments <- segment_order  # 直接使用預定義的順序
      
      # 建構 UI
      tagList(
        div(
          style = "padding: 20px; background: #f8f9fa; border-radius: 8px;",
          
          # 整體摘要
          div(
            style = "margin-bottom: 25px;",
            h5("📊 客戶留存智能分析", style = "color: #2c3e50; margin-bottom: 15px;"),
            p(
              style = "color: #555; line-height: 1.8;",
              HTML(paste0(
                "分析時間：", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "<br>",
                "分析客群數：", length(ai_results$analysis), " 個<br>",
                "總客戶數：", format(sum(sapply(ai_results$analysis, function(x) x$count)), big.mark = ","), " 人"
              ))
            )
          ),
          
          # 各客群建議
          div(
            style = "margin-bottom: 20px;",
            h5("🎯 分群行銷策略建議", style = "color: #2c3e50; margin-bottom: 20px;"),
            
            # 為每個客群建立卡片
            tagList(
              lapply(seq_along(sorted_segments), function(i) {
                seg_name <- sorted_segments[i]
                seg_data <- ai_results$analysis[[seg_name]]
                
                # 根據客群類型選擇顏色
                border_color <- switch(
                  gsub(" \\(.*\\)", "", seg_name),
                  "主力客戶" = "#2ecc71",
                  "首購客戶" = "#3498db",
                  "瞌睡客戶" = "#f39c12",
                  "半睡客戶" = "#e67e22",
                  "沉睡客戶" = "#e74c3c",
                  "#95a5a6"
                )
                
                div(
                  style = paste0("margin-bottom: 20px; padding: 15px; background: white; ",
                               "border-radius: 5px; border-left: 4px solid ", border_color, ";"),
                  
                  # 標題
                  h6(
                    paste0(chinese_numbers[i], "、", seg_name),
                    style = paste0("color: ", border_color, "; margin-bottom: 12px; font-weight: bold;")
                  ),
                  
                  # 客群規模
                  p(
                    tags$b("客群規模："),
                    paste0(seg_data$count, " 人（佔 ", round(seg_data$ratio, 1), "%）"),
                    style = "margin-bottom: 10px; color: #555;"
                  ),
                  
                  # AI 建議內容
                  div(
                    style = "padding: 10px; background: #f8f9fa; border-radius: 4px;",
                    HTML(markdown::markdownToHTML(
                      text = seg_data$recommendations,
                      fragment.only = TRUE
                    ))
                  )
                )
              })
            )
          ),
          
          # 執行優先順序
          div(
            style = "margin-top: 25px; padding: 15px; background: #e8f4fd; border-radius: 5px;",
            h6("💡 執行優先順序建議", style = "color: #2c3e50; margin-bottom: 10px;"),
            p(
              style = "color: #555;",
              "根據 AI 分析，建議按以下優先順序執行：",
              br(),
              "1. 優先挽留瞌睡客戶 (S1) - 成功率最高",
              br(),  
              "2. 維護主力客戶 (E0) - 穩定收入基礎",
              br(),
              "3. 激活半睡客戶 (S2) - 需要強化措施",
              br(),
              "4. 培育首購客戶 (N) - 長期價值建設"
            )
          )
        )
      )
    })
    
  })
}