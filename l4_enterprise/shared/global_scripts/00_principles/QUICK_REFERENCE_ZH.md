# AI MarTech 原則快速參考

> 這份文件是中文快速導覽，不再硬編碼原則總數與章節數量。
>
> 入口請以目前結構為準：
> - 人類入口：`NAVIGATION.md`
> - AI/LLM 入口：`llm/index.yaml`
> - 英文正本：`docs/en/`
> - 中文鏡像：`docs/zh/`
>
> **更新日期：2026-03-06**

---

## 先看哪裡

### 如果你是人類開發者

1. 先看 `NAVIGATION.md`
2. 再依主題進到 `docs/en/part1_principles/` 或 `docs/en/part2_implementations/`
3. 需要中文對照時再查 `docs/zh/`

### 如果你是 AI / LLM

1. 先讀 `llm/index.yaml`
2. 再讀 `llm/CH00_meta.yaml`
3. 按 scenario mapping 補讀其他 `llm/*.yaml`

---

## 最常用原則

| 排名 | ID | 標題 | 用途 |
|------|----|------|------|
| 1 | MP029 | 禁止假資料 | 生產資料流程不可用假資料或 placeholder 資料 |
| 2 | MP064 | ETL / 衍生分離 | ETL 負責資料準備，衍生負責商業邏輯 |
| 3 | MP108 | ETL 階段順序 | ETL 必須遵守 0IM → 1ST → 2TR |
| 4 | DM_R041 | ETL 目錄結構 | ETL / DRV 檔案放在正確目錄 |
| 5 | DM_R044 | 衍生實作標準 | D*.R 衍生腳本的寫法 |
| 6 | SO_R007 | 一函數一檔案 | 每個函數一個檔案 |
| 7 | UI_P004 | 元件 N-Tuple 模式 | UI 元件由 UI + Server + Defaults 組成 |
| 8 | UI_R001 | UI-Server-Defaults 規則 | Shiny 元件三元組的具體命名與分檔規則 |
| 9 | UI_R022 | UI 翻譯字典模式 | UI 文字必須走 translation dictionary |
| 10 | IC_R008 | GitHub Issue Scope Governance | issue 必須用共享 repo 與正確 scope label |

---

## 目前章節結構

### 第一部分：原則

位於 `docs/{lang}/part1_principles/`：

- `CH00_fundamental_principles`
- `CH01_structure_organization`
- `CH02_data_management`
- `CH03_development_methodology`
- `CH04_ui_components`
- `CH05_testing_deployment`
- `CH06_integration_collaboration`
- `CH07_security`
- `CH08_user_experience`
- `CH09_etl_pipelines`

重要：
- `CH07_security` 是目前唯一的 `CH07` 章節目錄
- UX 章節已移到 `CH08_user_experience`，不要再用 bare `CH07` 指代
- 引用路徑時請寫完整目錄名，不要只寫章節號碼

### 第二部分：實作指南

位於 `docs/{lang}/part2_implementations/`：

- `CH10_database_specifications`
- `CH11_data_flow_architecture`
- `CH12_etl_pipelines`
- `CH13_derivations`
- `CH14_modules_tools`
- `CH15_functions_reference`
- `CH16_apis_external_integration`
- `CH17_connections`
- `CH18_templates_examples`
- `CH19_solutions_patterns`
- `CH20_app_architecture`

### 第三部分：領域知識

位於 `docs/{lang}/part3_domain_knowledge/`：

- `CH21_marketing_analytics`
- `CH22_statistics`
- `CH23_system_architecture`
- `CH24_ai_assisted_development`（目前僅英文來源）

---

## 常見情境

### 情境 1：建立 ETL 管線

先看：
- `MP064`
- `MP108`
- `DM_R041`
- `llm/CH11_etl.yaml`

### 情境 2：建立衍生腳本

先看：
- `DM_R042`
- `DM_R044`
- `MP064`
- `llm/CH12_derivations.yaml`

### 情境 3：建立 Shiny UI 元件

先看：
- `UI_P004`
- `UI_R001`
- `UI_R022`
- `UX_P001` / `UX_P002`（如果牽涉啟動效能或查詢渲染）

### 情境 4：安全與憑證設定

先看：
- `CH07_security`
- `SEC_R001`
- `SEC_R002`
- `SEC_R003`

### 情境 5：issue / 協作流程

先看：
- `CH06_integration_collaboration`
- `IC_R007`
- `IC_R008`

---

## 快速提醒

### 必查

1. 不要在生產流程建立假資料：`MP029`
2. ETL 與衍生不能混寫：`MP064`
3. ETL 階段順序不能跳：`MP108`
4. R 函數遵守一函數一檔案：`SO_R007`
5. Shiny 元件遵守 N-Tuple：`UI_P004` + `UI_R001`
6. UI 文字遵守 translation dictionary：`UI_R022`

### 常見誤區

❌ 把 `docs/zh/` 當成永遠最新的版本  
❌ 在文件裡引用不存在的 `PRINCIPLES_LLM/` 路徑  
❌ 用 bare `CH07` 指代 security 或 UX 任一章節  
❌ 在入口文件硬編碼會快速過期的總數與範圍  

---

## 檔案入口總覽

```text
00_principles/
├── NAVIGATION.md
├── INDEX.md
├── README.md
├── QUICK_REFERENCE.md
├── QUICK_REFERENCE_ZH.md
├── llm/
│   ├── index.yaml
│   ├── CH00_meta.yaml
│   ├── CH01_structure.yaml
│   ├── CH02_data.yaml
│   ├── CH03_development.yaml
│   ├── CH04_ui.yaml
│   ├── CH05_testing.yaml
│   ├── CH06_ic.yaml
│   └── CH07_ux.yaml
└── docs/
    ├── en/
    └── zh/
```
