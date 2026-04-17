# Git 同步工具指南

我已經為您創建了兩個腳本來同步所有的 Git repositories（包括 submodule 和 subrepo）。

## 🛠 同步腳本

### 1. **sync_all_repos.sh**（互動式）
- 詳細顯示每個步驟
- 詢問是否提交變更
- 允許自訂 commit 訊息
- 適合需要仔細控制的情況

### 2. **quick_sync_all.sh**（快速版）
- 自動提交所有變更
- 使用預設 commit 訊息
- 不需要互動
- 適合日常快速同步

## 📦 倉庫結構

您的專案包含：
- **主倉庫**：ai_martech
- **Submodule**：global_scripts
- **Subrepo**：
  - l1_basic/positioning_app
  - l1_basic/VitalSigns
  - l1_basic/InsightForge

## 🚀 使用方法

### 方式 1：互動式同步
```bash
./sync_all_repos.sh
```
腳本會：
1. 檢查每個倉庫的狀態
2. 詢問是否提交變更
3. 同步所有倉庫

### 方式 2：快速同步
```bash
./quick_sync_all.sh
```
腳本會：
1. 自動提交所有變更
2. 自動 pull 和 push
3. 不需要任何輸入

## 🔄 同步順序

1. **global_scripts** (submodule)
   - commit → pull → push

2. **Subrepo 應用程式**
   - git subrepo pull
   - git subrepo push

3. **主倉庫**
   - commit → pull → push

## ⚠️ 注意事項

1. **Git Subrepo**
   - subrepo 的變更會先推送到各自的遠端倉庫
   - 然後更新主倉庫的引用

2. **衝突處理**
   - 如果遇到衝突，腳本會停止
   - 需要手動解決衝突後重新執行

3. **權限**
   - 確保對所有遠端倉庫都有推送權限
   - GitHub SSH key 需要正確設定

## 🎯 建議工作流程

每日結束工作時：
```bash
# 快速同步所有變更
./quick_sync_all.sh
```

重要變更時：
```bash
# 使用互動式，仔細檢查每個步驟
./sync_all_repos.sh
```

---
創建時間：2024-01-15 