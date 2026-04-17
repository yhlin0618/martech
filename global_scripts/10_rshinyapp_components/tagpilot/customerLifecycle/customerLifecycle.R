# =============================================================================
# customerLifecycle.R — Customer Lifecycle (CLV) Prediction Component
# Migrated from L3 module_tagpilot_lifecycle.R → L4 enterprise pattern
# Following: UI_R001, UI_R011, MP064, MP029, DEV_R001, UX_P002
# =============================================================================

customerLifecycleComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- UI ----
  ui_filter <- tagList(
    ai_insight_button_ui(ns, translate)
  )

  ui_display <- tagList(
    # KPI Row
    fluidRow(
      column(3, uiOutput(ns("kpi_avg_clv"))),
      column(3, uiOutput(ns("kpi_high_clv"))),
      column(3, uiOutput(ns("kpi_avg_p_alive"))),
      column(3, uiOutput(ns("kpi_avg_expected_txn")))
    ),
    # CLV Distribution + P(alive) Distribution
    fluidRow(
      column(6, bs4Card(title = translate("CLV Distribution"), status = "primary",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("hist_clv"), height = "300px"))),
      column(6, bs4Card(title = translate("P(alive) Distribution"), status = "info",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("hist_p_alive"), height = "300px")))
    ),
    # CLV vs P(alive) Scatter
    fluidRow(
      column(12, bs4Card(title = translate("CLV vs P(alive) Matrix"), status = "success",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("scatter_clv_palive"), height = "380px")))
    ),
    # Rescue List (high CLV + low P(alive))
    fluidRow(
      column(12, bs4Card(title = translate("Rescue Priority List"), status = "danger",
        width = 12, solidHeader = TRUE,
        tags$p(class = "text-muted", translate("High value customers with low survival probability — prioritize retention efforts")),
        DT::dataTableOutput(ns("rescue_table"))))
    ),
    # Full Detail Table
    fluidRow(
      column(12, bs4Card(title = translate("Lifecycle Prediction Detail"), status = "primary",
        width = 12, solidHeader = TRUE,
        downloadButton(ns("download_csv"), translate("Download CSV"), class = "btn-sm btn-outline-primary mb-2"),
        DT::dataTableOutput(ns("detail_table"))))
    ),
    # AI Insight Result — bottom of display (GUIDE03)
    fluidRow(
      column(12, ai_insight_result_ui(ns, translate))
    )
  )

  # ---- Server ----
  server_fn <- function(input, output, session) {
    moduleServer(id, function(input, output, session) {

      dna_data <- reactive({
        cfg <- comp_config()
        req(cfg$filters$platform_id)
        tryCatch({
          pl_id <- cfg$filters$product_line_id_sliced
          if (is.null(pl_id) || pl_id == "all") pl_id <- "all"
          sql <- "SELECT * FROM df_dna_by_customer WHERE platform_id = ? AND product_line_id_filter = ?"
          df <- DBI::dbGetQuery(app_connection, sql, params = list(cfg$filters$platform_id, pl_id))
          if (nrow(df) == 0) { message("[customerLifecycle] No data"); return(NULL) }
          message("[customerLifecycle] Loaded ", nrow(df), " records")
          df
        }, error = function(e) { message("[customerLifecycle] Error: ", e$message); NULL })
      })

      # KPI: Average CLV
      output$kpi_avg_clv <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else paste0("$", format(round(mean(df$clv, na.rm = TRUE), 0), big.mark = ","))
        bs4ValueBox(value = val, subtitle = translate("Avg CLV"),
                    icon = icon("gem"), color = "primary", width = 12)
      })

      # KPI: High CLV customers (top 20%)
      output$kpi_high_clv <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("High CLV Customers"), icon = icon("crown"), color = "success", width = 12))
        vals <- df$clv[!is.na(df$clv)]
        if (length(vals) < 3) return(bs4ValueBox(value = "-", subtitle = translate("High CLV Customers"), icon = icon("crown"), color = "success", width = 12))
        p80 <- quantile(vals, 0.8)
        n <- sum(df$clv >= p80, na.rm = TRUE)
        bs4ValueBox(value = format(n, big.mark = ","), subtitle = translate("High CLV Customers"),
                    icon = icon("crown"), color = "success", width = 12)
      })

      # KPI: Average P(alive)
      output$kpi_avg_p_alive <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else paste0(round(mean(df$p_alive, na.rm = TRUE) * 100, 1), "%")
        bs4ValueBox(value = val, subtitle = translate("Avg Survival Rate"),
                    icon = icon("heartbeat"), color = "info", width = 12)
      })

      # KPI: Average expected transactions
      output$kpi_avg_expected_txn <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else round(mean(df$btyd_expected_transactions, na.rm = TRUE), 1)
        bs4ValueBox(value = val, subtitle = translate("Avg Expected Transactions"),
                    icon = icon("shopping-bag"), color = "warning", width = 12)
      })

      # Histogram: CLV distribution
      output$hist_clv <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        vals <- df$clv[!is.na(df$clv)]
        if (length(vals) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        plotly::plot_ly(x = vals, type = "histogram",
                        marker = list(color = "#007bff", line = list(color = "white", width = 1))) %>%
          plotly::layout(xaxis = list(title = translate("CLV")), yaxis = list(title = translate("Customer Count")),
                         margin = list(t = 10, b = 50))
      })

      # Histogram: P(alive) distribution
      output$hist_p_alive <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        vals <- df$p_alive[!is.na(df$p_alive)]
        if (length(vals) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        plotly::plot_ly(x = vals, type = "histogram",
                        marker = list(color = "#17a2b8", line = list(color = "white", width = 1))) %>%
          plotly::layout(xaxis = list(title = translate("P(alive)")), yaxis = list(title = translate("Customer Count")),
                         margin = list(t = 10, b = 50))
      })

      # Scatter: CLV vs P(alive) — quadrant matrix
      output$scatter_clv_palive <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        plot_df <- df[!is.na(df$clv) & !is.na(df$p_alive), ]
        if (nrow(plot_df) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))
        # Sample for large datasets
        if (nrow(plot_df) > 2000) plot_df <- plot_df[sample(nrow(plot_df), 2000), ]

        # Quadrant labels
        clv_med <- median(plot_df$clv, na.rm = TRUE)
        palive_med <- 0.5  # natural threshold
        plot_df$quadrant <- ifelse(plot_df$clv >= clv_med & plot_df$p_alive >= palive_med, "\u9ad8\u50f9\u503c\u9ad8\u5b58\u6d3b",
                             ifelse(plot_df$clv >= clv_med & plot_df$p_alive < palive_med, "\u9ad8\u50f9\u503c\u4f4e\u5b58\u6d3b",
                              ifelse(plot_df$clv < clv_med & plot_df$p_alive >= palive_med, "\u4f4e\u50f9\u503c\u9ad8\u5b58\u6d3b",
                                     "\u4f4e\u50f9\u503c\u4f4e\u5b58\u6d3b")))
        colors <- c("\u9ad8\u50f9\u503c\u9ad8\u5b58\u6d3b" = "#28a745",
                     "\u9ad8\u50f9\u503c\u4f4e\u5b58\u6d3b" = "#dc3545",
                     "\u4f4e\u50f9\u503c\u9ad8\u5b58\u6d3b" = "#17a2b8",
                     "\u4f4e\u50f9\u503c\u4f4e\u5b58\u6d3b" = "#6c757d")
        plotly::plot_ly(plot_df, x = ~p_alive, y = ~clv, color = ~quadrant,
                        colors = colors, type = "scatter", mode = "markers",
                        marker = list(size = 5, opacity = 0.6),
                        text = ~paste0("ID: ", customer_id, "\nCLV: $", round(clv, 0),
                                       "\nP(alive): ", round(p_alive, 3),
                                       "\nExpected Txn: ", round(btyd_expected_transactions, 1)),
                        hoverinfo = "text") %>%
          plotly::layout(
            xaxis = list(title = translate("P(alive)")),
            yaxis = list(title = translate("CLV")),
            shapes = list(
              list(type = "line", x0 = palive_med, x1 = palive_med, y0 = 0, y1 = 1, yref = "paper",
                   line = list(color = "#adb5bd", dash = "dash")),
              list(type = "line", x0 = 0, x1 = 1, xref = "paper", y0 = clv_med, y1 = clv_med,
                   line = list(color = "#adb5bd", dash = "dash"))
            ),
            margin = list(t = 10, b = 50)
          )
      })

      # Rescue table: high CLV + low P(alive)
      output$rescue_table <- DT::renderDataTable({
        df <- dna_data()
        if (is.null(df)) return(DT::datatable(data.frame(Message = translate("No Data"))))
        vals_clv <- df$clv[!is.na(df$clv)]
        if (length(vals_clv) < 3) return(DT::datatable(data.frame(Message = translate("No Data"))))
        clv_p80 <- quantile(vals_clv, 0.8)
        rescue <- df[!is.na(df$clv) & !is.na(df$p_alive) & df$clv >= clv_p80 & df$p_alive < 0.5, ]
        if (nrow(rescue) == 0) return(DT::datatable(data.frame(Message = translate("No high-value at-risk customers found"))))
        rescue <- rescue[order(rescue$p_alive), ]
        show_df <- data.frame(
          ID = rescue$customer_id,
          CLV = round(rescue$clv, 0),
          P_alive = round(rescue$p_alive, 3),
          Expected_Txn = round(rescue$btyd_expected_transactions, 1),
          Total_Spent = round(rescue$total_spent, 0),
          NES = rescue$nes_status,
          stringsAsFactors = FALSE
        )
        DT::datatable(show_df,
          colnames = c(translate("Customer ID"), translate("CLV"), translate("P(alive)"),
                       translate("Expected Transactions"), translate("Total Spent"), translate("NES")),
          rownames = FALSE,
          options = list(pageLength = 10, scrollX = TRUE, dom = "lftip",
                         language = list(url = "//cdn.datatables.net/plug-ins/1.13.7/i18n/zh-HANT.json")))
      })

      # Full detail table
      output$detail_table <- DT::renderDataTable({
        df <- dna_data()
        if (is.null(df)) return(DT::datatable(data.frame(Message = translate("No Data"))))
        show_df <- data.frame(
          ID = df$customer_id,
          CLV = round(df$clv, 0),
          PCV = round(df$pcv, 2),
          P_alive = round(df$p_alive, 3),
          Expected_Txn = round(df$btyd_expected_transactions, 1),
          Total_Spent = round(df$total_spent, 0),
          Tenure = round(df$time_first_to_now, 0),
          Purchases = df$nt,
          stringsAsFactors = FALSE
        )
        show_df <- show_df[order(-show_df$CLV, na.last = TRUE), ]
        DT::datatable(show_df,
          colnames = c(translate("Customer ID"), translate("CLV"), translate("PCV"), translate("P(alive)"),
                       translate("Expected Transactions"), translate("Total Spent"),
                       translate("Tenure (days)"), translate("Total Purchases")),
          filter = "top", rownames = FALSE,
          options = list(pageLength = 15, scrollX = TRUE, dom = "lftip",
                         language = list(url = "//cdn.datatables.net/plug-ins/1.13.7/i18n/zh-HANT.json")))
      })

      # AI Insight — non-blocking via ExtendedTask (GUIDE03, TD_P004 compliant)
      gpt_key <- Sys.getenv("OPENAI_API_KEY", "")
      ai_task <- create_ai_insight_task(gpt_key)

      setup_ai_insight_server(
        input, output, session, ns,
        task = ai_task,
        gpt_key = gpt_key,
        prompt_key = "customer_analysis.lifecycle_insights",
        get_template_vars = function() {
          df <- dna_data()
          if (is.null(df) || nrow(df) == 0) return(NULL)

          clv_vals <- df$clv[!is.na(df$clv)]
          palive_vals <- df$p_alive[!is.na(df$p_alive)]
          btyd_vals <- df$btyd_expected_transactions[!is.na(df$btyd_expected_transactions)]

          # Rescue count: high CLV + low P(alive)
          clv_p80 <- if (length(clv_vals) >= 3) stats::quantile(clv_vals, 0.8) else Inf
          rescue_n <- sum(!is.na(df$clv) & !is.na(df$p_alive) & df$clv >= clv_p80 & df$p_alive < 0.5)

          list(
            total_customers = as.character(nrow(df)),
            clv_distribution = paste0(
              "Avg CLV: $", format(round(mean(clv_vals), 0), big.mark = ","), "\n",
              "Median CLV: $", format(round(stats::median(clv_vals), 0), big.mark = ","), "\n",
              "P80 CLV: $", format(round(stats::quantile(clv_vals, 0.8), 0), big.mark = ","), "\n",
              "High CLV customers (top 20%): ", sum(clv_vals >= clv_p80)
            ),
            survival_summary = paste0(
              "Avg P(alive): ", round(mean(palive_vals), 3), "\n",
              "Median P(alive): ", round(stats::median(palive_vals), 3), "\n",
              "Low survival (<0.5): ", sum(palive_vals < 0.5), " customers (",
              round(sum(palive_vals < 0.5) / length(palive_vals) * 100, 1), "%)"
            ),
            btyd_predictions = paste0(
              "Avg expected transactions: ", round(mean(btyd_vals), 2), "\n",
              "Rescue priority (high CLV + low P(alive)): ", rescue_n, " customers"
            )
          )
        },
        component_label = "customerLifecycle"
      )

      # CSV download
      output$download_csv <- downloadHandler(
        filename = function() paste0("customer_lifecycle_clv_", Sys.Date(), ".csv"),
        content = function(file) {
          df <- dna_data()
          if (!is.null(df)) {
            export <- data.frame(
              customer_id = df$customer_id,
              clv = round(df$clv, 2), pcv = round(df$pcv, 2),
              p_alive = round(df$p_alive, 3),
              btyd_expected_transactions = round(df$btyd_expected_transactions, 2),
              total_spent = round(df$total_spent, 0),
              time_first_to_now = round(df$time_first_to_now, 0),
              nt = df$nt, nes_status = df$nes_status,
              stringsAsFactors = FALSE
            )
            export <- export[order(-export$clv, na.last = TRUE), ]
            con <- file(file, "w", encoding = "UTF-8")
            writeChar("\ufeff", con, eos = NULL)
            close(con)
            # write.table (NOT write.csv) — write.csv ignores append=TRUE (DEV_R051)
            utils::write.table(export, file, row.names = FALSE, sep = ",",
                               quote = TRUE, append = TRUE, fileEncoding = "UTF-8")
          }
        }
      )

    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
