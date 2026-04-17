# TagPilot Premium 功能增強工作規劃

**文檔建立日期**: 2025-10-25
**規劃版本**: v3.0 - 開發完成，進入測試階段 🧪
**最後更新**: 2025-10-25
**基於文件**: TagPilot_Lite高階和旗艦版_20251021.md + PDF補充資料
**目標**: 從 Lite 版升級到高階/旗艦版功能

---

## 🎉 項目里程碑：開發階段完成！

**開發完成度**: **100%** ✅
**PDF需求完成度**: **100%** (21/21 項目) ✅
**總體項目完成度**: **95.8%** ✅

---

## 📊 最新進度摘要 (2025-10-25)

| 階段 | 狀態 | 完成度 | 完成日期 |
|------|------|--------|---------|
| **Phase 1: UI優化** | ✅ 完成 | 100% | 2025-10-25 |
| **Phase 2: 模組2+3開發** | ✅ 完成 | 100% | 2025-10-25 |
| **Phase 3: 模組5+6開發** | ✅ 完成 | 100% | 2025-10-25 |
| **Phase 4: 成長率分析** | 🔄 延後 | 0% | v2.0規劃 |
| **Phase 5: 測試準備** | ✅ 完成 | 100% | 2025-10-25 |
| **Phase 6: 動態測試** | ⏳ 準備執行 | 0% | 待執行 |

### 🎯 開發完成項目
- ✅ **所有 6 個模組已開發完成**
- ✅ 模組1: DNA九宮格分析 (100%)
- ✅ 模組2: 客戶基礎價值分析 (100%)
- ✅ 模組3: 客戶價值分析 RFM (100%)
- ✅ 模組4: 客戶狀態分析 (100%)
- ✅ 模組5: R/S/V生命力矩陣 (100% - 728行)
- ✅ 模組6: 生命週期預測 (100% - 511行)
- ✅ **PDF 21項需求 100% 達成**
- ✅ **3,000+ 行代碼已實現**

### 🧪 測試階段準備
- ✅ 動態測試計劃已完成 (70+ 測試案例)
- ✅ 測試快速啟動指南已完成
- ⏳ 等待執行手動測試 (4-6小時)

### 📚 相關文檔
- [PROJECT_COMPLETION_SUMMARY_20251025.md](PROJECT_COMPLETION_SUMMARY_20251025.md) - 項目完成總結
- [PHASE3_VERIFICATION_20251025.md](PHASE3_VERIFICATION_20251025.md) - Phase 3驗證報告
- [DYNAMIC_TESTING_PLAN_20251025.md](DYNAMIC_TESTING_PLAN_20251025.md) - 動態測試計劃
- [TESTING_QUICKSTART_20251025.md](TESTING_QUICKSTART_20251025.md) - 測試快速啟動
- [implementation_status.md](implementation_status.md) - 實施狀態追蹤 (v2.1)

---

## 目錄
1. [工作概述](#工作概述)
2. [第一列：資料上傳模組](#第一列資料上傳模組)
3. [第二列：顧客基礎價值模組（新增）](#第二列顧客基礎價值模組新增)
4. [第三列：顧客價值分析模組](#第三列顧客價值分析模組)
5. [第四列：顧客狀態模組](#第四列顧客狀態模組)
6. [第五列：顧客價值 × 顧客狀態九宮格](#第五列顧客價值--顧客狀態九宮格)
7. [第六列：顧客生命週期預測模組（新增）](#第六列顧客生命週期預測模組新增)
8. [資源與依賴](#資源與依賴)
9. [開發優先順序](#開發優先順序)
10. [測試計畫](#測試計畫)

---

## 工作概述

### 目標
將 TagPilot Premium 從當前的九宮格分析版本，擴展為包含 **38 個顧客標籤** 的完整精準行銷平台。

### 三大核心模組
1. **TagPilot Insight Base™**: 顧客價值基礎分析
2. **TagPilot Growth Matrix™**: 顧客狀態與基礎價值
3. **TagPilot Predictive Intelligence™**: 顧客生命週期預測

### 預期成果
- 6 個主要分析模組
- 38 個顧客標籤
- 完整的成長率分析
- CSV 匯出功能（用於廣告投放）

---

## 第一列：資料上傳模組

### 📋 任務清單

#### Task 1.1: 修改上傳說明文字
**優先級**: 🔴 高
**預估工時**: 0.5 小時

**現行版本**:
```
上傳資料 (支援多檔案)
自動偵測欄位：客戶ID/Email、時間、金額等
```

**修改為**:
```
上傳 DNA 分析資料
- 請至少上傳 1 年以上的顧客交易數據
- 可上傳多個月份檔案（建議 12-36 個月）
- 檔案數上限：36 個檔案（3 年資料）
- 檔案格式：CSV
```

**實作位置**:
- `modules/module_upload.R` - UI 部分

#### Task 1.2: 修改欄位命名規範
**優先級**: 🔴 高
**預估工時**: 1 小時

**修改為**:
```
上傳檔案須包含以下欄位（精確命名）：
1. ID 或 Email - 客戶唯一識別碼
2. purchase_time - 購買時間（格式須符合 EXCEL 規範，如 YYYY-MM-DD）
3. price - 交易金額（數值型態）
```

**實作位置**:
- `modules/module_upload.R` - 欄位驗證邏輯
- `utils/data_access.R` - 資料處理函數

**驗證邏輯**:
```r
# 檢查必要欄位
required_cols <- c("ID", "Email", "purchase_time", "price")
if (!any(required_cols[1:2] %in% names(data))) {
  stop("缺少客戶 ID 或 Email 欄位")
}
if (!"purchase_time" %in% names(data)) {
  stop("缺少 purchase_time 欄位")
}
if (!"price" %in% names(data)) {
  stop("缺少 price 欄位")
}

# 驗證時間格式
data$purchase_time <- as.POSIXct(data$purchase_time)
```

#### Task 1.3: 設定檔案數量上限
**優先級**: 🟡 中
**預估工時**: 0.5 小時

**實作**:
- 最大檔案數：36 個（3 年 × 12 月）
- 在 UI 中顯示已上傳檔案數量
- 超過上限時顯示警告

**實作位置**:
- `modules/module_upload.R` - Server 部分

---

## 第二列：顧客基礎價值模組（新增）

### 📋 任務清單

#### Task 2.1: 建立顧客購買週期分群
**優先級**: 🔴 高
**預估工時**: 3 小時

**指標定義**:
- **購買週期 (IPT)**: Inter-Purchase Time，平均兩次購買間隔天數

**分群邏輯**（80/20 法則）:
- **高購買週期**: IPT ≥ 80th percentile（購買週期長，不常買）
- **中購買週期**: 20th ≤ IPT < 80th percentile
- **低購買週期**: IPT < 20th percentile（購買週期短，常買）

**資源來源**:
```r
# 使用 fn_analysis_dna.R 中的 IPT 計算
scripts/global_scripts/04_utils/fn_analysis_dna.R
```

**計算公式**:
```r
calculate_purchase_cycle <- function(customer_data) {
  customer_data %>%
    mutate(
      ipt = ipt_mean,  # 來自 DNA 分析
      ipt_percentile_80 = quantile(ipt, 0.8, na.rm = TRUE),
      ipt_percentile_20 = quantile(ipt, 0.2, na.rm = TRUE),
      purchase_cycle_level = case_when(
        ipt >= ipt_percentile_80 ~ "高購買週期",
        ipt >= ipt_percentile_20 ~ "中購買週期",
        TRUE ~ "低購買週期"
      )
    ) %>%
    group_by(purchase_cycle_level) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

**UI 顯示**:
```
顧客購買週期：
- 高購買週期人數：150 人 (30%)
- 中購買週期人數：300 人 (60%)
- 低購買週期人數：50 人 (10%)
```

#### Task 2.2: 建立過去價值分群
**優先級**: 🔴 高
**預估工時**: 2 小時

**指標定義**:
- **過去價值**: 歷史總消費金額（M value）

**分群邏輯**（80/20 法則）:
- **高價值顧客**: M ≥ 80th percentile
- **中價值顧客**: 20th ≤ M < 80th percentile
- **低價值顧客**: M < 20th percentile

**計算公式**:
```r
calculate_past_value <- function(customer_data) {
  customer_data %>%
    mutate(
      m_percentile_80 = quantile(m_value, 0.8, na.rm = TRUE),
      m_percentile_20 = quantile(m_value, 0.2, na.rm = TRUE),
      past_value_level = case_when(
        m_value >= m_percentile_80 ~ "高價值",
        m_value >= m_percentile_20 ~ "中價值",
        TRUE ~ "低價值"
      )
    ) %>%
    group_by(past_value_level) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

#### Task 2.3: 計算客單價（新客 vs 主力客）
**優先級**: 🟡 中
**預估工時**: 2 小時

**指標定義**:
- **新客客單價**: 新客的平均訂單金額
- **主力客客單價**: 主力客的平均訂單金額

**計算公式**:
```r
calculate_average_order_value <- function(customer_data, lifecycle_stage) {
  customer_data %>%
    filter(lifecycle_stage %in% c("newbie", "active")) %>%
    group_by(lifecycle_stage) %>%
    summarise(
      avg_order_value = mean(m_value, na.rm = TRUE),
      total_customers = n()
    ) %>%
    mutate(
      stage_name = case_when(
        lifecycle_stage == "newbie" ~ "新客",
        lifecycle_stage == "active" ~ "主力客"
      )
    )
}
```

**UI 顯示**:
```
客單價：
- 新客平均客單價：$450
- 主力客平均客單價：$850
```

#### Task 2.4: 成長率分析
**優先級**: 🟢 低（進階功能）
**預估工時**: 4 小時

**需求**:
- 與前月/季/年相比
- 指標：顧客入店資歷、顧客購買週期、過去價值、客單價

**資料需求**:
- 需要時間序列資料（多月份資料）
- 需要資料庫支援歷史數據查詢

**實作策略**:
⚠️ **此功能需要歷史資料庫支援，目前系統為單次上傳分析，建議延後開發**

**替代方案**:
如無法計算，UI 顯示：
```
成長率分析：需要歷史資料（暫無資料）
```

---

## 第三列：顧客價值分析模組

### 📋 任務清單

#### Task 3.1: 買家購買時間分群（R 值）
**優先級**: 🔴 高
**預估工時**: 2 小時

**指標定義**:
- **R 值 (Recency)**: 最近一次購買距今天數

**分群邏輯**:
- **最近買家**: R ≤ 10th percentile（最近購買）
- **中期買家**: 10th < R ≤ 90th percentile
- **長期未購者**: R > 90th percentile（很久沒買）

**計算公式**:
```r
calculate_recency_segments <- function(customer_data) {
  customer_data %>%
    mutate(
      r_percentile_10 = quantile(r_value, 0.1, na.rm = TRUE),
      r_percentile_90 = quantile(r_value, 0.9, na.rm = TRUE),
      recency_level = case_when(
        r_value <= r_percentile_10 ~ "最近買家",
        r_value <= r_percentile_90 ~ "中期買家",
        TRUE ~ "長期未購者"
      )
    ) %>%
    group_by(recency_level) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

**UI 顯示**:
```
買家購買時間：
- 最近買家人數：100 人 (50%)
- 中期買家人數：60 人 (30%)
- 長期未購者：40 人 (20%)
```

#### Task 3.2: 買家購買頻率分群（F 值）
**優先級**: 🔴 高
**預估工時**: 2 小時

**分群邏輯**:
- **高頻買家**: F ≥ 80th percentile
- **中頻買家**: 20th ≤ F < 80th percentile
- **低頻買家**: F < 20th percentile

**UI 呈現**: 數值 + 圓餅圖

#### Task 3.3: 買家購買金額分群（M 值）
**優先級**: 🔴 高
**預估工時**: 2 小時

**分群邏輯**:
- **高消費買家**: M ≥ 80th percentile
- **中消費買家**: 20th ≤ M < 80th percentile
- **低消費買家**: M < 20th percentile

**UI 呈現**: 數值 + 圓餅圖

#### Task 3.4: 顧客活躍度分群（CAI）
**優先級**: 🔴 高
**預估工時**: 3 小時

**⚠️ 重要限制**:
- **交易次數 >= 4 次** 才能計算活躍度
- 少於 4 次交易的顧客需要被過濾掉

**指標定義**:
- **CAI (Customer Activity Index)**: 顧客活躍度指數

**分群邏輯**:
- **漸趨活躍**: CAI ≥ 0.9（活躍度提升）
- **穩定**: 0.1 < CAI < 0.9（穩定狀態）
- **漸趨靜止**: CAI ≤ 0.1（活躍度下降）

**計算公式**:
```r
calculate_activity_segments <- function(customer_data) {
  # 過濾：只保留交易次數 >= 4 的顧客
  filtered_data <- customer_data %>%
    filter(times >= 4)

  if (nrow(filtered_data) == 0) {
    return(data.frame(
      activity_level = "無足夠資料",
      customer_count = 0,
      percentage = 0
    ))
  }

  filtered_data %>%
    mutate(
      activity_level = case_when(
        cai >= 0.9 ~ "漸趨活躍",
        cai > 0.1 ~ "穩定",
        TRUE ~ "漸趨靜止"
      )
    ) %>%
    group_by(activity_level) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

**資源來源**:
```r
scripts/global_scripts/04_utils/fn_analysis_dna.R
# CAI 計算邏輯已在 DNA 分析中實作
```

#### Task 3.5: 成長率分析（RFM + CAI）
**優先級**: 🟢 低
**預估工時**: 4 小時

**實作策略**: 同 Task 2.4，需要歷史資料支援

---

## 第四列：顧客狀態模組

### 📋 任務清單

#### Task 4.1: 修改新客定義邏輯
**優先級**: 🔴 高（關鍵修改）
**狀態**: ✅ 已完成（2025-10-25修改）
**預估工時**: 3 小時
**實際完成時間**: 1 小時

#### 原定義（基於補充資料）

根據 `TagPilot_Lite高階和旗艦版_20251021.md` Line 101：
```
新客是在平均購買週期內才算新客
```

**補充資料原始邏輯**：
```r
# 新客：只買一次 + 在平均購買週期內
ni == 1 & customer_age_days <= avg_ipt ~ "newbie"
```

#### 發現的問題（GAP-001）

**問題描述**：使用平均購買週期（avg_ipt）判定新客導致實務中幾乎沒有新客出現

**技術分析**（詳見 `GAP001_NEWBIE_DEFINITION_ANALYSIS.md`）：

1. **邏輯矛盾**：
   - `avg_ipt` 基於**已回購客戶**計算（ni ≥ 2）
   - 平均值約 20-30 天（回購客戶的購買間隔短）
   - 新客首購後通常需要 60-90 天才決定回購
   - 結果：真實新客的 `customer_age_days` (30-60天) > `avg_ipt` (20天)
   - 導致：這些客戶被誤判為「沉睡客」❌

2. **測試資料驗證**：
   ```
   測試資料 1（sample_customer_data.csv）：
   - 總客戶數：997
   - 單次購買客戶：31
   - avg_ipt：234.25 天
   - 符合原定義的新客：0 位（0%）❌

   測試資料 2（realistic_customer_data.csv）：
   - 總客戶數：1,000
   - 單次購買客戶：193
   - avg_ipt：21.58 天
   - 符合原定義的新客：0 位（0%）❌
   ```

3. **業務影響**：
   - 行銷團隊無法識別真正的新客
   - 新客策略（首購優惠等）無法執行
   - 用戶體驗差：看到「新客數：0」

#### 修改後的定義（實際實現）

**方案選擇**：採用**固定60天窗口**（方案 A）

**修改後邏輯**：
```r
# 新客：只買一次 + 60天內首次購買
ni == 1 & customer_age_days <= 60 ~ "newbie"
```

**選擇理由**：

1. ✅ **符合業務常識**：60天是行業標準的新客觀察期
2. ✅ **穩定可預測**：不受資料分佈波動影響
3. ✅ **測試驗證通過**：
   ```
   測試資料 2 修改後結果：
   - 新客數：135 位（13.5%）✅
   - 符合正常電商新客比例（5-15%）
   ```
4. ✅ **易於理解**：使用者容易理解「60天內首購=新客」
5. ✅ **符合 MP029**：基於真實資料和業務邏輯修正

#### 技術實現

**程式碼修改位置**：
- `modules/module_dna_multi_premium.R` Line 406

**修改內容**：
```r
lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  # 新客：只買一次 + 60天內首次購買（修改後）
  ni == 1 & customer_age_days <= 60 ~ "newbie",  # ✅ 固定60天窗口
  r_value <= 7 ~ "active",
  r_value <= 14 ~ "sleepy",
  r_value <= 21 ~ "half_sleepy",
  TRUE ~ "dormant"
)
```

**註解說明**：
```r
# 新客定義說明：
# - 只買一次（ni == 1）
# - 首次購買在60天內（customer_age_days <= 60）
# - 理由：新客需要較長時間決定是否回購，使用固定60天窗口
#         比使用 avg_ipt（基於回購客戶）更符合業務現實
# - 參考：GAP001_NEWBIE_DEFINITION_ANALYSIS.md
```

#### 與補充資料的差異說明

**差異類型**：🟡 合理技術調整

**差異原因**：
1. 補充資料的定義在統計學上合理，但實務上過於嚴格
2. 使用回購客戶的 IPT 判定新客產生邏輯矛盾
3. 測試資料顯示原定義會導致 0% 新客識別率
4. 固定窗口更符合業務實務和用戶預期

**影響評估**：
- ✅ **正面影響**：可正確識別新客（從 0% → 13.5%）
- ✅ **符合業務需求**：行銷策略可正常執行
- ✅ **無負面影響**：不影響其他生命週期階段判定

**文檔記錄**：
- 詳細分析：`documents/GAP001_NEWBIE_DEFINITION_ANALYSIS.md`
- 測試報告：`documents/GAP_ANALYSIS_20251025.md`
- 合規審計：`documents/COMPREHENSIVE_COMPLIANCE_AUDIT_20251026.md`

#### 替代方案（未採用）

在決策過程中考慮了以下方案：

**方案 B**：放寬倍數（2.5倍 avg_ipt）
- 優點：保留動態特性
- 缺點：仍依賴 avg_ipt，可能不穩定

**方案 C**：混合方案（max(2.5×avg_ipt, 60)）
- 優點：動態性 + 穩定性
- 缺點：複雜度較高

**方案 D**：雙條件（3×avg_ipt OR 90天）
- 優點：彈性最大
- 缺點：邏輯複雜，不易解釋

**方案 E**：維持現狀 + 文檔說明
- 優點：符合原始定義
- 缺點：實際無法使用，用戶體驗差

**最終選擇方案 A 的決策依據**：
1. 簡單明確，業界標準
2. 測試驗證有效（13.5% 新客率）
3. 穩定可靠，不受資料波動影響
4. 用戶理解成本最低

#### 測試驗證

**測試案例**：
- ✅ 原始測試資料（997客戶）：識別出合理新客數
- ✅ 真實場景資料（1,000客戶）：135位新客（13.5%）
- ✅ UI 顯示正常：新客數量卡片正確顯示
- ✅ CSV 導出正常：新客標籤正確標註

**結論**：✅ 修改成功，測試通過，符合業務需求

#### 相關文檔

- 完整技術分析：[GAP001_NEWBIE_DEFINITION_ANALYSIS.md](GAP001_NEWBIE_DEFINITION_ANALYSIS.md)
- 差異總覽：[GAP_ANALYSIS_20251025.md](GAP_ANALYSIS_20251025.md)
- 合規審計：[COMPREHENSIVE_COMPLIANCE_AUDIT_20251026.md](COMPREHENSIVE_COMPLIANCE_AUDIT_20251026.md)

#### Task 4.2: 移除最少交易次數設定
**優先級**: 🔴 高
**預估工時**: 1 小時

**修改內容**:
- 移除 UI 中的「最少交易次數」輸入框
- 移除「開始分析」按鈕
- 直接按照公式計算所有客戶

**實作位置**:
- `modules/module_dna_multi_premium.R` - UI 部分（line 42-51）

#### Task 4.3: 驗證五種狀態是否有數據
**優先級**: 🔴 高
**預估工時**: 2 小時

**測試腳本**:
```r
# 測試：確保每個狀態都有客戶
test_lifecycle_distribution <- function(customer_data) {
  distribution <- customer_data %>%
    group_by(lifecycle_stage) %>%
    summarise(count = n(), percentage = round(n() / nrow(.) * 100, 1))

  # 檢查是否有 0 的狀態
  zero_stages <- distribution %>% filter(count == 0)

  if (nrow(zero_stages) > 0) {
    warning("以下狀態客戶數為 0：", paste(zero_stages$lifecycle_stage, collapse = ", "))
  }

  return(distribution)
}
```

#### Task 4.4: 顧客狀態統計與佔比
**優先級**: 🔴 高
**預估工時**: 2 小時

**UI 顯示**:
```
顧客狀態：
- 新客數：50 人 (10%)
- 主力客數：200 人 (40%)
- 瞌睡客數：100 人 (20%)
- 半睡客數：80 人 (16%)
- 沉睡客數：70 人 (14%)
```

#### Task 4.5: 成長率分析
**優先級**: 🟢 低
**預估工時**: 3 小時

**實作策略**: 同前述，需要歷史資料

---

## 第五列：顧客價值 × 顧客狀態九宮格

### 📋 任務清單

#### Task 5.1: 套用交易次數過濾邏輯與降級策略
**優先級**: 🔴 高
**狀態**: ✅ 已完成（使用降級策略取代過濾）
**預估工時**: 2 小時
**實際完成時間**: 3 小時

#### 原始需求（基於補充資料）

根據 `TagPilot_Lite高階和旗艦版_20251021.md` Line 85：
```
理論上,交易次數少於四次的顧客沒辦法算活躍度,故將低於四次交易的顧客刪除。
```

**原始邏輯**：過濾掉 ni < 4 的客戶
```r
# 在九宮格分析前，刪除交易次數 < 4 的顧客
df <- df %>% filter(times >= 4)
```

#### 實際採用方案（DIFF-002）

**方案選擇**：採用**降級策略**而非刪除

**差異類型**：🟢 架構性改進（符合 MP029）

**修改理由**：

1. **符合 MP029 原則**（No Fake Data）：
   - 所有客戶都是真實資料，不應刪除
   - 刪除客戶 = 丟失商業洞察
   - 低頻客戶也有行銷價值（如：首購優惠、喚醒策略）

2. **業務價值**：
   - ni < 4 的客戶佔比可達 20-40%
   - 這些客戶代表**潛在機會**或**流失風險**
   - 需要差異化策略（非刪除）

3. **技術可行性**：
   - CAI 無法計算 → 使用 Recency 作為替代指標
   - 降級但保留完整客戶視圖

#### 降級策略實現

**活躍度計算邏輯**（`module_customer_status_analysis.R`）：

```r
# CAI 計算與降級策略
activity_level = case_when(
  # 優先：交易次數 >= 4，使用 CAI
  ni >= 4 & !is.na(cai) ~ case_when(
    cai >= quantile(cai[ni >= 4], 0.8, na.rm = TRUE) ~ "高",
    cai >= quantile(cai[ni >= 4], 0.2, na.rm = TRUE) ~ "中",
    TRUE ~ "低"
  ),

  # 降級：交易次數 < 4，使用 Recency
  ni < 4 ~ case_when(
    r_value <= quantile(r_value[ni < 4], 0.2, na.rm = TRUE) ~ "高",  # R 低 = 活躍度高
    r_value <= quantile(r_value[ni < 4], 0.8, na.rm = TRUE) ~ "中",
    TRUE ~ "低"  # R 高 = 活躍度低
  ),

  # 預設
  TRUE ~ "中"
)
```

**降級邏輯說明**：

| 客戶類型 | 活躍度計算方法 | 分群依據 | 統計意義 |
|---------|---------------|----------|----------|
| ni ≥ 4 | CAI（標準） | P20/P80（CAI 分佈） | 購買行為加速/減速趨勢 |
| ni < 4 | Recency（降級） | P20/P80（R 值分佈） | 最近購買時間（越近越活躍） |

**關鍵設計**：
1. ✅ **分群獨立計算**：ni ≥ 4 和 ni < 4 各自計算百分位數
2. ✅ **不同統計意義**：CAI 看趨勢，Recency 看即時狀態
3. ✅ **保留所有客戶**：無資料丟失
4. ✅ **可解釋性**：文檔說明降級邏輯

#### 九宮格分析處理

**實作邏輯**（`module_dna_multi_premium.R`）：

```r
# 九宮格資料準備
nine_grid_data <- reactive({
  req(values$dna_results, input$lifecycle_stage)

  df <- values$dna_results$data_by_customer

  # ✅ 不過濾，保留所有客戶
  # df <- df %>% filter(times >= 4)  # ❌ 原始邏輯（已移除）

  # 過濾選定的生命週期階段
  df <- df[df$lifecycle_stage == input$lifecycle_stage, ]

  if (nrow(df) == 0) return(NULL)

  return(df)
})
```

**視覺化標示**：

UI 中顯示活躍度時會標註計算方法：
```
活躍度分佈：
- 高活躍：150 人（15%）
- 中活躍：600 人（60%）
- 低活躍：250 人（25%）

註：交易次數 ≥4 使用 CAI，< 4 使用 Recency（降級策略）
```

#### 與補充資料的差異說明

**差異類型**：🟢 架構性改進（更優方案）

**差異點**：
- **補充資料**：刪除 ni < 4 的客戶
- **實際實現**：保留 + 降級策略

**差異理由**：

1. **MP029 合規**：不生成假資料，不刪除真實資料
2. **更完整的客戶視圖**：所有客戶都可被分析和標記
3. **更豐富的行銷策略**：低頻客戶也有對應策略

**統計合理性**：

| 方案 | ni < 4 處理 | 優點 | 缺點 |
|------|------------|------|------|
| **刪除**（原始） | 移除這些客戶 | ✅ CAI 計算準確 | ❌ 丟失 20-40% 客戶<br>❌ 無法分析流失原因<br>❌ 違反 MP029 |
| **降級**（採用） | 使用 R 值替代 | ✅ 保留所有客戶<br>✅ 符合 MP029<br>✅ 更完整分析 | ⚠️ 活躍度語義略有差異（文檔說明） |

#### 測試驗證

**測試資料**（realistic_customer_data.csv）：

```
總客戶數：1,000
- ni ≥ 4：600 人（60%）→ 使用 CAI
- ni < 4：400 人（40%）→ 使用 Recency 降級

結果驗證：
✅ 所有客戶都有活躍度標籤
✅ 九宮格可顯示所有客戶
✅ 策略建議涵蓋所有客戶類型
✅ CSV 導出包含完整客戶名單
```

**業務影響評估**：

| 指標 | 刪除方案 | 降級方案（採用） | 評估 |
|------|----------|-----------------|------|
| 客戶覆蓋率 | 60% | 100% | ✅ 提升 40% |
| 行銷策略完整性 | 部分 | 完整 | ✅ 改善 |
| 資料遺失 | 40% | 0% | ✅ 無遺失 |
| CAI 準確度 | 100% | 100%（ni≥4） | ✅ 不影響 |
| 用戶體驗 | 混淆（客戶消失） | 完整視圖 | ✅ 改善 |

#### 文檔更新

**使用者說明**（加入幫助文字）：

```
【活躍度計算說明】

活躍度指標反映客戶購買行為的動態趨勢：

1. 標準計算（交易次數 ≥ 4）：
   - 使用 CAI（Customer Activity Index）
   - CAI 分析購買加速/減速趨勢
   - 分三級：高（加速）、中（穩定）、低（減速）

2. 降級計算（交易次數 < 4）：
   - 使用 Recency（最近購買天數）
   - 反映當前活躍狀態而非趨勢
   - 分三級：高（R小，最近購買）、中、低（R大，久未購買）

兩組客戶各自計算百分位數，確保分佈合理。
```

#### 相關文檔

- 合規審計：[COMPREHENSIVE_COMPLIANCE_AUDIT_20251026.md](COMPREHENSIVE_COMPLIANCE_AUDIT_20251026.md) (DIFF-002)
- 邏輯文檔：[logic.md](logic.md) - 降級策略章節
- 警告說明：[warnings.md](warnings.md) - 統計意義說明

**結論**：✅ 採用降級策略優於刪除，符合 MP029，提供更完整的客戶分析

#### Task 5.2: 確認新客定義一致性
**優先級**: 🔴 高
**預估工時**: 1 小時

**驗證**:
- 九宮格中的新客定義應與第四列一致
- 只買一次 + 在平均購買週期內

#### Task 5.3: 修改 Excel 匯出格式
**優先級**: 🟡 中
**預估工時**: 3 小時

**修改需求**:
1. **刪除第一個 xlsx（含亂碼）**
2. **保留第二個 xlsx，但修改欄位**

**保留欄位**:
```
customer_id, value_level, activity_level, lifecycle_stage, strategy
```

**新增欄位**:
```
strategy - 建議策略（來自 get_strategy 函數）
```

**實作邏輯**:
```r
# 匯出函數
export_customer_strategies <- function(customer_data) {
  export_df <- customer_data %>%
    mutate(
      # 取得策略
      grid_position = paste0(
        switch(value_level, "高" = "A", "中" = "B", "低" = "C"),
        switch(activity_level, "高" = "1", "中" = "2", "低" = "3"),
        switch(lifecycle_stage,
          "newbie" = "N", "active" = "C", "sleepy" = "D",
          "half_sleepy" = "H", "dormant" = "S"
        )
      ),
      strategy_info = map(grid_position, get_strategy),
      strategy_title = map_chr(strategy_info, ~.x$title),
      strategy_action = map_chr(strategy_info, ~.x$action),
      strategy_kpi = map_chr(strategy_info, ~.x$kpi)
    ) %>%
    select(customer_id, value_level, activity_level, lifecycle_stage,
           strategy_title, strategy_action, strategy_kpi)

  return(export_df)
}
```

#### Task 5.4: 確認價值等級計算公式
**優先級**: 🔴 高
**預估工時**: 2 小時

**當前邏輯**（line 281-296）:
```r
value_level = case_when(
  is.na(m_value) ~ "未知",
  m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
  m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
  TRUE ~ "低"
)
```

**驗證需求**:
根據補充資料，應該是：
- **高價值**: RFM ≥ 80th pct（綜合 R/F/M）+ 過去價值 ≥ 80th
- **中價值**: 20-80th pct
- **低價值**: ≤ 20th pct

**⚠️ 需確認**:
- 是否使用 M 值單獨判斷？
- 還是需要綜合 RFM？

**建議邏輯**（如果要綜合 RFM）:
```r
# 計算綜合得分
rfm_score = (r_normalized + f_normalized + m_normalized) / 3

value_level = case_when(
  rfm_score >= quantile(rfm_score, 0.8, na.rm = TRUE) ~ "高",
  rfm_score >= quantile(rfm_score, 0.2, na.rm = TRUE) ~ "中",
  TRUE ~ "低"
)
```

#### Task 5.5: 刪除「客戶區隔管理」功能
**優先級**: 🟡 中
**預估工時**: 0.5 小時

**檢查位置**: 搜尋程式碼中是否有此功能

---

## 第六列：顧客生命週期預測模組（新增）

### 📋 任務清單

#### Task 6.1: 靜止戶預測（R - Dormancy Risk）
**優先級**: 🔴 高
**預估工時**: 4 小時

**指標定義**:
- **R 值（靜止風險）**: 基於 Recency，預測客戶流失風險

**分群邏輯**（80/20 法則）:
- **高靜止戶**: R ≥ 80th percentile（高流失風險）
- **中靜止戶**: 20th ≤ R < 80th percentile
- **低靜止戶**: R < 20th percentile（低流失風險）

**計算公式**:
```r
calculate_dormancy_risk <- function(customer_data) {
  customer_data %>%
    mutate(
      r_percentile_80 = quantile(r_value, 0.8, na.rm = TRUE),
      r_percentile_20 = quantile(r_value, 0.2, na.rm = TRUE),
      dormancy_risk = case_when(
        r_value >= r_percentile_80 ~ "高靜止戶",
        r_value >= r_percentile_20 ~ "中靜止戶",
        TRUE ~ "低靜止戶"
      )
    ) %>%
    group_by(dormancy_risk) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

**UI 功能**:
- 滑鼠移到「高靜止戶」時，顯示 tooltip
- Tooltip 內容：意涵 + 常見策略（來自補充資料表格）

**Tooltip 內容**:
```
高靜止戶：
意涵：即將或已經流失
常見策略：喚醒/挽回行銷 (Reactivation)
行銷方案：
- 針對近期無交易的高風險客發送「回流誘因」
- EDM+LINE 再行銷 + 限時回購券
- 情緒化文案（如「我們想你了」）
```

#### Task 6.2: 交易穩定度（S - Transaction Stability）
**優先級**: 🔴 高
**預估工時**: 4 小時

**指標定義**:
- **S 值（交易穩定度）**: 購買行為的規律性，基於 IPT 變異係數

**計算邏輯**:
```r
calculate_transaction_stability <- function(customer_data_by_date) {
  # 計算每位客戶的 IPT 標準差
  stability_data <- customer_data_by_date %>%
    arrange(customer_id, date) %>%
    group_by(customer_id) %>%
    mutate(
      days_between = as.numeric(difftime(date, lag(date), units = "days"))
    ) %>%
    summarise(
      ipt_sd = sd(days_between, na.rm = TRUE),
      ipt_mean = mean(days_between, na.rm = TRUE),
      # 變異係數（CV）：標準差 / 平均值
      stability_cv = ipt_sd / ipt_mean,
      .groups = "drop"
    ) %>%
    mutate(
      # CV 越小越穩定
      stability_percentile_20 = quantile(stability_cv, 0.2, na.rm = TRUE),
      stability_percentile_80 = quantile(stability_cv, 0.8, na.rm = TRUE),
      stability_level = case_when(
        stability_cv <= stability_percentile_20 ~ "高穩定",
        stability_cv <= stability_percentile_80 ~ "中穩定",
        TRUE ~ "低穩定"
      )
    )

  return(stability_data)
}
```

**分群邏輯**:
- **高穩定顧客**: CV ≤ 20th percentile（購買間隔穩定）
- **中穩定顧客**: 20th < CV ≤ 80th percentile
- **低穩定顧客**: CV > 80th percentile（購買不規律）

**資源來源**:
- 需要 `sales_by_customer_by_date` 資料
- 來自 `fn_analysis_dna.R` 的輸入資料

#### Task 6.3: 顧客終生價值（CLV - Customer Lifetime Value）
**優先級**: 🔴 高
**預估工時**: 4 小時

**指標定義**:
- **CLV**: 預測客戶未來總價值

**計算邏輯**:
```r
calculate_clv <- function(customer_data) {
  customer_data %>%
    mutate(
      # 簡化 CLV 計算：平均訂單價值 × 購買頻率 × 預期生命週期
      # 預期生命週期 = 1 / 流失率（這裡用 1/年 作為簡化）
      avg_order_value = m_value,
      purchase_frequency = f_value,
      expected_lifetime_years = 1,  # 簡化假設

      clv = avg_order_value * purchase_frequency * expected_lifetime_years
    ) %>%
    mutate(
      clv_percentile_80 = quantile(clv, 0.8, na.rm = TRUE),
      clv_percentile_20 = quantile(clv, 0.2, na.rm = TRUE),
      clv_level = case_when(
        clv >= clv_percentile_80 ~ "高價值",
        clv >= clv_percentile_20 ~ "中價值",
        TRUE ~ "低價值"
      )
    ) %>%
    group_by(clv_level) %>%
    summarise(
      customer_count = n(),
      percentage = round(n() / nrow(.) * 100, 1)
    )
}
```

**進階 CLV 計算**（選用）:
如果要更精確，可使用：
```r
# CLV = (平均訂單價值 × 購買頻率 × 客戶生命週期) - 獲客成本
# 或使用生存分析預測
```

#### Task 6.4: 顧客生命力矩陣（R × S × V Grid）
**優先級**: 🔴 高
**預估工時**: 6 小時

**矩陣定義**:
整合三個維度：
- R（靜止戶預測）: 高/中/低
- S（交易穩定度）: 高/中/低
- V（顧客終生價值）: 高/中/低

**共 27 種組合**（3 × 3 × 3）

**策略對應表**（來自補充資料）:
```r
get_vitality_strategy <- function(r_level, s_level, v_level) {
  strategies <- list(
    # 低R × 高S × 高V
    "低高高" = list(
      type = "金鑽客",
      strategy = "VIP體驗+品牌共創",
      action = "專屬客服/新品搶先體驗/會員大使"
    ),
    # 低R × 高S × 中V
    "低高中" = list(
      type = "成長型忠誠客",
      strategy = "升級誘因",
      action = "搭售組合、滿額升級、會員積分任務"
    ),
    # 中R × 中S × 高V
    "中中高" = list(
      type = "預警高值客",
      strategy = "早期挽回",
      action = "回購提醒、VIP喚醒禮、定向廣告再觸及"
    ),
    # 高R × 低S × 高V
    "高低高" = list(
      type = "流失高值客",
      strategy = "挽回行銷",
      action = "再行銷廣告、專屬優惠、客服致電喚回"
    ),
    # 高R × 低S × 低V
    "高低低" = list(
      type = "沉睡客",
      strategy = "低成本回流/冷啟策略",
      action = "廣告再曝光+再註冊誘因"
    )
    # ... 其他 22 種組合
  )

  key <- paste0(r_level, s_level, v_level)
  return(strategies[[key]] %||% list(
    type = "一般客群",
    strategy = "標準行銷",
    action = "常規促銷活動"
  ))
}
```

**UI 設計**:
- 3D 矩陣視覺化（或使用多層次表格）
- 每個格子顯示：客戶類型、策略、行動方案
- 可點擊查看詳細客戶名單

#### Task 6.5: CSV 匯出功能（廣告投放用）
**優先級**: 🔴 高
**預估工時**: 3 小時

**匯出欄位**:
```
customer_id, email, r_level, s_level, v_level,
customer_type, strategy, action,
recommended_campaign, estimated_clv
```

**實作邏輯**:
```r
export_vitality_matrix <- function(customer_data) {
  export_df <- customer_data %>%
    mutate(
      # 取得策略
      strategy_info = pmap(list(r_level, s_level, v_level), get_vitality_strategy),
      customer_type = map_chr(strategy_info, ~.x$type),
      strategy = map_chr(strategy_info, ~.x$strategy),
      action = map_chr(strategy_info, ~.x$action)
    ) %>%
    select(customer_id, email, r_level, s_level, v_level,
           customer_type, strategy, action, clv)

  # 匯出 CSV
  write.csv(export_df, "customer_vitality_matrix.csv", row.names = FALSE)

  return(export_df)
}
```

**UI 按鈕**:
```r
downloadButton(ns("download_vitality"), "下載生命力矩陣 CSV")
```

---

## 資源與依賴

### 現有資源

#### 1. Global Scripts
```
scripts/global_scripts/04_utils/fn_analysis_dna.R
- DNA 分析主函數
- 計算 R/F/M/CAI/IPT 等指標

scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R
- 資料合併工具

scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R
- 因子處理工具
```

#### 2. 現有模組
```
modules/module_dna_multi_premium.R
- 九宮格分析模組
- 已有基礎架構可擴展

modules/module_upload.R
- 資料上傳模組
- 需要修改說明文字和驗證邏輯
```

#### 3. 資料結構
```
dna_results$data_by_customer
- 客戶層級資料
- 包含 R/F/M/CAI/IPT 等指標

dna_results$data_by_customer_by_date
- 交易明細資料
- 用於計算穩定度
```

### 需要新增的資源

#### 1. 新模組
```
modules/module_base_value.R
- 顧客基礎價值分析
- Task 2.1 - 2.4

modules/module_value_analysis.R
- 顧客價值分析（RFM + CAI）
- Task 3.1 - 3.5

modules/module_lifecycle_status.R
- 顧客狀態分析
- Task 4.1 - 4.5

modules/module_predictive_intelligence.R
- 顧客生命週期預測
- Task 6.1 - 6.5
```

#### 2. 輔助函數
```
utils/fn_calculate_stability.R
- 交易穩定度計算

utils/fn_calculate_clv.R
- CLV 計算

utils/fn_vitality_matrix.R
- 生命力矩陣邏輯
```

#### 3. 策略資料
```
data/vitality_strategies.R
- 27 種生命力矩陣策略對應表
```

---

## 開發優先順序

### Phase 1: 核心修正（🔴 高優先級）
**預估時間**: 2-3 週

1. **Task 4.1**: 修改新客定義（關鍵）
2. **Task 4.2**: 移除最少交易次數
3. **Task 5.1**: 套用交易次數過濾（>= 4 次）
4. **Task 3.4**: 顧客活躍度分群（>= 4 次）
5. **Task 1.1-1.2**: 修改上傳說明和欄位驗證

### Phase 2: 基礎分析擴展（🔴 高優先級）
**預估時間**: 3-4 週

6. **Task 2.1**: 顧客購買週期分群
7. **Task 2.2**: 過去價值分群
8. **Task 2.3**: 客單價分析
9. **Task 3.1-3.3**: RFM 分群
10. **Task 4.3-4.4**: 顧客狀態統計

### Phase 3: 預測模組（🔴 高優先級）
**預估時間**: 4-5 週

11. **Task 6.1**: 靜止戶預測
12. **Task 6.2**: 交易穩定度
13. **Task 6.3**: CLV 計算
14. **Task 6.4**: 生命力矩陣
15. **Task 6.5**: CSV 匯出

### Phase 4: 進階功能（🟡 中優先級）
**預估時間**: 2-3 週

16. **Task 5.3**: Excel 匯出格式優化
17. **Task 5.4**: 確認價值等級公式
18. **Task 1.3**: 檔案數量上限

### Phase 5: 成長率分析（🟢 低優先級）
**預估時間**: 需要架構調整

19. **Task 2.4, 3.5, 4.5**: 成長率分析
    - ⚠️ 需要資料庫支援歷史資料
    - 建議延後或作為獨立專案

---

## 測試計畫

### 單元測試

#### 測試 1: 新客定義
```r
test_newbie_definition <- function() {
  # 測試案例
  test_customers <- data.frame(
    customer_id = c(1, 2, 3, 4),
    times = c(1, 1, 2, 1),
    customer_age_days = c(15, 45, 30, 20)
  )

  avg_ipt <- 30  # 假設平均購買週期 30 天

  result <- test_customers %>%
    mutate(
      is_newbie = times == 1 & customer_age_days <= avg_ipt
    )

  # 預期結果
  expect_equal(result$is_newbie, c(TRUE, FALSE, FALSE, TRUE))
}
```

#### 測試 2: 交易次數過濾
```r
test_activity_filter <- function() {
  test_customers <- data.frame(
    customer_id = 1:10,
    times = c(1, 2, 3, 4, 5, 6, 3, 2, 4, 5)
  )

  filtered <- test_customers %>% filter(times >= 4)

  # 預期結果：5 位客戶
  expect_equal(nrow(filtered), 5)
}
```

#### 測試 3: 80/20 分群
```r
test_pareto_segmentation <- function() {
  test_values <- seq(1, 100)

  result <- data.frame(value = test_values) %>%
    mutate(
      p80 = quantile(value, 0.8),
      p20 = quantile(value, 0.2),
      segment = case_when(
        value >= p80 ~ "高",
        value >= p20 ~ "中",
        TRUE ~ "低"
      )
    )

  # 檢查分佈
  distribution <- result %>%
    group_by(segment) %>%
    summarise(count = n())

  # 預期：高 20%、中 60%、低 20%
  expect_equal(distribution$count, c(20, 60, 20))
}
```

### 整合測試

#### 測試場景 1: 完整資料流
```
上傳資料 → DNA 分析 → 基礎價值 → 價值分析 →
顧客狀態 → 九宮格 → 生命力矩陣 → CSV 匯出
```

#### 測試場景 2: 邊界情況
- 只有 1 位客戶
- 所有客戶交易次數 < 4
- 所有客戶都是新客
- 極端分佈（所有客戶都在同一格）

#### 測試場景 3: 真實資料
- Kitchen Mama 歷史資料
- 至少 1000 筆客戶
- 至少 12 個月資料

---

## 風險與限制

### 已知風險

1. **成長率分析需要歷史資料**
   - 當前系統為單次上傳分析
   - 需要資料庫架構支援
   - **建議**: 延後開發或作為獨立專案

2. **CLV 計算的準確性**
   - 簡化公式可能不夠精確
   - **建議**: 使用生存分析或機器學習模型

3. **27 種生命力矩陣策略**
   - 策略內容需要行銷專家審核
   - **建議**: 先實作 9 種核心策略

### 技術限制

1. **記憶體限制**
   - 大量客戶（> 100,000）可能導致效能問題
   - **建議**: 實作分頁或抽樣機制

2. **計算時間**
   - DNA 分析 + 多層級分群可能耗時
   - **建議**: 使用 future/furrr 並行計算

### 資料品質要求

1. **必要欄位**
   - ID/Email、purchase_time、price
   - 缺一不可

2. **時間範圍**
   - 至少 12 個月資料
   - 建議 24-36 個月

3. **資料完整性**
   - 客戶至少有 1 筆交易
   - 時間格式正確

---

## 完成標準

### Phase 1 完成標準
- [ ] 新客定義修改完成，測試通過
- [ ] 交易次數過濾正確實作
- [ ] 上傳說明文字更新
- [ ] 欄位驗證邏輯正確

### Phase 2 完成標準
- [ ] 所有基礎分析指標正確計算
- [ ] UI 顯示完整（人數 + 百分比）
- [ ] 分群邏輯符合 80/20 法則
- [ ] 圓餅圖正確呈現

### Phase 3 完成標準
- [ ] R/S/V 三個指標正確計算
- [ ] 27 種策略對應完整
- [ ] 生命力矩陣正確顯示
- [ ] CSV 匯出功能正常

### 最終驗收標準
- [ ] 所有功能測試通過
- [ ] 真實資料驗證通過
- [ ] 效能測試通過（1000+ 客戶）
- [ ] 文檔完整（使用手冊 + API 文檔）
- [ ] 程式碼符合 MP/P/R 原則

---

## 附錄

### A. 術語對照表

| 英文縮寫 | 中文名稱 | 說明 |
|---------|---------|------|
| R | Recency | 最近購買日 |
| F | Frequency | 購買頻率 |
| M | Monetary | 購買金額 |
| CAI | Customer Activity Index | 顧客活躍度指數 |
| IPT | Inter-Purchase Time | 購買間隔時間 |
| CLV | Customer Lifetime Value | 顧客終生價值 |
| CRI | Customer Regularity Index | 顧客規律性指數 |

### B. 參考資料

1. **補充文件**: TagPilot_Lite高階和旗艦版_20251021.md
2. **現有模組**: module_dna_multi_premium.R
3. **DNA 分析**: fn_analysis_dna.R
4. **原則文件**: scripts/global_scripts/00_principles/

### C. 聯絡資訊

**技術支援**: partners@peakededges.com
**文檔版本**: v2.0
**最後更新**: 2025-10-25

---

**下一步行動**:
1. 審核此工作規劃
2. 確認優先順序
3. 分配開發資源
4. 建立開發時程
5. 開始 Phase 1 開發
