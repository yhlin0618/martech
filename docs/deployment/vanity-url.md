# Posit Connect Vanity URL 設定指南

⚠️ **重要**：Vanity URL 只能在部署後設定，無法在部署時自動配置。

## 什麼是 Vanity URL？

Posit Connect Cloud 預設會產生隨機 URL（如 `https://connect.posit.cloud/content/abc123def456/`），
可以設定自訂的 Vanity URL 讓網址更好記。

## 方法一：手動設定（UI）

1. 登入 [Posit Connect Cloud](https://connect.posit.cloud/)
2. 找到已部署的應用程式
3. 點擊右上角「Settings」（齒輪圖示）
4. 在「Vanity URL」區段輸入名稱
5. 點擊「Save」

## 方法二：API 自動設定（R）

### 取得內容 GUID

```r
library(httr)
library(jsonlite)

connect_server <- Sys.getenv("CONNECT_SERVER")
api_key <- Sys.getenv("CONNECT_API_KEY")

response <- GET(
  paste0(connect_server, "__api__/v1/content"),
  add_headers(Authorization = paste("Key", api_key))
)

content_list <- content(response)
# 找到應用程式的 guid
```

### 設定 Vanity URL

```r
content_guid <- "YOUR-CONTENT-GUID"
vanity_path <- "positioning"

response <- PUT(
  paste0(connect_server, "__api__/v1/content/", content_guid, "/vanity"),
  add_headers(Authorization = paste("Key", api_key)),
  body = list(path = vanity_path),
  encode = "json"
)

if (status_code(response) == 200) {
  cat("✅ Vanity URL 設定成功！\n")
} else {
  cat("❌ 設定失敗\n")
}
```

### 部署後自動設定函數

```r
deploy_with_vanity <- function(app_dir, app_name, vanity_path) {
  cat("📤 部署應用程式...\n")
  deployment <- rsconnect::deployApp(
    appDir = app_dir,
    appName = app_name,
    server = "connect.posit.cloud",
    forceUpdate = TRUE
  )

  Sys.sleep(5)

  connect_server <- Sys.getenv("CONNECT_SERVER")
  api_key <- Sys.getenv("CONNECT_API_KEY")

  response <- GET(
    paste0(connect_server, "__api__/v1/content"),
    add_headers(Authorization = paste("Key", api_key)),
    query = list(name = app_name)
  )

  content_list <- content(response)

  if (length(content_list) > 0) {
    content_guid <- content_list[[1]]$guid
    vanity_response <- PUT(
      paste0(connect_server, "__api__/v1/content/", content_guid, "/vanity"),
      add_headers(Authorization = paste("Key", api_key)),
      body = list(path = vanity_path),
      encode = "json"
    )

    if (status_code(vanity_response) == 200) {
      cat("✅ Vanity URL 設定成功：", paste0(connect_server, vanity_path, "/\n"))
    } else {
      cat("⚠️ 設定失敗，請手動在 Connect 設定\n")
    }
  }
}
```

## URL 命名規則

- 只能使用小寫字母、數字和連字號（`-`）
- 不能使用底線、特殊字元、中文
- 必須在整個 Connect 伺服器上唯一

## 注意事項

- 需要應用程式的編輯權限
- 部署後可能需要等待幾秒鐘才能設定
- 變更後舊 URL 立即失效
