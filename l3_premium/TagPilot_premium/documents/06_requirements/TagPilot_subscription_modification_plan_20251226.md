# TagPilot 訂閱版修改計畫

**文件建立日期**: 2025-12-26
**來源文件**: `TagPilot訂閱板修改建議_20251223.pdf`
**狀態**: 待實作

---

## 修改原則

1. **不刪除程式碼**：不使用的模組或功能以 comment out 方式處理
2. **新功能獨立模組**：新增功能建立新模組，不修改現有模組結構
3. **UI 顏色標示**：新增可識別欄位需在 UI 以藍色標示
4. **保持向下相容**：確保現有功能不受影響

---

## 修改項目總覽

| 項次 | 類型 | 優先級 | 狀態 | 影響模組 |
|------|------|--------|------|----------|
| 1 | 欄位識別 + UI 顏色 | P1 | 待實作 | `module_upload.R` |
| 2 | 名稱修正 | P1 | 待實作 | `module_customer_value_analysis.R` |
| 3 | CAI 修正 | P1 | 待實作 | `module_customer_activity.R` |
| 4 | 移除功能 | P2 | 待實作 | `module_customer_activity.R` |
| 5 | 移除功能 | P2 | 待實作 | `module_customer_status.R` |
| 6 | 移除功能 | P2 | 待實作 | `module_dna_multi_premium_v2.R` |
| 7 | CLV 計算 | - | **跳過** | - |
| 8 | 移除功能 | P2 | 待實作 | `module_rsv_matrix.R` |
| 9 | 選單重命名 | P1 | 待實作 | `app.R` |
| 10 | 文字修正 | P1 | 待實作 | `module_rsv_matrix.R` |
| 11 | **新增功能** | P1 | 待實作 | **新建模組** |
| 12 | **新增功能** | P2 | 待實作 | **新建模組** |

---

## 詳細修改規格

### 1️⃣ 新增欄位識別 + UI 藍色標示

**檔案**: `modules/module_upload.R`

#### 新增可識別欄位

| 欄位類型 | 現有識別 | **新增識別（藍色標示）** |
|----------|----------|-------------------------|
| ID/Email | `customer_id`, `email`, `buyer_email` | `ship-postal-code` |
| purchase_time | `payment_time`, `purchase_time`, `purchase_date`, `date` | `purchase-date` |
| price | `lineitem_price`, `amount`, `price` | `item-price` |

#### UI 修改

```r
# 在 UI 說明文字中，新增欄位以藍色顯示
# 使用 HTML span 標籤
tags$span(style = "color: #007bff;", "ship-postal-code")
tags$span(style = "color: #007bff;", "purchase-date")
tags$span(style = "color: #007bff;", "item-price")
```

#### 實作位置

- [ ] 修改 `module_upload.R` 的欄位識別邏輯
- [ ] 修改 UI 說明區塊，新增藍色標示

---

### 2️⃣ 購買週期名稱修正

**檔案**: `modules/module_customer_value_analysis.R`

| 現況 | 修改為 |
|------|--------|
| 中位購買週期 | **平均購買週期** |

#### 實作位置

- [ ] 修改 UI 標籤文字
- [ ] 修改計算邏輯（如需從中位數改為平均數）

---

### 3️⃣ CAI 顧客活躍度修正（重要）

**檔案**: `modules/module_customer_activity.R`

#### 3.1 名稱修改

| 現況 | 修改為 |
|------|--------|
| 平均 CAI 值 | **平均顧客活躍度** |
| 活躍客戶比率 | **漸趨活躍消費客戶比例** |
| 穩定客戶比例 | **穩定消費客戶比率** |
| 靜止客戶比例 | **漸趨靜止消費客戶比例** |
| CAI 係數 | **顧客活躍度係數** |

#### 3.2 分群標準調整

| 類型 | 現行標準 | **新標準** |
|------|----------|-----------|
| 漸趨活躍客 | `cai_ecdf >= 0.8` | **`cai >= 0.2`** |
| 穩定消費客 | `0.2 <= cai_ecdf < 0.8` | **`-0.2 < cai < 0.2`** |
| 漸趨靜止客 | `cai_ecdf < 0.2` | **`cai < -0.2`** |

```r
# 新分群邏輯
activity_segment = case_when(
  cai >= 0.2 ~ "漸趨活躍消費客戶",
  cai > -0.2 ~ "穩定消費客戶",
  TRUE ~ "漸趨靜止消費客戶"
)
```

#### 3.3 資料篩選

- CAI 計算需 **ni >= 4**
- 顯示活躍度分析時，先篩選 ni >= 4 的客戶

#### 實作位置

- [ ] 修改 UI 所有相關標籤
- [ ] 修改分群邏輯（使用 cai 原始值而非 cai_ecdf）
- [ ] 修改資料篩選邏輯
- [ ] 修改客戶明細表欄位名稱

---

### 4️⃣ Comment Out：生命週期 × CAI 交叉分析

**檔案**: `modules/module_customer_activity.R`

#### 處理方式

```r
# ============================================================================
# [COMMENTED OUT - 2025-12-26] 生命週期 × CAI 交叉分析
# 原因：簡化分析內容，避免廠商覺得太複雜
# ============================================================================
# output$lifecycle_cai_matrix <- renderPlotly({
#   ... 原有程式碼 ...
# })
```

#### 實作位置

- [ ] Comment out UI 區塊
- [ ] Comment out Server 邏輯

---

### 5️⃣ Comment Out：顧客動態 × 流失風險矩陣

**檔案**: `modules/module_customer_status.R`

#### 處理方式

```r
# ============================================================================
# [COMMENTED OUT - 2025-12-26] 顧客動態 × 流失風險矩陣
# 原因：簡化分析內容
# ============================================================================
```

#### 實作位置

- [ ] Comment out UI 區塊（熱力圖/矩陣圖）
- [ ] Comment out Server 邏輯

---

### 6️⃣ Comment Out：顧客市場區隔分析

**檔案**: `modules/module_dna_multi_premium_v2.R` 或獨立模組

#### 處理方式

```r
# ============================================================================
# [COMMENTED OUT - 2025-12-26] 顧客市場區隔分析
# 原因：簡化分析內容
# ============================================================================
```

#### 實作位置

- [ ] Comment out 九宮格相關 UI
- [ ] Comment out 處理狀態說明區塊
- [ ] Comment out 分析方法資訊區塊

---

### 7️⃣ CLV 計算 - **跳過**

**狀態**: 不需修改

CLV 計算目前使用 MAMBA 的 `analysis_dna()` 函數，包含：
- `clv`: 預測未來 10 年價值
- `pcv`: Past Customer Value

計算方式正確，無需調整。

---

### 8️⃣ Comment Out：客戶類型與策略對應表

**檔案**: `modules/module_rsv_matrix.R`

#### 處理方式

```r
# ============================================================================
# [COMMENTED OUT - 2025-12-26] 客戶類型與策略對應表
# 原因：將由新的「客戶行銷決策表」取代
# ============================================================================
# output$strategy_table <- renderDT({
#   ... 原有程式碼 ...
# })
```

#### 實作位置

- [ ] Comment out 策略對應表 UI
- [ ] Comment out 策略對應表 Server 邏輯

---

### 9️⃣ 選單名稱調整

**檔案**: `app.R`

#### Sidebar 選單修改

| 現況 | 修改為 |
|------|--------|
| 顧客動態 | **顧客狀態** |
| 顧客基礎價值 | **顧客結構** |
| - | RSV 生命力矩陣下新增：**客戶行銷決策表** |

#### 實作位置

- [ ] 修改 `app.R` sidebar 選單項目
- [ ] 新增「客戶行銷決策表」選單項目

---

### 🔟 RSV 高風險客戶文字修正

**檔案**: `modules/module_rsv_matrix.R`

| 現況 | 修改為 |
|------|--------|
| 0% 客戶處於高流失風險 | **0% 客戶屬於高風險客戶** |

#### 實作位置

- [ ] 修改 `output$high_risk_pct` 的文字輸出

---

### 1️⃣1️⃣ **新增模組**：客戶行銷決策表

**新檔案**: `modules/module_marketing_decision.R`

#### 功能說明

根據多個標籤組合，為每位客戶提供具體行銷策略建議。

#### 決策邏輯表

| 順序 | 判斷條件 | 疊加判斷 | 主策略 | 行銷目的 |
|------|----------|----------|--------|----------|
| ① | NES ∈ {S1,S2,S3} | 不看其他 | 喚醒/回流 | 防流失 |
| ② | CAI 低（趨勢下降）| 靜止戶=中/高 | 關係修復 | 降反感 |
| ③ | 靜止戶=高 | CLV 高/低分流 | 成本控管 | 避免浪費 |
| ④ | NES = N（新客）| 穩定度/CLV 不納入 | Onboarding | 建立信任 |
| ⑤ | RFM ≤ 5 | CLV 低 | 低成本培養 | 不放棄 |
| ⑥-1 | 5 < RFM ≤ 10 | 穩定度低 | 標準培養（保守）| 建立穩定節奏 |
| ⑥-2 | 5 < RFM ≤ 10 | 穩定度中 | 標準培養（核心）| 擴展需求 |
| ⑥-3 | 5 < RFM ≤ 10 | 穩定度高 | 標準培養（進階）| 提升客單 |
| ⑦-1 | RFM 高 | 穩定度低 | VIP 維繫 | 穩定度低 |
| ⑦-2 | RFM 高 | 穩定度中 | VIP 維繫 | 穩定度中 |
| ⑦-3 | RFM 高 | 穩定度高 | VIP 維繫 | 穩定度高 |
| ⑧ | NES = E0 | CLV 高 | 尊榮維繫 | 穩定關係 |
| ⑨ | 其他/資料不足 | 兜底 | 基礎維繫 | 周延覆蓋 |

#### 模組結構

```r
# modules/module_marketing_decision.R

# UI Function
marketingDecisionUI <- function(id) {
  ns <- NS(id)
  # 決策表 UI
}

# Server Function
marketingDecisionServer <- function(id, customer_data) {
  moduleServer(id, function(input, output, session) {
    # 決策邏輯實作
  })
}

# 決策引擎函數
assign_marketing_strategy <- function(df) {
  # 根據決策順序分配策略
}
```

#### 實作位置

- [ ] 建立 `modules/module_marketing_decision.R`
- [ ] 在 `app.R` 註冊模組
- [ ] 新增 sidebar 選單項目

---

### 1️⃣2️⃣ **新增模組**：客戶標籤輸出表

**新檔案**: `modules/module_customer_export.R`

#### 功能說明

提供完整客戶標籤輸出，可下載 CSV。

#### 輸出欄位

| 欄位類型 | 欄位名稱 |
|----------|----------|
| 基礎資料 | 客戶 ID |
| RFM | RFM 分數、最近購買天數 (R)、購買頻率 (F)、購買金額 (M) |
| 活躍度 | CAI / 顧客活躍度係數、NES |
| 風險 | 流失風險 |
| 交易 | 交易次數、平均購買間隔天數、回購時間 |
| 價值 | 顧客價值、顧客終身價值 (CLV) |
| RSV | R 風險、S 穩定、V 價值、客戶類型 |
| **行銷** | **行銷方案建議**（來自決策表）|

#### 模組結構

```r
# modules/module_customer_export.R

# UI Function
customerExportUI <- function(id) {
  ns <- NS(id)
  # 客戶明細表 + 下載按鈕
}

# Server Function
customerExportServer <- function(id, customer_data, marketing_strategy) {
  moduleServer(id, function(input, output, session) {
    # 合併所有標籤
    # 提供篩選功能
    # CSV 下載
  })
}
```

#### 未來功能（Phase 2）

- 新增欄位：**推薦產品**
- 方法：購物籃分析（條件機率）或隨機森林
- 資料需求：需上傳含產品交易品項的資料

#### 實作位置

- [ ] 建立 `modules/module_customer_export.R`
- [ ] 整合至 RSV 生命力矩陣頁面或獨立頁面
- [ ] 實作 CSV 下載功能

---

## 實作順序建議

### Phase 1：基礎修改（P1 優先級）

1. **欄位識別 + UI 藍色標示**（#1）
2. **購買週期名稱修正**（#2）
3. **CAI 顧客活躍度修正**（#3）
4. **選單名稱調整**（#9）
5. **RSV 文字修正**（#10）

### Phase 2：功能精簡（P2 優先級）

6. **Comment out 生命週期 × CAI 交叉分析**（#4）
7. **Comment out 顧客動態 × 流失風險矩陣**（#5）
8. **Comment out 顧客市場區隔分析**（#6）
9. **Comment out 客戶類型與策略對應表**（#8）

### Phase 3：新增功能

10. **新增客戶行銷決策表模組**（#11）
11. **新增客戶標籤輸出表模組**（#12）

### Phase 4：未來功能

12. 產品推薦功能（購物籃分析）

---

## 測試計畫

### 功能測試

- [ ] 欄位識別測試（上傳含新欄位的資料）
- [ ] CAI 分群測試（驗證新閾值 ±0.2）
- [ ] 選單導航測試
- [ ] 行銷決策表邏輯測試
- [ ] CSV 輸出測試

### 回歸測試

- [ ] 現有功能不受影響
- [ ] Comment out 的功能可輕鬆還原
- [ ] 資料流程完整性

---

## 相關文件

- 原始需求：`documents/06_requirements/TagPilot訂閱板修改建議_20251223.pdf`
- 資料流程：`documents/02_architecture/data_flow_analysis.md`
- RSV 模組說明：`documents/02_architecture/module_doc/module_rsv_matrix.md`

---

**文件版本**: 1.0
**建立者**: Claude AI Assistant
**最後更新**: 2025-12-26
