# module_rsv_matrix.R 模組說明文件

## 檔案資訊

- **檔案路徑**: `modules/module_rsv_matrix.R`
- **檔案大小**: 約 950 行
- **功能**: R/S/V 顧客生命力矩陣（風險-穩定-價值三維分析）
- **版本**: 3.0
- **最後更新**: 2025-12-03

---

## 模組概述

這是 **R/S/V 顧客生命力矩陣模組**，使用三個維度分析客戶：

| 維度 | 全名 | v3.0 主要變數 | Fallback 變數 |
|------|------|--------------|---------------|
| R | Risk（靜止風險）| `nrec_prob`（邏輯回歸預測流失機率）| `customer_dynamics` → `r_value` |
| S | Stability（交易穩定度）| `cri` / `cri_ecdf`（經驗貝氏 CRI）| `ni`（交易次數）|
| V | Value（終生價值）| `clv`（預測未來 10 年價值）| `total_spent` → `m_value * ni` |

提供 **27 種客戶類型**（3×3×3）與策略建議。

---

## RSV Framework v3.0 重大更新

### 變更摘要

| 項目 | v2.0（舊版）| v3.0（新版）|
|------|-------------|-------------|
| R (Risk) | `customer_dynamics` 映射 | `nrec_prob` 邏輯回歸預測 |
| S (Stability) | `ni` 交易次數 | `cri` / `cri_ecdf` 經驗貝氏 |
| V (Value) | `total_spent` 歷史總消費 | `clv` 預測 10 年價值 |
| 資料來源 | DNA 代理變數 | MAMBA `analysis_dna()` 真實變數 |

### 為什麼升級到 v3.0？

1. **MAMBA 已經計算 RSV 變數**：`analysis_dna()` 已經輸出 `nrec_prob`, `cri`, `clv`
2. **更精確的預測**：使用邏輯回歸和經驗貝氏方法
3. **前瞻性指標**：CLV 預測未來 10 年價值，而非僅看歷史消費

---

## 檔案結構

### 第一部分：UI 介面 (Lines 39-165)

| 區塊 | Lines | 說明 |
|------|-------|------|
| 狀態面板 | 40-44 | 顯示分析進度與 RSV 變數來源 |
| 關鍵指標卡片 | 46-84 | 高風險/高穩定/高價值客戶數 |
| R/S/V 分布圓餅圖 | 86-115 | 三個維度的分布 |
| R × S 熱力圖 | 128-135 | 風險 vs 穩定度矩陣 |
| 策略對應表 | 137-144 | 27 種客戶類型與策略 |
| 客戶明細表 | 146-164 | 含 R/S/V 標籤的客戶列表 |

---

### 第二部分：Server 邏輯 (Lines 170-800+)

---

## 📊 核心資料處理 (Lines 200-470)

### R (Risk) 靜止風險計算 (Lines 220-260)

**v3.0：優先使用 `nrec_prob`**

```r
# 優先使用 MAMBA 的 nrec_prob（邏輯回歸預測流失機率 0-1）
# nrec_prob > 0.7 → 高靜止戶（即將或已經流失）
# nrec_prob 0.3-0.7 → 中靜止戶（互動減少但仍有潛力）
# nrec_prob < 0.3 → 低靜止戶（穩定活躍群）

df_rsv <- df %>%
  mutate(
    # 保留原始 nrec_prob 用於顯示
    risk_prob = if ("nrec_prob" %in% names(.)) nrec_prob else NA_real_,

    r_level = if ("nrec_prob" %in% names(.) && !all(is.na(nrec_prob))) {
      # 使用 MAMBA 的 nrec_prob
      case_when(
        is.na(nrec_prob) ~ "中",
        nrec_prob > 0.7 ~ "高",   # 高流失風險
        nrec_prob > 0.3 ~ "中",   # 中流失風險
        TRUE ~ "低"               # 低流失風險
      )
    } else if ("customer_dynamics" %in% names(.)) {
      # Fallback 1: 使用 customer_dynamics
      case_when(
        customer_dynamics %in% c("dormant", "half_sleepy") ~ "高",
        customer_dynamics == "sleepy" ~ "中",
        customer_dynamics %in% c("active", "newbie") ~ "低",
        TRUE ~ "中"
      )
    } else {
      # Fallback 2: 使用 r_value 分位數
      r_p80 <- quantile(r_value, 0.8, na.rm = TRUE)
      r_p20 <- quantile(r_value, 0.2, na.rm = TRUE)
      case_when(
        r_value >= r_p80 ~ "高",
        r_value >= r_p20 ~ "中",
        TRUE ~ "低"
      )
    },

    tag_032_dormancy_risk = case_when(
      r_level == "高" ~ "高靜止戶",
      r_level == "中" ~ "中靜止戶",
      TRUE ~ "低靜止戶"
    )
  )
```

### S (Stability) 交易穩定度計算 (Lines 262-375)

**v3.0：優先使用 `cri` / `cri_ecdf`**

```r
# 優先使用 MAMBA 的 CRI（Customer Regularity Index）
# CRI 邏輯：cri 接近 0 = 高穩定, cri 接近 1 = 低穩定

df_rsv <- df %>%
  mutate(
    stability_metric = if ("cri" %in% names(.) && !all(is.na(cri))) {
      cri  # 使用 CRI
    } else {
      ni   # Fallback: 使用 ni
    },
    stability_source = if ("cri" %in% names(.) && !all(is.na(cri))) "cri" else "ni"
  )

# CRI-based 分群（使用 cri_ecdf）
if (use_cri) {
  if ("cri_ecdf" %in% names(df) && !all(is.na(df$cri_ecdf))) {
    # 使用 cri_ecdf（已是 0-1 的 ECDF 值）
    s_level = case_when(
      is.na(cri_ecdf) ~ "中",
      cri_ecdf < 0.33 ~ "高",  # CRI 較低 = 高穩定
      cri_ecdf < 0.67 ~ "中",
      TRUE ~ "低"              # CRI 較高 = 低穩定
    )
  } else {
    # 使用 cri 分位數
    cri_p33 <- quantile(stability_metric, 0.33)
    cri_p67 <- quantile(stability_metric, 0.67)
    s_level = case_when(
      stability_metric < cri_p33 ~ "高",  # CRI 較低 = 高穩定
      stability_metric < cri_p67 ~ "中",
      TRUE ~ "低"
    )
  }
} else {
  # ni-based fallback: higher ni = higher stability
  s_level = case_when(
    stability_metric >= s_p80 ~ "高",
    stability_metric >= s_p20 ~ "中",
    TRUE ~ "低"
  )
}

tag_033_transaction_stability = case_when(
  s_level == "高" ~ "高穩定",
  s_level == "中" ~ "中穩定",
  TRUE ~ "低穩定"
)
```

### V (Value) 終生價值計算 (Lines 376-458)

**v3.0：優先使用真實 `clv`**

```r
# 優先使用 MAMBA 的真實 CLV（預測未來 10 年價值）
# 只有在 clv 不存在時才使用 fallback

df_rsv <- df %>%
  mutate(
    clv_value = if ("clv" %in% names(.) && !all(is.na(clv))) {
      clv  # 使用 MAMBA 的真實 CLV
    } else if ("total_spent" %in% names(.)) {
      total_spent  # Fallback 1: 歷史總消費
    } else if ("m_value" %in% names(.) && "ni" %in% names(.)) {
      m_value * ni  # Fallback 2: AOV × 交易次數
    } else {
      m_value  # Last resort
    },
    value_source = if ("clv" %in% names(.) && !all(is.na(clv))) "clv" else "total_spent"
  )

# V level 分群（使用 P20/P80）
v_p20 <- quantile(clv_value, 0.2, na.rm = TRUE)
v_p80 <- quantile(clv_value, 0.8, na.rm = TRUE)

v_level = case_when(
  clv_value >= v_p80 ~ "高",
  clv_value >= v_p20 ~ "中",
  TRUE ~ "低"
)

tag_034_customer_lifetime_value = case_when(
  v_level == "高" ~ "高價值",
  v_level == "中" ~ "中價值",
  TRUE ~ "低價值"
)
```

### 組合客戶類型 (Lines 460-470)

```r
# 組合 R/S/V 產生 rsv_key
rsv_key = paste0(r_level, s_level, v_level)  # 如 "低高高"

# 映射到客戶類型和策略
customer_type = get_customer_type(rsv_key)   # 如 "💎 金鑽客"
strategy = get_strategy_text(rsv_key)
action = get_action_text(rsv_key)
```

---

## 📊 狀態訊息輸出 (Lines 502-542)

**v3.0 新增：顯示 RSV 變數來源**

```r
output$status <- renderText({
  # 偵測使用的 RSV 變數來源
  r_source <- if ("risk_prob" %in% names(df) && !all(is.na(df$risk_prob))) {
    "nrec_prob (邏輯回歸預測)"
  } else if ("customer_dynamics" %in% names(df)) {
    "customer_dynamics (DNA 分析)"
  } else {
    "r_value (分位數)"
  }

  s_source <- if (df$stability_source[1] == "cri") {
    "cri (經驗貝氏 CRI)"
  } else {
    "ni (交易次數)"
  }

  v_source <- if (df$value_source[1] == "clv") {
    "clv (預測 10 年價值)"
  } else {
    "total_spent (歷史總消費)"
  }

  paste0(
    "✅ RSV 生命力矩陣 v3.0 計算完成\n",
    "總客戶數：", n_total, " 人\n",
    "客戶類型數：", n_types, " 種\n",
    "━━━━━━━━━━━━━━━━━━━━━━━━\n",
    "📊 RSV 變數來源：\n",
    "  R (風險): ", r_source, "\n",
    "  S (穩定): ", s_source, "\n",
    "  V (價值): ", v_source
  )
})
```

---

## 📈 關鍵指標輸出 (Lines 544-600)

```r
# 高風險客戶數
high_risk_count = sum(r_level == "高")
high_risk_pct = high_risk_count / nrow(df) * 100

# 高穩定客戶數
high_stability_count = sum(s_level == "高")

# 高價值客戶數
high_value_count = sum(v_level == "高")
```

---

## 🎯 策略定義函數 (Lines 800+)

### 核心 9 種客戶分類

| rsv_key | 客戶類型 | 策略 | 行動方案 |
|---------|----------|------|----------|
| 低高高 | 💎 金鑽客 | VIP 體驗 + 品牌共創 | 專屬客服/新品搶先體驗/會員大使 |
| 低高中 | 🌱 成長型忠誠客 | 升級誘因 | 搭售組合、滿額升級、會員積分任務 |
| 中中高 | ⚠️ 預警高值客 | 早期挽回 | 回購提醒、VIP 喚醒禮、定向廣告 |
| 高低高 | 💔 流失高值客 | 挽回行銷 | 再行銷廣告、專屬優惠、客服致電 |
| 高低低 | 💤 沉睡客 | 低成本回流 | 廣告再曝光 + 再註冊誘因 |
| 中中中 | 📊 潛力客群 | 分群培育 | 推薦新品、品牌故事、任務制獎勵 |
| 低低低 | 👁️ 邊緣客/觀望客 | 輕促銷策略 | 試用/入門優惠券/聯合活動 |
| 中高高 | 💡 沉靜貴客 | 情感維繫 | 品牌關懷訊息、生日禮、活動邀請 |
| 高高中 | ⚠️ 風險主力客 | 挽留提醒 | 優惠截止倒數、客服問候 |

---

## 關鍵設計特點

### 1. 三維分析框架

```
R (風險) × S (穩定) × V (價值) = 27 種組合

低/中/高 × 低/中/高 × 低/中/高 = 3³ = 27
```

### 2. v3.0 優先使用 MAMBA 真實變數

| 維度 | MAMBA 變數 | 計算方法 | Fallback |
|------|------------|----------|----------|
| R | `nrec_prob` | 邏輯回歸預測流失機率 | `customer_dynamics` → `r_value` |
| S | `cri` / `cri_ecdf` | 經驗貝氏收縮估計 | `ni` |
| V | `clv` | PIF 函數預測 10 年價值 | `total_spent` |

### 3. 智能 Fallback 機制

當 MAMBA 變數不存在時自動使用 fallback：

```r
# R: nrec_prob → customer_dynamics → r_value
# S: cri/cri_ecdf → ni
# V: clv → total_spent → m_value * ni
```

### 4. 狀態面板顯示變數來源

讓使用者清楚知道目前使用的是 MAMBA 真實變數還是 fallback。

---

## 與其他模組的關係

### 資料來源

- **接收**：`customer_data()`（來自上游 DNA 模組）
- **包含**：`analysis_dna()` 輸出的完整 RSV 變數

### 依賴欄位（v3.0 優先順序）

| 欄位 | 說明 | 優先級 |
|------|------|--------|
| `nrec_prob` | 流失機率（0-1）| R 首選 |
| `customer_dynamics` | 顧客動態分類 | R Fallback 1 |
| `r_value` | 最近購買天數 | R Fallback 2 |
| `cri` | Customer Regularity Index | S 首選 |
| `cri_ecdf` | CRI 的 ECDF 值 | S 輔助 |
| `ni` | 購買次數 | S Fallback |
| `clv` | 預測終身價值 | V 首選 |
| `total_spent` | 歷史總消費 | V Fallback 1 |
| `m_value` | 平均客單價 | V Fallback 2 |

### 輸出標籤

| 標籤 | 說明 |
|------|------|
| `tag_032_dormancy_risk` | 靜止風險（高/中/低靜止戶）|
| `tag_033_transaction_stability` | 交易穩定度（高/中/低穩定）|
| `tag_034_customer_lifetime_value` | 終生價值（高/中/低價值）|
| `risk_prob` | 原始 nrec_prob 值（用於顯示）|
| `stability_source` | 穩定度變數來源（cri/ni）|
| `value_source` | 價值變數來源（clv/total_spent）|

---

## 版本歷史

| 版本 | 日期 | 變更內容 |
|------|------|----------|
| 3.0 | 2025-12-03 | **重大更新**：使用 MAMBA 真實 RSV 變數（nrec_prob, cri, clv）|
| 2.0 | 2025-12-03 | 使用 DNA 代理變數（customer_dynamics, ni, total_spent）|
| 1.1 | 2025-11 | 修正 CLV 計算、下載欄位處理 |
| 1.0 | 2025-10 | 初始版本 |
