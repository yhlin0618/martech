# module_lifecycle_prediction.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_lifecycle_prediction.R`
- **檔案大小**: 約 629 行
- **功能**: 生命週期預測模組
- **最後更新**: 2025-11

---

## 模組概述

這是**生命週期預測模組**，主要做：
1. 下次購買金額預測
2. 下次購買日期預測
3. 預測信心度評估

---

## 核心預測邏輯

### 預測金額

```r
# 預測下次購買金額 = 歷史平均訂單金額
tag_030_next_purchase_amount = m_value / ni
```

### 預測日期（剩餘時間演算法）

```r
# 1. 計算預期購買週期 = ipt（平均購買間隔）
expected_cycle = ipt

# 2. 計算已過時間 = r_value（距上次購買天數）
time_elapsed = r_value

# 3. 計算剩餘時間
remaining_time = expected_cycle - time_elapsed

# 4. 預測下次購買日期
if (remaining_time > 0):
    # 週期內：今天 + 剩餘時間
    next_date = today + remaining_time
else:
    # 已逾期：今天 + 完整週期
    next_date = today + expected_cycle
```

### 預測信心度

| 購買次數 (ni) | 信心度 |
|---------------|--------|
| ≥ 4 | 高（綠色）|
| 2-3 | 中（黃色）|
| 1 | 低（紅色）|

---

## 檔案結構

### 第一部分：UI 介面 (Lines 25-185)

| 區塊 | Lines | 說明 |
|------|-------|------|
| 狀態顯示 | 32-35 | 分析進度 |
| 預測關鍵指標 | 41-80 | 平均預測金額、高信心度客戶數 |
| 預測分布圖表 | 82-101 | 金額分布、日期分布 |
| 預測時間軸 | 103-115 | 未來 90 天預測 |
| 預測 vs 歷史散點圖 | 117-161 | 含詳細說明 footer |
| 詳細資料表 | 163-182 | 客戶列表 + 下載 |

---

### 第二部分：Server 邏輯 (Lines 192-616)

---

## 📊 區塊 1：資料處理 (Lines 202-228)

### 計算預測標籤 (Lines 209-212)

```r
# 使用 utils 中的函數計算預測標籤
processed <- customer_data() %>%
  calculate_prediction_tags()

# 產生：
# - tag_030_next_purchase_amount：預測購買金額
# - tag_031_next_purchase_date：預測購買日期
```

---

## 📈 區塊 2：關鍵指標 (Lines 241-267)

### 平均預測購買金額 (Lines 245-249)

```r
avg_val <- mean(tag_030_next_purchase_amount, na.rm = TRUE)
```

### 高信心度預測客戶 (Lines 263-267)

```r
# 購買次數 ≥ 4 的客戶數
count <- sum(ni >= 4)
```

---

## 📊 區塊 3：預測金額分布圖 (Lines 269-287)

```r
plot_ly(
  x = tag_030_next_purchase_amount,
  type = "histogram",
  nbinsx = 30
)
```

---

## 📊 區塊 4：預測日期分布圖 (Lines 289-315)

```r
# 計算距今天數
days_until <- difftime(tag_031_next_purchase_date, today, units = "days")

plot_ly(
  x = days_until,
  type = "histogram",
  nbinsx = 30
)
```

---

## 📈 區塊 5：預測時間軸（未來 90 天）(Lines 317-361)

```r
# 篩選未來 90 天內的預測
timeline_data <- processed_data %>%
  filter(
    tag_031_next_purchase_date >= today,
    tag_031_next_purchase_date <= today + 90
  ) %>%
  count(tag_031_next_purchase_date)

# 輸出折線圖
plot_ly(
  x = ~tag_031_next_purchase_date,
  y = ~n,
  type = "scatter",
  mode = "lines+markers"
)
```

---

## 🔥 區塊 6：預測 vs 歷史散點圖 (Lines 363-524) ⭐

這是核心視覺化！

### 資料準備 (Lines 370-406)

```r
# ✅ 修正：顯示所有有預測金額的客戶
scatter_data <- processed_data %>%
  filter(
    !is.na(tag_030_next_purchase_amount),
    !is.na(tag_011_rfm_m),
    tag_030_next_purchase_amount > 0,
    tag_011_rfm_m > 0
  )
```

### 信心度分類 (Lines 422-430)

```r
confidence = case_when(
  ni >= 4 ~ "高（≥4次）",   # 綠色
  ni >= 2 ~ "中（2-3次）",  # 黃色
  TRUE ~ "低（1次）"        # 紅色
)
```

### 分層採樣策略 (Lines 432-461)

```r
if (original_count > 2000) {
  # 優先保留所有重複購買客戶（ni≥2）
  high_value <- scatter_data %>% filter(ni >= 2)

  # 如果高價值客戶超過 1000，採樣到 1000
  if (nrow(high_value) > 1000) {
    high_value <- high_value %>% sample_n(1000)
  }

  # 從 ni=1 客戶中採樣補足到 2000
  remaining_slots <- 2000 - nrow(high_value)
  low_value <- scatter_data %>%
    filter(ni == 1) %>%
    sample_n(min(nrow(.), remaining_slots))

  scatter_data <- bind_rows(high_value, low_value)
}
```

### 散點圖輸出 (Lines 479-523)

```r
plot_ly() %>%
  # 散點圖
  add_trace(
    x = ~tag_011_rfm_m,              # X軸：歷史平均金額
    y = ~tag_030_next_purchase_amount,  # Y軸：預測金額
    size = ~ni,                       # 氣泡大小：購買次數
    color = ~confidence,              # 顏色：信心度
    colors = c(
      "高（≥4次）" = "#28a745",
      "中（2-3次）" = "#ffc107",
      "低（1次）" = "#dc3545"
    )
  ) %>%
  # 參考線 y=x
  add_trace(
    x = c(0, max_value),
    y = c(0, max_value),
    mode = "lines",
    line = list(color = "gray", dash = "dash"),
    name = "參考線 (y=x)"
  )
```

### 圖表解讀

| 位置 | 意義 |
|------|------|
| 對角線上方 | 預測金額 > 歷史金額（客單價可能提升）|
| 對角線下方 | 預測金額 < 歷史金額（客單價可能下降）|
| 對角線附近 | 預測金額 ≈ 歷史金額（穩定）|

---

## 📋 區塊 7：資料表 (Lines 526-585)

### 表格內容 (Lines 537-555)

```r
display_data <- processed_data %>%
  mutate(
    days_until = difftime(tag_031_next_purchase_date, today, units = "days"),
    confidence = case_when(
      ni >= 4 ~ "高",
      ni >= 2 ~ "中",
      TRUE ~ "低"
    )
  ) %>%
  select(
    customer_id,
    購買次數 = ni,
    預測金額 = tag_030_next_purchase_amount,
    預測日期 = tag_031_next_purchase_date,
    距今天數 = days_until,
    預測信心度 = confidence
  ) %>%
  arrange(距今天數) %>%
  head(100)
```

---

## 📥 區塊 8：CSV 下載 (Lines 587-608)

```r
export_data <- processed_data %>%
  select(
    customer_id,
    ni,
    tag_030_next_purchase_amount,
    tag_031_next_purchase_date
  )

# 檔名：customer_lifecycle_prediction_2025-11-24.csv
write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8")
```

---

## 關鍵設計特點

### 1. 剩餘時間演算法

```
週期內客戶：今天 + 剩餘時間
逾期客戶：今天 + 完整週期

例如：
- 客戶A：平均週期 30 天，距上次購買 10 天
  → 剩餘 20 天 → 預測日期 = 今天 + 20

- 客戶B：平均週期 30 天，距上次購買 40 天
  → 已逾期 10 天 → 預測日期 = 今天 + 30（下個週期）
```

### 2. 信心度評估

| ni | 間隔數 | 信心度 | 說明 |
|----|--------|--------|------|
| 1 | 0 | 低 | 無法計算平均週期 |
| 2-3 | 1-2 | 中 | 週期估計不穩定 |
| ≥4 | ≥3 | 高 | 有足夠資料建立模式 |

### 3. 分層採樣

- 優先保留 ni≥2 的客戶（重複購買者更有參考價值）
- 避免圖表被大量 ni=1 的新客淹沒
- 確保各信心度層級都有代表性

### 4. 預測金額邏輯

```r
# 使用歷史平均訂單金額
tag_030_next_purchase_amount = m_value / ni

# 這是合理的假設：客戶下次購買金額 ≈ 歷史平均
```

---

## 實際應用範例

假設某電商有 5,000 位客戶：

### 預測關鍵指標

```
平均預測購買金額: $1,200
高信心度預測客戶: 800 位（ni ≥ 4）
```

### 預測時間軸

```
未來 7 天：預計 50 位客戶購買
未來 14 天：預計 120 位客戶購買
未來 30 天：預計 300 位客戶購買
未來 90 天：預計 800 位客戶購買
```

### 散點圖洞察

```
右上象限（高歷史 + 高預測）：500 位 VIP 客戶
左下象限（低歷史 + 低預測）：2,000 位新客/邊緣客戶
對角線上方：300 位客單價可能提升的客戶
對角線下方：200 位客單價可能下降的客戶
```

---

## 與其他模組的關係

### 資料來源

- **接收**：`customer_data()`（來自 Status 模組）

### 依賴欄位

| 欄位 | 說明 |
|------|------|
| `m_value` | 總消費金額 |
| `ni` | 購買次數 |
| `ipt` | 平均購買間隔 |
| `r_value` | 最近購買天數 |
| `tag_011_rfm_m` | M 值（用於散點圖）|

### 輸出標籤

| 標籤 | 說明 |
|------|------|
| `tag_030_next_purchase_amount` | 預測購買金額 |
| `tag_031_next_purchase_date` | 預測購買日期 |
| `tag_031_prediction_method` | 預測方法說明 |

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.1 | 2025-11 | 增加分層採樣、詳細說明 footer、放寬過濾條件 |
| 1.0 | 2025-10 | 初始版本 |
