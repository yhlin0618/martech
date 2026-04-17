# 執行 App 時

**使用時機**: 啟動或測試 Shiny 應用程式時

---

## 執行方式

### 工作目錄
**專案根目錄** 是工作目錄，不是 app 資料夾：
```
/Users/che/.../MAMBA/   ← 從這裡執行
```

### 啟動 App
```r
# 在 RStudio 或 R console
source("app.R")

# 或使用 Rscript
Rscript app.R
```

---

## 登入資訊

### 測試用密碼（只要輸入密碼的情況）
```
VIBE
```

### 測試用帳號密碼（要輸入帳號密碼的情況）
```
帳號：admin
密碼：618112
```

---

## 常見問題

### 路徑錯誤
如果遇到 `Error in source()` 或找不到檔案：
- 確認工作目錄是專案根目錄
- 使用 `getwd()` 檢查目前目錄
- 使用 `setwd()` 切換到正確目錄

### 資料庫連線
App 啟動時會自動連接 `data/app_data/app_data.duckdb`。
確保資料庫檔案存在且未被其他程序鎖定。

---

## E2E 測試

修改核心功能後、部署前，使用 **shinytest2** 執行自動化 E2E 測試。

詳細說明請參考 `08-shiny-testing.md`。

### 快速執行
```bash
cd D_RACING
Rscript -e "testthat::test_dir('scripts/global_scripts/98_test/e2e')"
```

### 互動式測試（除錯用）

使用 `/shiny-debug` 指令進行探索性測試和即時除錯。

### 各 App 測試端口
| App | 端口 |
|-----|------|
| BrandEdge | 3838 |
| InsightForge | 3839 |
| VitalSigns | 3840 |
