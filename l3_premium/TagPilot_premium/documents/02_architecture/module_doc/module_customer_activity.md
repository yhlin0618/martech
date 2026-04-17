# module_customer_activity.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_customer_activity.R`
- **檔案大小**: 約 574 行
- **功能**: 顧客活躍度模組（CAI 分析）
- **最後更新**: 2025-11

---

## 模組概述

這是**顧客活躍度模組**，主要分析 **CAI（Customer Activity Index）**。

### 核心概念：CAI 是什麼？

```r
# CAI (Customer Activity Index) = (mle - wmle) / mle
#   mle = 最後購買間隔
#   wmle = 加權平均購買間隔

# CAI > 0 → 購買間隔縮短 → 漸趨活躍
# CAI ≈ 0 → 購買間隔穩定 → 穩定消費
# CAI < 0 → 購買間隔拉長 → 漸趨靜止
```

**重要限制**：只計算 **ni ≥ 4** 的客戶（需要足夠的購買間隔數據）

---

## 檔案結構

### 第一部分：UI 介面 (Lines 22-151)

| 區塊 | Lines | 說明 |
|------|-------|------|
| 總覽指標卡片 | 29-66 | 平均 CAI 值、活躍/穩定/靜止客戶比例 |
| 活躍度分群分析 | 71-90 | 分群統計表格、圓餅圖 |
| 生命週期 × CAI 交叉矩陣 | 95-105 | 熱力圖 |
| CAI 分布分析 | 110-129 | 直方圖、散點圖 |
| 客戶詳細資料表 | 134-150 | 列表 + 下載功能 |

---

### 第二部分：Server 邏輯 (Lines 154-572)

---

## 📊 區塊 1：資料處理與分群 (Lines 168-242)

### Step 1：標準化欄位名稱 (Lines 190-194)

```r
# 處理 cai 或 cai_value（不同 DNA 版本命名不同）
cai_df <- processed_data() %>%
  mutate(
    cai = if("cai_value" %in% names(.)) cai_value else cai,
    cai_ecdf = if("cai_ecdf" %in% names(.)) cai_ecdf else NA_real_
  )
```

### Step 2：過濾有效資料 (Lines 196-199)

```r
# ⚠️ 只保留 ni >= 4 的客戶（CAI 才有意義）
cai_df <- cai_df %>%
  filter(!is.na(cai))
```

### Step 3：使用 P20/P80 分群 (Lines 207-216)

```r
activity_segment = case_when(
  is.na(cai_ecdf) ~ "未知",
  cai_ecdf >= 0.8 ~ "漸趨活躍戶",   # 前 20%（購買間隔縮短最多）
  cai_ecdf >= 0.2 ~ "穩定消費戶",   # 中間 60%
  TRUE ~ "漸趨靜止戶"               # 後 20%（購買間隔拉長最多）
)
```

### 分群統計 (Lines 221-233)

計算每一群的：
- 客戶數量
- 百分比
- 平均 CAI 值

---

## 📈 區塊 2：總覽指標輸出 (Lines 244-282)

四個 ValueBox 的計算：

```r
# 1. 平均 CAI 值
avg_cai = mean(cai_data$cai)

# 2-4. 各分群的百分比（直接從 segment_data 取）
active_pct = 漸趨活躍戶的百分比
stable_pct = 穩定消費戶的百分比
inactive_pct = 漸趨靜止戶的百分比
```

---

## 📋 區塊 3：分群表格與圓餅圖 (Lines 284-336)

### 表格 (Lines 288-307)

- 顯示四列：分群、客戶數量、百分比、平均 CAI
- 顏色標記：
  - 綠色：漸趨活躍戶
  - 黃色：穩定消費戶
  - 紅色：漸趨靜止戶

### 圓餅圖 (Lines 309-336)

- 排除「未知」分群
- 綠/黃/紅三色配色

---

## 🔥 區塊 4：生命週期 × CAI 交叉矩陣 (Lines 338-424) ⭐

這是最重要的分析！

### Step 1：檢查資料 (Lines 346-354)

```r
# 檢查是否有 tag_017_customer_dynamics 欄位
if (!"tag_017_customer_dynamics" %in% names(values$cai_data)) {
  # 顯示錯誤訊息
}
```

### Step 2：建立交叉表 (Lines 357-364)

```r
cross_tab_data <- cai_data %>%
  group_by(tag_017_customer_dynamics, activity_segment) %>%
  summarise(count = n()) %>%
  pivot_wider(names_from = activity_segment, values_from = count)
```

### Step 3：排序生命週期 (Lines 367-372)

```r
lifecycle_order <- c("新客", "主力客", "半睡客", "睡眠客", "沉睡客")
cross_tab_data <- cross_tab_data %>%
  arrange(match(tag_017_customer_dynamics, lifecycle_order))
```

### Step 4：輸出熱力圖 (Lines 390-422)

- X 軸：CAI 活躍度分群（漸趨活躍戶/穩定消費戶/漸趨靜止戶）
- Y 軸：生命週期階段（新客/主力客/半睡客/睡眠客/沉睡客）
- 顏色深淺：客戶數量

### 分析意義

| 組合 | 意義 | 建議行動 |
|------|------|----------|
| 主力客 + 漸趨活躍戶 | 最佳客戶 | 持續維護 |
| 主力客 + 漸趨靜止戶 | 危險訊號 | 需要喚醒 |
| 半睡客 + 漸趨活躍戶 | 有機會喚回 | 重點培育 |

---

## 📊 區塊 5：CAI 分布圖表 (Lines 426-473)

### 圖 1：CAI 數值分布 (Lines 430-445)

- 直方圖顯示 CAI 的分布
- 看出資料是否偏態

### 圖 2：CAI × 購買金額關係 (Lines 447-473)

- 散點圖：X = 購買金額，Y = CAI 值
- 顏色 = 活躍度分群
- **分析意義**：看高價值客戶的活躍度趨勢

---

## 📋 區塊 6：詳細資料表 (Lines 475-521)

### 表格內容 (Lines 482-501)

```r
select(
  客戶ID = customer_id,
  CAI係數 = cai,
  顧客活躍度分群 = activity_segment,
  購買次數 = tag_010_rfm_f,
  最近購買天數 = tag_009_rfm_r,
  購買金額 = tag_011_rfm_m
) %>%
arrange(desc(CAI係數)) %>%
head(100)  # 只顯示前 100 筆
```

---

## 📥 區塊 7：下載功能 (Lines 523-571)

### 下載說明 Modal (Lines 527-548)

- 提醒 UTF-8 BOM 編碼問題
- 說明檔案內容

### CSV 下載 (Lines 550-571)

- 包含完整客戶 CAI 資料
- 按 CAI 係數降序排列
- 檔名：`customer_activity_index_2025-11-24.csv`

---

## 關鍵設計特點

### 1. CAI 的計算邏輯

```
CAI = (mle - wmle) / mle

# mle = Mean of Last intervals（最後購買間隔的平均）
# wmle = Weighted Mean of intervals（加權平均，權重遞減）

# 例如：
# 客戶A：最近購買間隔 = 10 天，歷史平均 = 20 天
# CAI = (20 - 10) / 20 = 0.5（正值，購買變頻繁 → 活躍）

# 客戶B：最近購買間隔 = 30 天，歷史平均 = 20 天
# CAI = (20 - 30) / 20 = -0.5（負值，購買變慢 → 靜止）
```

### 2. 為什麼只計算 ni ≥ 4？

- 計算 CAI 需要「購買間隔的變化趨勢」
- 至少要 4 次購買才能產生 3 個間隔
- 這樣才能比較「近期間隔」vs「歷史平均間隔」

### 3. 使用 cai_ecdf（百分位數）分群

- **不用 CAI 的絕對值**
- 因為不同產業的 CAI 分布不同
- 用相對排名（P20/P80）更穩健

### 4. 與生命週期的交叉分析

- **生命週期**（customer_dynamics）告訴你「客戶現在是什麼狀態」
- **CAI** 告訴你「客戶正在往哪個方向走」
- 結合起來才能做出精準策略

---

## 實際應用範例

假設某電商有 1,000 位 ni ≥ 4 的客戶：

### 總覽指標

```
平均 CAI 值: 0.12
活躍客戶比例: 20%（200 位）
穩定客戶比例: 60%（600 位）
靜止客戶比例: 20%（200 位）
```

### 生命週期 × CAI 矩陣

```
              漸趨活躍戶   穩定消費戶   漸趨靜止戶
主力客           150          350           50     ← 50位危險客戶！
半睡客            30           80           90
睡眠客            15           50           85
沉睡客             5           20          100     ← 大部分已放棄
```

### 策略洞察

| 組合 | 數量 | 建議策略 |
|------|------|----------|
| 主力客 + 漸趨靜止 | 50 位 | VIP 流失預警 → 專屬客服關懷 |
| 半睡客 + 漸趨活躍 | 30 位 | 有機會喚回 → 加碼行銷 |
| 沉睡客 + 漸趨靜止 | 100 位 | 可能放棄 → 降低行銷成本 |

---

## 與其他模組的關係

### 資料來源

- **接收**：`processed_data()`（來自 DNA 分析）

### 依賴欄位

| 欄位 | 說明 |
|------|------|
| `cai` / `cai_value` | CAI 值 |
| `cai_ecdf` | CAI 的百分位數 |
| `tag_017_customer_dynamics` | 生命週期分類 |
| `tag_009_rfm_r` | R 值 |
| `tag_010_rfm_f` | F 值 |
| `tag_011_rfm_m` | M 值 |

### 關鍵限制

- 只分析 ni ≥ 4 的客戶

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 1.0 | 2025-10 | 初始版本 |
