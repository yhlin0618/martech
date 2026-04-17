# calculate_customer_tags.R 函數說明文件

## 檔案資訊

- **檔案路徑**: `utils/calculate_customer_tags.R`
- **功能**: 模組化的標籤計算邏輯
- **最後更新**: 2025-11

---

## 檔案概述

這個檔案包含將 DNA 分析結果轉換為 **34 個標準化標籤** 的函數集合。

遵循 **MP016 Modularity 原則**：將標籤計算邏輯模組化，便於維護和測試。

---

## 函數列表

| 函數名稱 | 功能 |
|----------|------|
| `calculate_base_value_tags()` | 計算基數價值標籤 |
| `calculate_rfm_scores()` | 計算 RFM 分數 |
| `calculate_rfm_tags()` | 計算 RFM 分析標籤 |
| `calculate_status_tags()` | 計算客戶狀態標籤 |
| `calculate_prediction_tags()` | 計算生命週期預測標籤 |
| `calculate_all_customer_tags()` | 一次計算所有標籤（主函數）|
| `get_tags_summary()` | 獲取標籤摘要資訊 |

---

## 函數詳細說明

### 1. calculate_base_value_tags() (Lines 20-35)

#### 功能

計算客戶基數價值標籤（第二列）

#### 產生標籤

| 標籤 | 說明 | 計算公式 |
|------|------|----------|
| `tag_001_avg_purchase_cycle` | 平均購買週期 | = ipt |
| `tag_003_historical_total_value` | 歷史總價值 | = m_value |
| `tag_004_avg_order_value` | 平均客單價 (AOV) | = m_value / ni |

#### 程式碼

```r
calculate_base_value_tags <- function(customer_data) {
  customer_data %>%
    mutate(
      tag_001_avg_purchase_cycle = ipt,
      tag_003_historical_total_value = m_value,
      tag_004_avg_order_value = m_value / ni
    )
}
```

#### ⚠️ 重要說明

- `m_value` 在 DNA 分析中已經是總消費金額（total_spent）
- **不需要**再乘以 ni

---

### 2. calculate_rfm_scores() (Lines 48-96)

#### 功能

計算 RFM 分數（輔助函數）

#### 分數規則

| 維度 | 邏輯 | 5 分 | 1 分 |
|------|------|------|------|
| R分數 | 越小越好 | 最近購買 | 最久沒買 |
| F分數 | 越大越好 | 高頻率 | 低頻率 |
| M分數 | 越大越好 | 高價值 | 低價值 |

#### 計算方法

```r
# 使用 P20/P40/P60/P80 分位數將客戶分成 5 組
r_quantiles <- quantile(r_value, probs = c(0.2, 0.4, 0.6, 0.8))

r_score = case_when(
  r_value <= r_quantiles[1] ~ 5,  # 最近購買（最好）
  r_value <= r_quantiles[2] ~ 4,
  r_value <= r_quantiles[3] ~ 3,
  r_value <= r_quantiles[4] ~ 2,
  TRUE ~ 1  # 最久沒買（最差）
)

# 產生
tag_012_rfm_score = r_score + f_score + m_score  # 範圍 3-15
```

#### ✅ 更新說明

- 現在為**所有客戶**計算 RFM 分數
- 移除 ni >= 4 的限制

---

### 3. calculate_rfm_tags() (Lines 109-130)

#### 功能

計算 RFM 分析標籤（第三列）

#### 產生標籤

| 標籤 | 說明 | 來源 |
|------|------|------|
| `tag_009_rfm_r` | R值（最近購買天數）| = r_value |
| `tag_010_rfm_f` | F值（購買頻率）| = f_value = ni |
| `tag_011_rfm_m` | M值（貨幣價值）| = m_value |
| `tag_012_rfm_score` | RFM總分（3-15分）| = r_score + f_score + m_score |
| `tag_013_value_segment` | 價值分群（高/中/低）| = value_level |

#### 程式碼

```r
calculate_rfm_tags <- function(customer_data) {
  customer_data <- customer_data %>%
    mutate(
      tag_009_rfm_r = r_value,
      tag_010_rfm_f = f_value,
      tag_011_rfm_m = m_value,
      tag_013_value_segment = value_level
    )

  # 計算 RFM 分數
  customer_data <- calculate_rfm_scores(customer_data)

  return(customer_data)
}
```

---

### 4. calculate_status_tags() (Lines 141-179)

#### 功能

計算客戶狀態標籤（第四列）

#### 產生標籤

| 標籤 | 說明 |
|------|------|
| `tag_017_customer_dynamics` | 客戶動態（中文）|
| `tag_018_churn_risk` | 流失風險（高/中/低風險）|
| `tag_019_days_to_churn` | 距離流失天數 |

#### 客戶動態轉換（英文 → 中文）

```r
tag_017_customer_dynamics = case_when(
  customer_dynamics == "newbie" ~ "新客",
  customer_dynamics == "active" ~ "主力客",
  customer_dynamics == "sleepy" ~ "睡眠客",
  customer_dynamics == "half_sleepy" ~ "半睡客",
  customer_dynamics == "dormant" ~ "沉睡客",
  TRUE ~ customer_dynamics
)
```

#### 流失風險計算

```r
tag_018_churn_risk = case_when(
  # 新客：特殊處理
  ni == 1 ~ "新客（無法評估）",
  # 交易次數不足（2-3次）
  ni < 4 ~ if_else(r_value > 30, "中風險", "低風險"),
  # 一般客戶：基於 R值 與 平均購買週期的比較
  r_value > ipt * 2 ~ "高風險",    # 超過2倍購買週期
  r_value > ipt * 1.5 ~ "中風險",  # 超過1.5倍購買週期
  TRUE ~ "低風險"
)
```

#### 預估流失天數計算

```r
tag_019_days_to_churn = case_when(
  ni == 1 ~ NA_real_,  # 新客無法預測
  ni < 2 ~ NA_real_,   # 需至少2次購買
  is.na(ipt) | ipt <= 0 ~ NA_real_,  # ipt 無效
  # 一般客戶：2倍平均購買間隔 - 當前R值
  TRUE ~ pmax(0, round(ipt * 2 - r_value, 0))
)
```

---

### 5. calculate_prediction_tags() (Lines 197-246)

#### 功能

計算生命週期預測標籤（第六列）

#### 產生標籤

| 標籤 | 說明 |
|------|------|
| `tag_030_next_purchase_amount` | 下次購買預測金額 |
| `tag_031_next_purchase_date` | 下次購買預測日期 |
| `tag_031_prediction_method` | 預測方法說明 |

#### 預測金額

```r
# 使用平均訂單金額作為預測
tag_030_next_purchase_amount = case_when(
  ni == 0 ~ NA_real_,
  is.na(m_value) ~ NA_real_,
  TRUE ~ m_value / ni  # 平均訂單金額
)
```

#### 預測日期（剩餘時間演算法）

```r
# Step 1: 預期購買週期
expected_cycle = ipt

# Step 2: 已過時間
time_elapsed = r_value

# Step 3: 剩餘時間
remaining_time = pmax(0, expected_cycle - time_elapsed)

# Step 4: 預測日期
tag_031_next_purchase_date = case_when(
  remaining_time > 0 ~ today + remaining_time,  # 週期內
  TRUE ~ today + expected_cycle                  # 已逾期
)
```

---

### 6. calculate_all_customer_tags() (Lines 255-261)

#### 功能

一次計算所有標籤（主函數）

#### 呼叫順序

```r
calculate_all_customer_tags <- function(customer_data) {
  customer_data %>%
    calculate_base_value_tags() %>%      # 第二列：基數價值
    calculate_rfm_tags() %>%             # 第三列：RFM 分析
    calculate_status_tags() %>%          # 第四列：客戶狀態
    calculate_prediction_tags()          # 第六列：生命週期預測
}
```

#### 使用方式

```r
# 在 module_dna_multi_premium.R 中使用:
source("utils/calculate_customer_tags.R")

customer_data <- calculate_all_customer_tags(customer_data)
```

---

### 7. get_tags_summary() (Lines 272-305)

#### 功能

獲取標籤摘要資訊

#### 返回內容

```r
list(
  total_tags = 標籤總數,
  tag_groups = 各分類的標籤列表,
  group_counts = 各組可用標籤數,
  tag_names = 所有標籤名稱
)
```

#### 標籤分組

| 分類 | 標籤 |
|------|------|
| 客戶基數價值 | tag_001, tag_003, tag_004 |
| RFM 分析 | tag_009 ~ tag_013 |
| 客戶狀態 | tag_017 ~ tag_019 |
| 生命週期預測 | tag_030, tag_031 |

---

## 標籤完整列表

### 第二列：客戶基數價值

| 標籤編號 | 名稱 | 說明 |
|----------|------|------|
| tag_001 | avg_purchase_cycle | 平均購買週期 |
| tag_003 | historical_total_value | 歷史總價值 |
| tag_004 | avg_order_value | 平均客單價 |

### 第三列：RFM 分析

| 標籤編號 | 名稱 | 說明 |
|----------|------|------|
| tag_009 | rfm_r | R 值（最近購買天數）|
| tag_010 | rfm_f | F 值（購買頻率）|
| tag_011 | rfm_m | M 值（貨幣價值）|
| tag_012 | rfm_score | RFM 總分 |
| tag_013 | value_segment | 價值分群 |

### 第四列：客戶狀態

| 標籤編號 | 名稱 | 說明 |
|----------|------|------|
| tag_017 | customer_dynamics | 客戶動態（中文）|
| tag_018 | churn_risk | 流失風險 |
| tag_019 | days_to_churn | 預估流失天數 |

### 第六列：生命週期預測

| 標籤編號 | 名稱 | 說明 |
|----------|------|------|
| tag_030 | next_purchase_amount | 下次購買預測金額 |
| tag_031 | next_purchase_date | 下次購買預測日期 |

---

## 關鍵設計特點

### 1. 模組化設計

- 每個功能獨立成函數
- 便於單獨測試和除錯
- 可以分步驟呼叫

### 2. 依賴關係處理

```
基數價值 → RFM 分析 → 客戶狀態 → 生命週期預測
```

`calculate_all_customer_tags()` 確保正確的呼叫順序

### 3. 穩健的錯誤處理

- 處理 NA 值
- 處理除以零
- 處理無效的 ipt 值

---

## 與其他模組的關係

### 被呼叫位置

- `modules/module_dna_multi_premium_v2.R` (Step 18)
- `modules/module_lifecycle_prediction.R`

### 依賴欄位

| 欄位 | 來源 |
|------|------|
| r_value, f_value, m_value | DNA 分析 |
| ni | DNA 分析 |
| ipt | DNA 分析 |
| customer_dynamics | analyze_customer_dynamics_new |
| value_level | analyze_customer_dynamics_new |

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.1 | 2025-11 | 修正 tag_019 使用 ipt 而非 ipt_mean |
| 1.0 | 2025-10 | 初始版本 |
