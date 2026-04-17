# 測試 Prompt 管理系統
# Test Prompt Management System

# 載入 prompt 管理系統
source("utils/prompt_manager.R")

cat("========================================\n")
cat("測試 Prompt 管理系統\n")
cat("========================================\n\n")

# 1. 測試載入 prompts
cat("1. 載入 Prompt 資料...\n")
prompts_df <- load_prompts()
cat(paste("  成功載入", nrow(prompts_df), "個 prompts\n\n"))

# 2. 列出所有可用的 prompts
cat("2. 可用的 Prompts：\n")
available <- list_available_prompts(prompts_df)
print(available)
cat("\n")

# 3. 測試取得特定 prompt
cat("3. 測試取得特定 Prompt...\n")
test_prompt <- get_prompt("extract_attributes", prompts_df)
cat("  屬性萃取 prompt 內容（前100字）：\n")
cat(paste("  ", substr(test_prompt, 1, 100), "...\n\n"))

# 4. 測試解析 prompt
cat("4. 測試解析 Prompt（分離 system 和 user）...\n")
parsed <- parse_prompt(test_prompt)
cat("  System prompt:", substr(parsed$system, 1, 50), "...\n")
cat("  User prompt:", substr(parsed$user, 1, 50), "...\n\n")

# 5. 測試變數替換
cat("5. 測試變數替換...\n")
variables <- list(
  num_attributes = 15,
  sample_reviews = "這個產品品質很好，價格合理..."
)

replaced_prompt <- replace_prompt_variables(test_prompt, variables)
cat("  替換後的 prompt（前150字）：\n")
cat(paste("  ", substr(replaced_prompt, 1, 150), "...\n\n"))

# 6. 測試準備 GPT 消息
cat("6. 測試準備 GPT 消息格式...\n")
messages <- prepare_gpt_messages(
  var_id = "extract_attributes",
  variables = variables,
  prompts_df = prompts_df
)

cat("  System role:", messages[[1]]$role, "\n")
cat("  System content（前50字）:", substr(messages[[1]]$content, 1, 50), "...\n")
cat("  User role:", messages[[2]]$role, "\n")
cat("  User content（前50字）:", substr(messages[[2]]$content, 1, 50), "...\n\n")

# 7. 測試不同的分析類型
cat("7. 測試其他分析類型的 Prompt...\n")

# 測試屬性評分
score_messages <- prepare_gpt_messages(
  var_id = "score_attributes",
  variables = list(
    attributes = "品質, 價格, 功能",
    review_text = "產品品質優秀，但價格偏高"
  ),
  prompts_df = prompts_df
)
cat("  屬性評分 prompt 準備完成\n")

# 測試品牌識別度策略
strategy_messages <- prepare_gpt_messages(
  var_id = "brand_identity_strategy",
  variables = list(
    brand_name = "測試品牌",
    unique_attributes = "創新性、環保、高品質"
  ),
  prompts_df = prompts_df
)
cat("  品牌策略 prompt 準備完成\n")

# 測試定位策略
positioning_messages <- prepare_gpt_messages(
  var_id = "positioning_strategy",
  variables = list(
    features = '{"訴求": ["品質", "創新"], "改善": ["價格"]}'
  ),
  prompts_df = prompts_df
)
cat("  定位策略 prompt 準備完成\n\n")

# 8. 測試錯誤處理
cat("8. 測試錯誤處理...\n")
tryCatch({
  invalid_prompt <- get_prompt("non_existent_id", prompts_df)
  if (is.null(invalid_prompt)) {
    cat("  ✓ 正確處理不存在的 var_id\n")
  }
}, error = function(e) {
  cat("  錯誤：", e$message, "\n")
})

# 9. 顯示統計資訊
cat("\n========================================\n")
cat("測試總結\n")
cat("========================================\n")
cat(paste("總共載入 prompts:", nrow(prompts_df), "\n"))
cat(paste("分析類型:", length(unique(prompts_df$analysis_name)), "\n"))
cat("所有測試完成！\n")

# 10. 示例：如何在實際應用中使用
cat("\n========================================\n")
cat("實際使用範例\n")
cat("========================================\n")
cat("
# 在您的模組中使用：
# 1. 在檔案開頭載入 prompt 管理系統
source('utils/prompt_manager.R')
prompts_df <- load_prompts()

# 2. 在需要使用 GPT 的地方
messages <- prepare_gpt_messages(
  var_id = 'extract_attributes',
  variables = list(
    num_attributes = input$num_attributes,
    sample_reviews = sample_text
  ),
  prompts_df = prompts_df
)

# 3. 執行 API 請求
response <- chat_api(messages)
")

cat("\n測試腳本執行完成！\n")