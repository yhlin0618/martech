# UI 佈局規則

**使用時機**: 建立或修改 Shiny 元件的 UI 時

---

## Sidebar 層級規則 (UI_R026)

Sidebar 由上到下嚴格按以下順序排列，**不可混放**：

```
┌─ Sidebar ──────────────────────────┐
│ ① 全域 Filter（Global Filters）   │
│    平台 (Platform)                 │
│    產品線 (Product Line)           │
│ ── 分隔線 ──────────────────────── │
│ ② Tab 選單（sidebarMenu）          │
│    總覽儀表板                      │
│    TagPilot ▸ ...                  │
│    VitalSigns ▸ ...                │
│    BrandEdge ▸ ...                 │
│    ...                             │
│ ③ Local Filter（條件顯示）         │
│    如：國家篩選（僅 VitalSigns）   │
│ ④ 元件 Filter（dynamic_filter）    │
│    元件專屬篩選控件                │
│    AI 洞察按鈕（最底部）           │
└────────────────────────────────────┘
```

### 各層定義

| 層級 | 名稱 | 可見性 | 內容 |
|------|------|--------|------|
| ① | Global Filter | 永遠可見 | 平台、產品線 — 影響所有 tab |
| ② | Tab 選單 | 永遠可見 | `sidebarMenu` — 模組導航 |
| ③ | Local Filter | **條件顯示** | 跨多個 tab 共用但非全域的 filter（如國家篩選只在 VitalSigns tab 出現） |
| ④ | 元件 Filter | **條件顯示** | `dynamic_filter` — 依 active tab 切換的元件專屬 filter，AI 按鈕在此區最底部 |

### 判斷 filter 放哪一層

```
新增 filter 時：
├── 影響所有 tab？ → ① Global Filter
├── 影響某類 tab（如所有 VitalSigns）？ → ③ Local Filter（條件顯示）
├── 只影響單一 tab？ → ④ 元件 Filter（寫在元件的 ui$filter 裡）
└── 不確定？ → 預設放 ④，避免全域污染
```

### 常見錯誤

| 錯誤 | 正確 | 原因 |
|------|------|------|
| 把國家 filter 放在 ①（全域區） | 放在 ③（Local Filter） | 國家只影響 VitalSigns，非全域 |
| 把 AI 按鈕放在 ② 或 ③ | 放在 ④ 的最底部 | AI 按鈕屬於元件專屬操作 |
| Local filter 無條件顯示 | 用 `renderUI` + tab 判斷 | 避免無關 tab 看到多餘控件 |

---

## 元件內部佈局（ui_filter + ui_display）

每個元件的 UI 分為 `ui_filter`（出現在 sidebar ④）和 `ui_display`（主面板）。

### ui_filter（sidebar ④ 區域）
放置**元件專屬互動控件**：
- 元件特有的篩選條件
- AI 生成按鈕（`ai_insight_button_ui()`）— **必須在最底部**

**流程邏輯**：選擇篩選條件 → 按下 AI 按鈕 → 結果顯示在主面板

### ui_display（主面板）上方
放置**資料展示**：
- KPI 卡片
- 圖表
- 下載按鈕（位於資料表上方，UI_R018）
- 資料表

### ui_display（主面板）最底部
放置**整合/摘要**性質的內容：
- AI 結果卡片（`ai_insight_result_ui()`）— spinner + 結果

---

## AI Insight UI 拆分

`ai_insight_ui()` 拆為兩個函數：

| 函數 | 位置 | 包含 |
|------|------|------|
| `ai_insight_button_ui(ns, translate)` | `ui_filter` 最底部 | actionButton |
| `ai_insight_result_ui(ns, translate)` | `ui_display` 最底部 | spinner + result card |

### 標準模式

```r
ui_filter <- tagList(
  # 元件專屬 filter（如有）
  ai_insight_button_ui(ns, translate)  # 永遠在最底部
)

ui_display <- tagList(
  # KPI, charts, tables...
  fluidRow(column(12, bs4Card(... detail_table ...))),
  # AI result at very bottom
  fluidRow(column(12, ai_insight_result_ui(ns, translate)))
)
```

---

## 相關原則

- **UI_R001**: UI-Server-Defaults Triple Pattern
- **UI_R018**: Download Button Placement（資料表上方）
- **UI_R026**: Sidebar Layout Hierarchy（本頁定義）
- **UX_P002**: Progressive Disclosure（AI 結果為摘要，放最後）
