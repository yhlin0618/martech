# RFM — Recency, Frequency, Monetary

## 定義

RFM 是系統用來描述客戶購買狀態的三個基礎指標：

- `Recency (R)`：距離最近一次購買已經過了多久
- `Frequency (F)`：客戶累積買了幾次
- `Monetary (M)`：客戶累積花了多少錢

三個值合起來，可以快速回答「這個客戶最近有沒有買、買得勤不勤、花得多不多」。

## 數學公式

對客戶 $i$：

$$
R_i = \text{time}\\_\text{now} - t_{i,\max}
$$

$$
F_i = n_i
$$

$$
M_i = \sum_{k=1}^{n_i} a_{ik}
$$

若系統要把三個維度整理成 3 到 15 分的總分，會先把 0 到 1 的分位分數換成 1 到 5 分：

$$
s(x) = \min \left(5,\max \left(1,\left\lceil 5x \right\rceil \right)\right)
$$

$$
\text{RFM Score}_i = s(\text{dna}\\_\text{r}\\_\text{score}_i) + s(\text{dna}\\_\text{f}\\_\text{score}_i) + s(\text{dna}\\_\text{m}\\_\text{score}_i)
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $t_{i,\max}$ | 客戶 $i$ 最近一次購買時間 |
| $n_i$ | 客戶 $i$ 的購買次數 |
| $a_{ik}$ | 客戶 $i$ 第 $k$ 次購買金額 |
| $\text{time}\\_\text{now}$ | 系統計算時點 |
| $\text{dna}\\_\text{r}\\_\text{score}$、$\text{dna}\\_\text{f}\\_\text{score}$、$\text{dna}\\_\text{m}\\_\text{score}$ | 0 到 1 的比較分位分數 |

## 範例

某位客戶最近一次購買是 12 天前，累積購買 6 次，總消費 18,500 元：

- $R = 12$
- $F = 6$
- $M = 18{,}500$

如果這位客戶在三個維度的分位分數分別是 0.81、0.63、0.58，則：

- $s(0.81)=5$
- $s(0.63)=4$
- $s(0.58)=3$
- $\text{RFM Score}=12$

這代表他同時具備「近期有買、購買次數不低、累積金額中上」的特徵。

## 價值分級（Value Tier）

儀表板中的「客戶價值」頁面，除了 RFM Score 之外，還會用 [[CLV|Term-CLV]] 將客戶分為三個價值等級：

$$
\text{Value Tier}_i =
\begin{cases}
\text{High Value}, & \text{CLV}_i > Q_{0.8}(\text{CLV}) \\
\text{Mid Value}, & Q_{0.2}(\text{CLV}) \le \text{CLV}_i \le Q_{0.8}(\text{CLV}) \\
\text{Low Value}, & \text{CLV}_i < Q_{0.2}(\text{CLV})
\end{cases}
$$

其中 $Q_{0.2}$ 和 $Q_{0.8}$ 是全體客戶 CLV 的第 20 和第 80 百分位數。換句話說，這不是固定金額門檻，而是**相對排名**：

- **High Value**：CLV 排在全體前 20% 的客戶
- **Mid Value**：CLV 排在中間 60% 的客戶
- **Low Value**：CLV 排在最後 20% 的客戶

這個分級也是 [[RSV|Term-RSV]] 中 Value 維度的來源。

## R 程式碼實作

以下是系統實際的計算邏輯（摘自 `04_utils/fn_analysis_dna.R`）：

```r
# --- R、F、M 原始值 ---
r_f_dt2[, r_value := as.numeric(difftime(time_now, payment_time, units = "days"))]
r_f_dt2[, f_value := times]
# M (total_spent) 已由上游彙總

# --- ECDF 分位排名（0~1） ---
r_f_dt2[, r_ecdf := cume_dist(r_value)]
r_f_dt2[, f_ecdf := cume_dist(f_value)]
r_f_dt2[, m_ecdf := cume_dist(total_spent)]

# --- 高中低分群（以 R 為例） ---
r_breaks <- c(-0.0001, 0.1, 0.9, 1.0001)
text_r_label <- c("Long Inactive", "Medium Inactive", "Recent Buyer")
r_f_dt2[, r_label := cut(r_ecdf, r_breaks,
                          labels = text_r_label,
                          right = FALSE, ordered_result = TRUE)]

# M 的分群同理
m_breaks <- c(-0.0001, 0.1, 0.9, 1.0001)
text_m_label <- c("Low Value", "Medium Value", "High Value")

# --- 1~5 分轉換 ---
# s(x) = min(5, max(1, ceiling(5 * x)))
r_f_dt2[, dna_r_score := pmin(5, pmax(1, ceiling(5 * r_ecdf)))]
r_f_dt2[, dna_f_score := pmin(5, pmax(1, ceiling(5 * f_ecdf)))]
r_f_dt2[, dna_m_score := pmin(5, pmax(1, ceiling(5 * m_ecdf)))]

# --- RFM 總分（3~15） ---
r_f_dt2[, rfm_score := dna_r_score + dna_f_score + dna_m_score]
```

**白話解讀**：
- 系統用 ECDF（經驗累積分布函數）把每個客戶的 R、F、M 轉成 0~1 的排名，再用 `ceiling(5x)` 映射到 1~5 分。
- 高中低分群的切點是 10% / 90%，例如 R 排名前 10% 的客戶歸為 "Long Inactive"，後 10% 歸為 "Recent Buyer"。
- 三個維度加總得到 RFM Score（3~15），分數越高代表 R、F、M 的排名越頂端。

### 價值分級的 R 程式碼

```r
# --- Value Tier（基於 CLV 的 20/80 百分位切法） ---
clv_q20 <- quantile(dt$clv, 0.2, na.rm = TRUE)
clv_q80 <- quantile(dt$clv, 0.8, na.rm = TRUE)

dt[, value_tier := fcase(
  clv > clv_q80,  "High Value",
  clv >= clv_q20, "Mid Value",
  default = "Low Value"
)]
```

> 對應程式碼位置：`04_utils/fn_analysis_dna.R`

## 儀表板中的位置

- `TagPilot > customerValue`：R、F、M 的分布、分段、價值等級與客戶明細
- `TagPilot > marketingDecision`：RFM Score 會用來決定部分行銷策略
- `TagPilot > customerExport`：匯出名單時會帶出 `rfm_score`
