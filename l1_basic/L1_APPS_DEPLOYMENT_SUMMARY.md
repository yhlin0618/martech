# L1 Basic 應用程式部署總結

## 🎯 完成的工作

### 1. Git 同步
- ✅ 執行了 `quick_sync_all.sh` 同步所有 repositories
- ✅ 主倉庫、submodule 和 subrepos 都已同步到最新

### 2. 配置檔案準備
為每個應用程式創建了 `app_config.yaml`：

| 應用程式 | GitHub Repository | 狀態 |
|---------|------------------|------|
| positioning_app | kiki830621/positioning_app | ✅ 已配置 |
| VitalSigns | kiki830621/VitalSigns | ✅ 已配置 |
| InsightForge | kiki830621/InsightForge | ✅ 已配置 |

### 3. 部署腳本
每個應用程式都有：
- `deploy_now.R` - 互動式部署
- `deploy_auto.R` - 自動部署
- `.renvignore` - 避免語法錯誤

### 4. 環境變數
每個應用程式都有 `.env` 檔案，包含：
- PostgreSQL 資料庫連線資訊
- OpenAI API Keys

## 📋 部署步驟

### 方法 1：個別部署每個應用程式

```bash
# 1. positioning_app
cd positioning_app
source("deploy_now.R")

# 2. VitalSigns
cd ../VitalSigns
source("deploy_now.R")

# 3. InsightForge
cd ../InsightForge
source("deploy_now.R")
```

### 方法 2：使用總覽腳本

```r
# 在 l1_basic 目錄執行
source("deploy_all_apps.R")
```

### 方法 3：推送到 GitHub（subrepo）

```bash
# 在 l1_basic 目錄執行
./push_all_subrepos.sh
```

## 🚀 Posit Connect Cloud 部署

每個應用程式在 Posit Connect Cloud：

1. **登入** https://connect.posit.cloud
2. **創建新應用程式**：
   - 選擇 Shiny
   - 選擇對應的 GitHub repository
3. **設定環境變數**（從 .env 複製）
4. **部署**

## ⚠️ 注意事項

1. **主檔案設定**
   - positioning_app 使用 `full_app_v17.R` 作為主檔案
   - VitalSigns 和 InsightForge 使用 `app.R`

2. **Git Subrepo**
   - 每個應用程式都是獨立的 git-subrepo
   - 修改後需要推送到各自的 repository

3. **環境變數安全**
   - 確保 `.env` 檔案不會提交到 Git
   - API Keys 需要定期更新

## 📌 快速連結

- [positioning_app](https://github.com/kiki830621/positioning_app)
- [VitalSigns](https://github.com/kiki830621/VitalSigns)
- [InsightForge](https://github.com/kiki830621/InsightForge)

## 🔧 疑難排解

### manifest.json 更新失敗
手動執行：
```r
library(rsconnect)
rsconnect::writeManifest()
```

### 找不到部署腳本
確保在正確的目錄，或使用完整路徑：
```r
source("/path/to/app/deploy_now.R")
``` 