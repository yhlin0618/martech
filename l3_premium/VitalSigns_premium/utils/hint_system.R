# Hint System Functions for bs4Dash
# bs4Dash 提示系統功能函數 - VitalSigns Premium

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

# VitalSigns 特定：為銷售分析元件添加提示
add_sales_hint <- function(ui_element, element_type, hints_df = NULL) {
  # 根據元件類型對應到 var_id
  var_id <- switch(element_type,
    "upload" = "upload_button",
    "date" = "date_range",
    "product" = "product_select",
    "monitor" = "sales_monitor_tab",
    "trends" = "market_trends_tab",
    "score" = "sales_health_score",
    "kpi" = "kpi_dashboard",
    element_type # 預設使用原始類型
  )
  
  return(add_hint(ui_element, var_id, hints_df))
}

# 批量為多個元素添加提示
add_hints_batch <- function(ui_elements, var_ids, hints_df = NULL, enable_hints = TRUE) {
  if (!enable_hints || length(ui_elements) != length(var_ids)) {
    return(ui_elements)
  }
  
  # 一次載入所有提示
  if (is.null(hints_df)) {
    hints_df <- load_hints()
  }
  
  # 為每個元素添加提示
  result <- mapply(function(element, var_id) {
    add_hint(element, var_id, hints_df, enable_hints)
  }, ui_elements, var_ids, SIMPLIFY = FALSE)
  
  return(result)
}

# 更新或新增提示
update_hint <- function(var_id, 
                       concept_name, 
                       description,
                       hint_file = "database/hint.csv") {
  
  # 載入現有提示
  hints_df <- load_hints(hint_file)
  
  # 檢查是否已存在
  existing_index <- which(hints_df$var_id == var_id)
  
  if (length(existing_index) > 0) {
    # 更新現有提示
    hints_df[existing_index, "concept_name"] <- concept_name
    hints_df[existing_index, "description"] <- description
    message(paste("Updated hint for var_id:", var_id))
  } else {
    # 新增提示
    new_row <- data.frame(
      concept_name = concept_name,
      var_id = var_id,
      description = description,
      stringsAsFactors = FALSE
    )
    hints_df <- rbind(hints_df, new_row)
    message(paste("Added new hint for var_id:", var_id))
  }
  
  # 寫回檔案
  write.csv(hints_df, hint_file, row.names = FALSE, fileEncoding = "UTF-8")
  
  return(TRUE)
}

# 列出所有可用的提示
list_available_hints <- function(hints_df = NULL) {
  if (is.null(hints_df)) {
    hints_df <- load_hints()
  }
  
  return(data.frame(
    concept_name = hints_df$concept_name,
    var_id = hints_df$var_id,
    stringsAsFactors = FALSE
  ))
}