#' Safe Get Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' safe_get()
safe_get <- function(object_name, folder_path = "app_data", suppress = FALSE) {
  
  # 定義一個內部函數，根據 suppress 參數決定是否顯示訊息
  message_conditional <- function(msg) {
    if (!suppress) message(msg)
  }
  
  # 定義一個檢查物件是否無效的函數（NULL 或 nrow = 0）
  is_invalid <- function(obj) {
    is.null(obj) || (is.data.frame(obj) && nrow(obj) == 0)
  }
  
  # 使用 get0 檢查並嘗試取得物件
  r <- get0(object_name, envir = .GlobalEnv)
  
  # 如果 r 無效，則從指定資料夾中載入
  if (is_invalid(r)) {
    # 設定檔案路徑
    file_path <- file.path(folder_path, paste0(object_name, ".rds"))
    
    # 檢查檔案是否存在
    if (file.exists(file_path)) {
      message_conditional(paste(object_name, "不存在或為空，從", file_path, "載入。"))
      # 載入物件並存入全域環境
      r <- readRDS(file_path)
      assign(object_name, r, envir = .GlobalEnv)
    } else {
      warning(paste("無法找到", object_name, "。確保", file_path, "檔案存在。返回空的 data.frame()。"))
      # 返回空的 data.frame()
      r <- data.frame()
    }
  } else {
    message_conditional(paste(object_name, "已存在於環境中，直接取得。"))
  }
  
  return(r)
}
