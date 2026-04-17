# 應用程式結構標準

## 概述
本文件定義了 AI MarTech 專案中應用程式的標準目錄結構和組織規範。

## 適用範圍

### L1 Basic（基礎版）
本標準**強制適用於** `l1_basic/` 目錄下的所有應用程式。

### L2 Pro 和 L3 Enterprise
- L2 Pro（專業版）和 L3 Enterprise（企業版）可能採用不同的架構模式
- 這些層級的結構標準將在未來根據其特定需求另行定義
- 可能採用微服務、容器化或其他企業級架構

## 必要目錄結構（L1 Basic）

L1 Basic 層級的每個應用程式必須遵循以下標準結構：

```
app_name/
├── app.R                    # 主應用程式檔案
├── README.md               # 應用程式說明文件
├── scripts/
│   └── global_scripts/     # global_scripts 的 git submodule
├── config/                 # 配置檔案
├── modules/                # 應用程式特定模組
├── database/               # 資料庫檔案（如果需要）
├── test_data/              # 測試資料
├── tests/                  # 測試腳本
├── www/                    # 網頁資源（CSS、JS、圖片等）
├── deploy.R                # 部署腳本
└── .gitignore             # Git 忽略規則
```

## Global Scripts 整合規則（L1 Basic）

### 1. 強制要求
L1 Basic 層級的每個應用程式**必須**在 `scripts/global_scripts/` 包含 global_scripts repository。

### 2. 整合方式
- **推薦**：使用 git submodule（適用於需要追蹤特定版本的情況）
- **替代**：直接複製（適用於需要修改 global_scripts 的情況）

### 3. 設置步驟

#### 使用 Git Submodule：
```bash
cd app_name
mkdir -p scripts
cd scripts
git submodule add git@github.com:kiki830621/precision_marketing_global_scripts.git global_scripts
git submodule update --init --recursive
```

#### 直接複製：
```bash
cd app_name
mkdir -p scripts
cp -r /path/to/global_scripts scripts/
```

### 4. 路徑引用
在應用程式中引用 global_scripts：
```r
# 標準路徑引用
source("scripts/global_scripts/22_initializations/sc_initialization_app_mode.R")

# 使用相對路徑
global_scripts_path <- file.path("scripts", "global_scripts")
```

## 配置管理

### 1. 環境檢測
應用程式應能自動檢測運行環境：
```r
# 檢查是否在應用程式模式
if (file.exists("scripts/global_scripts")) {
  # 應用程式模式
  source("scripts/global_scripts/...")
} else if (file.exists("../global_scripts")) {
  # 開發模式
  source("../global_scripts/...")
}
```

### 2. 路徑配置
使用配置檔案管理路徑：
```r
# config/paths.R
GLOBAL_SCRIPTS_PATH <- if (file.exists("scripts/global_scripts")) {
  "scripts/global_scripts"
} else {
  "../global_scripts"
}
```

## 例外情況

如果應用程式因特殊原因無法遵循此標準，必須：
1. 在應用程式的 README.md 中說明原因
2. 提供替代的 global_scripts 訪問方式
3. 確保功能不受影響

## 驗證檢查

開發者應定期執行以下檢查：
```bash
# 檢查所有 l1_basic 應用程式
for app in l1_basic/*/; do
  echo "Checking $app"
  if [ -d "$app/scripts/global_scripts" ]; then
    echo "✓ global_scripts found"
  else
    echo "✗ global_scripts missing"
  fi
done
```

## 更新日期
2024-12-27 