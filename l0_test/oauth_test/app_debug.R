# app_debug.R - 診斷版本
# 用於測試 OAuth 連線問題

library(shiny)
library(httr2)
library(jose)
library(openssl)

# === 讀環境變數 ===
ISSUER        <- Sys.getenv("OIDC_ISSUER")
CLIENT_ID     <- Sys.getenv("OIDC_CLIENT_ID")
CLIENT_SECRET <- Sys.getenv("OIDC_CLIENT_SECRET")
SCOPES        <- Sys.getenv("OIDC_SCOPES", "openid email profile")

# 固定使用此 Redirect URI
REDIRECT_URI  <- "https://kyleyhl-brandedge.share.connect.posit.cloud/?oidc_cb=1"

# 顯示配置狀態
cat("=== OAuth Configuration ===\n")
cat("ISSUER:", ISSUER, "\n")
cat("CLIENT_ID:", if(nzchar(CLIENT_ID)) "[SET]" else "[NOT SET]", "\n")
cat("REDIRECT_URI:", REDIRECT_URI, "\n")
cat("===========================\n\n")

# 初始化變數
AUTHZ_EP <- NULL
TOKEN_EP <- NULL
JWKS_URI <- NULL
USERINFO_EP <- NULL
discovery_error <- NULL

# 如果有 ISSUER，嘗試取得 Discovery
if (nzchar(ISSUER)) {
  cat("Attempting to fetch OIDC Discovery...\n")
  discovery_url <- paste0(ISSUER, "/.well-known/openid-configuration")
  cat("URL:", discovery_url, "\n")
  
  tryCatch({
    # 加入超時控制（5秒）
    oidc <- request(discovery_url) |>
      req_timeout(5) |>
      req_perform() |>
      resp_body_json()
    
    AUTHZ_EP <- oidc$authorization_endpoint
    TOKEN_EP <- oidc$token_endpoint
    JWKS_URI <- oidc$jwks_uri
    USERINFO_EP <- oidc$userinfo_endpoint
    
    cat("✓ Discovery successful!\n")
    cat("  - Authorization:", AUTHZ_EP, "\n")
    cat("  - Token:", TOKEN_EP, "\n")
    cat("  - JWKS:", JWKS_URI, "\n")
    cat("  - UserInfo:", USERINFO_EP %||% "N/A", "\n\n")
    
  }, error = function(e) {
    discovery_error <<- e$message
    cat("✗ Discovery failed!\n")
    cat("  Error:", e$message, "\n\n")
  })
}

# === 簡單的 UI ===
ui <- fluidPage(
  titlePanel("OAuth Test - Debug Mode"),
  
  h3("Environment Status"),
  verbatimTextOutput("env_status"),
  
  h3("Discovery Status"),
  verbatimTextOutput("discovery_status"),
  
  conditionalPanel(
    condition = "output.can_proceed == 'true'",
    h3("OAuth Flow"),
    p("Configuration successful! Ready to start OAuth flow."),
    actionButton("start_oauth", "Start OAuth Login", class = "btn-primary"),
    br(), br(),
    verbatimTextOutput("user_info")
  ),
  
  br(),
  h3("Troubleshooting"),
  verbatimTextOutput("troubleshooting")
)

# === Server ===
server <- function(input, output, session) {
  
  # 環境變數狀態
  output$env_status <- renderPrint({
    list(
      "OIDC_ISSUER" = if(nzchar(ISSUER)) ISSUER else "NOT SET",
      "OIDC_CLIENT_ID" = if(nzchar(CLIENT_ID)) "SET" else "NOT SET",
      "OIDC_CLIENT_SECRET" = if(nzchar(CLIENT_SECRET)) "SET" else "NOT SET",
      "OIDC_SCOPES" = SCOPES,
      "REDIRECT_URI" = REDIRECT_URI
    )
  })
  
  # Discovery 狀態
  output$discovery_status <- renderPrint({
    if (!nzchar(ISSUER)) {
      "No ISSUER configured"
    } else if (!is.null(discovery_error)) {
      paste("Failed:", discovery_error)
    } else if (!is.null(AUTHZ_EP)) {
      list(
        "Status" = "Success",
        "Authorization" = AUTHZ_EP,
        "Token" = TOKEN_EP,
        "JWKS" = JWKS_URI,
        "UserInfo" = USERINFO_EP %||% "N/A"
      )
    } else {
      "Unknown state"
    }
  })
  
  # 是否可以繼續
  output$can_proceed <- reactive({
    if (!is.null(AUTHZ_EP) && nzchar(CLIENT_ID)) "true" else "false"
  })
  outputOptions(output, "can_proceed", suspendWhenHidden = FALSE)
  
  # 疑難排解建議
  output$troubleshooting <- renderPrint({
    tips <- c()
    
    if (!nzchar(ISSUER)) {
      tips <- c(tips, "1. Set OIDC_ISSUER environment variable")
    }
    
    if (!nzchar(CLIENT_ID)) {
      tips <- c(tips, "2. Set OIDC_CLIENT_ID environment variable")
    }
    
    if (!is.null(discovery_error)) {
      tips <- c(tips, 
        "3. Check if WordPress OAuth Server is configured",
        "4. Verify the ISSUER URL is correct (no trailing slash)",
        "5. Check if .well-known/openid-configuration is accessible",
        "6. Test URL in browser: " %||% paste0(ISSUER, "/.well-known/openid-configuration"))
    }
    
    if (length(tips) == 0) {
      "No issues detected - ready to proceed!"
    } else {
      paste(tips, collapse = "\n")
    }
  })
  
  # OAuth 登入按鈕
  observeEvent(input$start_oauth, {
    if (!is.null(AUTHZ_EP) && nzchar(CLIENT_ID)) {
      state <- base64url_encode(rand_bytes(32))
      nonce <- base64url_encode(rand_bytes(32))
      verifier <- gsub("=+$", "", base64url_encode(rand_bytes(32)))
      challenge <- base64url_encode(sha256(charToRaw(verifier)))
      
      session$userData$oidc_state <- state
      session$userData$oidc_nonce <- nonce
      session$userData$code_verifier <- verifier
      
      auth_url <- paste0(
        AUTHZ_EP, "?response_type=code",
        "&client_id=", URLencode(CLIENT_ID),
        "&redirect_uri=", URLencode(REDIRECT_URI),
        "&scope=", URLencode(SCOPES),
        "&state=", state,
        "&nonce=", nonce,
        "&code_challenge_method=S256",
        "&code_challenge=", challenge
      )
      
      showModal(modalDialog(
        title = "OAuth Login",
        p("Redirecting to WordPress for login..."),
        p("Auth URL:", tags$code(auth_url)),
        footer = tagList(
          actionButton("do_redirect", "Proceed to Login", class = "btn-primary"),
          modalButton("Cancel")
        )
      ))
      
      observeEvent(input$do_redirect, {
        removeModal()
        session$sendCustomMessage("location", auth_url)
      })
    }
  })
  
  # 使用者資訊
  output$user_info <- renderPrint({
    if (!is.null(session$userData$user)) {
      session$userData$user
    } else {
      "Not logged in"
    }
  })
  
  # 處理 OAuth 回呼
  observe({
    q <- parseQueryString(isolate(session$clientData$url_search))
    if (!is.null(q$oidc_cb) && !is.null(q$code) && !is.null(q$state)) {
      # 這裡可以加入 code exchange 邏輯
      output$user_info <- renderPrint({
        list(
          "OAuth Callback Received" = TRUE,
          "Code" = substr(q$code, 1, 10),
          "State" = substr(q$state, 1, 10)
        )
      })
    }
  })
}

# 加入 JavaScript 重導向
ui <- tagList(
  tags$head(tags$script(HTML('
    Shiny.addCustomMessageHandler("location", function(url) {
      window.location.href = url;
    });
  '))),
  ui
)

shinyApp(ui, server)