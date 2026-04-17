#' Generate Dummy Matrix Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' generate_dummy_matrix()
library(dplyr)
library(tidyr)

# ## 考量、和/ 的，但可能有duplicate issue 應該已經修正，但之後保險起見可以檢查
# generate_dummy_matrix <- function(data, id_column_name,separator="[、/,]") {
#   id_column_name <- as.character(id_column_name)
#   
#   # 选取数值型和ID列以外的所有列进行转换
#   target_columns <- names(data)[!names(data) %in% id_column_name & !sapply(data, is.numeric)]
#   
#   # 长格式转换，处理包含NA的行和多种分隔符
#   data_long <- data %>%
#     pivot_longer(cols = target_columns, names_to = "feature", values_to = "value") %>%
#     separate_rows(value, sep = separator) %>%
#     drop_na(value) %>%
#     # 为每个特征和其值生成一个唯一的列名
#     mutate(feature_value = paste(feature, value, sep = "_")) %>%
#     # 创建dummy变量
#     mutate(dummy = 1) %>%
#     distinct() %>% 
#     pivot_wider(id_cols = id_column_name, names_from = feature_value, 
#                 values_from = dummy, values_fill = list(dummy = 0)) # 正确使用values_fill
#   
#   # 合并数值型列
#   num_columns <- select(data, !!sym(id_column_name), where(is.numeric))
#   
#   # 合并数值型列和转换后的数据
#   final_data <- left_join(num_columns, data_long, by = id_column_name)
#   
#   ordered_cols <- c(id_column_name, names(num_columns)[-1], 
#                     sort(setdiff(names(final_data), c(id_column_name, names(num_columns)[-1]))))
#   
#   final_data <- final_data %>%
#     select(all_of(ordered_cols))
#   
#   
#   return(final_data)
# }
# 
# 
# library(tidyverse)
# 
# generate_dummy_matrix <- function(data, id_column_name, separator="[、/,]") {
#   id_column_name <- as.character(id_column_name)
#   
#   # 选取数值型和ID列以外的所有列进行转换
#   target_columns <- names(data)[!names(data) %in% id_column_name & !sapply(data, is.numeric)]
#   
#   # 长格式转换，不处理包含NA的行，以适应多种分隔符
#   data_long <- data %>%
#     pivot_longer(cols = target_columns, names_to = "feature", values_to = "value") %>%
#     separate_rows(value, sep = separator) %>%
#     # 不再在这里删除NA值
#     mutate(feature_value = paste(feature, value, sep = "_"),
#            # 创建dummy变量，这里处理NA值
#            dummy = if_else(is.na(value), NA_integer_, 1)) %>%
#     distinct() %>%
#     pivot_wider(id_cols = id_column_name, names_from = feature_value, 
#                 values_from = dummy, values_fill = list(dummy = 0))  # values_fill只应用于非NA的情况
#   
#   # 合并数值型列
#   num_columns <- select(data, !!sym(id_column_name), where(is.numeric))
#   
#   # 合并数值型列和转换后的数据
#   final_data <- left_join(num_columns, data_long, by = id_column_name)
#   
#   ordered_cols <- c(id_column_name, names(num_columns)[-1], 
#                     sort(setdiff(names(final_data), c(id_column_name, names(num_columns)[-1]))))
#   
#   final_data <- final_data %>%
#     select(all_of(ordered_cols))
#   
#   return(final_data)
# }
# data <- sub_res
# id_column_name <- "key"
#data <-a# product_Property_001_Electric_Can_Opener
#id_column_name <- "ASIN"
generate_dummy_matrix <- function(data, id_column_name, separator="[、/,]",remain_name=NULL) {
  id_column_name <- as.character(id_column_name)
  # id_column_name <- "ASIN"
  # remain_name <- "品牌"
  # unit_equation = "克:盎司:公斤:Kilograms=1:28.3:1000:1000;毫升:公升=1:1000"
  # data <- d %>% select(.,-any_of(remove_name)) %>% 
  #   convert_units_to_smallest(., unit_equation) %>%
  #   select(-"重量")
  data <- data %>%
    mutate(across(where(~is.list(.x)), ~unlist(.x)))
  # 选取数值型和ID列以外的所有列进行转换
  if (is.null(remain_name)){
    target_columns <- names(data)[!names(data) %in% id_column_name & !sapply(data, is.numeric)]
  }else{
    target_columns <- names(data)[!names(data) %in% id_column_name & !sapply(data, is.numeric)& !names(data) %in% remain_name]
  }

  
  # 长格式转换
  data_long <- data %>%
    pivot_longer(cols = target_columns, names_to = "feature", values_to = "value") %>%
    separate_rows(value, sep = separator) %>%
    # 处理NA值，为每个特征和其值生成一个唯一的列名，同时处理NA情况
    mutate(feature_value = if_else(is.na(value), paste(feature, "NA", sep = "_"), paste(feature, value, sep = "_")),
           dummy = if_else(is.na(value), 1, 1)) %>%
    distinct() %>%
    pivot_wider(id_cols = id_column_name, names_from = feature_value, 
                values_from = dummy, values_fill = list(dummy = 0)) 
  
  # 合并数值型列
  num_columns <- select(data, any_of(c(id_column_name)),where(is.numeric))
  REMAIN_COL <- select(data,any_of(c(id_column_name, remain_name)))
  # 合并数值型列和转换后的数据
  final_data <- left_join(num_columns, data_long, by = id_column_name)
  final_data <- left_join(final_data, REMAIN_COL, by = id_column_name)

  if(is.null(remain_name)){
    ordered_cols <- c(id_column_name, names(num_columns)[-1], 
                      sort(setdiff(names(final_data), c(id_column_name, names(num_columns)[-1]))))
  }else{
    ordered_cols <- c(id_column_name, names(num_columns)[-1],remain_name, 
                      sort(setdiff(names(final_data), c(id_column_name, names(num_columns)[-1]))))
  }
  final_data <- final_data %>%
    select(all_of(ordered_cols))

  return(final_data)
}

