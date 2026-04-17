# Positioning App PostgreSQL 設定指南

本文檔說明如何為 positioning_app 設定 PostgreSQL 資料庫連接，包含本地開發和雲端部署的配置方法。

## 目錄

1. [資料庫連接模式](#資料庫連接模式)
2. [本地開發設定](#本地開發設定)
3. [環境變數配置](#環境變數配置)
4. [Posit Connect Cloud 部署](#posit-connect-cloud-部署)
5. [ShinyApps.io 部署](#shinyappsio-部署)
6. [資料庫結構](#資料庫結構)
7. [安全最佳實踐](#安全最佳實踐)

## 資料庫連接模式

positioning_app 支援兩種資料庫模式：

### 1. SQLite 模式（本地開發）
- 檔案：`db_ini.R`
- 資料庫：`users.sqlite`
- 適用：本地測試、開發環境

### 2. PostgreSQL 模式（生產環境）
- 檔案：`db_ini_online.R`, `full_app_v17.R`
- 使用環境變數配置
- 適用：雲端部署、生產環境

## 本地開發設定

### 步驟 1：創建 .env 文件

在 `l1_basic/positioning_app/` 目錄下創建 `.env` 文件：

```bash
# PostgreSQL 連接設定
PGHOST=localhost
PGPORT=5432
PGUSER=your_username
PGPASSWORD=your_password
PGDATABASE=positioning_app_db
PGSSLMODE=prefer

# 其他 API 金鑰（如需要）
# OPENAI_API_KEY=your_openai_api_key
```

### 步驟 2：確保 .gitignore 包含 .env

檢查 `.gitignore` 文件包含：

```
.env
.Renviron
```

### 步驟 3：本地測試

```r
# 測試資料庫連接
source("db_ini_online.R")
```

## 環境變數配置

### 必需的 PostgreSQL 環境變數

| 變數名稱 | 說明 | 預設值 |
|---------|------|--------|
| `PGHOST` | PostgreSQL 主機地址 | 無 |
| `PGPORT` | 連接埠 | 5432 |
| `PGUSER` | 資料庫使用者名稱 | 無 |
| `PGPASSWORD` | 資料庫密碼 | 無 |
| `PGDATABASE` | 資料庫名稱 | 無 |
| `PGSSLMODE` | SSL 連接模式 | require |

### 應用程式中的使用方式

```r
# 從 full_app_v17.R
library(dotenv)
dotenv::load_dot_env(file = ".env")

get_con <- function() {
  con <- dbConnect(
    Postgres(),
    host     = Sys.getenv("PGHOST"),
    port     = as.integer(Sys.getenv("PGPORT", 5432)),
    user     = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname   = Sys.getenv("PGDATABASE"),
    sslmode  = Sys.getenv("PGSSLMODE", "require")
  )
  # ... 建表邏輯
  con
}
```

## Posit Connect Cloud 部署

### 步驟 1：準備部署

確保您的 GitHub 儲存庫中**不包含** `.env` 文件。

### 步驟 2：在 Connect Cloud 設定環境變數

1. 登入 [Posit Connect Cloud](https://connect.posit.cloud/)
2. 點擊 "Publish" 按鈕
3. 選擇 "Shiny"
4. 選擇您的 GitHub 儲存庫
5. 選擇 `app.R` 或 `full_app_v17.R` 作為主要文件
6. 點擊 **"Advanced settings"**
7. 在 **"Configure variables"** 下點擊 **"Add variable"**
8. 添加以下環境變數：

```
Name: PGHOST
Value: your-database-host.com

Name: PGPORT
Value: 5432

Name: PGUSER
Value: your_db_username

Name: PGPASSWORD
Value: your_db_password

Name: PGDATABASE
Value: your_database_name

Name: PGSSLMODE
Value: require
```

9. 點擊 "Publish"

## ShinyApps.io 部署

### 方法 1：使用 rsconnect 設定環境變數

```r
library(rsconnect)

# 部署時包含環境變數
rsconnect::deployApp(
  appName = "positioning_app",
  envVars = c(
    "PGHOST",
    "PGPORT", 
    "PGUSER",
    "PGPASSWORD",
    "PGDATABASE",
    "PGSSLMODE"
  )
)
```

### 方法 2：在 ShinyApps.io 儀表板設定

1. 登入 [ShinyApps.io](https://www.shinyapps.io/)
2. 進入您的應用程式設定
3. 找到 "Settings" → "Environment Variables"
4. 添加所需的環境變數

## 資料庫結構

positioning_app 會自動創建以下表格：

### users 表
```sql
CREATE TABLE IF NOT EXISTS users (
  id           SERIAL PRIMARY KEY,
  username     TEXT UNIQUE,
  hash         TEXT,
  role         TEXT DEFAULT 'user',
  login_count  INTEGER DEFAULT 0,
  email        TEXT,
  fail_count   INTEGER DEFAULT 0,
  last_fail    TEXT,
  reset_token  TEXT,
  token_expiry TEXT
);
```

### rawdata 表
```sql
CREATE TABLE IF NOT EXISTS rawdata (
  id           SERIAL PRIMARY KEY,
  user_id      INTEGER REFERENCES users(id),
  uploaded_at  TIMESTAMPTZ DEFAULT now(),
  json         JSONB
);
```

### processed_data 表
```sql
CREATE TABLE IF NOT EXISTS processed_data (
  id            SERIAL PRIMARY KEY,
  user_id       INTEGER REFERENCES users(id),
  processed_at  TIMESTAMPTZ DEFAULT now(),
  json          JSONB
);
```

## 安全最佳實踐

### 1. 環境變數管理

- **永遠不要**將 `.env` 文件提交到版本控制
- 使用 `.gitignore` 排除敏感文件
- 為不同環境使用不同的資料庫憑證

### 2. 資料庫安全

- 使用 SSL 連接（`PGSSLMODE=require`）
- 限制資料庫使用者權限
- 定期更換密碼
- 使用強密碼

### 3. 應用程式安全

- 密碼使用 bcrypt 加密
- 實施登入次數限制
- 記錄失敗的登入嘗試

### 4. 部署檢查清單

- [ ] 確認 `.env` 不在 Git 儲存庫中
- [ ] 所有環境變數都已在部署平台設定
- [ ] SSL 模式設為 `require`
- [ ] 資料庫備份策略已建立
- [ ] 監控和日誌記錄已啟用

## 故障排除

### 常見問題

1. **連接失敗**
   ```r
   # 檢查環境變數是否正確載入
   print(Sys.getenv("PGHOST"))
   print(Sys.getenv("PGUSER"))
   ```

2. **SSL 錯誤**
   - 確認 `PGSSLMODE` 設定正確
   - 某些主機可能需要 `PGSSLMODE=disable`（僅限開發環境）

3. **權限錯誤**
   - 確認資料庫使用者有創建表格的權限
   - 檢查資料庫是否存在

### 測試連接

```r
# 簡單的連接測試腳本
library(DBI)
library(RPostgres)
library(dotenv)

dotenv::load_dot_env()

tryCatch({
  con <- dbConnect(
    Postgres(),
    host     = Sys.getenv("PGHOST"),
    port     = as.integer(Sys.getenv("PGPORT", 5432)),
    user     = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname   = Sys.getenv("PGDATABASE"),
    sslmode  = Sys.getenv("PGSSLMODE", "require")
  )
  
  print("✅ 連接成功！")
  dbDisconnect(con)
  
}, error = function(e) {
  print(paste("❌ 連接失敗：", e$message))
})
```

## 相關資源

- [RPostgres 文檔](https://rpostgres.r-dbi.org/)
- [PostgreSQL 官方文檔](https://www.postgresql.org/docs/)
- [Posit Connect Cloud 環境變數指南](https://docs.posit.co/connect-cloud/)
- [ShinyApps.io 部署指南](https://docs.rstudio.com/shinyapps.io/)

最後更新：2024-01-15 