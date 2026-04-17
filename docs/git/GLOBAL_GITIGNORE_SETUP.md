# 全域 Git 忽略規則設定

## ✅ 已完成設定

我已經為您設定了全域的 Git 忽略規則，讓所有的 Git 專案都會自動忽略敏感檔案。

### 設定內容

**檔案位置**：`~/.gitignore_global`

**已加入的忽略規則**：

#### 環境變數檔案
- `.env` 和所有 `.env.*` 變體
- `.Renviron` 和所有 `.Renviron.*` 變體

#### R 相關敏感檔案
- `.Rprofile`
- `.httr-oauth`

#### 其他敏感檔案
- 包含 `secret`、`private` 的檔案
- `.pem`、`.key` 憑證檔案
- `credentials`、`secrets` 檔案
- API key 相關檔案
- 資料庫配置檔案

## 🔍 檢查設定

查看全域 gitignore 設定：
```bash
git config --global core.excludesfile
```

查看全域 gitignore 內容：
```bash
cat ~/.gitignore_global
```

測試檔案是否被忽略：
```bash
git check-ignore .env
git check-ignore .Renviron
```

## 📝 修改設定

如需新增或修改規則：
```bash
# 編輯全域 gitignore
nano ~/.gitignore_global
# 或
vim ~/.gitignore_global
```

## ⚠️ 重要提醒

1. **全域規則會套用到所有 Git 專案**
   - 不需要在每個專案都設定
   - 個別專案的 `.gitignore` 仍然有效

2. **安全最佳實踐**
   - 永遠不要將密碼、API Key 提交到 Git
   - 即使設定了 gitignore，也要小心不要強制提交（`git add -f`）

3. **團隊協作**
   - 全域 gitignore 只影響您的電腦
   - 團隊共用的忽略規則應放在專案的 `.gitignore`

## 🔐 額外安全建議

1. **使用 git-secrets**
   ```bash
   # 安裝 git-secrets（macOS）
   brew install git-secrets
   
   # 設定防止提交 AWS 憑證
   git secrets --install
   git secrets --register-aws
   ```

2. **定期檢查**
   ```bash
   # 檢查是否有敏感檔案被追蹤
   git ls-files | grep -E "(\.env|\.Renviron|secret|password|key)"
   ```

3. **如果不小心提交了敏感資訊**
   - 立即更換密碼/API Key
   - 使用 `git filter-branch` 或 `BFG Repo-Cleaner` 清除歷史記錄
   - 考慮將 repository 設為私有

---
設定完成時間：2024-01-15 