################################################################################
# 關鍵字廣告投放建議模組
################################################################################

#' 關鍵字廣告建議模組 UI
keywordAdsModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統（如果存在）
  hints_df <- NULL
  if (exists("load_hints") && is.function(load_hints)) {
    hints_df <- load_hints()
  }
  
  fluidRow(
    bs4Card(
      title = "🔍 關鍵字廣告投放建議",
      status = "info",
      width = 12,
      solidHeader = TRUE,
      elevation = 3,
      
      fluidRow(
        column(12,
          p("根據產品屬性分析結果，建議最佳關鍵字廣告策略", style = "color: #666; margin-bottom: 20px;"),
          
          # 分析控制區
          div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
            h5("📋 分析設定"),
            fluidRow(
              column(4,
                selectInput(ns("keyword_brand"), "選擇品牌/產品：", choices = NULL)
              ),
              column(4,
                numericInput(ns("keyword_count"), "建議關鍵字數量：", 
                           value = 10, min = 5, max = 20, step = 1)
              ),
              column(4,
                selectInput(ns("keyword_platform"), "廣告平台：",
                           choices = c("Google Ads" = "google",
                                     "Facebook Ads" = "facebook",
                                     "全平台" = "all"),
                           selected = "google")
              )
            ),
            actionButton(ns("generate_keywords"), "生成關鍵字建議", 
                        class = "btn-primary", icon = icon("search"))
          ),
          
          # 結果顯示區
          uiOutput(ns("keyword_results")),
          
          # 下載報告
          div(
            style = "margin-top: 20px;",
            downloadButton(ns("download_keywords"), "下載關鍵字報告", 
                          class = "btn-secondary")
          )
        )
      )
    )
  )
}

#' 關鍵字廣告建議模組 Server
keywordAdsModuleServer <- function(id, scored_data, prompts_df = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 儲存關鍵字建議結果
    keyword_suggestions <- reactiveVal(NULL)
    
    # 更新品牌選擇列表
    observe({
      req(scored_data())
      variations <- unique(scored_data()$Variation)
      updateSelectInput(session, "keyword_brand", choices = variations)
    })
    
    # 生成關鍵字建議
    observeEvent(input$generate_keywords, {
      req(input$keyword_brand, scored_data())
      
      showNotification("🔄 正在分析關鍵字...", type = "message", duration = 3)
      
      tryCatch({
        # 取得品牌評分資料
        brand_data <- scored_data() %>%
          filter(Variation == input$keyword_brand)
        
        # 計算各屬性平均分
        attr_cols <- names(brand_data)[!names(brand_data) %in% "Variation"]
        attr_cols <- attr_cols[sapply(brand_data[attr_cols], is.numeric)]
        
        brand_mean <- brand_data %>%
          summarise(across(all_of(attr_cols), \(x) mean(x, na.rm = TRUE)))
        
        # 排序屬性（由高到低）
        attr_scores <- sort(unlist(brand_mean), decreasing = TRUE)
        top_attrs <- names(head(attr_scores, 5))
        
        # 使用集中式 Prompt 管理生成關鍵字
        if (!is.null(prompts_df) && exists("prepare_gpt_messages")) {
          # 檢查 prompts_df 是否包含所需的 prompt
          if (!"keyword_generation" %in% prompts_df$var_id) {
            # 如果沒有找到 prompt，使用備用方案
            basic_keywords <- generate_basic_keywords(input$keyword_brand, top_attrs)
            keyword_suggestions(basic_keywords)
            output$keyword_results <- renderUI({
              div(
                style = "background: white; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px;",
                h5("📌 關鍵字建議（基本版）", style = "color: #2c3e50; margin-bottom: 15px;"),
                div(
                  style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
                  HTML(gsub("\n", "<br>", basic_keywords))
                )
              )
            })
            showNotification("使用基本關鍵字生成", type = "message", duration = 3)
            return()
          }
          
          messages <- prepare_gpt_messages(
            var_id = "keyword_generation",
            variables = list(
              brand_name = input$keyword_brand,
              top_attributes = paste(top_attrs, collapse = ", "),
              keyword_count = input$keyword_count,
              platform = input$keyword_platform,
              avg_score = round(mean(attr_scores), 2)
            ),
            prompts_df = prompts_df
          )
          
          # 呼叫 GPT API
          if (exists("chat_api")) {
            keyword_text <- chat_api(messages)
            keyword_suggestions(keyword_text)
          } else {
            # 備用方案：生成基本關鍵字
            basic_keywords <- generate_basic_keywords(input$keyword_brand, top_attrs)
            keyword_suggestions(basic_keywords)
          }
        } else {
          # 沒有 Prompt 管理的備用方案
          basic_keywords <- generate_basic_keywords(input$keyword_brand, top_attrs)
          keyword_suggestions(basic_keywords)
        }
        
        # 顯示結果
        output$keyword_results <- renderUI({
          req(keyword_suggestions())
          
          div(
            style = "background: white; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px;",
            h5("📌 關鍵字廣告建議", style = "color: #2c3e50; margin-bottom: 15px;"),
            
            # 關鍵屬性
            div(
              style = "background: #e8f4f8; padding: 10px; border-radius: 5px; margin-bottom: 15px;",
              strong("核心優勢屬性："),
              p(paste(top_attrs, collapse = " | "), style = "margin-top: 5px;")
            ),
            
            # 關鍵字建議
            div(
              style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
              HTML(gsub("\n", "<br>", keyword_suggestions()))
            )
          )
        })
        
        showNotification("✅ 關鍵字建議生成完成！", type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("生成失敗：", e$message), type = "error")
        output$keyword_results <- renderUI({
          div(class = "alert alert-danger", paste("錯誤：", e$message))
        })
      })
    })
    
    # 下載功能
    output$download_keywords <- downloadHandler(
      filename = function() {
        paste0("keyword_ads_", input$keyword_brand, "_", Sys.Date(), ".txt")
      },
      content = function(file) {
        writeLines(keyword_suggestions() %||% "尚無關鍵字建議", file)
      }
    )
    
    # 輔助函數：生成基本關鍵字
    generate_basic_keywords <- function(brand, attrs) {
      keywords <- c(
        paste(brand, "評價"),
        paste(brand, "推薦"),
        paste(brand, "比較"),
        paste(attrs, brand),
        paste("最佳", attrs),
        paste(attrs, "產品")
      )
      paste("建議關鍵字：\n", paste("• ", keywords, collapse = "\n"))
    }
  })
}