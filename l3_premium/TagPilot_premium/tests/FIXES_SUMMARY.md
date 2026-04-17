# TagPilot Premium 修正總結

## 日期：2025-11-11

## 已完成的修正

### 1. ✅ 修正 `calculate_customer_tags.R` 中的 `tag_019_days_to_churn` 計算

**問題**：引用了不存在的 `ipt_mean` 欄位
**修正**：改為使用 DNA 分析提供的 `ipt` 欄位
**檔案**：[utils/calculate_customer_tags.R](../utils/calculate_customer_tags.R#L169-L177)

```r
# 修正前
is.na(ipt_mean) | ipt_mean <= 0 ~ NA_real_,
TRUE ~ pmax(0, round(ipt_mean * 2 - r_value, 0))

# 修正後
is.na(ipt) | ipt <= 0 ~ NA_real_,
TRUE ~ pmax(0, round(ipt * 2 - r_value, 0))
```

---

### 2. ✅ 修正 `module_dna_multi_premium_v2.R` 的 grid_position 計算

**問題**：grid_position 只生成基礎代碼（如 "A1"），沒有加上生命週期後綴（如 "C"），導致 `get_strategy()` 無法找到對應的客戶類型標籤

**修正**：分兩步計算 grid_position
1. 計算基礎九宮格位置（A1-C3）
2. 根據 customer_dynamics 加上生命週期後綴（N/C/S/H/D）

**重要**：`customer_dynamics` 由 DNA 分析返回，值為**英文**（newbie/active/sleepy/half_sleepy/dormant）

**檔案**：[modules/module_dna_multi_premium_v2.R](../modules/module_dna_multi_premium_v2.R#L565-L599)

```r
customer_data <- customer_data %>%
  mutate(
    # 第一步：計算基礎九宮格位置
    grid_base = case_when(
      is.na(activity_level) ~ "無",  # ni < 4
      value_level == "高" & activity_level == "高" ~ "A1",
      value_level == "高" & activity_level == "中" ~ "A2",
      # ... 其他組合
      TRUE ~ "其他"
    ),
    # 第二步：根據客戶生命週期加上後綴
    # ⚠️ 注意：customer_dynamics 是英文！
    lifecycle_suffix = case_when(
      customer_dynamics == "newbie" ~ "N",        # 新客
      customer_dynamics == "active" ~ "C",        # 主力客
      customer_dynamics == "sleepy" ~ "S",        # 瞌睡客
      customer_dynamics == "half_sleepy" ~ "H",   # 半睡客
      customer_dynamics == "dormant" ~ "D",       # 沉睡客
      TRUE ~ ""
    ),
    # 第三步：組合成完整的 grid_position
    grid_position = if_else(
      grid_base == "無" | grid_base == "其他",
      grid_base,
      paste0(grid_base, lifecycle_suffix)  # 例如：A1 + C = A1C
    )
  ) %>%
  select(-grid_base, -lifecycle_suffix)  # 移除暫存欄位
```

**效果**：
- 修正前：grid_position = "A1" → `get_strategy("A1")` 返回 default strategy
- 修正後：grid_position = "A1C" → `get_strategy("A1C")` 返回 "王者引擎-C"

---

### 3. ✅ 新增 module_dna_multi_premium_v2.R 的 UTF-8 BOM CSV 下載

**問題**：CSV 下載功能不存在，且需要 UTF-8 BOM 才能在 Excel 中正確顯示中文

**修正**：
1. 移除 DataTables 內建的 export buttons
2. 在 UI 的 bs4Card footer 新增自訂下載按鈕
3. 建立 downloadHandler 輸出 UTF-8 BOM 編碼的 CSV

**檔案**：
- UI：[modules/module_dna_multi_premium_v2.R](../modules/module_dna_multi_premium_v2.R#L111)
- Server：[modules/module_dna_multi_premium_v2.R](../modules/module_dna_multi_premium_v2.R#L1136-L1189)

---

### 4. ✅ 優化預測購買金額圖表的過濾條件和採樣策略

**問題**：對於有 97% 新客（ni=1）的資料集，圖表只顯示少數客戶

**修正**：
1. **放寬過濾條件**：只要有預測金額和歷史金額即可（包含 ni=1 的新客）
2. **改進採樣策略**：使用分層採樣
   - 客戶數 > 2000：優先保留所有 ni≥2 客戶，再從 ni=1 中採樣補足到 2000
   - 客戶數 500-2000：隨機採樣 500
   - 客戶數 < 500：顯示全部
3. **新增詳細說明**：在圖表下方加入篩選條件和採樣策略的說明

**檔案**：[modules/module_lifecycle_prediction.R](../modules/module_lifecycle_prediction.R#L126-L158,L356-L445)

---

## 驗證測試

### 測試腳本

1. **[tests/test_grid_position.R](test_grid_position.R)** - 驗證 grid_position 計算邏輯
2. **[tests/test_diagnosis.R](test_diagnosis.R)** - 診斷預測金額和 RSV 矩陣問題

### 測試結果（使用 KM_eg 資料）

```
=== Grid Position Logic Test ===

Lifecycle suffix distribution:
   C    N    S
 224 9958   27

Final grid_position distribution:
   無   A1C   A1S   B1C   C1C   C1S
10198     2     2     3     3     1

Customer type (title) distribution:
  customer_type     n
  <chr>         <int>
1 分類 無       10198   # ni < 4，無活躍度資料
2 成長火箭-C        3   # B1C
3 潛力新芽-C        3   # C1C
4 王者引擎-C        2   # A1C
5 王者引擎-S        2   # A1S
6 潛力新芽-S        1   # C1S

Total customers: 10209
Customers WITHOUT type label: 0 (0.0%)
Customers WITH type label: 10209 (100.0%)
```

✅ **100% 客戶都有 customer_type 標籤**

---

## 重要注意事項

### ⚠️ customer_dynamics 語言問題

`analyze_customer_dynamics_new()` 返回的 `customer_dynamics` 是**英文**：
- newbie（新客）
- active（主力客）
- sleepy（瞌睡客）
- half_sleepy（半睡客）
- dormant（沉睡客）

在 `calculate_all_customer_tags()` 中會被轉換為**中文** `tag_017_customer_dynamics`。

**在 module 中**：
- Step 17 計算 grid_position 時，使用的是**英文** `customer_dynamics` ✅
- Step 18 調用 `calculate_all_customer_tags()` 後，新增了**中文** `tag_017_customer_dynamics`

### 🔄 必須重新啟動應用程式

所有修正都需要**重新啟動 Shiny 應用程式**才會生效。修改 R 檔案後，現有的 R session 不會自動重新載入。

---

## 待處理項目

### ⏳ 需要實際客戶資料驗證的問題

1. **需求 #12 - AOV 邏輯**：主力客 AOV 低於新客 AOV
   - 可能是正常的業務現象（首購優惠、產品組合差異）
   - 需要實際業務資料驗證

2. **需求 #14 - 預測圖表資料完整性**：已修正過濾條件，現在應該顯示更多客戶

### ⏸️ 等待增強

3. **DNA 分析欠缺 `ipt_sd` 和 `ipt_mean`**：
   - RSV 矩陣需要這些欄位來計算變異係數（CV）作為穩定度指標
   - 目前退回使用 `ni` 作為穩定度代理指標
   - 對於 97% ni=1 的資料集，會導致 RSV 分布集中

---

## 測試檢查清單

使用修正後的程式碼，請驗證：

- [ ] 重新啟動應用程式
- [ ] 上傳 KM_eg 測試資料
- [ ] 檢查「客戶列表」表格
  - [ ] 「客戶類型標籤」欄位應顯示完整名稱（如「王者引擎-C」）而非「分類 A1」
  - [ ] 「建議策略」欄位應顯示具體行動方案
  - [ ] 「九宮格位置」應顯示包含後綴的完整代碼（如「A1C」）
- [ ] 測試 CSV 下載
  - [ ] 下載按鈕可以正常運作
  - [ ] Excel 能正確開啟並顯示中文欄位名稱
  - [ ] 客戶類型標籤和建議策略都有完整資料
- [ ] 檢查「預測購買金額 vs 歷史平均金額」圖表
  - [ ] 圖表顯示更多客戶（約 2000 個氣泡，包含 ni=1 的新客）
  - [ ] 底部說明清楚解釋篩選和採樣邏輯
  - [ ] 控制台有詳細的診斷輸出

---

**修正完成日期**：2025-11-11
**測試資料**：test_data/KM_eg/*.csv (40,240 筆交易，38,218 位客戶)
