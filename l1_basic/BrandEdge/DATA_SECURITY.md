# 資料安全策略

## 概述
為了保護資料安全和用戶隱私，本專案採用「零資料」版本控制策略。所有資料檔案（CSV、Excel、資料庫等）都不會上傳到 GitHub。

## 安全優勢
1. **防止資料洩露**：即使 GitHub 帳號被盜，攻擊者也無法獲得任何實際資料
2. **保護隱私**：客戶評論、銷售數據等敏感資訊不會公開
3. **降低風險**：避免意外提交包含個人資訊的檔案

## 資料獲取方式

### 開發者
請聯繫專案管理員獲取：
1. 測試資料集的安全下載連結
2. 資料庫範本檔案
3. API 金鑰（如需要）

### 使用者
應用程式會提供：
1. 資料上傳介面
2. 範例資料生成器
3. 資料匯入指南

## 本地開發設置

### 1. 創建必要的空資料庫
```r
# 創建空的 SQLite 資料庫
library(DBI)
library(RSQLite)

# 創建使用者資料庫
con <- dbConnect(SQLite(), "database/users.sqlite")
dbExecute(con, "
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
")
dbDisconnect(con)
```

### 2. 生成測試資料
```r
# 生成假的評論資料
generate_fake_reviews <- function(n = 100) {
  data.frame(
    review_id = 1:n,
    product = sample(c("Product A", "Product B", "Product C"), n, replace = TRUE),
    rating = sample(1:5, n, replace = TRUE),
    comment = sample(c("很好", "不錯", "普通", "需要改進"), n, replace = TRUE),
    date = seq(Sys.Date() - 100, Sys.Date(), length.out = n)
  )
}

# 儲存到 test 目錄
write.csv(generate_fake_reviews(), "data/test/fake_reviews.csv", row.names = FALSE)
```

## 資料檔案結構（僅供參考）

雖然實際檔案不在版本控制中，但預期的檔案結構如下：

```
data/
├── sample/
│   └── amazon_can_opener_reviews.xlsx  # 範例評論資料
├── test/
│   └── fake_data.xlsx                  # 測試資料
└── user/
    └── (使用者上傳的檔案)

database/
└── users.sqlite                        # 使用者認證資料庫
```

## 部署注意事項

部署時需要：
1. 手動上傳必要的資料檔案
2. 設置適當的檔案權限
3. 配置資料備份策略
4. 實施存取控制

## 緊急聯絡

如需資料存取權限，請聯繫：
- 專案管理員：[請填寫聯絡方式]
- 備用聯絡人：[請填寫聯絡方式] 