################################################################################
# module_upload_complete_score.R - 上傳已完成評分的資料模組
# Created: 2025-09-16
# Purpose: 允許使用者上傳已經完成屬性評分的資料，並選擇對應欄位
################################################################################

library(shiny)
library(bs4Dash)
library(DT)
library(readxl)
library(dplyr)

#' Upload Complete Score Module - UI
#'
#' 允許使用者上傳已經完成屬性評分的資料，並選擇對應欄位
#' @param id Module namespace ID
uploadCompleteScoreUI <- function(id) {
  ns <- NS(id)

  div(id = ns("upload_complete_box"),
      box(
        title = "上傳已評分資料",
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        width = 12,

        # 評分資料上傳區
        div(
          h5("1.1 上傳產品屬性評分資料", style = "color: #007bff; font-weight: bold;"),
          div(
            class = "alert alert-info",
            icon("info-circle"),
            " 請上傳包含產品ID、產品名稱及各屬性評分的CSV或Excel檔案。",
            br(),
            tags$small("範例格式：product_id, product_name, 屬性1, 屬性2, ..., total_score, avg_score")
          ),

          fileInput(ns("score_file"),
                    "選擇屬性評分檔案",
                    multiple = FALSE,
                    accept = c(".xlsx", ".xls", ".csv"),
                    buttonLabel = "瀏覽...",
                    placeholder = "未選擇檔案"),

          # 欄位選擇區 - 評分資料
          conditionalPanel(
            condition = "output.score_file_uploaded == true",
            ns = ns,
            hr(),
            h5("1.2 選擇資料欄位", style = "color: #28a745; font-weight: bold;"),

            # 基本欄位選擇
            fluidRow(
              column(4,
                     selectInput(ns("product_id_col"),
                                 "產品ID欄位 (ASIN/SKU):",
                                 choices = NULL,
                                 selected = NULL)
              ),
              column(4,
                     selectInput(ns("product_name_col"),
                                 "產品名稱欄位:",
                                 choices = NULL,
                                 selected = NULL)
              ),
              column(4,
                     selectInput(ns("brand_col"),
                                 "品牌欄位 (選填):",
                                 choices = NULL,
                                 selected = NULL)
              )
            ),

            br(),
            h5("1.3 選擇屬性評分欄位", style = "color: #28a745; font-weight: bold;"),
            div(
              class = "well",
              style = "background-color: #f8f9fa; padding: 15px;",
              p("請勾選所有屬性評分欄位（數值型欄位）：", style = "font-weight: bold;"),
              p(tags$small("系統已自動識別可能的屬性欄位，請確認或調整選擇。")),
              uiOutput(ns("attribute_columns_ui"))
            )
          )
        )
      ),


      # 處理按鈕區
      box(
        width = 12,
        status = "info",
        div(
          style = "text-align: center; padding: 20px;",
          actionButton(ns("process_btn"),
                       "處理並預覽資料",
                       class = "btn-success btn-lg",
                       icon = icon("cogs"),
                       width = "300px"),
          br(), br(),
          uiOutput(ns("upload_msg"))
        )
      ),

      # 資料預覽區
      conditionalPanel(
        condition = "output.data_processed == true",
        ns = ns,
        box(
          title = "資料預覽",
          status = "success",
          solidHeader = TRUE,
          width = 12,

          tabsetPanel(
            tabPanel("評分資料",
                     br(),
                     div(
                       class = "info-box bg-info",
                       span(class = "info-box-icon", icon("table")),
                       div(class = "info-box-content",
                           span(class = "info-box-text", "資料摘要"),
                           verbatimTextOutput(ns("score_summary"))
                       )
                     ),
                     br(),
                     DTOutput(ns("score_preview"))
            ),
            tabPanel("屬性統計",
                     br(),
                     fluidRow(
                       column(6,
                              plotOutput(ns("attribute_distribution"), height = "400px")
                       ),
                       column(6,
                              plotOutput(ns("attribute_correlation"), height = "400px")
                       )
                     ),
                     br(),
                     plotOutput(ns("attribute_stats"), height = "400px")
            ),
            tabPanel("資料品質",
                     br(),
                     div(
                       class = "alert alert-info",
                       h4("資料品質檢查報告"),
                       hr(),
                       uiOutput(ns("data_quality_report"))
                     )
            )
          ),
          br(),
          div(
            style = "text-align: center;",
            actionButton(ns("confirm_data"),
                         "確認資料，進行下一步分析",
                         class = "btn-primary btn-lg",
                         icon = icon("arrow-right"),
                         width = "350px")
          )
        )
      )
  )
}

#' Upload Complete Score Module - Server
#'
#' @param id Module namespace ID
#' @param user_id User ID for tracking
uploadCompleteScoreServer <- function(id, user_id = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    values <- reactiveValues(
      score_data = NULL,
      score_columns = NULL,
      processed_score = NULL,
      attribute_columns = NULL,
      score_file_uploaded = FALSE,
      data_processed = FALSE,
      field_mapping = NULL
    )

    # 處理評分檔案上傳
    observeEvent(input$score_file, {
      req(input$score_file)

      tryCatch({
        # 讀取檔案
        file_ext <- tools::file_ext(input$score_file$datapath)
        if (file_ext %in% c("xlsx", "xls")) {
          values$score_data <- readxl::read_excel(input$score_file$datapath)
        } else if (file_ext == "csv") {
          # 嘗試不同的編碼
          values$score_data <- tryCatch(
            read.csv(input$score_file$datapath, stringsAsFactors = FALSE),
            error = function(e) {
              tryCatch(
                read.csv(input$score_file$datapath, stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8"),
                error = function(e2) {
                  read.csv(input$score_file$datapath, stringsAsFactors = FALSE,
                           fileEncoding = "Big5")
                }
              )
            }
          )
        }

        # 取得欄位名稱
        values$score_columns <- names(values$score_data)
        values$score_file_uploaded <- TRUE

        # 更新欄位選擇器 - 產品ID
        product_id_patterns <- c("product_id", "ASIN", "SKU", "asin", "sku",
                                 "產品ID", "產品編號", "商品編號")
        matched_id <- intersect(product_id_patterns, values$score_columns)
        updateSelectInput(session, "product_id_col",
                          choices = c("請選擇" = "", values$score_columns),
                          selected = if(length(matched_id) > 0) matched_id[1] else "")

        # 更新欄位選擇器 - 產品名稱
        product_name_patterns <- c("product_name", "name", "產品名稱", "商品名稱",
                                    "title", "Title", "產品", "商品")
        matched_name <- intersect(product_name_patterns, values$score_columns)
        updateSelectInput(session, "product_name_col",
                          choices = c("請選擇" = "", values$score_columns),
                          selected = if(length(matched_name) > 0) matched_name[1] else "")

        # 更新欄位選擇器 - 品牌
        brand_patterns <- c("brand", "Brand", "品牌", "variation", "Variation")
        matched_brand <- intersect(brand_patterns, values$score_columns)
        updateSelectInput(session, "brand_col",
                          choices = c("無" = "無", values$score_columns),
                          selected = if(length(matched_brand) > 0) matched_brand[1] else "無")

        showNotification(paste("評分檔案上傳成功！共", nrow(values$score_data), "筆資料"),
                         type = "message", duration = 3)

      }, error = function(e) {
        showNotification(paste("評分檔案讀取失敗:", e$message), type = "error", duration = 5)
      })
    })

    # 動態生成屬性欄位選擇器
    output$attribute_columns_ui <- renderUI({
      req(values$score_columns)

      # 找出可能的數值型欄位
      numeric_cols <- c()
      for (col in values$score_columns) {
        # 檢查是否為數值型欄位
        sample_values <- head(values$score_data[[col]], 100)
        # 移除NA值
        sample_values <- sample_values[!is.na(sample_values)]

        if (length(sample_values) > 0) {
          # 嘗試轉換為數值
          numeric_test <- suppressWarnings(as.numeric(sample_values))
          # 如果超過50%可以轉換為數值，則認為是數值型欄位
          if (sum(!is.na(numeric_test)) / length(sample_values) > 0.5) {
            numeric_cols <- c(numeric_cols, col)
          }
        }
      }

      # 排除明顯的ID、名稱和統計欄位
      exclude_patterns <- c("id", "ID", "name", "名稱", "title", "Title",
                            "total", "avg", "sum", "count", "mean", "std",
                            "brand", "Brand", "品牌", "ASIN", "SKU", "sku",
                            "score", "Score", "分數", "總分", "平均", "合計",
                            "total_score", "avg_score", "average", "總計")

      # 使用更智能的方式識別屬性欄位
      potential_attrs <- c()
      for (col in numeric_cols) {
        # 檢查是否符合排除模式
        is_excluded <- FALSE
        for (pattern in exclude_patterns) {
          if (grepl(pattern, col, ignore.case = TRUE)) {
            # 特殊處理：如果欄位名稱只包含中文，且包含"分"字，可能是屬性
            if (pattern %in% c("score", "Score", "分數") &&
                !grepl("^[a-zA-Z_]+", col) &&
                !grepl("total|avg|sum|mean", col, ignore.case = TRUE)) {
              # 這可能是屬性評分，不排除
            } else {
              is_excluded <- TRUE
              break
            }
          }
        }

        if (!is_excluded) {
          # 檢查數值範圍，屬性評分通常在0-10之間
          col_values <- suppressWarnings(as.numeric(values$score_data[[col]]))
          col_values <- col_values[!is.na(col_values)]
          if (length(col_values) > 0) {
            if (min(col_values) >= 0 && max(col_values) <= 100) {
              potential_attrs <- c(potential_attrs, col)
            }
          }
        }
      }

      # 生成checkbox群組，分組顯示
      div(
        style = "max-height: 300px; overflow-y: auto;",
        checkboxGroupInput(ns("selected_attributes"),
                           label = NULL,
                           choices = numeric_cols,
                           selected = potential_attrs,
                           inline = FALSE),
        hr(),
        div(
          class = "text-muted",
          tags$small(paste("已自動選擇", length(potential_attrs), "個可能的屬性欄位，",
                           "共有", length(numeric_cols), "個數值型欄位可選"))
        )
      )
    })


    # 處理資料
    observeEvent(input$process_btn, {
      req(values$score_data)
      req(input$product_id_col, input$product_name_col)

      # 檢查是否有選擇屬性欄位
      if (is.null(input$selected_attributes) || length(input$selected_attributes) == 0) {
        showNotification("請至少選擇一個屬性欄位！", type = "error", duration = 5)
        return()
      }

      tryCatch({
        # 處理評分資料
        score_cols <- c(input$product_id_col, input$product_name_col)
        if (!is.null(input$brand_col) && input$brand_col != "無" && input$brand_col != "") {
          score_cols <- c(score_cols, input$brand_col)
        }
        score_cols <- c(score_cols, input$selected_attributes)

        # 移除可能的重複欄位
        score_cols <- unique(score_cols)

        # 移除空值
        score_cols <- score_cols[!is.na(score_cols) & score_cols != ""]

        # 調試資訊
        cat("Debug - score_cols:", paste(score_cols, collapse = ", "), "\n")
        cat("Debug - available cols:", paste(names(values$score_data), collapse = ", "), "\n")

        # 檢查是否有欄位被選擇
        if (length(score_cols) == 0) {
          stop("沒有選擇任何欄位！請至少選擇產品ID、產品名稱和一個屬性欄位。")
        }

        # 確認所有選擇的欄位都存在
        available_cols <- names(values$score_data)
        missing_cols <- setdiff(score_cols, available_cols)
        if (length(missing_cols) > 0) {
          stop(paste("找不到以下欄位:", paste(missing_cols, collapse = ", "),
                     "\n可用欄位:", paste(head(available_cols, 20), collapse = ", ")))
        }

        # 安全地選擇欄位
        tryCatch({
          values$processed_score <- values$score_data[, score_cols, drop = FALSE]
        }, error = function(e) {
          stop(paste("選擇欄位時發生錯誤:", e$message,
                     "\n嘗試選擇的欄位:", paste(score_cols, collapse = ", ")))
        })

        # 確保屬性欄位是數值型
        for (col in input$selected_attributes) {
          if (col %in% names(values$processed_score)) {
            values$processed_score[[col]] <- as.numeric(values$processed_score[[col]])
          }
        }

        # 建立資料結構：
        # 1. Variation 欄位使用產品ID (ASIN/SKU)
        # 2. product_name 保留產品名稱
        # 3. brand 欄位存放品牌資訊（如果有選擇）

        # 先建立基本結構，使用產品ID作為Variation
        variation_data <- values$processed_score[[1]]  # 第一欄是產品ID
        product_name_data <- values$processed_score[[2]]  # 第二欄是產品名稱

        # 處理品牌欄位
        if (!is.null(input$brand_col) && input$brand_col != "無" && input$brand_col != "") {
          # 檢查品牌欄位來源
          if (input$brand_col == input$product_id_col) {
            # 如果品牌欄位選擇的是產品ID，複製產品ID
            brand_data <- variation_data
          } else if (input$brand_col == input$product_name_col) {
            # 如果品牌欄位選擇的是產品名稱，複製產品名稱
            brand_data <- product_name_data
          } else if (input$brand_col %in% input$selected_attributes) {
            # 如果品牌欄位是屬性欄位之一，取得該欄位資料
            brand_col_idx <- which(names(values$processed_score) == input$brand_col)
            brand_data <- values$processed_score[[brand_col_idx]]
          } else {
            # 品牌欄位是獨立選擇的欄位（在第3個位置）
            brand_data <- values$processed_score[[3]]
          }
        } else {
          # 如果沒有選擇品牌欄位，創建預設品牌
          brand_data <- rep("Default", nrow(values$processed_score))
        }

        # 重建資料框架
        # Variation使用產品ID，並新增brand欄位
        if (!is.null(input$brand_col) && input$brand_col != "無" && input$brand_col != "" &&
            !(input$brand_col %in% c(input$product_id_col, input$product_name_col, input$selected_attributes))) {
          # 品牌是獨立欄位，需要從原始資料中移除
          attr_start_idx <- 4
          attr_cols <- values$processed_score[, attr_start_idx:ncol(values$processed_score), drop = FALSE]
        } else {
          # 品牌是複製自其他欄位，保留所有屬性欄位
          attr_start_idx <- 3
          attr_cols <- values$processed_score[, attr_start_idx:ncol(values$processed_score), drop = FALSE]
        }

        # 組合最終資料框架
        values$processed_score <- cbind(
          Variation = variation_data,      # 使用產品ID作為Variation
          product_name = product_name_data, # 保留產品名稱
          brand = brand_data,               # 品牌資訊
          attr_cols                         # 所有屬性欄位
        )

        values$attribute_columns <- input$selected_attributes

        # 計算統計資訊
        attr_scores <- values$processed_score[, values$attribute_columns]
        values$processed_score$avg_score <- rowMeans(attr_scores, na.rm = TRUE)
        values$processed_score$total_score <- rowSums(attr_scores, na.rm = TRUE)

        # 儲存欄位映射資訊
        values$field_mapping <- list(
          score = list(
            product_id_col = input$product_id_col,
            product_name_col = input$product_name_col,
            brand_col = if(input$brand_col != "無") input$brand_col else NULL,
            selected_attributes = input$selected_attributes
          )
        )

        values$data_processed <- TRUE
        showNotification("資料處理成功！", type = "message", duration = 3)

      }, error = function(e) {
        showNotification(paste("資料處理失敗:", e$message), type = "error", duration = 5)
      })
    })

    # 輸出控制顯示
    output$score_file_uploaded <- reactive({ values$score_file_uploaded })
    output$data_processed <- reactive({ values$data_processed })
    outputOptions(output, "score_file_uploaded", suspendWhenHidden = FALSE)
    outputOptions(output, "data_processed", suspendWhenHidden = FALSE)

    # 評分資料預覽
    output$score_preview <- renderDT({
      req(values$processed_score)
      datatable(
        values$processed_score,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          language = list(
            url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese-traditional.json"
          )
        ),
        class = 'display nowrap'
      ) %>%
        formatRound(columns = c(values$attribute_columns, "avg_score"), digits = 2) %>%
        formatStyle(
          columns = values$attribute_columns,
          backgroundColor = styleInterval(c(3, 7), c('#ffcccc', '#ffffcc', '#ccffcc'))
        )
    })

    # 評分資料摘要
    output$score_summary <- renderPrint({
      req(values$processed_score)
      cat("產品數量:", nrow(values$processed_score), "\n")
      cat("屬性數量:", length(values$attribute_columns), "\n")
      cat("屬性名稱:", paste(values$attribute_columns[1:min(10, length(values$attribute_columns))],
                              collapse = ", "))
      if (length(values$attribute_columns) > 10) {
        cat("... 等共", length(values$attribute_columns), "個屬性")
      }
      cat("\n")
      cat("平均評分:", round(mean(values$processed_score$avg_score, na.rm = TRUE), 2), "\n")
      if ("Variation" %in% names(values$processed_score)) {
        cat("產品數量:", length(unique(values$processed_score$Variation)), "\n")
        cat("產品列表 (ASIN/SKU):", paste(head(unique(values$processed_score$Variation), 5), collapse = ", "))
        if (length(unique(values$processed_score$Variation)) > 5) {
          cat("...")
        }
        cat("\n")
      }
    })

    # 屬性統計圖表
    output$attribute_stats <- renderPlot({
      req(values$processed_score, values$attribute_columns)

      # 計算每個屬性的平均分
      attr_means <- colMeans(values$processed_score[, values$attribute_columns], na.rm = TRUE)
      attr_df <- data.frame(
        attribute = names(attr_means),
        mean_score = attr_means,
        stringsAsFactors = FALSE
      )

      # 排序
      attr_df <- attr_df[order(attr_df$mean_score, decreasing = TRUE), ]

      # 只顯示前20個屬性（如果超過20個）
      if (nrow(attr_df) > 20) {
        attr_df <- attr_df[1:20, ]
        title_text <- paste("前20個屬性平均評分（共", length(values$attribute_columns), "個屬性）")
      } else {
        title_text <- "各屬性平均評分"
      }

      # 繪製條形圖
      par(mar = c(8, 4, 3, 2), las = 2)
      colors <- colorRampPalette(c("#3498db", "#2ecc71"))(nrow(attr_df))
      bp <- barplot(
        attr_df$mean_score,
        names.arg = attr_df$attribute,
        col = colors,
        main = title_text,
        ylab = "平均分數",
        ylim = c(0, max(attr_df$mean_score) * 1.2),
        cex.names = 0.8
      )

      # 添加數值標籤
      text(bp, attr_df$mean_score, labels = round(attr_df$mean_score, 1),
           pos = 3, cex = 0.7)

      # 添加平均線
      abline(h = mean(attr_df$mean_score), col = "red", lty = 2, lwd = 2)
      legend("topright", paste("整體平均:", round(mean(attr_df$mean_score), 2)),
             lty = 2, col = "red", bty = "n")
    })

    # 屬性分布圖
    output$attribute_distribution <- renderPlot({
      req(values$processed_score, values$attribute_columns)

      # 準備數據
      attr_data <- values$processed_score[, values$attribute_columns]

      # 計算每個產品的平均分分布
      avg_scores <- rowMeans(attr_data, na.rm = TRUE)

      # 繪製直方圖
      hist(avg_scores,
           breaks = 20,
           col = "#3498db",
           border = "white",
           main = "產品平均評分分布",
           xlab = "平均評分",
           ylab = "產品數量",
           las = 1)

      # 添加密度曲線
      lines(density(avg_scores, na.rm = TRUE), col = "red", lwd = 2)

      # 添加垂直線標示平均值和中位數
      abline(v = mean(avg_scores, na.rm = TRUE), col = "darkgreen", lty = 2, lwd = 2)
      abline(v = median(avg_scores, na.rm = TRUE), col = "purple", lty = 2, lwd = 2)

      legend("topright",
             c(paste("平均:", round(mean(avg_scores, na.rm = TRUE), 2)),
               paste("中位數:", round(median(avg_scores, na.rm = TRUE), 2))),
             col = c("darkgreen", "purple"),
             lty = 2, lwd = 2, bty = "n")
    })

    # 屬性相關性熱圖
    output$attribute_correlation <- renderPlot({
      req(values$processed_score, values$attribute_columns)

      # 計算相關性矩陣
      attr_data <- values$processed_score[, values$attribute_columns]

      # 限制屬性數量以便視覺化
      if (length(values$attribute_columns) > 15) {
        # 選擇變異最大的15個屬性
        attr_vars <- apply(attr_data, 2, var, na.rm = TRUE)
        top_attrs <- names(sort(attr_vars, decreasing = TRUE)[1:15])
        attr_data <- attr_data[, top_attrs]
        title_text <- "屬性相關性熱圖（前15個高變異屬性）"
      } else {
        title_text <- "屬性相關性熱圖"
      }

      cor_matrix <- cor(attr_data, use = "complete.obs")

      # 繪製熱圖
      heatmap(cor_matrix,
              col = colorRampPalette(c("#3498db", "white", "#e74c3c"))(100),
              scale = "none",
              margins = c(10, 10),
              main = title_text,
              cexRow = 0.8,
              cexCol = 0.8)
    })

    # 資料品質報告
    output$data_quality_report <- renderUI({
      req(values$processed_score)

      # 計算資料品質指標
      total_cells <- nrow(values$processed_score) * length(values$attribute_columns)
      missing_cells <- sum(is.na(values$processed_score[, values$attribute_columns]))
      completeness <- round((1 - missing_cells / total_cells) * 100, 2)

      # 計算每個屬性的缺失率
      attr_missing <- sapply(values$attribute_columns, function(col) {
        sum(is.na(values$processed_score[[col]])) / nrow(values$processed_score) * 100
      })

      # 找出問題屬性
      high_missing_attrs <- names(attr_missing[attr_missing > 20])
      low_variance_attrs <- c()

      for (col in values$attribute_columns) {
        col_var <- var(values$processed_score[[col]], na.rm = TRUE)
        if (!is.na(col_var) && col_var < 0.1) {
          low_variance_attrs <- c(low_variance_attrs, col)
        }
      }

      # 生成報告
      tagList(
        tags$ul(
          tags$li(paste("資料完整性:", completeness, "%")),
          tags$li(paste("總資料點:", format(total_cells, big.mark = ","))),
          tags$li(paste("缺失資料點:", format(missing_cells, big.mark = ","))),
          tags$li(paste("產品數量:", nrow(values$processed_score))),
          tags$li(paste("屬性數量:", length(values$attribute_columns)))
        ),

        if (length(high_missing_attrs) > 0) {
          div(
            class = "alert alert-warning",
            h5("注意：以下屬性缺失率較高（>20%）"),
            tags$ul(
              lapply(high_missing_attrs, function(attr) {
                tags$li(paste(attr, ":", round(attr_missing[attr], 1), "% 缺失"))
              })
            )
          )
        },

        if (length(low_variance_attrs) > 0) {
          div(
            class = "alert alert-info",
            h5("提示：以下屬性變異性較低"),
            tags$ul(
              lapply(low_variance_attrs[1:min(5, length(low_variance_attrs))], function(attr) {
                tags$li(attr)
              })
            )
          )
        },

        if (completeness >= 90 && length(high_missing_attrs) == 0) {
          div(
            class = "alert alert-success",
            icon("check-circle"),
            " 資料品質良好，可以進行後續分析"
          )
        }
      )
    })

    # 錯誤訊息
    output$upload_msg <- renderUI({
      if (values$data_processed) {
        div(
          class = "alert alert-success",
          icon("check-circle"),
          " 資料處理完成，請檢視預覽結果並確認進行下一步"
        )
      }
    })

    # 返回處理後的資料和欄位映射資訊
    return(list(
      score_data = reactive({ values$processed_score }),
      attribute_columns = reactive({ values$attribute_columns }),
      data_ready = reactive({ values$data_processed }),
      confirm = reactive({ input$confirm_data }),
      field_mapping = reactive({ values$field_mapping }),
      # 新增：返回品牌資訊（如果有）
      has_brand = reactive({ "brand" %in% names(values$processed_score) }),
      brands = reactive({
        if ("brand" %in% names(values$processed_score)) {
          unique(values$processed_score$brand)
        } else {
          NULL
        }
      }),
      # 返回Variation資訊（產品ID）
      variations = reactive({
        if ("Variation" %in% names(values$processed_score)) {
          unique(values$processed_score$Variation)
        } else {
          NULL
        }
      })
    ))
  })
}