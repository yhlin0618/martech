# Positioning App 部署指南

本文檔記錄 positioning_app 的部署歷史和具體部署指令。

## 部署歷史

### ShinyApps.io 部署

- **URL**: https://kyle-lin.shinyapps.io/positioning_app/
- **帳號**: kyle-lin
- **App ID**: 14821732
- **最後部署**: 2024-06-27

### Posit Connect Cloud 部署

- **manifest.json**: ✅ 已生成（4339行）
- **主要文件**: full_app_v17.R
- **R 版本**: 4.5.0

## 快速部署指令

### 部署到 ShinyApps.io

```r
# 1. 載入 rsconnect
library(rsconnect)

# 2. 設置帳號（如果尚未設置）
# rsconnect::setAccountInfo(
#   name = 'kyle-lin',
#   token = 'YOUR_TOKEN',
#   secret = 'YOUR_SECRET'
# )

# 3. 切換到應用目錄
setwd("l1_basic/positioning_app")

# 4. 部署應用
rsconnect::deployApp(
  appName = "positioning_app",
  appTitle = "positioning_app",
  appFiles = c(
    "full_app_v17.R",
    "app.R",  # 如果 app.R 是 full_app_v17.R 的複製
    "data/",
    "www/",
    "icons/"
  ),
  forceUpdate = TRUE
)

# 5. 查看部署狀態
rsconnect::showLogs(appName = "positioning_app")
```

### 部署到 Posit Connect Cloud

```r
# 1. 更新 manifest.json（如果需要）
setwd("l1_basic/positioning_app")
rsconnect::writeManifest(appPrimaryDoc = "full_app_v17.R")

# 2. 確保 app.R 是最新版本
file.copy("full_app_v17.R", "app.R", overwrite = TRUE)

# 3. 推送到 GitHub
# git add .
# git commit -m "Update for Posit Connect Cloud deployment"
# git push
```

然後在 Posit Connect Cloud 網頁介面：
1. 登入 https://connect.posit.cloud/
2. 點擊 "Publish"
3. 選擇 "Shiny"
4. 選擇 positioning_app 的 GitHub 儲存庫
5. 選擇 app.R 作為主要文件
6. 點擊 "Publish"

## 應用結構

```
positioning_app/
├── full_app_v17.R          # 主要應用文件
├── app.R                   # 部署用（full_app_v17.R 的複製）
├── manifest.json           # Posit Connect Cloud 依賴清單
├── rsconnectsetting.R      # rsconnect 設定腳本
├── data/                   # 數據文件
├── www/                    # 靜態資源
├── icons/                  # 圖標文件
├── database/               # 資料庫文件
└── rsconnect/              # 部署配置
    └── documents/
        └── full_app_v17.R/
            └── shinyapps.io/
                └── kyle-lin/
                    └── positioning_app.dcf
```

## 重要文件說明

### manifest.json
- 自動生成的依賴清單
- 包含所有 R 套件版本資訊
- Posit Connect Cloud 部署必需

### rsconnectsetting.R
```r
rsconnect::writeManifest(appPrimaryDoc = "full_app_v17.R")
```

### 部署配置 (.dcf)
位於 `rsconnect/documents/full_app_v17.R/shinyapps.io/kyle-lin/positioning_app.dcf`
記錄了 ShinyApps.io 的部署資訊。

## 版本管理

目前有多個版本的應用文件：
- full_app_v10.R 到 full_app_v17.R
- 當前生產版本：full_app_v17.R

部署前請確認：
1. app.R 是最新版本的複製
2. manifest.json 是最新的
3. 所有必要的數據文件都已包含

## 注意事項

1. **數據安全**：確保敏感數據不被上傳
2. **文件大小**：ShinyApps.io 有文件大小限制
3. **依賴管理**：確保所有套件都在 manifest.json 中
4. **路徑問題**：使用相對路徑，避免絕對路徑
5. **環境變數**：確保 PostgreSQL 環境變數已正確設定（見 [POSTGRESQL_SETUP.md](POSTGRESQL_SETUP.md)）

## 疑難排解

### 常見問題

1. **部署失敗**
   ```r
   # 查看詳細錯誤
   options(rsconnect.http.verbose = TRUE)
   rsconnect::deployApp(logLevel = "verbose")
   ```

2. **套件版本問題**
   ```r
   # 重新生成 manifest.json
   rsconnect::writeManifest(appPrimaryDoc = "full_app_v17.R")
   ```

3. **文件找不到**
   - 檢查文件路徑是否正確
   - 確認文件已包含在 appFiles 中

## 聯絡資訊

- ShinyApps.io 帳號：kyle-lin
- 應用 URL：https://kyle-lin.shinyapps.io/positioning_app/

最後更新：2024-01-15 