# 活躍轉化模組 (Engagement Flow Module) - 修正版
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
            p("此散佈圖展示客戶的活躍度分布：", style = "margin-bottom: 5px;"),
            tags$ul(
              tags$li("橫軸：活躍度指數 (CAI)，正值表示活躍，負值表示沉睡"),
              tags$li("縱軸：客戶數量或客戶價值"),
              tags$li("點的大小：代表客戶的消費金額"),
              tags$li("顏色深淺：表示購買頻率高低")
            ),
            p("理想狀態是多數客戶集中在右側（高活躍度區域）", style = "font-style: italic; color: #666;")
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
              tags$li("橫軸：購買頻率（次數）"),
              tags$li("縱軸：平均購買週期（天）"),
              tags$li("氣泡大小：該群體的客戶數量")
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
              uiOutput(ns("ai_purchase_frequency"))
            ),
            
            tabPanel(
              title = "喚醒機會分析",
              icon = icon("bell"),
              br(),
              uiOutput(ns("ai_reactivation_opportunity"))
            ),
            
            tabPanel(
              title = "忠誠度階梯策略",
              icon = icon("stairs"),
              br(),
              uiOutput(ns("ai_loyalty_ladder"))
            ),
            
            tabPanel(
              title = "喚醒客戶清單",
              icon = icon("list"),
              br(),
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
      
      # 計算 CAI
      avg_cai <- mean(data$cai, na.rm = TRUE)
      
      # 計算轉化率
      total_customers <- nrow(data)
      converted_customers <- sum(data$times >= 5, na.rm = TRUE)
      conversion_rate <- (converted_customers / total_customers) * 100
      
      # 計算購買頻率
      avg_frequency <- mean(data$times, na.rm = TRUE)
      
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
      if(metrics$cai > 0) {
        paste0("+", round(metrics$cai, 2))
      } else {
        as.character(round(metrics$cai, 2))
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
    
    # 客戶活躍度分布（改為散佈圖）
    output$activity_distribution <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      # 準備散佈圖數據
      scatter_data <- data %>%
        mutate(
          activity_group = cut(cai, 
                              breaks = c(-Inf, -2, -1, 0, 1, 2, Inf),
                              labels = c("極低", "低", "偏低", "中等", "偏高", "高")),
          hover_text = paste0(
            "客戶ID: ", customer_id, "<br>",
            "活躍度: ", round(cai, 2), "<br>",
            "購買次數: ", times, "<br>",
            "總消費: $", format(total_spent, big.mark = ",")
          )
        )
      
      plot_ly(scatter_data,
              x = ~cai,
              y = ~total_spent,
              color = ~times,
              size = ~total_spent,
              colors = "RdYlGn",
              type = 'scatter',
              mode = 'markers',
              text = ~hover_text,
              hoverinfo = 'text',
              marker = list(
                sizemode = 'diameter',
                sizeref = 2,
                sizemin = 3
              )) %>%
        layout(
          title = list(text = "客戶活躍度 vs 消費價值", font = list(size = 14)),
          xaxis = list(
            title = "活躍度指數 (CAI)",
            zeroline = TRUE,
            zerolinecolor = '#888',
            zerolinewidth = 2
          ),
          yaxis = list(
            title = "總消費金額",
            type = "log"
          ),
          showlegend = TRUE
        )
    })
    
    # 轉化漏斗分析（改為漏斗圖）
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
        summarise(count = n()) %>%
        mutate(
          purchase_group = factor(purchase_group, 
                                 levels = c("1次購買", "2次購買", "3-4次購買", "≥5次購買")),
          percentage = count / sum(count) * 100,
          cumulative = cumsum(count),
          conversion_rate = (count / max(cumulative)) * 100
        ) %>%
        arrange(purchase_group)
      
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
    })
    
    # 購買頻率與週期分析
    output$purchase_patterns <- renderPlotly({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      # 計算購買模式
      pattern_data <- data %>%
        filter(times > 1) %>%
        mutate(
          avg_cycle = r_value / (times - 1),
          frequency_group = cut(times, 
                               breaks = c(0, 2, 5, 10, 20, Inf),
                               labels = c("2次", "3-5次", "6-10次", "11-20次", ">20次"))
        ) %>%
        group_by(frequency_group) %>%
        summarise(
          count = n(),
          avg_cycle_days = mean(avg_cycle, na.rm = TRUE),
          total_value = sum(total_spent, na.rm = TRUE)
        ) %>%
        filter(!is.na(frequency_group))
      
      plot_ly(pattern_data,
              x = ~frequency_group,
              y = ~avg_cycle_days,
              size = ~count,
              color = ~total_value,
              colors = "Blues",
              type = 'scatter',
              mode = 'markers',
              marker = list(
                sizemode = 'diameter',
                sizeref = 1,
                sizemin = 10
              ),
              text = ~paste0(
                "頻率組: ", frequency_group, "<br>",
                "平均週期: ", round(avg_cycle_days, 1), "天<br>",
                "客戶數: ", count, "<br>",
                "總價值: $", format(total_value, big.mark = ",")
              ),
              hoverinfo = 'text') %>%
        layout(
          title = list(text = "購買頻率 vs 購買週期", font = list(size = 14)),
          xaxis = list(title = "購買頻率"),
          yaxis = list(title = "平均購買週期（天）"),
          showlegend = FALSE
        )
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
          avg_days = mean(r_value, na.rm = TRUE)
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
              text = "所有客戶都處於活躍狀態",
              showarrow = FALSE,
              font = list(size = 20)
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
          avg_value = mean(total_spent, na.rm = TRUE)
        ) %>%
        filter(!is.na(loyalty_level))
      
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
    })
    
    # CSV 下載功能
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
    
    # AI 分析功能
    
    # AI 購買頻率分析
    output$ai_purchase_frequency <- renderUI({
      req(engagement_metrics())
      metrics <- engagement_metrics()
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          result <- execute_gpt_request(
            var_id = "activity_purchase_frequency_analysis",
            variables = list(
              avg_frequency = round(metrics$purchase_frequency, 1),
              high_freq_count = sum(metrics$raw_data$times >= 5, na.rm = TRUE),
              low_freq_count = sum(metrics$raw_data$times <= 2, na.rm = TRUE),
              total_customers = nrow(metrics$raw_data)
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(result)) {
            return(div(
              style = "padding: 15px; background: #f0f8ff; border-radius: 8px;",
              render_ai_result(result)
            ))
          }
        }, error = function(e) {
          cat("購買頻率 AI 分析失敗:", e$message, "\n")
        })
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #f0f8ff; border-radius: 8px;",
        h5("📊 購買頻率洞察", style = "color: #2c3e50;"),
        p(paste0("平均購買頻率為 ", round(metrics$purchase_frequency, 1), " 次")),
        h5("💡 行銷建議", style = "color: #2c3e50; margin-top: 15px;"),
        tags$ul(
          tags$li("低頻客戶：推出首購優惠，降低二購門檻"),
          tags$li("中頻客戶：定期推送個人化商品推薦"),
          tags$li("高頻客戶：提供 VIP 專屬權益，維持忠誠度")
        )
      )
    })
    
    # AI 喚醒機會分析
    output$ai_reactivation_opportunity <- renderUI({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      reactivation_stats <- data %>%
        filter(nes_status %in% c("S1", "S2", "S3")) %>%
        summarise(
          total = n(),
          total_value = sum(total_spent, na.rm = TRUE),
          avg_days = mean(r_value, na.rm = TRUE)
        )
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
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
            return(div(
              style = "padding: 15px; background: #fff5e6; border-radius: 8px;",
              render_ai_result(result)
            ))
          }
        }, error = function(e) {
          cat("喚醒機會 AI 分析失敗:", e$message, "\n")
        })
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #fff5e6; border-radius: 8px;",
        h5("🔔 喚醒機會評估", style = "color: #d97706;"),
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
    
    # AI 忠誠度階梯分析
    output$ai_loyalty_ladder <- renderUI({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
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
        summarise(count = n())
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df)) {
        tryCatch({
          result <- execute_gpt_request(
            var_id = "activity_loyalty_ladder_strategy",
            variables = list(
              first_time = loyalty_dist$count[loyalty_dist$loyalty_level == "初次購買"],
              occasional = loyalty_dist$count[loyalty_dist$loyalty_level == "偶爾購買"],
              regular = loyalty_dist$count[loyalty_dist$loyalty_level == "常客"],
              loyal = loyalty_dist$count[loyalty_dist$loyalty_level == "忠誠客戶"],
              ambassador = loyalty_dist$count[loyalty_dist$loyalty_level == "品牌大使"]
            ),
            chat_api_function = chat_api,
            model = "gpt-4o-mini",
            prompts_df = prompts_df
          )
          
          if(!is.null(result)) {
            return(div(
              style = "padding: 15px; background: #f5f0ff; border-radius: 8px;",
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
        h5("🏆 忠誠度階梯策略", style = "color: #7c3aed;"),
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
    
    # AI 喚醒客戶清單分析
    output$ai_reactivation_list <- renderUI({
      req(engagement_metrics())
      data <- engagement_metrics()$raw_data
      
      reactivation_customers <- data %>%
        filter(nes_status %in% c("S1", "S2"))
      
      if(enable_gpt && !is.null(chat_api) && !is.null(prompts_df) && nrow(reactivation_customers) > 0) {
        tryCatch({
          result <- execute_gpt_request(
            var_id = "activity_reactivation_marketing_plan",
            variables = list(
              s1_count = sum(reactivation_customers$nes_status == "S1"),
              s2_count = sum(reactivation_customers$nes_status == "S2"),
              total_historical_value = sum(reactivation_customers$total_spent, na.rm = TRUE),
              avg_order_value = mean(reactivation_customers$m_value, na.rm = TRUE)
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
          cat("喚醒清單 AI 分析失敗:", e$message, "\n")
        })
      }
      
      # 預設分析
      div(
        style = "padding: 15px; background: #ffebee; border-radius: 8px;",
        h5("📋 喚醒客戶行銷計畫", style = "color: #c62828;"),
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
}