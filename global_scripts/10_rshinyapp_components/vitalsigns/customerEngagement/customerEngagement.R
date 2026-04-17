# =============================================================================
# customerEngagement.R — Customer Engagement Component (VitalSigns)
# CONSUMES: df_dna_by_customer (from D01)
# Following: UI_R001, UI_R011, MP064, MP029, DEV_R001
# =============================================================================

customerEngagementComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- UI ----
  ui_filter <- tagList(
    ai_insight_button_ui(ns, translate)
  )

  ui_display <- tagList(
    # KPI Row
    fluidRow(
      column(3, uiOutput(ns("kpi_cai"))),
      column(3, uiOutput(ns("kpi_freq"))),
      column(3, uiOutput(ns("kpi_ipt"))),
      column(3, uiOutput(ns("kpi_reactivation")))
    ),
    # Charts Row 1
    fluidRow(
      column(6, bs4Card(title = translate("Activity Scatter (CAI vs Spending)"), status = "primary",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("activity_scatter"), height = "320px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("activity_scatter_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("activity_scatter_x")),
            tags$li(translate("activity_scatter_y")),
            tags$li(translate("activity_scatter_color")),
            tags$li(translate("activity_scatter_size"))
          ),
          tags$p(translate("activity_scatter_ideal"), style = "font-style: italic; color: #666;")
        )
      )),
      column(6, bs4Card(title = translate("Conversion Funnel"), status = "success",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("funnel_chart"), height = "320px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("funnel_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("funnel_first")),
            tags$li(translate("funnel_second")),
            tags$li(translate("funnel_regular")),
            tags$li(translate("funnel_loyal"))
          ),
          tags$p(translate("funnel_note"), style = "font-style: italic; color: #666;")
        )
      ))
    ),
    # Charts Row 2
    fluidRow(
      column(6, bs4Card(title = translate("Purchase Pattern (Freq vs IPT)"), status = "info",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("pattern_scatter"), height = "320px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("patterns_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("patterns_x")),
            tags$li(translate("patterns_y")),
            tags$li(translate("patterns_size")),
            tags$li(translate("patterns_color"))
          ),
          tags$p(translate("patterns_ideal"), style = "font-style: italic; color: #666;")
        )
      )),
      column(6, bs4Card(title = translate("Reactivation Opportunity"), status = "warning",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("reactivation_bar"), height = "320px"),
        tags$br(),
        tags$div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px;",
          tags$h6(translate("Chart Interpretation"), style = "color: #2c3e50; font-weight: bold;"),
          tags$p(translate("reactivation_desc"), style = "margin-bottom: 5px;"),
          tags$ul(
            tags$li(translate("reactivation_status")),
            tags$li(translate("reactivation_count")),
            tags$li(translate("reactivation_use"))
          ),
          tags$p(translate("reactivation_priority"), style = "font-style: italic; color: #666;")
        )
      ))
    ),
    # Loyalty Ladder
    fluidRow(
      column(12, bs4Card(title = translate("Loyalty Ladder"), status = "primary",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("loyalty_ladder"), height = "300px")))
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
            "SELECT d.customer_id, d.cai_value, d.f_value, d.m_value, d.total_spent AS spent_total,",
            " d.ipt_mean, d.ni AS ni_count, d.nes_status, d.r_value, d.nrec_prob",
            " FROM df_dna_by_customer d",
            country_join,
            " WHERE d.platform_id = '", cfg$filters$platform_id, "'",
            if (!is.null(cfg$filters$product_line_id_sliced) && cfg$filters$product_line_id_sliced != "all")
              paste0(" AND d.product_line_id_filter = '", cfg$filters$product_line_id_sliced, "'")
            else " AND d.product_line_id_filter = 'all'"
          ))
          if (nrow(df) == 0) { message("[customerEngagement] No data returned"); return(NULL) }
          message("[customerEngagement] Loaded ", nrow(df), " records | cols: ", paste(names(df), collapse=", "))
          message("[customerEngagement] UI targets: kpi_cai, kpi_freq, kpi_ipt, kpi_reactivation, activity_scatter, funnel_chart, pattern_scatter, reactivation_bar, loyalty_ladder")
          df
        }, error = function(e) {
          message("[customerEngagement] Data load error: ", e$message)
          NULL
        })
      })

      # KPIs
      output$kpi_cai <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else round(mean(df$cai_value, na.rm = TRUE), 2)
        bs4ValueBox(value = val, subtitle = translate("Avg CAI"),
                    icon = icon("heartbeat"), color = "primary", width = 12)
      })

      output$kpi_freq <- renderUI({
        df <- dna_data()
        val <- if (is.null(df)) "-" else round(mean(df$f_value, na.rm = TRUE), 1)
        bs4ValueBox(value = val, subtitle = translate("Avg Purchase Frequency"),
                    icon = icon("shopping-cart"), color = "info", width = 12)
      })

      output$kpi_ipt <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Avg Inter-Purchase Time"),
                                            icon = icon("clock"), color = "warning", width = 12))
        ipt_vals <- df$ipt_mean[!is.na(df$ipt_mean) & df$ni_count > 1]
        val <- if (length(ipt_vals) > 0) paste0(round(mean(ipt_vals), 1), " ", translate("days")) else "-"
        bs4ValueBox(value = val, subtitle = translate("Avg Inter-Purchase Time"),
                    icon = icon("clock"), color = "warning", width = 12)
      })

      output$kpi_reactivation <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Reactivation Opportunity"),
                                            icon = icon("redo"), color = "danger", width = 12))
        n_sleeping <- sum(df$nes_status %in% c("S1", "S2", "S3"), na.rm = TRUE)
        pct <- round(n_sleeping / nrow(df) * 100, 1)
        bs4ValueBox(value = paste0(n_sleeping, " (", pct, "%)"),
                    subtitle = translate("Reactivation Opportunity"),
                    icon = icon("redo"), color = "danger", width = 12)
      })

      # Activity scatter: CAI vs Total Spent, size = frequency
      output$activity_scatter <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        df_plot <- df[!is.na(df$cai_value) & !is.na(df$spent_total), ]
        if (nrow(df_plot) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("Insufficient Data")))

        plotly::plot_ly(df_plot, x = ~cai_value, y = ~spent_total, type = "scatter", mode = "markers",
                        marker = list(size = ~pmin(f_value * 2, 20), opacity = 0.6,
                                      color = ~f_value, colorscale = "Viridis", showscale = TRUE,
                                      colorbar = list(title = translate("Frequency"))),
                        text = ~paste0("ID:", customer_id, "\nCAI:", round(cai_value, 2),
                                       "\nSpent:", round(spent_total, 0))) %>%
          plotly::layout(
            xaxis = list(title = translate("Customer Activity Index (CAI)")),
            yaxis = list(title = translate("Total Spent"))
          )
      })

      # Conversion funnel
      output$funnel_chart <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        n1 <- sum(df$ni_count >= 1, na.rm = TRUE)
        n2 <- sum(df$ni_count >= 2, na.rm = TRUE)
        n34 <- sum(df$ni_count >= 3 & df$ni_count <= 4, na.rm = TRUE) + sum(df$ni_count >= 2 & df$ni_count < 3, na.rm = TRUE)
        n3_4 <- sum(df$ni_count >= 3, na.rm = TRUE)
        n5plus <- sum(df$ni_count >= 5, na.rm = TRUE)

        funnel_df <- data.frame(
          stage = c(translate("1 purchase"),
                    translate("2 purchases"),
                    translate("3-4 purchases"),
                    translate("5+ purchases")),
          count = c(n1, n2, n3_4, n5plus),
          stringsAsFactors = FALSE
        )
        funnel_df$stage <- factor(funnel_df$stage, levels = rev(funnel_df$stage))

        plotly::plot_ly(funnel_df, y = ~stage, x = ~count, type = "bar", orientation = "h",
                        marker = list(color = c("#007bff", "#17a2b8", "#28a745", "#dc3545")),
                        text = ~paste0(count, " (", round(count / n1 * 100, 1), "%)"),
                        textposition = "auto") %>%
          plotly::layout(xaxis = list(title = translate("Customer Count")),
                         yaxis = list(title = ""))
      })

      # Purchase pattern scatter: Frequency vs IPT
      output$pattern_scatter <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        df_plot <- df[!is.na(df$ipt_mean) & df$ni_count > 1, ]
        if (nrow(df_plot) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("Insufficient Data")))

        plotly::plot_ly(df_plot, x = ~f_value, y = ~ipt_mean, type = "scatter", mode = "markers",
                        marker = list(size = 6, opacity = 0.5, color = "#17a2b8"),
                        text = ~paste0("ID:", customer_id, "\nF:", f_value, "\nIPT:", round(ipt_mean, 1), " ", translate("days"))) %>%
          plotly::layout(
            xaxis = list(title = translate("Purchase Frequency")),
            yaxis = list(title = translate("Avg Inter-Purchase Time (days)"))
          )
      })

      # Reactivation opportunity: S1/S2/S3 counts
      output$reactivation_bar <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        sleeping <- df[df$nes_status %in% c("S1", "S2", "S3"), ]
        if (nrow(sleeping) == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Sleeping Customers")))

        tbl <- as.data.frame(table(sleeping$nes_status), stringsAsFactors = FALSE)
        names(tbl) <- c("status", "count")
        labels <- c(S1 = translate("Drowsy"), S2 = translate("Half-Sleeping"), S3 = translate("Dormant"))
        tbl$label <- labels[tbl$status]
        colors <- c(S1 = "#ffc107", S2 = "#fd7e14", S3 = "#dc3545")

        plotly::plot_ly(tbl, x = ~label, y = ~count, type = "bar",
                        marker = list(color = colors[tbl$status]),
                        text = ~count, textposition = "outside") %>%
          plotly::layout(xaxis = list(title = ""), yaxis = list(title = translate("Customer Count")))
      })

      # AI Insight — non-blocking via ExtendedTask (GUIDE03, TD_P004 compliant)
      gpt_key <- Sys.getenv("OPENAI_API_KEY", "")
      ai_task <- create_ai_insight_task(gpt_key)

      setup_ai_insight_server(
        input, output, session, ns,
        task = ai_task,
        gpt_key = gpt_key,
        prompt_key = "vitalsigns_analysis.engagement_insights",
        get_template_vars = function() {
          df <- dna_data()
          if (is.null(df) || nrow(df) == 0) return(NULL)

          n <- nrow(df)
          cai_vals <- df$cai_value[!is.na(df$cai_value)]
          ipt_vals <- df$ipt_mean[!is.na(df$ipt_mean) & df$ni_count > 1]
          n_sleeping <- sum(df$nes_status %in% c("S1", "S2", "S3"), na.rm = TRUE)

          list(
            total_customers = as.character(n),
            engagement_summary = paste0(
              "Avg CAI: ", round(mean(cai_vals), 3), "\n",
              "Median CAI: ", round(stats::median(cai_vals), 3), "\n",
              "Avg purchase frequency: ", round(mean(df$f_value, na.rm = TRUE), 1), " times\n",
              "Avg total spent: $", format(round(mean(df$spent_total, na.rm = TRUE), 0), big.mark = ",")
            ),
            purchase_pattern = paste0(
              "Avg inter-purchase time: ", if (length(ipt_vals) > 0) paste0(round(mean(ipt_vals), 0), " days") else "N/A", "\n",
              "Median IPT: ", if (length(ipt_vals) > 0) paste0(round(stats::median(ipt_vals), 0), " days") else "N/A"
            ),
            loyalty_ladder = paste0(
              "One-time: ", sum(df$ni_count == 1, na.rm = TRUE), " (", round(sum(df$ni_count == 1, na.rm = TRUE) / n * 100, 1), "%)\n",
              "Repeat (2-3): ", sum(df$ni_count >= 2 & df$ni_count <= 3, na.rm = TRUE), "\n",
              "Regular (4-6): ", sum(df$ni_count >= 4 & df$ni_count <= 6, na.rm = TRUE), "\n",
              "Loyal (7-12): ", sum(df$ni_count >= 7 & df$ni_count <= 12, na.rm = TRUE), "\n",
              "VIP (13+): ", sum(df$ni_count > 12, na.rm = TRUE)
            ),
            reactivation_summary = paste0(
              "Sleeping customers (S1+S2+S3): ", n_sleeping, " (", round(n_sleeping / n * 100, 1), "%)\n",
              "S1 (Drowsy): ", sum(df$nes_status == "S1", na.rm = TRUE), "\n",
              "S2 (Half-Sleeping): ", sum(df$nes_status == "S2", na.rm = TRUE), "\n",
              "S3 (Dormant): ", sum(df$nes_status == "S3", na.rm = TRUE)
            )
          )
        },
        component_label = "customerEngagement"
      )

      # Loyalty ladder
      output$loyalty_ladder <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        ladder <- data.frame(
          level = c(translate("One-time"), translate("Repeat"), translate("Regular"), translate("Loyal"), translate("VIP")),
          count = c(
            sum(df$ni_count == 1, na.rm = TRUE),
            sum(df$ni_count >= 2 & df$ni_count <= 3, na.rm = TRUE),
            sum(df$ni_count >= 4 & df$ni_count <= 6, na.rm = TRUE),
            sum(df$ni_count >= 7 & df$ni_count <= 12, na.rm = TRUE),
            sum(df$ni_count > 12, na.rm = TRUE)
          ),
          stringsAsFactors = FALSE
        )
        ladder$level <- factor(ladder$level, levels = rev(ladder$level))

        plotly::plot_ly(ladder, y = ~level, x = ~count, type = "bar", orientation = "h",
                        marker = list(color = c("#dc3545", "#fd7e14", "#ffc107", "#28a745", "#007bff")),
                        text = ~count, textposition = "auto") %>%
          plotly::layout(xaxis = list(title = translate("Customer Count")), yaxis = list(title = ""))
      })

    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
