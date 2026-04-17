# Positioning App Subrepo 部署指南

positioning_app 是透過 git-subrepo 管理的獨立 repository。

## 📍 Repository 資訊
- **主倉庫**：`git@github.com:kiki830621/ai_martech.git`
- **Subrepo**：`git@github.com:kiki830621/positioning_app.git`
- **管理方式**：git-subrepo

## 🚀 推送到 positioning_app Repository

### 方法 1：使用 git-subrepo（推薦）
```bash
# 在主倉庫根目錄執行
cd /Users/che/Library/CloudStorage/Dropbox/ai_martech

# 推送 positioning_app 到它自己的 repository
git subrepo push l1_basic/positioning_app
```

### 方法 2：手動推送
如果需要單獨處理 positioning_app：

```bash
# 1. 克隆 positioning_app repository
cd ~/temp
git clone git@github.com:kiki830621/positioning_app.git

# 2. 複製最新檔案
cp -r /Users/che/Library/CloudStorage/Dropbox/ai_martech/l1_basic/positioning_app/* ~/temp/positioning_app/

# 3. 推送變更
cd ~/temp/positioning_app
git add .
git commit -m "Update positioning app"
git push origin main

# 4. 清理
cd ~
rm -rf ~/temp/positioning_app
```

## 📋 部署到 Posit Connect Cloud

1. **確保 positioning_app repository 是最新的**
   ```bash
   cd /Users/che/Library/CloudStorage/Dropbox/ai_martech
   git subrepo push l1_basic/positioning_app
   ```

2. **在 Posit Connect Cloud 選擇**
   - Repository：`kiki830621/positioning_app`
   - Branch：`main`
   - App path：`.`（根目錄）
   - Main file：`app.R`

## ⚠️ 重要注意事項

1. **雙重管理**：positioning_app 同時存在於：
   - 主倉庫中作為 subrepo
   - 獨立的 GitHub repository

2. **同步更新**：修改後需要：
   - 提交到主倉庫
   - 使用 `git subrepo push` 推送到獨立 repository

3. **部署使用獨立 Repository**：
   - Posit Connect Cloud 應該連接到 `kiki830621/positioning_app`
   - 不是主倉庫 `kiki830621/ai_martech`

## 🔄 更新流程

```bash
# 1. 在 positioning_app 目錄做修改
cd /Users/che/Library/CloudStorage/Dropbox/ai_martech/l1_basic/positioning_app
# ... 修改檔案 ...

# 2. 提交到主倉庫
git add .
git commit -m "Update positioning app"
git push origin main

# 3. 推送到 positioning_app repository
cd ../..  # 回到主倉庫根目錄
git subrepo push l1_basic/positioning_app

# 4. 在 Posit Connect Cloud 重新部署
# （透過網頁界面）
```

## 🎯 快速部署檢查清單

- [ ] 所有變更已提交到主倉庫
- [ ] 執行 `git subrepo push l1_basic/positioning_app`
- [ ] positioning_app repository 已更新
- [ ] manifest.json 是最新的
- [ ] 環境變數已在 Posit Connect Cloud 設定
- [ ] 選擇正確的 repository：`kiki830621/positioning_app`
