#' Load App Configuration from YAML File and Parameter Directory
#'
#' This function loads application configuration from a YAML file and 
#' sets up brand-specific parameters in the global environment.
#' It also dynamically loads all .xlsx files from the app_data/parameters directory
#' and makes them available as global variables.
#'
#' @param config_path Character string. Path to the YAML configuration file.
#' @param parameters_dir Character string. Path to the parameters directory.
#' @param verbose Logical. Whether to display verbose loading messages.
#' @param config List. Optional pre-loaded configuration (to avoid reading from file).
#' @param load_parameters Logical. Whether to load parameter files. Default: TRUE.
#'
#' @return List containing the loaded configuration.
#'
#' @examples
#' config <- load_app_config("app_config.yaml")
load_app_config <- function(config_path = "app_config.yaml", 
                            parameters_dir = file.path("app_data", "parameters"),
                            verbose = FALSE,
                            config = NULL,
                            load_parameters = TRUE) {
  if (verbose) message(paste("Loading configuration from", config_path))
  
  # Check if yaml package is available
  if (!requireNamespace("yaml", quietly = TRUE)) {
    install.packages("yaml")
    library(yaml)
  } else { library(yaml) }
  
  # Check if config file exists
  if (!file.exists(config_path)) {
    warning(paste("Configuration file not found:", config_path))
    return(list())
  }
  
  # Load configuration or use provided config
  tryCatch({
    if (is.null(config)) {
      if (verbose) message("Loading config from file:", config_path)
      config <- yaml::read_yaml(config_path)
    } else {
      if (verbose) message("Using pre-loaded config")
    }
    
    # Determine parameters directory based on config
    if (!is.null(config$parameters) && config$parameters == "default") {
      parameters_dir <- file.path("app_data", "parameters")
      if (verbose) message(paste("Using default parameters directory:", parameters_dir))
    } else if (!is.null(config$brand$parameters_folder)) {
      if (config$brand$parameters_folder == "default") {
        parameters_dir <- file.path("app_data", "parameters")
        if (verbose) message(paste("Using default parameters folder from brand config:", parameters_dir))
      } else {
        parameters_dir <- config$brand$parameters_folder
        if (verbose) message(paste("Using custom parameters folder from brand config:", parameters_dir))
      }
    }
    
    # Check if parameters directory exists if specified
    if (!is.null(parameters_dir) && !dir.exists(parameters_dir)) {
      warning(paste("Parameters directory not found:", parameters_dir))
      parameters_dir <- NULL
    }
    
    # Extract brand settings and make them available globally
    if (!is.null(config$brand)) {
      assign("language", config$brand$language, envir = .GlobalEnv)
      
      # Handle either raw_data or raw_data_folder (for backwards compatibility)
      if (!is.null(config$brand$raw_data)) {
        assign("raw_data", config$brand$raw_data, envir = .GlobalEnv)
        assign("raw_data_folder", config$brand$raw_data, envir = .GlobalEnv)
      } else if (!is.null(config$brand$raw_data_folder)) {
        assign("raw_data", config$brand$raw_data_folder, envir = .GlobalEnv)
        assign("raw_data_folder", config$brand$raw_data_folder, envir = .GlobalEnv)
      }
      
      assign("brand_name", config$brand$name, envir = .GlobalEnv)
      
      # Get language from brand config
      language <- config$brand$language
      
      # Fix marketing channels parsing issue (MP107: Root Cause Resolution Principle)
      # This specifically addresses issues with spaces in channel names from YAML
      if (!is.null(config$company)) {
        # Process marketing channels if they exist in the config
        if (!is.null(config$company$marketing_channels) || 
            any(grepl("^marketing_channels", names(config$company)))) {
          
          # Initialize list for normalized marketing channels
          normalized_channels <- list()
          
          # Extract all keys that could contain marketing channel information
          mc_keys <- grep("marketing_channels", names(config$company), value = TRUE)
          
          if (length(mc_keys) > 0) {
            if (verbose) message("Found potential marketing channel keys: ", paste(mc_keys, collapse=", "))
            
            # Process each key that might contain marketing channel information
            for (key in mc_keys) {
              if (key == "marketing_channels") {
                # This is the main key we expect
                channels <- config$company[[key]]
                if (is.list(channels)) {
                  # Add all proper channels
                  for (channel_name in names(channels)) {
                    channel_id <- channels[[channel_name]]
                    normalized_channels[[channel_name]] <- channel_id
                    if (verbose) message("Added channel from marketing_channels: ", channel_name)
                  }
                }
              } else {
                # This might be a malformed key like "marketing_channelsOfficial Website"
                # Extract channel name from malformed key
                channel_name <- sub("^marketing_channels(.+)$", "\\1", key)
                if (nzchar(channel_name)) {
                  # Clean up channel name (remove extra backticks if present)
                  channel_name <- gsub("`", "", channel_name)
                  # Remove leading spaces if any
                  channel_name <- trimws(channel_name)
                  
                  # Get channel id
                  channel_id <- config$company[[key]]
                  
                  if (!is.null(channel_id) && nzchar(channel_id)) {
                    normalized_channels[[channel_name]] <- channel_id
                    if (verbose) message("Added channel from malformed key: ", channel_name)
                  }
                }
              }
            }
            
            # Replace the marketing_channels in config with the normalized version
            if (length(normalized_channels) > 0) {
              config$company$marketing_channels <- normalized_channels
              
              # Create global version for direct access
              assign("marketing_channels", normalized_channels, envir = .GlobalEnv)
              if (verbose) message("Created normalized marketing_channels with ", length(normalized_channels), " channels")
              
              # Also handle channel_availability based on the normalized channels
              if (!is.null(config$company$channel_availability)) {
                channel_availability <- config$company$channel_availability
              } else {
                channel_availability <- list()
                # Default all channels to available
                for (channel_id in unlist(normalized_channels)) {
                  channel_availability[[channel_id]] <- TRUE
                }
              }
              
              # Ensure channel_availability matches channels
              for (channel_id in unlist(normalized_channels)) {
                if (is.null(channel_availability[[channel_id]])) {
                  # Default to TRUE if not specified
                  channel_availability[[channel_id]] <- TRUE
                }
              }
              
              assign("channel_availability", channel_availability, envir = .GlobalEnv)
              config$company$channel_availability <- channel_availability
              
              if (verbose) message("Created normalized channel_availability with ", length(channel_availability), " channels")
            }
          }
        }
      }
      
      if (verbose) {
        message("Brand configuration loaded:")
        message(paste(" - brand_name:", config$brand$name))
        message(paste(" - language:", language))
        if (!is.null(config$brand$raw_data)) {
          message(paste(" - raw_data:", config$brand$raw_data))
        } else if (!is.null(config$brand$raw_data_folder)) {
          message(paste(" - raw_data:", config$brand$raw_data_folder, "(from raw_data_folder)"))
        }
      }
      
      # Only load parameter files if parameters directory is specified and exists and load_parameters is TRUE
      if (!load_parameters) {
        if (verbose) message("Parameter loading disabled. Skipping parameter loading.")
      } else if (is.null(parameters_dir)) {
        if (verbose) message("No parameters directory specified. Skipping parameter loading.")
      } else if (!requireNamespace("readxl", quietly = TRUE)) {
        warning("readxl package not available. Cannot load parameter data files.")
      } else if (!requireNamespace("dplyr", quietly = TRUE)) {
        warning("dplyr package not available. Cannot load parameter data files.")
      } else {
        param_files <- list.files(parameters_dir, pattern = "\\.xlsx$", full.names = TRUE)
        param_files <- param_files[!grepl("^~\\$", basename(param_files))]
        
        if (verbose) message(paste("Found", length(param_files), "parameter files"))
        
        for (file_path in param_files) {
          file_name <- tools::file_path_sans_ext(basename(file_path))
          
          if (verbose) message(paste(" - Loading parameter file:", file_name))
          
          tryCatch({
            param_data <- readxl::read_excel(file_path)
            assign(paste0(file_name, "_dtah"), param_data, envir = .GlobalEnv)
            
            if (file_name == "product_line") {
              product_line_data <- param_data %>%
                dplyr::mutate(
                  product_line_id = sprintf("%03d", dplyr::row_number() - 1),
                  product_line_id_name = paste0(product_line_id, "_", product_line_name_english)
                )
              assign("product_line_dtah", product_line_data, envir = .GlobalEnv)
              
              product_line_dict <- as.list(setNames(
                product_line_data$product_line_id, 
                product_line_data[[paste0("product_line_name_", language)]]
              ))
              assign("product_line_dictionary", product_line_dict, envir = .GlobalEnv)
              assign("product_line_id_vec", unlist(product_line_dict), envir = .GlobalEnv)
              assign("vec_product_line_id_noall", unlist(product_line_dict)[-1], envir = .GlobalEnv)
              
            } else if (file_name == "platform") {
              platform_data <- param_data %>%
                dplyr::filter(is.na(include) | include != 0) %>%
                dplyr::mutate(
                  platform_key = tolower(gsub(" ", "", platform_name_english)),
                  platform_display = platform_name_english
                )
              assign("platform_dtah", platform_data, envir = .GlobalEnv)
              
              platform_dict <- as.list(setNames(
                platform_data$platform_key, 
                platform_data[[paste0("platform_name_", language)]]
              ))
              assign("platform_dictionary", platform_dict, envir = .GlobalEnv)
              assign("platform_vec", unlist(platform_dict), envir = .GlobalEnv)
              assign("source_dictionary", platform_dict, envir = .GlobalEnv)
              assign("source_vec", unlist(platform_dict), envir = .GlobalEnv)
              
            } else if (file_name == "ui_terminology_dictionary") {
              assign("ui_terminology_dictionary_dtah", param_data, envir = .GlobalEnv)
              
              if (all(c("category", "term_key", paste0("term_", language)) %in% names(param_data))) {
                ui_terms <- param_data %>%
                  dplyr::group_by(category) %>%
                  dplyr::summarize(
                    terms = list(setNames(term_key, .data[[paste0("term_", language)]]))
                  ) %>%
                  dplyr::pull(terms, category)
                assign("ui_terms", ui_terms, envir = .GlobalEnv)
              } else if (all(c("English", language) %in% names(param_data)) ||
                         any(grepl("^en_.*\\.UTF-8$", names(param_data), ignore.case = TRUE)) ||
                         any(grepl("^zh_.*\\.UTF-8$", names(param_data), ignore.case = TRUE))) {
                available_columns <- names(param_data)
                if (verbose) message(paste("Dictionary columns:", paste(available_columns, collapse = ", ")))
                
                language_column <- NULL
                english_column <- NULL
                for (col in available_columns) {
                  if (tolower(col) == tolower(language)) {
                    language_column <- col
                    if (verbose) message(paste("Direct language match found:", col))
                    break
                  }
                }
                if (is.null(language_column)) {
                  lang_code <- sub("^([a-z]+)_.*$", "\\1", tolower(language))
                  if (verbose) message(paste("Trying to match by language code:", lang_code))
                  for (col in available_columns) {
                    col_lang_code <- sub("^([a-z]+)_.*$", "\\1", tolower(col))
                    if (col_lang_code == lang_code) {
                      language_column <- col
                      if (verbose) message(paste("Matched language by code:", lang_code, "->", col))
                      break
                    }
                  }
                }
                if ("en_US.UTF-8" %in% available_columns) {
                  english_column <- "en_US.UTF-8"
                } else if ("English" %in% available_columns) {
                  english_column <- "English"
                } else {
                  english_column <- available_columns[1]
                }
                if (verbose) message(paste("Using", english_column, "as source column"))
                
                if (!is.null(language_column)) {
                  ui_dictionary <- setNames(param_data[[language_column]], param_data[[english_column]])
                  ui_dictionary <- ui_dictionary[!is.na(names(ui_dictionary)) & !is.na(ui_dictionary)]
                  
                  if (verbose && length(ui_dictionary) > 0) {
                    sample_keys <- head(names(ui_dictionary), 3)
                    for (key in sample_keys) {
                      message(paste("Sample translation:", key, "->", ui_dictionary[[key]]))
                    }
                  }
                  
                  assign("ui_dictionary", as.list(ui_dictionary), envir = .GlobalEnv)
                  
                  translate <- function(text, default_lang = "English") {
                    if (is.null(text)) return(text)
                    if (length(text) > 1) {
                      return(sapply(text, translate, default_lang = default_lang))
                    }
                    if (!exists("ui_dictionary") || !is.list(ui_dictionary) || length(ui_dictionary) == 0) {
                      if (verbose) message(paste("Dictionary unavailable for translation of:", text))
                      return(text)
                    }
                    tryCatch({
                      result <- ui_dictionary[[text]]
                      if (is.null(result)) {
                        text_lower <- tolower(text)
                        for (key in names(ui_dictionary)) {
                          if (tolower(key) == text_lower) {
                            result <- ui_dictionary[[key]]
                            break
                          }
                        }
                      }
                      if (is.null(result)) {
                        if (!exists("missing_translations")) {
                          assign("missing_translations", character(0), envir = .GlobalEnv)
                        }
                        if (!(text %in% missing_translations)) {
                          missing_translations <<- c(missing_translations, text)
                          if (verbose) message(paste("Missing translation for:", text))
                        }
                        return(text)
                      }
                      return(result)
                    }, error = function(e) {
                      message(paste("Error in translation:", e$message, "for text:", text))
                      return(text)
                    })
                  }
                  
                  assign("translate", translate, envir = .GlobalEnv)
                  
                  if (verbose) message(paste("Created translation function with", length(ui_dictionary), "terms"))
                  
                  check_locale_availability <- function() {
                    tryCatch({
                      system_locales <- system("locale -a", intern = TRUE)
                      expected_locales <- c("en_US.UTF-8", "zh_TW.UTF-8")
                      missing_locales <- expected_locales[!expected_locales %in% system_locales]
                      if (length(missing_locales) > 0) {
                        warning("Some configured locales are not available on the system: ", 
                                paste(missing_locales, collapse = ", "))
                      }
                      available_locales <- expected_locales[expected_locales %in% system_locales]
                      if (length(available_locales) == 0) {
                        warning("None of the expected locales are available on the system.")
                        if (verbose) {
                          message("Available locales: ", paste(head(system_locales, 10), collapse = ", "),
                                  if (length(system_locales) > 10) "..." else "")
                        }
                      }
                      return(available_locales)
                    }, error = function(e) {
                      warning("Error checking locales: ", e$message)
                      return(c("en_US.UTF-8", "zh_TW.UTF-8"))
                    })
                  }
                  
                  available_locales <- check_locale_availability()
                  assign("available_locales", available_locales, envir = .GlobalEnv)
                  if (verbose) message("Available locales: ", paste(available_locales, collapse = ", "))
                }
              }
            } else {
              # Generic dictionary creation for other parameter files
              english_col <- grep("english$|en$", names(param_data), value = TRUE)[1]
              lang_col <- grep(paste0(language, "$"), names(param_data), value = TRUE)[1]
              id_col <- grep("^id$|_id$", names(param_data), value = TRUE)[1]
              
              if (!is.na(english_col) && !is.na(lang_col) && !is.na(id_col)) {
                dict_name <- paste0(file_name, "_dictionary")
                dict_value <- as.list(setNames(param_data[[id_col]], param_data[[lang_col]]))
                assign(dict_name, dict_value, envir = .GlobalEnv)
                
                vec_name <- paste0(file_name, "_vec")
                assign(vec_name, unlist(dict_value), envir = .GlobalEnv)
              }
            }
            
            if (verbose) message(paste("   Successfully loaded", file_name))
          }, error = function(e) {
            warning(paste("Error loading parameter file", file_name, ":", e$message))
          })
        }
      }
    }
    
    return(config)
  }, error = function(e) {
    warning(paste("Error loading configuration:", e$message))
    return(list())
  })
}