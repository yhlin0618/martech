# Git 對 JSON/CSV 檔案的處理策略

## 現況問題

目前 `.gitignore` 排除了所有 `*.json` 和 `*.csv` 檔案，造成：
- 需要為 `manifest.json` 等重要檔案設定例外
- 範例資料、測試資料無法輕易分享
- 配置檔案需要特別處理
- 增加開發複雜度

## 建議策略

### 方案 A：完全不排除（推薦）
**不在 .gitignore 中排除 JSON/CSV**

優點：
- ✅ 開發流程簡單
- ✅ 範例資料可以直接提交
- ✅ 配置檔案容易管理
- ✅ 不需要記住例外規則

缺點：
- ⚠️ 需要開發者自行注意不要提交敏感資料
- ⚠️ 可能不小心提交大型資料檔案

### 方案 B：選擇性排除
**只排除特定目錄的 JSON/CSV**

```gitignore
# 排除特定目錄的資料檔案
data/raw/*.csv
data/raw/*.json
cache/*.json
temp/*.csv

# 但不排除其他位置的 JSON/CSV
```

### 方案 C：排除大檔案
**基於檔案大小而非類型**

使用 Git LFS 或設定大小限制：
```gitignore
# 使用 git-lfs 追蹤大型檔案
*.csv filter=lfs diff=lfs merge=lfs -text
*.json filter=lfs diff=lfs merge=lfs -text
```

## 安全考量

如果選擇不排除 JSON/CSV，建議：

1. **敏感資料命名規範**
   ```
   *secret*.json
   *private*.csv
   *credentials*.json
   *.env.json
   ```

2. **資料目錄結構**
   ```
   project/
   ├── data/
   │   ├── sample/     # 可提交的範例資料
   │   ├── raw/        # 不提交的原始資料
   │   └── private/    # 不提交的敏感資料
   ```

3. **Pre-commit 檢查**
   - 檢查檔案大小
   - 掃描敏感關鍵字
   - 確認不包含 API keys

## 實施建議

1. 移除全域的 `*.json` 和 `*.csv` 排除規則
2. 只排除明確的敏感檔案模式
3. 使用目錄結構來區分可提交和不可提交的資料
4. 加入 README 說明資料管理政策 