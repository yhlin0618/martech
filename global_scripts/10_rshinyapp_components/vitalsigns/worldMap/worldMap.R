# =============================================================================
# worldMap.R — World Market Map Component (VitalSigns)
# CONSUMES: df_geo_sales_by_country (from D03_01)
# Following: UI_R001, UI_R011, MP064, MP029, DEV_R050, 10-ui-layout
# =============================================================================

worldMapComponent <- function(id, app_connection, comp_config, translate) {
  ns <- NS(id)

  # ---- KPI choices (DEV_R050: display text from translate, not hardcoded) ----
  kpi_choices <- c(
    "revenue"   = "revenue",
    "orders"    = "orders",
    "customers" = "customers",
    "aov"       = "aov"
  )

  # ---- UI ----
  ui_filter <- tagList(
    selectInput(
      ns("kpi_select"),
      label = translate("Select KPI"),
      choices = stats::setNames(
        kpi_choices,
        c(translate("Revenue"), translate("Order Count"),
          translate("Customer Count"), translate("Avg Order Value"))
      ),
      selected = "revenue"
    ),
    radioButtons(
      ns("view_mode"),
      label = translate("View Mode"),
      choices = stats::setNames(
        c("world", "us_states"),
        c(translate("World Map"), translate("US States"))
      ),
      selected = "world",
      inline = TRUE
    ),
    ai_insight_button_ui(ns, translate)
  )

  ui_display <- tagList(
    # KPI Row
    fluidRow(
      column(3, uiOutput(ns("kpi_countries"))),
      column(3, uiOutput(ns("kpi_largest"))),
      column(3, uiOutput(ns("kpi_top3_share"))),
      column(3, uiOutput(ns("kpi_total_revenue")))
    ),
    # Map Row
    fluidRow(
      column(12, bs4Card(
        title = translate("World Market Distribution"), status = "primary",
        width = 12, solidHeader = TRUE,
        plotly::plotlyOutput(ns("geo_map"), height = "480px")
      ))
    ),
    # Detail Table
    fluidRow(
      column(12, bs4Card(
        title = translate("Country Details"), status = "primary",
        width = 12, solidHeader = TRUE,
        downloadButton(ns("download_csv"), translate("Download CSV"),
                       class = "btn-sm btn-outline-primary mb-2"),
        DT::dataTableOutput(ns("detail_table"))
      ))
    ),
    # AI Insight Result — bottom of display (10-ui-layout)
    fluidRow(
      column(12, ai_insight_result_ui(ns, translate))
    )
  )

  # ---- Server ----
  server_fn <- function(input, output, session) {
    moduleServer(id, function(input, output, session) {

      geo_data <- reactive({
        cfg <- comp_config()
        req(cfg$filters$platform_id)
        tryCatch({
          filter_clause <- if (!is.null(cfg$filters$product_line_id_sliced) &&
                               cfg$filters$product_line_id_sliced != "all") {
            paste0(" AND product_line_id_filter = '", cfg$filters$product_line_id_sliced, "'")
          } else {
            " AND product_line_id_filter = 'all'"
          }

          df <- DBI::dbGetQuery(app_connection, paste0(
            "SELECT ship_country, total_revenue, order_count, customer_count,",
            " avg_order_value, avg_quantity",
            " FROM df_geo_sales_by_country",
            " WHERE platform_id = '", cfg$filters$platform_id, "'",
            filter_clause
          ))
          if (nrow(df) == 0) {
            message("[worldMap] No data returned")
            return(NULL)
          }
          message("[worldMap] Loaded ", nrow(df), " countries")
          df
        }, error = function(e) {
          message("[worldMap] Data load error: ", e$message)
          NULL
        })
      })

      # Helper: get column by selected KPI
      kpi_col <- reactive({
        req(input$kpi_select)  # guard against NULL during init
        switch(input$kpi_select,
               "revenue"   = "total_revenue",
               "orders"    = "order_count",
               "customers" = "customer_count",
               "aov"       = "avg_order_value",
               "total_revenue")
      })

      kpi_label <- reactive({
        req(input$kpi_select)  # guard against NULL during init
        switch(input$kpi_select,
               "revenue"   = translate("Revenue"),
               "orders"    = translate("Order Count"),
               "customers" = translate("Customer Count"),
               "aov"       = translate("Avg Order Value"),
               translate("Revenue"))
      })

      # ---- KPIs ----
      output$kpi_countries <- renderUI({
        df <- geo_data()
        val <- if (is.null(df)) "-" else as.character(nrow(df))
        bs4ValueBox(value = val, subtitle = translate("Total Countries"),
                    icon = icon("globe"), color = "primary", width = 12)
      })

      output$kpi_largest <- renderUI({
        df <- geo_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Largest Market"),
                                            icon = icon("trophy"), color = "success", width = 12))
        top <- df[which.max(df$total_revenue), ]
        bs4ValueBox(value = top$ship_country,
                    subtitle = paste0(translate("Largest Market"), " ($",
                                      format(round(top$total_revenue, 0), big.mark = ","), ")"),
                    icon = icon("trophy"), color = "success", width = 12)
      })

      output$kpi_top3_share <- renderUI({
        df <- geo_data()
        if (is.null(df) || nrow(df) < 1) return(bs4ValueBox(
          value = "-", subtitle = translate("Top 3 Market Share"),
          icon = icon("chart-pie"), color = "info", width = 12))
        ordered <- df[order(-df$total_revenue), ]
        top3_rev <- sum(utils::head(ordered$total_revenue, 3))
        total_rev <- sum(ordered$total_revenue)
        pct <- round(top3_rev / total_rev * 100, 1)
        bs4ValueBox(value = paste0(pct, "%"), subtitle = translate("Top 3 Market Share"),
                    icon = icon("chart-pie"), color = "info", width = 12)
      })

      output$kpi_total_revenue <- renderUI({
        df <- geo_data()
        if (is.null(df)) return(bs4ValueBox(value = "-", subtitle = translate("Revenue"),
                                            icon = icon("dollar-sign"), color = "warning", width = 12))
        total <- sum(df$total_revenue, na.rm = TRUE)
        bs4ValueBox(value = paste0("$", format(round(total, 0), big.mark = ",")),
                    subtitle = translate("Revenue"),
                    icon = icon("dollar-sign"), color = "warning", width = 12)
      })

      # ---- State-level data (Issue #240) ----
      state_data <- reactive({
        cfg <- comp_config()
        req(cfg$filters$platform_id)
        tryCatch({
          filter_clause <- if (!is.null(cfg$filters$product_line_id_sliced) &&
                               cfg$filters$product_line_id_sliced != "all") {
            paste0(" AND product_line_id_filter = '", cfg$filters$product_line_id_sliced, "'")
          } else {
            " AND product_line_id_filter = 'all'"
          }
          df <- DBI::dbGetQuery(app_connection, paste0(
            "SELECT ship_state, total_revenue, order_count, customer_count,",
            " avg_order_value, avg_quantity",
            " FROM df_geo_sales_by_state",
            " WHERE platform_id = '", cfg$filters$platform_id, "'",
            filter_clause
          ))
          if (nrow(df) == 0) return(NULL)
          message("[worldMap] Loaded ", nrow(df), " US states")
          df
        }, error = function(e) {
          message("[worldMap] State data load error: ", e$message)
          NULL
        })
      })

      # ---- ISO2 → ISO3 mapping (plotly requires ISO-3 alpha-3 codes) ----
      iso2to3 <- c(
        AD="AND",AE="ARE",AF="AFG",AG="ATG",AI="AIA",AL="ALB",AM="ARM",AO="AGO",
        AR="ARG",AS="ASM",AT="AUT",AU="AUS",AW="ABW",AZ="AZE",BA="BIH",BB="BRB",
        BD="BGD",BE="BEL",BF="BFA",BG="BGR",BH="BHR",BI="BDI",BJ="BEN",BM="BMU",
        BN="BRN",BO="BOL",BR="BRA",BS="BHS",BT="BTN",BW="BWA",BY="BLR",BZ="BLZ",
        CA="CAN",CD="COD",CF="CAF",CG="COG",CH="CHE",CI="CIV",CL="CHL",CM="CMR",
        CN="CHN",CO="COL",CR="CRI",CU="CUB",CV="CPV",CY="CYP",CZ="CZE",DE="DEU",
        DJ="DJI",DK="DNK",DM="DMA",DO="DOM",DZ="DZA",EC="ECU",EE="EST",EG="EGY",
        ER="ERI",ES="ESP",ET="ETH",FI="FIN",FJ="FJI",FK="FLK",FM="FSM",FO="FRO",
        FR="FRA",GA="GAB",GB="GBR",GD="GRD",GE="GEO",GF="GUF",GH="GHA",GI="GIB",
        GL="GRL",GM="GMB",GN="GIN",GP="GLP",GQ="GNQ",GR="GRC",GT="GTM",GU="GUM",
        GW="GNB",GY="GUY",HK="HKG",HN="HND",HR="HRV",HT="HTI",HU="HUN",ID="IDN",
        IE="IRL",IL="ISR",IN="IND",IQ="IRQ",IR="IRN",IS="ISL",IT="ITA",JM="JAM",
        JO="JOR",JP="JPN",KE="KEN",KG="KGZ",KH="KHM",KI="KIR",KM="COM",KN="KNA",
        KP="PRK",KR="KOR",KW="KWT",KY="CYM",KZ="KAZ",LA="LAO",LB="LBN",LC="LCA",
        LI="LIE",LK="LKA",LR="LBR",LS="LSO",LT="LTU",LU="LUX",LV="LVA",LY="LBY",
        MA="MAR",MC="MCO",MD="MDA",ME="MNE",MG="MDG",MH="MHL",MK="MKD",ML="MLI",
        MM="MMR",MN="MNG",MO="MAC",MP="MNP",MQ="MTQ",MR="MRT",MS="MSR",MT="MLT",
        MU="MUS",MV="MDV",MW="MWI",MX="MEX",MY="MYS",MZ="MOZ","NA"="NAM",NC="NCL",
        NE="NER",NF="NFK",NG="NGA",NI="NIC",NL="NLD",NO="NOR",NP="NPL",NR="NRU",
        NU="NIU",NZ="NZL",OM="OMN",PA="PAN",PE="PER",PF="PYF",PG="PNG",PH="PHL",
        PK="PAK",PL="POL",PM="SPM",PN="PCN",PR="PRI",PS="PSE",PT="PRT",PW="PLW",
        PY="PRY",QA="QAT",RE="REU",RO="ROU",RS="SRB",RU="RUS",RW="RWA",SA="SAU",
        SB="SLB",SC="SYC",SD="SDN",SE="SWE",SG="SGP",SH="SHN",SI="SVN",SK="SVK",
        SL="SLE",SM="SMR",SN="SEN",SO="SOM",SR="SUR",SS="SSD",ST="STP",SV="SLV",
        SX="SXM",SY="SYR",SZ="SWZ",TC="TCA",TD="TCD",TG="TGO",TH="THA",TJ="TJK",
        TL="TLS",TM="TKM",TN="TUN",TO="TON",TR="TUR",TT="TTO",TV="TUV",TW="TWN",
        TZ="TZA",UA="UKR",UG="UGA",US="USA",UY="URY",UZ="UZB",VA="VAT",VC="VCT",
        VE="VEN",VG="VGB",VI="VIR",VN="VNM",VU="VUT",WF="WLF",WS="WSM",XK="XKX",
        YE="YEM",YT="MYT",ZA="ZAF",ZM="ZMB",ZW="ZWE"
      )

      # ---- Map (plotly::plot_geo) — World or US States ----
      output$geo_map <- plotly::renderPlotly({
        view <- input$view_mode
        if (is.null(view)) view <- "world"
        col <- kpi_col()
        label <- kpi_label()

        if (view == "us_states") {
          # ---- US States View ----
          df <- state_data()
          if (is.null(df)) {
            return(plotly::plot_ly() %>%
                     plotly::layout(title = translate("No Geographic Data")))
          }

          hover_text <- paste0(
            "<b>", df$ship_state, "</b><br>",
            translate("Revenue"), ": $", format(round(df$total_revenue, 0), big.mark = ","), "<br>",
            translate("Order Count"), ": ", format(df$order_count, big.mark = ","), "<br>",
            translate("Customer Count"), ": ", format(df$customer_count, big.mark = ","), "<br>",
            translate("Avg Order Value"), ": $", format(round(df$avg_order_value, 0), big.mark = ",")
          )

          raw_vals <- df[[col]]
          log_vals <- log10(pmax(raw_vals, 1))
          max_log <- ceiling(max(log_vals, na.rm = TRUE))
          tick_vals <- seq(0, max_log, by = 1)
          tick_text <- vapply(tick_vals, function(v) {
            val <- 10^v
            if (val >= 1e6) paste0(round(val / 1e6, 1), "M")
            else if (val >= 1e3) paste0(round(val / 1e3, 0), "K")
            else as.character(round(val, 0))
          }, character(1))

          plotly::plot_geo(df) %>%
            plotly::add_trace(
              locations = df$ship_state,
              locationmode = "USA-states",
              z = log_vals,
              colorscale = "Blues",
              text = hover_text,
              hoverinfo = "text",
              colorbar = list(title = label, tickvals = tick_vals, ticktext = tick_text)
            ) %>%
            plotly::layout(
              geo = list(
                scope = "usa",
                showlakes = TRUE,
                lakecolor = plotly::toRGB("white")
              ),
              margin = list(l = 0, r = 0, t = 30, b = 0)
            )

        } else {
          # ---- World View ----
          df <- geo_data()
          if (is.null(df)) {
            return(plotly::plot_ly() %>%
                     plotly::layout(title = translate("No Geographic Data")))
          }

          # Convert ISO2 → ISO3 for plotly
          iso3_codes <- iso2to3[df$ship_country]
          iso3_codes[is.na(iso3_codes)] <- df$ship_country[is.na(iso3_codes)]

          hover_text <- paste0(
            "<b>", df$ship_country, "</b><br>",
            translate("Revenue"), ": $", format(round(df$total_revenue, 0), big.mark = ","), "<br>",
            translate("Order Count"), ": ", format(df$order_count, big.mark = ","), "<br>",
            translate("Customer Count"), ": ", format(df$customer_count, big.mark = ","), "<br>",
            translate("Avg Order Value"), ": $", format(round(df$avg_order_value, 0), big.mark = ",")
          )

          raw_vals <- df[[col]]
          log_vals <- log10(pmax(raw_vals, 1))
          max_log <- ceiling(max(log_vals, na.rm = TRUE))
          tick_vals <- seq(0, max_log, by = 1)
          tick_text <- vapply(tick_vals, function(v) {
            val <- 10^v
            if (val >= 1e6) paste0(round(val / 1e6, 1), "M")
            else if (val >= 1e3) paste0(round(val / 1e3, 0), "K")
            else as.character(round(val, 0))
          }, character(1))

          plotly::plot_geo(df) %>%
            plotly::add_trace(
              locations = iso3_codes,
              locationmode = "ISO-3",
              z = log_vals,
              colorscale = "Blues",
              text = hover_text,
              hoverinfo = "text",
              colorbar = list(title = label, tickvals = tick_vals, ticktext = tick_text)
            ) %>%
            plotly::layout(
              geo = list(
                projection = list(type = "natural earth"),
                showframe = FALSE,
                showcoastlines = TRUE,
                coastlinecolor = plotly::toRGB("grey80")
              ),
              margin = list(l = 0, r = 0, t = 30, b = 0)
            )
        }
      })

      # ---- Detail Table ----
      output$detail_table <- DT::renderDataTable({
        view <- input$view_mode
        if (is.null(view)) view <- "world"

        if (view == "us_states") {
          df <- state_data()
          if (is.null(df)) return(DT::datatable(
            data.frame(Message = translate("No Geographic Data"))))

          show_df <- data.frame(
            State         = df$ship_state,
            Revenue       = round(df$total_revenue, 0),
            Orders        = df$order_count,
            Customers     = df$customer_count,
            AOV           = round(df$avg_order_value, 0),
            Avg_Qty       = round(df$avg_quantity, 1),
            stringsAsFactors = FALSE
          )
          show_df <- show_df[order(-show_df$Revenue), ]
          names(show_df) <- c(translate("State"), translate("Revenue"),
                              translate("Order Count"), translate("Customer Count"),
                              translate("Avg Order Value"), "Avg Qty")
        } else {
          df <- geo_data()
          if (is.null(df)) return(DT::datatable(
            data.frame(Message = translate("No Geographic Data"))))

          show_df <- data.frame(
            Country       = df$ship_country,
            Revenue       = round(df$total_revenue, 0),
            Orders        = df$order_count,
            Customers     = df$customer_count,
            AOV           = round(df$avg_order_value, 0),
            Avg_Qty       = round(df$avg_quantity, 1),
            stringsAsFactors = FALSE
          )
          show_df <- show_df[order(-show_df$Revenue), ]
          names(show_df) <- c(translate("Country"), translate("Revenue"),
                              translate("Order Count"), translate("Customer Count"),
                              translate("Avg Order Value"), "Avg Qty")
        }

        DT::datatable(show_df,
                      filter = "top", rownames = FALSE,
                      options = list(pageLength = 15, scrollX = TRUE, dom = "lftip",
                                     language = list(url = "//cdn.datatables.net/plug-ins/1.13.7/i18n/zh-HANT.json")))
      })

      # ---- AI Insight (non-blocking, ExtendedTask) ----
      gpt_key <- Sys.getenv("OPENAI_API_KEY", "")
      ai_task <- create_ai_insight_task(gpt_key)

      setup_ai_insight_server(
        input, output, session, ns,
        task = ai_task,
        gpt_key = gpt_key,
        prompt_key = "vitalsigns_analysis.world_map_insights",
        get_template_vars = function() {
          df <- geo_data()
          if (is.null(df) || nrow(df) == 0) return(NULL)

          ordered <- df[order(-df$total_revenue), ]
          total_rev <- sum(ordered$total_revenue, na.rm = TRUE)

          # Country revenue summary (top 10)
          top_n <- utils::head(ordered, 10)
          country_lines <- vapply(seq_len(nrow(top_n)), function(i) {
            pct <- round(top_n$total_revenue[i] / total_rev * 100, 1)
            sprintf("%s: $%s (%s%%, %d orders, %d customers)",
                    top_n$ship_country[i],
                    format(round(top_n$total_revenue[i], 0), big.mark = ","),
                    pct, top_n$order_count[i], top_n$customer_count[i])
          }, character(1))

          # Concentration
          top1_pct <- round(ordered$total_revenue[1] / total_rev * 100, 1)
          top3_pct <- round(sum(utils::head(ordered$total_revenue, 3)) / total_rev * 100, 1)
          top5_pct <- round(sum(utils::head(ordered$total_revenue, 5)) / total_rev * 100, 1)

          list(
            total_countries = as.character(nrow(df)),
            largest_market = sprintf("%s ($%s, %.1f%%)",
                                    ordered$ship_country[1],
                                    format(round(ordered$total_revenue[1], 0), big.mark = ","),
                                    top1_pct),
            country_revenue_summary = paste(country_lines, collapse = "\n"),
            concentration_summary = sprintf(
              "Top 1: %.1f%%\nTop 3: %.1f%%\nTop 5: %.1f%%\nTotal countries: %d",
              top1_pct, top3_pct, top5_pct, nrow(df))
          )
        },
        component_label = "worldMap"
      )

      # ---- Download CSV ----
      output$download_csv <- downloadHandler(
        filename = function() paste0("world_market_", Sys.Date(), ".csv"),
        content = function(file) {
          df <- geo_data()
          if (!is.null(df)) {
            con <- file(file, "wb")
            writeBin(charToRaw("\xef\xbb\xbf"), con)
            close(con)
            # write.table (NOT write.csv) — write.csv ignores append=TRUE (DEV_R051)
            utils::write.table(df, file, row.names = FALSE, sep = ",",
                               quote = TRUE, append = TRUE, fileEncoding = "UTF-8")
          }
        }
      )

    })
  }

  list(ui = list(filter = ui_filter, display = ui_display), server = server_fn)
}
