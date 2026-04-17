# Hint System Functions for bs4Dash
# bs4Dash 提示系統功能函數

library(shiny)
library(bs4Dash)

# 載入提示資料
load_hints <- function(hint_file = "database/hint.csv") {
  if (file.exists(hint_file)) {
    hints <- read.csv(hint_file, stringsAsFactors = FALSE, encoding = "UTF-8")
    return(hints)
  } else {
    warning("Hint file not found: ", hint_file)
    return(data.frame(
      concept_name = character(),
      var_id = character(),
      description = character(),
      stringsAsFactors = FALSE
    ))
  }
}

# 取得特定 var_id 的提示內容
get_hint <- function(var_id, hints_df = NULL) {
  if (is.null(hints_df)) {
    hints_df <- load_hints()
  }
  
  hint_row <- hints_df[hints_df$var_id == var_id, ]
  
  if (nrow(hint_row) > 0) {
    return(hint_row$description[1])
  } else {
    return(NULL)
  }
}

# 為 UI 元素添加提示功能 - 使用 bs4Dash 的 tooltip
add_hint <- function(ui_element, var_id, hints_df = NULL, enable_hints = TRUE) {
  if (!enable_hints) {
    return(ui_element)
  }
  
  hint_text <- get_hint(var_id, hints_df)
  
  if (!is.null(hint_text)) {
    # 使用 bs4Dash 的 tooltip 功能
    return(
      bs4Dash::tooltip(
        tag = ui_element,
        title = hint_text,
        placement = "top"
      )
    )
  } else {
    return(ui_element)
  }
}

# 為 Shiny UI 元素添加提示（兼容 bs4Dash）
add_hint_bs4 <- function(ui_element, var_id, hints_df = NULL, enable_hints = TRUE) {
  if (!enable_hints) {
    return(ui_element)
  }
  
  hint_text <- get_hint(var_id, hints_df)
  
  if (!is.null(hint_text)) {
    # 為元素添加 data attributes 和 title
    return(
      tags$div(
        ui_element,
        `data-toggle` = "tooltip",
        `data-placement` = "top",
        title = hint_text,
        style = "display: inline-block;"
      )
    )
  } else {
    return(ui_element)
  }
}

# 初始化提示系統的 JavaScript
init_hint_system <- function() {
  tags$script(HTML("
    $(document).ready(function(){
      // 初始化 Bootstrap tooltips
      $('[data-toggle=\"tooltip\"]').tooltip({
        trigger: 'hover',
        container: 'body',
        boundary: 'window'
      });
      
      // 當新元素加入時重新初始化
      Shiny.addCustomMessageHandler('init_tooltips', function(message) {
        setTimeout(function() {
          $('[data-toggle=\"tooltip\"]').tooltip({
            trigger: 'hover',
            container: 'body',
            boundary: 'window'
          });
        }, 100);
      });
    });
  "))
}

# 在 server 端觸發提示初始化
trigger_hint_init <- function(session) {
  session$sendCustomMessage("init_tooltips", list())
}