# ==========================================
# AI MarTech Sandbox Portal - 2x2 Grid Launcher
# ==========================================
# 將 BrandEdge / InsightForge / TagPilot / VitalSigns 整合到一個 Shiny 入口頁。
# - 點擊任一卡片 -> 啟動（開啟）對應 App 並跳轉
# - 沿用既有的 config/yaml/portal_config.yaml（與 app_portal.R 同一份設定）
# - 內建 round-robin 負載平衡（在 N 個部署 instance 之間輪詢）
#
# 與 app_portal.R 的差異：
#   * 改為 2x2 四宮格（原本是一排 4 個）
#   * 整張卡片可點，不只是按鈕
#   * 加入漸層、hover 動畫、響應式版面
#
# 執行方式：
#   library(shiny); runApp("app_portal_grid.R")
# ==========================================

# ---- 自動偵測專案根目錄（讓檔案放哪裡都能跑） ----
local({
  candidate_roots <- c(
    "/Users/kylelin/Library/CloudStorage/Dropbox/ai_martech/l3_premium/sandbox/sandbox_test"
  )
  marker <- "config/yaml/portal_config.yaml"
  if (!file.exists(marker)) {
    for (root in candidate_roots) {
      if (file.exists(file.path(root, marker))) {
        setwd(root)
        message("✅ Portal 工作目錄: ", getwd())
        break
      }
    }
  }
  if (!file.exists(marker)) {
    stop(
      "❌ 找不到 ", marker, "。\n",
      "   請在 RStudio 中先 setwd() 到 sandbox_test/，或直接打開 sandbox.Rproj。"
    )
  }
})

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(yaml)
})

# ============================================================================
# 設定
# ============================================================================
config <- yaml::read_yaml("config/yaml/portal_config.yaml")
APPS   <- config$apps

# 是否在新分頁開啟（TRUE = 新分頁；FALSE = 同分頁跳轉）
OPEN_IN_NEW_TAB <- TRUE

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ---- Round-robin 計數器（在多個 instance 間輪詢） ----
counters <- new.env(parent = emptyenv())
for (app_id in names(APPS)) counters[[app_id]] <- 0L

get_next_instance_url <- function(app_id) {
  info <- APPS[[app_id]]
  n <- info$instances %||% 1L
  counters[[app_id]] <- (counters[[app_id]] %% n) + 1L
  sprintf(info$url_pattern, counters[[app_id]])
}

# ============================================================================
# 卡片色系（漸層 + 強調色），對應 portal_config.yaml 中每個 app 的 color
# ============================================================================
APP_THEMES <- list(
  primary = list(grad = "linear-gradient(135deg, #2C3E50 0%, #4CA1AF 100%)"),
  success = list(grad = "linear-gradient(135deg, #11998e 0%, #38ef7d 100%)"),
  warning = list(grad = "linear-gradient(135deg, #F39C12 0%, #F1C40F 100%)"),
  danger  = list(grad = "linear-gradient(135deg, #E74C3C 0%, #FF6B6B 100%)")
)

create_tile <- function(app_id, app_info) {
  theme <- APP_THEMES[[app_info$color %||% "primary"]] %||% APP_THEMES$primary

  tags$div(
    id = paste0("tile_", app_id),
    class = "app-tile",
    `data-app-id` = app_id,
    style = sprintf("background: %s;", theme$grad),
    # 整張卡片可點：寫入一個 input 給 server 端 observe
    onclick = sprintf(
      "Shiny.setInputValue('tile_clicked', {id: '%s', nonce: Math.random()}, {priority:'event'});",
      app_id
    ),

    tags$div(class = "tile-icon",
             tags$i(class = sprintf("fa fa-%s", app_info$icon %||% "rocket"))),
    tags$div(class = "tile-name", app_info$name %||% app_id),
    tags$div(class = "tile-desc", app_info$description %||% ""),
    tags$div(class = "tile-cta",
             icon("rocket"), " Launch ",
             tags$i(class = "fa fa-arrow-right"))
  )
}

# ============================================================================
# UI
# ============================================================================
ui <- page_fillable(
  theme = bs_theme(bootswatch = "flatly", version = 5),
  title = "AI MarTech Sandbox Portal",

  tags$head(
    tags$link(
      rel  = "stylesheet",
      href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
    ),
    tags$style(HTML("
      :root { --tile-radius: 18px; }
      html, body, .bslib-page-fill { background: #f5f6fa !important; }

      .portal-wrap {
        display: flex; flex-direction: column;
        align-items: center; justify-content: center;
        min-height: 100vh;
        padding: 3rem 1.5rem;
      }
      .portal-header { text-align: center; margin-bottom: 2.5rem; }
      .portal-title {
        font-size: 2.4rem; font-weight: 700;
        color: #1a1a2e; margin-bottom: .35rem;
      }
      .portal-subtitle { color: #666; font-size: 1.05rem; }

      /* === 2x2 四宮格 === */
      .grid-2x2 {
        display: grid;
        grid-template-columns: repeat(2, minmax(260px, 320px));
        grid-template-rows:    repeat(2, 1fr);
        gap: 1.75rem;
        max-width: 720px;
        width: 100%;
      }

      .app-tile {
        position: relative;
        height: 280px;
        border-radius: var(--tile-radius);
        padding: 1.75rem;
        color: #fff;
        cursor: pointer;
        overflow: hidden;
        box-shadow: 0 8px 24px rgba(0,0,0,.08);
        transition: transform .25s ease, box-shadow .25s ease;
        display: flex; flex-direction: column;
        justify-content: space-between;
        user-select: none;
      }
      .app-tile:hover {
        transform: translateY(-6px) scale(1.02);
        box-shadow: 0 18px 40px rgba(0,0,0,.18);
      }
      .app-tile::before {
        content: ''; position: absolute; inset: 0;
        background: rgba(255,255,255,.08);
        opacity: 0; transition: opacity .25s ease;
        pointer-events: none;
      }
      .app-tile:hover::before { opacity: 1; }

      .tile-icon { font-size: 3rem; opacity: .9; }
      .tile-name {
        font-size: 1.6rem; font-weight: 700; letter-spacing: .3px;
      }
      .tile-desc { font-size: .95rem; opacity: .9; margin-top: .35rem; }
      .tile-cta  { margin-top: 1rem; font-weight: 600; opacity: .92; }
      .tile-cta i.fa-arrow-right {
        margin-left: .35rem; transition: transform .25s ease;
      }
      .app-tile:hover .tile-cta i.fa-arrow-right { transform: translateX(4px); }

      /* === 響應式（手機變單欄） === */
      @media (max-width: 700px) {
        .grid-2x2 { grid-template-columns: 1fr; max-width: 360px; }
        .app-tile { height: 230px; }
      }
    ")),
    tags$script(HTML(sprintf("
      Shiny.addCustomMessageHandler('redirect', function(url) {
        if (%s) { window.open(url, '_blank'); }
        else    { window.location.href = url; }
      });
    ", if (OPEN_IN_NEW_TAB) "true" else "false")))
  ),

  tags$div(
    class = "portal-wrap",
    tags$div(
      class = "portal-header",
      tags$div(class = "portal-title", "AI MarTech Sandbox"),
      tags$div(class = "portal-subtitle",
               "點擊任一卡片即啟動對應的應用程式")
    ),
    tags$div(
      class = "grid-2x2",
      lapply(names(APPS), function(app_id) {
        create_tile(app_id, APPS[[app_id]])
      })
    )
  )
)

# ============================================================================
# Server
# ============================================================================
server <- function(input, output, session) {
  observeEvent(input$tile_clicked, {
    payload <- input$tile_clicked
    if (is.null(payload)) return()
    app_id <- payload$id
    if (is.null(app_id) || !nzchar(app_id) || !app_id %in% names(APPS)) return()

    url <- get_next_instance_url(app_id)
    message(sprintf("🚀 Launching %s -> %s", app_id, url))
    session$sendCustomMessage("redirect", url)
  })
}

shinyApp(ui = ui, server = server)
