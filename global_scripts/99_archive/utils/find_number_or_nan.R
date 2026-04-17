#' Find Number or Nan Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' find_number_or_nan()
find_number_or_nan <- function(s) {
  # 检查是否为 NA 或包含 'NaN'
  if (is.na(s) || grepl("NaN|nan", s, ignore.case = TRUE)) {
    return(NA_integer_)
  }
  
  # 匹配 0-10 的数字
  match <- str_match(s, "\\b(10|[0-9])\\b")[, 1]
  if (!is.na(match)) {
    return(as.integer(match))
  } else {
    return(NA_integer_)
  }
}

# 定义函数：处理单个元素
process_element <- function(x) {
  if (is.character(x)) {
    # 分割字符串
    first_element <- str_split(x, ",|，", simplify = TRUE)[, 1]
    # 提取第一个数字
    return(find_number_or_nan(first_element))
  } else {
    return(NA_integer_)
  }
}

# 对指定列范围应用转换
process_columns <- function(df, start_column) {
  df %>%
    mutate(across(start_column:ncol(df), 
                  ~ ifelse(is.character(.x), sapply(.x, process_element), NA_integer_)))
}
