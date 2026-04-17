# VitalSigns "找不到times" 問題修復總結

## 問題描述
工程師回報說 VitalSigns app 在執行 DNA 分析時出現「找不到times」的錯誤。

## 問題根因
`analysis_dna` 函數在內部嘗試提取資料欄位時，如果傳入的資料是 tibble 而非標準的 data.frame，可能會導致欄位提取失敗。

具體來說，在 `fn_analysis_dna.R` 的第 287 行：
```r
data_by_customer <- as.data.table(df_sales_by_customer_id[, c("customer_id", "ipt", "total_spent", "times")])
```

## 修復方案
在調用 `analysis_dna` 函數前，將資料明確轉換為 data.frame：

```r
dna_results <- analysis_dna(
  df_sales_by_customer = as.data.frame(sales_by_customer),
  df_sales_by_customer_by_date = as.data.frame(sales_by_customer_by_date),
  skip_within_subject = FALSE,
  verbose = TRUE,
  global_params = complete_global_params
)
```

## 修改的檔案
- `l1_basic/VitalSigns/modules/module_dna_multi.R` - 在第 326 行加入 `as.data.frame()` 轉換

## 驗證方法
1. 執行 `test_times_field_diagnosis.R` 診斷腳本
2. 上傳測試資料並執行 DNA 分析
3. 確認不再出現「找不到times」錯誤

## 其他建議
- 確保所有傳入 `analysis_dna` 的資料都是標準 data.frame 格式
- 使用 `verbose = TRUE` 參數以獲得更詳細的錯誤訊息
- 避免在資料處理過程中混用 tibble 和 data.frame

## Archive 版本為何沒有問題？

經過深入比較，發現 archive 版本使用的是**不同版本的 analysis_dna 函數**！

### 關鍵差異：

1. **Archive 版本的 analysis_dna（第 314 行）**：
   ```r
   data_by_customer <- as.data.table(df_sales_by_customer_id[, required_cols])
   ```
   - 使用 `required_cols` 變數
   - 有完整的欄位檢查機制

2. **當前版本的 analysis_dna（第 287 行）**：
   ```r
   data_by_customer <- as.data.table(df_sales_by_customer_id[, c("customer_id", "ipt", "total_spent", "times")])
   ```
   - 直接硬編碼欄位名稱
   - 當 df_sales_by_customer_id 是 tibble 時，這種寫法可能失敗

3. **module_dna_multi.R 的差異**：
   - 兩個版本的 module_dna_multi.R 幾乎相同
   - 但 archive 版本使用的 analysis_dna 函數有更好的錯誤處理

### 真正的原因：
Archive 版本沒有問題是因為它使用了更穩健的 analysis_dna 函數版本，而不是因為 module_dna_multi.R 的差異。

## 部署狀態
✅ 修復已提交並推送到 GitHub
✅ 請工程師重新部署應用程式以應用修復 