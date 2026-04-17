# Positioning App 資料管理

## 🔒 重要安全更新 (2024-06-27)

本專案已實施「**零資料**」版本控制策略：
- ❌ GitHub 上**不包含任何資料檔案**
- ✅ 所有資料需在本地生成或另外獲取
- 🛡️ 確保資料安全和隱私保護

## 快速設置

首次使用請執行：
```bash
Rscript setup_local_data.R
```

這會為你創建完整的測試環境。

## 資料目錄結構

```
positioning_app/
├── data/                    # 所有資料檔案（不納入版控）
│   ├── sample/             # 範例資料
│   ├── test/               # 測試資料
│   └── user/               # 使用者上傳資料
├── database/               # 資料庫檔案（不納入版控）
└── cache/                  # 暫存檔案
```

## 資料檔案說明

### 預期的資料檔案（需自行生成或獲取）

1. **database/users.sqlite**
   - 使用者認證資料庫
   - 執行 `setup_local_data.R` 自動創建

2. **data/sample/amazon_can_opener_reviews.xlsx**
   - 範例評論資料
   - 執行 `setup_local_data.R` 生成假資料

3. **data/test/fake_data.xlsx**
   - 測試用資料
   - 執行 `setup_local_data.R` 生成假資料

## 程式碼更新指引

確保你的程式碼使用正確的路徑：

```r
# ✅ 正確的路徑
data <- readxl::read_excel("data/sample/amazon_can_opener_reviews.xlsx")
con <- dbConnect(SQLite(), "database/users.sqlite")

# ❌ 舊的路徑（不要使用）
data <- readxl::read_excel("亞馬遜電動開罐器顧客評論.xlsx")
con <- dbConnect(SQLite(), "users.sqlite")
```

## Git Subrepo 管理

此專案使用 git-subrepo 管理，可以雙向同步：
- 拉取上游更新：`git subrepo pull l1_basic/positioning_app`
- 推送本地修改：`git subrepo push l1_basic/positioning_app`

⚠️ **注意**：推送時不會包含任何資料檔案，這是刻意的安全設計。

## 真實資料獲取

如需真實資料：
1. 聯繫專案管理員獲取安全下載連結
2. 使用提供的 API 金鑰存取資料
3. 從授權的資料源匯入

## 故障排除

### 找不到資料檔案？
執行 `Rscript setup_local_data.R` 創建測試環境

### 需要真實資料？
聯繫專案管理員或查看內部文件

### 資料太大無法處理？
考慮使用資料取樣或串流處理 