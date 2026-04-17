#' Remove Novariation Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' remove_novariation()
remove_novariation <- function(data, exceptions = c("asin")) {
  # 確保資料是 data.table 格式
  if (!is.data.table(data)) {
    data <- as.data.table(data)
  }
  
  # 檢查例外欄位是否存在於資料中
  if (!is.null(exceptions)) {
    missing_exceptions <- exceptions[!exceptions %in% names(data)]
    if (length(missing_exceptions) > 0) {
      stop(paste("例外欄位不存在於資料中:", paste(missing_exceptions, collapse = ", ")))
    }
  }
  
  # 檢查每個欄位是否有變化
  non_var_cols <- sapply(data, function(x) {
    # 將 factors 轉為 characters，並處理 NA 值
    unique_values <- unique(as.character(x[!is.na(x)]))
    length(unique_values) == 1
  })
  
  # 如果有例外欄位，確保它們不被刪除
  if (!is.null(exceptions)) {
    non_var_cols[names(data) %in% exceptions] <- FALSE
  }
  
  # 移除無變化的欄位
  data_clean <- data[, !non_var_cols, with = FALSE]
  
  # 檢查清理後是否還有剩餘欄位
  if (ncol(data_clean) == 0) {
    warning("All columns have been removed due to lack of variation.")
    return(NULL)
  }
  
  # 返回清理後的資料
  return(data_clean)
}


# 使用範例
# 假設你有一個數據框名為Design.product
# Design.product2 <- remove_novariation(Design.product)


# library(data.table)

# 創建一個data.table測試集
# test_data <- data.table(
#   ID = 1:10,                         # 有變異
#   Gender = c(rep("Male", 5), rep("Female", 5)),  # 有變異
#   Age = rep(30, 10),                 # 沒有變異
#   Height = c(170, 175, 180, 165, 160, 170, 175, 180, 165, 160),  # 有變異
#   Weight = rep(70, 10),              # 沒有變異
#   Score = 1:10                       # 有變異
# )
# 
# # 檢查生成的測試集
# print(test_data)
# 
# # 測試 remove_novariation 函數
# cleaned_data <- remove_novariation(test_data)
# 
# # 檢查處理後的數據
# print(cleaned_data)
