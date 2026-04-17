# 執行 Pipeline 時

**使用時機**: 執行 ETL/DRV 腳本時

---

## Pipeline Orchestration (ETL + DRV)

使用 {targets} R package 進行 ETL 和 DRV 腳本編排，實現宣告式依賴管理。

---

## 目錄結構

```
update_scripts/
├── _targets.R               # 主編排
├── _targets_config.yaml     # 生成的配置（git-ignored）
├── Makefile                 # 所有命令
├── ETL/
│   ├── _targets_etl.R       # ETL 層定義
│   └── {platform}/          # 各平台 ETL 腳本
├── DRV/
│   ├── _targets_drv.R       # DRV 層定義
│   └── {platform}/          # 各平台 DRV 腳本
└── scheduling/              # launchd 模板（macOS）
```

---

## 三層配置架構 (SO_P016)

```
Layer 1 (Universal):  global_scripts/templates/_targets_config.base.yaml
                      └─ Schema only, 透過 shared/ 共用
                                   │
                                   ▼ (modifyList merge)
Layer 2 (Company):    app_config.yaml > pipeline: section
                      └─ 公司專屬啟用平台
                                   │
                                   ▼ (make config-merge)
Layer 3 (Generated):  {project_root}/_targets_config.yaml
                      └─ 最終合併配置，用於執行
```

---

## 常用命令

### 配置管理
```bash
cd scripts/update_scripts

make config-merge      # 合併 base + company → generated config
make config-scan       # 掃描 ETL/DRV 目錄的腳本
make config-full       # config-merge + scan + validate
make config-validate   # 驗證配置完整性
```

### 執行
```bash
make run TARGET=cbz_D04_02   # 執行特定目標含依賴
make run PLATFORM=cbz        # 執行平台所有目標
make run                     # 執行所有啟用平台
make dry-run TARGET=cbz_D04_02  # 顯示將執行什麼（不實際執行）
```

### 狀態與可視化
```bash
make status            # 檢查 pipeline 進度
make vis               # 可視化完整 DAG
make vis TARGET=cbz_D04_02   # 可視化特定目標子圖
```

### 排程（macOS launchd）
```bash
make schedule          # 設定每週自動執行（週日 2:00 AM）
make schedule-status   # 檢查排程狀態
make unschedule        # 停用自動執行
make schedule-logs     # 查看排程日誌
```

---

## 依賴標記 (MP140)

每個 DRV 腳本**必須**在檔案開頭宣告依賴：

```r
#####
# CONSUMES: df_cbz_sales_transformed
# PRODUCES: df_cbz_poisson_analysis_all
# DEPENDS_ON_ETL: cbz_ETL_sales_2TR
# DEPENDS_ON_DRV: cbz_D04_01
#####
```

| 標記 | 意義 |
|------|------|
| `CONSUMES` | 讀取的表格名稱 |
| `PRODUCES` | 產出的表格名稱 |
| `DEPENDS_ON_ETL` | 依賴的 ETL 腳本 |
| `DEPENDS_ON_DRV` | 依賴的 DRV 腳本 |

---

## 執行模式

### 重要：必須使用 Makefile 執行 DRV 腳本

**禁止**在 APP_MODE 下直接用 `Rscript` 執行 DRV 腳本。

| 初始化模式 | `db_path_list` 包含 | 適用場景 |
|-----------|---------------------|----------|
| APP_MODE (`autoinit()`) | 僅 `app_data` | 啟動 Shiny App |
| UPDATE_MODE (Makefile) | 全部 6 層（raw/staged/transformed/processed/cleansed/app_data） | ETL/DRV pipeline |

DRV 腳本需要讀寫多個資料庫（如 `processed_data` → `cleansed_data` → `app_data`），**只有** UPDATE_MODE 會正確設定所有路徑。直接在 APP_MODE 下跑會因 `db_path_list$cleansed_data` 為 NULL 而失敗。

### 手動執行
```bash
cd scripts/update_scripts
make run TARGET=cbz_D04_02
```

### 排程執行（週日凌晨）
```bash
make schedule
```

### 完整 pipeline 重建
```bash
make run  # 執行所有啟用平台的完整 pipeline
```

---

## Troubleshooting

### 常見問題

| 問題 | 原因 | 解決方案 |
|------|------|----------|
| "No targets to run" | 配置未生成 | `make config-full` |
| "Config file not found" | 缺少 `_targets_config.yaml` | `make config-merge` |
| "Target not found" | 目標名稱無效 | 用 `make status` 確認有效名稱 |
| "Permission denied" | 檔案權限問題 | 檢查 data 目錄的讀寫權限 |
| "Database locked" | 並發存取 | 關閉其他 R session 或 DuckDB 連線 |

### 除錯步驟

```bash
# 1. 檢查配置
make config-validate

# 2. 查看目前狀態
make status

# 3. 可視化依賴圖
make vis

# 4. 查看日誌
make logs
tail -f logs/run_*.log

# 5. 清除重建
make clean && make config-full && make run
```

---

## 相關原則

- **DM_R042**: Makefile Command Reference - 完整命令參考
- **MP140**: Pipeline Orchestration - 宣告式依賴，按需執行
- **MP141**: Scheduled Execution Pattern - 手動 + 排程模式
- **MP142**: Configuration-Driven Pipeline - 三層 YAML 配置
- **SO_P016**: Configuration Scope Hierarchy - Universal/Company/Application
- **MP122**: Quad-Track Shared Symlink Architecture
- **MP064**: ETL-Derivation separation
- **DM_R041**: Directory structure (platform subdirectories)

---

## 詳細參考

完整的命令說明請參考：
`docs/en/part1_principles/CH02_data_management/rules/DM_R042_makefile_command_reference.qmd`
