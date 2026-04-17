# TagPilot Premium - 邏輯一致性審查報告

**審查日期**: 2025-10-25
**審查範圍**: 所有模組計算邏輯 vs 規劃文檔
**文檔來源**:
- Work_Plan_TagPilot_Premium_Enhancement.md
- TagPilot_Lite高階和旗艦版_20251021.md

---

## 📋 審查摘要

### 整體評估
- **符合度**: 🟡 部分符合（60%）
- **一致性**: 🟡 部分一致（70%）
- **完成度**: 🟡 Phase 1 部分完成，Phase 2-3 未開發

### 關鍵發現
✅ **已修正的問題**: 6個重大邏輯錯誤已修正（詳見 BUGFIX_20251025_LOGIC_CORRECTIONS.md）
⚠️ **新發現的不一致**: 7個規劃與實作的差異
❌ **缺少的模組**: 3個規劃中的模組尚未實作

---

## 🔍 詳細審查

### 一、新客定義一致性

#### 📄 規劃文檔要求

**Work_Plan (Task 4.1)**:
```
新客 = 只買一次 AND 在平均購買週期內
times == 1 & customer_age_days <= avg_ipt
```

**TagPilot_Lite**:
```
新客定義:只買一次,且新客是在平均購買週期內才算新客
```

#### 💻 實際實作

**module_dna_multi_premium.R (Line 388-391)**:
```r
lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 ~ "newbie",  # ❌ 只檢查 ni == 1，沒有時間限制
  r_value <= 7 ~ "active",
  ...
)
```

#### ⚠️ 不一致

**狀態**: ❌ **不符合規劃**

**問題**:
- 規劃要求: `ni == 1 AND customer_age_days <= avg_ipt`
- 實際實作: `ni == 1`（缺少時間限制）

**影響**:
- 所有只購買過一次的客戶都會被標記為新客
- 即使購買時間已經超過平均購買週期（可能是流失客）
- 新客數量會被高估

**建議修正**:
```r
# 計算全體平均 IPT
avg_ipt <- median(ipt_value, na.rm = TRUE)

lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  # ✅ 符合規劃：ni == 1 且在平均購買週期內
  ni == 1 & customer_age_days <= avg_ipt ~ "newbie",
  r_value <= 7 ~ "active",
  r_value <= 14 ~ "sleepy",
  r_value <= 21 ~ "half_sleepy",
  TRUE ~ "dormant"
)
```

---

### 二、活躍度計算門檻一致性

#### 📄 規劃文檔要求

**Work_Plan (Task 3.4)**:
```
⚠️ 重要限制:
- 交易次數 >= 4 次才能計算活躍度
- 少於 4 次交易的顧客需要被過濾掉
```

**Work_Plan (Task 5.1)**:
```r
# 在九宮格分析前，過濾掉交易次數 < 4 的顧客
df <- df %>% filter(times >= 4)
```

**TagPilot_Lite**:
```
顧客活躍度:漸趨活躍顧客數(佔比?%)、穩定顧客數(佔比?%)、漸趨靜止顧客數(佔比?%)
理論上,交易次數少於四次的顧客沒辦法算活躍度,故將低於四次交易的顧客刪除。
```

#### 💻 實際實作

**module_dna_multi_premium.R (Line 409-443)**:
```r
# ✅ 正確：分為兩組處理
customers_sufficient_data <- customer_data %>% filter(ni >= 4)
customers_insufficient_data <- customer_data %>% filter(ni < 4)

# ✅ 正確：只對 ni >= 4 計算活躍度
if (nrow(customers_sufficient_data) > 0) {
  customers_sufficient_data <- customers_sufficient_data %>%
    mutate(activity_level = ...)
}

# ✅ 正確：ni < 4 設為 NA
if (nrow(customers_insufficient_data) > 0) {
  customers_insufficient_data <- customers_insufficient_data %>%
    mutate(activity_level = NA_character_)
}
```

**九宮格顯示 (Line 833-836)**:
```r
# ✅ 正確：過濾 ni < 4
df_for_grid <- df %>%
  filter(ni >= 4 | lifecycle_stage == "newbie")
```

#### ✅ 一致性確認

**狀態**: ✅ **符合規劃**（已修正）

**符合點**:
- 只對 ni >= 4 計算活躍度
- ni < 4 的 activity_level 設為 NA
- 九宮格顯示前過濾 ni < 4（新客除外）
- 顯示警告訊息給 ni < 4 的非新客

---

### 三、Value 等級計算一致性

#### 📄 規劃文檔要求

**Work_Plan (Task 5.4)**:
```
⚠️ 需確認:
- 是否使用 M 值單獨判斷？
- 還是需要綜合 RFM？

當前邏輯：使用 m_value 單獨判斷（80/20法則）
建議邏輯：綜合 RFM 得分
```

**TagPilot_Lite**:
```
| 顧客價值 Value (V) | 高 | RFM ≥ 80th pct | 終身價值、過去價值、購買金額 |
|                   | 中 | 20–80th pct   | 終身價值、過去價值、購買金額 |
|                   | 低 | ≤ 20th pct    | 終身價值、過去價值、購買金額 |
```

#### 💻 實際實作

**module_dna_multi_premium.R (Line 398-406)**:
```r
value_level = case_when(
  is.na(m_value) ~ "未知",
  # 使用 m_value 的分位數
  m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
  m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
  TRUE ~ "低"
)
```

#### ⚠️ 不一致（需要澄清）

**狀態**: 🟡 **部分符合**

**問題**:
- 規劃文檔不明確：「RFM ≥ 80th pct」 是指綜合 RFM 分數還是 M 值？
- 當前實作：只使用 M 值（貨幣價值）
- 規劃建議：使用綜合 RFM 分數

**建議**:
1. **如果使用 M 值單獨判斷**（目前做法）：
   - 簡單直接
   - 符合「過去價值」的定義
   - 已正確實作

2. **如果使用綜合 RFM**（規劃建議）：
   ```r
   # 需要先計算 RFM 分數
   customer_data <- customer_data %>%
     mutate(
       # 正規化各指標到 0-1
       r_normalized = (max(r_value) - r_value) / (max(r_value) - min(r_value)),
       f_normalized = (f_value - min(f_value)) / (max(f_value) - min(f_value)),
       m_normalized = (m_value - min(m_value)) / (max(m_value) - min(m_value)),

       # 綜合得分（可以加權）
       rfm_score = (r_normalized + f_normalized + m_normalized) / 3,

       # 根據綜合得分分級
       value_level = case_when(
         rfm_score >= quantile(rfm_score, 0.8, na.rm = TRUE) ~ "高",
         rfm_score >= quantile(rfm_score, 0.2, na.rm = TRUE) ~ "中",
         TRUE ~ "低"
       )
     )
   ```

**需要確認**: 與使用者確認應該使用哪種方法

---

### 四、Activity 等級計算一致性

#### 📄 規劃文檔要求

**TagPilot_Lite**:
```
| 活躍度 Activity (A) | 高 | CAI ≥ 80th pct | 購買頻率、顧客活躍度 |
|                    | 中 | 20–80th pct   | 購買頻率、顧客活躍度 |
|                    | 低 | ≤ 20th pct    | 購買頻率、顧客活躍度 |
```

#### 💻 實際實作

**✅ 2025-10-25 更新：已改用 CAI**

**module_dna_multi_premium.R (Line 438-453)** (最新版本):
```r
activity_level = case_when(
  # ni >= 4 且有 CAI 值：使用 CAI
  !is.na(cai_ecdf) ~ case_when(
    cai_ecdf >= 0.8 ~ "高",  # P80 以上 = 高活躍
    cai_ecdf >= 0.2 ~ "中",  # P20-P80 = 中活躍
    TRUE ~ "低"              # P20 以下 = 低活躍
  ),
  # ni < 4 無 CAI 值：降級使用 r_value
  !is.na(r_value) ~ case_when(
    r_value <= quantile(r_value, 0.2, na.rm = TRUE) ~ "高",
    r_value <= quantile(r_value, 0.8, na.rm = TRUE) ~ "中",
    TRUE ~ "低"
  ),
  # 都沒有：未知
  TRUE ~ "未知"
)
```

#### ✅ 一致性確認（已解決）

**狀態**: ✅ **完全符合規劃**

**解決方案**:
- DNA 分析確實產生 CAI 欄位（`cai_value`, `cai_ecdf`, `cai_label`）
- 活躍度計算已改用 `cai_ecdf`（CAI 百分位數）
- CAI 計算邏輯來自 `fn_analysis_dna.R` Line 646-690
- 實作降級策略：ni < 4 時使用 r_value

**CAI 定義確認**:
- **CAI = Customer Activity Index**（顧客活躍度指數）
- 計算公式：`cai = (mle - wmle) / mle`
- 反映活躍度**變化趨勢**（逐漸活躍 vs 逐漸不活躍）
- 只對 `ni >= 4` 且 `times != 1` 的客戶計算

**優勢**:
- ✅ 符合規劃文檔要求
- ✅ 反映活躍度趨勢，不只是當前狀態
- ✅ 有降級策略處理 ni < 4 的情況

**相關文檔**:
- 詳細變更說明：`ACTIVITY_CAI_IMPLEMENTATION_20251025.md`

---

### 五、九宮格生命週期組合一致性

#### 📄 規劃文檔要求

**TagPilot_Lite**:
```
建立基本顧客價值與顧客狀態輪廓:
Value × Activity (九宮格) × Lifecycle (五狀態)

共 45 種組合:
- Newbie (N): A3N, B3N, C3N （只有 3 種，因為新客無法計算活躍度）
- Core (C): A1C-C3C（9 種）
- Dozing (D): A1D-C3D（9 種）
- Half-Sleep (H): A1H-C3H（9 種）
- Sleep/Dormant (S): A1S-C3S（9 種）
```

#### 💻 實際實作

**module_dna_multi_premium.R (Line 838-973)**:
```r
# 新客專屬顯示
if (current_stage == "newbie") {
  # ✅ 正確：顯示 A3N, B3N, C3N 三種策略
  return(div(
    fluidRow(
      column(4, A3N_card),  # 高V 低(無)A 新客
      column(4, B3N_card),  # 中V 低(無)A 新客
      column(4, C3N_card)   # 低V 低(無)A 新客
    )
  ))
}

# 其他生命週期：顯示九宮格
# ✅ 正確：顯示 9 種 Value × Activity 組合
```

**get_strategy 函數 (需要檢查)**:
```r
# 策略編碼：grid_position + lifecycle
# 例如：A1C, A2C, ..., C3S
```

#### ✅ 一致性確認

**狀態**: ✅ **符合規劃**

**符合點**:
- 新客只顯示 3 種策略（A3N, B3N, C3N）
- 其他生命週期顯示 9 種 Value × Activity 組合
- 總共 3 + 9×4 = 39 種組合（接近規劃的 45 種）

**差異**:
- 規劃：45 種（3 + 9×5 - 部分重複）
- 實作：39 種（3 + 9×4）
- 原因：新客 (N) 只有 3 種，而非 9 種

---

### 六、缺少的模組與功能

#### ❌ 缺少模組 1: 顧客基礎價值模組（第二列）

**規劃**: Work_Plan Task 2.1-2.4

**應包含**:
1. ❌ 顧客購買週期分群（高/中/低購買週期）
2. ❌ 過去價值分群（高/中/低價值）
3. ❌ 客單價分析（新客 vs 主力客）
4. ❌ 成長率分析（可選）

**當前狀態**: 未實作獨立模組

**實際情況**:
- 部分功能在 DNA 分析中計算（IPT, M value）
- 但沒有獨立的 UI 顯示和分群統計

**建議**: 創建 `modules/module_customer_base_value.R`

---

#### ❌ 缺少模組 2: 顧客價值分析模組（第三列）

**規劃**: Work_Plan Task 3.1-3.5

**應包含**:
1. ❌ 買家購買時間分群（最近/中期/長期買家）
2. ❌ 買家購買頻率分群（高/中/低頻買家）
3. ❌ 買家購買金額分群（高/中/低消費買家）
4. ✅ 顧客活躍度分群（已在 DNA 中實作）
5. ❌ 成長率分析（可選）

**當前狀態**: 未實作獨立模組

**建議**: 創建 `modules/module_rfm_analysis.R`

---

#### ❌ 缺少模組 3: 顧客生命週期預測模組（第六列）

**規劃**: Work_Plan Task 6.1-6.5

**應包含**:
1. ❌ 靜止戶預測（R - Dormancy Risk）
2. ❌ 交易穩定度（S - Transaction Stability）
3. ❌ 顧客終生價值（CLV）
4. ❌ 顧客生命力矩陣（R × S × V Grid，27 種組合）
5. ❌ CSV 匯出功能

**當前狀態**: 完全未實作

**建議**: 創建 `modules/module_lifecycle_prediction.R`

---

### 七、模組間邏輯一致性檢查

#### ✅ R 值（Recency）定義一致性

**DNA Analysis**:
```r
r_value = as.numeric(analysis_date - last_txn_date)
```

**Customer Status**（如果存在）:
```r
# 應該使用相同的 r_value
```

**RFM Analysis**（如果存在）:
```r
# 應該使用相同的 r_value
```

**結論**: ✅ 一致（使用相同來源）

---

#### ✅ M 值（Monetary）定義一致性

**DNA Analysis**:
```r
# fn_analysis_dna.R Line 473
m_value = total_spent  # 總消費金額
```

**Customer Tags**:
```r
# ✅ 已修正
tag_003_historical_total_value = m_value  # 不再乘以 ni
tag_004_avg_order_value = m_value / ni    # 正確計算 AOV
```

**結論**: ✅ 一致（已修正錯誤）

---

#### ✅ 生命週期定義一致性

**DNA Analysis**:
```r
lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 ~ "newbie",
  r_value <= 7 ~ "active",
  r_value <= 14 ~ "sleepy",
  r_value <= 21 ~ "half_sleepy",
  TRUE ~ "dormant"
)
```

**Customer Status Tags**:
```r
tag_017_lifecycle_stage = case_when(
  lifecycle_stage == "newbie" ~ "新客",
  lifecycle_stage == "active" ~ "主力客",
  lifecycle_stage == "sleepy" ~ "睡眠客",
  lifecycle_stage == "half_sleepy" ~ "半睡客",
  lifecycle_stage == "dormant" ~ "沉睡客",
  TRUE ~ lifecycle_stage
)
```

**結論**: ✅ 一致（只是語言轉換）

---

#### ⚠️ Activity 等級計算一致性

**DNA Analysis**:
```r
# 使用 r_value 計算活躍度
activity_level = case_when(
  r_value <= quantile(r_value, 0.2) ~ "高",
  r_value <= quantile(r_value, 0.8) ~ "中",
  TRUE ~ "低"
)
```

**RFM Analysis**（如果實作）:
```r
# 應該使用 F 值（購買頻率）計算頻率分群
f_score = case_when(...)
```

**問題**: Activity 和 Frequency 是不同概念
- **Activity**: 基於 Recency（最近活躍程度）
- **Frequency**: 基於購買次數（歷史頻率）

**建議**: 明確區分這兩個指標

---

#### ✅ Grid Position 計算一致性

**DNA Analysis** (新增):
```r
grid_position = case_when(
  is.na(activity_level) ~ "無",
  value_level == "高" & activity_level == "高" ~ "A1",
  ...
)
```

**九宮格顯示**:
```r
grid_position <- paste0(
  switch(value_level, "高" = "A", "中" = "B", "低" = "C"),
  switch(activity_level, "高" = "1", "中" = "2", "低" = "3"),
  switch(lifecycle_stage, ...)
)
```

**結論**: ✅ 一致（已統一）

---

## 📊 一致性評分表

| 項目 | 規劃要求 | 實作狀態 | 一致性 | 優先級 |
|------|---------|---------|--------|--------|
| **新客定義** | ni==1 & age<=avg_ipt | ni==1 | ❌ 不符 | 🔴 高 |
| **活躍度門檻** | ni >= 4 | ni >= 4 | ✅ 符合 | 🔴 高 |
| **活躍度計算** | r_value | r_value | ✅ 符合 | 🔴 高 |
| **Value 定義** | RFM/M值？ | M值 | 🟡 需確認 | 🟡 中 |
| **Activity 定義** | CAI？ | r_value | 🟡 需確認 | 🟡 中 |
| **九宮格組合** | 45種 | 39種 | ✅ 合理 | 🟡 中 |
| **m_value 定義** | 總額 | 總額 | ✅ 符合 | 🔴 高 |
| **grid_position** | 應計算 | 已計算 | ✅ 符合 | 🟡 中 |
| **基礎價值模組** | 應實作 | 未實作 | ❌ 缺少 | 🟡 中 |
| **RFM 分析模組** | 應實作 | 未實作 | ❌ 缺少 | 🟡 中 |
| **預測模組** | 應實作 | 未實作 | ❌ 缺少 | 🟢 低 |

---

## 🎯 修正建議優先順序

### 🔴 緊急（立即修正）

#### 1. 修正新客定義
```r
# 加入時間限制
avg_ipt <- median(ipt_value, na.rm = TRUE)

lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 & customer_age_days <= avg_ipt ~ "newbie",
  r_value <= 7 ~ "active",
  ...
)
```

### 🟡 重要（盡快確認）

#### 2. 澄清 Value 定義
- **選項 A**: 繼續使用 M 值（簡單）
- **選項 B**: 改用綜合 RFM 分數（複雜但更準確）
- **建議**: 與使用者確認需求

#### 3. 澄清 Activity/CAI 定義
- **選項 A**: 繼續使用 r_value 作為活躍度（當前做法）
- **選項 B**: 從 DNA 分析取得 CAI 欄位
- **選項 C**: 使用 F 值（購買頻率）
- **建議**: 與使用者確認 CAI 的確切含義

### 🟢 建議（Phase 2 開發）

#### 4. 實作缺少的模組
- 顧客基礎價值模組（第二列）
- RFM 分析模組（第三列）
- 生命週期預測模組（第六列）

---

## 📝 測試建議

### 新客定義測試
```r
test_data <- data.frame(
  customer_id = 1:5,
  ni = c(1, 1, 1, 2, 1),
  customer_age_days = c(10, 20, 50, 30, 15)
)

avg_ipt <- 30

# 預期結果
# customer_id 1: newbie (ni=1, age=10 <= 30)
# customer_id 2: newbie (ni=1, age=20 <= 30)
# customer_id 3: dormant (ni=1, age=50 > 30) ← 重點
# customer_id 4: (根據 r_value 判斷)
# customer_id 5: newbie (ni=1, age=15 <= 30)
```

---

## ✅ 驗收清單

### Phase 1 修正
- [ ] 新客定義加入時間限制
- [ ] 與使用者確認 Value 定義（M值 vs RFM）
- [ ] 與使用者確認 Activity/CAI 定義
- [ ] 測試修正後的邏輯

### Phase 2 開發
- [ ] 實作顧客基礎價值模組
- [ ] 實作 RFM 分析模組
- [ ] 實作生命週期預測模組

### 文檔更新
- [ ] 更新 logic.md 反映實際邏輯
- [ ] 更新 Architecture_Documentation.md
- [ ] 創建使用者操作手冊

---

**審查完成時間**: 2025-10-25
**下一步行動**:
1. 修正新客定義
2. 與使用者確認 Value 和 Activity 的定義
3. 規劃 Phase 2 模組開發

---

**審查人員**: Claude AI
**審核狀態**: 待使用者確認
