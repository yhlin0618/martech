# ============================================================================
# InsightForge 資料存取工具模組
# 直接引用 global_scripts 功能
# ============================================================================

# 載入 global_scripts 核心功能
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")  # 增強資料存取 (tbl2)
source("scripts/global_scripts/04_utils/fn_import_csvxlsx.R")  # 檔案匯入工具
source("scripts/global_scripts/04_utils/fn_clean_column_names.R")  # 欄位名稱清理
source("scripts/global_scripts/04_utils/fn_handle_na.R")  # NA 值處理
source("scripts/global_scripts/04_utils/safe_get.R")  # 安全取值
source("scripts/global_scripts/04_utils/remove_na_strings.R")  # 移除 NA 字串

# 載入數據庫連接模組（包含跨數據庫兼容函數）
source("database/db_connection.R")

# ── 擴展的資料存取介面 ──────────────────────────────────────────────────────
#' InsightForge 統一資料存取函數
#' 
#' 直接使用 global_scripts 的 tbl2 作為核心，提供 InsightForge 專用的包裝
#' 
#' @param data_source 資料來源（完全支援 tbl2 的所有格式）
#' @param table_name 表格名稱或資料標識
#' @param ... 額外參數傳遞給 tbl2
#' 
#' @return tibble 物件，支援完整 dplyr 操作鏈
#' 
#' @examples
#' # 直接使用 tbl2 的強大功能
#' insights_data(con, "rawdata")  # 資料庫存取
#' insights_data("data/file.csv")  # 檔案存取
#' insights_data(list(data = df), "data")  # list 存取
#' 
#' @export
insights_data <- function(data_source, table_name = NULL, ...) {
  # 直接使用 global_scripts 的 tbl2，只加上簡單的錯誤處理
  tryCatch({
    if (is.null(table_name)) {
      tbl2(data_source, ...)
    } else {
      tbl2(data_source, table_name, ...)
    }
  }, error = function(e) {
    cat("❌ 資料存取錯誤:", e$message, "\n")
    cat("💡 資料源類型:", class(data_source), "\n")
    if (!is.null(table_name)) {
      cat("💡 請求的表格:", table_name, "\n")
    }
    stop(e)
  })
}

# ── InsightForge 專用資料存取函數（基於 global_scripts） ─────────────────
#' 從資料庫載入使用者資料
get_users_data <- function(con) {
  tbl2(con, "users") %>%
    select(id, username, role, login_count)
}

#' 從資料庫載入原始評論資料
get_rawdata <- function(con, user_id = NULL) {
  data <- tbl2(con, "rawdata")
  
  if (!is.null(user_id)) {
    data <- data %>% filter(user_id == !!user_id)
  }
  
  return(data)
}

#' 從資料庫載入處理後的資料
get_processed_data <- function(con, user_id = NULL) {
  data <- tbl2(con, "processed_data")
  
  if (!is.null(user_id)) {
    data <- data %>% filter(user_id == !!user_id)
  }
  
  return(data)
}

#' 載入評論分析資料（從 JSON 欄位解析）
get_comment_analysis <- function(con, user_id) {
  raw_data <- get_rawdata(con, user_id) %>%
    collect()
  
  # 解析 JSON 資料
  if (nrow(raw_data) > 0) {
    json_data <- jsonlite::fromJSON(raw_data$json[1])
    return(dplyr::as_tibble(json_data))
  } else {
    return(tibble())
  }
}

#' 載入品牌分析資料
get_brand_analysis <- function(con, user_id) {
  processed <- get_processed_data(con, user_id) %>%
    collect()
  
  if (nrow(processed) > 0) {
    json_data <- jsonlite::fromJSON(processed$json[1])
    return(dplyr::as_tibble(json_data))
  } else {
    return(tibble())
  }
}

# ── 檔案系統資料存取 ──────────────────────────────────────────────────────
#' 載入上傳的 Excel 檔案
load_excel_file <- function(file_path, sheet = NULL) {
  insights_data(file_path, sheet = sheet)
}

#' 載入 CSV 檔案
load_csv_file <- function(file_path) {
  insights_data(file_path)
}

#' 儲存分析結果到檔案
save_analysis_results <- function(data, file_path, format = "csv") {
  switch(format,
    "csv" = readr::write_csv(data, file_path),
    "xlsx" = writexl::write_xlsx(data, file_path),
    "rds" = saveRDS(data, file_path),
    stop("不支援的檔案格式:", format)
  )
  cat("✅ 資料已儲存至:", file_path, "\n")
}

# ── 資料驗證工具 ──────────────────────────────────────────────────────────
#' 驗證上傳資料格式
validate_upload_data <- function(data) {
  required_cols <- c("Variation", "Title", "Body")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  
  if (length(missing_cols) > 0) {
    stop("❌ 缺少必要欄位: ", paste(missing_cols, collapse = ", "))
  }
  
  # 檢查資料完整性
  empty_rows <- sum(is.na(data$Variation) | is.na(data$Body))
  if (empty_rows > 0) {
    warning("⚠️ 發現 ", empty_rows, " 列空白資料")
  }
  
  cat("✅ 資料格式驗證通過\n")
  cat("📊 總列數:", nrow(data), "\n")
  cat("📋 品牌數:", length(unique(data$Variation)), "\n")
  
  return(TRUE)
}

# ── 資料快速存取工具 ──────────────────────────────────────────────────────
#' 創建資料快速存取介面
create_data_interface <- function(con) {
  list(
    # 資料庫相關
    users = function() get_users_data(con),
    rawdata = function(user_id = NULL) get_rawdata(con, user_id),
    processed = function(user_id = NULL) get_processed_data(con, user_id),
    
    # 分析相關
    comments = function(user_id) get_comment_analysis(con, user_id),
    brands = function(user_id) get_brand_analysis(con, user_id),
    
    # 通用存取
    get_data = function(table_name, ...) insights_data(con, table_name, ...)
  )
}

# ── 測試和診斷工具 ───────────────────────────────────────────────────────
#' 測試資料存取功能
test_data_access <- function(con = NULL) {
  cat("🧪 測試 InsightForge 資料存取功能\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # 測試 tbl2 基本功能
  cat("📋 測試 tbl2 基本功能...\n")
  test_df <- data.frame(id = 1:3, name = c("A", "B", "C"))
  result <- tbl2(test_df)
  cat("  ✅ tbl2 轉換測試通過\n")
  
  # 測試檔案存取（如果有測試檔案）
  if (file.exists("tests/test_data.csv")) {
    cat("📁 測試檔案存取...\n")
    file_data <- insights_data("tests/test_data.csv")
    cat("  ✅ 檔案存取測試通過\n")
  }
  
  # 測試資料庫存取（如果提供連接）
  if (!is.null(con)) {
    cat("🗄 測試資料庫存取...\n")
    tryCatch({
      users <- get_users_data(con)
      cat("  ✅ 使用者資料存取測試通過，找到", nrow(users), "個使用者\n")
    }, error = function(e) {
      cat("  ⚠️ 資料庫存取測試失敗:", e$message, "\n")
    })
  }
  
  cat(paste(rep("=", 50), collapse = ""), "\n")
  cat("�� 資料存取功能測試完成\n")
} 