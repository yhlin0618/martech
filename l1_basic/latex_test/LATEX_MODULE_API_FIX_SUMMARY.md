# LaTeX 模組 API 問題修正總結

## 問題描述
在 Shiny 環境中，LaTeX 報告模組的 GPT API 請求經常出現 `Timeout was reached [api.openai.com]: SSL/TLS connection timeout` 錯誤。

## 根本原因分析
1. **網路環境問題**：公司/學校網路、VPN、防火牆可能阻擋 Shiny 進程的外部連線
2. **Shiny 環境特殊性**：Shiny 的 reactive 環境可能影響網路請求的穩定性
3. **超時設定過短**：原本的 30 秒超時在網路不穩定時不夠
4. **缺乏 fallback 機制**：API 失敗時沒有備用方案

## 修正方案

### 1. 增強 API 請求穩定性
**檔案**：`scripts/global_scripts/04_utils/fn_latex_report_utils.R`

**修正內容**：
- 增加重試次數：從 3 次增加到 5 次
- 調整延遲策略：初始延遲 3 秒，倍數從 2 倍改為 1.5 倍
- 動態超時設定：Shiny 環境使用 60 秒，非 Shiny 環境使用 30 秒
- 添加 User-Agent 和明確的 SSL 設定

```r
# 修正前
max_retries <- 3
retry_delay <- 2
httr::timeout(30)

# 修正後
max_retries <- 5
retry_delay <- 3
timeout_value <- if (interactive() && !is.null(shiny::getDefaultReactiveDomain())) {
  60  # Shiny 環境
} else {
  30  # 非 Shiny 環境
}
```

### 2. 添加 Fallback 機制
**檔案**：`modules/module_latex_report.R`

**新增功能**：
- `generate_fallback_latex()` 函數：當 API 失敗時自動生成基本 LaTeX 內容
- 包含銷售摘要、DNA 分析等基本資訊
- 明確標示為備用模式生成的報告

**優點**：
- 即使 API 失敗，用戶仍能獲得基本的報告
- 不會因為網路問題而完全無法使用功能
- 提供清晰的錯誤提示

### 3. 修正模板整合問題
**問題**：生成的 LaTeX 內容包含重複的 preamble
**解決**：
- 更新 GPT 提示，明確要求只生成內容部分
- 修正模板整合邏輯，確保正確插入到 `\maketitle` 之後
- 添加 `generate_complete_latex_document()` 函數

### 4. 診斷工具
**新增檔案**：
- `test_shiny_api_debug.R`：專門測試 Shiny 環境中的 API 連線
- `diagnose_latex_issue.R`：全面診斷 LaTeX 模組問題
- `test_template_integration.R`：測試模板整合功能

## 使用建議

### 1. 網路環境檢查
如果仍然遇到 API 超時問題，請檢查：
- 是否在公司/學校網路環境
- 是否使用 VPN
- 防火牆設定是否阻擋外部連線

### 2. 測試步驟
1. 運行 `test_shiny_api_debug.R` 診斷 API 連線
2. 使用 `test_latex_app_fixed.R` 測試完整功能
3. 如果 API 失敗，系統會自動使用備用模式

### 3. 備用模式
當 API 連線失敗時，系統會：
- 自動生成基本的 LaTeX 報告內容
- 包含銷售摘要和 DNA 分析資訊
- 在報告中標示為備用模式生成
- 仍然可以正常編譯和下載 PDF

## 技術細節

### API 請求改進
```r
# 添加更多 headers 和設定
httr::add_headers(
  "Authorization" = paste("Bearer", api_key),
  "Content-Type" = "application/json",
  "User-Agent" = "R-LaTeX-Report-Generator/1.0"
),
httr::config(ssl_verifypeer = TRUE, ssl_verifyhost = TRUE)
```

### Fallback 內容生成
```r
generate_fallback_latex <- function(report_data) {
  # 根據實際資料生成基本 LaTeX 內容
  # 包含銷售摘要、DNA 分析等
  # 標示為備用模式
}
```

## 結論
這些修正大幅提升了 LaTeX 報告模組的穩定性：
1. **更好的錯誤處理**：API 失敗時有備用方案
2. **更穩定的連線**：增強的 retry 邏輯和超時設定
3. **更完整的診斷**：提供多種測試工具
4. **更好的用戶體驗**：即使網路問題也能生成基本報告

建議在網路環境不穩定的情況下，優先使用備用模式，或考慮在網路較穩定的環境中運行。 