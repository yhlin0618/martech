# ==========================================
# VitalSigns - Customer Vitality Diagnostic System
# ==========================================
# L3 Premium Application
# InsightForge Dynamic YAML Architecture v4.0
# Version: 2.0.0 - Generator Migration
# Last Updated: 2025-10-12
# ==========================================

# ==========================================
# 設定應用類型識別
# ==========================================
Sys.setenv(APP_TYPE = "vitalsigns")
Sys.setenv(APP_CONFIG_FILE = "config/yaml/vitalsigns_config/vitalsigns.yaml")

# ==========================================
# 載入 VitalSigns 環境變數
# ==========================================
message("🔧 載入 VitalSigns 環境變數...")

# Load VitalSigns-specific .env file
vitalsigns_env_file <- "env/vitalsigns/.env"
if (file.exists(vitalsigns_env_file)) {
  # Manual loading (more reliable than dotenv for this use case)
  env_lines <- readLines(vitalsigns_env_file, warn = FALSE)
  env_lines <- env_lines[!grepl("^#", env_lines) & nzchar(trimws(env_lines))]

  for (line in env_lines) {
    if (grepl("=", line)) {
      parts <- strsplit(line, "=", fixed = TRUE)[[1]]
      if (length(parts) >= 2) {
        key <- trimws(parts[1])
        value <- trimws(paste(parts[-1], collapse = "="))
        value <- gsub('^["\']|["\']$', '', value)  # Remove quotes

        # Set environment variable using proper syntax
        do.call(Sys.setenv, setNames(list(value), key))
      }
    }
  }
  message("✅ 已載入 VitalSigns 環境變數: ", vitalsigns_env_file)

  # Verify key variables are loaded
  if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    message("   - OPENAI_API_KEY: ", substr(Sys.getenv("OPENAI_API_KEY"), 1, 20), "...")
  }
  if (nzchar(Sys.getenv("PGHOST"))) {
    message("   - PGHOST: ", Sys.getenv("PGHOST"))
  }
} else {
  message("⚠️  找不到 VitalSigns .env 檔案，使用預設設定")
  message("   期望路徑: ", vitalsigns_env_file)
}

# ==========================================
# 載入必要套件
# ==========================================
message("📦 載入必要套件...")

suppressPackageStartupMessages({
  library(shiny)
  library(bs4Dash)
  library(shinyjs)
  library(yaml)
  library(dplyr)
  library(tidyr)
  library(DT)
  library(DBI)
  library(RPostgres)
  library(RSQLite)
  library(stringr)
  library(readxl)
  library(jsonlite)
  library(httr)
  library(httr2)
  library(plotly)
  library(GGally)
  library(tidyverse)
  library(bcrypt)
  library(future)
  library(furrr)
  library(markdown)
  library(shinycssloaders)
  library(tibble)
  library(lubridate)
  library(pool)     # Connection pooling 支援多並發用戶 (2025-01-07)
})

# ==========================================
# 設定檔案上傳大小限制 (從 YAML 讀取)
# ==========================================
# Read upload size limit from module config
upload_config_path <- "config/yaml/module_config/vitalsigns_upload.yaml"
if (file.exists(upload_config_path)) {
  upload_config <- yaml::read_yaml(upload_config_path)
  max_file_size_mb <- if (!is.null(upload_config$upload_limits) &&
                          !is.null(upload_config$upload_limits$max_file_size_mb)) {
    upload_config$upload_limits$max_file_size_mb
  } else {
    100  # Fallback default
  }
  options(shiny.maxRequestSize = max_file_size_mb * 1024^2)
  message(sprintf("✅ 已設定檔案上傳大小限制: %dMB (從配置檔讀取)", max_file_size_mb))
} else {
  # Fallback if config not found
  options(shiny.maxRequestSize = 100 * 1024^2)
  message("⚠️  找不到上傳配置檔，使用預設限制: 100MB")
}

# ==========================================
# 自動切換工作目錄
# ==========================================
tryCatch({
  if (!is.null(sys.frame(1)$ofile)) {
    this_file <- sys.frame(1)$ofile
  } else {
    ca <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", ca, value = TRUE)
    if (length(file_arg)) this_file <- sub("--file=", "", file_arg[1])
  }

  if (exists("this_file") && !is.null(this_file)) {
    this_dir <- dirname(normalizePath(this_file))
    setwd(this_dir)
    message("✅ 工作目錄已設定為: ", getwd())
  }
}, error = function(e) {
  message("⚠️ 無法自動設定工作目錄")
})

# ==========================================
# 載入環境變數和配置
# ==========================================
# 載入 dotenv
if (!requireNamespace("dotenv", quietly = TRUE)) {
  install.packages("dotenv")
}
library(dotenv)

# 載入 .env 檔案
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
  message("✅ 已載入 .env 檔案")
}

# 載入配置檔
if (file.exists("config/config.R")) {
  source("config/config.R")
  message("✅ 已載入 config/config.R")
}

# 載入套件檔
if (file.exists("config/packages.R")) {
  source("config/packages.R")
  if (exists("initialize_packages")) {
    initialize_packages()
  }
  message("✅ 已載入 config/packages.R")
}

# ==========================================
# 載入 Supabase 登入模組（必須在 UI 生成器之前）
# 模組位於 global_scripts，可透過 git subrepo 在各專案共用
# ==========================================
# 認證工具在 11_rshinyapp_utils（工具類）
supabase_auth_path <- "scripts/global_scripts/11_rshinyapp_utils/supabase_auth"
# 登入元件在 10_rshinyapp_components（元件類）
login_component_path <- "scripts/global_scripts/10_rshinyapp_components/login"

if (file.exists(file.path(supabase_auth_path, "module_supabase_auth.R")) &&
    file.exists(file.path(login_component_path, "module_login_supabase.R"))) {
  source(file.path(supabase_auth_path, "module_supabase_auth.R"))
  source(file.path(login_component_path, "module_login_supabase.R"))
  USE_SUPABASE_AUTH <<- TRUE
  message("✅ 已載入 Supabase 登入模組 (from global_scripts)")
} else {
  stop("❌ 找不到 Supabase 登入模組")
}

# ==========================================
# 載入工具模組
# ==========================================
message("🔧 載入工具模組...")

# Configuration Manager
if (file.exists("utils/config_manager.R")) {
  source("utils/config_manager.R")
}

# UI Generator
if (file.exists("utils/ui_generator.R")) {
  source("utils/ui_generator.R")
}

# Server Engine (not needed - we follow BrandEdge's inline pattern)
if (file.exists("utils/server_engine.R")) {
  source("utils/server_engine.R")
}

# Module Manager
if (file.exists("utils/module_manager.R")) {
  source("utils/module_manager.R")
}

# Session Manager
if (file.exists("utils/session_manager.R")) {
  source("utils/session_manager.R")
}

# Language Manager
if (file.exists("utils/language_manager.R")) {
  source("utils/language_manager.R")
  message("✅ 已載入語言管理系統")
}

# Unified Content Manager
if (file.exists("utils/unified_content_manager.R")) {
  source("utils/unified_content_manager.R")
  message("✅ 已載入統一內容管理系統")
}

# Sidebar Updater
if (file.exists("utils/sidebar_updater.R")) {
  source("utils/sidebar_updater.R")
  message("✅ 已載入側邊欄更新器")
}

# Unified Language Sync
if (file.exists("utils/unified_language_sync.R")) {
  source("utils/unified_language_sync.R")
  message("✅ 已載入統一語言同步架構")
}

# Unified Language Manager
if (file.exists("utils/unified_language_manager.R")) {
  source("utils/unified_language_manager.R")
  message("✅ 已載入統一語言管理器")
}

# Database Connection
if (file.exists("database/db_connection.R")) {
  source("database/db_connection.R")
  message("✅ 已載入資料庫連接模組")
}

# Hint System
if (file.exists("utils/hint_system.R")) {
  source("utils/hint_system.R")
  message("✅ 已載入提示系統")
}

# Prompt Manager
if (file.exists("utils/prompt_manager.R")) {
  source("utils/prompt_manager.R")
  message("✅ 已載入 Prompt 管理系統")
}

# OpenAI Utils
if (file.exists("utils/openai_utils.R")) {
  source("utils/openai_utils.R")
  message("✅ 已載入 OpenAI 工具函數")
}

# Token Tracker
if (file.exists("utils/token_tracker.R")) {
  source("utils/token_tracker.R")
  message("✅ 已載入 Token 追蹤工具")
}

message("✅ 工具模組載入完成")

# ==========================================
# 修復並行處理設定
# ==========================================
if (Sys.getenv("SHINY_PORT") != "") {
  plan(sequential)
} else {
  plan(multisession, workers = min(2, parallel::detectCores() - 1))
}
options(future.rng.onMisuse = "ignore")

# ==========================================
# 設定資源路徑
# ==========================================
addResourcePath("assets", "scripts/global_scripts/24_assets")
addResourcePath("www", "www")
message("✅ 已設定資源路徑")

# ==========================================
# 載入配置
# ==========================================
message("📋 載入應用配置...")

# Load main app configuration
config_file <- Sys.getenv("APP_CONFIG_FILE", "config/yaml/vitalsigns_config/vitalsigns.yaml")

app_config <- if (exists("load_app_config")) {
  tryCatch({
    load_app_config(config_file)
  }, error = function(e) {
    message("配置載入失敗: ", e$message)
    # Use minimal configuration
    list(
      app_info = list(
        name = "VitalSigns 精準行銷平台",
        version = "2.0.0"
      ),
      modules = list(),
      pages = list()
    )
  })
} else {
  # If no config_manager, directly read YAML
  yaml::read_yaml(config_file)
}

# ==========================================
# 初始化統一語言管理系統
# ==========================================
# Determine initial language
config_language <- if (!is.null(app_config$language$default)) {
  # Convert config language directory name to language code
  if (app_config$language$default == "chinese") "zh_TW" else "en_US"
} else {
  "zh_TW"  # Default Chinese
}

# Set app_config as global variable for language manager
# NOTE 2025-01-07: 這個 assign 在 server 函數外，所以影響較小
# app_config 在每個 process 啟動時只讀取一次配置檔
assign("app_config", app_config, envir = .GlobalEnv)

# Initialize unified language manager
if (exists("initialize_unified_language_manager")) {
  initialize_unified_language_manager(config_language)
} else {
  stop("initialize_unified_language_manager() function not found. Please check utils/unified_language_manager.R is loaded.")
}

# DEBUG: Check global_lang_content type
if (exists("global_lang_content")) {
  glc_test <- get("global_lang_content", envir = .GlobalEnv)
  cat("🔍 [INIT DEBUG] global_lang_content type check:\n")
  cat("  - is.function:", is.function(glc_test), "\n")
  cat("  - class:", paste(class(glc_test), collapse = ", "), "\n")
  rm(glc_test)
}

default_language <- config_language

cat("🌍 === 語言初始化調試資訊 ===\n")
cat("🌍 app_config$language$default:", app_config$language$default, "\n")
cat("🌍 最終使用語言:", default_language, "\n")
cat("🌍 ================================\n")

message(paste("✅ 已載入初始語言內容:", default_language))

# Maintain backward compatibility
lang_content <- if (exists("get_unified_language_content") && is.function(get_unified_language_content)) {
  get_unified_language_content()
} else if (exists("global_lang_content") && is.function(global_lang_content)) {
  tryCatch(isolate(global_lang_content()), error = function(e) list(language = default_language, content = list()))
} else {
  list(language = default_language, content = list())
}

# ==========================================
# 語言輔助函數
# ==========================================
# Safe text retrieval function with fallback
get_text <- function(path, fallback = "", ...) {
  # Use dynamic language content - directly access global_lang_content (through closure)
  current_lang_content <- tryCatch({
    # Directly try to call global_lang_content() - it should be available via closure
    isolate(global_lang_content())
  }, error = function(e) {
    # If global_lang_content not available, try global_language_state directly
    cat("⚠️ [get_text] global_lang_content not accessible, trying global_language_state\n")
    tryCatch({
      if (exists("global_language_state", inherits = TRUE) && is.reactivevalues(global_language_state)) {
        isolate(global_language_state$language_content)
      } else if (exists("lang_content", inherits = TRUE)) {
        lang_content
      } else {
        NULL
      }
    }, error = function(e2) {
      cat("⚠️ [get_text] All fallbacks failed, using static fallback\n")
      if (exists("lang_content", inherits = TRUE)) {
        lang_content
      } else {
        NULL
      }
    })
  })

  # Debug: Show current language
  if (!is.null(current_lang_content$language)) {
    cat("🌐 [get_text] Path:", path, "| Language:", current_lang_content$language, "\n")
  }

  # Find text from language content
  result <- NULL
  if (!is.null(current_lang_content)) {
    keys <- strsplit(path, "\\.")[[1]]

    # Handle simple key with underscore
    if (length(keys) == 1 && grepl("_", keys[1])) {
      parts <- strsplit(keys[1], "_")[[1]]
      if (length(parts) >= 2) {
        # Try to find in common
        if (!is.null(current_lang_content$content$common)) {
          if (parts[1] == "app" && !is.null(current_lang_content$content$common$app)) {
            result <- current_lang_content$content$common$app[[paste(parts[-1], collapse = "_")]]
          } else if (parts[1] == "login" && !is.null(current_lang_content$content$common$login)) {
            result <- current_lang_content$content$common$login[[paste(parts[-1], collapse = "_")]]
          } else if (length(parts) >= 2 && parts[length(parts)] %in% c("button", "btn") && !is.null(current_lang_content$content$common$buttons)) {
            button_key <- paste(parts[-length(parts)], collapse = "_")
            result <- current_lang_content$content$common$buttons[[button_key]]
          } else if (!is.null(current_lang_content$content$common[[parts[1]]])) {
            if (length(parts) == 2) {
              result <- current_lang_content$content$common[[parts[1]]][[parts[2]]]
            } else {
              result <- current_lang_content$content$common[[parts[1]]][[paste(parts[-1], collapse = "_")]]
            }
          }
        }

        # If not found, try to find in modules
        if (is.null(result) && !is.null(current_lang_content$content$modules)) {
          if (!is.null(current_lang_content$content$modules[[parts[1]]])) {
            if (length(parts) == 2) {
              result <- current_lang_content$content$modules[[parts[1]]][[parts[2]]]
            } else {
              result <- current_lang_content$content$modules[[parts[1]]][[paste(parts[-1], collapse = "_")]]
            }
          }
        }
      }
    }

    # If simple key not found, try standard path lookup
    if (is.null(result)) {
      # Start from content.common
      if (!is.null(current_lang_content$content$common)) {
        temp_result <- current_lang_content$content$common
        for (key in keys) {
          if (is.list(temp_result) && key %in% names(temp_result)) {
            temp_result <- temp_result[[key]]
          } else {
            temp_result <- NULL
            break
          }
        }
        if (!is.null(temp_result)) {
          result <- temp_result
        }
      }
    }

    # If not found, search from content directly
    if (is.null(result) && !is.null(current_lang_content$content)) {
      temp_result <- current_lang_content$content
      for (key in keys) {
        if (is.list(temp_result) && key %in% names(temp_result)) {
          temp_result <- temp_result[[key]]
        } else {
          temp_result <- NULL
          break
        }
      }
      if (!is.null(temp_result)) {
        result <- temp_result
      }
    }

    # If still not found, search directly from language content
    if (is.null(result)) {
      temp_result <- current_lang_content
      for (key in keys) {
        if (is.list(temp_result) && key %in% names(temp_result)) {
          temp_result <- temp_result[[key]]
        } else {
          temp_result <- NULL
          break
        }
      }
      if (!is.null(temp_result) && is.character(temp_result)) {
        result <- temp_result
      }
    }
  }

  # If no result found, use fallback
  if (is.null(result)) {
    cat("⚠️ [get_text] Path not found:", path, "- Using fallback:", fallback, "\n")
    result <- fallback
  } else {
    cat("✅ [get_text] Found:", path, "=", as.character(result), "\n")
  }

  # Support string template replacement
  if (length(list(...)) > 0 && is.character(result)) {
    args <- list(...)
    for (name in names(args)) {
      result <- gsub(paste0("\\{", name, "\\}"), args[[name]], result)
    }
  }

  return(if (is.character(result)) result else fallback)
}

# ==========================================
# Module language text retrieval function
# ==========================================
get_module_text <- function(module_id, path, fallback = "", ...) {
  current_lang_content <- if (exists("global_lang_content") && is.function(global_lang_content)) {
    tryCatch(isolate(global_lang_content()), error = function(e) NULL)
  } else {
    NULL
  }

  if (is.null(current_lang_content) || is.null(current_lang_content$content$modules)) {
    return(fallback)
  }

  module_content <- current_lang_content$content$modules[[module_id]]
  if (is.null(module_content)) {
    return(fallback)
  }

  keys <- strsplit(path, "\\.")[[1]]
  result <- module_content

  for (key in keys) {
    if (is.list(result) && key %in% names(result)) {
      result <- result[[key]]
    } else {
      return(fallback)
    }
  }

  # Support string template replacement
  if (length(list(...)) > 0 && is.character(result)) {
    args <- list(...)
    for (name in names(args)) {
      result <- gsub(paste0("\\{", name, "\\}"), args[[name]], result)
    }
  }

  return(if (is.character(result)) result else fallback)
}

# ==========================================
# NULL coalescing operator
# ==========================================
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

# ==========================================
# Module language text helper function
# ==========================================
get_module_texts <- function(lang_content, module_name) {
  language_code <- if (!is.null(lang_content$language)) {
    lang_content$language
  } else {
    "zh_TW"
  }

  module_texts <- get_module_language_content(module_name, language_code)

  if (!is.null(module_texts)) {
    module_texts$language <- language_code
  }

  return(module_texts)
}

# ==========================================
# Display configuration information
# ==========================================
message("========================================")
message("應用程式: ", app_config$app_info$name %||% "未命名")
message("版本: ", app_config$app_info$version %||% "2.0.0")
message("環境: ", app_config$environment$mode %||% "development")
message("========================================")

# ==========================================
# 載入 VitalSigns 模組
# ==========================================
message("載入 VitalSigns 模組...")

# 載入登入模組
# 注意：無論使用 Supabase 或傳統認證，都需要載入傳統模組以獲取 loginModuleUI
if (file.exists("modules/module_login.R")) {
  source("modules/module_login.R")
  message("✅ 已載入傳統登入模組（UI 函數）")
} else {
  message("⚠️ 未找到傳統登入模組")
}

# 檢查 Supabase 是否已在前面載入（from global_scripts）
# 如果已載入，跳過此區塊；否則嘗試備用路徑
if (!exists("USE_SUPABASE_AUTH") || !USE_SUPABASE_AUTH) {
  if (file.exists(file.path(supabase_auth_path, "module_supabase_auth.R")) &&
      file.exists(file.path(login_component_path, "module_login_supabase.R"))) {
    source(file.path(supabase_auth_path, "module_supabase_auth.R"))
    source(file.path(login_component_path, "module_login_supabase.R"))
    USE_SUPABASE_AUTH <<- TRUE
    message("✅ 已載入 Supabase 登入模組（fallback）")
  } else {
    USE_SUPABASE_AUTH <<- FALSE
    message("ℹ️ 將使用傳統登入模組")
  }
} else {
  message("✅ Supabase 登入模組已在前面載入，跳過此區塊")
}

# Dynamically load VitalSigns modules from YAML
if (!is.null(app_config$pages)) {
  cat("📋 檢查 pages 配置...\n")
  cat("   總頁面數:", length(app_config$pages), "\n")

  # Collect all enabled module names (exclude login, it's already loaded separately)
  module_names <- unique(sapply(app_config$pages, function(page) {
    page_id <- page$id %||% "NULL"
    page_module <- page$module %||% "NULL"
    page_enabled <- page$enabled %||% FALSE

    cat(sprintf("   檢查頁面: %s (module: %s, enabled: %s)\n",
                page_id, page_module, page_enabled))

    if (!is.null(page$module) && page$enabled &&
        !page$module %in% c("login")) {
      cat("      -> 將載入此模組\n")
      return(page$module)
    }
    cat("      -> 跳過\n")
    return(NULL)
  }))

  # Remove NULL values
  module_names <- module_names[!sapply(module_names, is.null)]
  cat("📦 準備載入的模組列表:\n")
  for (i in seq_along(module_names)) {
    cat(sprintf("   %d. %s\n", i, module_names[[i]]))
  }

  # Load each module
  for (module_name in module_names) {
    cat("🔍 嘗試載入模組:", module_name, "\n")

    # Check if already has "vitalsigns_" prefix to avoid duplication
    if (grepl("^vitalsigns_", module_name)) {
      module_file <- paste0("modules/module_", module_name, ".R")
    } else {
      module_file <- paste0("modules/module_vitalsigns_", module_name, ".R")
    }

    cat("   第一次嘗試路徑:", module_file, "\n")

    if (file.exists(module_file)) {
      source(module_file)
      message(paste("✅ 已從 YAML 配置載入:", basename(module_file)))
    } else {
      # Try without vitalsigns prefix as fallback
      alt_module_file <- paste0("modules/module_", module_name, ".R")
      cat("   備用路徑:", alt_module_file, "(存在:", file.exists(alt_module_file), ")\n")

      if (file.exists(alt_module_file)) {
        source(alt_module_file)
        message(paste("✅ 已從 YAML 配置載入:", basename(alt_module_file)))
      } else {
        warning(paste("⚠️ YAML 配置中的模組檔案不存在:", module_file, "和", alt_module_file))
      }
    }
  }

  message(paste("📦 共載入", length(module_names), "個 VitalSigns 模組"))
}

message("========================================")

# ==========================================
# 定義 UI (Using Generator - Same Pattern as BrandEdge)
# ==========================================
ui <- function() {
  # Check if dynamic UI generator exists
  if (exists("generate_app_ui")) {
    ui_content <- generate_app_ui(app_config)
    tagList(
      ui_content,
      # Register sidebar updater JavaScript
      if (exists("register_sidebar_updater_js")) {
        register_sidebar_updater_js()
      } else {
        NULL
      },
      # VitalSigns specific JavaScript and CSS
      tags$head(
        tags$style(HTML("
          /* VitalSigns specific styles */
          .step-indicator {
            display: flex;
            justify-content: space-between;
            margin-bottom: 2rem;
            padding: 1rem;
            background: #f8f9fa;
            border-radius: 8px;
          }
          .step-item {
            flex: 1;
            text-align: center;
            padding: 0.5rem;
            border-radius: 5px;
            transition: all 0.3s;
            margin: 0 5px;
          }
          .step-item.active {
            background: #007bff;
            color: white;
          }
          .step-item.completed {
            background: #28a745;
            color: white;
          }
          .welcome-banner {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1.5rem;
            border-radius: 10px;
            margin-bottom: 2rem;
            text-align: center;
          }
        "))
      ),
      tags$script(HTML("
        // Handle global language change messages
        Shiny.addCustomMessageHandler('global_language_change', function(data) {
          console.log('Received global language change:', data.language);
          Shiny.setInputValue('global_language_change', data, {priority: 'event'});
        });

        // Force module language sync handler
        Shiny.addCustomMessageHandler('force_module_language_sync', function(data) {
          console.log('🔄 Force module language sync:', data.language);
          setTimeout(function() {
            Shiny.setInputValue('force_language_reload', {
              language: data.language,
              timestamp: data.timestamp,
              force: true
            }, {priority: 'event'});

            if (window.Shiny && window.Shiny.unbindAll && window.Shiny.bindAll) {
              try {
                window.Shiny.unbindAll();
                window.Shiny.bindAll();
                console.log('✅ Shiny elements rebound');
              } catch(e) {
                console.log('⚠️ Shiny rebind warning:', e);
              }
            }
          }, 50);
        });

        // Listen to module language update messages
        Shiny.addCustomMessageHandler('module_language_update', function(data) {
          console.log('Module language update:', data.language);
          if (data.language) {
            sessionStorage.setItem('selected_language', data.language);
          }
        });

        // Handle language button style updates
        Shiny.addCustomMessageHandler('updateLanguageButtonClass', function(data) {
          console.log('Update language button style:', data);
          if (data.activeBtn) {
            $('#' + data.activeBtn).addClass('active').removeClass('btn-outline-primary').addClass('btn-primary');
          }
          if (data.inactiveBtn) {
            $('#' + data.inactiveBtn).removeClass('active').removeClass('btn-primary').addClass('btn-outline-primary');
          }
        });

        // Handle sidebar text updates
        Shiny.addCustomMessageHandler('updateSidebarText', function(data) {
          console.log('🌐 Update sidebar text:', data.id, '->', data.text);
          var element = document.getElementById(data.id);
          if (element) {
            element.textContent = data.text;
            console.log('✅ Sidebar text updated successfully');
          } else {
            console.log('⚠️ Sidebar element not found:', data.id);
          }
        });

        // Check sessionStorage for language setting on page load
        $(document).ready(function() {
          var savedLanguage = sessionStorage.getItem('selected_language');
          if (savedLanguage) {
            console.log('Load language setting from sessionStorage:', savedLanguage);
            Shiny.setInputValue('initial_language', savedLanguage, {priority: 'event'});
          }
        });
      "))
    )
  } else {
    # Fallback simple UI
    fluidPage(
      titlePanel(app_config$app_info$name %||% "VitalSigns 精準行銷平台"),
      sidebarLayout(
        sidebarPanel(
          h4("功能選單"),
          p("請檢查配置檔案")
        ),
        mainPanel(
          h3("系統初始化中"),
          p("請檢查配置檔案")
        )
      )
    )
  }
}

# ==========================================
# 定義 Server (Following BrandEdge Pattern Exactly)
# ==========================================
server <- function(input, output, session) {

  # ==========================================
  # Initialize reactive variables
  # ==========================================

  # User state
  user_logged_in <- reactiveVal(FALSE)
  current_user <- reactiveVal(NULL)

  # Output for conditionalPanel (needed by UI generator)
  output$user_logged_in <- reactive({
    user_logged_in()
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)

  # Data state
  upload_data <- reactiveVal(NULL)
  dna_data <- reactiveVal(NULL)
  analysis_data <- reactiveVal(NULL)
  allow_dna <- reactiveVal(FALSE)

  # Progress info
  progress_info <- reactiveVal(list(start=NULL, done=0, total=0))

  # UI update trigger
  module_ui_update_trigger <- reactiveVal(0)

  # ==========================================
  # Token 使用量追蹤
  # ==========================================
  token_state <- reactiveVal(create_token_state(
    model = app_config$api$openai$default_model %||% "gpt-5-nano"
  ))

  # 全域更新函數（供模組呼叫）
  update_token_usage <- function(usage_info) {
    if (!is.null(usage_info)) {
      current <- token_state()
      updated <- update_token_state(current, usage_info)
      token_state(updated)
      message(sprintf("📊 Token 更新: +%d tokens, 累計: %d, 費用: %s",
                     usage_info$total_tokens %||% 0,
                     updated$total_tokens,
                     format_cost(updated$total_cost)))
    }
  }
  assign("update_token_usage", update_token_usage, envir = .GlobalEnv)

  # Token 使用量 UI 輸出
  output$token_model_display <- renderUI({
    state <- token_state()
    tags$span(state$model)
  })

  output$token_count_display <- renderUI({
    state <- token_state()
    tags$span(format_tokens(state$total_tokens))
  })

  output$token_cost_display <- renderUI({
    state <- token_state()
    tags$span(format_cost(state$total_cost))
  })

  # ==========================================
  # Initialize language system (backward compatible)
  # ==========================================

  # Create global_lang_content reactive (derived from global_language_state)
  if (exists("global_language_state") && is.reactivevalues(global_language_state)) {
    global_lang_content <- reactive({
      # Trigger update
      global_language_state$update_trigger

      # Return language content
      if (!is.null(global_language_state$language_content)) {
        return(global_language_state$language_content)
      } else {
        return(list())
      }
    })

    message("✅ [Server] global_lang_content reactive created")
  } else {
    # If no unified language manager, create empty reactive
    global_lang_content <- reactive({ list() })
    warning("⚠️ [Server] global_language_state doesn't exist, using empty global_lang_content")
  }

  # ==========================================
  # Language switching handlers
  # ==========================================

  # Switch language from navbar
  observeEvent(input$navbar_language_selector, {
    req(input$navbar_language_selector)

    new_language <- input$navbar_language_selector
    current_language <- isolate(global_language_state$language_content$language)

    cat("🌍 Navbar language switch:", new_language, "(current:", current_language, ")\n")

    # ⚠️ Only execute switch if language actually changed
    if (new_language != current_language) {
      if (exists("unified_language_switch") && is.function(unified_language_switch)) {
        unified_language_switch(
          session = session,
          new_language = new_language,
          app_config = app_config,
          module_ui_update_trigger = module_ui_update_trigger
        )
        message("✅ Language switched:", new_language)

        # ✅ Show notification but don't reload (avoid logout)
        lang_name <- switch(new_language,
          "zh_TW" = "中文",
          "en_US" = "English",
          "ja_JP" = "日本語",
          new_language
        )

        # Show notification based on new language
        notification_msg <- switch(new_language,
          "zh_TW" = paste0("語言已切換為", lang_name, "。側邊欄已更新。請點擊其他頁面以查看完整語言變更。"),
          "en_US" = paste0("Language switched to ", lang_name, ". Sidebar updated. Click another page to see full language change."),
          "ja_JP" = paste0("言語を", lang_name, "に切り替えました。サイドバーが更新されました。完全な言語変更を確認するには、別のページをクリックしてください。"),
          paste0("Language updated to ", lang_name, ". Sidebar menu updated. Click another page to see full change.")
        )

        showNotification(
          notification_msg,
          type = "message",
          duration = 5
        )
        # ⚠️ Don't use session$reload() - would cause logout
      }
    } else {
      cat("⏭️  Language unchanged, skip switch\n")
    }
  }, ignoreInit = TRUE)

  # Switch language from home page
  observeEvent(input$home_language_change, {
    req(input$home_language_change)

    new_language <- input$home_language_change$language
    cat("🌍 Home page language switch:", new_language, "\n")

    if (exists("unified_language_switch") && is.function(unified_language_switch)) {
      unified_language_switch(
        session = session,
        new_language = new_language,
        app_config = app_config,
        module_ui_update_trigger = module_ui_update_trigger
      )
      message("✅ Language switched:", new_language)
    }
  })

  # Switch language from module
  observeEvent(input$global_language_change, {
    req(input$global_language_change)

    new_language <- input$global_language_change$language
    cat("🌍 Module language switch:", new_language, "\n")

    if (exists("unified_language_switch") && is.function(unified_language_switch)) {
      unified_language_switch(
        session = session,
        new_language = new_language,
        app_config = app_config,
        module_ui_update_trigger = module_ui_update_trigger
      )

      # Send force sync message
      session$sendCustomMessage("force_module_language_sync", list(
        language = new_language,
        timestamp = as.numeric(Sys.time())
      ))

      message("✅ Language switched and synced:", new_language)
    }
  })

  # ==========================================
  # Initialize language from sessionStorage
  # ==========================================
  observeEvent(input$initial_language, {
    req(input$initial_language)

    saved_language <- input$initial_language
    cat("🌍 Load language from sessionStorage:", saved_language, "\n")

    if (exists("unified_language_switch") && is.function(unified_language_switch)) {
      unified_language_switch(
        session = session,
        new_language = saved_language,
        app_config = app_config,
        module_ui_update_trigger = module_ui_update_trigger
      )
      message("✅ Language setting restored:", saved_language)
    }
  })

  # ==========================================
  # Login module handling
  # ==========================================
  login_result <- NULL

  # 優先使用 Supabase 登入模組
  if (exists("USE_SUPABASE_AUTH") && USE_SUPABASE_AUTH && exists("loginSupabaseServer")) {
    message("🔐 使用 Supabase 登入模組")
    login_result <- loginSupabaseServer("login1", app_name = "vitalsigns")
  } else if (exists("loginModuleServer")) {
    message("🔐 使用傳統 bcrypt 登入模組")
    # Get language texts for login module (use generic "login", not app-specific)
    # Use lang_content (static variable from initialization), not global_lang_content() reactive!
    login_lang_texts <- if (!is.null(lang_content)) {
      get_module_texts(lang_content, "login")
    } else {
      NULL
    }

    login_result <- loginModuleServer("login1", lang_texts = login_lang_texts)
  }

  # 登入狀態監聽（適用於 Supabase 和傳統登入）
  if (!is.null(login_result)) {
    observe({
      if (!is.null(login_result$user_info())) {
        user_logged_in(TRUE)
        current_user(login_result$user_info())
        message("✅ User logged in:", login_result$user_info()$username)
      }
    })

    # Handle logout - monitor logged_in reactive value
    observe({
      if (!is.null(login_result$logged_in) && is.function(login_result$logged_in)) {
        logged_in_status <- tryCatch({
          login_result$logged_in()
        }, error = function(e) {
          TRUE  # If error, assume still logged in
        })

        # Detect logout: was logged in (current_user exists), now logged out
        if (!logged_in_status && !is.null(current_user())) {
          user_logged_in(FALSE)
          current_user(NULL)
          message("👋 User logged out")
        }
      }
    })
  }

  # ==========================================
  # Storage for cross-module data sharing
  # ==========================================
  # Create reactiveValues in parent scope for module communication
  shared_data <- reactiveValues(
    upload_result = NULL,
    dna_result = NULL
  )

  # ==========================================
  # Logout button handler
  # ==========================================
  observeEvent(input$logout_btn, {
    message("🚪 Logout button clicked")

    # Update state FIRST to trigger UI change
    user_logged_in(FALSE)
    current_user(NULL)

    # Clear shared data
    shared_data$upload_result <- NULL
    shared_data$dna_result <- NULL

    # Call login module logout function to clear its internal state
    if (!is.null(login_result) && !is.null(login_result$logout)) {
      tryCatch({
        login_result$logout()
        message("✅ Login module logout called successfully")
      }, error = function(e) {
        message("⚠️ Login module logout error:", e$message)
      })
    }

    # Force session reload to return to login page
    session$reload()

    message("👋 User logged out via button - UI reloading to show login page")
  })

  # ==========================================
  # Dynamic module initialization - VitalSigns Submodules
  # ==========================================
  # Initialize module server for each enabled page
  for (page in app_config$pages) {
    # Skip login (already initialized above)
    if (!is.null(page$module) && page$enabled &&
        !page$id %in% c("login")) {
      local({
        page_id <- page$id
        module_name <- page$module

        cat("📦 Initialize module server:", module_name, "(ID:", page_id, ")\n")

        # Handle naming mappings
        name_mappings <- list(
          "vitalsigns_upload" = "uploadVitalsigns",
          "vitalsigns_dna" = "dnaVitalsigns",
          "vitalsigns_acquisition" = "acquisitionVitalsigns",
          "vitalsigns_retention" = "retentionVitalsigns",
          "vitalsigns_engagement" = "engagementVitalsigns",
          "vitalsigns_revenue_pulse" = "revenuePulseVitalsigns"
        )

        base_name <- name_mappings[[module_name]]
        if (is.null(base_name)) base_name <- module_name

        server_func_name <- paste0(base_name, "ModuleServer")

        if (exists(server_func_name)) {
          server_func <- get(server_func_name)

          # Create dynamic language content reactive
          module_lang_texts <- reactive({
            current_lang <- global_lang_content()
            cat("📦 [Module Lang Texts] Module:", module_name, "\n")
            if (!is.null(current_lang)) {
              cat("  - global_lang_content() language:", current_lang$language %||% "NULL", "\n")
              module_texts <- get_module_texts(current_lang, module_name)
              if (!is.null(module_texts)) {
                cat("  - module_texts language:", module_texts$language %||% "NULL", "\n")
              } else {
                cat("  - module_texts is NULL\n")
              }
              return(module_texts)
            } else {
              cat("  - global_lang_content() is NULL\n")
              NULL
            }
          })

          tryCatch({
            # Get module configuration
            module_config <- app_config$module_configs[[module_name]]

            # Module-specific initialization
            if (module_name == "vitalsigns_upload") {
              upload_result <- server_func(page_id,
                                         con = get_db_connection,
                                         user_info = login_result$user_info,
                                         lang_texts = module_lang_texts,
                                         module_config = module_config)

              # ✅ Store in shared_data for cross-module access
              shared_data$upload_result <- upload_result

              # Store upload data globally
              observe({
                if (!is.null(upload_result$data) && is.function(upload_result$data)) {
                  data <- upload_result$data()
                  if (!is.null(data)) {
                    upload_data(data)
                    allow_dna(FALSE)       # 新資料上傳後需再按下一步才允許 DNA
                    shared_data$dna_result <- NULL  # 清空舊 DNA 結果
                    message("✅ Upload data updated: ", nrow(data), " rows")
                  }
                }
              })

              # Navigation: Upload → DNA module
              # Monitor the proceed_step reactive from upload module
              observeEvent(upload_result$proceed_step(), {
                cat("🚀 [Navigation] Next step button clicked in Upload module\n")

                # Validate that data is uploaded
                if (is.null(upload_data()) || nrow(upload_data()) == 0) {
                  showNotification(
                    get_text("messages.error.no_data_to_proceed", "請先上傳資料"),
                    type = "warning",
                    duration = 3
                  )
                  return()
                }

                # 允許 DNA 開始處理並導向 DNA 分頁
                allow_dna(TRUE)

                # Navigate to DNA analysis page
                updateTabItems(session, "sidebar_menu", "vitalsigns_dna")

                # Show success notification
                showNotification(
                  get_text("messages.success.navigate_to_dna", "正在進入DNA分析..."),
                  type = "message",
                  duration = 2
                )

                cat("✅ [Navigation] Successfully navigated to DNA module\n")
              }, ignoreInit = TRUE)

            } else if (module_name == "vitalsigns_dna") {
              # ✅ FIX: Use global upload_data() reactive that's populated by upload module
              # This ensures data is available regardless of module initialization order
              # ✅ Pass api_config for centralized model configuration
              upload_data_for_dna <- reactive({
                if (!allow_dna()) return(NULL)
                upload_data()
              })

              dna_result <- server_func(page_id,
                                      uploaded_data = upload_data_for_dna,  # Gate by allow_dna
                                      con = get_db_connection,
                                      user_info = login_result$user_info,
                                      module_config = module_config,
                                      lang_texts = module_lang_texts,
                                      api_config = app_config$api$openai)

              # ✅ Store in shared_data for cross-module access
              shared_data$dna_result <- dna_result

              # Store DNA data globally
              # FIX: Use observeEvent with explicit trigger to avoid multiple fires
              # The DNA module reactive fires on status_text/ai_insights changes too,
              # but we only want to update dna_data when dna_results actually changes
              last_dna_nrow <- reactiveVal(0)  # Track previous row count

              observe({
                if (!is.null(dna_result) && is.function(dna_result)) {
                  result <- dna_result()
                  if (!is.null(result) && !is.null(result$dna_results)) {
                    # Only update if dna_results content actually changed
                    current_nrow <- if (!is.null(result$dna_results$data_by_customer)) {
                      nrow(result$dna_results$data_by_customer)
                    } else {
                      length(result$dna_results)
                    }

                    if (current_nrow != isolate(last_dna_nrow())) {
                      last_dna_nrow(current_nrow)
                      dna_data(result$dna_results)
                      message("✅ DNA data updated: ", length(result$dna_results), " elements")
                    }
                  }
                }
              })

            } else if (module_name %in% c("vitalsigns_acquisition", "vitalsigns_retention",
                                         "vitalsigns_engagement", "vitalsigns_revenue_pulse")) {
              # ✅ Analysis modules depend on DNA result from shared_data
              # ✅ Enable GPT and provide chat_api for AI analysis
              # ✅ Pass api_config for centralized model configuration
              server_func(page_id,
                         con = get_db_connection,
                         user_info = login_result$user_info,
                         dna_module = shared_data$dna_result,
                         module_config = module_config,
                         lang_texts = module_lang_texts,
                         enable_hints = TRUE,
                         enable_gpt = TRUE,
                         chat_api = chat_api,
                         api_config = app_config$api$openai)
            } else {
              # Default call - parameter order: id, module_config, lang_texts
              server_func(page_id, module_config = module_config, lang_texts = module_lang_texts)
            }
            cat("✅ Module server initialization successful:", module_name, "\n")
          }, error = function(e) {
            cat("❌ Module server initialization failed:", module_name, "-", e$message, "\n")
          })
        } else {
          cat("⚠️ Module function not found:", server_func_name, "\n")
        }
      })
    }
  }

  # ==========================================
  # Dynamic page title renderer (Following InsightForge Pattern)
  # ==========================================
  # Render dynamic title for each page
  for (page in app_config$pages) {
    local({
      page_id <- page$id

      output[[paste0("page_title_", page_id)]] <- renderUI({
        # Listen to language update trigger
        module_ui_update_trigger()

        # Get current language content
        current_lang_content <- global_lang_content()

        # Get page title translation
        page_title <- if (!is.null(current_lang_content) &&
                         !is.null(current_lang_content$content$common$pages) &&
                         !is.null(current_lang_content$content$common$pages[[page_id]])) {
          current_lang_content$content$common$pages[[page_id]]
        } else {
          page$title  # Fallback to original title
        }

        h3(page_title)
      })
    })
  }

  # ==========================================
  # Dynamic UI renderer - Generate UI for each module page (Following InsightForge Pattern)
  # ==========================================
  # Generate renderUI for each enabled module (without observe wrapper)
  for (page in app_config$pages) {
    if (!is.null(page$module) && page$enabled && !page$id %in% c("login")) {
      local({
        page_id <- page$id
        module_name <- page$module
        output_id <- paste0(page_id, "_", module_name, "_ui_container")

        output[[output_id]] <- renderUI({
          # Listen to language update trigger (INSIDE renderUI like InsightForge)
          module_ui_update_trigger()

          tryCatch({
            # Get lang_content inside renderUI
            lang_content <- global_lang_content()

            # Get module language text
            module_texts <- if (!is.null(lang_content)) {
              get_module_texts(lang_content, module_name)
            } else {
              NULL
            }

            # Handle naming mappings
            name_mappings <- list(
              "vitalsigns_upload" = "uploadVitalsigns",
              "vitalsigns_dna" = "dnaVitalsigns",
              "vitalsigns_acquisition" = "acquisitionVitalsigns",
              "vitalsigns_retention" = "retentionVitalsigns",
              "vitalsigns_engagement" = "engagementVitalsigns",
              "vitalsigns_revenue_pulse" = "revenuePulseVitalsigns"
            )

            base_name <- name_mappings[[module_name]]
            if (is.null(base_name)) base_name <- module_name

            ui_func_name <- paste0(base_name, "ModuleUI")

            if (exists(ui_func_name)) {
              ui_func <- get(ui_func_name)

              # 🔍 Get module config for this module
              module_config <- app_config$module_configs[[module_name]]

              # 🔍 Debug: Log config and lang_texts loading
              if (!is.null(module_config)) {
                cat("✅ [UI Render] Passing config to", ui_func_name, "\n")
              } else {
                cat("⚠️  [UI Render] No config found for module:", module_name, "\n")
              }

              if (!is.null(module_texts)) {
                cat("✅ [UI Render] lang_texts available, language:", module_texts$language %||% "NULL", "\n")
                cat("🔍 [UI Render] lang_texts structure:", paste(names(module_texts), collapse = ", "), "\n")
              } else {
                cat("❌ [UI Render] lang_texts is NULL for module:", module_name, "\n")
              }

              # Pass module_config and lang_texts to UI function
              ui_func(page_id, module_config = module_config, lang_texts = module_texts)
            } else {
              div(
                class = "alert alert-warning",
                paste("找不到模組 UI 函數:", ui_func_name)
              )
            }
          }, error = function(e) {
            div(
              class = "alert alert-danger",
              h4("模組載入失敗"),
              p(paste("模組:", module_name)),
              p(paste("錯誤:", e$message))
            )
          })
        })
      })
    }
  }

  # ==========================================
  # Session cleanup
  # ==========================================
  session$onSessionEnded(function() {
    message("Session ended")
  })
}

# ==========================================
# Execute application
# ==========================================

# 正確關閉連接池：App 停止時關閉 Pool
onStop(function() {
  if (exists("close_pool") && is.function(close_pool)) {
    close_pool()
  }
})

shinyApp(ui = ui, server = server)
