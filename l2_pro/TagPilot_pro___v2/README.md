# VitalSigns 精準行銷平台

> An AI-powered precision marketing dashboard built with R Shiny & bs4Dash

---

## 📦 專案簡介
Vital Signs 旨在協助品牌快速從銷售與顧客互動資料中萃取洞見，並以客戶 DNA 分析等功能支援精準行銷決策。本專案以 **R Shiny** 為核心，整合

* AI (GPT API) 對話分析
* PostgreSQL / SQLite 資料庫
* ETL 與統計模型
* 互動式 Dashboard（bs4Dash）

> 若您只想先體驗功能，可直接啟動程式，系統會自動建立 **SQLite** 測試資料庫與預設帳號：
> * 管理員：`admin / admin123`
> * 一般用戶：`testuser / user123`

---

## 🚀 快速開始

### 1 . 系統需求
* R 4.2 以上
* 建議使用 **RStudio**
* （選用）PostgreSQL 14+ 伺服器

### 2 . 取得程式碼
```bash
# 使用 Git
git clone https://github.com/YourOrg/VitalSigns.git
cd VitalSigns
```

### 3 . 安裝依賴套件
啟動 R 後執行：
```r
source("config/packages.R")
initialize_packages()   # 將自動安裝並載入所需套件
```

### 4 . 建立環境變數（可選）
於 `config/.env` 撰寫：
```
# PostgreSQL
PGHOST=127.0.0.1
PGPORT=5432
PGUSER=postgres
PGPASSWORD=******
PGDATABASE=vitalsigns
PGSSLMODE=require

# OpenAI
OPENAI_API_KEY=sk-xxxxx
```
如未提供，程式將自動切換至 **SQLite** 測試模式，並停用 AI 功能。

### 5 . 啟動應用程式
```r
shiny::runApp()   # 於專案根目錄
```
或直接在 RStudio 按下 <Run App>。

---

## 🗂️ 目錄結構
```
├── app.R                # Shiny 入口腳本
├── config/              # 套件與環境設定
│   └── config.R         # APP_CONFIG 與驗證
├── database/            # 資料庫連線與本地 SQLite
├── modules/             # Shiny 模組（登入、上傳、DNA…）
├── scripts/global_scripts/   # 可重用資料/AI/ETL 函式庫
├── www/                 # 靜態資源（圖片、CSS）
└── tests/               # testthat 自動化測試
```
更完整的全域函式請參考 `scripts/global_scripts/`。開發時 **務必優先重用** 該資料夾中的工具腳本。

---

## 🛠️ 開發與測試
1. 遵循 `scripts/global_scripts/00_principles/` 開發守則。
2. 單元測試：
   ```r
   devtools::test()
   ```
3. 建議使用 [`renv`](https://rstudio.github.io/renv/) 或 [`packrat`](https://rstudio.github.io/packrat/) 進行套件隔離。

---

## ☁️ 部署
* **本地/內網**：確保防火牆允許 3838 port 後，執行 `Rscript app.R`。
* **shinyapps.io / Posit Connect**：
  1. 編輯 `deploy.R` 以符合您的帳號設定。
  2. 執行 `source("deploy.R")` 完成上傳。

---

## 👥 貢獻
歡迎提出 Issue 或 Pull Request 提升功能與穩定性。提交程式碼前請確保通過所有測試並符合專案規範。

---

## 📄 授權
© 2024 祈鋒行銷科技有限公司 — 未經授權不得轉載、改作或再散佈。 