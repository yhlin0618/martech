# LaTeX 報告模組測試指南

## 📋 概述

這個指南將幫助你測試 LaTeX 報告模組的功能。我們提供了多個測試工具，從簡單的快速測試到完整的應用程式測試。

## 🚀 快速開始

### 1. 快速測試 (推薦先執行)

執行快速測試腳本來驗證基本功能：

```r
# 在 R 中執行
source("test_latex_quick_test.R")
```

這個測試會：
- ✅ 創建測試資料
- ✅ 測試資料收集功能
- ✅ 驗證 LaTeX 編譯器
- ✅ 測試 LaTeX 編譯
- ✅ 驗證錯誤處理

### 2. 完整應用程式測試

運行完整的測試應用程式：

```r
# 在 R 中執行
source("test_latex_app.R")
```

這會啟動一個 Shiny 應用程式，提供：
- 📁 資料上傳功能
- 🔧 設定選項
- 📄 LaTeX 報告生成
- 📥 下載功能

## 📁 測試文件說明

### 核心文件
- **`test_latex_quick_test.R`** - 快速功能測試腳本
- **`test_latex_app.R`** - 完整測試應用程式
- **`test_data/sample_sales_data.csv`** - 測試用銷售資料

### 模組文件
- **`modules/module_latex_report.R`** - LaTeX 報告模組
- **`scripts/global_scripts/04_utils/fn_latex_report_utils.R`** - 輔助函數

## 🔧 系統需求

### 必要套件
```r
# 安裝必要套件
install.packages(c("shiny", "dplyr", "DT", "readr", "jsonlite", "httr", "rmarkdown"))
```

### LaTeX 編譯器
- **Windows**: 安裝 MiKTeX 或 TeX Live
- **macOS**: 安裝 MacTeX
- **Linux**: 安裝 TeX Live

### OpenAI API Key
- 註冊 OpenAI 帳號
- 獲取 API Key
- 確保有足夠的額度

## 📊 測試資料

### 使用提供的測試資料
1. 使用 `test_data/sample_sales_data.csv`
2. 包含 100+ 筆銷售記錄
3. 包含所有必要欄位

### 自訂測試資料
CSV 檔案應包含以下欄位：
```csv
customer_id,lineitem_price,payment_time,product_name,platform
customer_001,125.50,2024-01-15 10:30:00,產品A,amazon
customer_002,89.99,2024-01-16 14:20:00,產品B,ebay
...
```

## 🧪 測試步驟

### 步驟 1: 快速測試
```r
# 執行快速測試
source("test_latex_quick_test.R")
```

檢查輸出：
- ✅ 所有功能測試通過
- ⚠️ 編譯器可用性
- 📄 編譯結果

### 步驟 2: 應用程式測試
```r
# 啟動測試應用程式
source("test_latex_app.R")
```

在應用程式中：
1. **上傳資料** 或 **生成測試資料**
2. **設定 API Key** 和 **編譯器**
3. **測試編譯器**
4. **生成 LaTeX 報告**
5. **下載結果**

### 步驟 3: 功能驗證

#### 資料上傳測試
- [ ] CSV 檔案可以正常上傳
- [ ] 資料預覽正常顯示
- [ ] 欄位識別正確

#### LaTeX 編譯測試
- [ ] 編譯器測試通過
- [ ] 簡單 LaTeX 可以編譯
- [ ] PDF 檔案生成成功

#### GPT 整合測試
- [ ] API Key 驗證通過
- [ ] GPT 可以生成 LaTeX
- [ ] 生成的 LaTeX 語法正確

#### 下載功能測試
- [ ] .tex 檔案可以下載
- [ ] .pdf 檔案可以下載
- [ ] 檔案內容正確

## 🐛 故障排除

### 常見問題

#### 1. 套件載入錯誤
```r
# 解決方案：安裝缺失套件
install.packages("package_name")
```

#### 2. LaTeX 編譯器不可用
```bash
# Windows (使用 MiKTeX)
# 下載並安裝 MiKTeX

# macOS (使用 MacTeX)
brew install --cask mactex

# Linux (使用 TeX Live)
sudo apt-get install texlive-full
```

#### 3. API Key 錯誤
- 檢查 API Key 是否正確
- 確認 API Key 有足夠額度
- 檢查網路連線

#### 4. 中文顯示問題
- 使用 xelatex 編譯器
- 確認 LaTeX 文件包含中文支援
- 檢查系統字體

### 除錯技巧

#### 檢查編譯器
```r
# 在 R 中測試編譯器
system2("pdflatex", "--version")
system2("xelatex", "--version")
```

#### 檢查 API 連線
```r
# 測試 API 連線
library(httr)
response <- GET("https://api.openai.com/v1/models", 
                add_headers("Authorization" = "Bearer YOUR_API_KEY"))
status_code(response)
```

#### 檢查檔案權限
```r
# 檢查輸出目錄
dir.create("test_reports", showWarnings = FALSE)
file.access("test_reports", mode = 2)  # 檢查寫入權限
```

## 📈 效能測試

### 資料量測試
- 小資料集 (100 筆記錄)
- 中資料集 (1,000 筆記錄)
- 大資料集 (10,000 筆記錄)

### 編譯時間測試
- 簡單報告 (< 30 秒)
- 複雜報告 (< 2 分鐘)
- 大型報告 (< 5 分鐘)

### API 回應時間測試
- GPT-3.5-turbo (< 10 秒)
- GPT-4 (< 30 秒)

## 📝 測試報告

### 測試結果記錄
記錄以下資訊：
- 測試日期和時間
- 系統環境 (OS, R 版本)
- LaTeX 編譯器版本
- 測試結果 (通過/失敗)
- 錯誤訊息 (如果有)
- 效能數據

### 範例測試報告
```
測試日期: 2025-01-27
系統: Windows 10, R 4.3.0
編譯器: pdflatex 3.141592653
結果: 通過
- 快速測試: ✓
- 應用程式測試: ✓
- 編譯功能: ✓
- API 整合: ✓
效能:
- 資料處理: 0.5 秒
- LaTeX 生成: 15 秒
- PDF 編譯: 2 秒
```

## 🔄 持續測試

### 自動化測試
考慮設置自動化測試：
- 定期執行快速測試
- 監控 API 可用性
- 檢查編譯器狀態

### 回歸測試
在修改模組後：
1. 執行快速測試
2. 驗證所有功能
3. 檢查效能變化
4. 更新測試報告

## 📞 支援

如果遇到問題：
1. 檢查故障排除指南
2. 查看錯誤日誌
3. 確認系統需求
4. 聯繫開發團隊

## 📚 相關文件

- [LaTeX 報告模組使用說明](md/latex_report_module_usage.md)
- [模組原始碼](modules/module_latex_report.R)
- [輔助函數](scripts/global_scripts/04_utils/fn_latex_report_utils.R)
- [完整測試](tests/test_latex_report_module.R) 