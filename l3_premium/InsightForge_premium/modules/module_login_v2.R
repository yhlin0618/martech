################################################################################
# InsightForge 登入模組 v2 - 優化版
# 基於 BrandEdge 架構，延遲資料庫連接以改善登入速度
################################################################################

#' Login & Register Module – UI
#' @param id module id
#' @param app_title 應用程式標題
#' @param app_icon 應用程式圖示路徑
loginModuleUI <- function(id, app_title = "InsightForge", app_icon = "assets/icons/app_icon.png") {
  ns <- NS(id)
  
  tagList(
    tags$style(HTML(paste0(
      ".login-container {",
      "  min-height: 100vh; display: flex; align-items: center; justify-content: center;",
      "  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }",
      ".login-card {",
      "  background: #fff; border-radius: 20px; box-shadow: 0 10px 40px rgba(0,0,0,0.1);",
      "  padding: 3rem 2rem; max-width: 400px; width: 100%; margin: 0 auto; text-align: center; }",
      ".login-icon { margin-bottom: 2rem; }",
      ".login-title { font-size: 1.8rem; font-weight: 600; color: #2c3e50; margin-bottom: 0.5rem; }",
      ".login-subtitle { font-size: 1rem; color: #7f8c8d; margin-bottom: 2rem; }",
      ".login-btn { width: 100%; font-size: 1.1rem; padding: 0.75rem; border-radius: 8px;",
      "  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);",
      "  border: none; color: white; font-weight: 500; transition: all 0.3s; }",
      ".login-btn:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102,126,234,0.4); }",
      ".login-link { color: #667eea; margin-top: 1.5rem; display: block; font-weight: 500; }",
      ".login-form .form-group { text-align: left; margin-bottom: 1.5rem; }",
      ".login-form label { font-weight: 500; color: #495057; margin-bottom: 0.5rem; }",
      ".login-form input { border-radius: 8px; border: 1px solid #dee2e6; padding: 0.5rem 1rem; }",
      ".login-form input:focus { border-color: #667eea; box-shadow: 0 0 0 0.2rem rgba(102,126,234,0.25); }",
      ".test-account { margin-top: 2rem; padding: 1rem; background: #f8f9fa; border-radius: 8px; }",
      ".test-account-title { font-size: 0.875rem; color: #6c757d; margin-bottom: 0.5rem; }",
      ".test-account-info { font-size: 0.9rem; color: #495057; font-family: monospace; }"
    ))),
    
    div(class = "login-container",
      div(id = ns("login_page"), class = "login-card",
        # Logo 和標題
        div(class = "login-icon",
          img(src = app_icon, height = "100px", alt = paste(app_title, "Logo"))
        ),
        div(class = "login-title", app_title),
        div(class = "login-subtitle", "精準行銷平台"),
        
        # 登入表單
        div(class = "login-form",
          div(class = "form-group",
            label(for = ns("login_user"), "帳號"),
            textInput(ns("login_user"), NULL, placeholder = "請輸入帳號")
          ),
          div(class = "form-group",  
            label(for = ns("login_pw"), "密碼"),
            passwordInput(ns("login_pw"), NULL, placeholder = "請輸入密碼")
          ),
          actionButton(ns("login_btn"), "登入系統", class = "login-btn"),
          actionLink(ns("to_register"), "沒有帳號？立即註冊", class = "login-link")
        ),
        
        # 測試帳號提示
        div(class = "test-account",
          div(class = "test-account-title", "測試帳號"),
          div(class = "test-account-info", "admin / admin123")
        ),
        
        # 訊息顯示
        uiOutput(ns("login_msg"))
      ),
      
      # 註冊頁面（隱藏）
      hidden(
        div(id = ns("register_page"), class = "login-card",
          div(class = "login-icon",
            icon("user-plus", style = "font-size: 60px; color: #667eea;")
          ),
          div(class = "login-title", "註冊新帳號"),
          div(class = "login-subtitle", "加入 InsightForge"),
          
          div(class = "login-form",
            div(class = "form-group",
              label(for = ns("reg_user"), "帳號"),
              textInput(ns("reg_user"), NULL, placeholder = "設定您的帳號")
            ),
            div(class = "form-group",
              label(for = ns("reg_pw"), "密碼"),
              passwordInput(ns("reg_pw"), NULL, placeholder = "至少6個字元")
            ),
            div(class = "form-group",
              label(for = ns("reg_pw2"), "確認密碼"),
              passwordInput(ns("reg_pw2"), NULL, placeholder = "再次輸入密碼")
            ),
            actionButton(ns("register_btn"), "建立帳號", class = "login-btn"),
            actionLink(ns("to_login"), "已有帳號？返回登入", class = "login-link")
          ),
          
          uiOutput(ns("register_msg"))
        )
      )
    )
  )
}

#' Login & Register Module – Server
#' 延遲資料庫初始化，只在登入時建立連接
#' @param id module id
#' @return reactiveValues list(user_info, logged_in, logout, db_con)
loginModuleServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # ── 模組變數 ─────────────────────────────────────────────────────────────
    ns <- session$ns
    user_info <- reactiveVal(NULL)
    db_con <- reactiveVal(NULL)  # 延遲初始化的資料庫連接
    
    # NULL 合併運算子
    `%||%` <- function(x, y) {
      if (is.null(x) || length(x) == 0 || (is.character(x) && !nzchar(x))) y else x
    }
    
    # ── 延遲資料庫連接函數 ───────────────────────────────────────────────────
    get_db_connection <- function() {
      if (is.null(db_con())) {
        con <- tryCatch({
          # 嘗試連接資料庫
          source("database/db_connection.R")
          get_con()
        }, error = function(e) {
          cat("⚠️ 資料庫連接失敗:", e$message, "\n")
          NULL
        })
        
        if (!is.null(con)) {
          # 初始化資料表
          init_user_tables(con)
          db_con(con)
        }
      }
      return(db_con())
    }
    
    # ── 初始化使用者資料表 ───────────────────────────────────────────────────
    init_user_tables <- function(con) {
      if (inherits(con, "SQLiteConnection")) {
        # SQLite 語法
        dbExecute(con, "
          CREATE TABLE IF NOT EXISTS users (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            username     TEXT UNIQUE,
            hash         TEXT,
            role         TEXT DEFAULT 'user',
            login_count  INTEGER DEFAULT 0
          );
        ")
      } else {
        # PostgreSQL 語法  
        dbExecute(con, "
          CREATE TABLE IF NOT EXISTS users (
            id           SERIAL PRIMARY KEY,
            username     TEXT UNIQUE,
            hash         TEXT,
            role         TEXT DEFAULT 'user',
            login_count  INTEGER DEFAULT 0
          );
        ")
      }
      
      # 檢查並創建測試用戶
      existing_users <- dbGetQuery(con, "SELECT COUNT(*) as count FROM users")
      if (existing_users$count == 0) {
        cat("📝 創建測試管理員用戶...\n")
        dbExecute(con, 
          "INSERT INTO users (username, hash, role, login_count) VALUES (?, ?, 'admin', 0)",
          params = list("admin", bcrypt::hashpw("admin123"))
        )
      }
    }
    
    # ── UI 頁面切換 ──────────────────────────────────────────────────────────
    observeEvent(input$to_register, {
      shinyjs::hide("login_page")
      shinyjs::show("register_page")
    })
    
    observeEvent(input$to_login, {
      shinyjs::hide("register_page")
      shinyjs::show("login_page")
    })
    
    # ── 註冊處理 ────────────────────────────────────────────────────────────
    observeEvent(input$register_btn, {
      req(input$reg_user, input$reg_pw, input$reg_pw2)
      
      # 驗證密碼
      if (input$reg_pw != input$reg_pw2) {
        output$register_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("exclamation-triangle"), " 兩次密碼不一致"
          )
        })
        return()
      }
      
      if (nchar(input$reg_pw) < 6) {
        output$register_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("exclamation-triangle"), " 密碼至少需要6個字元"
          )
        })
        return()
      }
      
      # 延遲取得資料庫連接
      con <- get_db_connection()
      if (is.null(con)) {
        output$register_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("database"), " 資料庫連接失敗"
          )
        })
        return()
      }
      
      # 檢查帳號是否存在
      exists <- dbGetQuery(con, 
        "SELECT 1 FROM users WHERE username = ?",
        params = list(input$reg_user)
      )
      
      if (nrow(exists) > 0) {
        output$register_msg <- renderUI({
          div(class = "alert alert-warning mt-3",
            icon("user-times"), " 此帳號已被使用"
          )
        })
        return()
      }
      
      # 創建新用戶
      dbExecute(con,
        "INSERT INTO users (username, hash, role, login_count) VALUES (?, ?, 'user', 0)",
        params = list(input$reg_user, bcrypt::hashpw(input$reg_pw))
      )
      
      output$register_msg <- renderUI({
        div(class = "alert alert-success mt-3",
          icon("check-circle"), " 註冊成功！請登入"
        )
      })
      
      # 自動填入帳號並切換到登入頁
      updateTextInput(session, "login_user", value = input$reg_user)
      Sys.sleep(1)  # 短暫延遲讓用戶看到成功訊息
      shinyjs::hide("register_page")
      shinyjs::show("login_page")
    })
    
    # ── 登入處理 ────────────────────────────────────────────────────────────
    observeEvent(input$login_btn, {
      req(input$login_user, input$login_pw)
      
      # 顯示載入中
      output$login_msg <- renderUI({
        div(class = "text-center mt-3",
          tags$div(class = "spinner-border text-primary", role = "status"),
          tags$span(class = "ml-2", "驗證中...")
        )
      })
      
      # 延遲取得資料庫連接
      con <- get_db_connection()
      if (is.null(con)) {
        output$login_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("database"), " 資料庫連接失敗，請稍後再試"
          )
        })
        return()
      }
      
      # 查詢用戶
      user_row <- dbGetQuery(con,
        "SELECT * FROM users WHERE username = ?",
        params = list(input$login_user)
      )
      
      if (nrow(user_row) == 0) {
        output$login_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("user-slash"), " 帳號不存在"
          )
        })
        return()
      }
      
      # 檢查登入次數限制
      login_count <- user_row$login_count %||% 0
      if (user_row$role != "admin" && login_count >= 100) {
        output$login_msg <- renderUI({
          div(class = "alert alert-warning mt-3",
            icon("ban"), " 已達登入次數上限，請聯絡管理員"
          )
        })
        return()
      }
      
      # 驗證密碼
      if (bcrypt::checkpw(input$login_pw, user_row$hash)) {
        # 更新登入次數（非管理員）
        if (user_row$role != "admin") {
          dbExecute(con,
            "UPDATE users SET login_count = login_count + 1 WHERE id = ?",
            params = list(user_row$id)
          )
        }
        
        # 設定用戶資訊
        user_info(user_row)
        
        output$login_msg <- renderUI({
          div(class = "alert alert-success mt-3",
            icon("check-circle"), " 登入成功！"
          )
        })
        
        # 隱藏登入頁面
        shinyjs::hide("login_page")
        shinyjs::hide("register_page")
      } else {
        output$login_msg <- renderUI({
          div(class = "alert alert-danger mt-3",
            icon("key"), " 密碼錯誤"
          )
        })
      }
    })
    
    # ── 登出函數 ────────────────────────────────────────────────────────────
    logout <- function() {
      user_info(NULL)
      
      # 清空輸入欄位
      updateTextInput(session, "login_user", value = "")
      updatePasswordInput(session, "login_pw", value = "")
      
      # 顯示登入頁面
      shinyjs::show("login_page")
      shinyjs::hide("register_page")
      
      # 清除訊息
      output$login_msg <- renderUI(NULL)
      output$register_msg <- renderUI(NULL)
    }
    
    # ── 返回值 ──────────────────────────────────────────────────────────────
    list(
      user_info = reactive(user_info()),
      logged_in = reactive(!is.null(user_info())),
      logout = logout,
      db_con = reactive(db_con())  # 提供資料庫連接給主應用
    )
  })
}