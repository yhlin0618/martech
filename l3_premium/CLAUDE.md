# L3 Premium 層專案設定指引

此文件為 Claude AI 在 L3 Premium 層建立新專案的標準作業程序。

## 📋 新專案設定檢查清單

### 1. 專案目錄結構
```bash
l3_premium/
├── [client_name]_[app_name]_premium/  # 客戶專屬應用
│   ├── app.R                          # 主應用程式
│   ├── app_config.yaml                # 應用配置
│   ├── .gitignore                     # Git 忽略規則
│   └── scripts/
│       └── global_scripts -> ../../../global_scripts  # 符號連結
└── [standard_app]_premium/            # 標準應用
    └── (同上結構)
```

### 2. 建立新專案步驟

#### Step 1: 複製基礎應用
```bash
# 選擇一個現有應用作為模板（如 TagPilot_premium）
cp -r TagPilot_premium [new_app_name]_premium
cd [new_app_name]_premium
```

#### Step 2: 清理舊檔案
```bash
# 刪除舊的 Git 資訊
rm -rf .git
rm -rf .Rproj.user
rm -f *.Rproj

# 清理 archive 和測試資料
rm -rf archive/*
rm -rf data/test_data/*
```

#### Step 3: 設定 git subrepo
```bash
# 移除舊的符號連結或目錄
rm -rf scripts/global_scripts

# 使用 git subrepo clone 建立 subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

# 這會：
# 1. 複製 global_scripts 的內容到 scripts/global_scripts
# 2. 建立 scripts/global_scripts/.gitrepo 檔案追蹤 subrepo 資訊
# 3. 自動 commit 這些變更
```

#### Step 4: 設定 Git
```bash
# 初始化 Git
git init

# 建立 .gitignore（如果不存在）
cat > .gitignore << 'EOF'
# R and RStudio
.Rproj.user
.Rhistory
.RData
.Ruserdata
*.Rproj

# Environment
.env
.env.local

# Data
*.db
*.sqlite
*.duckdb
data/
database/*.db

# Large files
*.xlsx
*.csv

# Cache
cache/
temp/
*.log

# OS
.DS_Store

# Deployment
rsconnect/
manifest.json
EOF

# 初始 commit
git add -A
git commit -m "Initial commit: [App Name] Premium

- [簡短描述應用功能]
- Premium tier application
- Based on [template_name] template"
```

#### Step 5: 推送到 GitHub
```bash
# 使用 GitHub CLI 建立私有 repository
gh repo create [repository_name] --private --source=. --remote=origin --push
```

## 🏷️ 命名規範

### 客戶專屬應用
- 格式：`[client_name]_[app_name]_premium`
- 範例：`wonderful_food_BrandEdge_premium`
- GitHub repo：同名

### 標準應用
- 格式：`[app_name]_premium`
- 範例：`TagPilot_premium`
- GitHub repo：同名

## 📝 app_config.yaml 模板

```yaml
app_info:
  name: "[App Name] Premium"
  version: "1.0.0"
  tier: "l3_premium"
  client: "[client_name]"  # 如果是客戶專屬
  
database:
  type: "postgresql"
  test_mode: false
  
deployment:
  target: "connect"
  account: "kyle-lin"
  
modules:
  - name: "module_name"
    enabled: true
    
theme:
  primary_color: "#007bff"
  bootswatch: "cosmo"
```

## 🔗 更新 CLAUDE_GIT.md

新增專案後，記得更新 `/projects/ai_martech/CLAUDE_GIT.md`：

1. 在 L3 Premium 層區塊新增專案資訊
2. 更新 Repository 統計數據
3. 記錄建立時間

## 📦 Subrepo 管理

### 初次設定
```bash
# 在專案根目錄執行
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
```

### 更新 global_scripts
```bash
# 從遠端拉取最新版本
git subrepo pull scripts/global_scripts

# 推送本地修改到遠端（需要權限）
git subrepo push scripts/global_scripts
```

### 檢查 subrepo 狀態
```bash
git subrepo status scripts/global_scripts
```

### Subrepo vs 符號連結
- **L1/L2/L4 層**：使用 git subrepo（獨立版本控制）
- **L3 Premium 層**：建議使用 git subrepo（與其他層保持一致）
- **Wonderful Food 專案**：目前使用符號連結（可考慮改為 subrepo）

## ⚠️ 注意事項

1. **環境變數**：不要將 `.env` 檔案加入 Git
2. **資料保護**：確保客戶資料不被追蹤
3. **Subrepo 設定**：使用 git subrepo 而非符號連結
4. **權限設定**：GitHub repository 預設設為 private
5. **Commit 順序**：先設定 subrepo 再做初始 commit

## 🎯 快速命令（給 Claude 使用）

### 為 Wonderful Food 建立新應用
```bash
# 設定變數
CLIENT="wonderful_food"
APP_NAME="NewApp"
FULL_NAME="${CLIENT}_${APP_NAME}_premium"

# 執行建立流程
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l3_premium
cp -r TagPilot_premium $FULL_NAME
cd $FULL_NAME
rm -rf .git .Rproj.user *.Rproj
rm -rf scripts/global_scripts
git init
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
git add -A
git commit -m "Initial commit: ${CLIENT} ${APP_NAME} Premium with subrepo"
gh repo create $FULL_NAME --private --source=. --remote=origin --push
```

### 為標準應用建立
```bash
# 設定變數
APP_NAME="NewStandardApp"
FULL_NAME="${APP_NAME}_premium"

# 執行建立流程（同上，但不含 client 前綴）
```

---
**最後更新**: 2025-09-11
**用途**: Claude AI 專用操作指引