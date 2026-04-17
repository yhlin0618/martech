# AI MarTech 專案 Git 架構狀態報告

## 報告時間
2025-09-25 10:30

## 架構概覽

本專案經過完整的 Git 架構重新設計，從原本的巢狀 subrepo 結構轉換為獨立 git repositories 配合 shared subrepo 的架構。

## Git 架構設計

### 🏗️ 核心設計原則
- **獨立自主**：每個應用都是獨立的 git repository
- **共用程式碼**：透過 `global_scripts` subrepo 共享核心功能
- **分層管理**：L1 Basic、L2 Pro、L4 Enterprise 三層架構
- **統一同步**：所有 subrepos 都指向同一個 commit SHA (463c31676f...)

### 📁 Repository 結構

#### 1. 共享程式庫 (Shared Library)
```
global_scripts/
├── Repository: git@github.com:kiki830621/ai_martech_global_scripts.git
├── 功能: 核心功能、資料庫工具、UI 組件、AI 整合
└── 狀態: ✅ 獨立 git repository
```

#### 2. L1 Basic 應用層 (5 個應用)
> **注意**: L1 Basic 層的 repositories 目前使用 HTTPS 格式，建議統一改為 SSH 格式 (git@github.com:)
```
l1_basic/InsightForge/
├── Repository: https://github.com/kiki830621/InsightForge.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo

l1_basic/TagPilot/
├── Repository: https://github.com/kiki830621/TagPilot.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo

l1_basic/VitalSigns/
├── Repository: https://github.com/kiki830621/VitalSigns.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo

l1_basic/BrandEdge/
├── Repository: https://github.com/kiki830621/BrandEdge.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo

l1_basic/latex_test/
├── Repository: https://github.com/kiki830621/latex_test.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo
```

#### 3. L2 Pro 應用層 (2 個應用)
```
l2_pro/TagPilot_pro/
├── Repository: git@github.com:kiki830621/TagPilot_pro.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo

l2_pro/TagPilot_pro___v2/
├── Repository: git@github.com:kiki830621/TagPilot_pro___v2.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
└── 狀態: ✅ 獨立 git + subrepo (測試改版)
```

#### 4. L3 Premium 應用層 (8 個應用)

**已有 GitHub Repository:**
```
l3_premium/TagPilot_premium/
├── Repository: https://github.com/kiki830621/TagPilot_premium.git
└── 狀態: ✅ 獨立 git repository

l3_premium/VitalSigns_premium/
├── Repository: https://github.com/kiki830621/VitalSigns_premium.git
└── 狀態: ✅ 獨立 git repository

l3_premium/InsightForge_premium/
├── Repository: (本地 Git，尚未推送)
└── 狀態: ⚠️ 需要設定 GitHub remote
```

**Wonderful Food 專案 (3 個獨立 repositories):**
```
l3_premium/wonderful_food/wonderful_food_BrandEdge_premium/
├── Repository: https://github.com/kiki830621/wonderful_food_BrandEdge_premium.git
├── 狀態: ✅ 獨立 git repository
└── 建立時間: 2025-09-11

l3_premium/wonderful_food/wonderful_food_InsightForge_premium/
├── Repository: https://github.com/kiki830621/wonderful_food_InsightForge_premium.git
├── 狀態: ✅ 獨立 git repository
└── 建立時間: 2025-09-11

l3_premium/wonderful_food/wonderful_food_TagPilot_premium/
├── Repository: https://github.com/kiki830621/wonderful_food_TagPilot_premium.git
├── 狀態: ✅ 獨立 git repository
└── 建立時間: 2025-09-11
```

**開發測試專案:**
```
l3_premium/sandbox/
├── Repository: https://github.com/kiki830621/ai_martech_sandbox.git
├── 基於: InsightForge_premium 複製
├── 狀態: ✅ 私人 git repository (已推送)
├── 用途: 開發測試環境
└── 建立時間: 2025-09-25
```

**尚未設定 Git:**
```
l3_premium/BrandEdge_premium/
└── 狀態: ❌ 無 Git repository
```

#### 5. L4 Enterprise 應用層 (2 個應用)
```
l4_enterprise/WISER/
├── Repository: git@github.com:kiki830621/ai_martech_l4_WISER.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
├── 資料保護: .gitignore 包含 data/database_to_csv/, data/local_data/
└── 狀態: ✅ 獨立 git + subrepo

l4_enterprise/kitchenMAMA/
├── Repository: git@github.com:kiki830621/ai_martech_l4_kitchenMAMA.git
├── Subrepo: scripts/global_scripts/ → ai_martech_global_scripts
├── 資料保護: .gitignore 包含 data/database_to_csv/, data/local_data/
└── 狀態: ✅ 獨立 git + subrepo
```

## 技術實作詳情

### 🔄 Subrepo 同步狀態
所有應用的 subrepo 都指向相同的 commit SHA: `463c31676f60e2d7a86f59f7e8f631c8f3ba59ae`

### 🛡️ 安全配置
- **WISER 企業級保護**：敏感資料目錄已從 git 追蹤中排除
- **環境變數保護**：所有 `.env` 檔案都在 `.gitignore` 中
- **資料庫檔案**：所有 `.sqlite`, `.db`, `.duckdb` 檔案都被忽略

### 📊 Repository 統計
- **總計**: 18 個 git repositories (1 共享 + 17 應用)
- **GitHub 已推送**: 16 個 repositories
- **本地 Git 未推送**: 1 個 (InsightForge_premium)
- **無 Git**: 1 個 (BrandEdge_premium)
- **SSH 格式**: 5 個 repositories (global_scripts, L2 Pro, L4 Enterprise)
- **HTTPS 格式**: 11 個 repositories (L1 Basic 層 + L3 Premium 層)
- **Subrepo 總數**: 9 個 (L1 Basic + L2 Pro + L4 Enterprise)

## 開發工作流程

### 🔨 同步流程
1. **修改 global_scripts**：推送到 ai_martech_global_scripts repository
2. **更新應用 subrepo**：在各應用中執行 `git subrepo pull scripts/global_scripts`
3. **提交應用變更**：提交各應用的 subrepo 更新

### 🚀 部署流程

**部署方式：GitHub 整合自動部署**

每個應用都可以獨立部署到 Posit Connect Cloud，無需擔心依賴關係衝突。

#### 日常部署步驟
1. **提交變更**：`git add -A && git commit -m "描述"`
2. **推送到 GitHub**：`git push origin main`
3. **Posit Connect Cloud 自動拉取並部署**

#### 首次設定（在 Posit Connect Cloud 網站）
1. 登入 https://connect.posit.cloud
2. 點擊「Publish」→「Import from Git」
3. 連結 GitHub 帳號（如尚未連結）
4. 選擇 GitHub repo（如 `kiki830621/wonderful_food_InsightForge_premium`）
5. 選擇 branch：`main`
6. 設定環境變數（Variables）：
   - `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGSSLMODE`
   - `OPENAI_API_KEY`
7. 點擊 Deploy

#### 部署後管理
- **URL 格式**：`https://connect.posit.cloud/kyle-lin/content/[content-id]`
- **Vanity URL**：可在 Settings 中設定自訂路徑
- **重新部署**：推送到 GitHub 後，在 Connect 頁面點擊「Refresh」或設定自動更新

### 📦 Dropbox 同步配置
**重要**：完成 Git 設置後，必須執行以下腳本排除 Git 目錄同步：

```bash
./bash/apply_dropboxignore.sh
```

此腳本功能：
- 自動讀取 `.dropboxignore` 檔案規則
- 對所有 `.git` 目錄套用 macOS Dropbox ignore 屬性 (`com.apple.fileprovider.ignore#P`)
- 避免 Git repositories 與 Dropbox 同步產生衝突
- 保持程式碼檔案正常同步，僅排除版本控制檔案

執行結果：10 個 Git repositories 被排除 Dropbox 同步，確保版本控制系統獨立運作。

### 📝 檔案組織規範
```
每個應用的標準結構:
app_name/
├── .git/                    # 獨立 git repository
├── .gitignore              # 應用專屬忽略規則
├── app.R                   # Shiny 應用主檔案
├── app_config.yaml         # 應用配置
├── manifest.json           # 部署清單
├── scripts/
│   └── global_scripts/     # Subrepo (共享程式庫)
└── ...                     # 應用專屬檔案
```

## 架構優勢

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

## 未來規劃

### 🎯 短期目標
- [ ] 完成 latex_test 的 GitHub repository 創建和推送
- [ ] 建立自動化同步腳本，簡化 subrepo 更新流程
- [ ] 建立各應用的獨立 CI/CD pipeline

### 🔮 長期願景
- 考慮將 global_scripts 包裝成 R package
- 建立自動化測試框架，確保跨應用相容性
- 實施應用版本標籤策略

## 結論

✅ **Git 架構重新設計完全成功**

本次架構重新設計徹底解決了原本巢狀 subrepo 的複雜性問題，建立了一個清晰、可維護、可擴展的多應用開發環境。每個應用現在都是獨立的 git repository，透過統一的 global_scripts subrepo 共享核心功能，實現了代碼重用與應用獨立性的完美平衡。

## 新增專案說明

### 🍽️ Wonderful Food 專案
**時間**: 2025-09-11  
**位置**: `l3_premium/wonderful_food/`  
**架構**: 三個獨立 Git repositories（原計劃的共用架構已改為獨立）

此專案為美好食品（Wonderful Food）客製化的精準行銷解決方案，包含三個核心應用：
- **wonderful_food_BrandEdge_premium**: 品牌定位與市場分析
- **wonderful_food_InsightForge_premium**: 客戶洞察與數據分析  
- **wonderful_food_TagPilot_premium**: 客戶DNA分析與分群

每個應用都有獨立的 Git repository 和 GitHub 專案，便於獨立開發和部署。每個應用都有自己的 `scripts/global_scripts` 符號連結，指向主專案的 global_scripts。

### 📝 待處理項目
- **InsightForge_premium**: 需要建立 GitHub repository 並推送
- **BrandEdge_premium**: 需要初始化 Git 並建立 GitHub repository
- **wonderful_food_apps**: GitHub repository 需要手動刪除（需要 delete_repo 權限）

### 🆕 最新變更 (2025-09-25)

- **新增 sandbox 專案**: 在 L3 Premium 層建立開發測試環境
  - 基於 InsightForge_premium 複製
  - 已建立私人 GitHub repository: https://github.com/kiki830621/ai_martech_sandbox
  - 包含完整應用結構，用於實驗和創新開發
  - global_scripts 目前為本地複製（待網路穩定後可設定為 subrepo）
  - 狀態: ✅ 已推送至 GitHub

---
**維護者**: Che
**最後更新**: 2025-12-22
**版本**: v2.3 (補充完整部署流程說明)
