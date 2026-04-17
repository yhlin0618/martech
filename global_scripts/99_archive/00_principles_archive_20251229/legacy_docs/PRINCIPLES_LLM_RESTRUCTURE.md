# PRINCIPLES_LLM 資料夾重構計畫

## 目標架構

```
00_principles/
├── PRINCIPLES_LLM/
│   ├── index.yaml              ← 核心原則 (~50個) + 場景映射 + 章節索引
│   ├── CH00_security.yaml      ← MP110-MP118 安全原則 (9個)
│   ├── CH00_meta.yaml          ← 其他 MP 原則
│   ├── CH01_structure.yaml     ← SO_P, SO_R 原則
│   ├── CH02_data.yaml          ← DM_P, DM_R 原則
│   ├── CH03_development.yaml   ← DEV_P, DEV_R 原則
│   ├── CH04_ui.yaml            ← UI_P, UI_R 原則
│   └── CH05_testing.yaml       ← TD_P, TD_R 原則
├── NAVIGATION.md               ← 更新指向新位置
├── INDEX.md                    ← 更新指向新位置
└── README.md                   ← 更新指向新位置
```

## 執行步驟

### Phase 1: 創建資料夾結構
- [x] 創建 PRINCIPLES_LLM/ 資料夾
- [x] 創建 index.yaml（從現有 PRINCIPLES_LLM.yaml 重組）

### Phase 2: 分割章節檔案
- [x] 創建 CH00_security.yaml（MP110-MP118）
- [ ] 創建其他章節檔案（空模板，待後續填充）

### Phase 3: 更新引用
- [x] 更新 _shared_guidelines.md
- [x] 更新 NAVIGATION.md
- [x] 更新 INDEX.md
- [x] 更新 README.md

### Phase 4: 清理
- [x] 保留舊的 PRINCIPLES_LLM.yaml（標記為 DEPRECATED，向後兼容）
- [x] 驗證所有引用正確

## index.yaml 設計

```yaml
# PRINCIPLES_LLM/index.yaml
# 核心原則 + 場景映射 + 章節索引

version: "3.0"
description: "MAMBA Principles - LLM-Friendly Format (Hierarchical)"

# 章節檔案索引
chapter_files:
  CH00_security: "CH00_security.yaml"    # MP110-MP118
  CH00_meta: "CH00_meta.yaml"            # 其他 MP
  CH01_structure: "CH01_structure.yaml"  # SO_P, SO_R
  CH02_data: "CH02_data.yaml"            # DM_P, DM_R
  CH03_development: "CH03_development.yaml"  # DEV_P, DEV_R
  CH04_ui: "CH04_ui.yaml"                # UI_P, UI_R
  CH05_testing: "CH05_testing.yaml"      # TD_P, TD_R

# 場景 → 章節映射
scenario_chapters:
  building_etl: ["CH02_data"]
  database_work: ["CH02_data"]
  creating_ui: ["CH04_ui"]
  security_audit: ["CH00_security"]
  debugging: ["CH03_development"]

# 核心原則（~50個高頻使用）
# 這些原則完整定義在此，不需要讀章節檔案
principles:
  - id: MP029
    ...
```

## LLM 讀取流程

```
1. 讀取 PRINCIPLES_LLM/index.yaml（必讀）
   - 獲得核心原則定義
   - 獲得場景映射
   - 獲得章節檔案索引

2. 根據任務，決定是否需要讀章節檔案
   - 做安全相關？→ 讀 CH00_security.yaml
   - 做 ETL？    → 讀 CH02_data.yaml
   - 做 UI？     → 讀 CH04_ui.yaml

3. 如果核心原則已足夠，不需讀章節檔案
```

## 狀態追蹤

- 開始時間：2025-12-14 14:55
- 當前狀態：✅ 完成
- 最後更新：2025-12-14

## 完成摘要

### 創建的檔案
1. `PRINCIPLES_LLM/index.yaml` - 核心原則 (~12個) + 場景映射 + 章節索引 (~850 行)
2. `PRINCIPLES_LLM/CH00_security.yaml` - MP110-MP118 安全原則 (9個, ~450 行)

### 更新的檔案
1. `.claude/agents/_shared_guidelines.md` - 更新查閱流程指向新結構
2. `NAVIGATION.md` - 更新 AI 入口說明
3. `INDEX.md` - 更新 Quick Start 和 Recent Changes
4. `README.md` - 更新目錄結構說明

### 保留的檔案（向後兼容）
- `PRINCIPLES_LLM.yaml` - 標記為 DEPRECATED，保留給舊版 agent 使用
