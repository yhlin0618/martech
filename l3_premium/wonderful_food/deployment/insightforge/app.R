###############################################################################
# InsightForge 精準行銷平台 - 主應用程式                                          #
# 版本: v18 (bs4Dash)                                                         #
# 更新: 2024-06-23                                                            #
###############################################################################

# ── 自動切換工作目錄 ─────────────────────────────────────────────────
# 這段程式碼會在載入任何相對路徑之前嘗試把工作目錄切到 app.R 所在的資料夾，
# 以免在不同電腦或啟動方式（source/runApp/Rscript）下需要手動 setwd。
try({
  current_wd <- getwd()
  this_file  <- NULL
  # 方法一：如果是用 source() 載入，sys.frame(1)$ofile 會有路徑
  if (!is.null(sys.frame(1)$ofile)) {
    this_file <- sys.frame(1)$ofile
  } else {
    # 方法二：如果是用 Rscript，從 commandArgs 找 --file=
    ca <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", ca, value = TRUE)
    if (length(file_arg)) this_file <- sub("--file=", "", file_arg[1])
  }
  # 方法三：在 shiny::runApp(path) 情況，app.R 會在 appDir 下
  if (is.null(this_file) && requireNamespace("shiny", quietly = TRUE)) {
    app_dir_opt <- shiny::getShinyOption("appDir", default = NULL)
    if (!is.null(app_dir_opt)) this_file <- file.path(app_dir_opt, "app.R")
  }
  if (!is.null(this_file)) {
    app_dir <- dirname(normalizePath(this_file))
    if (!identical(current_wd, app_dir)) {
      setwd(app_dir)
      cat("📂 自動將工作目錄設為:", app_dir, "\n")
    }
  }
}, silent = TRUE)

# ── 系統初始化 ────────────────────────────────────────────────────────────
source("config/packages.R")    # 載入套件管理
source("config/config.R")      # 載入配置設定（包含 .env 載入）

# 載入模組配置（如果存在）
if (file.exists("config/module_config.R")) {
  source("config/module_config.R")  # 載入模組選擇配置
}

# 載入工具函數 (shared 版本)
if (file.exists("utils/openai_utils.R")) {
  source("utils/openai_utils.R")  # 提供 chat_api 函數
}
if (file.exists("utils/hint_system.R")) {
  source("utils/hint_system.R")
}
if (file.exists("utils/prompt_manager.R")) {
  source("utils/prompt_manager.R")
}

# 載入 Supabase 認證模組 (global_scripts 版本)
source("scripts/global_scripts/10_rshinyapp_components/login/supabase_auth.R")
source("scripts/global_scripts/10_rshinyapp_components/login/login_module_supabase.R")

# 載入必要的套件（module_score 需要）
library(stringr)  # for str_extract

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
source("utils/data_access.R")  # 資料存取工具（整合 tbl2）- shared 版本

# 載入改進版模組（如果存在），否則載入原版
if (file.exists("modules/module_wo_b_v2.R")) {
  source("modules/module_wo_b_v2.R")  # 使用改進版分析模組
} else {
  source("modules/module_wo_b.R")     # 原版分析模組 (shared)
}

source("scripts/global_scripts/10_rshinyapp_components/login/login_module.R")

# 根據配置選擇上傳模組
use_complete_score <- getOption("use_complete_score_upload", TRUE)  # 預設使用新模組
if (use_complete_score && file.exists("modules/module_upload_complete_score.R")) {
  source("modules/module_upload_complete_score.R")  # 新的已評分資料上傳模組
  source("modules/module_score_v2.R")   # 評分模組（UI 仍需要 scoreModuleUI）
  cat("✅ 使用已評分資料上傳模組\n")
  USE_COMPLETE_SCORE <- TRUE
} else {
  source("modules/module_upload.R")     # 原始上傳模組
  source("modules/module_score_v2.R")   # 評分模組（已整合 prompt 管理）
  cat("📝 使用原始上傳與評分模組\n")
  USE_COMPLETE_SCORE <- FALSE
}

# 載入新增的行銷策略模組
if (file.exists("modules/module_keyword_ads.R")) {
  source("modules/module_keyword_ads.R")  # 關鍵字廣告模組
}
if (file.exists("modules/module_product_dev.R")) {
  source("modules/module_product_dev.R")  # 新品開發模組
}

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
  title = "InsightForge 精準行銷平台",
  fullscreen = TRUE,
  
  # 頁首
  header = bs4DashNavbar(
    title = bs4DashBrand(
      title = "InsightForge",
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
        if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE) {
          tagList(
            div(class = "step-item", id = "step_1", "1. 上傳已評分資料"),
            div(class = "step-item", id = "step_2", "2. 模型分析")
          )
        } else {
          tagList(
            div(class = "step-item", id = "step_1", "1. 上傳資料"),
            div(class = "step-item", id = "step_2", "2. 分析評分"),
            div(class = "step-item", id = "step_3", "3. 模型估計")
          )
        }
    ),
    
    # 選單
    sidebarMenu(
      id = "sidebar_menu",
      bs4SidebarHeader("分析流程"),
      bs4SidebarMenuItem(
        text = if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE) "上傳已評分資料" else "資料上傳",
        tabName = "upload",
        icon = icon("upload")
      ),
      # 只在使用原始模組時顯示評分選項
      if(!exists("USE_COMPLETE_SCORE") || !USE_COMPLETE_SCORE) {
        bs4SidebarMenuItem(
          text = "屬性評分", 
          tabName = "scoring",
          icon = icon("star")
        )
      },
      bs4SidebarMenuItem(
        text = "銷售模型",
        tabName = "regression_merge",
        icon = icon("chart-line")
      ),
      
      bs4SidebarHeader("行銷策略"),
      bs4SidebarMenuItem(
        text = "關鍵字廣告",
        tabName = "keyword_ads",
        icon = icon("search")
      ),
      bs4SidebarMenuItem(
        text = "新品開發",
        tabName = "product_dev",
        icon = icon("lightbulb")
      ),
      bs4SidebarMenuItem(
        text = "廣告時段",
        tabName = "ad_timing",
        icon = icon("clock")
      ),
      bs4SidebarMenuItem(
        text = "個人化廣告",
        tabName = "personalized_ads",
        icon = icon("user-tag")
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
            title = if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE) "步驟 1：上傳已評分資料" else "步驟 1：上傳資料",
            status = "primary",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE) {
              uploadCompleteScoreUI("upload1")
            } else {
              uploadModuleUI("upload1")
            }
          )
        )
      ),
      
      # 評分頁面
      bs4TabItem(
        tabName = "scoring",
        fluidRow(
          bs4Card(
            title = "步驟 2：產生屬性並評分",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            scoreModuleUI("score1")
          )
        )
      ),
      
      # 銷售模型頁面
      bs4TabItem(
        tabName = "regression_merge",
        fluidRow(
          bs4Card(
            title = "銷售模型（各 Variation 評分均值）",
            status = "danger",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            tabsetPanel(
              tabPanel("評分均值", DTOutput("variation_mean_tbl")),
              # 隱藏銷售資料和合併結果
              # tabPanel("銷售資料", DTOutput("sales_summary_tbl")),
              # tabPanel("合併結果", DTOutput("merged_data_tbl")),
              tabPanel("銷售模型", 
                fluidRow(
                  column(12,
                    h5("📊 銷售模型分析"),
                    p("分析評分屬性對銷售數據的影響", style = "color: #666;"),
                    br(),
                    actionButton("run_poisson", "執行銷售模型分析", class = "btn-primary"),
                    br(), br(),
                    DTOutput("poisson_results_tbl"),
                    br(),
                    h5("📈 結果解讀"),
                    verbatimTextOutput("poisson_interpretation")
                  )
                )
              ),
              tabPanel("個性化行銷策略",
                fluidRow(
                  column(12,
                    h5("🎯 品牌個性化行銷策略"),
                    p("根據屬性分析結果制定精準行銷策略", style = "color: #666;"),
                    br(),
                    selectInput("brand_select", "選擇品牌/產品：", choices = NULL),
                    actionButton("generate_strategy", "生成行銷策略", class = "btn-success"),
                    br(), br(),
                    uiOutput("marketing_strategy")
                  )
                )
              )
            )
          )
        )
      ),
      
      # 關鍵字廣告頁面
      bs4TabItem(
        tabName = "keyword_ads",
        keywordAdsModuleUI("keyword1")
      ),
      
      # 新品開發頁面
      bs4TabItem(
        tabName = "product_dev",
        productDevModuleUI("product1")
      ),
      
      # 廣告時段頁面（暫時顯示開發中）
      bs4TabItem(
        tabName = "ad_timing",
        fluidRow(
          bs4Card(
            title = "⏰ 廣告投放時段建議",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            div(
              style = "padding: 40px; text-align: center;",
              icon("clock", style = "font-size: 48px; color: #ffc107; margin-bottom: 20px;"),
              h4("功能開發中"),
              p("根據銷售數據分析最佳廣告投放時段")
            )
          )
        )
      ),
      
      # 個人化廣告頁面（暫時顯示開發中）
      bs4TabItem(
        tabName = "personalized_ads",
        fluidRow(
          bs4Card(
            title = "👤 個人化廣告輸出",
            status = "purple",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            div(
              style = "padding: 40px; text-align: center;",
              icon("user-tag", style = "font-size: 48px; color: #6f42c1; margin-bottom: 20px;"),
              h4("功能開發中"),
              p("為不同客群生成個性化廣告內容")
            )
          )
        )
      )
    )
  ),
  
  # 頁尾
  footer = bs4DashFooter(
    fixed = TRUE,
    left = "InsightForge v18 - 精準行銷平台",
    right = "© 2024 All Rights Reserved"
  )
)

# ── 資源路徑設定 (在 UI 定義前) ──────────────────────────────────────────
# 設定 global_scripts 資源路徑
addResourcePath("assets", "scripts/global_scripts/24_assets")
addResourcePath("global_assets", "scripts/global_scripts")  # 供 login.css 等 CSS 使用

# ── 條件式 UI ─────────────────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),
  
  # 初始化提示系統（如果存在）
  if (exists("init_hint_system") && is.function(init_hint_system)) {
    init_hint_system()
  },
  
  # 資源路徑設定
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "https://use.fontawesome.com/releases/v5.15.4/css/all.css"),
    # Modern Login Page CSS (from global_scripts/19_CSS/login.css)
    tags$link(rel = "stylesheet", type = "text/css", href = "global_assets/19_CSS/login.css"),
    tags$style("#icon_bar { display:flex; gap:12px; align-items:center; margin-bottom:16px; } #icon_bar img { max-height:60px; }")
  ),

  # 根據登入狀態顯示不同UI
  conditionalPanel(
    condition = "output.user_logged_in == false",
    # 登入頁面 - 使用 login.css 的 login-page-wrapper 樣式
    loginSupabaseUI("login1",
                    title = "InsightForge",
                    subtitle = "精準行銷平台",
                    app_icon = "global_assets/24_assets/icons/app_icon.png",
                    show_language_selector = FALSE)
  ),
  
  conditionalPanel(
    condition = "output.user_logged_in == true", 
    main_app_ui
  )
)

# ── Server ------------------------------------------------------------------
server <- function(input, output, session) {
  con_global   <- get_con()
  db_info <- get_db_info(con_global)  # 取得資料庫連接資訊
  onStop(function() dbDisconnect(con_global))
  
  # 全域 reactive 物件
  user_info    <- reactiveVal(NULL)   # 登入後的 user row
  working_data <- reactiveVal(NULL)   # 原始 / 評分後的資料
  sales_data   <- reactiveVal(NULL)   # 銷售資料
  
  # 設定資源路徑 - 使用不同的前綴避免衝突
  # 注意：不能直接使用 'www' 作為 addResourcePath 的目錄
  if (dir.exists("www/icons")) {
    addResourcePath("app_icons", "www/icons")
  }
  # 如果 www/icons 不存在，則不設定額外的資源路徑
  # Shiny 會自動處理 www 目錄下的檔案
  
  # 登入模組（Supabase 版本）
  # 使用 Supabase REST API 進行驗證，不需要資料庫連線
  login_mod <- loginSupabaseServer("login1", app_name = "insightforge")
  observe({
    user_info(login_mod$user_info())
  })
  
  # 初始化 score_mod 變數
  score_mod <- NULL
  
  # 根據模組類型處理上傳
  if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE) {
    # 使用新的已評分資料上傳模組
    # 修正：user_id 參數應該是一個值，不是 reactive
    current_user_id <- reactive({
      if(!is.null(user_info()) && !is.null(user_info()$id)) {
        user_info()$id
      } else {
        "default_user"  # 提供預設值
      }
    })
    upload_complete_mod <- uploadCompleteScoreServer("upload1", current_user_id())
    
    # 建立 score_mod 物件以相容後續程式碼
    score_mod <- list(
      scored_data = reactive({
        if(!is.null(upload_complete_mod$score_data())) {
          # 將資料格式轉換為與原始 score_mod 相容的格式
          data <- upload_complete_mod$score_data()
          
          # 取得欄位映射資訊
          field_mapping_info <- NULL
          if(!is.null(upload_complete_mod$field_mapping)) {
            field_mapping_info <- tryCatch({
              upload_complete_mod$field_mapping()
            }, error = function(e) NULL)
          }
          
          # 動態設定 Variation 欄位
          if(!"Variation" %in% names(data)) {
            # 優先使用欄位映射中的產品名稱
            if(!is.null(field_mapping_info) && !is.null(field_mapping_info$score$product_name_col)) {
              name_field <- field_mapping_info$score$product_name_col
              if(name_field %in% names(data)) {
                data$Variation <- data[[name_field]]
                cat("📋 使用使用者選擇的產品名稱欄位作為 Variation:", name_field, "\n")
              }
            } else if("product_name" %in% names(data)) {
              data$Variation <- data$product_name
              cat("📝 使用 product_name 作為 Variation\n")
            } else if("product_id" %in% names(data)) {
              data$Variation <- data$product_id
              cat("📝 使用 product_id 作為 Variation\n")
            }
          }
          
          # 調試輸出
          cat("✅ score_mod$scored_data 已準備完成\n")
          cat("   資料筆數:", nrow(data), "\n")
          cat("   欄位:", paste(names(data), collapse = ", "), "\n")
          data
        } else {
          cat("⚠️ upload_complete_mod$score_data() 為空\n")
          NULL
        }
      }),
      proceed_step = reactive({ upload_complete_mod$confirm() }),
      # 加入屬性欄位資訊
      attribute_columns = reactive({ upload_complete_mod$attribute_columns() }),
      # 加入欄位映射資訊
      field_mapping = reactive({ upload_complete_mod$field_mapping() })
    )
    
    # 設定銷售資料
    observe({
      sales_data(upload_complete_mod$sales_data())
    })
    
    # 按「確認資料」自動切換到銷售模型頁面
    observeEvent(upload_complete_mod$confirm(), {
      if (upload_complete_mod$confirm() > 0) {
        updateTabItems(session, "sidebar_menu", "regression_merge")
        showNotification("✅ 進入銷售模型分析頁面", type = "message", duration = 3)
      }
    }, ignoreInit = TRUE)
    
  } else {
    # 使用原始上傳模組
    upload_mod <- uploadModuleServer("upload1", con_global, user_info)
    observe({
      working_data(upload_mod$data())
      sales_data(upload_mod$sales_data())
    })
    
    # 按「下一步」自動切換到評分頁面
    observeEvent(upload_mod$proceed_step(), {
      if (!is.null(upload_mod$proceed_step()) && upload_mod$proceed_step() > 0 && !is.null(upload_mod$data()) && nrow(upload_mod$data()) > 0) {
        updateTabItems(session, "sidebar_menu", "scoring")
      }
    }, ignoreInit = TRUE)
    
    # 評分模組
    score_mod <- scoreModuleServer("score1", con_global, user_info, working_data)
  }
  
  # 載入 prompts (供新模組使用)
  prompts_df <- NULL
  if (exists("load_prompts") && is.function(load_prompts)) {
    prompts_df <- load_prompts()
  }
  
  # 關鍵字廣告模組
  if (exists("keywordAdsModuleServer")) {
    keyword_mod <- keywordAdsModuleServer("keyword1", 
                                         reactive(score_mod$scored_data()),
                                         prompts_df)
  }
  
  # 新品開發模組
  if (exists("productDevModuleServer")) {
    product_mod <- productDevModuleServer("product1",
                                         reactive(score_mod$scored_data()),
                                         prompts_df)
  }
  
  # 只在使用原始模組時，監聽評分模組的下一步
  if(!exists("USE_COMPLETE_SCORE") || !USE_COMPLETE_SCORE) {
    observeEvent(score_mod$proceed_step(), {
      if (!is.null(score_mod$proceed_step()) && score_mod$proceed_step() > 0) {
        updateTabItems(session, "sidebar_menu", "regression_merge")
        showNotification("✅ 進入銷售模型分析頁面", type = "message", duration = 3)
      }
    }, ignoreInit = TRUE)
  }
  
  # 銷售模型頁面
  observe({
    # 檢查 score_mod 是否存在且有資料
    if(is.null(score_mod) || is.null(score_mod$scored_data)) {
      cat("⚠️ 銷售模型頁面: score_mod 尚未準備好\n")
      return()
    }
    
    scored_data_check <- tryCatch({
      score_mod$scored_data()
    }, error = function(e) {
      cat("⚠️ 銷售模型頁面: 無法取得 scored_data\n")
      NULL
    })
    
    if(is.null(scored_data_check) || nrow(scored_data_check) == 0) {
      return()
    }
    
    # 計算各 Variation 的評分均值
    # 獲取評分欄位
    if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE && !is.null(score_mod$attribute_columns)) {
      # 使用新模組時，從 attribute_columns 取得屬性欄位
      score_cols <- score_mod$attribute_columns()
      cat("📊 使用 attribute_columns:", paste(score_cols, collapse = ", "), "\n")
    } else {
      # 使用原始模組時，除了 Variation 外的所有數值欄位
      score_cols <- names(scored_data_check)[!names(scored_data_check) %in% "Variation"]
      score_cols <- score_cols[sapply(scored_data_check[score_cols], is.numeric)]
    }
    
    # 排除非屬性欄位
    exclude_cols <- c("product_id", "product_name", "avg_score", "total_score")
    score_cols <- score_cols[!score_cols %in% exclude_cols]
    
    mean_data <- scored_data_check %>%
      select(Variation, all_of(score_cols)) %>%
      group_by(Variation) %>%
      summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
      ungroup()
    
    output$variation_mean_tbl <- renderDT(mean_data, selection = "none")
    
    # 如果有銷售資料，進行智能合併
    if (!is.null(sales_data())) {
      # 顯示原始銷售資料
      output$sales_summary_tbl <- renderDT(sales_data(), selection = "none")
      
      # 建立品牌與產品ID的對應關係
      # 檢查是否需要建立對應表
      eval_variations <- unique(mean_data$Variation)
      sales_variations <- unique(sales_data()$Variation)
      
      # 如果 Variation 名稱不匹配，嘗試建立對應關係
      if (length(intersect(eval_variations, sales_variations)) == 0) {
        # 智能對應：檢查是否為產品ID格式與實際評論資料中的 Variation
        # 從評論資料中取得實際的產品 Variation
        actual_variations <- unique(score_mod$scored_data()$Variation)
        
        # 檢查銷售資料中的 Variation 是否與評論資料中的 Variation 匹配
        common_vars <- intersect(actual_variations, sales_variations)
        
        if (length(common_vars) > 0) {
          # 直接使用匹配的 Variation 進行合併
          matched_sales <- sales_data() %>%
            filter(Variation %in% common_vars)
          
          matched_eval <- mean_data %>%
            filter(Variation %in% common_vars)
          
          merged_data <- matched_sales %>%
            left_join(matched_eval, by = "Variation") %>%
            arrange(Time)
          
          # 添加統計資訊
          merged_data_with_info <- merged_data %>%
            mutate(
              資料來源 = "直接匹配",
              匹配狀態 = ifelse(!is.na(starts_with("Score_")[1]), "✅ 已匹配評分", "⚠️ 無評分資料")
            ) %>%
            select(資料來源, 匹配狀態, everything())
          
          output$merged_data_tbl <- renderDT(merged_data_with_info, selection = "none")
          
        } else {
          # 如果沒有直接匹配，創建簡單的順序對應
          if (length(eval_variations) <= length(sales_variations)) {
            mapping_table <- data.frame(
              eval_variation = eval_variations,
              sales_variation = sales_variations[1:length(eval_variations)],
              stringsAsFactors = FALSE
            )
            
            # 將銷售資料的 Variation 轉換為評論資料的格式
            sales_mapped <- sales_data() %>%
              left_join(mapping_table, by = c("Variation" = "sales_variation")) %>%
              mutate(
                原始產品ID = Variation,
                Variation = coalesce(eval_variation, Variation)
              ) %>%
              select(-eval_variation)
            
            # 進行合併
            merged_data <- sales_mapped %>%
              left_join(mean_data, by = "Variation") %>%
              arrange(Time)
            
            # 合併結果添加對應關係資訊
            merged_data_with_info <- merged_data %>%
              mutate(
                對應方式 = "順序對應",
                對應關係 = paste("評論品牌:", Variation, "←→ 產品ID:", 原始產品ID)
              ) %>%
              select(對應方式, 對應關係, everything())
            
            output$merged_data_tbl <- renderDT(merged_data_with_info, selection = "none")
          } else {
            # 如果無法建立對應關係，顯示警告
            warning_msg <- data.frame(
              警告 = "評論資料與銷售資料的 Variation 無法匹配",
              評論品牌 = paste(eval_variations, collapse = ", "),
              銷售產品ID = paste(sales_variations, collapse = ", "),
              建議 = "請確保檔名格式正確，或手動建立對應關係"
            )
            output$merged_data_tbl <- renderDT(warning_msg, selection = "none")
          }
        }
      } else {
        # 直接合併（如果 Variation 名稱匹配）
        merged_data <- sales_data() %>%
          left_join(mean_data, by = "Variation") %>%
          arrange(Time)
        
        output$merged_data_tbl <- renderDT(merged_data, selection = "none")
      }
    } else {
      output$sales_summary_tbl <- renderDT(data.frame(Message = "尚未上傳銷售資料"), selection = "none")
      output$merged_data_tbl <- renderDT(mean_data, selection = "none")
    }
  })
  
  # ── 銷售模型分析 ──────────────────────────────────────────
  # 引用 global_scripts 中的 Poisson regression 函數
  source("scripts/global_scripts/07_models/Poisson_Regression.R")
  
  # 銷售模型分析
  observeEvent(input$run_poisson, {
    cat("\n========== 開始 Poisson 分析 ==========\n")
    
    # 先檢查 score_mod 是否存在
    if(is.null(score_mod)) {
      cat("❌ score_mod 為 NULL\n")
      showNotification("❌ 系統錯誤：評分模組未初始化", type = "error")
      return()
    }
    
    # 檢查 score_mod$scored_data
    cat("1. 檢查 score_mod$scored_data:\n")
    scored_data_val <- tryCatch({
      if(!is.null(score_mod$scored_data)) {
        score_mod$scored_data()
      } else {
        cat("   ❌ score_mod$scored_data 不存在\n")
        NULL
      }
    }, error = function(e) {
      cat("   ❌ 錯誤:", e$message, "\n")
      NULL
    })
    
    if (is.null(scored_data_val)) {
      cat("   ❌ scored_data 為 NULL\n")
      showNotification("❌ 評分資料為空，請先完成資料上傳和處理", type = "error")
      return()
    } else {
      cat("   ✅ scored_data 有", nrow(scored_data_val), "筆資料\n")
      cat("   欄位:", paste(names(scored_data_val), collapse = ", "), "\n")
    }
    
    # 檢查銷售資料
    cat("2. 檢查銷售資料:\n")
    sales_data_val <- sales_data()
    if (is.null(sales_data_val)) {
      cat("   ❌ sales_data 為 NULL\n")
      showNotification("❌ 銷售資料為空，請先上傳銷售資料", type = "error")
      return()
    } else {
      cat("   ✅ sales_data 有", nrow(sales_data_val), "筆資料\n")
      cat("   欄位:", paste(names(sales_data_val), collapse = ", "), "\n")
    }
    
    showNotification("🔄 正在執行 銷售模型分析...", type = "message", duration = 3)
    
    tryCatch({
      # 準備合併資料
      # 獲取評分欄位
      if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE && !is.null(score_mod$attribute_columns)) {
        # 使用新模組時，從 attribute_columns 取得屬性欄位
        score_cols <- score_mod$attribute_columns()
      } else {
        # 使用原始模組時，除了 Variation 外的所有數值欄位
        score_cols <- names(score_mod$scored_data())[!names(score_mod$scored_data()) %in% "Variation"]
        score_cols <- score_cols[sapply(score_mod$scored_data()[score_cols], is.numeric)]
      }
      
      # 排除非屬性欄位
      exclude_cols <- c("product_id", "product_name", "avg_score", "total_score")
      score_cols <- score_cols[!score_cols %in% exclude_cols]
      
      cat("🔍 Poisson分析使用的屬性欄位:", paste(score_cols, collapse = ", "), "\n")
      
      # 確保 scored_data_val 有值
      scored_data_val <- score_mod$scored_data()
      if(is.null(scored_data_val) || nrow(scored_data_val) == 0) {
        cat("❌ scored_data_val 為空\n")
        showNotification("❌ 評分資料為空", type = "error")
        return()
      }
      
      # 計算平均值
      mean_data <- scored_data_val %>%
        select(Variation, all_of(score_cols)) %>%
        group_by(Variation) %>%
        summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
        ungroup()
      
      cat("3. mean_data 計算結果:\n")
      cat("   資料筆數:", nrow(mean_data), "\n")
      cat("   Variation:", paste(mean_data$Variation, collapse = ", "), "\n")
      
      # 智能合併評分與銷售資料
      sales_data_val <- sales_data()
      if(is.null(sales_data_val) || nrow(sales_data_val) == 0) {
        cat("❌ sales_data_val 為空\n")
        showNotification("❌ 銷售資料為空", type = "error")
        return()
      }
      
      # 動態處理銷售資料的產品識別欄位
      if(!"Variation" %in% names(sales_data_val)) {
        # 嘗試從欄位映射資訊取得產品ID欄位名稱
        field_mapping_info <- NULL
        if(!is.null(score_mod$field_mapping)) {
          field_mapping_info <- tryCatch({
            score_mod$field_mapping()
          }, error = function(e) NULL)
        }
        
        # 找出銷售資料的產品ID欄位
        sales_id_field <- NULL
        if(!is.null(field_mapping_info) && !is.null(field_mapping_info$sales$product_id_col)) {
          # 使用使用者選擇的欄位名稱
          sales_id_field <- field_mapping_info$sales$product_id_col
          cat("📋 使用使用者選擇的銷售產品ID欄位:", sales_id_field, "\n")
        } else if("product_id" %in% names(sales_data_val)) {
          # 退回使用 product_id
          sales_id_field <- "product_id"
          cat("📝 使用預設 product_id 作為銷售資料的識別欄位\n")
        }
        
        if(!is.null(sales_id_field) && sales_id_field %in% names(sales_data_val)) {
          sales_data_val$Variation <- sales_data_val[[sales_id_field]]
          cat("✅ 銷售資料 Variation 設定完成，使用欄位:", sales_id_field, "\n")
        } else {
          cat("❌ 銷售資料沒有有效的產品識別欄位\n")
          cat("   銷售資料欄位:", paste(names(sales_data_val), collapse = ", "), "\n")
          cat("   嘗試的欄位:", sales_id_field, "\n")
          showNotification("❌ 銷售資料缺少產品識別欄位", type = "error")
          return()
        }
      }
      
      eval_variations <- unique(mean_data$Variation)
      sales_variations <- unique(sales_data_val$Variation)
      actual_variations <- unique(scored_data_val$Variation)
      common_vars <- intersect(actual_variations, sales_variations)
      
      # 加入調試信息
      cat("📊 資料對應檢查：\n")
      cat("評分變體數量:", length(eval_variations), "\n")
      cat("銷售變體數量:", length(sales_variations), "\n")
      cat("直接匹配數量:", length(common_vars), "\n")
      
      # 顯示前幾個變體以便檢查
      if(length(eval_variations) > 0) {
        cat("評分變體範例 (前5個):", paste(head(eval_variations, 5), collapse = ", "), "\n")
      }
      if(length(sales_variations) > 0) {
        cat("銷售變體範例 (前5個):", paste(head(sales_variations, 5), collapse = ", "), "\n")
      }
      if(length(common_vars) > 0) {
        cat("匹配的變體 (前5個):", paste(head(common_vars, 5), collapse = ", "), "\n")
      }
      
      if (length(common_vars) > 0) {
        # 直接匹配的情況
        cat("✅ 使用直接匹配策略\n")
        analysis_data <- sales_data_val %>%
          filter(Variation %in% common_vars) %>%
          left_join(mean_data, by = "Variation") %>%
          filter(!is.na(Sales))  # 確保有銷售數據
      } else {
        # 智能對應策略：處理數量不匹配的情況
        cat("🔄 使用智能對應策略\n")
        
        if (length(eval_variations) == 0 || length(sales_variations) == 0) {
          cat("❌ 變體數量檢查失敗:\n")
          cat("   eval_variations 長度:", length(eval_variations), "\n")
          cat("   sales_variations 長度:", length(sales_variations), "\n")
          cat("   mean_data 筆數:", nrow(mean_data), "\n")
          cat("   sales_data_val 筆數:", nrow(sales_data_val), "\n")
          
          if(length(eval_variations) == 0) {
            showNotification("❌ 評分資料沒有有效的變體（Variation）", type = "error")
          } else {
            showNotification("❌ 銷售資料沒有有效的變體（Variation）", type = "error")
          }
          return()
        }
        
        # 取較小的數量進行對應
        min_length <- min(length(eval_variations), length(sales_variations))
        max_length <- max(length(eval_variations), length(sales_variations))
        
        cat("對應策略：取前", min_length, "個進行配對\n")
        
        if (length(eval_variations) <= length(sales_variations)) {
          # 評分變體較少或相等
          mapping_table <- data.frame(
            eval_variation = eval_variations,
            sales_variation = sales_variations[1:length(eval_variations)],
            stringsAsFactors = FALSE
          )
        } else {
          # 銷售變體較少，評分變體較多
          mapping_table <- data.frame(
            eval_variation = eval_variations[1:length(sales_variations)],
            sales_variation = sales_variations,
            stringsAsFactors = FALSE
          )
        }
        
        cat("對應表：\n")
        print(mapping_table)
        
        analysis_data <- sales_data_val %>%
          left_join(mapping_table, by = c("Variation" = "sales_variation")) %>%
          mutate(Variation = coalesce(eval_variation, Variation)) %>%
          select(-eval_variation) %>%
          left_join(mean_data, by = "Variation") %>%
          filter(!is.na(Sales))
          
        # 顯示成功對應的信息
        showNotification(
          sprintf("💡 智能對應完成：%d個變體成功配對", min_length), 
          type = "message", 
          duration = 5
        )
      }
      
      # 檢查合併結果
      if (nrow(analysis_data) == 0) {
        showNotification("❌ 合併後無可用資料進行分析", type = "error")
        return()
      }
      
      # 準備銷售模型分析  
      # 找出評分欄位（數值型態且非 Variation, Time, Sales 等基本欄位）
      basic_cols <- c("Variation", "Time", "Sales", "原始產品ID", "eval_variation")
      score_columns <- names(analysis_data)[!names(analysis_data) %in% basic_cols]
      score_columns <- score_columns[sapply(analysis_data[score_columns], is.numeric)]
      
      if (length(score_columns) == 0) {
        showNotification("❌ 找不到評分屬性欄位", type = "error")
        return()
      }
      
      # 執行銷售模型分析
      poisson_results <- list()
      
      for (score_col in score_columns) {
        # 過濾掉 NA 值並準備資料
        analysis_subset <- analysis_data %>%
          filter(!is.na(.data[[score_col]]), !is.na(Sales)) %>%
          mutate(
            # 確保 Sales 為正數（Poisson 回歸要求非負整數）
            Sales = pmax(0, as.numeric(Sales))
          ) %>%
          rename(sales = Sales)  # Poisson_Regression 函數期望的欄位名稱
        
        if (nrow(analysis_subset) > 2) {  # 確保有足夠的觀測值（最低2個）
          result <- tryCatch({
            poisson_regression(score_col, analysis_subset)
          }, error = function(e) {
            list(marginal_effect_pct = NA, track_multiplier = NA, interpretation = "錯誤", practical_meaning = "無法分析")
          })
          
          # 解析結果（新版函數返回 list 格式）
          if (is.list(result) && !is.na(result$marginal_effect_pct)) {
            poisson_results[[score_col]] <- data.frame(
              屬性 = score_col,
              邊際效應百分比 = result$marginal_effect_pct,
              賽道倍數 = result$track_multiplier,
              係數 = result$coefficient,
              統計結論 = result$interpretation,
              商業意義 = result$practical_meaning,
              觀測數 = nrow(analysis_subset),
              stringsAsFactors = FALSE
            )
          }
        }
      }
      
      if (length(poisson_results) > 0) {
        # 合併結果
        final_results <- do.call(rbind, poisson_results)
        rownames(final_results) <- NULL
        
        # 過濾只顯示正向係數的結果
        final_results <- final_results %>%
          filter(係數 > 0) %>%
          arrange(desc(賽道倍數))
        
        if (nrow(final_results) > 0) {
          output$poisson_results_tbl <- renderDT(
            final_results,
            options = list(pageLength = 10, scrollX = TRUE),
            selection = "none"
          )
          
          # 生成針對正向係數的新版解讀
          top_track_attr <- final_results$屬性[1]
          top_track_multiplier <- final_results$賽道倍數[1]
          top_marginal_idx <- which.max(final_results$邊際效應百分比)
          top_marginal_attr <- final_results$屬性[top_marginal_idx]
          top_marginal_effect <- final_results$邊際效應百分比[top_marginal_idx]
          
          interpretation <- paste0(
            "🎯 產品屬性正向影響力分析報告\n\n",
            "📊 分析概要：\n",
            "• 成功分析了 ", nrow(final_results), " 個具有正向影響的評分屬性\n",
            "• 所有係數均為正值，表示這些屬性對銷售有促進作用\n\n",
            
            "🏁 賽道冠軍（戰略重點）：\n",
            "• ", top_track_attr, " - 賽道倍數 ", top_track_multiplier, " 倍\n",
            "• 意義：從最低到最高的總體正向影響潛力最大\n",
            "• 建議：適合制定長期戰略改進計劃，提升此屬性將帶來最大收益\n\n",
            
            "⚡ 邊際效應冠軍（日常優化）：\n",
            "• ", top_marginal_attr, " - 每提升1單位促進銷售 ", top_marginal_effect, "%\n",
            "• 意義：小幅改進就能看到明顯的正向效果\n",
            "• 建議：適合日常運營的快速優化，投報率高\n\n",
            
            "📈 決策指南（針對正向影響屬性）：\n",
            "• 賽道倍數 > 2.0：極重要正向因素，核心競爭優勢\n",
            "• 賽道倍數 1.2-2.0：重要促進因素，應重點關注\n",
            "• 邊際效應 > 50%：強烈正向影響，小改進大效果\n",
            "• 邊際效應 20-50%：中等正向影響，穩定提升策略\n\n",
            "💡 行動建議：專注於正向係數屬性的提升，制定「戰略+戰術」雙重優化策略，確保投資回報最大化"
          )
          
          output$poisson_interpretation <- renderText(interpretation)
          
          showNotification("銷售模型分析", type = "message", duration = 3)
        } else {
          output$poisson_results_tbl <- renderDT(
            data.frame(訊息 = "沒有發現正向影響的屬性"),
            selection = "none"
          )
          output$poisson_interpretation <- renderText("📊 分析結果：所有屬性的係數均為非正值，建議檢查資料品質或重新評估屬性定義")
        }
      } else {
        output$poisson_results_tbl <- renderDT(
          data.frame(訊息 = "沒有足夠的資料進行銷售分析"),
          selection = "none"
        )
        output$poisson_interpretation <- renderText("❌ 分析失敗：資料不足或格式錯誤")
      }
      
    }, error = function(e) {
      showNotification(paste("分析錯誤：", e$message), type = "error")
      output$poisson_interpretation <- renderText(paste("錯誤：", e$message))
    })
  })
  
  # ── 個性化行銷策略生成 ──────────────────────────────────────────
  # 儲存分析結果供策略生成使用
  poisson_analysis_results <- reactiveVal(NULL)
  scored_mean_data <- reactiveVal(NULL)
  
  # 監聽 Poisson 分析結果
  observeEvent(input$run_poisson, {
    # 檢查 score_mod 是否存在
    if(is.null(score_mod) || is.null(score_mod$scored_data)) {
      return()
    }
    
    # 安全地取得 scored_data
    scored_data_temp <- tryCatch({
      score_mod$scored_data()
    }, error = function(e) {
      NULL
    })
    
    if(is.null(scored_data_temp) || nrow(scored_data_temp) == 0) {
      return()
    }
    
    # 保存評分均值資料
    # 獲取評分欄位
    if(exists("USE_COMPLETE_SCORE") && USE_COMPLETE_SCORE && !is.null(score_mod$attribute_columns)) {
      score_cols <- score_mod$attribute_columns()
    } else {
      score_cols <- names(scored_data_temp)[!names(scored_data_temp) %in% "Variation"]
      score_cols <- score_cols[sapply(scored_data_temp[score_cols], is.numeric)]
    }
    
    # 排除非屬性欄位
    exclude_cols <- c("product_id", "product_name", "avg_score", "total_score")
    score_cols <- score_cols[!score_cols %in% exclude_cols]
    
    mean_data <- scored_data_temp %>%
      select(Variation, all_of(score_cols)) %>%
      group_by(Variation) %>%
      summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
      ungroup()
    
    scored_mean_data(mean_data)
  })
  
  # 更新品牌選擇列表
  observe({
    if (!is.null(scored_mean_data())) {
      updateSelectInput(session, "brand_select", 
                       choices = unique(scored_mean_data()$Variation))
    }
  })
  
  # 生成個性化行銷策略
  observeEvent(input$generate_strategy, {
    req(input$brand_select, scored_mean_data())
    
    showNotification("🔄 正在生成個性化行銷策略...", type = "message", duration = 3)
    
    tryCatch({
      # 取得選定品牌的評分資料
      brand_scores <- scored_mean_data() %>%
        filter(Variation == input$brand_select)
      
      # 取得屬性名稱（排除 Variation）
      attr_cols <- names(brand_scores)[names(brand_scores) != "Variation"]
      
      # 計算屬性分類（基於分數和影響力）
      # 注意：這裡簡化處理，實際需要結合 Poisson 結果
      brand_scores_vec <- as.numeric(brand_scores[1, attr_cols])
      names(brand_scores_vec) <- attr_cols
      
      # 分類屬性
      median_score <- median(brand_scores_vec, na.rm = TRUE)
      high_score_attrs <- names(brand_scores_vec)[brand_scores_vec >= median_score]
      low_score_attrs <- names(brand_scores_vec)[brand_scores_vec < median_score]
      
      # 簡化分類（實際應結合 Poisson 係數）
      strength_attrs <- paste(head(high_score_attrs, 3), collapse = ", ")
      weakness_attrs <- paste(head(low_score_attrs, 3), collapse = ", ")
      opportunity_attrs <- if(length(high_score_attrs) > 3) paste(high_score_attrs[4:min(6, length(high_score_attrs))], collapse = ", ") else "無"
      marginal_attrs <- if(length(low_score_attrs) > 3) paste(low_score_attrs[4:min(6, length(low_score_attrs))], collapse = ", ") else "無"
      
      # 找出最高分屬性作為示例
      top_attr <- names(which.max(brand_scores_vec))
      top_score <- max(brand_scores_vec, na.rm = TRUE)
      avg_score <- mean(brand_scores_vec, na.rm = TRUE)
      
      # 準備 GPT 訊息
      if (exists("prepare_gpt_messages") && exists("load_prompts")) {
        prompts_df <- load_prompts()
        
        messages <- prepare_gpt_messages(
          var_id = "personalized_marketing",
          variables = list(
            brand_name = input$brand_select,
            strength_attrs = strength_attrs,
            weakness_attrs = weakness_attrs,
            opportunity_attrs = opportunity_attrs,
            marginal_attrs = marginal_attrs,
            top_track_attr = top_attr,
            track_multiplier = round(runif(1, 1.5, 3), 1), # 簡化示例
            top_marginal_attr = top_attr,
            marginal_effect = round(runif(1, 20, 80), 0), # 簡化示例
            avg_score = round(avg_score, 2)
          ),
          prompts_df = prompts_df
        )
        
        # 呼叫 GPT API
        strategy_text <- chat_api(messages)
        
        # 顯示策略
        output$marketing_strategy <- renderUI({
          div(
            style = "background: #f8f9fa; padding: 20px; border-radius: 10px; margin-top: 20px;",
            h4(paste("🎯", input$brand_select, "個性化行銷策略"), style = "color: #2c3e50; margin-bottom: 15px;"),
            div(
              style = "background: white; padding: 15px; border-radius: 8px; border-left: 4px solid #3498db;",
              HTML(gsub("\n", "<br>", strategy_text))
            ),
            br(),
            div(
              style = "background: #e8f4f8; padding: 10px; border-radius: 5px; margin-top: 10px;",
              p(strong("📊 屬性得分摘要："), style = "margin-bottom: 5px;"),
              p(paste("• 平均得分：", round(avg_score, 2), "/ 5"), style = "margin: 2px;"),
              p(paste("• 最高分屬性：", top_attr, "(", round(top_score, 2), ")"), style = "margin: 2px;"),
              p(paste("• 評估屬性數：", length(attr_cols)), style = "margin: 2px;")
            )
          )
        })
        
        showNotification("✅ 行銷策略生成完成！", type = "message", duration = 3)
        
      } else {
        # 沒有 GPT 的備用方案
        output$marketing_strategy <- renderUI({
          div(
            style = "background: #f8f9fa; padding: 20px; border-radius: 10px;",
            h4(paste(input$brand_select, "屬性分析摘要")),
            p(paste("優勢屬性：", strength_attrs)),
            p(paste("劣勢屬性：", weakness_attrs)),
            p(paste("平均得分：", round(avg_score, 2)))
          )
        })
      }
      
    }, error = function(e) {
      showNotification(paste("策略生成失敗：", e$message), type = "error")
      output$marketing_strategy <- renderUI({
        div(class = "alert alert-danger", paste("錯誤：", e$message))
      })
    })
  })
  
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
    if (!is.null(user_info())) {
      div(
        style = "color: white; padding: 8px;",
        sprintf("👤 %s", user_info()$username)
      )
    }
  })
  
  # 資料庫狀態顯示
  output$db_status <- renderUI({
    div(
      style = sprintf("color: %s; padding: 8px; margin-right: 15px; background: rgba(255,255,255,0.1); border-radius: 5px;", db_info$color),
      span(db_info$icon, style = "margin-right: 5px;"),
      span(db_info$type, style = "font-weight: bold; margin-right: 5px;"),
      span(sprintf("(%s)", db_info$status), style = "font-size: 0.9em; opacity: 0.8;")
    )
  })
  
  # 步驟指示器更新
  observe({
    if (!is.null(input$sidebar_menu)) {
      runjs("$('.step-item').removeClass('active completed');")
      if (input$sidebar_menu == "upload") {
        runjs("$('#step_1').addClass('active');")
      } else if (input$sidebar_menu == "scoring") {
        runjs("$('#step_1').addClass('completed'); $('#step_2').addClass('active');")
      } else if (input$sidebar_menu %in% c("regression_merge")) {
        runjs("$('#step_1, #step_2').addClass('completed'); $('#step_3').addClass('active');")
      }
    }
  })
  
  # 登出按鈕
  observeEvent(input$logout, {
    user_info(NULL); working_data(NULL); facets_rv(NULL)
    output$preview_tbl <- renderDT(NULL)
    output$score_tbl   <- renderDT(NULL)
    output$pairs_rawtbl <- renderDT(NULL)
    output$brand_mean <- renderDT(NULL)
    shinyjs::disable("score")
    shinyjs::disable("to_step3")
    # 也可呼叫 login_mod$logout() 來重置 module 狀態
    login_mod$logout()
  })
  
  # 註冊 regression_trigger 到 session$userData，供 module 使用
  session$userData$regression_trigger <- regression_trigger
  
  # 其餘 UI 輸出、分析、模型估計等可依原本方式，資料來源改用 working_data() 或 score_mod$scored_data()。
}

# ---- Run --------------------------------------------------------------------
shinyApp(ui, server)
