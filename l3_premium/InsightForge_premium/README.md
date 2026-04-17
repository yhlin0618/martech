# InsightForge 精準行銷平台

[![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-276DC3?style=flat&logo=r&logoColor=white)](https://shiny.rstudio.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

## 📋 專案概述

InsightForge 是一個由 AI 驅動的精準行銷平台，協助品牌根據客戶評論數據制定個人化行銷策略。整合 NLP、統計分析與行銷理論，提供從資料收集到策略建議的端到端解決方案。

## 🚀 主要功能

- 🎯 **客群分群建模** - 基於評論數據的客戶分群
- 🧠 **AI 屬性產生** - 自動識別產品關鍵屬性
- 💬 **評論語意分析** - 多維度評分與情感分析
- 📈 **品牌定位分析** - 競品比較與市場定位
- 📊 **策略建議報告** - AI 生成的行銷建議

## 📁 專案結構

```
InsightForge/
├── app.R              # 🎯 當前部署版本
├── deploy.R           # 🚀 部署腳本
├── app/               # 📦 應用程式版本管理
│   ├── app_v16.R      #     版本 16
│   └── app_v17.R      #     版本 17 (最新)
├── modules/           # 🧩 功能模組
│   ├── module_login.R
│   ├── module_score.R
│   ├── module_upload.R
│   └── module_wo_b.R
├── archive/           # 📦 歷史檔案
├── www/               # 🎨 靜態資源
├── md/                # 📄 Markdown 文檔
└── documents/         # 📋 專案文檔
```

## ⚙️ 環境設定

### 必要套件
```r
install.packages(c(
  "shiny", "shinyjs", "DBI", "RPostgres", "bcrypt",
  "readxl", "jsonlite", "httr2", "DT", "dplyr", 
  "plotly", "bslib", "future", "furrr", "markdown"
))
```

### 環境變數 (.env)
```bash
PGHOST=your_postgres_host
PGPORT=5432
PGUSER=your_username
PGPASSWORD=your_password
PGDATABASE=your_database
PGSSLMODE=require
OPENAI_API_KEY=your_openai_api_key
```

## 🚀 部署流程

### 1. 開發模式
```bash
# 直接運行最新版本
R -e "shiny::runApp('app/app_v17.R')"
```

### 2. 生產部署
```bash
# 使用部署腳本
Rscript deploy.R v17

# 或使用預設最新版本
Rscript deploy.R

# 啟動應用
R -e "shiny::runApp()"
```

### 3. 版本切換
```bash
# 切換到特定版本
Rscript deploy.R v16

# 查看可用版本
Rscript deploy.R invalid_version
```

## 📊 使用流程

### 步驟 1：上傳資料
- 上傳包含 `Variation/Title/Body` 欄位的 Excel 檔案
- 系統會自動預覽和驗證資料格式

### 步驟 2：屬性產生與評分
- AI 自動產生 6 個產品屬性維度
- 系統使用 GPT-4o-mini 對評論進行 1-5 分評分
- 支援平行處理提升效能

### 步驟 3：分析與視覺化
- **品牌分數比較** - 各品牌屬性表現
- **品牌 DNA 分析** - 與理想點的差距視覺化
- **關鍵因素識別** - 影響表現的關鍵屬性
- **策略建議** - AI 生成的行銷建議

## 🛠 技術架構

- **前端**: Shiny + bslib (Bootstrap 5)
- **後端**: PostgreSQL + JSONB
- **AI 整合**: OpenAI GPT-4o-mini
- **視覺化**: Plotly + DT
- **部署**: 支援 shinyapps.io

## 👥 開發團隊

**祈鋒行銷科技有限公司**  
聯絡人: [partners@peakedges.com](mailto:partners@peakedges.com)

## 📄 版權資訊

© 2024 祈鋒行銷科技有限公司. All rights reserved. 

## 🔑 專案重點與設計

- **三步驟工作流程**：評論上傳 → 屬性產生與評分 → 視覺化／策略。
- **模組化架構**：UI 與 Server 分離，所有功能封裝於 `modules/`，多版本 Shiny App 置於 `app/` (以 `app.R` 為入口)。
- **共同函式庫**：`scripts/global_scripts/` 為 **Git Submodule**，指向外部倉庫 `precision_marketing_global_scripts`（詳見 `.gitmodules`）。開發時請優先 `source()` 其中函式，避免重複開發。
- **部署與版本切換**：`deploy.R` 可指定版本 (如 `v17`) 自動複製成 `app.R` 並備份舊版，方便回溯。
- **資料庫**：預設使用 SQLite (`database/insightforge_test.db`)，亦可切換至 PostgreSQL。連線邏輯集中於 `database/db_connection.R`。
- **UI 技術**：採用 `bs4Dash` + 自訂 CSS (`www/`)，登入後以步驟導覽方式操作。
- **測試**：`tests/` 內含模型與流程測試 (`test_app_poisson_output.R` 等)，建議持續擴充。
- **CI/CD**：建議後續於 GitHub Actions 加入 R CMD check、Shiny test、自動部署腳本，確保品質。 