<!-- SPECTRA:START v1.0.1 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `/spectra:*` skills when:

- A discussion needs structure before coding → `/spectra:discuss`
- User wants to plan, propose, or design a change → `/spectra:propose`
- Tasks are ready to implement → `/spectra:apply`
- There's an in-progress change to continue → `/spectra:ingest`
- User asks about specs or how something works → `/spectra:ask`
- Implementation is done → `/spectra:archive`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra:apply` and `/spectra:ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# L4 Enterprise — CLAUDE.md

## KM Legacy Reference

**KM** 是 **kitchenMAMA** 的縮寫。舊版精準行銷專案（precision_marketing）保存在：

```
kitchenMAMA/archive/precision_marketing_KitchenMAMA/
```

開發新功能時，經常需要參考這個舊專案的實作。它包含許多尚未移植到現行 L4 架構的模組。

### 目錄結構

```
precision_marketing_KitchenMAMA/
├── precision_marketing_app/           # 單體式版本
│   └── survival_analysis_app/         # KM 生存分析子 App
├── precision_marketing_app_modular/   # 模組化版本（主要參考）
│   └── R/modules/macro/              # Macro 分析模組
├── commented_R/                       # 舊程式碼（含誤導檔名，見下方）
├── data/                              # 舊資料檔案
└── Documents/                         # 舊文件
```

### 關鍵參考檔案

| 檔案 | 用途 | 備註 |
|------|------|------|
| `precision_marketing_app_modular/R/modules/macro/macro_awakening_matrix.R` | NES 覺醒率轉換矩陣（heatmap） | 用 `activation_rate` 做 NES 狀態轉換，**最相關的參考** |
| `precision_marketing_app/survival_analysis_app/modules/survival_analysis_module.R` | 完整 KM + Cox PH 生存分析模組 | 862 行，含 `survfit()`, `coxph()`, `ggsurvplot()` |
| `commented_R/RScripts/deprecated/KM_hearchical_Bayesian_model.R` | brms 產品選擇模型 | **名稱誤導** — 不是 KM 生存分析，是 Bayesian 產品偏好模型 |

### 覺醒率矩陣 Pattern

```r
# 從 macro_awakening_matrix.R
transition_matrix <- nes_data %>%
  pivot_wider(names_from = nesstatus_now, values_from = activation_rate, values_fill = 0) %>%
  column_to_rownames(var = "nesstatus_pre")
desired_order <- c("N", "E0", "S1", "S2", "S3")
```

### 與現行系統的關係

- **BG/NBD P(alive)** 已部署（2026-03-03, Issue #211），覆蓋流失預測
- **KM 生存分析** 為補充性工具（gap-time survival），尚未移植
- **覺醒率** = S→E0 轉換率，從 NES 狀態轉換矩陣計算，尚未移植

## Company Projects

L4 Enterprise 目前有 6 個公司專案：

| Company | 說明 |
|---------|------|
| D_RACING | 技詮賽車精品 |
| MAMBA | MAMBA |
| QEF_DESIGN | 向創設計 |
| URBANER | 奧本電剪 |
| WISER | WISER（原始模板） |
| kitchenMAMA | 美食鍋 |

所有公司共用 `shared/global_scripts/`（透過 symlink 或 subrepo）。

每家公司的 **deployed Posit Connect URL + deploy metadata** 記錄在 `.claude/companies.yaml`（#377）。MAMBA 的 live URL 是 `https://kyleyhl-ai-martech-l4-mamba.share.connect.posit.cloud/`。

## Shared Architecture

- **global_scripts**: `shared/global_scripts/` — 所有公司共用的核心程式碼
- **Template**: `template/` — 新公司專案的起始模板（基於 WISER）
- **Data**: `data/` — 共用資料目錄
