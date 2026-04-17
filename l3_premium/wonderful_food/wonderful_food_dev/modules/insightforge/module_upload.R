################################################################################
# 2⃣  module_upload.R ----------------------------------------------------------
################################################################################

# 載入必要的資料存取工具
source("utils/data_access.R")  # 包含 tbl2 函數

#' Upload & Preview Module – UI
uploadModuleUI <- function(id) {
  ns <- NS(id)
  div(id = ns("step1_box"),
      h4("步驟 1：上傳資料"),
      
      # 評論資料上傳
      div(
        h5("1.1 上傳評論資料"),
        includeMarkdown("md/notification.md"),
        div(
          style = "background: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
          icon("info-circle"),
          " 限制：最多10個品牌，每個品牌最多500筆評論"
        ),
        fileInput(ns("excel_multiple"), "下圖可上傳多個顧客評論檔案(系統會自動合併)", multiple = TRUE, accept = c(".xlsx", ".xls", ".csv")),
        br()
      ),
      
      # Sales 資料上傳
      div(
        h5("1.2 上傳銷售資料 (選填)"),
        div(
          style = "background: #fff3cd; border: 1px solid #ffc107; padding: 10px; border-radius: 5px; margin-bottom: 10px;",
          icon("info-circle"),
          " 限制：最多10個品牌，每個品牌最多2000筆銷售資料"
        ),
        fileInput(ns("sales_multiple"), "下圖可上傳多個銷售資料檔案(系統會自動合併)", multiple = TRUE, accept = c(".xlsx", ".xls", ".csv")),
        br()
      ),
      
      actionButton(ns("load_btn"), "上傳並預覽", class = "btn-success"), br(),
      verbatimTextOutput(ns("step1_msg")),
      
      # 分頁顯示兩種資料
      tabsetPanel(
        tabPanel("評論資料預覽", DTOutput(ns("preview_tbl"))),
        tabPanel("銷售資料預覽", DTOutput(ns("sales_preview_tbl")))
      ),
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
    # 分別存儲兩種資料
    working_data <- reactiveVal(NULL)
    sales_data <- reactiveVal(NULL)
    
    # ---- 上傳 & 儲存 --------------------------------------------------------
    observeEvent(input$load_btn, {
      req(user_info())
      
      # 處理評論資料上傳
      if (!is.null(input$excel_multiple) && nrow(input$excel_multiple) > 0) {
        files <- input$excel_multiple
        all_data <- list()
        for (i in seq_len(nrow(files))) {
          ext <- tolower(tools::file_ext(files$name[i]))
          if (!ext %in% c("xlsx", "xls", "csv")) {
            output$step1_msg <- renderText(sprintf("⚠️ 檔案 '%s' 格式不支援，只能上傳 .xlsx / .xls/.csv", files$name[i]))
            return()
          }
          dat <- if (ext == "csv") {
            readr::read_csv(files$datapath[i])
          } else {
            readxl::read_excel(files$datapath[i])
          }
          must <- c("Variation", "Title", "Body")
          if (!all(must %in% names(dat))) {
            output$step1_msg <- renderText(sprintf("⚠️ 檔案 '%s' 缺少 Variation / Title / Body 欄位", files$name[i]))
            return()
          }
          all_data[[i]] <- dat
        }
        dat_all <- do.call(rbind, all_data)
        
        # 實施樣本數限制：每個品牌最多500筆評論
        dat_all <- dat_all %>%
          group_by(Variation) %>%
          slice_head(n = 500) %>%
          ungroup()
        
        # 檢查品牌數量限制（最多10個品牌）
        unique_brands <- unique(dat_all$Variation)
        if (length(unique_brands) > 10) {
          dat_all <- dat_all %>%
            filter(Variation %in% unique_brands[1:10])
          showNotification(
            sprintf("⚠️ 已限制為前10個品牌，每品牌最多500筆評論"), 
            type = "warning", duration = 5
          )
        }
        # 準備新記錄資料
        new_rawdata <- data.frame(
          user_id = user_info()$id,
          uploaded_at = as.character(Sys.time()),
          json = jsonlite::toJSON(dat_all, dataframe = "rows", auto_unbox = TRUE),
          stringsAsFactors = FALSE
        )
        
        # 使用 DBI 直接插入新記錄
        DBI::dbWriteTable(con, "rawdata", new_rawdata, append = TRUE)
        working_data(dat_all)
        output$preview_tbl <- renderDT(dat_all, selection = "none")
      }
      
      # 處理銷售資料上傳
      if (!is.null(input$sales_multiple) && nrow(input$sales_multiple) > 0) {
        files <- input$sales_multiple
        all_sales <- list()
        for (i in seq_len(nrow(files))) {
          ext <- tolower(tools::file_ext(files$name[i]))
          if (!ext %in% c("xlsx", "xls", "csv")) {
            output$step1_msg <- renderText(sprintf("⚠️ 檔案 '%s' 格式不支援，只能上傳 .xlsx / .xls/.csv", files$name[i]))
            return()
          }
          dat <- if (ext == "csv") {
            readr::read_csv(files$datapath[i])
          } else {
            readxl::read_excel(files$datapath[i])
          }
          
          # 從檔名提取 Variation ID 或品牌名稱
          filename_base <- sub("\\.[^.]+$", "", files$name[i])  # 移除副檔名
          
          # 檢查是否為 _sales 格式
          if (grepl("_sales$", filename_base)) {
            variation_id <- sub("^(.*?)_sales$", "\\1", filename_base)
          } else {
            # 如果不是標準格式，使用整個檔名（去除副檔名）
            variation_id <- filename_base
          }
          
          dat$Variation <- variation_id
          dat$檔案來源 <- files$name[i]  # 記錄原始檔名便於追蹤
          
          all_sales[[i]] <- dat
        }
        sales_all <- do.call(rbind, all_sales)
        
        # 實施樣本數限制：每個品牌最多2000筆銷售資料
        sales_all <- sales_all %>%
          group_by(Variation) %>%
          slice_head(n = 2000) %>%
          ungroup()
        
        # 檢查品牌數量限制（最多10個品牌）
        unique_brands <- unique(sales_all$Variation)
        if (length(unique_brands) > 10) {
          sales_all <- sales_all %>%
            filter(Variation %in% unique_brands[1:10])
          showNotification(
            sprintf("⚠️ 已限制為前10個品牌，每品牌最多2000筆銷售資料"), 
            type = "warning", duration = 5
          )
        }
        
        # 準備銷售資料記錄
        new_salesdata <- data.frame(
          user_id = user_info()$id,
          uploaded_at = as.character(Sys.time()),
          json = jsonlite::toJSON(sales_all, dataframe = "rows", auto_unbox = TRUE),
          stringsAsFactors = FALSE
        )
        
        # 使用 DBI 直接插入銷售資料
        DBI::dbWriteTable(con, "salesdata", new_salesdata, append = TRUE)
        sales_data(sales_all)
        output$sales_preview_tbl <- renderDT(sales_all, selection = "none")
      }
      
      # 更新上傳狀態訊息
      msg <- character(0)
      if (!is.null(working_data())) {
        n_brands <- length(unique(working_data()$Variation))
        msg <- c(msg, sprintf("✅ 已上傳評論資料：%d 個品牌，共 %d 筆（每品牌上限500筆）", 
                             n_brands, nrow(working_data())))
      }
      if (!is.null(sales_data())) {
        n_brands <- length(unique(sales_data()$Variation))
        msg <- c(msg, sprintf("✅ 已上傳銷售資料：%d 個品牌，共 %d 筆（每品牌上限2000筆）", 
                             n_brands, nrow(sales_data())))
      }
      if (length(msg) == 0) {
        msg <- "⚠️ 請至少上傳評論資料"
      }
      output$step1_msg <- renderText(paste(msg, collapse = "\n"))
    })
    
    # 禁止沒資料時按下一步
    observeEvent(input$to_step2, {
      if (is.null(working_data()) || nrow(working_data()) == 0) {
        showNotification("⚠️ 請先上傳並預覽評論資料", type = "error")
        return()
      }
    })
    
    # ---- export ------------------------------------------------------------
    list(
      data         = reactive(working_data()),
      sales_data   = reactive(sales_data()),
      proceed_step = reactive({ input$to_step2 })   # a trigger to switch step outside
    )
  })
}