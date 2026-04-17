# AI MarTech 項目文檔

本目錄包含 AI MarTech 項目的所有業務文檔和技術指南。

## 文檔結構

### /configuration - 配置指南
應用程式命名、資料檔案最佳實踐、資料庫設置等。

### /contract - 合約
產學合作契約等法律文件。

### /deployment - 部署文檔
部署架構、指南、Posit Connect 設定等。

### /documentations - 產品與架構文件
- 應用程式結構標準
- 資料管理規範
- 產品層級說明 (L1~L4)
- 架構筆記

### /git - Git 管理
- Git 備份策略、同步指南、工作流程
- Git Subrepo 架構（Company-Agnostic 設計模式）
- Submodule vs Subrepo 比較

### /manual - 使用手冊
產品操作手冊。

### /presentations - 簡報資料
專案相關簡報和演示文稿。

### /records - 會議與對話記錄
- 會議逐字稿 (.srt)，檔名格式：`YYYYMMDD_主題-transcript.srt`
- 歸檔音檔在 `archived/`
- LINE 對話記錄

### /suggestion - 客戶建議
按公司分類（MAMBA/、QEF/）的客戶建議文件。

## 共享資源（iCloud）

| 類型 | 名稱 | 來源 | 用途 |
|------|------|------|------|
| 行事曆 | ai行銷 | iCloud | 專案會議、里程碑等時程 |
| 提醒事項 | ai行銷 | iCloud | 專案待辦事項 |

## 快速導航

- **新手入門**: `git/GIT_STRUCTURE_OVERVIEW.md`
- **部署應用**: `deployment/DEPLOYMENT_GUIDE.md`
- **配置資料庫**: `configuration/POSTGRESQL_SETUP.md`
- **Git 操作**: `git/GIT_SYNC_GUIDE.md`
- **產品架構**: `documentations/APP_STRUCTURE_STANDARD.md`

## 文檔維護原則

1. 所有新文檔應放置在適當的子目錄中，根目錄只保留 README.md
2. 文檔命名使用大寫字母和下劃線（如：`NEW_FEATURE_GUIDE.md`）
3. 會議記錄檔名統一為 `YYYYMMDD_主題-transcript.srt`
