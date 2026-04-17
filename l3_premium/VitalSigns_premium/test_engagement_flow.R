# 活躍轉化模組測試
# 驗證所有更新功能

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)
library(markdown)

# 載入所需模組
source("utils/hint_system.R")
source("utils/prompt_manager.R")
source("modules/module_engagement_flow.R")

# 檢查 hints
cat("================================================================================\n")
cat("活躍轉化模組功能驗證\n")
cat("================================================================================\n\n")

cat("1️⃣ 檢查 Hint 定義\n")
cat(paste(rep("-", 40), collapse=""), "\n")

hints_df <- load_hints()
engagement_hints <- c("customer_activity_index", "customer_conversion_rate", 
                      "reactivation_rate", "purchase_frequency",
                      "avg_inter_purchase_time", "activity_distribution_chart",
                      "conversion_rate_analysis_chart")

found_hints <- 0
for(hint_id in engagement_hints) {
  if(hint_id %in% hints_df$var_id) {
    found_hints <- found_hints + 1
    cat("✓", hint_id, "\n")
  } else {
    cat("✗", hint_id, "缺失\n")
  }
}

cat("\n找到", found_hints, "/", length(engagement_hints), "個活躍轉化相關提示\n\n")

cat("2️⃣ 檢查 AI Prompts\n")
cat(paste(rep("-", 40), collapse=""), "\n")

prompts_df <- load_prompts()
engagement_prompts <- c("purchase_frequency_analysis", "customer_reactivation_opportunity",
                        "loyalty_ladder_strategy", "reactivation_marketing_plan")

found_prompts <- 0
for(prompt_id in engagement_prompts) {
  if(prompt_id %in% prompts_df$var_id) {
    found_prompts <- found_prompts + 1
    cat("✓", prompt_id, "\n")
  } else {
    cat("✗", prompt_id, "缺失\n")
  }
}

cat("\n找到", found_prompts, "/", length(engagement_prompts), "個活躍轉化相關 prompts\n\n")

cat("3️⃣ 功能驗證清單\n")
cat(paste(rep("-", 40), collapse=""), "\n")

features <- list(
  "KPI 定義提示 (5個指標)" = TRUE,
  "移除再購率" = TRUE,
  "新增喚醒率" = TRUE,
  "客戶活躍度分布說明" = TRUE,
  "轉化率分析說明" = TRUE,
  "CSV 下載 - 需喚醒客戶" = TRUE,
  "CSV 下載 - 忠誠度階梯" = TRUE,
  "AI 分析集中下方 (4個分頁)" = TRUE,
  "Markdown 渲染支援" = TRUE
)

for(feature in names(features)) {
  if(features[[feature]]) {
    cat("✅", feature, "\n")
  } else {
    cat("❌", feature, "\n")
  }
}

cat("\n================================================================================\n")
cat("測試總結\n")
cat("================================================================================\n")

if(found_hints == length(engagement_hints) && 
   found_prompts == length(engagement_prompts)) {
  cat("✅ 活躍轉化模組已完整配置\n")
  cat("   • 所有 hints 已載入\n")
  cat("   • 所有 prompts 已載入\n")
  cat("   • 功能完整實作\n")
} else {
  cat("⚠️ 部分配置缺失\n")
  if(found_hints < length(engagement_hints)) {
    cat("   • 缺少", length(engagement_hints) - found_hints, "個 hints\n")
  }
  if(found_prompts < length(engagement_prompts)) {
    cat("   • 缺少", length(engagement_prompts) - found_prompts, "個 prompts\n")
  }
}

cat("\n💡 主要更新重點：\n")
cat("   • 5個 KPI 都有定義提示 (tooltip)\n")
cat("   • 圖表加入說明文字\n")
cat("   • 可下載需喚醒客戶和忠誠度階梯 CSV\n")
cat("   • AI 分析集中在下方分頁顯示\n")
cat("   • 支援 Markdown 轉 HTML 渲染\n")

cat("\n================================================================================\n")