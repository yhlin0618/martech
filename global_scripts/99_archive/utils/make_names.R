#' Make Names Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' make_names()
make_names <- function(x) {
  if (!is.character(x)) stop("Input must be a character vector") # 防錯處理
  
  x %>%
    gsub("([a-z])([A-Z])", "\\1_\\2", .) %>% # 將驼峰命名轉換為蛇形命名
    tolower() %>%                           # 轉換為小寫
    make.names() %>%                        # 轉換為合法的 R 名稱
    gsub("\\.", "_", .) %>%                 # 將所有 . 替換為 _
    gsub("__+", "_", .) %>%                 # 替換連續的下劃線為單個下劃線
    gsub("^_+|_+$", "", .)                  # 去除開頭和結尾的下劃線
}
