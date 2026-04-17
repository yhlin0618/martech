# Supabase Auth System

此文件夾包含 Sandbox Apps 從 bcrypt 遷移到 Supabase REST API 登入系統的相關文件。

## 架構概覽

```
┌─────────────────────────────────────────────────────────────┐
│                   SANDBOX AUTH SYSTEM                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐                                          │
│  │   Portal     │    （不需登入）                           │
│  │   (Vercel)   │    - 只做 round-robin 分配               │
│  │              │    - 計數器邏輯不變                       │
│  └──────┬───────┘                                          │
│         │                                                   │
│         │ 跳轉                                              │
│         ▼                                                   │
│  ┌──────────────┐    ┌──────────────────────────────────┐  │
│  │ Shiny Apps   │    │        Supabase                   │  │
│  │              │    │  ┌─────────────────────────────┐  │  │
│  │ ┌──────────┐ │    │  │ REST API                    │  │  │
│  │ │ 登入頁面  │─┼────│  │  - 密碼驗證 (verify_password)│  │  │
│  │ └──────────┘ │    │  │  - 登入限制檢查              │  │  │
│  │              │    │  └─────────────────────────────┘  │  │
│  │ - BrandEdge  │    │                                    │  │
│  │ - InsightF.  │    │  ┌─────────────────────────────┐  │  │
│  │ - TagPilot   │    │  │ Database (PostgreSQL)       │  │  │
│  │ - VitalSigns │    │  │  - users (用戶 + 密碼雜湊)   │  │  │
│  └──────────────┘    │  │  - login_limits (登入限制)   │  │  │
│                      │  └─────────────────────────────┘  │  │
│                      └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 文件清單

| 文件 | 說明 |
|------|------|
| `README.md` | 本文件 - 系統概覽 |
| `setup_guide.md` | 環境設定指南 |
| `migration_plan.md` | 完整遷移計劃（從 Plan Mode） |
| `troubleshooting.md` | 常見問題排解 |

## 相關程式碼

### Supabase 模組位置

```
sandbox_test/modules/supabase/
├── module_supabase_auth.R      # Supabase API 呼叫函數
└── module_login_supabase.R     # 登入 UI 模組
```

### 環境變數

```bash
# Posit Connect Variable Set 需設定：
SUPABASE_URL=https://oziernubrqgqthjksbii.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# 本地開發在 env/{app}/.env
```

## 測試帳號

| 帳號 | 密碼 | 權限 |
|------|------|------|
| admin | 12345 | 管理員（無登入次數限制） |

## 部署方式

使用 Claude Code slash command：

```
/sandbox-deploy
```

或參考 `~/.claude/skills/sandbox-deploy/SKILL.md`

## 相關連結

- [Supabase Dashboard](https://supabase.com/dashboard/project/oziernubrqgqthjksbii)
- [Portal](https://ai-martech.vercel.app)
- [Posit Connect Cloud](https://connect.posit.cloud/)
