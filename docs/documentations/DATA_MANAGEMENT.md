# 資料檔案管理規範

## 目錄結構

每個產品層級應遵循以下資料目錄結構：

```
l1_basic/
├── positioning_app/
│   ├── app.R
│   ├── app_data/          # 應用程式必要資料（需納入版控）
│   │   ├── parameters/    # 參數設定檔
│   │   ├── structure/     # 資料結構定義
│   │   └── *.duckdb      # 核心資料庫（但不含敏感資料）
│   ├── data/              # 使用者資料（不納入版控）
│   │   ├── sample/        # 範例資料
│   │   ├── test/          # 測試資料
│   │   └── user/          # 使用者上傳
│   ├── database/          # 使用者資料庫（不納入版控）
│   │   └── users.sqlite
│   └── cache/             # 暫存檔案（不納入版控）
│       └── .gitkeep
```

## 資料分類與版本控制策略

### 1. 應用程式資料 (app_data/) ✅ 納入版控
- **目的**：應用程式運行必需的核心資料
- **內容**：
  - 參數設定檔（parameters/）
  - 資料結構定義
  - 預處理的參考資料
  - 不含個人資訊的應用資料
- **原則**：只包含公開、脫敏的資料

### 2. 使用者資料 (data/, database/) ❌ 不納入版控
- **目的**：保護隱私和安全
- **內容**：
  - 客戶評論
  - 銷售數據
  - 使用者帳號
  - 任何可識別個人的資訊
- **原則**：永不上傳到 GitHub

### 3. 壓縮檔 ❌ 不納入版控
- **原因**：避免拖慢 git 速度
- **類型**：*.zip, *.rar, *.7z, *.tar, *.gz
- **替代**：使用雲端儲存或下載連結

## 資料類型分類

### 1. 範例資料 (sample/)
- **目的**：展示功能、教學用途
- **特點**：檔案較小、已脫敏
- **管理**：納入版本控制
- **範例**：`sample_reviews.csv`, `demo_data.xlsx`

### 2. 測試資料 (test/)
- **目的**：開發測試、單元測試
- **特點**：可能包含邊界案例
- **管理**：納入版本控制
- **範例**：`fake_data.xlsx`, `test_cases.csv`

### 3. 使用者資料 (user/)
- **目的**：實際運行時的資料
- **特點**：由使用者上傳或產生
- **管理**：不納入版本控制（.gitignore）
- **範例**：使用者上傳的 CSV/XLSX

### 4. 資料庫檔案 (database/)
- **目的**：持久化儲存
- **特點**：SQLite、DuckDB 等
- **管理**：
  - 空白模板納入版本控制
  - 實際資料不納入版本控制

### 5. 暫存檔案 (cache/)
- **目的**：提升效能
- **特點**：可重新產生
- **管理**：不納入版本控制

## Git 管理策略

### .gitignore 設定
```gitignore
# 使用者資料（安全考量）
data/
database/
*.csv
*.xlsx
*.sqlite

# 但 app_data 需要上傳（應用程式必需）
!app_data/
!app_data/**/*

# 排除壓縮檔（效能考量）
*.zip
*.rar
*.7z

# 暫存檔案
cache/*
!cache/.gitkeep
```

### 資料安全原則

1. **最小必要原則**：只上傳應用程式運行必需的最小資料集
2. **脫敏處理**：app_data 中的資料必須經過脫敏處理
3. **分離存儲**：敏感資料與應用資料分開存放
4. **定期審查**：定期檢查 app_data 確保無敏感資訊

## 資料大小限制

| 環境 | CSV | Excel | 資料庫 |
|------|-----|-------|--------|
| L1 Basic | < 5MB | < 2MB | < 50MB |
| L2 Pro | < 50MB | < 20MB | < 500MB |
| L3 Enterprise | 無限制* | 無限制* | 無限制* |

*實際限制取決於部署環境

## 最佳實踐

### 1. 資料載入
```r
# 使用相對路徑
sample_data <- read.csv("data/sample/reviews.csv")

# 檢查檔案存在
if (file.exists("data/user/upload.xlsx")) {
  user_data <- readxl::read_excel("data/user/upload.xlsx")
}
```

### 2. 資料儲存
```r
# 確保目錄存在
dir.create("data/user", recursive = TRUE, showWarnings = FALSE)

# 儲存使用者資料
write.csv(processed_data, "data/user/processed_result.csv")
```

### 3. 資料安全
- 敏感資料加密儲存
- 定期清理過期檔案
- 實施存取權限控制

## 遷移步驟

1. 建立目錄結構
2. 移動現有檔案到對應目錄
3. 更新程式碼中的路徑
4. 設定 .gitignore
5. 測試資料載入功能 