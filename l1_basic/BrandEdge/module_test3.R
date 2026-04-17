## position_analysis_modules.R
# Shiny modules for PCA, Ideal analysis, Strategy analysis, and UI display

library(shiny)
library(dplyr)
library(plotly)
library(DT)
library(DBI)
library(duckdb)

# connect and load raw data
db <- dbConnect(duckdb(), dbdir = "D:/新增資料夾/Dropbox/Precision Marketing_KitchenMAMA/precision_marketing_app/app_data.duckdb", read_only = TRUE)
position_dta <- tbl(db, "position_dta") %>%
  collect() %>%
  filter(product_line_id == "001")

# 1. PCA Module --------------------------------------------------------------
pcaModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("hint")),       # 顯示提示
    plotlyOutput(ns("pca_plot"))
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
        tags$div(style="color:#888", "請先從左側選好「分類／品牌／ASIN」，並且該組資料至少有兩個數值欄，才能看到 PCA 結果。")
      }
    })
    
    output$pca_plot <- renderPlotly({
      nums <- data()
      req(ncol(nums) >= 2)     # 只有夠欄才繪圖
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
idealModuleServer <- function(id, data, raw,indicator,key_vars) {
  moduleServer(id, function(input, output, session) {
    # ... 保留 ideal_row, indicator, key_fac 定義 ...
    
    
    # 1. 抓出「理想點」那一 row，只取數值欄
    ideal_row <- reactive({
      df <- data()
      req("Ideal" %in% df$asin)
      df %>%
        filter(asin == "Ideal") %>%
        select(where(~ is.numeric(.x) && !any(is.na(.x))))
    })
    
    
    #  print(key_vars())
    output$key_factors <- renderText({
      paste("關鍵因素：", paste(key_vars(), collapse = ", "))
    })
    
    output$ideal_rank <- renderDT({
      ind <- indicator()
      df  <- raw() %>% select(asin, brand)
      # 計算 Score
      #ind %>% select(-c("asin","sales","rating")) %>%  rowSums() %>% print()
      df$Score <-   ind %>% select(-any_of(c("asin","sales","rating"))) %>%  rowSums()
      df <- df %>% filter(asin != "Ideal") %>% arrange(desc(Score))
      # 用 DT::datatable 才會出現 Score 欄
      DT::datatable(df,
                    rownames = FALSE,
                    options = list(pageLength = 10, searching = TRUE))
    })
    output$debug_keys <- renderPrint({
      key_vars()  # 看看挑出来的关键字段名
    })
    # output$debug_ideal <- renderPrint({
    #   indicator()  # 看看 reactive 里到底拿到的那一列数值
    # })
    
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
library(ggplot2)
library(plotly)

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
      sums_key  <- colSums(ind[feats_key])
      sums_non  <- colSums(ind[feats_non])
      
      quad_feats <- list(
        訴求 = feats_key[sums_key >  mean(sums_key)],
        改變 = feats_key[sums_key <= mean(sums_key)],
        改善 = feats_non[sums_non >  mean(sums_non)],
        劣勢 = feats_non[sums_non <= mean(sums_non)]
      )
      
      # 组织成一个 data.frame: quadrant, text, col, row
      grid_df <- do.call(rbind, lapply(names(quad_feats), function(q) {
        feats <- quad_feats[[q]]
        n     <- length(feats)
        cols  <- ceiling(n/6)
        # assign column and row
        df2 <- data.frame(
          quadrant = q,
          text     = feats,
          idx      = seq_along(feats),
          stringsAsFactors = FALSE
        )
        df2$col <- (df2$idx - 1) %/% 6 + 1
        df2$row <- (df2$idx - 1) %% 6 + 1
        df2
      }))
      
      # 对每个 quadrant 生成 x,y
      # 我们在 2×2 网格里，把 x,y 映射到：
      # 改善(1,2)  訴求(2,2)
      # 劣勢(1,1)  改變(2,1)
      quadrant_pos <- data.frame(
        quadrant = c("改善","訴求","劣勢","改變"),
        gx = c(1,2,1,2),
        gy = c(2,2,1,1)
      )
      grid_df <- merge(grid_df, quadrant_pos, by="quadrant")
      # 每个大格子里的 x: col / (max_col+1)
      grid_df <- grid_df %>%
        group_by(quadrant) %>%
        mutate(
          max_col = max(col),
          x = (col - 0.5) / max_col + (gx-1)*0.5,      # map to [0,1]
          y = 1 - ((row - 0.5) / 6 + (2-gy)*0.5)      # invert y, map to [0,1]
        ) %>% ungroup()
      
      # 加上标题
      titles <- quadrant_pos %>%
        mutate(
          x = (gx-0.5)*0.5,
          y = (gy-0.05)*0.5 + 0.5
        )
      
      p <- ggplot() +
        # 中心轴
        geom_segment(aes(x=0.5,xend=0.5,y=0,yend=1), size=1) +
        geom_segment(aes(x=0,xend=1,y=0.5,yend=0.5), size=1) +
        # 象限标题
        geom_text(data=titles, aes(x=x,y=y,label=quadrant), size=6) +
        # 象限元素
        geom_text(data=grid_df, aes(x=x,y=y,label=text), size=4, color="blue") +
        coord_fixed(xlim=c(0,1), ylim=c(0,1), expand=FALSE) +
        theme_void()
      
      ggplotly(p, tooltip = NULL) %>%
        layout(margin=list(l=10,r=10,t=10,b=10))
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
    # 抓理想点数值
    ideal_vals <- idealFull() %>%
      filter(asin == "Ideal") %>%
      select(where(is.numeric))
    # 抓其它 ASIN 的数值
    df_vals <- idealRaw() %>%
      select(where(is.numeric))
    # 只保留非 sales/rating 的特征
    feature_names <- setdiff(names(df_vals), c("sales", "rating"))
    df_vals <- df_vals[ , feature_names]
    ideal_cmp <- unlist(ideal_vals[1, feature_names])
    mat <- sweep(df_vals, 2, ideal_cmp, FUN = ">") * 1
    ind <- as.data.frame(mat)
    ind$asin <- idealRaw()$asin
    ind
  })
  
  
  # key factors for Ideal & Strategy
  keyVars <- reactive({
    ideal_vals <- idealFull() %>% filter(asin == "Ideal") %>% select(where(is.numeric))
    clean_vals <- ideal_vals %>% select(where(~ !any(is.na(.))))
    names(clean_vals)[ which(unlist(clean_vals[1,]) > mean(unlist(clean_vals[1,]))) ]
  })
  
  # Launch modules, pass indicator and keyVars to both if needed
  pcaModuleServer("pca1",   pcaData)
  idealModuleServer("ideal1", idealFull, idealRaw,indicator = indicator, key_vars = keyVars)
  strategyModuleServer("strat1", indicator, key_vars = keyVars)
}

shinyApp(ui, server)