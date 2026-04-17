source("config/packages.R")    # 載入套件管理
source("config/config.R")      # 載入配置設定
library(httr)
library(jsonlite)
library(tidyverse)
library(data.table)

# 取得 API Key
api_key <- Sys.getenv("OPENAI_API_KEY")

setwd("./sandbox")
sales_data <- fread("./data_2020_2025.csv")
item_category <-  fread("./product_categories_20250920.csv")
unique_cate <- item_category$category %>% unique()

for (cate in unique_cate ) {
  seleted_item <- item_category %>% filter(category==cate)
  sub_sales <- sales_data %>% filter(product_id %in% seleted_item$product_id)
  sub_f_name <- paste0("subset_",cate,".csv")
  sub_sales %>%  fwrite(file.path(".",sub_f_name))
  
  
}
