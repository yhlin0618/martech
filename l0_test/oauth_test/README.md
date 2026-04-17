# OAuth Test - WordPress OIDC Integration

這是一個使用 OAuth 2.0 + PKCE 實現 WordPress SSO 的 Shiny 測試應用。

## 功能特點

- ✅ OAuth 2.0 Authorization Code Flow + PKCE
- ✅ OpenID Connect (OIDC) 身份驗證
- ✅ 自動發現端點 (/.well-known/openid-configuration)
- ✅ ID Token 簽章驗證 (JWKS)
- ✅ UserInfo 端點支援
- ✅ 角色型存取控制示例
- ✅ 完整錯誤處理與提示

## 部署前準備

### 1. WordPress 端設定

在您的 WordPress 安裝 **WP OAuth Server** 或 **miniOrange OAuth Server** 外掛，並：

1. 新增 OAuth Client：
   - **Grant Type**: Authorization Code（啟用 PKCE）
   - **Redirect URI**: `https://kyleyhl-brandedge.share.connect.posit.cloud/?oidc_cb=1`（一字不差）
   - **Scopes**: `openid email profile`
   - 儲存後記下 `client_id` 和 `client_secret`

2. 記下您的 WordPress 網域（例：`https://your-wp.example.com`）

### 2. 環境變數設定

#### 在 Posit Connect Cloud：
1. 進入應用的 Settings → Environment Variables
2. 新增以下變數：
   - `OIDC_ISSUER` = 您的 WordPress 網域
   - `OIDC_CLIENT_ID` = 您的 Client ID
   - `OIDC_CLIENT_SECRET` = 您的 Client Secret
   - `OIDC_SCOPES` = openid email profile

#### 本機開發：
1. 複製 `.env.example` 為 `.env`
2. 填入實際值
3. 使用 `dotenv::load_dot_env()` 或設定 `~/.Renviron`

## 安裝相依套件

```r
# 使用 pak（推薦）
pak::pak(c("shiny", "httr2", "jose", "openssl"))

# 或使用 install.packages
install.packages(c("shiny", "httr2", "jose", "openssl"))
```

## 執行應用

```r
# 本機執行
shiny::runApp("app.R")

# 或直接
Rscript app.R
```

## 測試檢查清單

- [ ] 開啟應用 → 自動導向 WordPress 登入
- [ ] 成功登入 → 返回應用顯示使用者資訊
- [ ] 顯示 sub/email/name 等基本資訊
- [ ] 若有 admin 角色 → 顯示管理員專區
- [ ] 點擊登出 → 清除 session 並重新導向登入

## 常見錯誤排除

### redirect_uri_mismatch
- **原因**：WordPress 後台設定的 Redirect URI 與應用不符
- **解決**：確認 WordPress OAuth Client 的 Redirect URI 設定為：
  ```
  https://kyleyhl-brandedge.share.connect.posit.cloud/?oidc_cb=1
  ```
  （注意大小寫、斜線、參數必須完全一致）

### invalid_client
- **原因**：Client ID 或 Secret 錯誤
- **解決**：檢查環境變數 `OIDC_CLIENT_ID` 和 `OIDC_CLIENT_SECRET`

### invalid_grant
- **原因**：授權碼無效或 PKCE 驗證失敗
- **解決**：
  1. 確認 WordPress 端已啟用 PKCE
  2. 檢查是否重複使用授權碼
  3. 確認 state/nonce 驗證

### Discovery 端點失敗
- **原因**：無法存取 OIDC 設定端點
- **解決**：
  1. 確認 `OIDC_ISSUER` 設定正確（不要有結尾斜線）
  2. 測試存取：`https://your-wp.com/.well-known/openid-configuration`

## 安全考量

1. **全程 HTTPS**：所有通訊必須使用 HTTPS
2. **State 驗證**：防止 CSRF 攻擊
3. **Nonce 驗證**：防止重放攻擊
4. **PKCE**：即使公開客戶端也能安全運作
5. **簽章驗證**：使用 JWKS 驗證 ID Token
6. **環境變數**：敏感資訊不寫死在程式碼中

## 進階設定

### 角色型存取控制

應用會自動檢查使用者的 `roles` 屬性。若包含 "admin"，會顯示管理員專區。

```r
# 在您的程式碼中使用：
user <- session$userData$user
if (!is.null(user$roles) && "admin" %in% user$roles) {
  # 顯示管理員功能
}
```

### 全域登出

若要實現全域登出（同時登出 WordPress），可修改登出處理：

```r
observeEvent(input$logout, {
  # 清除本地 session
  session$userData$user <- NULL
  session$userData$tokens <- NULL
  
  # 導向 WordPress 登出
  logout_url <- paste0(ISSUER, "/wp-login.php?action=logout")
  session$sendCustomMessage("redir", logout_url)
})
```

## 支援與問題回報

如遇到問題，請檢查：
1. 環境變數是否正確設定
2. WordPress OAuth Server 設定是否正確
3. 網路連線是否正常
4. 查看 R console 的錯誤訊息