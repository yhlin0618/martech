# 活躍轉化模組 (Engagement Flow Module) - 最終修正版
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
    
    # KPI 指標卡片
    fluidRow(
      column(3,
        bs4ValueBox(
          value = textOutput(ns("cai_value")),
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
          icon = icon("chart-line"),
          color = "primary",
          width = 12
        )
      ),
      column(2,
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
          icon = icon("percentage"),
          color = "success",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("purchase_frequency")),
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
            "購買頻率"
          },
          icon = icon("shopping-cart"),
          color = "info",
          width = 12
        )
      ),
      column(2,
        bs4ValueBox(
          value = textOutput(ns("avg_inter_purchase")),
          subtitle = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "平均再購時間 ",
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
          color = "purple",
          width = 12
        )
      )
    ),
    
    br(),
    
    # 圖表區域
    fluidRow(
      # 客戶活躍度分布散佈圖
      column(6,
        bs4Card(
          title = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "客戶活躍度分布 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 14px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "activity_distribution_chart", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "客戶活躍度分布"
          },
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("activity_distribution")),
          br(),
          div(
            style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
            h6("📊 圖表解讀說明", style = "color: #2c3e50; font-weight: bold;"),
            p("此散佈圖展示客戶的活躍度與消費關係：", style = "margin-bottom: 5px;"),
            tags$ul(
              tags$li("橫軸：活躍度指數 (CAI)，正值表示活躍上升，負值表示活躍下降"),
              tags$li("縱軸：總消費金額"),
              tags$li("點的顏色：代表購買次數（綠色=高頻，紅色=低頻）"),
              tags$li("點的大小：也反映消費金額大小")
            ),
            p("理想狀態是多數客戶集中在右上角（高活躍度、高消費）", style = "font-style: italic; color: #666;")
          )
        )
      ),
      
      # 轉化漏斗分析
      column(6,
        bs4Card(
          title = if(enable_hints && !is.null(hints_df)) {
            tags$span(
              "顧客轉化漏斗 ",
              tags$i(
                class = "fas fa-info-circle",
                style = "font-size: 14px; color: #6c757d;",
                title = hints_df[hints_df$var_id == "conversion_funnel_chart", "description"][1],
                `data-toggle` = "tooltip",
                `data-placement` = "top"
              )
            )
          } else {
            "顧客轉化漏斗"
          },
          status = "success",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("conversion_funnel")),
          br(),
          div(
            style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
            h6("📊 圖表解讀說明", style = "color: #2c3e50; font-weight: bold;"),
            p("漏斗圖展示客戶從首購到忠誠的轉化過程：", style = "margin-bottom: 5px;"),
            tags$ul(
              tags$li("1次購買：首購客戶基數 (100%)"),
              tags$li("2次購買：二購轉化率 = 2次購買客戶數 ÷ 總客戶數"),
              tags$li("3-4次：常客轉化率"),
              tags$li("≥5次：忠誠客戶轉化率")
            ),
            p("轉化率越高，表示客戶忠誠度經營越成功", style = "font-style: italic; color: #666;")
          )
        )
      )
    ),
    
    br(),
    
    # 購買頻率與週期分析
    fluidRow(
      column(6,
        bs4Card(
          title = "購買頻率與週期分析",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput(ns("purchase_patterns")),
          br(),
          div(
            style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
            h6("📊 圖表解讀說明", style = "color: #2c3e50; font-weight: bold;"),
            p("此圖分析客戶的購買節奏：", style = "margin-bottom: 5px;"),
            tags$ul(
              tags$li("橫軸：購買頻率分組"),
              tags$li("縱軸：平均購買週期（天）"),
              tags$li("氣泡大小：該群體的客戶數量"),
              tags$li("顏色深淺：總價值高低")
            ),
            p("頻率高且週期短的客戶是最有價值的核心客群", style = "font-style: italic; color: #666;")
          )
        )
      ),
      
      # 客戶喚醒機會分析
      column(6,
        bs4Card(
          title = "客戶喚醒機會分析",
          status = "warning",
          solidHeader = TRUE,
          width = 12,
          footer = downloadButton(ns("download_reactivation"), "下載需喚醒客戶清單", class = "btn-sm"),
          plotlyOutput(ns("reactivation_opportunity"))
        )
      )
    ),
    
    br(),
    
    # 忠誠度階梯
    fluidRow(
      column(12,
        bs4Card(
          title = "忠誠度階梯",
          status = "purple",
          solidHeader = TRUE,
          width = 12,
          footer = downloadButton(ns("download_loyalty"), "下載忠誠度分析", class = "btn-sm"),
          plotlyOutput(ns("loyalty_ladder"))
        )
      )
    ),
    
    br(),
    
    # AI 智能分析集中區
    fluidRow(
      column(12,
        bs4Card(
          title = "🤖 AI 智能分析與建議",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          collapsible = TRUE,
          
          tabsetPanel(
            type = "tabs",
            
            tabPanel(
              title = "購買頻率分析",
              icon = icon("chart-bar"),
              br(),
              actionButton(ns("btn_analyze_frequency"), 
                          "開始 AI 分析", 
                          icon = icon("robot"),
                          class = "btn-primary"),
              br(), br(),
              uiOutput(ns("ai_purchase_frequency"))
            ),
            
            tabPanel(
              title = "喚醒機會分析",
              icon = icon("bell"),
              br(),
              actionButton(ns("btn_analyze_reactivation"), 
                          "開始 AI 分析", 
                          icon = icon("robot"),
                          class = "btn-warning"),
              br(), br(),
              uiOutput(ns("ai_reactivation_opportunity"))
            ),
            
            tabPanel(
              title = "忠誠度階梯策略",
              icon = icon("stairs"),
              br(),
              actionButton(ns("btn_analyze_loyalty"), 
                          "開始 AI 分析", 
                          icon = icon("robot"),
                          class = "btn-success"),
              br(), br(),
              uiOutput(ns("ai_loyalty_ladder"))
            ),
            
            tabPanel(
              title = "喚醒客戶清單",
              icon = icon("list"),
              br(),
              actionButton(ns("btn_analyze_list"), 
                          "開始 AI 分析", 
                          icon = icon("robot"),
                          class = "btn-danger"),
              br(), br(),
              uiOutput(ns("ai_reactivation_list"))
            )
          )
        )
      )
    )
  )
}

# Server Function
engagementFlowModuleServer <- function(id, con, user_info, dna_module_result, 
                                       enable_hints = TRUE, enable_gpt = FALSE, 
                                       chat_api = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # 載入 prompt 管理器
    prompts_df <- NULL
    if(enable_gpt) {
      prompts_df <- load_prompts()
    }
    
    # AI 分析狀態管理
    ai_analysis_state <- reactiveValues(
      frequency_analyzed = FALSE,
      reactivation_analyzed = FALSE,
      loyalty_analyzed = FALSE,
      list_analyzed = FALSE
    )
    
    # 輔助函數：處理 AI 結果的 Markdown 轉換
    render_ai_result <- function(result) {
      if(!is.null(result)) {
        if(grepl("\\*\\*|##|\\n\\n|^[0-9]+\\.|^-\\s", result)) {
          html_content <- markdownToHTML(text = result, fragment.only = TRUE)
          return(HTML(html_content))
        } else {
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
    
    # 計算活躍度指標
    engagement_metrics <- reactive({
      req(dna_results())
      
      data <- dna_results()$data_by_customer
      
      # 檢查必要欄位是否存在
      if(!"cai" %in% names(data)) {
        # 如果沒有 CAI，嘗試計算一個簡單的活躍度指標
        if("r_value" %in% names(data) && "f_value" %in% names(data)) {
          # 簡單的活躍度計算：頻率越高、最近購買時間越短，活躍度越高
          data$cai <- (1 / (data$r_value + 1)) * log(data$f_value + 1)
          # 標準化到 -10 到 10 的範圍
          data$cai <- scale(data$cai)[,1] * 5
        } else {
          data$cai <- 0
        }
      }
      
      # 計算 CAI
      avg_cai <- mean(data$cai, na.rm = TRUE)
      if(is.na(avg_cai) || is.nan(avg_cai)) {
        avg_cai <- 0
      }
      
      # 計算轉化率
      total_customers <- nrow(data)
      converted_customers <- sum(data$times >= 5, na.rm = TRUE)
      conversion_rate <- if(total_customers > 0) {
        (converted_customers / total_customers) * 100
      } else {
        0
      }
      
      # 計算購買頻率
      avg_frequency <- mean(data$times, na.rm = TRUE)
      if(is.na(avg_frequency)) avg_frequency <- 0
      
      # 計算平均再購時間
      repurchase_customers <- data[data$times > 1, ]
      avg_inter_purchase <- if(nrow(repurchase_customers) > 0) {
        mean(repurchase_customers$r_value / (repurchase_customers$times - 1), na.rm = TRUE)
      } else {
        NA
      }
      
      # 計算喚醒率
      dormant_customers <- sum(data$nes_status %in% c("S1", "S2", "S3"), na.rm = TRUE)
      reactivated_customers <- sum(data$nes_status == "E0" & data$times > 2, na.rm = TRUE)
      reactivation_rate <- if(dormant_customers > 0) {
        (reactivated_customers / dormant_customers) * 100
      } else {
        0
      }
      
      list(
        cai = avg_cai,
        conversion_rate = conversion_rate,
        purchase_frequency = avg_frequency,
        avg_inter_purchase = avg_inter_purchase,
        reactivation_rate = reactivation_rate,
        raw_data = data
      )
    })
    
    # KPI 顯示
    output$cai_value <- renderText({
      metrics <- engagement_metrics()
      cai_val <- metrics$cai
      if(!is.na(cai_val) && !is.nan(cai_val)) {
        if(cai_val > 0) {
          paste0("+", round(cai_val, 2))
        } else {
          as.character(round(cai_val, 2))
        }
      } else {
        "0.00"
      }
    })
    
    output$conversion_rate <- renderText({
      metrics <- engagement_metrics()
      paste0(round(metrics$conversion_rate, 1), "%")
    })
    
    output$purchase_frequency <- renderText({
      metrics <- engagement_metrics()
      paste0(round(metrics$purchase_frequency, 1), "次")
    })
    
    output$avg_inter_purchase <- renderText({
      metrics <- engagement_metrics()
      if(!is.na(metrics$avg_inter_purchase)) {
        paste0(round(metrics$avg_inter_purchase, 0), "天")
      } else {
        "N/A"
      }
    })
    
    output$reactivation_rate <- renderText({
      metrics <- engagement_metrics()
      paste0(round(metrics$reactivation_rate, 1), "%")
    })
    
    # 客戶活躍度分布（正確的散佈圖 - CAI vs 總消費）
    output$activity_distribution <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      # 移除 NA 值
      data <- data %>%
        filter(!is.na(cai) & !is.na(total_spent) & total_spent > 0)
      
      if(nrow(data) == 0) {
        return(plotly_empty() %>%
          layout(
            title = "無資料顯示",
            annotations = list(
              list(
                text = "無有效的活躍度資料",
                showarrow = FALSE,
                font = list(size = 20)
              )
            )
          ))
      }
      
      # 準備散佈圖數據
      scatter_data <- data %>%
        mutate(
          hover_text = paste0(
            "客戶ID: ", customer_id, "<br>",
            "活躍度(CAI): ", round(cai, 2), "<br>",
            "購買次數: ", times, "次<br>",
            "總消費: $", format(round(total_spent, 0), big.mark = ",")
          )
        )
      
      # 創建散佈圖
      plot_ly(scatter_data,
              x = ~cai,
              y = ~total_spent,
              color = ~times,
              colors = "RdYlGn",
              type = 'scatter',
              mode = 'markers',
              text = ~hover_text,
              hoverinfo = 'text',
              marker = list(
                size = ~sqrt(total_spent),
                sizemode = 'area',
                sizeref = 2 * max(sqrt(scatter_data$total_spent)) / (30^2),
                sizemin = 4,
                opacity = 0.7,
                line = list(color = 'white', width = 0.5)
              )) %>%
        layout(
          title = list(text = "客戶活躍度 vs 總消費金額", font = list(size = 14)),
          xaxis = list(
            title = "活躍度指數 (CAI)",
            zeroline = TRUE,
            zerolinecolor = 'rgba(0,0,0,0.3)',
            zerolinewidth = 2,
            gridcolor = 'rgba(0,0,0,0.1)'
          ),
          yaxis = list(
            title = "總消費金額 ($)",
            type = if(min(scatter_data$total_spent) > 0 && 
                     max(scatter_data$total_spent) / min(scatter_data$total_spent) > 100) "log" else "linear",
            gridcolor = 'rgba(0,0,0,0.1)'
          ),
          showlegend = TRUE,
          legend = list(title = list(text = "購買次數")),
          hovermode = 'closest'
        )
    })
    
    # 轉化漏斗分析
    output$conversion_funnel <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      # 準備漏斗數據
      funnel_data <- data %>%
        mutate(
          purchase_group = case_when(
            times == 1 ~ "1次購買",
            times == 2 ~ "2次購買",
            times >= 3 & times <= 4 ~ "3-4次購買",
            times >= 5 ~ "≥5次購買"
          )
        ) %>%
        group_by(purchase_group) %>%
        summarise(count = n(), .groups = 'drop')
      
      # 確保所有類別都存在
      all_groups <- data.frame(
        purchase_group = c("1次購買", "2次購買", "3-4次購買", "≥5次購買"),
        stringsAsFactors = FALSE
      )
      
      funnel_data <- all_groups %>%
        left_join(funnel_data, by = "purchase_group") %>%
        mutate(
          count = ifelse(is.na(count), 0, count),
          purchase_group = factor(purchase_group, 
                                 levels = c("1次購買", "2次購買", "3-4次購買", "≥5次購買"))
        ) %>%
        arrange(purchase_group)
      
      if(sum(funnel_data$count) > 0) {
        plot_ly(funnel_data,
                type = "funnel",
                y = ~purchase_group,
                x = ~count,
                textposition = "inside",
                textinfo = "value+percent",
                marker = list(
                  color = c("#FF6B6B", "#FFA06B", "#FFD93D", "#6BCF7F")
                ),
                connector = list(line = list(color = "royalblue", width = 3)),
                hovertemplate = "%{y}<br>客戶數: %{x}<br>占比: %{percentTotal}<extra></extra>") %>%
          layout(
            title = list(text = "客戶購買轉化漏斗", font = list(size = 14)),
            yaxis = list(title = "購買階段"),
            xaxis = list(title = "客戶數"),
            showlegend = FALSE
          )
      } else {
        plotly_empty()
      }
    })
    
    # 購買頻率與週期分析（完全修正版）
    output$purchase_patterns <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      # 過濾重複購買客戶
      pattern_data <- data %>%
        filter(times > 1 & !is.na(r_value) & !is.na(total_spent))
      
      if(nrow(pattern_data) > 0) {
        # 計算平均週期
        pattern_data <- pattern_data %>%
          mutate(
            avg_cycle = r_value / (times - 1),
            frequency_label = case_when(
              times == 2 ~ "2次",
              times >= 3 & times <= 5 ~ "3-5次",
              times >= 6 & times <= 10 ~ "6-10次",
              times >= 11 & times <= 20 ~ "11-20次",
              times > 20 ~ ">20次",
              TRUE ~ "其他"
            ),
            freq_numeric = case_when(
              times == 2 ~ 1,
              times >= 3 & times <= 5 ~ 2,
              times >= 6 & times <= 10 ~ 3,
              times >= 11 & times <= 20 ~ 4,
              times > 20 ~ 5,
              TRUE ~ 6
            )
          )
        
        # 按組彙總
        pattern_summary <- pattern_data %>%
          group_by(frequency_label, freq_numeric) %>%
          summarise(
            count = n(),
            avg_cycle_days = mean(avg_cycle, na.rm = TRUE),
            total_value = sum(total_spent, na.rm = TRUE),
            .groups = 'drop'
          ) %>%
          filter(!is.na(avg_cycle_days)) %>%
          arrange(freq_numeric)
        
        if(nrow(pattern_summary) > 0) {
          # 為 X 軸創建有序的標籤
          pattern_summary$x_order <- pattern_summary$freq_numeric
          
          plot_ly(pattern_summary,
                  x = ~freq_numeric,
                  y = ~avg_cycle_days,
                  size = ~count,
                  color = ~total_value,
                  colors = "Blues",
                  type = 'scatter',
                  mode = 'markers',
                  marker = list(
                    sizemode = 'diameter',
                    sizeref = 2 * max(pattern_summary$count) / (50^2),
                    sizemin = 10,
                    opacity = 0.8,
                    line = list(color = 'white', width = 1)
                  ),
                  text = ~paste0(
                    "頻率組: ", frequency_label, "<br>",
                    "平均週期: ", round(avg_cycle_days, 1), "天<br>",
                    "客戶數: ", count, "人<br>",
                    "總價值: $", format(round(total_value, 0), big.mark = ",")
                  ),
                  hoverinfo = 'text') %>%
            layout(
              title = list(text = "購買頻率 vs 購買週期", font = list(size = 14)),
              xaxis = list(
                title = "購買頻率",
                tickmode = "array",
                tickvals = pattern_summary$freq_numeric,
                ticktext = pattern_summary$frequency_label,
                gridcolor = 'rgba(0,0,0,0.1)'
              ),
              yaxis = list(
                title = "平均購買週期（天）",
                gridcolor = 'rgba(0,0,0,0.1)'
              ),
              showlegend = FALSE
            )
        } else {
          plotly_empty()
        }
      } else {
        plotly_empty() %>%
          layout(
            title = "無資料顯示",
            annotations = list(
              list(
                text = "無重複購買客戶資料",
                showarrow = FALSE,
                font = list(size = 20)
              )
            )
          )
      }
    })
    
    # 客戶喚醒機會分析
    output$reactivation_opportunity <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      reactivation_data <- data %>%
        filter(nes_status %in% c("S1", "S2", "S3")) %>%
        mutate(
          urgency = case_when(
            r_value > 180 ~ "緊急",
            r_value > 90 ~ "重要",
            TRUE ~ "一般"
          ),
          urgency_order = case_when(
            urgency == "緊急" ~ 1,
            urgency == "重要" ~ 2,
            urgency == "一般" ~ 3
          )
        ) %>%
        group_by(urgency, urgency_order) %>%
        summarise(
          count = n(),
          total_value = sum(total_spent, na.rm = TRUE),
          avg_days = mean(r_value, na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        arrange(urgency_order)
      
      if(nrow(reactivation_data) > 0) {
        plot_ly(reactivation_data,
                x = ~urgency,
                y = ~count,
                color = ~urgency,
                colors = c("緊急" = "#dc3545", "重要" = "#ffc107", "一般" = "#28a745"),
                type = 'bar',
                text = ~paste0(
                  count, " 位客戶<br>",
                  "總價值: $", format(total_value, big.mark = ","), "<br>",
                  "平均沉睡: ", round(avg_days, 0), "天"
                ),
                textposition = "outside",
                hoverinfo = 'text') %>%
          layout(
            title = list(text = "需喚醒客戶分析", font = list(size = 14)),
            xaxis = list(title = "緊急程度"),
            yaxis = list(title = "客戶數"),
            showlegend = FALSE
          )
      } else {
        plotly_empty() %>%
          layout(
            title = "無需喚醒的客戶",
            annotations = list(
              list(
                text = "所有客戶都處於活躍狀態",
                showarrow = FALSE,
                font = list(size = 20)
              )
            )
          )
      }
    })
    
    # 忠誠度階梯
    output$loyalty_ladder <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      loyalty_data <- data %>%
        mutate(
          loyalty_level = factor(
            case_when(
              times == 1 ~ "初次購買",
              times >= 2 & times <= 3 ~ "偶爾購買",
              times >= 4 & times <= 6 ~ "常客",
              times >= 7 & times <= 10 ~ "忠誠客戶",
              times > 10 ~ "品牌大使"
            ),
            levels = c("初次購買", "偶爾購買", "常客", "忠誠客戶", "品牌大使")
          )
        ) %>%
        group_by(loyalty_level) %>%
        summarise(
          count = n(),
          avg_value = mean(total_spent, na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        filter(!is.na(loyalty_level))
      
      if(nrow(loyalty_data) > 0) {
        plot_ly(loyalty_data,
                x = ~loyalty_level,
                y = ~count,
                type = 'bar',
                marker = list(
                  color = c("#e8e8e8", "#b3d9ff", "#66b3ff", "#0080ff", "#0040ff")
                ),
                text = ~paste0(count, " 位<br>",
                             "平均消費: $", format(round(avg_value, 0), big.mark = ",")),
                textposition = "outside",
                hovertemplate = "%{x}<br>客戶數: %{y}<br>%{text}<extra></extra>") %>%
          layout(
            title = list(text = "客戶忠誠度階梯分布", font = list(size = 14)),
            xaxis = list(title = "忠誠度等級"),
            yaxis = list(title = "客戶數"),
            showlegend = FALSE
          )
      } else {
        plotly_empty()
      }
    })
    
    # CSV 下載功能（保持不變）
    output$download_reactivation <- downloadHandler(
      filename = function() {
        paste0("reactivation_customers_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        data <- engagement_metrics()$raw_data
        
        reactivation_list <- data %>%
          filter(nes_status %in% c("S1", "S2", "S3")) %>%
          mutate(
            urgency = case_when(
              r_value > 180 ~ "緊急",
              r_value > 90 ~ "重要",
              TRUE ~ "一般"
            ),
            suggested_action = case_when(
              r_value > 180 ~ "發送大額優惠券+個人化關懷",
              r_value > 90 ~ "限時優惠+產品推薦",
              TRUE ~ "定期關懷郵件"
            )
          ) %>%
          select(customer_id, nes_status, r_value, total_spent, times, urgency, suggested_action) %>%
          arrange(desc(r_value))
        
        write.csv(reactivation_list, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    output$download_loyalty <- downloadHandler(
      filename = function() {
        paste0("loyalty_ladder_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        data <- engagement_metrics()$raw_data
        
        loyalty_export <- data %>%
          mutate(
            loyalty_level = case_when(
              times == 1 ~ "初次購買",
              times >= 2 & times <= 3 ~ "偶爾購買",
              times >= 4 & times <= 6 ~ "常客",
              times >= 7 & times <= 10 ~ "忠誠客戶",
              times > 10 ~ "品牌大使"
            ),
            next_level_target = case_when(
              times == 1 ~ "需再購1次升級為偶爾購買",
              times >= 2 & times <= 3 ~ paste0("需再購", 4 - times, "次升級為常客"),
              times >= 4 & times <= 6 ~ paste0("需再購", 7 - times, "次升級為忠誠客戶"),
              times >= 7 & times <= 10 ~ paste0("需再購", 11 - times, "次升級為品牌大使"),
              times > 10 ~ "已達最高等級"
            )
          ) %>%
          select(customer_id, loyalty_level, times, total_spent, m_value, next_level_target) %>%
          arrange(desc(times), desc(total_spent))
        
        write.csv(loyalty_export, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # AI 分析功能（加入按鈕觸發 + 確認 API 使用）
    
    # 購買頻率分析
    observeEvent(input$btn_analyze_frequency, {
      req(engagement_metrics())
      metrics <- engagement_metrics()
      
      output$ai_purchase_frequency <- renderUI({
        withProgress(message = '正在進行 AI 分析...', value = 0.5, {
          
          # 檢查是否啟用 GPT 並有 API
          api_status <- paste0("API狀態: ", 
                              ifelse(enable_gpt, "已啟用", "未啟用"), 
                              " | chat_api: ", 
                              ifelse(!is.null(chat_api), "已設定", "未設定"))
          
          cat("[購買頻率分析]", api_status, "\n")
          
          if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
            tryCatch({
              # 準備數據
              freq_distribution <- metrics$raw_data %>%
                mutate(freq_group = cut(times, breaks = c(0, 1, 3, 5, 10, Inf),
                                       labels = c("1次", "2-3次", "4-5次", "6-10次", ">10次"))) %>%
                group_by(freq_group) %>%
                summarise(count = n(), .groups = 'drop')
              
              cat("[購買頻率分析] 執行 execute_gpt_request...\n")
              
              result <- execute_gpt_request(
                var_id = "activity_purchase_frequency_analysis",
                variables = list(
                  avg_frequency = round(metrics$purchase_frequency, 1),
                  frequency_distribution = paste(freq_distribution$freq_group, ":", 
                                               freq_distribution$count, "人", 
                                               collapse = ", ")
                ),
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              if(!is.null(result)) {
                cat("[購買頻率分析] GPT API 成功返回結果\n")
                ai_analysis_state$frequency_analyzed <- TRUE
                return(div(
                  style = "padding: 15px; background: #f0f8ff; border-radius: 8px;",
                  h5("🤖 AI 分析結果 (GPT-4)", style = "color: #0066cc; margin-bottom: 15px;"),
                  tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
                  render_ai_result(result)
                ))
              } else {
                cat("[購買頻率分析] GPT API 返回空結果\n")
              }
            }, error = function(e) {
              cat("[購買頻率分析] AI 分析失敗:", e$message, "\n")
            })
          } else {
            cat("[購買頻率分析] 使用預設分析（GPT未啟用或未設定）\n")
          }
          
          # 預設分析
          div(
            style = "padding: 15px; background: #f0f8ff; border-radius: 8px;",
            h5("📊 購買頻率洞察（預設分析）", style = "color: #2c3e50;"),
            tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
            p(paste0("平均購買頻率為 ", round(metrics$purchase_frequency, 1), " 次")),
            h5("💡 行銷建議", style = "color: #2c3e50; margin-top: 15px;"),
            tags$ul(
              tags$li("低頻客戶：推出首購優惠，降低二購門檻"),
              tags$li("中頻客戶：定期推送個人化商品推薦"),
              tags$li("高頻客戶：提供 VIP 專屬權益，維持忠誠度")
            )
          )
        })
      })
    })
    
    # 喚醒機會分析
    observeEvent(input$btn_analyze_reactivation, {
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      output$ai_reactivation_opportunity <- renderUI({
        withProgress(message = '正在進行 AI 分析...', value = 0.5, {
          
          reactivation_stats <- data %>%
            filter(nes_status %in% c("S1", "S2", "S3")) %>%
            summarise(
              total = n(),
              total_value = sum(total_spent, na.rm = TRUE),
              avg_days = mean(r_value, na.rm = TRUE),
              .groups = 'drop'
            )
          
          api_status <- paste0("API: ", ifelse(enable_gpt && !is.null(chat_api), "啟用", "未啟用"))
          cat("[喚醒機會分析]", api_status, "\n")
          
          if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df) && reactivation_stats$total > 0) {
            tryCatch({
              cat("[喚醒機會分析] 執行 execute_gpt_request...\n")
              
              result <- execute_gpt_request(
                var_id = "activity_customer_reactivation_analysis",
                variables = list(
                  reactivation_count = reactivation_stats$total,
                  total_value = round(reactivation_stats$total_value, 0),
                  avg_dormant_days = round(reactivation_stats$avg_days, 0)
                ),
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              if(!is.null(result)) {
                cat("[喚醒機會分析] GPT API 成功返回結果\n")
                ai_analysis_state$reactivation_analyzed <- TRUE
                return(div(
                  style = "padding: 15px; background: #fff5e6; border-radius: 8px;",
                  h5("🤖 AI 分析結果 (GPT-4)", style = "color: #ff9800; margin-bottom: 15px;"),
                  tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
                  render_ai_result(result)
                ))
              }
            }, error = function(e) {
              cat("[喚醒機會分析] AI 分析失敗:", e$message, "\n")
            })
          }
          
          # 預設分析
          div(
            style = "padding: 15px; background: #fff5e6; border-radius: 8px;",
            h5("🔔 喚醒機會評估（預設分析）", style = "color: #d97706;"),
            tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
            p(paste0("共 ", reactivation_stats$total, " 位客戶需要喚醒")),
            p(paste0("潛在價值：$", format(reactivation_stats$total_value, big.mark = ","))),
            h5("🎯 喚醒策略", style = "color: #d97706; margin-top: 15px;"),
            tags$ul(
              tags$li("S1 瞌睡客：發送「我們想念您」郵件 + 小額優惠"),
              tags$li("S2 半睡客：限時大額折扣 + 新品推薦"),
              tags$li("S3 沉睡客：問卷調查 + 重新激活獎勵")
            )
          )
        })
      })
    })
    
    # 忠誠度階梯分析（保持原有邏輯，加入 API 狀態顯示）
    observeEvent(input$btn_analyze_loyalty, {
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      output$ai_loyalty_ladder <- renderUI({
        withProgress(message = '正在進行 AI 分析...', value = 0.5, {
          
          loyalty_dist <- data %>%
            mutate(
              loyalty_level = case_when(
                times == 1 ~ "初次購買",
                times >= 2 & times <= 3 ~ "偶爾購買",
                times >= 4 & times <= 6 ~ "常客",
                times >= 7 & times <= 10 ~ "忠誠客戶",
                times > 10 ~ "品牌大使"
              )
            ) %>%
            group_by(loyalty_level) %>%
            summarise(count = n(), .groups = 'drop')
          
          api_status <- paste0("API: ", ifelse(enable_gpt && !is.null(chat_api), "啟用", "未啟用"))
          
          if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
            tryCatch({
              # 確保所有層級都有值
              get_count <- function(level) {
                val <- loyalty_dist$count[loyalty_dist$loyalty_level == level]
                if(length(val) == 0) return(0) else return(val)
              }
              
              result <- execute_gpt_request(
                var_id = "activity_loyalty_ladder_strategy",
                variables = list(
                  first_time = get_count("初次購買"),
                  occasional = get_count("偶爾購買"),
                  regular = get_count("常客"),
                  loyal = get_count("忠誠客戶"),
                  ambassador = get_count("品牌大使")
                ),
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              if(!is.null(result)) {
                ai_analysis_state$loyalty_analyzed <- TRUE
                return(div(
                  style = "padding: 15px; background: #f5f0ff; border-radius: 8px;",
                  h5("🤖 AI 分析結果 (GPT-4)", style = "color: #7c3aed; margin-bottom: 15px;"),
                  tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
                  render_ai_result(result)
                ))
              }
            }, error = function(e) {
              cat("忠誠度階梯 AI 分析失敗:", e$message, "\n")
            })
          }
          
          # 預設分析
          div(
            style = "padding: 15px; background: #f5f0ff; border-radius: 8px;",
            h5("🏆 忠誠度階梯策略（預設分析）", style = "color: #7c3aed;"),
            tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
            p("客戶忠誠度分布分析"),
            h5("📈 升級策略", style = "color: #7c3aed; margin-top: 15px;"),
            tags$ul(
              tags$li("初次→偶爾：首購後 7 天內提供二購優惠"),
              tags$li("偶爾→常客：推出累積消費獎勵計畫"),
              tags$li("常客→忠誠：VIP 會員專屬權益"),
              tags$li("忠誠→大使：推薦獎勵計畫 + 專屬客服")
            )
          )
        })
      })
    })
    
    # 喚醒客戶清單分析
    observeEvent(input$btn_analyze_list, {
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      output$ai_reactivation_list <- renderUI({
        withProgress(message = '正在進行 AI 分析...', value = 0.5, {
          
          reactivation_customers <- data %>%
            filter(nes_status %in% c("S1", "S2"))
          
          api_status <- paste0("API: ", ifelse(enable_gpt && !is.null(chat_api), "啟用", "未啟用"))
          
          if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df) && nrow(reactivation_customers) > 0) {
            tryCatch({
              result <- execute_gpt_request(
                var_id = "activity_reactivation_marketing_plan",
                variables = list(
                  s1_count = sum(reactivation_customers$nes_status == "S1"),
                  s2_count = sum(reactivation_customers$nes_status == "S2"),
                  total_historical_value = round(sum(reactivation_customers$total_spent, na.rm = TRUE), 0),
                  avg_order_value = round(mean(reactivation_customers$m_value, na.rm = TRUE), 0)
                ),
                chat_api_function = chat_api,
                model = "gpt-4o-mini",
                prompts_df = prompts_df
              )
              
              if(!is.null(result)) {
                ai_analysis_state$list_analyzed <- TRUE
                return(div(
                  style = "padding: 15px; background: #ffebee; border-radius: 8px;",
                  h5("🤖 AI 分析結果 (GPT-4)", style = "color: #dc3545; margin-bottom: 15px;"),
                  tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
                  render_ai_result(result)
                ))
              }
            }, error = function(e) {
              cat("喚醒清單 AI 分析失敗:", e$message, "\n")
            })
          }
          
          # 預設分析
          div(
            style = "padding: 15px; background: #ffebee; border-radius: 8px;",
            h5("📋 喚醒客戶行銷計畫（預設分析）", style = "color: #c62828;"),
            tags$small(api_status, style = "color: #999; display: block; margin-bottom: 10px;"),
            p(paste0("需喚醒客戶總數：", nrow(reactivation_customers), " 位")),
            h5("📧 執行方案", style = "color: #c62828; margin-top: 15px;"),
            tags$ul(
              tags$li("第 1 波：發送個人化關懷郵件"),
              tags$li("第 2 波：提供限時專屬優惠"),
              tags$li("第 3 波：新品推薦 + 滿額贈"),
              tags$li("第 4 波：最後通牒優惠")
            ),
            p("建議每波間隔 7-10 天，追蹤開信率與轉換率", style = "font-style: italic; color: #666;")
          )
        })
      })
    })
    
  })
}