###############################################################################
# Tag Pilot 精準行銷平台 - 主應用程式                                          #
# 版本: v18 (bs4Dash)                                                         #
# 更新: 2024-06-23                                                            #
###############################################################################

# ── 系統初始化 ──────────────────────────────────────────────────────────────
source("config/packages.R")    # 載入套件管理
source("config/config.R")      # 載入配置設定

# 初始化套件環境
initialize_packages()

# 驗證配置
validate_config()

# ── 全域 CSS 樣式 ────────────────────────────────────────────────────────
css_deps <- tags$head(tags$style(HTML("
  /* 確保 DataTables 的滾動條始終顯示 */
  .dataTables_scrollBody { overflow-x: scroll !important; }
  /* macOS 滾動條始終顯示的全域設定 */
  .dataTables_scrollBody::-webkit-scrollbar { -webkit-appearance: none; }
  .dataTables_scrollBody::-webkit-scrollbar:horizontal { height: 10px; }
  .dataTables_scrollBody::-webkit-scrollbar-thumb { border-radius: 5px; background-color: rgba(0,0,0,.3); }
  .dataTables_scrollBody::-webkit-scrollbar-track { background-color: rgba(0,0,0,.1); border-radius: 5px; }

  /* 登入頁面樣式 */
  .login-container {
    max-width: 400px;
    margin: 2rem auto;
    padding: 2rem;
    background: white;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  .login-icon { text-align: center; margin-bottom: 2rem; }

  /* 步驟指示器 */
  .step-indicator {
    display: flex;
    justify-content: space-between;
    margin-bottom: 2rem;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 8px;
  }
  .step-item {
    flex: 1;
    text-align: center;
    padding: 0.5rem;
    border-radius: 5px;
    transition: all 0.3s;
  }
  .step-item.active {
    background: #007bff;
    color: white;
  }
  .step-item.completed {
    background: #28a745;
    color: white;
  }

  /* 歡迎訊息樣式 */
  .welcome-banner {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1.5rem;
    border-radius: 10px;
    margin-bottom: 2rem;
    text-align: center;
  }
")))

# ── 載入模組 ────────────────────────────────────────────────────────────────
source("database/db_connection.R")    # 資料庫連接模組
source("utils/data_access.R")         # 資料存取工具（整合 tbl2）
source("modules/module_wo_b.R")       # 主要分析模組
source("scripts/global_scripts/10_rshinyapp_components/login/login_module.R")  # 登入模組
source("modules/module_upload.R")     # 上傳模組
source("modules/module_dna.R")
source("modules/module_dna_multi.R")        # DNA 分析模組

# ── reactive values -----------------------------------------------------------
facets_rv   <- reactiveVal(NULL)  # 目前 LLM 產出的 10 個屬性 (字串向量)
progress_info <- reactiveVal(list(start=NULL, done=0, total=0))
safe_value <- function(txt) {
  txt <- trimws(txt)
  num <- str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}

# 全域 tab 切換 trigger
regression_trigger <- reactiveVal(0)

# ── 登入頁面 UI ──────────────────────────────────────────────────────────
# 使用新的參數化登入模組

# ── 主要應用 UI (bs4Dash) ───────────────────────────────────────────────
main_app_ui <- bs4DashPage(
  title = "Tag Pilot 精準行銷平台",
  fullscreen = TRUE,

  # 頁首
  header = bs4DashNavbar(
    title = bs4DashBrand(
      title = "Tag Pilot",
      color = "primary",
      image = "assets/icons/app_icon.png"
    ),
    skin = "light",
    status = "primary",
    fixed = TRUE,
    rightUi = tagList(
      uiOutput("db_status"),
      uiOutput("user_menu")
    )
  ),

  # 側邊欄
  sidebar = bs4DashSidebar(
    status = "primary",
    width = "280px",
    elevation = 3,
    minified = FALSE,

    # 歡迎訊息
    div(class = "welcome-banner",
        h5("🎉 歡迎！", style = "margin: 0;"),
        textOutput("welcome_user", inline = TRUE)
    ),

    # 步驟指示器
    div(class = "step-indicator",
        div(class = "step-item", id = "step_1", "1. 上傳資料"),
        div(class = "step-item", id = "step_2", "2. Value × Activity 九宮格")
    ),

    # 選單
    sidebarMenu(
      id = "sidebar_menu",
      bs4SidebarHeader("分析流程"),
      bs4SidebarMenuItem(
        text = "資料上傳",
        tabName = "upload",
        icon = icon("upload")
      ),
      bs4SidebarMenuItem(
        text = "Value × Activity 九宮格",
        tabName = "dna_analysis",
        icon = icon("dna")
      ),
      bs4SidebarHeader("平台資訊"),
      bs4SidebarMenuItem(
        text = "關於我們",
        tabName = "about",
        icon = icon("info-circle")
      )
    ),

    # 登出按鈕
    div(style = "position: absolute; bottom: 20px; width: calc(100% - 40px);",
        actionButton("logout", "登出", class = "btn-secondary btn-block", icon = icon("sign-out-alt"))
    )
  ),

  # 主要內容
  body = bs4DashBody(
    css_deps,
    useShinyjs(),

    bs4TabItems(
      # 上傳資料頁面
      bs4TabItem(
        tabName = "upload",
        fluidRow(
          bs4Card(
            title = "步驟 1：上傳資料 (支援多檔案)",
            status = "primary",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            uploadModuleUI("upload1")
          )
        )
      ),



      # DNA 分析頁面
      bs4TabItem(
        tabName = "dna_analysis",
        fluidRow(
          bs4Card(
            title = "步驟 2：Value × Activity 九宮格",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            dnaMultiModuleUI("dna_multi1")
          )
        )
      ),

      # 關於我們頁面
      bs4TabItem(
        tabName = "about",
        fluidRow(
          bs4Card(
            title = NULL,
            status = "info",
            width = 12,
            solidHeader = FALSE,
            elevation = 3,
            div(
              style = "text-align: center; margin-bottom: 2rem;",
              img(src = "assets/icons/app_icon.png", width = "320px", alt = "Tag Pilot Logo")
            ),
            h1("精準行銷平台", style = "text-align: center; color: #007bff; margin-bottom: 2rem;"),

            h2("🎯 服務描述", style = "color: #343a40; border-bottom: 2px solid #007bff; padding-bottom: 0.5rem;"),
            p(
              "我們是一套由 AI 驅動的精準行銷平台，協助品牌根據客戶特徵與行為數據，制定個人化行銷策略。我們整合 NLP、推薦系統與自動化分析以及統計和行銷理論，提供高效且可擴展的解決方案，協助行銷團隊更快達成轉換與黏著目標。",
              style = "font-size: 1.1rem; line-height: 1.6; margin-bottom: 1.5rem;"),
            p("本平台除了能提供企業上針對過去資料的洞見外，也能進一步協助新產品開發。",
              style = "font-size: 1.1rem; line-height: 1.6; margin-bottom: 2rem;"),

            h2("🛠️ 提供服務", style = "color: #343a40; border-bottom: 2px solid #007bff; padding-bottom: 0.5rem;"),
            div(
              style = "background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;",
              tags$ul(
                style = "list-style: none; padding: 0; margin: 0;",
                tags$li(
                  icon("bullseye"),
                  " 客群分群建模（Segmentation Modeling）",
                  style = "margin-bottom: 0.8rem; font-size: 1.1rem;"
                ),
                tags$li(
                  icon("brain"),
                  " 意圖辨識與推薦系統（Intent Detection & Recommendation）",
                  style = "margin-bottom: 0.8rem; font-size: 1.1rem;"
                ),
                tags$li(
                  icon("comments"),
                  " 評論內容語意分析（Sentiment & Aspect Analysis）",
                  style = "margin-bottom: 0.8rem; font-size: 1.1rem;"
                ),
                tags$li(
                  icon("chart-line"),
                  " 行銷活動預測與績效追蹤（Campaign Forecasting & Tracking）",
                  style = "margin-bottom: 0.8rem; font-size: 1.1rem;"
                ),
                tags$li(
                  icon("chart-bar"),
                  " 多管道數據整合與儀表板（Omni-channel Dashboard & ETL）",
                  style = "font-size: 1.1rem;"
                )
              )
            ),

            h2(
              "🤝 過去合作廠商",
              style = "color: #343a40; border-bottom: 2px solid #007bff; padding-bottom: 0.5rem;"
            ),
            div(
              style = "background: #e3f2fd; padding: 1.5rem; border-radius: 8px; margin-bottom: 2rem;",
              tags$a(
                href = "https://shopkitchenmama.com/",
                target = "_blank",
                "美商駿旺 (Kitchen Mama)",
                style = paste(
                  "font-size: 1.2rem; color: #1976d2;",
                  "text-decoration: none; font-weight: bold;"
                )
              )
            ),

            hr(style = "margin: 2rem 0; border-color: #dee2e6;"),

            h2(
              "📞 聯絡方式",
              style = "color: #343a40; border-bottom: 2px solid #007bff; padding-bottom: 0.5rem;"
            ),
            div(
              style = paste(
                "background: #fff3cd; padding: 1.5rem; border-radius: 8px;",
                "border-left: 4px solid #ffc107;"
              ),
              p(
                strong("公司: "),
                "祈鋒行銷科技有限公司",
                style = "margin-bottom: 1rem; font-size: 1.1rem;"
              ),
              p(
                strong("聯絡資訊: "),
                tags$a(
                  href = "mailto:yuhsiang@utaipei.edu.tw",
                  "林郁翔",
                  style = "color: #007bff; text-decoration: none;"
                ),
                style = "margin-bottom: 1rem; font-size: 1.1rem;"
              ),
              p(
                "如需商業合作或平台體驗，請聯絡資料分析團隊。",
                style = "font-style: italic; color: #6c757d; margin-bottom: 0;"
              )
            )
          )
        )
      )
    )
  ),

  # 頁尾
  footer = bs4DashFooter(
    fixed = TRUE,
    left = "Tag Pilot v18 - 精準行銷平台",
    right = "© 2024 All Rights Reserved"
  )
)

# ── 資源路徑設定 (在 UI 定義前) ──────────────────────────────────────────
# 設定 global_scripts 資源路徑
addResourcePath("assets", "scripts/global_scripts/24_assets")

# ── 條件式 UI ─────────────────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),

  # 資源路徑設定
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "https://use.fontawesome.com/releases/v5.15.4/css/all.css"),
    tags$style("#icon_bar { display:flex; gap:12px; align-items:center; margin-bottom:16px; } #icon_bar img { max-height:60px; }")
  ),

  # 根據登入狀態顯示不同UI
  conditionalPanel(
    condition = "output.user_logged_in == false",
    div(style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 2rem 0;",
        loginModuleUI("login1",
                      app_title = "TagPilot Pro",
                      app_icon = "assets/icons/app_icon.png",
                      contacts_md = "md/contacts.md",
                      background_color = "transparent",
                      primary_color = "#17a2b8")
    )
  ),

  conditionalPanel(
    condition = "output.user_logged_in == true",
    main_app_ui
  )
)

# ── Server ------------------------------------------------------------------
server <- function(input, output, session) {
  # 設定檔案上傳大小限制為 200MB
  options(shiny.maxRequestSize = 200*1024^2)

  con_global   <- get_con()
  db_info <- get_db_info(con_global)  # 取得資料庫連接資訊
  onStop(function() dbDisconnect(con_global))

  # 全域 reactive 物件
  user_info    <- reactiveVal(NULL)   # 登入後的 user row

  sales_data   <- reactiveVal(NULL)   # 銷售資料

  # 設定資源路徑
  images_path <- if (dir.exists("www/images")) "www/images" else "www"
  addResourcePath("images", images_path)

  # 登入模組
  login_mod <- loginModuleServer("login1", con_global)
  observe({
    user_info(login_mod$user_info())
  })

  # 上傳模組
  upload_mod <- uploadModuleServer("upload1", con_global, user_info)
  observe({
    sales_data(upload_mod$dna_data())  # 將DNA資料傳遞給sales_data以供DNA模組使用
  })

  # 按「下一步」自動切換到DNA分析頁面
  observeEvent(upload_mod$proceed_step(), {
    if (!is.null(upload_mod$proceed_step()) && upload_mod$proceed_step() > 0 && !is.null(upload_mod$dna_data()) && nrow(upload_mod$dna_data()) > 0) {
      updateTabItems(session, "sidebar_menu", "dna_analysis")
    }
  }, ignoreInit = TRUE)

    # DNA 分析模組
    dna_mod <- dnaMultiModuleServer("dna_multi1", con_global, user_info, upload_mod$dna_data)

  # 登入狀態輸出
  output$user_logged_in <- reactive({
    !is.null(user_info())
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)

  # 歡迎訊息
  output$welcome_user <- renderText({
    if (!is.null(user_info())) {
      sprintf("%s (%s)", user_info()$username, user_info()$role)
    } else {
      ""
    }
  })

  # 用戶選單
  output$user_menu <- renderUI({
    req(user_info())
    div(
      style = "display: flex; align-items: center;",
      span(
        icon("user"), user_info()$username,
        style = "margin-right: 15px;"
      )
    )
  })

  # 資料庫狀態顯示
  output$db_status <- renderUI({
    if (dbIsValid(con_global)) {
      span(
        icon("database"), "資料庫已連接",
        style = "color: #28a745; margin-right: 15px;"
      )
    } else {
      span(
        icon("database"), "資料庫未連接",
        style = "color: #dc3545; margin-right: 15px;"
      )
    }
  })

  # 步驟指示器更新
  observe({
    if (!is.null(input$sidebar_menu)) {
      runjs("$('.step-item').removeClass('active completed');")
      if (input$sidebar_menu == "upload") {
        runjs("$('#step_1').addClass('active');")
      } else if (input$sidebar_menu == "dna_analysis") {
        runjs("$('#step_1').addClass('completed'); $('#step_2').addClass('active');")
      }
      # 關於頁面不影響步驟指示器狀態
    }
  })

  # 登出按鈕
  observeEvent(input$logout, {
    user_info(NULL); sales_data(NULL)
    # 也可呼叫 login_mod$logout() 來重置 module 狀態
    login_mod$logout()
  })


}

# ---- Run --------------------------------------------------------------------
shinyApp(ui, server)
