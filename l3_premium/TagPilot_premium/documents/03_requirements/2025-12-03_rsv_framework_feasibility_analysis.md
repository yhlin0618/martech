# RSV 分析框架可行性評估報告

**分析日期**: 2025-12-03
**專案**: MAMBA (L4 Enterprise)
**舊版參考**: KitchenMAMA Precision Marketing
**分析者**: principle-product-manager

---

## 執行摘要

### 結論：✅ **RSV 框架已完整實作於 MAMBA**

經過深入分析，發現 MAMBA 專案的 `fn_analysis_dna.R` **已經完整實作了 RSV 框架**，只是使用不同的變數名稱。

**關鍵發現**:

| RSV 維度 | MAMBA 變數名稱 | 計算位置 | 狀態 |
|---------|---------------|---------|------|
| **R - Dormancy Risk (靜止戶預測)** | `nrec`, `nrec_prob` | `fn_analysis_dna.R` L837-976 | ✅ 已實作 |
| **S - Transaction Stability (交易穩定度)** | `cri`, `cri_ecdf` | `fn_analysis_dna.R` L775-834 | ✅ 已實作 |
| **V - Customer Lifetime Value (顧客終身價值)** | `clv`, `pcv`, `total_sum` | `fn_analysis_dna.R` L711-751 | ✅ 已實作 |

**不需要新開發**，只需要：
1. 理解現有變數與 RSV 框架的對應關係
2. 在 UI 層級增加 RSV 專用的視覺化呈現（可選）
3. 增加 RSV 術語的中文標籤對照（可選）

---

## 一、MAMBA 現有 RSV 實作分析

### 1.1 核心檔案位置

```
scripts/global_scripts/04_utils/fn_analysis_dna.R
```

這是 MAMBA 的「顧客 DNA 分析」核心函數，包含完整的 RSV 計算邏輯。

### 1.2 RSV 各維度詳細實作

#### **R - Dormancy Risk (靜止戶預測)**: `nrec`

**位置**: `fn_analysis_dna.R` 第 837-976 行

**計算邏輯**:
```r
# 10. Nrec Calculation (Churn prediction)
trace_month <- -3  # 追蹤過去 3 個月

# 判斷客戶是否在過去 3 個月有購買
date_rows[, ncode := (payment_time > add_with_rollback(time_now, months(trace_month)))]

# 訓練邏輯回歸模型預測流失機率
logistic_model_cv <- train(
  nrec ~ f_label + cai,
  data = da_clean,
  method = "glm",
  family = "binomial",
  trControl = cv_control
)

# 輸出：
# - nrec: 預測結果 ("rec" = 會回購, "nrec" = 不會回購)
# - nrec_prob: 流失機率 (0-1)
```

**分層對照**:

| RSV 靜止戶層級 | MAMBA 變數值 | 意涵 |
|--------------|-------------|------|
| 高靜止戶 | `nrec = "nrec"`, `nrec_prob > 0.7` | 即將或已經流失 |
| 中靜止戶 | `nrec_prob` 0.3-0.7 | 互動減少但仍有潛力 |
| 低靜止戶 | `nrec = "rec"`, `nrec_prob < 0.3` | 穩定活躍群 |

---

#### **S - Transaction Stability (交易穩定度)**: `cri`

**位置**: `fn_analysis_dna.R` 第 775-834 行

**計算邏輯**:
```r
# 9. CRI Calculation (Customer Regularity Index)
cri_dt <- ipt_table[ni > 1]  # 只計算購買次數 > 1 的客戶

# 計算全域參數
alpha <- mean(cri_dt$ni, na.rm = TRUE)  # 平均購物次數
n <- nrow(cri_dt)                        # 顧客數量
theta <- sum(cri_dt$ipt_mean_inv, na.rm = TRUE) / (alpha * n)

# 計算 GE (Global Expectation / 全域穩定度)
ge <- 1 / ((alpha - 1) * theta)

# 計算個人穩定度指標
cri_table <- cri_dt[, .(
  ge = ge,                     # 全域穩定度
  ie = ipt_mean,               # 個人平均購物間隔 (Individual Expectation)
  be = (ni / (ni + alpha - 1)) * ipt_mean +
       ((alpha - 1) / (ni + alpha - 1)) * ge,  # 平衡穩定度 (Balanced Expectation)
  cri = abs(ipt_mean - be) / abs(ipt_mean - ge)  # 交易穩定度指數
), by = customer_id]
```

**統計基礎**: 經驗貝氏收縮估計 (Empirical Bayes Shrinkage)
- `BE` = 個人估計與全域估計的加權平均
- 購買次數越多，越信任個人資料
- `CRI` = 衡量個人穩定度偏離平衡估計的程度

**分層對照**:

| RSV 穩定度層級 | MAMBA 變數值 | 意涵 |
|--------------|-------------|------|
| 高穩定顧客 | `cri` 接近 0 | 固定頻率與金額、行為一致 |
| 中穩定顧客 | `cri` 中等 | 有規律但偶爾波動 |
| 低穩定顧客 | `cri` 接近 1 | 購買間隔不固定、交易起伏大 |

---

#### **V - Customer Lifetime Value (顧客終身價值)**: `clv`

**位置**: `fn_analysis_dna.R` 第 711-751 行

**計算邏輯**:
```r
# 7. CLV Calculation
# PIF (Purchase Intention Function) 定義
pif <- function(t) {
  ifelse(t < 5, (4*t^2+20), 120 + 80*(1 - exp(5-t))) / 20
}

# CLV 計算函數
clv_fcn <- function(x) {
  t <- 0:10  # 時間向量從 0 到 10 年
  discount_factors <- (0.9)^t / (1 + delta*4)^t  # 折扣因子
  pif_values <- pif(t)  # 購買意願函數
  sapply(x, function(total_spent) sum(total_spent * pif_values * discount_factors))
}

# 計算每位顧客的 CLV
clv_dt <- dt[, .(total_sum = sum(total_spent, na.rm = TRUE)), by = customer_id]
clv_dt[, clv := clv_fcn(total_sum)]
```

**相關變數**:
- `clv`: 顧客終身價值（預測未來 10 年）
- `pcv`: 過去顧客價值 (Past Customer Value)
- `total_sum`: 歷史消費總額

**分層對照**:

| RSV 價值層級 | 分層方式 | 意涵 |
|------------|---------|------|
| 高價值顧客 | `clv` 前 20% (ntile) | 高消費力、高忠誠度 |
| 中價值顧客 | `clv` 中間 60% | 穩定貢獻、可升級 |
| 低價值顧客 | `clv` 後 20% | 消費低或不穩 |

---

## 二、RSV 變數名稱對照表

### 2.1 完整變數對照

| RSV 框架術語 | MAMBA 變數 | 資料型態 | 說明 |
|-------------|-----------|---------|------|
| **R: Dormancy Risk** | | | |
| 靜止戶預測 | `nrec` | Factor | "rec" (會回購) / "nrec" (不會回購) |
| 流失機率 | `nrec_prob` | Numeric (0-1) | 預測不會回購的機率 |
| **S: Transaction Stability** | | | |
| 交易穩定度 | `cri` | Numeric | Customer Regularity Index |
| 穩定度百分位 | `cri_ecdf` | Numeric (0-1) | CRI 的 ECDF 值 |
| 全域穩定度 | `ge` | Numeric | Global Expectation |
| 個人穩定度 | `ie` | Numeric | Individual Expectation |
| 平衡穩定度 | `be` | Numeric | Balanced Expectation |
| **V: Customer Lifetime Value** | | | |
| 顧客終身價值 | `clv` | Numeric | 預測未來 10 年價值 |
| 過去顧客價值 | `pcv` | Numeric | 歷史消費折現值 |
| 歷史消費總額 | `total_sum` | Numeric | 實際消費總額 |

### 2.2 其他相關 DNA 變數

| 變數名稱 | 說明 | RSV 相關性 |
|---------|------|-----------|
| `ipt_mean` | 平均購買間隔 (Inter-Purchase Time) | S 的基礎計算 |
| `ni` | 購買次數 | R, S, V 的基礎 |
| `m_value` | 平均客單價 (Monetary Value) | V 的基礎 |
| `f_value` | 購買頻率 (Frequency) | R, S 的預測變數 |
| `r_value` | 最近購買天數 (Recency) | R 的基礎 |
| `cai` | 顧客活躍度指數 (Customer Activity Index) | R 的預測變數 |
| `nes_status` | NES 狀態 (N/E0/S1/S2/S3) | R 的分群參考 |

---

## 三、舊版 KitchenMAMA 對照

### 3.1 計算邏輯來源

MAMBA 的 `fn_analysis_dna.R` 源自舊版 KitchenMAMA 的 `DNA_Function_dplyr2.R`:

```
舊版位置:
/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/
l4_enterprise/kitchenMAMA/archive/precision_marketing_KitchenMAMA/
commented_R/RScripts/Functions/DNA_Function_dplyr2.R
```

### 3.2 舊版 vs MAMBA 比較

| 功能 | 舊版 KitchenMAMA | MAMBA | 差異 |
|-----|-----------------|-------|------|
| CRI 計算 | L362-397 | L775-834 | 邏輯相同，增加錯誤處理 |
| Nrec 預測 | L399-569 | L837-976 | 邏輯相同，增加完整性檢查 |
| CLV 計算 | L253-316 | L711-751 | 邏輯相同，變數命名標準化 |
| 輸入資料 | data.table 格式 | 支援多種格式 | MAMBA 更靈活 |
| 錯誤處理 | 基本 | 完整 | MAMBA 更穩健 |

### 3.3 舊版 RFM 原型

另外還有一個獨立的 RFM 分析原型（不是 RSV，但可作為 UI 參考）：

```
/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/
l4_enterprise/kitchenMAMA/archive/precision_marketing_KitchenMAMA/
precision_marketing_app/update_scripts/global_scripts/99_archive/
old_app_version_2025_04_05/rfm_analysis_prototype.R
```

這個檔案包含：
- 完整的 Shiny UI/Server 模組
- 5 種視覺化圖表
- 行銷策略建議框架

---

## 四、使用建議

### 4.1 如何呼叫 RSV 分析

```r
# 載入函數
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")

# 準備資料
df_sales_by_customer <- tbl2(con, "df_sales_by_customer") %>% collect()
df_sales_by_customer_by_date <- tbl2(con, "df_sales_by_customer_by_date") %>% collect()

# 執行 DNA 分析（包含完整 RSV）
result <- analysis_dna(
  df_sales_by_customer = df_sales_by_customer,
  df_sales_by_customer_by_date = df_sales_by_customer_by_date,
  verbose = TRUE
)

# 取得結果
data_by_customer <- result$data_by_customer

# RSV 相關欄位：
# R: nrec, nrec_prob
# S: cri, cri_ecdf, ge, ie, be
# V: clv, pcv, total_sum
```

### 4.2 RSV 分群應用範例

```r
# 建立 RSV 分群
rsv_segments <- data_by_customer %>%
  mutate(
    # R: Dormancy Risk 分群
    r_segment = case_when(
      nrec_prob > 0.7 ~ "高靜止戶",
      nrec_prob > 0.3 ~ "中靜止戶",
      TRUE ~ "低靜止戶"
    ),
    # S: Transaction Stability 分群
    s_segment = case_when(
      cri_ecdf < 0.33 ~ "高穩定顧客",
      cri_ecdf < 0.67 ~ "中穩定顧客",
      TRUE ~ "低穩定顧客"
    ),
    # V: Customer Lifetime Value 分群
    v_segment = case_when(
      clv > quantile(clv, 0.8, na.rm = TRUE) ~ "高價值顧客",
      clv > quantile(clv, 0.2, na.rm = TRUE) ~ "中價值顧客",
      TRUE ~ "低價值顧客"
    )
  )
```

---

## 五、後續優化建議（可選）

### 5.1 UI 層級增強

如果需要專門的 RSV 視覺化介面，可以：

1. 建立 `microRSV` Shiny 模組
2. 新增 RSV 專用的儀表板視圖
3. 整合楊昊紘提供的 TagPilot Predictive Intelligence™ 行銷策略表

### 5.2 術語標準化

建立 RSV 術語對照表，讓使用者更容易理解：

```yaml
# config/rsv_labels.yaml
zh_TW:
  R:
    name: "靜止戶預測"
    description: "預測顧客流失風險"
    levels:
      high: "高靜止戶 - 即將或已經流失"
      medium: "中靜止戶 - 互動減少但仍有潛力"
      low: "低靜止戶 - 穩定活躍群"
  S:
    name: "交易穩定度"
    description: "衡量交易規律性"
    levels:
      high: "高穩定顧客 - 固定頻率與金額"
      medium: "中穩定顧客 - 有規律但偶爾波動"
      low: "低穩定顧客 - 購買間隔不固定"
  V:
    name: "顧客終身價值"
    description: "估算 CLV"
    levels:
      high: "高價值顧客 - 高消費力、高忠誠度"
      medium: "中價值顧客 - 穩定貢獻、可升級"
      low: "低價值顧客 - 消費低或不穩"
```

---

## 六、結論

### ✅ MAMBA 已完整實作 RSV 框架

- **R (Dormancy Risk)** = `nrec` + `nrec_prob` (第 837-976 行)
- **S (Transaction Stability)** = `cri` + `cri_ecdf` (第 775-834 行)
- **V (Customer Lifetime Value)** = `clv` + `pcv` (第 711-751 行)

### 不需要新開發

現有的 `fn_analysis_dna.R` 已經包含所有 RSV 計算邏輯，只需要：
1. 理解變數對應關係（本報告已說明）
2. 在應用層使用這些變數進行分群和策略制定

---

**報告結束**

如有任何問題，請參考：
- `scripts/global_scripts/04_utils/fn_analysis_dna.R` - RSV 計算核心
- `scripts/global_scripts/00_principles/` - MAMBA 原則系統
