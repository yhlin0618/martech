## ----------------------  .Rprofile  ----------------------
## This file is named sc_Rprofile.R instead of .Rprofile to ensure Git tracking.
## To use this file, copy it to .Rprofile in your project root or working directory.
##
## Usage:
## cp sc_Rprofile.R ~/.Rprofile    # for global use
## cp sc_Rprofile.R ./.Rprofile    # for project-specific use
##

## ❶ 私有環境（存放全部狀態與常數） --------------------------
.InitEnv <- new.env(parent = baseenv())
.InitEnv$mode <- NULL # 目前 OPERATION_MODE

# ## 掛到搜尋路徑最前（名稱維持 .autoinit_env） ----------------
# if (!".autoinit_env" %in% search()) attach(.InitEnv, name = ".autoinit_env")
# search()

## ❷ 共用工具函式存進 .InitEnv -------------------------------
.InitEnv$detect_script_path <- function() {
  for (i in rev(seq_len(sys.nframe()))) {
    f <- tryCatch(sys.frame(i)$ofile, error = function(e) NULL)
    if (!is.null(f) && nzchar(f)) {
      return(normalizePath(f))
    }
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
    p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) {
      return(normalizePath(p))
    }
  }
  ca <- commandArgs(trailingOnly = FALSE)
  fi <- sub("^--file=", "", ca[grep("^--file=", ca)])
  if (length(fi) == 1) {
    return(normalizePath(fi))
  }
  ""
}

.InitEnv$get_mode <- function(path) {
  # Walk up the path ancestry to find update_scripts or global_scripts
  # This handles scripts in subdirectories like ETL/amz/ or DRV/all/
  if (nzchar(path)) {
    path_lower <- tolower(path)
    parts <- unlist(strsplit(path_lower, .Platform$file.sep, fixed = TRUE))
    if ("update_scripts" %in% parts) return("UPDATE_MODE")
    if ("global_scripts" %in% parts) return("GLOBAL_MODE")
  }
  "APP_MODE"
}

## ❸ 初始化函式（存放於 .InitEnv） ----------------------------
.InitEnv$autoinit <- function() {
  # Allow explicit override: if OPERATION_MODE was pre-set in .GlobalEnv, respect it
  if (exists("OPERATION_MODE", envir = .GlobalEnv, inherits = FALSE)) {
    .InitEnv$OPERATION_MODE <- get("OPERATION_MODE", envir = .GlobalEnv)
  } else {
    .InitEnv$OPERATION_MODE <- .InitEnv$get_mode(.InitEnv$detect_script_path())
  }
  if (identical(.InitEnv$mode, .InitEnv$OPERATION_MODE)) {
    return(invisible(NULL))
  }

  message(">> OPERATION_MODE = ", .InitEnv$OPERATION_MODE)
  .InitEnv$OPERATION_MODE <- .InitEnv$OPERATION_MODE

  if (!requireNamespace("here", quietly = TRUE)) {
    install.packages("here") # 若不存在就安裝
  }

  base <- if (exists("APP_DIR", envir = .InitEnv)) {
    .InitEnv$APP_DIR
  } else {
    base <- here::here()
    list2env(list(
      APP_DIR = base,
      COMPANY_DIR = dirname(base),
      GLOBAL_DIR = file.path(base, "scripts", "global_scripts"),
      GLOBAL_DATA_DIR = file.path(base, "scripts", "global_scripts", "30_global_data"),
      GLOBAL_PARAMETER_DIR = file.path(base, "scripts", "global_scripts", "30_global_data", "parameters"),
      CONFIG_PATH = file.path(base, "app_config.yaml"),
      APP_DATA_DIR = file.path(base, "data", "app_data"),
      APP_PARAMETER_DIR = file.path(base, "data", "app_data", "parameters"),
      LOCAL_DATA_DIR = file.path(base, "data", "local_data")
      # app_config_path
    ), envir = .InitEnv)
    base
  }

  # ---- 讀取 db_paths.yaml (DM_R048: YAML for configuration) -----------------
  yaml_path <- file.path(.InitEnv$GLOBAL_DIR, "30_global_data", "parameters",
                         "scd_type1", "db_paths.yaml")
  if (!file.exists(yaml_path)) {
    stop("Required db configuration file not found: ", yaml_path, ". db_paths.yaml is mandatory.")
  }

  # Load YAML and construct full paths
  db_config <- yaml::read_yaml(yaml_path)
  db_path_list <- list()

  # Process databases section (DM_R050: Mode-Specific Path Loading)
  if (!is.null(db_config$databases)) {
    if (.InitEnv$OPERATION_MODE == "APP_MODE") {
      # APP_MODE: load the databases consumed at Shiny runtime.
      #   - app_data is REQUIRED on disk (fail-fast below).
      #   - meta_data is OPTIONAL (DM_R054 v2.1.1): populate when the local
      #     DuckDB file exists (local dev / DuckDB mode), but tolerate its
      #     absence so Supabase-mode deploys on Posit Connect don't fail
      #     fast when no local meta_data.duckdb is bundled.
      if ("app_data" %in% names(db_config$databases)) {
        db_path_list[["app_data"]] <-
          file.path(base, db_config$databases[["app_data"]])
      }
      if ("meta_data" %in% names(db_config$databases)) {
        .meta_path <- file.path(base, db_config$databases[["meta_data"]])
        if (file.exists(.meta_path)) {
          db_path_list[["meta_data"]] <- .meta_path
        } else if (nzchar(Sys.getenv("AUTOINIT_DEBUG", ""))) {
          message("[autoinit-debug] APP_MODE: meta_data.duckdb absent at ",
                  .meta_path,
                  " — skipping (DM_R054 v2.1.1: Supabase mode will handle ",
                  "via dbConnectAppData).")
        }
        rm(.meta_path)
      }
    } else {
      # UPDATE_MODE/GLOBAL_MODE: 載入所有路徑
      for (name in names(db_config$databases)) {
        db_path_list[[name]] <- file.path(base, db_config$databases[[name]])
      }
    }
  }

  # Process domain section (only for UPDATE_MODE/GLOBAL_MODE)
  if (!is.null(db_config$domain) &&
      .InitEnv$OPERATION_MODE %in% c("UPDATE_MODE", "GLOBAL_MODE")) {
    for (name in names(db_config$domain)) {
      db_path_list[[name]] <- file.path(base, db_config$domain[[name]])
    }
  }

  # ---- Fail-fast precheck (autoinit-failfast-policy spec) -------------------
  # Verify all required DB files exist on disk BEFORE any downstream
  # sc_initialization_*.R is sourced. Without this guard, a missing .duckdb
  # path on Dropbox CloudStorage can cause DuckDB create + sync lock
  # contention, leading to multi-hour hangs (see issue #421).
  #
  # DM_R054 v2.1.1: APP_MODE is OUT OF SCOPE for this precheck because
  # production deploys on Posit Connect run with database.mode = supabase
  # and have NO local DuckDB files in /cloud/project/data/. Fail-fast in
  # APP_MODE would always trip on Posit Connect. Shiny startup errors in
  # APP_MODE are handled by dbConnectAppData() which routes to Supabase
  # when local DuckDB is unreachable. Dropbox × DuckDB race (issue #421)
  # only manifests in UPDATE_MODE anyway (ETL pipeline runs there).
  run_precheck <- !identical(.InitEnv$OPERATION_MODE, "APP_MODE")
  if (nzchar(Sys.getenv("AUTOINIT_DEBUG", ""))) {
    message("[autoinit-debug] OPERATION_MODE=", .InitEnv$OPERATION_MODE,
            "; precheck=", if (run_precheck) "ENABLED" else "SKIPPED (APP_MODE)")
    if (run_precheck) {
      message("[autoinit-debug] precheck running for ", length(db_path_list), " DB paths")
      for (n in names(db_path_list)) {
        message("[autoinit-debug]   ", n, " -> ", db_path_list[[n]],
                " (exists=", file.exists(db_path_list[[n]]), ")")
      }
    }
  }
  missing_dbs <- character()
  if (run_precheck) {
    for (name in names(db_path_list)) {
      path <- db_path_list[[name]]
      if (!file.exists(path)) {
        missing_dbs <- c(missing_dbs,
                         sprintf("  - %s: %s", name, path))
      }
    }
  }
  if (length(missing_dbs) > 0) {
    company <- basename(base)
    stop(sprintf(
      paste0(
        "ETL pipeline incomplete: %d required DB file(s) missing:\n",
        "%s\n\n",
        "Remediation: %s\n",
        "  cd %s/scripts/update_scripts\n",
        "  make run PLATFORM=<platform>              # full pipeline\n",
        "  make run PLATFORM=<platform> TARGET=<tgt> # specific layer\n\n",
        "Typical first-time bootstrap:\n",
        "  make config-full && make run PLATFORM=amz"
      ),
      length(missing_dbs),
      paste(missing_dbs, collapse = "\n"),
      if (length(missing_dbs) >= 2)
        "Multiple layers missing; run the full pipeline to rebuild."
      else
        "Run the ETL target that produces the missing file.",
      company
    ), call. = FALSE)
  }

  # Assign to environments
  assign("db_path_list", db_path_list, envir = .InitEnv)
  assign("db_path_list", db_path_list, envir = .GlobalEnv)
  list2env(db_path_list, envir = .GlobalEnv)

  ## 把 .InitEnv 裡所有綁定複製到 .GlobalEnv (這樣常數才能被使用)
  list2env(as.list(.InitEnv, all.names = TRUE), envir = .GlobalEnv)

  ## 1️⃣ 決定應該載入哪些初始化腳本（向量）
  init_files <- switch(OPERATION_MODE,
    UPDATE_MODE = c(
      "sc_initialization_app_mode.R",
      "sc_initialization_update_mode.R"
    ), # ← 兩支都跑
    GLOBAL_MODE = "sc_initialization_update_mode.R",
    APP_MODE = "sc_initialization_app_mode.R"
  )

  ## 2️⃣ 逐一載入 -------------------------------------------------
  for (f in init_files) {
    full <- file.path(.InitEnv$GLOBAL_DIR, "22_initializations", f)
    if (file.exists(full)) {
      sys.source(full, envir = .GlobalEnv)
    } else {
      stop("Init file not found: ", full)
    }
  }

  .GlobalEnv$INITIALIZATION_COMPLETED <- TRUE

  invisible(NULL)
}

## ❹ 收尾函式（存放於 .InitEnv） ------------------------------
.InitEnv$autodeinit <- function() {
  ## 1. 關閉所有資料庫連線（函式在 .InitEnv 內）
  if (exists("dbDisconnect_all")) {
    dbDisconnect_all()
  }

  # ## 2. 從搜尋路徑移除 .InitEnv（若有 attach 過）
  # if (".autoinit_env" %in% search()) detach(".autoinit_env")

  ## 3. 刪除 .GlobalEnv 中除 .InitEnv 以外的所有物件 ----------
  objs <- ls(envir = .GlobalEnv, all.names = TRUE)
  objs <- setdiff(objs, c(".InitEnv")) # 保留私有環境
  rm(list = objs, envir = .GlobalEnv)
  gc() # 觸發垃圾回收

  ## 4. 把轉接器薄殼函式重新放回 .GlobalEnv -------------------
  assign("autoinit",
    function(...) .InitEnv$autoinit(...),
    envir = .GlobalEnv
  )
  assign("autodeinit",
    function(...) .InitEnv$autodeinit(...),
    envir = .GlobalEnv
  )

  ## 5. 清除 MODE 旗標，讓下次 autoinit() 重新啟動 ------------
  .InitEnv$mode <- NULL
  message(">> De-init completed ‒ GlobalEnv 已清空並重建薄殼")

  invisible(NULL)
}

## ❺ .GlobalEnv 轉接器（薄殼函式） ---------------------------
assign("autoinit",
  function(...) .InitEnv$autoinit(...),
  envir = .GlobalEnv
)
assign("autodeinit",
  function(...) .InitEnv$autodeinit(...),
  envir = .GlobalEnv
)

## ❻ （可選）啟動即初始化；若不想自動請註解 ------------------
# autoinit()
## -----------------------------------------------------------
