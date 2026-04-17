# TagPilot Premium Bug 報告

## 🐛 發現的問題

### 1. 生命週期階段對應不一致

#### 問題描述
在 `module_dna_multi_premium.R` 中，生命週期階段 (lifecycle_stage) 與策略代碼的對應存在不一致性。

#### 問題位置

**檔案**: `modules/module_dna_multi_premium.R`

**行號 796-802**：生命週期轉換為策略代碼
```r
case_when(
  lifecycle_stage == "newbie" ~ "N",      # 新客
  lifecycle_stage == "active" ~ "C",      # 主力客 → 應該是 Cycling
  lifecycle_stage == "sleepy" ~ "D",      # 睡眠客 → 應該是 Declining  
  lifecycle_stage == "half_sleepy" ~ "H", # 半睡客 → 應該是 Hibernating
  TRUE ~ "S"  # dormant → 應該是 Sleeping
)
```

**行號 947-953**：生命週期判斷邏輯
```r
lifecycle_stage = case_when(
  is.na(r_value) | is.na(customer_age_days) ~ "unknown",
  customer_age_days <= 30 ~ "newbie",    # 30天內為新客
  r_value <= 7 ~ "active",               # 7天內有購買為主力客
  r_value <= 30 ~ "sleepy",              # 30天內有購買為睡眠客
  r_value <= 90 ~ "half_sleepy",         # 90天內有購買為半睡客
  TRUE ~ "dormant"                       # 90天以上為沉睡客
)
```

### 2. 策略對應表與程式邏輯不匹配

#### CSV檔案定義 (mapping.csv)
- **C**: Cycling (成長期)
- **D**: Declining (衰退期)  
- **H**: Hibernating (休眠期)
- **S**: Sleeping (沉睡期)

#### 程式邏輯問題
1. `active` 對應到 `C`，但 C 應該代表 "Cycling" 成長期，不是 "active" 主力客
2. `sleepy` 對應到 `D`，但 D 應該代表 "Declining" 衰退期
3. 生命週期的判斷邏輯可能與業務定義不符

### 3. 潛在的分群錯誤

由於生命週期對應錯誤，可能導致：
- 客戶被分配到錯誤的策略組
- 行銷策略與客戶實際狀態不匹配
- KPI 追蹤可能失準

## 🔧 建議修復方案

### 方案 A: 修正程式碼以符合 CSV 定義

```r
# 修正生命週期對應
case_when(
  lifecycle_stage == "newbie" ~ "N",        # 新客 (正確)
  lifecycle_stage == "cycling" ~ "C",       # 成長期 (需要新增此狀態)
  lifecycle_stage == "declining" ~ "D",     # 衰退期 (需要新增此狀態)
  lifecycle_stage == "hibernating" ~ "H",   # 休眠期 (需要新增此狀態)
  lifecycle_stage == "sleeping" ~ "S",      # 沉睡期 (需要新增此狀態)
  TRUE ~ "S"
)

# 修正生命週期判斷邏輯
lifecycle_stage = case_when(
  is.na(r_value) | is.na(customer_age_days) ~ "unknown",
  customer_age_days <= 30 ~ "newbie",       # 新客：首購30天內
  r_value <= 14 & f_value >= 3 ~ "cycling", # 成長期：頻繁購買
  r_value <= 30 & f_value >= 2 ~ "cycling", # 成長期：規律購買
  r_value <= 60 ~ "declining",              # 衰退期：購買間隔拉長
  r_value <= 120 ~ "hibernating",           # 休眠期：長時間未購買
  TRUE ~ "sleeping"                          # 沉睡期：超過120天
)
```

### 方案 B: 重新定義生命週期邏輯

建議採用更精確的生命週期定義：

```r
calculate_lifecycle_stage <- function(r_value, f_value, m_value, customer_age_days) {
  # 新客判斷
  if (customer_age_days <= 30) return("newbie")
  
  # 基於 RFM 的綜合判斷
  if (r_value <= 30) {
    if (f_value >= 3) return("cycling")    # 高頻成長客
    else return("active")                   # 一般活躍客
  } else if (r_value <= 60) {
    return("declining")                     # 開始衰退
  } else if (r_value <= 120) {
    return("hibernating")                   # 進入休眠
  } else {
    return("sleeping")                      # 沉睡客戶
  }
}
```

## 📊 影響範圍評估

### 受影響的功能
1. **九宮格分群**: 所有 39 種分群可能都有錯誤
2. **策略對應**: 客戶可能收到錯誤的行銷策略
3. **KPI 追蹤**: 效果評估可能不準確
4. **報表生成**: 統計數據可能有誤

### 資料影響
- 所有已處理的客戶資料需要重新分群
- 歷史策略執行記錄需要檢查
- KPI 報表需要重新計算

## 🎯 修復優先級

**嚴重程度**: 🔴 高

**原因**:
1. 核心業務邏輯錯誤
2. 影響所有客戶分群
3. 可能導致錯誤的行銷決策

**建議**: 立即修復並重新測試所有分群邏輯

## 📝 測試建議

### 單元測試
```r
test_that("生命週期分類正確", {
  # 測試新客
  expect_equal(
    calculate_lifecycle_stage(NA, NA, NA, 15),
    "newbie"
  )
  
  # 測試成長期客戶
  expect_equal(
    calculate_lifecycle_stage(7, 5, 10000, 60),
    "cycling"
  )
  
  # 測試衰退期客戶
  expect_equal(
    calculate_lifecycle_stage(45, 2, 5000, 90),
    "declining"
  )
})
```

### 整合測試
1. 使用測試資料集驗證所有 39 種分群
2. 檢查策略對應是否正確
3. 驗證 KPI 計算邏輯

## 🔄 修復追蹤

- [ ] 確認業務邏輯定義
- [ ] 修正程式碼
- [ ] 更新測試案例
- [ ] 執行回歸測試
- [ ] 重新處理歷史資料
- [ ] 驗證修復效果
- [ ] 更新文件

---
**報告日期**: 2024-08-26  
**報告人**: Claude Code  
**版本**: v1.0  
**狀態**: 待修復