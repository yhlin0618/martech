# TagPilot Premium - Gap Analysis (差距分析)

**文件版本**: v1.0
**分析日期**: 2025-10-25
**分析人員**: Claude AI + User Feedback
**參考文件**: [Work_Plan_TagPilot_Premium_Enhancement.md](Work_Plan_TagPilot_Premium_Enhancement.md)

---

## 🎯 執行摘要

根據 Work_Plan 和用戶反饋，發現以下關鍵差距：

### 🔴 Critical Issues（必須修復）

1. **新客數量未正確顯示** - 用戶報告「沒有顯示」
2. **生命週期階段篩選功能缺失** - 「沒有根據選擇客群而有呈現不同內容」
3. **預測購買金額氣泡圖缺失** - 「預測購買金額 vs 歷史平均金額（氣泡大小 = 購買次數）Error [object Object]」

### 🟡 Medium Priority（建議改進）

4. Module 2-6 缺少生命週期階段過濾器
5. CSV 導出功能需要優化
6. UI 中的一些說明文字需要更新

### 🟢 Low Priority（未來增強）

7. 成長率分析功能（需要歷史資料支援）
8. 27 種 R/S/V 策略的完整描述

---

## 📊 詳細差距分析

### Module 1: DNA 九宮格分析

#### ✅ 已實現的功能

| 功能項目 | Work_Plan 需求 | 當前狀態 | 位置 |
|---------|--------------|---------|------|
| 新客定義邏輯 | ni == 1 & customer_age_days <= avg_ipt | ✅ 已實現 | Line 406 |
| RFM 計算 | 80/20 法則 | ✅ 已實現 | Line 380-430 |
| 九宮格分類 | 9 種客戶類型 | ✅ 已實現 | Line 520-540 |
| 熱力圖 | 互動式視覺化 | ✅ 已實現 | - |

#### ❌ 缺失的功能

| 功能項目 | Work_Plan 需求 | 當前狀態 | 優先級 |
|---------|--------------|---------|-------|
| **新客數量顯示** | 應該顯示新客人數和百分比 | ❌ 未顯示或為 0 | 🔴 Critical |
| 生命週期過濾器 | 可選擇特定階段（newbie/active/...） | ❌ 缺失 | 🔴 Critical |
| 階段篩選後的九宮格 | 根據選擇的階段更新九宮格 | ❌ 缺失 | 🔴 Critical |

#### 🐛 已知問題

**Issue 1: 新客數量為 0 或未顯示**

**根本原因分析**:
1. 新客定義邏輯正確（Line 406）：`ni == 1 & customer_age_days <= avg_ipt`
2. 可能的問題：
   - `customer_age_days` 計算錯誤
   - `avg_ipt` 計算不正確
   - 測試資料不符合條件（所有單次購買客戶都超過平均購買週期）

**需要檢查的代碼**:
```r
# Line 390-395: 計算 customer_age_days
customer_age_days = as.numeric(difftime(Sys.time(), first_purchase_date, units = "days"))

# Line 398-400: 計算 avg_ipt
avg_ipt <- mean(customer_data$ipt_mean, na.rm = TRUE)
```

**建議修復**:
```r
# 1. 加入除錯訊息
cat("平均購買週期 (avg_ipt):", avg_ipt, "\n")
cat("單次購買客戶數:", sum(customer_data$ni == 1), "\n")
cat("符合新客條件客戶數:", sum(customer_data$ni == 1 & customer_data$customer_age_days <= avg_ipt), "\n")

# 2. 檢查 first_purchase_date 是否正確
cat("first_purchase_date 範例:", head(customer_data$first_purchase_date), "\n")

# 3. 考慮放寬新客定義（如果資料特性需要）
# 選項 A: 使用中位數而非平均數
avg_ipt <- median(customer_data$ipt_mean, na.rm = TRUE)

# 選項 B: 使用更長的時間窗口（例如 1.5 倍）
ni == 1 & customer_age_days <= (avg_ipt * 1.5) ~ "newbie"
```

---

**Issue 2: 生命週期階段篩選功能缺失**

**Work_Plan 需求** (Task 5.2, Line 571-577):
```
確認新客定義一致性
- 九宮格中的新客定義應與第四列一致
- 只買一次 + 在平均購買週期內
```

**當前狀態**:
- ❌ UI 沒有提供生命週期階段下拉選單
- ❌ 無法根據階段過濾客戶
- ❌ 所有階段混合顯示在同一個九宮格

**需要新增的 UI 元素**:
```r
# 在 Module 1 UI 中新增
selectInput(
  ns("lifecycle_filter"),
  "選擇生命週期階段：",
  choices = c(
    "全部" = "all",
    "新客" = "newbie",
    "主力客" = "active",
    "瞌睡客" = "sleepy",
    "半睡客" = "half_sleepy",
    "沉睡客" = "dormant"
  ),
  selected = "all"
)
```

**需要新增的 Server 邏輯**:
```r
# 過濾資料
filtered_data <- reactive({
  req(values$dna_results)
  df <- values$dna_results$data_by_customer

  # 根據選擇的階段過濾
  if (input$lifecycle_filter != "all") {
    df <- df %>% filter(lifecycle_stage == input$lifecycle_filter)
  }

  return(df)
})

# 更新九宮格使用 filtered_data()
```

---

### Module 6: 生命週期預測模組

#### ❌ 缺失的關鍵功能

**Issue 3: 預測購買金額 vs 歷史平均金額氣泡圖**

**Work_Plan 未明確提及，但用戶期望的功能**:
- 氣泡圖：X軸 = 歷史平均金額，Y軸 = 預測購買金額
- 氣泡大小 = 購買次數（Frequency）
- 用途：視覺化客戶價值預測

**當前狀態**:
- ❌ 完全缺失此視覺化
- ❌ 用戶看到 "Error [object Object]"

**需要實現的功能**:
```r
# UI 輸出
plotlyOutput(ns("predicted_vs_historical_plot"))

# Server 邏輯
output$predicted_vs_historical_plot <- renderPlotly({
  req(prediction_data())

  df <- prediction_data() %>%
    mutate(
      # 計算歷史平均金額
      historical_avg = m_value / ni,
      # 預測購買金額（簡化版：使用歷史平均）
      predicted_amount = historical_avg * prediction_confidence_factor
    )

  plot_ly(
    df,
    x = ~historical_avg,
    y = ~predicted_amount,
    size = ~ni,  # 氣泡大小 = 購買次數
    color = ~lifecycle_stage,
    text = ~paste(
      "客戶:", customer_id,
      "<br>歷史平均:", round(historical_avg, 2),
      "<br>預測金額:", round(predicted_amount, 2),
      "<br>購買次數:", ni
    ),
    hoverinfo = "text",
    type = "scatter",
    mode = "markers"
  ) %>%
    layout(
      title = "預測購買金額 vs 歷史平均金額",
      xaxis = list(title = "歷史平均金額"),
      yaxis = list(title = "預測購買金額")
    )
})
```

**錯誤來源分析**:
用戶看到 "Error [object Object]" 可能是因為：
1. JavaScript 錯誤（前端問題）
2. 嘗試渲染不存在的圖表物件
3. 資料格式錯誤傳遞到前端

**建議修復步驟**:
1. 檢查 Module 6 的 UI 定義是否有此圖表
2. 檢查 Server 是否有對應的 renderPlotly
3. 加入錯誤處理：
```r
output$predicted_vs_historical_plot <- renderPlotly({
  tryCatch({
    req(prediction_data())
    # ... 繪圖邏輯 ...
  }, error = function(e) {
    # 返回錯誤訊息圖表
    plot_ly() %>%
      layout(
        title = paste("錯誤:", e$message),
        xaxis = list(title = ""),
        yaxis = list(title = "")
      )
  })
})
```

---

### Module 2-6: 通用問題

#### ❌ 缺失功能：生命週期階段過濾

**問題描述**:
所有模組（2-6）都沒有提供根據生命週期階段篩選資料的功能，導致：
- 無法針對特定客群（如新客）進行分析
- 所有分析結果混合所有階段，不夠精細

**Work_Plan 期望** (Task 5.1, Line 551-566):
```r
# 在九宮格分析前，過濾掉交易次數 < 4 的顧客
nine_grid_data <- reactive({
  req(values$dna_results, input$lifecycle_stage)

  df <- values$dna_results$data_by_customer

  # ⚠️ 關鍵修改：只保留交易次數 >= 4 的顧客
  df <- df %>% filter(times >= 4)

  # 過濾選定的生命週期階段
  df <- df[df$lifecycle_stage == input$lifecycle_stage, ]

  if (nrow(df) == 0) return(NULL)

  return(df)
})
```

**需要在所有模組新增**:
1. UI 篩選器：
```r
selectInput(
  ns("lifecycle_filter"),
  "生命週期階段：",
  choices = c("全部" = "all", "新客" = "newbie", ...)
)
```

2. 響應式資料過濾：
```r
filtered_data <- reactive({
  req(input_data())
  df <- input_data()

  if (input$lifecycle_filter != "all") {
    df <- df %>% filter(lifecycle_stage == input$lifecycle_filter)
  }

  return(df)
})
```

3. 更新所有圖表和表格使用 `filtered_data()`

---

## 📋 完整差距清單

### 🔴 Critical Priority（必須修復）

| ID | 問題 | 模組 | Work_Plan 參考 | 預估工時 |
|----|------|------|--------------|---------|
| GAP-001 | 新客數量未正確顯示 | Module 1 | Task 4.1 | 2-3 小時 |
| GAP-002 | 缺少生命週期階段篩選器 | Module 1 | Task 5.1-5.2 | 3-4 小時 |
| GAP-003 | 預測購買金額氣泡圖缺失 | Module 6 | 用戶需求 | 4-5 小時 |
| GAP-004 | Error [object Object] 錯誤 | Module 6 | - | 2 小時 |

### 🟡 High Priority（建議改進）

| ID | 問題 | 模組 | Work_Plan 參考 | 預估工時 |
|----|------|------|--------------|---------|
| GAP-005 | Module 2-6 缺少階段過濾 | All Modules | Task 5.1 | 6-8 小時 |
| GAP-006 | Excel 匯出格式需優化 | Module 1 | Task 5.3 | 3 小時 |
| GAP-007 | 價值等級計算公式確認 | Module 1 | Task 5.4 | 2 小時 |

### 🟢 Medium Priority（未來增強）

| ID | 問題 | 模組 | Work_Plan 參考 | 預估工時 |
|----|------|------|--------------|---------|
| GAP-008 | 檔案數量上限設定 | Module 0 | Task 1.3 | 0.5 小時 |
| GAP-009 | 上傳說明文字優化 | Module 0 | Task 1.1 | 0.5 小時 |
| GAP-010 | 欄位命名規範說明 | Module 0 | Task 1.2 | 1 小時 |

### 🟢 Low Priority（延後開發）

| ID | 問題 | 模組 | Work_Plan 參考 | 預估工時 |
|----|------|------|--------------|---------|
| GAP-011 | 成長率分析 | Module 2-4 | Task 2.4, 3.5, 4.5 | 12-15 小時 |
| GAP-012 | 27 種策略完整描述 | Module 5-6 | Task 6.4 | 6-8 小時 |

---

## 🔍 根本原因分析

### 為什麼會有這些差距？

#### 1. 需求理解偏差
- **原因**: PDF 需求與 Work_Plan 有細微差異
- **影響**: 某些功能（如氣泡圖）未被識別為核心需求
- **解決**: 建立更詳細的需求文檔

#### 2. 測試資料問題
- **原因**: 測試資料可能不符合真實場景
  - 例如：所有單次購買客戶都超過平均購買週期
  - 導致新客數量為 0
- **影響**: 功能看似正常但實際不work
- **解決**: 使用多樣化的測試資料集

#### 3. UI/UX 設計不完整
- **原因**: 專注於後端邏輯，忽略了前端互動
- **影響**: 缺少篩選器、選擇器等關鍵 UI 元素
- **解決**: UI/UX 設計review階段

#### 4. 錯誤處理不足
- **原因**: "Error [object Object]" 顯示前端錯誤處理不完整
- **影響**: 用戶無法理解錯誤原因
- **解決**: 加強 try-catch 和友善的錯誤訊息

---

## 🎯 修復優先順序建議

### Phase 1: 立即修復（本週內）
**預估總工時**: 13-17 小時

1. **GAP-001**: 修復新客數量顯示（2-3 小時）
   - 加入除錯日誌
   - 檢查 `customer_age_days` 和 `avg_ipt` 計算
   - 考慮放寬新客定義條件

2. **GAP-002**: 新增生命週期階段篩選器（3-4 小時）
   - Module 1 UI 新增 selectInput
   - 實作 filtered_data() reactive
   - 更新九宮格資料來源

3. **GAP-003 + GAP-004**: 實作預測購買金額氣泡圖（6-7 小時）
   - 在 Module 6 UI 新增 plotlyOutput
   - 實作 renderPlotly 邏輯
   - 加入完整錯誤處理
   - 測試資料流

4. **GAP-007**: 確認價值等級計算公式（2 小時）
   - Review Work_Plan Task 5.4
   - 與使用者確認需求
   - 更新文檔

### Phase 2: 本月完成（下週）
**預估總工時**: 9-11 小時

5. **GAP-005**: 所有模組新增階段過濾（6-8 小時）
   - Module 2-6 依序新增篩選器
   - 統一 UI 風格
   - 測試資料流

6. **GAP-006**: 優化 Excel 匯出（3 小時）
   - 刪除第一個 xlsx
   - 修改第二個 xlsx 欄位
   - 新增 strategy 欄位

### Phase 3: 次要改進（下個月）
**預估總工時**: 2 小時

7. **GAP-008 至 GAP-010**: Module 0 優化
   - 上傳說明文字
   - 欄位命名規範
   - 檔案數量上限

### Phase 4: 長期規劃（v2.0）
**預估總工時**: 18-23 小時

8. **GAP-011**: 成長率分析
   - 需要資料庫架構支援
   - 建議作為獨立專案

9. **GAP-012**: 完整策略描述
   - 需要行銷專家 review
   - 逐步完善

---

## 📊 修復後的預期狀態

### Module 1: DNA 九宮格分析

#### 修復後應該呈現：
```
顧客狀態分佈：
- 新客數：120 人 (12%)         ✅ 正確顯示
- 主力客數：400 人 (40%)       ✅ 正確顯示
- 瞌睡客數：200 人 (20%)       ✅ 正確顯示
- 半睡客數：150 人 (15%)       ✅ 正確顯示
- 沉睡客數：130 人 (13%)       ✅ 正確顯示

[生命週期階段篩選器: ▼ 選擇階段]   ✅ 新增
- 全部
- 新客
- 主力客
- 瞌睡客
- 半睡客
- 沉睡客

[九宮格會根據選擇的階段動態更新]    ✅ 功能實現
```

### Module 6: 生命週期預測

#### 修復後應該呈現：
```
[預測購買金額 vs 歷史平均金額氣泡圖]  ✅ 新增圖表

圖表說明：
- X軸：歷史平均金額（過去平均每筆交易金額）
- Y軸：預測購買金額（未來預期購買金額）
- 氣泡大小：購買次數（越大 = 購買越頻繁）
- 顏色：生命週期階段

互動功能：
- 滑鼠懸停顯示詳細資訊
- 可zoom放大/縮小
- 可點擊legend過濾

錯誤處理：
- 無資料時顯示友善訊息
- 計算錯誤時顯示具體錯誤原因
- 不再顯示 "[object Object]"    ✅ 修復
```

---

## 🧪 測試計畫

### GAP-001: 新客數量測試

**測試案例 1: 正常情況**
```r
# 測試資料
test_data <- data.frame(
  customer_id = 1:10,
  ni = c(1, 1, 1, 2, 3, 4, 2, 1, 5, 3),
  first_purchase_date = as.Date(c(
    "2024-10-01",  # 25天前
    "2024-09-15",  # 40天前（超過avg_ipt）
    "2024-10-20",  # 5天前
    ...
  ))
)

# 假設 avg_ipt = 30 天

# 預期結果：
# - 客戶 1: 新客（ni=1, 25天 < 30天）
# - 客戶 2: 沉睡客（ni=1, 40天 > 30天）
# - 客戶 3: 新客（ni=1, 5天 < 30天）
# - 客戶 8: 新客（ni=1, 15天 < 30天）

# 預期新客數: 3 人（30%）
```

**測試案例 2: 邊界情況**
```r
# 所有客戶都是單次購買
ni = rep(1, 100)

# 一半在平均週期內，一半超過
first_purchase_date = c(
  rep(Sys.Date() - 15, 50),  # 15天前
  rep(Sys.Date() - 60, 50)   # 60天前
)

# 預期新客數: 50 人（50%）
```

**驗收標準**:
- ✅ 新客數量 > 0
- ✅ 新客百分比合理（5-20%）
- ✅ 新客定義邏輯正確執行
- ✅ UI 正確顯示新客數量

---

### GAP-002 & GAP-005: 階段過濾測試

**測試案例**:
```r
# 選擇「新客」
input$lifecycle_filter <- "newbie"

# 預期結果：
# - 九宮格只顯示新客
# - 統計數字只計算新客
# - 圖表只包含新客資料
```

**驗收標準**:
- ✅ 篩選器正確過濾資料
- ✅ UI 數字與資料一致
- ✅ 圖表正確更新
- ✅ 切換階段時即時更新

---

### GAP-003: 氣泡圖測試

**測試案例**:
```r
# 測試資料
test_data <- data.frame(
  customer_id = 1:50,
  historical_avg = runif(50, 100, 1000),
  predicted_amount = runif(50, 150, 1200),
  ni = sample(1:20, 50, replace = TRUE),
  lifecycle_stage = sample(c("newbie", "active", "sleepy", "half_sleepy", "dormant"), 50, replace = TRUE)
)

# 預期結果：
# - 50 個氣泡
# - 氣泡大小對應 ni
# - 顏色區分階段
# - 懸停顯示完整資訊
```

**驗收標準**:
- ✅ 圖表正確渲染
- ✅ 氣泡大小正確
- ✅ 顏色區分正確
- ✅ 互動功能正常
- ✅ 無錯誤訊息

---

## 📝 修復檢查清單

### 開始修復前

- [ ] 備份當前程式碼
- [ ] 建立新的 git branch（例如：feature/gap-fixes）
- [ ] Review 完整 Work_Plan
- [ ] 與使用者確認需求優先順序

### 修復 GAP-001 (新客數量)

- [ ] 在 module_dna_multi_premium.R Line 390-410 加入除錯日誌
- [ ] 執行應用，查看日誌輸出
- [ ] 檢查 `avg_ipt` 值是否合理
- [ ] 檢查 `customer_age_days` 計算邏輯
- [ ] 如需要，調整新客定義條件
- [ ] 測試案例 1 & 2 通過
- [ ] 更新文檔

### 修復 GAP-002 (階段篩選器)

- [ ] 在 Module 1 UI 新增 selectInput
- [ ] 實作 filtered_data() reactive
- [ ] 更新九宮格資料來源
- [ ] 更新統計卡片資料來源
- [ ] 更新圖表資料來源
- [ ] 測試所有階段切換
- [ ] 確認 UI 即時更新
- [ ] 更新文檔

### 修復 GAP-003 & GAP-004 (氣泡圖)

- [ ] 在 Module 6 定位正確位置
- [ ] 新增 UI: plotlyOutput
- [ ] 實作 Server: renderPlotly
- [ ] 計算歷史平均金額
- [ ] 計算預測購買金額（簡化版）
- [ ] 設定氣泡大小 = ni
- [ ] 設定顏色 = lifecycle_stage
- [ ] 加入完整錯誤處理 (try-catch)
- [ ] 測試正常情況
- [ ] 測試錯誤情況
- [ ] 確認無 "[object Object]" 錯誤
- [ ] 更新文檔

### 修復 GAP-005 (所有模組階段過濾)

- [ ] Module 2: 新增篩選器
- [ ] Module 3: 新增篩選器
- [ ] Module 4: 新增篩選器
- [ ] Module 5: 新增篩選器
- [ ] Module 6: 新增篩選器
- [ ] 統一 UI 風格
- [ ] 測試所有模組
- [ ] 更新文檔

### 完成後

- [ ] 執行完整回歸測試
- [ ] 更新 Work_Plan 狀態
- [ ] 更新 VERIFICATION_SUMMARY
- [ ] 建立新的 BUGFIX_SUMMARY（如有新 bug）
- [ ] Commit 並 push 到 GitHub
- [ ] 通知使用者測試

---

## 📚 相關文檔

1. **[Work_Plan_TagPilot_Premium_Enhancement.md](Work_Plan_TagPilot_Premium_Enhancement.md)** - 原始需求文檔
2. **[COMPLETE_REQUIREMENTS_FROM_PDF_20251025.md](COMPLETE_REQUIREMENTS_FROM_PDF_20251025.md)** - PDF 需求提取
3. **[VERIFICATION_SUMMARY_20251025.md](VERIFICATION_SUMMARY_20251025.md)** - 驗證總結
4. **[BUGFIX_SUMMARY_20251025.md](BUGFIX_SUMMARY_20251025.md)** - 已修復的 Bug

---

## 🎯 成功標準

### Phase 1 完成標準

**功能標準**:
- ✅ 新客數量正確顯示（>0 且合理百分比）
- ✅ 生命週期階段篩選器正常運作
- ✅ 預測購買金額氣泡圖正確渲染
- ✅ 無 "[object Object]" 錯誤

**品質標準**:
- ✅ 所有 Critical 測試案例通過
- ✅ 無新增的錯誤或退步
- ✅ 程式碼有適當註解
- ✅ 文檔更新完整

**使用者驗收標準**:
- ✅ 使用者確認新客數量正確
- ✅ 使用者確認可根據階段篩選
- ✅ 使用者確認氣泡圖符合需求
- ✅ 使用者滿意度 ≥ 8/10

---

**文件版本**: v1.0
**最後更新**: 2025-10-25
**狀態**: 📝 待修復
**預估完成時間**: Phase 1: 1-2 週，Phase 2: 2-3 週

**下一步**: 開始 GAP-001 修復（新客數量顯示問題）
