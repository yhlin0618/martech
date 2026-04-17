# 部署到 Posit Connect Cloud

> **受眾**:工讀生、新人、久久 deploy 一次忘記流程的人
>
> **技術細節**:如果你想知道「為什麼是這樣」,見 `shared/global_scripts/00_principles/docs/en/part1_principles/CH00_fundamental_principles/02_structure_organization/MP122_penta_track_subrepo_architecture.qmd` 的 Section 14。這份文件只講「怎麼做」。

## 核心觀念:每個公司有兩個 repo

為什麼?因為 **Posit Connect Cloud 無法解析 symlink**。我們的開發架構用 symlink 共享 `global_scripts/`(跨公司複用),但 Posit Connect 從 GitHub clone 下來後,symlink 會變成死 link,app 啟動失敗。

解法:**一個給人改 code,一個給 Posit Connect 讀**。

| Repo | 用途 | 你改哪個 |
|------|------|---------|
| **dev repo** (例如 `ai_martech_l4_MAMBA`) | 日常開發、寫 code、commit 新功能 | **這個** |
| **deploy repo** (例如 `ai_martech_l4_MAMBA_deploy`) | 給 Posit Connect 讀的實檔版本 | **不要手改** — 由 `make deploy-sync` 自動產生 |

## Deploy repo 在哪?

在 dev repo 的子目錄:

```
MAMBA/                             ← dev repo
├── app.R
├── scripts/
│   └── global_scripts -> ../../shared/global_scripts  ← 這是 symlink
└── deployment/
    └── mamba-enterprise/          ← ✨ deploy repo 的本地 clone
        ├── app.R                  ← 實檔(rsync 過來)
        ├── scripts/
        │   └── global_scripts/    ← 3,000+ 個實檔(不是 symlink)
        └── .git/                  ← 獨立 git repo
```

`deployment/mamba-enterprise/` 有自己的 `.git`,是獨立的 git repo,remote 指向 `ai_martech_l4_MAMBA_deploy`。它是一個**本地 clone**,你看得到、進得去、跑 `git log` 等都可以。

你不會手動改它的內容 — 每次 `make deploy-sync` 都會用 `rsync -avL --delete` 從 dev repo 完整覆蓋過去。

## 資料流

```
你寫 code
   ↓
MAMBA/ (dev repo,含 symlinks)
   ↓  make deploy-sync  (rsync -avL 解析 symlink)
MAMBA/deployment/mamba-enterprise/ (deploy repo,實檔)
   ↓  make deploy-push  (git commit + push)
kiki830621/ai_martech_l4_MAMBA_deploy (GitHub)
   ↓  webhook
Posit Connect Cloud (自動重新部署)
```

## 日常部署三步驟

在公司專案根目錄(例如 `MAMBA/`)下執行:

```bash
# 1. 同步 dev → deploy(rsync -avL,解析 symlinks 為實檔)
make deploy-sync

# 2. 看改了什麼(檢查不會誤刪 production code)
make deploy-diff

# 3. Commit + push → 自動觸發 Posit Connect 部署
make deploy-push
```

Step 2 的 `deploy-diff` 很重要 — 看到大量 `.R` 檔被刪就要停下來,大量 `.qmd`(文件)被刪是正常的(refactor 產物)。

## 首次設定 checklist

如果這個專案還沒有 deploy repo:

- [ ] 確認 GitHub 上有 `ai_martech_{tier}_{COMPANY}_deploy` repo(若沒有,去 GitHub 建立一個 private repo)
- [ ] 在專案根目錄跑 `make deploy-init`(會建立 `deployment/{app_name}/` 目錄、初始化 git、加 remote)
- [ ] 跑一次 `make deploy-sync` + `make deploy-push`(初始化內容)
- [ ] 在 Posit Connect Cloud 的 New Content,選 GitHub source 指向 **deploy repo**(不是 dev repo!)
- [ ] 設定 env vars(`PGHOST`, `OPENAI_API_KEY` 等,見 `.env.template`)
- [ ] Deploy 並驗證可連線

## 常見問題

### Q:客戶說 MAMBA 連不上,我要怎麼 debug?

1. **先確認 Posit Connect 的 source repo 是 deploy repo**,不是 dev repo。
   - 去 Posit Connect portal → Content → mamba-enterprise → Settings → GitHub
   - Source 必須是 `ai_martech_l4_MAMBA_deploy`
   - 如果是 dev repo(`ai_martech_l4_MAMBA`),改成 deploy repo。這是 80% 連不上問題的原因 — symlink 在 Posit Connect 是死 link。

2. **跑 `make deploy-sync` + `make deploy-diff`** 看 dev 跟 deploy 是否有 drift。久沒 sync 時 diff 會非常大。

3. **跑 `make deploy-push`** push 最新版到 deploy repo 觸發自動部署。

4. 如果還是不行,去 Posit Connect 看 app 的 log(Content → mamba-enterprise → Logs)。

### Q:我改了 dev repo 的 code,Posit Connect 會自動更新嗎?

**不會。** 你必須跑:

```bash
make deploy-sync    # 同步 dev → deploy
make deploy-push    # 推 deploy repo,Posit Connect webhook 觸發
```

dev repo 只是 source of truth,Posit Connect 不看它。

### Q:deploy repo 被我不小心改到了怎麼辦?

放心,`make deploy-sync` 用 `rsync -avL --delete`,會直接覆蓋 deploy repo 為 dev repo 的內容。你本地的改動會被覆蓋。

### Q:為什麼 `make deploy-diff` 顯示很多 `.qmd` 被刪?

這通常是正常的。`.qmd` 是 Quarto 文件(原則系統的說明),不影響 app runtime。因為原則系統會被 refactor,dev repo 的文件結構改變時,`rsync --delete` 會把 deploy repo 的舊文件清掉。

**只有 `.R` 檔被刪才要警覺**。

### Q:我可以同時改 dev repo 和 deploy repo 嗎?

**不行。** Deploy repo 是 derived artifact(衍生產物),手改會在下次 `deploy-sync` 被覆蓋。所有改動都在 dev repo 做。

## 命名規則

| Tier | Dev repo | Deploy repo |
|------|---------|-------------|
| L1 Basic | `ai_martech_l1_{APP}` | `ai_martech_l1_{APP}_deploy` |
| L4 Enterprise | `ai_martech_l4_{COMPANY}` | `ai_martech_l4_{COMPANY}_deploy` |

例如:
- dev: `ai_martech_l4_QEF_DESIGN`
- deploy: `ai_martech_l4_QEF_DESIGN_deploy`

## 相關原則

如果你想深入理解:

- **MP122** Penta-Track Subrepo Architecture Section 14 — 架構原因和正式規範
- **TD_P001** Deployment Patterns — 部署 pattern 總覽
- **TD_R006** Deployment Driver Orchestration — deploy-sync / deploy-push 的規範
- **DEV_R040** No Symlinks in Deployable — 為何 deploy 目錄禁止 symlink
