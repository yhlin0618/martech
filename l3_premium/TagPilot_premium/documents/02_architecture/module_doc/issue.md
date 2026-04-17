# TagPilot Premium 變數定義與問題記錄

## 文件資訊

- **建立日期**: 2025-11-26
- **用途**: 記錄開發過程中發現的變數定義問題和修正說明

---

## 問題 1：中位購買週期計算錯誤

### 問題描述

在 `module_customer_value_analysis.R` 的「中位購買週期」指標計算中，原始邏輯使用錯誤的公式。

### 錯誤代碼 (Lines 468-496)

```r
# ❌ 錯誤的計算方式
f_values <- values$processed_data$tag_010_rfm_f  # F = ni = 購買次數（次）
purchase_cycles <- 1 / f_values                   # 1 / 次數 = ？？？
median_cycle <- median(purchase_cycles)
```

### 問題分析

1. **單位不對**：`F value = ni` 是購買「次數」（沒有時間單位）
2. **`1 / 次數`** 沒有意義！應該是「時間 / 次數」才對

### 正確的做法

DNA 分析已經產生了 **`ipt`**（Inter-Purchase Time）變數，應該直接使用：

- `ipt_mean`：平均購買間隔（由 `analysis_dna()` 產生）
- `ipt`：首購到最後購買的總天數（由 `analyze_customer_dynamics_new()` 產生）

### 修正代碼

```r
# ✅ 正確：優先使用 DNA 提供的 ipt_mean
if ("ipt_mean" %in% names(processed_data)) {
  ipt_values <- processed_data$ipt_mean
} else if ("ipt" %in% names(processed_data)) {
  # 從 ipt 和 ni 計算：平均購買間隔 = ipt / (ni - 1)
  ipt_values <- processed_data %>%
    filter(ni >= 2, !is.na(ipt), ipt > 0) %>%
    mutate(avg_ipt = ipt / (ni - 1)) %>%
    pull(avg_ipt)
}
median_cycle <- median(ipt_values)
```

### 修正位置

- **檔案**: `modules/module_customer_value_analysis.R`
- **Lines**: 468-510

### 修正日期

2025-11-26

---

## 問題 2：DNA 分析中 ipt 與 ipt_mean 的差異

### 問題描述

兩個 DNA 分析函數產生不同的購買間隔欄位：

| 函數 | 產生欄位 | 計算方式 |
|------|----------|----------|
| `analysis_dna()` | `ipt_mean` | 平均購買間隔（天） |
| `analyze_customer_dynamics_new()` | `ipt` | 首購到最後購買的總天數 |

### 關鍵差異

```r
# analysis_dna.R (Line 463)
ipt_mean = ipt  # 直接使用，已是平均間隔

# analyze_customer_dynamics_new.R (Line 254)
ipt = difftime(time_last, time_first, units = "days")  # 總時間跨度，不是平均！
```

### 正確的平均購買間隔計算

如果只有 `ipt`（總時間跨度），需要自行計算平均：

```r
# 平均購買間隔 = 總時間跨度 / (購買次數 - 1)
avg_ipt = ipt / (ni - 1)  # 只對 ni >= 2 有意義
```

### 影響範圍

所有使用 `ipt` 或 `ipt_mean` 的模組都需要確認使用正確的欄位。

---

## 問題 3：m_value 的重新定義

### 問題描述

在 `analyze_customer_dynamics_new.R` 中，`m_value` 被**重新定義**為 AOV：

```r
# Line 257
m_value = m_value / ni  # Convert total to AOV
```

### 影響

| 輸入時 | 輸出後 |
|--------|--------|
| m_value = 總消費金額 | m_value = 平均訂單金額 (AOV) |
| - | total_spent = 總消費金額 |

### 後續模組注意事項

- 如果需要**總消費金額**，使用 `total_spent`
- 如果需要**平均訂單金額**，使用 `m_value`

### 受影響模組

- `module_rsv_matrix.R`：CLV 計算
- `module_customer_base_value.R`：AOV 比較
- `calculate_customer_tags.R`：tag_003, tag_004 計算

---

## 問題 4：customer_dynamics 語言不一致

### 問題描述

DNA 分析返回的 `customer_dynamics` 是**英文**，但某些模組期望**中文**值。

### DNA 輸出（英文）

```r
customer_dynamics = c("newbie", "active", "sleepy", "half_sleepy", "dormant")
```

### UI 顯示需求（中文）

```r
顧客動態 = c("新客", "主力客", "睡眠客", "半睡客", "沉睡客")
```

### 解決方案

在 `calculate_customer_tags.R` 中進行轉換：

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

### 已修正位置

- `modules/module_dna_multi_premium_v2.R` (Lines 584-590)：grid_position 的 lifecycle_suffix 計算
- `utils/calculate_customer_tags.R`：tag_017 轉換

---

## 問題 5：RSV 下載欄位不存在

### 問題描述

`module_rsv_matrix.R` 的下載功能嘗試選擇不存在的欄位：

```r
# ❌ 錯誤：ipt_mean 和 ipt_sd 可能不存在
select(
  ...,
  "平均購買間隔" = "ipt_mean",
  "購買間隔標準差" = "ipt_sd"
)
```

### 錯誤訊息

```
Warning: Error in select: Can't select columns that don't exist.
✖ Column 'ipt_sd' doesn't exist.
```

### 修正代碼

使用 `any_of()` 處理可能不存在的欄位：

```r
# ✅ 正確：使用 any_of 處理可選欄位
select(
  ...,
  any_of(c(
    "平均購買間隔" = "ipt",      # DNA 提供的是 ipt，不是 ipt_mean
    "購買間隔標準差" = "ipt_sd"  # 可能不存在
  ))
)
```

### 修正位置

- **檔案**: `modules/module_rsv_matrix.R`
- **Lines**: 763-766

---

## 問題 6：tag_019_days_to_churn 使用不存在的 ipt_mean

### 問題描述

`calculate_customer_tags.R` 中的流失天數計算使用 `ipt_mean`，但該欄位可能不存在。

### 修正

改為使用 `ipt`：

```r
# ❌ 錯誤
is.na(ipt_mean) | ipt_mean <= 0 ~ NA_real_,

# ✅ 正確
is.na(ipt) | ipt <= 0 ~ NA_real_,
```

### 修正位置

- **檔案**: `utils/calculate_customer_tags.R`
- **Line**: 174

---

## 問題總結

| 問題 | 根本原因 | 修正狀態 |
|------|----------|----------|
| 中位購買週期錯誤 | 使用 1/F 而非 ipt | ✅ 已修正 |
| ipt vs ipt_mean | 兩個 DNA 函數輸出不同 | ⚠️ 需注意 |
| m_value 重定義 | 被轉換為 AOV | ⚠️ 需注意 |
| customer_dynamics 語言 | DNA 輸出英文 | ✅ 已修正 |
| RSV 下載欄位 | 欄位不存在 | ✅ 已修正 |
| tag_019 使用 ipt_mean | 欄位不存在 | ✅ 已修正 |

---

## 建議的程式碼規範

### 1. 欄位使用前先檢查

```r
if ("欄位名" %in% names(data)) {
  # 使用欄位
} else {
  # 替代方案或錯誤處理
}
```

### 2. 使用 any_of() 處理可選欄位

```r
select(
  必要欄位,
  any_of(c("可選欄位1", "可選欄位2"))
)
```

### 3. 明確的變數命名

| 變數 | 命名建議 |
|------|----------|
| 總消費金額 | `total_spent` |
| 平均訂單金額 | `aov` 或 `avg_order_value` |
| 平均購買間隔 | `avg_ipt` 或 `ipt_mean` |
| 購買間隔總天數 | `ipt_total` 或 `time_span` |

---

## 更新記錄

| 日期 | 更新內容 |
|------|----------|
| 2025-11-26 | 建立文件，記錄 6 個已發現問題 |
