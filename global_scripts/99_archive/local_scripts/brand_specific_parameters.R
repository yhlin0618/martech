library(readxl)
library(tidyverse)

###brand specific settings###

language <-  "chinese"

# 定義存放子資料夾的主資料夾路徑
raw_data_folder <- file.path("..","rawdata_MAMBA")

#####brand specific parameter settings###

brand_name <-  "MAMBA"

# 生產線設定
product_line_dtah <- read_excel(file.path("app_data", "scd_type1", "product_line.xlsx")) %>%
  mutate(product_line_id =  sprintf("%03d", row_number() - 1),
         product_line_id_name = paste0(product_line_id, "_", product_line_name_english))

product_line_dictionary <- as.list(setNames(product_line_dtah$product_line_id, product_line_dtah[[paste0("product_line_name_", language)]]))

product_line_id_vec <- unlist(product_line_dictionary)
vec_product_line_id_noall <- unlist(product_line_dictionary)[-1]

# 銷售平台設定
source_dtah <- read_excel(file.path("app_data", "scd_type1", "source.xlsx")) %>%
  mutate(source = tolower(gsub(" ", "", source_english)))


source_dictionary <- as.list(setNames(source_dtah$source, source_dtah[[paste0("source_", language)]]))
source_vec <- unlist(source_dictionary)

