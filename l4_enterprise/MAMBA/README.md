# MAMBA Enterprise Platform

L4 Enterprise AI MarTech 應用程式。

## 基本資訊

| 項目 | 值 |
|------|-----|
| **Company** | MAMBA |
| **Tier** | L4 Enterprise |
| **Platforms** | cbz, eby |
| **Database** | Supabase (production) / DuckDB (local dev) |
| **Raw Data** | `./data/local_data/rawdata_MAMBA` |

## Quick Start

```bash
# 設定環境變數
cp .env.template .env
# 編輯 .env 填入實際憑證

# 啟動應用
Rscript app.R
```

## 架構：Symlink + 雙 Git Repo

本專案採用 symlink 架構，`scripts/` 下的共用模組指向 `shared/` 的 canonical copy：

```
MAMBA/                                  ← 開發 repo (private)
├── app.R
├── app_config.yaml
├── Makefile
├── scripts/
│   ├── global_scripts -> ../../shared/global_scripts
│   ├── nsql -> ../../shared/nsql
│   └── update_scripts -> ../../shared/update_scripts
└── deployment/
    └── mamba-enterprise/               ← 部署 repo (public)
        ├── app.R
        ├── scripts/global_scripts/     ← 真實檔案（rsync 過來）
        └── manifest.json
```

### 為什麼需要兩個 repo？

- **開發 repo** (`ai_martech_l4_MAMBA`)：使用 symlink 共用 `shared/` 程式碼，避免重複
- **部署 repo** (`ai_martech_l4_MAMBA_deploy`)：Posit Connect Cloud 從 GitHub clone 時無法解析 symlink，所以需要包含真實檔案的獨立 repo（可為 private）

### 資料流

```
開發 repo  ──make deploy-sync──▶  部署 repo  ──git push──▶  Posit Connect
(symlinks)      (rsync -avL)      (真實檔案)    (webhook)     (自動部署)
```

## 部署

### 日常部署

```bash
# 1. 同步開發 → 部署（rsync -avL 解析 symlinks）
make deploy-sync

# 2. 檢查差異
make deploy-diff

# 3. Commit + Push → 自動觸發 Posit Connect 部署
make deploy-push
```

### 所有 Makefile 命令

```bash
make help              # 查看所有可用命令
make deploy-sync       # 同步開發 → 部署
make deploy-push       # commit + push 到 GitHub
make deploy-diff       # 查看部署目錄的變更
make deploy-status     # 查看部署目錄 git 狀態
make deploy-manifest   # 重新產生 manifest.json
make deploy-init       # 首次初始化（已完成）
```

## ETL Pipeline

ETL/DRV 腳本位於 `scripts/update_scripts/`：

```bash
cd scripts/update_scripts
make run PLATFORM=cbz      # 執行 Cyberbiz 平台
make run PLATFORM=eby      # 執行 eBay 平台
make status                # 檢查 pipeline 狀態
```

## 配置檔案

| 檔案 | 用途 |
|------|------|
| `app_config.yaml` | 應用配置（平台、資料庫、部署設定） |
| `.env` | 環境變數（API keys、DB credentials，不提交） |
| `.Rprofile` | R session 初始化（載入 autoinit） |
| `manifest.json` | Posit Connect 套件清單 |

## GitHub Repos

| Repo | 可見性 | 用途 |
|------|--------|------|
| `kiki830621/ai_martech_l4_MAMBA` | Private | 開發版本控制 |
| `kiki830621/ai_martech_l4_MAMBA_deploy` | Private | Posit Connect 部署來源 |
