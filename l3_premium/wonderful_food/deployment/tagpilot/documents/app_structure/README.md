# TagPilot Premium App Structure Documentation

## 專案概覽
**名稱**: TagPilot Premium (wonderful_food 版本)  
**類型**: L3 Premium 精準行銷平台  
**框架**: R Shiny + bs4Dash v5  
**版本**: v18 (2024-06-23)

## 🏗️ 系統架構

### 技術堆疊
- **前端框架**: bs4Dash v5 (Bootstrap 4 Dashboard)
- **後端框架**: R Shiny Server
- **資料庫**: PostgreSQL (生產) / SQLite (開發測試)
- **AI整合**: OpenAI API
- **資料處理**: dplyr, tidyverse
- **視覺化**: plotly, ggplot2
- **認證**: bcrypt

### 架構特點
1. **模組化設計**: 功能模組化，易於維護和擴展
2. **響應式佈局**: 自適應不同螢幕尺寸
3. **雙資料庫支援**: 自動切換 PostgreSQL/SQLite
4. **Git Subrepo**: 共用 global_scripts 程式碼
5. **IPT客戶分群**: T-Series Insight (T1/T2/T3)

## 📁 目錄結構

```
wonderful_food_TagPilot_premium/
├── app.R                           # 主應用程式入口
├── app2.R                          # 備用/測試版本
├── app_config.yaml                 # 應用配置檔案
├── manifest.json                   # 部署清單
├── TagPilot.Rproj                  # RStudio 專案檔
│
├── config/                         # 配置管理
│   ├── config.R                   # 主配置載入器
│   └── packages.R                 # 套件管理
│
├── modules/                        # 功能模組
│   ├── module_wo_b.R              # 主要分析模組 (ROS框架)
│   ├── module_dna_multi_premium.R # DNA分析 Premium版
│   ├── module_upload.R            # 資料上傳模組
│   ├── module_login.R             # 登入模組
│   └── module_score.R             # 評分模組
│
├── database/                       # 資料庫相關
│   ├── db_connection.R            # 資料庫連接管理
│   ├── vitalsigns_test.db         # SQLite測試資料庫
│   ├── mapping.csv                # 策略對應表
│   └── strategy.csv               # 策略定義
│
├── scripts/                        # 腳本庫
│   └── global_scripts/            # Git Subrepo 共用程式碼
│       ├── 00_principles/         # 開發原則 (257+ 規則)
│       ├── 01_db/                 # 資料庫初始化
│       ├── 02_db_utils/           # 資料庫工具 (tbl2)
│       ├── 04_utils/              # 通用工具函數
│       ├── 08_ai/                 # AI整合工具
│       ├── 10_rshinyapp_components/ # UI組件
│       └── 11_rshinyapp_utils/   # Shiny工具
│
├── utils/                          # 應用工具
│   └── data_access.R              # 資料存取層
│
├── www/                           # 靜態資源
│   └── images/                    # 圖像資源
│
├── test_data/                     # 測試資料
│   ├── KM_eg/                    # KitchenMAMA範例
│   └── README_test_data.md       # 測試資料說明
│
├── documents/                     # 文件
│   └── app_structure/            # 架構文件 (本文件)
│
└── archive/                       # 歷史版本存檔
    └── VitalSigns_archive/       # VitalSigns舊版本
```

## 🔧 核心模組分析

### 1. app.R - 主應用程式
```r
# 架構模式：
- 系統初始化 → 載入配置 → 載入模組 → 定義UI → 定義Server → 啟動應用

# 特點：
- ROS框架整合 (Risk/Opportunity/Stability)
- 全域CSS樣式定義
- Reactive Values管理
- 模組化載入機制
```

### 2. module_dna_multi_premium.R - DNA分析模組
```r
# 核心功能：
- IPT客戶生命週期分群 (T1/T2/T3)
- 80/20規則重組 (Top 20%, Middle 30%, Long Tail 50%)
- 多檔案處理支援
- AI洞察整合

# 技術特點：
- calculate_ipt_segments_full() 分群演算法
- 動態排名計算
- 邊界案例處理
```

### 3. database/db_connection.R - 資料庫連接
```r
# 雙模式支援：
- PostgreSQL (生產環境)
- SQLite (開發測試)

# 智慧切換：
- 自動偵測環境
- 無縫切換資料庫
- 跨資料庫SQL相容

# 安全特性：
- bcrypt密碼加密
- 參數化查詢防SQL注入
```

## 🎨 UI/UX設計模式

### bs4Dash框架
- **版本**: v5
- **主題**: cosmo (Bootstrap 4)
- **佈局**: 響應式側邊欄 + 主內容區

### CSS客製化
```css
/* 關鍵樣式 */
- DataTables滾動優化
- macOS滾動條顯示
- 登入頁面樣式
- 步驟指示器
- 歡迎橫幅漸層
```

### UI組件架構
1. **登入系統**: 獨立模組，支援角色權限
2. **側邊欄**: 動態選單，依權限顯示
3. **主內容**: Tab切換，模組化載入
4. **資料表格**: DT套件，支援互動篩選

## 🔄 資料流程

### 1. 資料上傳流程
```
使用者上傳 → module_upload → 驗證格式 → 存入資料庫 → 觸發分析
```

### 2. DNA分析流程
```
載入資料 → IPT計算 → T系列分群 → 生成洞察 → 視覺化呈現
```

### 3. ROS框架流程
```
Risk評估 → Opportunity識別 → Stability分析 → 策略建議
```

## 🔐 安全機制

### 認證系統
- bcrypt密碼雜湊
- Session管理
- 角色權限控制 (admin/user)

### 資料庫安全
- 參數化查詢
- SQL注入防護
- 環境變數管理敏感資訊

### 部署安全
- .gitignore排除敏感檔案
- 環境變數配置
- SSL/TLS連線

## 📊 關鍵演算法

### IPT (Inter-Purchase Time) 分群
```r
# T1: Top 20% (最快回購)
# T2: Middle 30% (中等回購)
# T3: Long Tail 50% (最慢回購)

分群邏輯：
1. 計算每個客戶的平均購買間隔
2. 依IPT排序並計算百分位
3. 根據百分位劃分T1/T2/T3
```

### ROS評分系統
```r
# Risk: 基於 nrec_prob (流失機率)
# Opportunity: 基於 ipt_mean (購買間隔)
# Stability: 基於 CRI (Customer Regularity Index)
```

## 🚀 部署配置

### 環境變數需求
```yaml
# PostgreSQL連線
PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, PGSSLMODE

# OpenAI API
OPENAI_API_KEY

# 應用配置
APP_ENV (development/production)
```

### 部署目標
- **主要**: Posit Connect Cloud
- **備選**: ShinyApps.io
- **本地**: RStudio Server

## 🔄 Git Subrepo管理

### global_scripts結構
```
來源: git@github.com:kiki830621/ai_martech_global_scripts.git
版本: 463c31676f60e2d7a86f59f7e8f631c8f3ba59ae

包含：
- 257+開發原則
- 通用資料庫工具
- AI整合函數
- UI組件庫
```

### 更新流程
```bash
# 拉取最新global_scripts
git subrepo pull scripts/global_scripts

# 推送本地修改
git subrepo push scripts/global_scripts
```

## 📝 開發原則遵循

### 核心原則
1. **MP002**: 結構化藍圖 - 模組化架構
2. **MP016**: 模組性 - 功能獨立封裝
3. **MP047**: 函數式程式設計
4. **R092**: Universal DBI模式

### 命名規範
- 函數: `fn_function_name.R`
- 模組: `module_feature_name.R`
- 變數: 描述性命名 (如 `customer_dna_matrix`)

### 資料處理
- 使用 `tbl2()` 取代 `dplyr::tbl()`
- 配置驅動開發 (app_config.yaml)
- Reactive編程模式

## 🔍 測試策略

### 單元測試
```r
tests/
├── test_database.R         # 資料庫連線測試
├── test_config.R          # 配置載入測試
└── test_complete_flow.R   # 完整流程測試
```

### 測試資料
- SQLite測試資料庫
- CSV範例檔案
- 模擬客戶資料

## 📈 效能優化

### 資料處理
- 向量化運算
- data.table加速
- 延遲載入策略

### UI響應
- Shiny async處理
- Progress indicators
- 客戶端快取

## 🎯 未來發展方向

### 短期規劃
- [ ] 完善T-Series Insight演算法
- [ ] 增加更多AI洞察功能
- [ ] 優化大數據處理效能

### 長期願景
- [ ] 微服務架構遷移
- [ ] 多租戶支援
- [ ] 即時數據流處理

---
**文件版本**: v1.0  
**更新日期**: 2024-08-26  
**維護者**: Claude Code  
**生成方式**: 架構分析與逆向工程