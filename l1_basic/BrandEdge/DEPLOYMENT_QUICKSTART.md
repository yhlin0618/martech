# 🚀 部署快速開始

## 最簡單的方式：一鍵部署

部署腳本包含**自動路徑偵測**功能，會自動找到並切換到正確的專案目錄。

### 方法 1：互動式部署（推薦）
```bash
# 在專案目錄執行
Rscript deploy_now.R

# 或從任何地方執行（自動偵測專案位置）
Rscript /path/to/positioning_app/deploy_now.R
```
這會引導您完成所有部署步驟。

### 方法 2：自動部署
```bash
# 在專案目錄執行
Rscript deploy_auto.R

# 或從任何地方執行（自動偵測專案位置）
Rscript /path/to/positioning_app/deploy_auto.R
```
自動完成所有準備工作，然後顯示部署指示。

## 部署流程

兩個腳本都會：
1. ✅ 更新 app.R 到最新版本
2. ✅ 更新 manifest.json
3. ✅ 檢查關鍵檔案
4. ✅ 顯示 Git 狀態
5. 📋 提供部署指示

## Posit Connect Cloud 部署

執行腳本後，按照指示：
1. 登入 https://connect.posit.cloud
2. 點擊 Publish → Shiny
3. 填寫：
   - Repository: `kiki830621/ai_martech`
   - Application Path: `l1_basic/positioning_app`
   - Primary File: `app.R`
   - Branch: `main`

## 更多工具

所有部署工具都在：
```
scripts/global_scripts/23_deployment/
```

詳細文檔請參考：
- `scripts/global_scripts/23_deployment/05_docs/COMPLETE_DEPLOYMENT_GUIDE.md`
- `scripts/global_scripts/23_deployment/05_docs/POSIT_CONNECT_CLOUD_GITHUB_DEPLOYMENT.md` 