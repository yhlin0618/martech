# 測試整合後的 Prompt 管理系統
# Test Integrated Prompt Management System

cat("========================================\n")
cat("測試整合後的 Prompt 管理系統\n")
cat("========================================\n\n")

# 1. 測試載入模組
cat("1. 測試載入修改後的模組...\n")

tryCatch({
  # 載入必要的套件
  library(httr2)
  library(jsonlite)
  library(stringr)
  library(dplyr)
  
  # 測試載入 module_brandedge_flagship.R
  source("modules/module_brandedge_flagship.R")
  cat("  ✓ module_brandedge_flagship.R 載入成功\n")
  
  # 測試載入 module_wo_b.R
  source("modules/module_wo_b.R")
  cat("  ✓ module_wo_b.R 載入成功\n")
  
}, error = function(e) {
  cat("  ✗ 載入模組時發生錯誤：", e$message, "\n")
})

cat("\n")

# 2. 測試 prompt 管理系統
cat("2. 測試 Prompt 管理系統功能...\n")

# 確認 prompts_df 已載入
if (exists("prompts_df")) {
  cat("  ✓ prompts_df 已成功載入\n")
  cat(paste("    載入", nrow(prompts_df), "個 prompts\n"))
} else {
  cat("  ✗ prompts_df 未載入\n")
}

cat("\n")

# 3. 測試生成消息
cat("3. 測試生成 GPT 消息...\n")

# 測試屬性萃取
test_extract <- tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "extract_attributes",
    variables = list(
      num_attributes = 15,
      sample_reviews = "這是測試評論內容"
    ),
    prompts_df = prompts_df
  )
  cat("  ✓ 屬性萃取 prompt 生成成功\n")
  TRUE
}, error = function(e) {
  cat("  ✗ 屬性萃取 prompt 生成失敗：", e$message, "\n")
  FALSE
})

# 測試屬性評分
test_score <- tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "score_attributes",
    variables = list(
      attributes = "品質, 價格, 功能",
      review_text = "產品品質很好"
    ),
    prompts_df = prompts_df
  )
  cat("  ✓ 屬性評分 prompt 生成成功\n")
  TRUE
}, error = function(e) {
  cat("  ✗ 屬性評分 prompt 生成失敗：", e$message, "\n")
  FALSE
})

# 測試品牌策略
test_strategy <- tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "brand_identity_strategy",
    variables = list(
      brand_name = "測試品牌",
      unique_attributes = "創新、環保"
    ),
    prompts_df = prompts_df
  )
  cat("  ✓ 品牌策略 prompt 生成成功\n")
  TRUE
}, error = function(e) {
  cat("  ✗ 品牌策略 prompt 生成失敗：", e$message, "\n")
  FALSE
})

# 測試定位策略
test_positioning <- tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "positioning_strategy",
    variables = list(
      features = '{"訴求": ["品質"], "改善": ["價格"]}'
    ),
    prompts_df = prompts_df
  )
  cat("  ✓ 定位策略 prompt 生成成功\n")
  TRUE
}, error = function(e) {
  cat("  ✗ 定位策略 prompt 生成失敗：", e$message, "\n")
  FALSE
})

cat("\n")

# 4. 模擬 API 調用（不實際執行）
cat("4. 模擬 API 調用測試...\n")

# 創建模擬的 chat_api 函數
mock_chat_api <- function(messages, ...) {
  # 檢查消息格式
  if (length(messages) >= 2 && 
      messages[[1]]$role == "system" && 
      messages[[2]]$role == "user") {
    return("模擬回應：API 調用格式正確")
  } else {
    stop("消息格式不正確")
  }
}

# 測試調用
test_api_call <- tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "extract_attributes",
    variables = list(
      num_attributes = 10,
      sample_reviews = "測試內容"
    ),
    prompts_df = prompts_df
  )
  
  response <- mock_chat_api(messages)
  cat("  ✓ 模擬 API 調用成功\n")
  cat("    回應：", response, "\n")
  TRUE
}, error = function(e) {
  cat("  ✗ 模擬 API 調用失敗：", e$message, "\n")
  FALSE
})

cat("\n")

# 5. 總結
cat("========================================\n")
cat("測試總結\n")
cat("========================================\n")

total_tests <- 6
passed_tests <- sum(c(
  exists("prompts_df"),
  test_extract,
  test_score,
  test_strategy,
  test_positioning,
  test_api_call
))

cat(paste("通過測試：", passed_tests, "/", total_tests, "\n"))

if (passed_tests == total_tests) {
  cat("✓ 所有測試通過！Prompt 管理系統整合成功。\n")
} else {
  cat("⚠ 部分測試失敗，請檢查相關配置。\n")
}

cat("\n使用說明：\n")
cat("1. 所有 GPT prompts 現在都從 database/prompt.csv 載入\n")
cat("2. 使用 prepare_gpt_messages() 函數準備消息\n")
cat("3. 傳入 var_id 和需要的變數即可\n")
cat("4. 不需要在程式碼中硬編碼 prompt 內容\n")
cat("\n測試完成！\n")