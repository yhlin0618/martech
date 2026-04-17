################################################################################
# InsightForge 評分模組 v2 - 使用集中式 Prompt 管理
################################################################################

#' Attribute Generation & Scoring Module – UI
scoreModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統
  hints_df <- load_hints()
  
  div(id = ns("step2_box"),
    h4("步驟 2：產生屬性並評分"),
    
    # 1. 屬性數量選擇（加入提示）
    h5("1. 選擇屬性數量", add_info_icon("num_attributes", hints_df)),
    sliderInput(ns("num_attributes"), NULL, 
                min = 10, max = 30, value = 15, step = 1, ticks = FALSE),
    
    add_hint(
      actionButton(ns("gen_facets"), "產生屬性", class = "btn-secondary"),
      "gen_facets", hints_df
    ),
    verbatimTextOutput(ns("facet_msg")), 
    br(),
    
    # 2. 評論數量選擇（加入提示）
    h5("2. 選擇要分析的顧客評論則數", add_info_icon("nrows", hints_df)),
    sliderInput(ns("nrows"), NULL, 
                min = 10, max = 500, value = 50, step = 10, ticks = FALSE),
    
    # 3. 開始評分（加入提示）
    h5("3. 請點擊 [開始評分]"),
    add_hint(
      actionButton(ns("score"), "開始評分", class = "btn-primary"),
      "score_button", hints_df
    ),
    br(), br(),
    
    DTOutput(ns("score_tbl")), 
    br(),
    actionButton(ns("to_step3"), "下一步 ➡️", class = "btn-info")
  )
}

#' Attribute Generation & Scoring Module – Server
#' 使用集中式 Prompt 管理系統
scoreModuleServer <- function(id, con, user_info, raw_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # ── 載入 Prompt 管理系統 ──────────────────────────────────────────────
    prompts_df <- load_prompts()
    
    # ── 反應式變數 ────────────────────────────────────────────────────────
    facets_rv    <- reactiveVal(NULL)
    working_data <- reactiveVal(NULL)   # scored data output
    
    # 取得全域 regression_trigger
    regression_trigger <- session$userData$regression_trigger
    
    # ── 輔助函數 ──────────────────────────────────────────────────────────
    safe_value <- function(txt) {
      txt <- trimws(txt)
      num <- stringr::str_extract(txt, "[1-5]")
      if (!is.na(num)) return(as.numeric(num))
      val <- suppressWarnings(as.numeric(txt))
      if (!is.na(val) && val >= 1 && val <= 5) return(val)
      NA_real_
    }
    
    # ── 產生屬性 ──────────────────────────────────────────────────────────
    observeEvent(input$gen_facets, {
      dat <- raw_data()
      req(nrow(dat) > 0)
      
      # 顯示 progress bar
      shinyWidgets::progressSweetAlert(
        session = session,
        id = "facet_progress",
        title = "正在分析屬性...",
        display_pct = FALSE,
        value = 0
      )
      
      # 抽樣評論資料 - 每個 Variation 各抽 30 筆
      dat_sample <- dplyr::bind_rows(
        lapply(split(dat, dat$Variation), function(df) {
          df[sample(seq_len(nrow(df)), min(30, nrow(df))), , drop=FALSE]
        })
      )
      
      # 準備評論資料為 JSON
      sample_txt <- jsonlite::toJSON(dat_sample, dataframe = "rows", auto_unbox = TRUE)
      
      # 使用集中式 Prompt 管理系統
      messages <- tryCatch({
        prepare_gpt_messages(
          var_id = "extract_attributes",
          variables = list(
            num_attributes = input$num_attributes,
            sample_reviews = sample_txt
          ),
          prompts_df = prompts_df
        )
      }, error = function(e) {
        cat("❌ Prompt 準備失敗:", e$message, "\n")
        NULL
      })
      
      if (is.null(messages)) {
        shinyWidgets::closeSweetAlert(session = session)
        showNotification("❌ 無法準備 prompt", type = "error")
        return()
      }
      
      # 呼叫 chat API
      txt <- try(chat_api(messages), silent = TRUE)
      
      if (inherits(txt, "try-error")) {
        shinyWidgets::closeSweetAlert(session = session)
        showNotification(paste0("❌ 產生屬性失敗：", txt), type = "error", duration = 6)
        output$facet_msg <- renderText("⚠️ 產生屬性失敗，請重試")
        shinyjs::disable(ns("score"))
        return()
      }
      
      # 解析屬性
      attrs <- stringr::str_extract_all(txt, "[^{},，\\s]+")[[1]] |> 
               unique() |> 
               trimws()
      
      if (length(attrs) < input$num_attributes - 1) {
        shinyWidgets::closeSweetAlert(session = session)
        shinyjs::disable(ns("score"))
        output$facet_msg <- renderText("⚠️ 無法解析屬性，請重試")
        return()
      }
      
      # 儲存屬性
      facets_rv(attrs)
      shinyjs::enable(ns("score"))
      output$facet_msg <- renderText(
        sprintf("✅ 已產生 %d 個屬性：%s", 
                length(attrs), 
                paste(attrs, collapse = ", "))
      )
      
      shinyWidgets::closeSweetAlert(session = session)
      showNotification(
        sprintf("✅ 已產生 %d 個屬性！", length(attrs)), 
        type = "message", 
        duration = 3
      )
    })
    
    # ── 開始評分 ──────────────────────────────────────────────────────────
    observeEvent(input$score, {
      shinyjs::disable(ns("score"))
      
      attrs <- facets_rv()
      req(length(attrs) > 0)
      
      df0 <- raw_data()
      req(!is.null(df0))
      
      # 抽樣評論 - 每個 Variation 各抽 input$nrows 筆
      df <- dplyr::bind_rows(
        lapply(split(df0, df0$Variation), function(d) {
          n <- min(input$nrows, nrow(d))
          if (n == 0) return(NULL)
          d[sample(seq_len(nrow(d)), n), , drop=FALSE]
        })
      )
      
      total <- nrow(df)
      results_list <- vector("list", total)
      
      # 進度條
      withProgress(message = "評分中…", value = 0, {
        for (i in seq_len(total)) {
          row <- df[i, ]
          
          # 準備每個屬性的評分 prompts（使用集中管理）
          prompts <- lapply(attrs, function(a) {
            # 準備評論 JSON
            review_json <- jsonlite::toJSON(
              row[c("Variation", "Title", "Body")], 
              dataframe = "rows", 
              auto_unbox = TRUE
            )
            
            # 使用集中式 Prompt
            prepare_gpt_messages(
              var_id = "score_attribute",
              variables = list(
                review_json = review_json,
                attribute = a
              ),
              prompts_df = prompts_df
            )
          })
          
          # 平行呼叫 API
          res_vec <- furrr::future_map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          }, .options = furrr::furrr_options(seed = TRUE))
          
          # 解析分數
          vals <- purrr::map_dbl(res_vec, safe_value)
          scores_df <- as.data.frame(
            setNames(as.list(vals), attrs), 
            check.names = FALSE
          )
          scores_df <- cbind(Variation = row$Variation, scores_df)
          results_list[[i]] <- scores_df
          
          incProgress(1 / total)
        }
      })
      
      # 合併結果
      result_df <- dplyr::bind_rows(results_list)
      
      # 顯示評分結果
      show_df <- result_df[, c("Variation", attrs), drop = FALSE]
      output$score_tbl <- DT::renderDT(show_df, selection = "none")
      
      # 啟用下一步
      shinyjs::enable(ns("to_step3"))
      
      # 使用 prompt 產生總結（選擇性）
      if (nrow(result_df) > 0) {
        # 計算統計資料
        score_distribution <- sapply(result_df[attrs], mean, na.rm = TRUE)
        
        # 產生評分總結
        summary_messages <- prepare_gpt_messages(
          var_id = "scoring_summary",
          variables = list(
            total_reviews = nrow(result_df),
            num_variations = length(unique(result_df$Variation)),
            attributes = paste(attrs, collapse = ", "),
            score_distribution = paste(
              names(score_distribution), ":", 
              round(score_distribution, 2), 
              collapse = "; "
            )
          ),
          prompts_df = prompts_df
        )
        
        # 可選：呼叫 API 產生總結
        # summary_text <- try(chat_api(summary_messages), silent = TRUE)
        # if (!inherits(summary_text, "try-error")) {
        #   showNotification(summary_text, type = "message", duration = 10)
        # }
      }
      
      showNotification("✅ 評分完成並已存入 processed_data", type = "message")
      working_data(result_df)
    })
    
    # ── 下一步按鈕 ────────────────────────────────────────────────────────
    observeEvent(input$to_step3, {
      showNotification("➡️ 進入資料合併！", type = "message")
      if (!is.null(regression_trigger)) {
        regression_trigger(isolate(regression_trigger()) + 1)
      }
    })
    
    # ── 輸出 ──────────────────────────────────────────────────────────────
    list(
      scored_data = reactive(working_data()),
      proceed_step = reactive({ input$to_step3 })
    )
  })
}