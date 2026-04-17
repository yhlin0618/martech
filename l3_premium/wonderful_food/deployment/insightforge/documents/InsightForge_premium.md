# InsightForge Premium 精準行銷平台

## 系統概述

InsightForge Premium 是一個基於 AI 技術的精準行銷分析平台，專門設計用於分析客戶評論、產生產品屬性評分，並建立銷售預測模型。該系統採用 R Shiny + bs4Dash 框架構建，整合 OpenAI GPT 模型進行智能分析，支援 PostgreSQL 與 SQLite 雙資料庫架構。

### 版本資訊
- **當前版本**: v18.3 (bs4Dash + UI優化)
- **更新日期**: 2025-01-12
- **框架**: R Shiny + bs4Dash
- **AI 模型**: GPT-4o-mini
- **語言**: 繁體中文

### 最新改進 (v18.3) - 2025-01-12
- 📧 **聯絡資訊更新**: 統一更新為 partners@peakedges.com
- 📝 **UI 文字優化**: 改進檔案上傳提示文字，更清楚說明多檔案合併功能

### v18.2 - 2025-01-11
- 📦 **完整樣本數限制**: 
  - 品牌數量上限 10 個
  - 每品牌評論 500 筆上限
  - 每品牌銷售 2,000 筆上限
  - 自動截取超額資料並顯示警告
- ✨ **集中式 Prompt 管理**: 所有 GPT prompts 統一管理在 `database/prompt.csv`
- 🎯 **集中式提示系統**: UI 提示文字統一管理在 `database/hint.csv`
- 🚀 **改進登入效能**: 延遲資料庫連接，加快首頁載入速度
- 🔧 **模組化重構**: 引入 BrandEdge 架構的最佳實踐
- 🐛 **修復頁面切換**: 解決「下一步」按鈕無法切換頁面的問題
- 📊 **擴展屬性分析**: 支援 10-30 個產品屬性分析（原 6-10 個）
- 🎯 **個性化行銷策略**: 新增品牌個性化行銷策略生成
- 🔍 **關鍵字廣告建議**: 新增關鍵字廣告投放建議模組
- 💡 **新品開發建議**: 新增市場缺口分析與新品開發建議

## 核心功能

### 1. 智能評論分析 (AI-Powered Review Analysis)
- **批量評論上傳**: 下圖可上傳多個顧客評論檔案(系統會自動合併)，支援 Excel、CSV 格式
- **AI 屬性萃取**: 使用 GPT 模型自動識別產品關鍵屬性（**10-30 個維度**）
- **智能評分系統**: 對每則評論進行多維度評分（1-5 分制）
- **品牌比較分析**: 跨品牌/產品的屬性表現對比
- **樣本數限制**: 
  - 最多支援 10 個品牌同時分析
  - 每品牌評論上限 500 筆
  - 每品牌銷售數據上限 2,000 筆

### 2. 銷售預測模型 (Sales Prediction Model)
- **Poisson 迴歸分析**: 評估各屬性對銷售的影響力
- **賽道倍數計算**: 識別最具提升潛力的產品屬性
- **邊際效應分析**: 量化每單位改進帶來的銷售提升
- **智能資料對應**: 自動匹配評論資料與銷售資料
- **個性化行銷策略**: 根據屬性分析生成品牌專屬策略

### 3. 行銷策略工具（新增）
- **關鍵字廣告建議**: 基於產品優勢生成 Google/Facebook 廣告關鍵字
- **新品開發建議**: 分析市場缺口，提供產品創新方向
- **廣告時段建議**: 分析最佳投放時間（開發中）
- **個人化廣告**: 針對不同客群客製化廣告內容（開發中）

### 4. 視覺化分析工具
- **PCA 主成分分析**: 3D 視覺化產品屬性分布
- **理想產品分析**: 計算與理想產品的距離並排序
- **互動式圖表**: 使用 Plotly 提供動態視覺化

## 系統架構

### 技術堆疊

```yaml
前端框架:
  - R Shiny
  - bs4Dash v5
  - DataTables
  - Plotly

後端技術:
  - R 語言
  - OpenAI API (GPT-4o-mini)
  - Future/Furrr (平行處理)

資料庫:
  - PostgreSQL (生產環境)
  - SQLite (開發/測試環境)

部署平台:
  - Posit Connect Cloud
  - ShinyApps.io (備選)
```

### 目錄結構

```
InsightForge_premium/
├── app.R                    # 主應用程式入口（v18.1 已整合集中管理）
├── app_config.yaml          # 應用配置檔
├── config/                  # 配置管理
│   ├── config.R            # 系統配置
│   ├── packages.R          # 套件管理
│   ├── module_config.R     # 模組選擇配置（新增）
│   └── .env               # 環境變數（不納入版控）
├── modules/                # 功能模組
│   ├── module_upload.R    # 資料上傳模組（含樣本數限制）
│   ├── module_upload_complete_score.R # 已評分資料上傳模組（新增）
│   ├── module_score.R     # 評分模組 v1
│   ├── module_score_v2.R  # 評分模組 v2（集中式 Prompt，10-30 屬性，500 筆上限）
│   ├── module_wo_b.R      # 分析模組（PCA、理想分析）
│   ├── module_wo_b_v2.R   # 分析模組 v2（集中式管理版）
│   ├── module_login.R     # 登入認證模組
│   ├── module_keyword_ads.R  # 關鍵字廣告建議模組（新增）
│   └── module_product_dev.R  # 新品開發建議模組（新增）
├── database/              # 資料庫與集中管理
│   ├── db_connection.R   # 資料庫連接管理
│   ├── hint.csv          # UI 提示文字集中管理（新增）
│   └── prompt.csv        # GPT Prompts 集中管理（新增）
├── utils/                 # 工具函數
│   ├── data_access.R     # 資料存取介面
│   ├── openai_utils.R    # OpenAI API 工具（新增）
│   ├── hint_system.R     # 提示系統管理（新增）
│   └── prompt_manager.R  # Prompt 管理器（新增）
├── scripts/              # 全域腳本
│   └── global_scripts/   # 共享功能庫
│       ├── 00_principles/   # 開發原則文檔
│       ├── 01_db/           # 資料庫工具
│       ├── 02_db_utils/    # tbl2 資料存取
│       ├── 04_utils/       # 通用工具函數
│       ├── 07_models/      # 統計模型（Poisson 迴歸）
│       └── 10_rshinyapp_components/ # UI 元件
├── www/                  # 靜態資源
│   └── icons/           # 應用圖示
├── md/                   # Markdown 文檔
│   ├── notification.md  # 使用說明
│   └── contacts.md     # 聯絡資訊
└── documents/           # 專案文檔
    └── InsightForge_premium.md # 本文檔
```

## 工作流程

### 雙模式資料處理

系統支援兩種處理模式，可透過 `config/module_config.R` 切換：

#### 模式 1：傳統評論分析流程（原始流程）
1. 上傳客戶評論原始資料
2. AI 自動萃取產品屬性
3. AI 對每則評論進行屬性評分
4. 執行銷售模型分析

#### 模式 2：已評分資料流程（新增）
1. 直接上傳已完成評分的產品屬性資料
2. 動態選擇欄位對應（產品ID、產品名稱、屬性分數）
3. 上傳銷售資料並選擇欄位對應
4. 跳過 AI 評分步驟，直接執行分析

### 三步驟分析流程

#### 步驟 1：資料上傳
1. 使用者登入系統
2. **傳統模式**：上傳客戶評論資料（必填）
   - 支援格式：Excel (.xlsx, .xls) 或 CSV
   - 必要欄位：`Variation`（品牌/產品）、`Title`（標題）、`Body`（評論內容）
   **已評分模式**：上傳已評分資料（必填）
   - 支援格式：Excel 或 CSV
   - 動態選擇欄位：產品ID、產品名稱、多個屬性評分欄位
3. 上傳銷售資料（選填）
   - 支援格式：Excel 或 CSV
   - **傳統模式**必要欄位：`Variation`、`Time`、`Sales`
   - **已評分模式**動態選擇：產品ID、時間、銷售數量欄位
   
**資料限制**：
- 系統自動實施樣本數限制
- 超過限制時自動截取，並顯示警告訊息
- 品牌數超過10個時，僅保留前10個品牌

#### 步驟 2：屬性評分
**傳統模式**：
1. 選擇屬性數量（**10-30 個**）
2. 系統自動產生關鍵屬性
   - AI 分析評論內容
   - 提取最重要的產品特質
3. 選擇分析樣本數（10-500 則，每品牌實際處理上限）
4. 執行智能評分
   - 每則評論對每個屬性評分（1-5 分）
   - 使用平行處理加速

**已評分模式**：
- 跳過此步驟，直接進入銷售模型分析

#### 步驟 3：銷售模型
1. 查看各 Variation 評分均值
2. 執行 Poisson 迴歸分析
3. 解讀分析結果
   - 賽道倍數：戰略優化重點
   - 邊際效應：日常改進方向

## 核心模組詳細說明

### 1. 登入模組 (login_module.R)

#### 功能概述
- 使用者認證與授權管理
- 支援多角色權限（admin/user）
- 登入次數追蹤與限制
- 密碼加密存儲（bcrypt）

#### 實作細節
- **延遲載入**：v18.1 改進，資料庫連接延遲至實際需要時才建立
- **登入流程**：
  1. 驗證帳號密碼（bcrypt 比對）
  2. 檢查登入次數限制（非管理員上限 5 次）
  3. 更新登入計數器
  4. 返回使用者資訊

#### 輸出結果
- `user_info()`：包含使用者 ID、名稱、角色、登入次數
- `logged_in()`：布林值，表示登入狀態

---

### 2. 資料上傳模組

#### 2.1 傳統上傳模組 (module_upload.R)

##### 功能概述
- 多檔案批次上傳：可上傳多個檔案，系統會自動合併
- 自動資料合併與驗證
- 評論與銷售資料分離處理

##### 實作細節
- **資料驗證**：
  - 評論資料必要欄位：`Variation`、`Title`、`Body`
  - 銷售資料必要欄位：`Variation`、`Time`、`Sales`
- **智能合併**：相同格式檔案自動合併
- **資料存儲**：JSON 格式存入資料庫
- **樣本數限制實作** (v18.2)：
  - 品牌數量檢查：`module_upload.R` 第 87-95、151-159 行
  - 評論資料截取：`group_by(Variation) %>% slice_head(n = 500)`
  - 銷售資料截取：`group_by(Variation) %>% slice_head(n = 2000)`
  - UI 警告提示：黃色背景提示框顯示限制說明

##### 輸出結果
- `data()`：處理後的評論資料 data.frame
- `sales_data()`：銷售資料 data.frame
- 資料預覽表格（DataTable）

#### 2.2 已評分資料上傳模組 (module_upload_complete_score.R)

##### 功能概述
- 直接上傳已評分的產品屬性資料
- 動態欄位選擇與對應
- 支援銷售資料上傳與欄位選擇
- 自動計算產品平均分數與總分

##### 實作細節
- **動態欄位選擇**：
  ```r
  # 評分資料欄位選擇
  selectInput("product_id_col", "選擇產品ID欄位")
  selectInput("product_name_col", "選擇產品名稱欄位")
  checkboxGroupInput("selected_attributes", "選擇屬性評分欄位")
  
  # 銷售資料欄位選擇
  selectInput("sales_product_id_col", "選擇產品ID欄位")
  selectInput("sales_time_col", "選擇時間欄位")
  selectInput("sales_quantity_col", "選擇銷售數量欄位")
  ```

- **欄位映射儲存**：
  ```r
  field_mapping = reactive({
    list(
      score = list(
        product_id_col = input$product_id_col,
        product_name_col = input$product_name_col,
        selected_attributes = input$selected_attributes
      ),
      sales = list(
        product_id_col = input$sales_product_id_col,
        time_col = input$sales_time_col,
        quantity_col = input$sales_quantity_col
      )
    )
  })
  ```

- **資料處理流程**：
  1. 讀取 CSV/Excel 檔案
  2. 顯示欄位選擇介面
  3. 根據選擇處理資料
  4. 計算平均分數與總分
  5. 返回處理後資料與欄位映射

##### 輸出結果
- `score_data()`：處理後的評分資料（包含 avg_score, total_score）
- `sales_data()`：處理後的銷售資料
- `attribute_columns()`：選擇的屬性欄位列表
- `field_mapping()`：欄位映射資訊
- `data_ready()`：資料處理完成狀態

---

### 3. 屬性評分模組 (module_score.R)

#### 功能概述
- AI 驅動的產品屬性萃取（10-30 個屬性）
- 多維度智能評分（1-5 分制）
- 平行處理加速運算

#### 實作流程
1. **屬性生成階段**：
   ```r
   # 每個 Variation 抽樣 30 筆評論
   # 使用 GPT-4o-mini 分析產品屬性
   # Prompt: "extract_attributes" (來自 prompt.csv)
   ```
   
2. **評分階段**：
   ```r
   # 每個 Variation 最多處理 100 筆（可調整）
   # 對每個屬性進行 1-5 分評分
   # 使用 furrr 平行處理
   ```

3. **平行處理機制**：
   - 使用 `future::plan(multisession)` 建立多工作階段
   - `furrr::future_map_chr()` 平行呼叫 GPT API
   - 每個評論的多個屬性評分同時進行
   - 錯誤容錯：單一 API 失敗不影響其他評分

#### 技術細節
- **Prompt 管理**：集中式管理（`database/prompt.csv`）
- **平行處理**：`furrr::future_map_chr()` 加速 API 呼叫
- **錯誤處理**：API 失敗時返回 NA，不中斷流程

#### 輸出結果
- `scored_data()`：包含所有屬性評分的 data.frame
- 格式：`[Variation, 屬性1, 屬性2, ..., 屬性N]`
- 每個儲存格為 1-5 的評分或 NA

---

### 4. 銷售模型與個性化策略

#### 功能概述
- Poisson 迴歸分析
- 賽道倍數與邊際效應計算
- 個性化行銷策略生成

#### 分析流程
1. **資料準備**：
   - 計算各 Variation 屬性評分均值
   - 智能匹配評論與銷售資料

2. **Poisson 迴歸**：
   ```r
   # 對每個屬性執行
   glm(Sales ~ 屬性分數, family = poisson())
   ```

3. **指標計算**：
   - **賽道倍數**：`exp(β × (5-1))` - 屬性從最低到最高的影響倍數
   - **邊際效應**：`(exp(β) - 1) × 100%` - 每提升 1 分的銷售增長

#### 個性化策略生成
- **輸入**：品牌屬性分數、Poisson 分析結果
- **處理**：GPT 根據優劣勢屬性生成策略
- **輸出**：
  1. 品牌定位建議
  2. 核心賣點（3 個）
  3. 目標客群定義
  4. 行銷訊息重點
  5. 改進優先順序

---

### 5. 關鍵字廣告建議模組 (module_keyword_ads.R)

#### 功能概述
- 基於產品優勢生成關鍵字
- 支援多平台（Google Ads、Facebook）
- 可下載關鍵字報告

#### 生成邏輯
1. **屬性分析**：找出前 5 個高分屬性
2. **關鍵字類型**：
   - 高轉換關鍵字（交易意圖）
   - 長尾關鍵字（精準定位）
   - 競品比較關鍵字
   - 品牌關鍵字

#### 輸出結果
- 10-20 個建議關鍵字
- 每個關鍵字標註：
  - 搜尋意圖（資訊/交易/導航）
  - 競爭程度（高/中/低）
  - 建議出價策略

#### 技術實作細節
- **備用機制**：當 GPT API 或 prompt 不可用時，使用基本關鍵字生成
- **基本關鍵字模板**：
  ```r
  # 品牌相關：[品牌] + 評價/推薦/比較
  # 屬性相關：[屬性] + [品牌]
  # 通用詞：最佳 + [屬性]
  ```
- **下載功能**：生成 .txt 格式報告供廣告投放使用

---

### 6. 新品開發建議模組 (module_product_dev.R)

#### 功能概述
- 市場缺口分析
- 開發策略建議
- 優先順序規劃

#### 策略選項
1. **填補市場空缺**：聚焦低分屬性（< 中位數）
2. **強化優勢領域**：聚焦高分屬性（≥ 中位數）
3. **創新突破**：結合高低分屬性
4. **競品超越**：全面提升

#### 動態調整機制
- **根據策略**：調整屬性優先級和預期潛力
  - 缺口策略：30-60% 潛力
  - 優勢策略：20-40% 潛力
  - 創新策略：40-70% 潛力
  
- **根據客群**：調整開發方向
  - 大眾市場：功能實用性
  - 高端客群：品質體驗
  - 年輕族群：創新設計
  - 專業用戶：效能規格

#### 輸出結果
1. **市場機會分析**：
   - 市場缺口（低分屬性列表）
   - 競爭優勢（高分屬性列表）
   
2. **開發建議**：
   - 產品概念描述
   - 核心功能規劃
   - 差異化賣點
   
3. **開發路線圖**：
   - 優先級 1-5 項
   - 預期提升潛力
   - 建議開發週期

#### 視覺化呈現設計
- **顏色編碼系統**：
  - 🔴 紅色邊框：優先級 1（最緊急）
  - 🟡 黃色邊框：優先級 2（重要）
  - 🟢 綠色邊框：優先級 3+（一般）
  
- **潛力評估演算法**：
  ```r
  # 根據策略動態調整潛力範圍
  gap_strategy: 30-60%      # 高潛力
  strength_strategy: 20-40%  # 穩定提升
  innovation_strategy: 40-70% # 高風險高回報
  compete_strategy: 25-50%    # 中等潛力
  ```
  
- **開發週期建議**：
  - 優先級 1：3 個月快速迭代
  - 優先級 2：6 個月標準開發
  - 優先級 3+：9 個月長期規劃

---

### 7. 分析模組 (module_wo_b_v2.R)

#### PCA 主成分分析
- **功能**：降維視覺化品牌定位
- **計算**：`prcomp(center=TRUE, scale=TRUE, rank=3)`
- **輸出**：3D 散點圖，顯示品牌在屬性空間的分布

#### 理想產品分析（MAMBA）
- **功能**：計算品牌與理想產品的距離
- **方法**：
  1. 定義理想值 = 各屬性最高分
  2. 計算達成率 = 達到理想值的屬性數/總屬性數
  3. 排序品牌表現

- **輸出**：
  - 品牌排名表
  - 優勢與劣勢屬性
  - 達成率百分比

---

### 8. 集中管理系統（v18.1 新增）

#### 8.1 提示系統 (hint_system.R)
- **功能**: 集中管理所有 UI 提示文字
- **資料來源**: `database/hint.csv`
- **主要函數**:
  - `load_hints()`: 載入提示資料
  - `get_hint()`: 取得特定提示
  - `add_hint()`: 為元件加入提示
  - `add_info_icon()`: 加入資訊圖示
- **支援**: bs4Dash tooltip 整合

#### 8.2 Prompt 管理器 (prompt_manager.R)
- **功能**: 集中管理所有 GPT prompts
- **資料來源**: `database/prompt.csv`
- **主要函數**:
  - `load_prompts()`: 載入 prompt 資料
  - `prepare_gpt_messages()`: 準備 GPT 訊息
  - `replace_prompt_variables()`: 變數替換
- **支援**: 動態變數替換、版本控制

#### 8.3 OpenAI 工具 (openai_utils.R)
- **功能**: 統一的 OpenAI API 介面
- **主要函數**:
  - `chat_api()`: 呼叫 GPT API
- **特性**: 錯誤處理、超時保護、自動重試

## 資料庫設計

### 資料表結構

```sql
-- 使用者資料表
users (
  id           INTEGER PRIMARY KEY,
  username     TEXT UNIQUE,
  hash         TEXT,           -- bcrypt 加密密碼
  role         TEXT,            -- 'admin' 或 'user'
  login_count  INTEGER
)

-- 原始評論資料
rawdata (
  id          INTEGER PRIMARY KEY,
  user_id     INTEGER,
  uploaded_at TEXT,
  json        TEXT              -- JSON 格式評論資料
)

-- 處理後資料
processed_data (
  id          INTEGER PRIMARY KEY,
  user_id     INTEGER,
  created_at  TEXT,
  json        TEXT              -- JSON 格式評分結果
)
```

## 環境配置

### 必要環境變數

```bash
# PostgreSQL 資料庫配置
PGHOST=your_host
PGPORT=5432
PGUSER=your_user
PGPASSWORD=your_password
PGDATABASE=your_database
PGSSLMODE=require

# OpenAI API 金鑰
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxx
```

### 套件依賴

```r
# 核心框架
shiny, bs4Dash, shinyjs, shinyWidgets

# 資料處理
dplyr, tidyr, purrr, jsonlite, stringr

# 資料庫
DBI, RPostgres, RSQLite

# AI 整合
httr2

# 視覺化
DT, plotly

# 平行處理
future, furrr

# 認證
bcrypt

# 其他
readxl, readr, writexl
```

## 統計模型說明

### Poisson 迴歸模型

系統使用 Poisson 迴歸評估產品屬性對銷售的影響：

```r
glm(sales ~ score_attribute, family = poisson(link = "log"), data = analysis_data)
```

**關鍵指標**：
- **賽道倍數** (Track Multiplier): `exp(β × (max_score - min_score))`
  - 解釋：屬性從最低分提升到最高分的總體影響倍數
  - 用途：識別戰略改進重點

- **邊際效應百分比** (Marginal Effect %): `(exp(β) - 1) × 100`
  - 解釋：屬性每提升 1 分帶來的銷售增長百分比
  - 用途：評估日常優化投報率

## 部署指南

### Posit Connect Cloud 部署

1. **環境準備**
   ```bash
   # 檢查必要檔案
   - app.R
   - manifest.json
   - app_config.yaml
   ```

2. **設定環境變數**
   - 在 Posit Connect 建立 Variable Set
   - 配置所有必要的環境變數

3. **部署命令**
   ```r
   rsconnect::deployApp(
     appDir = ".",
     appName = "insightforge-premium",
     server = "posit.cloud"
   )
   ```

### 本地開發環境

1. **安裝依賴套件**
   ```r
   source("config/packages.R")
   initialize_packages()
   ```

2. **配置環境變數**
   - 複製 `config/.env.example` 為 `config/.env`
   - 填入實際配置值

3. **啟動應用**
   ```r
   shiny::runApp("app.R", port = 8080)
   ```

## 模組切換配置

### 配置檔案 (config/module_config.R)

```r
# 設定是否使用已評分資料上傳模組
# TRUE: 使用新的 module_upload_complete_score.R（直接上傳已評分資料）
# FALSE: 使用原始的 module_upload.R + module_score_v2.R（上傳評論後進行評分）

options(use_complete_score_upload = TRUE)
```

### 主程式整合 (app.R)

系統會根據配置自動選擇適當的模組：

```r
# 載入配置
source("config/module_config.R")
USE_COMPLETE_SCORE <- getOption("use_complete_score_upload", FALSE)

# 條件式載入模組
if(USE_COMPLETE_SCORE) {
  source("modules/module_upload_complete_score.R")
} else {
  source("modules/module_upload.R")
  source("modules/module_score_v2.R")
}

# Server 中的條件式處理
if(USE_COMPLETE_SCORE) {
  # 使用已評分資料上傳模組
  score_mod <- uploadCompleteScoreServer("upload_complete", user_id)
  
  # 動態欄位映射
  field_mapping_info <- score_mod$field_mapping()
  if(!is.null(field_mapping_info$sales$product_id_col)) {
    sales_id_field <- field_mapping_info$sales$product_id_col
    sales_data_val$Variation <- sales_data_val[[sales_id_field]]
  }
} else {
  # 使用傳統評論上傳與評分模組
  upload_data <- uploadServer("upload", user_id)
  score_mod <- scoreServerV2("score", upload_data$data, user_id)
}
```

### 動態欄位處理

系統支援動態欄位映射，避免硬編碼欄位名稱：

```r
# 銷售資料 Variation 欄位動態處理
if(!"Variation" %in% names(sales_data_val)) {
  field_mapping_info <- score_mod$field_mapping()
  
  if(!is.null(field_mapping_info$sales$product_id_col)) {
    sales_id_field <- field_mapping_info$sales$product_id_col
    sales_data_val$Variation <- sales_data_val[[sales_id_field]]
  }
}

# 評分資料欄位動態處理
if(!is.null(field_mapping_info$score$product_id_col)) {
  id_field <- field_mapping_info$score$product_id_col
  scored_data_temp <- scored_data_temp %>%
    rename(Variation = !!sym(id_field))
}
```

## 效能優化

### 平行處理策略

#### 架構設計
- 評分作業使用 `future` + `furrr` 平行化
- 生產環境自動調整 worker 數量
- 本地開發預設使用 2 個 worker

#### 實作細節
```r
# 設定平行處理計畫
future::plan(multisession, workers = availableCores() - 1)

# 平行評分範例
results <- furrr::future_map_chr(
  prompts_list,
  function(prompt) {
    tryCatch(
      chat_api(prompt),
      error = function(e) NA_character_
    )
  },
  .options = furrr_options(seed = TRUE)
)
```

#### 效能優化
- **批次處理**：每批 10-20 個請求
- **超時控制**：單一請求 60 秒超時
- **重試機制**：失敗請求自動重試 1 次
- **記憶體管理**：處理完成後立即釋放

### 資料庫優化
- 使用連接池管理資料庫連接
- JSON 格式存儲減少表格複雜度
- 支援 PostgreSQL 與 SQLite 自動切換

### UI 響應優化
- 步驟式引導減少認知負擔
- Progress bar 提供即時回饋
- 資料表使用 DataTables 分頁顯示

## 安全機制

1. **認證授權**
   - bcrypt 密碼加密
   - 角色權限控制
   - 登入狀態管理

2. **API 安全**
   - API 金鑰環境變數存儲
   - 請求超時保護（60 秒）
   - 錯誤處理與日誌記錄

3. **資料保護**
   - 使用者資料隔離
   - SQL 注入防護
   - 敏感資訊不納入版控

## 技術實作深度解析

### 樣本數限制機制

#### 上傳階段處理 (module_upload.R)
```r
# 1. 評論資料限制
dat_all <- dat_all %>%
  group_by(Variation) %>%
  slice_head(n = 500) %>%  # 每品牌最多 500 筆
  ungroup()

# 2. 品牌數量限制
if (length(unique_brands) > 10) {
  dat_all <- dat_all %>%
    filter(Variation %in% unique_brands[1:10])
  showNotification("⚠️ 已限制為前10個品牌")
}
```

#### 評分階段處理 (module_score_v2.R)
```r
# SliderInput 設定
sliderInput(
  ns("nrows"), 
  min = 10,   # 最少 10 筆
  max = 500,  # 最多 500 筆
  value = 50, # 預設 50 筆
  step = 10   # 步進 10 筆
)
```

### 評分演算法詳解

#### 屬性萃取演算法
```r
# 1. 資料抽樣策略
# 每個品牌/Variation 抽樣 30 筆確保代表性
dat_sample <- dplyr::bind_rows(
  lapply(split(dat, dat$Variation), function(df) {
    df[sample(seq_len(nrow(df)), min(30, nrow(df))), ]
  })
)

# 2. GPT 屬性萃取
# 使用產品定位理論框架
# 萃取：屬性、功能、利益、用途
```

#### 評分標準化處理
```r
safe_value <- function(txt) {
  txt <- trimws(txt)
  # 優先提取數字模式
  num <- stringr::str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  # 容錯處理
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}
```

### Poisson 迴歸深度分析

#### 模型選擇理由
- **為何選擇 Poisson**：銷售資料為計數資料（非負整數）
- **連結函數**：使用 log link 確保預測值為正
- **過度離散處理**：當發現過度離散時，考慮負二項迴歸

#### 指標計算公式
```r
# 賽道倍數計算
track_multiplier = exp(coefficient * (5 - 1))
# 解釋：屬性從 1 分提升到 5 分的總體影響

# 邊際效應計算  
marginal_effect = (exp(coefficient) - 1) * 100
# 解釋：每提升 1 分的百分比增長
```

### 策略生成演算法

#### 動態策略調整機制
```r
# 根據屬性分數分布決定策略
if (strategy == "gap") {
  # 聚焦低於中位數的屬性
  focus_attrs <- attrs[scores < median(scores)]
  potential <- runif(1, 30, 60)  # 高潛力
} else if (strategy == "strength") {
  # 聚焦高於中位數的屬性
  focus_attrs <- attrs[scores >= median(scores)]
  potential <- runif(1, 20, 40)  # 穩定提升
}
```

## 故障排除

### 常見問題

1. **OpenAI API 連接失敗**
   - 檢查 `OPENAI_API_KEY` 是否正確設定
   - 確認網路連接正常
   - 查看 API 配額是否充足
   - 檢查 `utils/openai_utils.R` 是否載入

2. **資料庫連接錯誤**
   - PostgreSQL 連接失敗會自動切換到 SQLite
   - 檢查環境變數配置
   - 確認資料庫服務運行中

3. **評分結果異常**
   - 確認上傳資料格式正確
   - 檢查必要欄位完整性
   - 重新產生屬性後再評分
   - 確認 `database/prompt.csv` 存在且格式正確

4. **頁面切換失敗**
   - 確認 `updateTabItems()` 正確呼叫
   - 檢查 tab 名稱是否一致
   - 確認 reactive 事件正確觸發

5. **提示系統無法載入**
   - 檢查 `database/hint.csv` 是否存在
   - 確認 CSV 格式正確（var_id, title, content）
   - 驗證 `utils/hint_system.R` 已載入

6. **已評分資料上傳問題**
   - 確認 CSV 檔案編碼為 UTF-8
   - 檢查數值欄位是否包含非數值資料
   - 驗證產品 ID 欄位不含空值
   - 確認 `config/module_config.R` 設定正確

7. **銷售模型資料傳遞失敗**
   - 檢查 score_mod 變數作用域
   - 確認 field_mapping() 回傳值不為 NULL
   - 驗證 Variation 欄位正確映射
   - 查看控制台除錯訊息

## 測試工具

### 測試資料生成 (test_complete_score_data.R)

```r
# 創建測試用的已評分資料
create_test_score_data <- function() {
  score_data <- data.frame(
    product_id = paste0("PRD", sprintf("%04d", 1:10)),
    product_name = product_names,
    新鮮 = round(runif(10, 3, 5), 1),
    美味 = round(runif(10, 3, 5), 1),
    營養 = round(runif(10, 2, 5), 1),
    # ... 更多屬性
  )
  write.csv(score_data, "test_score_data.csv", row.names = FALSE)
}

# 創建測試用的銷售資料
create_test_sales_data <- function(products) {
  sales_data <- expand.grid(
    product_id = products,
    month = 1:6
  ) %>%
    mutate(
      period = paste0("2024-", sprintf("%02d", month)),
      Sales = round(runif(n(), 50, 200)),
      sale_price = round(runif(n(), 100, 500))
    )
  write.csv(sales_data, "test_sales_data.csv", row.names = FALSE)
}
```

### 測試應用 (test_upload_complete_score.R)

獨立測試應用，用於驗證已評分資料上傳模組：
- 載入 `module_upload_complete_score.R`
- 提供完整的上傳、預覽、分析流程
- 包含屬性排名、產品表現、視覺化分析
- 支援 Poisson 迴歸分析（需銷售資料）

## 版本更新歷程

### v18.4 (2025-01-16)
- ✅ 新增已評分資料上傳模組 (`module_upload_complete_score.R`)
- ✅ 實作動態欄位映射功能
- ✅ 支援雙模式切換（評論分析 vs 已評分資料）
- ✅ 修復銷售模型分析資料傳遞問題
- ✅ 優化變數作用域管理
- ✅ 新增測試資料生成工具
- ✅ 完善模組配置管理系統

### v18.3 (2025-01-12)
- ✅ 更新聯絡資訊為 partners@peakedges.com
- ✅ 優化上傳模組 UI 文字描述
- ✅ 改進多檔案上傳提示說明

### v18.2 (2025-01-11)
- ✅ 完整實作樣本數限制機制
- ✅ 優化評分模組參數設定
- ✅ 加入 UI 限制說明提示
- ✅ 更新完整文檔

### v18.1 (2025-01-11)
- ✅ 實作集中式 Prompt 管理系統
- ✅ 實作集中式提示系統
- ✅ 改進登入模組效能
- ✅ 修復頁面切換問題
- ✅ 整合 BrandEdge 架構優點
- ✅ 擴展屬性分析範圍（10-30 個）
- ✅ 新增個性化行銷策略生成
- ✅ 新增關鍵字廣告建議模組
- ✅ 新增新品開發建議模組
- ⏳ 廣告時段建議（介面預留）
- ⏳ 個人化廣告輸出（介面預留）

### v18.0 (2024-06-23)
- 初始版本發布
- bs4Dash 框架整合
- Poisson 迴歸模型實作
- 多資料庫支援

## 未來發展

### 計劃功能
- [ ] **廣告時段建議**：整合 `scripts/global_scripts/01_db/108g_create_or_replace_time_range_dta.R`
- [ ] **個人化廣告**：利用 `scripts/global_scripts/01_db/fn_create_df_customer_profile.R`
- [ ] **競品分析**：整合 `scripts/global_scripts/01_db/0101g_create_or_replace_amazon_competitor_sales_dta.R`
- [ ] 多語言支援（英文介面）
- [ ] 批次報告生成
- [ ] 歷史分析對比
- [ ] 自訂評分維度
- [ ] API 服務介面

### 技術優化
- [ ] 使用 `scripts/global_scripts/07_models/SGD.R` 優化模型效能
- [ ] 整合 `scripts/global_scripts/05_etl_utils/` ETL 工具
- [ ] Redis 快取層
- [ ] 非同步任務佇列
- [ ] 微服務架構
- [ ] 容器化部署

### 相關文檔
- 📄 [待開發功能詳細說明](pending_features.md)

## 聯絡資訊

- **系統維護**: IT Support Team
- **業務諮詢**: Marketing Analytics Team
- **技術支援**: partners@peakedges.com
- **商業合作**: partners@peakedges.com

---

*文檔版本: 1.4*  
*最後更新: 2025-01-16*  
*© 2025 InsightForge Premium - All Rights Reserved*