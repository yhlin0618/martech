# Markdown Report Generator

這是一個 Shiny 應用程式，使用 GPT API 生成專業的 Markdown 報告，並可以編譯成 PDF。

## 功能特色

- **智能報告生成**: 使用 GPT API 根據數據摘要生成專業的 Markdown 報告
- **靈活配置**: 可自定義報告標題、作者、日期等設定
- **多種內容選項**: 可選擇包含摘要、圖表、建議等內容
- **即時預覽**: 提供 Markdown 內容的 HTML 預覽
- **PDF 編譯**: 將 Markdown 內容編譯成 PDF 文件
- **下載功能**: 支援下載 Markdown 和 PDF 文件

## 安裝需求

### R 套件
```r
install.packages(c(
  "shiny",
  "dotenv", 
  "dplyr",
  "httr",
  "jsonlite",
  "rmarkdown",
  "knitr",
  "markdown"
))
```

### 環境設定
1. 創建 `.env` 文件在專案根目錄
2. 添加你的 OpenAI API 金鑰：
```
OPENAI_API_KEY_LIN=your_api_key_here
```

## 使用方法

### 1. 運行測試
```r
# 測試功能
source("test_md_functionality.R")
```

### 2. 運行應用
```r
# 方法 1: 直接運行
source("test_md_app.R")

# 方法 2: 使用 runApp
library(shiny)
runApp("test_md_app.R")
```

## 應用界面

### 側邊欄設定
- **報告設定**: 標題、作者、日期
- **數據設定**: 客戶數量、交易數量
- **內容選項**: 摘要、圖表、建議
- **生成按鈕**: 生成 Markdown、編譯 PDF
- **狀態顯示**: 顯示當前操作狀態

### 主面板
- **Generated Markdown**: 顯示生成的 Markdown 內容
- **Preview**: HTML 預覽
- **Download**: 下載 Markdown 和 PDF 文件

## 工作流程

1. **設定報告參數**: 在側邊欄設定報告的基本資訊
2. **生成樣本數據**: 應用會自動生成測試數據
3. **調用 GPT API**: 將數據摘要發送給 GPT 生成 Markdown
4. **預覽內容**: 在預覽標籤中查看格式化內容
5. **編譯 PDF**: 使用 rmarkdown 將 Markdown 編譯成 PDF
6. **下載文件**: 下載生成的 Markdown 或 PDF 文件

## 技術細節

### GPT API 調用
- 使用 GPT-3.5-turbo 模型
- 最大 token 數: 2000
- 溫度設定: 0.7
- 超時設定: 30 秒

### PDF 編譯
- 使用 `rmarkdown::render()` 函數
- 輸出格式: `pdf_document`
- 自動處理 LaTeX 編譯

### 錯誤處理
- API 調用失敗時使用備用內容
- PDF 編譯錯誤時顯示詳細錯誤訊息
- 網路超時處理

## 自定義選項

### 修改 GPT 提示詞
在 `call_gpt_for_markdown()` 函數中修改 `prompt` 變數。

### 添加新的內容選項
1. 在 UI 中添加新的 checkboxInput
2. 在 report_config 中添加對應的設定
3. 在 GPT 提示詞中包含新的選項

### 修改 PDF 樣式
創建自定義的 R Markdown 模板或修改 `rmarkdown::render()` 的參數。

## 故障排除

### API 連接問題
- 檢查 `.env` 文件中的 API 金鑰是否正確
- 確認網路連接正常
- 檢查 API 金鑰是否有足夠的額度

### PDF 編譯問題
- 確保已安裝 MiKTeX 或其他 LaTeX 發行版
- 檢查 R 套件 `rmarkdown` 是否正確安裝
- 查看編譯錯誤日誌

### 權限問題
- 確保應用有寫入 `test_reports` 目錄的權限
- 在 Windows 上可能需要以管理員身份運行

## 範例輸出

### Markdown 內容範例
```markdown
# Sales Analysis Report

**Author:** Analyst  
**Date:** 2025-01-27

## Executive Summary

This report analyzes sales data for 10 customers across 50 transactions.

## Key Findings

- Total Revenue: $15,000
- Average Transaction: $300
- Unique Customers: 10
- Total Transactions: 50

## Analysis

The data shows strong performance with an average transaction value of $300.

## Recommendations

1. Focus on customer retention strategies
2. Consider upselling opportunities
3. Analyze seasonal trends for better planning

---

*Report generated on 2025-01-27 14:30:00*
```

## 開發說明

### 檔案結構
```
├── test_md_app.R              # 主要 Shiny 應用
├── test_md_functionality.R    # 功能測試腳本
├── README_markdown_app.md     # 說明文件
└── test_reports/              # 生成的報告目錄
```

### 擴展建議
- 添加更多數據源支援
- 實現報告模板系統
- 添加圖表生成功能
- 支援多語言報告
- 添加報告歷史記錄

## 授權

此專案遵循 MIT 授權條款。 