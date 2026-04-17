# 測試 NA 值修正和 Markdown 格式顯示

library(dplyr)

cat("================================================================================\n")
cat("測試營收脈能 NA 值處理和 Markdown 格式\n")
cat("================================================================================\n\n")

# 1. 測試 NA 值處理
cat("1️⃣ 測試 NA 值處理\n")
cat(paste(rep("-", 40), collapse=""), "\n")

# 模擬有 NA 的數據
test_data <- c(NA, 5, 10, NA, 15, NA)
recent_data <- c(NA, NA, NA)

# 原始可能出錯的邏輯
cat("原始數據:", paste(test_data, collapse=", "), "\n")
cat("最近數據:", paste(recent_data, collapse=", "), "\n")

avg_growth <- mean(test_data, na.rm = TRUE)
recent_avg <- mean(recent_data, na.rm = TRUE)

cat("平均值:", avg_growth, "\n")
cat("最近平均:", recent_avg, "\n")

# 測試修正後的邏輯
trend_direction <- if(!is.na(recent_avg) && !is.na(avg_growth)) {
  if(recent_avg > avg_growth) "上升" else "下降"
} else {
  "穩定"
}

cat("趨勢判斷:", trend_direction, "\n")

# 處理 infinite 值
max_val <- max(test_data, na.rm = TRUE)
min_val <- min(test_data, na.rm = TRUE)

cat("最大值 (原始):", max_val, "\n")
cat("最小值 (原始):", min_val, "\n")

# 修正後的處理
max_val <- if(is.na(max_val) || is.infinite(max_val)) 0 else max_val
min_val <- if(is.na(min_val) || is.infinite(min_val)) 0 else min_val

cat("最大值 (修正):", max_val, "\n")
cat("最小值 (修正):", min_val, "\n\n")

# 2. 測試全部都是 NA 的情況
cat("2️⃣ 測試全 NA 數據\n")
cat(paste(rep("-", 40), collapse=""), "\n")

all_na_data <- c(NA, NA, NA)
avg_all_na <- mean(all_na_data, na.rm = TRUE)
cat("全 NA 平均值:", avg_all_na, "\n")
cat("是否為 NaN:", is.nan(avg_all_na), "\n")

# 修正處理
avg_all_na <- if(is.na(avg_all_na) || is.nan(avg_all_na)) 0 else avg_all_na
cat("修正後:", avg_all_na, "\n\n")

# 3. 測試 Markdown 格式
cat("3️⃣ 測試 Markdown 格式轉換\n")
cat(paste(rep("-", 40), collapse=""), "\n")

# 載入 markdown 套件
if(!require(markdown)) {
  install.packages("markdown")
  library(markdown)
}

# 測試 Markdown 文本
test_md <- "## 分析結果

**重點發現：**
- 新客戶平均客單價：$1,500
- 主力客戶平均客單價：$4,500
- 成長率：**15%**

### 建議策略
1. 提升新客價值
2. 深化主力客戶經營"

cat("原始 Markdown:\n")
cat(test_md, "\n\n")

# 轉換為 HTML
html_output <- markdownToHTML(text = test_md, fragment.only = TRUE)
cat("轉換後的 HTML (前200字):\n")
cat(substr(html_output, 1, 200), "...\n\n")

# 測試檢測是否包含 Markdown
has_markdown <- grepl("\\n\\n|\\*\\*|##", test_md)
cat("檢測到 Markdown 格式:", has_markdown, "\n")

# 測試普通文本
plain_text <- "這是普通文本，沒有特殊格式"
has_markdown_plain <- grepl("\\n\\n|\\*\\*|##", plain_text)
cat("普通文本檢測:", has_markdown_plain, "\n\n")

cat("================================================================================\n")
cat("測試總結\n")
cat("================================================================================\n")
cat("✅ NA 值處理：使用條件判斷避免錯誤\n")
cat("✅ Infinite 值處理：檢查並替換為 0\n")
cat("✅ Markdown 檢測：使用正則表達式\n")
cat("✅ HTML 轉換：使用 markdown::markdownToHTML\n")
cat("\n💡 關鍵修正：\n")
cat("1. 在 if 條件前檢查 !is.na()\n")
cat("2. 處理 NaN 和 Infinite 值\n")
cat("3. 自動檢測並轉換 Markdown 格式\n")
cat("================================================================================\n")