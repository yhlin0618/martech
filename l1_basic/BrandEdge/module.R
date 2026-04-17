
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
        tags$div(style="color:#888", "請先從左側選好「分類／品牌／Variation」，並且該組資料至少有兩個數值欄，才能看到 PCA 結果。")
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
      req("Ideal" %in% df$Variation)
      df %>%
        filter(Variation == "Ideal") %>%
        select(where(~ is.numeric(.x) && !any(is.na(.x))))
    })
    
    
    #  print(key_vars())
    output$key_factors <- renderText({
      paste("關鍵因素：", paste(key_vars(), collapse = ", "))
    })
    
    output$ideal_rank <- renderDT({
      ind <- indicator()
      df  <- raw() %>% select(Variation, Brand)
      # 計算 Score
      #ind %>% select(-c("Variation","sales","rating")) %>%  rowSums() %>% print()
      df$Score <-   ind %>% select(-any_of(c("Variation","sales","rating"))) %>%  rowSums()
      df <- df %>% filter(Variation != "Ideal") %>% arrange(desc(Score))
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
    selectInput(ns("select_Variation"), "選擇Variation", choices = NULL),
    plotlyOutput(ns("strategy_plot"), height = "800px")
  )
}
strategyModuleServer <- function(id, data, key_vars) {
  moduleServer(id, function(input, output, session) {
    
    observe({
      df <- data()
      req(df)
      updateSelectInput(session, "select_Variation", choices = df$Variation)
    })
    
    output$strategy_plot <- renderPlotly({
      req(input$select_Variation)
      
      # 取出當前 Variation 的 indicator row
      ind       <- data() %>% filter(Variation == input$select_Variation)
      key       <- key_vars()
      feats_key <- key
      feats_non <- setdiff(names(ind), c(key, "Variation"))
      
      sums_key <- colSums(ind[feats_key])
      sums_non <- colSums(ind[feats_non])
      
      # 分象限
      quad_feats <- list(
        訴求 = feats_key[sums_key >  mean(sums_key)],
        改變 = feats_key[sums_key <= mean(sums_key)],
        改善 = feats_non[sums_non >  mean(sums_non)],
        劣勢 = feats_non[sums_non <= mean(sums_non)]
      )
      
      # 通用：把一組特征拆成多列，每列最多6行
      make_multi_col <- function(feats, x_center, y_title, y_step = -1.5) {
        n <- length(feats)
        if (n == 0) return(NULL)
        cols <- ceiling(n / 6)      # 需要的列数
        # split 会产生一个列表
        cols_list <- split(feats, rep(1:cols, each=6, length.out=n))
        # 对每个子列表分别生成数据框
        dfs <- lapply(seq_along(cols_list), function(ci) {
          col_feats <- cols_list[[ci]]
          rows      <- length(col_feats)
          data.frame(
            text = col_feats,
            x    = x_center + (ci - (cols+1)/2) * 3,
            y    = y_title + seq(1, by=y_step, length.out=rows)
          )
        })
        # dfs 本身就是一个 list，直接传给 do.call
        do.call(rbind, dfs)
      }
      
      
      
      specs <- list(
        訴求 = list(x= +5, y=  10),
        改變 = list(x= +5, y=  -1),
        改善 = list(x= -5, y=  10),
        劣勢 = list(x= -5, y=  -1)
      )
      
      # 基础空白坐标系
      p <- plot_ly() %>%
        layout(
          shapes = list(
            list(type='line', x0=0, x1=0, y0=-11, y1=11, line=list(width=2)),
            list(type='line', x0=-11, x1=11, y0=0, y1=0, line=list(width=2))
          ),
          xaxis=list(showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE, range=c(-12,12)),
          yaxis=list(showgrid=FALSE, zeroline=FALSE, showticklabels=FALSE, range=c(-12,12)),
          showlegend=FALSE
        )
      
      # 象限標題
      titles_list <- lapply(names(specs), function(nm) {
        sp <- specs[[nm]]
        data.frame(text = nm, x = sp$x, y = sp$y)
      })
      titles_df <- do.call(rbind, titles_list)
      p <- p %>% add_trace(
        data = titles_df, type='scatter', mode='text',
        x = ~x, y = ~y, text = ~text,
        textfont = list(size=15, color="black")
      )
      
      # 加入每個象限的特征文字
      for (nm in names(quad_feats)) {
        sp    <- specs[[nm]]
        df_c  <- make_multi_col(quad_feats[[nm]], sp$x, sp$y - 2)
        if (!is.null(df_c)) {
          p <- p %>% add_trace(
            data = df_c, type='scatter', mode='text',
            x = ~x, y = ~y, text = ~text,
            textfont = list(size=14, color="blue")
          )
        }
      }
      
      p %>% layout(
        margin = list(l=60, r=60, t=60, b=60), 
        font = list(size = 8)  # 全局字体设为 10
      )
    })
  })
}



## 5. Brand DNA Module -------------------------------------------------------
dnaModuleUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotlyOutput(ns("dna_plot"), height = "600px")
  )
}

dnaModuleServer <- function(id, data_full) {
  moduleServer(id, function(input, output, session) {
    output$dna_plot <- renderPlotly({
      
      
      # pivot 成长表
      dta_Brand_log <- data_full() %>% 
        pivot_longer(
          cols = -c("Variation", "Brand"),
          names_to = "attribute",
          values_to = "score"
        ) %>%
        arrange(Variation, attribute)
      
      # # 保持属性顺序
      # dta_Brand_log$attribute <- factor(
      #   dta_Brand_log$attribute,
      #   levels = unique(dta_Brand_log$attribute)
      # )
      # 
      Variation_groups <- split(dta_Brand_log, dta_Brand_log$Variation)
      dta_Brand_log$attribute <- as.factor(dta_Brand_log$attribute)
      fac_lis <-  dta_Brand_log$attribute
      
      p <- plot_ly()
      
      # 为每个Brand添加一条线
      for (Variation_data in Variation_groups) {
        
        Brand <- unique(Variation_data$Brand)
        p <- add_trace(p,data=Variation_data, x = ~levels(fac_lis), y = ~score, 
                       color=~Brand, type = 'scatter', mode = 'lines+markers', name = Brand,
                       text = ~Variation, hoverinfo = 'text',
                       marker = list(size = 10),  # 设置点的大小
                       line = list(width = 2),     # 设置线的宽度
                       visible = "legendonly"  # 默认隐藏所有内容
        )
      }
      p <- layout(p,
                  #title = "Brand DNA",
                  xaxis = list(
                    title = list(
                      text = "Attribute",
                      font = list(size = 20)  # 设置x轴标题字体大小
                    ),
                    tickangle = -45  # 旋转x轴文本
                  ),
                  yaxis = list(
                    title = "Score",font = list(size = 20)
                  )
                  #           legend = list(
                  #   itemclick = 'toggleothers', # 点击图例时，切换其他图例
                  #   traceorder = 'normal'       # 图例的显示顺序
                  # )
      )
      p
    })
  })
}


