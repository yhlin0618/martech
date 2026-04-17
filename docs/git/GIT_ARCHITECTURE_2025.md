# AI MarTech Git 架構說明（2025年版）

## 📅 更新日期
2025-07-23

## 🎯 架構概覽

本專案經過完整的 Git 架構重新設計，從原本的巢狀 subrepo 結構轉換為**獨立 git repositories 配合 shared subrepo** 的架構。

## 🏗️ 核心設計原則

- **獨立自主**：每個應用都是獨立的 git repository
- **共用程式碼**：透過 `global_scripts` subrepo 共享核心功能
- **分層管理**：L1 Basic、L2 Pro、L3 Enterprise 三層架構
- **統一同步**：所有 subrepos 都指向同一個 commit SHA

## 📊 Repository 結構圖

```
AI MarTech 生態系統
├── 🗂️ 主專案目錄（非 Git）
│   └── Dropbox 同步和備份
│
├── 📦 共享程式庫
│   └── global_scripts/
│       ├── Repository: git@github.com:kiki830621/ai_martech_global_scripts.git
│       ├── 功能: 核心功能、資料庫工具、UI 組件、AI 整合
│       └── 狀態: ✅ 獨立 git repository
│
├── 🏢 L1 Basic 應用層（5個應用）
│   ├── InsightForge/
│   │   ├── Repository: https://github.com/kiki830621/InsightForge.git
│   │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│   │   └── 狀態: ✅ 獨立 git + subrepo
│   │
│   ├── TagPilot/
│   │   ├── Repository: https://github.com/kiki830621/TagPilot.git
│   │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│   │   └── 狀態: ✅ 獨立 git + subrepo
│   │
│   ├── VitalSigns/
│   │   ├── Repository: https://github.com/kiki830621/VitalSigns.git
│   │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│   │   └── 狀態: ✅ 獨立 git + subrepo（已移除 LFS）
│   │
│   ├── BrandEdge/
│   │   ├── Repository: https://github.com/kiki830621/BrandEdge.git
│   │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│   │   └── 狀態: ✅ 獨立 git + subrepo
│   │
│   └── latex_test/
│       ├── Repository: (本地開發，未推送到 GitHub)
│       ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│       └── 狀態: ✅ 本地 git + subrepo
│
├── 🚀 L2 Pro 應用層（2個應用）
│   ├── TagPilot_pro/
│   │   ├── Repository: git@github.com:kiki830621/TagPilot_pro.git
│   │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│   │   └── 狀態: ✅ 獨立 git + subrepo
│   │
│   └── TagPilot_pro___v2/
│       ├── Repository: git@github.com:kiki830621/TagPilot_pro___v2.git
│       ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
│       └── 狀態: ✅ 獨立 git + subrepo (測試改版)
│
└── 🏛️ L3 Enterprise 應用層（2個應用）
    ├── WISER/
    │   ├── Repository: git@github.com:kiki830621/ai_martech_l3_WISER.git
    │   ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
    │   ├── 資料保護: .gitignore 包含 data/database_to_csv/, data/local_data/
    │   └── 狀態: ✅ 獨立 git + subrepo
    │
    └── kitchenMAMA/
        ├── Repository: git@github.com:kiki830621/ai_martech_l3_kitchenMAMA.git
        ├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
        ├── 資料保護: .gitignore 包含 data/database_to_csv/, data/local_data/
        └── 狀態: ✅ 獨立 git + subrepo
```

## 📊 統計數據

- **總計**: 10 個 git repositories (1 共享 + 9 應用)
- **GitHub 已推送**: 9 個 repositories
- **本地開發**: 1 個 repository (latex_test)
- **Subrepo 總數**: 9 個 (每個應用一個)

## 🔄 Git 同步關係

```
ai_martech_global_scripts (GitHub)
    ↓ [Git Subrepo 同步]
    ├── InsightForge/scripts/global_scripts/
    ├── TagPilot/scripts/global_scripts/
    ├── VitalSigns/scripts/global_scripts/
    ├── BrandEdge/scripts/global_scripts/
    ├── latex_test/scripts/global_scripts/
    ├── TagPilot_pro/scripts/global_scripts/
    ├── TagPilot_pro___v2/scripts/global_scripts/
    ├── WISER/scripts/global_scripts/
    └── kitchenMAMA/scripts/global_scripts/
```

## 🛠️ 標準應用結構

每個應用都遵循統一的目錄結構：

```
app_name/
├── .git/                    # 獨立 git repository
├── .gitignore              # 應用專屬忽略規則（包含 *.db）
├── app.R                   # Shiny 應用主檔案
├── app_config.yaml         # 應用配置
├── manifest.json           # 部署清單
├── scripts/
│   └── global_scripts/     # Subrepo (共享程式庫)
└── ...                     # 應用專屬檔案
```

## 🔧 開發工作流程

### 1. 修改共享程式碼
```bash
# 在 global_scripts 目錄中開發
cd global_scripts/
git add .
git commit -m "Add new feature"
git push origin main
```

### 2. 更新應用中的 subrepo
```bash
# 在需要更新的應用目錄中
cd l1_basic/VitalSigns/
git subrepo pull scripts/global_scripts
git add .
git commit -m "Update global_scripts subrepo"
git push origin main
```

### 3. 批量更新所有應用
```bash
# 使用自動化腳本
./bash/subrepo_sync.sh
```

## 📦 Dropbox 同步配置

**重要**：完成 Git 設置後，必須執行以下腳本排除 Git 目錄同步：

```bash
./bash/apply_dropboxignore.sh
```

此腳本功能：
- 自動讀取 `.dropboxignore` 檔案規則
- 對所有 `.git` 目錄套用 macOS Dropbox ignore 屬性
- 避免 Git repositories 與 Dropbox 同步產生衝突
- 保持程式碼檔案正常同步，僅排除版本控制檔案

執行結果：8 個 Git repositories 被排除 Dropbox 同步，確保版本控制系統獨立運作。

## 🛡️ 安全配置

### 資料庫檔案保護
所有應用的 `.gitignore` 都包含：
```
# Database files
*.sqlite
*.duckdb
*.db
```

### 企業級資料保護（L3 應用）
```
# Enterprise data directories - IMPORTANT: Keep these private!
data/database_to_csv/
data/local_data/
```

### 環境變數保護
```
# Environment files
.env
```

## 🚨 已解決的技術問題

### 1. 大檔案問題
- **問題**: TagPilot 中有 600MB+ 的資料庫檔案超過 GitHub 限制
- **解決**: 使用 `git filter-branch` 從歷史中移除大檔案
- **命令**: 
```bash
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch "large_file.db"' --prune-empty --tag-name-filter cat -- --all
git push --force origin main
```

### 2. Git LFS 衝突問題
- **問題**: VitalSigns 引用了不存在的 LFS 物件（404 錯誤）
- **解決**: 完全移除 LFS 依賴並清理歷史
- **步驟**:
```bash
# 1. 移除 LFS 物件引用
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch "lfs_file.csv"' --prune-empty --tag-name-filter cat -- --all

# 2. 清理 LFS 配置
git config --remove-section lfs 2>/dev/null
rm -rf .git/lfs

# 3. 強制推送
git push --force origin main
```

### 3. Repository 重新命名
- **完成**: positioning_app → BrandEdge
- **完成**: WISER → ai_martech_l3_WISER
- **完成**: kitchenMAMA → ai_martech_l3_kitchenMAMA

## 💡 架構優勢

### ✅ 解決的問題
1. **巢狀 subrepo 複雜性**：完全消除巢狀結構
2. **依賴關係混亂**：每個應用都是獨立單位
3. **部署困難**：每個應用可獨立部署
4. **版本衝突**：應用之間互不影響
5. **權限管理**：可為不同應用設定不同存取權限

### ⚡ 獲得的好處
1. **開發效率**：並行開發不會互相干擾
2. **維護簡單**：問題隔離在單一應用內
3. **部署靈活**：支援漸進式部署策略
4. **擴展性強**：新增應用不影響現有架構
5. **團隊協作**：不同團隊可負責不同應用

## 🔮 未來規劃

### 短期目標
- [ ] 完成 latex_test 的 GitHub repository 創建和推送
- [ ] 建立自動化同步腳本，簡化 subrepo 更新流程
- [ ] 建立各應用的獨立 CI/CD pipeline

### 長期願景
- 考慮將 global_scripts 包裝成 R package
- 建立自動化測試框架，確保跨應用相容性
- 實施應用版本標籤策略

## 📚 相關文檔

- [CLAUDE_GIT.md](../../CLAUDE_GIT.md) - 完整的架構狀態報告
- [GIT_SYNC_GUIDE.md](./GIT_SYNC_GUIDE.md) - 同步操作指南
- [SUBMODULE_VS_SUBREPO.md](./SUBMODULE_VS_SUBREPO.md) - 技術選擇說明

## 🔗 快速參考

### 常用命令
```bash
# 檢查所有 subrepo 狀態
git subrepo status --all

# 拉取最新的 global_scripts
git subrepo pull scripts/global_scripts

# 推送 subrepo 變更
git subrepo push scripts/global_scripts

# 應用 Dropbox 忽略規則
./bash/apply_dropboxignore.sh
```

### 緊急恢復
如果遇到 Git 問題，所有備份檔案位於：
```
archive/git_removal_YYYYMMDD_HHMMSS/
├── .git_backup_*           # 完整 Git 備份
├── .git_removed_*          # 移除的 Git 目錄
├── .gitattributes_removed_* # LFS 設定
├── .gitignore_removed_*    # Git 忽略規則
└── .gitmodules_removed_*   # Submodule 設定
```

---

**維護者**: Che  
**最後更新**: 2025-07-23  
**版本**: v2.0 (獨立 repository 架構)