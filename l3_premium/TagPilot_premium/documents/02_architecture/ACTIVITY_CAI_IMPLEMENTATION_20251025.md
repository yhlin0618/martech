# 活躍度計算邏輯變更：改用 CAI 指標

**日期**: 2025-10-25
**修改版本**: TagPilot Premium v1.0
**變更類型**: 重大邏輯變更（按規劃文檔要求）

---

## 📋 變更摘要

將活躍度（Activity）計算邏輯從使用 `r_value`（最近購買天數）改為使用 `cai_ecdf`（Customer Activity Index 百分位數），以**完全符合規劃文檔**的要求。

---

## 🎯 變更原因

### 規劃文檔要求
根據 `Work_Plan_TagPilot_Premium_Enhancement.md` 和 `TagPilot_Lite高階和旗艦版_20251021.md`：

- **Task 5.5 - 活躍度維度定義**: "Activity: CAI ≥ 80th pct"
- 明確要求使用 **CAI（Customer Activity Index）** 作為活躍度指標

### 舊實作問題
- 舊版本使用 `r_value`（Recency，最近購買天數）作為活躍度指標
- 與規劃文檔不一致
- `r_value` 只反映當前狀態，無法反映活躍度變化趨勢

---

## 🔍 CAI vs r_value 的差異

| 指標 | 定義 | 計算邏輯 | 反映內容 | 適用條件 |
|------|------|---------|----------|---------|
| **CAI** | Customer Activity Index | 基於購買間隔時間的變化趨勢 | **活躍度變化趨勢**（逐漸活躍/逐漸不活躍） | ni >= 4 |
| **r_value** | Recency（最近購買天數） | 當前時間 - 最後購買時間 | **當前狀態**（最近是否購買） | 所有客戶 |

### CAI 的優勢
1. **反映趨勢**：能識別客戶活躍度是「逐漸活躍」還是「逐漸不活躍」
2. **更科學**：基於統計模型計算，不是單一時間點
3. **符合規劃**：完全符合規劃文檔的業務邏輯要求

### CAI 的限制
1. **需要足夠數據**：只對 `ni >= 4` 且 `times != 1` 的客戶計算
2. **不適用新客**：新客（ni == 1）無法計算 CAI

---

## 📊 CAI 計算邏輯（來自 fn_analysis_dna.R）

### 計算公式（Line 669-677）

```r
# 只對符合條件的客戶計算 CAI
cai_dt <- dt[times != 1 & ni >= ni_threshold, .(
  mle = sum(ipt * (1/(ni-1))),
  wmle = sum(ipt * ((times-1) / sum(times-1)))
), by = customer_id]

# 計算 CAI 值和百分位數
cai_dt[, cai := (mle - wmle) / mle]
cai_dt[, cai_ecdf := ecdf(cai)(cai)]
cai_dt[, cai_label := cut(cai_ecdf, breaks = cai_breaks, labels = text_cai_label,
                          right = FALSE, ordered_result = TRUE)]
```

### 計算條件
- `times != 1`: 排除只有一次交易的記錄
- `ni >= ni_threshold`: 交易次數 >= 閾值（預設為 4）
- **不符合條件的客戶，CAI 值為 NA**

### 返回欄位
1. **`cai_value`** (原名 `cai`): CAI 數值
2. **`cai_ecdf`**: CAI 的累積分佈函數值（百分位數，0-1）
3. **`cai_label`**: CAI 分類標籤
   - "Gradually Inactive" (逐漸不活躍)
   - "Stable" (穩定)
   - "Increasingly Active" (逐漸活躍)

---

## ✅ 新實作邏輯（方案 A）

### 檔案：`modules/module_dna_multi_premium.R`

### Line 418-455: ni >= 4 的客戶（有 CAI）

```r
if (nrow(customers_sufficient_data) > 0) {
  customers_sufficient_data <- customers_sufficient_data %>%
    mutate(
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
    )
}
```

### Line 457-488: ni < 4 的客戶（無 CAI，降級策略）

```r
if (nrow(customers_insufficient_data) > 0) {
  insufficient_non_newbie <- customers_insufficient_data %>%
    filter(lifecycle_stage != "newbie")

  if (nrow(insufficient_non_newbie) > 0) {
    customers_insufficient_data <- customers_insufficient_data %>%
      mutate(
        # ni < 4 的非新客：使用 r_value 降級策略
        activity_level = case_when(
          lifecycle_stage == "newbie" ~ NA_character_,  # 新客不計算活躍度
          !is.na(r_value) ~ case_when(
            r_value <= quantile(r_value[lifecycle_stage != "newbie"], 0.2, na.rm = TRUE) ~ "高",
            r_value <= quantile(r_value[lifecycle_stage != "newbie"], 0.8, na.rm = TRUE) ~ "中",
            TRUE ~ "低"
          ),
          TRUE ~ NA_character_
        ),
        insufficient_data_flag = TRUE  # 標記使用降級策略
      )
  }
}
```

---

## 🔄 活躍度分類邏輯對比

### 舊版本（使用 r_value）

| 活躍度 | 條件 | 意義 |
|--------|------|------|
| 高 | r_value <= P20 | 最近 20% 購買（最近購買） |
| 中 | P20 < r_value <= P80 | 中等時間沒購買 |
| 低 | r_value > P80 | 最久 20% 沒購買 |

**問題**：只看當前狀態，無法判斷趨勢

### 新版本（使用 CAI）

| 活躍度 | 條件 | 意義 |
|--------|------|------|
| 高 | cai_ecdf >= 0.8 | CAI P80 以上（逐漸活躍） |
| 中 | 0.2 <= cai_ecdf < 0.8 | CAI P20-P80（穩定） |
| 低 | cai_ecdf < 0.2 | CAI P20 以下（逐漸不活躍） |

**優勢**：反映活躍度變化趨勢

---

## 🎯 降級策略（ni < 4 時）

當客戶交易次數不足（ni < 4）時，DNA 分析不會計算 CAI，此時使用降級策略：

### 降級邏輯
1. **新客（ni == 1）**: `activity_level = NA`（不計算活躍度）
2. **非新客（2 <= ni < 4）**: 使用 `r_value` 作為活躍度代理指標
   - 高活躍：r_value <= P20（最近購買）
   - 中活躍：P20 < r_value <= P80
   - 低活躍：r_value > P80（最久沒購買）

### 標記欄位
- `insufficient_data_flag = TRUE`: 標記使用降級策略的客戶

---

## 📊 影響範圍

### 直接影響
1. **活躍度分類**：所有客戶的 `activity_level` 計算邏輯改變
2. **九宮格分析**：Value × Activity 九宮格的分佈會改變
3. **客戶標籤**：基於活躍度的標籤（如 `tag_010_activity_trend`）會改變

### 間接影響
1. **客戶分群策略**：活躍度定義改變會影響分群結果
2. **營銷策略建議**：基於活躍度的營銷建議會更準確
3. **流失預測**：CAI 能更好地預測流失趨勢

---

## ✅ 優勢與風險

### 優勢
1. ✅ **符合規劃文檔**：完全按照業務邏輯要求實作
2. ✅ **更科學**：CAI 反映活躍度變化趨勢，不只是當前狀態
3. ✅ **更準確**：能識別「逐漸活躍」vs「逐漸不活躍」的客戶
4. ✅ **有降級策略**：ni < 4 時仍能計算活躍度（使用 r_value）

### 風險與注意事項
1. ⚠️ **分佈變化**：活躍度分佈會與舊版本不同
2. ⚠️ **需要數據量**：CAI 需要 ni >= 4，小客戶可能受限
3. ⚠️ **解釋複雜度**：CAI 概念比 r_value 更複雜，需要向業務人員解釋

---

## 🧪 測試建議

### 測試重點
1. **CAI 欄位存在性**：確認 DNA 分析返回 `cai_value` 和 `cai_ecdf`
2. **活躍度分佈**：檢查高/中/低活躍度的客戶數量分佈
3. **降級策略**：驗證 ni < 4 的客戶是否正確使用 r_value
4. **九宮格分析**：確認九宮格顯示正確
5. **客戶標籤**：檢查活躍度相關標籤是否正確

### 測試案例

#### 案例 1: ni >= 4 的客戶
```r
# 測試數據
customer_1 <- list(
  customer_id = "C001",
  ni = 5,
  cai_ecdf = 0.85,  # P85 = 高活躍
  r_value = 30
)

# 預期結果
expected_activity <- "高"  # 因為 cai_ecdf >= 0.8
```

#### 案例 2: ni < 4 的非新客
```r
# 測試數據
customer_2 <- list(
  customer_id = "C002",
  ni = 3,
  cai_ecdf = NA,  # ni < 4，沒有 CAI
  r_value = 5     # 最近購買
)

# 預期結果
expected_activity <- "高"  # 因為 r_value 小（降級策略）
expected_flag <- TRUE      # insufficient_data_flag
```

#### 案例 3: 新客
```r
# 測試數據
customer_3 <- list(
  customer_id = "C003",
  ni = 1,
  cai_ecdf = NA,
  r_value = 10
)

# 預期結果
expected_activity <- NA  # 新客不計算活躍度
```

---

## 📚 相關文檔

1. **規劃文檔**:
   - `Work_Plan_TagPilot_Premium_Enhancement.md` (Task 5.5)
   - `TagPilot_Lite高階和旗艦版_20251021.md`

2. **DNA 分析函數**:
   - `global_scripts/04_utils/fn_analysis_dna.R` (Line 646-690)

3. **邏輯一致性審計**:
   - `LOGIC_CONSISTENCY_AUDIT_20251025.md`

4. **之前的 Bug 修正**:
   - `BUGFIX_20251025_LOGIC_CORRECTIONS.md`

---

## 👥 影響團隊

### 開發團隊
- 需要了解 CAI 的計算邏輯和業務意義
- 測試時注意活躍度分佈變化

### 業務團隊
- 需要重新理解活躍度定義（從「最近購買」改為「活躍度趨勢」）
- 營銷策略可能需要調整

### 數據分析團隊
- 歷史數據對比時需要注意定義變化
- 可能需要重新計算歷史活躍度分佈

---

## ✅ 完成檢查清單

- [x] 修改 `module_dna_multi_premium.R` 活躍度計算邏輯
- [x] 加入 CAI 優先策略
- [x] 實作 r_value 降級策略（ni < 4）
- [x] 處理新客特殊情況
- [x] 加入詳細代碼註解
- [x] 建立變更文檔
- [ ] 執行單元測試
- [ ] 驗證九宮格分析顯示
- [ ] 確認客戶標籤計算正確
- [ ] 向業務團隊說明變更

---

**變更狀態**: ✅ 已完成
**測試狀態**: ⏳ 待測試
**部署狀態**: ⏳ 待部署

---

**最後更新**: 2025-10-25
**修改人**: Claude AI
**審核人**: 待確認
