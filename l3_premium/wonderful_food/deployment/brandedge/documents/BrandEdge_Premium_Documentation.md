# BrandEdge Premium - 品牌印記引擎完整技術文檔

## 目錄
1. [系統概述](#系統概述)
2. [最新系統架構](#最新系統架構)
3. [資料處理架構](#資料處理架構)
4. [核心模組詳解](#核心模組詳解)
5. [函數與API參考](#函數與api參考)
6. [資料流程與狀態管理](#資料流程與狀態管理)
7. [屬性欄位管理系統](#屬性欄位管理系統)
8. [部署與環境配置](#部署與環境配置)
9. [維護與除錯指南](#維護與除錯指南)
10. [版本歷史與更新](#版本歷史與更新)

---

## 系統概述

BrandEdge Premium 是一個企業級品牌分析平台，專為處理已評分的產品屬性資料而設計。系統支援動態屬性選擇、多維度品牌分析，並提供完整的市場洞察。

### 核心特色
- **動態屬性系統**：支援上傳時自由選擇分析屬性（不限數量）
- **預評分資料處理**：直接處理已完成屬性評分的資料，無需AI評分步驟
- **嚴格欄位控制**：只分析使用者選擇的屬性，自動排除計算欄位
- **Metadata驅動架構**：透過屬性metadata在模組間傳遞資訊
- **完整分析模組**：8大核心分析模組覆蓋市場分析全面向
- **資料結構標準化**：Variation(產品ID)、product_name、brand三層結構

### 版本資訊
- **當前版本**：v4.0.0 Premium Edition
- **更新日期**：2025-01-16
- **主要更新**：
  - 全新上傳已評分資料模組
  - 動態屬性欄位選擇系統
  - Metadata驅動的分析架構
  - 嚴格的屬性欄位過濾機制

---

## 最新系統架構

### 應用程式架構圖
```
┌─────────────────────────────────────────────────────────────────┐
│                    使用者介面層 (UI Layer)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  bs4Dash Framework + Shiny Reactive System              │    │
│  │  ┌───────────────────────────────────────────────────┐  │    │
│  │  │ module_upload_complete_score.R                    │  │    │
│  │  │ - 上傳已評分資料                                    │  │    │
│  │  │ - 動態欄位選擇 (產品ID/名稱/品牌/屬性)              │  │    │
│  │  │ - 資料預覽與驗證                                    │  │    │
│  │  └───────────────────────────────────────────────────┘  │    │
│  │  ┌───────────────────────────────────────────────────┐  │    │
│  │  │ 分析模組群組                                        │  │    │
│  │  │ - module_market_profile_enhanced.R               │  │    │
│  │  │ - module_brandedge_flagship.R                    │  │    │
│  │  │ - module_wo_b.R                                  │  │    │
│  │  └───────────────────────────────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                  資料處理層 (Data Processing Layer)               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Metadata Management System                             │    │
│  │  - attr(data, "attribute_columns") 屬性欄位儲存         │    │
│  │  - 動態欄位識別與過濾                                     │    │
│  │  - 計算欄位自動排除                                       │    │
│  └─────────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Data Transformation Pipeline                           │    │
│  │  - CSV/Excel 讀取與編碼處理                              │    │
│  │  - 欄位映射與重命名                                       │    │
│  │  - 資料型別轉換與驗證                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│                    核心邏輯層 (Core Logic Layer)                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  app.R - 主應用控制器                                      │    │
│  │  - Session 管理與狀態控制                                  │    │
│  │  - 模組間資料傳遞協調                                      │    │
│  │  - Reactive 資料流管理                                     │    │
│  │  - 屬性 Metadata 傳播                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### 檔案結構與功能對應
```
wonderful_food_BrandEdge_premium/
│
├── app.R                                    # 主應用程式
│   ├── UI定義
│   │   ├── 側邊欄選單結構
│   │   └── 主要內容區域
│   └── Server邏輯
│       ├── 上傳模組整合
│       ├── 資料流控制
│       └── Metadata傳遞
│
├── modules/                                 # 功能模組
│   ├── module_upload_complete_score.R      # ⭐ 核心上傳模組
│   │   ├── uploadCompleteScoreUI()
│   │   └── uploadCompleteScoreServer()
│   │       ├── 檔案上傳處理
│   │       ├── 欄位智能識別
│   │       ├── 動態UI生成
│   │       └── 資料結構建立
│   │
│   ├── module_market_profile_enhanced.R    # 市場輪廓分析
│   │   ├── marketProfileEnhancedUI()
│   │   └── marketProfileEnhancedServer()
│   │       ├── analyze_segments()
│   │       ├── 屬性相關性分析
│   │       └── 市場區隔視覺化
│   │
│   ├── module_brandedge_flagship.R         # 品牌定位分析
│   │   ├── marketTrackModuleServer()       # 市場賽道
│   │   ├── advancedDNAModuleServer()       # DNA分析
│   │   ├── strategyModuleServer()          # 策略定位
│   │   ├── pcaModuleServer()               # PCA分析
│   │   └── idealModuleServer()             # 理想點分析
│   │
│   └── module_wo_b.R                       # WO分析模組
│       ├── wo_bModuleUI()
│       └── wo_bModuleServer()
│
├── database/                                # 資料與配置
│   ├── prompt.csv                          # AI提示詞
│   ├── hint.csv                            # UI提示
│   └── brandedge_test.db                   # 測試資料庫
│
├── documents/                               # 文檔
│   ├── BrandEdge_Premium_Documentation.md  # 本文檔
│   └── README_upload_complete_score.md     # 上傳模組說明
│
└── tests/                                   # 測試腳本
    ├── test_dynamic_columns.R              # 動態欄位測試
    ├── test_attribute_metadata.R           # Metadata測試
    ├── test_strict_attributes.R            # 屬性過濾測試
    └── test_complete_attribute_system.R    # 系統整合測試
```

---

## 資料處理架構

### 資料流程圖
```
┌─────────────────────────────────────────────────────────┐
│           Step 1: 檔案上傳與讀取                          │
│  支援格式: CSV, Excel (自動編碼偵測: UTF-8/Big5)          │
│  檔案大小限制: 100MB                                      │
│  資料筆數限制: 無特定限制                                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│           Step 2: 欄位智能識別                            │
│  產品ID模式: product_id, ASIN, SKU, 產品編號              │
│  產品名稱模式: product_name, name, title, 產品名稱        │
│  品牌模式: brand, Brand, 品牌, variation                 │
│  屬性識別: 數值型欄位, 排除計算欄位                        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│           Step 3: 使用者欄位選擇                          │
│  必選: 產品ID欄位, 產品名稱欄位                           │
│  可選: 品牌欄位 (可複製其他欄位內容)                       │
│  多選: 屬性欄位 (checkbox選擇)                            │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│           Step 4: 資料結構標準化                          │
│  欄位重命名:                                              │
│  - 第1欄 → Variation (使用產品ID)                         │
│  - 第2欄 → product_name                                  │
│  - 第3欄 → brand (品牌資訊或預設值)                       │
│  - 其餘欄位保留原名 (選擇的屬性)                           │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│           Step 5: Metadata設定與傳遞                      │
│  attr(data, "attribute_columns") <- selected_attributes  │
│  確保所有分析模組只使用選擇的屬性                          │
│  自動排除: total_score, avg_score, 總分, 平均分           │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│           Step 6: 分析模組處理                            │
│  所有模組統一流程:                                        │
│  1. 讀取 attr(data, "attribute_columns")                │
│  2. 驗證屬性欄位存在性                                    │
│  3. 確保數值型態                                          │
│  4. 執行特定分析                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 核心模組詳解

### 1. 上傳完整評分模組 (module_upload_complete_score.R)

#### 主要功能
- 處理已完成屬性評分的資料檔案
- 提供智能欄位識別與映射
- 動態生成屬性選擇介面
- 建立標準化資料結構

#### 關鍵函數

```r
# UI函數
uploadCompleteScoreUI <- function(id) {
  # 功能：建立上傳介面
  # 參數：id - 模組命名空間
  # 返回：UI元素列表
}

# Server函數
uploadCompleteScoreServer <- function(id, user_id) {
  # 功能：處理上傳邏輯
  # 參數：
  #   id - 模組命名空間
  #   user_id - 使用者識別
  # 返回：list(
  #   data = reactive(),        # 處理後的資料
  #   attributes = reactive(),   # 選擇的屬性列表
  #   has_brand = reactive(),   # 是否有品牌欄位
  #   brands = reactive(),       # 品牌列表
  #   variations = reactive()    # 產品ID列表
  # )
}
```

#### 內部狀態管理
```r
values <- reactiveValues(
  score_data = NULL,          # 原始上傳資料
  score_columns = character(), # 所有欄位名稱
  score_file_uploaded = FALSE, # 檔案上傳狀態
  processed_score = NULL,      # 處理後資料
  attribute_columns = NULL,    # 選擇的屬性欄位
  data_processed = FALSE,      # 處理完成狀態
  field_mapping = list()       # 欄位映射資訊
)
```

#### 欄位識別邏輯
```r
# 排除模式（不會被識別為屬性）
exclude_patterns <- c(
  "id", "ID", "name", "名稱", "title", "Title",
  "total", "avg", "sum", "count", "mean", "std",
  "brand", "Brand", "品牌", "ASIN", "SKU", "sku",
  "score", "Score", "分數", "總分", "平均", "合計",
  "total_score", "avg_score", "average", "總計"
)
```

### 2. 市場輪廓增強模組 (module_market_profile_enhanced.R)

#### 主要功能
- 市場區隔分析與視覺化
- 品牌強弱項評估
- 屬性相關性熱力圖
- 動態市場洞察報告

#### 關鍵分析函數

```r
analyze_segments <- reactive({
  # 嚴格使用 metadata 中的屬性欄位
  attr_cols <- attr(df, "attribute_columns")

  if (is.null(attr_cols)) {
    showNotification("錯誤：未找到屬性欄位資訊", type = "error")
    return(data.frame())
  }

  # 排除計算欄位
  exclude_cols <- c("total_score", "avg_score", "總分", "平均分")
  attr_cols <- attr_cols[!attr_cols %in% exclude_cols]

  # 執行區隔分析...
})
```

### 3. 品牌定位旗艦模組 (module_brandedge_flagship.R)

#### 子模組結構

##### 3.1 市場賽道分析 (marketTrackModule)
```r
marketTrackModuleServer <- function(id, data) {
  # 識別高潛力發展賽道
  # 計算成長潛力與市場重要性
  # 生成四象限策略矩陣
}
```

##### 3.2 進階DNA分析 (advancedDNAModule)
```r
advancedDNAModuleServer <- function(id, data_full, selected_brands) {
  # 多品牌雷達圖比較
  # 競爭優勢識別
  # 使用動態屬性欄位
}
```

##### 3.3 品牌定位策略 (strategyModule)
```r
strategyModuleServer <- function(id, data, key_vars) {
  # 四象限策略分析
  # 只使用選擇的屬性欄位
  # GPT整合策略建議
}
```

##### 3.4 PCA主成分分析 (pcaModule)
```r
pcaModuleServer <- function(id, data) {
  # 降維分析
  # 品牌定位圖
  # 嚴格使用屬性metadata
}
```

### 4. WO分析模組 (module_wo_b.R)

#### 主要功能
- 理想點(Ideal)分析
- 品牌排名計算
- 策略四象限圖
- AI策略建議

#### 關鍵計算
```r
# Score計算（只使用選擇的屬性）
attr_cols <- attr(raw(), "attribute_columns")
if (!is.null(attr_cols)) {
  score_cols <- intersect(key_vars(), attr_cols)
} else {
  score_cols <- key_vars()
}

df$Score <- ind %>%
  select(any_of(score_cols)) %>%
  rowSums(na.rm = TRUE)
```

---

## 函數與API參考

### 全域Reactive變數 (app.R)

```r
# ========== 核心資料儲存 ==========
scoring_data <- reactiveVal(NULL)
# 結構：data.frame
# 欄位：
#   Variation - 產品ID (ASIN/SKU)
#   product_name - 產品名稱
#   brand - 品牌
#   [屬性1, 屬性2, ...] - 動態屬性欄位

facets_rv <- reactiveVal(NULL)
# 類型：character vector
# 內容：選擇的屬性名稱列表

complete_score_data <- reactive({
  # 從上傳模組獲取處理後資料
  upload_module$data()
})

complete_score_attributes <- reactive({
  # 從上傳模組獲取屬性列表
  upload_module$attributes()
})
```

### 屬性識別與管理函數

```r
# 從資料獲取屬性欄位
get_attribute_columns <- function(data) {
  attr_cols <- attr(data, "attribute_columns")

  if (is.null(attr_cols)) {
    warning("No attribute metadata found")
    return(character(0))
  }

  # 確保欄位存在
  attr_cols <- attr_cols[attr_cols %in% names(data)]

  # 排除計算欄位
  exclude <- c("total_score", "avg_score", "總分", "平均分")
  attr_cols <- attr_cols[!attr_cols %in% exclude]

  # 確保是數值型
  attr_cols <- attr_cols[sapply(data[attr_cols], is.numeric)]

  return(attr_cols)
}

# 設定屬性metadata
set_attribute_metadata <- function(data, attributes) {
  attr(data, "attribute_columns") <- attributes
  return(data)
}
```

### 資料驗證函數

```r
# 驗證上傳資料
validate_upload_data <- function(data) {
  errors <- character()

  # 檢查必要欄位
  if (!"Variation" %in% names(data)) {
    errors <- c(errors, "缺少Variation欄位")
  }

  if (!"product_name" %in% names(data)) {
    errors <- c(errors, "缺少product_name欄位")
  }

  # 檢查資料筆數
  if (nrow(data) < 2) {
    errors <- c(errors, "資料至少需要2筆")
  }

  # 檢查屬性欄位
  attr_cols <- attr(data, "attribute_columns")
  if (is.null(attr_cols) || length(attr_cols) == 0) {
    errors <- c(errors, "未選擇任何屬性欄位")
  }

  return(errors)
}
```

---

## 資料流程與狀態管理

### Reactive資料流

```
使用者上傳檔案
    ↓
uploadCompleteScoreServer 處理
    ↓
設定 attr(data, "attribute_columns")
    ↓
app.R 接收並傳播資料
    ↓
各分析模組讀取 metadata
    ↓
執行特定屬性分析
```

### 模組間通訊模式

```r
# 在 app.R 中
upload_module <- uploadCompleteScoreServer("upload_complete", user_id = user_info)

# 傳遞資料給分析模組
observeEvent(upload_module$data(), {
  data <- upload_module$data()

  # 設定屬性metadata
  if (!is.null(upload_module$attributes())) {
    attr(data, "attribute_columns") <- upload_module$attributes()
  }

  # 更新全域資料
  scoring_data(data)
})

# 分析模組使用資料
marketProfileEnhancedServer("market_enhanced",
  data = reactive({
    data <- scoring_data()
    # metadata會自動傳遞
    return(data)
  })
)
```

---

## 屬性欄位管理系統

### 設計原則

1. **嚴格性**：只使用使用者明確選擇的屬性
2. **排他性**：自動排除所有計算欄位
3. **追蹤性**：透過metadata在模組間傳遞
4. **容錯性**：提供明確錯誤訊息

### 排除規則

自動排除的欄位模式：
- 計算結果：total_score, avg_score, 總分, 平均分, 總計
- 統計指標：sum, mean, count, std, average
- 識別欄位：id, ID, SKU, ASIN (除非作為Variation)
- 元資料：sales_count, review_count, rating

### 實作範例

```r
# 正確的屬性使用方式
analyze_attributes <- function(data) {
  # 步驟1：獲取metadata
  attr_cols <- attr(data, "attribute_columns")

  # 步驟2：驗證
  if (is.null(attr_cols)) {
    stop("未找到屬性欄位資訊")
  }

  # 步驟3：確保存在
  attr_cols <- attr_cols[attr_cols %in% names(data)]

  # 步驟4：類型檢查
  attr_cols <- attr_cols[sapply(data[attr_cols], is.numeric)]

  # 步驟5：使用屬性
  if (length(attr_cols) > 0) {
    result <- data %>%
      select(all_of(attr_cols)) %>%
      # 執行分析...
  }

  return(result)
}
```

---

## 部署與環境配置

### 系統需求

#### R版本與套件
```r
# R版本需求
R >= 4.0.0

# 必要套件
install.packages(c(
  "shiny",           # 1.7.0+
  "bs4Dash",         # 2.0.0+
  "DT",              # 0.20+
  "plotly",          # 4.10.0+
  "dplyr",           # 1.0.0+
  "tidyr",           # 1.2.0+
  "readr",           # 2.0.0+
  "readxl",          # 1.4.0+
  "shinycssloaders", # 1.0.0+
  "DBI",             # 1.1.0+
  "RSQLite",         # 2.2.0+
  "bcrypt"           # 0.2+
))
```

### 環境變數設定

```bash
# .env 檔案範例
# OpenAI設定（如需AI功能）
OPENAI_API_KEY=sk-...

# 資料庫設定（生產環境）
PGHOST=localhost
PGPORT=5432
PGUSER=brandedge_user
PGPASSWORD=secure_password
PGDATABASE=brandedge_db
PGSSLMODE=require

# 應用設定
SHINY_PORT=3838
SHINY_HOST=0.0.0.0
```

### 執行指令

#### 本地開發
```bash
# 設定工作目錄
cd /path/to/wonderful_food_BrandEdge_premium

# 執行應用
Rscript -e "shiny::runApp('app.R', port = 3838, host = '127.0.0.1')"
```

#### Docker部署
```dockerfile
FROM rocker/shiny:4.2.0

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev

# 安裝R套件
RUN R -e "install.packages(c('shiny', 'bs4Dash', 'DT', ...))"

# 複製應用
COPY . /srv/shiny-server/

# 執行
CMD ["/usr/bin/shiny-server"]
```

---

## 維護與除錯指南

### 常見問題與解決方案

#### 1. 屬性欄位未正確識別
```r
# 問題：分析顯示"未找到屬性欄位資訊"
# 檢查點：
1. 確認上傳模組有選擇屬性
2. 檢查 attr(data, "attribute_columns") 是否設定
3. 驗證欄位名稱是否匹配

# 除錯程式碼：
cat("屬性欄位:", paste(attr(data, "attribute_columns"), collapse = ", "), "\n")
cat("資料欄位:", paste(names(data), collapse = ", "), "\n")
```

#### 2. 計算欄位被誤用
```r
# 問題：total_score等欄位出現在分析中
# 解決：確保排除邏輯正確執行

exclude_cols <- c("total_score", "avg_score", "總分", "平均分")
attr_cols <- attr_cols[!attr_cols %in% exclude_cols]
```

#### 3. 編碼問題
```r
# 問題：中文顯示亂碼
# 解決：使用正確的編碼讀取

data <- tryCatch(
  read.csv(file, fileEncoding = "UTF-8"),
  error = function(e) {
    read.csv(file, fileEncoding = "Big5")
  }
)
```

### 效能優化建議

1. **資料量控制**
   - 限制上傳檔案大小（建議 < 50MB）
   - 使用資料分頁顯示大型表格

2. **Reactive優化**
   - 使用 `isolate()` 避免不必要的更新
   - 實施 `debounce()` 減少頻繁觸發

3. **記憶體管理**
   - 定期清理大型物件
   - 使用 `gc()` 手動回收記憶體

### 日誌與監控

```r
# 啟用詳細日誌
options(shiny.trace = TRUE)
options(shiny.fullstacktrace = TRUE)

# 自定義日誌函數
log_action <- function(action, details = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message <- paste0("[", timestamp, "] ", action)
  if (!is.null(details)) {
    message <- paste0(message, " - ", details)
  }
  cat(message, "\n")

  # 寫入日誌檔案
  write(message, file = "app.log", append = TRUE)
}
```

---

## 版本歷史與更新

### v4.0.0 (2025-01-16)
- 🆕 全新上傳已評分資料模組
- 🆕 動態屬性欄位選擇系統
- 🔧 Metadata驅動架構實作
- 🔧 嚴格屬性欄位過濾機制
- 📝 完整技術文檔更新

### v3.2.1 (2025-01-12)
- 移除PCA定位地圖功能
- 更新系統名稱為「品牌印記引擎」
- 統一聯絡資訊

### v3.0.0 (2024-12-01)
- 初始Premium版本發布
- 8大核心分析模組
- AI整合功能

---

## 測試套件

### 可用測試腳本

1. **test_dynamic_columns.R**
   - 測試動態欄位選擇功能
   - 驗證屬性識別邏輯

2. **test_attribute_metadata.R**
   - 測試metadata傳遞機制
   - 驗證模組間通訊

3. **test_strict_attributes.R**
   - 測試嚴格屬性過濾
   - 驗證計算欄位排除

4. **test_complete_attribute_system.R**
   - 完整系統整合測試
   - 端到端功能驗證

### 執行測試
```bash
# 執行所有測試
Rscript tests/run_all_tests.R

# 執行單一測試
Rscript tests/test_dynamic_columns.R
```

---

## 聯絡資訊

**技術支援**
- Email: partners@peakedges.com
- 系統版本：v4.0.0 Premium Edition
- 文檔更新：2025-01-16

---

*BrandEdge Premium - 以數據驅動的品牌策略分析平台*