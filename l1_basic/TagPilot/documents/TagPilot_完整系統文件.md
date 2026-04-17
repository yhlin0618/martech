# TagPilot 精準行銷平台 - 完整系統文件

**版本**: 1.3.0  
**最後更新**: 2025-01-08  
**維護團隊**: TagPilot Development Team

## 📋 目錄
1. [系統概述](#系統概述)
2. [技術架構](#技術架構)
3. [核心功能](#核心功能)
   - [Value × Activity 九宮格分析](#value--activity-九宮格分析)
   - [客戶區隔命名系統](#客戶區隔命名系統)
4. [資料流程](#資料流程)
5. [使用者介面](#使用者介面)
6. [部署與環境](#部署與環境)
7. [開發規範](#開發規範)
8. [API 整合](#api-整合)
9. [安全性設計](#安全性設計)
10. [維護與監控](#維護與監控)

---

## 系統概述

### 🎯 產品定位
**TagPilot** (原名 VitalSigns) 是一個基於 AI 技術的精準行銷分析平台，專為電商品牌設計，協助企業從銷售資料中萃取客戶洞察，實現精準行銷決策。

### 💡 核心價值
- **客戶 DNA 分析**：深度剖析客戶購買行為模式
- **AI 智能洞察**：利用 OpenAI GPT 分析客戶評論與互動
- **多平台整合**：支援 Amazon、eBay 等主流電商平台
- **即時視覺化**：互動式儀表板即時呈現關鍵指標

### 🎬 使用場景
1. **品牌經理**：監控產品表現，識別明星產品
2. **行銷人員**：分析客戶群體，制定精準行銷策略
3. **客服團隊**：了解客戶需求，提升服務品質
4. **產品開發**：基於客戶反饋優化產品設計

---

## 技術架構

### 🏗️ 系統架構圖
```
┌──────────────────────────────────────────────────┐
│                   前端介面層                       │
│         R Shiny + bs4Dash + JavaScript           │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────┴─────────────────────────────┐
│                   應用程式層                       │
│     Shiny Modules + Reactive Programming         │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────┴─────────────────────────────┐
│                   業務邏輯層                       │
│    Global Scripts + Principles Architecture      │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────┴─────────────────────────────┐
│                   資料處理層                       │
│      ETL Pipeline + DNA Analysis Engine          │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────┴─────────────────────────────┐
│                   資料存儲層                       │
│   PostgreSQL (生產) / SQLite (開發) / DuckDB     │
└──────────────────────────────────────────────────┘
```

### 🔧 技術棧

#### 前端技術
- **框架**：R Shiny (v1.7+)
- **UI 套件**：bs4Dash (Bootstrap 4)
- **圖表**：plotly, echarts4r
- **表格**：DT (DataTables)
- **樣式**：自訂 CSS + Bootswatch (Cosmo 主題)

#### 後端技術
- **核心語言**：R (v4.2+)
- **資料處理**：tidyverse, dplyr, data.table
- **資料庫**：DBI, RPostgres, RSQLite, duckdb
- **平行處理**：future, furrr
- **API 整合**：httr, jsonlite

#### AI/ML 整合
- **OpenAI GPT**：文字分析、情感分析、主題萃取
- **統計模型**：客戶分群、RFM 分析、預測模型

### 📁 專案結構
```
TagPilot/
├── app.R                      # 主應用程式入口
├── app_config.yaml            # 應用程式配置
├── manifest.json              # 部署清單
│
├── config/                    # 配置檔案
│   ├── config.R              # 系統配置
│   ├── packages.R            # 套件管理
│   └── .env                  # 環境變數 (不納入版控)
│
├── modules/                   # Shiny 模組
│   ├── module_login.R        # 登入/註冊模組
│   ├── module_upload.R       # 資料上傳模組
│   ├── module_dna_multi.R    # DNA 分析核心模組
│   └── module_score.R        # 評分模組
│
├── scripts/                   # 核心腳本
│   └── global_scripts/       # 全域函式庫
│       ├── 00_principles/    # 架構原則 (257+ 規則)
│       ├── 01_db/           # 資料庫連線
│       ├── 02_db_utils/     # 資料庫工具
│       ├── 03_config/       # 配置載入
│       ├── 05_openai/       # OpenAI 整合
│       └── 10_rshinyapp_components/  # UI 元件
│
├── database/                  # 資料庫檔案
│   ├── init_db.R            # 資料庫初始化
│   └── vitalsigns.sqlite     # 本地測試資料庫
│
├── www/                       # 靜態資源
│   └── images/               # 圖片資源
│
├── tests/                     # 測試檔案
│   ├── test_database.R      # 資料庫測試
│   └── test_modules.R       # 模組測試
│
└── documents/                 # 文件資料夾
    └── TagPilot_完整系統文件.md  # 本文件
```

---

## 核心功能

### 1. 🔐 使用者管理

#### 登入系統
- **雙重驗證**：帳號密碼 + 角色權限
- **角色類型**：
  - 管理員 (admin)：完整系統權限
  - 一般用戶 (user)：資料檢視與分析權限
- **測試帳號**：
  - 管理員：admin / admin123
  - 用戶：testuser / user123

#### 註冊流程
1. 填寫帳號、密碼
2. 密碼二次確認
3. 自動分配一般用戶權限
4. 登入後可開始使用

### 2. 📊 資料上傳與處理

#### 支援格式
- CSV 檔案 (UTF-8, Big5 編碼)
- Excel 檔案 (.xlsx, .xls)
- 直接資料庫連線

#### 資料類型
- **銷售資料**：訂單、產品、金額、時間
- **客戶資料**：客戶 ID、地區、購買歷史
- **產品資料**：SKU、類別、價格、庫存
- **評論資料**：評分、評論文字、情感

### 3. 🧬 Value × Activity 九宮格分析

#### 分析維度

TagPilot 採用創新的 **Value × Activity 九宮格分析法**，將客戶根據兩個核心維度進行精準分類：

1. **價值維度 (Value)**：基於客戶的總消費金額 (Monetary)
   - 高價值：前 20% 的客戶
   - 中價值：中間 60% 的客戶
   - 低價值：後 20% 的客戶

2. **活躍度維度 (Activity)**：基於客戶的購買頻率 (Frequency)
   - 高活躍：前 20% 的客戶
   - 中活躍：中間 60% 的客戶
   - 低活躍：後 20% 的客戶

#### 九宮格區隔系統

透過價值與活躍度的交叉分析，形成 9 個獨特的客戶區隔：

| 價值/活躍度 | 高活躍度 | 中活躍度 | 低活躍度 |
|------------|---------|---------|---------|
| **高價值** | A1C 王者引擎-C | A2C 王者穩健-C | A3C 王者休眠-C |
| **中價值** | B1C 成長火箭-C | B2C 成長常規-C | B3C 成長停滯-C |
| **低價值** | C1C 潛力新芽-C | C2C 潛力維持-C | C3C 清倉邊緣-C |

#### 客戶區隔命名系統

每個區隔都有其獨特的命名規則，包含三個部分：

1. **字母代碼**：
   - **A**：高價值客戶群
   - **B**：中價值客戶群
   - **C**：低價值客戶群

2. **數字代碼**：
   - **1**：高活躍度
   - **2**：中活躍度
   - **3**：低活躍度

3. **狀態後綴**：
   - **C (Current)**：當前狀態
   - **N (New)**：新進狀態
   - **D (Declining)**：下降狀態
   - **H (Historical)**：歷史狀態
   - **S (Sleeping)**：休眠狀態

#### 區隔特徵說明

##### A 系列（高價值客戶）
- **A1C 王者引擎-C**：最有價值且最活躍的 VIP 客戶，是營收的主要引擎
- **A2C 王者穩健-C**：高價值但購買頻率中等的穩定客戶
- **A3C 王者休眠-C**：曾經高消費但近期不活躍，需要喚醒策略

##### B 系列（中價值客戶）
- **B1C 成長火箭-C**：中等價值但高度活躍，有潛力升級為高價值客戶
- **B2C 成長常規-C**：標準的中堅客戶群體，穩定貢獻
- **B3C 成長停滯-C**：中等價值但活躍度下降，需要激活

##### C 系列（低價值客戶）
- **C1C 潛力新芽-C**：低價值但高活躍，可能是新客戶或小額高頻客戶
- **C2C 潛力維持-C**：低價值中等活躍，需要培育策略
- **C3C 清倉邊緣-C**：低價值低活躍，可能流失的邊緣客戶

#### 分析計算邏輯

```r
# 資料分群計算
calculate_segments <- function(data) {
  # 計算 M (Monetary) 和 F (Frequency)
  customer_metrics <- data %>%
    group_by(customer_id) %>%
    summarise(
      M = sum(total_amount, na.rm = TRUE),  # 總消費金額
      F = n_distinct(order_date),           # 購買頻率
      .groups = 'drop'
    )
  
  # 計算分位數（20%, 80%）
  m_quantiles <- quantile(customer_metrics$M, probs = c(0.2, 0.8))
  f_quantiles <- quantile(customer_metrics$F, probs = c(0.2, 0.8))
  
  # 分類客戶
  customer_metrics <- customer_metrics %>%
    mutate(
      value_level = cut(M, 
        breaks = c(-Inf, m_quantiles[1], m_quantiles[2], Inf),
        labels = c("低", "中", "高")),
      activity_level = cut(F,
        breaks = c(-Inf, f_quantiles[1], f_quantiles[2], Inf),
        labels = c("低", "中", "高"))
    )
  
  return(customer_metrics)
}
```

### 4. 📊 客戶資料預覽與下載

#### 資料預覽功能
系統在九宮格分析下方提供即時的客戶資料預覽表格，讓使用者在下載前可以先檢視資料內容：

- **顯示欄位**：客戶ID、總消費金額、購買頻率、價值等級、活躍度等級、客戶區隔
- **排序功能**：預設按總消費金額降序排列
- **搜尋功能**：可快速搜尋特定客戶
- **分頁顯示**：支援 10/25/50/100 筆資料切換

#### 資料下載格式
提供兩種下載格式，滿足不同的資料分析需求：

1. **CSV 格式**
   - UTF-8 編碼，支援中文顯示
   - 可直接匯入 Excel 或其他分析工具
   - 包含所有原始資料欄位

2. **Excel 格式 (.xlsx)**
   - 原生 Excel 格式
   - 自動格式化數值欄位
   - 中文欄位名稱

#### 下載資料內容
每筆下載的資料包含以下資訊：
- 客戶識別碼（customer_id）
- 總消費金額（M - Monetary）
- 購買頻率（F - Frequency）
- 價值等級（高/中/低）
- 活躍度等級（高/中/低）
- 客戶區隔名稱（如 A1C 王者引擎-C）

### 5. 🤖 AI 分析功能

#### OpenAI GPT 整合
- **評論分析**：自動提取產品優缺點
- **情感分析**：正面/中性/負面分類
- **主題萃取**：識別客戶關注焦點
- **摘要生成**：長文本自動摘要

#### 分析流程
1. 資料預處理與清洗
2. 批次送入 GPT API
3. 結構化結果解析
4. 視覺化呈現

### 6. 📈 視覺化儀表板

#### 圖表類型
- **趨勢圖**：銷售趨勢、客戶成長
- **分佈圖**：客戶分群、地理分佈
- **熱力圖**：產品關聯、時段分析
- **雷達圖**：客戶特徵、產品評分

#### 互動功能
- 即時篩選與鑽取
- 圖表聯動更新
- 資料匯出 (CSV, PNG)
- 全螢幕檢視模式

---

## 資料流程

### 🔄 ETL Pipeline

```
原始資料 → 資料清洗 → 資料轉換 → 資料標準化 → 分析處理 → 結果呈現
```

**重要更新 (v1.3.0)**：資料流程已優化，客戶區隔模組現在直接從上傳模組接收資料，不再透過資料庫中轉

#### 階段說明

1. **Import (匯入)**
   - 來源：CSV, Excel, API, Database
   - 驗證：格式檢查、編碼轉換
   - 標記：加入來源標籤、時間戳

2. **Cleanse (清洗)**
   - 去除重複資料
   - 處理缺失值
   - 修正格式錯誤
   - 統一編碼格式

3. **Transform (轉換)**
   - 資料型態轉換
   - 欄位重新命名
   - 計算衍生欄位
   - 單位標準化

4. **Process (處理)**
   - 業務邏輯套用
   - 統計指標計算
   - 模型預測
   - 分群分類

5. **Store (儲存)**
   - 寫入資料庫
   - 建立索引
   - 更新快取
   - 備份歸檔

### 📊 資料模型

#### 核心資料表

```sql
-- 用戶表
users (
  user_id INTEGER PRIMARY KEY,
  username TEXT UNIQUE,
  password_hash TEXT,
  role TEXT,
  created_at TIMESTAMP
)

-- 銷售資料表
sales_data (
  sale_id INTEGER PRIMARY KEY,
  customer_id TEXT,
  product_id TEXT,
  platform_id INTEGER,
  order_date TIMESTAMP,
  amount DECIMAL,
  quantity INTEGER
)

-- 客戶 DNA 表
customer_dna (
  dna_id INTEGER PRIMARY KEY,
  customer_id TEXT,
  platform_id INTEGER,
  product_line_id INTEGER,
  recency INTEGER,
  frequency INTEGER,
  monetary DECIMAL,
  segment TEXT,
  calculated_at TIMESTAMP
)

-- 產品資料表
products (
  product_id TEXT PRIMARY KEY,
  product_name TEXT,
  category TEXT,
  brand TEXT,
  price DECIMAL
)
```

---

## 使用者介面

### 🎨 設計理念
- **簡潔直觀**：降低學習曲線
- **響應式設計**：支援多種裝置
- **視覺層次**：重要資訊優先呈現
- **一致性**：統一的操作邏輯

### 📱 介面結構

#### 1. 登入頁面
- 簡潔卡片式設計
- 品牌 Logo 展示
- 快速切換登入/註冊
- 測試帳號提供

#### 2. 主控台
- **側邊欄導航**：功能模組快速切換
  - 資料上傳
  - Value × Activity 九宮格
  - 客戶區隔管理
  - 關於我們
- **頂部狀態列**：用戶資訊、資料庫狀態
- **步驟指示器**：3 步驟流程引導
  1. 上傳資料
  2. Value × Activity 九宮格
  3. 客戶區隔
- **內容區域**：動態載入各功能模組

#### 3. 資料上傳介面
- 支援多檔案上傳
- 支援 CSV、Excel 格式
- 即時檔案驗證
- 進度條顯示
- 錯誤提示與修正建議
- 自動偵測編碼（UTF-8、Big5）

#### 4. Value × Activity 九宮格介面

##### 九宮格視覺化
- **3×3 矩陣佈局**：清晰展示 9 個客戶區隔
- **顏色編碼**：
  - 綠色系：高價值客戶（A 系列）
  - 藍色系：中價值客戶（B 系列）
  - 橘紅色系：低價值客戶（C 系列）
- **即時統計**：每個區隔顯示客戶數量和佔比
- **互動提示**：滑鼠懸停顯示詳細資訊

##### 客戶資料預覽
- **表格位置**：九宮格下方
- **可摺疊設計**：節省畫面空間
- **欄位顯示**：
  - 客戶ID
  - 總消費金額（格式化千分位）
  - 購買頻率
  - 價值等級
  - 活躍度等級
  - 客戶區隔（如 A1C 王者引擎-C）
- **互動功能**：
  - 排序：點擊欄位標題
  - 搜尋：即時過濾
  - 分頁：10/25/50/100 筆切換

##### 下載功能
- **位置**：九宮格上方右側
- **格式選項**：
  - CSV（綠色按鈕）
  - Excel（藍色按鈕）
- **檔案命名**：customer_segments_YYYY-MM-DD

#### 5. 客戶區隔管理介面 (v1.3.0 更新)
- ~~進階篩選功能~~ (已移除，直接顯示全部結果)
- 統計摘要卡片（總客戶數、區隔數量、平均價值、Email完整率）
- 詳細客戶清單（自動分析並分類）
- 視覺化圖表（區隔分佈圓餅圖、價值分佈直方圖）
- 匯出功能（CSV/Excel）

### 🎯 使用流程

#### 標準操作流程
```
1. 登入系統
   ↓
2. 上傳銷售資料（CSV/Excel）
   ↓
3. 系統自動進行 DNA 分析
   ↓
4. 查看 Value × Activity 九宮格
   ↓
5. 預覽客戶區隔資料
   ↓
6. 下載分析結果（CSV/Excel）
```

#### 快速操作提示
1. **快速上傳**：拖放檔案到上傳區域
2. **快速預覽**：九宮格下方自動顯示資料
3. **快速下載**：點擊上方下載按鈕
4. **快速切換**：使用步驟指示器跳轉

---

## 部署與環境

### 🖥️ 系統需求

#### 最低需求
- **作業系統**：Windows 10, macOS 10.14+, Linux
- **R 版本**：4.2.0+
- **記憶體**：4GB RAM
- **儲存空間**：2GB

#### 建議配置
- **R 版本**：4.3.0+
- **記憶體**：8GB+ RAM
- **CPU**：4 核心以上
- **資料庫**：PostgreSQL 14+

### 🚀 部署方式

#### 1. 本地部署
```bash
# 1. 複製專案
git clone https://github.com/your-org/TagPilot.git
cd TagPilot

# 2. 安裝相依套件
Rscript -e "source('config/packages.R'); initialize_packages()"

# 3. 設定環境變數
cp config/.env.example config/.env
# 編輯 .env 檔案填入實際值

# 4. 啟動應用
Rscript app.R
```

#### 2. Docker 部署
```dockerfile
FROM rocker/shiny:4.3.0

# 安裝系統相依
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libssl-dev

# 複製應用程式
COPY . /srv/shiny-server/

# 安裝 R 套件
RUN R -e "source('/srv/shiny-server/config/packages.R'); initialize_packages()"

# 暴露連接埠
EXPOSE 3838

# 啟動 Shiny Server
CMD ["/usr/bin/shiny-server"]
```

#### 3. 雲端部署

##### Posit Connect Cloud
1. 建立 manifest.json
2. 設定環境變數 (Variable Sets)
3. 使用 rsconnect 套件部署
```r
rsconnect::deployApp(
  appDir = ".",
  appName = "TagPilot",
  account = "your-account"
)
```

##### ShinyApps.io
```r
rsconnect::deployApp(
  appDir = ".",
  appName = "tagpilot",
  account = "your-account"
)
```

### 🔧 環境變數配置

```bash
# PostgreSQL 連線
PGHOST=db.example.com
PGPORT=5432
PGUSER=tagpilot_user
PGPASSWORD=secure_password
PGDATABASE=tagpilot_db
PGSSLMODE=require

# OpenAI API
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx

# 應用程式設定
APP_ENV=production
APP_PORT=3838
APP_HOST=0.0.0.0
```

---

## 開發規範

### 📐 架構原則

系統遵循 **257+ 條開發原則**，儲存於 `scripts/global_scripts/00_principles/`：

#### 核心原則層級
1. **Meta-Principles (MP)**：系統架構基礎 (54 條)
2. **Principles (P)**：實作指導原則 (82 條)
3. **Rules (R)**：具體實作規則 (124 條)
4. **Modules (M)**：可執行模組
5. **Sequences (S)**：工作流程序列
6. **Derivations (D)**：完整資料轉換

#### 關鍵開發原則

##### MP018: DRY (Don't Repeat Yourself)
- 每個知識點只有單一權威來源
- 避免程式碼重複
- 提取共用邏輯為函式

##### R021: 一個函式一個檔案
```r
# 檔案：fn_calculate_rfm.R
calculate_rfm <- function(customer_data) {
  # RFM 計算邏輯
}
```

##### R069: 函式檔案命名
- 函式檔案必須使用 `fn_` 前綴
- 例：`fn_analyze_dna.R`, `fn_process_sales.R`

##### R092: Universal DBI 模式
```r
# 標準資料庫連線
source("scripts/global_scripts/01_db/dbConnect.R")
conn <- dbConnect_universal()
```

### 🧪 測試規範

#### 單元測試
```r
# tests/test_dna_analysis.R
test_that("DNA 分析正確計算 RFM", {
  test_data <- create_test_customers()
  result <- calculate_rfm(test_data)
  
  expect_equal(nrow(result), nrow(test_data))
  expect_true(all(result$recency >= 0))
  expect_true(all(result$frequency > 0))
})
```

#### 整合測試
```r
# tests/test_integration.R
test_that("完整資料流程", {
  # 1. 上傳資料
  upload_result <- upload_sales_data(test_file)
  expect_true(upload_result$success)
  
  # 2. 執行分析
  analysis_result <- run_dna_analysis(upload_result$data)
  expect_s3_class(analysis_result, "data.frame")
  
  # 3. 產生報告
  report <- generate_report(analysis_result)
  expect_true(file.exists(report$path))
})
```

### 📝 程式碼風格

#### 命名規範
- **變數**：snake_case (如 `customer_data`)
- **函式**：snake_case (如 `calculate_rfm()`)
- **常數**：UPPER_CASE (如 `MAX_RETRIES`)
- **檔案**：snake_case (如 `fn_analyze_dna.R`)

#### 註解規範
```r
#' 計算客戶 RFM 分數
#' 
#' @param customer_data 客戶資料框架
#' @param reference_date 參考日期 (預設為今天)
#' @return 包含 RFM 分數的資料框架
#' @examples
#' rfm_scores <- calculate_rfm(customers, Sys.Date())
calculate_rfm <- function(customer_data, reference_date = Sys.Date()) {
  # 實作內容
}
```

---

## API 整合

### 🤖 OpenAI API

#### 配置
```r
# 設定 API 金鑰
Sys.setenv(OPENAI_API_KEY = "sk-xxxxx")

# 載入 OpenAI 工具
source("scripts/global_scripts/05_openai/openai_utils.R")
```

#### 使用範例
```r
# 分析客戶評論
analyze_reviews <- function(reviews) {
  prompt <- "分析以下產品評論，提取主要優缺點："
  
  response <- call_openai_api(
    prompt = prompt,
    text = reviews,
    model = "gpt-4",
    temperature = 0.7
  )
  
  return(parse_ai_response(response))
}
```

### 📊 資料庫 API

#### PostgreSQL 連線
```r
# 生產環境連線
conn <- dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("PGHOST"),
  port = Sys.getenv("PGPORT"),
  dbname = Sys.getenv("PGDATABASE"),
  user = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD"),
  sslmode = "require"
)
```

#### 資料操作
```r
# 查詢資料
customers <- tbl(conn, "customers") %>%
  filter(status == "active") %>%
  collect()

# 寫入資料
dbWriteTable(conn, "customer_dna", dna_results, overwrite = TRUE)

# 交易處理
dbBegin(conn)
tryCatch({
  dbExecute(conn, "INSERT INTO sales_data ...")
  dbExecute(conn, "UPDATE customers SET ...")
  dbCommit(conn)
}, error = function(e) {
  dbRollback(conn)
  stop(e)
})
```

---

## 安全性設計

### 🔒 認證與授權

#### 密碼安全
- 使用 bcrypt 雜湊演算法
- Salt 自動生成
- 密碼複雜度要求

```r
# 密碼雜湊
library(bcrypt)
hashed_password <- hashpw(plain_password, gensalt(12))

# 密碼驗證
checkpw(plain_password, hashed_password)
```

#### Session 管理
- 自動過期 (預設 24 小時)
- 安全 Cookie 設定
- CSRF 防護

### 🛡️ 資料保護

#### 敏感資料處理
- 環境變數儲存憑證
- 不記錄敏感資訊
- 加密傳輸 (HTTPS)

#### SQL 注入防護
```r
# 使用參數化查詢
safe_query <- sqlInterpolate(
  conn,
  "SELECT * FROM users WHERE user_id = ?id",
  id = user_input
)
dbGetQuery(conn, safe_query)
```

### 📋 安全檢查清單

- [ ] 所有密碼都經過雜湊處理
- [ ] API 金鑰儲存在環境變數
- [ ] 使用參數化 SQL 查詢
- [ ] 實施輸入驗證
- [ ] 啟用 HTTPS
- [ ] 定期更新相依套件
- [ ] 實施存取控制
- [ ] 記錄安全事件

---

## 維護與監控

### 📊 效能監控

#### 關鍵指標
- **回應時間**：頁面載入 < 3 秒
- **並發用戶**：支援 50+ 同時在線
- **資料處理**：10 萬筆資料 < 30 秒
- **記憶體使用**：< 2GB 常駐

#### 監控工具
```r
# 效能分析
library(profvis)
profvis({
  # 要分析的程式碼
  result <- run_dna_analysis(large_dataset)
})

# 記憶體監控
library(pryr)
mem_used()  # 目前記憶體使用
object_size(large_dataset)  # 物件大小
```

### 🔧 日常維護

#### 資料庫維護
```sql
-- 定期清理
VACUUM ANALYZE customer_dna;

-- 重建索引
REINDEX TABLE sales_data;

-- 備份資料庫
pg_dump tagpilot_db > backup_$(date +%Y%m%d).sql
```

#### 日誌管理
```r
# 設定日誌
library(logger)
log_threshold(INFO)
log_appender(appender_file("logs/app.log"))

# 記錄事件
log_info("用戶 {user} 登入成功")
log_error("資料庫連線失敗: {error_msg}")
```

### 🐛 問題排查

#### 常見問題

1. **資料庫連線失敗**
   - 檢查環境變數設定
   - 確認網路連線
   - 驗證資料庫服務狀態

2. **記憶體不足**
   - 使用 data.table 替代 dplyr
   - 實施分批處理
   - 增加伺服器記憶體

3. **API 呼叫失敗**
   - 檢查 API 金鑰有效性
   - 確認配額餘額
   - 實施重試機制

#### 除錯技巧
```r
# 啟用詳細日誌
options(shiny.trace = TRUE)
options(shiny.error = browser)

# 使用瀏覽器除錯
browser()  # 設定中斷點
debug(function_name)  # 除錯特定函式

# 追蹤反應式執行
reactlog::reactlog_enable()
shinyApp(ui, server)
reactlog::reactlog_show()
```

### 📈 版本更新

#### 更新流程
1. **開發環境測試**
2. **備份生產資料**
3. **更新程式碼**
4. **執行資料庫遷移**
5. **驗證功能正常**
6. **監控系統狀態**

#### 版本管理
```bash
# 使用 Git 標籤管理版本
git tag -a v1.2.0 -m "新增 AI 分析功能"
git push origin v1.2.0

# 查看版本歷史
git log --oneline --graph --all
```

---

## 附錄

### 📚 參考資源

- [R Shiny 官方文件](https://shiny.rstudio.com/)
- [bs4Dash 套件文件](https://bs4dash.rinterface.com/)
- [DBI 資料庫介面](https://dbi.r-dbi.org/)
- [OpenAI API 文件](https://platform.openai.com/docs/)

### 🤝 技術支援

- **GitHub Issues**: [專案 Issues 頁面]
- **Email**: support@tagpilot.com
- **文件更新**: 每月定期更新

### 📄 授權資訊

© 2024 祈鋒行銷科技有限公司
本系統受智慧財產權保護，未經授權不得複製、修改或散佈。

---

## 更新紀錄

### 版本 1.3.0 (2025-01-08)
#### 架構優化
- 🔄 **客戶區隔模組資料流程重構**
  - 從資料庫讀取改為直接接收上傳模組資料
  - 移除不必要的資料庫中轉步驟
  - 提升資料處理效能

#### 介面簡化
- 🎨 **移除所有篩選控制**
  - 移除客戶區隔篩選器
  - 移除平台篩選器
  - 移除日期範圍選擇器
  - 直接顯示所有分析結果

#### 功能改進
- ✨ 資料即時傳遞機制
- ✨ 使用 dplyr 直接處理記憶體資料
- ✨ 改進欄位自動偵測（amount/lineitem_price/total_amount）
- ✨ 加入調試訊息追蹤資料流程

#### 錯誤修正
- 🐛 修正 if-else 語法錯誤（"unexpected 'else'"）
- 🐛 修正資料無法正確傳遞問題
- 🐛 修正登入前出現警告訊息問題
- 🐛 修正篩選器顯示"無資料"問題

#### 技術細節
- 📦 移除 `tables_monitor` reactivePoll
- 📦 移除所有 `DBI::dbListTables` 和 `DBI::dbGetQuery` 操作
- 📦 簡化 `filtered_data` reactive（直接返回 `customer_data()`）
- 📦 更新模組函數簽名，新增 `uploaded_data` 參數

詳細更新說明請參考：[2025-01-08_客戶區隔模組優化更新.md](./2025-01-08_客戶區隔模組優化更新.md)

### 版本 1.2.0 (2025-01-03)
#### 重大更新
- 🔄 **DNA 分析模組整合**
  - 統一使用標準化 `fn_analysis_dna` 函數
  - 與 TagPilot Pro (l2_pro) 版本保持一致
  - 提供完整 48 個 DNA 分析指標
  
#### 功能改進
- ✨ 完整 RFM 分析（Recency, Frequency, Monetary）
- ✨ 新增 CAI（客戶活躍指數）計算
- ✨ 新增 CLV（客戶終身價值）預測
- ✨ 新增 CRI（客戶規律性指數）
- ✨ 流失預測機率計算

#### 錯誤修正
- 🐛 修正九宮格分割錯誤（'breaks' are not unique）
- 🐛 改進分位數重複時的處理邏輯
- 🐛 簡化資料處理，移除 Amazon 特定欄位依賴

#### 技術優化
- 📦 模組化 DNA 分析函數
- 🚀 提升資料處理效能
- 📝 改進錯誤處理和日誌輸出

詳細更新說明請參考：[2025-01-03_DNA模組整合更新.md](./2025-01-03_DNA模組整合更新.md)

### 版本 2.0.0 (2024-09-02)
#### 新增功能
- ✨ Value × Activity 九宮格分析系統
- ✨ 專業客戶區隔命名系統（A1C-C3C）
- ✨ 客戶資料即時預覽表格
- ✨ CSV/Excel 雙格式下載功能
- ✨ 客戶區隔管理模組

#### 改進項目
- 🎨 優化九宮格視覺化呈現
- 🎨 新增顏色編碼系統
- 📊 改進資料表格互動功能
- 🔧 修正日期格式處理錯誤
- 🔧 改善資料欄位映射邏輯

#### 技術更新
- 升級 bs4Dash 至最新版本
- 優化資料處理效能
- 改進錯誤處理機制

### 版本 1.0.0 (2024-06-23)
- 初始版本發布
- 基礎登入系統
- 資料上傳功能
- 簡單 RFM 分析

---

## 聯絡資訊

**公司**: 祈鋒行銷科技有限公司  
**Email**: partners@peakedges.com  
**技術支援**: support@tagpilot.com  

---

**文件版本**: 1.3.0  
**最後更新**: 2025-01-08  
**維護團隊**: TagPilot Development Team