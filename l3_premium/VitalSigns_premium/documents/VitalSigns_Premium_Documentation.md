# VitalSigns Premium 精準行銷平台 - 技術文件

## 目錄
1. [平台概述](#平台概述)
2. [系統架構](#系統架構)
3. [核心功能](#核心功能)
4. [技術堆疊](#技術堆疊)
5. [模組說明](#模組說明)
6. [資料流程](#資料流程)
7. [VitalSigns 旗艦版四大板塊](#vitalsigns-旗艦版四大板塊)
8. [指標計算定義](#指標計算定義)
9. [安全性與認證](#安全性與認證)
10. [部署與配置](#部署與配置)
11. [API 整合](#api-整合)
12. [維護指南](#維護指南)

---

## 平台概述

VitalSigns Premium 是一套由 AI 驅動的精準行銷平台，專為品牌提供基於客戶特徵與行為數據的個人化行銷策略。平台整合 NLP、推薦系統與自動化分析，以及統計和行銷理論，提供高效且可擴展的解決方案。

### 主要特色
- **AI 驅動的客戶 DNA 分析**：運用 RFM 分析與進階演算法深入了解客戶行為
- **多檔案批次處理**：支援 Amazon 銷售報告與一般交易記錄的自動合併
- **智慧欄位偵測**：自動識別客戶 ID、時間、金額等關鍵欄位
- **視覺化儀表板**：互動式圖表呈現客戶分群與價值分布
- **模組化架構**：遵循 257+ 條原則的嚴謹開發框架

### 服務範圍
- 客群分群建模（Segmentation Modeling）
- 意圖辨識與推薦系統（Intent Detection & Recommendation）
- 評論內容語意分析（Sentiment & Aspect Analysis）
- 行銷活動預測與績效追蹤（Campaign Forecasting & Tracking）
- 多管道數據整合與儀表板（Omni-channel Dashboard & ETL）

---

## 完整應用程式架構

### 主應用程式結構 (app.R)

```r
# 主應用程式入口點
# 版本: v18 (bs4Dash)
# 架構: Shiny + bs4Dash + PostgreSQL

app.R
├── 系統初始化
│   ├── source("config/packages.R")     # 套件管理
│   ├── source("config/config.R")       # 系統配置
│   └── initialize_packages()            # 套件環境初始化
│
├── 認證系統
│   ├── source("database/db_connection_lazy.R")  # 延遲載入資料庫
│   ├── source("modules/module_login_optimized.R") # 登入模組
│   └── auth_con <- get_auth_connection()         # 認證連接
│
├── 核心模組載入
│   ├── module_upload.R                 # 資料上傳模組
│   ├── module_dna_multi_optimized.R    # DNA分析模組
│   ├── module_wo_b.R                   # 策略分析模組
│   └── 四大板塊模組
│       ├── module_revenue_pulse.R      # 營收脈能
│       ├── module_customer_acquisition.R # 客戶增長
│       ├── module_customer_retention_new.R # 客戶留存
│       └── module_engagement_flow.R    # 活躍轉化
│
└── 工具模組
    ├── utils/data_access.R             # 資料存取工具
    ├── utils/hint_system.R             # 提示系統
    ├── utils/prompt_manager.R          # 提示管理
    └── utils/ai_loading_manager.R      # AI載入管理
```

### UI 架構 (bs4Dash 框架)

```r
bs4DashPage(
  header = bs4DashNavbar(
    ├── title = "Vital Signs"           # 應用標題
    ├── rightUi = [
    │   ├── uiOutput("db_status")       # 資料庫狀態顯示
    │   └── uiOutput("user_menu")       # 使用者選單
    │   ]
  ),
  
  sidebar = bs4DashSidebar(
    ├── 歡迎訊息 (welcome_banner)
    ├── 步驟指示器 (step-indicator) 
    └── 選單項目:
        ├── 資料上傳 (upload)
        ├── 客戶DNA分析 (dna_analysis)
        ├── 營收脈能 (revenue_pulse)
        ├── 客戶增長 (customer_acquisition)
        ├── 客戶留存 (customer_retention)
        ├── 活躍轉化 (engagement_flow)
        └── 關於我們 (about)
  ),
  
  body = bs4DashBody(
    bs4TabItems(
      ├── bs4TabItem("upload", uploadModuleUI())
      ├── bs4TabItem("dna_analysis", dnaMultiModuleUI())
      ├── bs4TabItem("revenue_pulse", revenuePulseModuleUI())
      ├── bs4TabItem("customer_acquisition", customerAcquisitionModuleUI())
      ├── bs4TabItem("customer_retention", customerRetentionModuleUI())
      ├── bs4TabItem("engagement_flow", engagementFlowModuleUI())
      └── bs4TabItem("about", [關於頁面內容])
    )
  )
)
```

### Server 架構與 Reactive 流程

```r
server <- function(input, output, session) {
  # 1. 登入系統
  login_result <- loginModuleServer("login_optimized", auth_con)
  
  # 2. 資料庫連接（登入成功後建立）
  con_global <- reactive({ 
    if (login_result$logged_in()) get_con() else NULL 
  })
  
  # 3. 全域 Reactive Values
  sales_data <- reactiveVal(NULL)      # 銷售資料
  user_info <- reactive(login_result$user_info())
  
  # 4. 核心模組初始化與資料流
  upload_mod <- uploadModuleServer("upload1", con_global, user_info)
  ├── 輸出: dna_data()             # 標準化交易資料
  ├── 輸出: proceed_step()         # 步驟切換觸發
  └── 副作用: sales_data(upload_mod$dna_data())
  
  dna_mod <- dnaMultiModuleServer("dna_multi1", con_global, user_info, 
                                  upload_mod$dna_data, chat_api)
  ├── 輸入: upload_mod$dna_data()  # 來自上傳模組
  ├── 輸出: analysis_result()     # DNA分析結果
  └── 輸出: customer_segments()   # 客戶分群
  
  time_series_mod <- timeSeriesAnalysisServer("time_series", 
                                             raw_data = upload_mod$dna_data)
  ├── 輸出: daily_data()          # 日度聚合資料
  ├── 輸出: monthly_data()        # 月度聚合資料
  └── 輸出: trend_analysis()      # 趋势分析
  
  # 5. 四大板塊模組 (依賴 dna_mod 和time_series_mod)
  revenue_mod <- revenuePulseModuleServer("revenue_pulse1", 
                   con_global, user_info, dna_mod, time_series_mod, chat_api)
  
  acquisition_mod <- customerAcquisitionModuleServer("customer_acquisition1",
                       con_global, user_info, dna_mod, time_series_mod, chat_api)
  
  retention_mod <- customerRetentionModuleServer("customer_retention1",
                     con_global, user_info, dna_mod, chat_api)
  
  engagement_mod <- engagementFlowModuleServer("engagement_flow1",
                      con_global, user_info, dna_mod, chat_api)
}
```

### 系統架構
```
┌─────────────────────────────────────────────────────────────┐
│                     VitalSigns Premium                       │
├─────────────────────────────────────────────────────────────┤
│                    前端 (R Shiny + bs4Dash)                  │
├──────────────┬─────────────┬─────────────┬──────────────────┤
│   登入模組    │  上傳模組    │  DNA分析模組  │   策略模組      │
├──────────────┴─────────────┴─────────────┴──────────────────┤
│                    後端處理層 (R Server)                      │
├──────────────┬─────────────┬─────────────┬──────────────────┤
│  資料存取層   │  分析引擎    │  OpenAI API  │   視覺化引擎    │
├──────────────┴─────────────┴─────────────┴──────────────────┤
│                 資料庫層 (PostgreSQL/SQLite)                 │
└─────────────────────────────────────────────────────────────┘
```

### 目錄結構
```
VitalSigns_premium/
├── app.R                    # 主應用程式入口
├── config/
│   ├── config.R            # 系統配置
│   └── packages.R          # 套件管理
├── modules/
│   ├── module_upload.R     # 資料上傳模組
│   ├── module_dna_multi.R  # DNA 多檔案分析模組
│   ├── module_wo_b.R       # 策略分析模組（PCA、Ideal、Strategy）
│   ├── module_login.R      # 登入認證模組
│   ├── module_revenue_pulse.R       # 營收脈能模組
│   ├── module_customer_acquisition.R # 客戶增長模組
│   ├── module_customer_retention.R   # 客戶留存模組
│   ├── module_engagement_flow.R      # 活躍轉化模組
│   └── module_time_series_analysis.R # 時間序列分析模組
├── database/
│   └── db_connection.R     # 資料庫連接管理
├── utils/
│   └── data_access.R       # 資料存取工具
├── scripts/
│   └── global_scripts/     # 共用腳本庫
├── www/                    # 靜態資源
├── md/                     # Markdown 文件
└── documents/              # 專案文件
```

---

## 核心功能

### 1. 資料上傳與處理 (module_upload.R)

#### 功能描述
- 支援多檔案同時上傳（CSV、Excel）
- 自動偵測並標準化欄位名稱
- 智慧合併不同格式的檔案
- 資料預覽與驗證

#### 欄位偵測邏輯
```r
# 客戶 ID 偵測優先順序
1. Email 欄位：buyer email, buyer_email, email
2. ID 欄位：customer_id, customer, buyer_id, user_id

# 時間欄位偵測
purchase date, payments date, payment_time, date, time

# 金額欄位偵測
item price, lineitem_price, amount, sales, price, total
```

#### 資料處理流程
1. 檔案上傳 → 格式驗證
2. 欄位偵測 → 標準化命名
3. 資料合併 → 去重處理
4. 資料儲存 → JSON 格式存入資料庫

### 2. 客戶 DNA 分析 (module_dna_multi.R)

#### 核心演算法
- **RFM 分析**：Recency（最近購買時間）、Frequency（購買頻率）、Monetary（購買金額）
- **NES 狀態分類**：基於客戶參與度的進階分群
- **CLV 計算**：客戶終身價值預測
- **CAI 指標**：客戶活躍度指數

#### 分析維度
```r
# DNA 分析核心指標
- r_value: 最近購買距今天數
- f_value: 總購買次數
- m_value: 平均單次消費金額
- ipt_mean: 平均購買週期
- cai_value: 客戶活躍度（0-1）
- nes_status: 客戶狀態（N, E0, S1, S2, S3）
```

#### 視覺化元件
- **ECDF 圖**：累積分布函數圖表
- **直方圖**：各指標分布情況
- **互動式表格**：支援數值/文字轉換顯示

### 3. 策略分析模組 (module_wo_b.R)

#### PCA 主成分分析
- 3D 視覺化品牌定位
- 降維分析關鍵屬性
- 互動式 Plotly 圖表

#### 理想點分析
- 計算與理想品牌的距離
- 排序最接近理想的產品組合
- 關鍵因素識別

#### 四象限策略矩陣
```
┌─────────────┬─────────────┐
│    改善      │     訴求     │
│ (非關鍵高分) │  (關鍵高分)  │
├─────────────┼─────────────┤
│    劣勢      │     改變     │
│ (非關鍵低分) │  (關鍵低分)  │
└─────────────┴─────────────┘
```

#### AI 策略建議
- 整合 OpenAI API (GPT-4o-mini)
- 根據四象限分析自動生成行銷建議
- 繁體中文輸出，300 字內精準建議

---

## 技術堆疊

### 前端技術
- **框架**：R Shiny (v1.7+)
- **UI 套件**：bs4Dash (Bootstrap 4)
- **視覺化**：
  - plotly (互動式圖表)
  - DT (互動式表格)
- **其他**：
  - shinyjs (JavaScript 整合)
  - shinycssloaders (載入動畫)

### 後端技術
- **語言**：R (4.0+)
- **資料處理**：
  - dplyr, tidyr (資料操作)
  - jsonlite (JSON 處理)
  - readxl (Excel 讀取)
- **統計分析**：
  - 自訂 analysis_dna 函數
  - prcomp (PCA 分析)

### 資料庫
- **生產環境**：PostgreSQL
- **開發環境**：SQLite/DuckDB
- **連接**：DBI + RPostgres/RSQLite

### API 整合
- **OpenAI API**：
  - 模型：gpt-4o-mini
  - 用途：策略分析、行銷建議
  - 溫度：0.3（確保穩定輸出）

### 安全性
- **認證**：bcrypt 密碼加密
- **環境變數**：
  - OPENAI_API_KEY
  - PGHOST, PGPORT, PGUSER, PGPASSWORD

---

## 模組說明

### 提示管理系統 (Prompts & Hints Management)

#### 集中化管理架構

VitalSigns Premium 使用集中化的提示和提示管理系統，確保所有 AI 分析和用戶提示的一致性：

**提示管理 (database/prompt.csv)**：
- `module`：模組名稱（如 "engagement_flow", "revenue_pulse"）
- `analysis_type`：分析類型（如 "cai_analysis", "frequency_analysis"）
- `prompt_text`：完整的 AI 提示文本
- `updated_at`：更新時間戳

**提示系統 (database/hint.csv)**：
- `module_name`：對應的模組名稱
- `hint_id`：唯一提示識別碼
- `title`：提示標題
- `content`：提示內容（支援 HTML 格式）
- `category`：提示分類（如 "指標說明", "使用建議"）
- `order`：顯示順序
- `active`：是否啟用

**管理工具**：
- `utils/prompt_manager.R`：提供 `get_prompt()`, `list_prompts()` 等函數
- `utils/hint_system.R`：提供 `get_hint()`, `render_hint_panel()` 等函數

#### 使用範例

```r
# 獲取特定模組的 AI 提示
prompt <- get_prompt("engagement_flow", "cai_analysis")

# 渲染提示面板
hint_panel <- render_hint_panel("engagement_flow", ns)
```

### module_upload.R - 上傳模組

**主要函數**：
- `uploadModuleUI()`: UI 介面定義
- `uploadModuleServer()`: 伺服器邏輯
- `detect_fields()`: 欄位自動偵測

**輸出**：
- `dna_data()`: 標準化後的交易資料
- `proceed_step()`: 步驟切換觸發器

### module_dna_multi_optimized.R - DNA 分析模組（優化版）

**UI 函數架構**：
```r
dnaMultiModuleUI(id, enable_hints = TRUE) -> div
├── 條件式檔案上傳區 (conditionalPanel)
├── DNA分析結果區:
│   ├── 統計摘要表格 (DT::dataTableOutput)
│   ├── 分布圖表區 (plotlyOutput)
│   └── 客戶分群表格 (DT::dataTableOutput)
└── AI洞察分析區 (uiOutput)
```

**Server 函數定義**：
```r
dnaMultiModuleServer(id, con, user_info, uploaded_dna_data, 
                     chat_api, enable_hints, enable_prompts)
├── 參數說明:
│   ├── con: reactive(DBI Connection)
│   ├── user_info: reactive(list(username, role))
│   ├── uploaded_dna_data: reactive(data.frame) from upload module
│   ├── chat_api: function(messages, model, api_key)
│   ├── enable_hints: boolean
│   └── enable_prompts: boolean
├── 內部 Reactive 架構:
│   ├── raw_data <- reactive({ uploaded_dna_data() || local_upload })
│   ├── analysis_result <- reactive({ analysis_dna(raw_data(), params) })
│   ├── customer_segments <- reactive({ segment_customers(analysis_result()) })
│   └── ai_insights <- reactive({ generate_ai_insights(analysis_result(), chat_api) })
└── 輸出物件:
    ├── analysis_result(): DNA分析完整結果
    ├── customer_data(): 客戶層級資料
    ├── summary_stats(): 統計摘要
    └── segments_data(): 分群結果
```

**DNA 分析核心演算法**：
```r
analysis_dna(data, global_params) -> list
├── 輸入參數:
│   ├── data: 標準化交易資料
│   └── global_params: list(
│       ├── delta = 0.1,              # 時間折扣因子
│       ├── ni_threshold = 2,         # 最少交易次數
│       ├── cai_breaks = c(0,0.1,0.9,1),
│       ├── f_breaks = c(-0.0001,1.1,2.1,Inf),
│       ├── r_breaks = c(-0.0001,0.1,0.9,1.0001),
│       └── m_breaks = c(-0.0001,0.1,0.9,1.0001)
│       )
├── 計算步驟:
│   ├── 1. 客戶交易彙總
│   ├── 2. RFM 指標計算
│   ├── 3. CAI (Customer Activity Index) 計算
│   ├── 4. CLV (Customer Lifetime Value) 估算
│   ├── 5. NES 狀態分類
│   └── 6. 預測指標計算
└── 輸出結構:
    ├── customer_level_data: 客戶層級指標
    │   ├── customer_id, r_value, f_value, m_value
    │   ├── ipt_mean, cai_value, clv, pcv
    │   └── nes_status, nes_ratio, nrec_prob
    ├── segment_summary: 分群統計
    └── model_params: 模型參數
```

**指標計算詳細定義**：
```r
# RFM 核心指標
r_value = as.numeric(difftime(time_now, last_payment_time, units="days"))
f_value = times  # 總購買次數
m_value = total_spent / times  # 平均單次消費

# 進階指標
ipt_mean = mean(interpurchase_times)  # 平均購買週期
cai_value = (mle - wmle) / mle  # 客戶活躍度指數
clv = sum(total_spent * pif_values * discount_factors)  # 客戶終身價值

# NES 狀態分類
nes_ratio = as.numeric(time_since_last) / as.numeric(ipt_mean)
nes_status = case_when(
  times == 1 ~ "N",   # 新客戶
  nes_ratio <= 1.7 ~ "E0",  # 主力客戶
  nes_ratio <= 3.4 ~ "S1",  # 輕度休眠
  nes_ratio <= 5.1 ~ "S2",  # 中度休眠
  TRUE ~ "S3"  # 深度休眠
)
```

**AI 洞察生成**：
```r
generate_ai_insights(analysis_result, chat_api) -> character
├── 提取關鍵統計資料
├── 建構分析上下文
├── 調用 OpenAI API:
│   ├── system prompt: get_prompt("dna_analysis", "customer_insights")
│   └── user context: 統計摘要 + 分群分析
└── 返回 markdown 格式洞察
```

**關鍵參數**：
```r
global_params = list(
  delta = 0.1,              # 時間折扣因子
  ni_threshold = 2,         # 最少交易次數
  cai_breaks = c(0, 0.1, 0.9, 1),
  f_breaks = c(-0.0001, 1.1, 2.1, Inf),
  r_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
  m_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
  nes_breaks = c(0, 1, 2, 2.5, Inf)
)
```

### module_wo_b.R - 策略分析模組

**子模組**：
1. **pcaModule**: PCA 主成分分析
2. **idealModule**: 理想點分析
3. **strategyModule**: 四象限策略分析
4. **dnaModule**: 品牌 DNA 視覺化

**OpenAI 整合**：
```r
chat_api <- function(messages,
                     model = "gpt-4o-mini",
                     api_key = Sys.getenv("OPENAI_API_KEY"),
                     timeout_sec = 60)
```

### module_revenue_pulse.R - 營收脈能模組

**主要函數**：
- `revenuePulseModuleUI()`: UI 介面定義
- `revenuePulseModuleServer()`: 伺服器邏輯

**核心功能**：量化收入規模、單客價值與獲利韌性
- CLV 分群分析與視覺化
- 收入趨勢分析（整合時間序列模組）
- ARPU/AOV 計算與比較
- 獲利韌性評估

**AI 分析功能**：
```r
# CLV 洞察分析
output$ai_clv_insights <- renderUI({
  if(exists("create_pulse_loading")) {
    analysis <- ai_clv_analysis()
    if(is.null(analysis) || is.null(analysis$stats)) {
      invalidateLater(500)
      return(create_pulse_loading(
        message = "正在分析客戶價值分群...",
        icon_name = "chart-pie"
      ))
    }
  }
  # 顯示分析結果...
})
```

**載入動畫整合**：
模組已整合 `utils/reactive_loading.R` 系統，為自動 AI 分析提供載入狀態顯示。

### module_customer_acquisition.R - 客戶增長模組

**主要函數**：
- `customerAcquisitionModuleUI()`: UI 介面定義
- `customerAcquisitionModuleServer()`: 伺服器邏輯

**功能**：監測客戶池擴張速度與結構健康

### module_customer_retention.R - 客戶留存模組

**主要函數**：
- `customerRetentionModuleUI()`: UI 介面定義
- `customerRetentionModuleServer()`: 伺服器邏輯

**功能**：衡量基盤穩定度與流失風險

### module_engagement_flow.R - 活躍轉化模組

**主要函數**：
- `engagementFlowModuleUI()`: UI 介面定義
- `engagementFlowModuleServer()`: 伺服器邏輯

**核心功能**：
- 顧客活躍度指數 (CAI) 分析：顯示**平均值**
- 購買頻率與週期分析：使用**散佈圖**呈現個別客戶數據點
- 再購率與喚醒機會分析
- 轉化漏斗視覺化
- 互動深度評估

**AI 分析整合**：
```r
# CAI 分析提示
cai_prompt <- get_prompt("engagement_flow", "cai_analysis")

# 檢查 API 可用性
if(exists("chat_api") && is.function(chat_api)) {
  ai_result <- chat_api(list(
    list(role = "system", content = cai_prompt),
    list(role = "user", content = analysis_context)
  ))
}
```

**視覺化特色**：
- CAI 數值顯示：`paste0("+", formatted_cai, " (平均)")`
- 散佈圖實現：`plotly` 的 `scatter` 模式，每個點代表一位客戶
- 顏色分組：依客戶價值群組區分
- 互動功能：點擊查看客戶詳細資訊

**載入動畫**：
使用 `utils/reactive_loading.R` 中的 `create_pulse_loading()` 提供分析進行中的視覺回饋。

### module_time_series_analysis.R - 時間序列分析模組

**主要函數**：
- `timeSeriesAnalysisUI()`: UI 介面定義（目前為空，純數據處理）
- `timeSeriesAnalysisServer()`: 伺服器邏輯
- `aggregate_time_series()`: 時間序列聚合函數
- `calculate_trend()`: 趨勢計算函數

**功能**：
- 提供統一的時間序列數據處理接口
- 支援日/週/月/季/年的數據聚合
- 計算成長率、移動平均、同比增長
- 提供趨勢分析和簡單預測

**輸出**：
```r
list(
  daily_data = reactive(),      # 日度聚合數據
  weekly_data = reactive(),     # 週度聚合數據
  monthly_data = reactive(),    # 月度聚合數據
  quarterly_data = reactive(),  # 季度聚合數據
  yearly_data = reactive(),     # 年度聚合數據
  revenue_trend = reactive(),   # 收入趨勢分析
  customer_trend = reactive(),  # 客戶趨勢分析
  metrics_summary = reactive()  # 關鍵指標摘要
)
```

---

## 資料流程

### 標準作業流程
```
1. 使用者登入
   ↓
2. 上傳交易資料（支援多檔案）
   ↓
3. 系統自動偵測欄位
   ↓
4. 資料標準化與合併
   ↓
5. 執行 DNA 分析
   ↓
6. 時間序列分析（平行處理）
   ↓
7. 生成視覺化報表
   ↓
8. AI 策略建議（選用）
```

### 時間序列資料流程
```
原始交易數據 (upload_mod)
   ↓
時間序列分析模組 (time_series_mod)
   ├─→ 日/週/月/季/年聚合
   ├─→ 成長率計算
   └─→ 趨勢分析
         ↓
四大板塊模組使用
   ├─→ 營收脈能：月度收入趨勢
   ├─→ 客戶增長：客戶增長趨勢
   ├─→ 客戶留存：（預留 Cohort 分析）
   └─→ 活躍轉化：（預留活躍度趨勢）
```

### 資料轉換流程
```
原始資料 → 欄位偵測 → 標準化結構：
{
  customer_id: 客戶識別碼
  payment_time: 交易時間
  lineitem_price: 交易金額
  source_file: 來源檔案
}
```

---

## VitalSigns 旗艦版四大板塊

VitalSigns 旗艦版擴展了原有的 DNA 分析功能，新增四大關鍵板塊，提供全方位的客戶洞察：

### 1. 營收脈能 (Revenue Pulse)
量化收入規模、單客價值與獲利韌性，對應 ARPU／AOV、Customer Equity、CLV 理論。

**主要功能**：
- 銷售額總覽
- 人均購買金額 (ARPU) 分析
- 新客與主力客單價比較
- 顧客終生價值 (CLV) 分布
- 交易穩定度評估

### 2. 客戶增長 (Customer Acquisition & Coverage)
監測客戶池擴張速度與結構健康，對應獲客漏斗、市場滲透率與 Bass Diffusion。

**主要功能**：
- 顧客總數與累積趨勢
- 顧客新增率計算
- 客戶池結構分析
- 獲客漏斗視覺化
- 客戶分群分布

### 3. 客戶留存 (Customer Retention)
衡量基盤穩定度與流失風險，結合 RFM-Lifecycle、Survival/Churn Modeling。

**主要功能**：
- 顧客留存率與流失率
- 客戶狀態結構 (N/E0/S1-S3)
- 流失風險預測
- RFM 客戶分群熱力圖
- 靜止戶識別與預測

### 4. 活躍轉化 (Engagement Flow)
掌握互動→再購→喚醒的節奏深度，結合 Engagement Ladder、Loyalty Loop 與 RFM 概念。

**主要功能**：
- 顧客活躍度指數 (CAI)
- 再購率與購買頻率分析
- 客戶轉化漏斗
- 喚醒機會識別
- 忠誠度階梯分析

---

## 指標計算定義

### DNA 分析核心指標（由 analysis_dna 函數計算）

#### RFM 指標
- **r_value (Recency)**：最近購買距今天數
  ```r
  r_value = as.numeric(difftime(time_now, last_payment_time, units = "days"))
  ```

- **f_value (Frequency)**：總購買次數
  ```r
  f_value = times  # 客戶的總交易次數
  ```

- **m_value (Monetary)**：平均單次消費金額
  ```r
  m_value = total_spent / times
  ```

#### 進階指標
- **ipt_mean (Inter-Purchase Time)**：平均購買週期
  ```r
  ipt_mean = ipt  # 預先計算的購買間隔時間
  ```

- **cai_value (Customer Activity Index)**：客戶活躍度指數 (0-1)
  ```r
  mle = sum(ipt * (1/(ni-1)))
  wmle = sum(ipt * ((times-1) / sum(times-1)))
  cai = (mle - wmle) / mle
  ```

- **pcv (Past Customer Value)**：過去客戶價值
  ```r
  pcv = sum(total_spent * (1+delta)^(difftime))
  # delta = 0.0001 (時間折扣因子)
  ```

- **clv (Customer Lifetime Value)**：客戶終生價值
  ```r
  # 使用 pif 函數和折扣因子計算未來價值
  clv = sum(total_spent * pif_values * discount_factors)
  ```

- **cri (Customer Regularity Index)**：客戶規律性指數
  ```r
  # 基於客戶購買間隔的變異性計算
  cri = abs(ipt_mean - be) / abs(ipt_mean - ge)
  ```

#### 客戶狀態分類
- **nes_status**：基於 NES (New-Existing-Sleeping) 模型的客戶狀態
  - **N (New)**：新客戶（首購客）
  - **E0 (Existing)**：主力客戶（活躍客戶）
  - **S1 (Sleepy 1)**：瞌睡客戶（輕度休眠）
  - **S2 (Sleepy 2)**：半睡客戶（中度休眠）
  - **S3 (Sleepy 3)**：沉睡客戶（深度休眠）

- **nes_ratio**：NES 比率計算
  ```r
  nes_ratio = as.numeric(difftime) / as.numeric(ipt_mean)
  # 使用固定 nes_median = 1.7
  ```

#### 預測指標
- **nrec**：客戶流失預測（rec = 預測留存, nrec = 預測流失）
- **nrec_prob**：流失機率 (0-1)

### VitalSigns 旗艦版擴展指標

#### 營收脈能指標
- **總銷售額**：`sum(total_spent)`
- **ARPU**：`mean(total_spent)` - 人均購買金額
- **新客單價**：`mean(m_value)` where `nes_status == "N"`
- **主力客單價**：`mean(m_value)` where `nes_status == "E0"`
- **平均CLV**：`mean(clv)`
- **交易穩定度**：`mean(cri)` - 使用 CRI 指標

#### 客戶增長指標
- **活躍客戶數**：`count` where `nes_status != "S3"`
- **累積客戶數**：`total count`
- **顧客新增率**：`(新客戶數 / 總客戶數) × 100`
- **顧客變動率**：`(活躍客戶數 / 總客戶數) × 100`

#### 客戶留存指標
- **留存率**：`100 - 流失率`
- **流失率**：`(S3客戶數 / 總客戶數) × 100`
- **風險客戶數**：`count` where `nes_status in ("S1", "S2")`
- **各狀態比率**：各 `nes_status` 的百分比

#### 活躍轉化指標
- **平均CAI**：`mean(cai_value)` - 顯示格式：`"+2.34 (平均)"`
- **再購率**：`(購買≥2次客戶數 / 總客戶數) × 100`
- **平均購買頻率**：`mean(f_value)`
- **平均再購時間**：`mean(ipt_mean)`
- **轉化率**：`(E0客戶數 / (N+E0客戶數)) × 100`
- **購買頻率分布**：使用散佈圖 (scatter plot) 呈現，X軸為購買頻率，Y軸為平均購買週期，每個點代表一個客戶
- **喚醒機會分析**：識別 S1-S2 狀態客戶的再激活潛力

### 時間序列分析指標

#### 聚合指標（支援日/週/月/季/年）
- **期間收入**：`sum(lineitem_price)` - 該期間的總收入
- **期間交易數**：`count(transactions)` - 該期間的交易筆數
- **期間客戶數**：`n_distinct(customer_id)` - 該期間的不重複客戶數
- **平均交易金額**：`mean(lineitem_price)` - 該期間的平均單筆交易金額

#### 成長率指標
- **收入成長率**：
  ```r
  revenue_growth = (revenue - lag(revenue)) / lag(revenue) * 100
  ```
- **客戶成長率**：
  ```r
  customer_growth = (customers - lag(customers)) / lag(customers) * 100
  ```
- **交易成長率**：
  ```r
  transaction_growth = (transactions - lag(transactions)) / lag(transactions) * 100
  ```

#### 移動平均與同比
- **3期移動平均**：
  ```r
  revenue_ma3 = zoo::rollmean(revenue, k = 3, fill = NA, align = "right")
  ```
- **同比增長（YoY）**：
  ```r
  # 月度數據的年同比
  revenue_yoy = (revenue - lag(revenue, 12)) / lag(revenue, 12) * 100
  # 季度數據的年同比
  revenue_yoy = (revenue - lag(revenue, 4)) / lag(revenue, 4) * 100
  ```

#### 趨勢分析指標
- **趨勢方向**：基於線性回歸斜率判斷
  - `positive`：斜率 > 0.05
  - `negative`：斜率 < -0.05
  - `stable`：-0.05 ≤ 斜率 ≤ 0.05
- **趨勢強度**：R² 值，表示趨勢的擬合度
- **簡單預測**：基於線性模型的未來3期預測

---

## 安全性與認證

### 登入系統
- 使用 bcrypt 加密密碼
- Session 管理
- 角色權限控制

### 資料保護
- 環境變數管理敏感資訊
- SQL 注入防護（參數化查詢）
- 客戶資料加密儲存

### API 安全
- API Key 環境變數管理
- 請求超時控制（60 秒）
- 錯誤處理與日誌記錄

---

## 部署與配置

### 環境需求
```bash
# R 版本
R >= 4.0.0

# 必要套件
shiny, bs4Dash, DT, plotly, dplyr, tidyverse
DBI, RPostgres, RSQLite, duckdb
httr, jsonlite, bcrypt
future, furrr
```

### 環境變數設定
```bash
# OpenAI API
export OPENAI_API_KEY="your-api-key"

# PostgreSQL (生產環境)
export PGHOST="your-host"
export PGPORT="5432"
export PGUSER="your-user"
export PGPASSWORD="your-password"
export PGDATABASE="your-database"
export PGSSLMODE="require"
```

### 啟動應用
```r
# 開發環境
Rscript app.R

# 生產環境（Posit Connect）
# 使用 manifest.json 部署
```

### 載入動畫系統 (Loading Animation System)

#### 核心組件

**utils/ai_loading_manager.R**：
- 統一管理所有 AI 分析的載入狀態
- 提供進度條和漸變動畫效果
- 支援按鈕觸發式分析

**主要函數**：
```r
# 創建載入 UI
create_ai_loading_ui(id, message, submessage)

# 執行帶載入的 AI 分析
with_ai_loading(analysis_name, analysis_function, progress_steps)

# 初始化載入管理器
init_ai_loading_manager()
```

**utils/reactive_loading.R**：
- 專門處理自動執行的 reactive AI 分析
- 提供脈動效果的載入動畫
- 支援無縫切換到分析結果

**主要函數**：
```r
# 創建脈動載入效果
create_pulse_loading(message, icon_name)

# Reactive 載入包裝
reactiveWithLoading(expr, loading_message, delay)

# 漸進式載入
renderUIWithLoading(data_reactive, render_function, loading_ui)
```

**utils/loading_animation.R**：
- 提供基礎載入 UI 組件
- 支援多種載入動畫樣式
- CSS 動畫和進度條效果

#### 使用模式

**模組整合範例**：
```r
# 在模組 server 中
output$ai_analysis <- renderUI({
  # 檢查是否有載入工具可用
  if(exists("create_pulse_loading")) {
    analysis_result <- some_ai_analysis()
    
    # 如果分析還未完成，顯示載入動畫
    if(is.null(analysis_result)) {
      invalidateLater(500)  # 定期檢查
      return(create_pulse_loading(
        message = "AI 分析中...",
        icon_name = "robot"
      ))
    }
    
    # 分析完成，顯示結果
    return(format_analysis_result(analysis_result))
  }
  
  # 沒有載入工具時的後備方案
  return(div("分析中..."))
})
```

**載入狀態管理**：
```r
# 顯示載入動畫
show_ai_loading(session, "loading_id", "result_id")

# 隱藏載入動畫並顯示結果
hide_ai_loading(session, "loading_id", "result_id")
```

---

## API 整合

### OpenAI API 使用

**統一 API 函數**：
```r
chat_api <- function(messages,
                     model = "gpt-4o-mini",
                     api_key = Sys.getenv("OPENAI_API_KEY"),
                     timeout_sec = 60)
```

**請求格式**：
```r
messages = list(
  list(role = "system", content = get_prompt("module_name", "analysis_type")),
  list(role = "user", content = "使用者輸入或分析上下文")
)
```

**整合模式**：
```r
# 在模組中檢查 API 可用性
if(exists("chat_api") && is.function(chat_api)) {
  # API 可用，執行 AI 分析
  ai_result <- chat_api(messages)
} else {
  # API 不可用，顯示預設分析
  ai_result <- "使用預設分析（GPT未啟用或未設定）"
}
```

**回應處理**：
- 自動去除 code fence 和 API 狀態訊息
- Markdown 轉 HTML 顯示
- 錯誤重試機制
- 載入動畫整合

**環境變數管理**：
- **統一使用** `OPENAI_API_KEY`（已移除舊版 `OPENAI_API_KEY_LIN`）
- 支援 Posit Connect Variable Set 進行多應用金鑰管理

### 資料庫 API

**通用連接模式**：
```r
con <- dbConnect_universal()  # 使用 R092 原則
```

**查詢模式**：
```r
# 參數化查詢防止 SQL 注入
db_execute(
  "INSERT INTO table (col1, col2) VALUES (?, ?)",
  params = list(val1, val2)
)
```

---

## 維護指南

### 日常維護

1. **資料庫維護**
   - 定期備份 rawdata 表
   - 清理過期 session 資料
   - 監控查詢效能

2. **日誌管理**
   - 檢查錯誤日誌
   - 分析使用者行為
   - API 使用量監控

3. **效能優化**
   - 使用 future/furrr 進行並行處理
   - 適當的資料分頁
   - 快取常用查詢結果

### 故障排除

**常見問題**：

1. **資料上傳失敗**
   - 檢查檔案格式
   - 驗證欄位名稱
   - 確認檔案大小限制（200MB）

2. **DNA 分析錯誤**
   - 確認最少交易次數設定
   - 檢查資料完整性
   - 驗證必要欄位存在

3. **OpenAI API 錯誤**
   - 確認 API Key 有效
   - 檢查網路連線
   - 留意 rate limit

### 更新流程

1. **測試環境驗證**
   ```bash
   # 使用本地測試
   Rscript app.R
   ```

2. **程式碼檢查**
   - 遵循 257+ 條開發原則
   - 執行單元測試
   - 程式碼審查
   - 驗證 AI 載入動畫功能
   - 確認集中化提示管理正常運作

3. **部署程序**
   - 更新 manifest.json
   - 推送至 Posit Connect
   - 設定環境變數 (OPENAI_API_KEY, PostgreSQL 配置)
   - 驗證部署成功
   - 測試 AI 分析功能

4. **部署後檢查**
   - 確認所有模組的 AI 分析正常運作
   - 驗證載入動畫顯示正確
   - 檢查提示和提示系統功能
   - 測試散佈圖和其他視覺化更新

---

## 附錄

### 關鍵檔案說明

- `app.R`: 主程式入口，定義 UI 結構與 server 邏輯
- `app_config.yaml`: 應用配置檔（如存在）
- `CLAUDE.md`: AI 助理操作指引
- `global_scripts/`: 共用函數庫
- `www/assets/`: 靜態資源（圖片、CSS）

### 相關資源

- [Shiny 官方文件](https://shiny.rstudio.com/)
- [bs4Dash 文件](https://bs4dash.rinterface.com/)
- [DBI 資料庫介面](https://dbi.r-dbi.org/)
- [OpenAI API 文件](https://platform.openai.com/docs/)

### 聯絡資訊

**開發團隊**：祈鋒行銷科技有限公司  
**Email**：partners@peakedges.com

---

## 版本歷史

### v2.1 (2025-08-07)
- 新增時間序列分析模組
- 修復 RFM 熱力圖的資料類型衝突問題
- 營收脈能模組新增月度收入趨勢圖表
- 客戶增長模組新增客戶增長趨勢圖表
- 加入完整的時間序列指標計算定義

### v2.0 (2024-12-26)
- 新增 VitalSigns 旗艦版四大板塊
- 加入營收脈能、客戶增長、客戶留存、活躍轉化模組
- 完整的指標計算定義文件
- 更新系統架構以支援擴展功能

### v1.0 (2024-06-23)
- 初始版本發布
- 基本 DNA 分析功能
- 資料上傳與處理
- 策略分析模組

---

## 資料庫連接架構更新

### 資料庫連接的更新（移除 SQLite fallback）

**get_con() 函數更新**：
```r
get_con <- function() {
  con <- NULL
  db_type <- NULL
  db_info <- NULL
  
  # 嘗試載入配置
  tryCatch({
    db_config <- get_config("db")
    
    # 只嘗試 PostgreSQL 連接
    if (!is.null(db_config$host) && nzchar(db_config$host)) {
      con <- dbConnect(
        RPostgres::Postgres(),
        host     = db_config$host,
        port     = db_config$port,
        user     = db_config$user,
        password = db_config$password,
        dbname   = db_config$dbname,
        sslmode  = db_config$sslmode
      )
      
      db_type <- "PostgreSQL"
      db_info <- list(
        type = "PostgreSQL",
        host = db_config$host,
        port = db_config$port,
        dbname = db_config$dbname,
        icon = "🐘",
        color = "#336791",
        status = "正式環境"
      )
    } else {
      stop("無 PostgreSQL 配置")
    }
  }, error = function(e) {
    # 不再使用本地 SQLite，直接拋出錯誤
    stop(paste("無法連接到 PostgreSQL 資料庫:", e$message))
  })
  
  # 檢查連接是否成功
  if (is.null(con)) {
    stop("資料庫連接失敗")
  }
  
  # 只使用 PostgreSQL 語法建表
  if (inherits(con, "PqConnection")) {
    # Users 表
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS users (
        id           SERIAL PRIMARY KEY,
        username     TEXT UNIQUE,
        hash         TEXT,
        role         TEXT DEFAULT 'user',
        login_count  INTEGER DEFAULT 0
      );
    ")
    
    # 原始資料表
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS rawdata (
        id           SERIAL PRIMARY KEY,
        user_id      INTEGER REFERENCES users(id),
        uploaded_at  TIMESTAMPTZ DEFAULT now(),
        json         JSONB
      );
    ")
    
    # 處理後資料表
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS processed_data (
        id            SERIAL PRIMARY KEY,
        user_id       INTEGER REFERENCES users(id),
        processed_at  TIMESTAMPTZ DEFAULT now(),
        json          JSONB
      );
    ")
    
    # 銷售資料表
    dbExecute(con, "
      CREATE TABLE IF NOT EXISTS salesdata (
        id           SERIAL PRIMARY KEY,
        user_id      INTEGER REFERENCES users(id),
        uploaded_at  TIMESTAMPTZ DEFAULT now(),
        json         JSONB
      );
    ")
  }
  
  # 檢查用戶表是否為空
  existing_users <- dbGetQuery(con, "SELECT COUNT(*) as count FROM users")
  if (existing_users$count == 0) {
    # 用戶表為空時，需要管理員手動創建首個管理員帳號
    message("注意：用戶表為空，請聯絡系統管理員創建管理員帳號")
  }
  
  # 儲存連接資訊到屬性
  attr(con, "db_info") <- db_info
  
  return(con)
}
```

**配套輔助函數**：
```r
# 資料庫資訊取得
get_db_info <- function(con = NULL) {
  if (is.null(con)) {
    return(list(
      type = "未連接",
      icon = "❌",
      color = "#DC3545",
      status = "未連接"
    ))
  }
  
  db_info <- attr(con, "db_info")
  if (!is.null(db_info)) return(db_info)
  
  # PostgreSQL 預設資訊
  if (inherits(con, "PqConnection")) {
    return(list(
      type = "PostgreSQL",
      icon = "🐘",
      color = "#336791",
      status = "正式環境"
    ))
  }
}

# 跨資料庫查詢（現僅PostgreSQL）
db_query <- function(query, params = NULL) {
  tryCatch({
    con <- get_con()
    
    # PostgreSQL 參數化查詢處理
    if (inherits(con, "PqConnection") && !is.null(params) && grepl("\\?", query)) {
      # 將 ? 轉換為 $1, $2, $3...
      param_count <- 1
      while (grepl("\\?", query)) {
        query <- sub("\\?", paste0("$", param_count), query)
        param_count <- param_count + 1
      }
    }
    
    if (is.null(params)) {
      dbGetQuery(con, query)
    } else {
      dbGetQuery(con, query, params)
    }
  }, error = function(e) {
    stop("資料庫查詢錯誤: ", e$message)
  })
}
```

**重要變更說明**：
1. **移除SQLite支援**：不再嘗試建立本地SQLite資料庫作為fallback
2. **強制PostgreSQL**：必須有有效的PostgreSQL配置才能運行應用
3. **統一SQL語法**：只使用PostgreSQL語法建立表格，避免跨資料庫相容性問題
4. **簡化部署**：生產環境和開發環境使用相同的資料庫系統
5. **錯誤處理**：連接失敗直接停止應用，提供明確的錯誤訊息
6. **自動建表**：使用PostgreSQL的SERIAL、TIMESTAMPTZ、JSONB等特有功能
7. **用戶管理**：系統不再自動創建測試帳號，需由管理員手動創建

這個更新確保了生產環境的一致性，簡化了維護工作，並充分利用了PostgreSQL的進階功能。

---

## 最新更新記錄 (2025-08-13)

### 1. AI 分析整合修復
- **問題**：活躍轉化模組的 AI 分析無法正常運作，顯示 "API狀態: 未啟用 | chat_api: 未設定"
- **解決**：在 `app.R` 中正確傳遞 `chat_api` 參數到模組初始化
```r
engagement_mod <- engagementFlowModuleServer("engagement_flow1", con_global, user_info, dna_mod, 
                                            enable_hints = TRUE, enable_gpt = TRUE, chat_api = chat_api)
```

### 2. 視覺化更新
- **CAI 顯示修正**：客戶活躍度 (CAI) 改為顯示平均值，格式：`"+2.34 (平均)"`
- **散佈圖實現**：購買頻率與週期分析從氣泡圖改為散佈圖，每個點代表一個客戶
```r
plot_ly(pattern_data,
        x = ~purchase_frequency,
        y = ~avg_cycle,
        color = ~value_group,
        type = 'scatter',
        mode = 'markers',
        ...)
```

### 3. 載入動畫系統
- **創建統一載入管理**：新增 `utils/ai_loading_manager.R` 和 `utils/reactive_loading.R`
- **整合到模組**：營收脈能和活躍轉化模組已整合載入動畫
- **移除 API 狀態顯示**：從 AI 分析結果中移除 "API狀態: 已啟用" 等訊息

### 4. 集中化管理確認
- **提示管理**：確認 `database/prompt.csv` 正常運作，包含各模組的 AI 提示
- **提示系統**：確認 `database/hint.csv` 和 `utils/hint_system.R` 功能正常
- **管理工具**：`utils/prompt_manager.R` 提供統一的提示獲取介面

### 5. 語法錯誤修復
- **修復括號配對錯誤**：解決 `module_engagement_flow.R:1264` 的語法錯誤
- **代碼清理**：移除重複的 API 狀態顯示邏輯

### 6. OpenAI API 環境變數統一
- **統一金鑰名稱**：全面使用 `OPENAI_API_KEY`，移除舊版 `OPENAI_API_KEY_LIN`
- **Posit Connect 支援**：支援 Variable Set 進行多應用金鑰管理

---

*文件版本：v2.3*  
*最後更新：2025-08-13*  
*更新內容：AI 分析整合修復、載入動畫系統、視覺化更新、集中化管理確認*