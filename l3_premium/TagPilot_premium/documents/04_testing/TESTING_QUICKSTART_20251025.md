# TagPilot Premium - 測試快速啟動指南

**版本**: v1.0
**日期**: 2025-10-25
**用途**: 快速啟動和執行動態測試

---

## 🚀 快速啟動（5 分鐘開始測試）

### Step 1: 準備環境 (1 分鐘)

```r
# 設定工作目錄
setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

# 檢查套件（可選，如果之前已檢查過）
source("scripts/global_scripts/98_test/test_package_dependencies.R")
```

### Step 2: 準備測試資料 (1 分鐘)

確保有測試資料檔案：
- 路徑：`test_data/sample_customer_data.csv`
- 必填欄位：`customer_id`, `transaction_date`, `transaction_amount`
- 建議資料量：1,000+ 筆客戶記錄

如果沒有測試資料，可以使用以下 R 代碼生成：

```r
# 生成測試資料
library(dplyr)
library(lubridate)

set.seed(42)
n_customers <- 1000
n_transactions <- 5000

customer_ids <- sprintf("CUST%04d", 1:n_customers)

test_data <- data.frame(
  customer_id = sample(customer_ids, n_transactions, replace = TRUE),
  transaction_date = sample(
    seq(as.Date("2023-01-01"), as.Date("2024-12-31"), by = "day"),
    n_transactions,
    replace = TRUE
  ),
  transaction_amount = round(runif(n_transactions, 10, 1000), 2)
) %>%
  arrange(customer_id, transaction_date)

# 儲存測試資料
dir.create("test_data", showWarnings = FALSE)
write.csv(test_data, "test_data/sample_customer_data.csv", row.names = FALSE)

cat("✅ 測試資料已生成：", nrow(test_data), "筆交易,",
    length(unique(test_data$customer_id)), "位客戶\n")
```

### Step 3: 啟動應用程式 (30 秒)

```r
# 啟動 Shiny 應用
shiny::runApp("app.R")
```

**預期結果**:
- 瀏覽器自動開啟（通常是 http://127.0.0.1:xxxx）
- 看到 TagPilot Premium 首頁
- 側邊欄顯示所有模組選單

### Step 4: 開始測試 (3 分鐘快速驗證)

#### 快速健康檢查（3 分鐘）

1. **上傳資料** (30 秒)
   - 點擊「上傳資料」
   - 選擇 `test_data/sample_customer_data.csv`
   - ✅ 應看到成功訊息和資料摘要

2. **檢查模組 1** (30 秒)
   - 查看 DNA 九宮格分析
   - ✅ 應看到九宮格熱圖
   - ✅ 應看到客戶分佈統計

3. **檢查模組 2** (30 秒)
   - 點擊「客戶基礎價值分析」
   - ✅ 應看到購買週期分群表和圓餅圖
   - ✅ 應看到歷史價值分群

4. **檢查模組 3** (30 秒)
   - 點擊「客戶價值分析 (RFM)」
   - ✅ 應看到 R/F/M 分群表
   - ✅ 應看到 3 個圓餅圖

5. **檢查模組 5** (30 秒)
   - 點擊「R/S/V 生命力矩陣」
   - ✅ 應看到矩陣視覺化
   - ✅ 應看到 27 種組合統計

6. **檢查模組 6** (30 秒)
   - 點擊「生命週期預測」
   - ✅ 應看到預測資料表
   - ✅ 應看到預測視覺化圖表

**如果以上 6 項都通過 → 應用基本運作正常！** 🎉

---

## 📋 完整測試清單（使用檢查表）

### 使用方式

1. 開啟 [DYNAMIC_TESTING_PLAN_20251025.md](DYNAMIC_TESTING_PLAN_20251025.md)
2. 逐項執行測試案例
3. 勾選完成的項目
4. 記錄任何錯誤或異常

### 測試優先級

#### 🔴 Critical（必須全部通過）
- Module 1: 資料上傳功能
- Module 3: RFM 分析核心功能
- Module 4: 九宮格核心功能
- 無系統崩潰

#### 🟠 High（應該通過）
- Module 2, 5, 6 核心功能
- 所有視覺化正確顯示
- 邊界情況不崩潰

#### 🟡 Medium（建議通過）
- UI/UX 友好
- CSV 下載功能
- 行動裝置顯示

---

## 🧪 測試執行模式

### 模式 A: 快速驗證（30 分鐘）

**目標**: 確認基本功能運作
**適用**: 開發後快速檢查

```
✅ 快速健康檢查（3 分鐘）
✅ Critical 測試案例（20 分鐘）
✅ 效能基本檢查（7 分鐘）
```

**通過標準**:
- 所有 Critical 測試案例通過
- 無系統崩潰
- 載入時間 < 10 秒

---

### 模式 B: 標準測試（2 小時）

**目標**: 完整功能驗證
**適用**: 階段性驗收

```
✅ 快速健康檢查（3 分鐘）
✅ Critical 測試案例（30 分鐘）
✅ High 測試案例（50 分鐘）
✅ 邊界情況測試（20 分鐘）
✅ 效能測試（17 分鐘）
```

**通過標準**:
- 所有 Critical 和 High 測試案例通過
- 邊界情況正確處理
- 效能達標

---

### 模式 C: 完整測試（4-6 小時）

**目標**: 全面品質保證
**適用**: 正式上線前

```
✅ 所有測試案例（70+ 項）
✅ 多資料集測試
✅ 壓力測試
✅ 使用者接受測試
```

**通過標準**:
- 所有測試案例通過
- 多種資料集驗證
- 客戶滿意度確認

---

## 🔍 常見測試場景

### 場景 1: 小資料集測試

**資料**: 100 筆客戶
**預期**:
- 功能正常運作
- 可能出現樣本數警告 ⚠️
- CAI 計算客戶較少（ni < 4 較多）

**檢查點**:
- [ ] 系統不崩潰
- [ ] 警告訊息正確顯示
- [ ] 降級策略啟用（使用 R 值代替 CAI）

---

### 場景 2: 大資料集測試

**資料**: 10,000+ 筆客戶
**預期**:
- 功能正常運作
- 載入時間可能較長
- 所有分群都有足夠樣本

**檢查點**:
- [ ] 載入時間 < 10 秒
- [ ] 圖表渲染時間 < 5 秒
- [ ] 無記憶體錯誤

---

### 場景 3: 邊界資料測試

**資料**:
- 包含單次購買客戶
- 包含高頻客戶（100+ 次購買）
- 包含異常金額（0 或極大值）

**檢查點**:
- [ ] 單次購買客戶標記為 newbie（如在週期內）
- [ ] 高頻客戶正確處理
- [ ] 異常值顯示警告但不崩潰

---

## ⚡ 快速問題排查

### 問題 1: 應用無法啟動

**症狀**: `shiny::runApp("app.R")` 報錯

**排查步驟**:
```r
# 1. 檢查工作目錄
getwd()
# 應該是: /Users/hauhungyang/.../TagPilot_premium

# 2. 檢查 app.R 是否存在
file.exists("app.R")

# 3. 檢查套件
source("scripts/global_scripts/98_test/test_package_dependencies.R")

# 4. 查看詳細錯誤訊息
source("app.R")
```

---

### 問題 2: 資料上傳失敗

**症狀**: 上傳檔案後顯示錯誤

**排查步驟**:
1. 檢查檔案格式（必須是 CSV）
2. 檢查必填欄位是否存在
3. 檢查日期格式（應為 YYYY-MM-DD）
4. 查看瀏覽器控制台錯誤訊息

**常見錯誤**:
- `Error: 缺少必填欄位` → 檢查欄位名稱
- `Error: 日期格式錯誤` → 檢查日期格式
- `Error: 檔案為空` → 檢查檔案內容

---

### 問題 3: 圖表不顯示

**症狀**: 模組載入但圖表空白

**排查步驟**:
1. 檢查瀏覽器控制台（F12）
2. 確認資料是否正確載入
3. 檢查 Plotly 套件版本

**解決方案**:
```r
# 更新 Plotly
install.packages("plotly")

# 重新啟動應用
shiny::runApp("app.R")
```

---

### 問題 4: 模組切換卡住

**症狀**: 點擊側邊欄後無反應

**排查步驟**:
1. 檢查 R Console 是否有錯誤訊息
2. 重新整理瀏覽器頁面
3. 重新啟動 Shiny 應用

---

## 📊 測試記錄模板

### 測試執行記錄

```
測試日期: 2025-10-XX
測試人員: [姓名]
測試模式: [A/B/C]
測試資料: [dataset_name]
R 版本: [x.x.x]
Shiny 版本: [x.x.x]

## 快速健康檢查結果
- [ ] 上傳資料成功
- [ ] 模組 1 顯示正常
- [ ] 模組 2 顯示正常
- [ ] 模組 3 顯示正常
- [ ] 模組 5 顯示正常
- [ ] 模組 6 顯示正常

## Critical 測試結果
通過: XX / XX
失敗: XX
通過率: XX%

## 主要問題
1. [問題描述]
2. [問題描述]

## 測試結論
[ ] 通過 - 可以繼續
[ ] 有問題 - 需要修正
[ ] 阻塞 - 無法繼續
```

---

## 🎯 測試完成標準

### ✅ 最低通過標準（可部署）

- [x] 快速健康檢查 100% 通過
- [x] Critical 測試案例 100% 通過
- [x] 無系統崩潰或嚴重錯誤
- [x] 效能測試達標（載入 < 10 秒）

### ✅ 建議通過標準（推薦部署）

- [x] 最低通過標準 ✅
- [x] High 測試案例 ≥ 90% 通過
- [x] 邊界情況正確處理
- [x] 使用者體驗良好

### ✅ 完美通過標準（生產就緒）

- [x] 建議通過標準 ✅
- [x] 所有測試案例 100% 通過
- [x] 多資料集驗證通過
- [x] 客戶驗收通過

---

## 📞 需要協助？

### 查看詳細文檔
- **完整測試計劃**: [DYNAMIC_TESTING_PLAN_20251025.md](DYNAMIC_TESTING_PLAN_20251025.md)
- **項目完成總結**: [PROJECT_COMPLETION_SUMMARY_20251025.md](PROJECT_COMPLETION_SUMMARY_20251025.md)
- **業務邏輯說明**: [logic.md](logic.md)

### 常見問題
- 技術問題 → 查看 [warnings.md](warnings.md)
- 架構問題 → 查看 [TagPilot_Premium_App_Architecture_Documentation.md](TagPilot_Premium_App_Architecture_Documentation.md)
- 決策記錄 → 查看 [DECISIONS_20251025.md](DECISIONS_20251025.md)

---

## 🚦 測試流程圖

```
開始
 ↓
準備環境（1 分鐘）
 ↓
準備測試資料（1 分鐘）
 ↓
啟動應用（30 秒）
 ↓
快速健康檢查（3 分鐘）
 ↓
[通過？]
 ├─ 否 → 排查問題 → 修正 → 重新測試
 └─ 是 → 選擇測試模式
         ↓
    ┌────┴────┬─────────┬──────────┐
    ↓         ↓         ↓          ↓
  模式A     模式B     模式C    自訂測試
 (30分)    (2小時)   (4-6小時)
    ↓         ↓         ↓          ↓
    └─────┬───┴─────────┴──────────┘
          ↓
      記錄結果
          ↓
      評估通過標準
          ↓
    [達到標準？]
     ├─ 否 → 記錄問題 → 修正 → 重新測試
     └─ 是 → 完成測試 🎉
```

---

**快速啟動指南版本**: v1.0
**建立日期**: 2025-10-25
**維護**: Claude AI Assistant

**💡 提示**: 建議先執行「模式 A: 快速驗證」，確認基本功能無誤後，再進行更詳細的測試。

**🎉 準備好了嗎？執行 `shiny::runApp("app.R")` 開始測試！**
