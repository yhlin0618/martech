# =============================================================================
# revenuePulse.R — Revenue Pulse Component (VitalSigns)
# CONSUMES: df_dna_by_customer (from D01)
# Following: UI_R001, UI_R011, MP064, MP029, DEV_R001
# =============================================================================

revenuePulseComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- UI ----
  ui_filter <- tagList(
    ai_insight_button_ui(ns, translate)
  )

  ui_display <- tagList(
    # KPI Row
    fluidRow(
      column(3, uiOutput(ns("kpi_revenue"))),
      column(3, uiOutput(ns("kpi_arpu"))),
      column(3, uiOutput(ns("kpi_avg_clv"))),
      column(3, uiOutput(ns("kpi_consistency")))
    ),
    # Charts Row 1
    fluidRow(
      column(6, bs4Card(title = translate("AOV: New vs Core Customers"), status = "info",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("aov_bar"), height = "300px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("aov_bar_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("aov_bar_new")),
            tags$li(translate("aov_bar_core")),
            tags$li(translate("aov_bar_use"))
          )
        )
      )),
      column(6, bs4Card(title = translate("CLV Distribution"), status = "primary",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("clv_scatter"), height = "300px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("clv_scatter_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("clv_scatter_x")),
            tags$li(translate("clv_scatter_y")),
            tags$li(translate("clv_scatter_line"))
          ),
          tags$p(translate("clv_scatter_ideal"), style = "font-style: italic; color: #666;")
        )
      ))
    ),
    # Charts Row 2
    fluidRow(
      column(6, bs4Card(title = translate("Pareto 80/20 Curve"), status = "success",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("pareto_curve"), height = "300px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("pareto_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("pareto_x")),
            tags$li(translate("pareto_y")),
            tags$li(translate("pareto_line"))
          ),
          tags$p(translate("pareto_ideal"), style = "font-style: italic; color: #666;")
        )
      )),
      column(6, bs4Card(title = translate("Revenue Segment Distribution"), status = "warning",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("revenue_pie"), height = "300px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("revenue_pie_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("revenue_pie_segments")),
            tags$li(translate("revenue_pie_use"))
          ),
          tags$p(translate("revenue_pie_ideal"), style = "font-style: italic; color: #666;")
        )
      ))
    ),
    # Top Customers Table
    fluidRow(
      column(12, bs4Card(title = translate("Top Revenue Customers"), status = "primary",
        width = 12, solidHeader = TRUE,
        downloadButton(ns("download_csv"), translate("Download CSV"), class = "btn-sm btn-outline-primary mb-2"),
        DT::dataTableOutput(ns("top_table"))))
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
          country <- cfg$filters$country
          country_join <- ""
          if (!is.null(country) && country != "all") {
            country_join <- paste0(
              " INNER JOIN df_customer_country_map ccm",
              " ON d.customer_id = ccm.customer_id",
              " AND ccm.platform_id = '", cfg$filters$platform_id, "'",
              " AND ccm.ship_country = '", country, "'")
          }
          df <- DBI::dbGetQuery(app_connection, paste0(
            "SELECT d.customer_id, d.m_value, d.total_spent AS spent_total, d.clv AS clv_value, d.cri AS cri_value, d.nes_status, d.ni AS ni_count, d.f_value, d.r_value",
            " FROM df_dna_by_customer d",
            country_join,
            " WHERE d.platform_id = '", cfg$filters$platform_id, "'",
            if (!is.null(cfg$filters$product_line_id_sliced) && cfg$filters$product_line_id_sliced != "all")
              paste0(" AND d.product_line_id_filter = '", cfg$filters$product_line_id_sliced, "'")
            else " AND d.product_line_id_filter = 'all'"
          ))
          if (nrow(df) == 0) { message("[revenuePulse] No data returned"); return(NULL) }
          message("[revenuePulse] Loaded ", nrow(df), " records | cols: ", paste(names(df), collapse=", "))
          message("[revenuePulse] UI targets: kpi_revenue, kpi_arpu, kpi_avg_clv, kpi_consistency, aov_bar, clv_scatter, pareto_curve, revenue_pie, top_table")
          df
        }, error = function(e) {
          message("[revenuePulse] Data load error: ", e$message)
          NULL
        })
      })

      # KPIs
      output$kpi_revenue <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else paste0("$", format(round(sum(df$spent_total, na.rm = TRUE), 0), big.mark = ","))
        bs4ValueBox(value = val, subtitle = translate("Total Revenue"),
                    icon = icon("dollar-sign"), color = "success", width = 12)
      })

      output$kpi_arpu <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else paste0("$", format(round(mean(df$m_value, na.rm = TRUE), 0), big.mark = ","))
        bs4ValueBox(value = val, subtitle = translate("ARPU"),
                    icon = icon("user-tag"), color = "info", width = 12)
      })

      output$kpi_avg_clv <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else paste0("$", format(round(mean(df$clv_value, na.rm = TRUE), 0), big.mark = ","))
        bs4ValueBox(value = val, subtitle = translate("Avg CLV"),
                    icon = icon("gem"), color = "primary", width = 12)
      })

      output$kpi_consistency <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Transaction Consistency"),
                                            icon = icon("sync"), color = "warning", width = 12))
        cri_vals <- df$cri_value[!is.na(df$cri_value)]
        val <- if (length(cri_vals) > 0) paste0(round((1 - mean(cri_vals)) * 100, 1), "%") else "-"
        bs4ValueBox(value = val, subtitle = translate("Transaction Consistency"),
                    icon = icon("sync"), color = "warning", width = 12)
      })

      # AOV: New vs Core
      output$aov_bar <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        df$segment <- ifelse(df$nes_status == "N", translate("New"), translate("Core"))
        agg <- stats::aggregate(m_value ~ segment, data = df, FUN = mean, na.rm = TRUE)

        plotly::plot_ly(agg, x = ~segment, y = ~round(m_value, 0), type = "bar",
                        marker = list(color = c("#17a2b8", "#007bff")),
                        text = ~paste0("$", format(round(m_value, 0), big.mark = ",")),
                        textposition = "outside") %>%
          plotly::layout(yaxis = list(title = translate("Avg Order Value")),
                         xaxis = list(title = ""))
      })

      # CLV Scatter
      output$clv_scatter <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        p80 <- quantile(df$clv_value, 0.80, na.rm = TRUE)

        plotly::plot_ly(df, x = ~spent_total, y = ~clv_value, type = "scatter", mode = "markers",
                        marker = list(size = 5, opacity = 0.6,
                                      color = ifelse(df$clv_value > p80, "#dc3545", "#007bff")),
                        text = ~paste0("ID:", customer_id, "\nCLV:", round(clv_value, 0))) %>%
          plotly::layout(
            xaxis = list(title = translate("Total Spent")),
            yaxis = list(title = "CLV"),
            shapes = list(list(type = "line", y0 = p80, y1 = p80, x0 = 0, x1 = max(df$spent_total, na.rm = TRUE),
                               line = list(dash = "dash", color = "red")))
          )
      })

      # Pareto 80/20
      output$pareto_curve <- renderPlotly({
        df <- dna_data()
        if (is.null(df) || nrow(df) < 2) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        df <- df[order(-df$spent_total), ]
        df$cum_pct_customers <- seq_len(nrow(df)) / nrow(df) * 100
        df$cum_pct_revenue   <- cumsum(df$spent_total) / sum(df$spent_total, na.rm = TRUE) * 100

        plotly::plot_ly(df, x = ~cum_pct_customers, y = ~cum_pct_revenue,
                        type = "scatter", mode = "lines",
                        line = list(color = "#007bff", width = 2)) %>%
          plotly::add_trace(x = c(0, 100), y = c(0, 100), mode = "lines",
                            line = list(dash = "dash", color = "#adb5bd"), showlegend = FALSE) %>%
          plotly::layout(
            xaxis = list(title = translate("% Customers (cumulative)")),
            yaxis = list(title = translate("% Revenue (cumulative)")),
            shapes = list(
              list(type = "line", x0 = 20, x1 = 20, y0 = 0, y1 = 100,
                   line = list(dash = "dot", color = "#dc3545")),
              list(type = "line", x0 = 0, x1 = 100, y0 = 80, y1 = 80,
                   line = list(dash = "dot", color = "#dc3545"))
            ),
            showlegend = FALSE
          )
      })

      # Revenue segment pie
      output$revenue_pie <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        q <- quantile(df$spent_total, c(0.25, 0.5, 0.75), na.rm = TRUE)
        df$rev_seg <- ifelse(df$spent_total > q[3], translate("High"),
                      ifelse(df$spent_total > q[2], translate("Mid-High"),
                      ifelse(df$spent_total > q[1], translate("Mid-Low"), translate("Low"))))
        tbl <- as.data.frame(table(df$rev_seg), stringsAsFactors = FALSE)
        names(tbl) <- c("segment", "count")

        plotly::plot_ly(tbl, labels = ~segment, values = ~count, type = "pie",
                        marker = list(colors = c("#dc3545", "#ffc107", "#17a2b8", "#28a745")),
                        textinfo = "label+percent") %>%
          plotly::layout(showlegend = TRUE)
      })

      # Top customers table
      output$top_table <- DT::renderDataTable({
        df <- dna_data()
        if (is.null(df)) return(DT::datatable(data.frame(Message = translate("Please run ETL pipeline first"))))

        df <- df[order(-df$spent_total), ]
        top <- head(df, 50)
        show_df <- data.frame(
          Rank = seq_len(nrow(top)),
          ID = top$customer_id,
          Total_Spent = round(top$spent_total, 0),
          CLV = round(top$clv_value, 0),
          Frequency = top$f_value,
          NES = top$nes_status,
          stringsAsFactors = FALSE
        )
        names(show_df) <- c(translate("Rank"), "ID", translate("Total Spent"),
                            "CLV", translate("Frequency"), "NES")
        DT::datatable(show_df, rownames = FALSE,
          options = list(pageLength = 15, scrollX = TRUE,
                         language = list(url = "//cdn.datatables.net/plug-ins/1.13.7/i18n/zh-HANT.json")))
      })

      # AI Insight — non-blocking via ExtendedTask (GUIDE03, TD_P004 compliant)
      gpt_key <- Sys.getenv("OPENAI_API_KEY", "")
      ai_task <- create_ai_insight_task(gpt_key)

      setup_ai_insight_server(
        input, output, session, ns,
        task = ai_task,
        gpt_key = gpt_key,
        prompt_key = "vitalsigns_analysis.revenue_pulse_insights",
        get_template_vars = function() {
          df <- dna_data()
          if (is.null(df) || nrow(df) == 0) return(NULL)

          total_rev <- sum(df$spent_total, na.rm = TRUE)
          n <- nrow(df)
          df_sorted <- df[order(-df$spent_total), ]
          top20_pct <- round(sum(head(df_sorted, ceiling(n * 0.2))$spent_total) / total_rev * 100, 1)

          n_new <- sum(df$nes_status == "N", na.rm = TRUE)
          n_core <- sum(df$nes_status != "N", na.rm = TRUE)
          aov_new <- if (n_new > 0) round(mean(df$m_value[df$nes_status == "N"], na.rm = TRUE), 0) else 0
          aov_core <- if (n_core > 0) round(mean(df$m_value[df$nes_status != "N"], na.rm = TRUE), 0) else 0

          list(
            total_customers = as.character(n),
            revenue_summary = paste0(
              "Total revenue: $", format(round(total_rev, 0), big.mark = ","), "\n",
              "ARPU: $", format(round(mean(df$m_value, na.rm = TRUE), 0), big.mark = ","), "\n",
              "Avg CLV: $", format(round(mean(df$clv_value, na.rm = TRUE), 0), big.mark = ",")
            ),
            pareto_summary = paste0(
              "Top 20% customers contribute ", top20_pct, "% of total revenue\n",
              "Revenue concentration: ", ifelse(top20_pct > 80, "highly concentrated", ifelse(top20_pct > 60, "moderately concentrated", "well distributed"))
            ),
            aov_comparison = paste0(
              "New customer AOV: $", format(aov_new, big.mark = ","), "\n",
              "Core customer AOV: $", format(aov_core, big.mark = ","), "\n",
              "AOV gap: ", ifelse(aov_core > 0, paste0(round((aov_core - aov_new) / aov_core * 100, 1), "%"), "N/A")
            ),
            consistency_summary = paste0(
              "Avg CRI: ", round(mean(df$cri_value, na.rm = TRUE), 3), "\n",
              "Transaction consistency: ", round((1 - mean(df$cri_value, na.rm = TRUE)) * 100, 1), "%"
            )
          )
        },
        component_label = "revenuePulse"
      )

      output$download_csv <- downloadHandler(
        filename = function() paste0("revenue_pulse_", Sys.Date(), ".csv"),
        content = function(file) {
          df <- dna_data()
          if (!is.null(df)) {
            con <- file(file, "wb")
            writeBin(charToRaw("\xef\xbb\xbf"), con)
            close(con)
            utils::write.csv(df[order(-df$spent_total), ], file, row.names = FALSE,
                             fileEncoding = "UTF-8", append = TRUE)
          }
        }
      )
    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
