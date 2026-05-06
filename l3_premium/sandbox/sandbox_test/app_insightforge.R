# ==========================================
# 動態 YAML 驅動的 Shiny 應用程式
# ==========================================
# 根據 YAML 配置動態生成應用程式
# Version: 4.0
# Last Updated: 2025-09-27

# ==========================================
# 設定應用類型識別
# ==========================================
Sys.setenv(APP_TYPE = "insightforge")
Sys.setenv(APP_CONFIG_FILE = "config/yaml/insightforge_config/insightforge.yaml")

# ==========================================
# 載入 InsightForge 環境變數
# ==========================================
message("🔧 載入 InsightForge 環境變數...")

# Load InsightForge-specific .env file
insightforge_env_file <- "env/insightforge/.env"
if (file.exists(insightforge_env_file)) {
  # Manual loading (more reliable than dotenv for this use case)
  env_lines <- readLines(insightforge_env_file, warn = FALSE)
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
  message("✅ 已載入 InsightForge 環境變數: ", insightforge_env_file)

  # Verify key variables are loaded
  if (nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    message("   - OPENAI_API_KEY: ", substr(Sys.getenv("OPENAI_API_KEY"), 1, 20), "...")
  }
  if (nzchar(Sys.getenv("PGHOST"))) {
    message("   - PGHOST: ", Sys.getenv("PGHOST"))
  }
} else {
  message("⚠️  找不到 InsightForge .env 檔案，使用預設設定")
  message("   期望路徑: ", insightforge_env_file)
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
  library(DT)
  library(DBI)
  library(RPostgres)
  library(RSQLite)
  library(stringr)  # 需要用於 module_scoring 的 str_extract 函數
  library(pool)     # Connection pooling 支援多並發用戶 (2025-01-07)
})

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
    app_dir <- dirname(normalizePath(this_file))
    setwd(app_dir)
    message("工作目錄設為: ", app_dir)
  }
}, error = function(e) {
  message("無法自動設定工作目錄")
})

# ==========================================
# 載入配置
# ==========================================
# Note: Environment variables already loaded at the beginning of this file

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
# 載入工具模組
# ==========================================
# 載入配置管理器
if (file.exists("utils/config_manager.R")) {
  source("utils/config_manager.R")
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
  message("✅ 已載入 Supabase 登入模組 (from global_scripts)")
} else {
  stop("❌ 找不到 Supabase 登入模組")
}

# 載入 UI 生成器
if (file.exists("utils/ui_generator.R")) {
  source("utils/ui_generator.R")
}

# 載入 Server 引擎
if (file.exists("utils/server_engine.R")) {
  source("utils/server_engine.R")
}

# 載入模組管理器
if (file.exists("utils/module_manager.R")) {
  source("utils/module_manager.R")
}

# 載入 Session 管理器
if (file.exists("utils/session_manager.R")) {
  source("utils/session_manager.R")
}

# 載入 OpenAI 工具函數（提供 chat_api 函數）
if (file.exists("utils/openai_utils.R")) {
  source("utils/openai_utils.R")
  message("✅ 已載入 OpenAI 工具函數")
}

# 載入 Token 追蹤工具
if (file.exists("utils/token_tracker.R")) {
  source("utils/token_tracker.R")
  message("✅ 已載入 Token 追蹤工具")
}

# 載入提示系統（Hint System）
if (file.exists("utils/hint_system.R")) {
  source("utils/hint_system.R")
  message("✅ 已載入提示系統")
}

# 載入 Prompt 管理系統（集中管理 GPT prompts）
if (file.exists("utils/prompt_manager.R")) {
  source("utils/prompt_manager.R")
  message("✅ 已載入 Prompt 管理系統")
}

# 載入語言管理系統
if (file.exists("utils/language_manager.R")) {
  source("utils/language_manager.R")
  message("✅ 已載入語言管理系統")
}

# 載入統一內容管理系統
if (file.exists("utils/unified_content_manager.R")) {
  source("utils/unified_content_manager.R")
  message("✅ 已載入統一內容管理系統")
}

# 載入側邊欄更新器
if (file.exists("utils/sidebar_updater.R")) {
  source("utils/sidebar_updater.R")
  message("✅ 已載入側邊欄更新器")
}

# 載入統一語言同步架構
if (file.exists("utils/unified_language_sync.R")) {
  source("utils/unified_language_sync.R")
  message("✅ 已載入統一語言同步架構")
}

# 載入統一語言管理器
if (file.exists("utils/unified_language_manager.R")) {
  source("utils/unified_language_manager.R")
  message("✅ 已載入統一語言管理器")
}

# ==========================================
# 設定資源路徑
# ==========================================
# 添加資源路徑，讓 Shiny 可以找到圖片和其他靜態檔案
addResourcePath("assets", "scripts/global_scripts/24_assets")
addResourcePath("www", "www")

message("✅ 已設定資源路徑")

# ==========================================
# 載入應用程式配置
# ==========================================
# DEFENSIVE: earlier Sys.setenv() at line 12 can be clobbered by
# dotenv::load_dot_env(".env") inside sourced helpers (when the guard in
# config/config.R doesn't trip, e.g. stale shell env). Hard-pin to
# InsightForge's own config file here so tagpilot/brandedge/vitalsigns
# paths never leak in.
Sys.setenv(APP_TYPE = "insightforge")
Sys.setenv(APP_CONFIG_FILE = "config/yaml/insightforge_config/insightforge.yaml")
config_file <- Sys.getenv("APP_CONFIG_FILE")

# 載入配置
app_config <- if (exists("load_app_config")) {
  tryCatch({
    load_app_config(config_file)
  }, error = function(e) {
    message(get_text("system.config_load_failed", "配置載入失敗: {error}", error = e$message))
    # 使用最小配置
    list(
      app_info = list(
        name = get_text("system.fallback_app_name", "應用程式"),
        version = "1.0"
      ),
      modules = list(),
      pages = list()
    )
  })
} else {
  # 如果沒有 config_manager，直接讀取 YAML
  yaml::read_yaml(config_file)
}

# 將 app_config 設置為全域變數，供語言管理器使用
# NOTE 2025-01-07: 這個 assign 在 server 函數外，所以影響較小
# app_config 在每個 process 啟動時只讀取一次配置檔
# 真正有問題的是在 server 函數內修改這個全局變數（已移除 <<- 操作）
assign("app_config", app_config, envir = .GlobalEnv)

# ==========================================
# 初始化统一语言管理系统
# ==========================================
# 确定初始语言
config_language <- if (!is.null(app_config$language$default)) {
  # 將 config 中的語言目錄名稱轉換為語言代碼
  if (app_config$language$default == "chinese") "zh_TW" else "en_US"
} else {
  "zh_TW"  # 預設中文
}

# 初始化统一语言管理器
# CRITICAL: 不要在這裡創建 global_lang_content！
# initialize_unified_language_manager() 會創建正確的 reactive() 表達式
# 如果這裡先創建 reactiveVal()，會阻止正確的創建
if (exists("initialize_unified_language_manager")) {
  initialize_unified_language_manager(config_language)
} else {
  # 备用初始化方案已停用 - 會導致 global_lang_content 類型錯誤
  # 如果 initialize_unified_language_manager 不存在，應該報錯而不是使用錯誤的備用方案
  stop("initialize_unified_language_manager() function not found. Please check utils/unified_language_manager.R is loaded.")

  # REMOVED: This code was preventing correct initialization
  # global_lang_content <- reactiveVal(NULL)
  # assign("global_lang_content", global_lang_content, envir = .GlobalEnv)
  #
  # if (exists("load_language_content")) {
  #   initial_lang <- load_language_content(language = config_language)
  # }
}

# DEBUG: Check what type global_lang_content is after initialization
if (exists("global_lang_content")) {
  glc_test <- get("global_lang_content", envir = .GlobalEnv)
  cat("🔍 [INIT DEBUG] global_lang_content type check:\n")
  cat("  - is.function:", is.function(glc_test), "\n")
  cat("  - class:", paste(class(glc_test), collapse = ", "), "\n")
  cat("  - formals:", if(is.function(glc_test)) paste(names(formals(glc_test)), collapse = ", ") else "N/A", "\n")
  rm(glc_test)
}

default_language <- config_language

cat("🌍 === 語言初始化調試資訊 ===\n")
cat("🌍 app_config$language$default:", app_config$language$default, "\n")
cat("🌍 最終使用語言:", default_language, "\n")
cat("🌍 ================================\n")

message(paste("✅ 已載入初始語言內容:", default_language))

# 保持向後兼容
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
# 安全獲取語言文字的函數，提供備用文字
get_text <- function(path, fallback = "", ...) {
  # 使用動態語言內容，如果可用的話
  current_lang_content <- if (exists("global_lang_content") && is.function(global_lang_content)) {
    tryCatch(isolate(global_lang_content()), error = function(e) lang_content)
  } else {
    lang_content
  }

  # 從語言內容中尋找文字
  result <- NULL
  if (!is.null(current_lang_content)) {
    # 拆解路徑 (例如 "system.loading.env_file" 或簡單的 "app_title")
    keys <- strsplit(path, "\\.")[[1]]

    # 處理簡單的 key (例如 "app_title", "login_title")
    if (length(keys) == 1 && grepl("_", keys[1])) {
      parts <- strsplit(keys[1], "_")[[1]]
      if (length(parts) >= 2) {
        # 嘗試在 common 中查找 (例如 common.app.title)
        if (!is.null(current_lang_content$content$common)) {
          # 處理 app_* 格式
          if (parts[1] == "app" && !is.null(current_lang_content$content$common$app)) {
            result <- current_lang_content$content$common$app[[paste(parts[-1], collapse = "_")]]
          }
          # 處理 login_* 格式
          else if (parts[1] == "login" && !is.null(current_lang_content$content$common$login)) {
            result <- current_lang_content$content$common$login[[paste(parts[-1], collapse = "_")]]
          }
          # 處理 *_button 或 *_btn 格式
          else if (length(parts) >= 2 && parts[length(parts)] %in% c("button", "btn") && !is.null(current_lang_content$content$common$buttons)) {
            button_key <- paste(parts[-length(parts)], collapse = "_")
            result <- current_lang_content$content$common$buttons[[button_key]]
          }
          # 處理其他 common 下的部分 (navigation_*, status_*, etc.)
          else if (!is.null(current_lang_content$content$common[[parts[1]]])) {
            if (length(parts) == 2) {
              result <- current_lang_content$content$common[[parts[1]]][[parts[2]]]
            } else {
              result <- current_lang_content$content$common[[parts[1]]][[paste(parts[-1], collapse = "_")]]
            }
          }
        }

        # 如果沒找到，嘗試在模組中查找
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

    # 如果簡單 key 沒找到，嘗試標準路徑查找
    if (is.null(result)) {
      # 1. 從 content.common 開始尋找 (最常見的情況)
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

    # 2. 如果沒找到，從 content 直接尋找
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

    # 3. 如果還是沒找到，直接從語言內容尋找 (向後兼容)
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

  # 如果沒找到結果，使用 fallback
  if (is.null(result)) {
    result <- fallback
  }

  # 支持字串模板替換（不論是找到的內容還是 fallback）
  if (length(list(...)) > 0 && is.character(result)) {
    args <- list(...)
    for (name in names(args)) {
      result <- gsub(paste0("\\{", name, "\\}"), args[[name]], result)
    }
  }

  return(if (is.character(result)) result else fallback)
}

# ==========================================
# 模組語言文字獲取函數
# ==========================================
get_module_text <- function(module_id, path, fallback = "", ...) {
  # 獲取當前語言內容
  current_lang_content <- if (exists("global_lang_content") && is.function(global_lang_content)) {
    tryCatch(isolate(global_lang_content()), error = function(e) NULL)
  } else {
    NULL
  }

  if (is.null(current_lang_content) || is.null(current_lang_content$content$modules)) {
    return(fallback)
  }

  # 從模組內容中獲取文字
  module_content <- current_lang_content$content$modules[[module_id]]
  if (is.null(module_content)) {
    return(fallback)
  }

  # 拆解路徑 (例如 "ui.buttons.run_analysis")
  keys <- strsplit(path, "\\.")[[1]]
  result <- module_content

  for (key in keys) {
    if (is.list(result) && key %in% names(result)) {
      result <- result[[key]]
    } else {
      return(fallback)
    }
  }

  # 支持字串模板替換
  if (length(list(...)) > 0 && is.character(result)) {
    args <- list(...)
    for (name in names(args)) {
      result <- gsub(paste0("\\{", name, "\\}"), args[[name]], result)
    }
  }

  return(if (is.character(result)) result else fallback)
}

# ==========================================
# NULL 合併運算子
# ==========================================
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

# ==========================================
# 模組語言文字輔助函數
# ==========================================
get_module_texts <- function(lang_content, module_name) {
  # 使用統一內容管理系統的函數
  # lang_content 參數實際上是完整的語言內容，需要提取語言碼
  language_code <- if (!is.null(lang_content$language)) {
    lang_content$language
  } else {
    "zh_TW"  # 預設中文
  }

  # 呼叫統一內容管理系統的函數
  module_texts <- get_module_language_content(module_name, language_code)

  # 如果成功取得內容，加入 language 欄位
  if (!is.null(module_texts)) {
    module_texts$language <- language_code
  }

  return(module_texts)
}

# ==========================================
# 顯示配置資訊
# ==========================================
message("========================================")
message(get_text("system.app_status.title", "應用程式: {name}", name = app_config$app_info$name %||% get_text("system.unnamed", "未命名")))
message(get_text("system.app_status.version", "版本: {version}", version = app_config$app_info$version %||% "1.0"))
message(get_text("system.app_status.environment", "環境: {environment}", environment = app_config$environment$mode %||% "development"))
message("========================================")

# ==========================================
# 定義 UI
# ==========================================
ui <- function() {
  # 檢查是否有動態 UI 生成器
  if (exists("generate_app_ui")) {
    # 添加全局語言變更處理的 JavaScript
    ui_content <- generate_app_ui(app_config)
    tagList(
      ui_content,
      # 註冊側邊欄更新器 JavaScript
      if (exists("register_sidebar_updater_js")) {
        register_sidebar_updater_js()
      } else {
        NULL
      },
      tags$script(HTML("
        // 處理全局語言變更消息
        Shiny.addCustomMessageHandler('global_language_change', function(data) {
          console.log('收到全局語言變更:', data.language);
          // 觸發Shiny的input事件
          Shiny.setInputValue('global_language_change', data, {priority: 'event'});
        });

        // **關鍵修復**: 強制模組語言同步處理器
        Shiny.addCustomMessageHandler('force_module_language_sync', function(data) {
          console.log('🔄 強制模組語言同步:', data.language);

          // 立即更新頁面上所有可見的文字元素
          setTimeout(function() {
            // 觸發頁面重新渲染
            Shiny.setInputValue('force_language_reload', {
              language: data.language,
              timestamp: data.timestamp,
              force: true
            }, {priority: 'event'});

            // 強制刷新所有動態內容
            if (window.Shiny && window.Shiny.unbindAll && window.Shiny.bindAll) {
              try {
                window.Shiny.unbindAll();
                window.Shiny.bindAll();
                console.log('✅ Shiny 元素重新綁定完成');
              } catch(e) {
                console.log('⚠️ Shiny 重新綁定警告:', e);
              }
            }
          }, 50);
        });

        // 監聽模組語言更新消息
        Shiny.addCustomMessageHandler('module_language_update', function(data) {
          console.log('模組語言更新:', data.language);
          // 儲存語言偏好但不刷新頁面
          if (data.language) {
            sessionStorage.setItem('selected_language', data.language);
          }
        });

        // 處理強制 UI 刷新消息
        Shiny.addCustomMessageHandler('force_ui_refresh', function(data) {
          console.log('強制 UI 刷新:', data.language);
          // 觸發 Shiny 重新渲染相關 UI 元素
          setTimeout(function() {
            Shiny.setInputValue('force_ui_refresh_trigger', {
              language: data.language,
              timestamp: data.timestamp
            }, {priority: 'event'});
          }, 100);
        });

        // 處理語言按鈕樣式更新
        Shiny.addCustomMessageHandler('updateLanguageButtonClass', function(data) {
          console.log('更新語言按鈕樣式:', data);
          if (data.activeBtn) {
            $('#' + data.activeBtn).addClass('active').removeClass('btn-outline-primary').addClass('btn-primary');
          }
          if (data.inactiveBtn) {
            $('#' + data.inactiveBtn).removeClass('active').removeClass('btn-primary').addClass('btn-outline-primary');
          }
        });

        // 🌐 處理側邊欄文字更新
        Shiny.addCustomMessageHandler('updateSidebarText', function(data) {
          console.log('🌐 更新側邊欄文字:', data.id, '->', data.text);
          var element = document.getElementById(data.id);
          if (element) {
            element.textContent = data.text;
            console.log('✅ 側邊欄文字更新成功');
          } else {
            console.log('⚠️ 找不到側邊欄元素:', data.id);
          }
        });

        // 🔥 頁面載入時檢查 sessionStorage 中的語言設定
        $(document).ready(function() {
          var savedLanguage = sessionStorage.getItem('selected_language');
          if (savedLanguage) {
            console.log('從 sessionStorage 載入語言設定:', savedLanguage);
            // 通知 Shiny 應用語言設定
            Shiny.setInputValue('initial_language', savedLanguage, {priority: 'event'});
          }
        });
      "))
    )
  } else {
    # 備用簡單 UI
    fluidPage(
      titlePanel(app_config$app_info$name %||% get_text("system.fallback_app_name", "應用程式")),

      # 如果有頁面定義，顯示簡單選單
      if (length(app_config$pages) > 0) {
        sidebarLayout(
          sidebarPanel(
            h4(get_text("system.ui.function_menu", "功能選單")),
            lapply(app_config$pages, function(page) {
              if (!is.null(page$hide_in_menu) && page$hide_in_menu) return(NULL)
              if (!is.null(page$enabled) && !page$enabled) return(NULL)
              actionLink(
                inputId = paste0("goto_", page$id),
                label = page$title,
                icon = if (!is.null(page$icon)) icon(page$icon) else NULL
              )
            })
          ),
          mainPanel(
            h3(get_text("system.ui.content_area", "內容區域")),
            uiOutput("main_content")
          )
        )
      } else {
        # 沒有頁面定義時的預設內容
        mainPanel(
          h3(get_text("system.ui.system_initializing", "系統初始化中")),
          p(get_text("system.ui.check_config_file", "請檢查配置檔案"))
        )
      }
    )
  }
}

# ==========================================
# 定義 Server
# ==========================================
server <- function(input, output, session) {

  # ==========================================
  # 🔥 創建 global_lang_content reactive 表達式
  # ==========================================
  # CRITICAL: 必須在 server 函數內創建，才能正確響應 global_language_state 的變化
  # 先刪除任何舊的 reactive，確保我們創建新的
  if (exists("global_lang_content", envir = .GlobalEnv)) {
    cat("⚠️ [SERVER] 偵測到舊的 global_lang_content，正在刪除...\n")
    rm(global_lang_content, envir = .GlobalEnv)
  }

  # 創建新的 reactive 表達式
  global_lang_content <- reactive({
    content <- global_language_state$language_content
    cat("📖 [SERVER] global_lang_content reactive 被讀取，返回語言:", content$language %||% "NULL", "\n")
    return(content)
  })
  # 2025-01-07: 移除全局狀態污染，避免跨 session 干擾
  # assign("global_lang_content", global_lang_content, envir = .GlobalEnv)
  cat("✅ [SERVER] 已在 server 函數內創建 global_lang_content reactive 表達式 (session-local)\n")

  # ==========================================
  # 🔥 創建 reactive prompts_df 和 hints_df
  # ==========================================
  # 這些會隨著語言變更自動更新
  prompts_df <- reactive({
    current_lang <- global_lang_content()
    language_code <- current_lang$language %||% "zh_TW"
    cat("📝 [SERVER] prompts_df reactive 被讀取，語言:", language_code, "\n")

    if (exists("load_prompts") && is.function(load_prompts)) {
      prompts <- load_prompts(language = language_code)
      cat("  ✅ 載入", nrow(prompts), "個 prompts (", language_code, ")\n")
      return(prompts)
    } else {
      cat("  ⚠️ load_prompts 函數不存在\n")
      return(NULL)
    }
  })
  # 2025-01-07: 移除全局狀態污染，避免跨 session 干擾
  # assign("prompts_df", prompts_df, envir = .GlobalEnv)

  hints_df <- reactive({
    current_lang <- global_lang_content()
    language_code <- current_lang$language %||% "zh_TW"
    cat("💡 [SERVER] hints_df reactive 被讀取，語言:", language_code, "\n")

    if (exists("load_hints") && is.function(load_hints)) {
      hints <- load_hints(language = language_code)
      cat("  ✅ 載入", nrow(hints), "個 hints (", language_code, ")\n")
      return(hints)
    } else {
      cat("  ⚠️ load_hints 函數不存在\n")
      return(NULL)
    }
  })
  # 2025-01-07: 移除全局狀態污染，避免跨 session 干擾
  # assign("hints_df", hints_df, envir = .GlobalEnv)

  # 設定 prompts_enabled 標誌
  prompts_enabled <- TRUE
  # 2025-01-07: 移除全局狀態污染，避免跨 session 干擾
  # assign("prompts_enabled", prompts_enabled, envir = .GlobalEnv)

  cat("✅ [SERVER] 已創建 reactive prompts_df 和 hints_df\n")

  # ==========================================
  # 🔥 處理初始語言設定（從 sessionStorage 讀取）
  # ==========================================
  observeEvent(input$initial_language_from_storage, {
    saved_language <- input$initial_language_from_storage
    if (!is.null(saved_language) && exists("load_language_content")) {
      cat("\n📱 === 初始語言設定處理 ===", "\n")
      cat("📱 從 sessionStorage 讀取語言:", saved_language, "\n")
      cat("📱 當前 global_lang_content 語言:", isolate(global_lang_content())$language, "\n")

      # 載入對應的語言內容
      tryCatch({
        # 2025-01-07: 移除全局狀態修改，避免跨 session 污染
        # 語言狀態已經由 global_lang_content reactive 追蹤，不需要修改 app_config
        # if (!is.null(app_config$language)) {
        #   app_config$language$default <<- saved_language
        # }

        # 重新載入語言內容
        new_lang_content <- load_language_content(app_config, language = saved_language)
        # global_lang_content 會由 load_language_content 自動同步，不需要手動設置
        # global_lang_content(new_lang_content)

        cat("✅ 已應用初始語言設定:", saved_language, "\n")
        cat("✅ 新的 global_lang_content 語言:", global_lang_content()$language, "\n")
        cat("📱 === 初始語言設定完成 ===", "\n\n")

        # 重新載入所有模組的語言內容並更新 UI
        if (saved_language == "en_US") {
          # 載入英文版本的所有模組內容
          cat("🔄 切換到英文介面\n")
        } else {
          # 載入中文版本的所有模組內容
          cat("🔄 切換到中文介面\n")
        }
      }, error = function(e) {
        cat("⚠️ 載入初始語言設定失敗:", e$message, "\n")
        cat("📱 === 初始語言設定失敗 ===", "\n\n")
      })
    } else {
      cat("📱 跳過初始語言設定（語言為 NULL 或無 load_language_content）\n")
    }
  }, once = TRUE, ignoreInit = FALSE)

  # ==========================================
  # 🎯 統一的語言變更處理器
  # ==========================================
  # 所有語言變更都通過這個統一的處理器
  observeEvent(input$global_language_change, {
    language_data <- input$global_language_change
    if (!is.null(language_data) && !is.null(language_data$language)) {
      # 增強調試輸出
      cat("\n🌍 ===============================\n")
      cat("🌍 統一語言變更處理器觸發\n")
      cat("🌍 請求語言:", language_data$language, "\n")
      cat("🌍 來源:", language_data$source %||% "未知", "\n")
      cat("🌍 時間戳:", format(as.POSIXct(language_data$timestamp/1000, origin="1970-01-01"), "%H:%M:%S"), "\n")
      cat("🌍 當前 global_lang_content 語言:", if(!is.null(global_lang_content())) global_lang_content()$language else "NULL", "\n")
      cat("🌍 是否來自Header:", language_data$fromHeader %||% FALSE, "\n")

      # 避免重複處理相同語言
      current_lang <- if (!is.null(global_lang_content())) global_lang_content()$language else NULL
      if (!is.null(current_lang) && current_lang == language_data$language) {
        cat("⚡ 語言相同（", current_lang, "），跳過處理但更新UI狀態\n")
        cat("🌍 ===============================\n\n")
        # 僅更新UI按鈕狀態
        shinyjs::runjs(sprintf("updateAllLanguageButtons('%s');", language_data$language))
        return()
      }

      # 載入新的語言內容
      tryCatch({
        # 2025-01-07: 移除全局狀態修改，避免跨 session 污染
        # 語言狀態已經由 global_lang_content reactive 追蹤，不需要修改 app_config
        # if (!is.null(app_config$language)) {
        #   cat("🔧 更新 app_config 語言設定:", language_data$language, "\n")
        #   app_config$language$default <<- language_data$language
        # }
        cat("🔧 語言設定已由 global_lang_content 追蹤:", language_data$language, "\n")

        # 重新載入語言內容
        cat("📥 正在載入語言內容:", language_data$language, "\n")
        new_lang_content <- load_language_content(app_config, language = language_data$language)

        # 詳細檢查載入的內容
        cat("🔍 [SWITCH DEBUG] 載入的內容檢查:\n")
        cat("    - 類型:", class(new_lang_content), "\n")
        cat("    - 欄位:", paste(names(new_lang_content), collapse=", "), "\n")
        cat("    - language 存在:", "language" %in% names(new_lang_content), "\n")
        if ("language" %in% names(new_lang_content)) {
          cat("    - language 值:", new_lang_content$language %||% "NULL", "\n")
          cat("    - language 類型:", class(new_lang_content$language), "\n")
        }

        # 設置到全域變數前再次檢查
        cat("🔍 [SWITCH DEBUG] 設置前檢查:\n")
        cat("    - 即將設置的 language:", new_lang_content$language, "\n")

        # global_lang_content 會由 load_language_content 自動同步，不需要手動設置
        # global_lang_content(new_lang_content)

        # 設置後立即檢查
        verification <- global_lang_content()
        cat("🔍 [SWITCH DEBUG] 設置後驗證:\n")
        cat("    - 取回的類型:", class(verification), "\n")
        cat("    - 取回的欄位:", paste(names(verification), collapse=", "), "\n")
        if ("language" %in% names(verification)) {
          cat("    - 取回的 language:", verification$language %||% "NULL", "\n")
        }

        cat("✅ 語言內容載入完成:", new_lang_content$language, "\n")
        cat("📊 模組數量:", length(new_lang_content$content$modules %||% list()), "\n")

        # 決定顯示的語言名稱（雙語顯示）
        actual_language <- new_lang_content$language

        # Get language display name from config
        lang_config <- if (exists("load_language_config") && is.function(load_language_config)) {
          load_language_config()
        } else {
          NULL
        }

        display_name <- "Unknown"
        if (!is.null(lang_config)) {
          for (lang in lang_config$supported_languages) {
            if (lang$code == actual_language) {
              display_name <- lang$display_name
              break
            }
          }
        }

        # Get notification message from YAML
        notification_template <- safe_get_text(new_lang_content$content$general$common, "language.switched_to", "Language switched to {language}")
        notification_msg <- gsub("\\{language\\}", display_name, notification_template)

        cat("🔔 語言顯示名稱:", display_name, "\n")

        # 更新側邊欄選單文字
        if (exists("update_sidebar_menu_text")) {
          cat("🔄 準備更新側邊欄選單文字\n")
          cat("🔍 [SIDEBAR DEBUG] 傳入參數檢查:\n")
          cat("    - new_lang_content 類型:", class(new_lang_content), "\n")
          cat("    - new_lang_content 欄位:", paste(names(new_lang_content), collapse=", "), "\n")
          if ("language" %in% names(new_lang_content)) {
            cat("    - language 值:", new_lang_content$language %||% "NULL", "\n")
          }
          cat("    - app_config$pages 存在:", !is.null(app_config$pages), "\n")
          update_sidebar_menu_text(session, app_config$pages, new_lang_content)
        }

        # 顯示通知
        showNotification(
          notification_msg,
          type = "message",
          duration = 2
        )

        # 儲存到 sessionStorage
        js_code <- sprintf("
          sessionStorage.setItem('selected_language', '%s');
          console.log('🗂️ Language preference saved: %s');
          updateAllLanguageButtons('%s');
        ", language_data$language, language_data$language, language_data$language)
        shinyjs::runjs(js_code)

        # 通知所有模組更新語言
        cat("📢 發送模組語言更新消息\n")
        session$sendCustomMessage("module_language_update", list(
          language = language_data$language,
          content = new_lang_content,
          timestamp = as.numeric(Sys.time())
        ))

        # 延遲觸發 UI 元素重新渲染，確保語言內容已載入
        shinyjs::delay(100, {
          session$sendCustomMessage("force_ui_refresh", list(
            language = language_data$language,
            timestamp = as.numeric(Sys.time())
          ))
        })

        # 🔄 重要: 觸發模組 UI 更新
        # 這是修復語言切換後頁面內容不更新的關鍵
        module_ui_update_trigger(module_ui_update_trigger() + 1)

        cat("🌍 統一語言切換處理完成\n")
        cat("🌍 最終語言:", global_lang_content()$language, "\n")
        cat("🌍 ===============================\n\n")

      }, error = function(e) {
        cat("❌ 語言切換失敗:", e$message, "\n")
        cat("🔍 錯誤詳細信息:", toString(e), "\n")
        cat("🌍 ===============================\n\n")
        showNotification(
          "語言切換失敗 / Language switch failed",
          type = "error",
          duration = 3
        )
      })
    } else {
      cat("⚠️ 無效的語言變更數據:", toString(language_data), "\n")
      cat("🌍 ===============================\n\n")
    }
  }, ignoreInit = TRUE)

  # ==========================================
  # 處理強制 UI 刷新請求
  # ==========================================
  observeEvent(input$force_ui_refresh_trigger, {
    refresh_data <- input$force_ui_refresh_trigger
    if (!is.null(refresh_data) && !is.null(refresh_data$language)) {
      cat("🔄 強制 UI 刷新觸發，語言:", refresh_data$language, "\n")

      # 更新全局語言內容到新語言
      current_content <- global_lang_content()
      if (!is.null(current_content) && current_content$language != refresh_data$language) {
        cat("🔄 UI 語言狀態不同步，重新載入語言內容\n")

        # 重新載入語言內容以確保同步
        tryCatch({
          # 使用全域 app_config
          lang_config <- app_config

          new_lang_content <- load_language_content(lang_config, refresh_data$language)
          # global_lang_content 會由 load_language_content 自動同步，不需要手動設置
          # global_lang_content(new_lang_content)

          cat("✅ UI 語言內容已更新至:", refresh_data$language, "\n")
        }, error = function(e) {
          cat("⚠️ UI 語言內容更新失敗:", e$message, "\n")
        })
      }
    }
  }, ignoreInit = TRUE)

  # ==========================================
  # 同步 Navbar 語言選擇器與全局語言狀態
  # ==========================================
  observe({
    current_lang <- global_lang_content()
    if (!is.null(current_lang) && !is.null(current_lang$language)) {
      # 只在語言實際改變時更新選擇器，避免循環觸發
      if (!is.null(input$navbar_language_selector) &&
          input$navbar_language_selector != current_lang$language) {
        updateSelectInput(session, "navbar_language_selector", selected = current_lang$language)
        cat("🔄 Navbar 選擇器自動同步至:", current_lang$language, "\n")
      }
    }
  })

  # ==========================================
  # 處理 Navbar 語言選擇器變更
  # ==========================================
  observeEvent(input$navbar_language_selector, {
    selected_lang <- input$navbar_language_selector
    if (!is.null(selected_lang)) {
      cat("\n🌍 Navbar語言選擇器變更\n")
      cat("  選擇語言:", selected_lang, "\n")

      # 使用統一的語言切換函數
      tryCatch({
        result <- unified_language_switch(
          session = session,
          new_language = selected_lang,
          app_config = app_config,
          lang_config = if (exists("load_language_config")) load_language_config() else NULL,
          module_ui_update_trigger = module_ui_update_trigger
        )

        if (result$success) {
          cat("✅ Navbar語言切換成功\n")
          # 觸發模組 UI 更新
          module_ui_update_trigger(module_ui_update_trigger() + 1)
        } else {
          cat("⚠️ Navbar語言切換未完成\n")
        }
      }, error = function(e) {
        cat("❌ Navbar語言切換失敗:", e$message, "\n")
        showNotification(
          "語言切換失敗 / Language switch failed",
          type = "error",
          duration = 3
        )
      })
    }
  }, ignoreInit = TRUE)

  # ==========================================
  # 處理 Header 語言切換事件 - 使用統一處理函數
  # ==========================================
  observeEvent(input$header_language_change, {
    language_data <- input$header_language_change
    if (!is.null(language_data) && !is.null(language_data$language)) {
      cat("\n🌍 Header語言切換事件觸發\n")
      cat("  請求語言:", language_data$language, "\n")
      cat("  來源:", language_data$source %||% "header", "\n")

      # 使用統一的語言切換函數
      tryCatch({
        result <- unified_language_switch(
          session = session,
          new_language = language_data$language,
          app_config = app_config,
          lang_config = if (exists("load_language_config")) load_language_config() else NULL,
          module_ui_update_trigger = module_ui_update_trigger
        )

        if (result$success) {
          cat("✅ Header語言切換成功\n")
          # 觸發模組 UI 更新
          module_ui_update_trigger(module_ui_update_trigger() + 1)
        } else {
          cat("⚠️ Header語言切換未完成\n")
        }
      }, error = function(e) {
        cat("❌ Header語言切換失敗:", e$message, "\n")
        showNotification(
          "語言切換失敗 / Language switch failed",
          type = "error",
          duration = 3
        )
      })
    }
  }, ignoreInit = TRUE)

  # ==========================================
  # 處理 Home 頁面語言切換事件 - 使用統一處理函數
  # ==========================================
  observeEvent(input$home_language_change, {
    language_data <- input$home_language_change
    if (!is.null(language_data) && !is.null(language_data$language)) {
      cat("\n🏠 Home頁面語言切換事件觸發\n")
      cat("  請求語言:", language_data$language, "\n")
      cat("  來源:", language_data$source %||% "home", "\n")

      # 使用統一的語言切換函數
      tryCatch({
        result <- unified_language_switch(
          session = session,
          new_language = language_data$language,
          app_config = app_config,
          lang_config = if (exists("load_language_config")) load_language_config() else NULL,
          module_ui_update_trigger = module_ui_update_trigger
        )

        if (result$success) {
          cat("✅ Home頁面語言切換成功\n")
          # 觸發模組 UI 更新
          module_ui_update_trigger(module_ui_update_trigger() + 1)
        } else {
          cat("⚠️ Home頁面語言切換未完成\n")
        }
      }, error = function(e) {
        cat("❌ Home頁面語言切換失敗:", e$message, "\n")
        showNotification(
          "語言切換失敗 / Language switch failed",
          type = "error",
          duration = 3
        )
      })
    }
  }, ignoreInit = TRUE)

  # ==========================================
  # 🔄 備用語言切換事件處理器 - 使用統一處理函數
  # ==========================================
  observeEvent(input$language_change_backup, {
    language_data <- input$language_change_backup
    cat("\n🔄 ===============================\n")
    cat("🔄 [BACKUP] 備用語言切換事件觸發\n")
    cat("🔄 語言:", language_data$language %||% "NULL", "\n")
    cat("🔄 來源:", language_data$source %||% "NULL", "\n")

    if (!is.null(language_data) && !is.null(language_data$language)) {
      # 使用統一的語言切換函數
      tryCatch({
        cat("🔄 執行備用語言切換...\n")

        result <- unified_language_switch(
          session = session,
          new_language = language_data$language,
          app_config = app_config,
          lang_config = if (exists("load_language_config")) load_language_config() else NULL,
          module_ui_update_trigger = module_ui_update_trigger
        )

        if (result$success) {
          cat("✅ 備用語言切換成功\n")
          # 觸發模組 UI 更新
          module_ui_update_trigger(module_ui_update_trigger() + 1)

          # 顯示成功通知
          lang_config <- if (exists("load_language_config")) load_language_config() else NULL
          language_display_name <- "Unknown"
          if (!is.null(lang_config)) {
            for (lang in lang_config$supported_languages) {
              if (lang$code == language_data$language) {
                language_display_name <- lang$display_name
                break
              }
            }
          }

          # Get notification message from current language YAML
          current_lang_content <- global_lang_content()
          notification_template <- safe_get_text(current_lang_content$content$general$common, "language.switched_to", "Language switched to {language}")
          notification_msg <- gsub("\\{language\\}", language_display_name, notification_template)

          showNotification(
            notification_msg,
            type = "message",
            duration = 2
          )
        }
      }, error = function(e) {
        cat("❌ 備用語言切換失敗:", e$message, "\n")
        showNotification(
          "備用語言切換失敗，請重試",
          type = "error",
          duration = 3
        )
      })
    } else {
      cat("⚠️ 備用事件：無效的語言數據\n")
    }

    cat("🔄 ===============================\n")
  }, ignoreInit = TRUE)

  # ==========================================
  # 動態更新側邊欄選單文字
  # ==========================================
  observe({
    # 監聽語言變更
    current_lang <- global_lang_content()

    if (!is.null(current_lang) && !is.null(app_config$pages)) {
      # 對每個頁面更新側邊欄文字
      for (page in app_config$pages) {
        if (!is.null(page$id)) {
          # 獲取翻譯後的頁面標題
          translated_title <- if (!is.null(current_lang$content$common$pages[[page$id]])) {
            current_lang$content$common$pages[[page$id]]
          } else {
            page$title  # 使用原始標題作為備用
          }

          # 使用 JavaScript 更新側邊欄文字
          session$sendCustomMessage("updateSidebarText", list(
            id = paste0("sidebar_text_", page$id),
            text = translated_title
          ))
        }
      }

      cat("✅ 側邊欄選單文字已更新為", current_lang$language, "\n")
    }
  })

  # ==========================================
  # 輸出當前語言調試資訊
  # ==========================================
  output$current_language_debug <- renderText({
    current_lang <- global_lang_content()
    if (!is.null(current_lang)) {
      paste(
        "當前語言 / Current Language:", current_lang$language, "\n",
        "語言內容模組數 / Module Count:", length(current_lang$content$modules %||% list()), "\n",
        "最後更新 / Last Updated:", Sys.time()
      )
    } else {
      "語言內容未載入 / Language content not loaded"
    }
  })

  # ==========================================
  # 語言狀態監控器（定期檢查並報告語言狀態）
  # ==========================================
  language_monitor <- reactiveTimer(5000)  # 每5秒檢查一次

  observe({
    language_monitor()
    isolate({
      current_state <- global_lang_content()
      if (!is.null(current_state)) {
        cat(sprintf("[%s] 📊 語言狀態監控: 當前語言=%s, 模組數=%d\n",
                   format(Sys.time(), "%H:%M:%S"),
                   current_state$language,
                   length(current_state$content$modules %||% list())))
      }
    })
  })

  # ==========================================
  # 建立資料庫連接
  # ==========================================
  con_global <- NULL
  db_info <- list(type = "None", status = get_text("system.database.status_disconnected", "未連接"), color = "red", icon = get_text("system.database.icon_disconnected", "❌"))

  # 載入資料庫連接模組
  if (file.exists("database/db_connection.R")) {
    source("database/db_connection.R")

    # 嘗試建立連接
    tryCatch({
      con_global <- get_con()
      if (!is.null(con_global) && exists("get_db_info")) {
        db_info <- get_db_info(con_global)
        message(get_text("system.database.connect_success", "✅ 資料庫連接成功: {type}", type = db_info$type))
      }
    }, error = function(e) {
      message(get_text("system.database.connect_failed", "⚠️ 資料庫連接失敗: {error}", error = e$message))
    })
  }

  # Session 結束時斷開連接
  # 注意：使用 Pool 時不應在 session 結束時關閉，Pool 會自動管理
  # 只有在整個 app 停止時才呼叫 close_pool()
  # session$onSessionEnded(function() {
  #   # 不要在這裡關閉 pool，會影響其他 session
  # })

  # ==========================================
  # 載入所有必要的模組
  # ==========================================
  # 載入登入模組
  # 注意：無論使用 Supabase 或傳統認證，都需要載入傳統模組以獲取 loginModuleUI
  login_module_path <- app_config$modules$login$path
  if (is.null(login_module_path)) {
    login_module_path <- "modules/module_login.R"
    if (!file.exists(login_module_path)) {
      login_module_path <- "modules/module_login_local.R"
    }
    if (!file.exists(login_module_path)) {
      login_module_path <- "scripts/global_scripts/10_rshinyapp_components/login/login_module.R"
    }
  }
  if (file.exists(login_module_path)) {
    source(login_module_path)
    message(get_text("system.loading.login_module", "✅ 已載入傳統登入模組（UI 函數）: {path}", path = login_module_path))
  }

  # 檢查 Supabase 登入函數是否已載入（from global_scripts）
  # 修正：改為檢查函數存在而非舊路徑，因為模組已從 global_scripts 載入
  if (exists("authenticate_user") && exists("loginSupabaseServer") && exists("loginSupabaseUI")) {
    USE_SUPABASE_AUTH <<- TRUE
    message("✅ Supabase 登入模組已啟用（from global_scripts）")
  } else {
    USE_SUPABASE_AUTH <<- FALSE
    message("ℹ️ 將使用傳統登入模組（Supabase 函數未載入）")
  }

  # 載入其他已啟用的模組
  for (module_name in names(app_config$modules)) {
    module_config <- app_config$modules[[module_name]]
    if (!is.null(module_config$enabled) && module_config$enabled && module_name != "login") {
      if (!is.null(module_config$path) && file.exists(module_config$path)) {
        tryCatch({
          source(module_config$path)
          message(get_text("system.loading.module_success", "✅ 已載入模組: {name}", name = module_name))
        }, error = function(e) {
          message(get_text("system.loading.module_failed", "⚠️ 無法載入模組 {name}: {error}", name = module_name, error = e$message))
        })
      }
    }
  }

  # ==========================================
  # 初始化 Reactive Values 和登入狀態
  # ==========================================
  user_info <- reactiveVal(NULL)

  # 模組 UI 更新觸發器 - 用於語言切換時強制重新渲染
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

  # 設定登入狀態輸出（必須在這裡設定，供 conditionalPanel 使用）
  output$user_logged_in <- reactive({
    !is.null(user_info())
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)

  # ==========================================
  # 初始化 Server Engine
  # ==========================================
  if (exists("ServerEngine")) {
    # 使用 ServerEngine R6 類別
    engine <- ServerEngine$new(app_config, session)
    shared_state <- engine$setup_login_management()

    # 初始化登入模組
    # 優先使用 Supabase 登入模組
    if (exists("USE_SUPABASE_AUTH") && USE_SUPABASE_AUTH && exists("loginSupabaseServer")) {
      message("🔐 使用 Supabase 登入模組")
      login_instance <- loginSupabaseServer("login1", app_name = "insightforge")
    } else if (exists("loginModuleServer")) {
      message("🔐 使用傳統 bcrypt 登入模組")
      # 使用反應式語言內容
      login_texts_reactive <- reactive({
        content <- global_lang_content()
        if (!is.null(content)) {
          get_module_texts(content, "login")
        } else if (!is.null(lang_content)) {
          get_module_texts(lang_content, "login")
        } else {
          NULL
        }
      })

      # 傳遞初始語言內容
      login_texts <- if (!is.null(lang_content)) {
        get_module_texts(lang_content, "login")
      } else {
        NULL
      }
      login_instance <- loginModuleServer("login1", login_texts)
    }

      # 監聽登入狀態
      observe({
        login_user <- login_instance$user_info()
        if (!is.null(login_user)) {
          user_info(login_user)  # 更新 reactive value
          engine$update_login_status(login_user)

          # 檢查是否需要應用語言設定
          isolate({
            selected_lang <- login_instance$selected_language()

            cat("\n🔔 === 登入語言調試資訊 ===\n")
            cat("🔔 登入模組返回語言:", selected_lang, "\n")
            cat("🔔 input$language_selector 值:", input$language_selector, "\n")
            cat("🔔 登入前 global_lang_content 語言:", isolate(global_lang_content())$language, "\n")

            if (!is.null(selected_lang)) {
              cat("🔔 準備應用語言設定:", selected_lang, "\n")

              # 直接觸發語言變更處理，而不是通過 JavaScript
              # 載入新的語言內容
              tryCatch({
                # 2025-01-07: 移除全局狀態修改，避免跨 session 污染
                # 語言狀態已經由 global_lang_content reactive 追蹤，不需要修改 app_config
                # if (!is.null(app_config$language)) {
                #   app_config$language$default <<- selected_lang
                # }

                # 重新載入語言內容
                new_lang_content <- load_language_content(app_config, language = selected_lang)
                # global_lang_content 會由 load_language_content 自動同步，不需要手動設置
                # global_lang_content(new_lang_content)

                cat("✅ === 語言載入成功調試資訊 ===\n")
                cat("✅ 要求載入語言:", selected_lang, "\n")
                cat("✅ 實際載入語言:", new_lang_content$language, "\n")
                cat("✅ 語言內容是否為空:", is.null(new_lang_content$content) || length(new_lang_content$content) == 0, "\n")
                cat("✅ 登入後 global_lang_content 語言:", global_lang_content()$language, "\n")
                cat("✅ ============================\n")

                # 更新 navbar 語言選擇器以匹配登入選擇
                updateSelectInput(session, "navbar_language_selector", selected = selected_lang)
                cat("✅ Navbar 語言選擇器已同步:", selected_lang, "\n")

                # 儲存到 sessionStorage 但不刷新頁面
                js_code <- sprintf("
                  sessionStorage.setItem('selected_language', '%s');
                  console.log('Language preference saved: %s');
                ", selected_lang, selected_lang)
                shinyjs::runjs(js_code)

                # 發送語言變更消息到主應用程式
                session$sendCustomMessage("global_language_change", list(
                  language = selected_lang,
                  content = selected_lang
                ))

                # **關鍵修復**: 強制所有模組立即更新語言
                session$sendCustomMessage("force_module_language_sync", list(
                  language = selected_lang,
                  force_reload = TRUE,
                  timestamp = as.numeric(Sys.time())
                ))

                # 延遲觸發 UI 元素重新渲染，確保語言內容已載入
                shinyjs::delay(200, {
                  session$sendCustomMessage("force_ui_refresh", list(
                    language = selected_lang,
                    timestamp = as.numeric(Sys.time())
                  ))

                  # 額外觸發一次全頁面重新渲染
                  shinyjs::runjs("
                    setTimeout(function() {
                      // 強制重新渲染所有動態內容
                      $('[data-toggle=\"tooltip\"]').tooltip('dispose').tooltip();
                      // 觸發窗口大小變更事件來重新布局
                      $(window).trigger('resize');
                    }, 100);
                  ")
                })

              }, error = function(e) {
                cat("⚠️ 語言切換失敗:", e$message, "\n")
                cat("🔔 ===============================\n\n")
              })
            } else {
              cat("🔔 登入模組未返回語言設定，保持當前語言\n")
              cat("🔔 ===============================\n\n")
            }
          })

          showNotification(paste(get_text("system.notifications.welcome", "歡迎!"), login_user$username), type = "message")

          # 從配置中取得預設頁面
          default_page <- app_config$navigation$default_page %||% "upload"
          updateTabItems(session, "sidebar_menu", default_page)
        }
      })

      # ==========================================
      # Logout button handler
      # ==========================================
      observeEvent(input$logout_btn, {
        message("🚪 Logout button clicked")

        # Clear user info FIRST to trigger UI change
        user_info(NULL)

        # Call login module logout function to clear its internal state
        if (!is.null(login_instance) && !is.null(login_instance$logout)) {
          tryCatch({
            login_instance$logout()
            message("✅ Login module logout called successfully")
          }, error = function(e) {
            message("⚠️ Login module logout error:", e$message)
          })
        }

        # Force session reload to return to login page
        session$reload()

        message("👋 User logged out via button - UI reloading to show login page")
      })

      # 顯示資料庫狀態
      output$db_status <- renderUI({
        div(
          style = sprintf("color: %s; padding: 8px; margin-right: 15px; background: rgba(255,255,255,0.1); border-radius: 5px;",
                         db_info$color),
          span(db_info$icon, style = "margin-right: 5px;"),
          span(db_info$type, style = "font-weight: bold; margin-right: 5px;"),
          span(sprintf("(%s)", db_info$status), style = "font-size: 0.9em; opacity: 0.8;")
        )
      })

      # 顯示用戶選單
      output$user_menu <- renderUI({
        if (!is.null(user_info())) {
          div(
            style = "color: white; padding: 8px;",
            sprintf("👤 %s", user_info()$username)
          )
        }
      })
    # NOTE: 已移除多餘的 }，ServerEngine if 區塊應延續到 line ~2063

    # 初始化所有模組 Server
    module_instances <- list()

    # ==========================================
    # 🎯 動態渲染模組 UI (語言切換支援)
    # ==========================================
    # 渲染上傳模組 UI (當語言變更時會重新渲染)
    output$upload_review_sales_upload_review_sales_ui_container <- renderUI({
      # 監聽語言更新觸發器，確保語言切換時重新渲染
      trigger_value <- module_ui_update_trigger()

      cat("\n🎨 === [Upload UI] renderUI 觸發 ===\n")
      cat("🎨 Trigger 值:", trigger_value, "\n")

      # 取得當前語言內容
      current_lang_content <- global_lang_content()

      cat("🎨 global_lang_content() 返回:\n")
      cat("  - 是否為 NULL:", is.null(current_lang_content), "\n")
      if (!is.null(current_lang_content)) {
        cat("  - 類型:", class(current_lang_content), "\n")
        cat("  - language 欄位:", current_lang_content$language %||% "不存在", "\n")
        cat("  - content 欄位是否存在:", "content" %in% names(current_lang_content), "\n")
      }

      # 同時檢查 global_language_state
      if (exists("global_language_state")) {
        cat("🎨 global_language_state 檢查:\n")
        cat("  - current_language:", isolate(global_language_state$current_language), "\n")
        state_content <- isolate(global_language_state$language_content)
        cat("  - language_content$language:", state_content$language %||% "NULL", "\n")
      }

      # 取得模組配置
      upload_config <- if (!is.null(app_config$module_configs$upload_review_sales)) {
        app_config$module_configs$upload
      } else {
        NULL
      }

      # 取得模組語言內容
      upload_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "upload_review_sales")
      } else {
        NULL
      }

      cat("🎨 upload_texts 語言:", upload_texts$language %||% "NULL", "\n")
      cat("🎨 === [Upload UI] renderUI 完成 ===\n\n")

      # 生成模組 UI
      if (exists("uploadModuleUI")) {
        uploadModuleUI("upload_review_sales", module_config = upload_config, lang_texts = upload_texts)
      } else {
        div("Upload module not found")
      }
    })

    # 渲染評分模組 UI
    output$scoring_scoring_ui_container <- renderUI({
      trigger_val <- module_ui_update_trigger()
      current_lang_content <- global_lang_content()

      cat("\n🎨 [OUTER renderUI] scoring_scoring_ui_container 重新渲染 (trigger:", trigger_val, ")\n")
      cat("  📖 當前語言:", current_lang_content$language %||% "NULL", "\n")

      score_config <- if (!is.null(app_config$module_configs$scoring)) {
        app_config$module_configs$scoring
      } else {
        NULL
      }

      score_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "scoring")
      } else {
        NULL
      }

      cat("  ✅ [OUTER] 準備渲染 scoreModuleUI，lang:", score_texts$language %||% "NULL", "\n")

      if (exists("scoreModuleUI")) {
        scoreModuleUI("scoring", module_config = score_config, lang_texts = score_texts)
      } else {
        div("Score module not found")
      }
    })

    # 渲染關鍵字廣告模組 UI
    output$keyword_ads_insightforge_keyword_ads_insightforge_ui_container <- renderUI({
      module_ui_update_trigger()
      current_lang_content <- global_lang_content()

      keyword_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "keyword_ads_insightforge")
      } else {
        NULL
      }

      # Get brand choices from scored_data if available
      brand_choices <- NULL
      if (!is.null(module_instances$score)) {
        brand_choices <- tryCatch({
          scored_func <- module_instances$score$scored_data
          if (!is.null(scored_func) && is.function(scored_func)) {
            data <- scored_func()
            cat("🎨 [OUTER renderUI] Keyword Ads - scored_data has", if(is.null(data)) "NULL" else nrow(data), "rows\n")
            if (!is.null(data) && "Variation" %in% names(data)) {
              choices <- unique(data$Variation)
              cat("🎨 [OUTER renderUI] Keyword Ads - extracted", length(choices), "brand choices:", paste(choices, collapse = ", "), "\n")
              choices
            } else {
              cat("🎨 [OUTER renderUI] Keyword Ads - no Variation column or NULL data\n")
              NULL
            }
          } else {
            cat("🎨 [OUTER renderUI] Keyword Ads - scored_data is not a function\n")
            NULL
          }
        }, error = function(e) {
          cat("🎨 [OUTER renderUI] Keyword Ads - Error getting scored_data:", e$message, "\n")
          NULL
        })
      } else {
        cat("🎨 [OUTER renderUI] Keyword Ads - module_instances$score is NULL\n")
      }

      cat("🎨 [OUTER renderUI] Keyword Ads - Final brand_choices:", if(is.null(brand_choices)) "NULL" else paste(brand_choices, collapse = ", "), "\n")

      if (exists("keyword_ads_insightforgeModuleUI")) {
        keyword_ads_insightforgeModuleUI("keyword_ads_insightforge", lang_texts = keyword_texts, brand_choices = brand_choices)
      } else {
        div("Keyword Ads module not found")
      }
    })

    # 渲染產品開發模組 UI
    output$product_dev_insightforge_product_dev_insightforge_ui_container <- renderUI({
      trigger_val <- module_ui_update_trigger()
      current_lang_content <- global_lang_content()

      cat("\n🎨 [OUTER renderUI] product_dev_product_dev_ui_container 重新渲染 (trigger:", trigger_val, ")\n")
      cat("  📖 當前語言:", current_lang_content$language %||% "NULL", "\n")

      product_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "product_dev_insightforge")
      } else {
        NULL
      }

      cat("  ✅ [OUTER] 準備渲染 productDevModuleUI，lang:", product_texts$language %||% "NULL", "\n")

      if (exists("product_dev_insightforgeModuleUI")) {
        product_dev_insightforgeModuleUI("product_dev_insightforge", lang_texts = product_texts)
      } else {
        div("Product Development module not found")
      }
    })

    # 渲染 sales_model 頁面的 sales_model 模組 UI
    output$sales_model_insightforge_sales_model_insightforge_ui_container <- renderUI({
      module_ui_update_trigger()
      current_lang_content <- global_lang_content()

      sales_config <- if (!is.null(app_config$module_configs$sales_model)) {
        app_config$module_configs$sales_model
      } else {
        NULL
      }

      sales_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "sales_model_insightforge")
      } else {
        NULL
      }

      if (exists("sales_model_insightforgeModuleUI")) {
        sales_model_insightforgeModuleUI("sales_model_insightforge", module_config = sales_config, lang_texts = sales_texts)
      } else {
        div("Sales Model module not found")
      }
    })

    # 渲染 About 模組 UI
    output$about_about_ui_container <- renderUI({
      module_ui_update_trigger()
      current_lang_content <- global_lang_content()

      cat("\n🎨 [About Module] renderUI 觸發\n")
      cat("🎨 當前語言:", current_lang_content$language %||% "NULL", "\n")

      about_config <- if (!is.null(app_config$module_configs$about)) {
        app_config$module_configs$about
      } else {
        NULL
      }

      about_texts <- if (!is.null(current_lang_content)) {
        get_module_texts(current_lang_content, "about")
      } else {
        NULL
      }

      cat("🎨 [About Module] about_texts language:", about_texts$language %||% "NULL", "\n")

      if (exists("aboutModuleUI")) {
        cat("🎨 [About Module] 調用 aboutModuleUI\n")
        aboutModuleUI("about", module_config = about_config, lang_texts = about_texts)
      } else {
        cat("❌ [About Module] aboutModuleUI 函數不存在\n")
        div("About module not found")
      }
    })

    # ==========================================
    # 🎯 動態頁面標題渲染 (語言切換支援)
    # ==========================================
    # 為每個頁面渲染動態標題
    for (page in app_config$pages) {
      local({
        page_id <- page$id

        output[[paste0("page_title_", page_id)]] <- renderUI({
          # 監聽語言更新觸發器
          module_ui_update_trigger()

          # 取得當前語言內容
          current_lang_content <- global_lang_content()

          # 獲取頁面標題翻譯
          page_title <- if (!is.null(current_lang_content) &&
                           !is.null(current_lang_content$content$common$pages) &&
                           !is.null(current_lang_content$content$common$pages[[page_id]])) {
            current_lang_content$content$common$pages[[page_id]]
          } else {
            page$title  # 備用原始標題
          }

          h2(page_title)
        })
      })
    }

    # 上傳模組 - 使用與 UI 一致的 namespace ID
    if (exists("uploadModuleServer")) {
      # 取得模組配置
      upload_config <- if (!is.null(app_config$module_configs$upload_review_sales)) {
        app_config$module_configs$upload
      } else {
        NULL
      }
      # 建立動態語言內容的 reactive
      upload_lang_texts <- reactive({
        current_lang <- global_lang_content()
        if (!is.null(current_lang)) {
          get_module_texts(current_lang, "upload_review_sales")
        } else {
          NULL
        }
      })
      module_instances$upload_review_sales <- uploadModuleServer("upload_review_sales", con_global, user_info,
                                                    module_config = upload_config,
                                                    lang_texts = upload_lang_texts)

      # 監聽上傳資料
      observe({
        uploaded <- module_instances$upload_review_sales$data()
        if (!is.null(uploaded)) {
          showNotification(get_text("system.notifications.data_upload_success", "資料上傳成功！"), type = "message")
        }
      })

      # 監聽下一步按鈕 - 切換到評分頁面
      observeEvent(module_instances$upload_review_sales$proceed_step(), {
        if (!is.null(module_instances$upload_review_sales$data())) {
          # 從配置中取得下一個頁面（評分頁）
          next_page <- app_config$navigation$upload_next_page %||% "scoring"
          updateTabItems(session, "sidebar_menu", next_page)
          showNotification(get_text("system.notifications.switch_to_scoring", "切換至評分頁面"), type = "message")
        }
      })
    }

    # 評分模組 - 使用與 UI 一致的 namespace ID
    if (exists("scoreModuleServer") && !is.null(module_instances$upload_review_sales)) {
      # 取得模組配置
      score_config <- if (!is.null(app_config$module_configs$scoring)) {
        app_config$module_configs$scoring
      } else {
        NULL
      }
      # 建立動態語言內容的 reactive
      score_lang_texts <- reactive({
        current_lang <- global_lang_content()
        cat("🔄 [Score lang_texts reactive] 被讀取，語言:", current_lang$language %||% "NULL", "\n")
        if (!is.null(current_lang)) {
          result <- get_module_texts(current_lang, "scoring")
          cat("  ✅ [Score lang_texts] 返回語言:", result$language %||% "NULL", "\n")
          result
        } else {
          NULL
        }
      })
      module_instances$score <- scoreModuleServer("scoring", con_global, user_info,
                                                  reactive(module_instances$upload_review_sales$data()),
                                                  score_config,
                                                  lang_texts = score_lang_texts)

      # 監聽下一步按鈕 - 切換到銷售模型頁面
      observeEvent(module_instances$score$proceed_step(), {
        if (!is.null(module_instances$score$scored_data())) {
          # 從配置中取得下一個頁面
          next_page <- app_config$navigation$scoring_next_page %||% "sales_model_insightforge"
          updateTabItems(session, "sidebar_menu", next_page)
          showNotification(get_text("system.notifications.enter_sales_model", "✅ 進入銷售模型分析頁面"), type = "message")
        }
      })
    }

    # 關鍵字廣告模組 - 使用與 UI 一致的 namespace ID
    if (exists("keywordAdsModuleServer") && !is.null(module_instances$score)) {
      # 建立動態語言內容的 reactive
      keyword_lang_texts <- reactive({
        current_lang <- global_lang_content()
        if (!is.null(current_lang)) {
          get_module_texts(current_lang, "keyword_ads_insightforge")
        } else {
          NULL
        }
      })
      # 取得 prompts (現在是 reactive)
      keyword_prompts <- if (exists("prompts_df") && prompts_enabled) prompts_df else NULL
      module_instances$keyword <- keywordAdsModuleServer("keyword_ads_insightforge",
                                                         reactive(module_instances$score$scored_data()),
                                                         prompts_df = keyword_prompts,  # reactive prompts_df
                                                         module_config = NULL,
                                                         lang_texts = keyword_lang_texts,
                                                         api_config = app_config$api$openai)
    }

    # ==========================================
    # 動態模組 UI 渲染器 - 響應語言變更
    # ==========================================
    # 為每個模組頁面添加動態 UI 渲染，使其能夠切換語言

    observe({
      # 觸發器: 語言更新或強制刷新
      module_ui_update_trigger()
      current_lang <- global_lang_content()

      if (!is.null(current_lang)) {
        cat("\n🎨 === 動態更新模組 UI ===\n")
        cat("🔍 [DEBUG] current_lang 結構檢查:\n")
        cat("    - 類型:", class(current_lang), "\n")
        cat("    - 欄位:", paste(names(current_lang), collapse=", "), "\n")
        cat("    - language 存在:", "language" %in% names(current_lang), "\n")
        cat("    - 所有欄位值:\n")
        for(field in names(current_lang)) {
          if(field == "content") {
            cat("      -", field, ": [content object with", length(current_lang[[field]]), "items]\n")
          } else {
            field_value <- current_lang[[field]]
            if(is.list(field_value)) {
              cat("      -", field, ": [list with", length(field_value), "items]\n")
            } else {
              cat("      -", field, ":", field_value %||% "NULL", "\n")
            }
          }
        }
        if ("language" %in% names(current_lang)) {
          cat("    - language 值: '", current_lang$language, "'\n", sep="")
          cat("    - language 類型:", class(current_lang$language), "\n")
          cat("    - language 長度:", length(current_lang$language), "\n")
          cat("    - language is.null:", is.null(current_lang$language), "\n")
          cat("    - language is.na:", is.na(current_lang$language), "\n")
        }
        cat("🎨 當前語言:", current_lang$language %||% "NULL", "\n")

        # 上傳模組 UI
        if (exists("uploadModuleUI")) {
          output$upload_review_sales_upload_review_sales_ui_container <- renderUI({
            upload_config <- app_config$module_configs$upload
            lang_texts <- get_module_texts(current_lang, "upload_review_sales")
            cat("🎨 更新上傳模組 UI，語言:", current_lang$language %||% "NULL", "\n")
            uploadModuleUI("upload_review_sales", module_config = upload_config, lang_texts = lang_texts)
          })
        }

        # 評分模組 UI
        if (exists("scoreModuleUI")) {
          output$scoring_scoring_ui_container <- renderUI({
            score_config <- app_config$module_configs$scoring
            lang_texts <- get_module_texts(current_lang, "scoring")
            cat("🎨 更新評分模組 UI，語言:", current_lang$language, "\n")
            scoreModuleUI("scoring", module_config = score_config, lang_texts = lang_texts)
          })
        }

        # 銷售模型模組 UI
        if (exists("sales_model_insightforgeModuleUI")) {
          output$sales_model_insightforge_sales_model_insightforge_ui_container <- renderUI({
            sales_config <- app_config$module_configs$sales_model
            lang_texts <- get_module_texts(current_lang, "sales_model_insightforge")
            cat("🎨 更新銷售模型模組 UI，語言:", current_lang$language, "\n")

            # Get brand choices from scored_data if available
            brand_choices <- NULL
            if (!is.null(module_instances$score)) {
              brand_choices <- tryCatch({
                scored_func <- module_instances$score$scored_data
                if (!is.null(scored_func) && is.function(scored_func)) {
                  data <- scored_func()
                  cat("  🎨 [OBSERVE renderUI] Sales Model - scored_data has", if(is.null(data)) "NULL" else nrow(data), "rows\n")
                  if (!is.null(data) && "Variation" %in% names(data)) {
                    choices <- unique(data$Variation)
                    cat("  🎨 [OBSERVE renderUI] Sales Model - extracted", length(choices), "brand choices:", paste(choices, collapse = ", "), "\n")
                    choices
                  } else {
                    cat("  🎨 [OBSERVE renderUI] Sales Model - no Variation column or NULL data\n")
                    NULL
                  }
                } else {
                  cat("  🎨 [OBSERVE renderUI] Sales Model - scored_data is not a function\n")
                  NULL
                }
              }, error = function(e) {
                cat("  🎨 [OBSERVE renderUI] Sales Model - Error getting scored_data:", e$message, "\n")
                NULL
              })
            } else {
              cat("  🎨 [OBSERVE renderUI] Sales Model - module_instances$score is NULL\n")
            }

            cat("  🎨 [OBSERVE renderUI] Sales Model - Final brand_choices:", if(is.null(brand_choices)) "NULL" else paste(brand_choices, collapse = ", "), "\n")

            sales_model_insightforgeModuleUI("sales_model_insightforge", module_config = sales_config, lang_texts = lang_texts, brand_choices = brand_choices)
          })
        }

        # 關鍵字廣告模組 UI
        if (exists("keyword_ads_insightforgeModuleUI")) {
          output$keyword_ads_insightforge_keyword_ads_insightforge_ui_container <- renderUI({
            keyword_config <- app_config$module_configs$keyword_ads
            lang_texts <- get_module_texts(current_lang, "keyword_ads_insightforge")
            cat("🎨 更新關鍵字廣告模組 UI，語言:", current_lang$language, "\n")

            # Get brand choices from scored_data if available
            brand_choices <- NULL
            if (!is.null(module_instances$score)) {
              brand_choices <- tryCatch({
                scored_func <- module_instances$score$scored_data
                if (!is.null(scored_func) && is.function(scored_func)) {
                  data <- scored_func()
                  cat("  🎨 [OBSERVE renderUI] Keyword Ads - scored_data has", if(is.null(data)) "NULL" else nrow(data), "rows\n")
                  if (!is.null(data) && "Variation" %in% names(data)) {
                    choices <- unique(data$Variation)
                    cat("  🎨 [OBSERVE renderUI] Keyword Ads - extracted", length(choices), "brand choices:", paste(choices, collapse = ", "), "\n")
                    choices
                  } else {
                    cat("  🎨 [OBSERVE renderUI] Keyword Ads - no Variation column or NULL data\n")
                    NULL
                  }
                } else {
                  cat("  🎨 [OBSERVE renderUI] Keyword Ads - scored_data is not a function\n")
                  NULL
                }
              }, error = function(e) {
                cat("  🎨 [OBSERVE renderUI] Keyword Ads - Error getting scored_data:", e$message, "\n")
                NULL
              })
            } else {
              cat("  🎨 [OBSERVE renderUI] Keyword Ads - module_instances$score is NULL\n")
            }

            cat("  🎨 [OBSERVE renderUI] Keyword Ads - Final brand_choices:", if(is.null(brand_choices)) "NULL" else paste(brand_choices, collapse = ", "), "\n")

            keyword_ads_insightforgeModuleUI("keyword_ads_insightforge", module_config = keyword_config, lang_texts = lang_texts, brand_choices = brand_choices)
          })
        }

        # 產品開發模組 UI
        if (exists("product_dev_insightforgeModuleUI")) {
          output$product_dev_insightforge_product_dev_insightforge_ui_container <- renderUI({
            product_config <- app_config$module_configs$product_dev
            lang_texts <- get_module_texts(current_lang, "product_dev_insightforge")
            cat("🎨 更新產品開發模組 UI，語言:", current_lang$language, "\n")
            product_dev_insightforgeModuleUI("product_dev_insightforge", module_config = product_config, lang_texts = lang_texts)
          })
        }

        # About 模組 UI
        if (exists("aboutModuleUI")) {
          output$about_about_ui_container <- renderUI({
            about_config <- app_config$module_configs$about
            lang_texts <- get_module_texts(current_lang, "about")
            cat("🎨 更新 About 模組 UI，語言:", current_lang$language, "\n")
            aboutModuleUI("about", module_config = about_config, lang_texts = lang_texts)
          })
        }

        cat("🎨 === 模組 UI 更新完成 ===\n\n")
      }
    })

    # 產品開發模組 - 使用與 UI 一致的 namespace ID
    if (exists("productDevModuleServer") && !is.null(module_instances$score)) {
      # 建立動態語言內容的 reactive
      product_lang_texts <- reactive({
        current_lang <- global_lang_content()
        cat("🔄 [Product Dev lang_texts reactive] 被讀取，語言:", current_lang$language %||% "NULL", "\n")
        if (!is.null(current_lang)) {
          result <- get_module_texts(current_lang, "product_dev_insightforge")
          cat("  ✅ [Product Dev lang_texts] 返回語言:", result$language %||% "NULL", "\n")
          result
        } else {
          NULL
        }
      })
      # 取得 prompts (現在是 reactive)
      product_prompts <- if (exists("prompts_df") && prompts_enabled) prompts_df else NULL
      module_instances$product <- productDevModuleServer("product_dev_insightforge",
                                                         reactive(module_instances$score$scored_data()),
                                                         prompts_df = product_prompts,  # reactive prompts_df
                                                         module_config = NULL,
                                                         lang_texts = product_lang_texts,
                                                         api_config = app_config$api$openai)
    }

    # 銷售模型模組 - 使用與 UI 一致的 namespace ID
    if (exists("salesModelModuleServer") && !is.null(module_instances$score) && !is.null(module_instances$upload_review_sales)) {
      # 取得模組配置
      sales_config <- if (!is.null(app_config$module_configs$sales_model)) {
        app_config$module_configs$sales_model
      } else {
        NULL
      }
      # 建立動態語言內容的 reactive
      sales_lang_texts <- reactive({
        current_lang <- global_lang_content()
        if (!is.null(current_lang)) {
          get_module_texts(current_lang, "sales_model_insightforge")
        } else {
          NULL
        }
      })
      # Sales model module server instance (unified)
      # 取得 prompts
      # 取得 prompts (現在是 reactive)
      sales_prompts <- if (exists("prompts_df") && prompts_enabled) prompts_df else NULL
      module_instances$sales_model <- salesModelModuleServer("sales_model_insightforge",
                                                              reactive(module_instances$score$scored_data()),
                                                              reactive(module_instances$upload_review_sales$sales_data()),
                                                              prompts_df = sales_prompts,  # reactive prompts_df
                                                              module_config = sales_config,
                                                              lang_texts = sales_lang_texts)
    }

    # About 模組 - 使用與 UI 一致的 namespace ID
    if (exists("aboutModuleServer")) {
      cat("🔧 [About Module] 正在初始化 Server...\n")

      # 取得模組配置
      about_config <- if (!is.null(app_config$module_configs$about)) {
        app_config$module_configs$about
      } else {
        NULL
      }

      # 建立動態語言內容的 reactive
      about_lang_texts <- reactive({
        current_lang <- global_lang_content()
        if (!is.null(current_lang)) {
          get_module_texts(current_lang, "about")
        } else {
          NULL
        }
      })

      # 初始化 About 模組 Server
      module_instances$about <- aboutModuleServer("about",
                                                  module_config = about_config,
                                                  lang_texts = about_lang_texts)

      cat("✅ [About Module] Server 初始化完成\n")
    } else {
      cat("❌ [About Module] aboutModuleServer 函數不存在\n")
    }
  }  # END of if (exists("ServerEngine"))

  # ==========================================
  # 備用模式：ServerEngine 不存在時使用
  # ==========================================
  if (!exists("ServerEngine")) {
    # 建立基本的 reactive values
    shared_state <- reactiveValues(
      user_info = NULL,
      current_page = NULL
    )

    # 處理頁面導航
    if (length(app_config$pages) > 0) {
      lapply(app_config$pages, function(page) {
        observeEvent(input[[paste0("goto_", page$id)]], {
          shared_state$current_page <- page$id
          showNotification(paste(get_text("system.notifications.switch_to", "切換至:"), page$title), type = "message")
        })
      })
    }

    # 顯示主要內容
    output$main_content <- renderUI({
      if (!is.null(shared_state$current_page)) {
        # 找到對應的頁面配置
        current_page_config <- NULL
        for (page in app_config$pages) {
          if (page$id == shared_state$current_page) {
            current_page_config <- page
            break
          }
        }

        if (!is.null(current_page_config)) {
          tagList(
            h4(current_page_config$title),
            if (!is.null(current_page_config$content)) {
              if (current_page_config$content$type == "html") {
                HTML(current_page_config$content$value)
              } else {
                p(current_page_config$content$value %||% get_text("system.ui.loading_content", "內容載入中..."))
              }
            } else {
              p(get_text("system.ui.page_loading", "頁面內容載入中..."))
            }
          )
        }
      } else {
        h4(get_text("system.ui.select_from_menu", "請從左側選單選擇功能"))
      }
    })

    # 初始化登入模組（備用模式）
    # 優先使用 Supabase 登入模組
    if (exists("USE_SUPABASE_AUTH") && USE_SUPABASE_AUTH && exists("loginSupabaseServer")) {
      message("🔐 [備用模式] 使用 Supabase 登入模組")
      login_instance <- loginSupabaseServer("login1", app_name = "insightforge")
    } else if (exists("loginModuleServer")) {
      message("🔐 [備用模式] 使用傳統 bcrypt 登入模組")
      # 取得模組語言內容
      login_texts <- if (!is.null(lang_content)) {
        get_module_texts(lang_content, "login")
      } else {
        NULL
      }
      login_instance <- loginModuleServer("login1", login_texts)
    }

      # 監聽登入狀態
      observe({
        login_user <- login_instance$user_info()
        if (!is.null(login_user)) {
          shared_state$user_info <- login_user
          user_info(login_user)  # 更新 reactive value
          showNotification(paste(get_text("system.notifications.welcome", "歡迎!"), login_user$username), type = "message")
        }
      })
    # NOTE: 移除多餘的右大括號，備用模式區塊應延續到最後

    # 初始化上傳模組（備用模式）
    if (exists("uploadModuleServer")) {
      upload_mod <- uploadModuleServer("upload_review_sales", con_global, user_info)

      # 監聽上傳資料
      observe({
        uploaded <- upload_mod$data()
        if (!is.null(uploaded)) {
          showNotification(get_text("system.notifications.data_upload_success", "資料上傳成功！"), type = "message")
        }
      })

      # 監聽下一步按鈕 - 切換到評分頁面
      observeEvent(upload_mod$proceed_step(), {
        if (!is.null(upload_mod$data())) {
          # 從配置中取得下一個頁面
          next_page <- app_config$navigation$upload_next_page %||% "scoring"
          updateTabItems(session, "sidebar_menu", next_page)
          showNotification(get_text("system.notifications.switch_to_scoring", "切換至評分頁面"), type = "message")
        }
      })
    }

    # 初始化評分模組（備用模式）
    if (exists("scoreModuleServer") && exists("upload_mod")) {
      score_mod <- scoreModuleServer("scoring", con_global, user_info,
                                     reactive(upload_mod$data()))

      # 監聽下一步按鈕
      observeEvent(score_mod$proceed_step(), {
        if (!is.null(score_mod$scored_data())) {
          # 從配置中取得下一個頁面
          next_page <- app_config$navigation$scoring_next_page %||% "sales_model_insightforge"
          updateTabItems(session, "sidebar_menu", next_page)
          showNotification(get_text("system.notifications.enter_sales_model", "✅ 進入銷售模型分析頁面"), type = "message")
        }
      })
    }

    # 初始化關鍵字廣告模組（備用模式）
    if (exists("keywordAdsModuleServer") && exists("score_mod")) {
      keyword_mod <- keywordAdsModuleServer("keyword_ads_insightforge",
                                            reactive(score_mod$scored_data()),
                                            api_config = app_config$api$openai)
    }

    # 初始化產品開發模組（備用模式）
    if (exists("productDevModuleServer") && exists("score_mod")) {
      product_mod <- productDevModuleServer("product_dev_insightforge",
                                            reactive(score_mod$scored_data()),
                                            api_config = app_config$api$openai)
    }
  }  # END of if (!exists("ServerEngine"))

  # 顯示資料庫狀態
  output$db_status <- renderUI({
    div(
      style = sprintf("color: %s; padding: 8px;", db_info$color),
      span(db_info$icon, style = "margin-right: 5px;"),
      span(db_info$type)
    )
  })
}

# ==========================================
# 啟動應用程式
# ==========================================

# 正確關閉連接池：App 停止時關閉 Pool
onStop(function() {
  if (exists("close_pool") && is.function(close_pool)) {
    close_pool()
  }
})

shinyApp(ui = ui(), server = server)

# ==========================================
# 備註說明
# ==========================================
# 這個版本的特點：
# 1. 完全由 YAML 配置驅動
# 2. 使用動態 UI 生成器（ui_generator.R）
# 3. 使用動態 Server 引擎（server_engine.R）
# 4. 配置管理由 config_manager.R 處理
# 5. 模組載入由 module_manager.R 處理
# 6. 無需修改程式碼即可改變應用行為
# 7. 所有業務邏輯都在 YAML 和模組中定義
