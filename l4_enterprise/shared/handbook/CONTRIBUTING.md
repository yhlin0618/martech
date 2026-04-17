# 如何貢獻 handbook

> 這份 CONTRIBUTING 本身就是 handbook 的第一篇內容 — 用 handbook 的方式教你參與 handbook。

## 你需要什麼才能開始

- GitHub 帳號(請團隊加你到本 repo 的 collaborator)
- 本機有 `git`
- 本機有 `gh`(GitHub CLI)
- 能登入 GitHub:`gh auth login`

## 最簡版工作流程

```bash
# 1. 從 handbook repo 直接 clone(不需要 clone 整個 l4_enterprise)
git clone git@github.com:kiki830621/ai_martech_handbook.git
cd ai_martech_handbook

# 2. 建立新 branch
git checkout -b fix-typo-in-readme

# 3. 編輯 markdown 檔案
# 用你熟悉的編輯器打開需要改的檔案

# 4. 確認改動
git status
git diff

# 5. Commit
git add <file>
git commit -m "docs: fix typo in README"

# 6. Push
git push -u origin fix-typo-in-readme

# 7. 開 PR
gh pr create --title "Fix typo in README" --body "修了 README 裡的拼字錯誤"
```

## Commit message 格式

| Prefix | 用在什麼情境 |
|--------|--------------|
| `docs:` | 改 markdown 文件內容(最常用) |
| `fix:` | 修正錯誤資訊(公式寫錯、步驟缺漏等) |
| `feat:` | 新增一份完整的 guide(新增整個 `.md` 檔案) |
| `refactor:` | 改組織結構但內容不變(例如把一個 section 拆成兩個) |

## 常見的第一個任務(good first tasks)

- 修 typo
- 把不清楚的句子改清楚
- 補上缺漏的 example
- 新增你剛遇到問題又解決的 debug 流程
- 把你從同事那邊學到的「小技巧」寫成一篇文件

**不要做**:

- 新增整個 framework 的技術說明 — 那屬於 principles 文件系統
- 改動檔案結構 — 先跟你的 mentor 討論
- 複製 MP/P/R 原則的內容到 handbook — 直接 link 就好

## 與 l4_enterprise 的關係

本 handbook 在 l4_enterprise 裡是 **git submodule**,路徑 `shared/handbook/`。如果你從 l4_enterprise 端 clone,用:

```bash
git clone --recurse-submodules git@github.com:kiki830621/l4_enterprise.git
```

已經 clone 但忘記 `--recurse-submodules`,可以補拉:

```bash
cd l4_enterprise
git submodule update --init --recursive
```

更新 submodule 到最新版:

```bash
cd l4_enterprise
git submodule update --remote shared/handbook
```

## 更完整的教學會放在哪裡

這份 CONTRIBUTING 是 stub(起點)。完整的 git workflow、commit 習慣、PR review 流程、如何處理 merge conflict 等,會由後續的 follow-up PRs 補到 [`workflows/`](./workflows/) 目錄。
