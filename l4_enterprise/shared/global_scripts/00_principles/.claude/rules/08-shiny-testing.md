# 測試 Shiny App 時

**使用時機**: 修改 UI、翻譯、元件邏輯後需要驗證結果時

---

## 測試策略（三軌制）

| 層級 | 工具 | 何時使用 |
|------|------|----------|
| **自動化 E2E**（主要） | shinytest2 + testthat | 每次 commit 前、迴歸測試（local app） |
| **互動式測試**（除錯） | /shiny-debug + agent-browser | 新功能探索、視覺驗證、除錯（local app） |
| **Live Dashboard 驗證** | safari-browser (macOS) | 部署後的 smoke test、Posit Connect rebuild 後的 UI spot check（remote URL） |

### 三工具適用情境對照

| 面向 | shinytest2 | agent-browser (via /shiny-debug) | safari-browser |
|------|-----------|----------------------------------|----------------|
| 適用環境 | local app only | local app only | **remote URL + local 皆可** |
| 操作層級 | Shiny input 層（`app$set_inputs()`） | DOM 層（CSS selector / click） | DOM 層 + tab/window 鎖定 |
| 後端可見性 | 可讀 R log、reactive values、output values | 可讀本地 `.shiny-debug/shiny.log` | 無（遠端 log 由 Posit Connect 管） |
| 瀏覽器需求 | 內建 chromote，零安裝 | 需安裝 agent-browser + 瀏覽器 | 直接呼叫系統 Safari（macOS 內建） |
| 斷言方式 | 直接比對 Shiny output 值 | DOM text / screenshot | DOM text / screenshot |
| 多視窗/多分頁支援 | N/A（測試用獨立 chromote session） | 單視窗 | **原生 `--url` / `--window` / `--document` 鎖定** |
| 快照測試 | 原生支援（JSON + screenshot） | 需自行建構 | 需自行建構 |
| 適合場景 | **自動化迴歸測試、CI** | **新功能探索、本地除錯** | **Live dashboard 驗證、部署後 smoke test** |

**結論**：三者互補不衝突。
- `shinytest2` 是 CI 主力(跑本地 app 做 input/output 斷言)
- `agent-browser` 是本地探索除錯主力(能同時看前端 + R log)
- `safari-browser` 是 live URL 驗證主力(遠端部署唯一選擇,且支援 tab 鎖定防誤操作)

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
- E2E 自動啟用：`98_test/e2e/setup.R`
- Issue: [#286](https://github.com/kiki830621/ai_martech_global_scripts/issues/286)

**Details**: `docs/en/part1_principles/CH05_testing_deployment/rules/DEV_R054_debug_mode_dashboard_logging.qmd`

---

## 互動式測試（/shiny-debug）

使用 `/shiny-debug` 指令（來自 `r-shiny-debugger` plugin）。

此工具整合：
- **前端**: `agent-browser` 操作 UI、截圖、讀取元素
- **後端**: R console log 即時監控錯誤和警告

---

## Live Dashboard 驗證（safari-browser）

使用 `safari-browser` CLI 驗證已部署到遠端（Posit Connect Cloud / Shinyapps.io）的 live dashboard。

### 適用情境

| 情境 | 使用時機 |
|------|---------|
| 部署後 smoke test | `make deploy-push` 後,確認 live URL 能載入、登入、顯示 KPI |
| Posit Connect rebuild 後 UI spot check | 資料更新重跑 pipeline + upload 後,驗證儀表板反映最新資料 |
| 跨平台 UI 驗證 | 切換多個 platform filter (all/cbz/eby) 確認每個都能正常渲染 |
| Customer 報告的 UI 問題重現 | 在 live 環境重現使用者描述的視覺問題並截圖 |

### 基本工作流程

> **⚠️ `@e1`, `@e2`, `@e10` 等 refs 是 per-page snapshot 的臨時編號,不是固定值**。每次頁面切換或 Shiny re-render 後**必須重跑** `safari-browser snapshot -i --url <substr>` 重新取得 refs。以下範例的 `@e1 = password`、`@e10 = cbz radio` 是 MAMBA 某次 snapshot 的結果,你的情境可能完全不同 — **不要直接複製數字**,要先 snapshot。

```bash
# 1. 開啟 live URL
safari-browser open "https://<company>-<app>.share.connect.posit.cloud/" --url <company>

# 2. 掃描互動元素（取得 @e1, @e2, ... refs）
safari-browser snapshot -i --url <company>

# 3. 互動（依 ref 操作）
safari-browser fill @e1 VIBE --url <company>   # 填密碼
safari-browser click @e2 --url <company>        # 點登入按鈕
safari-browser click @e10 --url <company>       # 切換 platform radio

# 4. 截圖驗證
safari-browser screenshot /tmp/dashboard_cbz.png --url <company>

# 5. 讀截圖確認 KPI 顯示完整
```

### Tab 鎖定最佳實踐（重要）

**macOS 使用者常同時開多個 Safari 視窗**。若不指定目標分頁,命令會操作「front tab」,可能誤動到其他頁面。

**一律加鎖定 flag**:

| Flag | 使用時機 | 範例 |
|------|---------|------|
| `--url <substring>` | **首選** — URL 不變就鎖得住,最穩定 | `--url mamba.share.connect` |
| `--window <N>` | 已知是第 N 個視窗(1-indexed) | `--window 2` |
| `--document <N>` / `--tab <N>` | 按文件索引(跨視窗全域編號) | `--document 3` |

**決策樹**:

```
需要自動化 → 用 --url <URL-substring>（最穩定）
知道是哪個視窗 → 用 --window <N>
確定是第 N 個分頁 → 用 --document <N>
都不確定 → 先跑 safari-browser documents 列出所有分頁再選
```

**錯誤做法**（會被背景 tab 變動影響）:

```bash
# ✗ 不好:沒鎖定,命令操作當前 front tab
safari-browser click @e10

# ✗ 不好:使用者切換到其他分頁時命令就跑到錯的頁面
safari-browser screenshot /tmp/x.png
```

**正確做法**:

```bash
# ✓ 好:鎖定 mamba live URL,不論使用者當下在哪個分頁都不影響
safari-browser click @e10 --url mamba.share.connect
safari-browser screenshot /tmp/x.png --url mamba.share.connect
```

### 前端與後端驗證差異

| 檢查項目 | agent-browser (local) | safari-browser (remote) |
|---------|----------------------|------------------------|
| 前端 console 錯誤 | `agent-browser console` | `safari-browser console --url <substr>` |
| 前端 JS errors | `agent-browser errors` | `safari-browser errors --url <substr>` |
| 後端 R log | `tail .shiny-debug/shiny.log` | **不可見** — 遠端 log 由 Posit Connect dashboard 管 |

**結論**:Live Dashboard 驗證**無法看後端 log**。若懷疑後端問題,需:
1. 登入 Posit Connect 管理介面看 deployment log
2. 或回本地用 `/shiny-debug` + agent-browser 重現

### MAMBA #378 Phase 5 實際驗證範本

```bash
# Setup: 讀取 deploy URL
URL="https://kyleyhl-ai-martech-l4-mamba.share.connect.posit.cloud/"
LOCK="--url mamba.share.connect"

# Step 1: 開啟 + 確認標題
safari-browser open "$URL" $LOCK
safari-browser snapshot -i $LOCK   # 驗證出現 @e1 (password input)

# Step 2: 登入
safari-browser fill @e1 VIBE $LOCK
safari-browser click @e2 $LOCK     # 進入系統 button

# Step 3: 驗證預設平台 (all)
safari-browser screenshot /tmp/dashboard_all.png $LOCK
# 讀 screenshot 確認 KPI 數字 > 0

# Step 4: 切換到 cbz
safari-browser click @e10 $LOCK    # cbz radio
safari-browser screenshot /tmp/dashboard_cbz.png $LOCK

# Step 5: 切換到 eby (關鍵! 必須驗證每個 active platform)
safari-browser click @e9 $LOCK     # eby radio
safari-browser screenshot /tmp/dashboard_eby.png $LOCK

# Step 6: 切換到各個 tab (customerAcquisition / customerRetention / dashboardOverview)
safari-browser click @e24 $LOCK    # 顧客結構 tab
safari-browser screenshot /tmp/tab_structure.png $LOCK
```

### 常見問題

| 問題 | 原因 | 解決方案 |
|------|------|----------|
| `safari-browser snapshot` 回傳空清單 | 頁面還在載入 | `safari-browser wait 3000 $LOCK` 後重跑 |
| Click 後畫面沒變 | Shiny reactive 尚未觸發 | 用 `safari-browser wait 3000 $LOCK` 代替 `sleep`。**不可用 `sleep 3`** — Bash hook 規則封鎖 `sleep N` 當 `N ≥ 2` 的第一層指令,只允許 `< 2 秒`的刻意延遲。 |
| 鎖定 `--url` 但找不到分頁 | URL 片段拼錯或分頁未開 | 先 `safari-browser documents` 列出實際 URL |
| KPI 顯示 `-` 或全零 | Posit Connect rebuild 未完成 | 等 3-5 分鐘讓 deploy 完成,或看 Connect log |

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

### 4. 多平台切換驗證 checklist（重要）

**觸發時機**:任何可能影響 per-platform 資料的 pipeline 改動(ETL/DRV/upload)後,live dashboard 驗證時。

**核心原則**:**每個 active platform 都要單獨驗證,不可只驗 `all`**。

app_config.yaml `platforms:` 下 `status: "active"` 的每一個平台都要切過 radio,因為:

- `all` 平台是多個平台的聚合;單一平台資料空/錯會被其他平台「稀釋」看不出來
- DRV 層的 platform-specific 資料表(如 `df_cbz_poisson_analysis_*`)只在切到對應 platform 時會載入
- UI 在 platform 切換時觸發不同的 reactive 流程,可能有不同的 edge case

**checklist 範本(MAMBA)**:

> **⚠️ 以下 cbz/eby 是 MAMBA 的 active platforms。跑其他公司時請依該公司的 `app_config.yaml` > `platforms:` section 替換成實際 active codes(例如 QEF_DESIGN 可能是 `amz`,D_RACING 可能不同)。**

- [ ] Platform = `all`:總覽儀表板 KPI 全部有值(> 0)
- [ ] Platform = `cbz`:總覽儀表板 KPI 全部有值,且數字合理(不應該是 `all` 的一半以下)
- [ ] Platform = `eby`:總覽儀表板 KPI 全部有值(即使 eby 客戶數少,也該有非零顯示)
- [ ] 每個 platform 切換一個 TagPilot subtab(如「顧客價值 (RFM)」),確認不會出現「No data」或全空圖表
- [ ] 每個 platform 切換到「報告中心」,確認報告能生成

**錯誤反例(MAMBA #378 Phase 5 incident)**:

> 只驗證 `all`(總覽 KPI 正常)就 mark task 完成,沒切 `eby` single platform,結果沒發現 eby 側資料下載量過小(5 customers)的問題。使用者上線後自己發現才回報。

**修正原則**:checklist 項目必須是「每個 active platform 一個 checkbox」,不能合併成單一項目「KPI 正常」。

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
