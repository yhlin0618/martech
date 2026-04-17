## position_analysis_modules.R
# Shiny modules for PCA, Ideal analysis, Strategy analysis, and UI display

library(shiny)
library(dplyr)
library(plotly)
library(DT)
library(DBI)
library(duckdb)

# connect and load raw data
db <- dbConnect(duckdb(),
                dbdir = "D:/新增資料夾/Dropbox/Precision Marketing_KitchenMAMA/precision_marketing_app/app_data.duckdb",
                read_only = TRUE)
position_dta <- tbl(db, "position_dta") %>%
  collect() %>%
  filter(product_line_id == "001")

# 1. PCA Module --------------------------------------------------------------
pcaModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("hint")),
    plotlyOutput(ns("pca_plot"), height = "600px")
  )
}

pcaModuleServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    pca_res <- reactive({
      nums <- data()
      prcomp(nums, center = TRUE, scale. = TRUE, rank. = 3)
    })
    
    output$hint <- renderUI({
      df <- data()
      if (ncol(df) < 2) {
        tags$div(style="color:#888", 
                 "請先從上方選好 ASIN 且該組資料至少有兩個數值欄，才能看到 PCA 結果。")
      }
    })
    
    output$pca_plot <- renderPlotly({
      nums <- data()
      req(ncol(nums) >= 2)
      pc <- pca_res()
      scores   <- as.data.frame(pc$x)
      loadings <- as.data.frame(pc$rotation) * 5
      load_long <- bind_rows(
        loadings %>% rownames_to_column("var") %>% mutate(PC1=0,PC2=0,PC3=0),
        loadings %>% rownames_to_column("var")
      )
      plot_ly() %>%
        add_markers(data = scores, x=~PC1, y=~PC2, z=~PC3, color=I("gray")) %>%
        add_lines  (data = load_long, x=~PC1, y=~PC2, z=~PC3, color=~var) %>%
        layout(scene = list(
          xaxis=list(title="PC1"),
          yaxis=list(title="PC2"),
          zaxis=list(title="PC3")
        ))
    })
  })
}


# 2. Ideal Analysis Module --------------------------------------------------
idealModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    textOutput(ns("key_factors")),
    DTOutput(ns("ideal_rank"))
  )
}

idealModuleServer <- function(id, data, raw, indicator, key_vars) {
  moduleServer(id, function(input, output, session) {
    # key factors text
    output$key_factors <- renderText({
      paste("關鍵因素：", paste(key_vars(), collapse = ", "))
    })
    
    # ranked table
    output$ideal_rank <- renderDT({
      ind <- indicator()
      df  <- raw() %>% select(asin, brand)
      df$Score <- rowSums(ind %>% select(-asin))
      df <- df %>% filter(asin != "Ideal") %>% arrange(desc(Score))
      DT::datatable(df, rownames = FALSE, options = list(pageLength = 10))
    })
  })
}


# 3. Strategy Analysis Module ------------------------------------------------
strategyModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(ns("select_asin"), "選擇ASIN", choices = NULL),
    plotlyOutput(ns("strategy_plot"), height = "800px")
  )
}
strategyModuleServer <- function(id, data, key_vars) {
  moduleServer(id, function(input, output, session) {
    observe({
      df <- data()
      req(df)
      updateSelectInput(session, "select_asin", choices = df$asin)
    })
    
    output$strategy_plot <- renderPlotly({
      req(input$select_asin)
      
      ind       <- data() %>% filter(asin == input$select_asin)
      key       <- key_vars()
      feats_key <- key
      feats_non <- setdiff(names(ind), c(key, "asin"))
      
      sums_key <- colSums(ind[feats_key])
      sums_non <- colSums(ind[feats_non])
      
      quad_feats <- list(
        訴求 = feats_key[sums_key >  mean(sums_key)],
        改變 = feats_key[sums_key <= mean(sums_key)],
        改善 = feats_non[sums_non >  mean(sums_non)],
        劣勢 = feats_non[sums_non <= mean(sums_non)]
      )
      
      # 拆成两行、控制每行最多6个
      split_two_rows <- function(feats) {
        n <- length(feats)
        row1 <- feats[1:min(6, n)]
        row2 <- if (n>6) feats[7:min(12, n)] else character(0)
        list(row1=row1, row2=row2)
      }
      
      # x,y 在子坐标(0~1)里排布
      place_text <- function(rows) {
        out <- data.frame()
        for (ri in seq_along(rows)) {
          feats <- rows[[ri]]
          m     <- length(feats)
          xs    <- if (m>0) seq(0.1, 0.9, length.out=m) else numeric(0)
          ys    <- rep(ifelse(ri==1, 0.8, 0.6), m)
          out  <- rbind(out, data.frame(text=feats, x=xs, y=ys))
        }
        out
      }
      
      # 构建所有 traces
      fig <- plot_ly()
      
      # 四个子域定义
      domains <- list(
        訴求 = list(x = c(0.5,1), y = c(0.5,1)),
        改變 = list(x = c(0.5,1), y = c(0,0.5)),
        改善 = list(x = c(0,0.5), y = c(0.5,1)),
        劣勢 = list(x = c(0,0.5), y = c(0,0.5))
      )
      
      # 对每个象限，添加标题 + 两行文字
      for (nm in names(quad_feats)) {
        dom  <- domains[[nm]]
        rows <- split_two_rows(quad_feats[[nm]])
        df_t <- place_text(rows)
        # 标题置顶
        fig <- fig %>%
          add_trace(
            type='scatter', mode='text',
            x = 0.5, y = 0.95, text = nm,
            textfont = list(size=20, color="black"),
            hoverinfo='none',
            xaxis = paste0("x", nm), yaxis = paste0("y", nm)
          ) %>%
          add_trace(
            data = df_t, type='scatter', mode='text',
            x=~x, y=~y, text=~text,
            textfont=list(size=14, color="blue"),
            hoverinfo='text',
            xaxis = paste0("x", nm), yaxis = paste0("y", nm)
          )
      }
      
      # layout 四个独立子坐标
      fig %>% layout(
        xaxis訴求 = list(domain=domains$訴求$x, anchor="y訴求", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        yaxis訴求 = list(domain=domains$訴求$y, anchor="x訴求", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        
        xaxis改變 = list(domain=domains$改變$x, anchor="y改變", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        yaxis改變 = list(domain=domains$改變$y, anchor="x改變", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        
        xaxis改善 = list(domain=domains$改善$x, anchor="y改善", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        yaxis改善 = list(domain=domains$改善$y, anchor="x改善", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        
        xaxis劣勢 = list(domain=domains$劣勢$x, anchor="y劣勢", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        yaxis劣勢 = list(domain=domains$劣勢$y, anchor="x劣勢", showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE),
        
        margin = list(l=0, r=0, t=0, b=0)
      )
    })
  })
}



# 4. Main App UI & Server ----------------------------------------------------
ui <- fluidPage(
  titlePanel("Position Analysis"),
  tabsetPanel(
    tabPanel("PCA", pcaModuleUI("pca1")),
    tabPanel("Ideal", idealModuleUI("ideal1")),
    tabPanel("Strategy", strategyModuleUI("strat1"))
  )
)

server <- function(input, output, session) {
  # raw data once
  raw       <- reactive({ position_dta })
  with_na   <- reactive({ raw() %>% select(where(~ !all(is.na(.)))) })
  no_na     <- reactive({ with_na() %>% select(where(~ !any(is.na(.)))) })
  
  # PCA data: numeric only
  pcaData   <- reactive({ no_na() %>% select(where(is.numeric)) })
  
  # Ideal data
  idealFull <- reactive({ with_na() })
  idealRaw  <- reactive({ idealFull() %>% filter(asin != "Ideal") })
  
  # Indicator for Strategy
  indicator <- reactive({
    ideal_vals <- idealFull() %>% filter(asin == "Ideal") %>% select(where(is.numeric))
    df_vals    <- idealRaw()  %>% select(where(is.numeric))
    feature_names <- setdiff(names(df_vals), c("sales", "rating"))
    df_vals <- df_vals[, feature_names]
    cmp    <- unlist(ideal_vals[1, feature_names])
    mat    <- sweep(df_vals, 2, cmp, FUN=">") * 1
    ind    <- as.data.frame(mat)
    ind$asin <- idealRaw()$asin
    ind
  })
  
  # key factors for Ideal & Strategy
  keyVars <- reactive({
    ideal_vals <- idealFull() %>% filter(asin == "Ideal") %>% select(where(is.numeric))
    clean_vals <- ideal_vals %>% select(where(~ !any(is.na(.))))
    names(clean_vals)[ which(unlist(clean_vals[1,]) > mean(unlist(clean_vals[1,]))) ]
  })
  
  # Launch modules
  pcaModuleServer("pca1", pcaData)
  idealModuleServer("ideal1", idealFull, idealRaw, indicator, keyVars)
  strategyModuleServer("strat1", indicator, keyVars)
}

shinyApp(ui, server)
