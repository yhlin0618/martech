# RSV — Risk / Stability / Value 客戶分類

## 定義

RSV 會從三個角度看客戶：

- `Risk`：流失風險高不高
- `Stability`：購買節奏穩不穩
- `Value`：未來價值高不高

每個維度分成 `High`、`Mid`、`Low` 三層，因此整體可以形成 27 種組合。

## 數學公式

對客戶 $i$：

$$
\text{Risk}_i =
\begin{cases}
\text{High}, & \text{nrec}\\_\text{prob}_i > 0.7 \\
\text{Mid}, & 0.3 \le \text{nrec}\\_\text{prob}_i \le 0.7 \\
\text{Low}, & \text{nrec}\\_\text{prob}_i < 0.3
\end{cases}
$$

$$
\text{Stability}_i =
\begin{cases}
\text{High}, & \text{cri}\\_\text{ecdf}_i < 0.33 \\
\text{Mid}, & 0.33 \le \text{cri}\\_\text{ecdf}_i \le 0.67 \\
\text{Low}, & \text{cri}\\_\text{ecdf}_i > 0.67
\end{cases}
$$

$$
\text{Value}_i =
\begin{cases}
\text{High}, & \text{CLV}_i > Q_{0.8}(\text{CLV}) \\
\text{Mid}, & Q_{0.2}(\text{CLV}) \le \text{CLV}_i \le Q_{0.8}(\text{CLV}) \\
\text{Low}, & \text{CLV}_i < Q_{0.2}(\text{CLV})
\end{cases}
$$

最後以三段文字組成客戶代碼：

$$
\text{RSV Key}_i = \text{Risk}_i-\text{Stability}_i-\text{Value}_i
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $\text{nrec}\\_\text{prob}_i$ | 流失機率，來自 [P(alive)](Term-P-alive) |
| $\text{cri}\\_\text{ecdf}_i$ | CRI 的分位位置，來自 [CRI](Term-CRI) |
| $\text{CLV}_i$ | 客戶終身價值，來自 [CLV](Term-CLV) |
| $Q_{0.2}(\text{CLV})$、$Q_{0.8}(\text{CLV})$ | 全體客戶 CLV 的第 20 與第 80 百分位 |

## 門檻值來源與意義

三個維度的分類門檻來自不同邏輯：

### Risk（風險）— 絕對門檻

使用 `nrec_prob`（流失機率）的**絕對數值** 0.3 和 0.7 作為切點。
這是 BG/NBD 模型的輸出，0 到 1 代表流失的機率，不需要跟其他客戶比較：

- `nrec_prob > 0.7`：超過七成機率流失 → High Risk
- `0.3 ≤ nrec_prob ≤ 0.7`：流失風險不確定 → Mid Risk
- `nrec_prob < 0.3`：不到三成機率流失 → Low Risk

### Stability（穩定性）— 相對門檻（ECDF 百分位）

使用 `cri_ecdf`（CRI 的經驗累積分布位置）的 0.33 和 0.67 作為切點。
CRI 越小表示購買節奏越規律，所以 ECDF 越低的人穩定性越高：

- `cri_ecdf < 0.33`：CRI 最低 1/3 → 節奏最規律 → High Stability
- `0.33 ≤ cri_ecdf ≤ 0.67`：中間 1/3 → Mid Stability
- `cri_ecdf > 0.67`：CRI 最高 1/3 → 節奏最不規律 → Low Stability

> Stability 是真正的「三等分」，把全體客戶依 CRI 百分位分成三份。

### Value（價值）— 相對門檻（CLV 百分位）

使用全體客戶 CLV 的第 20 和第 80 百分位作為切點：

- `CLV > P80`：前 20% → High Value
- `P20 ≤ CLV ≤ P80`：中間 60% → Mid Value
- `CLV < P20`：最後 20% → Low Value

> Value 用的是 20/60/20 的切法，和三等分不同。

### 為什麼三個維度的切法不一樣？

因為三個維度的意義不同：
- **Risk** 有客觀的機率解讀（0.7 就是七成機率），用絕對值最直觀
- **Stability** 沒有「幾分以上算穩定」的標準，用三等分讓分布均勻
- **Value** 關注兩端（高價值和低價值），用 20/80 百分位聚焦頭尾

## 範例

某位客戶的資料如下：

- $\text{nrec}\\_\text{prob} = 0.18$
- $\text{cri}\\_\text{ecdf} = 0.22$
- $\text{CLV}$ 高於全體第 80 百分位

因此：

- `Risk = Low`
- `Stability = High`
- `Value = High`

最後的 RSV 組合就是：

$$
\text{RSV Key} = \text{Low-High-High}
$$

這類客戶通常屬於值得重點經營的核心客群。

## 儀表板中的位置

- `TagPilot > rsvMatrix`：以矩陣方式看各類客戶分布與平均 CLV
- `TagPilot > marketingDecision`：根據 RSV 與其他條件給出策略
- `TagPilot > customerExport`：匯出時會帶出 `r_level`、`s_level`、`v_level`

## R 程式碼實作

### 程式碼摘錄

```r
# R (Risk) — 用流失機率的絕對門檻
df$r_level <- ifelse(
  is.na(df$nrec_prob), "Mid",
  ifelse(df$nrec_prob > 0.7, "High",
         ifelse(df$nrec_prob >= 0.3, "Mid", "Low")))

# S (Stability) — 用 CRI 百分位的三等分門檻
df$s_level <- ifelse(
  is.na(df$cri_ecdf), "Mid",
  ifelse(df$cri_ecdf < 0.33, "High",
         ifelse(df$cri_ecdf <= 0.67, "Mid", "Low")))

# V (Value) — 用 CLV 的動態百分位門檻
v_p20 <- quantile(clv_vals, 0.20, na.rm = TRUE)
v_p80 <- quantile(clv_vals, 0.80, na.rm = TRUE)
df$v_level <- ifelse(
  is.na(df$clv_value), "Mid",
  ifelse(df$clv_value > v_p80, "High",
         ifelse(df$clv_value >= v_p20, "Mid", "Low")))

# 組合成 RSV Key
df$rsv_key <- paste(df$r_level, df$s_level, df$v_level, sep = "-")
```

### 白話解讀

1. **Risk 用絕對數值切**：流失機率超過 0.7 就是高風險，低於 0.3 就是低風險，不需跟別人比
2. **Stability 用相對排名切**：把全體客戶依 CRI 百分位分成三份，最規律的 1/3 是高穩定
3. **Value 用動態門檻切**：每次執行時重新算全體客戶 CLV 的第 20 和第 80 百分位，前 20% 是高價值
4. **缺值一律歸 Mid**：如果某個指標算不出來（例如新客沒有足夠交易紀錄），系統預設放在中間層
5. **最後用短橫線串接**：三個層級文字組成像 `High-Mid-Low` 這樣的代碼，用來對應行銷策略

> **程式碼來源**：`10_rshinyapp_components/tagpilot/fn_rsv_classification.R`
