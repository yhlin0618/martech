

library(httr)
library(data.table)
library(tidyverse)
# 設定 URL 和 API Key

# start_time <- "2024-01-01"
# end_at <- "2025-08-20"
# url <- paste0("https://ai-api.ezbiz.com.tw/wonderfulfood-api/v1/internal/professor-lin-order?start_at=",start_time,"&end_at=",end_at)
app_id <- '2412221712088037'
token <- "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZW1iZXJfaWQiOiIyNTA4MjUwMTAwNzczMzU1IiwiZmlyc3RfbmFtZSI6InByb2Zlc3Nvcmxpbm9yZGVyIiwiZW1haWwiOiJwcm9mZXNzb3JsaW5vcmRlckB3b25kZXJmdWxmb29kLmNvbS50dyIsImlhdCI6MTc1NjA4NjI4MH0.hmkV4FwosOy9S5j_SGhys9YIZxABINab0Y5XL8XlWBM"
# # 發送 GET 請求，將 API key 放在 header
# res <- GET(url, add_headers(
#   `app-id` = app_id,
#   `access-token` = token
# )
# )
# content_list <- content(res, "parsed", simplifyDataFrame = TRUE)
# content_list$product_images[2]
# PRD0040300044
# names(content_list)
# 
# content_list %>% fwrite("url_example.csv")
# 
# 
# setDT(content_list)
# content_list[,.(product_id,product_images,product_url)] %>% unique()
# 
# 


start_date <- as.Date("2020-01-01")
end_date <- as.Date("2025-08-20")

# 儲存結果用
all_results <- list()

# === 產生每個月的區間 ===
month_starts <- seq(start_date, end_date, by = "month")

for (i in seq_along(month_starts)) {
  this_start <- month_starts[i]
  this_end <- if (i == length(month_starts)) {
    end_date
  } else {
    month_starts[i + 1] - 1
  }
  
  
  
  url <- paste0(
    "https://ai-api.ezbiz.com.tw/wonderfulfood-api/v1/internal/professor-lin-order?",
    "start_at=", this_start,
    "&end_at=", this_end
  )
  
  
  
  res <- GET(url, add_headers(
    `app-id` = app_id,
    `access-token` = token
  )
  )

  
  if (status_code(res) == 200) {
    content_data <- content(res, "parsed", simplifyDataFrame = TRUE)
    
    if (length(content_data) > 0) {
      message("✅ 資料成功取得：", this_start, " ~ ", this_end)
      all_results[[paste0(this_start, "_to_", this_end)]] <- content_data
    } else {
      message("⚠️ 無資料：", this_start, " ~ ", this_end)
    }
  } else {
    warning("❌ 錯誤 ", status_code(res), " 於 ", this_start, " ~ ", this_end)
  }
  
  Sys.sleep(0.2)  # Optional: 控制頻率
}

# === 整合所有資料 ===
result_df <- bind_rows(all_results, .id = "period")

result_df %>% unique()

setDT(result_df)
result_df[,.(product_id)] %>% unique()

result_df$total_amount %>% as.numeric() %>% sum()



write.csv(result_df, "data_2020_2025.csv", row.names = FALSE)

# rfm cai 活躍度


raw_dta <- fread("data_2020_2025.csv")
raw_dta %>% setDT()
raw_dta[,period:=NULL]
raw_dta <- raw_dta %>% unique()
setnames(raw_dta,"created_at","payments_date")

setnames(raw_dta,"email","customer_id")

setnames(raw_dta,"total_amount","amount")

write.csv(raw_dta[,.(customer_id,amount,payments_date)], "rename_data_2020_2025.csv", row.names = FALSE)



subd <- raw_dta[1:10000]

write.csv(subd[,.(customer_id,amount,payments_date)], "rename_data_2020_2025.csv", row.names = FALSE)


raw_dta[email=="0903016333a@gmail.com"]
