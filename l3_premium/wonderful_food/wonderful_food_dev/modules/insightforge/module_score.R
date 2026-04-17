################################################################################
# 3⃣  module_score.R -----------------------------------------------------------
################################################################################

#' Attribute Generation & Scoring Module – UI
scoreModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統（如果存在）
  hints_df <- NULL
  if (exists("load_hints") && is.function(load_hints)) {
    hints_df <- load_hints()
  }
  
  div(id = ns("step2_box"),
      h4("步驟 2：產生屬性並評分"),
      
      # 1. 屬性數量選擇（加入提示）
      h5("1. 選擇屬性數量", 
         if (!is.null(hints_df) && exists("add_info_icon")) {
           add_info_icon("num_attributes", hints_df)
         }),
      sliderInput(ns("num_attributes"), "屬性數量", 
                  min = 10, max = 30, value = 15, step = 1, ticks = FALSE),
      
      # 產生屬性按鈕（加入提示）
      if (!is.null(hints_df) && exists("add_hint")) {
        add_hint(
          actionButton(ns("gen_facets"), "產生屬性", class = "btn-secondary"),
          "gen_facets", hints_df
        )
      } else {
        actionButton(ns("gen_facets"), "產生屬性", class = "btn-secondary")
      },
      verbatimTextOutput(ns("facet_msg")), br(),
      
      # 2. 評論數量選擇（加入提示）
      h5("2. 選擇要分析的顧客評論則數",
         if (!is.null(hints_df) && exists("add_info_icon")) {
           add_info_icon("nrows", hints_df)
         }),
      sliderInput(ns("nrows"), "取前幾列 (評分)", min = 10, max = 500, value = 50, step = 10, ticks = FALSE),
      
      # 3. 開始評分（加入提示）
      h5("3. 請點擊 [開始評分]"),
      if (!is.null(hints_df) && exists("add_hint")) {
        add_hint(
          actionButton(ns("score"), "開始評分", class = "btn-primary"),
          "score_button", hints_df
        )
      } else {
        actionButton(ns("score"), "開始評分", class = "btn-primary")
      },
      br(), br(),
      DTOutput(ns("score_tbl")), br(),
      actionButton(ns("to_step3"), "下一步 ➡️", class = "btn-info")
  )
}

#' Attribute Generation & Scoring Module – Server
#'
#' @param raw_data reactive – data.frame from upload module
#' @return reactive containing the scored data.frame
scoreModuleServer <- function(id, con, user_info, raw_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    facets_rv    <- reactiveVal(NULL)
    working_data <- reactiveVal(NULL)   # scored data output
    # 取得全域 regression_trigger
    regression_trigger <- session$userData$regression_trigger
    
    # 載入 Prompt 管理系統（如果存在）
    prompts_df <- NULL
    if (exists("load_prompts") && is.function(load_prompts)) {
      prompts_df <- load_prompts()
    }
    
    # helpers
    safe_value <- function(txt) {
      txt <- trimws(txt)
      num <- stringr::str_extract(txt, "[1-5]")
      if (!is.na(num)) return(as.numeric(num))
      val <- suppressWarnings(as.numeric(txt))
      if (!is.na(val) && val >= 1 && val <= 5) return(val)
      NA_real_
    }
    
    # ---------------------------------------------------------------------
    observeEvent(input$gen_facets, {
      dat <- raw_data(); req(nrow(dat) > 0)
      # 顯示 progress bar
      shinyWidgets::progressSweetAlert(
        session = session,
        id = "facet_progress",
        title = "正在分析屬性...",
        display_pct = FALSE,
        value = 0
      )
      # by Variation 各抽 30 筆
      dat_sample <- dplyr::bind_rows(
        lapply(split(dat, dat$Variation), function(df) df[sample(seq_len(nrow(df)), min(30, nrow(df))), , drop=FALSE])
      )
      # 合併後送給 LLM
      sample_txt <- jsonlite::toJSON(dat_sample, dataframe = "rows", auto_unbox = TRUE)
      
      # 使用集中式 Prompt 管理（如果存在）
      if (!is.null(prompts_df) && exists("prepare_gpt_messages")) {
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
          # 如果 prompt 管理失敗，使用原始方式
          list(
            list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
            list(role = "user",
                 content = paste0(
                   "請針對以下各顧客評論中，從產品定位理論中的屬性、功能、利益和用途等特質，探勘出與該產品最重要、且出現次數最高的 ", input$num_attributes, " 個正面描述且具體的特質，並依照該特質出現頻率進行排序",
                   "輸出格式為 {屬性1 , 屬性2 , … , 屬性", input$num_attributes, "} 。禁止出現其他文字。\n\n評論：\n",
                   sample_txt))
          )
        })
      } else {
        # 使用原始方式
        messages <- list(
          list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
          list(role = "user",
               content = paste0(
                 "請針對以下各顧客評論中，從產品定位理論中的屬性、功能、利益和用途等特質，探勘出與該產品最重要、且出現次數最高的 ", input$num_attributes, " 個正面描述且具體的特質，並依照該特質出現頻率進行排序",
                 "輸出格式為 {屬性1 , 屬性2 , … , 屬性", input$num_attributes, "} 。禁止出現其他文字。\n\n評論：\n",
                 sample_txt))
        )
      }
      
      # 捕捉錯誤
      txt <- try(chat_api(messages), silent = TRUE)
      if (inherits(txt, "try-error")) {
        shinyWidgets::closeSweetAlert(session = session)
        showNotification(paste0("❌ 產生屬性失敗：", txt), type = "error", duration = 6)
        output$facet_msg <- renderText("⚠️ 產生屬性失敗，請重試")
        shinyjs::disable(ns("score"))
        return()
      }
      attrs <- stringr::str_extract_all(txt, "[^{},，\\s]+")[[1]] |> unique() |> trimws()
      if (length(attrs) < input$num_attributes - 1) {
        shinyWidgets::closeSweetAlert(session = session)
        shinyjs::disable(ns("score"))
        return(output$facet_msg <- renderText("⚠️ 無法解析屬性，請重試"))
      }
      facets_rv(attrs)
      shinyjs::enable(ns("score"))
      output$facet_msg <- renderText(sprintf("✅ 已產生 %d 個屬性：%s", length(attrs), paste(attrs, collapse = ", ")))
      shinyWidgets::closeSweetAlert(session = session)
      showNotification(sprintf("✅ 已產生 %d 個屬性！", length(attrs)), type = "message", duration = 3)
    })
    
    # ---------------------------------------------------------------------
    observeEvent(input$score, {
      shinyjs::disable(ns("score"))
      attrs <- facets_rv(); req(length(attrs) > 0)
      df0   <- raw_data();  req(!is.null(df0))
      # by Variation 各抽 input$nrows 筆（每個 Variation/asin 各自抽 input$nrows 筆）
      df <- dplyr::bind_rows(
        lapply(split(df0, df0$Variation), function(d) {
          n <- min(input$nrows, nrow(d))
          if (n == 0) return(NULL)
          d[sample(seq_len(nrow(d)), n), , drop=FALSE]
        })
      )
      total <- nrow(df)
      results_list <- vector("list", total)
      withProgress(message = "評分中…", value = 0, {
        for (i in seq_len(total)) {
          row <- df[i, ]
          
          # 準備每個屬性的評分 prompts
          prompts <- lapply(attrs, function(a) {
            review_json <- jsonlite::toJSON(row[c("Variation","Title","Body")], dataframe = "rows", auto_unbox = TRUE)
            
            # 使用集中式 Prompt 管理（如果存在）
            if (!is.null(prompts_df) && exists("prepare_gpt_messages")) {
              tryCatch({
                prepare_gpt_messages(
                  var_id = "score_attribute",
                  variables = list(
                    review_json = review_json,
                    attribute = a
                  ),
                  prompts_df = prompts_df
                )
              }, error = function(e) {
                # 如果 prompt 管理失敗，使用原始方式
                list(
                  list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
                  list(role = "user", content = sprintf("以下 JSON：%s請只回%s:<1-5或無>", review_json, a))
                )
              })
            } else {
              # 使用原始方式
              list(
                list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
                list(role = "user", content = sprintf("以下 JSON：%s請只回%s:<1-5或無>", review_json, a))
              )
            }
          })
          
          # parallel calls
          res_vec <- furrr::future_map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          }, .options = furrr_options(seed = TRUE))
          vals <- purrr::map_dbl(res_vec, safe_value)
          scores_df  <- as.data.frame(setNames(as.list(vals), attrs), check.names = FALSE)
          scores_df  <- cbind(Variation = row$Variation, scores_df)
          results_list[[i]] <- scores_df
          incProgress(1 / total)
        }
      })
      result_df  <- dplyr::bind_rows(results_list)
      # scoring頁面：只顯示所有評分結果（不做group by mean）
      show_df <- result_df[, c("Variation", attrs), drop = FALSE]
      output$score_tbl <- DT::renderDT(show_df, selection = "none")
      shinyjs::enable(ns("to_step3"))
      showNotification("✅ 評分完成並已存入 processed_data", type = "message")
      working_data(result_df)
    })
    
    # ---------------------------------------------------------------------
    # 下一步按鈕觸發事件（切換到回歸資料合併分頁）
    observeEvent(input$to_step3, {
      showNotification("➡️ 進入資料合併！", type = "message")
      if (!is.null(regression_trigger)) {
        regression_trigger(isolate(regression_trigger()) + 1)
      }
    })
    
    list(
      scored_data = reactive(working_data()),
      proceed_step = reactive({ input$to_step3 })
    )
  })
}