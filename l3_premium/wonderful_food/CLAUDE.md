# CLAUDE.md - Wonderful Food 開發與部署指引

此文件為 Claude Code 在 Wonderful Food 專案中操作的標準作業程序。

## Git Repositories

| 用途 | GitHub Repo | 說明 |
|------|-------------|------|
| 開發主線 | [kiki830621/wonderful_food_dev](https://github.com/kiki830621/wonderful_food_dev) | 所有程式碼編輯在這裡進行 |
| BrandEdge 部署 | [kiki830621/wonderful_food_BrandEdge_premium](https://github.com/kiki830621/wonderful_food_BrandEdge_premium) | Git-backed → Posit Connect |
| InsightForge 部署 | [kiki830621/wonderful_food_InsightForge_premium](https://github.com/kiki830621/wonderful_food_InsightForge_premium) | Git-backed → Posit Connect |
| TagPilot 部署 | [kiki830621/wonderful_food_TagPilot_premium](https://github.com/kiki830621/wonderful_food_TagPilot_premium) | Git-backed → Posit Connect |

## 部署網址

| App | Posit Connect URL |
|-----|-------------------|
| BrandEdge | https://kyleyhl-wonderful-food-brandedge-premium.share.connect.posit.cloud/ |
| InsightForge | https://kyleyhl-wonderful-food-insightforge-premium.share.connect.posit.cloud/ |
| TagPilot | https://kyleyhl-wonderful-food-tagpilot-premium.share.connect.posit.cloud |

## 環境概覽

```
wonderful_food/
├── CLAUDE.md                              # 本文件
├── Makefile                               # 同步腳本
├── wonderful_food_dev/                    # 開發環境 - 所有開發在這裡進行
│   ├── app_brandedge.R                    # BrandEdge 開發版
│   ├── app_insightforge.R                 # InsightForge 開發版
│   ├── app_tagpilot.R                     # TagPilot 開發版
│   ├── modules/
│   │   ├── shared/                        # 共用模組
│   │   ├── brandedge/                     # BrandEdge 專用
│   │   ├── insightforge/                  # InsightForge 專用
│   │   └── tagpilot/                      # TagPilot 專用
│   ├── utils/
│   │   ├── shared/                        # 共用工具
│   │   ├── brandedge/                     # BrandEdge 專用
│   │   └── tagpilot/                      # TagPilot 專用
│   ├── config/{brandedge,insightforge,tagpilot}/
│   ├── database/
│   ├── www/
│   └── md/
│
├── wonderful_food_BrandEdge_premium/      # 部署環境 (獨立 Git repo)
├── wonderful_food_InsightForge_premium/   # 部署環境 (獨立 Git repo)
└── wonderful_food_TagPilot_premium/       # 部署環境 (獨立 Git repo)
```

## 架構設計理由

### 為什麼需要 3 個獨立的 Git Repo？

**Posit Connect Cloud 的限制**：部署時只能連接一個 Git repository，無法指定 monorepo 中的子目錄。

因此架構設計為：

| Repository | 用途 |
|------------|------|
| `wonderful_food_dev/` | 開發主線，集中管理所有程式碼（階層式目錄） |
| `wonderful_food_BrandEdge_premium` | BrandEdge 部署專用（扁平化目錄） |
| `wonderful_food_InsightForge_premium` | InsightForge 部署專用（扁平化目錄） |
| `wonderful_food_TagPilot_premium` | TagPilot 部署專用（扁平化目錄） |

這是「**開發集中、部署分散**」的務實架構，用 Makefile 同步來彌補兩者的差距。

### 路徑轉換機制

開發環境使用階層式目錄結構，部署環境使用扁平結構：

```
開發環境 (wonderful_food_dev/)          部署環境 (deployment repos)
─────────────────────────────          ────────────────────────────
modules/shared/module_dna.R      →     modules/module_dna.R
modules/brandedge/module_login.R →     modules/module_login.R
utils/shared/data_access.R       →     utils/data_access.R
config/brandedge/config.R        →     config/config.R
```

Makefile 使用 `sed` 轉換路徑 + `rsync` 扁平化目錄。

## 關鍵規則

### 1. 開發地點
- **所有程式碼編輯** 都在 `wonderful_food_dev/` 進行
- **絕對不要** 直接編輯 deployment repos 下的檔案

### 2. 同步流程
開發完成後，使用 Makefile 同步：
```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l3_premium/wonderful_food
make sync-all        # 同步所有 app
make brandedge       # 只同步 BrandEdge
make insightforge    # 只同步 InsightForge
make tagpilot        # 只同步 TagPilot
```

### 3. 推送流程
同步後，到各 deployment repo 推送：
```bash
cd wonderful_food_BrandEdge_premium
git add -A
git commit -m "Update: 說明變更"
git push
```

## 常用命令快速參考

### 同步命令
```bash
# 工作目錄：wonderful_food/
make sync-all         # 同步所有
make brandedge        # 同步 BrandEdge
make insightforge     # 同步 InsightForge
make tagpilot         # 同步 TagPilot
make status           # 檢查所有 repo 狀態
make clean            # 清理暫存檔
```

### 檢查狀態
```bash
# 檢查各 deployment repo 的狀態
cd wonderful_food_BrandEdge_premium && git status
cd wonderful_food_InsightForge_premium && git status
cd wonderful_food_TagPilot_premium && git status
```

## App 對應關係

| 開發檔案 (wonderful_food_dev) | 部署檔案 (deployment) | GitHub Repo |
|-------------------------------|----------------------|-------------|
| `app_brandedge.R` | `wonderful_food_BrandEdge_premium/app.R` | wonderful_food_BrandEdge_premium |
| `app_insightforge.R` | `wonderful_food_InsightForge_premium/app.R` | wonderful_food_InsightForge_premium |
| `app_tagpilot.R` | `wonderful_food_TagPilot_premium/app.R` | wonderful_food_TagPilot_premium |

## 模組分類

### 共用模組 (modules/shared/)
| 檔案 | 說明 | 使用者 |
|------|------|--------|
| `module_dna.R` | DNA 分析模組 | BrandEdge + TagPilot |
| `module_wo_b.R` | 主要分析模組（基礎版） | InsightForge + TagPilot |

> **⚠️ 重要說明：`module_wo_b.R` 的特殊處理**
>
> BrandEdge 版本的 `module_wo_b.R` 包含專用函數（如 `keyFactorsModuleUI`），
> 與 shared 版本不同，因此 BrandEdge 使用專用版本而非 shared 版本。
>
> | App | 使用的 module_wo_b.R |
> |-----|---------------------|
> | BrandEdge | `modules/brandedge/module_wo_b.R` (590 行，含 keyFactorsModuleUI) |
> | InsightForge | `modules/shared/module_wo_b.R` (440 行) |
> | TagPilot | `modules/shared/module_wo_b.R` (440 行) |

### BrandEdge 專用模組 (modules/brandedge/)
- `module_wo_b.R` - **主要分析模組（BrandEdge 專用版，含 keyFactorsModuleUI）**
- `module_brandedge_flagship.R` - 旗艦版核心
- `module_brandedge_flagship_with_prompt_manager.R` - 含 Prompt 管理
- `module_market_profile_enhanced.R` - 市場檔案增強
- `module_login.R`, `module_upload.R`, `module_upload_complete_score.R`, `module_dna_multi.R`

### InsightForge 專用模組 (modules/insightforge/)
- `module_wo_b_v2.R` - OpenAI v2
- `module_score_v2.R` - 評分 v2
- `module_keyword_ads.R` - 關鍵字廣告
- `module_product_dev.R` - 產品開發
- `module_login.R`, `module_upload.R`, `module_upload_complete_score.R`, `module_score.R`

### TagPilot 專用模組 (modules/tagpilot/)
- `module_dna_multi_premium.R` - DNA 多變數 Premium
- `module_dna_multi_premium2.R` - DNA 多變數 Premium v2
- `module_dna_multi_pro2.R` - DNA 多變數 Pro v2
- `module_dna_multi_VS.R` - DNA 多變數 VS
- `module_login.R`, `module_upload.R`, `module_dna_multi.R`, `module_score.R`

## 工具分類

### 共用工具 (utils/shared/)
| 檔案 | 說明 |
|------|------|
| `data_access.R` | 資料存取工具（整合 tbl2） |
| `hint_system.R` | 提示系統 |
| `prompt_manager.R` | Prompt 管理器 |
| `openai_utils.R` | OpenAI API 工具 |

### 專用工具
- `utils/brandedge/` - BrandEdge 專用版本
- `utils/tagpilot/` - TagPilot 專用版本

## 同步內容清單

每次 `make sync-*` 會同步：
- `app_*.R` → `app.R` (重命名 + 路徑轉換)
- `modules/shared/` + `modules/{app}/` → `modules/` (扁平化)
- `utils/shared/` + `utils/{app}/` → `utils/` (扁平化)
- `config/{app}/` → `config/`
- `database/` (完整複製)
- `www/` (完整複製)
- `md/` (完整複製)

## 典型工作流程

### 場景 1：修改 BrandEdge 功能
```bash
# 1. 在 wonderful_food_dev 修改
cd wonderful_food_dev
# 編輯 app_brandedge.R, modules/brandedge/*.R 等

# 2. 同步到 deployment
cd ..
make brandedge

# 3. 推送到 GitHub（自動觸發 Posit Connect 部署）
cd wonderful_food_BrandEdge_premium
git add -A
git commit -m "feat: 新增某功能"
git push
```

### 場景 2：修改共用模組（影響所有 app）
```bash
# 1. 在 wonderful_food_dev 修改
cd wonderful_food_dev
# 編輯 modules/shared/*.R 或 utils/shared/*.R

# 2. 同步所有 app
cd ..
make sync-all

# 3. 推送所有 deployment
cd wonderful_food_BrandEdge_premium && git add -A && git commit -m "Update shared modules" && git push
cd ../wonderful_food_InsightForge_premium && git add -A && git commit -m "Update shared modules" && git push
cd ../wonderful_food_TagPilot_premium && git add -A && git commit -m "Update shared modules" && git push
```

## Posit Connect 部署資訊

### Git-backed Deployment 機制

Posit Connect Cloud 設定為 **Git-backed deployment**：

```
GitHub Repository                    Posit Connect Cloud
─────────────────                    ───────────────────
wonderful_food_BrandEdge_premium    ───→  BrandEdge App
wonderful_food_InsightForge_premium ───→  InsightForge App
wonderful_food_TagPilot_premium     ───→  TagPilot App

監聽：main branch
觸發：每次 git push 後自動重新部署
延遲：約 1-3 分鐘
```

### 環境變數設定

在 Posit Connect 的 **Variable Set** 中設定：
```
PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, PGSSLMODE
OPENAI_API_KEY
```

## 注意事項

1. **rsync 扁平化** - 同步會將 shared/ 和 {app}/ 合併到單一目錄
2. **路徑轉換** - sed 會自動處理 source() 路徑
3. **不要在 deployment 直接編輯** - 所有變更都會在下次同步時被覆蓋
4. **環境變數** - 在 Posit Connect 的 Variable Set 設定，不是在本地
5. **Git-backed deployment** - 推送到 GitHub 即自動部署

---

最後更新：2025-01-18
