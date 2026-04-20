# IPT — Inter-Purchase Time（平均購買間隔）

## 定義

IPT 代表一位客戶平均隔多久會再買一次。它是系統判斷客戶節奏的基礎指標，也是 [[NES|Term-NES]]、[[CAI|Term-CAI]]、[[CRI|Term-CRI]] 的共同起點。

## 數學公式

對購買次數大於 1 的客戶 $i$：

$$
\text{IPT}_i = \frac{t_{i,\max} - t_{i,\min}}{n_i - 1}
$$

若 $n_i \le 1$，系統不計算 IPT：

$$
\text{IPT}_i = \text{NA}
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $t_{i,\max}$ | 客戶 $i$ 最後一次購買時間 |
| $t_{i,\min}$ | 客戶 $i$ 第一次購買時間 |
| $n_i$ | 客戶 $i$ 的購買次數 |
| $\text{NA}$ | 代表資料不足，不強行計算 |

## 範例

某位客戶第一次購買在 2025-01-01，最後一次購買在 2025-04-01，總共買了 4 次。
1 月 1 日到 4 月 1 日相差 90 天，因此：

$$
\text{IPT} = \frac{90}{4-1} = 30
$$

這代表這位客戶平均每 30 天購買一次。

## 儀表板中的位置

- `TagPilot > customerStructure`：顯示 IPT 的平均值、分布圖與明細
- `VitalSigns > customerEngagement`：搭配頻率一起看購買節奏
- `TagPilot > customerExport`：會匯出 `avg_purchase_interval`

## R 程式碼實作

以下是系統實際計算 IPT 的核心邏輯（摘錄自 `fn_analysis_dna.R`）：

```r
# 使用每位客戶的首購日 (min_time_by_date) 和末購日 (max_time_by_date)
ipt_table[, ipt_mean := ifelse(ni <= 1, NA_real_,
  as.numeric(difftime(max_time_by_date, min_time_by_date, units = "days")) / (ni - 1)
)]
```

### 白話解讀

1. **只看有 2 次以上購買的客戶**：只買過 1 次的客戶沒有「間隔」可算，系統直接標為 NA
2. **總跨度 ÷ (次數 - 1)**：從第一次購買到最後一次購買的天數，除以間隔段數
3. **結果就是平均幾天買一次**：例如首購到末購 90 天、買了 4 次 → IPT = 90 ÷ 3 = 30 天

IPT 是 [[NES|Term-NES]]、[[CAI|Term-CAI]]、[[CRI|Term-CRI]] 等進階指標的基礎。所有需要判斷「客戶多久回購一次」的場景，背後都用到 IPT。

> **程式碼來源**：`04_utils/fn_analysis_dna.R`（RFM + IPT Calculation 區塊）
