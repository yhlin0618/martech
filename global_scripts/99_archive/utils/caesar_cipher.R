#' Caesar Cipher Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' caesar_cipher()
caesar_cipher <- function(input_string, shift = 3) {
  # 將所有字母轉換為小寫（或大寫，視需求而定）
  input_string <- tolower(input_string)
  
  # 將輸入字符串轉換為 ASCII 數字
  ascii_values <- utf8ToInt(input_string)
  
  # 計算轉換後的 ASCII 值
  shifted_values <- (ascii_values - 97 + shift) %% 26 + 97
  
  # 將轉換後的 ASCII 值轉換回字符
  encoded_string <- intToUtf8(shifted_values)
  
  return(encoded_string)
}
