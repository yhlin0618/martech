# P(alive) — BG/NBD 留存機率

## 定義

P(alive) 是系統用 BG/NBD 模型估出的「這位客戶現在還活著、仍可能繼續買」的機率。
數值越高，表示客戶越可能還在活躍狀態；數值越低，表示流失風險越高。

## 數學公式

若客戶有重複購買（$x \ge 1$）：

$$
P(\text{alive}) =
\frac{1}{
1 + \frac{a}{b + x - 1}
\left(\frac{\alpha + T}{\alpha + t_x}\right)^{r + x}
}
$$

若客戶沒有重複購買（$x = 0$）：

$$
P(\text{alive}) =
\frac{1}{
1 + \frac{a}{b}
\left[
\left(\frac{\alpha + T}{\alpha}\right)^r - 1
\right]
}
$$

系統也會另外計算：

$$
\text{nrec}\\_\text{prob} = 1 - P(\text{alive})
$$

$$
\text{Expected Transactions} =
P(\text{alive}) \times \frac{r}{\alpha} \times \text{prediction}\\_\text{periods}
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $x$ | 重複購買次數，不含首購 |
| $t_x$ | 最後一次購買距離首購的時間 |
| $T$ | 觀察期總長度 |
| $r$、$\alpha$ | 購買行為的模型參數 |
| $a$、$b$ | 流失行為的模型參數 |
| `prediction_periods` | 往未來預測多少期 |

## 範例

如果模型估得某位客戶：

- $P(\text{alive}) = 0.82$
- 預測期數 = 12
- $\frac{r}{\alpha} = 0.4$

則：

$$
\text{nrec}\\_\text{prob} = 1 - 0.82 = 0.18
$$

$$
\text{Expected Transactions} = 0.82 \times 0.4 \times 12 = 3.94
$$

這表示系統認為這位客戶仍然相當活躍，未來 12 期大約還有 4 次交易機會。

## 風險分級與經營建議

系統根據 `nrec_prob`（= 1 − P(alive)）將客戶分為三個風險等級：

$$
\text{Risk Level}_i =
\begin{cases}
\text{High Risk}, & \text{nrec}\\_\text{prob}_i > 0.7 \\
\text{Medium Risk}, & 0.3 \le \text{nrec}\\_\text{prob}_i \le 0.7 \\
\text{Low Risk}, & \text{nrec}\\_\text{prob}_i < 0.3
\end{cases}
$$

這也是 [[RSV|Term-RSV]] 中 Risk 維度的來源。

### 各風險等級的經營方向

| 風險等級 | P(alive) 範圍 | 客戶狀態 | 建議行動 |
|----------|---------------|----------|----------|
| Low Risk | P(alive) > 0.7 | 仍然活躍，短期內流失可能性低 | 維持關係、深化消費，不需投入高成本的挽回方案 |
| Medium Risk | 0.3 ≤ P(alive) ≤ 0.7 | 活躍度正在減弱 | 及早介入，發送提醒或小額優惠，防止滑入高風險 |
| High Risk | P(alive) < 0.3 | 流失可能性高，可能已離開 | 評估挽回成本是否值得；若值得，需要強力誘因 |

> 看這些數字時，重點不是「絕對數值」而是「趨勢」：如果某個客戶群的平均 P(alive) 持續下降，代表客戶基礎正在弱化，需要儘快檢視原因。

## 常見混淆：P(alive) 與靜止戶機率

儀表板上有兩個看起來相關但**意義相反**的數字，容易混淆：

| 指標 | 儀表板名稱 | 數學定義 | 意義 |
|------|-----------|----------|------|
| P(alive) | 留存機率 | BG/NBD 模型估計值 | 客戶**仍在活躍**的機率 |
| nrec_prob | 靜止戶機率 | 1 − P(alive) | 客戶**已流失**的機率 |

這兩個指標是**互補關係**（兩者相加 = 1），不是同一件事。

**常見誤讀**：
- 誤以為「P(alive) = 0.2」代表「有 20% 機率還活著」然後直接放棄 → 正確理解：這位客戶確實流失風險高，但仍有 20% 活躍可能。如果 CLV 很高，20% 的挽回機率可能仍值得投入。
- 誤以為「靜止戶機率」就是「P(alive)」的中文名 → 正確理解：靜止戶機率 = 1 − P(alive)，兩者方向相反。
- 誤以為應該把 P(alive) 的欄位名改成「靜止戶機率」→ 正確理解：不需要改名。P(alive) 顯示為「留存機率」，nrec_prob 顯示為「靜止戶機率」，各有其用途。

> **一句話總結**：P(alive) 高 = 好消息（客戶還在），靜止戶機率高 = 壞消息（客戶可能走了）。看到數字時，先確認你看的是哪一個。

## R 程式碼實作

以下是系統實際的計算邏輯（摘自 `04_utils/fn_analysis_btyd.R`）：

```r
# --- BG/NBD 模型參數由 CLVTools 估計 ---
# r_par, alpha_par: 購買行為的 Gamma 分布參數
# a_par, b_par:     流失行為的 Beta 分布參數

# --- P(alive) 封閉解（Fader, Hardie & Lee 2005, eq. 7） ---
# 對有重複購買的客戶 (x >= 1):
cust_stats[x >= 1 & T_cal > 0, p_alive := {
  1 / (1 + (a_par / (b_par + x - 1)) *
             ((alpha_par + T_cal) / (alpha_par + t_x))^(r_par + x))
}]

# 對僅有首購的客戶 (x = 0):
cust_stats[x == 0 & T_cal > 0, p_alive := {
  delta_val <- ((alpha_par + T_cal) / alpha_par)^r_par - 1
  1 / (1 + (a_par / b_par) * delta_val)
}]

# --- 預期交易次數 (CET) ---
prediction_periods <- 12   # 預測未來 12 期
cust_stats[, btyd_expected_transactions :=
  p_alive * (r_par / alpha_par) * prediction_periods]

# --- 流失機率覆蓋原有的 nrec_prob ---
data_by_customer[["nrec_prob"]] <- 1 - data_by_customer[["p_alive"]]
```

**白話解讀**：
- `x` = 重複購買次數（不含首購），`t_x` = 最後一次購買距首購的天數，`T_cal` = 觀察期總長度。
- 公式的直覺是：如果客戶最近還有買（$t_x$ 接近 $T$），分母趨近 1，P(alive) 就趨近 1；如果最近很久沒買（$T$ 遠大於 $t_x$），分母會變大，P(alive) 就下降。
- `CET`（Conditional Expected Transactions）= P(alive) × 每期平均購買率 × 預測期數。這是「在假設客戶還活著的前提下，預期未來會再買幾次」。
- 系統用 P(alive) 計算的 `nrec_prob`（= 1 − P(alive)）覆蓋舊版的流失機率欄位，確保風險分級一致。

### 經營啟示

- **P(alive) 下降但 CLV 高的客戶**：這是最值得搶救的一群，出現在 `TagPilot > customerLifecycle` 的 Rescue Priority List。
- **CET 接近 0**：代表系統預期這位客戶幾乎不會再回來。如果 CET < 1 且 NES 是 S3，挽回成本通常不划算。
- **觀察趨勢比絕對值重要**：同一批客戶的平均 P(alive) 如果逐月下滑，代表客戶基礎正在弱化。

> 對應程式碼位置：`04_utils/fn_analysis_btyd.R`

## 儀表板中的位置

- `TagPilot > customerStatus`：P(alive) 風險條與客戶明細
- `TagPilot > customerLifecycle`：P(alive) 與 CLV 的交叉象限
- `VitalSigns > customerRetention`：整體留存與流失風險概況，Churn Risk Analysis 堆疊圖按 NES 狀態與風險等級交叉呈現
