# BrandEdge 旗艦版 - 系統增強功能使用指南

## 版本更新
- **更新日期**：2025-01-11
- **版本**：v3.1
- **主要更新**：新增提示系統與集中式 Prompt 管理

---

## 目錄
1. [系統增強概述](#系統增強概述)
2. [UI 提示系統](#ui-提示系統)
3. [GPT Prompt 集中管理系統](#gpt-prompt-集中管理系統)
4. [架構改進](#架構改進)
5. [使用範例](#使用範例)
6. [維護指南](#維護指南)

---

## 系統增強概述

### 新增功能
1. **UI 提示系統**：為使用者介面元素提供即時提示說明
2. **Prompt 集中管理**：統一管理所有 GPT API 的 prompts
3. **模組化設計**：提升系統可維護性與擴展性

### 系統優勢
- 🎯 **使用者體驗提升**：即時提示協助使用者理解功能
- 📝 **維護便利**：集中管理 prompts，無需修改程式碼
- 🔄 **版本控制**：CSV 格式易於追蹤變更
- 🚀 **開發效率**：標準化的 API 呼叫流程

---

## UI 提示系統

### 系統架構

#### 檔案結構
```
database/
├── hint.csv                    # 提示資料檔
utils/
├── hint_system.R               # 提示系統核心功能
```

#### hint.csv 結構
| 欄位名稱 | 說明 | 範例 |
|---------|------|------|
| concept_name | UI 上顯示的文字 | "上傳資料" |
| var_id | 元素識別碼 | "upload_button" |
| description | 提示說明內容 | "點擊此按鈕上傳您的評論資料檔案" |

### 核心功能

#### 1. 載入提示資料
```r
# 載入所有提示
hints_df <- load_hints()
```

#### 2. 取得特定提示
```r
# 取得單一提示內容
hint_text <- get_hint("upload_button")
```

#### 3. 為 UI 元素添加提示
```r
# 使用 bs4Dash 的 tooltip 功能
add_hint(
  fileInput("file", "選擇檔案"),
  var_id = "upload_button",
  enable_hints = TRUE
)
```

### 實際應用範例

#### 在 app.R 中的使用
```r
# 載入提示系統
source("utils/hint_system.R")

# UI 部分
add_hint(
  fileInput("file", "選擇檔案", 
           accept = c(".xlsx", ".xls", ".csv")),
  var_id = "upload_button",
  enable_hints = TRUE
)

add_hint(
  sliderInput("num_attributes", 
             "要萃取的屬性數量：",
             min = 10, max = 30, value = 15),
  var_id = "num_attributes",
  enable_hints = TRUE
)
```

### 新增提示步驟

1. **編輯 hint.csv**
```csv
"新功能名稱","new_feature_id","這是新功能的詳細說明"
```

2. **在 UI 中使用**
```r
add_hint(
  你的UI元素,
  var_id = "new_feature_id",
  enable_hints = TRUE
)
```

---

## GPT Prompt 集中管理系統

### 系統架構

#### 檔案結構
```
database/
├── prompt.csv                  # Prompt 資料檔
utils/
├── prompt_manager.R           # Prompt 管理系統核心
modules/
├── module_brandedge_flagship.R # 已整合
└── module_wo_b.R              # 已整合
```

#### prompt.csv 結構
| 欄位名稱 | 說明 | 範例 |
|---------|------|------|
| analysis_name | 分析名稱 | "屬性萃取" |
| var_id | Prompt 識別碼 | "extract_attributes" |
| prompt | 完整 prompt 內容 | "system: ...\nuser: ..." |

### 核心功能

#### 1. 載入 Prompts
```r
# 載入所有 prompts
prompts_df <- load_prompts()
```

#### 2. 準備 GPT 消息
```r
# 準備 API 請求格式
messages <- prepare_gpt_messages(
  var_id = "extract_attributes",
  variables = list(
    num_attributes = 15,
    sample_reviews = "評論內容..."
  ),
  prompts_df = prompts_df
)
```

#### 3. 執行 API 請求
```r
# 使用準備好的消息執行 API
response <- chat_api(messages)
```

### 已整合的分析功能

| 分析類型 | var_id | 用途 |
|---------|--------|------|
| 屬性萃取 | extract_attributes | 從評論中萃取產品屬性 |
| 屬性評分 | score_attributes | 對屬性進行評分 |
| 品牌識別度策略 | brand_identity_strategy | 生成品牌策略 |
| 定位策略建議 | positioning_strategy | 品牌定位建議 |
| 市場賽道分析 | market_track_analysis | 識別市場機會 |
| 目標市場輪廓 | market_profile_analysis | 市場區隔分析 |
| 理想點分析 | ideal_point_analysis | 品牌優化建議 |
| PCA定位解讀 | pca_interpretation | 主成分分析解釋 |

### Prompt 變數系統

#### 變數替換機制
Prompt 中使用 `{variable_name}` 格式定義變數：

```
prompt 內容：
"請從以下評論中萃取{num_attributes}個最重要的產品屬性..."

使用時：
variables = list(num_attributes = 15)
結果：
"請從以下評論中萃取15個最重要的產品屬性..."
```

### 實際應用範例

#### 原始方式（硬編碼）
```r
# 之前的方式
sys <- list(role = "system", 
           content = "你是產品屬性分析專家...")
usr <- list(role = "user", 
           content = paste0("請從以下評論中萃取..."))
response <- chat_api(list(sys, usr))
```

#### 新方式（集中管理）
```r
# 現在的方式
messages <- prepare_gpt_messages(
  var_id = "extract_attributes",
  variables = list(
    num_attributes = input$num_attributes,
    sample_reviews = sample_text
  ),
  prompts_df = prompts_df
)
response <- chat_api(messages)
```

### 新增 Prompt 步驟

1. **編輯 prompt.csv**
```csv
"新分析功能","new_analysis_id","system: 系統角色\nuser: 使用者指令{variable1}"
```

2. **在程式碼中使用**
```r
messages <- prepare_gpt_messages(
  var_id = "new_analysis_id",
  variables = list(variable1 = "值"),
  prompts_df = prompts_df
)
```

---

## 架構改進

### 模組載入順序
```r
# app.R 載入順序
1. 套件載入
2. source("config/config.R")
3. source("database/db_connection.R")
4. source("utils/hint_system.R")        # 新增
5. source("utils/prompt_manager.R")     # 新增
6. validate_config()
```

### 模組間依賴關係
```
app.R
├── hint_system.R
│   └── database/hint.csv
├── prompt_manager.R
│   └── database/prompt.csv
├── module_brandedge_flagship.R
│   └── 使用 prompt_manager
└── module_wo_b.R
    └── 使用 prompt_manager
```

---

## 使用範例

### 完整的屬性分析流程

```r
# 1. 初始化
source("utils/prompt_manager.R")
prompts_df <- load_prompts()

# 2. 準備資料
sample_reviews <- review_data %>%
  sample_n(50) %>%
  pull(Body) %>%
  paste(collapse = " ")

# 3. 屬性萃取
extract_messages <- prepare_gpt_messages(
  var_id = "extract_attributes",
  variables = list(
    num_attributes = 15,
    sample_reviews = substr(sample_reviews, 1, 3000)
  ),
  prompts_df = prompts_df
)

attributes_response <- chat_api(extract_messages)
attributes <- fromJSON(attributes_response)$attributes

# 4. 屬性評分
score_messages <- prepare_gpt_messages(
  var_id = "score_attributes",
  variables = list(
    attributes = paste(attributes, collapse = ", "),
    review_text = single_review
  ),
  prompts_df = prompts_df
)

scores_response <- chat_api(score_messages, max_tokens = 500)
scores <- fromJSON(scores_response)$scores
```

---

## 維護指南

### 日常維護

#### 1. 更新提示內容
```bash
# 編輯 CSV 檔案
vi database/hint.csv
# 或
vi database/prompt.csv
```

#### 2. 測試系統
```r
# 測試提示系統
source("test_hint_system.R")

# 測試 Prompt 管理系統
source("test_prompt_manager.R")

# 測試整合系統
source("test_integrated_prompt_system.R")
```

#### 3. 監控與除錯

##### 檢查載入狀態
```r
# 檢查提示載入
hints_df <- load_hints()
print(nrow(hints_df))  # 應顯示提示數量

# 檢查 Prompt 載入
prompts_df <- load_prompts()
list_available_prompts()  # 列出所有可用 prompts
```

##### 除錯 Prompt 生成
```r
# 查看生成的消息內容
messages <- prepare_gpt_messages(
  var_id = "extract_attributes",
  variables = list(num_attributes = 10),
  prompts_df = prompts_df
)
print(messages)  # 檢查格式是否正確
```

### 最佳實踐

#### 1. Prompt 設計原則
- 明確定義 system 和 user 角色
- 使用描述性的變數名稱
- 保持 prompt 簡潔明確
- 測試變數替換的正確性

#### 2. 提示設計原則
- 簡短清晰的說明文字
- 避免技術術語
- 提供實用的操作指引
- 考慮使用者的知識水平

#### 3. 版本控制
- 定期備份 CSV 檔案
- 記錄修改日誌
- 使用 Git 追蹤變更

### 故障排除

#### 問題：提示未顯示
```r
# 檢查步驟
1. 確認 hint.csv 存在且格式正確
2. 檢查 var_id 是否匹配
3. 確認 enable_hints = TRUE
4. 檢查 bs4Dash 版本相容性
```

#### 問題：Prompt 變數未替換
```r
# 檢查步驟
1. 確認變數名稱拼寫正確
2. 檢查大括號格式 {variable_name}
3. 確認 variables list 包含所需變數
4. 測試 replace_prompt_variables() 函數
```

#### 問題：API 請求失敗
```r
# 檢查步驟
1. 確認 OPENAI_API_KEY 設定正確
2. 檢查消息格式（system/user 結構）
3. 驗證 JSON 回應格式
4. 檢查 API 配額限制
```

---

## 附錄

### A. 檔案清單

#### 新增檔案
- `database/hint.csv` - UI 提示資料
- `database/prompt.csv` - GPT Prompt 資料
- `utils/hint_system.R` - 提示系統功能
- `utils/prompt_manager.R` - Prompt 管理功能
- `test_hint_system.R` - 提示系統測試
- `test_prompt_manager.R` - Prompt 系統測試
- `test_integrated_prompt_system.R` - 整合測試

#### 修改檔案
- `app.R` - 載入新系統
- `modules/module_brandedge_flagship.R` - 使用集中 prompts
- `modules/module_wo_b.R` - 使用集中 prompts

### B. 系統需求

- R 版本：4.0+
- 必要套件：
  - bs4Dash（提示功能）
  - httr2（API 呼叫）
  - jsonlite（JSON 處理）
  - stringr（字串處理）

### C. 效能考量

- CSV 檔案在啟動時載入一次
- Prompt 準備為即時運算
- 建議定期清理未使用的 prompts
- 大量 API 呼叫時考慮批次處理

---

## 結語

本次系統增強大幅提升了 BrandEdge 旗艦版的可維護性與使用者體驗。透過集中管理機制，未來的功能擴展與維護將更加便利。建議定期檢視並優化 prompts 與提示內容，以確保系統始終提供最佳的使用體驗。

---

*文檔版本：1.0*
*最後更新：2025年1月11日*