# TagPilot Premium - 測試前檢查清單

**版本**: v1.0
**日期**: 2025-10-25
**用途**: 確保測試環境完全就緒

---

## ✅ 測試前必要檢查

### 1. 環境檢查

#### 1.1 工作目錄
```bash
# 確認當前目錄
pwd
# 應該是: /Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium
```

- [ ] 工作目錄正確
- [ ] 具有讀寫權限

#### 1.2 R 環境
```r
# 檢查 R 版本
R.version.string
# 建議: R version 4.0.0 或更高

# 檢查關鍵套件
library(shiny)
library(bs4Dash)
library(dplyr)
library(plotly)
library(DT)
```

- [ ] R 版本 ≥ 4.0.0
- [ ] Shiny 已安裝
- [ ] bs4Dash 已安裝
- [ ] dplyr 已安裝
- [ ] plotly 已安裝
- [ ] DT 已安裝

#### 1.3 必要檔案存在性
```bash
# 檢查主要檔案
ls -la app.R
ls -la modules/
ls -la scripts/global_scripts/
```

- [ ] app.R 存在
- [ ] modules/ 目錄存在
- [ ] scripts/global_scripts/ 存在（或 symlink 有效）
- [ ] 所有模組檔案齊全（6個）

---

### 2. 測試資料檢查

#### 2.1 測試資料檔案
```bash
# 檢查測試資料目錄
ls -la test_data/
```

- [ ] test_data/ 目錄存在
- [ ] 至少有一個 .csv 測試檔案
- [ ] 檔案大小 > 0 KB

#### 2.2 測試資料格式驗證
```r
# 讀取測試資料檢查格式
test_df <- read.csv("test_data/sample_customer_data.csv")

# 檢查必填欄位
required_cols <- c("customer_id", "transaction_date", "transaction_amount")
all(required_cols %in% names(test_df))

# 檢查資料量
cat("客戶數:", length(unique(test_df$customer_id)), "\n")
cat("交易筆數:", nrow(test_df), "\n")
```

**最低要求**:
- [ ] 包含 customer_id 欄位
- [ ] 包含 transaction_date 欄位
- [ ] 包含 transaction_amount 欄位
- [ ] 至少 100 位客戶
- [ ] 至少 500 筆交易

**建議標準**:
- [ ] 1,000+ 位客戶
- [ ] 5,000+ 筆交易
- [ ] 涵蓋 12+ 個月資料

---

### 3. 文檔準備檢查

#### 3.1 測試文檔齊全性
- [ ] DYNAMIC_TESTING_PLAN_20251025.md 存在
- [ ] TESTING_QUICKSTART_20251025.md 存在
- [ ] PRE_TESTING_CHECKLIST_20251025.md 存在（本文件）
- [ ] 可以在編輯器中開啟測試計劃

#### 3.2 測試記錄準備
- [ ] 準備好記錄測試結果的方式（筆記本或文件）
- [ ] 準備好截圖工具（如需要）
- [ ] 確認測試時間安排（4-6小時）

---

### 4. 應用程式完整性檢查

#### 4.1 模組檔案檢查
```bash
# 確認所有模組存在
ls -la modules/module_*.R
```

預期檔案（6個核心模組）:
- [ ] modules/module_upload.R
- [ ] modules/module_dna_multi_premium.R
- [ ] modules/module_customer_base_value.R
- [ ] modules/module_customer_value_analysis.R
- [ ] modules/module_rsv_matrix.R
- [ ] modules/module_lifecycle_prediction.R

#### 4.2 語法檢查（快速驗證）
```r
# 快速語法檢查
source("app.R", echo = FALSE)
cat("✅ app.R 語法正確\n")
```

- [ ] app.R 語法無錯誤
- [ ] 無 Error 訊息
- [ ] 無 Warning 訊息（可接受少量）

---

### 5. 測試環境設定

#### 5.1 瀏覽器準備
- [ ] Chrome 或 Firefox 已安裝
- [ ] 瀏覽器已更新到最新版本
- [ ] 清除瀏覽器快取（建議）
- [ ] 關閉其他不必要的分頁（避免效能影響）

#### 5.2 螢幕設定
- [ ] 螢幕解析度足夠（建議 ≥ 1920x1080）
- [ ] 視窗大小適中（可全螢幕或 80% 寬度）

#### 5.3 網路連線
- [ ] 網路連線穩定（部分套件可能需要載入外部資源）
- [ ] 無防火牆阻擋 localhost 連線

---

### 6. 備份與安全

#### 6.1 代碼備份
- [ ] 最新代碼已提交到 Git
- [ ] 確認 Git status 無未追蹤的重要檔案
- [ ] 可選：建立測試前的 Git tag

```bash
# 檢查 Git 狀態
git status

# 可選：建立測試前標記
git tag -a "v1.0-pre-testing" -m "Before dynamic testing"
```

#### 6.2 資料備份
- [ ] 測試資料已備份（如是重要客戶資料）
- [ ] 確認測試不會影響生產環境資料

---

## 🚀 啟動測試前最終確認

### 最後檢查清單（3分鐘）

```r
# === 最終環境驗證腳本 ===

# 1. 確認工作目錄
cat("工作目錄:", getwd(), "\n")

# 2. 檢查關鍵檔案
files_to_check <- c(
  "app.R",
  "modules/module_upload.R",
  "modules/module_dna_multi_premium.R",
  "modules/module_customer_base_value.R",
  "modules/module_customer_value_analysis.R",
  "modules/module_rsv_matrix.R",
  "modules/module_lifecycle_prediction.R"
)

all_exist <- all(file.exists(files_to_check))
cat("所有關鍵檔案存在:", all_exist, "\n")

# 3. 檢查測試資料
test_file <- "test_data/sample_customer_data.csv"
if (file.exists(test_file)) {
  df <- read.csv(test_file)
  cat("測試資料客戶數:", length(unique(df$customer_id)), "\n")
  cat("測試資料交易數:", nrow(df), "\n")

  # 檢查必填欄位
  required <- c("customer_id", "transaction_date", "transaction_amount")
  has_required <- all(required %in% names(df))
  cat("必填欄位完整:", has_required, "\n")
} else {
  cat("⚠️ 警告: 測試資料不存在\n")
}

# 4. 檢查套件
required_packages <- c("shiny", "bs4Dash", "dplyr", "plotly", "DT")
installed <- sapply(required_packages, requireNamespace, quietly = TRUE)
cat("必要套件已安裝:", all(installed), "\n")

# 5. 最終確認
if (all_exist && all(installed)) {
  cat("\n✅ 環境檢查完成！可以開始測試。\n")
  cat("📝 執行命令: shiny::runApp('app.R')\n")
} else {
  cat("\n⚠️ 環境檢查失敗，請解決上述問題後再開始測試。\n")
}
```

**執行結果**:
- [ ] 所有檔案存在: TRUE
- [ ] 測試資料有效: TRUE
- [ ] 套件已安裝: TRUE
- [ ] 環境檢查完成: ✅

---

## 📋 測試模式選擇

根據可用時間選擇測試模式：

### 模式 A: 快速驗證 (30分鐘)
**適用**: 快速確認基本功能
- [ ] 時間充足（≥ 30分鐘）
- [ ] 只需驗證核心功能
- [ ] 開發後快速檢查

### 模式 B: 標準測試 (2小時)
**適用**: 完整功能驗證
- [ ] 時間充足（≥ 2小時）
- [ ] 需要全面功能檢查
- [ ] 階段性驗收

### 模式 C: 完整測試 (4-6小時)
**適用**: 上線前完整驗證
- [ ] 時間充足（≥ 4小時）
- [ ] 正式部署前測試
- [ ] 需要詳細記錄

**我選擇**: [ ] 模式 A / [ ] 模式 B / [ ] 模式 C

---

## 🎯 準備就緒確認

### 最終啟動前確認（所有項目必須勾選）

環境準備:
- [ ] ✅ R 環境正常
- [ ] ✅ 工作目錄正確
- [ ] ✅ 所有檔案齊全
- [ ] ✅ 測試資料就緒

文檔準備:
- [ ] ✅ 測試計劃已閱讀
- [ ] ✅ 測試記錄方式已準備
- [ ] ✅ 時間已安排好

測試設定:
- [ ] ✅ 瀏覽器已準備
- [ ] ✅ 網路連線穩定
- [ ] ✅ 已選擇測試模式

備份安全:
- [ ] ✅ 代碼已備份
- [ ] ✅ 資料已確認安全

---

## 🚀 啟動測試！

當所有檢查項目都完成後，執行以下命令啟動測試：

```r
# 設定工作目錄（如果還沒設定）
setwd("/Users/hauhungyang/Library/CloudStorage/Dropbox/ai_martech/l3_premium/TagPilot_premium")

# 啟動 Shiny 應用
shiny::runApp("app.R")

# 或使用指定 port
shiny::runApp("app.R", port = 8888)
```

**預期結果**:
- ✅ 瀏覽器自動開啟
- ✅ 應用程式載入成功
- ✅ 看到 TagPilot Premium 首頁
- ✅ 側邊欄顯示所有模組

---

## 📞 問題排查

如果測試前檢查失敗：

### 問題 1: 測試資料不存在
**解決方案**: 使用以下 R 代碼生成測試資料

```r
# 生成測試資料
library(dplyr)
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

# 建立目錄並儲存
dir.create("test_data", showWarnings = FALSE)
write.csv(test_data, "test_data/sample_customer_data.csv", row.names = FALSE)

cat("✅ 測試資料已生成:", nrow(test_data), "筆交易\n")
```

### 問題 2: 套件缺失
**解決方案**: 安裝缺少的套件

```r
# 安裝所有必要套件
required_packages <- c(
  "shiny", "bs4Dash", "dplyr", "tidyr", "lubridate",
  "plotly", "DT", "httr", "jsonlite", "scales",
  "ggplot2", "purrr", "stringr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

cat("✅ 所有套件已安裝\n")
```

### 問題 3: global_scripts 連結失效
**解決方案**: 檢查符號連結

```bash
# 檢查連結
ls -la scripts/global_scripts

# 如果是斷裂的連結，重新建立
# （請根據實際路徑調整）
```

---

## ✅ 檢查清單總結

當所有項目都勾選完畢，你就可以開始測試了！

**測試開始時間**: ___________
**預計測試模式**: ___________
**預計完成時間**: ___________

**祝測試順利！** 🎉

---

**文檔版本**: v1.0
**建立日期**: 2025-10-25
**維護**: Claude AI Assistant
