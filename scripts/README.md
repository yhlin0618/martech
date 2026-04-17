# AI MarTech Scripts & Documentation

此資料夾是 AI MarTech 平台的腳本與文件中心。

## 目錄結構

### 目前結構

```
ai_martech/
├── scripts/                    # 📁 腳本與文件中心（本資料夾）
│   └── docs/                   # 技術文件
│       └── supabase_auth/      # Supabase 登入系統文件
├── global_scripts/             # 📁 共用程式碼（目前為 sibling）
│   ├── 00_principles/          # 257+ 開發原則
│   ├── 01_db/                  # 資料庫連線
│   ├── 02_db_utils/            # 資料庫工具
│   └── ...                     # 其他模組
├── bash/                       # Shell 腳本
└── docs/                       # 產品文件
```

### 規劃結構（未來）

```
ai_martech/
└── scripts/                    # 📁 所有腳本與共用程式碼
    ├── global_scripts/         # 共用程式碼（移入）
    ├── docs/                   # 技術文件
    └── ...                     # 其他腳本資料夾
```

> ⚠️ **注意**：將 `global_scripts/` 移入 `scripts/` 需要更新：
> - GitHub subrepo 配置
> - 各 App 的 symlinks
> - CLAUDE.md 路徑引用
> - 待規劃完整遷移方案

## 目前內容

| 資料夾 | 用途 |
|--------|------|
| `docs/supabase_auth/` | Supabase 登入系統文件 |

## 相關資源（目前為 sibling 資料夾）

| 資源 | 位置 | 說明 |
|------|------|------|
| **共用程式碼** | `../global_scripts/` | 所有 App 共用的 R 函數和模組 |
| **開發原則** | `../global_scripts/00_principles/` | 257+ 開發原則與規範 |
| **部署腳本** | `../bash/` | Shell 腳本（同步、部署、檢查） |
| **產品文件** | `../docs/` | 使用者文件和 API 文件 |

## Claude Code 整合

### Slash Commands

| 命令 | 說明 |
|------|------|
| `/sandbox-deploy` | 自動部署 Sandbox Apps 到 Posit Connect |

### Skills 位置

```
~/.claude/skills/
├── sandbox-deploy/     # Sandbox 部署自動化
├── agent-browser/      # 瀏覽器自動化
└── ...
```

## 文件索引

### Supabase Auth System

Sandbox Apps 的登入系統已從 bcrypt 遷移到 Supabase REST API。

- **文件位置**: `docs/supabase_auth/`
- **相關程式碼**: `l3_premium/sandbox/sandbox_test/modules/supabase/`
- **環境變數**: 需在 Posit Connect Variable Set 設定 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`

---

最後更新：2025-01-19
