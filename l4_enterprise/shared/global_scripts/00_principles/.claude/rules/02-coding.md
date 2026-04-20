# 寫程式碼時

**使用時機**: 建立或修改 R 腳本時

---

## global_scripts 版本規則 (CRITICAL)

`scripts/global_scripts/` 是 symlink，指向 `l4_enterprise/shared/global_scripts/`。

**修改共用函數時，必須改 shared 版本：**
```
✅ l4_enterprise/shared/global_scripts/08_ai/fn_rate_comments.R
❌ global_scripts/08_ai/fn_rate_comments.R  ← 最上層的是另一份，改了不會生效
```

所有 l4_enterprise 公司（QEF_DESIGN、MAMBA、WISER 等）共用 `shared/global_scripts/`。
最上層的 `global_scripts/` 是獨立的副本，不被 l4_enterprise 使用。

---

## ETL 6-Layer 架構

### 資料庫層級

**ETL Phase (Extract-Transform-Load)**
```
raw_data.duckdb (0IM) → staged_data.duckdb (1ST) → transformed_data.duckdb (2TR)
```

**DRV Phase (Derivation)**
```
processed_data.duckdb (3PR) → cleansed_data.duckdb (4CL) → app_data.duckdb (5NM)
```

---

## 命名模式

### 檔案命名
```
{platform}_ETL_{datatype}_{phase}.R
```
範例：
- `cbz_ETL_orders_0IM.R` - Cyberbiz 訂單 Import
- `eby_ETL_sales_1ST.R` - eBay 銷售 Staging
- `amz_ETL_products_2TR.R` - Amazon 產品 Transform

### 表格命名
```
df_{platform}_{datatype}___{layer}
```
範例：
- `df_cbz_orders___raw` - 原始訂單資料
- `df_eby_sales___staged` - 已暫存銷售資料
- `df_amz_products___transformed` - 已轉換產品資料

---

## ETL vs Derivation 分離 (MP064)

### ETL 階段（0IM/1ST/2TR）
- 只處理資料移動和格式轉換
- 不包含商業邏輯
- 不進行計算（如 RFM 分數）

### Derivation 階段（3PR/4CL/5NM）
- 商業邏輯在此處理
- 計算衍生欄位
- 建立分析用資料

---

## DRV 群組定義（重要！）

**建立 DRV 腳本前必須確認正確群組：**

| 群組 | 名稱 | 用途 | 範例 |
|------|------|------|------|
| **D00** | App Data Init | 基礎資料結構初始化 | `D00_01` 初始化 app_data |
| **D01** | Customer DNA Analysis | 客戶 DNA 分析（RFM、NES、DNA 分數）| `D01_05` df_dna_by_customer |
| **D02** | Filtered Customer Views | 分段客戶視圖 | `D02_01` 客戶分群視圖 |
| **D03** | Positioning Analysis | 市場定位分析 | `D03_01` 定位矩陣 |
| **D04** | Poisson Precision Marketing | Poisson 分析、時序分析 | `D04_02` Poisson 分析 |
| **D05** | Macro Trend Analysis | 總體趨勢分析（月度聚合、MoM/YoY） | `D05_01` df_macro_monthly_summary |

### 常見錯誤

| 錯誤 | 正確 | 原因 |
|------|------|------|
| DNA 相關放 D04 | DNA 相關放 **D01** | D01 = Customer DNA Analysis |
| Poisson 放 D01 | Poisson 放 **D04** | D04 = Poisson Precision Marketing |

### DRV 檔案命名

```
核心函數: fn_D{群組}_{序號}_core.R
執行腳本: all_D{群組}_{序號}.R
```

範例：
- `fn_D01_07_core.R` - D01 群組第 7 號核心函數（DNA 預計算）
- `all_D01_07.R` - D01 群組第 7 號執行腳本

---

## 程式碼品質 Checklist

### 架構合規
- [ ] 資料庫路徑符合 6-Layer 架構
- [ ] ETL phase 正確分離（Import/Stage/Transform）
- [ ] ETL 中無商業邏輯（商業邏輯在 Derivation）
- [ ] 使用 `dbConnect_universal()` 連接資料庫
- [ ] DuckDB 可重建性正確：raw_data 不可重建（不可刪），其餘皆可重建（DM_R061）
- [ ] DB 檔案放在 `db_paths.yaml` 定義的 canonical 路徑;發現錯位置時**移動資料,不改程式**（DM_R062）
- [ ] Metadata tables 放 `meta_data.duckdb`,**不放 app_data** 也**不走 6-layer ETL**（DM_R054 v2）

### 命名合規
- [ ] 檔案名稱符合 `{platform}_ETL_{datatype}_{phase}.R`
- [ ] 表格名稱符合 `df_{platform}_{datatype}___{layer}`
- [ ] 變數使用描述性名稱

### 文件合規
- [ ] 原則引用記錄在程式碼註解（如 `# Following MP064`）
- [ ] 五段式腳本結構（INITIALIZE/MAIN/TEST/DEINITIALIZE/AUTODEINIT）
- [ ] Console 輸出遵循 DEV_P022 透明度原則

### 資料合規 (MP029)
- [ ] 無假資料、樣本資料、模擬資料
- [ ] 所有測試使用真實資料子集
- [ ] 資料來源明確標註

### 程式碼字元合規 (MP100)
- [ ] 程式碼註解只用 ASCII + 基本中文，不用特殊 unicode（圈數字 ①②③、全形括號（）、emoji 等）
- [ ] 若需編號用 `(1)` `(2)` `(3)` 或 `layer 1` `layer 2` `layer 3`

### 副作用防禦 (MP154 / DEV_R055)
- [ ] mapping/lookup 失敗時使用 sentinel（如 `"UNKNOWN"`），不可用 NA
- [ ] ID 欄位語意一致（不混用 ID 和原始名稱）
- [ ] 部分失敗時有 `warning()` 並列出未映射值和修正指引

---

## 關鍵函數

```r
# 資料庫連接
source("scripts/global_scripts/02_db_utils/duckdb/fn_dbConnectDuckdb.R")
con <- dbConnectDuckdb(db_path_list$staged_data, read_only = TRUE)

# 初始化
source("scripts/global_scripts/22_initializations/sc_Rprofile.R")
autoinit()

# 結束
autodeinit()  # 必須是腳本最後一行
```

---

## DB 路徑 Canonical 強制 (DM_R062)

### 核心規則

所有 `.duckdb` 檔案**必須**放在 `shared/global_scripts/30_global_data/parameters/scd_type1/db_paths.yaml` 的 `databases:` / `domain:` section 定義的 canonical 路徑。

**發現錯位置時:移動資料 → canonical path,不改程式。**

### 為什麼

- code 期望 canonical path 但 file 在其他位置 → 兩種修法:
  - ❌ **改程式加 fallback**(e.g. `if exists(A) use A else B`) → 累積 legacy + 未來新人困惑
  - ✅ **移動檔案到 canonical**(一次到位)
- 事實(data location)錯了要改事實,不是改讀取邏輯(呼應 MP029「No Fake Information」)

### 違規

```r
# BAD: autoinit 試多個路徑
raw_data_path <- if (file.exists(file.path(base, "data", "raw_data.duckdb"))) {
  file.path(base, "data", "raw_data.duckdb")  # legacy 位置
} else {
  file.path(base, "data", "local_data", "raw_data.duckdb")  # canonical
}
```

### 符合

```r
# GOOD: 只讀 canonical;錯位置由人類移動
raw_data_path <- file.path(base, db_config$databases$raw_data)
if (!file.exists(raw_data_path)) {
  stop("raw_data.duckdb not at canonical path: ", raw_data_path,
       "\nMove the file to this path; do not add fallback paths to code.")
}
```

### 修復流程(錯位置檔案)

```bash
# 1. Archive(non-destructive)
mkdir -p <project_root>/data/archived/wrong_location
mv <wrong_path> <project_root>/data/archived/wrong_location/<name>_YYYYMMDD.duckdb

# 2. 若 canonical path 該有檔案但沒 → 跑 ETL rebuild
# autoinit 會在 db 缺失時報 actionable error(autoinit-failfast-policy)
```

### 相關原則

- **MP029**:No Fake Information(不假設,直接面對事實)
- **DM_R028**:ETL Data Type Separation(6-layer canonical 結構)
- **DM_R056**:Mode-Specific DB Paths(db_paths.yaml 為 source of truth)
- **autoinit-failfast-policy** spec:缺 canonical 檔案時立即報錯

---

## Metadata 必在 `meta_data.duckdb` (DM_R054 v2.1)

### 核心規則

所有 metadata tables(`df_platform`, `df_product_line`, `df_product_mapping`, `df_category_hierarchy` 等 reference / lookup / mapping 類)**必須**住在 `meta_data.duckdb`:

- **不**寫入 `app_data.duckdb`(違反 v2)
- **不**流經 6-layer ETL(raw / staged / transformed / processed / cleansed)
- 每個 metadata table 只能有**一個 canonical 物理位置**(無跨 DB 重複)

### 為什麼不放 app_data

`app_data.duckdb` 是 rebuildable(DM_R061):常見操作 `rm app_data.duckdb && make run` 會重建 app_data。若 metadata 在 app_data,此操作會**意外抹掉 metadata**。metadata 屬非 rebuildable(跟 raw_data 同類),必須有獨立 non-rebuildable 位置。

### 第 7 層定位

```
Transaction flow (6 layers):
  raw → staged → transformed → processed → cleansed → app_data

Metadata (parallel, 7th layer):
  meta_data.duckdb  ← non-rebuildable,survives app_data rebuild
```

### 讀取 metadata

```r
# 方案 1:直接連線(DM_R023 v1.2:讀取必須用 tbl2,不可 dbGetQuery + SELECT)
con_meta <- dbConnectDuckdb(db_path_list$meta_data, read_only = TRUE)
df_platform <- tbl2(con_meta, "df_platform") %>% collect()

# 方案 2:DuckDB ATTACH(跨 DB JOIN 首選)
# 路徑必須用 DBI::dbQuoteString 引用,避免含 single-quote 的路徑破壞 SQL;
# attach 後的表用 dbplyr::in_schema(),不可用 "meta.df_platform" 字面 dot-syntax。
attach_sql <- paste0(
  "ATTACH DATABASE ", DBI::dbQuoteString(con_app, db_path_list$meta_data),
  " AS meta (READ_ONLY)"
)
dbExecute(con_app, attach_sql)
tbl2(con_app, dbplyr::in_schema("meta", "df_platform")) %>% collect()
```

### Producer 契約

每個 metadata table 有**exactly 一個** producer ETL:

- Metadata ETL 命名:`all_ETL_{type}_0IM.R`(例:`all_ETL_meta_init_0IM.R`)
- PRODUCES 目標:`meta_data.duckdb`(non-6-layer)
- 必 idempotent
- **不**清掉 `__COMPANY` suffix 的診斷 tables(DM_R037 v3.0)

### 違規

```r
# ❌ 寫到 app_data
dbWriteTable(con_app, "df_platform", df_platform)

# ❌ 跨 DB 重複
dbWriteTable(con_meta, "df_platform", df)
dbWriteTable(con_app,  "df_platform", df)

# ❌ Fallback logic
path <- if (file.exists(app_path)) app_path else meta_path
```

### 符合

```r
# ✅ 寫到 meta_data(single canonical)
con_meta <- dbConnectDuckdb(db_path_list$meta_data, read_only = FALSE)
dbWriteTable(con_meta, "df_platform", df_platform, overwrite = TRUE)
```

### Rebuild safety 保證

`rm data/app_data/app_data.duckdb && make run` → app_data rebuilt、meta_data 完全不動。

### v2.1 runtime addendum(2026-04-19)

v2 建立了 canonical 位置,v2.1 把**runtime 路徑**也收攏。三條新 requirement:

#### 1. Runtime MAY NOT Read CSV Seeds

CSV(`data/app_data/parameters/scd_type1/df_product_line.csv`)是 **producer ETL 專屬的 seed 輸入**。`all_ETL_meta_init_0IM.R` 之外的任何程式 — Shiny 入口、UPDATE_MODE init、DRV、下游 ETL consumer —都**不准**在 runtime 跑 `read.csv(... df_product_line.csv)`。**沒有 fallback**:找不到 `meta_data.duckdb` 的正解永遠是「跑一次 bootstrap ETL」,不是「暫時退回 CSV」。

```r
# ❌ 違反 v2.1:runtime 退 CSV
if (file.exists(db_path_list$meta_data)) {
  df_product_line <- tbl2(meta_con, "df_product_line") %>% collect()
} else {
  df_product_line <- read.csv("data/app_data/parameters/scd_type1/df_product_line.csv")
}

# ❌ 違反 v2.1:Shiny entry 直接讀 CSV
df_product_line <- read.csv("data/app_data/parameters/scd_type1/df_product_line.csv")

# ✅ 符合 v2.1:runtime 只經 canonical reader
df_product_line <- fn_load_product_lines(
  conn = NULL,
  meta_data_path = db_path_list$meta_data
)  # meta_data 缺失時 stop() 並給 actionable message
```

#### 2. Readers SHALL Reach `meta_data.duckdb` Through `fn_load_product_lines`

所有 `df_product_line` 的 runtime consumer **必須**走 `shared/global_scripts/04_utils/fn_load_product_lines.R`。不准在 library 外面直接 `DBI::dbReadTable(meta_con, "df_product_line")` — 這個 helper 是 schema 驗證、encoding、canonical-path 錯誤訊息的單一入口。Cross-DB JOIN 透過 ATTACH 仍可(純 SQL-side),但一旦把結果 assign 到 R 變數做下游邏輯,還是要走 canonical reader。

```r
# ❌ 違反 v2.1:跳過 canonical reader
meta_con <- DBI::dbConnect(duckdb::duckdb(), db_path_list$meta_data, read_only = TRUE)
df_product_line <- DBI::dbReadTable(meta_con, "df_product_line")

# ✅ 符合 v2.1:library 外的所有 caller 都經 fn_load_product_lines
df_product_line <- fn_load_product_lines(conn, meta_data_path = db_path_list$meta_data)
```

`df_platform` 目前尚無對應的 canonical reader function;若日後新增 `fn_load_platforms()`,此規則自動延伸到 `df_platform`。

#### 3. APP_MODE `autoinit()` SHALL Populate `db_path_list$meta_data`

Shiny app 啟動(APP_MODE)時,`autoinit()` **必須**把 `meta_data` 跟 `app_data` 一起放進 `db_path_list`:

```r
db_path_list <- list(
  app_data  = file.path(project_root, db_paths$databases$app_data),
  meta_data = file.path(project_root, db_paths$databases$meta_data)  # v2.1 強制要求
)
```

沒放的話 reader 看到 `db_path_list$meta_data == NULL`,走進 `fn_load_product_lines` 的 no-fallback `stop()`,Shiny 無法啟動。UPDATE_MODE 的 pipeline init 已經 populate 全部 6+1 paths,不受本條影響。

### 相關原則

- **DM_R061**:Database Rebuildability Classification(rebuildable 分類)
- **DM_R062**:Canonical DB Path Enforcement(meta_data path in db_paths.yaml)
- **DM_R037 v3.0**:`___COMPANY` suffix 命名(`__MAMBA` 診斷表在 meta_data 被保留)
- **MP064**:ETL-Derivation Separation(metadata 是「第 7 層」,與 6-layer flow 並行)
- **MP029**:No Fake Information(canonical 位置是事實)

### 版本歷史

| 版本 | 規則 | 日期 |
|---|---|---|
| v1 | metadata MUST → app_data.duckdb | 2025-12-26 |
| v2 | metadata MUST → meta_data.duckdb(7 th layer) | 2026-04-19 |
| **v2.1** | **v2 + runtime addendum:no CSV fallback、canonical reader、APP_MODE autoinit populate meta_data** | **2026-04-19** |

- v1 → v2:spectra change `metadata-to-meta-data-duckdb`(issue #422)
- v2 → v2.1:spectra change `dm-r054-v2-migration-complete`(issue #424)

---

## 資料庫讀取規範 (DM_R023 v1.2)

**強制**：資料庫讀取必須使用 `tbl2()` + dplyr verbs。Raw SQL `dbGetQuery(... SELECT ...)` 一律禁止用於讀取,含 `?` positional placeholder 的版本更是**絕對不行**(DuckDB 接受但 PostgreSQL 拒絕,MAMBA #365 就是因此爆炸)。

完整規範見 `DM_R023_universal_dbi_approach.qmd` Section 6 Exceptions & Migration。

### 好的做法

```r
# 簡單 table
tbl2(con, "df_macro_monthly_summary") %>%
  filter(platform_id == "amz", product_line_id == "blb") %>%
  collect()

# Schema 限定(例如 PostgreSQL public schema 或 DuckDB ATTACH)
tbl2(con, dbplyr::in_schema("transformed_data", "df_amz_review___transformed")) %>%
  filter(!is.na(product_line_id)) %>%
  collect()

# group_by + summarise(dbplyr 會翻譯成 driver-specific SQL)
tbl2(con, "df_sales") %>%
  group_by(platform_id) %>%
  summarise(total = sum(amount)) %>%
  collect()
```

### 不好的做法

```r
# 禁止：raw SQL 讀取(違反 DM_R023)
DBI::dbGetQuery(con, "SELECT * FROM df_customers")

# 禁止：? placeholder(在 PostgreSQL 會 syntax error)
DBI::dbGetQuery(con, "SELECT * FROM df_x WHERE id = ?", params = list(input_id))

# 禁止(新程式碼):呼叫 dbGetQuerySafe 是 transition 期間的 band-aid
dbGetQuerySafe(con, sql, params = list(...))
# dbGetQuerySafe() 已於 2026-04-13 標記 deprecated,目標 2026-07-13 移除

# 禁止:dot-syntax 已被 tbl2.DBIConnection refactor 移除,改用 in_schema()
tbl2(con, "schema.table")  # ← 會被當作單一 table 名(含字面 '.')
```

### 三個允許的例外(Section 6)

| 情境 | 用什麼 | 範例 |
|---|---|---|
| 寫入(DDL/DML) | `DBI::dbExecute()` + raw SQL | `dbExecute(con, "CREATE TABLE ...")` |
| Driver 專屬 introspection | `02_db_utils/` 下的 helper 函數 | 未來的 `dbPragma()`、`dbIntrospect()` |
| 過渡期 `dbGetQuerySafe()` | 允許在舊程式碼存在直到 2026-07-13 | 新程式碼禁止呼叫 |

### 自動執行機制

`.claude/hooks/check-tbl2-compliance.sh` (PreToolUse on Edit/Write) 偵測 `DBI::dbGetQuery(.*SELECT` 和 `dbGetQuerySafe(` pattern,違反時 advisory 提醒(non-blocking)。

### 相關原則

- **DM_R023** (v1.2, 2026-04-13): Universal DBI Approach — 本規範的權威來源
- **DM_R002/R003/R011/R012/R013/R014**: 相關的 tbl2 / universal data access patterns
- **DOC_R009**: Triple-layer sync(`.qmd → llm/ → rules/`)— 修改本區段時必須同步 DM_R023.qmd 和 `llm/CH02_data.yaml`

---

## 錯誤模式監控

### DuckDB 錯誤
| 模式 | 意義 | 解決方案 |
|------|------|----------|
| `rapi_register_df` | DuckDB 註冊錯誤 | 檢查 DataFrame 類型和欄位 |
| `std::exception` | DuckDB C++ 例外 | 檢查 SQL 語法和資料類型 |
| `Conflicting lock` | 資料庫鎖定 | 關閉其他連線或重啟 R session |
| `column.*not found` | 欄位不存在 | 驗證表格 schema |

### API 錯誤
| 狀態碼 | 意義 | 解決方案 |
|--------|------|----------|
| `401` | 未授權 | 檢查 API key |
| `403` | 禁止存取 | 檢查權限設定 |
| `404` | 資源不存在 | 驗證 endpoint URL |
| `500` | 伺服器錯誤 | 檢查請求格式或稍後重試 |

### R 常見錯誤
| 模式 | 意義 | 解決方案 |
|------|------|----------|
| `Error in source()` | 找不到檔案 | 驗證路徑和工作目錄 |
| `could not find function` | 套件未載入 | 確認 library() 呼叫 |
| `replacement has.*rows` | 向量長度不符 | 檢查資料維度 |

---

## 即時監控指令

### 執行 R 腳本並監控輸出
```bash
stdbuf -oL -eL Rscript script.R 2>&1 | tee log.txt &
```

### 追蹤特定錯誤
```bash
stdbuf -oL -eL Rscript script.R 2>&1 | grep -E "(Error|Warning|✗)" | tee errors.txt
```

### 監控長時間執行的 ETL
```bash
# 背景執行並保存 log
nohup Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_orders_0IM.R > etl_log.txt 2>&1 &

# 即時追蹤
tail -f etl_log.txt
```

---

## ETL 偵錯流程

1. **確認資料庫連線**
   ```r
   con <- dbConnectDuckdb(db_path_list$staged_data)
   dbIsValid(con)  # 應回傳 TRUE
   ```

2. **檢查來源表格**
   ```r
   dbExistsTable(con, "source_table")
   dbGetQuery(con, "SELECT * FROM source_table LIMIT 5")
   ```

3. **驗證資料類型**
   ```r
   str(df)
   sapply(df, class)
   ```

4. **檢查 NA 分布**
   ```r
   colSums(is.na(df))
   ```

5. **驗證轉換結果**
   ```r
   nrow(df_before)
   nrow(df_after)
   names(df_after)
   ```

---

## 常見問題排解

### 資料庫鎖定
```r
# 解決方案 1: 關閉所有連線
DBI::dbDisconnect(con)
gc()  # 強制垃圾回收

# 解決方案 2: 重啟 R session
.rs.restartR()
```

### 記憶體不足
```r
# 檢查記憶體使用
pryr::mem_used()

# 清理大型物件
rm(large_object)
gc()

# 使用 data.table 取代 tibble 以節省記憶體
library(data.table)
dt <- as.data.table(df)
```

### 編碼問題
```r
# 確保 UTF-8
Sys.setlocale("LC_ALL", "en_US.UTF-8")

# 檢查字串編碼
Encoding(text_column)
```

---

## 顯示資料外部化 (DEV_R050)

### 核心規則

**禁止**在 R 函數中 hardcode 顯示用文字（行銷建議、分類描述、UI 長文本等）。

顯示資料**必須**存放在外部檔案：
- 位置：`30_global_data/parameters/` 下的 YAML 或 CSV
- R 函數只負責邏輯判斷，透過 key 從外部檔案載入顯示內容

### 正確做法

```r
# 好：從 YAML 載入顯示內容
strategies <- yaml::read_yaml("30_global_data/parameters/marketing_strategies.yaml")
purpose <- strategies[["Awakening / Return"]]$purpose
```

### 錯誤做法

```r
# 不好：hardcode 在 R 函數中
purpose <- "防流失"
recommendation <- paste0("1. 定期發送關懷訊息...<br>", "2. S1 給小額折扣...")
```

### 適用範圍

| 類型 | 放哪裡 | 範例 |
|------|--------|------|
| 行銷策略建議 | `30_global_data/parameters/marketing_strategies.yaml` | 13 策略的中文建議 |
| 分類標籤映射 | `30_global_data/parameters/*.yaml` | RSV 客戶類型名稱 |
| UI 短標籤 | `11_rshinyapp_utils/translation/ui_terminology.csv` | 按鈕、欄位名 |
| 程式邏輯常數 | R 函數內（可 hardcode） | 閾值 0.7、分位數 0.2 |

### 理由

- 內容可由非工程人員修改（改 YAML 比改 R 安全）
- 避免中文 unicode escape 造成可讀性問題
- 符合 configuration-driven 開發原則（MP142）
- 單一修改點：改一次 YAML，所有引用處自動更新

---

## CSV 下載必須含 UTF-8 BOM (DEV_R051)

### 核心規則

所有 `downloadHandler` 產出的 CSV 檔案**必須**包含 UTF-8 BOM（Byte Order Mark），確保 Excel 正確辨識中文編碼。

### 禁止使用 `write.csv` + `append`

R 的 `write.csv()` 會**靜默忽略** `append = TRUE` 參數（設計限制），導致先寫入的 BOM 被覆蓋。

### 正確做法

```r
output$download_csv <- downloadHandler(
  filename = function() paste0("export_", Sys.Date(), ".csv"),
  content = function(file) {
    df <- reactive_data()
    if (!is.null(df)) {
      # Step 1: Write UTF-8 BOM (Excel compatibility)
      con <- file(file, "wb")
      writeBin(charToRaw("\xef\xbb\xbf"), con)
      close(con)
      # Step 2: write.table (NOT write.csv) to support append=TRUE
      utils::write.table(df, file, row.names = FALSE, sep = ",",
                         quote = TRUE, append = TRUE, fileEncoding = "UTF-8")
    }
  }
)
```

### 錯誤做法

```r
# 不好：write.csv 忽略 append=TRUE，BOM 被覆蓋
utils::write.csv(df, file, row.names = FALSE, fileEncoding = "UTF-8", append = TRUE)
```

### 理由

- Excel 在 Windows/macOS 預設以系統 locale 開啟 CSV，無 BOM 時中文會亂碼
- `write.csv` 是 `write.table` 的嚴格包裝器，強制 `append=FALSE`
- 使用 `write.table` + 明確的 `sep=","` 和 `quote=TRUE` 等同於 `write.csv` 的行為，但支援 `append`

---

## 業務邏輯用英文 Key，UI 才 translate (DEV_R052)

### 核心規則

所有非 UI 的程式碼**必須**使用英文 canonical key。`translate()` **只能**在 UI 渲染層呼叫。

### 架構邊界

```
┌─────────── 非 UI（全英文）──────────┐
│  DRV:    r_label = "Recent Buyer"   │
│  switch: "Recent Buyer" = ...       │
│  filter: df$r_label == "Recent..."  │
│  config: key: "High Value"          │
├──────── translate() 邊界 ───────────┤
│  UI:     translate("Recent Buyer")  │
│  pie:    sapply(levels, translate)   │
│  table:  colnames = translate(...)  │
└─────────────────────────────────────┘
```

### 適用範圍

| 層級 | 語言 | 用 translate()? |
|------|------|-----------------|
| ETL / DRV 腳本 | 英文 | 否 |
| 函數檔案 (`fn_*.R`) | 英文 | 否 |
| switch / if-else / case_when | 英文 | 否 |
| 設定檔 (YAML / CSV) | 英文 key | 否 |
| Shiny server 邏輯 | 英文 | 否 |
| **Shiny UI 渲染** | **英文 → 翻譯** | **是（必須）** |

### 正確做法

```r
# DRV: 存英文
r_label = case_when(r_ecdf >= 0.67 ~ "Recent Buyer", ...)

# 業務邏輯: 用英文比對
switch(segment, "Recent Buyer" = list(strategy = "Deepen Engagement", ...))

# UI: translate 顯示
tags$h6(translate(segment))
```

### 錯誤做法

```r
# 不好：業務邏輯用中文 unicode escape
switch(segment, "\u9ad8\u6d3b\u8e8d" = ...)

# 不好：中間加 band-aid mapping
label_map <- c("Recent Buyer" = "\u9ad8\u6d3b\u8e8d")

# 不好：UI 不翻譯，直接顯示英文
tags$h6(segment)  # 應該用 translate(segment)
```

### 理由

- 英文 key 無 encoding 問題，中文 `\uXXXX` escape 不可讀且易出錯
- 業務邏輯不依賴顯示語言，未來加新語言零修改
- 防止 `switch()` 靜默 fall-through（Issue #241 的根因）
- **UI 必須 translate**：確保使用者看到的是其語言的內容

> **例外：AI Prompt 內容** — AI prompt 的多語系不用 `translate()`，改用 `load_openai_prompt(key, locale=)` 從 `ai_prompts.yaml` 載入。詳見 DEV_R053 和 `09-openai-integration.md`。

---

## 臺灣正體中文用語規範 (UI_R025)

### 核心規則

翻譯必須使用**臺灣正體中文**的慣用語，避免大陸慣用語造成的語意偏移。

注意：部分詞彙在臺灣有其**特定語意**，並非完全禁用。例如「數據」在臺灣可用於學術或統計脈絡（如「數據分析」），但泛指 data 時應用「資料」；「質量」在臺灣指物理的 mass，不指 quality。本規範針對的是**大陸用法語意外溢到臺灣不使用的場景**。

### 詞彙對照表

| 大陸用法（本專案避免） | 臺灣用法 | 說明 |
|---|---|---|
| 數據（泛指 data） | 資料 | 臺灣「數據」偏指 numerical data / statistics |
| 激活 | 活化、啟動 | |
| 捆綁 | 組合、搭售 | |
| 批量 | 批次、大量 | |
| 信息 | 資訊 | |
| 軟件 | 軟體 | |
| 網絡 | 網路 | |
| 視頻 | 影片 | |
| 用戶（泛指 user） | 使用者 | 臺灣「用戶」偏指帳戶持有人（如銀行用戶） |
| 反饋 | 回饋 | |

### 適用範圍

- `ui_terminology.csv` 的 `zh_tw` 欄位
- 所有經 `translate()` 顯示的文字
- AI prompts 中的中文 system prompt（如適用）
- 任何使用者可見的中文文字

### 理由

- 臺灣市場的產品必須使用在地化用語
- 大陸用語會讓臺灣使用者感到不自然且不專業
- 維護品牌的在地親和力

---

## 欄位/指標顯示名稱格式 (UI_R027)

### 核心規則

當資料項目有公認的英文縮寫或代碼時，顯示格式為：

**`中文全稱（英文縮寫）`**

中文全稱在前（因為 zh_TW 是主要 UI 語言），英文縮寫在全形括號 `（）` 內。

### 範例

| English Key | zh_TW 顯示 | 類別 |
|-------------|------------|------|
| CLV | 顧客終生價值（CLV） | 指標 |
| RFM | 顧客價值分數（RFM） | 指標 |
| NES | 新舊客狀態（NES） | 指標 |
| CAI | 客戶活躍指數（CAI） | 指標 |
| IPT | 平均購買間隔（IPT） | 指標 |
| P(alive) | 存活機率（P(alive)） | 指標 |
| E0 | 主力客（E0） | NES 狀態 |
| S1 | 瞌睡客（S1） | NES 狀態 |
| S2 | 半睡客（S2） | NES 狀態 |
| S3 | 沈睡客（S3） | NES 狀態 |
| MoM | 月增率（MoM） | 增長率 |
| YoY | 年增率（YoY） | 增長率 |

**無標準縮寫的項目**：純中文顯示（如「總營收」、「訂單數」）。

### 實作方式

格式存放在 `ui_terminology.csv`，不在 runtime 組合：

```csv
en_us,zh_tw
CLV,顧客終生價值（CLV）
NES Status - E0,主力客（E0）
Total Revenue,總營收
```

程式碼使用 `translate()` 即可取得正確格式：

```r
# translate("CLV") → "顧客終生價值（CLV）"
# translate("Total Revenue") → "總營收"
```

### 違規範例

```r
# 違規：只有縮寫，無中文
colnames(show_df) <- c("CLV", "RFM", "NES")

# 違規：有中文但缺少縮寫（有標準縮寫的項目）
# translate("CLV") → "顧客終生價值"

# 違規：英文在前
# translate("CLV") → "CLV 顧客終生價值"

# 違規：NES 狀態缺少代碼
# translate("NES Status - E0") → "主力客"
```

### 適用範圍

- DT::datatable 欄位名稱
- KPI 卡片標題
- 圖表軸標籤與圖例
- Sidebar filter 標籤
- 任何使用者可見的欄位名或指標標籤
