# 策略模組調試報告

## 問題診斷
用戶報告品牌定位策略與建議有問題。

## 可能的問題原因
1. **key_vars() 返回空值**：關鍵因素沒有正確識別
2. **feats_key/feats_non 分離錯誤**：屬性分組出現問題
3. **colSums 計算失敗**：數據結構不正確
4. **四象限邏輯錯誤**：平均值計算或比較出錯
5. **GPT策略分析沒有觸發**：API調用問題

## 已添加的調試功能

### 1. 關鍵變數輸出
```r
cat("key_vars:", paste(key, collapse = ", "), "\n")
cat("feats_key:", paste(feats_key, collapse = ", "), "\n")
cat("feats_non:", paste(feats_non, collapse = ", "), "\n")
```

### 2. 數值計算輸出
```r
cat("sums_key:", paste(names(sums_key), "=", sums_key, collapse = "; "), "\n")
cat("sums_non:", paste(names(sums_non), "=", sums_non, collapse = "; "), "\n")
```

### 3. 四象限分析結果
```r
cat("四象限分析結果:\n")
cat("訴求:", paste(quad_feats$訴求, collapse = ", "), "\n")
cat("改變:", paste(quad_feats$改變, collapse = ", "), "\n")
cat("改善:", paste(quad_feats$改善, collapse = ", "), "\n")
cat("劣勢:", paste(quad_feats$劣勢, collapse = ", "), "\n")
```

### 4. 空值保護
添加了對空數組的檢查和保護：
```r
if (length(feats_key) == 0) feats_key <- character(0)
if (length(feats_non) == 0) feats_non <- character(0)

sums_key <- if(length(feats_key) > 0) colSums(as.data.frame(ind)[feats_key]) else numeric(0)
sums_non <- if(length(feats_non) > 0) colSums(as.data.frame(ind)[feats_non]) else numeric(0)
```

## 測試步驟
1. 重新運行應用 `runApp()`
2. 完成數據上傳和評分
3. 進入策略建議頁面
4. 選擇一個 Variation
5. 查看控制台調試輸出
6. 點擊「策略探索」按鈕
7. 檢查策略分析是否出現

## 常見問題排查

### 如果 key_vars 為空
- 檢查 `key_factors` reactive 函數
- 確認 brand_data 中有理想點數據

### 如果 feats_key/feats_non 為空
- 檢查屬性是否正確匹配到數據欄位
- 確認 indicator_data 結構正確

### 如果四象限圖空白
- 檢查是否有足夠的屬性進行分析
- 確認數值計算沒有產生 NaN

### 如果策略分析沒有觸發
- 檢查 API 金鑰設定
- 確認網路連接正常
- 查看 GPT 回應是否有錯誤

## 狀態
�� 已添加完整調試功能，等待用戶測試反饋 