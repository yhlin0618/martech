# KM Amazon 銷售資料處理指南

## 📊 資料格式說明

KM_eg 目錄包含 Kitchen Mama 的 Amazon 銷售報告資料，具有以下特徵：

### 檔案結構
- **檔案數量**: 4個CSV檔案 (2023年2月份不同週期)
- **資料大小**: 每個檔案約2-6MB
- **記錄數量**: 總計約20,000+筆交易記錄
- **客戶數量**: 約15,000+個唯一客戶

### 關鍵欄位
| 原始欄位名稱 | 對應功能 | 範例 |
|-------------|---------|------|
| `Buyer Email` | 客戶識別碼 | `6dmg40tnw1lps6v@marketplace.amazon.com` |
| `Purchase Date` | 購買時間 | `2023-02-07T16:44:18-08:00` |
| `Item Price` | 商品價格 | `29.99` |
| `Title` | 商品名稱 | `Kitchen Mama Electric Can Opener...` |

## 🔧 電子郵件客戶ID處理

### 問題背景
Amazon 銷售報告使用匿名化的電子郵件作為客戶識別碼，如：
- `6dmg40tnw1lps6v@marketplace.amazon.com`
- `4lqxnhd5fds253y@marketplace.amazon.com`

這些無法直接轉換為數值型，需要特殊處理。

### 解決方案
系統自動執行以下步驟：

1. **自動偵測電子郵件格式**
   ```r
   # 偵測包含 "@" 的customer_id
   if(any(grepl("@", customer_id, fixed = TRUE)))
   ```

2. **創建一對一映射**
   ```r
   # 使用factor確保穩定映射
   customer_id = as.integer(as.factor(customer_id))
   ```

3. **保留原始資訊**
   ```r
   # 備份原始電子郵件
   original_customer_id = customer_id
   ```

## 📋 處理流程

### 步驟1：上傳檔案
1. 選擇 KM_eg 目錄中的所有4個CSV檔案
2. 啟用「自動偵測欄位」選項
3. 點擊「🚀 合併檔案並分析」

### 步驟2：自動處理
系統自動執行：
- 偵測 `Buyer Email` → `customer_id`
- 偵測 `Purchase Date` → `payment_time` 
- 偵測 `Item Price` → `lineitem_price`
- 合併4個檔案
- 電子郵件到數字ID映射

### 步驟3：DNA分析
- 最少交易次數：建議設為 `2`
- 時間折扣因子：使用預設 `0.1`
- 自動執行完整DNA分析

## 📊 預期結果

### 資料統計
```
✅ 電子郵件映射完成: 15000個唯一客戶
✅ 資料處理完成，有效記錄: 20000 客戶數: 15000
🧬 DNA 分析完成！
```

### 電子郵件映射表
在「📧 客戶ID映射」tab中可以看到：

| 原始電子郵件 | 數字客戶ID |
|-------------|-----------|
| 6dmg40tnw1lps6v@marketplace.amazon.com | 1001 |
| 4lqxnhd5fds253y@marketplace.amazon.com | 1002 |
| ... | ... |

### DNA分析結果
- **R值 (Recency)**: 最近購買時間
- **F值 (Frequency)**: 購買頻率
- **M值 (Monetary)**: 平均消費金額
- **NES狀態**: 客戶參與度等級
- **CLV**: 客戶終身價值

## 🔍 技術詳情

### 欄位偵測邏輯
```r
# 優先順序：電子郵件欄位
email_patterns <- c("buyer email", "buyer_email", "buyer.email", "email")

# 時間欄位（支援Amazon格式）
time_patterns <- c("purchase date", "purchase.date", "payments date", "payments.date")

# 金額欄位（支援Amazon格式）
amount_patterns <- c("item price", "item.price", "lineitem_price")
```

### 資料清理
- 移除無效記錄（NA值）
- 確保價格 > 0
- 統一時間格式為 POSIXct
- 創建平台標識 `platform_id = "upload"`

## ⚠️ 注意事項

1. **檔案大小**: 建議逐個或分批上傳以避免記憶體問題
2. **處理時間**: 大型檔案可能需要幾分鐘處理時間
3. **客戶隱私**: 原始電子郵件已經過Amazon匿名化
4. **欄位格式**: 系統自動處理點號分隔的欄位名稱 (`Buyer.Email`)

## 🎯 使用建議

### 分析參數建議
- **最少交易次數**: 2-3 (考慮到單次購買客戶)
- **時間折扣因子**: 0.1 (標準設定)
- **分析重點**: 關注回購客戶的行為模式

### 業務洞察
- 識別高價值回購客戶
- 分析季節性購買模式
- 優化客戶留存策略
- 個性化行銷方案

這個處理流程確保了Amazon銷售資料的完整分析，同時保持了資料的隱私性和準確性。 