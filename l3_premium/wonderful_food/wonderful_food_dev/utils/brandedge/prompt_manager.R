# Prompt Management System for GPT API
# GPT Prompt 集中管理系統

library(stringr)

# 載入 prompt 資料
load_prompts <- function(prompt_file = "database/prompt.csv") {
  if (file.exists(prompt_file)) {
    prompts <- read.csv(prompt_file, stringsAsFactors = FALSE, encoding = "UTF-8")
    return(prompts)
  } else {
    warning("Prompt file not found: ", prompt_file)
    return(data.frame(
      analysis_name = character(),
      var_id = character(),
      prompt = character(),
      stringsAsFactors = FALSE
    ))
  }
}

# 取得特定 var_id 的 prompt
get_prompt <- function(var_id, prompts_df = NULL) {
  if (is.null(prompts_df)) {
    prompts_df <- load_prompts()
  }
  
  prompt_row <- prompts_df[prompts_df$var_id == var_id, ]
  
  if (nrow(prompt_row) > 0) {
    return(prompt_row$prompt[1])
  } else {
    warning(paste("Prompt not found for var_id:", var_id))
    return(NULL)
  }
}

# 解析 prompt 為 system 和 user 部分
parse_prompt <- function(prompt_text) {
  if (is.null(prompt_text)) {
    return(list(system = "", user = ""))
  }
  
  # 分離 system 和 user 部分
  parts <- strsplit(prompt_text, "\nuser: ")[[1]]
  
  if (length(parts) >= 2) {
    system_part <- gsub("^system: ", "", parts[1])
    user_part <- parts[2]
  } else {
    # 如果沒有明確分離，整個作為 user prompt
    system_part <- "你是一位AI助手。"
    user_part <- prompt_text
  }
  
  return(list(
    system = system_part,
    user = user_part
  ))
}

# 替換 prompt 中的變數
replace_prompt_variables <- function(prompt_text, variables = list()) {
  if (is.null(prompt_text)) {
    return(prompt_text)
  }
  
  # 替換所有 {variable_name} 格式的變數
  for (var_name in names(variables)) {
    pattern <- paste0("\\{", var_name, "\\}")
    replacement <- as.character(variables[[var_name]])
    prompt_text <- gsub(pattern, replacement, prompt_text)
  }
  
  return(prompt_text)
}

# 準備 GPT API 請求的消息格式
prepare_gpt_messages <- function(var_id, variables = list(), prompts_df = NULL) {
  # 取得原始 prompt
  raw_prompt <- get_prompt(var_id, prompts_df)
  
  if (is.null(raw_prompt)) {
    stop(paste("Cannot find prompt for var_id:", var_id))
  }
  
  # 解析 system 和 user 部分
  parsed <- parse_prompt(raw_prompt)
  
  # 替換變數
  system_content <- replace_prompt_variables(parsed$system, variables)
  user_content <- replace_prompt_variables(parsed$user, variables)
  
  # 建立消息列表
  messages <- list(
    list(role = "system", content = system_content),
    list(role = "user", content = user_content)
  )
  
  return(messages)
}

# 便利函數：直接執行 GPT 請求
execute_gpt_request <- function(var_id, 
                                variables = list(), 
                                chat_api_function = NULL,
                                model = "gpt-4o-mini",
                                max_tokens = 2048,
                                temperature = 0.3,
                                prompts_df = NULL) {
  
  # 準備消息
  messages <- prepare_gpt_messages(var_id, variables, prompts_df)
  
  # 如果沒有提供 chat_api 函數，返回準備好的消息
  if (is.null(chat_api_function)) {
    return(messages)
  }
  
  # 執行 API 請求
  response <- tryCatch(
    chat_api_function(
      messages = messages,
      model = model,
      max_tokens = max_tokens,
      temperature = temperature
    ),
    error = function(e) {
      warning(paste("GPT API error:", e$message))
      return(NULL)
    }
  )
  
  return(response)
}

# 取得所有可用的 prompt ID
list_available_prompts <- function(prompts_df = NULL) {
  if (is.null(prompts_df)) {
    prompts_df <- load_prompts()
  }
  
  return(data.frame(
    analysis_name = prompts_df$analysis_name,
    var_id = prompts_df$var_id,
    stringsAsFactors = FALSE
  ))
}

# 更新或新增 prompt
update_prompt <- function(var_id, 
                         analysis_name, 
                         prompt_text,
                         prompt_file = "database/prompt.csv") {
  
  # 載入現有 prompts
  prompts_df <- load_prompts(prompt_file)
  
  # 檢查是否已存在
  existing_index <- which(prompts_df$var_id == var_id)
  
  if (length(existing_index) > 0) {
    # 更新現有 prompt
    prompts_df[existing_index, "analysis_name"] <- analysis_name
    prompts_df[existing_index, "prompt"] <- prompt_text
    message(paste("Updated prompt for var_id:", var_id))
  } else {
    # 新增 prompt
    new_row <- data.frame(
      analysis_name = analysis_name,
      var_id = var_id,
      prompt = prompt_text,
      stringsAsFactors = FALSE
    )
    prompts_df <- rbind(prompts_df, new_row)
    message(paste("Added new prompt for var_id:", var_id))
  }
  
  # 寫回檔案
  write.csv(prompts_df, prompt_file, row.names = FALSE, fileEncoding = "UTF-8")
  
  return(TRUE)
}