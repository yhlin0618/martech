################################################################################
# 2⃣  module_upload.R（整合 Hint 系統）----------------------------------------
################################################################################

# 載入提示系統
source("utils/hint_system.R")

#' Upload & Preview Module – UI（整合 Hint 系統）
uploadModuleUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  tagList(
    # 初始化提示系統
    if(enable_hints) init_hint_system() else NULL,
    
    div(id = ns("step1_box"),
        h4("步驟 1：上傳資料 (支援多檔案)"),
        
        # 上傳說明區塊
        bs4Card(
          title = "📋 上傳說明",
          status = "info",
          solidHeader = FALSE,
          width = 12,
          collapsible = TRUE,
          collapsed = FALSE,
          
          fluidRow(
            column(6,
              h5("📊 支援格式"),
              tags$ul(
                tags$li(tags$strong("Amazon 銷售報告"), " - 一般文字記載"),
                tags$li("Excel (.xlsx, .xls)"),
                tags$li("CSV 格式"),
                tags$li("可以月為單位，同時匯入多筆 CSV 檔案")
              ),
              div(
                class = "alert alert-warning",
                icon("exclamation-triangle"),
                tags$b(" 重要提醒："),
                "請上傳至少 3-12 個月以上的數據，以確保分析準確性。"
              ),
              h5("📦 自動偵測欄位"),
              p("系統將自動偵測以下欄位，並轉換為標準變數名稱："),
              tags$ul(
                tags$li(
                  HTML("<strong style='color: #007bff;'>customer_id</strong> ← 客戶識別"),
                  tags$ul(style = "font-size: 0.9em; color: #6c757d;",
                    tags$li("優先: buyer email, buyer_email, email"),
                    tags$li("次選: customer_id, customer, buyer_id, user_id")
                  )
                ),
                tags$li(
                  HTML("<strong style='color: #007bff;'>payment_time</strong> ← 交易時間"),
                  tags$ul(style = "font-size: 0.9em; color: #6c757d;",
                    tags$li("偵測: purchase date, payments date, payment_time"),
                    tags$li("其他: date, time, datetime")
                  )
                ),
                tags$li(
                  HTML("<strong style='color: #007bff;'>lineitem_price</strong> ← 交易金額"),
                  tags$ul(style = "font-size: 0.9em; color: #6c757d;",
                    tags$li("偵測: item price, lineitem_price, amount"),
                    tags$li("其他: sales, price, total")
                  )
                )
              ),
              div(
                class = "alert alert-info",
                icon("info-circle"),
                HTML("<b>💡 標準化說明：</b><br>"),
                HTML("無論您的原始欄位名稱為何，系統都會轉換為上述<span style='color: #007bff; font-weight: bold;'>藍色標準變數名稱</span>進行分析。<br>"),
                HTML("例如：'buyer email' → <strong>customer_id</strong>，'purchase date' → <strong>payment_time</strong>")
              )
            ),
            column(6,
              h5("📷 Amazon CSV 範例"),
              div(
                style = "border: 1px solid #dee2e6; padding: 10px; border-radius: 5px; background: #f8f9fa;",
                # 顯示範例圖片
                tags$img(
                  src = "data/KM_eg/amazon_csv_example.png",
                  width = "100%",
                  alt = "Amazon CSV 範例",
                  style = "max-width: 100%; height: auto; border: 1px solid #dee2e6;"
                ),
                tags$p(
                  class = "text-muted text-center mt-2",
                  tags$small("上圖為 Amazon 銷售報告 CSV 格式範例")
                )
              )
            )
          )
        ),
        
        # DNA 分析資料上傳 - 加入提示
        div(
          h5("📁 上傳銷售數據"),
          
          # 為檔案上傳添加提示
          add_hint_bs4(
            fileInput(ns("dna_files"), "多檔案上傳 (自動合併)", 
                     multiple = TRUE, 
                     accept = c(".xlsx", ".xls", ".csv")),
            var_id = "upload_button",
            hints_df = hints_df,
            enable_hints = enable_hints
          ),
          br()
        ),
        
        # 為上傳按鈕添加提示
        add_hint_bs4(
          actionButton(ns("load_btn"), "上傳並預覽", class = "btn-success"),
          var_id = "upload_button", 
          hints_df = hints_df,
          enable_hints = enable_hints
        ),
        br(),
        
        verbatimTextOutput(ns("step1_msg")),
        
        # 資料預覽
        DTOutput(ns("dna_preview_tbl")),
        br(),
        actionButton(ns("to_step2"), "下一步 ➡️", class = "btn-info")
    )
  )
}

#' Upload & Preview Module – Server（整合 Hint 系統）
#'
#' @param user_info reactive – passed from login module
#' @param enable_hints logical – whether to enable hint system
#' @return reactive containing the uploaded (raw) data.frame or NULL
uploadModuleServer <- function(id, con, user_info, enable_hints = TRUE) {
  moduleServer(id, function(input, output, session) {
    # 存儲DNA分析資料
    dna_data <- reactiveVal(NULL)
    
    # 如果啟用提示，定期觸發提示初始化
    if(enable_hints) {
      observe({
        trigger_hint_init(session)
      })
    }
    
    # ---- 欄位偵測函數 --------------------------------------------------------
    detect_fields <- function(df) {
      cols <- tolower(names(df))
      
      # 客戶ID欄位偵測（優先電子郵件）
      customer_field <- NULL
      email_patterns <- c("buyer email", "buyer_email", "email")
      id_patterns <- c("customer_id", "customer", "buyer_id", "user_id")
      
      for (pattern in email_patterns) {
        if (any(grepl(pattern, cols, fixed = TRUE))) {
          customer_field <- names(df)[grepl(pattern, cols, fixed = TRUE)][1]
          break
        }
      }
      
      if (is.null(customer_field)) {
        for (pattern in id_patterns) {
          if (any(grepl(pattern, cols, fixed = TRUE))) {
            customer_field <- names(df)[grepl(pattern, cols, fixed = TRUE)][1]
            break
          }
        }
      }
      
      # 時間欄位偵測
      time_field <- NULL
      time_patterns <- c("purchase date", "payments date", "payment_time", "date", "time", "datetime")
      for (pattern in time_patterns) {
        if (any(grepl(pattern, cols, fixed = TRUE))) {
          time_field <- names(df)[grepl(pattern, cols, fixed = TRUE)][1]
          break
        }
      }
      
      # 金額欄位偵測
      amount_field <- NULL
      amount_patterns <- c("item price", "lineitem_price", "amount", "sales", "price", "total")
      for (pattern in amount_patterns) {
        if (any(grepl(pattern, cols, fixed = TRUE))) {
          amount_field <- names(df)[grepl(pattern, cols, fixed = TRUE)][1]
          break
        }
      }
      
      return(list(customer_id = customer_field, time = time_field, amount = amount_field))
    }
    
    # ---- 上傳 & 儲存 --------------------------------------------------------
    observeEvent(input$load_btn, {
      req(user_info())
      
      # 重置之前的資料
      dna_data(NULL)
      output$step1_msg <- renderText("處理中...")
      
      # 處理DNA分析資料上傳
      if (!is.null(input$dna_files) && nrow(input$dna_files) > 0) {
        tryCatch({
          files <- input$dna_files
          all_data <- list()
          
          for (i in seq_len(nrow(files))) {
            ext <- tolower(tools::file_ext(files$name[i]))
            if (!ext %in% c("xlsx", "xls", "csv")) {
              output$step1_msg <- renderText(sprintf("⚠️ 檔案 '%s' 格式不支援，只能上傳 .xlsx / .xls/.csv", files$name[i]))
              return()
            }
            
            # 嘗試讀取檔案
            dat <- if (ext == "csv") {
              read.csv(files$datapath[i], stringsAsFactors = FALSE, check.names = FALSE)
            } else {
              as.data.frame(readxl::read_excel(files$datapath[i]))
            }
            
            # 檢查資料是否有效
            if (nrow(dat) == 0) {
              output$step1_msg <- renderText(sprintf("⚠️ 檔案 '%s' 是空的", files$name[i]))
              return()
            }
            
            # 添加來源檔案資訊
            dat$source_file <- files$name[i]
            all_data[[i]] <- dat
          }
        
        # 合併所有檔案
        all_columns <- unique(unlist(lapply(all_data, names)))
        for (i in seq_along(all_data)) {
          missing_cols <- setdiff(all_columns, names(all_data[[i]]))
          for (col in missing_cols) {
            all_data[[i]][[col]] <- NA
          }
          all_data[[i]] <- all_data[[i]][all_columns]
        }
        
        combined_data <- do.call(rbind, all_data)
        
        # 偵測並標準化欄位
        fields <- detect_fields(combined_data)
        
        if (!is.null(fields$customer_id) && !is.null(fields$time) && !is.null(fields$amount)) {
          # 標準化資料格式
          standardized_data <- combined_data
          names(standardized_data)[names(standardized_data) == fields$customer_id] <- "customer_id"
          names(standardized_data)[names(standardized_data) == fields$time] <- "payment_time"
          names(standardized_data)[names(standardized_data) == fields$amount] <- "lineitem_price"
          
          # 基本資料清理
          standardized_data <- standardized_data[!is.na(standardized_data$customer_id) & 
                                                !is.na(standardized_data$payment_time) & 
                                                !is.na(standardized_data$lineitem_price), ]
          
          # 根據配置決定是否上傳到SQL
          if (!exists("SKIP_SQL_UPLOAD") || !SKIP_SQL_UPLOAD) {
            # 儲存DNA資料（使用現有的rawdata表）
            db_execute("INSERT INTO rawdata (user_id,uploaded_at,json) VALUES (?,?,?)",
                      params = list(user_info()$id,
                                  as.character(Sys.time()),
                                  jsonlite::toJSON(standardized_data, dataframe = "rows", auto_unbox = TRUE)))
            upload_msg <- "✅ 已上傳DNA分析資料，共 %d 筆 (✅ 已偵測到DNA分析欄位)"
          } else {
            upload_msg <- "✅ 已載入DNA分析資料，共 %d 筆 (✅ 已偵測到DNA分析欄位，已跳過SQL上傳)"
          }
          
          dna_data(standardized_data)
          output$dna_preview_tbl <- renderDT(head(standardized_data, 1000), options = list(scrollX = TRUE), selection = "none")
          output$step1_msg <- renderText(sprintf(upload_msg, nrow(standardized_data)))
        } else {
          # 如果無法偵測DNA欄位，當作一般資料儲存
          dna_data(combined_data)
          output$dna_preview_tbl <- renderDT(head(combined_data, 1000), options = list(scrollX = TRUE), selection = "none")
          output$step1_msg <- renderText(sprintf("✅ 已上傳資料，共 %d 筆 (⚠️ 未偵測到完整DNA分析欄位)", nrow(combined_data)))
        }
        }, error = function(e) {
          output$step1_msg <- renderText(paste("❌ 檔案處理錯誤:", e$message))
          return()
        })
      } else {
        output$step1_msg <- renderText("⚠️ 請選擇要上傳的檔案")
      }
    })
    
    # 禁止沒資料時按下一步
    observeEvent(input$to_step2, {
      if (is.null(dna_data()) || nrow(dna_data()) == 0) {
        showNotification("⚠️ 請先上傳並預覽DNA分析資料", type = "error")
        return()
      }
    })
    
    # ---- export ------------------------------------------------------------
    list(
      dna_data     = reactive(dna_data()),         # DNA分析資料
      proceed_step = reactive({ input$to_step2 })   # a trigger to switch step outside
    )
  })
}