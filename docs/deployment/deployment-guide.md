# AI MarTech 應用部署指南

## 部署目標

| 平台 | 適合場景 | 網址格式 |
|------|---------|---------|
| **Posit Connect Cloud**（預設） | 生產環境、企業部署 | `https://{account}-{app}.share.connect.posit.cloud/` |
| **ShinyApps.io** | 開發測試、小型專案 | `https://{account}.shinyapps.io/{app-name}/` |

### 平台配置

在 `.env` 中設定：

```bash
# Posit Connect（預設）
DEPLOY_TARGET=connect
CONNECT_SERVER=https://your-posit-connect-server.com
CONNECT_API_KEY=your-api-key-here

# ShinyApps.io
DEPLOY_TARGET=shinyapps
SHINYAPPS_ACCOUNT=your-account
SHINYAPPS_APP_NAME=your-app-name
```

## 通用準備工作

### 應用程式結構

```
your-app/
├── app.R 或 (ui.R + server.R)
├── data/               # 資料檔案
├── www/               # 靜態資源
├── scripts/           # 輔助腳本
└── manifest.json      # Posit Connect Cloud 需要
```

### 安裝 rsconnect

```r
install.packages("rsconnect")
library(rsconnect)
```

## ShinyApps.io 部署

### 設置帳號

1. 註冊 [ShinyApps.io](https://www.shinyapps.io/)
2. 取得 Token（帳號 → Tokens → Show）

```r
rsconnect::setAccountInfo(
  name = 'your-account-name',
  token = 'your-token',
  secret = 'your-secret'
)
```

### 部署

```r
rsconnect::deployApp(
  appDir = "path/to/your/app",
  appName = "your-app-name",
  appFiles = c("app.R", "data/your-data.csv", "www/style.css")
)
```

### 限制

- 免費層：5 個應用，25 小時/月，1GB RAM
- 不支援某些系統套件

## Posit Connect Cloud 部署

### 前置需求

- GitHub 帳號 + 儲存庫
- Posit Connect Cloud 帳號

### 步驟

1. **生成 manifest.json**
   ```r
   rsconnect::writeManifest(appPrimaryDoc = "app.R")
   ```

2. **推送到 GitHub**
   ```bash
   git add manifest.json
   git commit -m "Add manifest.json"
   git push
   ```

3. **在 Connect Cloud 部署**
   - 登入 → Publish → Shiny → 選 GitHub repo → 選 branch → Publish

4. **更新**：推送到 GitHub 後點「Republish」

### 環境變數

在 Posit Connect 的「Advanced settings → Configure variables」設定：

```bash
PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, PGSSLMODE
OPENAI_API_KEY
```

## 最佳實踐

### 依賴管理

```r
renv::init()
renv::snapshot()
```

### 性能優化

```r
library(memoise)
expensive_function <- memoise(function(x) { ... })
global_data <- readRDS("data/preprocessed.rds")
```

## 疑難排解

| 問題 | 解決方案 |
|------|---------|
| 套件版本衝突 | `remotes::install_version("pkg", version = "x.y.z")` |
| 文件路徑問題 | 使用相對路徑或 `here::here()` |
| 記憶體限制 | 使用 data.table/arrow，實施分頁載入 |
| 部署失敗 | `options(rsconnect.http.verbose = TRUE)` 啟用詳細日誌 |

## 相關資源

- [ShinyApps.io 文檔](https://docs.rstudio.com/shinyapps.io/)
- [Posit Connect Cloud 文檔](https://docs.posit.co/connect-cloud/)
- [rsconnect 套件文檔](https://rstudio.github.io/rsconnect/)
- [Vanity URL 設定](vanity-url.md)
