---
title: "CHANGELOG 目錄重組提案"
date: "2025-11-05"
author: "principle-product-manager"
status: "proposal"
priority: "medium"
---

# CHANGELOG 目錄重組提案

## 📊 現狀分析

### 當前問題

1. **位置不一致**：
   - 專案 CHANGELOG：`scripts/global_scripts/00_principles/CHANGELOG/`
   - Agent 輸出：`/Overleaf/manuals/MAMBA/docs/work_notes/`
   - **問題**：變更記錄分散在兩個位置

2. **結構混亂**：
   - 根目錄有 **59 個** 日期命名的 .md 檔案（2025-08-26 到 2025-11-03）
   - 8 個子目錄：`IN_PROGRESS`, `analysis`, `archive`, `decisions`, `improvements`, `monitoring`, `releases`, `reviews`
   - 分類邏輯不清楚

3. **命名不一致**：
   ```
   2025-11-02_UI_R019_creation.md
   2025-11-02_issue_108_154_resolution.md
   2025-11-03_ISSUE_244_complete_resolution.md
   ```
   - 有些用 UI_R019，有些用 ISSUE_244
   - 大小寫不一致

4. **缺少索引**：
   - 雖有 `index.qmd`，但根目錄文件太多難以查找
   - 沒有按主題/規則/Issue 的快速索引

## 💡 建議的新結構

### 方案 A：按時間 + 類型分層（推薦）

```
scripts/global_scripts/00_principles/CHANGELOG/
├── README.md                          # 目錄說明和使用指南
├── index.qmd                          # 主索引（改進版）
├── QUICK_INDEX.md                     # 快速查找索引（按規則/Issue）
│
├── 2025/                              # 按年份分組
│   ├── 11_November/                   # 按月份分組
│   │   ├── issues/                    # Issue 解決記錄
│   │   │   ├── ISSUE_245_download_utf8_encoding.md
│   │   │   ├── ISSUE_246_dual_download_buttons.md
│   │   │   └── ...
│   │   ├── rules/                     # 規則創建/修改記錄
│   │   │   ├── UI_R020_csv_utf8_bom_standard.md
│   │   │   ├── UI_R021_dual_download_buttons.md
│   │   │   └── ...
│   │   ├── components/                # 組件修復/改進記錄
│   │   │   ├── poissonFeatureAnalysis_dual_buttons.md
│   │   │   └── ...
│   │   └── other/                     # 其他變更
│   │       └── ...
│   │
│   ├── 10_October/
│   │   └── ...
│   └── ...
│
├── templates/                         # 變更日誌模板
│   ├── issue_resolution_template.md
│   ├── rule_creation_template.md
│   ├── component_update_template.md
│   └── principle_revision_template.md
│
└── archive/                           # 歷史歸檔
    ├── 2024/
    ├── pre_restructure/               # 重組前的舊文件
    │   ├── 2025-08-26_*.md
    │   └── ...
    └── deprecated/                    # 已廢棄的變更記錄
```

**優點**：
- ✅ 按時間清晰分層（年/月）
- ✅ 按類型分類（issues, rules, components）
- ✅ 易於查找和維護
- ✅ 可擴展性好

**缺點**：
- ⚠️ 需要遷移現有 59 個文件
- ⚠️ 需要更新引用路徑

### 方案 B：按類型 + 時間索引（較簡單）

```
scripts/global_scripts/00_principles/CHANGELOG/
├── README.md
├── index.qmd
│
├── issues/                            # 所有 Issue 解決記錄
│   ├── 2025-11-05_ISSUE_245.md
│   ├── 2025-11-05_ISSUE_246.md
│   └── index.md                       # Issue 索引
│
├── rules/                             # 所有規則相關變更
│   ├── 2025-11-05_UI_R020.md
│   ├── 2025-11-05_UI_R021.md
│   └── index.md                       # 規則索引
│
├── components/                        # 所有組件變更
│   ├── 2025-11-05_poisson_dual_buttons.md
│   └── index.md
│
├── principles/                        # 原則修訂記錄
│   └── index.md
│
├── decisions/                         # 重大決策記錄（保留）
├── releases/                          # 發布記錄（保留）
└── archive/                           # 歷史歸檔
```

**優點**：
- ✅ 結構簡單
- ✅ 易於實施
- ✅ 按類型快速查找

**缺點**：
- ⚠️ 同一目錄文件過多（時間長了）
- ⚠️ 缺少時間層級

## 🎯 推薦方案：混合式（方案 C）

結合兩者優點：

```
scripts/global_scripts/00_principles/CHANGELOG/
├── README.md                          # 📖 使用指南
├── INDEX.md                           # 📇 主索引（自動生成）
│
├── active/                            # 🔄 活躍的變更記錄（最近 3 個月）
│   ├── 2025-11/
│   │   ├── ISSUE_245_download_utf8_encoding.md
│   │   ├── ISSUE_246_dual_download_buttons.md
│   │   ├── UI_R020_csv_utf8_bom_standard.md
│   │   └── UI_R021_dual_download_buttons.md
│   ├── 2025-10/
│   └── 2025-09/
│
├── by_type/                           # 📂 按類型快速查找（符號連結）
│   ├── issues/                        # -> 指向 active/ 和 archive/ 中的 ISSUE_* 文件
│   ├── rules/                         # -> 指向 UI_R*, MP*, DEV_R* 文件
│   ├── components/                    # -> 指向組件修改記錄
│   └── principles/                    # -> 指向原則修訂記錄
│
├── archive/                           # 📦 歷史歸檔（超過 3 個月）
│   ├── 2025/
│   │   ├── 2025-08/
│   │   └── 2025-07/
│   ├── 2024/
│   └── pre_2024/
│
├── templates/                         # 📝 變更日誌模板
│   ├── issue_template.md
│   ├── rule_template.md
│   └── component_template.md
│
├── decisions/                         # 🎯 重大決策記錄（保留）
├── releases/                          # 🚀 發布記錄（保留）
└── monitoring/                        # 📊 監控記錄（保留）
```

**優點**：
- ✅ 活躍文件易於訪問（active/最近3個月）
- ✅ 按類型快速查找（by_type/符號連結）
- ✅ 歷史歸檔不影響當前工作
- ✅ 保留現有有用的子目錄

## 🔧 實施計劃

### Phase 1: 創建新結構（1h）

1. 創建新目錄結構
2. 創建 README.md（使用指南）
3. 創建模板文件
4. 創建索引生成腳本

### Phase 2: 遷移現有文件（2h）

1. **自動分類腳本**：
   ```bash
   # 根據文件名自動分類
   - ISSUE_* → issues/
   - UI_R*, MP*, DEV_R* → rules/
   - *_resolution → issues/
   - *_creation → rules/
   ```

2. **手動審查**：
   - 檢查分類結果
   - 處理模糊案例

3. **更新引用**：
   - 搜尋所有引用舊路徑的文件
   - 更新為新路徑

### Phase 3: 建立符號連結（0.5h）

```bash
cd by_type/issues
ln -s ../../active/2025-11/ISSUE_245*.md .
ln -s ../../active/2025-11/ISSUE_246*.md .
```

### Phase 4: 文檔化（0.5h）

1. 更新 README.md
2. 創建索引
3. 文檔化分類規則

## 📝 變更日誌標準化

### 統一命名規範

```
格式: YYYY-MM-DD_[TYPE]_[ID]_[brief_description].md

範例:
2025-11-05_ISSUE_245_download_utf8_encoding.md
2025-11-05_UI_R021_dual_download_buttons.md
2025-11-05_COMP_poissonFeatureAnalysis_dual_buttons.md
2025-11-05_PRIN_MP124_revision.md
```

**TYPE 代碼**：
- `ISSUE`: Issue 解決
- `UI_R`, `MP`, `DEV_R`: 規則創建/修改
- `COMP`: 組件更新
- `PRIN`: 原則修訂
- `DEC`: 決策記錄
- `REL`: 發布記錄

### 統一文件結構

所有變更日誌應包含：

```markdown
---
type: "issue_resolution" | "rule_creation" | "component_update"
date: "YYYY-MM-DD"
id: "ISSUE_245" | "UI_R021" | "poissonFeatureAnalysis"
related_rules: ["UI_R020", "UI_R018"]
related_issues: ["ISSUE_245", "ISSUE_246"]
components: ["poissonFeatureAnalysis", "poissonCommentAnalysis"]
author: "principle-coder" | "principle-revisor"
status: "completed" | "in_progress"
---

# [Title]

## Executive Summary
- What was changed
- Why it was changed
- Impact

## Detailed Changes
[詳細內容]

## Verification
[驗證結果]

## Related
[相關連結]
```

## 🤖 principle-change-logger 整合

### 更新 Agent 行為

修改 `.claude/agents/principle-change-logger.md`：

```markdown
## 變更日誌輸出位置

**標準路徑**:
`scripts/global_scripts/00_principles/CHANGELOG/active/YYYY-MM/`

**命名規範**:
`YYYY-MM-DD_[TYPE]_[ID]_[brief_description].md`

## 自動分類規則

根據變更類型自動決定：
- Issue 解決 → `active/YYYY-MM/ISSUE_XXX_*.md`
- 規則創建 → `active/YYYY-MM/UI_RXXX_*.md`
- 組件更新 → `active/YYYY-MM/COMP_*.md`

## 自動索引更新

每次創建變更日誌後：
1. 更新 `INDEX.md`
2. 創建 `by_type/` 符號連結
3. 檢查是否需要歸檔舊記錄（>3個月）
```

### 什麼時候需要 change-logger？

**必須記錄**（Critical）：
- ✅ 新規則創建（UI_R*, MP*, DEV_R*）
- ✅ 規則重大修訂
- ✅ Issue 解決（尤其影響多個組件）
- ✅ 重大重構
- ✅ Breaking changes

**建議記錄**（Recommended）：
- ✅ 組件重大更新（如添加新功能）
- ✅ 架構調整
- ✅ 效能優化

**可選記錄**（Optional）：
- ⚠️ 小 bug 修復
- ⚠️ 文檔更新
- ⚠️ 程式碼風格調整

**不需記錄**（Skip）：
- ❌ 純註解修改
- ❌ 空白/格式調整
- ❌ 臨時測試代碼

## 🎯 下一步行動

### 立即行動（如果同意方案 C）

1. **Phase 0: 備份**（5 分鐘）
   ```bash
   cp -r CHANGELOG CHANGELOG_backup_20251105
   ```

2. **Phase 1: 創建結構**（30 分鐘）
   - 我可以創建新目錄結構
   - 創建 README 和模板
   - 創建分類腳本

3. **Phase 2: 試運行**（30 分鐘）
   - 先遷移最近 10 個文件測試
   - 驗證結構可行性
   - 調整細節

4. **Phase 3: 全面遷移**（1 小時）
   - 遷移所有文件
   - 建立符號連結
   - 更新索引

5. **Phase 4: 更新 Agent**（30 分鐘）
   - 更新 principle-change-logger 定義
   - 測試自動記錄功能

## 💬 需要您的決定

1. **選擇方案**：A、B、還是 C（推薦）？
2. **保留舊文件**：是否保留 `archive/pre_restructure/` 所有舊文件？
3. **符號連結**：macOS 支持，是否使用？
4. **立即實施**：是否現在開始重組？

如果同意方案 C，我可以立即開始實施！
