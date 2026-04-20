# CAI — Customer Activity Index（客戶活躍度指數）

## 定義

CAI 用來看客戶的購買節奏是在變快、變慢，還是大致維持原樣。
簡單說：

- `CAI > 0`：購買間隔正在縮短，活躍度上升
- `CAI ≈ 0`：節奏大致穩定
- `CAI < 0`：購買間隔正在拉長，活躍度下降

## 數學公式

對客戶 $i$，系統先對每一段購買間隔 $\text{IPT}_{ij}$ 計算兩種平均：

$$
\text{MLE}_i = \sum_j \left(\text{IPT}_{ij} \times \frac{1}{n_i - 1}\right)
$$

$$
\text{WMLE}_i = \sum_j \left(\text{IPT}_{ij} \times \frac{t_{ij} - 1}{\sum_j (t_{ij} - 1)}\right)
$$

其中較新的購買間隔會在 $\text{WMLE}$ 得到較高權重。最後：

$$
\text{CAI}_i = \frac{\text{MLE}_i - \text{WMLE}_i}{\text{MLE}_i}
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $\text{IPT}_{ij}$ | 客戶 $i$ 第 $j$ 段購買間隔 |
| $n_i$ | 客戶 $i$ 的購買次數 |
| $t_{ij}$ | 第 $j$ 筆交易的購買序號 |
| $\text{MLE}_i$ | 不分先後的平均購買間隔 |
| $\text{WMLE}_i$ | 較重視近期節奏的平均購買間隔 |

## 範例

某位客戶最近幾段購買間隔依序是 40、30、20 天：

- $\text{MLE}=(40+30+20)/3=30$
- 權重依序為 $1,2,3$，所以

$$
\text{WMLE} = \frac{40 \times 1 + 30 \times 2 + 20 \times 3}{1+2+3} = 26.7
$$

因此：

$$
\text{CAI} = \frac{30 - 26.7}{30} \approx 0.11
$$

因為結果大於 0，代表這位客戶最近買得比以前更密集。

## 分群標準

系統會根據 CAI 的 ECDF 百分位位置，將客戶分成三群。計算方式是先對所有客戶的 CAI 值取 ECDF（經驗累積分布函數），再依以下切點分類：

$$
\text{CAI Label}_i =
\begin{cases}
\text{Gradually Inactive}, & \text{CAI}\\_\text{ecdf}_i < 0.1 \\
\text{Stable}, & 0.1 \le \text{CAI}\\_\text{ecdf}_i < 0.9 \\
\text{Increasingly Active}, & \text{CAI}\\_\text{ecdf}_i \ge 0.9
\end{cases}
$$

白話說就是：

- **趨向不活躍（Gradually Inactive）**：CAI 排在全體最低 10% 的客戶。這些客戶的購買節奏正在明顯放慢。
- **穩定（Stable）**：中間 80% 的客戶，購買節奏大致維持。
- **趨向活躍（Increasingly Active）**：CAI 排在全體最高 10% 的客戶，購買節奏正在明顯變快。

> 這個分法**不是三等分**，也**不是 80/20 法則**，而是 **10/80/10 的百分位切法**。系統特意把極端值（最活躍和最不活躍的各 10%）分出來，讓中間大多數客戶歸為「穩定」，方便快速辨識需要特別關注的兩端。

### 前提條件

CAI 只對**購買 4 次以上**的客戶計算（預設 `ni_threshold = 4`）。購買次數不足的客戶沒有 CAI 值，不會出現在分群中。

## 儀表板中的位置

- `TagPilot > customerActivity`：CAI 分布、散點圖與建議
- `VitalSigns > customerEngagement`：用整體視角看活躍度變化
- `TagPilot > marketingDecision`：`CAI < -0.2` 會直接影響策略分派

## R 程式碼實作

以下是系統實際計算 CAI 的核心邏輯（摘錄自 `fn_analysis_dna.R`）：

```r
# 只對「非首購 且 購買次數 >= ni_threshold」的交易記錄計算
cai_dt <- dt[times != 1 & ni >= ni_threshold, .(
  mle  = sum(ipt * (1/(ni-1))),
  wmle = sum(ipt * ((times-1) / sum(times-1)))
), by = customer_id]

if (nrow(cai_dt) > 0) {
  cai_dt[, cai := (mle - wmle) / mle]
  cai_dt[, cai_ecdf := ecdf(cai)(cai)]
  cai_dt[, cai_label := cut(cai_ecdf,
    breaks = c(0, 0.1, 0.9, 1),
    labels = c("Gradually Inactive", "Stable", "Increasingly Active"),
    right = FALSE, ordered_result = TRUE)]
}
```

### 白話解讀

1. **篩選條件**：只取「不是第一筆交易」且「購買次數達門檻（預設 4 次以上）」的交易紀錄
2. **MLE（等權平均）**：把每段購買間隔（[[IPT|Term-IPT]]）除以 `(購買次數-1)`，全部加起來 — 這是「不分先後」的平均間隔
3. **WMLE（加權平均）**：用交易序號作為權重，越晚的交易權重越高 — 這是「較重視近期」的平均間隔
4. **CAI 值**：`(MLE - WMLE) / MLE`，MLE 比 WMLE 大 → 近期買得更密 → CAI > 0
5. **分群**：對所有客戶的 CAI 算 ECDF（經驗累積分布），最低 10% = 趨向不活躍、中間 80% = 穩定、最高 10% = 趨向活躍

> **程式碼來源**：`04_utils/fn_analysis_dna.R`（CAI Calculation 區塊）
