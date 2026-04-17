# module_customer_value_analysis.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_customer_value_analysis.R`
- **檔案大小**: 約 1,123 行
- **功能**: 客戶價值分析（RFM 分析）
- **最後更新**: 2025-11

---

## 模組概述

這是**客戶價值分析模組**，主要做 **RFM 分析和客戶分群**：
- R (Recency): 最近購買天數
- F (Frequency): 購買頻率
- M (Monetary): 購買金額

---

## 檔案結構

### 第一部分：UI 介面 (Lines 25-304)

定義了完整的 RFM 分析介面：

| 區塊 | Lines | 說明 |
|------|-------|------|
| 總覽指標卡片 | 50-87 | 總顧客數、平均客單價、中位購買週期、平均交易次數 |
| RFM 關鍵指標 | 92-141 | 平均 R/F/M 值、平均 RFM 總分 |
| R/F/M 分群分析 | 148-211 | 每個維度的表格 + 圓餅圖 |
| 分布圖表 | 214-242 | R/F/M 各維度的直方圖 |
| RFM 熱力圖 | 268-278 | 購買金額 vs 頻率（氣泡大小 = 最近購買日）|
| 詳細資料表 | 281-301 | 客戶列表 + CSV 下載 |

---

### 第二部分：Server 邏輯 (Lines 311-1110)

---

## 📊 區塊 1：資料處理與標籤計算 (Lines 322-386)

### 核心邏輯 (Lines 328-331)

```r
# 計算 RFM 標籤
processed <- customer_data() %>%
  calculate_rfm_tags()  # 呼叫 utils/calculate_customer_tags.R
```

產生的標籤：

| 標籤 | 說明 |
|------|------|
| `tag_009_rfm_r` | R 值（最近購買天數）|
| `tag_010_rfm_f` | F 值（購買頻率 = ni）|
| `tag_011_rfm_m` | M 值（平均購買金額 = AOV）|
| `tag_012_rfm_score` | RFM 總分（3-15 分）|
| `tag_013_value_segment` | 價值分群（高/中/低）|

### 資料品質檢查 (Lines 334-379)

**檢查 1：M 值變異度 (Lines 338-359)**

```r
# 計算變異係數 (Coefficient of Variation)
m_cv = sd(m_values) / mean(m_values)

# 如果 CV < 0.15 或 P20/Median/P80 太接近
if (m_cv < 0.15 || (m_p20 == m_median && m_median == m_p80)) {
  # 警告：M 值變異度較低，分群意義不大
}
```

**檢查 2：F 值單次購買比例 (Lines 361-377)**

```r
# 計算單次購買客戶比例
single_purchase_pct = mean(f_values < 1.5) * 100

if (single_purchase_pct > 90) {
  # 提示：超過 90% 客戶只買一次，可能需要擴大資料時間範圍
}
```

---

## 📊 區塊 2：總覽指標 (Lines 450-504)

### 四大總覽指標

**1. 總顧客數 (Lines 454-458)**

```r
n_customers = nrow(processed_data)
```

**2. 平均客單價 (Lines 460-466)**

```r
# 客單價 = 平均每次購買金額 (M value)
avg_aov = mean(tag_011_rfm_m)
```

**3. 中位購買週期 (Lines 468-510)** ⚠️ 已修正

```r
# ✅ 修正：優先使用 DNA 提供的 ipt_mean
if ("ipt_mean" %in% names(processed_data)) {
  ipt_values <- processed_data$ipt_mean
} else if ("ipt" %in% names(processed_data)) {
  # 從 ipt 和 ni 計算：平均購買間隔 = ipt / (ni - 1)
  ipt_values <- ipt / (ni - 1)
}
median_cycle <- median(ipt_values)

# 智能顯示格式：
# ≥ 365 天 → 顯示「年/次」
# ≥ 30 天 → 顯示「月/次」
# < 30 天 → 顯示「天/次」
```

**4. 平均交易次數 (Lines 512-518)**

```r
# F value 就是購買頻率（次數）
avg_transactions = mean(tag_010_rfm_f)
```

---

## 🎯 區塊 3：R/F/M 分群分析 (Lines 538-833)

每個維度（R/F/M）都有獨立的分群邏輯：

### R 值分群（最近購買日）(Lines 538-568)

**分群邏輯**：使用 **P20/P80** 方法

```r
p80 = quantile(r_value, 0.80)  # 第 80 百分位
p20 = quantile(r_value, 0.20)  # 第 20 百分位

r_segment = case_when(
  r_value <= p20 ~ "最近買家",      # 底部 20%（最近購買）
  r_value <= p80 ~ "中期買家",      # 中間 60%
  TRUE ~ "長期未購者"               # 頂部 20%（很久沒買）
)
```

**為什麼這樣分**：R 值越小 = 越近期購買 = 越好，所以 p20 以下是最好的客戶

---

### F 值分群（購買頻率）(Lines 570-628)

**智能分群邏輯**：根據資料特性自動選擇方法

**方法 1：固定閾值**（當單次購買比例 > 70%）

```r
if (single_purchase_pct > 0.7) {
  f_segment = case_when(
    f_value > 2 ~ "高頻買家",    # 買超過 2 次
    f_value > 1 ~ "中頻買家",    # 買 1-2 次
    TRUE ~ "低頻買家"            # 只買 1 次
  )
}
```

**方法 2：P20/P80**（當資料分布正常）

```r
else {
  p80 = quantile(f_value, 0.80)
  p20 = quantile(f_value, 0.20)

  f_segment = case_when(
    f_value >= p80 ~ "高頻買家",    # 頂部 20%
    f_value >= p20 ~ "中頻買家",    # 中間 60%
    TRUE ~ "低頻買家"               # 底部 20%
  )
}
```

**為什麼兩種方法**：如果 90% 客戶都只買一次，用百分位數分群沒意義，改用固定閾值更有商業意義

---

### M 值分群（購買金額）(Lines 630-695)

**智能分群邏輯**：檢查變異度

**方法 1：均值±標準差**（當變異度太低）

```r
m_cv = sd(m_value) / mean(m_value)

if (m_cv < 0.2 || (m_p80 - m_p20) / m_median < 0.3) {
  # 變異度太低，用均值±0.5倍標準差切分
  threshold_low = mean - 0.5 * sd
  threshold_high = mean + 0.5 * sd

  m_segment = case_when(
    m_value > threshold_high ~ "高消費買家",
    m_value >= threshold_low ~ "中消費買家",
    TRUE ~ "低消費買家"
  )
}
```

**方法 2：P20/P80**（當變異度正常）

```r
else {
  p80 = quantile(m_value, 0.80)
  p20 = quantile(m_value, 0.20)

  m_segment = case_when(
    m_value >= p80 ~ "高消費買家",    # 前 20%
    m_value >= p20 ~ "中消費買家",    # 中間 60%
    TRUE ~ "低消費買家"               # 後 20%
  )
}
```

---

## 📈 區塊 4：視覺化輸出 (Lines 697-989)

### 分群表格與圓餅圖 (Lines 697-833)

每個維度（R/F/M）都輸出：
- **表格**：顯示各群的客戶數、百分比、平均值
- **圓餅圖**：視覺化分布（綠/黃/紅配色）

### 分布直方圖 (Lines 839-885)

R/F/M 各維度的分布圖（Histogram），看出資料的偏態和集中趨勢

### RFM 總分分布 (Lines 891-910)

```r
# RFM 總分 = R分數 + F分數 + M分數
# 範圍：3-15 分（每個維度 1-5 分）
```

### 價值分群長條圖 (Lines 912-939)

顯示高/中/低價值客戶的數量分布

### RFM 熱力圖 (Lines 945-989) ⭐

**這是核心視覺化！**

```r
plot_ly(
  x = ~tag_011_rfm_m,        # 橫軸：購買金額 M
  y = ~tag_010_rfm_f,        # 縱軸：頻率 F
  size = ~tag_009_rfm_r,     # 氣泡大小：新近度 R
  color = ~tag_013_value_segment  # 顏色：價值分群
)
```

**解讀方式**：

| 位置 | 說明 |
|------|------|
| 右上角 | 高金額 + 高頻率 = 最佳客戶 |
| 左下角 | 低金額 + 低頻率 = 需要培育 |
| 氣泡大小 | 越小 = R 值越低 = 越近期購買（越好）|
| 顏色 | 綠色（高價值）、黃色（中價值）、紅色（低價值）|

**採樣策略**：如果資料 > 500 筆，隨機採樣 500 筆顯示（避免圖表過擠）

---

## 📥 區塊 5：資料表與下載 (Lines 995-1102)

### 客戶詳細資料表 (Lines 995-1027)

```r
display_data <- processed_data %>%
  select(
    customer_id,
    購買次數 = ni,
    R值_新近度 = tag_009_rfm_r,
    F值_頻率 = tag_010_rfm_f,
    M值_金額 = tag_011_rfm_m,
    RFM總分 = tag_012_rfm_score,
    價值分群 = tag_013_value_segment
  ) %>%
  arrange(desc(RFM總分)) %>%
  head(100)  # 只顯示前 100 筆
```

### CSV 下載功能 (Lines 1074-1102)

- 檔名格式：`customer_rfm_analysis_2025-11-24.csv`
- 編碼：UTF-8

### 下載說明 Modal (Lines 1035-1072)

教用戶如何正確用 Excel 開啟 CSV（避免亂碼）

---

## 關鍵設計特點

### 1. 智能分群邏輯

- **不是死板的 P20/P80**
- 根據資料特性自動調整

| 維度 | 條件 | 使用方法 |
|------|------|----------|
| F 值 | 單次購買多 | 固定閾值 |
| M 值 | 變異度低 | 標準差 |
| R 值 | 永遠 | P20/P80（時間維度較穩定）|

### 2. 資料品質檢查

- 自動檢測資料是否適合 RFM 分析
- 給出具體的改善建議
- 不會強制分群，而是提醒用戶注意

### 3. 多維度視覺化

| 圖表類型 | 用途 |
|----------|------|
| 表格 | 精確數據 |
| 圓餅圖 | 整體分布 |
| 直方圖 | 資料分布形態 |
| 熱力圖 | 三維關聯分析 |

---

## 與其他模組的關係

### 資料來源

- **接收**：`customer_data()`（來自上游模組）

### 輸出

- **輸出**：`values$processed_data`（加入 RFM 標籤）

### 關鍵標籤

| 標籤 | 說明 |
|------|------|
| `tag_009_rfm_r` | R 值 |
| `tag_010_rfm_f` | F 值 |
| `tag_011_rfm_m` | M 值 |
| `tag_012_rfm_score` | RFM 總分 |
| `tag_013_value_segment` | 價值分群 |

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.1 | 2025-11 | 修正中位購買週期計算邏輯，改用 DNA 提供的 ipt_mean |
| 1.0 | 2025-10 | 初始版本 |
