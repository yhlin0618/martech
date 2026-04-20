# 開發環境設定指南

> 本文件適用於所有使用 `global_scripts/` 的專案

本專案支援兩種開發模式，請依您的需求選擇：

## 選擇您的開發模式

| 我想要... | 選擇 | 設定時間 |
|-----------|------|---------|
| 偶爾修改，不需要 Git | **方案 A** | 0 分鐘 |
| 完整開發，需要 Git/部署 | **方案 B** | 10 分鐘 |

---

## 方案 A：Dropbox 協作模式

直接在共享的 Dropbox 資料夾中編輯。

**優點**：零設定，立即開始
**限制**：無法自己 commit/push，由主要維護者統一發布

### 步驟

1. 取得 Dropbox 共享資料夾存取權限
2. 直接編輯檔案
3. 通知主要維護者進行 commit 和部署

---

## 方案 B：標準 Git 模式

**重要**：請勿在 Dropbox/iCloud/OneDrive 等雲端同步資料夾中進行 Git 操作！

### 步驟

#### 1. 取得專案資料夾（二擇一）

**選項 1**: 複製 Dropbox 資料夾（推薦，最快）

```bash
# 將共享的 Dropbox 資料夾複製到本機非雲端位置
cp -r "/path/to/shared/Dropbox/PROJECT_NAME" ~/Projects/PROJECT_NAME
cd ~/Projects/PROJECT_NAME

# 驗證 Git remote
git remote -v

# 取得最新程式碼
git pull
```

**選項 2**: Git clone + 下載數據

```bash
cd ~/Projects
git clone <PROJECT_GIT_URL> PROJECT_NAME
cd PROJECT_NAME

# 從 Dropbox 下載數據資料夾
# - data/local_data/
# - data/app_data/
```

#### 2. 環境變數設定

```bash
cp .env.template .env
# 編輯 .env，填入：
# - PGHOST, PGPORT, PGUSER, PGPASSWORD (PostgreSQL)
# - OPENAI_API_KEY
# - 其他專案特定的 API 金鑰
```

#### 3. 驗證設定

```bash
# 測試資料庫連線
Rscript scripts/global_scripts/98_test/test_database.R

# 啟動應用
Rscript app.R
```

#### 4. 部署到 Posit Connect

```bash
# 確保有 Posit Connect 帳號和 Publisher 權限
Rscript scripts/global_scripts/23_deployment/deploy_now.R
```

---

## 數據更新

| 更新類型 | 方式 |
|---------|------|
| 程式碼更新 | `git pull` |
| 數據更新 | 從 Dropbox 複製最新的 `data/` 資料夾 |

---

## Git 工作流程（方案 B）

```bash
# 1. 創建功能分支
git checkout -b feature/your-feature-name

# 2. 開發並提交
git add .
git commit -m "描述您的變更"

# 3. 推送並創建 Pull Request
git push -u origin feature/your-feature-name
# 然後在 GitHub 創建 Pull Request

# 4. 合併後清理
git checkout main
git pull
git branch -d feature/your-feature-name
```

---

## 注意事項

1. **絕對不要**在雲端同步資料夾（Dropbox/iCloud/OneDrive）中進行 Git 操作
2. 大型數據檔案 (`*.duckdb`, `data/local_data/`) 已在 `.gitignore` 中排除
3. 如需數據，請從 Dropbox 取得或執行 ETL 管線生成
4. 環境變數 (`.env`) 不會被追蹤，請勿提交敏感資訊

---

## 問題排解

### Git remote 不正確

```bash
git remote set-url origin <CORRECT_GIT_URL>
```

### 無法連接資料庫

1. 確認 `.env` 中的連線資訊正確
2. 確認網路可以連接到資料庫伺服器
3. 執行 `Rscript scripts/global_scripts/98_test/test_database.R` 診斷

### 缺少數據檔案

從 Dropbox 複製 `data/local_data/` 和 `data/app_data/` 資料夾，或執行 ETL 管線：

```bash
cd scripts/update_scripts
make run  # 需要 API 連線資訊
```

---

## 相關原則

- **SO_P016**: Configuration Scope Hierarchy（本文件位於 Universal scope）
- **MP122**: Quad-Track Shared Symlink Architecture
