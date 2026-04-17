# Git Submodule vs Subrepo 說明

## 問題說明

在執行 `sync_all_repos.sh` 時出現警告：
```
⚠️ global_scripts 不是獨立的 git repository
```

## 原因

這是因為腳本原本使用 `[ -d "global_scripts/.git" ]` 來檢查，期望 `.git` 是一個目錄。

但對於 Git submodule：
- `.git` 是一個**檔案**，不是目錄
- 內容指向主倉庫的 `.git/modules/` 子目錄

## Git Submodule vs Subrepo

### Git Submodule (global_scripts)
```bash
# .git 是檔案
$ cat global_scripts/.git
gitdir: ../.git/modules/global_scripts

# 實際的 git 資料存在主倉庫中
$ ls .git/modules/global_scripts/
HEAD  config  description  hooks  info  logs  objects  refs
```

### Git Subrepo (l1_basic/positioning_app 等)
```bash
# 有 .gitrepo 檔案記錄設定
$ cat l1_basic/positioning_app/.gitrepo
[subrepo]
  remote = git@github.com:kiki830621/positioning_app.git
  branch = main
  commit = ...
```

## 修正方法

已將檢查從 `-d` (目錄) 改為 `-e` (存在)：
```bash
# 舊版（錯誤）
if [ -d "global_scripts/.git" ]; then

# 新版（正確）
if [ -e "global_scripts/.git" ]; then
```

## 專案中的 Git 結構

```
ai_martech/                    # 主倉庫
├── .git/                      # 主倉庫的 git 資料
├── global_scripts/            # Git Submodule
│   └── .git                   # 檔案，指向 ../.git/modules/global_scripts
└── l1_basic/
    ├── positioning_app/       # Git Subrepo
    │   └── .gitrepo          # Subrepo 設定檔
    ├── VitalSigns/           # Git Subrepo
    │   └── .gitrepo
    └── InsightForge/         # Git Subrepo
        └── .gitrepo
```

現在 `sync_all_repos.sh` 可以正確處理這兩種不同的 Git 管理方式了！ 