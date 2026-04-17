# VitalSigns Premium - bad_weak_ptr 錯誤診斷與修復記錄

## 📋 問題概述

在部署 VitalSigns Premium 到 Posit Connect 後，用戶嘗試登入時遇到 `bad_weak_ptr` 錯誤，導致無法正常使用應用程式。

---

## 🔍 錯誤現象

### 錯誤訊息 1: bad_weak_ptr

```
2025-10-14T14:08:08+08:00 警告： Error in value[[3L]]: 認證查詢錯誤: bad_weak_ptr
2025-10-14T14:08:08+08:00   101: stop
2025-10-14T14:08:08+08:00   100: value[[3L]]
2025-10-14T14:08:08+08:00    99: tryCatchOne
2025-10-14T14:08:08+08:00    98: tryCatchList
2025-10-14T14:08:08+08:00    97: tryCatch
2025-10-14T14:08:08+08:00    96: auth_db_query
2025-10-14T14:08:08+08:00    95: observe
2025-10-14T14:08:08+08:00    94: <observer:observeEvent(input$login_btn)>
```

### 相關日誌

```
2025-10-14T14:16:15+08:00 ✅ PostgreSQL 連接成功
2025-10-14T14:16:19+08:00 ✅ 認證連接已關閉    ← 問題根源！
2025-10-14T14:16:32+08:00 警告： Error in value[[3L]]: 認證查詢錯誤: bad_weak_ptr
```

### 錯誤訊息 2: PostgreSQL 參數語法錯誤

```
Warning: Error in value[[3L]]: 認證查詢錯誤: Failed to prepare query :
ERROR:  syntax error at end of input
LINE 1: SELECT * FROM users WHERE username=?
                                            ^
```

---

## 🧐 根本原因分析

### 原因 1: 認證連接過早關閉

#### 問題代碼 (app.R)

```r
session$onSessionEnded(function() {
  tryCatch({
    # ❌ 錯誤：在每個 session 結束時關閉認證連接
    if (!is.null(auth_con) && DBI::dbIsValid(auth_con)) {
      DBI::dbDisconnect(auth_con)
      cat("✅ 認證連接已關閉\n")
    }
  })
})
```

#### 為什麼這是錯誤的？

1. **`auth_con` 是全域變數**：在應用啟動時建立，供所有 session 共享
2. **在 Shiny 中，每個用戶瀏覽器連接是一個 session**
3. **當第一個 session 結束時**：
   - `session$onSessionEnded()` 被觸發
   - 認證連接被關閉
   - 但 `auth_con` 變數仍然存在
4. **當第二個用戶嘗試登入時**：
   - 使用已失效的 `auth_con`
   - 導致 `bad_weak_ptr` 錯誤

#### 生命週期示意圖

```
應用啟動
  ↓
建立 auth_con (全域)
  ↓
用戶 A 訪問 → Session 1 開始
  ↓
用戶 A 登入 → 使用 auth_con ✅
  ↓
用戶 A 離開 → Session 1 結束
  ↓
❌ auth_con 被關閉（錯誤！）
  ↓
用戶 B 訪問 → Session 2 開始
  ↓
用戶 B 登入 → 嘗試使用 auth_con
  ↓
💥 bad_weak_ptr 錯誤！
```

### 原因 2: 連接池類型檢測失敗

#### 問題代碼 (database/db_connection_lazy.R)

```r
auth_db_query <- function(con, query, params = NULL) {
  # ❌ 錯誤：只檢測 PqConnection，忽略了 Pool
  if (inherits(con, "PqConnection") && !is.null(params) && grepl("\\?", query)) {
    # 轉換參數從 ? 到 $1, $2, ...
  }
  dbGetQuery(con, query, params)
}
```

#### 為什麼這是錯誤的？

1. **使用連接池時**，`con` 的類別是 `"Pool"`，不是 `"PqConnection"`
2. **PostgreSQL 語法要求**：
   - ✅ 正確：`SELECT * FROM users WHERE username=$1`
   - ❌ 錯誤：`SELECT * FROM users WHERE username=?`
3. **參數沒有被轉換**，導致 SQL 語法錯誤

#### 類型檢測問題

```r
# 問題：
inherits(pool_connection, "PqConnection")  # 返回 FALSE
inherits(pool_connection, "Pool")          # 返回 TRUE

# 解決方案：
is_postgres <- inherits(con, "Pool") || inherits(con, "PqConnection")
```

### 原因 3: pool 套件未載入

#### 問題

```r
# config/packages.R
REQUIRED_PACKAGES <- c(
  "pool",  # ← 在清單中
  ...
)

load_packages <- function() {
  suppressPackageStartupMessages({
    library(pool)  # ← 但沒有條件檢查，直接載入
  })
}
```

#### 結果

- 如果 `pool` 套件未安裝，應用啟動失敗
- 在 Posit Connect 上可能出現 "Startup Error"

---

## 🛠️ 修復方案

### 修復 1: 保持認證連接活躍

#### 修改檔案：`app.R`

**之前**：
```r
session$onSessionEnded(function() {
  # ❌ 關閉全域共享的認證連接
  if (!is.null(auth_con) && DBI::dbIsValid(auth_con)) {
    DBI::dbDisconnect(auth_con)
    cat("✅ 認證連接已關閉\n")
  }
})
```

**之後**：
```r
session$onSessionEnded(function() {
  # ✅ 不要關閉認證連接 - 它是全域共享的
  # 認證連接會在應用程式結束時自動關閉
  cat("ℹ️ Session 結束，認證連接保持開啟供其他 session 使用\n")

  # 只關閉該 session 特定的資料庫連接
  if (!is.null(con_global())) {
    conn <- con_global()
    if (!is.null(conn) && DBI::dbIsValid(conn)) {
      DBI::dbDisconnect(conn)
      cat("✅ 主資料庫連接已關閉\n")
    }
  }
})
```

#### Commit
```
25f4d02 - Fix bad_weak_ptr error by keeping auth connection alive
```

### 修復 2: 實現連接池

#### 修改檔案：`database/db_connection_lazy.R`

**之前**：
```r
get_auth_connection <- function() {
  con <- dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("PGHOST"),
    ...
  )
  return(con)
}
```

**之後**：
```r
get_auth_connection <- function() {
  # ✅ 優先使用連接池
  if (requireNamespace("pool", quietly = TRUE)) {
    con <- pool::dbPool(
      drv = RPostgres::Postgres(),
      host = Sys.getenv("PGHOST"),
      port = as.integer(Sys.getenv("PGPORT", "5432")),
      user = Sys.getenv("PGUSER"),
      password = Sys.getenv("PGPASSWORD"),
      dbname = Sys.getenv("PGDATABASE"),
      sslmode = Sys.getenv("PGSSLMODE", "require"),
      minSize = 1,
      maxSize = 3
    )
    cat("✅ PostgreSQL 認證連接池建立成功\n")
  } else {
    # 後備：使用標準連接
    con <- dbConnect(...)
    cat("✅ PostgreSQL 認證連接成功\n")
  }
  return(con)
}
```

#### 優點

1. **自動重連**：連接失效時自動重建
2. **性能提升**：複用現有連接
3. **並發處理**：支持多用戶同時訪問
4. **自動管理**：Pool 在應用結束時自動關閉

#### Commit
```
a72b83f - Fix bad_weak_ptr error on Posit Connect by implementing connection pool
```

### 修復 3: pool 套件優雅降級

#### 修改檔案：`config/packages.R`

**之前**：
```r
load_packages <- function() {
  suppressPackageStartupMessages({
    library(pool)  # ❌ 如果未安裝會報錯
  })
}
```

**之後**：
```r
load_packages <- function() {
  suppressPackageStartupMessages({
    # ✅ pool 套件是可選的
    if (requireNamespace("pool", quietly = TRUE)) {
      library(pool)
      cat("✅ pool 套件已載入 - 將使用連接池\n")
    } else {
      cat("⚠️ pool 套件不可用 - 將使用標準資料庫連接\n")
    }
  })
}
```

#### Commit
```
f549f00 - Fix pool package loading to support graceful degradation
```

### 修復 4: 修復 PostgreSQL 參數檢測

#### 修改檔案：`database/db_connection_lazy.R`

**之前**：
```r
auth_db_query <- function(con, query, params = NULL) {
  # ❌ 只檢測 PqConnection
  if (inherits(con, "PqConnection") && !is.null(params) && grepl("\\?", query)) {
    param_count <- 1
    while (grepl("\\?", query)) {
      query <- sub("\\?", paste0("$", param_count), query)
      param_count <- param_count + 1
    }
  }
  dbGetQuery(con, query, params)
}
```

**之後**：
```r
auth_db_query <- function(con, query, params = NULL) {
  tryCatch({
    # ✅ 檢查是否為 PostgreSQL（包括 Pool 和 PqConnection）
    is_postgres <- inherits(con, "Pool") || inherits(con, "PqConnection")

    # 如果是 PostgreSQL 且查詢包含 ? 參數，需要轉換為 $1, $2, ...
    if (is_postgres && !is.null(params) && grepl("\\?", query)) {
      param_count <- 1
      while (grepl("\\?", query)) {
        query <- sub("\\?", paste0("$", param_count), query)
        param_count <- param_count + 1
      }
    }

    if (is.null(params)) {
      result <- dbGetQuery(con, query)
    } else {
      result <- dbGetQuery(con, query, params)
    }

    return(result)
  }, error = function(e) {
    stop("認證查詢錯誤: ", e$message)
  })
}
```

#### 同樣修復的函數

- `auth_db_execute()`
- `db_query()`
- `db_execute()`

#### Commit
```
c50585e - Fix PostgreSQL parameter placeholder detection for connection pools
```

---

## 📊 修復前後對比

### 修復前

```
應用啟動 → 建立 auth_con
  ↓
Session 1 開始 → 登入成功 ✅
  ↓
Session 1 結束 → auth_con 被關閉 ❌
  ↓
Session 2 開始 → 登入失敗 💥
  ↓
錯誤: bad_weak_ptr
```

### 修復後

```
應用啟動 → 建立 auth_con (Pool)
  ↓
Session 1 開始 → 登入成功 ✅
  ↓
Session 1 結束 → auth_con 保持開啟 ✅
  ↓
Session 2 開始 → 登入成功 ✅
  ↓
Session 3 開始 → 登入成功 ✅
  ↓
應用關閉 → Pool 自動清理
```

---

## 🎯 關鍵技術要點

### 1. Shiny 應用中的連接管理

#### 全域 vs Session 級別

| 類型 | 建立時機 | 關閉時機 | 用途 |
|------|---------|---------|------|
| **全域連接** | 應用啟動 | 應用結束 | 認證、共享資源 |
| **Session 連接** | Session 開始 | Session 結束 | 用戶特定數據 |

#### 範例

```r
# ✅ 正確：全域認證連接
auth_con <- get_auth_connection()  # 在 server 函數外部

server <- function(input, output, session) {
  # ✅ 正確：Session 特定連接
  con_global <- reactive({
    if (login_result$logged_in()) {
      get_con()  # 在 server 函數內部
    }
  })

  session$onSessionEnded(function() {
    # ❌ 錯誤：不要關閉全域連接
    # dbDisconnect(auth_con)

    # ✅ 正確：只關閉 session 連接
    if (!is.null(con_global())) {
      dbDisconnect(con_global())
    }
  })
}
```

### 2. 連接池 vs 標準連接

| 特性 | 標準連接 | 連接池 |
|------|---------|--------|
| **建立方式** | `dbConnect()` | `pool::dbPool()` |
| **類別** | `PqConnection` | `Pool` |
| **重連** | 手動 | 自動 |
| **並發** | 需要多個連接 | 內建支持 |
| **關閉** | 手動 `dbDisconnect()` | 自動清理 |
| **適用場景** | 單用戶、腳本 | 多用戶、Web 應用 |

### 3. PostgreSQL 參數語法

#### SQLite
```sql
SELECT * FROM users WHERE username = ?
```

#### PostgreSQL
```sql
SELECT * FROM users WHERE username = $1
SELECT * FROM users WHERE username = $1 AND role = $2
```

#### R 代碼轉換

```r
# 輸入 SQL
query <- "SELECT * FROM users WHERE username=? AND role=?"
params <- list("admin", "user")

# 檢測並轉換
if (is_postgres && grepl("\\?", query)) {
  # 第一個 ? → $1
  # 第二個 ? → $2
  query <- "SELECT * FROM users WHERE username=$1 AND role=$2"
}

# 執行
dbGetQuery(con, query, params)
```

---

## 📝 Git Commits 記錄

### 完整修復歷程

```bash
# 1. 實現連接池
git commit -m "Fix bad_weak_ptr error on Posit Connect by implementing connection pool

- Add pool package to required packages
- Implement connection pooling in get_auth_connection()
- Update app.R to handle both Pool and standard connections
- Connection pool automatically manages connection lifecycle
- Resolves authentication query errors on Posit Connect"

# 2. 保持認證連接活躍
git commit -m "Fix bad_weak_ptr error by keeping auth connection alive

- Keep auth_con alive across all sessions
- Only close auth_con when application stops
- Fix session-level connection cleanup logic
- Update session cleanup to preserve global auth connection"

# 3. pool 套件優雅降級
git commit -m "Fix pool package loading to support graceful degradation

- Make pool package optional in load_packages()
- Add fallback to standard database connection if pool is not available
- Prevent startup errors when pool package is missing
- Add informative messages about connection type being used"

# 4. 修復 PostgreSQL 參數檢測
git commit -m "Fix PostgreSQL parameter placeholder detection for connection pools

- Update auth_db_query and auth_db_execute to detect Pool connections
- Add is_postgres check that includes both Pool and PqConnection types
- Fix parameter conversion from ? to \$1, \$2, ... for pooled connections
- Apply same fix to db_query and db_execute functions"
```

---

## 🔧 驗證步驟

### 1. 本地測試

```r
# 啟動應用
shiny::runApp()

# 預期輸出
# ✅ pool 套件已載入 - 將使用連接池
# ✅ PostgreSQL 認證連接池建立成功
# ✅ 認證系統初始化完成
```

### 2. 多用戶測試

1. 開啟瀏覽器 A，登入成功
2. 關閉瀏覽器 A
3. 開啟瀏覽器 B，登入測試
4. 預期結果：✅ 登入成功

### 3. 日誌檢查

查看應該出現的訊息：
```
✅ PostgreSQL 認證連接池建立成功
ℹ️ Session 結束，認證連接保持開啟供其他 session 使用
```

不應該出現的訊息：
```
❌ 認證連接已關閉  ← 不應該出現
💥 bad_weak_ptr     ← 不應該出現
```

---

## 📚 相關資源

### 文件連結

- [RPostgres 套件文檔](https://rpostgres.r-dbi.org/)
- [pool 套件文檔](https://rstudio.github.io/pool/)
- [Shiny 資料庫最佳實踐](https://shiny.rstudio.com/articles/pool-basics.html)

### 程式碼位置

- 連接管理：`database/db_connection_lazy.R`
- 套件載入：`config/packages.R`
- Session 管理：`app.R` (第 404-421 行)
- 登入模組：`modules/module_login_optimized.R`

---

## 💡 最佳實踐建議

### 1. 在生產環境使用連接池

```r
# ✅ 推薦：連接池
pool::dbPool(
  drv = RPostgres::Postgres(),
  minSize = 1,    # 最小連接數
  maxSize = 3,    # 最大連接數
  ...
)

# ❌ 不推薦：單一連接（多用戶環境）
dbConnect(RPostgres::Postgres(), ...)
```

### 2. 區分全域和 Session 資源

```r
# 全域：在 server 函數外部
global_resource <- initialize_global()

server <- function(input, output, session) {
  # Session：在 server 函數內部
  session_resource <- reactive({
    if (condition()) {
      create_session_resource()
    }
  })

  session$onSessionEnded(function() {
    # 只清理 session 資源
    cleanup(session_resource())
    # 不要清理全域資源！
  })
}
```

### 3. 實現優雅降級

```r
# 優先使用最佳方案，提供後備選項
if (requireNamespace("pool", quietly = TRUE)) {
  use_connection_pool()
} else {
  use_standard_connection()
}
```

### 4. 資料庫參數轉換

```r
# 統一使用抽象函數，自動處理不同資料庫
auth_db_query <- function(con, query, params = NULL) {
  # 自動檢測資料庫類型
  # 自動轉換參數語法
  # 統一錯誤處理
}
```

---

## 🎓 學習要點

### 1. Shiny 生命週期

- **應用啟動** → 執行一次
- **Session 開始** → 每個用戶連接
- **Session 結束** → 用戶離開或關閉瀏覽器
- **應用結束** → 伺服器停止

### 2. R 的 S3 類別系統

```r
# 檢查物件類別
inherits(obj, "Pool")         # TRUE/FALSE
class(obj)                     # 返回類別名稱

# 連接池的類別層次
class(pool_conn)
# [1] "Pool"     "R6"

class(standard_conn)
# [1] "PqConnection"
# attr(,"package")
# [1] "RPostgres"
```

### 3. 資料庫連接的 C++ 指標

`bad_weak_ptr` 錯誤來自 C++ 層，表示：
- 底層資料庫連接已被釋放
- R 物件仍然存在但指向無效記憶體
- 嘗試使用時觸發錯誤

---

## 📞 支援與聯絡

如遇到類似問題：

1. **檢查日誌**：查看是否有 "認證連接已關閉" 訊息
2. **確認連接類型**：Pool 或標準連接
3. **驗證參數轉換**：PostgreSQL 需要 `$1, $2` 而非 `?`
4. **聯絡支援**：partners@peakedges.com

---

**文件版本**：1.0
**最後更新**：2025-10-14
**作者**：Claude Code
**審核**：鄭澈
