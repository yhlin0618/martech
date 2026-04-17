#!/usr/bin/env Rscript
# 快速部署 - 執行此檔案即可部署

# 取得腳本所在目錄
get_script_dir <- function() {
  # 獲取命令行參數
  args <- commandArgs(trailingOnly = FALSE)
  
  # 尋找 --file= 參數
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    # 從命令行執行
    script_path <- sub("^--file=", "", file_arg[1])
    return(dirname(normalizePath(script_path)))
  }
  
  # 在 RStudio 中執行 source() - 改進版本
  # 檢查各種可能的方式
  if (exists("ofile") && !is.null(ofile)) {
    return(dirname(normalizePath(ofile)))
  }
  
  # 使用 sys.frames() 和 sys.calls() 找到 source 調用
  frames <- sys.frames()
  calls <- sys.calls()
  
  for (i in rev(seq_along(calls))) {
    call <- calls[[i]]
    if (is.call(call) && length(call) >= 1) {
      # 檢查是否為 source 調用
      fn <- as.character(call[[1]])
      if (length(fn) > 0 && fn[1] == "source") {
        # 嘗試獲取檔案路徑
        if (length(call) >= 2) {
          file_arg <- call[[2]]
          if (is.character(file_arg) && file.exists(file_arg)) {
            return(dirname(normalizePath(file_arg)))
          }
          # 嘗試在對應的 frame 中評估
          if (i <= length(frames)) {
            file_path <- tryCatch(
              eval(file_arg, envir = frames[[i]]),
              error = function(e) NULL
            )
            if (!is.null(file_path) && is.character(file_path) && file.exists(file_path)) {
              return(dirname(normalizePath(file_path)))
            }
          }
        }
      }
    }
  }
  
  # 最後的備案：假設腳本在 l1_basic 的某個應用程式目錄
  # 動態偵測應用程式名稱
  current_path <- getwd()
  if (grepl("/l1_basic/[^/]+/?$", current_path)) {
    return(current_path)
  }
  
  # 嘗試一些常見的路徑模式
  base_path <- "/Users/che/Library/CloudStorage/Dropbox/ai_martech/l1_basic"
  if (dir.exists(base_path)) {
    # 檢查當前目錄名稱是否為應用程式名稱
    current_app <- basename(getwd())
    app_path <- file.path(base_path, current_app)
    if (dir.exists(app_path) && file.exists(file.path(app_path, "deploy_now.R"))) {
      return(app_path)
    }
  }
  
  # 預設使用當前目錄
  return(getwd())
}

# 自動偵測並切換到專案目錄
find_project_root <- function(start_dir = NULL) {
  if (is.null(start_dir)) {
    start_dir <- getwd()
  }
  
  # 方法 1: 如果在 RStudio 中執行
  if (Sys.getenv("RSTUDIO") == "1" && requireNamespace("rstudioapi", quietly = TRUE)) {
    project <- tryCatch(
      rstudioapi::getActiveProject(),
      error = function(e) NULL
    )
    if (!is.null(project)) {
      return(project)
    }
  }
  
  # 方法 2: 使用 rprojroot（如果有安裝）
  if (requireNamespace("rprojroot", quietly = TRUE)) {
    root <- tryCatch(
      rprojroot::find_root(rprojroot::is_rstudio_project, path = start_dir),
      error = function(e) NULL
    )
    if (!is.null(root)) {
      return(root)
    }
  }
  
  # 方法 3: 從起始目錄向上尋找 .Rproj 檔案
  current_dir <- start_dir
  while (TRUE) {
    rproj_files <- list.files(current_dir, pattern = "\\.Rproj$", full.names = TRUE)
    if (length(rproj_files) > 0) {
      return(current_dir)
    }
    
    parent <- dirname(current_dir)
    if (parent == current_dir) break  # 已到根目錄
    current_dir <- parent
  }
  
  # 方法 4: 從起始目錄向上尋找 app.R 或 scripts 目錄
  current_dir <- start_dir
  while (TRUE) {
    if (file.exists(file.path(current_dir, "app.R")) || 
        file.exists(file.path(current_dir, "app_config.yaml")) ||
        (dir.exists(file.path(current_dir, "scripts")) && 
         file.exists(file.path(current_dir, "scripts/global_scripts/23_deployment/sc_deployment_config.R")))) {
      return(current_dir)
    }
    
    parent <- dirname(current_dir)
    if (parent == current_dir) break
    current_dir <- parent
  }
  
  # 如果都找不到，使用起始目錄
  return(start_dir)
}

# 取得腳本目錄
script_dir <- get_script_dir()
cat("📂 腳本位置:", script_dir, "\n")

# 切換到專案目錄
project_root <- find_project_root(script_dir)
if (getwd() != project_root) {
  cat("📍 切換到專案目錄:", project_root, "\n")
  setwd(project_root)
}

# 確認在正確的目錄
if (!file.exists("scripts/global_scripts/23_deployment/sc_deployment_config.R")) {
  cat("❌ 錯誤：找不到部署腳本\n")
  cat("當前目錄:", getwd(), "\n")
  cat("請確認您在應用程式目錄中\n")
  stop("無法找到部署腳本")
}

# 執行配置驅動的一鍵部署腳本（互動式）
source("scripts/global_scripts/23_deployment/sc_deployment_config.R") 