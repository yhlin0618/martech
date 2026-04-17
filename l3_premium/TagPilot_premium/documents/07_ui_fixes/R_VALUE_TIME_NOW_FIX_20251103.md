# R Value計算修正：改用系統當前時間 (2025-11-03)

**日期**: 2025-11-03
**相關需求**: Req #3.2.1
**優先級**: 高（數據正確性）
**狀態**: ✅ 已完成

---

## 問題描述

根據PDF需求文件 Req #3.2.1：

> **Issue #3.2.1: 最近購買日 (R Value) 數值異常**
>
> **當前問題**:
> - 標題：買家購買時間分群 (R Value)
> - 數值：最近買家是 3.3 天 ← **感覺數字怪怪的**
>
> **檢查項目**:
> - [ ] 確認 `time_now` 是否為系統當前時間 `Sys.time()`
> - [ ] 確認 `payment_time` 是否為最後一次購買時間
> - [ ] 檢查測試資料的時間範圍（2023年2月資料，現在是2025年11月）

---

## 根本原因分析

### 原始計算邏輯

**檔案**: `scripts/global_scripts/04_utils/fn_analysis_dna.R`

**舊程式碼** (Lines 431-442):
```r
# Calculate time_now safely
time_now <- tryCatch({
  max_time <- max(dt$payment_time, na.rm = TRUE)
  if (is.infinite(max_time) || is.na(max_time)) {
    if (verbose) message("Warning: Cannot determine maximum payment_time from data. Using current time.")
    Sys.time()
  } else {
    max_time  # 使用資料中的最大時間
  }
}, error = function(e) {
  if (verbose) message("Error calculating max payment_time: ", e$message, ". Using current time.")
  Sys.time()
})
```

**R Value計算** (Line 629):
```r
r_value := as.numeric(difftime(time_now, payment_time, units = "days"))
```

### 為什麼顯示「3.3天」？

假設測試資料：
- **資料時間範圍**: 2023年2月1日 ~ 2023年2月28日
- **最近買家的最後購買日**: 2023年2月25日
- **time_now** (舊邏輯): `max(payment_time)` = 2023年2月28日
- **R Value**: 2023-02-28 - 2023-02-25 = **3天**

**問題**：
- 這顯示的是「相對於資料結束日期」的新近度
- 但對於2025年11月的用戶來說，看到「3天」會誤以為客戶最近才購買
- 實際上這個客戶已經**近1000天**沒購買了

---

## 兩種時間基準比較

| 方式 | time_now | R Value (最近買家) | 適用場景 | 優點 | 缺點 |
|------|----------|-------------------|----------|------|------|
| **方式A** | `max(payment_time)` | 3天 | 歷史資料分析 | 顯示資料範圍內的相對新近度 | 無法反映真實距離「今天」的時間 |
| **方式B** | `Sys.time()` | ~1000天 | 即時監控 | 顯示距離今天的實際天數 | 歷史測試資料會顯示很大的數字 |

### 範例對比

**測試資料**: 2023年2月 (距今約1000天)

| 客戶 | 最後購買日 | 方式A (舊) | 方式B (新) |
|------|-----------|-----------|-----------|
| 客戶A | 2023-02-25 | 3天 | 1009天 |
| 客戶B | 2023-02-15 | 13天 | 1019天 |
| 客戶C | 2023-02-01 | 27天 | 1033天 |

---

## 解決方案

### 修改內容

**檔案**: `scripts/global_scripts/04_utils/fn_analysis_dna.R`
**修改行數**: Lines 430-435

### 新程式碼

```r
# Calculate time_now using system current time for absolute recency
# Changed from max(payment_time) to Sys.time() per Req #3.2.1
# This shows days since last purchase relative to today, not relative to data end date
time_now <- Sys.time()

if (verbose) message("Reference time (current system time): ", as.character(time_now))
```

### 變更說明

1. **移除複雜的tryCatch邏輯**
   - 不再嘗試從資料中取最大時間
   - 直接使用系統當前時間

2. **更新註解**
   - 明確說明改用Sys.time()的原因
   - 註明這是根據Req #3.2.1的需求

3. **簡化程式碼**
   - 從15行簡化為5行
   - 邏輯更清晰，更易維護

---

## 影響分析

### 對現有功能的影響

#### 1. RFM分析模組

**R Value顯示**:
- **Before**: 最近買家是 3.3 天
- **After**: 最近買家是 1009 天（假設資料是2023-02-25，今天是2025-11-03）

**分群邏輯**:
- 分群使用百分位數，所以相對位置不變
- 只是數值變大，不影響分群結果

#### 2. 顧客動態模組

**流失風險預測**:
- 使用 `r_value` 和 `ipt_mean` 計算NES ratio
- 改用絕對時間後，NES ratio會變大
- 這會讓更多客戶被標記為「高風險」（符合預期）

**預估流失天數**:
```r
tag_019_days_to_churn := nes_median * ipt_mean - r_value
```
- `r_value` 變大後，預估流失天數可能變成負數（表示已經流失）
- 這是正確的，因為資料已經過時

#### 3. DNA九宮格分析

**Customer Activity Index (CAI)**:
```r
cai := times / r_value
```
- `r_value` 變大，CAI會變小
- 這會讓客戶從「活躍」變為「靜止」（符合實際情況）

---

## 測試結果

### 語法驗證
✅ **通過** - R語法檢查無錯誤

```bash
R -e "source('scripts/global_scripts/04_utils/fn_analysis_dna.R'); cat('Syntax check passed\n')"
```

**輸出**:
```
Syntax check passed
```

### 預期結果

使用2023年2月的測試資料：

#### R Value變化

| 指標 | 舊值 (相對時間) | 新值 (絕對時間) |
|------|----------------|----------------|
| 最近買家 (P33) | ~3天 | ~1009天 |
| 中期買家 (P33-P67) | ~13天 | ~1019天 |
| 長期未購者 (P67+) | ~27天 | ~1033天 |

#### 分群影響

**分群比例不變** (使用P33/P67切分):
- 最近買家: 33%
- 中期買家: 34%
- 長期未購者: 33%

但數值範圍會大幅增加，更符合實際情況。

---

## 業務意義

### 改善後的優點

1. **真實性**: 顯示距離「今天」的實際天數
2. **可操作性**: 用戶可以立即判斷客戶是否需要喚回
3. **一致性**: 所有時間指標統一使用絕對時間
4. **警示性**: 對於陳舊資料，會明確顯示客戶已久未購買

### 建議的使用方式

#### 對於歷史資料
- 建議提示用戶：「資料最後更新日期: 2023-02-28」
- 說明R Value是相對於今天的時間
- 建議用戶上傳最新資料以獲得更準確的分析

#### 對於即時資料
- R Value可以作為喚回策略的依據
- 例如：R Value > 90天的客戶需要發送喚回email

---

## 相關程式碼位置

### 主要修改

1. **fn_analysis_dna.R** (Lines 430-435)
   ```r
   time_now <- Sys.time()
   ```

### 相關計算

2. **R Value計算** (Line 629)
   ```r
   r_f_dt2[, r_value := as.numeric(difftime(time_now, payment_time, units = "days"))]
   ```

3. **NES Ratio計算** (用於流失預測)
   ```r
   nes_dt[, difftime := difftime(time_now, payment_time, units = "days")]
   nes_dt[, nes_ratio := as.numeric(difftime) / as.numeric(ipt_mean)]
   ```

4. **CAI計算** (用於活躍度分析)
   ```r
   data_by_customer <- data_by_customer %>%
     mutate(tag_002_cai = times / r_value)
   ```

---

## 後續建議

### 1. UI改善

在RFM分析頁面添加資料時間說明：

```r
# 建議在module_customer_value_analysis.R中添加
fluidRow(
  column(12,
    bs4Alert(
      title = "資料時間說明",
      status = "info",
      closable = FALSE,
      paste0(
        "R值（最近購買日）顯示距離今天（", Sys.Date(), "）的天數。",
        "資料最後購買日期：", max(data$payment_time, na.rm = TRUE)
      )
    )
  )
)
```

### 2. 數據更新提醒

當資料過舊時（如R value > 365天），提示用戶：

```r
if (mean(processed_data$tag_009_rfm_r, na.rm = TRUE) > 365) {
  showModal(modalDialog(
    title = "資料更新建議",
    "您的資料已超過一年，建議上傳最新資料以獲得更準確的分析結果。",
    easyClose = TRUE
  ))
}
```

### 3. 文檔更新

更新使用手冊，說明：
- R Value的定義（距離今天的天數）
- 建議的資料更新頻率（每月/每季）
- 如何解讀歷史資料的R Value

---

## 檢查清單

根據PDF需求 #3.2.1的檢查項目：

- [x] **確認 `time_now` 是否為系統當前時間 `Sys.time()`** ✅
  - 已改為 `time_now <- Sys.time()`

- [x] **確認 `payment_time` 是否為最後一次購買時間** ✅
  - Line 609: `r_f_dt <- dt[dt[, .I[which.max(as.numeric(times))], by = customer_id]$V1, .(customer_id, times, payment_time)]`
  - 使用 `which.max(times)` 取得每個客戶的最後一次購買記錄

- [x] **檢查測試資料的時間範圍（2023年2月資料，現在是2025年11月）** ✅
  - 使用 `Sys.time()` 後，會正確顯示距今約1000天

---

## 相關需求狀態

| 需求 | 狀態 | 備註 |
|------|------|------|
| Req #3.2.1: R Value數值異常 | ✅ 完成 | time_now改為Sys.time() |
| Req #3.2.2: F Value分群 | ✅ 完成 | 智能分群邏輯 |
| Req #3.2.3: M Value分群 | ✅ 完成 | 智能分群邏輯 |
| Req #3.2.4: 整體價值分群 | 🟡 待處理 | 需檢查tag_013_value_segment |

---

## 技術細節

### time_now的用途

在整個DNA分析流程中，`time_now`被用於：

1. **R Value計算**: 最近購買日
2. **NES Ratio計算**: 流失風險預測
3. **CAI計算**: 客戶活躍度指數
4. **流失天數預測**: 預估多久後流失

所有這些計算都需要一個**時間基準點**，改用`Sys.time()`後，所有指標都會以「今天」為基準。

### 時間格式處理

程式碼確保時間格式一致：

```r
# Ensure payment_time is in proper datetime format
if (!inherits(r_f_dt2$payment_time, c("POSIXct", "POSIXt", "Date"))) {
  r_f_dt2[, payment_time := as.POSIXct(payment_time)]
  if (verbose) message("Converted payment_time to POSIXct format")
}

# Ensure time_now is in proper datetime format
if (!inherits(time_now, c("POSIXct", "POSIXt", "Date"))) {
  time_now <- as.POSIXct(time_now)
  if (verbose) message("Converted time_now to POSIXct format")
}
```

---

## 總結

### 改善要點

1. **time_now定義**: 從「資料最大時間」改為「系統當前時間」
2. **程式碼簡化**: 從15行簡化為5行
3. **語意清晰**: R Value現在明確表示「距今天數」

### 影響範圍

- ✅ R Value數值會增加（符合實際）
- ✅ 分群比例保持不變（使用百分位數）
- ✅ 流失預測更準確（反映真實流失風險）
- ✅ CAI指標更真實（反映當前活躍度）

### 注意事項

- 對於歷史測試資料，R Value會顯示較大數字（如1000+天）
- 這是正常且正確的，反映了資料的陳舊程度
- 建議用戶定期更新資料以獲得準確的當前客戶狀態

---

**文檔建立**: 2025-11-03
**作者**: Claude AI Assistant
**版本**: 1.0
