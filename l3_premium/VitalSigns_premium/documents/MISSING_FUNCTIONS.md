# VitalSigns 旗艦版 - 尚未實現的計算函數

本文件記錄了 VitalSigns 旗艦版四大板塊中，目前尚未實現或需要額外開發的計算函數。

## 更新說明 (2024-12-26)

基於最新的實作進度，以下是各板塊的實現狀態更新。所有基於 `analysis_dna()` 函數可計算的指標都已實現，剩餘的主要是需要時間序列數據或外部數據源的功能。

### 2025-08-07 更新：global_scripts 函數整合

已檢查 `global_scripts` 中的可用函數：
1. **macroTrend.R** - 提供完整的時間序列趨勢分析功能
2. **query_nes_trend.R** - 處理 NES 狀態的時間序列數據
3. 創建了 **module_time_series_analysis.R** - 統一的時間序列處理模組

## 1. 營收脈能 (Revenue Pulse)

### 已實現
- ✅ 銷售額 (Sales Revenue) - 使用 `total_spent`
- ✅ 人均購買金額 (ARPU) - 使用 `total_spent / customer_count`
- ✅ 新客單價 - 使用 `m_value` 過濾 `nes_status == "N"`
- ✅ 主力客單價 - 使用 `m_value` 過濾 `nes_status == "E0"`
- ✅ 顧客終生價值 (CLV) - 使用 `clv` from `analysis_dna()`
- ✅ 交易穩定度 - 使用 `cri` (Customer Regularity Index)

### 需要實現
- ✅ **收入成長曲線** - 已創建時間序列分析模組
  - 實現方案：創建了 `module_time_series_analysis.R`
  - 功能：提供完整的時間序列聚合和趨勢分析
  - 使用方法：
    ```r
    # 在 app.R 中載入模組
    source("modules/module_time_series_analysis.R")
    
    # 在 server 中初始化
    time_series_results <- timeSeriesAnalysisServer(
      "time_series",
      raw_data = reactive({ upload_result$dna_data })
    )
    
    # 在其他模組中使用
    monthly_data <- time_series_results$monthly_data()
    revenue_trend <- time_series_results$revenue_trend()
    ```
  - 注意：需要從上傳模組傳遞原始數據，不修改現有的 DNA 分析模組

## 2. 客戶增長 (Customer Acquisition & Coverage)

### 已實現
- ✅ 顧客總數 - 簡單計數
- ✅ 累積顧客數 - 簡單計數
- ✅ 顧客新增率 - 使用 `nes_status == "N"` 比例

### 需要實現
- ❌ **顧客變動率 (Net Customer Change Rate)** - 需要時間序列比較
  - 建議函數：`calculate_net_change_rate(current_period, previous_period)`
  - 需要：期間比較邏輯、新增/流失客戶識別
  
- ❌ **獲客漏斗真實數據** - 目前使用簡化版本
  - 建議函數：`build_acquisition_funnel(data, touchpoints)`
  - 需要：多接觸點追蹤、轉化率計算

- ❌ **CAC 回收期計算** - 需要成本數據
  - 建議函數：`calculate_cac_payback(acquisition_cost, customer_value)`
  
- ❌ **市場滲透率 (TAM → SOM)** - 需要市場規模數據
  - 建議函數：`calculate_market_penetration(customer_base, market_size)`

## 3. 客戶留存 (Customer Retention)

### 已實現
- ✅ 顧客留存率 - 使用非沉睡客戶比例
- ✅ 顧客流失率 - 使用 `nes_status == "S3"` 比例
- ✅ 各狀態客戶比率 - 使用 `nes_status` 分組
- ✅ 靜止戶預測 - 使用 `nrec` from `analysis_dna()`
- ✅ RFM 熱力圖 - 已修復資料類型衝突問題（2025-08-07）

### 需要實現
- ❌ **Cohort 分析** - 需要客群追蹤
  - 建議函數：`cohort_retention_analysis(data, cohort_period)`
  - 需要：客群定義、時間序列追蹤、留存率矩陣

- ❌ **生存分析 (Survival Analysis)** - 需要完整的流失模型
  - 建議函數：`customer_survival_curve(data, time_window)`
  - 需要：Kaplan-Meier 估計、風險比率計算

- ❌ **動態流失預測** - 目前只有靜態預測
  - 建議函數：`dynamic_churn_prediction(data, features, model)`
  - 需要：機器學習模型、特徵工程、即時預測

## 4. 活躍轉化 (Engagement Flow)

### 已實現
- ✅ 顧客活躍度 (CAI) - 使用 `cai_value` from `analysis_dna()`
- ✅ 再購率 - 使用 `times >= 2` 比例
- ✅ 購買頻率 - 使用 `f_value`
- ✅ 平均再購時間 - 使用 `ipt_mean`

### 需要實現
- ❌ **真實喚醒率** - 需要歷史追蹤數據
  - 建議函數：`calculate_reactivation_rate(dormant_customers, time_window)`
  - 需要：休眠客戶標記、喚醒活動追蹤、成功率計算

- ❌ **參與度階梯 (Engagement Ladder)** - 需要行為追蹤
  - 建議函數：`build_engagement_ladder(customer_behaviors)`
  - 需要：多維度行為數據、參與度評分、階梯定義

- ❌ **忠誠度循環 (Loyalty Loop)** - 需要完整的客戶旅程
  - 建議函數：`analyze_loyalty_loop(customer_journey)`
  - 需要：接觸點數據、循環識別、強化點分析

- ❌ **最佳訊息頻率** - 需要 A/B 測試數據
  - 建議函數：`optimize_message_frequency(customer_segment, response_data)`
  - 需要：訊息發送記錄、回應率、疲勞度分析

## 共通需求

### 時間序列功能
許多指標需要時間序列分析能力：
- 建議開發：`time_series_aggregator(data, period, metrics)`
- 支援：日/週/月/季/年聚合、移動平均、同比/環比

### 預測模型整合
多個模組需要預測能力：
- 建議開發：`forecast_wrapper(data, method, horizon)`
- 支援：ARIMA、Prophet、機器學習模型

### 基準比較
需要行業基準或歷史基準比較：
- 建議開發：`benchmark_comparison(metrics, benchmark_data)`
- 支援：行業平均、歷史最佳、目標設定

## 實施建議

### 1. 優先順序（更新：2025-08-07）
   - **已完成**：
     - ✅ 時間序列聚合功能（已創建獨立模組）
     - ✅ 營收脈能的收入趨勢圖表
     - ✅ 客戶增長的增長趨勢圖表
     - ✅ RFM 熱力圖錯誤修復
   - **高優先級**：
     - 顧客變動率計算（基礎指標）
     - Cohort 分析（重要的留存分析工具）
   - **中優先級**：
     - 真實喚醒率（需要歷史數據）
     - 活躍度趨勢分析
   - **低優先級**：
     - 市場滲透率（需要外部市場數據）
     - 最佳訊息頻率（需要 A/B 測試基礎設施）

### 2. 資料需求
   - **必要資料**：
     - 完整的交易時間序列（包含日期時間戳）
     - 客戶狀態變化歷史記錄
     - 行銷活動執行記錄
   - **選擇性資料**：
     - 客戶互動記錄（email 開啟、點擊等）
     - 市場規模數據（TAM/SAM/SOM）
     - 成本數據（CAC 計算用）

### 3. 技術實作建議

#### 時間序列處理框架
```r
# 建議的時間序列聚合函數
time_series_aggregator <- function(data, period = "month", metrics = c("revenue", "customers")) {
  library(lubridate)
  library(data.table)
  
  dt <- as.data.table(data)
  dt[, period := floor_date(payment_time, period)]
  
  result <- dt[, .(
    revenue = sum(lineitem_price),
    customers = uniqueN(customer_id),
    transactions = .N
  ), by = period]
  
  return(result)
}
```

#### Cohort 分析實作
```r
# 建議的 Cohort 分析函數
cohort_retention_analysis <- function(data, cohort_period = "month") {
  library(tidyr)
  
  # 計算每個客戶的第一次購買月份（cohort）
  cohorts <- data %>%
    group_by(customer_id) %>%
    summarise(cohort = floor_date(min(payment_time), cohort_period))
  
  # 計算每個 cohort 在後續月份的留存
  # 回傳 cohort 矩陣
}
```

### 4. 資料庫架構建議

為支援未來功能，建議新增以下資料表：

```sql
-- 客戶狀態歷史表
CREATE TABLE customer_status_history (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER,
  status VARCHAR(10),
  status_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 行銷活動記錄表
CREATE TABLE marketing_campaigns (
  id SERIAL PRIMARY KEY,
  campaign_name VARCHAR(255),
  campaign_type VARCHAR(50),
  start_date DATE,
  end_date DATE,
  target_segment VARCHAR(50)
);

-- 客戶互動記錄表
CREATE TABLE customer_interactions (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER,
  interaction_type VARCHAR(50),
  interaction_date TIMESTAMP,
  campaign_id INTEGER REFERENCES marketing_campaigns(id)
);
```

### 5. 模組整合策略

1. **創建獨立的時間序列模組** ✅ 已完成
   - 檔案：`modules/module_time_series_analysis.R`
   - 功能：處理所有時間序列相關計算
   - 提供：日/週/月/季/年聚合、成長率計算、趨勢預測

2. **擴展現有模組**
   - 在每個板塊模組中加入時間序列分析標籤頁
   - 提供期間選擇器（日/週/月/季/年）

3. **建立共用函數庫**
   - 檔案：`utils/time_series_utils.R`
   - 包含所有時間序列處理的通用函數

## 6. 建議的整合方案

### app.R 修改建議
```r
# 在 app.R 的 server 函數中加入
# 載入時間序列分析模組
source("modules/module_time_series_analysis.R")

# 在 server 中初始化時間序列分析
time_series_results <- timeSeriesAnalysisServer(
  "time_series",
  raw_data = reactive({ upload_result$dna_data })
)

# 修改四大板塊的呼叫，傳入時間序列結果
revenue_pulse_result <- revenuePulseModuleServer(
  "revenue_pulse", 
  con = con, 
  user_info = user_info, 
  dna_module_result = dna_mod,
  time_series_data = time_series_results  # 新增參數
)
```

### 可使用的 global_scripts 函數

1. **macroTrend 模組** (`global_scripts/10_rshinyapp_components/macro/macroTrend/`)
   - 提供完整的趨勢分析 UI 和 Server 功能
   - 支援日/週/月粒度切換
   - 包含成長率計算和比較分析
   - 可直接整合到應用中

2. **query_nes_trend 函數** (`global_scripts/06_queries/308g_query_nes_trend.R`)
   - 專門處理 NES 狀態的時間序列
   - 可用於客戶留存模組的 Cohort 分析
   - 提供月度聚合功能

### 未來優化建議

1. **避免重複開發**：直接使用 `macroTrend` 模組而非重新實現
2. **資料流優化**：修改上傳模組，保留原始交易數據供時間序列分析使用
3. **統一接口**：建立標準的時間序列數據接口，讓所有模組都能使用

---

*更新日期：2025-08-07*  
*此文件將隨功能開發持續更新*