# 測試 Shiny App 時

**使用時機**: 修改 UI、翻譯、元件邏輯後需要驗證結果時

---

## 測試策略（雙軌制）

| 層級 | 工具 | 何時使用 |
|------|------|----------|
| **自動化 E2E**（主要） | shinytest2 + testthat | 每次 commit 前、迴歸測試 |
| **互動式測試**（補充） | /shiny-debug + agent-browser | 新功能探索、視覺驗證、除錯 |

### 為什麼選 shinytest2 而非 Playwright

| 面向 | shinytest2 | Playwright |
|------|-----------|------------|
| 操作層級 | Shiny input 層（`app$set_inputs()`） | DOM 層（CSS selector / click） |
| 後端可見性 | 可讀 R log、reactive values、output values | 只能看前端 console |
| 瀏覽器安裝 | 內建 chromote，零額外安裝 | 需安裝 Playwright + 瀏覽器二進位檔 |
| 斷言方式 | 直接比對 Shiny output 值 | 只能比對 DOM text / screenshot |
| 快照測試 | 原生支援（JSON + screenshot） | 需自行建構 |
| R 整合 | 原生（testthat 生態系） | 需跨語言橋接（Node.js ↔ R） |
| 適合場景 | **自動化迴歸測試、CI** | 跨框架 Web 測試 |

**結論**：Shiny 應用的 E2E 測試首選 shinytest2。Playwright（透過 `/shiny-debug` + agent-browser）保留作為互動式探索和視覺驗證的補充工具。

---

## 自動化 E2E 測試（shinytest2）

位置: `98_test/e2e/`

### 執行方式

從公司專案根目錄執行：
```bash
cd D_RACING
Rscript -e "testthat::test_dir('scripts/global_scripts/98_test/e2e')"
```

或透過 Makefile：
```bash
cd scripts/update_scripts
make e2e
```

### 測試分級

| 級別 | 名稱 | 內容 | 執行頻率 |
|------|------|------|----------|
| L1 | Smoke Test | 登入 + 首頁載入 | 每次 commit |
| L2 | Navigation | 所有 tab 可切換、無 R 錯誤 | 每次 commit |
| L3 | Functional | 元件互動、資料篩選、KPI 正確性 | 功能變更後 |
| L4 | Visual | 截圖比對（shinytest2 snapshot） | 重大 UI 變更後 |

### 新增測試場景

1. 在 `98_test/e2e/` 建立 `test-{場景名}.R`
2. 使用 `create_logged_in_app()` 取得已登入的 AppDriver
3. 使用 shinytest2 API 操作 + 斷言
4. 測試結束自動清理（`on.exit(stop_app_safely(app))`)

### 相關原則

- **TD_R007**: E2E Testing Standard
- **TD_R001**: Test Data（使用真實 app_data）
- **MP029**: No Fake Data

---

## DEBUG_MODE — 儀表板輸出全記錄 (DEV_R054)

當 `SHINY_DEBUG_MODE=TRUE` 時，所有 `render*()` 輸出必須呼叫 `debug_log_output()` 再回傳。用於自動偵測空白面板（NULL 輸出）。

- 工具函數：`04_utils/fn_debug_mode.R`
- E2E 自動啟用：`98_test/e2e/_setup.R`
- Issue: [#286](https://github.com/kiki830621/ai_martech_global_scripts/issues/286)

**Details**: `docs/en/part1_principles/CH05_testing_deployment/rules/DEV_R054_debug_mode_dashboard_logging.qmd`

---

## 互動式測試（/shiny-debug）

使用 `/shiny-debug` 指令（來自 `r-shiny-debugger` plugin）。

此工具整合：
- **前端**: `agent-browser` 操作 UI、截圖、讀取元素
- **後端**: R console log 即時監控錯誤和警告

---

## 本專案設定

### App 啟動方式

**工作目錄必須是專案根目錄**（參見 `06-running-app.md`）：

```bash
# 專案根目錄
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/QEF_DESIGN

# 啟動 App（由 /shiny-debug 自動處理）
Rscript app.R
```

`app.R` 會讀取 `app_config.yaml` 中的 `deployment.main_file`，實際執行：
```
scripts/global_scripts/10_rshinyapp_components/unions/union_production_test.R
```

### 登入資訊

| 情境 | 值 |
|------|-----|
| 密碼 only | `VIBE` |
| 帳號 + 密碼 | admin / 618112 |

目前 App 使用 **密碼 only** 模式（`passwordOnly` 模組）。

### 測試 Port

| 用途 | Port |
|------|------|
| 預設測試 | 3838 |
| 備用 | 3839, 3840 |

---

## 前後端雙軌檢查（重要）

每次 `agent-browser` 操作後，**必須同時檢查前端和後端**：

```bash
# 前端：瀏覽器 console 錯誤
agent-browser console
agent-browser errors

# 後端：R log 錯誤
tail -20 .shiny-debug/shiny.log
grep -iE "error|warning|✗" .shiny-debug/shiny.log | tail -10
```

### 後端 log 關鍵訊息

| Log 訊息 | 意義 |
|-----------|------|
| `[Translation] Initialized: ui_text=zh_TW` | 翻譯系統正常啟動 |
| `[Translation] Init failed` | 翻譯系統啟動失敗，降級為 identity |
| `PROFILE: source_type=...` | ETL config 讀取成功 |
| `Error in dbConnect` | 資料庫連線失敗 |
| `Column not found` | 表格 schema 不符 |

---

## 常見測試場景

### 1. UI 翻譯驗證

```
/shiny-debug 驗證 UI 翻譯是否正確顯示中文
```

檢查項目：
- [ ] Sidebar accordion 標題 → "平台"、"產品線"
- [ ] Product line dropdown → 中文產品名稱
- [ ] App 標題列 → "AI營銷平台"
- [ ] 後端 log 有 `[Translation] Initialized`

### 2. 元件切換

```
/shiny-debug 測試切換不同 sidebar tab 是否正常載入
```

檢查項目：
- [ ] 切換 tab 無前端 JS 錯誤
- [ ] 後端 log 無 Error
- [ ] 動態 filter 面板正確切換

### 3. 登入流程

```
/shiny-debug 測試登入流程
```

檢查項目：
- [ ] 登入頁面正確顯示
- [ ] 輸入密碼 `VIBE` 後進入主 App
- [ ] 錯誤密碼顯示提示訊息

---

## 遇到問題時的處理原則

### Log 不夠明確

如果 R log 中的錯誤訊息不足以定位問題：

1. **找到出錯的程式碼位置**
2. **加入更具體的 `message()` 或 `tryCatch()` 輸出**
3. **重啟 App 重新測試**

範例 — 從模糊的錯誤：
```r
# 不好：只知道「失敗了」
Error in eval(expr, envir)
```

改為明確的診斷：
```r
# 好：知道是哪個元件、什麼資料出問題
tryCatch({
  result <- some_operation(data)
}, error = function(e) {
  message("[ComponentName] Failed at operation X: ", e$message)
  message("[ComponentName] Input data class: ", class(data), ", nrow: ", nrow(data))
})
```

### 前端元素找不到

```bash
# 重新掃描頁面互動元素
agent-browser snapshot -i

# 如果頁面還在載入，等待
agent-browser wait 2000
agent-browser snapshot -i
```
