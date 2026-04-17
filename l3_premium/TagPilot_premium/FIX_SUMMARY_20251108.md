# TagPilot Premium 修復總結 - 2025-11-08

## 🎯 修復目標
解決應用程式部署到 Posit Connect 時的啟動失敗問題，參考 wonderful_food_BrandEdge_premium 已驗證的成功模式進行修復。

---

## 🐛 問題清單與修復方案

### 問題 1: 資料庫連接失敗
**錯誤訊息**:
```
Error in get_con() : 資料庫連接失敗
```

**根本原因**:
- `get_con()` 函數在建立連接後**立即執行表格初始化**
- 在應用啟動時就嘗試建表，但此時用戶尚未登入
- 如果連接有問題或權限不足，會在啟動時就失敗

**修復方案**:
1. 分離資料庫連接和表格初始化邏輯
2. 新增 `init_tables(con)` 函數專門負責建表
3. 只在用戶**登入成功後**才執行表格初始化

**修改檔案**: `database/db_connection.R`
```r
# ❌ 修復前：get_con() 中包含建表邏輯
get_con <- function() {
  con <- dbConnect(...)
  # 立即建表
  dbExecute(con, "CREATE TABLE IF NOT EXISTS users ...")
  # ...
}

# ✅ 修復後：分離連接和初始化
get_con <- function() {
  con <- dbConnect(...)
  return(con)  # 只返回連接
}

init_tables <- function(con) {
  # 建表邏輯移到這裡
  dbExecute(con, "CREATE TABLE IF NOT EXISTS users ...")
  # ...
}
```

---

### 問題 2: PostgreSQL 配置讀取失敗 (ISSUE-119)
**錯誤訊息**:
```
⚠️ PostgreSQL 配置不完整，將使用 SQLite 測試模式
缺少環境變數: PGHOST, PGUSER, PGPASSWORD, PGDATABASE
```

**根本原因**:
- 使用**靜態快照**方式讀取環境變數
- `APP_CONFIG` 在 `config.R` 載入時就固定了
- Posit Connect 可能在應用啟動後才注入環境變數
- 導致捕獲到空值

**修復方案**:
改用**動態配置讀取**，每次呼叫都重新讀取環境變數

**修改檔案**: `config/config.R`
```r
# ❌ 修復前：靜態快照
APP_CONFIG <- list(
  db = list(
    host = Sys.getenv("PGHOST"),  # 在載入時就固定了
    ...
  )
)

# ✅ 修復後：動態讀取
get_app_config <- function() {
  clean_env <- function(var_name, default = "") {
    value <- Sys.getenv(var_name, default)
    value <- trimws(value)
    value <- gsub('^["\']|["\']$', '', value)
    return(value)
  }

  list(
    db = list(
      host = clean_env("PGHOST"),  # 每次都重新讀取
      ...
    )
  )
}

get_config <- function(key = NULL) {
  config <- get_app_config()  # 動態生成
  # ...
}
```

**參考**:
- 修復了 ISSUE-119 (Posit Connect variable timing issue)
- 新增 `clean_env()` 清理 Posit Connect 可能加入的額外字元

---

### 問題 3: 檔案引用路徑錯誤
**錯誤訊息**:
```
無法開啟檔案 'scripts/global_scripts/04_utils/safe_get.R' : No such file or directory
```

**根本原因**:
- 引用的檔案名稱缺少 `fn_` 前綴
- 實際檔案名稱為 `fn_safe_get.R` 和 `fn_remove_na_strings.R`

**修復方案**:
修正所有檔案引用的名稱

**修改檔案**: `utils/data_access.R`
```r
# ❌ 修復前
source("scripts/global_scripts/04_utils/safe_get.R")
source("scripts/global_scripts/04_utils/remove_na_strings.R")

# ✅ 修復後
source("scripts/global_scripts/04_utils/fn_safe_get.R")
source("scripts/global_scripts/04_utils/fn_remove_na_strings.R")
```

---

### 問題 4: 缺少必要套件
**錯誤訊息**:
```
錯誤發生在 library(networkD3)： 不存在叫 'networkD3' 這個名稱的套件
```

**根本原因**:
- `modules/module_advanced_analytics.R` 使用了 `networkD3` 和 `htmlwidgets`
- 但這兩個套件沒有在 `config/packages.R` 的必要套件列表中

**修復方案**:
在套件列表中加入缺少的套件

**修改檔案**: `config/packages.R`
```r
REQUIRED_PACKAGES <- c(
  # ...
  # 視覺化
  "DT",
  "GGally",
  "plotly",
  "networkD3",      # ✅ 新增
  "htmlwidgets",    # ✅ 新增
  # ...
)

load_packages <- function() {
  suppressPackageStartupMessages({
    # ...
    library(networkD3)      # ✅ 新增
    library(htmlwidgets)    # ✅ 新增
    # ...
  })
}
```

---

### 問題 5: 語法錯誤
**警告訊息**:
```
package 'is.data.table' is not available
```

**根本原因**:
- `test_dna_flow.R` 中函數名稱和套件名稱寫反了
- `is.data.table::data.table()` 應該是 `data.table::is.data.table()`

**修復方案**:
修正函數調用語法

**修改檔案**: `test_dna_flow.R`
```r
# ❌ 修復前
if (is.data.table::data.table(customer_data)) {

# ✅ 修復後
if (data.table::is.data.table(customer_data)) {
```

---

### 問題 6: app.R 初始化順序
**根本原因**:
- 在 server 函數一開始就呼叫 `get_con()`
- 此時用戶尚未登入，但已嘗試初始化表格

**修復方案**:
調整初始化順序，只在登入後才初始化表格

**修改檔案**: `app.R`
```r
# ✅ 修復後
server <- function(input, output, session) {
  # 資料庫連接（連接但不初始化表格）
  con_global <- get_con()

  # 反應式變數
  user_info <- reactiveVal(NULL)
  db_initialized <- reactiveVal(FALSE)

  # 登入模組
  login_mod <- loginModuleServer("login1")

  observe({
    user_info(login_mod$user_info())

    # 登入成功後初始化資料表
    if (!is.null(user_info()) && !db_initialized()) {
      tryCatch({
        init_tables(con_global)
        db_initialized(TRUE)
        showNotification("✅ 資料庫初始化完成", type = "message")
      }, error = function(e) {
        showNotification(paste("資料庫初始化失敗:", e$message), type = "error")
      })
    }
  })
}
```

---

## 📝 修改檔案清單

### 核心修復
1. ✅ `database/db_connection.R`
   - 分離 `get_con()` 和 `init_tables()`
   - 簡化 `get_db_info()`
   - 更新 `db_query()` 和 `db_execute()`
   - 修正資料庫檔名和測試帳號

2. ✅ `config/config.R`
   - 新增 `get_app_config()` 動態配置函數
   - 新增 `clean_env()` 環境變數清理函數
   - 更新 `get_config()` 改為動態讀取

3. ✅ `config/packages.R`
   - 新增 `networkD3` 和 `htmlwidgets` 套件

4. ✅ `app.R`
   - 調整資料庫連接和初始化順序
   - 新增 `db_initialized` 狀態追蹤
   - 在登入後才初始化表格

5. ✅ `utils/data_access.R`
   - 修正檔案引用路徑（加上 `fn_` 前綴）

6. ✅ `test_dna_flow.R`
   - 修正 `is.data.table` 函數調用語法

---

## 🎯 驗證結果

### 本地測試
- ✅ SQLite 模式正常啟動
- ✅ 登入功能正常
- ✅ 資料上傳功能正常
- ✅ DNA 分析功能正常

### Posit Connect 部署
- ✅ 應用成功啟動
- ✅ PostgreSQL 環境變數正確讀取
- ✅ 資料庫連接成功
- ✅ 所有模組正常運作

---

## 📚 參考資料

### 成功案例
參考了以下已驗證可正常運作的專案：
- `wonderful_food_BrandEdge_premium`
- `wonderful_food_TagPilot_premium`

### 關鍵改進點
1. **動態配置讀取** - 解決 Posit Connect 變數注入時機問題
2. **延遲初始化** - 只在登入後才建立資料表
3. **環境變數清理** - 處理 Posit Connect 可能加入的額外字元

---

## 🚀 部署資訊

### GitHub Repository
- **原始 Repo**: `https://github.com/kiki830621/TagPilot_premium.git`
- **備份 Repo**: `git@github.com:kiki830621/TagPilot_premium___v20251108.git`

### Commit History
```
26ecfe5 - Update manifest.json and package metadata
b838d66 - Add networkD3 and htmlwidgets packages
41099e1 - Update data_access.R file references
c04685e - Refactor configuration loading
9a57e38 - Refactor database connection and initialization
```

---

## 🎓 經驗總結

### 最佳實踐
1. ✅ 使用動態配置讀取，避免靜態快照
2. ✅ 延遲資料庫初始化至用戶登入後
3. ✅ 所有檔案引用需檢查實際檔名
4. ✅ 必要套件列表需完整
5. ✅ 參考已驗證的成功案例

### 常見陷阱
1. ❌ 環境變數在載入時可能尚未設定（Posit Connect）
2. ❌ 在應用啟動時就執行需要權限的操作
3. ❌ 檔案命名規範不一致（有無 `fn_` 前綴）
4. ❌ 套件依賴不完整

---

**修復完成日期**: 2025-11-08
**修復狀態**: ✅ 完全解決
**測試狀態**: ✅ 通過所有測試
**修復人員**: Claude AI + 鄭澈
