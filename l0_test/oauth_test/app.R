# app.R  — oauth_test
# WordPress OIDC SSO for Shiny App
# 需要套件：shiny, httr2, jose, openssl
# 安裝：pak::pak(c("shiny","httr2","jose","openssl"))

library(shiny)
library(httr2)
library(jose)
library(openssl)

# === 讀環境變數 ===
ISSUER        <- Sys.getenv("OIDC_ISSUER")           # 例: https://your-wp.example.com
CLIENT_ID     <- Sys.getenv("OIDC_CLIENT_ID")
CLIENT_SECRET <- Sys.getenv("OIDC_CLIENT_SECRET")    # 若採公開客戶端+PKCE，可為空字串
SCOPES        <- Sys.getenv("OIDC_SCOPES", "openid email profile")

# Redirect URI - 優先使用環境變數，否則使用固定值
REDIRECT_URI <- Sys.getenv("OIDC_REDIRECT_URI", "https://kyleyhl-oauth-test.share.connect.posit.cloud/?oidc_cb=1")

# 顯示環境變數狀態（除錯用）
cat("=== OAuth Configuration Status ===\n")
cat("OIDC_ISSUER:", if(nzchar(ISSUER)) paste0("[SET: ", ISSUER, "]") else "[NOT SET]", "\n")
cat("OIDC_CLIENT_ID:", if(nzchar(CLIENT_ID)) "[SET]" else "[NOT SET]", "\n")
cat("OIDC_CLIENT_SECRET:", if(nzchar(CLIENT_SECRET)) "[SET]" else "[NOT SET/EMPTY]", "\n")
cat("OIDC_SCOPES:", SCOPES, "\n")
cat("REDIRECT_URI:", REDIRECT_URI, "\n")
cat("==================================\n")

# 檢查必要變數
if (!nzchar(ISSUER)) {
  cat("ERROR: OIDC_ISSUER environment variable is not set\n")
  cat("Please set it in Posit Connect: Settings > Environment Variables\n")
  cat("Example: OIDC_ISSUER=https://your-wordpress-site.com\n")
  stop("Missing required environment variable: OIDC_ISSUER")
}
if (!nzchar(CLIENT_ID)) {
  cat("ERROR: OIDC_CLIENT_ID environment variable is not set\n")
  cat("Please set it in Posit Connect: Settings > Environment Variables\n")
  stop("Missing required environment variable: OIDC_CLIENT_ID")
}

# === 讀取 OIDC Discovery ===
tryCatch({
  oidc <- request(paste0(ISSUER, "/.well-known/openid-configuration")) |>
    req_perform() |>
    resp_body_json()
  
  AUTHZ_EP <- oidc$authorization_endpoint
  TOKEN_EP <- oidc$token_endpoint
  JWKS_URI <- oidc$jwks_uri
  USERINFO_EP <- oidc$userinfo_endpoint %||% NULL
  
}, error = function(e) {
  stop(paste0(
    "無法取得 OIDC Discovery 端點。請確認 OIDC_ISSUER 設定正確。\n",
    "嘗試存取：", ISSUER, "/.well-known/openid-configuration\n",
    "錯誤訊息：", e$message
  ))
})

# === 小工具 ===
b64url <- function(n = 32) jose::base64url_encode(openssl::rand_bytes(n))
code_verifier  <- function() gsub("=+$", "", jose::base64url_encode(openssl::rand_bytes(32)))
code_challenge <- function(v) jose::base64url_encode(openssl::sha256(charToRaw(v)))

# === UI ===
ui <- fluidPage(
  tags$head(
    tags$script(HTML(
      "Shiny.addCustomMessageHandler('redir', function(url){ window.location.href = url; });"
    )),
    tags$style(HTML("
      .user-info { 
        background: #f8f9fa; 
        padding: 15px; 
        border-radius: 8px; 
        margin: 20px 0;
      }
      .admin-panel {
        background: #fff3cd;
        padding: 15px;
        border-radius: 8px;
        border: 1px solid #ffc107;
        margin: 20px 0;
      }
      .error-msg {
        color: #dc3545;
        font-weight: bold;
      }
    "))
  ),
  
  titlePanel("OAuth Test — Shiny via WordPress OIDC"),
  
  conditionalPanel(
    condition = "output.isLoggedIn == 'true'",
    div(class = "user-info",
      h4("使用者資訊"),
      verbatimTextOutput("whoami")
    ),
    
    conditionalPanel(
      condition = "output.isAdmin == 'true'",
      div(class = "admin-panel",
        h4("🔑 管理員專區"),
        p("您擁有管理員權限，可以存取進階功能。"),
        actionButton("adminAction", "執行管理員動作", class = "btn-warning")
      )
    ),
    
    hr(),
    actionButton("logout", "登出", class = "btn-danger"),
    br(), br(),
    
    h4("Token 資訊（除錯用）"),
    verbatimTextOutput("tokenInfo")
  ),
  
  conditionalPanel(
    condition = "output.isLoggedIn != 'true'",
    div(
      h4("正在重新導向至 WordPress 登入..."),
      p("如果沒有自動跳轉，請重新整理頁面。")
    )
  ),
  
  # 錯誤訊息區域
  uiOutput("errorMsg")
)

# === Server ===
server <- function(input, output, session) {
  
  # 動態生成 Redirect URI（如果沒有手動設定）
  if (!nzchar(REDIRECT_URI)) {
    # 從 session 中取得當前應用的 URL
    observe({
      req(session$clientData$url_protocol, session$clientData$url_hostname)
      
      base_url <- paste0(
        session$clientData$url_protocol, "//",
        session$clientData$url_hostname
      )
      
      # 如果有 port，加上 port
      if (!is.null(session$clientData$url_port) && session$clientData$url_port != "") {
        base_url <- paste0(base_url, ":", session$clientData$url_port)
      }
      
      # 如果有 pathname，加上 pathname
      if (!is.null(session$clientData$url_pathname) && session$clientData$url_pathname != "/") {
        base_url <- paste0(base_url, session$clientData$url_pathname)
      }
      
      # 設定全域 REDIRECT_URI
      REDIRECT_URI <<- paste0(base_url, "?oidc_cb=1")
      cat("Dynamic Redirect URI:", REDIRECT_URI, "\n")
    })
  }
  
  # Reactive values for error handling
  rv <- reactiveValues(
    error = NULL
  )
  
  do_login_flow <- function() {
    state <- b64url(); nonce <- b64url()
    ver <- code_verifier(); chall <- code_challenge(ver)
    
    session$userData$oidc_state <- state
    session$userData$oidc_nonce <- nonce
    session$userData$code_verifier <- ver
    
    # 確保有正確的 Redirect URI
    redirect_uri <- if (nzchar(REDIRECT_URI)) {
      REDIRECT_URI
    } else {
      # 動態生成
      paste0(
        session$clientData$url_protocol, "//",
        session$clientData$url_hostname,
        if (!is.null(session$clientData$url_port) && session$clientData$url_port != "") 
          paste0(":", session$clientData$url_port) else "",
        if (!is.null(session$clientData$url_pathname) && session$clientData$url_pathname != "/") 
          session$clientData$url_pathname else "/",
        "?oidc_cb=1"
      )
    }
    
    auth_url <- paste0(
      AUTHZ_EP, "?response_type=code",
      "&client_id=", URLencode(CLIENT_ID),
      "&redirect_uri=", URLencode(redirect_uri),
      "&scope=", URLencode(SCOPES),
      "&state=", state,
      "&nonce=", nonce,
      "&code_challenge_method=S256",
      "&code_challenge=", chall
    )
    
    cat("=== Starting OAuth Flow ===\n")
    cat("Auth URL:", auth_url, "\n")
    cat("Redirect URI:", redirect_uri, "\n")
    cat("===========================\n")
    
    session$sendCustomMessage("redir", auth_url)
  }
  
  exchange_code <- function(code, state_from_query) {
    tryCatch({
      # 驗 STATE（CSRF）
      if (!identical(state_from_query, session$userData$oidc_state)) {
        stop("State 不符：可能是 CSRF 攻擊或 session 過期。請重新登入。")
      }
      
      form <- list(
        grant_type    = "authorization_code",
        code          = code,
        redirect_uri  = REDIRECT_URI,
        client_id     = CLIENT_ID,
        code_verifier = session$userData$code_verifier
      )
      if (nzchar(CLIENT_SECRET)) form$client_secret <- CLIENT_SECRET
      
      token_resp <- request(TOKEN_EP) |>
        req_body_form(!!!form) |>
        req_headers(`Content-Type` = "application/x-www-form-urlencoded") |>
        req_perform()
      
      token <- resp_body_json(token_resp)
      
      # 檢查是否有 ID Token
      if (is.null(token$id_token)) {
        stop("No id_token returned - 請確認 WordPress OAuth Server 的 scope 設定包含 'openid'")
      }
      
      # 取 ID Token 並驗簽
      idt <- token$id_token
      jwks <- request(JWKS_URI) |> req_perform() |> resp_body_json()
      claims <- jose::jwt_decode_sig(idt, jose::read_jwk(jwks))
      
      # 基本宣告檢查
      if (claims$iss != ISSUER) {
        stop(paste("Issuer 不符。預期:", ISSUER, "實際:", claims$iss))
      }
      
      aud <- if (is.null(claims$aud)) claims$client_id else claims$aud
      if (!(CLIENT_ID %in% aud)) {
        stop(paste("Audience 不符。預期包含:", CLIENT_ID))
      }
      
      if (claims$exp <= as.numeric(Sys.time())) {
        stop("ID Token 已過期")
      }
      
      if (claims$nonce != session$userData$oidc_nonce) {
        stop("Nonce 不符：可能是重放攻擊")
      }
      
      # （可選）呼叫 /userinfo 拿更多屬性
      userinfo <- NULL
      if (!is.null(USERINFO_EP) && !is.null(token$access_token)) {
        tryCatch({
          userinfo <- request(USERINFO_EP) |>
            req_auth_bearer_token(token$access_token) |>
            req_perform() |>
            resp_body_json(simplifyVector = TRUE)
        }, error = function(e) {
          # UserInfo endpoint 失敗不應阻止登入
          warning(paste("UserInfo endpoint 呼叫失敗:", e$message))
        })
      }
      
      # 建立本地 session
      session$userData$user <- list(
        sub   = claims$sub,
        email = claims$email %||% userinfo$email %||% NA_character_,
        name  = claims$name  %||% userinfo$name  %||% NA_character_,
        roles = claims$roles %||% userinfo$roles %||% NULL,
        picture = claims$picture %||% userinfo$picture %||% NULL,
        preferred_username = claims$preferred_username %||% userinfo$preferred_username %||% NULL
      )
      session$userData$tokens <- token
      
      # 清一次性變數
      session$userData$oidc_state <- NULL
      session$userData$oidc_nonce <- NULL
      session$userData$code_verifier <- NULL
      
    }, error = function(e) {
      # 處理各種錯誤情況
      error_msg <- e$message
      
      if (grepl("redirect_uri_mismatch", error_msg, ignore.case = TRUE)) {
        rv$error <- paste0(
          "Redirect URI 不符：\n",
          "WordPress 後台設定的 Redirect URI 必須與以下完全一致：\n",
          REDIRECT_URI, "\n",
          "（包括大小寫、斜線、參數）"
        )
      } else if (grepl("invalid_grant", error_msg, ignore.case = TRUE)) {
        rv$error <- "授權碼無效或已過期。請確認 PKCE (code_verifier/code_challenge) 設定，或授權碼是否已被使用過。"
      } else if (grepl("invalid_client", error_msg, ignore.case = TRUE)) {
        rv$error <- "Client 認證失敗。請確認 CLIENT_ID 和 CLIENT_SECRET 設定正確，且在 WordPress OAuth Server 中已啟用。"
      } else {
        rv$error <- paste("登入失敗：", error_msg)
      }
      
      # 清除狀態，準備重試
      session$userData$oidc_state <- NULL
      session$userData$oidc_nonce <- NULL
      session$userData$code_verifier <- NULL
    })
  }
  
  # ---- 進入點：尚未登入就發起 OIDC ----
  observe({
    if (!is.null(session$userData$user)) return()
    
    q <- parseQueryString(isolate(session$clientData$url_search))
    
    # 檢查是否有錯誤參數（OAuth 錯誤回呼）
    if (!is.null(q$error)) {
      rv$error <- paste0(
        "OAuth 錯誤: ", q$error,
        if (!is.null(q$error_description)) paste0("\n描述: ", q$error_description) else ""
      )
      return()
    }
    
    if (!is.null(q$oidc_cb) && !is.null(q$code) && !is.null(q$state)) {
      # 回呼階段：檢查是否有對應的 state
      if (is.null(session$userData$oidc_state)) {
        # State 不存在，可能是新 session 或過期
        cat("Session expired or new browser session detected.\n")
        cat("Restarting OAuth flow...\n")
        
        # 重新開始 OAuth 流程（會導向 WordPress 登入/授權頁面）
        do_login_flow()
        return()
      }
      # 用 code 換 token
      exchange_code(q$code, q$state)
    } else if (is.null(rv$error) && is.null(q$oidc_cb)) {
      # 尚未回呼且無錯誤：導去 WordPress 登入
      do_login_flow()
    }
  })
  
  # 顯示目前身分
  output$whoami <- renderPrint({
    user <- session$userData$user
    if (is.null(user)) {
      "尚未登入"
    } else {
      list(
        "使用者 ID (sub)" = user$sub,
        "電子郵件" = user$email,
        "顯示名稱" = user$name,
        "使用者名稱" = user$preferred_username,
        "角色" = if (!is.null(user$roles)) paste(user$roles, collapse = ", ") else "無",
        "頭像" = user$picture
      )
    }
  })
  
  # Token 資訊（除錯用）
  output$tokenInfo <- renderPrint({
    tokens <- session$userData$tokens
    if (is.null(tokens)) {
      "無 Token"
    } else {
      list(
        "Access Token" = if (!is.null(tokens$access_token)) 
          paste0(substr(tokens$access_token, 1, 20), "...") else "無",
        "Token Type" = tokens$token_type,
        "Expires In" = paste(tokens$expires_in, "秒"),
        "Scope" = tokens$scope,
        "ID Token" = if (!is.null(tokens$id_token)) 
          paste0(substr(tokens$id_token, 1, 20), "...") else "無"
      )
    }
  })
  
  # 錯誤訊息顯示
  output$errorMsg <- renderUI({
    if (!is.null(rv$error)) {
      div(class = "error-msg",
        h4("❌ 錯誤"),
        pre(rv$error),
        actionButton("retry", "重試", class = "btn-primary")
      )
    }
  })
  
  # 重試按鈕
  observeEvent(input$retry, {
    rv$error <- NULL
    # 清除 URL 參數並重新載入
    session$sendCustomMessage("redir", strsplit(session$clientData$url_href, "?", fixed = TRUE)[[1]][1])
  })
  
  # 登入狀態輸出（供 conditionalPanel 使用）
  output$isLoggedIn <- reactive({
    if (!is.null(session$userData$user)) "true" else "false"
  })
  outputOptions(output, "isLoggedIn", suspendWhenHidden = FALSE)
  
  # 管理員狀態輸出
  output$isAdmin <- reactive({
    user <- session$userData$user
    if (!is.null(user) && !is.null(user$roles) && "admin" %in% user$roles) {
      "true"
    } else {
      "false"
    }
  })
  outputOptions(output, "isAdmin", suspendWhenHidden = FALSE)
  
  # 管理員動作示例
  observeEvent(input$adminAction, {
    showModal(modalDialog(
      title = "管理員功能",
      "這是只有管理員才能看到和執行的功能。",
      footer = modalButton("關閉")
    ))
  })
  
  # 登出（清 session）
  observeEvent(input$logout, {
    session$userData$user <- NULL
    session$userData$tokens <- NULL
    
    # 可選：如果 WordPress 有提供全域登出端點，可以在此加入
    # logout_url <- paste0(ISSUER, "/wp-login.php?action=logout")
    # session$sendCustomMessage("redir", logout_url)
    
    # 重新載入頁面
    session$reload()
  })
}

shinyApp(ui, server)