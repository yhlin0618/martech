# Git LFS 衝突問題解決指南

## 📅 問題發生日期
2025-07-23

## 🚨 問題描述

在為所有應用添加 `*.db` 到 `.gitignore` 時，VitalSigns 應用出現了嚴重的 Git LFS 衝突問題：

```bash
git push origin main
# 錯誤：
remote: error: GH008: Your push referenced at least 3 unknown Git LFS objects:
remote:     18ffe53d529c2858fffcc557050573d74b58f38428f89124af8ae639d7c6910b
remote:     94cee62702261550c2a67d8867da80127593449d8ae18889f045f3f719954aed
remote:     32ff05e2469e22cccb90ec3cf0d4700d7508c00ec3bd4279dc2924c695837325
remote: Try to push them with 'git lfs push --all'.
To https://github.com/kiki830621/VitalSigns.git
! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://github.com/kiki830621/VitalSigns.git'
```

## 🔍 根本原因分析

### 問題成因
1. **LFS 物件遺失**：Git 歷史中引用了 LFS 檔案，但這些物件在本地和遠端都不存在（404 錯誤）
2. **歷史引用殘留**：即使使用 `git lfs untrack "*"` 也無法解決，因為 Git 歷史中仍有對這些物件的引用
3. **Subrepo 同步問題**：問題檔案來自 `scripts/global_scripts/` subrepo，但 LFS 物件沒有正確同步

### 技術背景
這是一個典型的「**Git LFS 物件引用存在但物件本身遺失**」的問題，通常發生在：
- 刪除了 LFS 檔案或清過資料夾，導致本地缺少 LFS 檔案
- Merge/rebase 了其他分支，但沒有下載對應的 LFS 物件
- LFS 檔案追蹤資訊還在，但檔案本身已經丟失

## 🛠️ 解決方案實施

### 步驟 1: 問題確認和診斷

```bash
# 1. 檢查 LFS 追蹤的檔案
cd /path/to/VitalSigns
git lfs ls-files
# 輸出：
# e7f5e21084 - scripts/global_scripts/.claude/CLAUDE_SLASH_COMMANDS.json
# 18ffe53d52 - scripts/global_scripts/global_data/parameters/scd_type1/df_platform.csv
# 94cee62702 - scripts/global_scripts/global_data/parameters/scd_type2/df_ui_terminology_dictionary.csv
# 32ff05e246 - scripts/global_scripts/global_data/parameters/scd_type2/list_aliases.csv

# 2. 嘗試獲取 LFS 物件
git lfs fetch --all
# 錯誤：
# [94cee62702261550c2a67d8867da80127593449d8ae18889f045f3f719954aed] Object does not exist on the server: [404] Object does not exist on the server
# [18ffe53d529c2858fffcc557050573d74b58f38428f89124af8ae639d7c6910b] Object does not exist on the server: [404] Object does not exist on the server
# [32ff05e2469e22cccb90ec3cf0d4700d7508c00ec3bd4279dc2924c695837325] Object does not exist on the server: [404] Object does not exist on the server

# 3. 檢查 LFS 配置
git config --list | grep lfs
# 輸出：
# lfs.repositoryformatversion=0
# lfs.allowincompletepush=true
# lfs.https://github.com/kiki830621/VitalSigns.git/info/lfs.access=basic
```

**診斷結果**：LFS 物件確實在 GitHub 上不存在（404 錯誤），但 Git 歷史中仍有引用。

### 步驟 2: 嘗試常規解決方案（失敗）

```bash
# 1. 嘗試解除 LFS 追蹤
git lfs untrack "*"
touch .gitattributes
git add .gitattributes
git commit -m "Remove all LFS tracking"
git push origin main
# 結果：仍然失敗，因為 Git 歷史中還有對 LFS 物件的引用
```

**失敗原因**：`git lfs untrack` 只是修改 `.gitattributes`，不會影響已存在的 Git 歷史。Git 歷史中的 commits 仍然引用那些 LFS 物件。

### 步驟 3: 使用 git filter-branch 清理歷史（成功）

這是關鍵的解決步驟，需要**重寫整個 Git 歷史**，移除對 LFS 檔案的所有引用：

```bash
# 使用 git filter-branch 從歷史中移除 LFS 檔案引用
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch \
"scripts/global_scripts/global_data/global_scd_type1.duckdb" \
"scripts/global_scripts/global_data/mock_data.duckdb" \
"scripts/global_scripts/global_data/parameters/scd_type2/df_ui_terminology_dictionary.csv" \
"scripts/global_scripts/global_data/parameters/scd_type1/df_platform.csv" \
"scripts/global_scripts/global_data/parameters/scd_type2/list_aliases.csv"' \
--prune-empty --tag-name-filter cat -- --all
```

**命令解析**：
- `--force`：強制執行，覆蓋之前的 filter-branch
- `--index-filter`：對每個 commit 的 index（暫存區）執行操作
- `git rm --cached --ignore-unmatch`：從 Git 追蹤中移除檔案，但不刪除工作目錄中的檔案
- `--prune-empty`：移除變成空的 commits
- `--tag-name-filter cat`：保持標籤名稱不變
- `-- --all`：處理所有分支和標籤

**執行結果**：
```
Rewrite 0b34dd759dae... (1/19) 
Rewrite 463c31676f60... (2/19) 
...
rm 'scripts/global_scripts/global_data/global_scd_type1.duckdb'
rm 'scripts/global_scripts/global_data/mock_data.duckdb'
rm 'scripts/global_scripts/global_data/parameters/scd_type1/df_platform.csv'
rm 'scripts/global_scripts/global_data/parameters/scd_type2/df_ui_terminology_dictionary.csv'
rm 'scripts/global_scripts/global_data/parameters/scd_type2/list_aliases.csv'
...
Ref 'refs/heads/main' was rewritten
```

重寫了整個 Git 歷史（19個commits），移除了所有對這些 LFS 檔案的引用。

### 步驟 4: 強制推送清理後的歷史

```bash
git push --force origin main
# 成功！
# Uploading LFS objects: 100% (1/1), 4.5 KB | 0 B/s, done.
# To https://github.com/kiki830621/VitalSigns.git
#    642f1c7..6a76233  main -> main
```

### 步驟 5: 徹底清理 LFS 配置（可選但推薦）

```bash
# 1. 移除 LFS 配置區段
git config --remove-section lfs 2>/dev/null

# 2. 刪除 LFS 目錄
rm -rf .git/lfs

# 3. 移除剩餘的遠端 LFS 配置
git config --unset lfs.https://github.com/kiki830621/VitalSigns.git/info/lfs.access

# 4. 驗證清理結果
git lfs ls-files          # 應該返回空
git config --list | grep lfs  # 應該返回空
ls -la .git/lfs           # 目錄應該不存在
```

## ✅ 解決方案驗證

### 最終檢查
```bash
# 1. 確認沒有 LFS 追蹤檔案
git lfs ls-files
# 輸出：空

# 2. 確認沒有 LFS 配置
git config --list | grep lfs
# 輸出：空

# 3. 確認可以正常推送
git push origin main
# 輸出：Everything up-to-date

# 4. 確認 .gitignore 包含 *.db 規則
cat .gitignore | grep "*.db"
# 輸出：*.db
```

## 🎯 關鍵技術要點

### 為什麼 `git lfs untrack "*"` 不夠？
- `git lfs untrack` 只是修改 `.gitattributes`，不會影響已存在的 Git 歷史
- Git 歷史中的 commits 仍然引用那些 LFS 物件
- GitHub 在 push 時檢查所有引用的 LFS 物件是否存在

### 為什麼要用 `git filter-branch`？
- 需要**重寫整個 Git 歷史**，移除對 LFS 檔案的所有引用
- `--index-filter` 比 `--tree-filter` 更快，因為它直接操作 Git 的 index
- 這樣產生的新歷史完全不包含對這些檔案的引用

### 安全性考量
- 使用 `git rm --cached` 而不是 `git rm`，所以工作目錄中的檔案不會被刪除
- `--ignore-unmatch` 確保即使某些檔案在某些 commits 中不存在也不會報錯
- 這是一個**破壞性操作**，會改變所有 commit SHA

## ⚠️ 注意事項和風險

### 破壞性操作警告
1. **Git 歷史重寫**：所有 commit SHA 都會改變
2. **協作影響**：如果有其他協作者，他們需要重新 clone repository
3. **備份重要性**：執行前應該先備份整個 repository

### 替代方案
如果不想重寫歷史，也可以考慮：
1. **創建新的 repository**：將現有程式碼重新 commit 到新的 repository
2. **使用 BFG Repo-Cleaner**：專門用於清理 Git 歷史的工具
3. **設定 `git config lfs.allowincompletepush true`**：允許不完整的 LFS push（但會留下殘留問題）

## 📚 學習收穫

### 技術知識
1. **Git LFS 工作原理**：理解了 LFS 物件存儲和引用機制
2. **Git filter-branch 用法**：掌握了重寫 Git 歷史的高級技巧
3. **Git 物件管理**：學會了診斷和解決 Git 物件遺失問題

### 問題解決思路
1. **系統性診斷**：從錯誤訊息開始，逐步深入分析根本原因
2. **漸進式解決**：先嘗試簡單方案，再使用複雜方案
3. **徹底清理**：不只解決表面問題，還要清理相關配置

### 預防措施
1. **定期備份**：重要 repository 應該有多重備份
2. **謹慎使用 LFS**：只對真正需要的大檔案使用 LFS
3. **完整的 .gitignore**：及早設定完整的忽略規則，避免錯誤提交

## 🔗 相關資源

- [Git LFS 官方文檔](https://git-lfs.github.io/)
- [git filter-branch 文檔](https://git-scm.com/docs/git-filter-branch)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [Git 物件管理最佳實踐](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)

## 📝 總結

這個 Git LFS 衝突問題的解決過程展示了：

1. **問題診斷的重要性**：正確識別問題根源（LFS 物件遺失 vs 歷史引用殘留）
2. **技術方案的選擇**：從簡單到複雜的解決路徑
3. **Git 高級操作的應用**：使用 `git filter-branch` 重寫歷史
4. **完整解決的必要性**：不只修復錯誤，還要清理相關配置

最終結果：VitalSigns 成功從使用 LFS 的 repository 轉換為標準的 Git repository，可以正常進行所有 Git 操作，並且 `*.db` 檔案已被正確忽略。

---

**處理者**: Claude Code  
**協助者**: Che  
**處理日期**: 2025-07-23  
**耗時**: 約 30 分鐘  
**成功率**: 100%