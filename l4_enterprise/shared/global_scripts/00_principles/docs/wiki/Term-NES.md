# NES — New / Existing / Sleeping 客戶狀態

## 定義

NES 用來判斷客戶目前是：

- `N`：新客，還沒有足夠資料判斷購買節奏
- `E0`：仍在正常購買節奏內
- `S1`、`S2`、`S3`：已經進入不同程度的沉睡狀態

它的核心概念不是看「多久沒買」而已，而是看「多久沒買」相對於這位客戶平常的購買間隔是否異常。

## 數學公式

對客戶 $i$：

$$
\text{nes}\\_\text{ratio}_i = \frac{\text{time}\\_\text{now} - t_{i,\text{last}}}{\text{IPT}_i}
$$

系統目前使用固定的基準值：

$$
\text{nes}\\_\text{median} = 1.7
$$

並以

$$
\left[0,1,2,2.5,\infty\right) \times 1.7
$$

作為切點，因此分類規則可寫成：

$$
\text{NES}_i =
\begin{cases}
\text{N}, & \text{IPT}_i \text{ 不存在} \\
\text{E0}, & 0 \le \text{nes}\\_\text{ratio}_i < 1.7 \\
\text{S1}, & 1.7 \le \text{nes}\\_\text{ratio}_i < 3.4 \\
\text{S2}, & 3.4 \le \text{nes}\\_\text{ratio}_i < 4.25 \\
\text{S3}, & \text{nes}\\_\text{ratio}_i \ge 4.25
\end{cases}
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $t_{i,\text{last}}$ | 客戶 $i$ 最近一次購買時間 |
| $\text{time}\\_\text{now}$ | 系統計算時點 |
| $\text{IPT}_i$ | 客戶 $i$ 的平均購買間隔，見 [IPT](Term-IPT) |
| $\text{nes}\\_\text{ratio}_i$ | 目前空窗期相對於平常節奏的倍數 |
| `E0` | 仍在正常節奏內 |
| `S1`、`S2`、`S3` | 淺眠、中度沉睡、深度沉睡 |

## 範例

某位客戶平常平均每 30 天買一次，最近一次購買在 75 天前：

$$
\text{nes}\\_\text{ratio} = \frac{75}{30} = 2.5
$$

因為 $2.5$ 落在 $1.7$ 到 $3.4$ 之間，所以這位客戶會被分到 `S1`。

如果另一位客戶只有首購、還沒有第二次購買，系統就不會硬算購買節奏，而是直接標成 `N`。

## 個別 NES Ratio 值怎麼看

`nes_ratio` 是一個**無單位的倍數**，代表「目前空窗期是平常購買間隔的幾倍」。數值越小代表越活躍，越大代表越沉睡：

| nes_ratio 值 | 白話意義 | 舉例（假設 IPT = 30 天） |
|--------------|----------|--------------------------|
| 0.002 | 幾乎剛買完，距離下次購買時間只過了極小比例 | 最後一次購買是 1.4 小時前 |
| 0.5 | 才過了平常間隔的一半，還很活躍 | 最後一次購買是 15 天前 |
| 1.0 | 剛好到了平常該買的時候 | 最後一次購買是 30 天前 |
| 2.0 | 已經超過平常間隔的兩倍，開始有沉睡跡象 | 最後一次購買是 60 天前 |
| 4.0 | 平常間隔的四倍，深度沉睡 | 最後一次購買是 120 天前 |

> **關鍵觀念**：nes_ratio 是**個人化**的指標。同樣「30 天沒買」，對一個月買一次的客戶來說 nes_ratio = 1（正常），對一週買一次的客戶來說 nes_ratio = 4.3（深度沉睡）。NES 的價值就在於用每位客戶自己的節奏來判斷是否異常。

### 搭配 P(alive) 進一步判斷

NES 分類告訴你「這位客戶目前是活躍還是沉睡」，但無法預測「他未來會不會回來」。如果需要更精確的流失預測和未來交易次數估算，請搭配 [[P(alive)|Term-P-alive]] 指標使用：

- **P(alive)** = 客戶仍然活躍的機率（0~1）
- **CET（預期交易次數）** = P(alive) × 每期平均購買率 × 預測期數

NES 看的是「過去行為的偏離程度」，P(alive) 看的是「統計模型估計的未來可能性」。兩者互補。

## 再活化機會（Reactivation Opportunity）

在 `VitalSigns > customerEngagement` 中，系統會把所有沉睡客戶（S1 + S2 + S3）加總，顯示為「可再活化人數」KPI：

$$
\text{Reactivation Opportunity} = \sum_{i} \mathbf{1}\left[\text{NES}_i \in \{S1, S2, S3\}\right]
$$

白話說就是：**目前有多少人已經偏離正常購買節奏、但尚未被放棄**。這些客戶是活化行銷最直接的目標。

儀表板同時會顯示一張堆疊長條圖，把 S1、S2、S3 分開呈現，讓你看到沉睡客戶集中在哪個深度：

| 狀態 | 沉睡深度 | 活化難度 | 建議方向 |
|------|----------|----------|----------|
| S1 | 淺眠（剛離開正常節奏） | 低 | 提醒、小額優惠即可 |
| S2 | 中度沉睡 | 中 | 需要更強的誘因或個人化推薦 |
| S3 | 深度沉睡（長期未購買） | 高 | 評估挽回成本是否值得 |

> 實務上，S1 的挽回成本最低、成功率最高，通常是優先投入資源的對象。

## 預測沈睡天數（Estimated Days to Churn）

系統也會估計每位沉睡客還要多久會「完全流失」。計算邏輯是：

$$
\text{estimated}\\_\text{days}\\_\text{to}\\_\text{churn}_i = \text{IPT}_i \times \text{S3 上界} - (\text{time}\\_\text{now} - t_{i,\text{last}})
$$

其中 S3 上界 = $2.5 \times 1.7 = 4.25$。換句話說，系統假設當空窗期超過 IPT 的 4.25 倍時就視為完全流失，再用這個門檻減去目前已過的空窗期，得到「離完全流失還剩多少天」。

> 此指標出現在 `TagPilot > customerStatus` 的 Estimated Days to Churn 圖表中，幫助排定喚回優先順序：天數越少的客戶越需要立即處理。

## R 程式碼實作

以下是系統實際的計算邏輯（摘自 `04_utils/fn_analysis_dna.R`）：

```r
# --- NES 分類 ---
# 計算每位客戶的空窗期與 IPT 的比值
nes_dt[, difftime := difftime(time_now, payment_time, units = "days")]
nes_dt[, nes_ratio := as.numeric(difftime) / as.numeric(ipt_mean)]

# 固定基準值與切點
nes_median <- 1.7
nes_breaks <- c(0, 1, 2, 2.5, Inf)
text_nes_label <- c("E0", "S1", "S2", "S3")

# 分類：nes_ratio 乘以 nes_median 做切點，IPT 不存在者標為 "N"
nes_dt[, nes_status := fct_na_value_to_level(
  cut(nes_ratio,
      breaks = nes_breaks * nes_median,   # 實際切點: 0, 1.7, 3.4, 4.25, Inf
      labels = text_nes_label,
      right = FALSE,
      ordered_result = TRUE),
  level = "N"   # IPT 不存在 → 新客
)]
```

**白話解讀**：
- `nes_ratio` = 空窗天數 ÷ 平常購買間隔。如果這個值是 2，代表「已經等了平常兩倍的時間還沒回來買」。
- 切點是 `c(0, 1, 2, 2.5, Inf) × 1.7`，所以實際分界是 0 / 1.7 / 3.4 / 4.25。
- 如果客戶只買過一次（沒有 IPT），直接歸類為 `N`（新客），不硬算節奏。

> 對應程式碼位置：`04_utils/fn_analysis_dna.R`

## 儀表板中的位置

- `TagPilot > customerStatus`：NES 分布、各狀態人數與明細
- `VitalSigns > customerRetention`：從整體角度看新客、活躍客與沉睡客結構
- `VitalSigns > customerEngagement`：可再活化人數 KPI 與 S1/S2/S3 堆疊長條圖
- `TagPilot > marketingDecision`：NES 會直接影響策略分派
