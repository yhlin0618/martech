# 自動路徑偵測功能說明

部署腳本（`deploy_now.R` 和 `deploy_auto.R`）現在包含智能路徑偵測功能。

## 🎯 功能特點

### 1. 自動找到專案目錄
無論您從哪裡執行腳本，它都會：
- 偵測腳本本身的位置
- 向上搜尋找到專案根目錄（有 .Rproj 檔案的目錄）
- 自動切換到正確的目錄

### 2. 多種偵測方法
按優先順序嘗試：
1. **RStudio 專案**：如果在 RStudio 中，使用 `rstudioapi::getActiveProject()`
2. **rprojroot**：使用 `rprojroot` 套件尋找 .Rproj 檔案
3. **.Rproj 檔案**：向上搜尋包含 .Rproj 的目錄
4. **特徵檔案**：尋找 app.R、app_config.yaml 或 scripts 目錄

## 📍 使用範例

### 從任何地方執行
```bash
# 從主目錄執行
cd ~
Rscript /path/to/positioning_app/deploy_now.R

# 從其他專案執行
cd /some/other/project
Rscript /Users/che/Library/CloudStorage/Dropbox/ai_martech/l1_basic/positioning_app/deploy_now.R
```

### 在 RStudio 中
```r
# 即使工作目錄不在專案中也能執行
source("/full/path/to/deploy_now.R")
```

## 🔍 除錯資訊

執行時會顯示：
```
📂 腳本位置: /path/to/positioning_app
📍 切換到專案目錄: /path/to/positioning_app
```

## ⚠️ 注意事項

1. **確保有 .Rproj 檔案**：專案根目錄應該有 .Rproj 檔案（如 app.Rproj）
2. **相對路徑**：腳本內部使用相對路徑，所以必須在正確的目錄執行
3. **錯誤處理**：如果找不到專案目錄，會顯示錯誤訊息並停止執行

## 🛠️ 技術細節

腳本使用以下函數：
- `get_script_dir()`：取得腳本所在目錄
- `find_project_root()`：從起始目錄向上搜尋專案根目錄
- `setwd()`：切換到找到的專案目錄

這確保了無論從哪裡調用部署腳本，它都能正確執行。 