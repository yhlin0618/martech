#' Clean Column Names Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' clean_column_names()
clean_column_names <- function(column_names, separator = "\\.\\.") {
  pattern <- paste0(separator, ".*")
  cleaned_names <- gsub(pattern, "", column_names)
  return(cleaned_names)
}

# # 測試數據
# column_names <- c("product_Index", "AmazonReviewRating", "材質..Material.", "體積..Volume.", "顏色..Color.", "價格..Price.", "設計..Design.", "質量..Quality.")
# 
# # 使用函數清理列名
# cleaned_names <- clean_column_names(column_names)
# 
# # 打印結果
# print(cleaned_names)


clean_column_names_remove_english <- function(column_names) {
  # 使用正則表達式來移除所有英文字符（大小寫）
  cleaned_names <- gsub("[A-Za-z]", "", column_names)
  return(cleaned_names)
}
