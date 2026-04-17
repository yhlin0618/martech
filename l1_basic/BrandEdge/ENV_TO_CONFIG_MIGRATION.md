# 環境變數遷移指南

## 🎯 目標
將非敏感設定從 `.env` 移到 `app_config.yaml`，讓配置更清晰且可版本控制。

## 📋 遷移計畫

### 保留在 .env（敏感資訊）
```bash
# PostgreSQL 資料庫
PGHOST=your-host
PGPORT=your-port
PGUSER=your-user
PGPASSWORD=your-password
PGDATABASE=your-database
PGSSLMODE=require

# API Keys
OPENAI_API_KEY="your-key"
OPENAI_API_KEY="your-key"
```

### 已移到 app_config.yaml（非敏感資訊）
```yaml
deployment:
  target: "connect"  # 原本的 DEPLOY_TARGET
  
  shinyapps:
    account: "your-account-name"  # 原本的 SHINYAPPS_ACCOUNT
    app_name: "positioning_app"   # 原本的 SHINYAPPS_APP_NAME

app_info:
  name: "Positioning App"
  title: "Product Positioning Analysis"  # 原本的 APP_TITLE
```

## 🔧 如何遷移

### 1. 更新您的 .env
移除以下非敏感設定（已在 app_config.yaml）：
- `DEPLOY_TARGET`
- `SHINYAPPS_ACCOUNT`
- `SHINYAPPS_APP_NAME`
- `APP_TITLE`

### 2. 新的最小化 .env 範例
```bash
# 只包含敏感資訊
PGHOST=...
PGPORT=...
PGUSER=...
PGPASSWORD=...
PGDATABASE=...
PGSSLMODE=require

OPENAI_API_KEY="..."
OPENAI_API_KEY="..."
```

## 🚀 優點

1. **更安全**：敏感和非敏感資訊明確分離
2. **可版本控制**：app_config.yaml 可以安全地提交到 Git
3. **團隊協作**：共享配置更容易
4. **更清晰**：一眼就能看出哪些是機密資訊

## 📝 注意事項

- `.env` 檔案仍然不應該提交到 Git
- `app_config.yaml` 可以安全地提交
- 部署腳本會自動讀取兩個檔案的設定 