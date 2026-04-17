# Git 與 Dropbox 協作工作流程

## 概述

本專案採用 Dropbox + Git 的混合管理模式，確保資料安全與協作效率。

## 角色定義

### 1. 主要維護者（Git 推送權限）
- **權限**：完整 Dropbox 存取 + Git 推送權限
- **職責**：
  - 審核程式碼變更
  - 執行 git commit/push
  - 管理 submodule/subrepo 更新
  - 確保敏感資料不被上傳

### 2. 協作開發者（Dropbox 同步）
- **權限**：Dropbox 資料夾存取
- **職責**：
  - 在 Dropbox 中開發和測試
  - 提交變更請求給主要維護者
  - 不直接操作 git

## Git 推送前檢查清單

在執行 `git push` 前，主要維護者必須：

- [ ] 確認已獲得 Dropbox 資料夾的完整同步
- [ ] 檢查沒有未解決的 Dropbox 衝突檔案
- [ ] 執行 `git status` 確認變更內容
- [ ] 檢查是否有敏感資料（使用 `git diff --cached`）
- [ ] 確認 app_data 外的資料檔案都已排除
- [ ] 測試應用程式可正常運行

## Dropbox 同步設定

### 排除項目（.dropboxignore）
```
.git          # Git 版本控制目錄
*.tmp         # 暫存檔案
*.log         # 日誌檔案
cache/        # 快取目錄
```

### 為什麼排除 .git？
1. **避免衝突**：多人同時修改會造成 .git 內部檔案衝突
2. **效能考量**：.git 包含大量小檔案，影響同步速度
3. **安全性**：避免 git 歷史意外洩露

## 推薦工作流程

### 對主要維護者
```bash
# 1. 確保 Dropbox 完全同步
# 等待 Dropbox 圖示顯示 ✓

# 2. 檢查狀態
git status
git diff

# 3. 提交變更
git add -A
git commit -m "描述性的提交訊息"

# 4. 更新 submodules（如需要）
git submodule update --remote

# 5. 推送
git push origin main
```

### 對協作開發者
```bash
# 1. 在 Dropbox 中進行開發
# 2. 測試功能正常
# 3. 通知主要維護者進行 git 提交
```

## 緊急情況處理

### Dropbox 衝突
1. 查看衝突檔案（含"衝突的複本"）
2. 手動解決衝突
3. 刪除衝突複本
4. 重新同步

### Git 同步問題
1. 主要維護者執行 `git pull`
2. 解決任何合併衝突
3. 重新測試
4. 推送解決方案

## 安全提醒

⚠️ **絕對不要**：
- 在未完全同步時推送 git
- 讓多人同時操作 git
- 將 .git 目錄加入 Dropbox 同步
- 繞過 .gitignore 規則上傳敏感資料

✅ **務必要**：
- 定期檢查 .gitignore 是否正常運作
- 在推送前仔細檢查變更內容
- 保持良好的提交訊息習慣
- 定期備份重要資料 