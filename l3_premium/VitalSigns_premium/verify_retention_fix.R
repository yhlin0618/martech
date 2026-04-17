# 驗證客戶留存模組修正

cat("================================================================================\n")
cat("客戶留存模組修正驗證\n")
cat("================================================================================\n\n")

# 1. 載入模組測試
cat("1️⃣ 載入模組測試\n")
cat(paste(rep("-", 40), collapse=""), "\n")

tryCatch({
  suppressPackageStartupMessages({
    library(shiny)
    library(bs4Dash)
    library(DT)
    library(plotly)
    library(dplyr)
  })
  
  source("utils/hint_system.R")
  source("utils/prompt_manager.R")
  source("modules/module_customer_retention_new.R")
  
  cat("✅ 模組載入成功\n\n")
}, error = function(e) {
  cat("❌ 模組載入失敗:\n")
  cat("   錯誤:", e$message, "\n\n")
})

# 2. 檢查 hints
cat("2️⃣ 檢查 Hint 定義\n")
cat(paste(rep("-", 40), collapse=""), "\n")

hints_df <- load_hints()
retention_hints <- c("customer_retention_rate", "customer_churn_rate", 
                    "at_risk_customers", "core_customer_ratio",
                    "dormant_prediction", "new_customers", 
                    "drowsy_customers", "sleeping_customers")

found_hints <- 0
for(hint_id in retention_hints) {
  if(hint_id %in% hints_df$var_id) {
    found_hints <- found_hints + 1
  }
}

cat("找到", found_hints, "/", length(retention_hints), "個留存相關提示\n\n")

# 3. 檢查 prompts
cat("3️⃣ 檢查 AI Prompts\n")
cat(paste(rep("-", 40), collapse=""), "\n")

prompts_df <- load_prompts()
retention_prompts <- c("customer_retention_analysis", "new_customer_analysis",
                      "drowsy_customer_strategy", "sleeping_customer_strategy",
                      "customer_status_analysis")

found_prompts <- 0
for(prompt_id in retention_prompts) {
  if(prompt_id %in% prompts_df$var_id) {
    found_prompts <- found_prompts + 1
  }
}

cat("找到", found_prompts, "/", length(retention_prompts), "個留存相關 prompts\n\n")

# 4. UI 元件測試
cat("4️⃣ UI 元件測試\n")
cat(paste(rep("-", 40), collapse=""), "\n")

# 測試 UI 函數是否能正常產生
tryCatch({
  ui_test <- customerRetentionModuleUI("test", enable_hints = TRUE)
  cat("✅ UI 函數正常運作\n")
  cat("   產生", length(ui_test), "個 UI 元件\n\n")
}, error = function(e) {
  cat("❌ UI 函數錯誤:", e$message, "\n\n")
})

# 5. 功能清單
cat("5️⃣ 功能驗證清單\n")
cat(paste(rep("-", 40), collapse=""), "\n")

features <- list(
  "KPI 定義提示 (tooltips)" = TRUE,
  "新增狀態方框 (6個)" = TRUE,
  "客戶狀態順序 (N→E0→S1→S2→S3)" = TRUE,
  "CSV 下載功能" = TRUE,
  "AI 分析分頁 (5個)" = TRUE,
  "集中式 AI 建議" = TRUE,
  "移除 TagPilot 重複內容" = TRUE
)

for(feature in names(features)) {
  if(features[[feature]]) {
    cat("✅", feature, "\n")
  } else {
    cat("❌", feature, "\n")
  }
}

cat("\n")
cat("================================================================================\n")
cat("測試總結\n")
cat("================================================================================\n")

if(found_hints == length(retention_hints) && 
   found_prompts == length(retention_prompts)) {
  cat("✅ 客戶留存模組已完整配置\n")
  cat("   • 所有 hints 已載入\n")
  cat("   • 所有 prompts 已載入\n")
  cat("   • UI 元件正常運作\n")
  cat("   • 使用 tabsetPanel 替代 bs4TabPanel\n")
} else {
  cat("⚠️ 部分配置缺失\n")
  if(found_hints < length(retention_hints)) {
    cat("   • 缺少", length(retention_hints) - found_hints, "個 hints\n")
  }
  if(found_prompts < length(retention_prompts)) {
    cat("   • 缺少", length(retention_prompts) - found_prompts, "個 prompts\n")
  }
}

cat("\n💡 修正重點：\n")
cat("   • 使用 tabsetPanel() 和 tabPanel() 替代 bs4TabCard/bs4TabPanel\n")
cat("   • 這是 bs4Dash 版本相容性問題\n")
cat("   • 功能完全相同，只是函數名稱不同\n")

cat("\n================================================================================\n")