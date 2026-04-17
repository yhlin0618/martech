# 增強版市場輪廓分析模組
# 整合AI分析功能：市場區隔輪廓、目標客群偏好、潛在市場機會
# 創建日期：2025-01-11

library(dplyr)
library(tidyr)
library(plotly)
library(DT)
library(httr2)
library(jsonlite)
library(stringr)
library(markdown)

# 載入集中管理系統
if(file.exists("utils/prompt_manager.R")) {
  source("utils/prompt_manager.R")
  prompts_df <- tryCatch(load_prompts(), error = function(e) NULL)
} else {
  prompts_df <- NULL
}

if(file.exists("utils/hint_system.R")) {
  source("utils/hint_system.R")
  hints_df <- tryCatch(load_hints(), error = function(e) NULL)
} else {
  hints_df <- NULL
}

# ========== UI 函數 ==========
marketProfileEnhancedUI <- function(id) {
  ns <- NS(id)
  tagList(
    # 標題區
    div(class = "module-header mb-3",
        h3(icon("chart-pie"), "目標市場輪廓分析"),
        p(class = "text-muted", "市場區隔定位、客群偏好分析與潛在機會識別")),
    
    # 分析控制面板（加入提示）
    wellPanel(
      fluidRow(
        column(4,
          if(!is.null(hints_df) && exists("add_hint")) {
            add_hint(
              selectInput(ns("segmentation_method"), 
                         "市場區隔方法",
                         choices = list(
                           "K-means聚類" = "kmeans",
                           "屬性表現" = "performance",
                           "綜合分析" = "combined"
                         ),
                         selected = "kmeans"),
              var_id = "segmentation_method",
              hints_df = hints_df,
              enable_hints = TRUE
            )
          } else {
            selectInput(ns("segmentation_method"), 
                       "市場區隔方法",
                       choices = list(
                         "K-means聚類" = "kmeans",
                         "屬性表現" = "performance",
                         "綜合分析" = "combined"
                       ),
                       selected = "kmeans")
          }
        ),
        column(4,
          numericInput(ns("num_segments"), 
                      "區隔數量",
                      value = 4,
                      min = 3,
                      max = 6)
        ),
        column(4,
          actionButton(ns("run_analysis"), 
                      "執行AI分析",
                      class = "btn-primary btn-block",
                      icon = icon("brain"))
        )
      )
    ),
    
    # 結果顯示區
    tabsetPanel(
      id = ns("analysis_tabs"),
      
      # Tab 1: 市場區隔總覽
      tabPanel(
        title = "市場區隔總覽",
        value = "overview",
        br(),
        fluidRow(
          column(12,
            div(class = "segment-overview",
                uiOutput(ns("segment_summary_cards"))
            )
          )
        ),
        br(),
        fluidRow(
          column(6,
            plotlyOutput(ns("segment_distribution_plot"), height = "400px")
          ),
          column(6,
            plotlyOutput(ns("segment_characteristics_plot"), height = "400px")
          )
        )
      ),
      
      # Tab 2: 區隔詳細分析（MAMBA風格表格）
      tabPanel(
        title = "市場區隔分析",
        value = "detailed",
        br(),
        fluidRow(
          column(12,
            h4("市場區隔總覽"),
            DTOutput(ns("segment_summary_table"))
          )
        ),
        br(),
        fluidRow(
          column(12,
            h4("AI Market Segmentation Analysis Report"),
            uiOutput(ns("ai_segmentation_report"))
          )
        )
      ),
      
      # Tab 3: 客群偏好分析
      tabPanel(
        title = "客群偏好分析",
        value = "preferences",
        br(),
        fluidRow(
          column(12,
            div(class = "ai-analysis-section",
                h4(icon("users"), "目標客群偏好分析"),
                withSpinner(
                  uiOutput(ns("customer_preferences_analysis")),
                  type = 6
                )
            )
          )
        ),
        br(),
        fluidRow(
          column(6,
            plotlyOutput(ns("preference_heatmap"), height = "500px")
          ),
          column(6,
            plotlyOutput(ns("preference_radar"), height = "500px")
          )
        )
      ),
      
      # Tab 4: 潛在市場機會
      tabPanel(
        title = "潛在市場機會",
        value = "opportunities",
        br(),
        fluidRow(
          column(12,
            div(class = "ai-analysis-section",
                h4(icon("lightbulb"), "潛在市場機會分析"),
                withSpinner(
                  uiOutput(ns("market_opportunities_analysis")),
                  type = 6
                )
            )
          )
        ),
        br(),
        fluidRow(
          column(12,
            plotlyOutput(ns("opportunity_matrix"), height = "600px")
          )
        )
      ),
      
      # Tab 5: AI洞察報告
      tabPanel(
        title = "AI洞察報告",
        value = "insights",
        br(),
        fluidRow(
          column(12,
            div(class = "ai-insights-report",
                h4(icon("robot"), "AI綜合洞察報告"),
                withSpinner(
                  uiOutput(ns("ai_comprehensive_insights")),
                  type = 6
                )
            )
          )
        )
      )
    )
  )
}

# ========== Server 函數 ==========
marketProfileEnhancedServer <- function(id, data, brand_data, api_key = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # 反應式變數
    rv <- reactiveValues(
      segments = NULL,
      segment_details = NULL,
      customer_preferences = NULL,
      market_opportunities = NULL,
      ai_insights = NULL
    )
    
    # API金鑰處理
    get_api_key <- function() {
      if (!is.null(api_key)) return(api_key)
      key <- Sys.getenv("OPENAI_API_KEY")
      if (nzchar(key)) return(key)
      return(NULL)
    }
    
    # API調用函數（優先使用集中管理的prompt）
    call_gpt_api <- function(prompt = NULL, prompt_id = NULL, variables = list(), max_tokens = 1500) {
      api_key <- get_api_key()
      if (is.null(api_key)) {
        return("API金鑰未設定，無法執行AI分析")
      }
      
      # 如果有prompt_id且prompts_df存在，使用集中管理的prompt
      if (!is.null(prompt_id) && !is.null(prompts_df) && exists("prepare_gpt_messages")) {
        messages <- tryCatch({
          prepare_gpt_messages(
            var_id = prompt_id,
            variables = variables,
            prompts_df = prompts_df
          )
        }, error = function(e) {
          # 如果prepare_gpt_messages失敗，使用備用prompt
          list(
            list(role = "system", content = "你是品牌市場分析專家，請提供專業的市場分析洞察。"),
            list(role = "user", content = prompt)
          )
        })
      } else {
        # 使用傳入的prompt
        messages <- list(
          list(role = "system", content = "你是品牌市場分析專家，請提供專業的市場分析洞察。"),
          list(role = "user", content = prompt)
        )
      }
      
      tryCatch({
        req <- request("https://api.openai.com/v1/chat/completions") |>
          req_auth_bearer_token(api_key) |>
          req_headers(`Content-Type` = "application/json") |>
          req_body_json(list(
            model = "gpt-4o-mini",
            messages = messages,
            temperature = 0.7,
            max_tokens = max_tokens
          )) |>
          req_timeout(60)
        
        resp <- req_perform(req)
        content <- resp_body_json(resp)
        return(content$choices[[1]]$message$content)
      }, error = function(e) {
        return(paste("AI分析錯誤:", e$message))
      })
    }
    
    # 市場區隔分析（使用AI動態命名）
    analyze_segments <- reactive({
      req(data())
      df <- data()
      
      # 檢查資料是否足夠
      if(nrow(df) < 2) {
        return(data.frame())
      }
      
      # 嚴格使用 metadata 中的屬性欄位資訊
      attr_cols <- attr(df, "attribute_columns")

      if (is.null(attr_cols)) {
        # 沒有 metadata 表示資料未正確從上傳模組傳遞
        showNotification(
          "錯誤：未找到屬性欄位資訊，請確認已正確上傳並選擇屬性欄位",
          type = "error",
          duration = 5
        )
        return(data.frame())
      }

      # 確保屬性欄位存在於資料中
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 再次檢查 - 排除可能錯誤包含的非屬性欄位
      # total_score 和 avg_score 是計算結果，不應該作為屬性
      exclude_cols <- c("total_score", "avg_score", "總分", "平均分")
      attr_cols <- attr_cols[!attr_cols %in% exclude_cols]

      # 確保有屬性欄位
      if (length(attr_cols) == 0) {
        return(data.frame())
      }
      
      # 確保屬性欄位是數值型
      for (col in attr_cols) {
        if (col %in% names(df) && !is.numeric(df[[col]])) {
          df[[col]] <- as.numeric(df[[col]])
        }
      }

      # 基礎區隔分析
      segments <- df %>%
        mutate(
          avg_score = rowMeans(select(., all_of(attr_cols)), na.rm = TRUE),
          top_attributes = rowSums(select(., all_of(attr_cols)) >= 4, na.rm = TRUE),
          consistency = apply(select(., all_of(attr_cols)), 1, sd, na.rm = TRUE)
        )
      
      # 使用聚類分析進行初步分組（只在有足夠資料時）
      if(nrow(segments) >= 3) {
        # 準備聚類數據
        cluster_data <- segments %>%
          select(avg_score, top_attributes, consistency) %>%
          scale()
        
        # K-means聚類（分成3-4組）
        set.seed(123)
        n_clusters <- min(4, max(2, floor(nrow(segments)/2)))
        km <- kmeans(cluster_data, centers = n_clusters, nstart = 25)
        segments$cluster <- km$cluster
      } else {
        # 資料太少，使用簡單分組
        segments$cluster <- 1:nrow(segments)
      }
      
      # 加入市場地位分類
      market_avg <- mean(segments$avg_score, na.rm = TRUE)
      segments <- segments %>%
        mutate(
          performance_ratio = avg_score / market_avg,
          competitiveness_score = performance_ratio * (top_attributes / max(top_attributes, na.rm = TRUE)),
          # 市場地位分類
          market_position = case_when(
            competitiveness_score >= 1.5 ~ "市場領導者",
            competitiveness_score >= 1.2 ~ "強勢競爭者",
            competitiveness_score >= 0.8 ~ "主流品牌",
            TRUE ~ "挑戰者"
          )
        )
      
      # 為每個聚類生成AI命名
      segments <- segments %>%
        group_by(cluster) %>%
        mutate(
          cluster_avg_score = mean(avg_score),
          cluster_top_attrs = mean(top_attributes),
          cluster_size = n(),
          brands_in_cluster = paste(Variation, collapse = ", ")
        ) %>%
        ungroup()
      
      # 使用AI為每個聚類命名（如果API可用）
      if (!is.null(prompts_df) && "segment_naming" %in% prompts_df$var_id) {
        unique_clusters <- segments %>%
          select(cluster, cluster_avg_score, cluster_top_attrs, cluster_size, brands_in_cluster) %>%
          distinct()
        
        for(i in 1:nrow(unique_clusters)) {
          cluster_info <- unique_clusters[i,]
          
          # 找出該聚類的主要屬性
          cluster_brands <- segments %>% filter(cluster == cluster_info$cluster)
          top_attrs_cols <- attr_cols[order(colMeans(cluster_brands[attr_cols], na.rm = TRUE), decreasing = TRUE)[1:5]]
          
          # 取得該聚類的市場地位資訊
          cluster_position <- segments %>%
            filter(cluster == cluster_info$cluster) %>%
            summarise(
              avg_competitiveness = mean(competitiveness_score, na.rm = TRUE),
              dominant_position = names(sort(table(market_position), decreasing = TRUE))[1]
            )
          
          # 調用AI生成名稱（加入市場地位資訊）
          segment_name <- tryCatch({
            response <- call_gpt_api(
              prompt_id = "segment_naming",
              variables = list(
                avg_score = round(cluster_info$cluster_avg_score, 2),
                top_attributes = round(cluster_info$cluster_top_attrs),
                key_attributes = paste(top_attrs_cols, collapse = ", "),
                brands = substr(cluster_info$brands_in_cluster, 1, 100),
                market_share = round(cluster_info$cluster_size / nrow(segments) * 100, 1),
                market_position = cluster_position$dominant_position
              ),
              max_tokens = 200
            )
            
            # 解析AI回應
            if (!is.null(response) && !grepl("錯誤", response)) {
              # 嘗試提取名稱
              if (grepl("名稱[：:]", response)) {
                name <- sub(".*名稱[：:]\\s*\\[?([^\\]\\n]+)\\]?.*", "\\1", response)
                name <- trimws(name)
                if (nchar(name) > 0 && nchar(name) < 20) name else NULL
              } else {
                NULL
              }
            } else {
              NULL
            }
          }, error = function(e) NULL)
          
          # 如果AI命名失敗，使用描述性命名
          if (is.null(segment_name)) {
            # 根據實際數據生成描述性名稱
            segment_name <- paste0(
              "市場區隔", cluster_info$cluster, " (",
              if(cluster_info$cluster_avg_score >= 4.0) "高分" else if(cluster_info$cluster_avg_score >= 3.0) "中分" else "低分",
              "-",
              if(cluster_info$cluster_top_attrs >= median(segments$top_attributes)) "多屬性" else "少屬性",
              ")"
            )
          }
          
          segments$segment[segments$cluster == cluster_info$cluster] <- segment_name
        }
      } else {
        # 沒有AI時使用描述性命名
        segments <- segments %>%
          group_by(cluster) %>%
          mutate(
            # 根據實際數據特徵生成名稱
            segment = paste0(
              market_position[1], " (",
              "平均", round(mean(avg_score), 1), "分",
              if(mean(top_attributes) >= median(segments$top_attributes)) "-多優勢" else "-特定優勢",
              ")"
            )
          ) %>%
          ungroup()
      }
      
      # 計算市場份額和收入
      total_revenue <- 30000  # 假設總收入
      segments <- segments %>%
        group_by(segment) %>%
        mutate(
          segment_market_share = n() / nrow(segments) * 100,
          segment_revenue = segment_market_share * total_revenue / 100
        ) %>%
        ungroup() %>%
        mutate(
          market_share = segment_market_share / n(),
          revenue = segment_revenue / n()
        )
      
      segments
    })
    
    # 計算區隔詳細資訊
    calculate_segment_details <- function() {
      segments <- analyze_segments()
      df <- data()

      # 使用 metadata 中的屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        return(NULL)
      }
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 為每個區隔計算詳細統計
      segment_stats <- segments %>%
        group_by(segment) %>%
        summarise(
          品牌數 = n(),
          平均評分 = round(mean(avg_score), 2),
          最高評分 = round(max(avg_score), 2),
          最低評分 = round(min(avg_score), 2),
          平均優勢屬性數 = round(mean(top_attributes), 1),
          總市占率 = round(sum(market_share), 1),
          .groups = 'drop'
        )
      
      # 找出每個區隔的關鍵屬性
      segment_attributes <- segments %>%
        select(Variation, segment, all_of(attr_cols)) %>%
        pivot_longer(cols = all_of(attr_cols), names_to = "attribute", values_to = "score") %>%
        group_by(segment, attribute) %>%
        summarise(
          avg_score = mean(score, na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        group_by(segment) %>%
        arrange(desc(avg_score)) %>%
        slice_head(n = 5) %>%
        summarise(
          top_attributes = paste(attribute, collapse = ", "),
          .groups = 'drop'
        )
      
      list(
        stats = segment_stats,
        attributes = segment_attributes,
        segments = segments
      )
    }
    
    # 執行AI分析
    observeEvent(input$run_analysis, {
      showNotification("開始執行AI分析...", type = "message", duration = 3)
      
      withProgress(message = "執行AI分析中...", value = 0, {
        incProgress(0.2, detail = "分析市場區隔...")
        
        # 準備數據摘要
        segments <- analyze_segments()
        segment_summary <- segments %>%
          group_by(segment) %>%
          summarise(
            品牌 = paste(Variation, collapse = ", "),
            平均分數 = round(mean(avg_score), 2),
            .groups = 'drop'
          )
        
        # 1. 客群偏好分析（使用集中管理的prompt）
        incProgress(0.3, detail = "分析客群偏好...")
        
        # 優先使用集中管理的prompt
        if (!is.null(prompts_df) && "customer_preference_analysis" %in% prompts_df$var_id) {
          rv$customer_preferences <- call_gpt_api(
            prompt_id = "customer_preference_analysis",
            variables = list(
              segment_data = paste(capture.output(print(segment_summary, n = 20)), collapse = "\n")
            )
          )
        } else {
          # 備用prompt
          preference_prompt <- paste0(
            "根據以下品牌市場區隔數據，分析各區隔的目標客群偏好：\n\n",
            "市場區隔：\n",
            paste(capture.output(print(segment_summary, n = 20)), collapse = "\n"),
            "\n\n請分析：",
            "\n1. 各區隔的目標客群特徵",
            "\n2. 客群的核心需求和偏好",
            "\n3. 購買決策的關鍵因素",
            "\n4. 品牌溝通策略建議",
            "\n\n請用Markdown格式回覆，包含標題和條列式重點。"
          )
          rv$customer_preferences <- call_gpt_api(prompt = preference_prompt)
        }
        
        # 2. 潛在市場機會分析（使用集中管理的prompt）
        incProgress(0.6, detail = "識別市場機會...")
        
        # 優先使用集中管理的prompt
        if (!is.null(prompts_df) && "market_opportunities_analysis" %in% prompts_df$var_id) {
          rv$market_opportunities <- call_gpt_api(
            prompt_id = "market_opportunities_analysis",
            variables = list(
              market_data = paste(capture.output(print(segment_summary, n = 20)), collapse = "\n")
            )
          )
        } else {
          # 備用prompt
          opportunity_prompt <- paste0(
            "基於以下市場區隔分析，識別潛在的市場機會：\n\n",
            "市場現況：\n",
            paste(capture.output(print(segment_summary, n = 20)), collapse = "\n"),
            "\n\n請分析：",
            "\n1. 未被滿足的市場需求",
            "\n2. 競爭空白區域",
            "\n3. 成長潛力最大的區隔",
            "\n4. 具體的市場進入策略",
            "\n5. 風險評估與應對建議",
            "\n\n請用Markdown格式回覆，包含具體可行的建議。"
          )
          rv$market_opportunities <- call_gpt_api(prompt = opportunity_prompt)
        }
        
        # 3. 綜合洞察報告（使用集中管理的prompt）
        incProgress(0.9, detail = "生成綜合報告...")
        
        # 優先使用集中管理的prompt
        if (!is.null(prompts_df) && "market_profile_analysis" %in% prompts_df$var_id) {
          rv$ai_insights <- call_gpt_api(
            prompt_id = "market_profile_analysis",
            variables = list(
              segment_data = paste(capture.output(print(segment_summary, n = 20)), collapse = "\n")
            ),
            max_tokens = 2000
          )
        } else {
          # 備用prompt
          insights_prompt <- paste0(
            "作為市場策略顧問，請提供完整的市場分析洞察報告：\n\n",
            "市場數據：\n",
            paste(capture.output(print(segment_summary, n = 20)), collapse = "\n"),
            "\n\n請提供：",
            "\n1. 執行摘要（3-5個關鍵發現）",
            "\n2. 市場格局分析",
            "\n3. 競爭優勢評估",
            "\n4. 策略建議（短期vs長期）",
            "\n5. 行動計畫建議",
            "\n\n請用專業的Markdown格式，包含清晰的結構和可執行的建議。"
          )
          rv$ai_insights <- call_gpt_api(prompt = insights_prompt, max_tokens = 2000)
        }
        
        incProgress(1, detail = "完成！")
      })
      
      showNotification("AI分析完成！", type = "message", duration = 3)
    })
    
    # ========== 輸出渲染 ==========
    
    # 區隔摘要卡片
    output$segment_summary_cards <- renderUI({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(div(class = "alert alert-info", "請先上傳資料並執行屬性評分"))
      }
      
      segment_summary <- segments %>%
        group_by(segment) %>%
        summarise(
          count = n(),
          avg_score = round(mean(avg_score), 2),
          .groups = 'drop'
        )
      
      cards <- lapply(1:nrow(segment_summary), function(i) {
        segment_data <- segment_summary[i, ]
        color_class <- c("primary", "success", "warning", "info")[i %% 4 + 1]
        
        column(3,
          div(class = paste0("info-box bg-", color_class),
              div(class = "info-box-content",
                  span(class = "info-box-text", segment_data$segment),
                  span(class = "info-box-number", 
                       paste0(segment_data$count, " 個品牌")),
                  div(class = "progress",
                      div(class = "progress-bar",
                          style = paste0("width: ", segment_data$avg_score * 20, "%"))),
                  span(class = "progress-description",
                       paste0("平均評分: ", segment_data$avg_score))
              )
          )
        )
      })
      
      fluidRow(cards)
    })
    
    # 區隔分布圖
    output$segment_distribution_plot <- renderPlotly({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(plot_ly() %>% 
          add_annotations(
            text = "請先上傳資料並執行屬性評分",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            x = 0.5,
            y = 0.5
          ))
      }
      
      segment_summary <- segments %>%
        group_by(segment) %>%
        summarise(
          品牌數 = n(),
          平均評分 = round(mean(avg_score), 2),
          .groups = 'drop'
        )
      
      plot_ly(segment_summary, 
              labels = ~segment, 
              values = ~品牌數,
              type = 'pie',
              textposition = 'inside',
              textinfo = 'label+percent',
              hovertemplate = '%{label}<br>品牌數: %{value}<br>平均評分: %{customdata}<extra></extra>',
              customdata = ~平均評分,
              marker = list(colors = c('#3498db', '#2ecc71', '#f39c12', '#e74c3c'))) %>%
        layout(title = "市場區隔分布",
               showlegend = TRUE)
    })
    
    # 區隔特徵圖
    output$segment_characteristics_plot <- renderPlotly({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(plot_ly() %>% 
          add_annotations(
            text = "請先上傳資料並執行屬性評分",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            x = 0.5,
            y = 0.5
          ))
      }
      
      plot_data <- segments %>%
        select(Variation, segment, avg_score, top_attributes) %>%
        arrange(segment, desc(avg_score))
      
      plot_ly(plot_data,
              x = ~avg_score,
              y = ~top_attributes,
              color = ~segment,
              text = ~Variation,
              type = 'scatter',
              mode = 'markers+text',
              textposition = 'top center',
              marker = list(size = 15)) %>%
        layout(title = "區隔特徵分布",
               xaxis = list(title = "平均評分"),
               yaxis = list(title = "優勢屬性數"),
               showlegend = TRUE)
    })
    
    # 市場區隔總覽表格（MAMBA風格）
    output$segment_summary_table <- renderDT({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(datatable(data.frame(Message = "請先上傳資料並執行屬性評分")))
      }

      df <- data()

      # 使用 metadata 中的屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        return(NULL)
      }
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 彙總區隔資料
      segment_summary <- segments %>%
        group_by(segment) %>%
        summarise(
          Companies = n(),
          `Market Share` = sprintf("%.1f%%", sum(market_share, na.rm = TRUE)),
          `Total Revenue` = sprintf("$%s", format(round(sum(revenue, na.rm = TRUE)), big.mark = ",")),
          `Avg Revenue` = sprintf("$%s", format(round(mean(revenue, na.rm = TRUE)), big.mark = ",")),
          brands = paste(Variation, collapse = ", "),
          .groups = 'drop'
        )
      
      # 動態計算每個區隔的關鍵特徵（前5個高分屬性）
      key_characteristics <- segments %>%
        select(segment, all_of(attr_cols)) %>%
        group_by(segment) %>%
        summarise(across(all_of(attr_cols), mean, na.rm = TRUE), .groups = 'drop') %>%
        pivot_longer(cols = all_of(attr_cols), names_to = "attribute", values_to = "avg_score") %>%
        group_by(segment) %>%
        arrange(desc(avg_score)) %>%
        slice_head(n = 5) %>%
        summarise(
          `Key Characteristics` = paste(attribute[avg_score >= 3.5], collapse = "、"),
          .groups = 'drop'
        ) %>%
        mutate(
          `Key Characteristics` = ifelse(
            nchar(`Key Characteristics`) == 0,
            "尚在發展中",
            `Key Characteristics`
          )
        )
      
      # 合併資料
      final_table <- segment_summary %>%
        left_join(key_characteristics, by = "segment") %>%
        mutate(
          Segment = segment,
          Companies = paste0(Companies, " (品牌: ", substr(brands, 1, 50), 
                           ifelse(nchar(brands) > 50, "...", ""), ")")
        ) %>%
        select(Segment, Companies, `Market Share`, `Total Revenue`, `Avg Revenue`, `Key Characteristics`)
      
      # 不加入硬編碼的MAMBA行
      
      datatable(final_table,
                options = list(
                  pageLength = 10,
                  dom = 't',  # 只顯示表格
                  ordering = FALSE,
                  columnDefs = list(
                    list(className = 'dt-left', targets = c(0, 5)),
                    list(className = 'dt-center', targets = c(1, 2, 3, 4))
                  )
                ),
                rownames = FALSE,
                escape = FALSE) %>%
        formatStyle(
          'Segment',
          backgroundColor = styleEqual(
            c('配件完備族', '高端信賴派', 'MAMBA - 9 Product IDs'),
            c('#f0f0f0', '#e8f4f8', '#fff3cd')
          )
        )
    })
    
    # AI市場區隔分析報告
    output$ai_segmentation_report <- renderUI({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(div(class = "alert alert-info", "請先上傳資料並執行屬性評分"))
      }
      
      # 根據實際資料生成動態報告
      df <- data()

      # 使用 metadata 中的屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        return(NULL)
      }
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 計算各區隔統計
      segment_stats <- segments %>%
        group_by(segment) %>%
        summarise(
          count = n(),
          avg_score = round(mean(avg_score, na.rm = TRUE), 2),
          market_share = round(sum(market_share, na.rm = TRUE), 1),
          brands = paste(Variation, collapse = ", "),
          .groups = 'drop'
        )
      
      # 計算各區隔的關鍵屬性
      segment_attrs <- segments %>%
        select(segment, all_of(attr_cols)) %>%
        group_by(segment) %>%
        summarise(across(all_of(attr_cols), mean, na.rm = TRUE), .groups = 'drop') %>%
        pivot_longer(cols = all_of(attr_cols), names_to = "attribute", values_to = "score") %>%
        group_by(segment) %>%
        arrange(desc(score)) %>%
        slice_head(n = 5) %>%
        filter(score >= 3.5) %>%
        summarise(
          key_attrs = paste(attribute, collapse = "、"),
          .groups = 'drop'
        )
      
      # 合併資料
      report_data <- segment_stats %>%
        left_join(segment_attrs, by = "segment")
      
      # 生成動態HTML報告
      segment_list <- lapply(1:nrow(report_data), function(i) {
        row <- report_data[i,]
        paste0(
          '<li><strong>', row$segment, '：</strong>',
          '擁有', row$count, '家廠商，',
          '市占率為', row$market_share, '%，',
          '平均評分為', row$avg_score, '。',
          if(!is.na(row$key_attrs) && nchar(row$key_attrs) > 0) {
            paste0('其特色為', row$key_attrs, '。')
          } else {
            '尚在發展中。'
          },
          '</li>'
        )
      })
      
      report_html <- HTML(paste0(
        '<div class="ai-report-section">',
        '<h3>1. 市場區隔輪廓分析</h3>',
        '<ul>',
        paste(segment_list, collapse = ""),
        '</ul>',
        
        '<h3>2. 目標客群偏好分析</h3>',
        '<p>',
        if(nrow(report_data) > 0) {
          best_segment <- report_data[which.max(report_data$avg_score),]
          paste0(
            best_segment$segment, '具有最高平均評分（', best_segment$avg_score, '），',
            '應強化', if(!is.na(best_segment$key_attrs)) best_segment$key_attrs else '核心優勢',
            '來吸引目標客群。'
          )
        } else {
          '請執行AI分析以生成客群偏好分析。'
        },
        '</p>',
        
        '<h3>3. 潛在市場機會分析</h3>',
        '<p>',
        if(nrow(report_data) > 1) {
          low_share <- report_data[which.min(report_data$market_share),]
          paste0(
            '考慮到', low_share$segment, '市占率較低（', low_share$market_share, '%），',
            '但平均評分為', low_share$avg_score, '，這表示潛在市場機會。',
            '建議強化該區隔的市場策略。'
          )
        } else {
          '請執行AI分析以生成市場機會分析。'
        },
        '</p>',
        '</div>'
      ))
      
      div(
        style = "background: #f8f9fa; padding: 20px; border-radius: 8px; margin-top: 20px;",
        report_html
      )
    })
    
    # 客群偏好分析展示
    output$customer_preferences_analysis <- renderUI({
      if (is.null(rv$customer_preferences)) {
        return(p(class = "text-muted", "請點擊「執行AI分析」按鈕開始分析"))
      }
      
      HTML(markdown::markdownToHTML(
        text = rv$customer_preferences,
        fragment.only = TRUE
      ))
    })
    
    # 偏好熱圖
    output$preference_heatmap <- renderPlotly({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(plot_ly() %>% 
          add_annotations(
            text = "請先上傳資料並執行屬性評分",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            x = 0.5,
            y = 0.5
          ))
      }

      df <- data()

      # 使用 metadata 中的屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        return(plotly::plot_ly())
      }
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 計算每個區隔在各屬性的平均分數
      heatmap_data <- segments %>%
        select(segment, all_of(attr_cols)) %>%
        group_by(segment) %>%
        summarise(across(all_of(attr_cols), mean, na.rm = TRUE), .groups = 'drop') %>%
        pivot_longer(cols = -segment, names_to = "attribute", values_to = "score")
      
      # 轉換為矩陣格式
      heatmap_matrix <- heatmap_data %>%
        pivot_wider(names_from = attribute, values_from = score) %>%
        column_to_rownames("segment") %>%
        as.matrix()
      
      plot_ly(
        z = heatmap_matrix,
        x = colnames(heatmap_matrix),
        y = rownames(heatmap_matrix),
        type = "heatmap",
        colorscale = "Viridis",
        hovertemplate = "區隔: %{y}<br>屬性: %{x}<br>評分: %{z:.2f}<extra></extra>"
      ) %>%
        layout(
          title = "客群偏好熱圖",
          xaxis = list(title = "產品屬性", tickangle = 45),
          yaxis = list(title = "市場區隔")
        )
    })
    
    # 偏好雷達圖
    output$preference_radar <- renderPlotly({
      segments <- analyze_segments()
      
      # 檢查是否有資料
      if(is.null(segments) || nrow(segments) == 0) {
        return(plot_ly() %>% 
          add_annotations(
            text = "請先上傳資料並執行屬性評分",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            x = 0.5,
            y = 0.5
          ))
      }

      df <- data()

      # 使用 metadata 中的屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        return(plotly::plot_ly())
      }
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 選擇前8個最重要的屬性
      top_attrs <- df %>%
        select(all_of(attr_cols)) %>%
        summarise(across(everything(), mean, na.rm = TRUE)) %>%
        pivot_longer(everything()) %>%
        arrange(desc(value)) %>%
        slice_head(n = 8) %>%
        pull(name)
      
      # 準備雷達圖數據
      radar_data <- segments %>%
        group_by(segment) %>%
        summarise(across(all_of(top_attrs), mean, na.rm = TRUE), .groups = 'drop')
      
      # 創建雷達圖
      fig <- plot_ly(type = 'scatterpolar', fill = 'toself')
      
      for(i in 1:nrow(radar_data)) {
        fig <- fig %>%
          add_trace(
            r = as.numeric(radar_data[i, -1]),
            theta = top_attrs,
            name = radar_data$segment[i]
          )
      }
      
      fig %>%
        layout(
          title = "區隔偏好雷達圖",
          polar = list(
            radialaxis = list(
              visible = TRUE,
              range = c(0, 5)
            )
          ),
          showlegend = TRUE
        )
    })
    
    # 市場機會分析展示
    output$market_opportunities_analysis <- renderUI({
      if (is.null(rv$market_opportunities)) {
        return(p(class = "text-muted", "請點擊「執行AI分析」按鈕開始分析"))
      }
      
      HTML(markdown::markdownToHTML(
        text = rv$market_opportunities,
        fragment.only = TRUE
      ))
    })
    
    # 機會矩陣圖
    output$opportunity_matrix <- renderPlotly({
      segments <- analyze_segments()
      
      # 計算機會分數
      opportunity_data <- segments %>%
        mutate(
          market_size = market_share,
          growth_potential = 5 - avg_score,  # 分數越低，成長潛力越大
          competition = 1 / (top_attributes + 1),  # 優勢屬性越少，競爭越激烈
          opportunity_score = (market_size * 0.3 + growth_potential * 20 * 0.5 + (1-competition) * 100 * 0.2)
        )
      
      plot_ly(opportunity_data,
              x = ~growth_potential,
              y = ~market_size,
              size = ~opportunity_score,
              color = ~segment,
              text = ~Variation,
              type = 'scatter',
              mode = 'markers+text',
              textposition = 'top center',
              marker = list(sizemode = 'diameter', sizeref = 0.5)) %>%
        layout(
          title = "市場機會矩陣",
          xaxis = list(title = "成長潛力"),
          yaxis = list(title = "市場規模"),
          showlegend = TRUE,
          annotations = list(
            list(x = 0.8, y = 0.9, xref = "paper", yref = "paper",
                 text = "高潛力大市場", showarrow = FALSE,
                 font = list(color = "green", size = 12)),
            list(x = 0.2, y = 0.9, xref = "paper", yref = "paper",
                 text = "成熟大市場", showarrow = FALSE,
                 font = list(color = "blue", size = 12)),
            list(x = 0.8, y = 0.1, xref = "paper", yref = "paper",
                 text = "新興小市場", showarrow = FALSE,
                 font = list(color = "orange", size = 12)),
            list(x = 0.2, y = 0.1, xref = "paper", yref = "paper",
                 text = "飽和小市場", showarrow = FALSE,
                 font = list(color = "gray", size = 12))
          )
        )
    })
    
    # AI綜合洞察報告
    output$ai_comprehensive_insights <- renderUI({
      if (is.null(rv$ai_insights)) {
        return(p(class = "text-muted", "請點擊「執行AI分析」按鈕生成完整報告"))
      }
      
      div(class = "ai-report",
          HTML(markdown::markdownToHTML(
            text = rv$ai_insights,
            fragment.only = TRUE
          ))
      )
    })
    
    # 返回反應式值供其他模組使用
    return(list(
      segments = analyze_segments,
      segment_details = reactive({ calculate_segment_details() }),
      customer_preferences = reactive({ rv$customer_preferences }),
      market_opportunities = reactive({ rv$market_opportunities }),
      ai_insights = reactive({ rv$ai_insights })
    ))
  })
}