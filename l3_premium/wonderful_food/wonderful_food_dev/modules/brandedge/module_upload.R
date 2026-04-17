################################################################################
# 2⃣  module_upload.R ----------------------------------------------------------
################################################################################

#' Upload & Preview Module – UI
uploadModuleUI <- function(id) {
  ns <- NS(id)
  div(id = ns("step1_box"),
      h4("步驟 1：上傳資料"),
      
      # DNA 分析資料上傳
      div(
        h5("上傳 DNA 分析資料"),
        p("支援格式：", tags$strong("Amazon 銷售報告"), "、一般交易記錄"),
        p("自動偵測欄位：客戶ID/Email、時間、金額等"),
        fileInput(ns("dna_files"), "多檔案上傳 (自動合併)", multiple = TRUE, accept = c(".xlsx", ".xls", ".csv")),
        br()
      ),
      
      actionButton(ns("load_btn"), "上傳並預覽", class = "btn-success"), br(),
      verbatimTextOutput(ns("step1_msg")),
      
      # 資料預覽
      DTOutput(ns("dna_preview_tbl")),
      br(),
      actionButton(ns("to_step2"), "下一步 ➡️", class = "btn-info")
  )
}

#' Upload & Preview Module – Server
#'
#' @param user_info reactive – passed from login module
#' @return reactive containing the uploaded (raw) data.frame or NULL
uploadModuleServer <- function(id, con, user_info) {
  moduleServer(id, function(input, output, session) {
    # 存儲DNA分析資料
    dna_data <- reactiveVal(NULL)
    
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
          
          # 儲存DNA資料（使用現有的rawdata表）
          dbExecute(con, "INSERT INTO rawdata (user_id,uploaded_at,json) VALUES (?,?,?)",
                    params = list(user_info()$id,
                                  as.character(Sys.time()),
                                  jsonlite::toJSON(standardized_data, dataframe = "rows", auto_unbox = TRUE)))
          
          dna_data(standardized_data)
          output$dna_preview_tbl <- renderDT(head(standardized_data, 1000), options = list(scrollX = TRUE), selection = "none")
          output$step1_msg <- renderText(sprintf("✅ 已上傳DNA分析資料，共 %d 筆 (✅ 已偵測到DNA分析欄位)", nrow(standardized_data)))
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