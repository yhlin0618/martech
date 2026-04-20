# DNA Segments — 客戶 DNA 分段代碼

## 定義

DNA Segments 是把客戶在金額、頻率、近期性三個比較分數切成代碼，最後組成像 `M3F2R4` 這樣的短碼。
它的用途是讓系統可以快速分群、排序和比對，而不是要你只看代碼本身就下判斷。

## 數學公式

系統先建立三個比較分數：

$$
\text{dna}\\_\text{m}\\_\text{score}_i = m_{\text{ecdf},i}
$$

$$
\text{dna}\\_\text{f}\\_\text{score}_i = f_{\text{ecdf},i}
$$

$$
\text{dna}\\_\text{r}\\_\text{score}_i = 1 - r_{\text{ecdf},i}
$$

再依切點轉成代碼：

$$
M_i =
\begin{cases}
\text{M4}, & \text{dna}\\_\text{m}\\_\text{score}_i \ge 0.75 \\
\text{M3}, & \text{dna}\\_\text{m}\\_\text{score}_i \ge 0.50 \\
\text{M2}, & \text{dna}\\_\text{m}\\_\text{score}_i \ge 0.25 \\
\text{M1}, & \text{otherwise}
\end{cases}
$$

$$
F_i =
\begin{cases}
\text{F3}, & \text{dna}\\_\text{f}\\_\text{score}_i \ge 0.67 \\
\text{F2}, & \text{dna}\\_\text{f}\\_\text{score}_i \ge 0.33 \\
\text{F1}, & \text{otherwise}
\end{cases}
$$

$$
R_i =
\begin{cases}
\text{R4}, & \text{dna}\\_\text{r}\\_\text{score}_i \ge 0.75 \\
\text{R3}, & \text{dna}\\_\text{r}\\_\text{score}_i \ge 0.50 \\
\text{R2}, & \text{dna}\\_\text{r}\\_\text{score}_i \ge 0.25 \\
\text{R1}, & \text{otherwise}
\end{cases}
$$

最後：

$$
\text{DNA Segment}_i = M_iF_iR_i
$$

## 變數說明

| 變數 | 意義 |
|------|------|
| $m_{\text{ecdf}}$ | 金額在全體中的相對位置 |
| $f_{\text{ecdf}}$ | 頻率在全體中的相對位置 |
| $r_{\text{ecdf}}$ | Recency 在全體中的相對位置 |
| `M1` 到 `M4` | 金額分段代碼 |
| `F1` 到 `F3` | 頻率分段代碼 |
| `R1` 到 `R4` | 近期性分段代碼 |

## 範例

如果某位客戶的三個比較分數是：

- $\text{dna}\\_\text{m}\\_\text{score} = 0.62$
- $\text{dna}\\_\text{f}\\_\text{score} = 0.41$
- $\text{dna}\\_\text{r}\\_\text{score} = 0.82$

那麼系統會把他分成：

- $M = \text{M3}$
- $F = \text{F2}$
- $R = \text{R4}$

最後 DNA 短碼就是 `M3F2R4`。
如果你要理解這個代碼代表的商業意義，建議同時搭配 [[RFM|Term-RFM]] 的數值與分布圖一起看。

## 儀表板中的位置

- `TagPilot > customerValue`：以 R、F、M 分布與分段圖呈現 DNA 的基礎
- 目前主介面通常先讓你看 R、F、M 分段，不一定每頁都直接顯示 `M3F2R4` 這類短碼

## R 程式碼實作

### 程式碼摘錄

```r
m_segment <- dplyr::case_when(
  is.na(df$dna_m_score) ~ NA_character_,
  df$dna_m_score >= 0.75 ~ "M4",
  df$dna_m_score >= 0.50 ~ "M3",
  df$dna_m_score >= 0.25 ~ "M2",
  TRUE ~ "M1"
)

f_segment <- dplyr::case_when(
  is.na(df$dna_f_score) ~ NA_character_,
  df$dna_f_score >= 0.67 ~ "F3",
  df$dna_f_score >= 0.33 ~ "F2",
  TRUE ~ "F1"
)

r_segment <- dplyr::case_when(
  is.na(df$dna_r_score) ~ NA_character_,
  df$dna_r_score >= 0.75 ~ "R4",
  df$dna_r_score >= 0.50 ~ "R3",
  df$dna_r_score >= 0.25 ~ "R2",
  TRUE ~ "R1"
)

df$dna_segment <- paste0(m_segment, f_segment, r_segment)
```

### 白話解讀

1. **M（金額）分四段**：以 0.25 為間距，M1 是花最少的 25%、M4 是花最多的前 25%
2. **F（頻率）分三段**：以 0.33/0.67 為切點，F1 買最少次、F3 買最多次
3. **R（近期性）分四段**：跟 M 一樣用 0.25 間距，R4 代表最近才買過、R1 代表很久沒買
4. **缺值保留 NA**：如果某客戶連基本分數都沒有（例如資料不足），段碼不會硬塞一個值
5. **三段碼直接拼接**：`paste0` 把 M、F、R 三個代碼接在一起，形成像 `M3F2R4` 的短碼

> **程式碼來源**：`16_derivations/fn_D01_02_core.R`（`ensure_dna_fields()` 函數）
