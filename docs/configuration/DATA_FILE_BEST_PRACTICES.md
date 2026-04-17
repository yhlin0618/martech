# 資料檔案管理最佳實踐

## 🎯 核心原則

1. **JSON 和 CSV 檔案現在可以提交到 Git**
2. **開發者需要自行判斷哪些檔案適合提交**
3. **使用目錄結構和命名規範來區分**

## 📁 建議的目錄結構

```
project/
├── data/
│   ├── sample/         # ✅ 可提交 - 範例資料
│   │   ├── users.csv
│   │   └── config.json
│   ├── test/          # ✅ 可提交 - 測試資料
│   │   └── test_data.csv
│   ├── raw/           # ❌ 不提交 - 原始資料
│   │   └── full_database.csv
│   └── private/       # ❌ 不提交 - 敏感資料
│       └── api_keys.json
├── config/
│   ├── settings.json  # ✅ 可提交 - 一般設定
│   └── secrets.json   # ❌ 不提交 - 敏感設定
└── app_data/          # ✅ 永遠提交 - 應用必需資料
    └── defaults.json
```

## 🚫 不應該提交的檔案

### 1. 敏感資料
- 包含 API keys、密碼、token 的檔案
- 個人資料（PII）
- 內部商業數據

### 2. 大型檔案
- 超過 10MB 的 CSV 檔案
- 完整的資料庫匯出
- 未經處理的原始資料

### 3. 自動產生的檔案
- 快取資料
- 暫存檔案
- 計算結果（除非是範例）

## ✅ 應該提交的檔案

### 1. 配置檔案
- `app_config.yaml`
- `settings.json`
- `manifest.json`

### 2. 範例資料
- 小型示範資料集
- 測試用資料
- 文檔中引用的資料

### 3. 模板檔案
- 資料格式範本
- 配置範本
- 輸入範例

## 🛡️ 安全檢查清單

提交前請確認：

- [ ] 檔案不包含真實的 API keys 或密碼
- [ ] 檔案不包含客戶個人資料
- [ ] CSV 檔案小於 10MB
- [ ] 檔案名稱不包含 `secret`、`private`、`credentials`

## 💡 實用技巧

### 1. 使用環境變數
```json
// ❌ 不好 - config.json
{
  "api_key": "sk-1234567890abcdef"
}

// ✅ 好 - config.json
{
  "api_key": "${OPENAI_API_KEY}"
}
```

### 2. 創建範例檔案
```bash
# 從真實資料創建範例
head -100 data/raw/users.csv > data/sample/users_sample.csv
```

### 3. 使用 .gitignore 排除特定檔案
```gitignore
# 如果有特定檔案不想提交
data/temp_analysis.csv
config/local_settings.json
```

## 📝 檔案命名建議

- ✅ `sample_data.csv` - 清楚標示為範例
- ✅ `test_users.json` - 清楚標示為測試
- ✅ `config_template.json` - 清楚標示為模板
- ❌ `production_data.csv` - 避免誤導
- ❌ `real_api_keys.json` - 避免敏感命名

## 🔍 提交前檢查

```bash
# 檢查大檔案
find . -name "*.csv" -size +10M

# 搜尋敏感關鍵字
grep -r "api_key\|password\|secret" --include="*.json" --include="*.csv"

# 列出將要提交的檔案
git status --porcelain | grep -E "\.(json|csv)$"
```

記住：**寧可謹慎，不要輕易提交敏感或大型資料檔案！** 