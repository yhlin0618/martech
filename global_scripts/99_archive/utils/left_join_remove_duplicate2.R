library(data.table)

left_join_remove_duplicate2 <- function(df1, df2, id = "customer_id") {
  # 確保兩個資料框皆為 data.table
  setDT(df1)
  setDT(df2)
  
  # 先將 df2 依據 id 取唯一值，避免重複鍵值干擾 join
  df2_unique <- unique(df2, by = id)
  
  # 執行左連接，並為重複欄位加上後綴 ".y"
  result <- merge(df1, df2_unique, by = id, all.x = TRUE, suffixes = c("", ".y"))
  
  # 移除所有以 ".y" 結尾的重複欄位
  cols_to_remove <- grep("\\.y$", colnames(result), value = TRUE)
  result[, (cols_to_remove) := NULL]
  
  return(result)
}