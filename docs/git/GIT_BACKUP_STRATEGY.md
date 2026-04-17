# Git 備份策略

## 問題：.git 排除 vs 包含的權衡

### 排除 .git 的優缺點
**優點**：
- ✅ 避免多人同時操作造成 .git 內部檔案衝突
- ✅ Dropbox 同步更快（.git 包含大量小檔案）
- ✅ 避免 git 歷史意外洩露

**缺點**：
- ❌ 電腦損壞時會失去本地 git 歷史
- ❌ 無法在多台電腦間同步開發進度

### 包含 .git 的優缺點
**優點**：
- ✅ 電腦損壞時仍保留完整 git 歷史
- ✅ 可在多台電腦間無縫切換開發

**缺點**：
- ❌ 多人同時 git 操作會產生嚴重衝突
- ❌ Dropbox 同步變慢
- ❌ .git/objects 衝突難以解決

## 建議方案

### 方案一：GitHub 為主要備份（推薦）
```bash
# 經常推送到 GitHub
git push origin main

# 設定多個遠端倉庫作為備份
git remote add backup git@github.com:your-backup-repo.git
git push backup main
```

**優點**：
- Git 的標準做法
- 不依賴 Dropbox
- 支援協作

### 方案二：選擇性同步 .git（折衷方案）
只在主要維護者的電腦上同步 .git：

```bash
# 其他協作者執行
dropbox exclude add .git

# 主要維護者不排除（保留備份）
# 但要確保只有一個人進行 git 操作
```

### 方案三：定期備份 .git
創建備份腳本 `backup_git.sh`：

```bash
#!/bin/bash
# 定期備份 .git 到安全位置
BACKUP_DIR="$HOME/Backups/git_backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/ai_martech_git_backup.tar.gz" .git
echo "Git 備份完成：$BACKUP_DIR"
```

### 方案四：使用 git bundle（離線備份）
```bash
# 創建完整的 git bundle
git bundle create ai_martech_backup.bundle --all

# 儲存到 Dropbox 或其他雲端
cp ai_martech_backup.bundle ~/Dropbox/git_backups/

# 還原時
git clone ai_martech_backup.bundle restored_repo
```

## 實務建議

### 如果你是唯一開發者
- **可以考慮不排除 .git**
- 享受 Dropbox 自動備份的便利
- 注意不要在多台電腦同時進行 git 操作

### 如果有團隊協作
1. **維持排除 .git**
2. **頻繁推送到 GitHub**
3. **設定自動備份**：
   ```bash
   # 加入 crontab（每天備份）
   0 2 * * * /path/to/backup_git.sh
   ```

## 緊急恢復程序

如果電腦損壞：

1. **從 GitHub 恢復**
   ```bash
   git clone git@github.com:your-username/ai_martech.git
   ```

2. **恢復 Submodules**
   ```bash
   git submodule update --init --recursive
   ```

3. **恢復 Subrepos**
   ```bash
   git subrepo pull l1_basic/positioning_app
   ```

## 最終建議

考慮你的情況，我建議：
1. **短期**：如果你是唯一維護者，可以不排除 .git
2. **長期**：養成頻繁推送 GitHub 的習慣
3. **備份**：定期執行 git bundle 備份 