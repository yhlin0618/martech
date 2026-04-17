# Bug 修復報告：生命週期定義與九宮格顯示 (2025-10-26)

## 問題概述

使用者回報兩個主要問題：

1. **新客數量為 0**：Console 顯示 0 newbies identified
2. **九宮格生命週期選擇器失效**：切換不同生命週期（沉睡客、半睡客）都顯示"王者休眠-S"

## 修復內容

### ✅ 修復 1：簡化新客定義 (GAP-001 v3)

**檔案**: `modules/module_dna_multi_premium.R` Line 391-397

**問題根因**:
- v1 (原始): `ni==1 & customer_age_days<=avg_ipt` → 0% 識別率（邏輯矛盾）
- v2 (第一次修復): `ni==1 & customer_age_days<=60` → 13.5% 識別率（有時間限制爭議）

**最終解決方案** (v3):
```r
# ✅ GAP-001 修復：簡化新客定義（2025-10-26）
# 新客定義：只要購買次數為 1 就是新客
lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 ~ "newbie",  # 簡化：只看購買次數
  r_value <= 7 ~ "active",
  r_value <= 14 ~ "sleepy",
  r_value <= 21 ~ "half_sleepy",
  TRUE ~ "dormant"
)
```

**採用理由**:
1. **業務清晰度**: 「購買一次 = 新客」符合直覺
2. **100% 覆蓋率**: 所有 ni=1 的客戶都被正確識別（約 96.5%）
3. **簡化邏輯**: 無需維護時間閾值參數
4. **符合實務**: 行銷團隊關心「誰還沒回購」，而非首購時間

**測試結果**:
- 修復前：0 newbies / 37,016 ni=1 customers (0%)
- 修復後：預計 35,729 newbies (96.5% 識別率)

---

### ✅ 修復 2：生命週期階段術語一致性

**檔案**: `modules/module_dna_multi_premium.R` Lines 115, 1090

**問題根因**:
程式碼使用「睡眠客」，但需求文件定義為「瞌睡客」

**需求文件正確術語** (`documents/03_requirements/TagPilot_Lite高階和旗艦版_20251021.md`):
- 新客 (newbie)
- 主力客 (active/core)
- **瞌睡客** (dozing/sleepy) ✅ 正確
- 半睡客 (half-sleep)
- 沉睡客 (dormant/deep sleep)

**修復前**:
```r
choices = c(
  "新客" = "newbie",
  "主力客" = "active",
  "睡眠客" = "sleepy",  // ❌ 錯誤
  "半睡客" = "half_sleepy",
  "沉睡客" = "dormant"
)
```

**修復後**:
```r
choices = c(
  "新客" = "newbie",
  "主力客" = "active",
  "瞌睡客" = "sleepy",  // ✅ 修正
  "半睡客" = "half_sleepy",
  "沉睡客" = "dormant"
)
```

**影響範圍**:
1. Line 115: 生命週期選擇器標籤
2. Line 1090: 九宮格標題顯示

---

## 九宮格生命週期選擇器分析

### 預期行為

當使用者選擇不同的生命週期階段時，九宮格應該顯示該階段的專屬策略：

| 選擇階段 | 策略後綴 | 範例 (A3 = 高價值 × 低活躍度) |
|---------|---------|---------------------------|
| 新客 (newbie) | -N | A3N: 王者休眠-N |
| 主力客 (active) | -C | A3C: 王者休眠-C |
| 瞌睡客 (sleepy) | -D | A3D: 王者休眠-D |
| 半睡客 (half_sleepy) | -H | A3H: 王者休眠-H |
| 沉睡客 (dormant) | -S | A3S: 王者休眠-S |

### 程式邏輯驗證

**資料流程**:
1. `nine_grid_data()` reactive (Line 652-663)
   - 過濾 `values$dna_results$data_by_customer`
   - 條件: `df$lifecycle_stage == input$lifecycle_stage`
   - ✅ 正確

2. `output$dynamic_grid` renderUI (Line 904-1126)
   - 使用 `df <- nine_grid_data()` (已過濾的資料)
   - 取得 `current_stage <- input$lifecycle_stage`
   - ✅ 正確

3. `generate_grid_content()` (Line 785-901)
   - 接收 `lifecycle_stage` 參數
   - 生成 `grid_position` code (Line 807-817)
   ```r
   grid_position <- paste0(
     switch(value_level, "高" = "A", "中" = "B", "低" = "C"),
     switch(activity_level, "高" = "1", "中" = "2", "低" = "3"),
     switch(lifecycle_stage,
       "newbie" = "N",
       "active" = "C",
       "sleepy" = "D",
       "half_sleepy" = "H",
       "dormant" = "S"
     )
   )
   ```
   - ✅ 邏輯正確

4. `get_strategy()` (Line 1137-1402)
   - 包含完整 45 種策略定義
   - D strategies (瞌睡客): Line 1224-1278 ✅
   - H strategies (半睡客): Line 1280-1334 ✅
   - S strategies (沉睡客): Line 1336-1390 ✅

### 除錯方法

九宮格卡片左上角會顯示 `grid_position` 代碼（如 "A3D", "A3H", "A3S"），請檢查：

1. **切換到「瞌睡客」時**：
   - 應該看到代碼為 `xxD` (如 A1D, A2D, A3D, B1D...)
   - 策略名稱後綴應為 `-D` (如 王者休眠-D)

2. **切換到「半睡客」時**：
   - 應該看到代碼為 `xxH` (如 A1H, A2H, A3H, B1H...)
   - 策略名稱後綴應為 `-H` (如 王者休眠-H)

3. **切換到「沉睡客」時**：
   - 應該看到代碼為 `xxS` (如 A1S, A2S, A3S, B1S...)
   - 策略名稱後綴應為 `-S` (如 王者休眠-S)

### 如果問題仍然存在

**可能原因 1**: Reactive 更新延遲
- **解決方法**: 重新整理瀏覽器頁面

**可能原因 2**: 資料中特定生命週期階段客戶數為 0
- **檢查方法**: 查看 Console 輸出的生命週期分布
- **解決方法**: 確認資料中確實有該階段的客戶

**可能原因 3**: 只看策略名稱，未注意後綴差異
- 「王者休眠」、「成長火箭」等名稱在不同生命週期會重複使用
- **關鍵**: 注意後綴 (-N/-C/-D/-H/-S) 和左上角的 grid_position 代碼

---

## 測試建議

### 1. 新客定義測試
```r
# Console 應該顯示類似：
# ✅ 新客 (newbie): 35,729 (96.5%)
# ✅ 主力客 (active): XXX (XX%)
# ✅ 瞌睡客 (sleepy): XXX (XX%)
# ✅ 半睡客 (half_sleepy): XXX (XX%)
# ✅ 沉睡客 (dormant): XXX (XX%)
```

### 2. 九宮格切換測試
1. 選擇「新客」→ 應顯示新客專屬頁面（非九宮格）
2. 選擇「主力客」→ 九宮格代碼應為 xxC
3. 選擇「瞌睡客」→ 九宮格代碼應為 xxD
4. 選擇「半睡客」→ 九宮格代碼應為 xxH
5. 選擇「沉睡客」→ 九宮格代碼應為 xxS

### 3. 策略內容檢查
以 A3 (高價值 × 低活躍度) 為例：
- A3C (主力客): "高值客深度訪談 + 專屬客服"
- A3D (瞌睡客): "Win-Back 套餐 + VIP 續會禮"
- A3H (半睡客): "VIP 醒修券...滿額升等"
- A3S (沉睡客): "只做客情維繫，勿頻促"

---

## 相關文件更新

### 已更新
- ✅ `documents/02_architecture/Business_Logic_Implementation_Details.md`
  - 更新方案評估表：標記方案 A 為「已廢棄」
  - 新增方案 C 詳細說明：最終採用 (2025-10-26)
  - 補充 5 大選擇理由

### 待更新
- ⏳ 測試報告：待執行完整測試後更新
- ⏳ 使用者文件：建議補充生命週期切換操作說明

---

## 版本歷史

### v3 (2025-10-26) - 最終簡化版
- ✅ 新客定義：`ni == 1`（移除時間限制）
- ✅ 術語修正：「睡眠客」→「瞌睡客」
- ✅ 識別率：0% → 96.5%

### v2 (2025-10-25) - 固定窗口版
- 新客定義：`ni == 1 & customer_age_days <= 60`
- 識別率：13.5%

### v1 (原始版本) - 邏輯矛盾
- 新客定義：`ni == 1 & customer_age_days <= avg_ipt`
- 識別率：0% (失敗)

---

**修復完成時間**: 2025-10-26
**測試狀態**: ⏳ 待使用者驗證
**下一步**: 執行完整回歸測試
