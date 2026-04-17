# =============================================================================
# customerRetention.R — Customer Retention Component (VitalSigns)
# CONSUMES: df_dna_by_customer (from D01)
# Following: UI_R001, UI_R011, MP064, MP029, DEV_R001
# =============================================================================

customerRetentionComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- UI ----
  ui_filter <- tagList(
    ai_insight_button_ui(ns, translate)
  )

  ui_display <- tagList(
    # KPI Row 1
    fluidRow(
      column(3, uiOutput(ns("kpi_retention"))),
      column(3, uiOutput(ns("kpi_churn"))),
      column(3, uiOutput(ns("kpi_at_risk"))),
      column(3, uiOutput(ns("kpi_core_ratio")))
    ),
    # KPI Row 2: NES counts
    fluidRow(
      column(2, uiOutput(ns("kpi_n"))),
      column(2, uiOutput(ns("kpi_e0"))),
      column(2, uiOutput(ns("kpi_s1"))),
      column(2, uiOutput(ns("kpi_s2"))),
      column(2, uiOutput(ns("kpi_s3"))),
      column(2, uiOutput(ns("kpi_dormant_pred")))
    ),
    # Charts
    fluidRow(
      column(6, bs4Card(title = translate("Customer Structure (NES)"), status = "primary",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("structure_bar"), height = "350px"))),
      column(6, bs4Card(title = translate("Churn Risk Analysis"), status = "danger",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("risk_stacked"), height = "350px")))
    ),
    # Strategy tabs
    fluidRow(
      column(12, bs4Card(title = translate("Retention Strategy by Status"), status = "success",
        width = 12, solidHeader = TRUE,
        tabsetPanel(
          tabPanel(translate("Retention Overview"), uiOutput(ns("tab_overview"))),
          tabPanel(translate("New Customer"), uiOutput(ns("tab_new"))),
          tabPanel(translate("Core Customer"), uiOutput(ns("tab_core"))),
          tabPanel(translate("Drowsy"), uiOutput(ns("tab_s1"))),
          tabPanel(translate("Half-Sleeping"), uiOutput(ns("tab_s2"))),
          tabPanel(translate("Dormant"), uiOutput(ns("tab_s3")))
        )
      ))
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
            "SELECT d.customer_id, d.nes_status, d.nrec_prob, d.be2 AS be2_prob, d.m_value, d.total_spent AS spent_total,",
            " d.ni AS ni_count, d.f_value, d.clv AS clv_value, d.cri AS cri_value, d.r_value",
            " FROM df_dna_by_customer d",
            country_join,
            " WHERE d.platform_id = '", cfg$filters$platform_id, "'",
            if (!is.null(cfg$filters$product_line_id_sliced) && cfg$filters$product_line_id_sliced != "all")
              paste0(" AND d.product_line_id_filter = '", cfg$filters$product_line_id_sliced, "'")
            else " AND d.product_line_id_filter = 'all'"
          ))
          if (nrow(df) == 0) { message("[customerRetention] No data returned"); return(NULL) }
          message("[customerRetention] Loaded ", nrow(df), " records | cols: ", paste(names(df), collapse=", "))
          message("[customerRetention] UI targets: kpi_retention, kpi_churn, kpi_at_risk, kpi_core_ratio, kpi_n/e0/s1/s2/s3/dormant_pred, structure_bar, risk_stacked, tab_overview/new/core/s1/s2/s3")
          df
        }, error = function(e) {
          message("[customerRetention] Data load error: ", e$message)
          NULL
        })
      })

      # NES counts helper
      nes_counts <- reactive({
        df <- dna_data()
        if (is.null(df)) return(list(N = 0, E0 = 0, S1 = 0, S2 = 0, S3 = 0, total = 0))
        list(
          N  = sum(df$nes_status == "N", na.rm = TRUE),
          E0 = sum(df$nes_status == "E0", na.rm = TRUE),
          S1 = sum(df$nes_status == "S1", na.rm = TRUE),
          S2 = sum(df$nes_status == "S2", na.rm = TRUE),
          S3 = sum(df$nes_status == "S3", na.rm = TRUE),
          total = nrow(df)
        )
      })

      # KPIs Row 1
      output$kpi_retention <- renderUI({
        nc <- nes_counts()
        active <- nc$N + nc$E0
        pct <- if (nc$total > 0) round(active / nc$total * 100, 1) else 0
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Retention Rate"),
                    icon = icon("user-check"), color = "success", width = 12)
      })

      output$kpi_churn <- renderUI({
        nc <- nes_counts()
        sleeping <- nc$S1 + nc$S2 + nc$S3
        pct <- if (nc$total > 0) round(sleeping / nc$total * 100, 1) else 0
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Churn Rate"),
                    icon = icon("user-minus"), color = "danger", width = 12)
      })

      output$kpi_at_risk <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("At-Risk Customers"),
                                            icon = icon("exclamation-triangle"), color = "warning", width = 12))
        n_risk <- sum(df$nrec_prob > 0.5, na.rm = TRUE)
        bs4ValueBox(value = n_risk, subtitle = translate("At-Risk Customers"),
                    icon = icon("exclamation-triangle"), color = "warning", width = 12)
      })

      output$kpi_core_ratio <- renderUI({
        nc <- nes_counts()
        pct <- if (nc$total > 0) round(nc$E0 / nc$total * 100, 1) else 0
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Core Customer Ratio"),
                    icon = icon("star"), color = "info", width = 12)
      })

      # KPIs Row 2: NES status counts
      render_nes_kpi <- function(status, label, color, icon_name) {
        renderUI({
          nc <- nes_counts()
          bs4ValueBox(value = nc[[status]], subtitle = label,
                      icon = icon(icon_name), color = color, width = 12)
        })
      }

      output$kpi_n  <- render_nes_kpi("N", translate("N (New)"), "info", "user-plus")
      output$kpi_e0 <- render_nes_kpi("E0", translate("E0 (Core)"), "success", "user-check")
      output$kpi_s1 <- render_nes_kpi("S1", translate("S1 (Drowsy)"), "warning", "moon")
      output$kpi_s2 <- render_nes_kpi("S2", translate("S2 (Half-Sleep)"), "orange", "bed")
      output$kpi_s3 <- render_nes_kpi("S3", translate("S3 (Dormant)"), "danger", "skull")
      output$kpi_dormant_pred <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Predicted Dormant"),
                                            icon = icon("chart-line"), color = "secondary", width = 12))
        n_pred <- sum(df$nrec_prob > 0.7, na.rm = TRUE)
        bs4ValueBox(value = n_pred, subtitle = translate("Predicted Dormant"),
                    icon = icon("chart-line"), color = "secondary", width = 12)
      })

      # Customer structure bar
      output$structure_bar <- renderPlotly({
        nc <- nes_counts()
        if (nc$total == 0) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        status_df <- data.frame(
          status = c("N", "E0", "S1", "S2", "S3"),
          label = c(translate("New"), translate("Core"), translate("Drowsy"),
                    translate("Half-Sleeping"), translate("Dormant")),
          count = c(nc$N, nc$E0, nc$S1, nc$S2, nc$S3),
          stringsAsFactors = FALSE
        )
        status_df$label <- factor(status_df$label, levels = status_df$label)
        colors <- c("#17a2b8", "#28a745", "#ffc107", "#fd7e14", "#dc3545")

        plotly::plot_ly(status_df, x = ~label, y = ~count, type = "bar",
                        marker = list(color = colors),
                        text = ~paste0(count, " (", round(count / nc$total * 100, 1), "%)"),
                        textposition = "outside") %>%
          plotly::layout(xaxis = list(title = ""), yaxis = list(title = translate("Customer Count")))
      })

      # Churn risk stacked bar
      output$risk_stacked <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        df$risk_level <- ifelse(
          is.na(df$nrec_prob), translate("Unknown"),
          ifelse(df$nrec_prob > 0.7, translate("High Risk"),
                 ifelse(df$nrec_prob > 0.3, translate("Medium Risk"), translate("Low Risk")))
        )

        tbl <- as.data.frame(table(df$nes_status, df$risk_level), stringsAsFactors = FALSE)
        names(tbl) <- c("NES", "Risk", "Count")

        risk_colors <- setNames(
          c("#28a745", "#ffc107", "#dc3545", "#adb5bd"),
          c(translate("Low Risk"), translate("Medium Risk"), translate("High Risk"), translate("Unknown"))
        )

        plotly::plot_ly(tbl, x = ~NES, y = ~Count, color = ~Risk, type = "bar",
                        colors = risk_colors) %>%
          plotly::layout(barmode = "stack",
                         xaxis = list(title = translate("Customer Status")),
                         yaxis = list(title = translate("Customer Count")))
      })

      # Load marketing strategies from YAML (DEV_R050: externalized display data)
      strategies_yaml <- tryCatch({
        yaml_path <- file.path(GLOBAL_DIR, "30_global_data", "parameters", "marketing_strategies.yaml")
        if (file.exists(yaml_path)) yaml::read_yaml(yaml_path)$strategies else NULL
      }, error = function(e) { message("[customerRetention] YAML load: ", e$message); NULL })

      # Rich strategy tab renderer
      render_rich_tab <- function(title, subtitle, metrics_fn, strategy_keys) {
        renderUI({
          df <- dna_data()
          if (is.null(df)) return(tags$p(translate("No data available")))
          metrics <- metrics_fn(df)

          strategy_cards <- if (!is.null(strategies_yaml)) {
            lapply(strategy_keys, function(key) {
              s <- strategies_yaml[[key]]
              if (is.null(s)) return(NULL)
              rec_html <- gsub("<br>\\s*", "<br>", s$recommendation)
              tags$div(class = "card mb-3",
                tags$div(class = "card-header bg-light",
                  tags$strong(key), tags$span(class = "badge bg-info ms-2 ml-2", s$purpose)
                ),
                tags$div(class = "card-body", tags$p(HTML(rec_html)))
              )
            })
          }

          tags$div(
            tags$h5(title),
            tags$p(class = "text-muted", subtitle),
            tags$div(class = "row mb-3",
              lapply(metrics, function(m) {
                tags$div(class = "col-auto",
                  tags$div(class = "border rounded p-2 text-center",
                    tags$strong(m$value), tags$br(), tags$small(class = "text-muted", m$label)
                  ))
              })
            ),
            if (length(strategy_cards) > 0) tagList(
              tags$h6(class = "mt-3", icon("bullhorn"), " ", translate("Marketing Strategy")),
              tagList(strategy_cards)
            )
          )
        })
      }

      output$tab_overview <- render_rich_tab(
        translate("Retention Analysis Overview"),
        translate("Overall customer retention status and key metrics"),
        function(df) {
          nc <- nes_counts()
          active <- nc$N + nc$E0
          sleeping <- nc$S1 + nc$S2 + nc$S3
          list(
            list(value = format(nc$total, big.mark = ","), label = translate("Total Customers")),
            list(value = paste0(round(active / max(nc$total, 1) * 100, 1), "%"), label = translate("Retention Rate")),
            list(value = format(sleeping, big.mark = ","), label = translate("At-Risk Customers")),
            list(value = round(mean(df$nrec_prob, na.rm = TRUE), 3), label = translate("Avg Churn Prob")),
            list(value = sum(df$nrec_prob > 0.7, na.rm = TRUE), label = translate("High Churn Risk")),
            list(value = paste0("$", format(round(mean(df$clv_value, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg CLV"))
          )
        },
        character(0)
      )

      output$tab_new <- render_rich_tab(
        translate("New Customer Strategy"),
        translate("Convert one-time buyers into repeat customers — key period for building loyalty"),
        function(df) {
          new_df <- df[df$nes_status == "N", ]
          list(
            list(value = format(nrow(new_df), big.mark = ","), label = translate("New Customers")),
            list(value = paste0(round(nrow(new_df) / max(nrow(df), 1) * 100, 1), "%"), label = translate("% of Total")),
            list(value = paste0("$", format(round(mean(new_df$m_value, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg Spend")),
            list(value = round(mean(new_df$nrec_prob, na.rm = TRUE), 3), label = translate("Avg Churn Prob"))
          )
        },
        c("New Customer Nurturing")
      )

      output$tab_core <- render_rich_tab(
        translate("Core Customer Deepening"),
        translate("Strengthen relationships and increase lifetime value of active customers"),
        function(df) {
          core_df <- df[df$nes_status == "E0", ]
          list(
            list(value = format(nrow(core_df), big.mark = ","), label = translate("Core Customers")),
            list(value = paste0("$", format(round(mean(core_df$clv_value, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg CLV")),
            list(value = paste0("$", format(round(mean(core_df$spent_total, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg Total Spent")),
            list(value = round(mean(core_df$f_value, na.rm = TRUE), 1), label = translate("Avg Frequency"))
          )
        },
        c("Standard Nurturing (Core)", "Standard Nurturing (Advanced)")
      )

      output$tab_s1 <- render_rich_tab(
        translate("Drowsy Customer Awakening"),
        translate("Re-engage customers showing early signs of inactivity — highest recovery potential"),
        function(df) {
          s1_df <- df[df$nes_status == "S1", ]
          list(
            list(value = format(nrow(s1_df), big.mark = ","), label = translate("Drowsy Customers")),
            list(value = round(mean(s1_df$r_value, na.rm = TRUE), 0), label = translate("Avg Days Inactive")),
            list(value = round(mean(s1_df$nrec_prob, na.rm = TRUE), 3), label = translate("Avg Churn Prob")),
            list(value = paste0("$", format(round(mean(s1_df$spent_total, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg Historical Spend"))
          )
        },
        c("Awakening / Return", "Standard Nurturing (Conservative)")
      )

      output$tab_s2 <- render_rich_tab(
        translate("Half-Sleeping Customer Retention"),
        translate("Urgent action needed — these customers are at high risk of permanent churn"),
        function(df) {
          s2_df <- df[df$nes_status == "S2", ]
          list(
            list(value = format(nrow(s2_df), big.mark = ","), label = translate("Half-Sleeping")),
            list(value = round(mean(s2_df$r_value, na.rm = TRUE), 0), label = translate("Avg Days Inactive")),
            list(value = round(mean(s2_df$nrec_prob, na.rm = TRUE), 3), label = translate("Avg Churn Prob")),
            list(value = paste0("$", format(round(mean(s2_df$clv_value, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg CLV"))
          )
        },
        c("Relationship Repair", "Awakening / Return")
      )

      output$tab_s3 <- render_rich_tab(
        translate("Dormant Customer Activation"),
        translate("Low-cost strategies for long-dormant customers — focus on cost efficiency"),
        function(df) {
          s3_df <- df[df$nes_status == "S3", ]
          list(
            list(value = format(nrow(s3_df), big.mark = ","), label = translate("Dormant Customers")),
            list(value = round(mean(s3_df$r_value, na.rm = TRUE), 0), label = translate("Avg Days Inactive")),
            list(value = paste0("$", format(round(mean(s3_df$spent_total, na.rm = TRUE), 0), big.mark = ",")), label = translate("Avg Historical Spend")),
            list(value = round(mean(s3_df$nrec_prob, na.rm = TRUE), 3), label = translate("Avg Churn Prob"))
          )
        },
        c("Cost Control", "Low-Cost Nurturing")
      )

      # AI Insight — non-blocking via ExtendedTask (GUIDE03, TD_P004 compliant)
      gpt_key <- Sys.getenv("OPENAI_API_KEY", "")
      ai_task <- create_ai_insight_task(gpt_key)

      setup_ai_insight_server(
        input, output, session, ns,
        task = ai_task,
        gpt_key = gpt_key,
        prompt_key = "vitalsigns_analysis.retention_insights",
        get_template_vars = function() {
          df <- dna_data()
          if (is.null(df) || nrow(df) == 0) return(NULL)

          nc <- nes_counts()
          n <- nc$total
          active <- nc$N + nc$E0
          sleeping <- nc$S1 + nc$S2 + nc$S3

          list(
            total_customers = as.character(n),
            retention_summary = paste0(
              "Retention rate: ", round(active / max(n, 1) * 100, 1), "%\n",
              "Churn rate: ", round(sleeping / max(n, 1) * 100, 1), "%\n",
              "Core customer ratio: ", round(nc$E0 / max(n, 1) * 100, 1), "%"
            ),
            nes_distribution = paste0(
              "N (New): ", nc$N, " (", round(nc$N / max(n, 1) * 100, 1), "%)\n",
              "E0 (Core): ", nc$E0, " (", round(nc$E0 / max(n, 1) * 100, 1), "%)\n",
              "S1 (Drowsy): ", nc$S1, " (", round(nc$S1 / max(n, 1) * 100, 1), "%)\n",
              "S2 (Half-Sleeping): ", nc$S2, " (", round(nc$S2 / max(n, 1) * 100, 1), "%)\n",
              "S3 (Dormant): ", nc$S3, " (", round(nc$S3 / max(n, 1) * 100, 1), "%)"
            ),
            churn_risk_summary = paste0(
              "High risk (nrec_prob > 0.7): ", sum(df$nrec_prob > 0.7, na.rm = TRUE), "\n",
              "Medium risk (0.3-0.7): ", sum(df$nrec_prob > 0.3 & df$nrec_prob <= 0.7, na.rm = TRUE), "\n",
              "Low risk (< 0.3): ", sum(df$nrec_prob <= 0.3, na.rm = TRUE), "\n",
              "Avg churn probability: ", round(mean(df$nrec_prob, na.rm = TRUE), 3)
            ),
            value_at_risk = paste0(
              "Avg CLV of sleeping customers: $", format(round(mean(df$clv_value[df$nes_status %in% c("S1", "S2", "S3")], na.rm = TRUE), 0), big.mark = ","), "\n",
              "Total CLV at risk: $", format(round(sum(df$clv_value[df$nes_status %in% c("S1", "S2", "S3")], na.rm = TRUE), 0), big.mark = ",")
            )
          )
        },
        component_label = "customerRetention"
      )

    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
