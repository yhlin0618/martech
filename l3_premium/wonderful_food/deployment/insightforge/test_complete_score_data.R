################################################################################
# test_complete_score_data.R - 創建測試資料並執行應用
################################################################################

library(tidyverse)

# 創建測試用的已評分資料
create_test_score_data <- function() {
  # 模擬10個產品的評分資料
  products <- paste0("PRD", sprintf("%04d", 1:10))
  product_names <- c(
    "有機蔬菜組合包", "養生穀物粥", "冷壓果汁", "堅果禮盒",
    "手工餅乾", "天然蜂蜜", "有機茶葉", "健康麵包",
    "低脂優格", "營養沙拉"
  )
  
  # 建立評分資料
  score_data <- data.frame(
    product_id = products,
    product_name = product_names,
    新鮮 = round(runif(10, 3, 5), 1),
    美味 = round(runif(10, 3, 5), 1),
    營養 = round(runif(10, 2, 5), 1),
    健康 = round(runif(10, 3, 5), 1),
    方便 = round(runif(10, 2, 4), 1),
    安全 = round(runif(10, 4, 5), 1),
    品質 = round(runif(10, 3, 5), 1),
    價格 = round(runif(10, 2, 4), 1),
    stringsAsFactors = FALSE
  )
  
  # 寫入CSV檔案
  write.csv(score_data, "test_score_data.csv", row.names = FALSE)
  cat("✅ 已創建測試評分資料: test_score_data.csv\n")
  return(score_data)
}

# 創建測試用的銷售資料
create_test_sales_data <- function(products) {
  # 為每個產品創建多筆銷售記錄
  sales_data <- expand.grid(
    product_id = products,
    month = 1:6,
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      period = paste0("2024-", sprintf("%02d", month)),
      quantity = round(runif(n(), 50, 200)),
      sale_price = round(runif(n(), 100, 500)),
      total_amount = quantity * sale_price,
      created_at = as.Date(paste0("2024-", sprintf("%02d", month), "-15"))
    ) %>%
    rename(Sales = quantity) %>%
    select(product_id, period, created_at, Sales, sale_price, total_amount)
  
  # 寫入CSV檔案
  write.csv(sales_data, "test_sales_data.csv", row.names = FALSE)
  cat("✅ 已創建測試銷售資料: test_sales_data.csv\n")
  return(sales_data)
}

# 執行測試
cat("\n========== 創建測試資料 ==========\n")
score_data <- create_test_score_data()
sales_data <- create_test_sales_data(score_data$product_id)

cat("\n評分資料預覽:\n")
print(head(score_data))

cat("\n銷售資料預覽:\n")
print(head(sales_data))

cat("\n========== 啟動應用程式 ==========\n")
cat("請使用以下檔案進行測試:\n")
cat("1. 評分資料: test_score_data.csv\n")
cat("2. 銷售資料: test_sales_data.csv\n")
cat("\n測試步驟:\n")
cat("1. 上傳 test_score_data.csv 作為評分資料\n")
cat("2. 選擇 product_id 作為產品ID欄位\n")
cat("3. 選擇 product_name 作為產品名稱欄位\n")
cat("4. 勾選所有數值欄位作為屬性評分欄位\n")
cat("5. 上傳 test_sales_data.csv 作為銷售資料\n")
cat("6. 選擇對應欄位\n")
cat("7. 點擊處理並預覽\n")
cat("8. 確認後進入銷售模型分析\n")

# 啟動應用
shiny::runApp("app.R")