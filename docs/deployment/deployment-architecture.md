# AI MarTech 部署文件架構

## 文件組織原則

採用集中式架構，利用 global_scripts 的統一部署系統。

### 1. 集中部署系統（global_scripts）

```
global_scripts/
├── 21_rshinyapp_templates/rsconnect/
│   ├── deployment_MAMBA.R
│   └── deployment_WISER.R
└── 11_rshinyapp_utils/
    └── fn_deploy_shiny_app.R     # 核心部署函數
```

### 2. 文檔（docs/deployment/）

通用部署指南、平台設定教學、安全最佳實踐。

### 3. 本地配置（各 app 目錄）

```
your-app/
├── .env              # 實際環境變數（git ignored）
├── .env.example      # 環境變數範本
├── README.md         # 部署說明
└── manifest.json     # 自動生成
```

## 決策矩陣

| 內容類型 | 放置位置 | 原因 |
|---------|---------|------|
| 通用部署流程 | `docs/deployment/` | 避免重複，統一維護 |
| 平台設定教學 | `docs/deployment/` | 所有 app 共用 |
| 部署腳本 | `global_scripts/` | 透過 subrepo 同步 |
| 環境變數範本 | 各 app 目錄 | App 特定需求 |

## 工作流程

1. **新開發者**：先讀 `deployment-guide.md`，再看 app 的 README
2. **部署**：進入 app 目錄 → `cp .env.example .env` → 編輯 → 從專案根目錄執行部署腳本
3. **切換目標**：
   - Posit Connect（預設）：設定 `CONNECT_SERVER`
   - ShinyApps.io：設定 `DEPLOY_TARGET=shinyapps`
