# API 整合指南 - BrandEdge 品牌印記引擎

## 目錄
1. [OpenAI API 配置](#openai-api-配置)
2. [API 調用架構](#api-調用架構)
3. [錯誤處理機制](#錯誤處理機制)
4. [速率限制管理](#速率限制管理)
5. [成本優化策略](#成本優化策略)
6. [模擬模式開發](#模擬模式開發)
7. [安全最佳實踐](#安全最佳實踐)
8. [監控與日誌](#監控與日誌)

---

## OpenAI API 配置

### 環境設置

#### 1. 取得 API 金鑰
```bash
# 從 OpenAI 平台取得 API 金鑰
# https://platform.openai.com/api-keys
```

#### 2. 設定環境變數
```bash
# .env 檔案
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx

# 注意事項
# - 永遠不要將 API 金鑰寫死在程式碼中
# - 確保 .env 檔案在 .gitignore 中
# - 定期輪換 API 金鑰
```

#### 3. R 語言中載入環境變數
```r
# 載入 dotenv 套件
library(dotenv)

# 條件式載入 .env 檔案
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
}

# 取得 API 金鑰
api_key <- Sys.getenv("OPENAI_API_KEY")
```

### API 參數配置

```r
# 模型選擇
MODEL <- "gpt-4o-mini"  # 成本優化模型

# API 端點
API_URL <- "https://api.openai.com/v1/chat/completions"

# 請求參數
DEFAULT_PARAMS <- list(
  temperature = 0.7,    # 創意程度 (0-2)
  max_tokens = 500,     # 最大回應長度
  top_p = 1,           # 核心採樣
  frequency_penalty = 0, # 頻率懲罰
  presence_penalty = 0   # 存在懲罰
)
```

---

## API 調用架構

### 核心調用函數

```r
chat_api <- function(messages, 
                     max_retries = 5, 
                     retry_delay = 5, 
                     use_mock = FALSE) {
  
  # 模擬模式（開發測試用）
  if (use_mock) {
    return(generate_mock_response())
  }
  
  # 檢查 API 金鑰
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (is.null(api_key) || api_key == "") {
    stop("OPENAI_API_KEY 環境變數未設定")
  }
  
  # 構建請求體
  body <- list(
    model = "gpt-4o-mini",
    messages = messages,
    temperature = 0.7,
    max_tokens = 500
  )
  
  # 重試邏輯
  for (attempt in 1:max_retries) {
    tryCatch({
      # 發送 HTTP 請求
      resp <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers("Authorization" = paste("Bearer", api_key)),
        body = body,
        encode = "json"
      )
      
      # 處理回應
      status <- status_code(resp)
      
      if (status == 200) {
        result <- content(resp, "parsed")
        return(result$choices[[1]]$message$content)
      } else {
        handle_api_error(status, resp, attempt, max_retries)
      }
      
    }, error = function(e) {
      handle_connection_error(e, attempt, max_retries)
    })
  }
}
```

### 批次處理架構

```r
# 並行批次處理多個請求
batch_process_reviews <- function(reviews, attributes, batch_size = 10) {
  
  # 分割成批次
  batches <- split(reviews, 
                   ceiling(seq_along(reviews) / batch_size))
  
  # 並行處理
  if (Sys.getenv("SHINY_PORT") != "") {
    # Shiny 環境：順序處理
    results <- lapply(batches, function(batch) {
      process_batch(batch, attributes)
    })
  } else {
    # 本地環境：並行處理
    plan(multisession, workers = 2)
    results <- future_map(batches, function(batch) {
      process_batch(batch, attributes)
    })
  }
  
  # 合併結果
  do.call(rbind, results)
}
```

---

## 錯誤處理機制

### 錯誤類型與處理策略

#### 1. HTTP 狀態碼處理
```r
handle_http_error <- function(status_code, response) {
  error_handlers <- list(
    "400" = function() {
      msg <- "請求格式錯誤，請檢查參數"
      log_error(msg)
      stop(msg)
    },
    "401" = function() {
      msg <- "API 金鑰無效，請檢查 OPENAI_API_KEY"
      log_error(msg)
      stop(msg)
    },
    "403" = function() {
      msg <- "API 存取被拒絕，請檢查帳戶權限"
      log_error(msg)
      stop(msg)
    },
    "429" = function() {
      msg <- "API 速率限制，請稍後重試"
      log_warning(msg)
      return(list(retry = TRUE, message = msg))
    },
    "500" = function() {
      msg <- "OpenAI 伺服器錯誤"
      log_error(msg)
      return(list(retry = TRUE, message = msg))
    },
    "503" = function() {
      msg <- "OpenAI 服務暫時無法使用"
      log_warning(msg)
      return(list(retry = TRUE, message = msg))
    }
  )
  
  handler <- error_handlers[[as.character(status_code)]]
  if (!is.null(handler)) {
    return(handler())
  }
  
  # 未知錯誤
  msg <- paste("未知錯誤，狀態碼:", status_code)
  log_error(msg)
  stop(msg)
}
```

#### 2. 重試機制實現
```r
# 指數退避重試策略
exponential_backoff <- function(attempt, base_delay = 5) {
  # 計算延遲時間：base * 2^(attempt-1)
  delay <- min(base_delay * (2^(attempt-1)), 300)  # 最多等待 5 分鐘
  
  # 加入隨機抖動避免同時重試
  jitter <- runif(1, 0, delay * 0.1)
  
  actual_delay <- delay + jitter
  
  cat(sprintf("⏳ 第 %d 次重試，等待 %.1f 秒...\n", 
              attempt, actual_delay))
  
  Sys.sleep(actual_delay)
}
```

---

## 速率限制管理

### 速率限制參數

| 計劃等級 | RPM (每分鐘請求) | TPM (每分鐘 tokens) | 建議用途 |
|---------|-----------------|-------------------|---------|
| Free | 3 | 40,000 | 開發測試 |
| Tier 1 | 500 | 60,000 | 小規模應用 |
| Tier 2 | 5,000 | 80,000 | 中規模應用 |
| Tier 3 | 10,000 | 120,000 | 大規模應用 |

### 速率限制處理策略

```r
# 速率限制管理器
RateLimiter <- R6::R6Class("RateLimiter",
  private = list(
    .requests = list(),
    .window_size = 60,  # 60 秒窗口
    .max_rpm = 500       # 每分鐘最大請求數
  ),
  
  public = list(
    initialize = function(max_rpm = 500) {
      private$.max_rpm <- max_rpm
    },
    
    check_rate_limit = function() {
      current_time <- Sys.time()
      window_start <- current_time - private$.window_size
      
      # 清理過期請求記錄
      private$.requests <- Filter(function(t) t > window_start, 
                                  private$.requests)
      
      # 檢查是否超過限制
      if (length(private$.requests) >= private$.max_rpm) {
        wait_time <- as.numeric(difftime(
          private$.requests[[1]] + private$.window_size,
          current_time,
          units = "secs"
        ))
        return(list(allowed = FALSE, wait_time = wait_time))
      }
      
      # 記錄新請求
      private$.requests <- append(private$.requests, current_time)
      return(list(allowed = TRUE))
    }
  )
)

# 使用速率限制器
rate_limiter <- RateLimiter$new(max_rpm = 500)

before_api_call <- function() {
  check <- rate_limiter$check_rate_limit()
  
  if (!check$allowed) {
    cat(sprintf("⚠️ 速率限制：需等待 %.1f 秒\n", check$wait_time))
    Sys.sleep(check$wait_time)
  }
}
```

---

## 成本優化策略

### 1. 模型選擇優化

| 模型 | 輸入成本 (per 1M tokens) | 輸出成本 (per 1M tokens) | 使用場景 |
|-----|-------------------------|-------------------------|---------|
| gpt-4o | $2.50 | $10.00 | 複雜分析 |
| gpt-4o-mini | $0.15 | $0.60 | 一般分析（推薦） |
| gpt-3.5-turbo | $0.50 | $1.50 | 簡單任務 |

### 2. Token 使用優化

```r
# Token 計算與優化
optimize_prompt <- function(text, max_length = 1000) {
  # 1. 移除多餘空白
  text <- trimws(text)
  text <- gsub("\\s+", " ", text)
  
  # 2. 截斷過長文本
  if (nchar(text) > max_length) {
    text <- substr(text, 1, max_length)
    text <- paste0(text, "...")
  }
  
  # 3. 估算 token 數量（粗略估計）
  estimated_tokens <- ceiling(nchar(text) / 4)
  
  return(list(
    text = text,
    estimated_tokens = estimated_tokens
  ))
}

# 批次處理優化
optimize_batch_size <- function(total_items, max_tokens_per_request = 4000) {
  # 根據 token 限制計算最佳批次大小
  avg_tokens_per_item <- 100  # 估計值
  optimal_batch_size <- floor(max_tokens_per_request / avg_tokens_per_item)
  
  return(min(optimal_batch_size, 50))  # 最多 50 個項目
}
```

### 3. 快取策略

```r
# 使用 memoise 實現快取
library(memoise)

# 快取 API 調用結果
cached_api_call <- memoise(
  chat_api,
  cache = cache_disk(dir = "cache/api_responses"),
  expire = 3600  # 快取 1 小時
)

# 快取屬性萃取結果
cache_attributes <- function(product_type, attributes) {
  cache_key <- digest::digest(product_type)
  cache_file <- file.path("cache/attributes", paste0(cache_key, ".rds"))
  
  # 儲存快取
  if (!dir.exists("cache/attributes")) {
    dir.create("cache/attributes", recursive = TRUE)
  }
  
  saveRDS(list(
    product_type = product_type,
    attributes = attributes,
    timestamp = Sys.time()
  ), cache_file)
}

# 讀取快取
get_cached_attributes <- function(product_type) {
  cache_key <- digest::digest(product_type)
  cache_file <- file.path("cache/attributes", paste0(cache_key, ".rds"))
  
  if (file.exists(cache_file)) {
    cached <- readRDS(cache_file)
    
    # 檢查快取是否過期（24小時）
    if (difftime(Sys.time(), cached$timestamp, units = "hours") < 24) {
      return(cached$attributes)
    }
  }
  
  return(NULL)
}
```

---

## 模擬模式開發

### 模擬模式實現

```r
# 模擬回應生成器
generate_mock_response <- function(type = "attributes") {
  mock_responses <- list(
    attributes = "品質優良,價格實惠,使用方便,外觀美觀,功能豐富,服務良好,耐用性高,安裝簡單,效能卓越,設計精巧",
    
    score = sample(1:5, 1),
    
    analysis = "根據分析，此產品在品質和功能方面表現優秀，建議強化價格競爭力。"
  )
  
  return(mock_responses[[type]])
}

# 開發環境自動切換
get_api_mode <- function() {
  # 檢查環境變數
  if (Sys.getenv("USE_MOCK_API") == "TRUE") {
    return("mock")
  }
  
  # 檢查 API 金鑰
  if (Sys.getenv("OPENAI_API_KEY") == "") {
    cat("⚠️ 未設定 API 金鑰，使用模擬模式\n")
    return("mock")
  }
  
  return("production")
}
```

### 測試資料生成

```r
# 生成測試評論資料
generate_test_reviews <- function(n = 10) {
  variations <- c("Brand A", "Brand B", "Brand C")
  
  positive_phrases <- c(
    "品質很好", "價格合理", "使用方便", 
    "外觀漂亮", "功能齊全", "服務優良"
  )
  
  negative_phrases <- c(
    "品質一般", "價格偏高", "操作複雜",
    "外觀普通", "功能不足", "服務待改進"
  )
  
  reviews <- data.frame(
    Variation = sample(variations, n, replace = TRUE),
    Title = paste("評論", 1:n),
    Body = sapply(1:n, function(i) {
      if (runif(1) > 0.3) {
        # 70% 正面評論
        paste(sample(positive_phrases, 3), collapse = "，")
      } else {
        # 30% 負面評論
        paste(sample(negative_phrases, 2), collapse = "，")
      }
    }),
    stringsAsFactors = FALSE
  )
  
  return(reviews)
}
```

---

## 安全最佳實踐

### 1. API 金鑰管理

```r
# 安全檢查函數
validate_api_key <- function() {
  api_key <- Sys.getenv("OPENAI_API_KEY")
  
  # 檢查金鑰是否存在
  if (is.null(api_key) || api_key == "") {
    return(list(valid = FALSE, message = "API 金鑰未設定"))
  }
  
  # 檢查金鑰格式
  if (!grepl("^sk-[a-zA-Z0-9]{48}$", api_key)) {
    return(list(valid = FALSE, message = "API 金鑰格式無效"))
  }
  
  # 測試金鑰是否有效
  tryCatch({
    test_response <- chat_api(
      list(list(role = "user", content = "test")),
      max_retries = 1
    )
    return(list(valid = TRUE, message = "API 金鑰有效"))
  }, error = function(e) {
    return(list(valid = FALSE, message = paste("API 金鑰無效:", e$message)))
  })
}
```

### 2. 輸入驗證與清理

```r
# 清理用戶輸入
sanitize_input <- function(text) {
  # 移除潛在的注入攻擊
  text <- gsub("[<>\"']", "", text)
  
  # 限制長度
  if (nchar(text) > 10000) {
    text <- substr(text, 1, 10000)
  }
  
  # 移除控制字符
  text <- gsub("[[:cntrl:]]", "", text)
  
  return(text)
}

# 驗證評論資料
validate_review_data <- function(data) {
  required_columns <- c("Variation", "Title", "Body")
  
  # 檢查必要欄位
  if (!all(required_columns %in% names(data))) {
    missing <- setdiff(required_columns, names(data))
    stop(paste("缺少必要欄位:", paste(missing, collapse = ", ")))
  }
  
  # 檢查資料類型
  if (!is.character(data$Variation) && !is.factor(data$Variation)) {
    stop("Variation 欄位必須是文字類型")
  }
  
  # 檢查空值
  if (any(is.na(data$Body)) || any(data$Body == "")) {
    warning("部分評論內容為空")
  }
  
  return(TRUE)
}
```

### 3. 敏感資訊過濾

```r
# 移除個人識別資訊
remove_pii <- function(text) {
  # 移除 email
  text <- gsub("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", 
               "[EMAIL]", text)
  
  # 移除電話號碼
  text <- gsub("\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b", 
               "[PHONE]", text)
  
  # 移除信用卡號碼
  text <- gsub("\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b", 
               "[CARD]", text)
  
  # 移除社會安全號碼
  text <- gsub("\\b\\d{3}-\\d{2}-\\d{4}\\b", 
               "[SSN]", text)
  
  return(text)
}
```

---

## 監控與日誌

### 1. API 使用監控

```r
# API 使用追蹤器
APIMonitor <- R6::R6Class("APIMonitor",
  private = list(
    .log_file = "logs/api_usage.csv",
    .metrics = list()
  ),
  
  public = list(
    initialize = function(log_file = "logs/api_usage.csv") {
      private$.log_file <- log_file
      
      # 確保日誌目錄存在
      if (!dir.exists(dirname(log_file))) {
        dir.create(dirname(log_file), recursive = TRUE)
      }
      
      # 初始化日誌檔案
      if (!file.exists(log_file)) {
        write.csv(
          data.frame(
            timestamp = character(),
            endpoint = character(),
            model = character(),
            input_tokens = numeric(),
            output_tokens = numeric(),
            cost = numeric(),
            response_time = numeric(),
            status = character(),
            stringsAsFactors = FALSE
          ),
          log_file,
          row.names = FALSE
        )
      }
    },
    
    log_request = function(endpoint, model, input_tokens, 
                          output_tokens, response_time, status) {
      # 計算成本
      cost <- calculate_cost(model, input_tokens, output_tokens)
      
      # 記錄到檔案
      log_entry <- data.frame(
        timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        endpoint = endpoint,
        model = model,
        input_tokens = input_tokens,
        output_tokens = output_tokens,
        cost = cost,
        response_time = response_time,
        status = status,
        stringsAsFactors = FALSE
      )
      
      write.table(
        log_entry,
        private$.log_file,
        append = TRUE,
        sep = ",",
        row.names = FALSE,
        col.names = FALSE
      )
      
      # 更新內存指標
      private$.metrics[[length(private$.metrics) + 1]] <- log_entry
    },
    
    get_summary = function(period = "today") {
      # 讀取日誌
      logs <- read.csv(private$.log_file, stringsAsFactors = FALSE)
      logs$timestamp <- as.POSIXct(logs$timestamp)
      
      # 過濾時間範圍
      if (period == "today") {
        logs <- logs[as.Date(logs$timestamp) == Sys.Date(), ]
      } else if (period == "week") {
        logs <- logs[logs$timestamp > Sys.Date() - 7, ]
      } else if (period == "month") {
        logs <- logs[logs$timestamp > Sys.Date() - 30, ]
      }
      
      # 計算統計
      summary <- list(
        total_requests = nrow(logs),
        total_cost = sum(logs$cost, na.rm = TRUE),
        avg_response_time = mean(logs$response_time, na.rm = TRUE),
        success_rate = mean(logs$status == "success", na.rm = TRUE) * 100,
        total_tokens = sum(logs$input_tokens + logs$output_tokens, na.rm = TRUE)
      )
      
      return(summary)
    }
  )
)

# 成本計算函數
calculate_cost <- function(model, input_tokens, output_tokens) {
  # 價格表（每 1M tokens）
  pricing <- list(
    "gpt-4o-mini" = list(input = 0.15, output = 0.60),
    "gpt-4o" = list(input = 2.50, output = 10.00),
    "gpt-3.5-turbo" = list(input = 0.50, output = 1.50)
  )
  
  if (model %in% names(pricing)) {
    model_pricing <- pricing[[model]]
    cost <- (input_tokens * model_pricing$input + 
             output_tokens * model_pricing$output) / 1000000
    return(round(cost, 6))
  }
  
  return(0)
}
```

### 2. 錯誤日誌記錄

```r
# 錯誤日誌系統
setup_logging <- function() {
  library(logger)
  
  # 設定日誌等級
  log_threshold(DEBUG)
  
  # 設定日誌格式
  log_formatter(formatter_glue)
  
  # 設定日誌輸出
  log_appender(appender_tee(file = "logs/app.log"))
}

# 記錄 API 錯誤
log_api_error <- function(error, context = NULL) {
  log_error("API 錯誤: {error$message}")
  
  if (!is.null(context)) {
    log_debug("錯誤上下文: {toJSON(context)}")
  }
  
  # 記錄堆疊追蹤
  log_debug("堆疊追蹤: {paste(capture.output(traceback()), collapse = '\n')}")
}
```

### 3. 性能監控

```r
# 性能追蹤
track_performance <- function(operation, code) {
  start_time <- Sys.time()
  start_memory <- pryr::mem_used()
  
  # 執行操作
  result <- tryCatch({
    code
  }, error = function(e) {
    log_error("操作失敗: {operation} - {e$message}")
    NULL
  })
  
  # 記錄性能指標
  end_time <- Sys.time()
  end_memory <- pryr::mem_used()
  
  performance <- list(
    operation = operation,
    duration = as.numeric(difftime(end_time, start_time, units = "secs")),
    memory_used = as.numeric(end_memory - start_memory),
    timestamp = Sys.time()
  )
  
  log_info("性能: {operation} - 耗時: {performance$duration}秒, 記憶體: {performance$memory_used}MB")
  
  return(result)
}
```

---

## 故障排除指南

### 常見問題與解決方案

#### 1. API 金鑰錯誤
```
錯誤：401 Unauthorized
```
**解決方案**：
- 檢查 .env 檔案中的 OPENAI_API_KEY
- 確認金鑰沒有過期
- 驗證金鑰格式正確

#### 2. 速率限制
```
錯誤：429 Too Many Requests
```
**解決方案**：
- 實施指數退避重試
- 升級 API 計劃
- 使用批次處理減少請求數

#### 3. 超時錯誤
```
錯誤：Request timeout
```
**解決方案**：
- 增加超時設定
- 減少單次請求的資料量
- 使用非同步處理

#### 4. Token 限制
```
錯誤：Maximum token limit exceeded
```
**解決方案**：
- 縮短輸入文本
- 調整 max_tokens 參數
- 分割大型請求

---

## 最佳實踐總結

### DO ✅
1. **使用環境變數**儲存 API 金鑰
2. **實施重試機制**處理暫時性錯誤
3. **批次處理**提高效率
4. **快取結果**減少重複調用
5. **監控使用量**控制成本
6. **記錄錯誤**便於除錯
7. **驗證輸入**確保資料品質
8. **使用模擬模式**進行開發測試

### DON'T ❌
1. **不要**將 API 金鑰寫死在程式碼中
2. **不要**忽略錯誤處理
3. **不要**發送過大的請求
4. **不要**頻繁重試失敗的請求
5. **不要**儲存敏感資訊
6. **不要**忽略速率限制
7. **不要**在生產環境使用 debug 模式

---

## 聯絡資訊

公司: 祈鋒行銷科技有限公司

聯絡資訊: partners@peakedges.com

---

*文檔版本：v1.0 | 更新日期：2025-09-01*