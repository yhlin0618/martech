
#################################################################
#                        定位分析                                #
#################################################################

# 測試代碼
# position_dta_with_na_token <- tbl(app_data,"position_dta") %>%
#   filter(product_line_id == "001") %>%
#   collect() %>%
#   select(where(~ !all(is.na(.)))) %>%
#   dplyr::select(-any_of(c("product_line_id")))%>%
#   rename_with(remove_english_from_chinese)  %>%
#   rename(any_of(position_avoid_ambiguous))
# 
# position_dta_no_na_token <- req(position_dta_with_na_token) %>%
#   select(where(~ !any(is.na(.))), sales, rating)


position_dta_with_na <- reactive({
  #create data
  category <- req(str_extract(input$product_category, "^\\d{3}"))
  
  dta <- tbl(app_data,"position_dta") %>%
    filter(product_line_id == category) %>%
    collect() %>%
    select(where(~ !all(is.na(.)))) %>%
    dplyr::select(-any_of(c("product_line_id"))) %>% 
    rename_with(remove_english_from_chinese)  %>%
    rename(any_of(position_avoid_ambiguous)) 
  
  
  req(nrow(dta) > 0)  # 确保数据非空
  return(dta)
})

position_dta_no_na <- reactive({
  dta2 <- req(position_dta_with_na()) %>%
    select(where(~ !any(is.na(.))), sales, rating) #remove any NA columns
  
  req(nrow(dta2) > 0)  # 确保数据非空
  return(dta2)
})  



observeEvent(input$product_category, {
  position_dta_no_na_token<- req(position_dta_no_na())
  
  updateSelectizeInput(session, "position_brand", choices = req(remove_elements(CreateChoices(position_dta_no_na_token,brand),c("rating","revenue","ideal"))))
  updateSelectizeInput(session, "position_asin", choices = req(remove_elements(CreateChoices(position_dta_no_na_token,asin),c("rating","revenue","ideal"))))
  
  #####Update SA and keyfactor
  wo_Ideal <- position_dta_no_na_token %>% filter(asin!="Ideal")
  dta3 <- wo_Ideal %>% select(-any_of(c(Exclude_Variable$keys,Exclude_Variable$Not_GPTRating)))
  
  
  prin_comp <- prcomp(dta3, rank = 3)
  components <- prin_comp[["x"]]
  tape <- dplyr::select(wo_Ideal,c(asin ,brand)) %>% group_by(brand) %>% mutate(id=asin) %>% 
    mutate(id_brand=asin)
  components <- data.frame(components)
  components <- cbind(components,id_brand=tape$id_brand,brand=tape$brand )
  
  scaling <- 5
  
  Loadx <- prin_comp$rotation
  prin_comp$center
  dim(as.matrix(dta3))
  dim(t(prin_comp$center))
  
  score <- sweep(as.matrix(dta3),2,prin_comp$center)%*% as.matrix(prin_comp$rotation)
  
  brand_plotly_point <- cbind(tape,as.data.frame(score))
  
  loadings0 <- Loadx%>% unclass()%>% as.data.frame()
  loadings0 <- loadings0*scaling
  loadings2 <-  loadings0 %>% as_tibble()%>% mutate(idx=rownames(loadings0))# %>% rename(PC1=PA1, PC2=PA2, PC3=PA3)
  loadings0 <- loadings2 %>% mutate(PC1=0,PC2=0,PC3=0)
  #lodings_a <- loadings2 %>% mutate(PC1=PC1+1,)
  loadings2 <- bind_rows(loadings2,loadings0)
  loadings2 <- loadings2 %>% group_by(idx)
  
  
  # print(brand_plotly_point)
  
  output$Position_FA_plotly <- renderPlotly({
    # fig <- plot_ly(brand_plotly_point, x = ~PC1, y = ~PC2, z = ~PC3) %>% 
    #   add_lines(data=safe_get("brand_plotly_variable"),color = ~idx)
    fig <- plot_ly()
    fig <- add_markers( fig,size=12,
                        x =~PC1, y = ~PC2, z =~PC3, data =brand_plotly_point, 
                        color=~brand,
                        inherit = TRUE,
                        text = ~ id_brand, hoverinfo = 'text')%>%
      add_lines(data=loadings2,color = ~idx) %>% 
      layout(scene = list(
        xaxis = list(title = "主成分 1"),
        yaxis = list(title = "主成分 2"),
        zaxis = list(title = "主成分 3")
      ))
    fig
  })
  
  
  # : loadings2 (loading 包含0點) 屬性方向標
  # components 轉換後的資料(不包含理想點)
  
  # 理想點 轉換 (如果要對資料的話，要在246 把mutatye 換一下才能和component 串起來)
  Ideal2 <- (position_dta_no_na_token %>% filter(asin=="Ideal")) %>% 
    select(-any_of(c(Exclude_Variable$keys,Exclude_Variable$Not_GPTRating)))
  trans_ideal <- Ideal2 %>% as.matrix()%*%Loadx %>% as_tibble() %>% 
    #mutate(Type=c("Rating","Revenue","Ideal"))
    mutate(Type="Ideal") %>% 
    rename(any_of(c("Comp.1"="PC1","Comp.2"="PC2","Comp.3"="PC3")))
  
  dataideal <- position_dta_no_na_token  %>% select(-any_of(Exclude_Variable$keys))
  
  Indicator <- matrix(0, nrow = dim(dataideal)[1], ncol = dim(dataideal)[2]) %>% data.frame()
  
  for (i in 1:dim(dataideal)[2]) {
    idx_val <- as.data.frame(Ideal2)[which(names(Ideal2)==names(dataideal)[i])]
    Indicator[,i] <- as.data.frame(dataideal[,i])>as.numeric(idx_val)
  }
  Indicator <- Indicator+0
  
  gate1 <- rowSums(Ideal2)/dim(Ideal2)[2]
  # 關鍵因素評估
  Key_fac <- colnames(Ideal2)[Ideal2>gate1]
  # 標竿分析
  
  output$Position_KFE <- renderText({
    paste("關鍵因素: ",paste(Key_fac, collapse=", "))
  })
  
  
  Bench_mark <- list()
  for (i in 1:length(Key_fac)) {
    Bench_mark[[i]] <- position_dta_no_na_token$asin[dplyr::select(Indicator,Key_fac[i])[,1]==1] %>% 
      unique()
  }
  names(Bench_mark) <- Key_fac
  
  # 理想點分析
  # Q 試算距離還是什麼?
  IA <- dplyr::select(Indicator,any_of(Key_fac))
  IA <- IA %>% mutate(.,Score =rowSums(IA))
  IA <- cbind(IA,brand=position_dta_no_na_token$brand,asin=position_dta_no_na_token$asin)
  IA_lis <- IA %>% arrange(desc(Score))
  
  output$Ideal_rate_data <- renderDT({
    
    IA_lis %>% 
      dplyr::select(.,Score,brand,asin) %>% 
      filter(asin != "Ideal")%>% 
      rename(any_of(renamechinese))
  },
  options = list(
    pageLength = -1,  # 展示所有行
    searching = FALSE,  # 禁用搜尋框
    lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
    info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
    paging = FALSE,  # 禁用分頁
    columnDefs = list(
      list(visible = FALSE, targets = 0)
    ),
    scrollX = FALSE
  ))
  
  
  # 策略分析
  SA <- cbind(Indicator,brand=position_dta_no_na_token$brand,asin=position_dta_no_na_token$asin)
  
  #SA_token<<-SA
  #SA<- SA_token
  ###策略分析
  
  observeEvent(input$SA, {
    SA_token <- SA %>% remove_na_columns()  #sales跟rating去掉
    sub_SA <- filter(SA_token, asin == input$SA)
    sub_dir <- colSums(select_if(select(sub_SA, Key_fac), is.numeric))
    sub_dir_not_key <- colSums(select_if(select(sub_SA, -Key_fac), is.numeric))
    
    format_keys <- function(keys) {
      result <- ""
      # 遍历键并根据索引位置添加 \t 或 \n
      for (i in seq_along(keys)) {
        if (i %% 2 == 1) {  # 奇数索引，添加 \t
          result <- paste0(result, keys[i], "\t\t")
        } else {  # 偶数索引，添加 \n
          result <- paste0(result, keys[i], "\n")
        }
      }
      # 返回最终结果
      return(result)
    }
    
    not_key <- names(sub_dir_not_key)
    arguement_text <- format_keys(Key_fac[sub_dir > mean(sub_dir)])
    improvement_text <- format_keys(not_key[sub_dir_not_key > mean(sub_dir_not_key)])
    weakness_text <- format_keys(not_key[sub_dir_not_key <= mean(sub_dir_not_key)])
    changing_text <- format_keys(Key_fac[sub_dir <= mean(sub_dir)])
    
    # Function to adjust font size based on text length
    adjust_font_size <- function(text) {
      n <- nchar(text)
      if (n <= 30) {
        return(h1.fontsize)  # Larger font for shorter text
      } else if (n <= 35) {
        return(h2.fontsize)  # Medium font if text is moderately long
      } else if (n <= 45) {
        return(h3.fontsize)  # Medium font if text is moderately long
      } else if (n <= 50) {
        return(h4.fontsize)  # Medium font if text is moderately long
      } else if (n <= 60) {
        return(h5.fontsize)  # Medium font if text is moderately long
      } else {
        return(h6.fontsize)  # Smaller font for very long text
      }
    }
    
    output$Position_Strategy <- renderPlotly({
      
      # Create the plot
      p <- plot_ly() %>%
        add_trace(
          type = 'scatter', mode = 'text',
          x = c(5, -5, -5, 5), y = c(9, 9, -2, -2),
          text = c("訴求", "改善", "劣勢", "改變"),
          textfont = list(color = "blue",size=h1.fontsize)
        ) %>%
        add_trace(
          type = 'scatter', mode = 'text',
          x = c(5, -5, -5, 5), y = c(5, 5, -7, -7),
          text = c(arguement_text, improvement_text, weakness_text, changing_text),
          textfont = list(size = c(adjust_font_size(arguement_text), adjust_font_size(improvement_text),
                                   adjust_font_size(weakness_text), adjust_font_size(changing_text)), 
                          color = "blue")
        ) %>%
        layout(
          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(-10, 10)),
          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, range = c(-10, 10)),
          plot_bgcolor = 'white',
          showlegend = FALSE
          #hoverlabel = list(align = "left")
        )
      
      # Adding arrows as shapes
      p <- p %>%
        layout(
          shapes = list(
            list(
              type = 'line', x0 = 0, x1 = 0, y0 = -10, y1 = 10,
              line = list(color = "black", width = 2)
            ),
            list(
              type = 'line', x0 = -10, x1 = 10, y0 = 0, y1 = 0,
              line = list(color = "black", width = 2)
            )
          )
        )
      
      p
    })
  })
  
})

observeEvent(list(input$product_category,input$position_brand),{
  updateSelectizeInput(session, "position_asin", 
                       choices = req(getDynamicOptions(input$position_brand,position_dta_no_na(),brand,asin)))
})

######呈現position表格的資料##########
observeEvent(list(input$position_asin),{
  
  position_dta_with_na_token<- position_dta_with_na()
  position_dta_new<- position_dta_with_na_token    %>% 
    dplyr::mutate_if(is.numeric, round, digits = 1) %>%
    relocate(any_of(c("rating", "sales")), .after = last_col())%>% 
    relocate(any_of(c("asin", "brand")), .before = everything())
  
  Idealfoot <- position_dta_new %>% filter(asin=="Ideal") %>% select(-any_of(Exclude_Variable$Not_GPTRating))
  
  Idealcontainer <- htmltools::tags$table(
    tableHeader(c("",names(position_dta_new %>%  
                             dplyr::rename(any_of(renamechinese))))),
    tableFooter(c("","理想點","",Idealfoot[-c(1,2)]))
  )   
  
  
  output$Position_Selected_data <- renderDT({
    position_dta_new %>% 
      filter(asin %in% input$position_asin,!asin=="Ideal") %>% 
      arrange(desc(brand == brand_name)) %>%  
      dplyr::rename(any_of(renamechinese))
    
  }, container = Idealcontainer,
  extensions = c("Buttons","FixedHeader"),
  options = list(
    dom = 'Bfrtip',  # 顯示下載按鈕
    buttons = list(
      list(
        extend = 'excel',  # 設定按鈕類型為 CSV
        text = '品牌定位資料',  # 設定按鈕上顯示的文字
        filename = '品牌定位資料'  # 設定下載的檔案名稱
      )
    ),
    pageLength = -1,  # 展示所有行
    searching = FALSE,  # 禁用搜尋框
    lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
    info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
    paging = FALSE,  # 禁用分頁
    columnDefs = list(
      list(visible = FALSE, targets = 0)
    ),
    scrollX = FALSE
  ))
})




output$Position_DNA_plotly <- renderPlotly({
  position_dta_with_na_token <- position_dta_with_na()
  
  dta_brand_log <- position_dta_with_na_token %>% 
    select(-any_of(Exclude_Variable$Not_GPTRating)) %>%
    pivot_longer(cols=-c("asin","brand"),names_to = "attribute",values_to = "score") %>%
    arrange(asin ,attribute)
  
  asin_groups <- split(dta_brand_log, dta_brand_log$asin)
  dta_brand_log$attribute <- as.factor(dta_brand_log$attribute)
  fac_lis <-  dta_brand_log$attribute
  
  p <- plot_ly()
  
  # 为每个brand添加一条线
  for (asin_data in asin_groups) {
    
    brand <- unique(asin_data$brand)
    p <- add_trace(p,data=asin_data, x = ~levels(fac_lis), y = ~score, 
                   color=~brand, type = 'scatter', mode = 'lines+markers', name = brand,
                   text = ~asin, hoverinfo = 'text',
                   marker = list(size = 10),  # 设置点的大小
                   line = list(width = 2),     # 设置线的宽度
                   visible = "legendonly"  # 默认隐藏所有内容
    )
  }
  p <- layout(p,
              #title = "brand DNA",
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



# 關鍵因素理想點分析

observeEvent(list(input$product_category), {
  
  position_dta_no_na_token <- position_dta_no_na()
  
  df_withoutname <- position_dta_no_na_token %>% select(-any_of(c(Exclude_Variable$Not_GPTRating,Exclude_Variable$keys)))
  
  df_modified <- position_dta_no_na_token %>% select(-any_of(c(Exclude_Variable$Not_GPTRating,Exclude_Variable$keys))) %>%
    mutate(across(
      .cols = everything(),
      .fns = ~ ifelse(. < mean(.), mean(.), .)
    ))
  similarity_matrix <- t(df_modified) %>%
    cor(use = "pairwise.complete.obs")
  Pearson_dist <- as.dist(1 - similarity_matrix)
  
  
  hc_eu <- hclust(Pearson_dist, method = "complete")
  h <- (min(Pearson_dist)+max(Pearson_dist))/2
  clusterCut <- cutree(hc_eu, h = h)
  
  ## MDS
  d <- dist(df_withoutname) # euclidean distances between the rows
  fit <- MASS::isoMDS(d, k = 2) # k is the number of dim
  
  CSA <- position_dta_no_na_token
  CSA$xMDS <- fit$points[, 1]
  CSA$yMDS <- fit$points[, 2]
  
  CSA$group <- as.factor(clusterCut)
  
  CSA$shapes <- "circle"
  CSA$shapes[str_detect(CSA$brand, brand_name)] <- "star"
  CSA <- CSA %>%  group_by(group)
  
  output$Position_CSA_plot <- renderPlotly({
    p <-  plot_ly(
      CSA,
      x =  ~ xMDS,
      y =  ~ yMDS,
      color =  ~ group,
      mode = 'markers',
      symbol =  ~ shapes,
      text =  ~ paste('品牌:', brand, '<br> asin:', asin),
      hoverinfo = 'text',
      size = 3
    )
    p
  })
  
  # observeEvent(input$group_num, {
  #   output$selected_cl <-  DT::renderdataTable({
  #     CSA %>% filter(., group == input$group_num) %>% mutate_if(., is.numeric, round, 2)#%>% datatable(.) %>%  formatRound(., 3)
  #   })
  #   
  # })
  
})

  
  