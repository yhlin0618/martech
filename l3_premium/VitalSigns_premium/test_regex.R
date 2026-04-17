# 測試正則表達式語法

# 測試不同的跳脫方式
test_text <- "**粗體文字** 和 ## 標題"

# 正確的方式
cat("測試 1: grepl('\\\\*\\\\*', test_text)\n")
result1 <- grepl("\\*\\*", test_text)
cat("結果:", result1, "\n\n")

# 測試組合
cat("測試 2: grepl('\\n\\n|\\\\*\\\\*|##', test_text)\n")
result2 <- grepl("\n\n|\\*\\*|##", test_text)
cat("結果:", result2, "\n\n")

# 測試固定字串匹配
cat("測試 3: grepl('**', test_text, fixed = TRUE)\n")
result3 <- grepl("**", test_text, fixed = TRUE)
cat("結果:", result3, "\n\n")

# 更安全的方式 - 分開檢查
has_bold <- grepl("\\*\\*", test_text)
has_header <- grepl("##", test_text)
has_paragraph <- grepl("\n\n", test_text)

cat("包含粗體:", has_bold, "\n")
cat("包含標題:", has_header, "\n")
cat("包含段落:", has_paragraph, "\n")
cat("任一條件:", has_bold || has_header || has_paragraph, "\n")