# New Company Deployment Checklist

## Prerequisites (Check Before Starting)

- [ ] **GitHub CLI installed**: `gh --version`
  ```bash
  # If missing: brew install gh
  ```
- [ ] **GitHub CLI authenticated**: `gh auth status`
  ```bash
  # If not logged in: gh auth login
  ```
- [ ] **GitHub SSH access working**: `ssh -T git@github.com`
  ```bash
  # If fails, set up SSH key:
  ssh-keygen -t ed25519 -C "your_email@example.com"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub  # Add to GitHub → Settings → SSH Keys
  ```

> ⚠️ **Do NOT proceed if prerequisites fail!**

---

## Automated by Skill ✅

這些由 `/new-company` skill 自動完成：

- [ ] Project directory structure created
- [ ] `data/local_data/` directory created
- [ ] Git initialized at project root
- [ ] GitHub repo created: `ai_martech_{TIER}_{COMPANY}`
- [ ] global_scripts symlinked from shared/ (Track 1)
- [ ] update_scripts symlinked from shared/ (Track 2)
- [ ] nsql symlinked from shared/ (Track 4: Human-AI Confirmation Protocol)
- [ ] `.claude` symlink created (for Claude Code integration)
- [ ] All config files created from templates
- [ ] Parameters directories created (`data/app_data/parameters/scd_type1/`, `scd_type2/`)
- [ ] Product line discovery gate completed (full Google sheet scan + coverage validation) before deciding `product_line_id`
- [ ] `df_product_line.csv` created from coding sheet / KEYS.xlsx / manual input
- [ ] `chinese_labels.yaml` created with company-specific `product_attributes` section
- [ ] `brand_aliases.yaml` created with company-specific `brand_standardization` section
- [ ] Initial commit and push to GitHub

---

## ⚠️ 使用者必須設定 (User Must Configure)

### 1️⃣ Rawdata 資料夾設定

> Claude 不會動 rawdata，必須手動設定！

```bash
# 選一種方式：

# A: Symlink 到現有 Dropbox
ln -s /path/to/dropbox/client_data data/local_data/rawdata_{COMPANY}

# B: 用 Finder 移動 Dropbox 資料夾

# C: 純 API 資料（建空目錄）
mkdir -p data/local_data/rawdata_{COMPANY}
```

驗證：
```bash
ls -la data/local_data/rawdata_{COMPANY}
```

---

### 2️⃣ 環境變數設定 (.env)

```bash
cp .env.template .env
chmod 644 .env
```

**依啟用平台填入：**

| Platform | 必填環境變數 | 如何取得 |
|----------|-------------|----------|
| **Cyberbiz** | `CBZ_API_TOKEN` | Cyberbiz 後台 → API 設定 |
| | `CBZ_SHOP_ID` | Cyberbiz 後台 → 商店資訊 |
| **eBay** | `EBY_SSH_HOST` | 客戶提供的 SSH 跳板機 IP |
| | `EBY_SSH_USER` | SSH 登入帳號 |
| | `EBY_SSH_PASSWORD` | SSH 密碼（或用 key） |
| | `EBY_SQL_HOST` | SQL Server IP |
| | `EBY_SQL_DATABASE` | 資料庫名稱 |
| | `EBY_SQL_USER` | SQL 帳號 |
| | `EBY_SQL_PASSWORD` | SQL 密碼 |
| **Amazon** | `AMZ_ACCESS_KEY` | AWS IAM → Access Keys |
| | `AMZ_SECRET_KEY` | AWS IAM → Access Keys |
| **OpenAI** | `OPENAI_API_KEY` | OpenAI Platform → API Keys |
| **Supabase** | `SUPABASE_DB_HOST` | Supabase Dashboard → Database |
| | `SUPABASE_DB_PORT` | 預設 5432 |
| | `SUPABASE_DB_NAME` | 預設 postgres |
| | `SUPABASE_DB_USER` | Supabase Dashboard → Database |
| | `SUPABASE_DB_PASSWORD` | Supabase Dashboard → Database |
| **PostgreSQL** | `PGHOST`, `PGUSER`, etc. | 如使用外部 PostgreSQL（非 Supabase）|

---

### 2.5️⃣ Database Mode 設定 (app_config.yaml)

> 決定 App 如何連接資料庫（本地 DuckDB 或 Supabase PostgreSQL）

```yaml
database:
  mode: "duckdb"      # "duckdb" | "supabase" | "auto"
  duckdb:
    path: "data/app_data/app_data.duckdb"
    read_only: true
```

| Mode | 說明 | 適用場景 |
|------|------|----------|
| `duckdb` | 強制使用本地 DuckDB 檔案 | 本地開發、初始設定 |
| `supabase` | 強制使用 Supabase PostgreSQL | 部署、遠端測試 |
| `auto` | 自動偵測（有本地 DuckDB 就用，否則用 Supabase） | 進階場景 |

如選擇 `supabase` 或 `auto`，確保 `.env` 中的 Supabase 環境變數已填寫。

---

### 3️⃣ 平台啟用 (app_config.yaml)

編輯 `app_config.yaml`：

```yaml
# 取消註解需要的平台（map 格式）
platforms:
  cbz:
    status: "active"     # ✅ 啟用 Cyberbiz
  eby:
    status: "active"     # ✅ 啟用 eBay
  # amz:
  #   status: "active"   # ❌ 未啟用 Amazon

# 對應啟用 pipeline
pipeline:
  platforms:
    cbz:
      enabled: true      # ✅
      drv_groups: ["D00", "D01", "D04"]
    eby:
      enabled: true      # ✅
      drv_groups: ["D00", "D01", "D04"]
    amz:
      enabled: false     # ❌
```

**DRV 群組說明：**

| 群組 | 名稱 | 用途 |
|------|------|------|
| **D00** | App Data Init | 基礎資料結構初始化 |
| **D01** | Customer DNA Analysis | 客戶 DNA 分析（RFM、NES） |
| **D02** | Filtered Customer Views | 分段客戶視圖 |
| **D03** | Positioning Analysis | 市場定位分析 |
| **D04** | Poisson Precision Marketing | Poisson 分析、時序分析 |

---

### 4️⃣ Google Sheets 設定（如使用 metadata）

**取得 Sheet ID：**
```
https://docs.google.com/spreadsheets/d/【這段就是 SHEET_ID】/edit
```

編輯 `app_config.yaml`：
```yaml
googlesheet:
  product_profile: "1DAD...你的SheetID"
  comment_property: "1-es...你的SheetID"

metadata_sources:
  turbo:
    enabled: true
    sheet_id: "1DAD...你的SheetID"
    sheet_name: "metadata_Turbo"
```

**Google Sheets API 權限：**
1. 前往 Google Cloud Console
2. 啟用 Google Sheets API
3. 建立 Service Account
4. 下載 JSON key → 放到安全位置
5. 將 Sheet 分享給 Service Account email

---

### 5️⃣ eBay SSH Key 設定（如使用 eBay）

> 這是連到客戶 eBay 伺服器的 SSH，不是 GitHub SSH！

```bash
# 產生專用 SSH key
ssh-keygen -t ed25519 -C "{COMPANY}-eby-etl" -f ~/.ssh/id_eby_{COMPANY}

# 複製公鑰給客戶
cat ~/.ssh/id_eby_{COMPANY}.pub
# 請客戶加到他們的 ~/.ssh/authorized_keys

# 測試連線
ssh -i ~/.ssh/id_eby_{COMPANY} {EBY_SSH_USER}@{EBY_SSH_HOST}

# 更新 .env（改用 key 而非密碼）
# EBY_SSH_KEY_PATH=~/.ssh/id_eby_{COMPANY}
# 註解掉 EBY_SSH_PASSWORD
```

---

### 6️⃣ Posit Connect 設定（如需部署）

**首次設定：**
```r
# 安裝 rsconnect
install.packages("rsconnect")

# 連接帳號（從 Posit Connect 取得 token）
rsconnect::setAccountInfo(
  name = "{COMPANY_LOWER}-team",
  token = "your_token",
  secret = "your_secret"
)
```

**更新 app_config.yaml：**
```yaml
deployment:
  target: "posit_connect"
  url: "https://connect.posit.cloud"
  account_name: "{COMPANY_LOWER}-team"
  app_name: "{COMPANY_LOWER}-analytics"
```

---

### 7️⃣ 公司專屬腳本（如需客製化）

如果通用腳本不適用，建立公司變體：

```bash
cd scripts/update_scripts/ETL/eby/

# 複製通用版本
cp eby_ETL_orders_0IM.R eby_ETL_orders_0IM___{COMPANY}.R

# 編輯客製化內容
# - 連線參數
# - SSH tunnel 設定
# - 資料轉換邏輯

# 推送到共用 Track 2
cd ../../shared/update_scripts
git add .
git commit -m "Add {COMPANY} ETL variants"
git pull && git push
```

---

## 驗證設定

### 測試連線
```bash
Rscript scripts/global_scripts/98_test/test_connections.R
```

### 測試公司識別
```bash
Rscript -e '
source("scripts/global_scripts/04_utils/fn_resolve_script_path.R")
print(paste("Company:", get_company_from_config()))
'
```

### 測試 ETL
```bash
cd scripts/update_scripts
make config-merge
make run PLATFORM=cbz
```

### 啟動應用
```bash
Rscript app.R
```

---

## 設定摘要表

| 項目 | 必要性 | 檔案/位置 |
|------|--------|-----------|
| Rawdata 資料夾 | **必須** | `data/local_data/rawdata_{COMPANY}` |
| .env 憑證 | **必須** | `.env` |
| Database Mode | **必須** | `app_config.yaml` → `database.mode:` |
| 平台啟用 | **必須** | `app_config.yaml` → `platforms:` |
| Pipeline 啟用 | **必須** | `app_config.yaml` → `pipeline.platforms:` |
| df_product_line.csv | **必須** | `data/app_data/parameters/scd_type1/df_product_line.csv` |
| chinese_labels.yaml | **必須** | `data/app_data/parameters/scd_type2/chinese_labels.yaml` |
| brand_aliases.yaml | **必須** | `data/app_data/parameters/scd_type2/brand_aliases.yaml` |
| Coding Sheet URL | 建議 | Step 1 收集，用於建立上述 3 個參數檔案 |
| Supabase 憑證 | 如用 Supabase | `.env` → `SUPABASE_DB_*` |
| Google Sheets | 選用 | `app_config.yaml` → `googlesheet:` |
| eBay SSH Key | 如用 eBay | `~/.ssh/id_eby_{COMPANY}` |
| Posit Connect | 如需部署 | `rsconnect::setAccountInfo()` |
| 公司專屬腳本 | 如需客製 | `ETL/*___{COMPANY}.R` |

---

## Troubleshooting

### Shared Repo Issues
```bash
# 檢查 shared repos 狀態
cd shared/global_scripts && git status
cd shared/update_scripts && git status

# 強制拉取最新版本
cd shared/global_scripts && git pull --force
cd shared/update_scripts && git pull --force
```

### Connection Issues
```bash
# Test SSH tunnel (eBay)
ssh -L 1433:$EBY_SQL_HOST:1433 $EBY_SSH_USER@$EBY_SSH_HOST

# Test API (Cyberbiz)
curl -H "Authorization: Bearer $CBZ_API_TOKEN" https://api.cyberbiz.io/v1/test
```

### Script Resolution Issues
```bash
Rscript -e '
source("scripts/global_scripts/04_utils/fn_resolve_script_path.R")
script <- resolve_script_path("ETL/eby/eby_ETL_orders_0IM.R", "{COMPANY}")
print(script)
print(file.exists(script))
'
```
