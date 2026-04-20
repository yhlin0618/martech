# CLV — Customer Lifetime Value（客戶終身價值）

## 定義

CLV 是系統對「這位客戶未來還可能帶來多少價值」的估計。
它會用客戶過去累積消費作為基底，再乘上一條內建的購買強度曲線與折現因子，估計未來 11 個期點的加總價值。

## 數學公式

系統先定義購買強度函數：

$$
\text{PIF}(t) =
\frac{
\begin{cases}
4t^2 + 20, & t < 5 \\
120 + 80 \left(1 - e^{5-t}\right), & t \ge 5
\end{cases}
}{20}
$$

接著對客戶 $i$ 計算：

$$
\text{CLV}_i = \sum_{t=0}^{10}
\text{TotalSpent}_i \times \text{PIF}(t) \times \frac{0.9^t}{(1 + 4\delta)^t}
$$

其中系統預設：

$$
\delta = 0.0001
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $\text{TotalSpent}_i$ | 客戶 $i$ 的歷史總消費 |
| $t$ | 未來期點，系統使用 $0$ 到 $10$ |
| $\text{PIF}(t)$ | 系統內建的購買強度曲線 |
| $0.9^t$ | 留存衰減因子 |
| $(1+4\delta)^t$ | 折現因子 |

## 範例

如果某位客戶歷史總消費是 1,000 元，且使用系統預設 $\delta = 0.0001$，則：

$$
\text{CLV} =
\sum_{t=0}^{10}
1000 \times \text{PIF}(t) \times \frac{0.9^t}{(1.0004)^t}
$$

依照目前程式中的函數，結果大約會落在 36,000 左右。
這表示系統判斷這位客戶未來仍有相當高的可開發價值。

## 儀表板中的位置

- `TagPilot > customerLifecycle`：CLV 分布、象限圖與救援名單
- `VitalSigns > revenuePulse`：用整體角度觀察 CLV 結構
- `TagPilot > rsvMatrix`、`TagPilot > marketingDecision`：CLV 會決定 `Value` 層級

## R 程式碼實作

以下是系統實際計算 CLV 的核心邏輯（摘錄自 `fn_analysis_dna.R`）：

```r
# 購買強度函數 (PIF) — 模擬客戶隨時間增長的購買強度
pif <- function(t) {
  ifelse(t < 5, (4*t^2 + 20), 120 + 80*(1 - exp(5 - t))) / 20
}

# CLV 計算函數 — 加總 t=0~10 期的折現未來價值
clv_fcn <- function(x) {
  t <- 0:10
  discount_factors <- (0.9)^t / (1 + delta*4)^t   # delta = 0.0001
  pif_values <- pif(t)
  sapply(x, function(total_spent) sum(total_spent * pif_values * discount_factors))
}

# 對每位客戶：先彙總歷史消費，再套用 CLV 函數
clv_dt <- dt[, .(total_sum = sum(total_spent, na.rm = TRUE)), by = customer_id]
clv_dt[, clv := clv_fcn(total_sum)]
```

### 白話解讀

1. **PIF（購買強度曲線）**：系統假設客戶的購買力會隨時間增長 — 前期增長較快（二次函數），後期趨於平穩（指數飽和）。這條曲線反映「客戶越久越熟悉品牌、購買力可能越強」
2. **折現因子**：`0.9^t` 是留存衰減（每期有 10% 流失可能），`(1+0.0004)^t` 是貨幣折現。越遠的未來，價值打越多折
3. **最終加總**：每位客戶的歷史總消費 × 購買強度 × 折現因子，從 t=0 加到 t=10，得到「未來還能帶來多少價值」的估計

CLV 值越高，代表系統判斷這位客戶未來可開發價值越大。在 [[RSV|Term-RSV]] 分類中，CLV 決定了 Value 維度的排名。

> **程式碼來源**：`04_utils/fn_analysis_dna.R`（CLV Calculation 區塊）
