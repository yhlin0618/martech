# Git 結構總覽

## 🎯 關鍵概念

本專案使用了**三層嵌套**的 Git 結構：

1. **第一層**：主倉庫 (ai_martech)
2. **第二層**：應用程式 (positioning_app, VitalSigns, InsightForge)
3. **第三層**：應用程式內的 global_scripts

## 📊 視覺化結構圖

```
┌─────────────────────────────────────────────────────────────┐
│                     ai_martech (主倉庫)                      │
│                                                             │
│  ┌─────────────────────────┐                               │
│  │ global_scripts           │ ← Git Submodule              │
│  │ (共享腳本庫)              │   指向 precision_marketing_  │
│  │                         │   global_scripts              │
│  └─────────────────────────┘                               │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    l1_basic/                         │   │
│  │                                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐          │   │
│  │  │ positioning_app │  │ VitalSigns      │          │   │
│  │  │ (Git Subrepo)   │  │ (Git Subrepo)   │          │   │
│  │  │                 │  │                 │          │   │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │          │   │
│  │  │ │global_scripts│ │  │ │global_scripts│ │          │   │
│  │  │ │(Git Subrepo) │ │  │ │(Git Subrepo) │ │          │   │
│  │  │ └─────────────┘ │  │ └─────────────┘ │          │   │
│  │  └─────────────────┘  └─────────────────┘          │   │
│  │                                                      │   │
│  │  ┌─────────────────┐                                │   │
│  │  │ InsightForge    │                                │   │
│  │  │ (Git Subrepo)   │                                │   │
│  │  │                 │                                │   │
│  │  │ ┌─────────────┐ │                                │   │
│  │  │ │global_scripts│ │                                │   │
│  │  │ │(Git Subrepo) │ │                                │   │
│  │  │ └─────────────┘ │                                │   │
│  │  └─────────────────┘                                │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 同步關係

```
precision_marketing_global_scripts (GitHub)
           ↑
           ├──── [Submodule] ──→ ai_martech/global_scripts/
           │
           ├──── [Subrepo] ───→ positioning_app/scripts/global_scripts/
           │
           ├──── [Subrepo] ───→ VitalSigns/scripts/global_scripts/
           │
           └──── [Subrepo] ───→ InsightForge/scripts/global_scripts/
```

## 📝 重要說明

### 為什麼有兩種 global_scripts？

1. **主倉庫的 global_scripts (Submodule)**：
   - 用於開發和測試新功能
   - 直接連結到 GitHub repository
   - 更新會立即反映在主倉庫

2. **應用程式內的 global_scripts (Subrepo)**：
   - 確保應用程式的獨立性
   - 應用程式可以獨立部署
   - 版本控制更加穩定

### 同步順序的重要性

```bash
1. 主倉庫 (ai_martech)
   ↓
2. global_scripts (Submodule)
   ↓
3. 應用程式 (Subrepo: positioning_app, VitalSigns, InsightForge)
   ↓
4. 應用程式內的 global_scripts (Subrepo)
```

### 檔案識別

| 路徑 | Git 類型 | 識別檔案 |
|------|---------|----------|
| `/global_scripts/` | Submodule | `.git` (檔案) |
| `/l1_basic/positioning_app/` | Subrepo | `.gitrepo` |
| `/l1_basic/positioning_app/scripts/global_scripts/` | Subrepo | `.gitrepo` |

## 🛠️ 管理命令

### 檢查所有 Git 結構
```bash
# 查看所有 subrepo
find . -name ".gitrepo" -type f | sort

# 查看 submodule 狀態
git submodule status

# 查看 subrepo 狀態
git subrepo status --all
```

### 同步所有倉庫
```bash
# 使用自動化腳本（推薦）
./sync_all_repos.sh

# 或快速同步
./quick_sync_all.sh
```

### 單獨更新特定部分
```bash
# 更新主倉庫的 global_scripts
git submodule update --remote global_scripts

# 更新特定應用程式
git subrepo pull l1_basic/positioning_app

# 更新應用程式內的 global_scripts
git subrepo pull l1_basic/positioning_app/scripts/global_scripts
```

## 📌 最佳實踐

1. **定期同步**：使用 `sync_all_repos.sh` 確保所有部分都是最新的
2. **提交順序**：先提交應用程式內的變更，再同步到主倉庫
3. **版本一致性**：盡量保持所有 global_scripts 版本一致
4. **獨立測試**：每個應用程式應該能獨立運行和部署 