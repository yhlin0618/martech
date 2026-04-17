# 必須遵守的規則

**使用時機**: 每次對話都適用

---

## MP029 - 禁止 Fake Information（絕對禁止）

**核心原則**：Never assume; always verify before acting（不假設，先驗證）

### 1. DATA - 禁止假資料
- NO sample data, placeholder values, dummy data
- 如需資料但不可用：停止操作，詢問用戶
- 使用真實資料來源或生產資料的子集

### 2. FUNCTIONS - 先搜尋再建立 (DEV_R012)
- 建立新函數前，先搜尋 global_scripts/ 是否已存在
- 不要假設「函數不存在」

### 3. FILES - 先追蹤再修改 (DEV_R039)
- 修改檔案前，先 grep 確認哪個檔案「實際被使用」
- 不要假設「檔案名 = 實際使用的檔案」
- 範例：`grep 'source.*module_login' app_*.R` 確認實際載入的模組

### 4. PATHS - 先驗證再使用
- 確認路徑存在且正確
- 追蹤依賴鏈

**ENFORCEMENT**: 違反 MP029 視為嚴重錯誤。

---

## 原則查找流程

### 主要方法：llm/ 資料夾（v5.0）

1. **必讀** `00_principles/llm/index.yaml`
   - 主要入口（核心原則 + scenarios + chapter index）
   - 結構化規則（CNL + Datalog-like 雙格式）
   - 明確的 `dependencies` 區塊

2. **找到你的 scenario** 在 `scenarios:` 區塊
   - 每個 scenario 列出 `must_read` 原則
   - 按需檢查 `chapter_files`
   - 遵循該 scenario 的 `checklist`

3. **按需讀取 chapter files**:
   - `llm/CH00_meta.yaml` - 124 Meta-Principles
   - `llm/CH01_structure.yaml` - Structure & Organization
   - `llm/CH02_data.yaml` - Data Management
   - `llm/CH03_development.yaml` - Development Methodology
   - `llm/CH04_ui.yaml` - UI & UX
   - `llm/CH05_testing.yaml` - Testing & QA
   - `llm/CH06_ic.yaml` - Integration & Collaboration (Autopush)
   - `llm/CH07_ux.yaml` - User Experience
   - `llm/CH08_data_presentation.yaml` - Data Presentation & Visualization
   - `llm/CH19_documentation.yaml` - Documentation (Wiki, Changelog, Reporting)
   - `llm/CH09_database.yaml` - Database (DuckDB) Specs
   - `llm/CH11_etl.yaml` - ETL Pipeline Patterns
   - `llm/CH12_derivations.yaml` - Derivations
   - `llm/CH13_modules.yaml` - Modules & Tools
   - `llm/CH14_functions.yaml` - Functions Reference
   - `llm/CH15_apis.yaml` - APIs & External Integration
   - `llm/CH16_connections.yaml` - Connections
   - `llm/CH17_templates.yaml` - Templates & Examples
   - `llm/CH18_solutions.yaml` - Solutions & Patterns

4. **如需更多細節**，讀 .qmd 檔案：
   - 位置: `docs/en/part1_principles/{CHAPTER}/{ID}_{name}.qmd`

---

## 原則階層（Decision Priority）

衝突時優先順序：
1. **Meta-Principles (MP)** - 系統架構基礎
2. **Principles (P)** - 實作指引
3. **Rules (R)** - 具體實作模式
4. `global_scripts/` 既有程式碼模式
5. 業界最佳實踐（不與原則衝突時）

---

## 關鍵原則快速參考

### 架構基礎
- **MP064**: ETL-Derivation Separation - ETL 處理資料準備，Derivations 處理商業邏輯
- **MP092**: Platform ID Standard
- **MP093**: Script Separation Principle
- **MP103**: autodeinit() Behavior - 完整清理移除所有變數
- **MP104**: ETL Data Flow Separation

### 資料管理
- **DM_R028**: ETL Data Type Separation - 腳本遵循 `{platform}_ETL_{datatype}_{phase}.R`
- **DM_R023**: Universal DBI Approach (R092) - 使用 `dbConnect_universal()`
- **DM_R025**: Type Conversion Between R and DuckDB
- **DM_R036**: ETL Return Value Patterns

### 開發
- **DEV_R001**: Apply Functions Over Loops
- **DEV_R014**: data.table Vectorization
- **SO_R007**: One Function One File

### UI 元件
- **UI_R001**: UI-Server-Defaults Triple Pattern
- **UI_R011**: bs4Dash Structure Adherence

### 資料呈現 (Data Presentation)
- **MP153**: Data Type Presentation Fidelity - 不同資料類型需用符合其語意的格式呈現
- **DP_R001**: Distribution Winsorization - 分佈圖極端值縮尾處理
- **DP_R002**: Integer Display Fidelity - 整數型資料不可顯示小數點

### 版本控制（Autopush）
- **IC_P001**: Universal Immediate Sync - 每完成一個功能即 commit → pull → push
- **IC_R001**: Global Scripts Synchronization - global_scripts 的嚴格版本

---

## 檔案位置標準

**原則檔案僅在 docs/ 目錄：**
- `docs/en/part1_principles/` - English version (.qmd format)
- `docs/zh/part1_principles/` - Chinese version (.qmd format)

**根目錄 .md 檔案不是官方原則。**
