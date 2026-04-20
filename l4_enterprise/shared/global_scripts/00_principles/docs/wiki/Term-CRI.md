# CRI — Customer Regularity Index（客戶規律性指數）

## 定義

CRI 用來衡量客戶的購買節奏有多穩定。
數值越低，代表這位客戶的購買週期越規律；數值越高，代表購買時間較跳動、不容易預測。

## 數學公式

系統先在全體客戶上計算：

$$
\alpha = \text{mean}(n_i)
$$

$$
\theta = \frac{\sum_i \left(\frac{1}{\text{IPT}_i}\right)}{\alpha N}
$$

$$
\text{GE} = \frac{1}{(\alpha - 1)\theta}
$$

再對單一客戶 $i$ 計算：

$$
\text{BE}_i =
\frac{n_i}{n_i + \alpha - 1}\text{IPT}_i +
\frac{\alpha - 1}{n_i + \alpha - 1}\text{GE}
$$

$$
\text{CRI}_i = \frac{|\text{IPT}_i - \text{BE}_i|}{|\text{IPT}_i - \text{GE}|}
$$

系統另外會把 CRI 轉成分位值，供 [[RSV|Term-RSV]] 使用：

$$
\text{cri}\\_\text{ecdf}_i = \text{ECDF}(\text{CRI}_i)
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $n_i$ | 客戶 $i$ 的購買次數 |
| $\text{IPT}_i$ | 客戶 $i$ 的平均購買間隔 |
| $N$ | 可計算 CRI 的客戶總數 |
| $\alpha$、$\theta$ | 系統用來估計整體規律性的參數 |
| $\text{GE}$ | 全體客戶的整體期望間隔 |
| $\text{BE}_i$ | 針對客戶 $i$ 的 Bayes 期望間隔 |
| $\text{cri}\\_\text{ecdf}_i$ | CRI 在全體中的相對位置 |

## 範例

假設某位客戶：

- $n_i = 8$
- $\text{IPT}_i = 40$
- $\alpha = 5$
- $\text{GE} = 50$

則：

$$
\text{BE}_i =
\frac{8}{12}\times 40 + \frac{4}{12}\times 50
= 43.3
$$

$$
\text{CRI}_i = \frac{|40 - 43.3|}{|40 - 50|} \approx 0.33
$$

這代表這位客戶的購買節奏相對穩定，不算特別飄忽。

## R 程式碼實作

以下是系統實際的計算邏輯（摘自 `04_utils/fn_analysis_dna.R`）：

```r
# --- 全體參數 ---
alpha <- mean(cri_dt$ni)                          # 全體平均購買次數
theta <- sum(1 / cri_dt$ipt) / (alpha * nrow(cri_dt))  # 全體購買率參數
GE    <- 1 / ((alpha - 1) * theta)                # Global Expected Interval

# --- 單一客戶的 Bayes 估計 ---
cri_dt[, BE := (ni / (ni + alpha - 1)) * ipt +
               ((alpha - 1) / (ni + alpha - 1)) * GE]

# --- CRI 計算 ---
cri_dt[, cri := abs(ipt - BE) / abs(ipt - GE)]

# --- ECDF 排名（供 RSV 使用） ---
cri_dt[, cri_ecdf := ecdf(cri)(cri)]
```

**白話解讀**：
- `GE` 是「全體客戶的整體期望間隔」，代表如果不知道某客戶的個別購買習慣，系統會預測他的購買間隔是多少。
- `BE` 是針對個別客戶的 Bayes 估計：結合該客戶自己的 IPT（有多少個人觀察值）和 GE（整體預期），用購買次數當權重做加權平均。購買次數越多，`BE` 越靠近個人 IPT；購買次數越少，越靠近全體 GE。
- `CRI` 衡量的是「個人 IPT 偏離自己 Bayes 估計的程度」相對於「偏離全體預期的程度」。CRI 越低代表越規律。

> 對應程式碼位置：`04_utils/fn_analysis_dna.R`

## 儀表板中的位置

- `TagPilot > customerStructure`：CRI 的分布與建議
- `VitalSigns > revenuePulse`：整體平均 CRI
- `TagPilot > rsvMatrix`、`TagPilot > marketingDecision`：`cri_ecdf` 會決定 `Stability` 層級
