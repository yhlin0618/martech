# 示例：使用 Prompt Manager 的屬性萃取功能
# 這是一個示例文件，展示如何將原有模組改為使用集中管理的 prompt

# 載入 prompt 管理系統
source("utils/prompt_manager.R")

# 載入所有 prompts（只需載入一次）
prompts_df <- load_prompts()

# ============================================
# 原始代碼（使用硬編碼的 prompt）
# ============================================
extract_attributes_old <- function(sample_reviews, num_attributes, chat_api) {
  # 原始方式：直接在代碼中定義 prompt
  sys <- list(role = "system", content = "你是產品屬性分析專家，專門從顧客評論中萃取重要產品屬性。")
  usr <- list(
    role = "user",
    content = paste0(
      "請從以下評論中萃取", num_attributes, "個最重要的產品屬性，",
      "這些屬性應該是顧客最在意且經常提及的。",
      "請以JSON格式回覆，格式為：{\"attributes\": [\"屬性1\", \"屬性2\", ...]}",
      "\n\n評論內容：", substr(sample_reviews, 1, 3000)
    )
  )
  
  response <- chat_api(list(sys, usr))
  return(response)
}

# ============================================
# 新代碼（使用集中管理的 prompt）
# ============================================
extract_attributes_new <- function(sample_reviews, num_attributes, chat_api) {
  # 新方式：使用集中管理的 prompt
  
  # 準備變數
  variables <- list(
    num_attributes = num_attributes,
    sample_reviews = substr(sample_reviews, 1, 3000)
  )
  
  # 從 prompt manager 取得消息
  messages <- prepare_gpt_messages(
    var_id = "extract_attributes",
    variables = variables,
    prompts_df = prompts_df
  )
  
  # 執行 API 請求
  response <- chat_api(messages)
  return(response)
}

# ============================================
# 更簡潔的方式（使用 execute_gpt_request）
# ============================================
extract_attributes_simple <- function(sample_reviews, num_attributes, chat_api) {
  # 最簡潔的方式：直接使用 execute_gpt_request
  
  response <- execute_gpt_request(
    var_id = "extract_attributes",
    variables = list(
      num_attributes = num_attributes,
      sample_reviews = substr(sample_reviews, 1, 3000)
    ),
    chat_api_function = chat_api,
    model = "gpt-4o-mini",
    max_tokens = 500,
    prompts_df = prompts_df
  )
  
  return(response)
}

# ============================================
# 在 Shiny 模組中的實際使用範例
# ============================================
attributeExtractionServer <- function(id, review_data) {
  moduleServer(id, function(input, output, session) {
    
    # 載入 prompt 管理系統（在模組初始化時）
    prompts_df <- load_prompts()
    
    observeEvent(input$generate_attributes, {
      req(review_data())
      
      withProgress(message = "分析評論產生屬性...", value = 0, {
        incProgress(0.3)
        
        # 取樣評論進行分析
        sample_reviews <- review_data() %>%
          sample_n(min(50, nrow(.))) %>%
          pull(Body) %>%
          paste(collapse = " ")
        
        incProgress(0.6)
        
        # 使用集中管理的 prompt
        messages <- prepare_gpt_messages(
          var_id = "extract_attributes",
          variables = list(
            num_attributes = input$num_attributes,
            sample_reviews = substr(sample_reviews, 1, 3000)
          ),
          prompts_df = prompts_df
        )
        
        response <- tryCatch(
          chat_api(messages),
          error = function(e) {
            # 錯誤處理
            paste0('{"attributes": ["品質", "價格", "功能", "外觀", "耐用性"]}')
          }
        )
        
        incProgress(0.9)
        
        # 解析結果...
      })
    })
  })
}

# ============================================
# 其他分析功能的轉換範例
# ============================================

# 屬性評分功能
score_attributes_new <- function(review_text, attributes, chat_api) {
  messages <- prepare_gpt_messages(
    var_id = "score_attributes",
    variables = list(
      attributes = paste(attributes, collapse = ", "),
      review_text = substr(review_text, 1, 1000)
    ),
    prompts_df = prompts_df
  )
  
  response <- chat_api(messages, max_tokens = 500)
  return(response)
}

# 品牌識別度策略生成
generate_brand_strategy_new <- function(brand_name, unique_attributes, chat_api) {
  messages <- prepare_gpt_messages(
    var_id = "brand_identity_strategy",
    variables = list(
      brand_name = brand_name,
      unique_attributes = paste(unique_attributes, collapse = "、")
    ),
    prompts_df = prompts_df
  )
  
  response <- chat_api(messages)
  return(response)
}

# 定位策略建議
generate_positioning_strategy_new <- function(features, chat_api) {
  messages <- prepare_gpt_messages(
    var_id = "positioning_strategy",
    variables = list(
      features = features
    ),
    prompts_df = prompts_df
  )
  
  response <- chat_api(messages)
  return(response)
}

# ============================================
# 工具函數：列出所有可用的 prompts
# ============================================
show_available_prompts <- function() {
  prompts <- list_available_prompts()
  print(prompts)
  return(prompts)
}

# ============================================
# 工具函數：動態更新 prompt
# ============================================
update_analysis_prompt <- function(var_id, new_prompt_text) {
  # 可以在運行時更新 prompt
  update_prompt(
    var_id = var_id,
    analysis_name = "Updated Analysis",
    prompt_text = new_prompt_text
  )
  
  # 重新載入 prompts
  prompts_df <<- load_prompts()
  message("Prompt updated and reloaded")
}