################################################################################
# 新品開發建議模組
################################################################################

#' 新品開發建議模組 UI
productDevModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統
  hints_df <- NULL
  if (exists("load_hints") && is.function(load_hints)) {
    hints_df <- load_hints()
  }
  
  fluidRow(
    bs4Card(
      title = "🚀 新品開發建議",
      status = "success",
      width = 12,
      solidHeader = TRUE,
      elevation = 3,
      
      fluidRow(
        column(12,
          p("基於市場屬性分析，提供新產品開發方向建議", style = "color: #666; margin-bottom: 20px;"),
          
          # 分析設定
          div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
            h5("🎯 開發策略設定"),
            fluidRow(
              column(4,
                selectInput(ns("dev_strategy"), "開發策略：",
                           choices = c("填補市場空缺" = "gap",
                                     "強化優勢領域" = "strength",
                                     "創新突破" = "innovation",
                                     "競品超越" = "compete"),
                           selected = "gap")
              ),
              column(4,
                selectInput(ns("target_segment"), "目標客群：",
                           choices = c("大眾市場" = "mass",
                                     "高端客群" = "premium",
                                     "年輕族群" = "young",
                                     "專業用戶" = "pro"),
                           selected = "mass")
              ),
              column(4,
                numericInput(ns("dev_priority"), "優先開發數量：",
                           value = 3, min = 1, max = 5, step = 1)
              )
            ),
            actionButton(ns("analyze_opportunities"), "分析開發機會",
                        class = "btn-success", icon = icon("lightbulb"))
          ),
          
          # 市場缺口分析
          uiOutput(ns("market_gaps")),
          
          # 新品建議
          uiOutput(ns("product_suggestions")),
          
          # 開發路線圖
          uiOutput(ns("development_roadmap"))
        )
      )
    )
  )
}

#' 新品開發建議模組 Server
productDevModuleServer <- function(id, scored_data, prompts_df = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # 儲存分析結果
    market_analysis <- reactiveVal(NULL)
    dev_suggestions <- reactiveVal(NULL)
    
    # 分析開發機會
    observeEvent(input$analyze_opportunities, {
      req(scored_data())
      
      showNotification("🔄 正在分析市場機會...", type = "message", duration = 3)
      
      tryCatch({
        # 計算所有品牌的屬性平均分
        attr_cols <- names(scored_data())[!names(scored_data()) %in% "Variation"]
        attr_cols <- attr_cols[sapply(scored_data()[attr_cols], is.numeric)]
        
        overall_mean <- scored_data() %>%
          summarise(across(all_of(attr_cols), \(x) mean(x, na.rm = TRUE)))
        
        # 找出低分屬性（市場缺口）
        attr_scores <- unlist(overall_mean)
        low_score_attrs <- names(attr_scores)[attr_scores < median(attr_scores)]
        high_score_attrs <- names(attr_scores)[attr_scores >= median(attr_scores)]
        
        # 根據策略生成建議
        if (input$dev_strategy == "gap") {
          focus_attrs <- low_score_attrs
          strategy_desc <- "填補市場空缺"
        } else if (input$dev_strategy == "strength") {
          focus_attrs <- high_score_attrs
          strategy_desc <- "強化優勢領域"
        } else {
          focus_attrs <- c(head(high_score_attrs, 2), head(low_score_attrs, 2))
          strategy_desc <- input$dev_strategy
        }
        
        # 使用集中式 Prompt 管理
        if (!is.null(prompts_df) && exists("prepare_gpt_messages")) {
          # 檢查 prompts_df 是否包含所需的 prompt
          if (!"product_development" %in% prompts_df$var_id) {
            # 使用備用方案
            dev_suggestions("根據分析，建議開發重點：\n1. 改進低分屬性\n2. 強化優勢領域\n3. 創新突破")
          } else {
            messages <- prepare_gpt_messages(
              var_id = "product_development",
              variables = list(
                strategy = strategy_desc,
                target_segment = input$target_segment,
                focus_attributes = paste(head(focus_attrs, 5), collapse = ", "),
                market_gaps = paste(low_score_attrs, collapse = ", "),
                strength_areas = paste(high_score_attrs, collapse = ", "),
                priority_count = input$dev_priority
              ),
              prompts_df = prompts_df
            )
            
            if (exists("chat_api")) {
              suggestions <- chat_api(messages)
              dev_suggestions(suggestions)
            } else {
              dev_suggestions("GPT API 未設定，使用基本建議")
            }
          }
        } else {
          # 沒有 prompt 管理系統的備用方案
          dev_suggestions("建議開發方向：\n• 填補市場缺口\n• 強化競爭優勢\n• 創新產品功能")
        }
        
        # 顯示市場缺口分析（根據策略調整顯示內容）
        output$market_gaps <- renderUI({
          # 根據策略決定顯示重點
          title_text <- switch(input$dev_strategy,
            "gap" = "📊 市場缺口分析（重點開發）",
            "strength" = "📊 競爭優勢分析（強化領域）",
            "innovation" = "📊 創新機會分析",
            "compete" = "📊 競品超越分析",
            "📊 市場機會分析"
          )
          
          # 根據策略調整顯示順序和內容
          if (input$dev_strategy == "gap") {
            # 缺口策略：優先顯示低分屬性
            content <- div(
              p(strong("🎯 重點改進屬性（市場缺口）：")),
              tags$ul(
                lapply(head(low_score_attrs, min(5, length(low_score_attrs))), function(attr) {
                  tags$li(
                    style = "color: #dc3545;",
                    paste(attr, "- 平均分:", round(attr_scores[attr], 2), "（急需改進）")
                  )
                })
              ),
              if (length(high_score_attrs) > 0) {
                tagList(
                  p(strong("✅ 現有優勢（保持）：")),
                  tags$ul(
                    lapply(head(high_score_attrs, 2), function(attr) {
                      tags$li(paste(attr, "- 平均分:", round(attr_scores[attr], 2)))
                    })
                  )
                )
              }
            )
          } else if (input$dev_strategy == "strength") {
            # 優勢策略：優先顯示高分屬性
            content <- div(
              p(strong("⭐ 核心優勢（繼續強化）：")),
              tags$ul(
                lapply(head(high_score_attrs, min(5, length(high_score_attrs))), function(attr) {
                  tags$li(
                    style = "color: #28a745;",
                    paste(attr, "- 平均分:", round(attr_scores[attr], 2), "（競爭優勢）")
                  )
                })
              ),
              if (length(low_score_attrs) > 0) {
                tagList(
                  p(strong("⚠️ 待改進領域：")),
                  tags$ul(
                    lapply(head(low_score_attrs, 2), function(attr) {
                      tags$li(paste(attr, "- 平均分:", round(attr_scores[attr], 2)))
                    })
                  )
                )
              }
            )
          } else {
            # 其他策略：平衡顯示
            content <- div(
              p(strong("市場缺口（低分屬性）：")),
              tags$ul(
                lapply(head(low_score_attrs, 3), function(attr) {
                  tags$li(paste(attr, "- 平均分:", round(attr_scores[attr], 2)))
                })
              ),
              p(strong("競爭優勢（高分屬性）：")),
              tags$ul(
                lapply(head(high_score_attrs, 3), function(attr) {
                  tags$li(paste(attr, "- 平均分:", round(attr_scores[attr], 2)))
                })
              )
            )
          }
          
          div(
            style = "background: #fff3cd; border: 1px solid #ffc107; border-radius: 8px; padding: 15px; margin-bottom: 20px;",
            h5(title_text, style = "color: #856404;"),
            div(style = "margin-top: 10px;", content),
            # 加入策略說明
            tags$hr(),
            p(
              style = "font-size: 0.9em; color: #666;",
              strong("當前策略："), 
              switch(input$dev_strategy,
                "gap" = "填補市場空缺 - 優先改進低分屬性",
                "strength" = "強化優勢領域 - 繼續提升高分屬性",
                "innovation" = "創新突破 - 結合優勢與改進",
                "compete" = "競品超越 - 全面提升競爭力",
                input$dev_strategy
              )
            )
          )
        })
        
        # 顯示新品建議
        output$product_suggestions <- renderUI({
          req(dev_suggestions())
          
          div(
            style = "background: #d4edda; border: 1px solid #28a745; border-radius: 8px; padding: 15px; margin-bottom: 20px;",
            h5("💡 新品開發建議", style = "color: #155724;"),
            div(
              style = "background: white; padding: 10px; border-radius: 5px; margin-top: 10px;",
              HTML(gsub("\n", "<br>", dev_suggestions()))
            )
          )
        })
        
        # 顯示開發路線圖（根據策略和選擇動態調整）
        output$development_roadmap <- renderUI({
          # 根據策略決定行動方向
          action_verb <- switch(input$dev_strategy,
            "gap" = "改進",
            "strength" = "強化",
            "innovation" = "創新",
            "compete" = "提升",
            "開發"
          )
          
          # 根據目標客群調整描述
          target_desc <- switch(input$target_segment,
            "mass" = "大眾市場",
            "premium" = "高端客群",
            "young" = "年輕族群",
            "pro" = "專業用戶",
            "目標客群"
          )
          
          div(
            style = "background: #e7f3ff; border: 1px solid #007bff; border-radius: 8px; padding: 15px;",
            h5(paste("🗓️ 開發優先順序 -", target_desc), style = "color: #004085;"),
            div(
              style = "margin-top: 10px;",
              tags$ol(
                lapply(1:min(input$dev_priority, length(focus_attrs)), function(i) {
                  # 根據策略設定不同的提升潛力範圍
                  potential_range <- switch(input$dev_strategy,
                    "gap" = c(30, 60),      # 缺口策略：高潛力
                    "strength" = c(20, 40),  # 優勢策略：穩定提升
                    "innovation" = c(40, 70), # 創新策略：高風險高回報
                    "compete" = c(25, 50),    # 競品策略：中等潛力
                    c(20, 50)
                  )
                  
                  # 設定不同優先級的顏色
                  priority_color <- if(i == 1) "#dc3545" else if(i == 2) "#ffc107" else "#28a745"
                  
                  tags$li(
                    style = paste0("margin-bottom: 10px; padding: 8px; background: rgba(0,123,255,0.05); border-left: 3px solid ", priority_color, ";"),
                    strong(paste("優先級", i, ":", action_verb, focus_attrs[i])),
                    tags$br(),
                    tags$small(
                      style = "color: #666;",
                      paste("• 目標客群：", target_desc),
                      tags$br(),
                      paste("• 預期提升潛力：", 
                           round(runif(1, potential_range[1], potential_range[2])), "%"),
                      tags$br(),
                      paste("• 建議週期：", 
                           if(i == 1) "3個月" else if(i == 2) "6個月" else "9個月")
                    )
                  )
                })
              ),
              # 加入總體時程建議
              tags$hr(),
              p(
                style = "font-size: 0.9em; color: #666; margin-top: 10px;",
                strong("💡 開發建議："),
                switch(input$dev_strategy,
                  "gap" = "優先填補市場空缺，快速回應客戶需求",
                  "strength" = "持續強化競爭優勢，鞏固市場地位",
                  "innovation" = "大膽創新，開創藍海市場",
                  "compete" = "對標競品，全面提升產品力",
                  "制定明確的產品開發策略"
                )
              )
            )
          )
        })
        
        showNotification("✅ 新品開發建議生成完成！", type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("分析失敗：", e$message), type = "error")
      })
    })
  })
}