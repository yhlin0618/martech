# 部署格式問題修復說明

## 🔧 已修復的問題

### 1. 路徑偵測問題
**問題**：使用 `source()` 執行部署腳本時，無法正確偵測到專案目錄

**解決方案**：
- 改進 `get_script_dir()` 函數，增加多種偵測方法
- 添加備用路徑列表，確保能找到正確的專案目錄
- 支援從任何目錄執行部署腳本

### 2. rsconnect 語法錯誤
**問題**：`rsconnect::writeManifest()` 掃描到 archive 目錄中的舊檔案，產生大量語法錯誤

**解決方案**：
- 創建 `.renvignore` 檔案，排除問題目錄：
  - `scripts/global_scripts/99_archive/`
  - `**/archive/`
  - `**/tests/`
  - 實驗性語法檔案

- 修改 `writeManifest()` 調用，使用檔案過濾器：
  ```r
  rsconnect::writeManifest(
    appFiles = list.files(
      pattern = "^(?!.*(archive|99_archive|test|temp|cache)).*\\.(R|Rmd|html|css|js|png|jpg|jpeg|gif|yaml|yml|json)$"
    )
  )
  ```

### 3. 缺失套件問題
**問題**：顯示缺少 `gridlayout`, `logger`, `odbc`, `tbl2` 套件

**解決方案**：
- 在部署腳本中設定忽略這些套件（它們不是實際依賴）
- 使用 `suppressWarnings()` 避免不必要的警告

## 📋 部署前檢查清單

1. **確認 .renvignore 存在**
   ```bash
   cat .renvignore
   ```

2. **測試路徑偵測**
   ```r
   source("test_path_detection.R")
   ```

3. **清理舊的 manifest.json**
   ```bash
   rm manifest.json
   ```

4. **執行部署**
   ```r
   source("deploy_now.R")
   # 或
   source("deploy_auto.R")
   ```

## 🎯 最佳實踐

1. **保持 archive 目錄整潔**
   - 定期清理不需要的舊檔案
   - 確保 archive 中的程式碼至少語法正確

2. **使用配置檔案**
   - `app_config.yaml` 包含所有部署設定
   - 可以設定 `main_file` 為任何檔案（如 `full_app_v17.R`）

3. **環境隔離**
   - 使用 `.renvignore` 排除不相關的檔案
   - 只包含實際需要的依賴套件

## 🚀 快速部署

現在部署流程已優化，只需：

```r
# 從任何地方執行
source("/Users/che/Library/CloudStorage/Dropbox/ai_martech/l1_basic/positioning_app/deploy_now.R")
```

腳本會自動：
- 找到正確的專案目錄
- 處理檔案格式問題
- 更新 manifest.json（排除問題檔案）
- 準備部署到 Posit Connect Cloud 