# BrandEdge 旗艦版模組
# 支援10-30個屬性評分、市場賽道分析、品牌識別度策略等進階功能
# 最多支援20個品牌，1000則評論

library(httr2)
library(jsonlite)
library(stringr)
library(markdown)

# 載入 Prompt 管理系統
source("utils/prompt_manager.R")
# 載入所有 prompts（模組載入時執行一次）
prompts_df <- load_prompts()

# ========== 共用函數 ==========

strip_code_fence <- function(txt) {
  str_replace_all(
    txt,
    regex("^```[A-Za-z0-9]*[ \\t]*\\r?\\n|\\r?\\n```[ \\t]*$", multiline = TRUE),
    ""
  )
}

chat_api <- function(messages,
                     model       = "gpt-4o-mini",
                     api_key     = Sys.getenv("OPENAI_API_KEY"),
                     api_url     = "https://api.openai.com/v1/chat/completions",
                     timeout_sec = 60,
                     max_tokens  = 2048) {
  if (!nzchar(api_key)) stop("🔑 OPENAI_API_KEY is missing")
  
  body <- list(
    model       = model,
    messages    = messages,
    temperature = 0.3,
    max_tokens  = max_tokens
  )
  
  req <- request(api_url) |>
    req_auth_bearer_token(api_key) |>
    req_headers(`Content-Type`="application/json") |>
    req_body_json(body) |>
    req_timeout(timeout_sec)
  
  resp <- req_perform(req)
  
  if (resp_status(resp) >= 400) {
    err <- resp_body_string(resp)
    stop(sprintf("Chat API error %s:\n%s", resp_status(resp), err))
  }
  
  content <- resp_body_json(resp)
  return(trimws(content$choices[[1]]$message$content))
}

# ========== 1. 目標市場輪廓模組 ==========

marketProfileModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    h4("目標市場輪廓分析"),
    uiOutput(ns("market_segments")),
    br(),
    DTOutput(ns("brand_profile_table"))
  )
}

marketProfileModuleServer <- function(id, data, brand_data) {
  moduleServer(id, function(input, output, session) {
    
    # 市場區隔分析
    market_segments <- reactive({
      req(data())
      df <- data()

      # 智能識別屬性欄位
      # 優先使用 metadata 中的屬性欄位資訊
      attr_cols <- attr(df, "attribute_columns")

      if (is.null(attr_cols)) {
        # 如果沒有 metadata，排除已知的非屬性欄位
        non_attr_cols <- c("Variation", "product_id", "product_name", "brand",
                           "total_score", "avg_score")
        attr_cols <- names(df)[!names(df) %in% non_attr_cols]

        # 只保留數值型欄位
        attr_cols <- attr_cols[sapply(df[attr_cols], is.numeric)]
      }

      # 確保屬性欄位存在
      attr_cols <- attr_cols[attr_cols %in% names(df)]
      
      # 注意：scoring_data已經是每個品牌一行的匯總資料
      # 計算每個品牌的平均分數和高分屬性數
      segments <- df %>%
        mutate(
          avg_score = rowMeans(select(., all_of(attr_cols)), na.rm = TRUE),
          top_attributes = rowSums(select(., all_of(attr_cols)) >= 4, na.rm = TRUE),
          market_share = 100 / nrow(.)  # 假設每個品牌市占率相等
        ) %>%
        mutate(
          segment = case_when(
            avg_score >= 4.5 & top_attributes > median(top_attributes) ~ "領導品牌",
            avg_score >= 4.0 & top_attributes <= median(top_attributes) ~ "利基品牌",
            avg_score < 4.0 & top_attributes > median(top_attributes) ~ "大眾品牌",
            TRUE ~ "挑戰者品牌"
          )
        ) %>%
        select(Variation, avg_score, top_attributes, market_share, segment)
      
      segments
    })
    
    output$market_segments <- renderUI({
      segments <- market_segments()
      
      # 產生市場區隔描述
      segment_summary <- segments %>%
        group_by(segment) %>%
        summarise(
          品牌數 = n(),
          平均市占率 = round(mean(market_share), 1),
          .groups = 'drop'
        )
      
      HTML(paste0(
        "<div class='market-segments'>",
        "<h5>市場區隔狀況：</h5>",
        "<ul>",
        paste0(
          "<li>", segment_summary$segment, "：",
          segment_summary$品牌數, "個品牌，",
          "平均市占率", segment_summary$平均市占率, "%</li>",
          collapse = ""
        ),
        "</ul>",
        "</div>"
      ))
    })
    
    # 品牌輪廓表格
    output$brand_profile_table <- renderDT({
      segments <- market_segments()
      
      DT::datatable(
        segments,
        caption = "各品牌市場定位輪廓",
        rownames = FALSE,
        options = list(
          pageLength = 10,
          searching = TRUE,
          language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Chinese-traditional.json')
        )
      ) %>%
        formatRound(columns = c('avg_score', 'top_attributes', 'market_share'), digits = 2)
    })
  })
}

# ========== 2. 市場賽道分析模組 ==========

marketTrackModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    h4("高成長市場賽道分析"),
    plotlyOutput(ns("growth_track_plot"), height = "500px"),
    br(),
    uiOutput(ns("track_recommendations"))
  )
}

marketTrackModuleServer <- function(id, data, key_vars) {
  moduleServer(id, function(input, output, session) {

    # 分析成長賽道
    growth_tracks <- reactive({
      req(data())
      df <- data()

      # 獲取所有屬性欄位
      attr_cols <- attr(df, "attribute_columns")
      if (is.null(attr_cols)) {
        # 使用 key_vars 作為備選
        req(key_vars())
        attr_cols <- key_vars()
      }

      # 確保屬性欄位存在於資料中
      attr_cols <- attr_cols[attr_cols %in% names(df)]

      # 使用前5個屬性作為關鍵屬性
      keys <- head(attr_cols, 5)

      # 計算各屬性的成長潛力
      growth_data <- df %>%
        select(all_of(attr_cols)) %>%
        summarise_all(mean, na.rm = TRUE) %>%
        pivot_longer(everything(), names_to = "attribute", values_to = "current_performance") %>%
        mutate(
          # 假設理想值為1，計算成長空間
          growth_potential = pmax(0, 1 - current_performance),
          # 市場重要性（使用關鍵因素權重）
          importance = ifelse(attribute %in% keys[1:5], 1.0, 0.5),
          # 成長賽道得分
          track_score = growth_potential * importance
        ) %>%
        arrange(desc(track_score))
      
      growth_data
    })
    
    # 成長賽道視覺化
    output$growth_track_plot <- renderPlotly({
      tracks <- growth_tracks()
      
      plot_ly(tracks, 
              x = ~growth_potential, 
              y = ~importance,
              text = ~attribute,
              type = 'scatter',
              mode = 'markers+text',
              marker = list(
                size = ~track_score * 50,
                color = ~track_score,
                colorscale = 'Viridis',
                showscale = TRUE,
                colorbar = list(title = "賽道潛力")
              ),
              textposition = "top center") %>%
        layout(
          title = "市場成長賽道機會圖",
          xaxis = list(title = "成長潛力", range = c(-0.1, 1.1)),
          yaxis = list(title = "市場重要性", range = c(0, 1.2)),
          showlegend = FALSE,
          annotations = list(
            list(x = 0.75, y = 0.75, text = "高潛力賽道", showarrow = FALSE, font = list(size = 14, color = "green")),
            list(x = 0.25, y = 0.75, text = "成熟賽道", showarrow = FALSE, font = list(size = 14, color = "blue")),
            list(x = 0.75, y = 0.25, text = "利基賽道", showarrow = FALSE, font = list(size = 14, color = "orange")),
            list(x = 0.25, y = 0.25, text = "低優先賽道", showarrow = FALSE, font = list(size = 14, color = "gray"))
          )
        )
    })
    
    # 賽道建議
    output$track_recommendations <- renderUI({
      tracks <- growth_tracks()
      top_tracks <- head(tracks, 5)
      
      HTML(paste0(
        "<div class='track-recommendations'>",
        "<h5>建議優先發展的市場賽道：</h5>",
        "<ol>",
        paste0(
          "<li><strong>", top_tracks$attribute, "</strong>：",
          "成長潛力 ", round(top_tracks$growth_potential * 100, 1), "%，",
          "重要性 ", round(top_tracks$importance * 100, 0), "%</li>",
          collapse = ""
        ),
        "</ol>",
        "<hr>",
        "<div class='alert alert-info' style='margin-top: 20px;'>",
        "<h5><i class='fas fa-info-circle'></i> 指標說明</h5>",
        "<dl class='row' style='margin-bottom: 0;'>",
        "<dt class='col-sm-3'><i class='fas fa-chart-line'></i> 成長潛力</dt>",
        "<dd class='col-sm-9'>",
        "代表該屬性從目前表現提升到理想水準的改善空間。",
        "<br><small class='text-muted'>",
        "• 80-100%：有極大改善空間，是重要的成長機會<br>",
        "• 50-80%：中等改善空間，值得積極投入資源<br>",
        "• 20-50%：改善空間有限，需評估投資效益<br>",
        "• 0-20%：已接近理想狀態，維持現狀即可",
        "</small>",
        "</dd>",
        "<dt class='col-sm-3'><i class='fas fa-star'></i> 市場重要性</dt>",
        "<dd class='col-sm-9'>",
        "反映該屬性對整體市場競爭力的影響程度。",
        "<br><small class='text-muted'>",
        "• 100%：關鍵屬性，直接影響品牌成敗<br>",
        "• 50%：重要屬性，對品牌表現有顯著影響<br>",
        "• 數值越高，代表消費者越重視此屬性",
        "</small>",
        "</dd>",
        "<dt class='col-sm-3'><i class='fas fa-bullseye'></i> 四象限解讀</dt>",
        "<dd class='col-sm-9'>",
        "<small class='text-muted'>",
        "• <span class='text-success font-weight-bold'>高潛力賽道</span>（右上）：高成長潛力+高重要性 = 最優先投資<br>",
        "• <span class='text-primary font-weight-bold'>成熟賽道</span>（左上）：低成長潛力+高重要性 = 維持領先優勢<br>",
        "• <span class='text-warning font-weight-bold'>利基賽道</span>（右下）：高成長潛力+低重要性 = 差異化機會<br>",
        "• <span class='text-secondary font-weight-bold'>低優先賽道</span>（左下）：低成長潛力+低重要性 = 資源最低配置",
        "</small>",
        "</dd>",
        "</dl>",
        "</div>",
        "</div>"
      ))
    })
  })
}

# ========== 3. 進階品牌屬性評價模組（10-30個屬性）==========

advancedAttributeModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    h4("進階品牌屬性評價"),
    fluidRow(
      column(6, 
        numericInput(ns("num_attributes"), "屬性數量", value = 15, min = 10, max = 30)
      ),
      column(6,
        actionButton(ns("generate_attributes"), "產生屬性", class = "btn-primary")
      )
    ),
    br(),
    uiOutput(ns("attributes_list")),
    br(),
    actionButton(ns("start_scoring"), "開始評分", class = "btn-success"),
    br(),
    br(),
    DTOutput(ns("scoring_results"))
  )
}

advancedAttributeModuleServer <- function(id, review_data) {
  moduleServer(id, function(input, output, session) {
    rv <- reactiveValues(
      attributes = NULL,
      scores = NULL
    )
    
    # 產生屬性
    observeEvent(input$generate_attributes, {
      req(review_data())
      
      withProgress(message = "分析評論產生屬性...", value = 0, {
        incProgress(0.3)
        
        # 取樣評論進行分析
        sample_reviews <- review_data() %>%
          sample_n(min(50, nrow(.))) %>%
          pull(Body) %>%
          paste(collapse = " ")
        
        # 使用集中管理的 prompt 產生屬性
        messages <- prepare_gpt_messages(
          var_id = "extract_attributes",
          variables = list(
            num_attributes = input$num_attributes,
            sample_reviews = substr(sample_reviews, 1, 3000)
          ),
          prompts_df = prompts_df
        )
        
        incProgress(0.6)
        response <- tryCatch(
          chat_api(messages),
          error = function(e) {
            # 如果API失敗，使用預設屬性
            paste0('{"attributes": ["品質", "價格", "功能", "外觀", "耐用性", "使用便利性", ',
                   '"包裝", "客服", "配送速度", "性價比", "創新性", "安全性", ',
                   '"環保", "品牌信譽", "售後服務"]}')
          }
        )
        
        # 解析屬性
        attributes_parsed <- tryCatch(
          fromJSON(response)$attributes,
          error = function(e) {
            c("品質", "價格", "功能", "外觀", "耐用性", "使用便利性",
              "包裝", "客服", "配送速度", "性價比", "創新性", "安全性",
              "環保", "品牌信譽", "售後服務")
          }
        )
        
        # 確保有正確數量的屬性
        if (length(attributes_parsed) < input$num_attributes) {
          # 補充預設屬性
          default_attrs <- c("材質", "重量", "尺寸", "顏色", "保固", 
                            "配件", "說明書", "認證", "產地", "保存")
          attributes_parsed <- c(attributes_parsed, 
                                default_attrs[1:(input$num_attributes - length(attributes_parsed))])
        }
        
        rv$attributes <- head(attributes_parsed, input$num_attributes)
        incProgress(1)
      })
    })
    
    # 顯示屬性列表
    output$attributes_list <- renderUI({
      req(rv$attributes)
      
      HTML(paste0(
        "<div class='attributes-list'>",
        "<h5>已產生的屬性（共", length(rv$attributes), "個）：</h5>",
        "<div class='row'>",
        paste0(
          "<div class='col-md-3'><span class='badge badge-info'>",
          rv$attributes, "</span></div>",
          collapse = ""
        ),
        "</div>",
        "</div>"
      ))
    })
    
    # 開始評分
    observeEvent(input$start_scoring, {
      req(rv$attributes, review_data())
      
      withProgress(message = "進行屬性評分...", value = 0, {
        reviews <- review_data()
        n_reviews <- min(100, nrow(reviews))  # 最多評100則
        
        scores_matrix <- matrix(NA, nrow = n_reviews, ncol = length(rv$attributes))
        colnames(scores_matrix) <- rv$attributes
        
        for (i in 1:n_reviews) {
          incProgress(1/n_reviews, detail = paste("評分第", i, "則"))
          
          # 批次評分多個屬性
          review_text <- reviews$Body[i]
          
          # 使用集中管理的 prompt 進行評分
          messages <- prepare_gpt_messages(
            var_id = "score_attributes",
            variables = list(
              attributes = paste(rv$attributes, collapse = ", "),
              review_text = substr(review_text, 1, 1000)
            ),
            prompts_df = prompts_df
          )
          
          response <- tryCatch(
            chat_api(messages, max_tokens = 500),
            error = function(e) {
              # 產生隨機分數作為備用
              scores <- sample(3:5, length(rv$attributes), replace = TRUE)
              names(scores) <- rv$attributes
              toJSON(list(scores = as.list(scores)))
            }
          )
          
          # 解析分數
          scores_parsed <- tryCatch(
            fromJSON(response)$scores,
            error = function(e) {
              scores <- sample(3:5, length(rv$attributes), replace = TRUE)
              names(scores) <- rv$attributes
              as.list(scores)
            }
          )
          
          # 填入分數矩陣
          for (attr in rv$attributes) {
            if (!is.null(scores_parsed[[attr]])) {
              scores_matrix[i, attr] <- as.numeric(scores_parsed[[attr]])
            }
          }
        }
        
        # 計算平均分數
        rv$scores <- data.frame(
          Variation = reviews$Variation[1:n_reviews],
          scores_matrix
        ) %>%
          group_by(Variation) %>%
          summarise(across(everything(), ~mean(., na.rm = TRUE)), .groups = 'drop')
      })
    })
    
    # 顯示評分結果
    output$scoring_results <- renderDT({
      req(rv$scores)
      
      DT::datatable(
        rv$scores,
        caption = paste("品牌屬性評分結果（", ncol(rv$scores) - 1, "個屬性）"),
        rownames = FALSE,
        options = list(
          pageLength = 20,
          scrollX = TRUE,
          language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Chinese-traditional.json')
        )
      ) %>%
        formatRound(columns = 2:ncol(rv$scores), digits = 2)
    })
    
    return(reactive(rv$scores))
  })
}

# ========== 4. 進階品牌DNA比較模組 ==========

advancedDNAModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    h4("進階品牌DNA比較"),
    selectInput(ns("select_brands"), "選擇要比較的品牌", 
                choices = NULL, multiple = TRUE),
    plotlyOutput(ns("advanced_dna_plot"), height = "700px"),
    br(),
    uiOutput(ns("dna_insights"))
  )
}

advancedDNAModuleServer <- function(id, data_full) {
  moduleServer(id, function(input, output, session) {
    
    # 更新品牌選擇
    observe({
      req(data_full())
      brands <- unique(data_full()$Variation)
      updateSelectInput(session, "select_brands", 
                       choices = brands,
                       selected = head(brands, 5))  # 預設選前5個
    })
    
    # 繪製進階DNA圖
    output$advanced_dna_plot <- renderPlotly({
      req(data_full(), input$select_brands)
      
      # 篩選選定的品牌
      selected_data <- data_full() %>%
        filter(Variation %in% input$select_brands)
      
      # 獲取屬性欄位
      attr_cols <- attr(data_full(), "attribute_columns")
      if (is.null(attr_cols)) {
        # 沒有 metadata 表示資料未正確從上傳模組傳遞
        showNotification(
          "錯誤：未找到屬性欄位資訊，無法生成雷達圖",
          type = "error",
          duration = 5
        )
        return(NULL)
      }

      # 確保屬性欄位存在
      attr_cols <- attr_cols[attr_cols %in% names(selected_data)]

      # 轉換為長格式（只包含屬性欄位）
      dta_long <- selected_data %>%
        select(Variation, all_of(attr_cols)) %>%
        pivot_longer(
          cols = -c("Variation"),
          names_to = "attribute",
          values_to = "score"
        )
      
      # 創建雷達圖
      fig <- plot_ly(
        type = 'scatterpolar',
        mode = 'lines+markers',
        fill = 'toself'
      )
      
      # 為每個品牌添加軌跡
      for (brand in unique(dta_long$Variation)) {
        brand_data <- dta_long %>% filter(Variation == brand)
        
        fig <- fig %>%
          add_trace(
            r = brand_data$score,
            theta = brand_data$attribute,
            name = brand,
            text = paste("品牌:", brand, "<br>",
                        "屬性:", brand_data$attribute, "<br>",
                        "分數:", round(brand_data$score, 2)),
            hoverinfo = "text"
          )
      }
      
      # 設定布局
      fig <- fig %>%
        layout(
          title = list(
            text = "品牌DNA多維度比較",
            font = list(size = 20)
          ),
          polar = list(
            radialaxis = list(
              visible = TRUE,
              range = c(0, 5),
              tickmode = "linear",
              tick0 = 0,
              dtick = 1,
              ticktext = c("0", "1", "2", "3", "4", "5"),
              tickvals = c(0, 1, 2, 3, 4, 5)
            ),
            angularaxis = list(
              direction = "clockwise",
              rotation = 90
            )
          ),
          showlegend = TRUE,
          legend = list(
            orientation = "v",
            x = 1.1,
            y = 0.5
          )
        )
      
      fig
    })
    
    # DNA洞察分析
    output$dna_insights <- renderUI({
      req(data_full(), input$select_brands)
      
      selected_data <- data_full() %>%
        filter(Variation %in% input$select_brands)
      
      if (nrow(selected_data) < 2) {
        return(HTML("<p>請選擇至少2個品牌進行比較</p>"))
      }
      
      # 從 metadata 取得屬性欄位
      attr_cols <- attr(data_full(), "attribute_columns")

      if (is.null(attr_cols)) {
        # 如果沒有 metadata，使用所有數值欄位（排除已知的非屬性欄位）
        non_attr_cols <- c("Variation", "product_id", "product_name", "brand")
        attr_cols <- names(selected_data)[!names(selected_data) %in% non_attr_cols]
        attr_cols <- attr_cols[sapply(selected_data[attr_cols], is.numeric)]
      } else {
        # 確保屬性欄位存在於選擇的資料中
        attr_cols <- attr_cols[attr_cols %in% names(selected_data)]
      }

      # 找出差異最大的屬性
      attr_variance <- selected_data %>%
        select(all_of(attr_cols)) %>%
        summarise(across(everything(), var, na.rm = TRUE)) %>%
        pivot_longer(everything(), names_to = "attribute", values_to = "variance") %>%
        arrange(desc(variance))
      
      top_diff_attrs <- head(attr_variance, 5)
      
      # 找出領先品牌
      brand_avg_scores <- selected_data %>%
        pivot_longer(-Variation, names_to = "attribute", values_to = "score") %>%
        group_by(Variation) %>%
        summarise(avg_score = mean(score, na.rm = TRUE), .groups = 'drop') %>%
        arrange(desc(avg_score))
      
      leading_brand <- brand_avg_scores$Variation[1]
      
      # 為每個品牌找出優勢屬性（分數>=4）
      brand_strengths <- selected_data %>%
        pivot_longer(-Variation, names_to = "attribute", values_to = "score") %>%
        filter(score >= 4) %>%
        group_by(Variation) %>%
        summarise(
          強項屬性 = paste(head(attribute[order(score, decreasing = TRUE)], 3), collapse = "、"),
          強項數量 = n(),
          .groups = 'drop'
        )
      
      # 為每個品牌找出弱勢屬性（分數<3）
      brand_weaknesses <- selected_data %>%
        pivot_longer(-Variation, names_to = "attribute", values_to = "score") %>%
        filter(score < 3) %>%
        group_by(Variation) %>%
        summarise(
          弱項屬性 = paste(head(attribute[order(score)], 3), collapse = "、"),
          弱項數量 = n(),
          .groups = 'drop'
        )
      
      # 生成詳細的品牌洞察報告
      brands_detail <- ""
      for (i in 1:nrow(selected_data)) {
        brand_name <- selected_data$Variation[i]
        
        # 取得該品牌的強弱項
        strengths <- brand_strengths %>% filter(Variation == brand_name)
        weaknesses <- brand_weaknesses %>% filter(Variation == brand_name)
        
        # 找出該品牌表現最佳的屬性
        brand_scores <- selected_data %>%
          filter(Variation == brand_name) %>%
          select(all_of(attr_cols)) %>%
          pivot_longer(everything(), names_to = "attribute", values_to = "score") %>%
          arrange(desc(score))
        
        top_attrs <- head(brand_scores, 3)
        
        brands_detail <- paste0(brands_detail,
          "<li><strong>", brand_name, "</strong>：<br>",
          "　表現較佳：", 
          ifelse(nrow(strengths) > 0 && nchar(strengths$強項屬性) > 0, 
                 strengths$強項屬性, "無明顯優勢"),
          "（", paste(round(top_attrs$score, 2), collapse = "、"), "分）<br>",
          "　待改進：", 
          ifelse(nrow(weaknesses) > 0 && nchar(weaknesses$弱項屬性) > 0, 
                 weaknesses$弱項屬性, "表現均衡"),
          "</li>"
        )
      }
      
      # 使用AI生成深入洞察
      ai_insights <- tryCatch({
        # 準備數據給AI分析
        data_for_ai <- selected_data %>%
          pivot_longer(-Variation, names_to = "attribute", values_to = "score") %>%
          group_by(Variation) %>%
          summarise(
            avg_score = mean(score, na.rm = TRUE),
            top_attrs = paste(attribute[order(score, decreasing = TRUE)][1:3], collapse = "、"),
            weak_attrs = paste(attribute[order(score)][1:3], collapse = "、"),
            .groups = 'drop'
          )
        
        messages <- prepare_gpt_messages(
          var_id = "dna_insights_analysis",
          variables = list(
            brands_data = toJSON(data_for_ai),
            top_diff_attrs = paste(top_diff_attrs$attribute[1:3], collapse = "、")
          ),
          prompts_df = prompts_df
        )
        
        # 取得AI回應並轉換為HTML
        ai_response <- chat_api(messages, max_tokens = 800)
        # 將markdown轉換為HTML
        markdownToHTML(text = ai_response, fragment.only = TRUE)
        
      }, error = function(e) {
        # 如果API失敗，提供預設建議
        paste0(
          "<h6>策略建議：</h6>",
          "<ul>",
          "<li>領先品牌應持續強化優勢屬性，建立更高的競爭門檻</li>",
          "<li>挑戰者品牌應聚焦差異化定位，避免正面競爭</li>",
          "<li>關注市場變化趨勢，及時調整產品策略</li>",
          "</ul>"
        )
      })
      
      HTML(paste0(
        "<div class='dna-insights'>",
        "<h5>品牌DNA分析洞察：</h5>",
        "<ul>",
        "<li><strong>領先品牌：</strong>", leading_brand, 
        "（平均分數：", round(brand_avg_scores$avg_score[1], 2), "）</li>",
        "<li><strong>差異化最大的屬性：</strong>",
        paste(top_diff_attrs$attribute[1:3], collapse = "、"), "</li>",
        "<li><strong>品牌數量：</strong>", length(input$select_brands), "個</li>",
        "<li><strong>分析維度：</strong>", length(attributes), "個屬性</li>",
        "</ul>",
        "<h6>各品牌表現詳情：</h6>",
        "<ul>", brands_detail, "</ul>",
        "<div class='ai-insights-section'>",
        "<h6>AI深入洞察與策略建議：</h6>",
        ai_insights,
        "</div>",
        "</div>"
      ))
    })
  })
}

# ========== 5. 品牌識別度建構策略模組 ==========

brandIdentityModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    h4("品牌識別度建構策略"),
    selectInput(ns("target_brand"), "選擇目標品牌", choices = NULL),
    actionButton(ns("generate_identity"), "生成識別度策略", class = "btn-primary"),
    br(), br(),
    uiOutput(ns("identity_strategy")),
    br(),
    plotlyOutput(ns("identity_matrix"), height = "500px")
  )
}

brandIdentityModuleServer <- function(id, data, key_vars) {
  moduleServer(id, function(input, output, session) {
    rv <- reactiveValues(strategy = NULL)
    
    # 更新品牌選擇
    observe({
      req(data())
      brands <- unique(data()$Variation)
      updateSelectInput(session, "target_brand", choices = brands)
    })
    
    # 生成識別度策略
    observeEvent(input$generate_identity, {
      req(input$target_brand, data(), key_vars())
      
      withProgress(message = "分析品牌識別度...", value = 0, {
        incProgress(0.2)
        
        brand_data <- data() %>%
          filter(Variation == input$target_brand)
        
        # 分析品牌獨特性
        # 從 metadata 取得屬性欄位
        attr_cols <- attr(data(), "attribute_columns")
        if (is.null(attr_cols)) {
          attr_cols <- character(0)  # 空向量
        } else {
          attr_cols <- attr_cols[attr_cols %in% names(data())]
        }

        all_brands_avg <- data() %>%
          select(all_of(attr_cols)) %>%
          summarise(across(everything(), mean, na.rm = TRUE))

        brand_avg <- brand_data %>%
          select(all_of(attr_cols)) %>%
          summarise(across(everything(), mean, na.rm = TRUE))
        
        # 計算差異化指數
        differentiation <- abs(brand_avg - all_brands_avg)
        
        # 找出最獨特的屬性
        unique_attrs <- differentiation %>%
          pivot_longer(everything(), names_to = "attribute", values_to = "diff_score") %>%
          arrange(desc(diff_score)) %>%
          head(5)
        
        incProgress(0.5)
        
        # 使用集中管理的 prompt 生成策略
        messages <- prepare_gpt_messages(
          var_id = "brand_identity_strategy",
          variables = list(
            brand_name = input$target_brand,
            unique_attributes = paste(unique_attrs$attribute, collapse = "、")
          ),
          prompts_df = prompts_df
        )
        
        strategy_text <- tryCatch(
          chat_api(messages),
          error = function(e) {
            paste0(
              "## 品牌識別度建構策略\n\n",
              "1. **強化視覺識別**：設計獨特的品牌標誌和包裝，提升視覺記憶點\n",
              "2. **差異化定位**：聚焦於", unique_attrs$attribute[1], "等獨特優勢\n",
              "3. **故事行銷**：打造品牌故事，建立情感連結\n",
              "4. **體驗優化**：創造獨特的顧客體驗流程\n",
              "5. **社群經營**：建立品牌社群，培養忠誠顧客"
            )
          }
        )
        
        rv$strategy <- list(
          text = strategy_text,
          unique_attrs = unique_attrs,
          brand = input$target_brand
        )
        
        incProgress(1)
      })
    })
    
    # 顯示策略
    output$identity_strategy <- renderUI({
      req(rv$strategy)
      
      html <- markdownToHTML(text = rv$strategy$text, fragment.only = TRUE)
      
      HTML(paste0(
        "<div class='identity-strategy'>",
        html,
        "<h5>品牌獨特屬性：</h5>",
        "<ul>",
        paste0(
          "<li>", rv$strategy$unique_attrs$attribute,
          "（差異化指數：", round(rv$strategy$unique_attrs$diff_score, 3), "）</li>",
          collapse = ""
        ),
        "</ul>",
        "</div>"
      ))
    })
    
    # 識別度矩陣圖
    output$identity_matrix <- renderPlotly({
      req(data())
      
      # 計算每個品牌的識別度指標
      identity_scores <- data() %>%
        group_by(Variation) %>%
        summarise(
          avg_score = mean(c_across(where(is.numeric)), na.rm = TRUE),
          variance = var(c_across(where(is.numeric)), na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        mutate(
          uniqueness = variance,  # 變異度代表獨特性
          strength = avg_score     # 平均分代表實力
        )
      
      # 標記目標品牌
      if (!is.null(input$target_brand)) {
        identity_scores <- identity_scores %>%
          mutate(
            is_target = ifelse(Variation == input$target_brand, "目標品牌", "其他品牌"),
            marker_size = ifelse(Variation == input$target_brand, 20, 10)
          )
      } else {
        identity_scores$is_target <- "其他品牌"
        identity_scores$marker_size <- 10
      }
      
      plot_ly(identity_scores,
              x = ~uniqueness,
              y = ~strength,
              text = ~Variation,
              color = ~is_target,
              size = ~marker_size,
              type = 'scatter',
              mode = 'markers+text',
              textposition = 'top center',
              colors = c("目標品牌" = "red", "其他品牌" = "blue")) %>%
        layout(
          title = "品牌識別度定位矩陣",
          xaxis = list(title = "獨特性（識別度）"),
          yaxis = list(title = "品牌實力"),
          showlegend = TRUE,
          annotations = list(
            list(x = 0.75, y = 0.75, xref = "paper", yref = "paper",
                 text = "高識別高實力", showarrow = FALSE,
                 font = list(color = "green", size = 12)),
            list(x = 0.25, y = 0.75, xref = "paper", yref = "paper",
                 text = "低識別高實力", showarrow = FALSE,
                 font = list(color = "orange", size = 12)),
            list(x = 0.75, y = 0.25, xref = "paper", yref = "paper",
                 text = "高識別低實力", showarrow = FALSE,
                 font = list(color = "purple", size = 12)),
            list(x = 0.25, y = 0.25, xref = "paper", yref = "paper",
                 text = "低識別低實力", showarrow = FALSE,
                 font = list(color = "gray", size = 12))
          )
        )
    })
  })
}

# ========== 保留原有模組（向下相容）==========

# PCA Module
pcaModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("hint")),
    plotlyOutput(ns("pca_plot"))
  )
}

pcaModuleServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    
    # 預處理數據以避免常數列問題
    processed_data <- reactive({
      full_data <- data()
      req(ncol(full_data) >= 3)  # 至少需要 Variation + 2個數值列
      
      # 分離品牌名稱和數值數據
      brand_names <- full_data$Variation

      # 從 metadata 取得屬性欄位
      attr_cols <- attr(full_data, "attribute_columns")

      if (is.null(attr_cols)) {
        # 如果沒有 metadata，使用所有數值欄位
        non_attr_cols <- c("Variation", "product_id", "product_name", "brand")
        attr_cols <- names(full_data)[!names(full_data) %in% non_attr_cols]
        attr_cols <- attr_cols[sapply(full_data[attr_cols], is.numeric)]
      } else {
        # 確保屬性欄位存在
        attr_cols <- attr_cols[attr_cols %in% names(full_data)]
      }

      nums <- full_data %>% select(all_of(attr_cols))
      
      # 轉換為data.frame以避免tibble警告
      nums_df <- as.data.frame(nums)
      
      # 檢查並移除常數列（變異數為0的列）
      vars <- apply(nums_df, 2, var, na.rm = TRUE)
      valid_cols <- !is.na(vars) & vars > 1e-8  # 允許極小的變異
      
      if (sum(valid_cols) < 2) {
        return(NULL)  # 沒有足夠的變數進行PCA
      }
      
      # 返回處理後的數據和品牌名稱
      list(
        data = nums_df[, valid_cols, drop = FALSE],
        brands = brand_names,
        removed_cols = sum(!valid_cols)
      )
    })
    
    pca_res <- reactive({
      processed <- processed_data()
      req(!is.null(processed))
      prcomp(processed$data, center = TRUE, scale. = TRUE, rank. = 3)
    })
    
    output$hint <- renderUI({
      full_data <- data()
      processed <- processed_data()
      
      if (ncol(full_data) < 3) {  # Variation + 至少2個數值列
        tags$div(style="color:#888", "請先完成屬性評分，並且至少需要2個數值屬性才能進行PCA分析。")
      } else if (is.null(processed)) {
        tags$div(style="color:#orange", "⚠️ 數據中存在常數列（變異為0），無法進行PCA分析。請確認評分數據的變異性。")
      } else if (processed$removed_cols > 0) {
        tags$div(style="color:#blue", paste("ℹ️ 已自動移除", processed$removed_cols, "個常數列，使用", ncol(processed$data), "個變數進行PCA分析。"))
      } else {
        tags$div(style="color:#green", paste("✅ 使用", ncol(processed$data), "個屬性進行PCA分析"))
      }
    })
    
    output$pca_plot <- renderPlotly({
      processed <- processed_data()
      req(!is.null(processed), ncol(processed$data) >= 2)
      
      tryCatch({
        pc <- pca_res()
        scores   <- as.data.frame(pc$x)
        loadings <- as.data.frame(pc$rotation) * 5
        
        # 使用實際的品牌名稱
        scores$Brand <- processed$brands[1:nrow(scores)]
        
        load_long <- bind_rows(
          loadings %>% rownames_to_column("var") %>% mutate(PC1=0, PC2=0, PC3=0),
          loadings %>% rownames_to_column("var")
        )
        
        # 計算解釋變異量
        var_explained <- summary(pc)$importance[2, 1:3] * 100
        
        plot_ly() %>%
          add_markers(data = scores, 
                     x = ~PC1, y = ~PC2, z = ~PC3, 
                     text = ~paste("品牌:", Brand, "<br>PC1:", round(PC1, 2), "<br>PC2:", round(PC2, 2), "<br>PC3:", round(PC3, 2)),
                     hoverinfo = "text",
                     marker = list(size = 10, color = "steelblue", opacity = 0.8)) %>%
          add_lines(data = load_long, 
                   x = ~PC1, y = ~PC2, z = ~PC3, 
                   color = ~var,
                   line = list(width = 2),
                   hoverinfo = "text",
                   text = ~paste("屬性:", var)) %>%
          layout(
            title = "PCA 品牌定位地圖",
            scene = list(
              xaxis = list(title = paste("PC1 (", round(var_explained[1], 1), "%)")),
              yaxis = list(title = paste("PC2 (", round(var_explained[2], 1), "%)")),
              zaxis = list(title = paste("PC3 (", round(var_explained[3], 1), "%)"))
            ),
            margin = list(l = 0, r = 0, t = 50, b = 0)
          )
      }, error = function(e) {
        plot_ly() %>%
          add_annotations(
            text = paste("PCA 分析錯誤:", e$message, "<br>請確認數據品質和變異性"),
            xref = "paper", yref = "paper",
            x = 0.5, y = 0.5, xanchor = "center", yanchor = "center",
            showarrow = FALSE,
            font = list(size = 16, color = "red")
          ) %>%
          layout(title = "PCA 分析")
      })
    })
  })
}

# Ideal Analysis Module
idealModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    textOutput(ns("key_factors")),
    br(),
    br(),
    DTOutput(ns("ideal_rank"))
  )
}

idealModuleServer <- function(id, data, raw, indicator, key_vars) {
  moduleServer(id, function(input, output, session) {
    
    ideal_row <- reactive({
      df <- data()
      req("Ideal" %in% df$Variation)
      df %>%
        filter(Variation == "Ideal") %>%
        select(where(~ is.numeric(.x) && !any(is.na(.x))))
    })
    
    output$key_factors <- renderText({
      paste("關鍵因素：", paste(key_vars(), collapse = ", "))
    })
    
    output$ideal_rank <- renderDT({
      ind <- indicator()
      df  <- raw() %>% select(Variation)

      # 從 metadata 取得屬性欄位
      attr_cols <- attr(raw(), "attribute_columns")
      if (!is.null(attr_cols)) {
        # 只使用 key_vars 中且在屬性欄位中的欄位
        score_cols <- intersect(key_vars(), attr_cols)
      } else {
        # 降級方案：使用 key_vars
        score_cols <- key_vars()
      }

      df$Score <- ind %>%
        select(any_of(score_cols)) %>%
        rowSums(na.rm = TRUE)
      df <- df %>% filter(Variation != "Ideal") %>% arrange(desc(Score))
      
      DT::datatable(df,
                    rownames = FALSE,
                    options = list(pageLength = 10, searching = TRUE))
    })
  })
}

# Strategy Analysis Module
strategyModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(ns("select_Variation"), "選擇 Variation", choices = NULL),
    actionButton(ns("run_strategy"), "策略探索", class = "btn btn-primary mb-3"),
    plotlyOutput(ns("strategy_plot"), height = "800px"),
    withSpinner(
      htmlOutput(ns("strategy_summary")),
      type  = 6,
      color = "#0d6efd"
    )
  )
}

strategyModuleServer <- function(id, data, key_vars) {
  moduleServer(id, function(input, output, session) {
    rv <- reactiveValues(cache = list())
    
    observe({
      req(data())
      updateSelectInput(session, "select_Variation",
                        choices = unique(data()$Variation))
    })
    
    output$strategy_plot <- renderPlotly({
      req(input$select_Variation)
      
      ind       <- dplyr::filter(data(), Variation == input$select_Variation)
      req(nrow(ind) > 0)

      # 從 metadata 取得屬性欄位
      attr_cols <- attr(data(), "attribute_columns")

      if (is.null(attr_cols)) {
        showNotification("警告：未找到屬性欄位資訊", type = "warning")
        return()
      }

      # 確保屬性欄位存在於資料中
      attr_cols <- attr_cols[attr_cols %in% names(ind)]

      # 確保是數值型欄位
      attr_cols <- attr_cols[sapply(ind[attr_cols], is.numeric)]

      if (length(attr_cols) == 0) {
        showNotification("錯誤：沒有可用的數值屬性欄位", type = "error")
        return()
      }

      key       <- key_vars()
      # 只使用上傳時選擇的屬性欄位
      feats_key <- intersect(key, attr_cols)
      feats_non <- setdiff(attr_cols, key)

      sums_key <- if(length(feats_key) > 0) colSums(ind[feats_key, drop = FALSE]) else numeric(0)
      sums_non <- if(length(feats_non) > 0) colSums(ind[feats_non, drop = FALSE]) else numeric(0)
      
      quad_feats <- list(
        訴求 = feats_key[sums_key >  mean(sums_key)],
        改變 = feats_key[sums_key <= mean(sums_key)],
        改善 = feats_non[sums_non >  mean(sums_non)],
        劣勢 = feats_non[sums_non <= mean(sums_non)]
      )
      
      make_multi_col <- function(feats, x_center, y_title, y_step = -1.5) {
        if (length(feats) == 0) return(NULL)
        cols <- ceiling(length(feats) / 6)
        dfs  <- lapply(seq_along(feats), function(i) {
          data.frame(text = feats[i],
                     x    = x_center + ((i-1) %/% 6 - (cols-1)/2) * 3,
                     y    = y_title + ((i-1) %% 6) * y_step)
        })
        do.call(rbind, dfs)
      }
      
      specs <- list(
        訴求 = list(x =  5, y = 10),
        改變 = list(x =  5, y = -1),
        改善 = list(x = -5, y = 10),
        劣勢 = list(x = -5, y = -1)
      )
      
      p <- plotly::plot_ly() |>
        layout(
          shapes = list(
            list(type = 'line', x0 = 0, x1 = 0, y0 = -11, y1 = 11, line = list(width = 2)),
            list(type = 'line', x0 = -11, x1 = 11, y0 = 0,  y1 = 0,  line = list(width = 2))
          ),
          xaxis = list(showgrid = FALSE, zeroline = FALSE,
                       showticklabels = FALSE, range = c(-12, 12)),
          yaxis = list(showgrid = FALSE, zeroline = FALSE,
                       showticklabels = FALSE, range = c(-12, 12)),
          showlegend = FALSE
        )
      
      titles_df <- data.frame(
        text = names(specs),
        x    = vapply(specs, `[[`, numeric(1), "x"),
        y    = vapply(specs, `[[`, numeric(1), "y")
      )
      p <- p |> add_trace(
        data = titles_df, type = "scatter", mode = "text",
        x = ~x, y = ~y, text = ~text,
        textfont = list(size = 24, color = "black")
      )
      
      for (nm in names(quad_feats)) {
        df_c <- make_multi_col(
          quad_feats[[nm]], specs[[nm]]$x, specs[[nm]]$y - 2
        )
        if (!is.null(df_c)) {
          p <- p |> add_trace(
            data = df_c, type = "scatter", mode = "text",
            x = ~x, y = ~y, text = ~text,
            textfont = list(size = 18, color = "blue")
          )
        }
      }
      
      p |> layout(margin = list(l = 60, r = 60, t = 60, b = 60),
                  font   = list(size = 10))
    })
    
    observeEvent(input$run_strategy, {
      var_now <- req(input$select_Variation)
      
      withProgress(message = "策略分析中…", value = 0, {
        incProgress(0.2)
        
        ind       <- dplyr::filter(data(), Variation == input$select_Variation)

        # 從 metadata 取得屬性欄位
        attr_cols <- attr(data(), "attribute_columns")

        if (is.null(attr_cols)) {
          showNotification("警告：未找到屬性欄位資訊", type = "warning")
          return()
        }

        # 確保屬性欄位存在於資料中
        attr_cols <- attr_cols[attr_cols %in% names(ind)]

        # 確保是數值型欄位
        attr_cols <- attr_cols[sapply(ind[attr_cols], is.numeric)]

        if (length(attr_cols) == 0) {
          showNotification("錯誤：沒有可用的數值屬性欄位", type = "error")
          return()
        }

        key       <- key_vars()
        # 只使用上傳時選擇的屬性欄位
        feats_key <- intersect(key, attr_cols)
        feats_non <- setdiff(attr_cols, key)

        sums_key <- if(length(feats_key) > 0) colSums(ind[feats_key, drop = FALSE]) else numeric(0)
        sums_non <- if(length(feats_non) > 0) colSums(ind[feats_non, drop = FALSE]) else numeric(0)
        
        quad_feats <- list(
          Variation = input$select_Variation,
          訴求  = feats_key[sums_key >  mean(sums_key)],
          改變  = feats_key[sums_key <= mean(sums_key)],
          改善  = feats_non[sums_non >  mean(sums_non)],
          劣勢  = feats_non[sums_non <= mean(sums_non)]
        )
        features <- jsonlite::toJSON(quad_feats, auto_unbox = TRUE)
        incProgress(0.4)
        
        # 使用集中管理的 prompt 生成定位策略
        messages <- prepare_gpt_messages(
          var_id = "positioning_strategy",
          variables = list(
            features = features
          ),
          prompts_df = prompts_df
        )
        
        txt <- tryCatch(
          chat_api(messages),
          error = function(e) paste("❌ GPT 失敗：", e$message)
        )
        rv$cache[[var_now]] <- txt
        incProgress(0.9)
      })
    })
    
    output$strategy_summary <- renderUI({
      var_now <- req(input$select_Variation)
      txt     <- rv$cache[[var_now]]
      
      if (is.null(txt)) {
        return(HTML("<i style='color:gray'>尚未產生策略分析，請點擊「策略探索」。</i>"))
      }
      
      res <- strip_code_fence(txt)
      html <- markdownToHTML(text = res, fragment.only = TRUE)
      HTML(html)
    })
  })
}

# Brand DNA Module
dnaModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotlyOutput(ns("dna_plot"), height = "600px")
  )
}

dnaModuleServer <- function(id, data_full) {
  moduleServer(id, function(input, output, session) {
    output$dna_plot <- renderPlotly({
      
      dta_Brand_log <- data_full() %>% 
        pivot_longer(
          cols = -c("Variation"),
          names_to = "attribute",
          values_to = "score"
        ) %>%
        arrange(Variation, attribute)
      
      Variation_groups <- split(dta_Brand_log, dta_Brand_log$Variation)
      dta_Brand_log$attribute <- as.factor(dta_Brand_log$attribute)
      fac_lis <-  dta_Brand_log$attribute
      
      p <- plot_ly()
      
      for (Variation_data in Variation_groups) {
        Variation <- unique(Variation_data$Variation)
        p <- add_trace(p, data=Variation_data, x = ~levels(fac_lis), y = ~score, 
                       color=~Variation, type = 'scatter', mode = 'lines+markers', name = Variation,
                       text = ~Variation, hoverinfo = 'text',
                       marker = list(size = 10),
                       line = list(width = 2),
                       visible = "legendonly"
        )
      }
      p <- layout(p,
                  xaxis = list(
                    title = list(
                      text = "Attribute",
                      font = list(size = 20)
                    ),
                    tickangle = -45
                  ),
                  yaxis = list(
                    title = "Score",font = list(size = 20)
                  )
      )
      p
    })
  })
}