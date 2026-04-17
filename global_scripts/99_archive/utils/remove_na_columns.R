#' Remove Na Columns Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' remove_na_columns()
remove_na_columns <- function(data) {
  # 檢查每個欄位是否包含 NA 值
  non_na_cols <- colSums(is.na(data)) == 0
  
  # 根據資料框類型選擇不同的處理方式
  if (inherits(data, "data.table")) {
    # 若為 data.table，使用 ..non_na_cols 並指定 with = FALSE
    data_clean <- data[, which(non_na_cols), with = FALSE]
  } else if (inherits(data, "tbl_df")) {
    # 若為 tibble，直接使用非 NA 的列
    data_clean <- data[, non_na_cols, drop = FALSE]
  } else {
    # 若為一般的 data.frame，使用標準的索引方法
    data_clean <- data[, non_na_cols, drop = FALSE]
  }
  
  # 返回處理後的數據
  return(data_clean)
}




keep_numeric_columns <- function(data, exceptions = NULL) {
  # 如果輸入的資料不是 data.table，將其轉換為 data.table
  if (!is.data.table(data)) {
    data <- as.data.table(data)
  }
  
  # 檢查每個欄位是否為數值型
  numeric_cols <- sapply(data, is.numeric)
  
  # 如果指定了例外欄位，將其設為 TRUE 以確保它們被保留
  if (!is.null(exceptions)) {
    exceptions <- exceptions[exceptions %in% names(data)] # 檢查例外欄位是否在資料框中
    numeric_cols[exceptions] <- TRUE
  }
  
  # 只保留數值型的欄位以及例外欄位
  data_numeric <- data[, numeric_cols, with = FALSE]
  
  # 返回處理後的數據
  return(data_numeric)
}
