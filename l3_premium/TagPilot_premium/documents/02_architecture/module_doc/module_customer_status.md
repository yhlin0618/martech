# module_customer_status.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_customer_status.R`
- **檔案大小**: 約 772 行
- **功能**: 顧客動態模組（生命週期階段和流失風險）
- **最後更新**: 2025-11

---

## 模組概述

這是**顧客動態模組**，主要分析**生命週期階段和流失風險**。

### 核心標籤

| 標籤 | 說明 |
|------|------|
| `tag_017_customer_dynamics` | 顧客動態（新客/主力客/睡眠客/半睡客/沉睡客）|
| `tag_018_churn_risk` | 流失風險（低/中/高）|
| `tag_019_days_to_churn` | 預估流失天數 |

**重點**：這個模組**不做計算**，只做**展示**！所有標籤已在 DNA 分析時計算完成。

---

## 檔案結構

### 第一部分：UI 介面 (Lines 25-207)

| 區塊 | Lines | 說明 |
|------|-------|------|
| 顧客動態分布 + 流失風險分布 | 41-66 | 圓餅圖 + 長條圖 |
| 顧客動態 × 流失風險矩陣 | 68-79 | 熱力圖 |
| 流失狀態分布 + 預估流失天數分布 | 81-101 | 圓餅圖 + 直方圖 |
| 關鍵統計指標 | 103-181 | 各類客戶人數 |
| 顧客動態詳細資料表 | 184-205 | 列表 + 下載功能 |

---

### 第二部分：Server 邏輯 (Lines 215-758)

---

## 📊 區塊 1：資料載入 (Lines 224-253)

### 關鍵設計 (Lines 231-236)

```r
# ✅ CRITICAL: DNA module already calculated ALL tags
# We should NOT recalculate - just use the data
processed <- customer_data()

values$processed_data <- processed
```

**重要**：
- 這個模組**不重新計算**標籤
- 直接使用 DNA 模組傳來的資料
- `tag_017_customer_dynamics` 已經是**中文值**（新客、主力客等）

---

## 📈 區塊 2：關鍵指標統計 (Lines 266-322)

### 各生命週期階段人數 (Lines 270-322)

```r
# 使用中文值計數
newbie_count = sum(tag_017_customer_dynamics == "新客")
active_count = sum(tag_017_customer_dynamics == "主力客")
sleepy_count = sum(tag_017_customer_dynamics == "睡眠客")
half_sleepy_count = sum(tag_017_customer_dynamics == "半睡客")
dormant_count = sum(tag_017_customer_dynamics == "沉睡客")
high_risk_count = sum(tag_018_churn_risk == "高風險")
```

### 平均預估流失天數 (Lines 290-303)

```r
# 只計算有效資料（排除 NA 和負值）
valid_days <- tag_019_days_to_churn[tag_019_days_to_churn >= 0]
avg_val <- mean(valid_days)
```

---

## 🥧 區塊 3：顧客動態分布圖 (Lines 324-374)

### 圓餅圖邏輯 (Lines 328-374)

```r
# 計算各階段數量
lifecycle_counts <- processed_data %>%
  count(tag_017_customer_dynamics)

# 顏色映射（中文鍵）
color_map <- c(
  "新客" = "#17a2b8",      # 藍色
  "主力客" = "#28a745",    # 綠色
  "睡眠客" = "#ffc107",    # 黃色
  "半睡客" = "#fd7e14",    # 橘色
  "沉睡客" = "#6c757d"     # 灰色
)
```

---

## 📊 區塊 4：流失風險分布圖 (Lines 376-411)

### 長條圖邏輯 (Lines 380-411)

```r
# 計算各風險等級數量
risk_counts <- processed_data %>%
  count(tag_018_churn_risk) %>%
  arrange(match(tag_018_churn_risk, c("低", "中", "高")))

# 顏色映射
color_map <- c(
  "低" = "#28a745",   # 綠色
  "中" = "#ffc107",   # 黃色
  "高" = "#dc3545"    # 紅色
)
```

---

## 🔥 區塊 5：顧客動態 × 流失風險熱力圖 (Lines 413-486)

### Step 1：計算交叉矩陣 (Lines 421-428)

```r
heatmap_data <- processed_data %>%
  filter(!is.na(tag_017_customer_dynamics), !is.na(tag_018_churn_risk)) %>%
  count(tag_017_customer_dynamics, tag_018_churn_risk) %>%
  pivot_wider(names_from = tag_018_churn_risk, values_from = n)
```

### Step 2：確保有所有風險等級欄位 (Lines 435-440)

```r
for (risk in c("低", "中", "高")) {
  if (!risk %in% names(heatmap_data)) {
    heatmap_data[[risk]] <- 0
  }
}
```

### Step 3：過濾全為 0 的列 (Lines 442-446)

```r
# ✅ 只顯示有資料的列（移除全為 0 的顧客動態）
heatmap_data <- heatmap_data %>%
  mutate(row_total = `低` + `中` + `高`) %>%
  filter(row_total > 0) %>%
  select(-row_total)
```

### Step 4：排序並輸出熱力圖 (Lines 452-486)

```r
lifecycle_order <- c("新客", "主力客", "睡眠客", "半睡客", "沉睡客", "未知")
heatmap_data <- heatmap_data %>%
  arrange(match(tag_017_customer_dynamics, lifecycle_order))

# X 軸：流失風險（低/中/高）
# Y 軸：顧客動態（新客→沉睡客）
# 顏色深淺：客戶數量
```

---

## 🥧 區塊 6：流失狀態圓餅圖 (Lines 488-532)

### 將流失天數轉換為狀態 (Lines 496-506)

```r
churn_status <- processed_data %>%
  mutate(
    status = case_when(
      tag_019_days_to_churn == 0 ~ "已流失（0天）",  # 已超過預期回購時間
      tag_019_days_to_churn > 0 ~ "未流失",
      TRUE ~ "未知"
    )
  ) %>%
  count(status)
```

### 分析意義

| 狀態 | 說明 |
|------|------|
| 已流失（0天）| 已超過預期回購時間 → 高風險 |
| 未流失 | 還有時間可以挽回 |

---

## 📊 區塊 7：預估流失天數分布圖 (Lines 534-567)

### 只顯示未流失客戶 (Lines 541-543)

```r
# ✅ 只顯示未流失客戶（天數 > 0）
valid_data <- processed_data %>%
  filter(tag_019_days_to_churn > 0)
```

**為什麼這樣設計**：
- 天數 = 0 的客戶已經「流失」，放進直方圖會造成誤解
- 只顯示「還有多少天會流失」的客戶，更有行動意義

---

## 📋 區塊 8：詳細資料表 (Lines 569-618)

### 表格內容 (Lines 581-590)

```r
display_data <- processed_data %>%
  select(
    customer_id,
    購買次數 = ni,
    顧客動態 = tag_017_customer_dynamics,
    流失風險 = tag_018_churn_risk,
    預估流失天數 = tag_019_days_to_churn
  ) %>%
  arrange(預估流失天數) %>%  # 按流失天數排序（最危急的在前）
  head(100)
```

### 特殊處理 (Lines 593-600)

```r
# 將 0 天顯示為「已流失」
預估流失天數 = case_when(
  is.na(預估流失天數) ~ "N/A",
  預估流失天數 == 0 ~ "已流失",
  TRUE ~ as.character(round(預估流失天數, 1))
)
```

---

## 📥 區塊 9：下載功能 (Lines 620-751)

### 完整資料下載 (Lines 666-685)

- 檔名：`customer_dynamics_2025-11-24.csv`
- 包含所有客戶的顧客動態、流失風險、預估流失天數

### 高風險客戶下載 (Lines 731-751)

```r
# 只篩選高風險和中風險客戶
export_data <- processed_data %>%
  filter(tag_018_churn_risk %in% c("高風險", "中風險")) %>%
  arrange(desc(流失風險 == "高風險"))  # 高風險優先
```

---

## 關鍵設計特點

### 1. 不重複計算

```r
# ✅ 正確做法：直接使用 DNA 模組的計算結果
processed <- customer_data()

# ❌ 錯誤做法：在這裡重新計算標籤
# processed <- calculate_status_tags(customer_data())  # 不要這樣做！
```

### 2. 中文標籤值

```r
# tag_017_customer_dynamics 的值是中文
# "新客", "主力客", "睡眠客", "半睡客", "沉睡客"

# 不是英文
# "newbie", "active", "sleepy", "half_sleepy", "dormant"
```

### 3. 流失天數的解讀

| 值 | 意義 |
|-----|------|
| > 0 | 預估還有 N 天會流失（有機會挽回）|
| = 0 | 已超過預期回購時間（已流失）|
| NA | 無法計算（如 ni=1 的新客）|

### 4. 熱力圖的過濾邏輯

為什麼要過濾全為 0 的列？
- 如果某個生命週期階段沒有任何客戶，顯示出來會造成混淆
- 例如：所有客戶都不是「未知」，那就不要顯示「未知」這一列

---

## 實際應用範例

假設某電商有 5,000 位客戶：

### 顧客動態分布

```
新客:    2,500 位 (50%)
主力客:    800 位 (16%)
睡眠客:    600 位 (12%)
半睡客:    500 位 (10%)
沉睡客:    600 位 (12%)
```

### 流失風險分布

```
低風險: 2,000 位 (40%)
中風險: 1,500 位 (30%)
高風險: 1,500 位 (30%)
```

### 顧客動態 × 流失風險矩陣

```
          低風險   中風險   高風險
新客       1,800     500      200    ← 新客大部分低風險
主力客       600     150       50    ← 主力客也很安全
睡眠客       100     350      150    ← 開始有風險了
半睡客        50     300      150    ← 中高風險居多
沉睡客        50     200      350    ← 高風險最多！
```

### 行動洞察

| 組合 | 數量 | 建議策略 |
|------|------|----------|
| 沉睡客 + 高風險 | 350 位 | 最優先挽回目標 |
| 半睡客 + 中/高風險 | 450 位 | 次優先，還有機會 |
| 新客 + 低風險 | 1,800 位 | 培育成主力客的候選人 |

---

## 與其他模組的關係

### 資料來源

- **接收**：`customer_data()`（來自 RFM 分析模組）

### 依賴欄位

| 欄位 | 說明 |
|------|------|
| `tag_017_customer_dynamics` | 顧客動態（已是中文）|
| `tag_018_churn_risk` | 流失風險 |
| `tag_019_days_to_churn` | 預估流失天數 |
| `ni` | 購買次數 |

### 輸出

- **返回**：原始 `processed_data`（傳給下一個模組）

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.0 | 2025-10 | 初始版本 |
