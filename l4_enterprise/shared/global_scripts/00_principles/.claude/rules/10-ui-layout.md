# UI 佈局規則

**使用時機**: 建立或修改 Shiny 元件的 UI 時

---

## Sidebar 層級規則 (UI_R026)

Sidebar 由上到下嚴格按以下順序排列，**只有三層，不可混放**：

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
│ ③ 元件 Filter（dynamic_filter）    │
│    ← 所有 filter 都從這裡出來     │
│    元件專屬篩選控件                │
│    AI 洞察按鈕（最底部）           │
└────────────────────────────────────┘
```

### 各層定義

| 層級 | 名稱 | 可見性 | 內容 |
|------|------|--------|------|
| ① | Global Filter | 永遠可見 | 平台、產品線 — 影響所有 tab |
| ② | Tab 選單 | 永遠可見 | `sidebarMenu` — 模組導航 |
| ③ | 元件 Filter | **條件顯示** | `dynamic_filter` — 依 active tab 切換的元件專屬 filter，AI 按鈕在此區最底部 |

**注意：沒有 Local Filter 層。** 以前有 ③ Local Filter + ④ 元件 Filter 的設計，已廢除（見 UI_R028）。

### 判斷 filter 放哪一層

```
新增 filter 時：
├── 影響所有 tab？ → ① Global Filter
├── 只影響特定 tab？ → ③ 元件 Filter（寫在該元件的 ui$filter 裡）
├── 多個 tab 都需要？ → 每個 tab 的元件各自在 ui$filter 裡加
└── 不確定？ → 預設放 ③，避免全域污染
```

### 常見錯誤

| 錯誤 | 正確 | 原因 |
|------|------|------|
| 在 union 層加 `uiOutput("country_filter_sidebar")` | 放在 worldMap 的 `ui$filter` 裡 | UI_R028：所有 filter 必須通過元件架構 |
| 把 AI 按鈕放在 ① 或 ② | 放在 ③ 的最底部 | AI 按鈕屬於元件專屬操作 |
| 多個 tab 共用 filter 就提到 union 層 | 每個元件各自在 `ui$filter` 裡加 | UI_R028：不在 union 層注入 filter |

---

## 元件 Filter 排他性 (UI_R028)

### 核心規則

**所有 sidebar filter 控件必須通過元件的 `ui$filter` 機制。禁止在 union/layout 層注入 filter。**

### 元件契約

每個元件回傳恰好兩個 UI 部分：

```r
list(
  ui = list(
    filter  = ui_filter,   # → sidebar ③ dynamic_filter 容器
    display = ui_display    # → main panel body
  ),
  server = server_fn
)
```

只有 `filter` 和 `display`。**沒有第三個 slot。**

### 正確做法

```r
# worldMap 元件（需要國家篩選）
ui_filter <- tagList(
  selectInput(ns("country"), label = translate("Country"), ...),
  selectInput(ns("kpi_select"), label = translate("Select KPI"), ...),
  radioButtons(ns("view_mode"), label = translate("View Mode"), ...),
  ai_insight_button_ui(ns, translate)
)
```

### 錯誤做法

```r
# WRONG: 在 union 層繞過元件架構
sidebar = bs4DashSidebar(
  ...,
  uiOutput("country_filter_sidebar"),  # ← 違反 UI_R028
  uiOutput("dynamic_filter")
)
```

### YAGNI 原則

不要為「未來可能多個 tab 需要同一個 filter」而在 union 層建共用機制。先放在需要的元件的 `ui$filter` 裡。等到真的有第二個元件需要時，在那個元件的 `ui$filter` 裡也加一份。

---

## 元件內部佈局（ui_filter + ui_display）

每個元件的 UI 分為 `ui_filter`（出現在 sidebar ③）和 `ui_display`（主面板）。

### ui_filter（sidebar ③ 區域）
放置**該元件的所有互動控件**：
- 元件特有的篩選條件（國家、指標、時間範圍等）
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

## 互動行為規則 (UX_R001)

**所有導航動作（drill-down、返回、切換 tab、選擇 filter）一律用單擊。不可要求雙擊。**

適用範圍：
- 互動式視覺化（地圖點擊 drill-down / 返回）
- Tab 切換
- Filter 選擇
- 任何改變目前視圖的動作

---

## 相關原則

- **UI_R001**: UI-Server-Defaults Triple Pattern
- **UI_R018**: Download Button Placement（資料表上方）
- **UI_R026**: Sidebar Layout Hierarchy（三層：Global → Tab 選單 → 元件 Filter）
- **UI_R028**: Component Filter Exclusivity（所有 filter 必須通過 ui$filter）
- **UX_R001**: Single-Click Navigation（導航一律單擊，不可雙擊）
- **UX_P002**: Progressive Disclosure（AI 結果為摘要，放最後）
