################################################################################
# test_upload_complete_score.R - 測試已完成評分上傳模組
################################################################################

library(shiny)
library(bs4Dash)
library(DT)
library(dplyr)
library(readxl)

# 載入新的上傳模組
source("modules/module_upload_complete_score.R")

# 載入分析模組（如果需要）
source("modules/module_wo_b_v2.R")

# UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "InsightForge Premium - 已評分資料上傳測試",
    status = "primary"
  ),
  sidebar = bs4DashSidebar(
    sidebarMenu(
      id = "sidebar",
      menuItem(
        text = "上傳已評分資料",
        tabName = "upload",
        icon = icon("upload")
      ),
      menuItem(
        text = "分析結果",
        tabName = "analysis",
        icon = icon("chart-bar")
      )
    )
  ),
  body = bs4DashBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
      "))
    ),
    tabItems(
      # 上傳頁面
      tabItem(
        tabName = "upload",
        fluidRow(
          column(12,
            bs4Card(
              title = "上傳已完成評分的資料",
              status = "primary",
              width = 12,
              maximizable = TRUE,
              uploadCompleteScoreUI("upload_module")
            )
          )
        )
      ),
      
      # 分析頁面
      tabItem(
        tabName = "analysis",
        fluidRow(
          column(12,
            bs4Card(
              title = "資料分析",
              status = "success",
              width = 12,
              maximizable = TRUE,
              div(id = "analysis_content",
                  h4("請先上傳資料"),
                  uiOutput("analysis_ui")
              )
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # 使用者ID（測試用）
  user_id <- reactive({ "test_user" })
  
  # 呼叫上傳模組
  upload_result <- uploadCompleteScoreServer("upload_module", user_id())
  
  # 監控資料確認事件
  observeEvent(upload_result$confirm(), {
    if (upload_result$confirm() > 0) {
      # 切換到分析頁面
      updateTabItems(session, "sidebar", "analysis")
      showNotification("資料已確認，開始進行分析", type = "success")
    }
  })
  
  # 生成分析介面
  output$analysis_ui <- renderUI({
    req(upload_result$data_ready())
    
    tagList(
      h4("資料摘要"),
      
      # 顯示基本統計
      fluidRow(
        column(4,
          bs4InfoBox(
            title = "產品數量",
            value = nrow(upload_result$score_data()),
            icon = icon("box"),
            color = "primary",
            width = 12
          )
        ),
        column(4,
          bs4InfoBox(
            title = "屬性數量",
            value = length(upload_result$attribute_columns()),
            icon = icon("tags"),
            color = "info",
            width = 12
          )
        ),
        column(4,
          bs4InfoBox(
            title = "銷售記錄",
            value = ifelse(is.null(upload_result$sales_data()), 
                           "無", 
                           nrow(upload_result$sales_data())),
            icon = icon("shopping-cart"),
            color = "success",
            width = 12
          )
        )
      ),
      
      br(),
      
      # 分析選項
      tabsetPanel(
        tabPanel("屬性排名",
          br(),
          DTOutput("attribute_ranking")
        ),
        tabPanel("產品表現",
          br(),
          DTOutput("product_performance")
        ),
        tabPanel("視覺化分析",
          br(),
          plotOutput("visualization", height = "500px")
        ),
        if (!is.null(upload_result$sales_data())) {
          tabPanel("銷售分析",
            br(),
            h5("Poisson 迴歸分析"),
            verbatimTextOutput("poisson_results")
          )
        }
      )
    )
  })
  
  # 屬性排名表
  output$attribute_ranking <- renderDT({
    req(upload_result$score_data())
    
    score_data <- upload_result$score_data()
    attr_cols <- upload_result$attribute_columns()
    
    # 計算每個屬性的統計
    attr_stats <- data.frame(
      屬性 = attr_cols,
      平均分 = round(colMeans(score_data[attr_cols], na.rm = TRUE), 3),
      標準差 = round(apply(score_data[attr_cols], 2, sd, na.rm = TRUE), 3),
      最小值 = round(apply(score_data[attr_cols], 2, min, na.rm = TRUE), 3),
      最大值 = round(apply(score_data[attr_cols], 2, max, na.rm = TRUE), 3),
      stringsAsFactors = FALSE
    )
    
    # 排序
    attr_stats <- attr_stats[order(attr_stats$平均分, decreasing = TRUE), ]
    attr_stats$排名 <- seq_len(nrow(attr_stats))
    
    # 重新排列欄位
    attr_stats <- attr_stats[, c("排名", "屬性", "平均分", "標準差", "最小值", "最大值")]
    
    datatable(attr_stats, 
              options = list(pageLength = 15, dom = 'ft'),
              rownames = FALSE) %>%
      formatStyle("平均分",
                  background = styleColorBar(attr_stats$平均分, 'lightblue'),
                  backgroundSize = '98% 88%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center')
  })
  
  # 產品表現表
  output$product_performance <- renderDT({
    req(upload_result$score_data())
    
    score_data <- upload_result$score_data()
    
    # 選擇顯示欄位
    display_data <- score_data %>%
      select(product_id, product_name, avg_score, total_score) %>%
      arrange(desc(avg_score))
    
    datatable(display_data,
              options = list(pageLength = 20, scrollX = TRUE),
              rownames = FALSE) %>%
      formatRound(columns = c("avg_score"), digits = 2)
  })
  
  # 視覺化分析
  output$visualization <- renderPlot({
    req(upload_result$score_data())
    
    score_data <- upload_result$score_data()
    attr_cols <- upload_result$attribute_columns()
    
    # 創建熱圖
    # 取前20個產品
    top_products <- head(score_data, 20)
    
    # 準備矩陣資料
    heatmap_data <- as.matrix(top_products[, attr_cols])
    rownames(heatmap_data) <- substr(top_products$product_name, 1, 30)
    
    # 繪製熱圖
    heatmap(heatmap_data,
            Colv = NA,
            scale = "column",
            col = colorRampPalette(c("white", "#3498db", "#2ecc71"))(100),
            margins = c(10, 15),
            main = "產品屬性評分熱圖 (前20個產品)",
            xlab = "屬性",
            ylab = "產品")
  })
  
  # Poisson 迴歸分析（如果有銷售資料）
  output$poisson_results <- renderPrint({
    req(upload_result$sales_data())
    req(upload_result$score_data())
    
    # 合併資料
    score_data <- upload_result$score_data()
    sales_data <- upload_result$sales_data()
    
    # 彙總銷售資料
    sales_summary <- sales_data %>%
      group_by(product_id) %>%
      summarise(total_sales = sum(Sales, na.rm = TRUE))
    
    # 合併評分和銷售
    analysis_data <- merge(score_data, sales_summary, by = "product_id")
    
    # 對每個屬性執行 Poisson 迴歸
    attr_cols <- upload_result$attribute_columns()
    
    results <- list()
    for (attr in attr_cols) {
      formula_str <- paste("total_sales ~", attr)
      model <- glm(as.formula(formula_str), 
                   data = analysis_data,
                   family = poisson(link = "log"))
      
      coef_val <- coef(model)[2]
      p_value <- summary(model)$coefficients[2, 4]
      
      # 計算賽道倍數和邊際效應
      track_multiplier <- exp(coef_val * 4)  # 假設分數範圍是1-5
      marginal_effect <- (exp(coef_val) - 1) * 100
      
      results[[attr]] <- list(
        coefficient = round(coef_val, 4),
        p_value = round(p_value, 4),
        track_multiplier = round(track_multiplier, 2),
        marginal_effect = round(marginal_effect, 2),
        significant = p_value < 0.05
      )
    }
    
    # 排序並顯示結果
    results_df <- do.call(rbind, lapply(names(results), function(x) {
      c(attribute = x, results[[x]])
    }))
    
    print("Poisson 迴歸分析結果:")
    print("=" * 60)
    print(results_df)
  })
}

# 執行應用
shinyApp(ui, server)