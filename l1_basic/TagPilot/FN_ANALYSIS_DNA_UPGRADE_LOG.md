# fn_analysis_dna.R 升級到 Archive 版本日誌

## 升級時間
2025-06-28 21:11

## 原因
- 當前版本在處理 tibble 格式資料時會出現「找不到times」的錯誤
- Archive 版本有更完善的錯誤處理機制

## 版本對比
| 項目 | 舊版本 | Archive 版本 |
|------|--------|--------------|
| 檔案大小 | 40,649 bytes | 49,078 bytes |
| times 欄位處理 | 簡單，容易出錯 | 完善的檢查機制 |
| 錯誤訊息 | 不明確 | 清楚且有幫助 |

## 主要改進
1. **欄位檢查機制**（第 308-314 行）
   ```r
   required_cols <- c("customer_id", "ipt", "total_spent", "times")
   missing_cols <- required_cols[!required_cols %in% names(df_sales_by_customer_id)]
   if (length(missing_cols) > 0) {
     stop("ERROR: Required columns missing: ", paste(missing_cols, collapse = ", "))
   }
   ```

2. **times 欄位創建邏輯**（第 276-303 行）
   - 先嘗試使用 `times` 欄位
   - 若無，嘗試 `sum_transactions_by_customer` 或 `count_transactions_by_date`
   - 最後嘗試 `ni` 欄位
   - 都沒有才報錯，並提供清楚的錯誤訊息

## 依賴函數
Archive 版本需要以下額外函數：
- `fn_left_join_remove_duplicate2.R`
- `fn_fct_na_value_to_level.R`

這些函數在 module_dna_multi.R 中已經正確載入。

## 相容性注意事項
- 函數介面完全相同，理論上向後相容
- 但仍建議在 module_dna_multi.R 中保留 `as.data.frame()` 轉換
- 這樣可以確保即使 Archive 版本也能正確處理 tibble 資料

## 備份
舊版本已備份為：`fn_analysis_dna.R.backup_20250628_211140`

## 後續動作
✅ 已升級到 Archive 版本
✅ 保留了 module_dna_multi.R 中的 as.data.frame() 轉換
✅ 經測試，新版本提供更清楚的錯誤訊息 