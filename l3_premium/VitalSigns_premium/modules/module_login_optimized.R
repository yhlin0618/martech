################################################################################
# VitalSigns 優化登入模組 - 延遲載入資料庫
# 參考 BrandEdge 設計模式
################################################################################

#' Login & Register Module – UI
#' @param id  module id
loginModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$style(HTML(paste0(
      ".login-mobile-bg {",
      "  min-height: 100vh; display: flex; align-items: center; justify-content: center; background: #f5f6fa; }",
      ".login-mobile-card {",
      "  background: #fff; border-radius: 20px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); padding: 2.5rem 1.5rem 2rem 1.5rem; max-width: 350px; width: 100%; margin: 0 auto; text-align: center; }",
      ".login-mobile-icon { margin-bottom: 1.5rem; }",
      ".login-mobile-title { font-size: 1.5rem; font-weight: 600; color: #222; margin-bottom: 1.5rem; }",
      ".login-mobile-btn { width: 100%; font-size: 1.1rem; padding: 0.75rem; border-radius: 8px; }",
      ".login-mobile-link { color: #007bff; margin-top: 1rem; display: block; }",
      ".login-mobile-form .form-group { text-align: left; }",
      ".login-mobile-form label { font-weight: 500; }"
    ))),
    div(class = "login-mobile-bg",
      div(id = ns("login_page"), class = "login-mobile-card",
        div(class = "login-mobile-icon",
            img(src = "images/icon.png", height = "90px", alt = "VitalSigns Logo")
        ),
        div(class = "login-mobile-title", "VitalSigns Premium"),
        div(class = "login-mobile-form",
          textInput(ns("login_user"), "帳號"),
          passwordInput(ns("login_pw"), "密碼"),
          actionButton(ns("login_btn"), "登入", class = "btn-primary login-mobile-btn"),
          br(),
          actionLink(ns("to_register"), "沒有帳號？點此註冊", class = "login-mobile-link"),
          verbatimTextOutput(ns("login_msg"))
        )
      ),
      hidden(
        div(id = ns("register_page"), class = "login-mobile-card",
            h2("📝 註冊新帳號", style = "font-size:1.2rem; margin-bottom:1.5rem;"),
            textInput(ns("reg_user"), "帳號"),
            passwordInput(ns("reg_pw"), "密碼"),
            passwordInput(ns("reg_pw2"), "確認密碼"),
            actionButton(ns("register_btn"), "註冊", class = "btn-success login-mobile-btn"), br(),
            actionLink(ns("to_login"), "已有帳號？回登入", class = "login-mobile-link"),
            verbatimTextOutput(ns("register_msg"))
        )
      )
    )
  )
}

#' Login & Register Module – Server (優化版本)
#' 只連接用戶資料庫，不載入其他資料表
#' @param id module id
#' @param auth_con 僅用於認證的資料庫連接
#' @return reactiveValues list(user_info = reactive, logged_in = reactive, logout = function())
loginModuleServer <- function(id, auth_con = NULL) {
  moduleServer(id, function(input, output, session) {
    # ── helpers --------------------------------------------------------------
    show  <- shinyjs::show
    hide  <- shinyjs::hide
    ns    <- session$ns
    
    user_info <- reactiveVal(NULL)
    
    # 如果沒有提供連接，使用輕量級的認證連接
    if (is.null(auth_con)) {
      auth_con <- get_auth_connection()
    }
    
    # ---- UI page switches --------------------------------------------------
    observeEvent(input$to_register, { hide("login_page"); show("register_page") })
    observeEvent(input$to_login,    { hide("register_page"); show("login_page") })
    
    # ---- 註冊 --------------------------------------------------------------
    observeEvent(input$register_btn, {
      req(input$reg_user, input$reg_pw, input$reg_pw2)
      if (input$reg_pw != input$reg_pw2)
        return(output$register_msg <- renderText("❌ 兩次密碼不一致"))
      if (nchar(input$reg_pw) < 6)
        return(output$register_msg <- renderText("❌ 密碼至少 6 個字元"))
      
      # 使用認證連接查詢
      exists <- auth_db_query(auth_con, 
                              "SELECT 1 FROM users WHERE username=?", 
                              params = list(input$reg_user))
      if (nrow(exists) > 0)
        return(output$register_msg <- renderText("❌ 帳號已存在"))
      
      # 創建新用戶
      auth_db_execute(auth_con,
                     "INSERT INTO users (username,hash,role,login_count) VALUES (?,?, 'user',0)",
                     params = list(input$reg_user, bcrypt::hashpw(input$reg_pw)))
      
      output$register_msg <- renderText("✅ 註冊成功！請登入")
      updateTextInput(session, "login_user", value = input$reg_user)
      hide("register_page"); show("login_page")
    })
    
    # ---- 登入 --------------------------------------------------------------
    observeEvent(input$login_btn, {
      req(input$login_user, input$login_pw)
      
      # 使用認證連接查詢用戶
      row <- auth_db_query(auth_con,
                          "SELECT * FROM users WHERE username=?", 
                          params = list(input$login_user))
      
      if (nrow(row) == 0) 
        return(output$login_msg <- renderText("❌ 帳號不存在"))
      
      used <- row$login_count %||% 0
      if (row$role != "admin" && used >= 100)  # 放寬限制至100次
        return(output$login_msg <- renderText("⛔ 已達登入次數上限"))
      
      if (bcrypt::checkpw(input$login_pw, row$hash)) {
        if (row$role != "admin") {
          auth_db_execute(auth_con,
                         "UPDATE users SET login_count=login_count+1 WHERE id=?", 
                         params = list(row$id))
        }
        user_info(row)
        output$login_msg <- renderText("✅ 登入成功！載入資料中...")
      } else {
        output$login_msg <- renderText("❌ 帳號或密碼錯誤")
      }
    })
    
    # ---- public reactive & logout ----------------------------------------
    observeEvent(user_info(), {
      if (!is.null(user_info())) {
        hide("login_page"); hide("register_page")
      }
    })
    
    # expose a logout trigger so parent can hide/show pages
    list(
      user_info = reactive(user_info()),
      logged_in = reactive(!is.null(user_info())),
      logout = function() {
        user_info(NULL)
        show("login_page")
        hide("register_page")
      }
    )
  })
}