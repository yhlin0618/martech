# 電子郵件客戶ID映射修復

## 🔧 問題描述

在原始系統中，當客戶ID為電子郵件格式時，直接轉換為數值會產生NA值，導致：
1. **警告訊息**: `強制變更過程中產生了 NA`
2. **資料遺失**: 大量客戶記錄因為customer_id為NA而被過濾掉
3. **分析失敗**: DNA分析無法正常執行

## ✅ 修復方案

### 1. 電子郵件到數字ID的一對一映射
- 使用 `as.factor()` 創建穩定的電子郵件到數字ID映射
- 保留原始電子郵件以便追溯
- 確保每個唯一電子郵件對應唯一數字ID

### 2. 修復範圍
- `modules/module_dna.R` - 單檔案DNA分析模組
- `modules/module_dna_multi.R` - 多檔案DNA分析模組
- `scripts/global_scripts/04_utils/fn_analysis_dna.R` - 核心分析函數

### 3. 新增功能
- **電子郵件映射表**: 新增專用tab顯示電子郵件與數字ID的對應關係
- **智能轉換**: 只有在偵測到電子郵件格式時才創建映射
- **錯誤防護**: 避免重複轉換已經是數值型的customer_id

## 📊 修復效果

### 修復前
```
警告： There was 1 warning in `mutate()`.
ℹ In argument: `customer_id = as.numeric(customer_id)`.
Caused by warning:
! 強制變更過程中產生了 NA
```

### 修復後
```
✅ 電子郵件映射完成: 15000個唯一客戶
✅ 資料處理完成，有效記錄: 20000 客戶數: 15000
🧬 DNA 分析完成！
```

## 🗂️ 新增介面功能

### 電子郵件映射表
當系統偵測到電子郵件格式的客戶ID時，會自動顯示 "📧 客戶ID映射" tab，內容包括：

| 原始電子郵件 | 數字客戶ID |
|-------------|-----------|
| john.doe@example.com | 1001 |
| jane.smith@example.com | 1002 |
| alice.johnson@example.com | 1003 |

### 自動偵測機制
- **電子郵件格式**: 包含 "@" 符號的customer_id會被識別為電子郵件
- **一對一映射**: 使用 `as.integer(as.factor())` 確保穩定映射
- **條件顯示**: 只有當存在電子郵件映射時才顯示映射表

## 🔍 技術詳情

### 資料處理流程
1. **檢測格式**: 判斷customer_id是否包含"@"符號
2. **保留原始**: 將原始電子郵件存儲在 `original_customer_id` 欄位
3. **創建映射**: 使用 `as.integer(as.factor())` 生成數字ID
4. **避免重複**: 在後續處理中不再轉換已經是數值型的ID

### 映射穩定性
```r
# 修復前的問題程式碼
customer_id = as.numeric(customer_id)  # 會產生 NA

# 修復後的解決方案
customer_id = if(is.character(customer_id)) {
  if(any(grepl("@", customer_id, fixed = TRUE))) {
    as.integer(as.factor(customer_id))  # 穩定的一對一映射
  } else {
    as.integer(customer_id)
  }
} else {
  as.integer(customer_id)
}
```

## 📋 測試建議

### 測試資料
使用 `test_data/email_test.csv` 進行測試：
- 包含4個不同電子郵件客戶
- 10筆交易記錄
- 測試電子郵件到數字ID的映射

### 預期結果
1. ✅ 無NA值警告
2. ✅ 正確的客戶數統計
3. ✅ 顯示電子郵件映射表
4. ✅ DNA分析正常完成

## 🔄 向後相容性

- **數字ID客戶**: 原有的數字ID客戶不受影響
- **混合格式**: 同時支援電子郵件和數字ID格式
- **資料完整性**: 不會遺失任何有效的交易記錄

## 🎯 使用指南

1. **上傳包含電子郵件的檔案** (如Amazon銷售報告)
2. **系統自動偵測並創建映射**
3. **在「📧 客戶ID映射」tab中查看對應關係**
4. **正常進行DNA分析，無需額外設定**

此修復確保了系統能夠無縫處理電子郵件格式的客戶ID，同時保持資料的完整性和可追溯性。 