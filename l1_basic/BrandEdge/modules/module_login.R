
################################################################################
# 1⃣  module_login.R -----------------------------------------------------------
################################################################################

#' Login & Register Module – UI
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
            img(src = "images/icon.png", height = "90px", id = "icon_main")
        ),
        div(class = "login-mobile-title", "Vital Signs"),
        div(class = "login-mobile-form",
          textInput(ns("login_user"), "帳號"),
          passwordInput(ns("login_pw"), "密碼"),
          actionButton(ns("login_btn"), "登入", class = "btn-primary login-mobile-btn"),
          br(),
          actionLink(ns("to_register"), "沒有帳號？點此註冊", class = "login-mobile-link"),
          includeMarkdown("md/contacts.md"),
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
            includeMarkdown("md/contacts.md"),
            verbatimTextOutput(ns("register_msg"))
        )
      )
    )
  )
}

#' Login & Register Module – Server
#'
#' @return reactiveValues list(user_info = reactive, logged_in = reactive, logout = function())
loginModuleServer <- function(id, con) {
  moduleServer(id, function(input, output, session) {
    # ── helpers --------------------------------------------------------------
    show  <- shinyjs::show
    hide  <- shinyjs::hide
    ns    <- session$ns
    
    user_info <- reactiveVal(NULL)
    
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
      
      exists <- dbGetQuery(con, "SELECT 1 FROM users WHERE username=?", params = list(input$reg_user))
      if (nrow(exists))
        return(output$register_msg <- renderText("❌ 帳號已存在"))
      
      dbExecute(con, "INSERT INTO users (username,hash,role,login_count) VALUES (?,?, 'user',0)",
                params = list(input$reg_user, bcrypt::hashpw(input$reg_pw)))
      output$register_msg <- renderText("✅ 註冊成功！請登入")
      updateTextInput(session, "login_user", value = input$reg_user)
      hide("register_page"); show("login_page")
    })
    
    # ---- 登入 --------------------------------------------------------------
    observeEvent(input$login_btn, {
      req(input$login_user, input$login_pw)
      row <- dbGetQuery(con, "SELECT * FROM users WHERE username=?", params = list(input$login_user))
      if (!nrow(row)) return(output$login_msg <- renderText("❌ 帳號不存在"))
      
      used <- row$login_count %||% 0
      if (row$role != "admin" && used >= 5)
        return(output$login_msg <- renderText("⛔ 已達登入次數上限"))
      
      if (bcrypt::checkpw(input$login_pw, row$hash)) {
        if (row$role != "admin")
          dbExecute(con, "UPDATE users SET login_count=login_count+1 WHERE id=?", params = list(row$id))
        user_info(row)
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
