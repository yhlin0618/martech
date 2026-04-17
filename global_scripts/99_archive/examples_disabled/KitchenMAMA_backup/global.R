#source("./scripts/initialization_update_mode.R")
source("./scripts/global_scripts/global_parameters.R")
source("./scripts/global_scripts/global_path_settings.R")
source("./scripts/global_scripts/Safe_get.R")
source("./scripts/global_scripts/make_names.R")
source("./scripts/global_scripts/clean_column_names.R")
source("./scripts/global_scripts/remove_na_columns.R")
#source("./scripts/global_scripts/load_selected_rds.R")

renamechinese<- c("品牌"="brand",
                  "營收"="revenue",
                  "評分則數"="RatingNum",
                  "評分"="rating",
                  "ASIN"="asin",
                  "商品描述"="item_name",
                  "銷量"="sales",
                  "理想屬性分數"="Score",
                  "時間區間"="time_interval_label",
                  "新客數"="new_customers",
                  "來客數"="num_customers",
                  "累積顧客數"="cum_customers",
                  "顧客成長率"= "customer_acquisition_rate",
                  "顧客留存率"="customer_retention_rate",
                  "總銷售"="total",
                  "與上期差異"="total_difference",
                  "平均銷售"="average",
                  "對數價格平方"="logprice2",
                  "對數價格"="logprice",
                  "銷售成長率"="total_change_rate"
                  )
rename_list <- setNames(names(renamechinese), renamechinese)

position_avoid_ambiguous <-  c("品牌價值"="品牌")

renametemp<- c("asin"="Item_Index")



# 自訂函數，處理空向量的情況
# 自訂函數：處理欄位名稱
# 自訂函數：處理欄位名稱
remove_english_from_chinese <- function(column_names) {
  # 確保輸入為字元向量
  column_names <- as.character(column_names)
  
  # 檢查條件是否正確生成邏輯向量
  contains_chinese <- str_detect(column_names, "[\\u4e00-\\u9fa5]")
  contains_english_or_underscore <- str_detect(column_names, "[A-Za-z_]")  # 包括英文字母和底線
  
  # 防止條件出現問題
  if (length(contains_chinese) == 0 || length(contains_english_or_underscore) == 0) {
    return(column_names)
  }
  
  # 使用邏輯向量處理欄位名稱
  if_else(
    contains_chinese & contains_english_or_underscore,
    str_remove(column_names, "[A-Za-z_]+"),  # 刪除英文字符和底線
    column_names  # 保持不變
  )
}



# #######reticulate environment
# library(reticulate)
# 
# # Define any Python packages needed for the app here:
# PYTHON_DEPENDENCIES = c('pip', 'numpy','openai')
# 
# #如果沒有python3.10的話要安裝這個
# #reticulate::install_python(version = '3.10')
# 
# # Create virtual env and install dependencies
# # 1. 創建虛擬環境（如果尚未存在
# reticulate::virtualenv_create(version="3.10")
# 
# 
# # 2. 安裝所需的Python套件
# reticulate::virtualenv_install(packages = PYTHON_DEPENDENCIES)
# #reticulate::virtualenv_install(packages = PYTHON_DEPENDENCIES, ignore_installed=TRUE)
# # 3. 設置R環境以使用指定的虛擬環境
# reticulate::use_virtualenv(required = T)
# 
# reticulate::py_config()
# 
# #virtualenv_remove("r-reticulate")


#########

# 使用函數讀取指定資料夾中的所有RDS文件
#load_all_rds("dta/Load")
#load("dta/Load/Brand_data.Rdata")
#load_selected_rds("app_data")

#rm(LM_canopener)
#rm(lm_stepwise_model)
#gc()

####################################Funtions
getDynamicOptions <- function(list, dta, invariable, outvariable) {
  dta %>%
    dplyr::filter({{invariable}} %in% list) %>%
    dplyr::pull({{outvariable}}) %>%
    unique() %>%  # 使用 unique 而非 distinct
    sort()
}


CreateChoices <- function(dta, variable) {
  dta %>%
    dplyr::select({{ variable }}) %>%
    dplyr::pull() %>%
    unique() %>% 
    sort()
}

DownloadFeather <- function(URL){
  request(URL) %>%  
    req_perform() %>% resp_body_raw() %>% rawConnection() %>% read_feather()
}

remove_elements <- function(vector, elements) {
  # 移除指定的多個元素，不區分大小寫
  vector <- vector[!tolower(vector) %in% tolower(elements)]
  return(vector)
}

# 定義函數來處理所有變項
calculate_KPI_diff_shiny <- function(dta, output) {
  
  n = nrow(dta)
  for (var in colnames(dta)) {
    local({
      var_copy <- var
      
      # 動態生成輸出名稱
      observe({
        output[[paste0(var_copy, "_now")]] <- renderText({
          last(dta[[var_copy]])
        })
        outputOptions(output, paste0(var_copy, "_now"), suspendWhenHidden = FALSE)
        
        output[[paste0(var_copy, "_now_perc")]] <- renderText({
          dta[[var_copy]] %>% 
            last() %>% 
            as.numeric() %>% 
            scales::percent(accuracy = 0.01)
        })
        
        output[[paste0(var_copy, "_diff")]] <- renderUI({
          difference <- tryCatch({
            last(dta[[var_copy]]) - nth(dta[[var_copy]], -2)
          }, error = function(e) {
            return(NULL)  # 捕获错误时返回 NULL
          })
          
          if (is.null(difference) || is.na(difference)) {
            return(NULL)  # 返回空的 UI 元素
          }
          
          if (difference >= 0) {
            return(bs_icon("graph-up-arrow", class = "text-success"))
          } else {
            return(bs_icon("graph-down-arrow", class = "text-danger"))
          }
          
        })
          
        output[[paste0(var_copy, "_diff_perc")]] <- renderText({
          scales::percent((last(dta[[var_copy]]) - nth(dta[[var_copy]], -2))/nth(dta[[var_copy]], -2))
        })
        
        output[[paste0(var_copy, "_diff_value_perc")]] <- renderText({
          scales::percent((last(dta[[var_copy]]) - nth(dta[[var_copy]], -2)))
        })
        
        outputOptions(output, paste0(var_copy, "_diff"), suspendWhenHidden = FALSE)
      })
    })
  }
  output
}

ladder <- function(x) paste(strsplit(toupper(x), split = "")[[1]], sep = "", collapse="\n")



Recode_time_TraceBack <- function(profile) {
  switch(profile,
         "m1quarter" = "m1quarter",
         "m1year" = "m1year",
         "m1month" = "m1month",
         "quarter" = "m1quarter",
         "year" = "m1year",
         "month" = "m1month",
         NA)  # 如果沒有匹配，返回 NA
}

calculate_KPI_diff_TraceBack_shiny <- function(dta, unit, grouping = NULL, skipcolumns, output) {
  TraceBacktime <- Recode_time_TraceBack(unit)
  
  # 檢查 grouping 是否為 NULL
  if (is.null(grouping)) {
    # 如果 grouping 為 NULL，則只計算不分組的情況
    namesvec <- setdiff(colnames(dta), skipcolumns)
    
    for (var in namesvec) {
      # 保留 var 的本地拷貝
      for (suffix in c("", "_1")) {
        local({
          var_copy <- var
          suffix_copy <- suffix
          
          var_name_with_suffix <- paste0(var_copy, suffix_copy)
          
          # 動態生成輸出名
          observe({
            # 當前值文本輸出
            output_id_now <- paste(var_name_with_suffix, "now", sep = "_")
            output[[output_id_now]] <- renderText({
              now_data <- dta %>% filter(time_condition_filter=="now")
              if (nrow(now_data) > 0) {
                now_data[[var_copy]]
              } else {
                NA
              }
            })
            outputOptions(output, output_id_now, suspendWhenHidden = FALSE)
            
            output[[paste(var_name_with_suffix, "now_perc", sep = "_")]] <- renderText({
              now_data <- dta %>% filter(time_condition_filter=="now")
              if (nrow(now_data) > 0) {
                scales::percent(now_data[[var_copy]], accuracy = 0.01)
              } else {
                NA
              }
            })
            
            # 差異 UI 輸出
            output_id_diff <- paste(var_name_with_suffix, "diff", sep = "_")
            output[[output_id_diff]] <- renderUI({
              now_data <- dta %>% filter(time_condition_filter=="now")
              past_data <- dta %>% filter(time_condition_filter==TraceBacktime)
              
              # 檢查 now_data 和 past_data 是否為空
              if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                now_value <- now_data[[var_copy]]
                past_value <- past_data[[var_copy]]
                
                # 檢查 now_value 和 past_value 是否為 NA
                if (!is.na(now_value) && !is.na(past_value)) {
                  difference <- now_value - past_value
                  
                  # 根據差異選擇圖標
                  if (difference >= 0) {
                    return(bs_icon("graph-up-arrow", class = "text-success"))
                  } else {
                    return(bs_icon("graph-down-arrow", class = "text-danger"))
                  }
                  
                } else {
                  return(bs_icon("question", class = "text-info"))
                }
              } else {
                # 如果 subset 結果為空，返回提示消息
                if (nrow(now_data) == 0) {
                  return(bs_icon("question", class = "text-info"))
                }
                if (nrow(past_data) == 0) {
                  return(bs_icon("question", class = "text-info"))
                }
                return(bs_icon("question", class = "text-info"))
              }
            })
            
            # 差異百分比文本輸出
            output_id_diff_perc <- paste(var_name_with_suffix, "diff_perc", sep = "_")
            output[[output_id_diff_perc]] <- renderText({
              now_data <- dta %>% filter(time_condition_filter=="now")
              past_data <- dta %>% filter(time_condition_filter==TraceBacktime)
              
              if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                scales::percent((now_data[[var_copy]] - past_data[[var_copy]]) / past_data[[var_copy]], accuracy = 0.01)
              } else {
                NA
              }
            })
            outputOptions(output, output_id_diff_perc, suspendWhenHidden = FALSE)
            
            output_id_diff_value <- paste(var_name_with_suffix, "diff_value", sep = "_")
            output[[output_id_diff_value]] <- renderText({
              now_data <- dta %>% filter(time_condition_filter=="now")
              past_data <- dta %>% filter(time_condition_filter==TraceBacktime)
              
              if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                sprintf("%+d", (now_data[[var_copy]] - past_data[[var_copy]]))
              } else {
                NA
              }
            })
          })
        })
      }
    }
  } else {
    # 若 grouping 不為 NULL，按原先的分組計算
    groupinglevels <- levels(dta[[grouping]])
    namesvec <- setdiff(colnames(dta), c(grouping, skipcolumns))
    
    for (group in groupinglevels) {
      for (var in namesvec) {
        for (suffix in c("", "_1")) {
          local({
            group_copy <- group
            var_copy <- var
            suffix_copy <- suffix
            
            var_name_with_suffix <- paste0(var_copy, suffix_copy)
            group_name_with_suffix <- group_copy
            
            observe({
              output_id_now <- paste(group_name_with_suffix, var_name_with_suffix, "now", sep = "_")
              output[[output_id_now]] <- renderText({
                now_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == "now")
                if (nrow(now_data) > 0) {
                  now_data[[var_copy]]
                } else {
                  NA
                }
              })
              outputOptions(output, output_id_now, suspendWhenHidden = FALSE)
              
              output[[paste(group_name_with_suffix, var_name_with_suffix, "now_perc", sep = "_")]] <- renderText({
                now_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == "now")
                if (nrow(now_data) > 0) {
                  scales::percent(now_data[[var_copy]], accuracy = 0.01)
                } else {
                  NA
                }
              })
              
              output_id_diff <- paste(group_name_with_suffix, var_name_with_suffix, "diff", sep = "_")
              output[[output_id_diff]] <- renderUI({
                now_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == "now")
                
                past_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == TraceBacktime)
                
                if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                  now_value <- now_data[[var_copy]]
                  past_value <- past_data[[var_copy]]
                  
                  if (!is.na(now_value) && !is.na(past_value)) {
                    difference <- now_value - past_value
                    if (difference >= 0) {
                      return(bs_icon("graph-up-arrow", class = "text-success"))
                    } else {
                      return(bs_icon("graph-down-arrow", class = "text-danger"))
                    }
                    
                  } else {
                    return(bs_icon("question", class = "text-info"))
                    }
                  
                } else {
                  if (nrow(now_data) == 0) {
                    return(bs_icon("question", class = "text-info"))
                  }
                  if (nrow(past_data) == 0) {
                    return(bs_icon("question", class = "text-info"))
                  }
                  return(bs_icon("question", class = "text-info"))
                }
              })
              
              output_id_diff_perc <- paste(group_name_with_suffix, var_name_with_suffix, "diff_perc", sep = "_")
              output[[output_id_diff_perc]] <- renderText({
                now_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == "now")
                
                past_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == TraceBacktime)
                
                if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                  scales::percent((now_data[[var_copy]] - past_data[[var_copy]]) / past_data[[var_copy]], accuracy = 0.01)
                } else {
                  NA
                }
              })
              outputOptions(output, output_id_diff_perc, suspendWhenHidden = FALSE)
              
              output_id_diff_value <- paste(group_name_with_suffix, var_name_with_suffix, "diff_value", sep = "_")
              output[[output_id_diff_value]] <- renderText({
                now_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == "now")
                
                past_data <- dta %>%
                  filter(!!sym(grouping) == group_copy, time_condition_filter == TraceBacktime)
                
                if (nrow(now_data) > 0 && nrow(past_data) > 0) {
                  sprintf("%+d", (now_data[[var_copy]] - past_data[[var_copy]]))
                } else {
                  NA
                }
              })
            })
          })
        }
      }
    }
  }
  output
}


#####################################

####Recode variable

formattime <- function(time_scale, case){
  if(case == "quarter"){
    return(gsub("\\.", ".Q", lubridate::quarter(time_scale, type = "year.quarter")))
  }
  if(case == "year"){
    return(format(time_scale, "%Y"))
  }
  if(case == "month"){
    return(format(time_scale, "%Y/%m"))
  }
}



###Processing dta

process_sales_data <- function(SalesPattern, time_scale_profile) {

  
  SalesPattern %>% rename_with(make_names) %>% 
    group_by(time_interval = floor_date(time_scale, unit = time_scale_profile)) %>% 
    dplyr::summarise(total = sum(total),
                     num_customers = sum(num_customers)) %>% 
    mutate(Difference = round(total - lag(total, default = NA), 2),
           Average = round(total / num_customers, 2)) %>%
    mutate(time_interval = formattime(time_interval, time_scale_profile)) %>% 
    dplyr::select(time_interval, total, Difference, num_customers, Average)
}


Exclude_Variable=list(Not_GPTRating = c("rating","sales","revenue"),
                      keys = c("asin","brand","product_line_id"))

generate_render_code <- function(data_frame) {
  # 獲取資料框名稱
  data_frame_name <- deparse(substitute(data_frame))
  
  # 取得資料框的欄位名稱
  variable_names <- colnames(data_frame)
  
  # 防止多重輸出，逐一生成代碼
  render_code <- purrr::map_chr(variable_names, ~ {
    paste0("output$dna_", .x, 
           " <- renderText({as.character(", data_frame_name, " %>% select(", .x, ") %>% pull())})")
  })
  
  # 合併所有生成的代碼為單一字串
  render_code <- paste(render_code, collapse = "\n")
  
  return(render_code)
}




item_property_dictionary <- safe_get("item_property_dictionary_Dta")%>% rename_with(make_names)
asintosku <- setNames(item_property_dictionary$sku,item_property_dictionary$asin)
skutoasin <- setNames(item_property_dictionary$asin,item_property_dictionary$sku)
skutoproduct_line <- setNames(item_property_dictionary$product_line,item_property_dictionary$sku)
asintoproduct_line <- setNames(item_property_dictionary$product_line,item_property_dictionary$asin)

product_linetoChinese <- setNames(Product_List_Chinese,Product_List)



# server.R or app.R
onStop(function() {
  if (DBI::dbIsValid(app_data)) {
    dbDisconnect(app_data)
    cat("Global database connection closed.\n")
    gc()
  }
})