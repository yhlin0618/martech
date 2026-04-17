# 測試 KM_eg 資料處理
# 檢查電子郵件映射修復是否有效

library(dplyr)
library(readr)

# 設定路徑
km_file <- "test_data/KM_eg/2_1_23, 12_00 AM - 2_7_23, 11_59 PM.csv"

print("=== 測試 KM Amazon 銷售資料處理 ===")

# 讀取資料（限制前100行以快速測試）
if (file.exists(km_file)) {
  # 讀取檔案前幾行以檢查結構
  raw_data <- read.csv(km_file, nrows = 100, stringsAsFactors = FALSE)
  
  print(paste("檔案讀取成功，前100行包含", nrow(raw_data), "筆記錄"))
  print("欄位名稱:")
  print(names(raw_data))
  
  # 檢查關鍵欄位
  if ("Buyer.Email" %in% names(raw_data)) {
    print(paste("✅ 找到 Buyer Email 欄位"))
    print("前5個電子郵件範例:")
    print(head(raw_data$Buyer.Email, 5))
  }
  
  if ("Purchase.Date" %in% names(raw_data)) {
    print(paste("✅ 找到 Purchase Date 欄位"))
    print("前5個日期範例:")
    print(head(raw_data$Purchase.Date, 5))
  }
  
  if ("Item.Price" %in% names(raw_data)) {
    print(paste("✅ 找到 Item Price 欄位"))
    print("前5個價格範例:")
    print(head(raw_data$Item.Price, 5))
  }
  
  # 模擬模組處理過程
  print("\n=== 模擬電子郵件到數字ID映射 ===")
  
  if ("Buyer.Email" %in% names(raw_data) && "Purchase.Date" %in% names(raw_data) && "Item.Price" %in% names(raw_data)) {
    # 標準化欄位名稱
    processed_data <- raw_data %>%
      rename(
        customer_id = Buyer.Email,
        payment_time = Purchase.Date,
        lineitem_price = Item.Price
      ) %>%
      filter(
        !is.na(customer_id),
        !is.na(payment_time),
        !is.na(lineitem_price)
      ) %>%
      mutate(
        original_customer_id = customer_id,
        customer_id = as.integer(as.factor(customer_id)),  # 電子郵件到數字ID映射
        payment_time = as.POSIXct(payment_time),
        lineitem_price = as.numeric(lineitem_price),
        platform_id = "upload"
      )
    
    print(paste("處理完成，有效記錄:", nrow(processed_data)))
    print(paste("唯一客戶數:", length(unique(processed_data$customer_id))))
    
    # 顯示映射範例
    email_mapping <- processed_data %>%
      select(original_customer_id, customer_id) %>%
      distinct() %>%
      arrange(customer_id) %>%
      head(10)
    
    print("電子郵件到數字ID映射範例:")
    print(email_mapping)
    
    # 檢查customer_id類型
    print(paste("Customer ID 類型:", class(processed_data$customer_id)[1]))
    print(paste("是否為數值型:", is.numeric(processed_data$customer_id)))
    
  } else {
    print("❌ 缺少必要欄位")
  }
  
} else {
  print(paste("❌ 檔案不存在:", km_file))
}

print("\n=== 測試完成 ===") 