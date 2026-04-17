# module_dna_multi_premium_v2.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_dna_multi_premium_v2.R`
- **檔案大小**: 約 1,491 行
- **版本**: 2.0 (使用 Z-Score 方法計算客戶動態)
- **最後更新**: 2025-11

---

## 模組概述

這是整個 TagPilot Premium 系統的**核心分析模組**，負責：
1. 執行 DNA 客戶分析
2. 計算九宮格分類 (價值 × 活躍度)
3. 為每位客戶分配策略標籤
4. 輸出完整的客戶標籤資料

---

## 檔案結構

### 第一部分：設定與載入 (Lines 1-56)

#### Lines 1-11: 檔案說明和版本資訊
- 版本 2.0 使用 Z-Score 方法計算客戶動態
- 列出與 V1 的主要差異

#### Lines 12-56: 載入必要套件和函數
- Shiny 相關套件（shiny, bs4Dash, DT, plotly）
- DNA 分析函數、客戶標籤計算函數

```r
# 主要依賴
library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)

# 核心分析函數
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
source("utils/analyze_customer_dynamics_new.R")
source("utils/calculate_customer_tags.R")
```

---

### 第二部分：UI 函數 (Lines 61-118)

定義使用者看到的介面元素：

| 區塊 | 說明 |
|------|------|
| 狀態顯示區 | 顯示分析進度 |
| 分析方法資訊區 | 顯示 Z-score 參數 (μ_ind, W, λ_w, σ_w) |
| 客戶動態選擇器 | 選擇新客/主力客/瞌睡客等 |
| 九宮格矩陣 | 價值 × 活躍度視覺化 |
| 客戶列表表格 | 顯示客戶明細 |
| 下載按鈕 | 輸出 CSV |

---

### 第三部分：Server 函數 - 核心分析邏輯 (Lines 124-640)

這是整個模組的**大腦**，分成多個步驟：

#### 📊 資料驗證 (Lines 145-258)

檢查資料是否符合 Z-Score 方法要求：

| 條件 | 最低要求 |
|------|----------|
| 觀察期 | ≥ 365 天 |
| 總客戶數 | ≥ 100 |
| 回購客戶 | ≥ 30 |
| 總交易數 | ≥ 500 |

#### 🔬 主要分析流程 (Lines 270-640)

**Step 1-3 (Lines 289-334): 準備交易資料**

轉換成兩種格式：
- `sales_by_customer_by_date`：每客戶每日銷售
- `sales_by_customer`：每客戶總銷售

**Step 4 (Lines 337-349): DNA 基礎分析**

```r
# 呼叫 analysis_dna() 計算 RFM 指標
dna_result <- analysis_dna(
  sales_by_customer_by_date,
  sales_by_customer
)
# 產生：r_value, f_value, m_value, ni, cai, cai_ecdf
```

**Step 5 (Lines 351-360): 轉換結果為 tibble**

**Step 6-7 (Lines 363-391): 客戶動態分析**

```r
# 呼叫 analyze_customer_dynamics_new()
dynamics_result <- analyze_customer_dynamics_new(
  customer_summary,
  transaction_data
)
# 產生：customer_dynamics (newbie/active/sleepy/half_sleepy/dormant)
# 產生：value_level (高/中/低)
```

**Step 8-12 (Lines 396-496): 處理價值等級**

使用 analyze_customer_dynamics_new 的 value_level（P20/P80 分位數）

**Step 13-16 (Lines 500-561): 計算活躍度等級**

```r
# 重要限制：只計算 ni ≥ 4 的客戶
# ni < 4 的客戶 activity_level = NA
# 使用 cai_ecdf (P20/P80) 分類為 高/中/低
activity_level = case_when(
  ni < 4 ~ NA_character_,
  cai_ecdf >= 0.8 ~ "高",
  cai_ecdf >= 0.2 ~ "中",
  TRUE ~ "低"
)
```

**Step 17 (Lines 564-604): 計算九宮格位置 (grid_position)**

```r
# 計算公式
grid_base (A1-C3) + lifecycle_suffix (N/C/S/H/D) = grid_position

# 例如：A1C = 高價值 + 高活躍度 + 主力客
```

| 代碼 | 價值等級 | 活躍度等級 |
|------|----------|------------|
| A | 高 | 1 = 高 |
| B | 中 | 2 = 中 |
| C | 低 | 3 = 低 |

| 後綴 | 生命週期 |
|------|----------|
| N | newbie (新客) |
| C | active (主力客) |
| S | sleepy (瞌睡客) |
| H | half_sleepy (半睡客) |
| D | dormant (沉睡客) |

**Step 18 (Lines 608-615): 計算所有客戶標籤**

```r
# 呼叫 calculate_all_customer_tags()
# 產生 34 個標準化標籤（tag_001 ~ tag_034）
processed_data <- calculate_all_customer_tags(customer_data)
```

---

### 第四部分：UI 輸出邏輯 (Lines 642-1093)

#### 動態選擇器 (Lines 653-688)
- 根據資料動態生成客戶動態階段選項
- 顯示每個階段的客戶數量

#### Z-Score 資訊顯示 (Lines 691-711)
- 顯示 μ_ind（中位購買間隔）
- 顯示 W（活躍觀察窗）、λ_w、σ_w

#### 九宮格矩陣視覺化 (Lines 748-1093)

**generate_grid_content() (Lines 763-875)**

為每個格子生成內容：
- 客戶數量和占比
- 平均金額和購買頻率
- 客戶類型標籤（呼叫 get_strategy）
- 建議策略和 KPI

**新客特殊處理 (Lines 916-1048)**
- 新客（ni=1）無活躍度資料
- 顯示 A3N/B3N/C3N 三種策略卡片
- 不顯示九宮格

**非新客九宮格 (Lines 1051-1092)**
- 顯示 3×3 矩陣（高/中/低價值 × 高/中/低活躍度）
- 只顯示 ni ≥ 4 或新客

---

### 第五部分：客戶資料表格 (Lines 1096-1148)

```r
# renderDT() 顯示內容：
display_data <- processed_data %>%
  mutate(
    客戶類型標籤 = get_strategy(grid_position)$title,
    建議策略 = get_strategy(grid_position)$action
  ) %>%
  select(
    客戶ID,
    客戶類型標籤,    # 如「王者引擎-C」
    建議策略,        # 具體行動方案
    生命週期階段,
    價值等級,
    活躍度等級,
    九宮格位置,
    交易次數,
    最近購買天數
  )
```

---

### 第六部分：CSV 下載功能 (Lines 1154-1207)

```r
output$download_customer_data <- downloadHandler(
  filename = function() {
    paste0("customer_data_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
  },
  content = function(file) {
    # UTF-8 BOM 編碼：確保 Excel 正確顯示中文
    con <- file(file, open = "wb", encoding = "UTF-8")
    writeBin(charToRaw('\ufeff'), con)  # BOM
    write.csv(export_df, con, row.names = FALSE, fileEncoding = "UTF-8")
    close(con)
  }
)
```

---

### 第七部分：策略定義函數 (Lines 1225-1490)

**get_strategy(grid_position) 函數**

| 輸入 | 輸出 |
|------|------|
| grid_position（如 "A1C"）| title：客戶類型標籤（如「王者引擎-C」）|
| | action：建議策略（如「VIP 社群 + 新品搶先權」）|
| | icon：圖示 |
| | kpi：KPI 指標 |

**定義 45 種策略組合**：

| 類別 | 數量 | 範例 |
|------|------|------|
| 新客策略 | 3 | A3N, B3N, C3N |
| 主力客策略 | 9 | A1C ~ C3C |
| 瞌睡客策略 | 9 | A1D ~ C3D |
| 半睡客策略 | 9 | A1H ~ C3H |
| 沉睡客策略 | 9 | A1S ~ C3S |
| 隱藏組合 | 6 | 新客高/中活躍度（返回 NULL）|

---

## 關鍵邏輯總結

### 1. 資料流

```
原始交易 → DNA分析(RFM) → 客戶動態(英文) → 價值/活躍度等級 → grid_position → 策略標籤
```

### 2. 活躍度限制

- **ni ≥ 4**：可計算活躍度（使用 cai_ecdf）
- **ni < 4**：活躍度 = NA，grid_position = "無"

### 3. 語言對應

| DNA 返回 | 顯示標籤 |
|----------|----------|
| newbie | 新客 / N |
| active | 主力客 / C |
| sleepy | 瞌睡客 / S |
| half_sleepy | 半睡客 / H |
| dormant | 沉睡客 / D |

### 4. grid_position 組成

```
基礎位置 (A1-C3) + 生命週期後綴 (N/C/S/H/D) = 完整位置 (A1C)
```

---

## 與其他模組的關係

### 依賴模組

- `scripts/global_scripts/04_utils/fn_analysis_dna.R`：DNA 分析
- `utils/analyze_customer_dynamics_new.R`：客戶動態分析
- `utils/calculate_customer_tags.R`：標籤計算

### 輸出給下游模組

- `processed_data`：完整客戶資料（含所有標籤）
- 供後續模組（RFM、RSV、預測等）使用

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 2.0 | 2025-11 | 使用 Z-Score 方法；修正 lifecycle_suffix 使用英文值 |
| 1.0 | 2025-10 | 初始版本，使用固定閾值方法 |
