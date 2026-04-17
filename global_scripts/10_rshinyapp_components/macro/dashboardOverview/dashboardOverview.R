# =============================================================================
# dashboardOverview.R — Dashboard Overview Component
# CONSUMES: df_dna_by_customer, df_rsv_classified
# Following: UI_R001, UI_R011, MP029, DEV_R001
# =============================================================================

dashboardOverviewComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- UI ----
  ui_filter <- tagList()

  ui_display <- tagList(
    # Row 1: TagPilot KPIs
    fluidRow(
      column(3, uiOutput(ns("kpi_risk_ratio"))),
      column(3, uiOutput(ns("kpi_vip_count"))),
      column(3, uiOutput(ns("kpi_awaken_count"))),
      column(3, uiOutput(ns("kpi_core_count")))
    ),
    # Row 2: VitalSigns KPIs
    fluidRow(
      column(3, uiOutput(ns("kpi_retention"))),
      column(3, uiOutput(ns("kpi_arpu"))),
      column(3, uiOutput(ns("kpi_cai_index"))),
      column(3, uiOutput(ns("kpi_repeat_rate")))
    ),
    # Row 3: Charts
    fluidRow(
      column(6, bs4Card(title = translate("Customer Status (NES)"), status = "primary",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("nes_pie"), height = "300px"))),
      column(6, bs4Card(title = translate("Marketing Strategy Distribution"), status = "success",
        width = 12, solidHeader = TRUE, plotly::plotlyOutput(ns("strategy_bar"), height = "300px")))
    )
  )

  # ---- Server ----
  server_fn <- function(input, output, session) {
    moduleServer(id, function(input, output, session) {

      # DNA data (from df_dna_by_customer)
      dna_data <- reactive({
        cfg <- comp_config()
        req(cfg$filters$platform_id)
        tryCatch({
          pl_id <- cfg$filters$product_line_id_sliced
          if (is.null(pl_id) || pl_id == "all") pl_id <- "all"
          sql <- "SELECT nes_status, nt, cai, total_spent FROM df_dna_by_customer WHERE platform_id = ? AND product_line_id_filter = ?"
          df <- DBI::dbGetQuery(app_connection, sql, params = list(cfg$filters$platform_id, pl_id))
          if (nrow(df) == 0) { message("[dashboardOverview] No DNA data"); return(NULL) }
          message("[dashboardOverview] DNA data: ", nrow(df), " records")
          df
        }, error = function(e) {
          message("[dashboardOverview] DNA load error: ", e$message)
          NULL
        })
      })

      # RSV data (from df_rsv_classified)
      rsv_data <- reactive({
        cfg <- comp_config()
        req(cfg$filters$platform_id)
        tryCatch({
          pl_id <- cfg$filters$product_line_id_sliced
          if (is.null(pl_id) || pl_id == "all") pl_id <- "all"
          sql <- "SELECT marketing_strategy FROM df_rsv_classified WHERE platform_id = ? AND product_line_id_filter = ?"
          df <- DBI::dbGetQuery(app_connection, sql, params = list(cfg$filters$platform_id, pl_id))
          if (nrow(df) == 0) { message("[dashboardOverview] No RSV data"); return(NULL) }
          message("[dashboardOverview] RSV data: ", nrow(df), " records")
          df
        }, error = function(e) {
          message("[dashboardOverview] RSV load error: ", e$message)
          NULL
        })
      })

      # ---- TagPilot KPIs ----

      output$kpi_risk_ratio <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("High Risk Ratio"),
                                            icon = icon("exclamation-triangle"), color = "danger", width = 12))
        n_risk <- sum(df$nes_status %in% c("S2", "S3"), na.rm = TRUE)
        pct <- round(n_risk / nrow(df) * 100, 1)
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("High Risk Ratio"),
                    icon = icon("exclamation-triangle"), color = "danger", width = 12)
      })

      output$kpi_vip_count <- renderUI({
        df <- rsv_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("VIP Customers"),
                                            icon = icon("crown"), color = "purple", width = 12))
        n_vip <- sum(grepl("VIP|Premium", df$marketing_strategy), na.rm = TRUE)
        bs4ValueBox(value = format(n_vip, big.mark = ","), subtitle = translate("VIP Customers"),
                    icon = icon("crown"), color = "purple", width = 12)
      })

      output$kpi_awaken_count <- renderUI({
        df <- rsv_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Awaiting Awakening"),
                                            icon = icon("bell"), color = "warning", width = 12))
        n_awaken <- sum(grepl("Awakening", df$marketing_strategy), na.rm = TRUE)
        bs4ValueBox(value = format(n_awaken, big.mark = ","), subtitle = translate("Awaiting Awakening"),
                    icon = icon("bell"), color = "warning", width = 12)
      })

      output$kpi_core_count <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Core Customers (E0)"),
                                            icon = icon("gem"), color = "success", width = 12))
        n_core <- sum(df$nes_status == "E0", na.rm = TRUE)
        bs4ValueBox(value = format(n_core, big.mark = ","), subtitle = translate("Core Customers (E0)"),
                    icon = icon("gem"), color = "success", width = 12)
      })

      # ---- VitalSigns KPIs ----

      output$kpi_retention <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Retention Rate"),
                                            icon = icon("shield-halved"), color = "info", width = 12))
        n_active <- sum(!df$nes_status %in% c("S3"), na.rm = TRUE)
        pct <- round(n_active / nrow(df) * 100, 1)
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Retention Rate"),
                    icon = icon("shield-halved"), color = "info", width = 12)
      })

      output$kpi_arpu <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("ARPU"),
                                            icon = icon("coins"), color = "primary", width = 12))
        arpu <- round(mean(df$total_spent, na.rm = TRUE), 0)
        bs4ValueBox(value = format(arpu, big.mark = ","), subtitle = translate("ARPU"),
                    icon = icon("coins"), color = "primary", width = 12)
      })

      output$kpi_cai_index <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Activity Index (CAI)"),
                                            icon = icon("bolt"), color = "olive", width = 12))
        avg_cai <- mean(df$cai, na.rm = TRUE)
        if (is.nan(avg_cai) || is.na(avg_cai)) avg_cai <- "-" else avg_cai <- round(avg_cai, 3)
        bs4ValueBox(value = avg_cai, subtitle = translate("Activity Index (CAI)"),
                    icon = icon("bolt"), color = "olive", width = 12)
      })

      output$kpi_repeat_rate <- renderUI({
        df <- dna_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Repeat Purchase Rate"),
                                            icon = icon("redo"), color = "teal", width = 12))
        n_repeat <- sum(df$nt >= 2, na.rm = TRUE)
        pct <- round(n_repeat / nrow(df) * 100, 1)
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Repeat Purchase Rate"),
                    icon = icon("redo"), color = "teal", width = 12)
      })

      # ---- Charts ----

      output$nes_pie <- renderPlotly({
        df <- dna_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        tbl <- as.data.frame(table(df$nes_status), stringsAsFactors = FALSE)
        names(tbl) <- c("status", "count")
        labels <- c(N = translate("New"), E0 = translate("Core"),
                     S1 = translate("Drowsy"), S2 = translate("Half-Sleeping"), S3 = translate("Dormant"))
        tbl$label <- ifelse(tbl$status %in% names(labels), labels[tbl$status], tbl$status)
        colors <- c(N = "#17a2b8", E0 = "#28a745", S1 = "#ffc107", S2 = "#fd7e14", S3 = "#dc3545")

        plotly::plot_ly(tbl, labels = ~label, values = ~count, type = "pie",
                        marker = list(colors = colors[tbl$status]),
                        textinfo = "label+percent") %>%
          plotly::layout(showlegend = TRUE)
      })

      output$strategy_bar <- renderPlotly({
        df <- rsv_data()
        if (is.null(df)) return(plotly::plot_ly() %>% plotly::layout(title = translate("No Data")))

        tbl <- as.data.frame(table(df$marketing_strategy), stringsAsFactors = FALSE)
        names(tbl) <- c("strategy", "count")
        tbl <- tbl[order(-tbl$count), ]
        tbl$label <- sapply(tbl$strategy, translate)

        colors <- c("#dc3545", "#fd7e14", "#ffc107", "#28a745", "#20c997",
                     "#17a2b8", "#007bff", "#6610f2", "#6f42c1", "#e83e8c")

        plotly::plot_ly(tbl, x = ~reorder(label, -count), y = ~count, type = "bar",
                        marker = list(color = colors[seq_len(min(nrow(tbl), length(colors)))])) %>%
          plotly::layout(
            xaxis = list(title = "", tickangle = -30),
            yaxis = list(title = translate("Customer Count")),
            margin = list(b = 120)
          )
      })

    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
