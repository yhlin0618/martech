# DNA 分析資料格式要求

此頁面說明 InsightForge 精準行銷平台的 DNA 分析功能所需的資料格式。

## 📋 資料格式概述

DNA 分析需要 **銷售交易資料** 來分析客戶行為模式。請確保上傳的銷售資料包含以下必要欄位：

## 🔧 必要欄位

### 客戶識別
- **customer_id** 或 **buyer_email**: 客戶唯一識別碼
  - 可以是郵件地址或其他唯一客戶編號
  - 例：`customer123@email.com`, `C001234`

### 交易時間
- **payment_time** 或 **time** 或 **order_date**: 交易日期時間
  - 格式：`YYYY-MM-DD HH:MM:SS` 或 `YYYY-MM-DD`
  - 例：`2024-06-15 14:30:00`, `2024-06-15`

### 交易金額
- **lineitem_price** 或 **total_spent** 或 **sales** 或 **amount**: 交易金額
  - 數值型態
  - 例：`299.99`, `1580`

## 🎯 選填欄位

### 產品資訊
- **Variation**: 產品變體或品牌名稱
- **sku** 或 **asin**: 產品編號
- **product_line_id**: 產品線分類

### 地理資訊
- **ship_postal_code**: 配送郵遞區號（可用於客戶分群）

## 📊 資料範例

### 最小可行資料格式
```csv
customer_id,payment_time,lineitem_price
customer001,2024-06-01 10:30:00,299.99
customer001,2024-06-15 15:45:00,199.50
customer002,2024-06-02 09:15:00,499.00
customer002,2024-06-10 14:20:00,159.99
customer002,2024-06-20 16:10:00,299.99
```

### 完整格式範例
```csv
customer_id,payment_time,lineitem_price,Variation,sku,ship_postal_code
customer001,2024-06-01 10:30:00,299.99,Brand_A,SKU001,10001
customer001,2024-06-15 15:45:00,199.50,Brand_A,SKU002,10001
customer002,2024-06-02 09:15:00,499.00,Brand_B,SKU003,20002
customer002,2024-06-10 14:20:00,159.99,Brand_B,SKU004,20002
customer002,2024-06-20 16:10:00,299.99,Brand_A,SKU001,20002
```

## 🚀 DNA 分析輸出

成功分析後，系統將生成以下客戶 DNA 指標：

### 核心指標
- **R (Recency)**: 最近購買天數
- **F (Frequency)**: 購買頻率 
- **M (Monetary)**: 購買金額
- **IPT (Inter-Purchase Time)**: 購買間隔時間

### 進階指標
- **CAI (Customer Activity Index)**: 客戶活躍度指數
- **PCV (Past Customer Value)**: 過去客戶價值
- **CLV (Customer Lifetime Value)**: 客戶終身價值
- **NES (Next Expected Shopping)**: 下次預期購買狀態

### 視覺化分析
- 客戶分佈圖表 (ECDF)
- 頻率直方圖
- NES 狀態分佈
- 統計摘要表

## ⚠️ 注意事項

1. **資料品質要求**：
   - 每位客戶至少需要 2 筆以上的交易記錄
   - 交易時間需按時間順序排列
   - 金額必須為正數

2. **檔案格式支援**：
   - Excel (.xlsx, .xls)
   - CSV (.csv)
   - 支援多檔案合併上傳

3. **欄位名稱**：
   - 系統會自動識別常見的欄位名稱變體
   - 建議使用上述標準欄位名稱以確保最佳相容性

4. **資料隱私**：
   - 客戶 ID 會被自動編碼處理
   - 分析結果僅顯示統計指標，不包含個人識別資訊 