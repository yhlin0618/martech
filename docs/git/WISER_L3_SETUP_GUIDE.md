# WISER L3 Enterprise 設定指南

## 專案移動完成

已成功將 WISER 專案從原位置移至：
```
ai_martech/l4_enterprise/WISER/
```

## 已完成的清理工作

1. 刪除了所有備份 zip 目錄
2. 刪除了測試和舊版本文件：
   - `app_old_WISE.R`
   - `clustered_res*.csv`
   - `microDNADistribution_production_test.R`

3. 更新了 `app_config.yaml`：
   - 設定為 L3 Enterprise 層級
   - 更新品牌名稱為 WISER
   - 添加部署配置

4. 初始化了 Git repository 並完成初始提交

## ⚠️ 重要提醒

**OpenAI API Key 已暴露！**
在原始的 `app_config.yaml` 中發現了硬編碼的 API key：
```
OPENAI_API_KEY: "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"
```

請立即：
1. 在 OpenAI 控制台中撤銷此 key
2. 生成新的 API key
3. 將新 key 保存在 `.env` 文件中（不要提交到版本控制）

## 下一步：創建 GitHub Repository

### 1. 在 GitHub 創建新倉庫
- 名稱：`WISER`
- 描述：`WISER L3 Enterprise Platform - Complete precision marketing solution`
- 設為私有倉庫（Private）

### 2. 推送到 GitHub
```bash
cd l4_enterprise/WISER
git remote add origin git@github.com:kiki830621/WISER.git
git branch -M main
git push -u origin main
```

### 3. 設定為 Git Subrepo
回到主倉庫根目錄：
```bash
cd /Users/che/Library/CloudStorage/Dropbox/ai_martech
git subrepo init l4_enterprise/WISER -r git@github.com:kiki830621/WISER.git -b main
git add -A
git commit -m "Add WISER as L3 Enterprise subrepo"
git push
```

## 環境變數設定

請創建 `l4_enterprise/WISER/.env` 文件：
```env
# PostgreSQL Database Connection
PGHOST=your_database_host
PGPORT=5432
PGUSER=your_username
PGPASSWORD=your_password
PGDATABASE=wiser_enterprise
PGSSLMODE=require

# OpenAI API Key (請使用新的 key)
OPENAI_API_KEY=your_new_openai_api_key
OPENAI_API_KEY=your_secondary_openai_api_key

# Deployment Settings
DEPLOY_TARGET=connect
ACCOUNT_NAME=kyle-lin
```

## 專案結構說明

WISER 是 L3 企業版的完整解決方案，包含了：
- 完整的客戶 DNA 分析
- 精準行銷功能
- 企業級數據處理能力
- 多平台支持（Amazon + 官網）

與 L1 基礎版的模組化應用不同，L3 是一個完整的整合平台，適合大型企業使用。 