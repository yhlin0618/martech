################################################################################
# InsightForge 分析模組 v2 - 使用集中式 Prompt 管理
################################################################################

# ── 載入必要套件 ────────────────────────────────────────────────────────────
library(httr2)
library(jsonlite)
library(stringr)

# ── 工具函數 ────────────────────────────────────────────────────────────────
strip_code_fence <- function(txt) {
  str_replace_all(
    txt,
    regex("^```[A-Za-z0-9]*[ \\t]*\\r?\\n|\\r?\\n```[ \\t]*$", multiline = TRUE),
    ""
  )
}

# ── Chat API 函數（核心） ───────────────────────────────────────────────────
#' 呼叫 OpenAI Chat API
#' @param messages 訊息列表，包含 system 和 user 角色
#' @param model GPT 模型名稱
#' @param api_key OpenAI API 金鑰
#' @param api_url API 端點
#' @param timeout_sec 超時秒數
#' @return API 回應的內容文字
chat_api <- function(messages,
                     model       = "gpt-4o-mini",
                     api_key     = Sys.getenv("OPENAI_API_KEY"),
                     api_url     = "https://api.openai.com/v1/chat/completions",
                     timeout_sec = 60) {
  
  if (!nzchar(api_key)) {
    stop("🔑 OPENAI_API_KEY 未設定")
  }
  
  # 準備請求 body
  body <- list(
    model       = model,
    messages    = messages,
    temperature = 0.3,
    max_tokens  = 1024
  )
  
  # 建立請求
  req <- request(api_url) |>
    req_auth_bearer_token(api_key) |>
    req_headers(`Content-Type` = "application/json") |>
    req_body_json(body) |>
    req_timeout(timeout_sec)
  
  # 執行請求
  resp <- req_perform(req)
  
  # 錯誤處理
  if (resp_status(resp) >= 400) {
    err <- resp_body_string(resp)
    stop(sprintf("Chat API error %s:\n%s", resp_status(resp), err))
  }
  
  # 解析回應
  content <- resp_body_json(resp)
  return(trimws(content$choices[[1]]$message$content))
}

# ── PCA 分析模組 ────────────────────────────────────────────────────────────
#' PCA Module UI
pcaModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統
  hints_df <- load_hints()
  
  tagList(
    # 加入 PCA 提示
    div(
      style = "margin-bottom: 15px;",
      h5("PCA 品牌定位分析", add_info_icon("pca_analysis", hints_df))
    ),
    uiOutput(ns("hint")),       # 顯示提示
    plotlyOutput(ns("pca_plot"))
  )
}

#' PCA Module Server
pcaModuleServer <- function(id, data, prompts_df = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # PCA 計算
    pca_res <- reactive({
      nums <- data()
      req(ncol(nums) >= 2)
      prcomp(nums, center = TRUE, scale. = TRUE, rank. = 3)
    })
    
    # 提示訊息
    output$hint <- renderUI({
      df <- data()
      if (ncol(df) < 2) {
        tags$div(
          style = "color:#888; padding: 10px; background: #f8f9fa; border-radius: 5px;",
          icon("info-circle"),
          " 請先從左側選好「分類／品牌／Variation」，並且該組資料至少有兩個數值欄，才能看到 PCA 結果。"
        )
      }
    })
    
    # PCA 圖表
    output$pca_plot <- renderPlotly({
      nums <- data()
      req(ncol(nums) >= 2)
      
      pc <- pca_res()
      scores   <- as.data.frame(pc$x)
      loadings <- as.data.frame(pc$rotation) * 5
      
      # 準備載荷向量資料
      load_long <- bind_rows(
        loadings %>% rownames_to_column("var") %>% mutate(PC1=0, PC2=0, PC3=0),
        loadings %>% rownames_to_column("var")
      )
      
      # 建立 3D 圖表
      plot_ly() %>%
        add_markers(
          data = scores, 
          x = ~PC1, y = ~PC2, z = ~PC3, 
          color = I("gray"),
          name = "品牌",
          text = rownames(scores),
          hovertemplate = "品牌: %{text}<br>PC1: %{x:.2f}<br>PC2: %{y:.2f}<br>PC3: %{z:.2f}"
        ) %>%
        add_lines(
          data = load_long, 
          x = ~PC1, y = ~PC2, z = ~PC3, 
          color = ~var,
          name = ~var,
          hovertemplate = "屬性: %{name}"
        ) %>%
        layout(
          scene = list(
            xaxis = list(title = sprintf("PC1 (%.1f%%)", summary(pc)$importance[2,1]*100)),
            yaxis = list(title = sprintf("PC2 (%.1f%%)", summary(pc)$importance[2,2]*100)),
            zaxis = list(title = sprintf("PC3 (%.1f%%)", summary(pc)$importance[2,3]*100))
          ),
          title = "品牌定位 3D 空間分析"
        )
    })
    
    # 可選：使用 Prompt 產生 PCA 解讀
    observe({
      req(pca_res())
      
      if (!is.null(prompts_df)) {
        pc <- pca_res()
        
        # 取得主成分貢獻最大的屬性
        get_top_attrs <- function(pc_col, n = 3) {
          loadings <- abs(pc$rotation[, pc_col])
          top_attrs <- names(sort(loadings, decreasing = TRUE)[1:n])
          paste(top_attrs, collapse = ", ")
        }
        
        # 準備 PCA 解讀的變數
        pca_interpretation <- prepare_gpt_messages(
          var_id = "pca_interpretation",
          variables = list(
            num_attrs = ncol(data()),
            pc1_var = round(summary(pc)$importance[2,1]*100, 1),
            pc2_var = round(summary(pc)$importance[2,2]*100, 1),
            pc3_var = round(summary(pc)$importance[2,3]*100, 1),
            pc1_attrs = get_top_attrs(1),
            pc2_attrs = get_top_attrs(2),
            pc3_attrs = get_top_attrs(3),
            brands_distribution = paste(rownames(pc$x), collapse = ", ")
          ),
          prompts_df = prompts_df
        )
        
        # 儲存解讀用的訊息（可供後續使用）
        session$userData$pca_interpretation_messages <- pca_interpretation
      }
    })
  })
}

# ── 理想產品分析模組 ────────────────────────────────────────────────────────
#' Ideal Analysis Module UI
idealModuleUI <- function(id) {
  ns <- NS(id)
  
  # 載入提示系統
  hints_df <- load_hints()
  
  tagList(
    # 加入理想產品提示
    div(
      style = "margin-bottom: 15px;",
      h5("理想產品分析 (MAMBA)", add_info_icon("ideal_analysis", hints_df))
    ),
    textOutput(ns("key_factors")),
    br(),
    br(),
    DTOutput(ns("ideal_rank"))
  )
}

#' Ideal Analysis Module Server
idealModuleServer <- function(id, data, prompts_df = NULL) {
  moduleServer(id, function(input, output, session) {
    
    # 理想產品分析
    ideal_analysis <- reactive({
      df <- data()
      req(nrow(df) > 0, ncol(df) > 0)
      
      # 計算每個屬性的理想值（最大值）
      ideal_values <- apply(df, 2, max, na.rm = TRUE)
      
      # 計算每個品牌達到理想值的屬性數量
      ideal_scores <- apply(df, 1, function(row) {
        sum(row >= ideal_values, na.rm = TRUE)
      })
      
      # 建立結果資料框
      result <- data.frame(
        品牌 = rownames(df),
        理想分數 = ideal_scores,
        滿分 = ncol(df),
        達成率 = round(ideal_scores / ncol(df) * 100, 1),
        stringsAsFactors = FALSE
      )
      
      # 加入每個品牌的優勢與劣勢屬性
      result$優勢屬性 <- apply(df, 1, function(row) {
        achieved <- names(row)[row >= ideal_values]
        if (length(achieved) > 0) {
          paste(achieved[1:min(3, length(achieved))], collapse = ", ")
        } else {
          "無"
        }
      })
      
      result$待改進屬性 <- apply(df, 1, function(row) {
        gaps <- names(row)[row < ideal_values]
        if (length(gaps) > 0) {
          paste(gaps[1:min(3, length(gaps))], collapse = ", ")
        } else {
          "無"
        }
      })
      
      # 排序
      result <- result[order(result$理想分數, decreasing = TRUE), ]
      
      return(result)
    })
    
    # 顯示關鍵因素
    output$key_factors <- renderText({
      df <- data()
      if (nrow(df) == 0 || ncol(df) == 0) {
        return("請先選擇資料")
      }
      
      # 計算屬性的平均分數，找出最重要的屬性
      avg_scores <- colMeans(df, na.rm = TRUE)
      top_attrs <- names(sort(avg_scores, decreasing = TRUE)[1:min(5, length(avg_scores))])
      
      paste("關鍵成功因素：", paste(top_attrs, collapse = " > "))
    })
    
    # 顯示理想產品排名表
    output$ideal_rank <- renderDT({
      ideal_analysis()
    }, options = list(
      pageLength = 10,
      dom = 'ftip',
      language = list(
        search = "搜尋：",
        lengthMenu = "顯示 _MENU_ 筆",
        info = "第 _START_ 至 _END_ 筆，共 _TOTAL_ 筆",
        paginate = list(
          previous = "上一頁",
          `next` = "下一頁"
        )
      )
    ))
    
    # 可選：使用 Prompt 產生理想產品策略建議
    observe({
      req(ideal_analysis())
      
      if (!is.null(prompts_df) && nrow(ideal_analysis()) > 0) {
        # 為第一名品牌產生策略建議
        top_brand <- ideal_analysis()[1, ]
        
        ideal_strategy <- prepare_gpt_messages(
          var_id = "ideal_analysis",
          variables = list(
            brand_name = top_brand$品牌,
            total_score = top_brand$理想分數,
            max_score = top_brand$滿分,
            achieved_attrs = top_brand$優勢屬性,
            gap_attrs = top_brand$待改進屬性
          ),
          prompts_df = prompts_df
        )
        
        # 儲存策略建議用的訊息
        session$userData$ideal_strategy_messages <- ideal_strategy
      }
    })
  })
}

# ── 匯出模組 ────────────────────────────────────────────────────────────────
# 提供給主程式使用的函數
wo_b_module_exports <- list(
  chat_api = chat_api,
  strip_code_fence = strip_code_fence,
  pcaModuleUI = pcaModuleUI,
  pcaModuleServer = pcaModuleServer,
  idealModuleUI = idealModuleUI,
  idealModuleServer = idealModuleServer
)