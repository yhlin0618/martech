# LaTeX 報告模組使用說明

## 概述

LaTeX 報告模組 (`module_latex_report.R`) 是一個功能完整的報告生成工具，能夠：

1. **收集應用程式輸出資料**：自動收集銷售資料、DNA 分析結果等
2. **轉換為 JSON 格式**：將資料結構化為適合 GPT 處理的格式
3. **透過 GPT 生成 LaTeX**：使用 OpenAI API 生成專業的 LaTeX 報告
4. **本地編譯 PDF**：在本地環境編譯 LaTeX 並生成 PDF 報告
5. **提供下載功能**：支援下載 .tex 原始碼和 .pdf 報告

## 功能特色

### 📊 資料收集
- 自動識別銷售資料欄位（客戶ID、金額、時間等）
- 整合 DNA 分析結果（M、R、F、IPT 指標）
- 支援自訂資料來源和格式

### 🤖 AI 驅動
- 使用 GPT-4 或 GPT-3.5-turbo 生成 LaTeX
- 支援中文內容和專業格式
- 可自訂生成指令和創意度

### 📄 報告格式
- 標準報告模板
- 簡潔報告模板  
- 詳細報告模板
- 支援自訂模板

### 🔧 編譯選項
- 支援 pdflatex 和 xelatex 編譯器
- 自動編譯和手動編譯選項
- 編譯狀態即時顯示

## 安裝需求

### R 套件
```r
# 必要套件
library(dplyr)
library(jsonlite)
library(httr)
library(rmarkdown)
library(tools)

# 可選套件（用於更好的使用者體驗）
library(cli)  # 進度顯示
```

### 系統需求
- **LaTeX 編譯器**：pdflatex 或 xelatex
- **OpenAI API Key**：用於 GPT 報告生成
- **網路連線**：用於 API 呼叫

### 安裝 LaTeX
- **Windows**：安裝 MiKTeX 或 TeX Live
- **macOS**：安裝 MacTeX
- **Linux**：安裝 TeX Live

## 基本使用

### 1. 在 app.R 中載入模組

```r
# 載入模組
source("modules/module_latex_report.R")

# 在 UI 中加入模組
ui <- fluidPage(
  # ... 其他 UI 元件 ...
  latexReportModuleUI("latex_report")
)

# 在 Server 中初始化模組
server <- function(input, output, session) {
  # ... 其他模組 ...
  
  # 初始化 LaTeX 報告模組
  latex_results <- latexReportModuleServer(
    "latex_report",
    con = con,
    user_info = user_info,
    sales_data = sales_data,
    dna_results = dna_results,  # 可選
    other_results = other_results  # 可選
  )
}
```

### 2. 基本設定

1. **報告設定**
   - 輸入報告標題、作者、日期
   - 選擇報告模板（標準/簡潔/詳細）
   - 添加自訂指令（可選）

2. **資料選擇**
   - 勾選要包含的資料類型
   - 銷售摘要、DNA 分析、客戶分群等

3. **API 設定**
   - 輸入 OpenAI API Key
   - 選擇 GPT 模型
   - 調整創意度參數

### 3. 生成報告

1. 點擊「📄 生成 LaTeX 報告」按鈕
2. 系統會自動：
   - 收集選定的資料
   - 轉換為 JSON 格式
   - 發送給 GPT API
   - 生成 LaTeX 原始碼
   - 自動編譯 PDF（如果啟用）

### 4. 下載報告

- **LaTeX 原始碼**：點擊「📥 下載 .tex 檔案」
- **PDF 報告**：點擊「📥 下載 PDF 報告」

## 進階功能

### 自訂報告模板

```r
# 在自訂指令中指定特殊要求
custom_instructions <- "
請生成一份包含以下內容的報告：
1. 執行摘要
2. 資料概覽
3. 客戶分群分析
4. 策略建議
5. 附錄

請使用專業的商業報告格式，包含圖表和表格。
"
```

### 整合其他分析結果

```r
# 傳遞其他分析結果給模組
other_results <- list(
  customer_segments = customer_segments_data,
  market_analysis = market_analysis_data,
  recommendations = recommendations_data
)

latex_results <- latexReportModuleServer(
  "latex_report",
  con = con,
  user_info = user_info,
  sales_data = sales_data,
  dna_results = dna_results,
  other_results = other_results
)
```

### 自訂編譯設定

```r
# 在設定標籤中調整
latex_compiler = "xelatex"  # 使用 xelatex 以更好地支援中文
auto_compile = FALSE        # 手動編譯
```

## 故障排除

### 常見問題

#### 1. API Key 錯誤
**症狀**：顯示「API 錯誤」訊息
**解決方案**：
- 檢查 API Key 是否正確
- 確認 API Key 有足夠的額度
- 檢查網路連線

#### 2. LaTeX 編譯失敗
**症狀**：PDF 無法生成
**解決方案**：
- 確認已安裝 LaTeX 編譯器
- 檢查編譯器路徑設定
- 查看編譯日誌中的錯誤訊息

#### 3. 資料欄位無法識別
**症狀**：銷售摘要顯示錯誤
**解決方案**：
- 確認資料包含必要欄位（客戶ID、金額、時間）
- 檢查欄位名稱是否符合預期格式
- 使用自訂指令指定欄位對應

#### 4. 中文顯示問題
**症狀**：PDF 中中文顯示為亂碼
**解決方案**：
- 使用 xelatex 編譯器
- 確認 LaTeX 文件包含中文支援套件
- 檢查系統字體設定

### 除錯技巧

1. **檢查編譯日誌**
   - 在「編譯狀態」標籤中查看詳細錯誤訊息
   - 根據錯誤訊息調整 LaTeX 原始碼

2. **測試簡單文件**
   - 先使用簡單的 LaTeX 文件測試編譯器
   - 確認基本功能正常後再生成複雜報告

3. **驗證 API 連線**
   - 使用簡單的 API 測試確認連線正常
   - 檢查 API 額度和限制

## 效能優化

### 1. 資料處理
- 使用 `verbose = FALSE` 減少日誌輸出
- 預先過濾和清理資料
- 避免重複的資料處理

### 2. API 使用
- 合理設定 `max_tokens` 參數
- 使用適當的 `temperature` 值
- 考慮 API 呼叫頻率限制

### 3. 編譯優化
- 使用 `-interaction=nonstopmode` 參數
- 清理臨時檔案
- 考慮使用快取機制

## 擴展開發

### 新增報告模板

1. 修改 `fn_collect_report_data` 函數
2. 在 UI 中添加新的模板選項
3. 更新 GPT 提示詞以支援新模板

### 整合其他 AI 服務

1. 修改 `fn_generate_latex_via_gpt` 函數
2. 支援其他 AI 服務的 API
3. 添加相應的認證和錯誤處理

### 自訂編譯流程

1. 擴展 `fn_compile_latex_report` 函數
2. 支援更多編譯選項
3. 添加編譯後處理步驟

## 相關文件

- [模組原始碼](modules/module_latex_report.R)
- [輔助函數](scripts/global_scripts/04_utils/fn_latex_report_utils.R)
- [測試文件](tests/test_latex_report_module.R)
- [原則文件](scripts/global_scripts/00_principles/)

## 版本歷史

- **v1.0.0** (2025-01-27)
  - 初始版本
  - 基本 LaTeX 報告生成功能
  - GPT API 整合
  - 本地 PDF 編譯
  - 下載功能 