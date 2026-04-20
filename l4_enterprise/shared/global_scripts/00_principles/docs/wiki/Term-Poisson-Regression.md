# Poisson Regression — Poisson 回歸、IRR 與賽道倍數

## 定義

Poisson Regression 是用來分析「銷量這類計數資料」的模型。
在 InsightForge 360 裡，它主要回答三種問題：

- 哪些評論面向會推高或拉低銷量
- 哪些時間因素會影響表現
- 哪些產品特徵值得優先改善

## 數學公式

Poisson 回歸的基本型式為：

$$
\log(E[Y_i]) = \beta_0 + \sum_j \beta_j x_{ij}
$$

系統會把係數轉成較好理解的發生率比：

$$
\text{IRR}_j = e^{\beta_j}
$$

在 `poissonFeature` 與 `poissonComment` 頁，若有係數 $\beta$，系統另外會計算：

$$
\text{Marginal Effect} = (e^\beta - 1)\times 100
$$

若 $|\beta| > 5$，則邊際效果會被限制在 $\pm 500\%$ 內。
賽道倍數則依屬性範圍動態計算：

$$
\text{Track Multiplier} =
\min \left(
100,
\begin{cases}
e^2 \left(1 + 0.5(|\beta|-2)\right), & |\beta| > 2 \\
\exp \left(|\beta| \sqrt{\min(\text{range},10)}\right), & |\beta| \le 2
\end{cases}
\right)
$$

若資料只有 IRR 沒有係數，系統改用：

$$
\text{Marginal Effect} = \min \left(500,\max \left(-90,(\text{IRR}-1)\times 100\right)\right)
$$

$$
\text{Track Multiplier} = \min \left(100,\text{IRR}^{\sqrt{\text{range}}}\right)
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $Y_i$ | 第 $i$ 筆觀察的銷量或計數結果 |
| $x_{ij}$ | 第 $j$ 個解釋變數，例如評分、特徵或時間因子 |
| $\beta_j$ | 第 $j$ 個變數的回歸係數 |
| $\text{IRR}$ | 發生率比，大於 1 代表正向，小於 1 代表負向 |
| `range` | 該屬性在系統中採用的實際或推定範圍 |

## 範例

假設某個產品特徵的係數為 $\beta = 0.4$，屬性範圍為 4：

$$
\text{IRR} = e^{0.4} \approx 1.49
$$

$$
\text{Marginal Effect} = (e^{0.4}-1)\times 100 \approx 49.2\%
$$

$$
\text{Track Multiplier} = \exp(0.4\times \sqrt{4}) = e^{0.8} \approx 2.2
$$

意思是這個特徵每提升 1 單位，銷量平均可增加約 49%；從低到高整段拉開時，銷量可能相差約 2.2 倍。

## 儀表板中的位置

- `InsightForge 360 > poissonTime`：重點看 `IRR`、顯著性與時間模式
- `InsightForge 360 > poissonComment`：重點看評論面向的邊際效果與賽道倍數
- `InsightForge 360 > poissonFeature`：重點看產品特徵的邊際效果與賽道倍數

## R 程式碼實作

### 程式碼摘錄

```r
# 從回歸係數算出 IRR 與信賴區間
df$incidence_rate_ratio <- exp(df$coefficient)
df$conf_low  <- df$coefficient - 1.96 * df$std_error
df$conf_high <- df$coefficient + 1.96 * df$std_error
df$irr_conf_low  <- exp(df$conf_low)
df$irr_conf_high <- exp(df$conf_high)

# 邊際效果（百分比變化）
df$marginal_effect <- ifelse(
  abs(df$coefficient) > 5,
  sign(df$coefficient) * 500,
  (exp(df$coefficient) - 1) * 100
)

# 賽道倍數（Track Multiplier）
# 定義在 schema: track_multiplier = 100 / predictor_range
```

### 白話解讀

1. **IRR 是「倍率」**：`exp(coefficient)` 把回歸係數轉成直觀的倍數，IRR = 1.5 代表該因素每增加 1 單位，銷量平均增 50%
2. **信賴區間用 95%**：係數加減 1.96 倍標準誤，再 exp 轉換，就是 IRR 的可信範圍
3. **邊際效果有上限**：如果係數絕對值超過 5，效果會被限制在 ±500%，避免極端數字誤導
4. **賽道倍數看整段落差**：它衡量的是某個屬性「從最低拉到最高」時，銷量整體可能差幾倍
5. **沒有係數時用 IRR 反推**：如果資料只有 IRR 欄位（例如外部匯入），系統會用 `(IRR - 1) × 100` 反算邊際效果

> **程式碼來源**：`docs/en/part2_implementations/CH10_database_specifications/etl_schemas/r_definitions/SCHEMA_001_poisson_analysis.R`（`prepare_poisson_analysis_data()` 函數）
