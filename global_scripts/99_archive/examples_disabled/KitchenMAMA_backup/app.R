# Ensure necessary libraries are loaded
library(shiny)
library(gridlayout)
library(bslib)
library(bsicons)
library(DT)
library(sjmisc)
library(httr)
library(jsonlite)
library(psych)
library(openxlsx)
library(shinyjs)
library(NbClust)
library(caret)
library(patchwork)
library(arrow)
library(RColorBrewer)
library(sf)
library(tidyverse)
library(lubridate)
library(cowplot)
library(leaflet)
library(scales)
library(leaflet)
library(plotly)
library(treemap)
library(DBI)
library(duckdb)
library(dbplyr)
library(DBI)
library(duckdb)
library(dbplyr)




#library(httr2)

# data manipulation and visualization
select <- dplyr::select

###Read database

app_data<- dbConnect(duckdb(), dbdir = file.path("app_data.duckdb"), read_only = TRUE)
dbListTables(app_data) 

###在跑shiny以前要做的事情
source("global.R")
source("brand_specific_parameters.R")
#source("./Scripts/Combine KMsales.R")


###CSS settings

h1.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h1-font-size")), "[0-9\\.]+"))*16
h2.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h2-font-size")), "[0-9\\.]+"))*16
h3.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h3-font-size")), "[0-9\\.]+"))*16
h4.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h4-font-size")), "[0-9\\.]+"))*16
h5.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h5-font-size")), "[0-9\\.]+"))*16
h6.fontsize <- as.numeric(str_extract(bs_get_variables(bs_theme(), varnames = c("h6-font-size")), "[0-9\\.]+"))*16


###initial values


item_property_dictionary <- tbl(app_data,"item_property_dictionary")
asin_to_item_dictionary <- tbl(app_data,"asin_to_item_dictionary")
Demo_bind_data <- safe_get("Demo_bind_data")

amazon_Precision_Marketing_incidencerate_long_001_Electric_Can_Opener_Dta <- 
  safe_get("amazon_Precision_Marketing_incidencerate_long_001_Electric_Can_Opener_Dta")%>% 
  rename(any_of(renametemp)) %>% 
  rename_with(make_names)


advertise_generation_dta <- tbl(app_data,"advertise_generation_dta") %>% collect()

time_potential <- safe_get("amazon_time_potential_001_B07FVQLBL3_dta")%>% rename_with(make_names)

time_potential_asin_vec <- safe_get("amazon_time_potential_asin_001_vec")

var_names_vec <- safe_get("amazon_time_potential_var_names_001_vec")



Advertise_Text <- list(
  value_box(
    tags$h2("購物欄推薦序1st"),
    tags$h3(textOutput("Advertise_recommendation_product_line_1")),
    tags$h3(textOutput("Advertise_recommendation_asin_1")),
    tags$h6(textOutput("Advertise_recommendation_1"), style = "color: black;")
  ) ,
  
  value_box(
    tags$h2("購物欄推薦序2nd"),
    tags$h3(textOutput("Advertise_recommendation_product_line_2")),
    tags$h3(textOutput("Advertise_recommendation_asin_2")),
    tags$h6(textOutput("Advertise_recommendation_2"), style = "color: black;")
  ),
  value_box(
    tags$h2("購物欄推薦序3rd"),
    tags$h3(textOutput("Advertise_recommendation_product_line_3")),
    tags$h3(textOutput("Advertise_recommendation_asin_3")),
    tags$h6(textOutput("Advertise_recommendation_3"), style = "color: black;")
  )  
)

vbs <- list(
  value_box(
    title = "顧客資歷",
    value = textOutput("dna_time_first"),
    showcase = bs_icon("calendar-event-fill") ,
    p(textOutput("dna_time_first_tonow", inline = TRUE),"天")
  ) ,
  
  value_box(
    title = "最近購買日(R)",
    value = textOutput("dna_rlabel"),
    showcase = bs_icon("calendar-event-fill"),
    p(textOutput("dna_rvalue", inline = TRUE),"天前")
  ),
  value_box(
    title = "購買頻率(F)",
    value = textOutput("dna_flabel"),
    showcase = bs_icon("plus-lg"),
    p(textOutput("dna_fvalue", inline = TRUE),"次")
  ),
  value_box(
    title = "購買金額(M)",
    value = textOutput("dna_mlabel"),
    showcase = bs_icon("pie-chart"),
    p(textOutput("dna_mvalue", inline = TRUE),"美金")
  ),
  value_box(
    title = "顧客活躍度(CAI)",
    value = textOutput("dna_cailabel"),
    showcase = bs_icon("pie-chart"),
    p("CAI = ", textOutput("dna_cai", inline = TRUE))
  ),
  value_box(
    title = "顧客平均購買週期(IPT)",
    value = div(
      textOutput("dna_ipt_mean", inline = TRUE),  # 動態數據
      " 天"  # 靜態文本
    ),
    showcase = bs_icon("pie-chart"),
  ),
  value_box(
    title = "過去價值(PCV)",
    value = div(
      textOutput("dna_pcv", inline = TRUE),
      " 美金"
    ),
    showcase = bs_icon("pie-chart")
  ),
  value_box(
    title = "顧客終身價值(CLV)",
    value = div(
      textOutput("dna_clv", inline = TRUE),
      " 美金"
    ),
    showcase = bs_icon("pie-chart")
  ),
  value_box(
    title = "顧客交易穩定度 (CRI)",
    value = textOutput("dna_cri"),
    showcase = bs_icon("pie-chart")
  ),
  value_box(
    title = "顧客停止購買預測",
    value = textOutput("dna_nrec"),
    showcase = bs_icon("pie-chart"),
    p("停止機率 = ", textOutput("dna_nrec_onemin_prob",inline=T))
  ) ,
  value_box(
    title = "顧客狀態(NES)",
    value = textOutput("dna_nesstatus"),
    showcase = bs_icon("pie-chart")
  ) ,
  value_box(
    title = "新客單價",
    value = textOutput("dna_nt"),
    p("美金"),
    showcase = bs_icon("pie-chart")
  ) ,
  value_box(
    title = "主力客單價",
    value = textOutput("dna_e0t"),
    p("美金"),
    showcase = bs_icon("pie-chart") 
  )  
)

macros <- list(
  value_box(
    title = "銷售額",
    value = textOutput("total_now"),
    showcase = uiOutput("total_diff"),
    p(
      "成長率 = ", 
      span(textOutput("total_diff_perc", inline = TRUE))
    )
  ) ,
  
  value_box(
    title = "人均購買金額",
    value = textOutput("average_now"),
    showcase = uiOutput("average_diff"),
    p(
      "成長率 = ", 
      span(textOutput("average_diff_perc", inline = TRUE))
    )
  ),
   value_box(
     title = "顧客總數",
     value = textOutput("num_customers_now"),
     showcase = uiOutput("num_customers_diff"),
     p(
       "成長率 = ", 
       span(textOutput("num_customers_diff_perc", inline = TRUE))
     )
   ),
  value_box(
    title = "累積顧客數",
    value = textOutput("cum_customers_now"),
    showcase = uiOutput("cum_customers_diff"),
    p(
      "成長率 = ", 
      span(textOutput("cum_customers_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "顧客留存率",
    value = textOutput("customer_retention_rate_now_perc"),
    showcase = uiOutput("customer_retention_rate_diff"),
    p(
      "成長率 = ", 
      span(textOutput("customer_retention_rate_diff_value_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "顧客新增率",
    value = textOutput("customer_acquisition_rate_now_perc"),
    showcase = uiOutput("customer_acquisition_rate_diff"),
    p(
      "成長率 = ", 
      span(textOutput("customer_acquisition_rate_diff_value_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "顧客變動率",
    value = textOutput("E0_nes_prop_1_now_perc"),
    showcase = uiOutput("E0_nes_prop_1_diff")
    # p(
    #   "成長率 = ", 
    #   span(textOutput("CustomerAcquisitionRate.value_diff_perc", inline = TRUE))
    # )
  ),
  value_box(
    title = "顧客流失率",
    value = textOutput("S3_nes_prop_1_now_perc"),
    showcase = uiOutput("S3_nes_prop_1_diff")
    # p(
    #   "成長率 = ", 
    #   span(textOutput("CustomerAcquisitionRate.value_diff_perc", inline = TRUE))
    # )
  ),
  value_box(
    title = "顧客轉化率",
    value = textOutput("N_to_E0_prop_perc"),
    showcase = uiOutput("N_to_E0_prop_diff")
  ),
  value_box(
    title = "首購客比例（N）",
    value = textOutput("N_nes_prop_now_perc"),
    showcase = uiOutput("N_nes_prop_diff"),
    p(
      "人數 = ", 
      span(textOutput("N_nes_count_now", inline = TRUE)),
      "(",
      span(textOutput("N_nes_count_diff_value", inline = TRUE)),
      ")"
    ),
    p(
      "成長率 = ", 
      span(textOutput("N_nes_prop_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "主力客（E0）比例",
    value = textOutput("E0_nes_prop_now_perc"),
    showcase = uiOutput("E0_nes_prop_diff"),
    p(
      "人數 = ", 
      span(textOutput("E0_nes_count_now", inline = TRUE)),
      "(",
      span(textOutput("E0_nes_count_diff_value", inline = TRUE)),
      ")"
    ),
    p(
      "成長率 = ", 
      span(textOutput("E0_nes_prop_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "瞌睡客（S1）比例",
    value = textOutput("S1_nes_prop_now_perc"),
    showcase = uiOutput("S1_nes_prop_diff"),
    p(
      "人數 = ", 
      span(textOutput("S1_nes_count_now", inline = TRUE)),
      "(",
      span(textOutput("S1_nes_count_diff_value", inline = TRUE)),
      ")"
    ),
    p(
      "成長率 = ", 
      span(textOutput("S1_nes_prop_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "半睡顧客數（S2）",
    value = textOutput("S2_nes_prop_now_perc"),
    showcase = uiOutput("S2_nes_prop_diff"),
    p(
      "人數 = ", 
      span(textOutput("S2_nes_count_now", inline = TRUE)),
      "(",
      span(textOutput("S2_nes_count_diff_value", inline = TRUE)),
      ")"
    ),
    p(
      "成長率 = ", 
      span(textOutput("S2_nes_prop_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "沉睡顧客數（S3）",
    value = textOutput("S3_nes_prop_now_perc"),
    showcase = uiOutput("S3_nes_prop_diff"),
    p(
      "人數 = ", 
      span(textOutput("S3_nes_count_now", inline = TRUE)),
      "(",
      span(textOutput("S3_nes_count_diff_value", inline = TRUE)),
      ")"
    ),
    p(
      "成長率 = ", 
      span(textOutput("S3_nes_prop_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "新客單價",
    value = textOutput("N_nes_mmean_now"),
    showcase = uiOutput("N_nes_mmean_diff"),
    p(
      "成長率 = ", 
      span(textOutput("N_nes_mmean_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "主力客單價",
    value = textOutput("E0_nes_mmean_now"),
    showcase = uiOutput("E0_nes_mmean_diff"),
    p(
      "成長率 = ", 
      span(textOutput("E0_nes_mmean_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "顧客終生價值",
    value = textOutput("macro_clv_now"),
    showcase = uiOutput("macro_clv_diff"),
    p(
      "成長率 = ", 
      span(textOutput("macro_clv_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "交易穩定度",
    value = textOutput("macro_cri_now"),
    showcase = uiOutput("macro_cri_diff"),
    p(
      "成長率 = ", 
      span(textOutput("macro_cri_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "靜止戶預測",
    value = textOutput("macro_nrec_now"),
    showcase = uiOutput("macro_nrec_diff"),
    p(
      "成長率 = ", 
      span(textOutput("macro_nrec_diff_perc", inline = TRUE))
    )
  ),
  value_box(
    title = "顧客活躍度",
    value = textOutput("macro_cai_now"),
    showcase = uiOutput("macro_cai_diff"),
    p(
      "成長率 = ", 
      span(textOutput("macro_cai_diff_perc", inline = TRUE))
    )
  )
)



ui <- page_navbar(
  title = "AI行銷科技平台",
  selected = "宏觀銷售分析",
  collapsible = TRUE,
  theme = bslib::bs_theme(
              preset = "cerulean",
              base_font = font_google("Noto Sans TC", wght = "400", ital = 0, local = FALSE),
              code_font = font_google("Noto Sans TC", wght = "400", ital = 0, local = FALSE),
              heading_font = font_google("Noto Sans TC", wght = "600", ital = 0, local = FALSE)
            ),
  sidebar = sidebar(
    title = "選項",
    radioButtons(
      inputId = "distribution_channel",
      label = "行銷通路",
      choices = list(
        "Amazon" = "amazon",
        "Official Website" = "officialwebsite"
      ),
      selected = "officialwebsite",
      width = "100%"
    ),
    radioButtons(
      inputId = "product_category",
      label = "商品種類",
      choices = product_line_dictionary,
      selected = "001",
      width = "100%"
    )
  ),
  # 添加 CSS 樣式到頁面頭部,,,,,
  tags$head(
              tags$style(HTML("
                .bslib-value-box .value-box-value {
                  font-size: 16px !important; /* 調整字體大小 */
                }
                .bslib-value-box .value-box-title {
                  font-size: 18px !important; /* 調整標題字體大小 */
                }
              "))
            ),
  nav_panel(
    title = "宏觀銷售分析",
    tabsetPanel(
      selected = "宏觀分析",
      nav_panel(
        title = "宏觀分析",
        grid_container(
          layout = c(
            "area0 area1"
          ),
          row_sizes = c(
            "700px"
          ),
          col_sizes = c(
            "250px",
            "1.48fr"
          ),
          gap_size = "10px",
          grid_card(
            area = "area0",
            full_screen = TRUE,
            card_body(
              selectInput(
                inputId = "time_scale_profile",
                label = "時間尺度",
                choices = list("year" = "year", "quarter" = "quarter", "month" = "month"),
                selected = "quarter"
              ),
              selectizeInput(inputId = "Geo_Macro_Profile", 
                                                                                                                                                                                 label   = "地區（州或全部）"
                                                                                                                                                                                 , choices = setNames(as.list(state_dictionary$abbreviation), state_dictionary$name),
                                                                                                                                                                                 multiple = FALSE,
                                                                                                                                                                                 options = list(plugins = list('remove_button', 'drag_drop')))
            )
          ),
          grid_card(
            area = "area1",
            card_body(
              full_screen = TRUE,
              layout_column_wrap(
                                                                                                                                                                    width = "180px",
                                                                                                                                                                    fill = FALSE,
                                                                                                                                                                    !!!macros
                                                                                                                                                                  )
            )
          )
        )
      ),
      nav_panel(
        title = "喚醒率矩陣",
        grid_container(
          layout = c(
            "area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "1fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              plotlyOutput(outputId = "nes_transition_Plotly")
            )
          )
        )
      ),
      nav_panel(
        title = "銷售趨勢",
        card(
          full_screen = TRUE,
          card_body(
            grid_container(
              layout = c(
                "area0",
                "area1"
              ),
              gap_size = "10px",
              col_sizes = c(
                "1fr"
              ),
              row_sizes = c(
                "200px",
                "500px"
              ),
              grid_card(
                area = "area0",
                card_body(
                  DTOutput(outputId = "sales_pattern", width = "100%")
                )
              ),
              grid_card(
                area = "area1",
                card_body(plotlyOutput(outputId = "sales_pattern_Plot"))
              )
            )
          )
        )
      ),
      nav_panel(
        title = "顧客新增率",
        card(
          full_screen = TRUE,
          card_body(
            grid_container(
              layout = c(
                "area0 area0",
                "area1 area1"
              ),
              gap_size = "10px",
              col_sizes = c(
                "1fr",
                "1fr"
              ),
              row_sizes = c(
                "200px",
                "500px"
              ),
              grid_card(
                area = "area0",
                card_body(
                  DTOutput(
                    outputId = "customer_acquisition_rate",
                    width = "100%"
                  )
                )
              ),
              grid_card(
                area = "area1",
                card_body(
                  plotlyOutput(outputId = "customer_acquisition_rate_Plot")
                )
              )
            )
          )
        )
      ),
      nav_panel(
        title = "顧客宏觀地理分佈",
        leafletOutput("salesmap", width = "100%", height = "600px"),
        absolutePanel(
                          id = "controls",
                          class = "panel panel-default",
                          fixed = TRUE,
                          draggable = TRUE,
                          top = 140, left = "auto", right = 40, bottom = "auto",
                          width = 210, height = "auto",
                          style = "background-color: rgba(255, 255, 255, 0.9); 
                           padding: 15px; 
                           border-radius: 10px; 
                           box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);",
                          
                           div(selectInput(
                            inputId = "geo_salesmap",
                            label = "地理位置單位",
                            choices = list("州" = "state", "地區" = "local")
                          ),
                          style = "margin-bottom: 20px;"), 
                          
                          selectInput(
                            inputId = "macro_salesmap",
                            label = "宏觀分析指標",
                            choices = list(
                              "新客數"="new_customers",
                              "來客數"="num_customers",
                              "累積顧客數"="cum_customers",
                              "顧客成長率"= "customer_acquisition_rate",
                              "顧客留存率"="customer_retention_rate",
                              "總銷售"="total",
                              "與上期差異"="total_difference",
                              "銷售成長率"="total_change_rate",
                              "平均銷售"="average"
                            )
                          )
                        )
      ),
      nav_item(HTML("&nbsp;&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;&nbsp;")),
      nav_panel(
        title = "產品競爭銷售趨勢",
        grid_container(
          layout = c(
            "area0 area1",
            "area0 area2"
          ),
          gap_size = "10px",
          col_sizes = c(
            "250px",
            "1.5fr"
          ),
          row_sizes = c(
            "1fr",
            "250px"
          ),
          grid_card(
            area = "area0",
            card_body(
              selectInput(
                inputId = "time_scale",
                label = "時間尺度",
                choices = list(
                  "year" = "year",
                  "month" = "month",
                  "week" = "week",
                  "day" = "day"
                ),
                selected = "month"
              ),
              selectizeInput(inputId = "rival_brand", 
                                                                                                                                                                                                                   label   = "品牌名稱"
                                                                                                                                                                                                                   , choices = NULL,
                                                                                                                                                                                                                   multiple = TRUE,
                                                                                                                                                                                                                   options = list(plugins = list('remove_button', 'drag_drop'))),
              selectizeInput(
                                                                                                                                                                                                      inputId = "rival_asin",
                                                                                                                                                                                                      label   = "子品牌asin",
                                                                                                                                                                                                      multiple= TRUE,
                                                                                                                                                                                                      choices = NULL,
                                                                                                                                                                                                      options = list(plugins = list('remove_button', 'drag_drop'))),
              selectizeInput(inputId = "rival_item_name", 
                                                                                                                                                                                                                   label   = "子品牌名稱"
                                                                                                                                                                                                                   , choices = NULL,
                                                                                                                                                                                                                   multiple = TRUE,
                                                                                                                                                                                                                   options = list(plugins = list('remove_button', 'drag_drop')))
            ),
            card_body(),
            card_body()
          ),
          grid_card(
            area = "area1",
            card_body(plotlyOutput(outputId = "Rival_Plot"))
          ),
          grid_card(
            area = "area2",
            card_body(
              DTOutput(
                outputId = "rival_name_dictionary",
                width = "100%"
              )
            )
          )
        )
      )
    )
  ),
  nav_panel(
    title = "微觀顧客分析",
    tabsetPanel(
      id = "DNATab",
      nav_panel(
        title = "微觀",
        card(
          full_screen = TRUE,
          card_body(
            grid_container(
              layout = c(
                "area0 area1"
              ),
              row_sizes = c(
                "1fr"
              ),
              col_sizes = c(
                "250px",
                "1.32fr"
              ),
              gap_size = "10px",
              grid_card(
                area = "area0",
                card_body(
                  selectizeInput(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                inputId = "dna_customer_name",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                label = "Customer ID",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                choices = NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                multiple = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              )
                )
              ),
              grid_card(
                area = "area1",
                card_body(
                  layout_column_wrap(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                width = "200px",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                fill = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                !!!vbs
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              )
                )
              )
            )
          )
        )
      ),
      nav_panel(
        value = "macro",
        title = "宏觀",
        grid_container(
          layout = c(
            "area0 area1"
          ),
          gap_size = "10px",
          col_sizes = c(
            "250px",
            "1fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              markdown(
                mds = c(
                  "#### 累積分配圖"
                )
              ),
              actionButton(inputId = "M_ecdf", label = "購買金額(M)"),
              actionButton(inputId = "R_ecdf", label = "最近購買日(R)"),
              actionButton(inputId = "F_ecdf", label = "購買頻率(F)"),
              actionButton(
                inputId = "IPT_ecdf",
                label = "顧客平均購買週期(IPT)"
              ),
              markdown(
                mds = c(
                  "#### 長條圖"
                )
              ),
              actionButton(inputId = "F_barplot", label = "購買頻率(F)"),
              actionButton(inputId = "nes_barplot", label = "顧客狀態(NES)")
            )
          ),
          grid_card(
            area = "area1",
            card_body(plotlyOutput(outputId = "DNA_Macro_plot"))
          )
        )
      ),
      nav_panel(
        title = "顧客活躍度分析",
        grid_container(
          layout = c(
            "area0 area0",
            "area1 area1"
          ),
          gap_size = "10px",
          col_sizes = c(
            "1fr",
            "1fr"
          ),
          row_sizes = c(
            "450px",
            "250px"
          ),
          grid_card(
            area = "area0",
            card_body(plotOutput(outputId = "cai_F_scatter"))
          ),
          grid_card(
            area = "area1",
            card_body(
              DTOutput(outputId = "cai_F_nes_DT", width = "100%")
            )
          )
        )
      ),
      nav_panel(
        title = "顧客宏觀地理分佈",
        leafletOutput("mymap", width = "100%", height = "600px"),
        absolutePanel(
                          id = "controls",
                          class = "panel panel-default",
                          fixed = TRUE,
                          draggable = TRUE,
                          top = 140, left = "auto", right = 40, bottom = "auto",
                          width = 210, height = "auto",
                          style = "background-color: rgba(255, 255, 255, 0.9); 
                           padding: 15px; 
                           border-radius: 10px; 
                           box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);",
                          
                          div(
                            selectInput(
                              inputId = "time_scale_map",
                              label = "（累計）時間尺度",
                              choices = list(
                                "累計到現在" = "now",
                                "累計到一個月前" = "m1month",
                                "累計到一季前" = "m1quarter",
                                "累計到一年前" = "m1year"
                              ),
                              selected = "now",
                            ),
                            style = "margin-bottom: 20px;"
                          ), div(selectInput(
                            inputId = "geo_map",
                            label = "地理位置單位",
                            choices = list("州" = "state", "地區" = "local")
                          ),
                          style = "margin-bottom: 20px;")
                          , 
                          
                          selectInput(
                            inputId = "macro_map",
                            label = "宏觀分析指標",
                            choices = list(
                              "總營業額" = "sum_mvalue",
                              "總購買次數" = "sum_fvalue",
                              "總顧客過去價值" = "sum_pcv",
                              "總顧客終身價值" = "sum_clv",
                              "平均間隔購買時間" = "mean_ipt_mean",
                              "平均消費金額" = "mean_mvalue",
                              "平均購買頻率" = "mean_fvalue",
                              "平均最近購買日" = "mean_rvalue",
                              "平均顧客活躍度" = "mean_cai",
                              "平均過去價值" = "mean_pcv",
                              "平均顧客終身價值" = "mean_clv",
                              "平均交易穩定度" = "mean_cri"
                            )
                          )
                        )
      )
    )
  ),
  nav_panel(
    title = "目標輪廓描述",
    tabsetPanel(
      nav_panel(
        title = "市場輪廓描述",
        grid_container(
          layout = c(
            "area1 area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "250px",
            "1.21fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              plotlyOutput(
                outputId = "Demographicout",
                width = "100%",
                height = "700px"
              )
            )
          ),
          grid_card(
            area = "area1",
            full_screen = TRUE,
            card_body(
              selectizeInput(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    inputId = "Demographic",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    label = "市場區隔",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    choices = CreateChoices(Demo_bind_data,Demo),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    multiple = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    selected="",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    options = list(plugins = list('remove_button', 'drag_drop'))),
              selectizeInput(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    inputId = "IndexofDemographic",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    label = "指標",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    choices = names(Demo_bind_data)[str_detect(names(Demo_bind_data)," Customers|Ordered")],
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    multiple = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    selected="",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    options = list(plugins = list('remove_button', 'drag_drop')))
            )
          )
        )
      ),
      nav_panel(
        title = "市場賽道分析",
        grid_card(
          area = "area0",
          card_body(
            grid_container(
              layout = c(
                "area0"
              ),
              row_sizes = c(
                "700px"
              ),
              col_sizes = c(
                "1fr"
              ),
              gap_size = "10px",
              grid_card(
                area = "area0",
                card_body(
                  plotlyOutput(outputId = "plotly_Property_Potential")
                )
              )
            )
          )
        )
      )
    )
  ),
  nav_panel(
    title = "品牌定位分析",
    tabsetPanel(
      nav_panel(
        title = "品牌評分表",
        grid_container(
          layout = c(
            "area0 area1"
          ),
          gap_size = "10px",
          col_sizes = c(
            "250px",
            "1.49fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              selectizeInput(inputId = "position_brand", 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 label = "品牌", 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 choices = NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 multiple = TRUE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 selected="",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 options = list(plugins = list('remove_button', 'drag_drop'))),
              selectizeInput(inputId = "position_asin", 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   label = "子品牌", 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   choices = NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   multiple = TRUE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   selected="",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  )
            )
          ),
          grid_card(
            area = "area1",
            card_body(
              DTOutput(
                outputId = "Position_Selected_data",
                width = "100%"
              )
            )
          )
        )
      ),
      nav_panel(
        title = "品牌DNA",
        grid_container(
          layout = c(
            "area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "1fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              plotlyOutput(
                outputId = "Position_DNA_plotly",
                width = "100%",
                height = "700px"
              )
            )
          )
        )
      ),
      nav_panel(
        title = "品牌定位策略發展圖",
        grid_container(
          layout = c(
            "area0"
          ),
          row_sizes = c(
            "700px"
          ),
          col_sizes = c(
            "1.64fr"
          ),
          gap_size = "10px",
          grid_card(
            area = "area0",
            card_body(plotlyOutput(outputId = "Position_FA_plotly"))
          )
        )
      ),
      nav_panel(
        title = " 競爭者及關鍵因素分析",
        grid_container(
          layout = c(
            "area2",
            "area3"
          ),
          gap_size = "10px",
          col_sizes = c(
            "1.4fr"
          ),
          row_sizes = c(
            "450px",
            "250px"
          ),
          grid_card(
            area = "area2",
            card_header(h2("競爭者分析")),
            card_body(plotlyOutput(outputId = "Position_CSA_plot"))
          ),
          grid_card(
            area = "area3",
            card_header(h2("關鍵因素分析")),
            card_body(textOutput(outputId = "Position_KFE"))
          )
        )
      ),
      nav_panel(
        title = "理想點分析",
        grid_container(
          layout = c(
            "area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "1fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              DTOutput(outputId = "Ideal_rate_data", width = "100%")
            )
          )
        )
      ),
      nav_panel(
        title = "品牌定位策略建議",
        grid_container(
          layout = c(
            "area0 area1"
          ),
          row_sizes = c(
            "700px"
          ),
          col_sizes = c(
            "250px",
            "1fr"
          ),
          gap_size = "10px",
          grid_card(
            area = "area0",
            card_body(
              selectInput(
                inputId = "SA",
                label = "asin",
                choices = NULL,
                selected = ""
              )
            )
          ),
          grid_card(
            area = "area1",
            card_body(plotlyOutput(outputId = "Position_Strategy"))
          )
        )
      )
    )
  ),
  nav_panel(
    title = "精準行銷",
    tabsetPanel(
      nav_panel(
        title = "產品屬性重要性與最適定價",
        grid_container(
          layout = c(
            "area1 area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "250px",
            "1fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(plotlyOutput(outputId = "poltly_Importance"))
          ),
          grid_card(
            area = "area1",
            card_body(
              selectInput(
                inputId = "Importance_asin",
                label = "產品編號",
                choices = NULL,
                selected = ""
              ),
              markdown(
                mds = c(
                  "---",
                  "#### 產品最適定價",
                  "###### 利潤極大化定價"
                )
              ),
              textOutput(outputId = "Optimal_Price"),
              markdown(
                mds = c(
                  "###### 最大銷量（每日）"
                )
              ),
              textOutput(outputId = "Optimal_Q"),
              markdown(
                mds = c(
                  "###### 最大利潤（每日）"
                )
              ),
              textOutput(outputId = "Max_Profit"),
              markdown(
                mds = c(
                  "###### 最大銷售額（每日）"
                )
              ),
              textOutput(outputId = "Max_Revenue")
            )
          )
        )
      ),
      nav_panel(
        title = "競爭者屬性重要性分析",
        grid_container(
          layout = c(
            "area1 area0"
          ),
          gap_size = "10px",
          col_sizes = c(
            "300px",
            "1.52fr"
          ),
          row_sizes = c(
            "700px"
          ),
          grid_card(
            area = "area0",
            card_body(
              plotlyOutput(outputId = "plotly_Importance_Competiter")
            )
          ),
          grid_card(
            area = "area1",
            card_body(
              selectizeInput(
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      inputId = "Importance_Competiter_asin",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      label = "品牌與產品編號",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      choices = NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      multiple = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      selected="",
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      options = list(plugins = list('remove_button', 'drag_drop')))
            )
          )
        )
      ),
      nav_panel(
        title = "關鍵字廣告與新產品開發",
        grid_container(
          layout = c(
            "area0 area0"
          ),
          row_sizes = c(
            "700px"
          ),
          col_sizes = c(
            "1fr",
            "1fr"
          ),
          gap_size = "10px",
          grid_card(
            area = "area0",
            card_body(
              plotlyOutput(outputId = "plotly_Importance_Fixed")
            )
          )
        )
      ),
      nav_panel(
        title = "時間區段分析",
        nav_panel(
          title = "時段分析",
          grid_container(
            layout = c(
              "area0 area1"
            ),
            gap_size = "10px",
            col_sizes = c(
              "250px",
              "1.39fr"
            ),
            row_sizes = c(
              "700px"
            ),
            grid_card(
              area = "area0",
              card_body(
                selectizeInput(
                                                                                                                                                  inputId = "time_potential_Select",
                                                                                                                                                  label = "時間區段",
                                                                                                                                                  choices = list("時段" = "Daytime", "星期" = "Weekdays", "月份" = "Month", "節慶" = "Holiday","年份"="Year"),
                                                                                                                                                  selected = c("Daytime", "Weekdays", "Month", "Holiday", "year"),
                                                                                                                                                  multiple = TRUE,
                                                                                                                                                  options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                ),
                selectizeInput(
                                                                                                                                                  inputId = "time_potential_asin",
                                                                                                                                                  label = "ASIN",
                                                                                                                                                  choices = time_potential_asin_vec,
                                                                                                                                                  options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                )
              )
            ),
            grid_card(
              area = "area1",
              card_body(
                plotlyOutput(outputId = "plotly_time_potential")
              )
            )
          )
        )
      ),
      nav_panel(
        title = "個性化產品廣告輸出",
        grid_container(
          layout = c(
            "area0 area1",
            "area0 area1"
          ),
          gap_size = "10px",
          col_sizes = c(
            "0.44fr",
            "1.56fr"
          ),
          row_sizes = c(
            "1.01fr",
            "700px"
          ),
          grid_card(
            area = "area0",
            full_screen = TRUE,
            card_body(
              selectInput(
                inputId = "Advertise_Output_Media",
                label = "媒體",
                choices = list(
                  "tiktok" = "tiktok",
                  "Line" = "Line",
                  "Facebook" = "Facebook",
                  "手機簡訊" = "手機簡訊"
                )
              ),
              selectInput(
                inputId = "Advertise_Output_Language",
                label = "語言",
                choices = list("中文" = "Chinese", "英文" = "English")
              )
            )
          ),
          grid_card(
            area = "area1",
            card_body(
              DTOutput(
                outputId = "Advertise_Output_Table",
                width = "100%"
              )
            )
          )
        )
      ),
      nav_panel(
        title = "個人化廣告",
        grid_container(
          layout = c(
            "area0 area1",
            ".     .    "
          ),
          gap_size = "10px",
          col_sizes = c(
            "200px",
            "1.37fr"
          ),
          row_sizes = c(
            "700px",
            "1fr"
          ),
          grid_card(
            area = "area0",
            full_screen = TRUE,
            card_body(
              selectizeInput(
                                                                                                                                                                                                                                                                                                                                                                                            inputId = "advertise_customer_name",
                                                                                                                                                                                                                                                                                                                                                                                            label = "顧客姓名",
                                                                                                                                                                                                                                                                                                                                                                                            choices = NULL,
                                                                                                                                                                                                                                                                                                                                                                                            multiple = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                            options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                                                                                                                                                                                                                                                          ),
              selectInput(
                inputId = "Advertise_Ind_Language",
                label = "語言",
                choices = list("中文" = "Chinese", "英文" = "English"),
                selected = "Chinese"
              ),
              selectInput(
                inputId = "Advertise_Ind_Media",
                label = "媒體",
                choices = list(
                  "tiktok" = "tiktok",
                  "Line" = "Line",
                  "Facebook" = "Facebook",
                  "手機簡訊" = "手機簡訊"
                ),
                selected = "Line"
              )
            )
          ),
          grid_card(
            area = "area1",
            full_screen = TRUE,
            card_body(
              layout_column_wrap(
                                                                                                                                                                                                                                                                                                                                                                                            width = "700px",
                                                                                                                                                                                                                                                                                                                                                                                            fill = FALSE,
                                                                                                                                                                                                                                                                                                                                                                                            !!!Advertise_Text
                                                                                                                                                                                                                                                                                                                                                                                          )
            )
          )
        )
      ),
      nav_panel(
        title = "個人化廣告輸出",
        grid_container(
          layout = c(
            "area0 area1",
            "area0 area1"
          ),
          gap_size = "10px",
          col_sizes = c(
            "0.44fr",
            "1.56fr"
          ),
          row_sizes = c(
            "1.01fr",
            "700px"
          ),
          grid_card(
            area = "area0",
            full_screen = TRUE,
            card_body(
              sliderInput(
                inputId = "Advertise_Output_Ind_time",
                label = "最適廣告投放時間（天）",
                min = 0,
                max = 1000,
                value = 1,
                width = "100%"
              ),
              markdown(
                mds = c(
                  "---"
                )
              ),
              selectInput(
                inputId = "Advertise_Output_Ind_Media",
                label = "媒體",
                choices = list(
                  "tiktok" = "tiktok",
                  "Line" = "Line",
                  "Facebook" = "Facebook",
                  "手機簡訊" = "手機簡訊"
                )
              ),
              selectInput(
                inputId = "Advertise_Output_Ind_Language",
                label = "語言",
                choices = list("中文" = "Chinese", "英文" = "English")
              ),
              selectizeInput(
                                                                                                                                                                                                                                                                                                                      inputId = "Advertise_Output_Ind_nes",
                                                                                                                                                                                                                                                                                                                      label = "顧客nes",
                                                                                                                                                                                                                                                                                                                      choices = list("N" = "N", "E0" = "E0", "S1" = "S1", "S2" = "S2", "S3" = "S3"),
                                                                                                                                                                                                                                                                                                                      selected = c("N", "E0", "S1", "S2", "S3"),
                                                                                                                                                                                                                                                                                                                      multiple = TRUE,
                                                                                                                                                                                                                                                                                                                      options = list(plugins = list('remove_button', 'drag_drop'))
                                                                                                                                                                                                                                                                                                                    )
            )
          ),
          grid_card(
            area = "area1",
            card_body(
              DTOutput(
                outputId = "Advertise_Output_Ind_Table",
                width = "100%"
              )
            )
          )
        )
      )
    )
  )
)


server <- function(input, output, session) {
  
  ###Read database （這每一個人要分開來）
        
  app_data<- dbConnect(duckdb(), dbdir = file.path("app_data.duckdb"), read_only = TRUE)
  dbListTables(app_data) 
  
  
#產品銷售輪廓  
  
  
  ####產生不同產品合成的資料
  #source("./Scripts/Combine KMsales.R")
  
  ###############根據選單決定要那個資料###################
  
  nes_trend <- reactive({
    distribution_channel<- req(input$distribution_channel)
    category <- req(input$product_category)
    geo<- req(input$Geo_Macro_Profile)
    
    dta <- tbl(app_data,"nes_trend") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             state_filter==geo) %>%
      select(-any_of(ends_with("filter")),time_condition_filter) %>% collect()

    req(nrow(dta) > 0)  # 确保数据非空
    return(dta)
  })
  
  dna_trend <- reactive({
    distribution_channel<- req(input$distribution_channel)
    category <- req(input$product_category)
    geo<- req(input$Geo_Macro_Profile)
    
    dta <- tbl(app_data,"dna_trend") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             state_filter==geo) %>%
      select(-any_of(ends_with("filter")),time_condition_filter) %>% collect()
    
    req(nrow(dta) > 0)  # 确保数据非空
    return(dta)
  })
  
  
  competiter_sales_dta <- reactive({
    category <- req(input$product_category)
  
    dta <- tbl(app_data,"amazon_competitor_sales_dta") %>% 
      left_join(asin_to_item_dictionary,by = join_by(asin, product_line_id),copy = TRUE) %>%
      filter(product_line_id == category) %>%
      collect()
    req(nrow(dta) > 0)  # 确保数据非空
    
    return(dta)
  })
  
  
  sales_by_time_state<- reactive({
    distribution_channel<- req(input$distribution_channel)
    category <- req(input$product_category)
    geo<- req(input$Geo_Macro_Profile)
    time_scale_profile_selected <- req(input$time_scale_profile)
    
    # ##test####
    # time_scale_profile_selected <- "quarter"
    # category <- "000"
    # geo <- "AZ"
    # distribution_channel <- "amazon"
    # ##########
    
    dta <- tbl(app_data,"sales_by_time_state") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             time_condition_filter=="now") %>%   #state_filter==geo
      select(-source_filter,-product_line_id_filter,-time_condition_filter)%>% 
      group_by(state_filter,time_scale = floor_date(time_scale, unit = time_scale_profile_selected))%>% 
      summarise_all(sum,na.rm=T) %>% 
      collect()
    
    req(nrow(dta) > 0)  # 确保数据非空
    
    date_range <- tbl(app_data,"sales_by_time_state") %>% 
      filter(source_filter==distribution_channel)  %>%
      summarise(start_date = min(time_scale, na.rm = TRUE),
                end_date= max(time_scale, na.rm = TRUE)) %>% collect()
    
    start_date <- date_range$start_date
    end_date <- date_range$end_date 
    
    # Step 2: 創建完整的時間序列
    complete_time_scale <- seq.Date(
      from = floor_date(start_date, time_scale_profile_selected),  # 對齊起點到季度開始
      to = floor_date(end_date  - days(1) , time_scale_profile_selected),  # 對齊終點到季度結束
      by = time_scale_profile_selected
    )
    
    # Step 3: 為每組補全空白月份
    dta2 <- dta %>%
      complete(
        time_scale = complete_time_scale,
        fill = list(new_customers = 0, num_customers = 0) # 填補空值，可根據需求調整
      ) %>% arrange(state_filter,time_scale)
    
    dta3 <- dta2  %>% 
      mutate(cum_customers = cumsum(new_customers)) %>% 
      mutate(last_cum_customers = lag(cum_customers, default = NA),
             last_new_customers = lag(new_customers, default = NA),
             total_difference = total - lag(total, default = NA),
             total_change_rate = ifelse( (total_difference / lag(total, default = NA)) >1.5,1.5, (total_difference / lag(total, default = NA))),
             customer_acquisition_rate = ifelse( (new_customers / last_cum_customers) >1.5,1.5, (new_customers / last_cum_customers)),
             customer_retention_rate = ifelse(cum_customers==new_customers, NA,(cum_customers-new_customers) / cum_customers ),
             average = total/num_customers) %>% 
      select(-last_cum_customers,-last_new_customers)  %>%
      mutate(time_interval_label = formattime(time_scale, time_scale_profile_selected)) %>% 
      ungroup()
    
    # sales_by_time_token <- dta3
    return(dta3)
  })
  
  sales_by_time_zip<- reactive({
    distribution_channel<- req(input$distribution_channel)
    category <- req(input$product_category)
    time_scale_profile_selected <- req(input$time_scale_profile)
    
    # ##test####
    # time_scale_profile_selected <- "quarter"
    # category <- "000"
    # distribution_channel <- "amazon"
    # ##########
    
    dta <- tbl(app_data,"sales_by_time_zip") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             time_condition_filter=="now") %>%   #state_filter==geo
      select(-source_filter,-product_line_id_filter,-time_condition_filter)%>% 
      group_by(zipcode,time_scale = floor_date(time_scale, unit = time_scale_profile_selected))%>% 
      summarise_all(sum,na.rm=T) %>% 
      collect()
    
    req(nrow(dta) > 0)  # 确保数据非空
    
    date_range <- tbl(app_data,"sales_by_time_zip") %>% 
      filter(source_filter==distribution_channel) %>% 
      summarise(start_date = min(time_scale, na.rm = TRUE),
                end_date= max(time_scale, na.rm = TRUE)) %>% collect()
    
    start_date <- date_range$start_date
    end_date <- date_range$end_date
    
    # Step 2: 創建完整的時間序列
    complete_time_scale <- seq.Date(
      from = floor_date(start_date, time_scale_profile_selected),  # 對齊起點到季度開始
      to = floor_date(end_date  - days(1) , time_scale_profile_selected),  # 對齊終點到季度結束
      by = time_scale_profile_selected
    )
    # Step 3: 為每組補全空白月份
    
    #print(complete_time_scale)
    
    all_zipcodes <- dta %>% select(zipcode) %>% unique() %>% pull()
    
    
    # 创建完整的表
    expanded_data <- expand_grid(
      zipcode = all_zipcodes,
      time_scale = tail(complete_time_scale, n = 2)
    )
    
    # 左连接到原始数据以保留原始值，同时填补缺失值
    dta2 <- expanded_data %>%
      left_join(dta, by = c("zipcode", "time_scale")) %>%
      mutate(
        new_customers = tidyr::replace_na(new_customers, 0),
        num_customers = tidyr::replace_na(num_customers, 0),
        total = tidyr::replace_na(total, 0)
      ) %>% group_by(zipcode) %>% 
      arrange(zipcode, time_scale)
    
    
    dta3 <- dta2  %>% 
      mutate(cum_customers = cumsum(new_customers)) %>% 
      mutate(last_cum_customers = lag(cum_customers, default = NA),
             last_new_customers = lag(new_customers, default = NA),
             total_difference = total - lag(total, default = NA),
             total_change_rate = ifelse( (total_difference / lag(total, default = NA)) >1.5,1.5, (total_difference / lag(total, default = NA))),
             customer_acquisition_rate = ifelse( (new_customers / last_cum_customers) >1.5,1.5, (new_customers / last_cum_customers)),
             customer_retention_rate = ifelse(cum_customers==new_customers, NA,(cum_customers-new_customers) / cum_customers ),
             average = total/num_customers) %>% 
      select(-last_cum_customers,-last_new_customers)  %>%
      mutate(time_interval_label = formattime(time_scale, time_scale_profile_selected)) %>% 
      filter(time_scale==last(complete_time_scale))%>% 
      ungroup()
    
    # sales_by_time_token <- dta3
    return(dta3)
  })
  
  
  # sales_by_time<- reactive({
  #   distribution_channel<- req(input$distribution_channel)
  #   category <- req(input$product_category)
  #   geo<- req(input$Geo_Macro_Profile)
  #   time_scale_profile_selected <- req(input$time_scale_profile)
  # 
  #     # ##test####
  #     # time_scale_profile_selected <- "quarter"
  #     # category <- "000"
  #     # geo <- "ID"
  #     # distribution_channel <- "amazon"
  #     # ##########
  # 
  #   dta <- tbl(app_data,"sales_by_time") %>%
  #     filter(source_filter==distribution_channel,
  #            product_line_id_filter==category,
  #            time_condition_filter=="now",
  #            state_filter==geo) %>%
  #     select(-any_of(ends_with("filter")))%>%
  #     group_by(time_scale = floor_date(time_scale, unit = time_scale_profile_selected))%>%
  #     summarise_all(sum,na.rm=T) %>%
  #     collect()
  # 
  #   req(nrow(dta) > 0)  # 确保数据非空
  # 
  #   date_range <- tbl(app_data,"sales_by_time") %>%
  #     filter(source_filter==distribution_channel) %>%
  #     mutate(time_scale = floor_date(time_scale, unit = time_scale_profile_selected)) %>%
  #     summarise(start_date = min(time_scale, na.rm = TRUE),
  #               end_date= max(time_scale, na.rm = TRUE)) %>% collect()
  # 
  #   start_date <- date_range$start_date
  #   end_date <- date_range$end_date
  # 
  #   # Step 2: 創建完整的時間序列
  #   complete_time_scale <- seq.Date(from = start_date, to = end_date, by = time_scale_profile_selected)
  # 
  #   # Step 3: 為每組補全空白月份
  #   dta2 <- dta %>%
  #     complete(
  #       time_scale = complete_time_scale,
  #       fill = list(new_customers = 0, num_customers = 0) # 填補空值，可根據需求調整
  #     ) %>% arrange(time_scale)
  # 
  #   dta3 <- dta2  %>%
  #     mutate(cum_customers = cumsum(new_customers)) %>%
  #     mutate(last_cum_customers = lag(cum_customers, default = NA),
  #            last_new_customers = lag(new_customers, default = NA),
  #            total_difference = total - lag(total, default = NA),
  #            total_change_rate = ifelse( (total_difference / lag(total, default = NA)) >1.5,1.5, (total_difference / lag(total, default = NA))),
  #            customer_acquisition_rate = ifelse( (new_customers / last_cum_customers) >1.5,1.5, (new_customers / last_cum_customers)),
  #            customer_retention_rate = ifelse(cum_customers==new_customers, NA,(cum_customers-new_customers) / cum_customers ),
  #            average = total/num_customers) %>%
  #     select(-last_cum_customers,-last_new_customers)  %>%
  #     mutate(time_interval_label = formattime(time_scale, time_scale_profile_selected))
  # 
  #     # sales_by_time_token <- dta3
  #   return(dta3)
  # })
  

  sales_by_customer <- reactive({
    distribution_channel <- req(input$distribution_channel)
    category <- req(input$product_category)
    geo <- req(input$Geo_Macro_Profile)
    
    # ## Test ####
    # distribution_channel <- "officialwebsite"
    # category <- "001"
    # geo <- "ALL"
    # #################
    
    dta <- tbl(app_data, "sales_by_customer_dta") %>% 
      filter(
        source_filter == distribution_channel,
        product_line_id_filter == category,
        time_condition_filter == "now",
        state_filter == geo
      ) %>%
      select(-any_of(ends_with("filter")))
    
    if(distribution_channel=="amazon"){
      dta2 <- dta %>% mutate(customer_name=customer_id)%>% collect()
    } else if (distribution_channel=="officialwebsite"){
      dta2 <- dta %>% left_join(tbl(app_data, "customer_id_name_dictionary"), by = join_by(customer_id),copy=TRUE) %>% collect()
    } else{
      dta2 <- NULL
    }
  
    
    req(nrow(dta2) > 0)  # 確保數據非空
    
    #print(dta2)
    #sales_by_customer_token <- dta2
    return(dta2)
  })
  
  map_dta <- reactive({
    distribution_channel <- req(input$distribution_channel)
    category <- req(input$product_category)
    geo_map <- req(input$geo_map)
    time_scale_map <- req(input$time_scale_map)
    
    # ## Test ####
    # distribution_channel <- "officialwebsite"
    # category <- "001"
    # time_scale_map <- "m1quarter"
    # #################
    
    
    table_name <- ifelse(geo_map == "state", "sales_by_customer_state_dta", "sales_by_customer_zip_dta")
    
    data <- tbl(app_data, table_name) %>% 
      filter(product_line_id_filter == category, 
             source_filter == distribution_channel,
             time_condition_filter == time_scale_map) %>% 
      collect()
    
    return(data)
  })
  
  
  time_potential <- reactive({
    category <- req(input$product_category)
    distribution_channel<- req(input$distribution_channel)
    asin <- req(input$time_potential_asin)
    # 根據選擇的類別，從資料源加載數據
    
    print(category)
    print(distribution_channel)
    print(asin)
    
    if (category %in% c("003","005","007")){
      category <- "001"
    }
    

    data <- safe_get(paste(distribution_channel,"time_potential",category,asin,"dta",sep="_"))%>% rename_with(make_names)
    req(nrow(data)>0)
    return(data)
  })
  
  
  incidencerate_long <- reactive({

    category <- req(input$product_category)
    distribution_channel<- "amazon"
    
    dta <- tbl(app_data,"poisson_precision_marketing_incidence_ratio_long")%>% 
      filter(
        source_filter == distribution_channel,
        product_line_id_filter == category
      ) %>%
      select(-source_filter,-product_line_id_filter) %>% 
      collect()
    
    
    dta$covariate<- dta$covariate %>%
      dplyr::recode(!!!renamechinese) %>% 
      clean_column_names_remove_english() %>%
      make_names()
    
    req(nrow(dta)>0)
    return(dta)
  })
  
  incidencerate_long_fixed <- reactive({
    
    category <- req(input$product_category)
    distribution_channel<- "amazon"
    
    dta <- tbl(app_data,"poisson_precision_marketing_incidence_ratio_long_fixed")%>% 
      filter(
        source_filter == distribution_channel,
        product_line_id_filter == category
      ) %>%
      select(-source_filter,-product_line_id_filter) %>% 
      collect() 
    
    dta$covariate<- dta$covariate %>%
       dplyr::recode(!!!rename_list) %>% 
      clean_column_names_remove_english() %>%
      make_names()
    
    req(nrow(dta)>0)
    return(dta)
  })
  
  amazon_property_potential <- reactive({
    category <- req(input$product_category)

    dta <- tbl(app_data, "amazon_property_potential") %>% 
      filter(product_line_id_filter == category) %>% 
      select(-any_of(ends_with("filter"))) %>% 
      collect()
    
    dta$covariates <- dta$covariates %>%
      dplyr::recode(!!!rename_list) %>% 
      clean_column_names_remove_english() %>%
      make_names()
    
    req(nrow(dta)>0)
    
    return(dta)
  })
  
  
  Optimal_Pricing <- reactive({
    req(input$distribution_channel=="amazon")  #只有amazon有最適定價
    
    category <- req(input$product_category)
    
    dta <- safe_get(paste("amazon_Optimal_Pricing",category,"dta",sep="_")) 
    
    req(nrow(dta)>0)
    
    dta <- dta%>% as_tibble() %>% 
      rename(any_of(renametemp)) %>% 
      rename_with(make_names)
  
    # if (input$distribution_channel=="officialwebsite"){
    # Name_Correspondence <-  safe_get(paste("officialwebsite_Name_Correspondence",category,"dta",sep="_")) %>% 
    #   as_tibble() %>% 
    #   rename_with(make_names) 
    # 
    # print(skutoasin)
    # 
    # print(skutoasin[Name_Correspondence$name_transaction])
    # 
    # Name_Correspondence$asin <- skutoasin[Name_Correspondence$name_transaction]
    # 
    # print(colnames(Name_Correspondence))
    # 
    # dta2 <- dplyr::left_join(Name_Correspondence,dta,copy = TRUE) %>% 
    #   select(-any_of(c("closest_name_position","closest_name_item_property","asin_name_item_property")))
    # 
    # } else{
    #   dta2 <- dta
    # }
    
    return(dta)
  })
  
  
  
  nes_transition <- reactive({
    distribution_channel<- req(input$distribution_channel)
    category <- req(input$product_category)
    geo<- req(input$Geo_Macro_Profile)
    time_scale_profile_selected <- req(input$time_scale_profile)
    
    #print(distribution_channel)
    #print(category)
    #print(geo)
    #print(time_scale_profile_selected)
    
    # ##test####
    # time_scale_profile_selected <- "quarter"
    # category <- "000"
    # geo <- "ID"
    # distribution_channel <- "amazon"
    # ##########
    
    sales_by_customer_now <- tbl(app_data,"sales_by_customer_dta") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             time_condition_filter=="now",
             state_filter==geo) %>%
      select(-any_of(ends_with("filter")))
    
    time_scale_profile_selected2 <- (Recode_time_TraceBack(time_scale_profile_selected))
    
    sales_by_customer_past <- tbl(app_data,"sales_by_customer_dta") %>% 
      filter(source_filter==distribution_channel,
             product_line_id_filter==category,
             time_condition_filter== time_scale_profile_selected2,
             state_filter==geo) %>%
      select(-any_of(ends_with("filter")))    
    

    contingency_table <- left_join(sales_by_customer_past,sales_by_customer_now,by = join_by(customer_id),copy = TRUE) %>% 
      select(nesstatus.x,nesstatus.y) %>% collect() %>%  table()
    
    
    # 將矩陣轉換為 data.frame 並展開為長格式
    df_long <- as.data.frame(contingency_table)
    colnames(df_long) <- c("nesstatus_pre", "nesstatus_now", "count")
    
    # 計算百分比
    df_long <- df_long %>%
      group_by(nesstatus_pre) %>%
      mutate(activation_rate = count / sum(count))
    
    df_long 
    
    #print(df_long)
  })
  
  observe({
    # 更新 N_to_E0_prop_perc 的文字輸出
    output$N_to_E0_prop_perc <- renderText({
      nes_transition() %>%
        filter(nesstatus_pre == "N" & nesstatus_now == "E0") %>%
        pull(activation_rate) %>%
        scales::percent()
    })
  })
  
  # 靜態更新圖標
  output$N_to_E0_prop_diff <- renderUI({
    if (nes_transition() %>%
        filter(nesstatus_pre == "N" & nesstatus_now == "E0") %>%
        pull(activation_rate) %>%
        is.na()){
      return(bs_icon("question", class = "text-info"))
    }else {
      return(bs_icon("shift", class = "text-success") )     
    }

  })

  
  
 
  ###############修改選單###################
  
  
  #######畫不同產品的圖形
  
  
  # 假設 Dta_001_Electric_Can_Opener 是你的數據框，並且它包含time, Sales, 和 Product_ID 列
  # 直接使用 plot_ly 來繪製圖形
  
  observeEvent(list(input$product_category,input$distribution_channel), {
    sales_by_customer_token <- sales_by_customer()
    incidencerate_long_competiter_token <- incidencerate_long() %>% filter(brand!=brand_name)
    incidencerate_long_kitchenmama_token <- incidencerate_long() %>% filter(brand==brand_name)
    
    updateSelectizeInput(session, "dna_customer_name", 
                         choices = CreateChoices(sales_by_customer_token %>% filter(!is.na(cai)),customer_name),
                         server = TRUE)
    updateSelectizeInput(session, "Importance_asin", 
                         choices = CreateChoices(incidencerate_long_kitchenmama_token,asin))
    updateSelectizeInput(session, "Importance_Competiter_asin", 
                         choices = CreateChoices(incidencerate_long_competiter_token,brand_asin)) 
  })

  observeEvent(list(input$product_category,input$distribution_channel), {
   
    if (input$product_category!="000"){
      if (input$product_category %in% c("003","005","007")){
        asinlist<-safe_get(paste(input$distribution_channel,"time_potential_asin","001","vec",sep="_"))
        updateSelectizeInput(session, "time_potential_asin", 
                             choices = asinlist)     
      } else{
        asinlist<-safe_get(paste(input$distribution_channel,"time_potential_asin",input$product_category,"vec",sep="_"))
        print(asinlist)
    updateSelectizeInput(session, "time_potential_asin", 
                         choices = asinlist)}     
    }
  })
  
  
  observeEvent(list(input$product_category, input$distribution_channel), {  
    sales_data <- sales_by_customer()
    
    # 確保 sales_data 非空且包含有效的 'be' 資料
    req(nrow(sales_data) > 0, !is.null(sales_data$be2))
    
    be_values <- sales_data$be2
    be_values <- be_values[!is.na(be_values)]  # 過濾 NA
    
    # 確保有非 NA 值可以進行 min/max 操作
    req(length(be_values) > 0)
    
    updateSliderInput(
      session,
      inputId = "Advertise_Output_Ind_time",
      min = floor(min(be_values)),
      max = ceiling(max(be_values)),
      value = ceiling(max(be_values))
    )
  })
  
  #### 更新競爭者分析
  
  observeEvent(list(input$product_category,input$distribution_channel),{
    # 获取基础数据
    new_data <- competiter_sales_dta()
    # 检查数据是否有效   ##QQ這邊要限定亞馬遜嗎
    if (!is.null(new_data) && nrow(new_data) > 0) {
      # 更新 rival_brand 和 SA 的选项
      updateSelectizeInput(session, "rival_brand", choices = req(CreateChoices(new_data, brand)))
      updateSelectizeInput(session, "SA", choices = req(CreateChoices(new_data, asin)))
      updateSelectizeInput(session, "rival_item_name",choices = NULL)
      updateSelectizeInput(session, "rival_asin",choices = NULL)
    } else {
      # 如果数据为空，清空 rival_brand 和 SA 的选项
      updateSelectizeInput(session, "rival_brand", choices = NULL,selected = NULL)
      updateSelectizeInput(session, "SA", choices = NULL,selected = NULL)
      updateSelectizeInput(session, "rival_item_name",choices = NULL,selected = NULL)
      updateSelectizeInput(session, "rival_asin",choices = NULL,selected = NULL)
    }
  })
  
  # 动态更新 rival_item_name 和 rival_asin
  observeEvent(list(input$product_category,input$rival_brand), {
    
    # 获取基础数据
    new_data <- req(competiter_sales_dta())
    if(!is.null(input$rival_brand) && input$distribution_channel=="amazon"){
    # 更新 rival_item_name 和 rival_asin 的选项
    updateSelectizeInput(session, "rival_item_name",
                         choices = getDynamicOptions(input$rival_brand, new_data, brand, item_name))
    updateSelectizeInput(session, "rival_asin",
                         choices = getDynamicOptions(input$rival_brand, new_data, brand, asin))
    } else {
      updateSelectizeInput(session, "rival_item_name",choices = NULL)
      updateSelectizeInput(session, "rival_asin",choices = NULL)
    }
  })

  
  

  
  
  observeEvent(input$product_category, {
    ###個人化廣告更新的地方
    if(input$distribution_channel=="officialwebsite"){
      updateSelectizeInput(session, "advertise_customer_name", 
                           choices = req(CreateChoices(sales_by_customer(),customer_name)),
                           server = TRUE)
    }
  })
  
  
  output$rival_name_dictionary <- renderDT({
    # 数据处理和渲染
    req(input$distribution_channel=="amazon")  #只有亞馬遜有競爭者分析
    
    competiter_sales_dta() %>%
      dplyr::filter(
        brand %in% req(input$rival_brand) &
          (
            if (!is.null(input$rival_asin) || !is.null(input$rival_item_name)) {
              (if (!is.null(input$rival_asin)) asin %in% input$rival_asin else FALSE) |
                (if (!is.null(input$rival_item_name)) item_name %in% input$rival_item_name else FALSE)
            } else {
              FALSE  # 如果两个条件都为空，不筛选任何数据
            }
          )
      ) %>%
      dplyr::select(brand, asin, item_name) %>%
      dplyr::distinct()%>% 
      dplyr::rename(any_of(renamechinese))
  }, options = list(
    pageLength = -1,
    searching = FALSE,
    lengthChange = FALSE,
    info = FALSE,
    paging = FALSE,
    columnDefs = list(
      list(visible = FALSE, targets = 0)
    )
  ))
  
  
  
  output$Rival_Plot <- renderPlotly({
    
    req(input$distribution_channel=="amazon")  #只有亞馬遜有競爭者分析
    # 聚合數據
    aggregated_data <- competiter_sales_dta()%>%
      dplyr::filter(
        brand %in% req(input$rival_brand) &
          (
            if (!is.null(input$rival_asin) || !is.null(input$rival_item_name)) {
              (if (!is.null(input$rival_asin)) asin %in% input$rival_asin else FALSE) |
                (if (!is.null(input$rival_item_name)) item_name %in% input$rival_item_name else FALSE)
            } else {
              FALSE  # 如果两个条件都为空，不筛选任何数据
            }
          )
      )%>% 
      group_by(asin, time_scale = floor_date(time, unit = input$time_scale)) %>%
      summarise(sales = sum(sales,na.rm = T))
    
    # 根據時間尺度設定x軸刻度間隔
    dtick_setting <- switch(input$time_scale,
                            "year" = "Y1",  # 每年
                            "month" = "M1",  # 每月
                            "week" = "M1",   # 每週（也可以根據實際需要調整）
                            "day" = "D1")    # 每日
    
    tick_format <- switch(input$time_scale,
                          "year" = "%Y",
                          "month" = "%b %Y",
                          "week" = "Week %U, %Y",
                          "day" = "%d %b %Y")
    
    # 繪製圖形
    plot_ly(aggregated_data, x = ~time_scale, y = ~sales, color = ~asin, type = 'scatter', mode = 'lines+markers') %>%
      layout(
        xaxis = list(
          title = input$time_scale,
          tickmode = "auto",
          dtick = dtick_setting,
          tickformat = tick_format
        ),
        yaxis = list(title = "銷售量")
      )
  })
  
  
  ##########################################################################################################################################
  ##########################################################################################################################################
  ##########################################################################################################################################
  ##個人化廣告###
  

  observeEvent(list(input$advertise_customer_name,input$Advertise_Ind_Language,input$Advertise_Ind_Media),{
    
    req(input$distribution_channel=="officialwebsite") #只有官網有廣告
      sales_by_customer_token<- sales_by_customer()
      advertise_customer_name_token <-req(input$advertise_customer_name)
      #advertise_customer_name_token <- "Bonnie Burk"
      
      CustomerRow <- sales_by_customer_token %>%
        filter(customer_name == advertise_customer_name_token) 
      
      advertise_customer_id <-  CustomerRow$customer_id
      
      recommendations<- tbl(app_data,"recommendation_asin") %>% filter(customer_id==advertise_customer_id) %>% collect()
    
    
    output$Advertise_recommendation_asin_1 <- renderText({as.character(recommendations$recommendation_1)})
    output$Advertise_recommendation_asin_2 <- renderText({as.character(recommendations$recommendation_2)})
    output$Advertise_recommendation_asin_3 <- renderText({as.character(recommendations$recommendation_3)})
    
    output$Advertise_recommendation_product_line_1 <- renderText({as.character(product_linetoChinese[asintoproduct_line[recommendations$recommendation_1]])})
    output$Advertise_recommendation_product_line_2 <- renderText({as.character(product_linetoChinese[asintoproduct_line[recommendations$recommendation_2]])})
    output$Advertise_recommendation_product_line_3 <- renderText({as.character(product_linetoChinese[asintoproduct_line[recommendations$recommendation_3]])})
    

    
    output$Advertise_recommendation_1 <- renderText({advertise_generation_dta %>%
        filter(
          asin %in% (recommendations$recommendation_1),
          language == input$Advertise_Ind_Language,
          media == input$Advertise_Ind_Media
        ) %>%
        pull(advertisement) %>% as.character()})
    
    output$Advertise_recommendation_2 <- renderText({advertise_generation_dta %>%
        filter(
          asin %in% (recommendations$recommendation_2),
          language == input$Advertise_Ind_Language,
          media == input$Advertise_Ind_Media
        ) %>%
        pull(advertisement) %>% as.character()})
    
    output$Advertise_recommendation_3 <- renderText({advertise_generation_dta %>%
        filter(
          asin %in% (recommendations$recommendation_3),
          language == input$Advertise_Ind_Language,
          media == input$Advertise_Ind_Media
        ) %>%
        pull(advertisement) %>% as.character()})

  })
  

  
  
  
  

  
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
  

  

  

  
  observeEvent(list(input$Demographic, input$IndexofDemographic), {
    output$Demographicout <- renderPlotly({
      # 獲取篩選後的數據
      filtered_data <- Demo_bind_data %>%
        filter(Demo == req(input$Demographic))
      
      # 假設 filtered_data 已經存在並格式化
      filtered_data$`Reporting Date` <- as.Date(filtered_data$`Reporting Date`)
      
      # 使用 plotly 繪製折線圖
      plot_ly(
        data = filtered_data,
        x = ~`Reporting Date`,
        y = as.formula(paste0("~`", input$IndexofDemographic, "`")),
        type = 'scatter',
        mode = 'lines'
      ) %>%
        layout(
          title = list(text = paste(input$Demographic, "趨勢"), x = 0.5),
          xaxis = list(title = "日期"),
          yaxis = list(title = input$IndexofDemographic)
        )
    })
  })
  
  observeEvent(input$dna_customer_name,{
    
    sales_by_customer_token <- sales_by_customer() 
    
    
    Customer_dna<- sales_by_customer() %>% 
      filter(customer_name == req(input$dna_customer_name)) %>% 
      select(-any_of(c(starts_with("customer"),ends_with("filter")))) %>%
      mutate(nrec = recode(as.integer(nrec),
                                  `0` = "靜止戶",
                                  `1` = "非靜止戶",
                                  .default = "未知")) %>%
      mutate(
        nrec_onemin_prob = 1 - nrec_prob/100,
        across(c(time_first_tonow,rvalue), ~ round(.x, 0)),  # 對 ipt_mean 和 variable1 四捨五入到 1 位
        across(c(ipt_mean), ~ round(.x, 1)),  # 對 ipt_mean 和 variable1 四捨五入到 1 位
        across(c(clv,pcv,cai), ~ round(.x, 2)),  # 對 ipt_mean 和 variable1 四捨五入到 1 位
        across(c(cri, nesratio), ~ round(.x, 3)),  # 對 variable2 和 variable3 四捨五入到 3 位
        across(c(nrec_onemin_prob), ~ percent(.x, accuracy = 0.01))
      ) %>%
      mutate(across(everything(), ~ ifelse(is.na(.x), "未知", as.character(.x))))
    
    #print(testdata<<-Customer_dna)
    #cat(generate_render_code(testdata))

    
    eval(parse(text = generate_render_code(Customer_dna)))
    
        
  })
  
  
  # Use observe to run calculate_KPI_diff_shiny when processeddata changes
  observe({
    calculate_KPI_diff_shiny(req(sales_by_time_state() %>% filter(state_filter==input$Geo_Macro_Profile)), output)    
  })
  
  output$sales_pattern <- renderDT({
    # 獲取數據
    sales_by_time_token <- sales_by_time_state() %>% filter(state_filter==input$Geo_Macro_Profile)
    
    # 選取需要的列
    dta <- sales_by_time_token %>%
      select(time_interval_label, total, total_difference, total_change_rate, num_customers, average)%>% 
      dplyr::rename(any_of(renamechinese))  # 重命名列
    
    # 渲染 dataTable 並格式化
    datatable(
      dta,
      options = list(
        pageLength = -1,  # 展示所有行
        searching = FALSE,  # 禁用搜尋框
        lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
        info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
        paging = FALSE,  # 禁用分頁
        columnDefs = list(
          list(visible = FALSE, targets = 0)  # 隱藏第一列
        )
      )
    ) %>%
      formatRound(c("總銷售", "與上期差異", "平均銷售"), 2) %>%  # 使用重命名後的列名進行格式化
    formatPercentage(c("銷售成長率"), 2) 
  })

  # 使用 subplot 來組合這些圖形
  output$sales_pattern_Plot <- renderPlotly({
    
    sales_by_time_token<- sales_by_time_state() %>% filter(state_filter==input$Geo_Macro_Profile)
    
    # 創建第一個圖形
    p11 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~total, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'blue'), marker = list(color = 'blue')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '總銷售'))
    
    # 創建第二個圖形
    p12 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~num_customers, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'red'), marker = list(color = 'red')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '來客數'))
    
    # 創建第三個圖形
    p13 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~average, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'black'), marker = list(color = 'black')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '平均銷售'))
    
    p14 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~total_change_rate, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'orange'), marker = list(color = 'orange')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '銷售成長率'))
    
    p15 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~cum_customers, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'purple'), marker = list(color = 'purple')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '顧客總數'))
    
    subplot(style(p11, showlegend = FALSE), 
            style(p12, showlegend = FALSE), 
            style(p13, showlegend = FALSE),
            style(p14, showlegend = FALSE),
            style(p15, showlegend = FALSE), nrows = 5, shareX = TRUE, titleX = TRUE,titleY = TRUE)%>% 
      layout(
        yaxis = list(fixedrange = TRUE),  # 固定 y 軸範圍
        showlegend = FALSE)
  })
  
  

  
  output$customer_acquisition_rate <- renderDT({
    sales_by_time_token <- sales_by_time_state() %>% filter(state_filter==input$Geo_Macro_Profile)
    
    
    # 選取和重命名數據
    dta <- sales_by_time_token %>%
      select(
        time_interval_label,
        new_customers,
        num_customers,
        cum_customers,
        customer_acquisition_rate,
        customer_retention_rate
      ) %>%
      dplyr::rename(any_of(renamechinese))
    
    # 使用 datatable 並格式化百分比
    datatable(
      dta,
      options = list(
        pageLength = -1,  # 展示所有行
        searching = FALSE,  # 禁用搜尋框
        lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
        info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
        paging = FALSE,  # 禁用分頁
        columnDefs = list(
          list(visible = FALSE, targets = 0)  # 隱藏第一列
        )
      ),
      colnames = c("", colnames(dta))  # 設置自定義列名
    ) %>%
      formatPercentage(c("顧客成長率", "顧客留存率"), 2)  # 使用重命名後的列名進行格式化
  })
  
  # %>% 
  #   mutate(sales_by_time = scales::percent(sales_by_time_value),
  #          customer_transformation_rate = scales::percent(customer_transformation_rate_value))
  
  


  # 使用 cowplot 的 plot_grid 來組合這些圖形
  output$customer_acquisition_rate_Plot <-  renderPlotly({
    
    sales_by_time_token<- sales_by_time_state() %>% filter(state_filter==input$Geo_Macro_Profile)
    
    
    # 創建第一個圖形
    p11 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~new_customers, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'blue'), marker = list(color = 'blue')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '新客數'))
    
    p12 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~num_customers, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'red'), marker = list(color = 'red')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '來客數'))
    
    p13 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~cum_customers, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'black'), marker = list(color = 'black')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '累積顧客數'))
    
    p14 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~customer_acquisition_rate, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'orange'), marker = list(color = 'orange')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '顧客新增率'))
    
    p15 <- plot_ly(sales_by_time_token, x = ~time_scale, y = ~customer_retention_rate, type = 'scatter', mode = 'lines+markers', 
                   line = list(color = 'purple'), marker = list(color = 'purple')) %>%
      layout( xaxis = list(title = '時間區間'), yaxis = list(title = '顧客留存率'))
    
    subplot(style(p11, showlegend = FALSE), 
            style(p12, showlegend = FALSE), 
            style(p13, showlegend = FALSE), 
            style(p14, showlegend = FALSE),
            style(p15, showlegend = FALSE), nrows = 5, shareX = TRUE, titleX = TRUE,titleY = TRUE)%>% 
      layout(
        yaxis = list(fixedrange = TRUE),  # 固定 y 軸範圍
        showlegend = FALSE)
    
    
    })
  ##############################
  #Other KPIs
  
  observeEvent(list(input$time_scale_profile,input$product_category,input$Geo_Macro_Profile),{
     calculate_KPI_diff_TraceBack_shiny(nes_trend(),
                                        unit = input$time_scale_profile,
                                        grouping  ="nesstatus",
                                        skipcolumns=c("time_condition_filter") ,
                                        output)
    
    calculate_KPI_diff_TraceBack_shiny(dna_trend(),
                                       unit = input$time_scale_profile,
                                       grouping=NULL,
                                       skipcolumns=c("time_condition_filter") ,
                                       output)
  })
  
  
  
  
  ###############################33


  
  observeEvent(input$M_ecdf, {
    output$DNA_Macro_plot <- renderPlotly({
      req(input$DNATab == "macro")
      
      # 計算 ECDF
      ecdf_data <- ecdf(sales_by_customer()$mvalue)
      
      # 創建 ECDF 的 x 和 y 值
      #x_vals <- sort(sales_by_customer()$mvalue)
      
      
      percentiles <- seq(0, 1, length.out = 5000)
      x_vals <- quantile(sales_by_customer()$mvalue, percentiles, na.rm = TRUE)
      y_vals <- ecdf_data(x_vals)
      
      # 設置 x 軸的範圍 (0 到 90% 分位數)
      x_limit <- quantile(sales_by_customer()$mvalue, 0.99, na.rm = TRUE)
      x_position <- quantile(sales_by_customer()$mvalue, 0.1, na.rm = TRUE)
      M_count <- table(sales_by_customer()$mlabel)
      
      # 計算 ECDF
      ecdf_data <- ecdf(sales_by_customer()$mvalue)
      
      # 創建 ECDF 的 x 和 y 值
      percentiles <- seq(0, 1, length.out = 5000)
      x_vals <- quantile(sales_by_customer()$mvalue, percentiles, na.rm = TRUE)
      y_vals <- ecdf_data(x_vals)
      
      # 設置 x 和 y 軸的範圍
      x_limit <- quantile(sales_by_customer()$mvalue, 1, na.rm = TRUE)
      
      # 使用 plotly 繪製 ECDF 圖，並禁用大部分互動功能
      plot_ly(x = ~x_vals, y = ~y_vals, type = 'scattergl', mode = 'lines', 
              line = list(shape = 'hv'),
              hovertemplate = paste(
                "金額：%{x:.0f} 元<br>",
                "累積比例：%{y:.2%}<extra></extra>"
              )) %>%
          add_lines(x = range(x_vals), y = Mbreaks[2] , line = list(dash = 'dash', color = 'red')) %>%
          add_lines(x = range(x_vals), y = Mbreaks[3] , line = list(dash = 'dash', color = 'red')) %>% 
        layout(
          title = paste0("ECDF Plot of Monetary Value ( n = ", sum(!is.na(sales_by_customer()$mvalue)), " )"),
          xaxis = list(title = "Monetary Value", range = c(0, x_limit), fixedrange = TRUE),  # 固定 x 軸範圍
          yaxis = list(title = "Cumulative Proportion", range = c(0, 1), fixedrange = TRUE),  # 固定 y 軸範圍
          showlegend = FALSE,  # 禁用圖例
          
          # 加入文字標籤
          annotations = list(
            list(
              x = 0,  # x 軸位置，這裡設為0，模擬左對齊
              y = (Mbreaks[1]+Mbreaks[2])/2,  # 第一個標籤的 y 軸位置
              text = paste0(textMlabel[1]," ( n = ",M_count[1]," )"),  # 第二個標籤文字
              showarrow = FALSE,  # 不顯示箭頭
              xref = "paper", yref = "y",  # 使用相對參考
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            ),
            list(
              x = 0,  # 第二個標籤 x 軸位置
              y = (Mbreaks[2]+Mbreaks[3])/2,  # 第二個標籤的 y 軸位置
              text = paste0(textMlabel[2]," ( n = ",M_count[2]," )"),  # 第二個標籤文字
              showarrow = FALSE,
              xref = "paper", yref = "y",
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            ),
            list(
              x = 0,  # 第三個標籤 x 軸位置
              y = (Mbreaks[3]+Mbreaks[4])/2,  # 第三個標籤的 y 軸位置
              text = paste0(textMlabel[3]," ( n = ",M_count[3]," )"),  # 第二個標籤文字
              showarrow = FALSE,
              xref = "paper", yref = "y",
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            )
          )
        )
        
      

  })})
  
  observeEvent(input$F_ecdf, {
  output$DNA_Macro_plot <- renderPlotly({
    req(input$DNATab == "macro")
    
    # 計算 ECDF
    ecdf_data <- ecdf(sales_by_customer()$fvalue)
    
    # 創建 ECDF 的 x 和 y 值
    x_vals <- 0:10
    y_vals <- ecdf_data(x_vals)
    
    
    # 使用 plotly 繪製 ECDF 圖
    plot_ly(x = ~x_vals, y = ~y_vals, type = 'scattergl', mode = 'lines',
            line = list(shape = 'hv'),
            hovertemplate = paste(
              "頻率: %{x:.2f}<br>",
              "累積比例: %{y:.2%}<extra></extra>"
            )) %>%
      layout(
        title = paste0("ECDF Plot of Frequency ( n = ", sum(!is.na(sales_by_customer()$fvalue)), " )"),
        xaxis = list(title = "Frequency", range = c(0, 10), fixedrange = TRUE),
        yaxis = list(title = "Cumulative Proportion", range = c(0, 1), fixedrange = TRUE),
        showlegend = FALSE  # 禁用圖例
      )
  })
  })
  
  observeEvent(input$R_ecdf, {
    output$DNA_Macro_plot <- renderPlotly({
      req(input$DNATab == "macro")
      # 計算 ECDF
      ecdf_data <- ecdf(sales_by_customer()$rvalue)
      
      # 創建 ECDF 的 x 和 y 值
      #x_vals <- sort(sales_by_customer()$rvalue)
      
      # 使用 quantile() 在 0 到 1 的範圍內等間隔取 10,000 個百分位數點
      percentiles <- seq(0, 1, length.out = 5000)
      x_vals <- quantile(sales_by_customer()$rvalue, percentiles, na.rm = TRUE)
      y_vals <- ecdf_data(x_vals)
      
      # 設置 x 軸的範圍 (0 到 99% 分位數)
      x_limit <- quantile(sales_by_customer()$rvalue, 0.99, na.rm = TRUE)
      R_count <- table(sales_by_customer()$rlabel)
      
      # 設置 x 和 y 軸的範圍
      x_limit <- quantile(sales_by_customer()$rvalue, 1, na.rm = TRUE)
      
      # 使用 plotly 繪製 ECDF 圖，並禁用大部分互動功能
      plot_ly(x = ~x_vals, y = ~y_vals, type = 'scattergl', mode = 'lines', 
              line = list(shape = 'hv'),
              hovertemplate = paste(
                "天數：%{x:.0f} 天<br>",
                "累積比例：%{y:.2%}<extra></extra>"
              )) %>%
        add_lines(x = range(x_vals), y = Rbreaks[2], line = list(dash = 'dash', color = 'red')) %>%
        add_lines(x = range(x_vals), y = Rbreaks[3], line = list(dash = 'dash', color = 'red')) %>% 
        layout(
          title = paste0("ECDF Plot of Recency ( n = ", sum(!is.na(sales_by_customer()$rvalue)), " )"),
          xaxis = list(title = "Recency (days)", range = c(0, x_limit), fixedrange = TRUE),  # 固定 x 軸範圍
          yaxis = list(title = "Cumulative Proportion", range = c(0, 1), fixedrange = TRUE),  # 固定 y 軸範圍
          showlegend = FALSE,  # 禁用圖例
          
          # 加入文字標籤
          annotations = list(
            list(
              x = 0,  # x 軸位置，這裡設為0，模擬左對齊
              y = (Rbreaks[1] + Rbreaks[2]) / 2,  # 第一個標籤的 y 軸位置
              text = paste0(textRlabel[1], " ( n = ", R_count[1], " )"),  # 第一個標籤文字
              showarrow = FALSE,  # 不顯示箭頭
              xref = "paper", yref = "y",  # 使用相對參考
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            ),
            list(
              x = 0,  # 第二個標籤 x 軸位置
              y = (Rbreaks[2] + Rbreaks[3]) / 2,  # 第二個標籤的 y 軸位置
              text = paste0(textRlabel[2], " ( n = ", R_count[2], " )"),  # 第二個標籤文字
              showarrow = FALSE,
              xref = "paper", yref = "y",
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            ),
            list(
              x = 0,  # 第三個標籤 x 軸位置
              y = (Rbreaks[3] + Rbreaks[4]) / 2,  # 第三個標籤的 y 軸位置
              text = paste0(textRlabel[3], " ( n = ", R_count[3], " )"),  # 第三個標籤文字
              showarrow = FALSE,
              xref = "paper", yref = "y",
              xanchor = "left",  # 左對齊
              font = list(size = h5.fontsize, color = "red")
            )
          )
        )
      
    })
    })
  
  # observeEvent(input$cai_ecdf, {
  #   output$DNA_Macro_plot <- renderPlot({
  #     req(input$DNATab == "macro")
  #     
  #     ggplot(sales_by_customer(), aes(x = cai)) +
  #       stat_ecdf(geom = "step") +
  #       geom_hline(yintercept = caibreaks[2:(length(caibreaks) - 1)], color = "red", linetype = "dashed", size = 1) +
  #       geom_text(data = data.frame(y = Rbreaks[2:(length(caibreaks) - 1)]+c(0.03,-0.03), label = round(quantile(sales_by_customer()$cai,caibreaks[2:(length(caibreaks) - 1)],na.rm = T),2)), 
  #                 aes(x = -Inf, y = y, label = label), 
  #                 hjust = -0.1, color = "red", family = "STSongti-TC-Regular")+
  #       geom_text(data = data.frame(x = -Inf, y =  (caibreaks[-length(caibreaks)] + caibreaks[-1]) / 2, label = paste0(textcailabel," ( n = ",table(sales_by_customer()$cailabel)," )")),
  #                 aes(x = x, y = y, label = label), family = "STSongti-TC-Regular", hjust = 0) +
  #       # geom_text(data = intersection_points, aes(x = cai, y = ecdf_value, label = sprintf("x = %.2f, y = %.2f", cai, ecdf_value)), 
  #       #            vjust = -1, hjust = -0.1, color = "blue", family = "STSongti-TC-Regular") +
  #       labs(title = paste0("ECDF Plot of Inter purchase time ( n = ",sum(!is.na(sales_by_customer()$cailabel))," )"), x = "cai", y = "Cumulative Proportion") +
  #       theme_minimal()  +
  #       theme(text = element_text(size = h5.fontsize),
  #             axis.text = element_text(size = h5.fontsize))
  #     
  #     
  #   })})
  
  observeEvent(input$IPT_ecdf, {
    output$DNA_Macro_plot <- renderPlotly({
      req(input$DNATab == "macro")
      req(sum(!is.na(sales_by_customer()$ipt_mean)) > 0, "No data available for ECDF plot.")

      
      # 計算 ECDF
      ecdf_data <- ecdf(sales_by_customer()$ipt_mean)
      
      # 創建 ECDF 的 x 和 y 值
      percentiles <- seq(0, 1, length.out = 5000)
      x_vals <- quantile(sales_by_customer()$ipt_mean, percentiles, na.rm = TRUE)
      y_vals <- ecdf_data(x_vals)
      
      # 設置 x 軸的範圍 (0 到 99% 分位數)
      x_limit <- quantile(sales_by_customer()$ipt_mean, 0.99, na.rm = TRUE)
      
      # 計算 ipt_mean 的均值和中位數
      mean_value <- mean(sales_by_customer()$ipt_mean, na.rm = TRUE)
      median_value <- median(sales_by_customer()$ipt_mean, na.rm = TRUE)
      
      # 使用 plotly 繪製 ECDF 圖，並添加垂直線
      plot_ly(x = ~x_vals, y = ~y_vals, type = 'scattergl', mode = 'lines', 
              line = list(shape = 'hv'),
              hovertemplate = paste(
                "購買間隔天數：%{x:.0f} days<br>",
                "累積比例：%{y:.2%}<extra></extra>"
              )) %>%
        # 添加垂直線到 mean 的位置
        add_lines(x = mean_value, y = c(0, 1), line = list(dash = 'dash', color = 'red')) %>%
        # 添加標籤顯示 mean 值
        add_annotations(
          x = mean_value, 
          y = 0.55,  # 標籤在 y 軸稍高顯示
          text = paste("平均數：", round(mean_value, 2), "天"),
          showarrow = TRUE, 
          arrowhead = 2,
          ax = 20,  # 箭頭的偏移
          ay = -40  # 箭頭的偏移
        ) %>%
        # 添加垂直線到 median 的位置
        add_lines(x = median_value, y = c(0, 1), line = list(dash = 'dash', color = 'blue')) %>%
        # 添加標籤顯示 median 值
        add_annotations(
          x = median_value, 
          y = 0.45,  # 標籤在 y 軸稍低顯示
          text = paste("中位數：", round(median_value, 2), "天"),
          showarrow = TRUE, 
          arrowhead = 2,
          ax = 20,  # 箭頭的偏移
          ay = -40  # 箭頭的偏移
        ) %>%
        layout(
          title = paste0("ECDF Plot of Inter purchase time ( n = ", sum(!is.na(sales_by_customer()$ipt_mean)), " )"),
          xaxis = list(title = "Inter purchase time (days)", range = c(0, x_limit)),
          yaxis = list(title = "Cumulative Proportion"),
          showlegend = FALSE  # 禁用圖例
        )
      
    })})
  
  observeEvent(input$nes_barplot, {
    output$DNA_Macro_plot <- renderPlotly({
      req(input$DNATab == "macro")
      
      # 計算每個 nesstatus 的計數和比例
      nes_data <- sales_by_customer() %>%
        dplyr::count(nesstatus) %>%
        mutate(percentage = n / sum(n) * 100)  # 計算每個類別的比例
      
      # 使用 plotly 繪製條形圖，顯示數量和比例
      plot_ly(
        data = nes_data, 
        x = ~nesstatus, 
        y = ~n, 
        type = 'bar',
        text = ~paste0("Count: ", n, "<br>Percentage: ", round(percentage, 2), "%"),  # 顯示計數和比例
        textposition = 'auto'  # 自動顯示標籤
      ) %>%
        layout(
          xaxis = list(title = "狀態",fixedrange = TRUE)  # 固定 x 軸範圍)
        )
    })})
  
  observeEvent(input$F_barplot, {
    output$DNA_Macro_plot <- renderPlotly({
      req(input$DNATab == "macro")
      
      # 計算每個 Flabel 的計數和比例
      flabel_data <- sales_by_customer() %>%
        dplyr::count(flabel) %>%
        mutate(percentage = n / sum(n) * 100)  # 計算每個類別的比例
      
      # 使用 plotly 繪製條形圖，顯示數量和比例
      plot_ly(
        data = flabel_data, 
        x = ~flabel, 
        y = ~n, 
        type = 'bar',
        text = ~paste0("人數: ", n, "<br>比例: ", round(percentage, 2), "%"),  # 顯示計數和比例
        textposition = 'auto'
      ) %>%
        layout(
          xaxis = list(title = "頻率",fixedrange = TRUE)  # 固定 x 軸範圍
        )
    
    })})
  
  
  
  output$cai_F_scatter <- renderPlot({
    sales_by_customer_token <- sales_by_customer()
    #Plot code goes here
    temp<- sales_by_customer_token %>% filter(fvalue>=ni_threshold,fvalue<100,!is.na(fvalue),!is.na(cai))
    req(nrow(temp)>0)
    
    fmean <- mean(temp$fvalue,na.rm=T)

    
    ggplot(temp, aes(x=fvalue, y=cai,color = nesstatus)) + 
      geom_hline(yintercept=0,color="red")+
      geom_vline(xintercept=fmean,color="red")+
      geom_point(position = position_jitter(width = 0.01))+
      ylim(-1, 1)+
      annotate("text", x =max(temp$fvalue)*2/3, y = 0.5, label = ladder("忠誠&活躍"),lineheight =0.8, size=h5.fontsize / .pt)+
      annotate("text", x = max(temp$fvalue)*2/3, y = -0.5, label = ladder("忠誠&不活躍"),lineheight =0.8,size=h5.fontsize / .pt)+
      annotate("text", x = 0, y = 0.5, label = ladder("不忠誠&活躍"),lineheight =0.8,size=h5.fontsize / .pt)+
      annotate("text", x = 0, y = -0.5, label = ladder("不忠誠&不活躍"),lineheight =0.8,size=h5.fontsize / .pt)+
      labs(x = "Frequency (times)", y = "CAI", 
           color = "nes") +
      theme_minimal()  +
      theme(text = element_text(size = h5.fontsize),
            axis.text = element_text(size = h5.fontsize))
    
  })

  output$cai_F_nes_DT <- renderDT({
    sales_by_customer_token <- sales_by_customer()
    
    temp <- sales_by_customer_token %>%
      filter(fvalue >= ni_threshold, fvalue < 100, !is.na(fvalue), !is.na(cai))
    fmean <- mean(temp$fvalue, na.rm = TRUE)
    
    processed_data <- sales_by_customer_token %>%
      mutate(
        ydim = cai > 0,  # 判断活跃
        xdim = fvalue > fmean,  # 判断忠诚
        Fourclass = factor(
          as.integer(recode(as.character(2 * ydim + xdim), 
                            '0' = '3', '1' = '4', '3' = '1', '2' = '2')),
          levels = c(1, 2, 3, 4)
        )
      ) %>%
      group_by(Fourclass) %>%
      summarise(count = n(), .groups = "drop") %>%
      complete(Fourclass, fill = list(count = 0)) %>%
      filter(!is.na(Fourclass)) %>%
      mutate(
        prop = count / sum(count),  # 计算比例
        percept = scales::percent(prop),  # 格式化百分比
        label = c("忠誠&活躍", "不忠誠&活躍", "不忠誠&不活躍", "忠誠&不活躍")
      ) %>%
      select(Fourclass, count, percept, label)  # 选择所需列，顺序保持与 colnames 一致
    
    # 返回 dataTable
    datatable(
      processed_data,
      options = list(
        pageLength = -1,  # 展示所有行
        searching = FALSE,  # 禁用搜索框
        lengthChange = FALSE,  # 不显示“Show [number] entries”选项
        info = FALSE,  # 不显示“Showing 1 to X of X entries”信息
        paging = FALSE,  # 禁用分页
        columnDefs = list(
          list(visible = FALSE, targets = 0),  # 隐藏 "象限" 列（索引为 0）
          list(className = "dt-center", targets = "_all")
        )
      ),
      colnames = c("象限", "客戶數", "百分比", "類型")  # 设置表格列名
    ) 
  })


  # output$Position_Cluster_DT <- renderDT({
  #   Position_Cluster_selected()%>% 
  #     mutate_if(., is.numeric, round, 2)
  # }, options = list(
  #   pageLength = -1,  # 展示所有行
  #   searching = FALSE,  # 禁用搜尋框
  #   lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
  #   info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
  #   paging = FALSE,  # 禁用分頁
  #   scrollX = FALSE,
  #   columnDefs = list(
  #     list(visible = FALSE, targets = 0)
  #   )
  # ))
    
    
    
# 
#   output$Position_Cluster_Plotly <- renderPlotly({
# 
#     dta_brand <- rename(Position_Cluster_selected(),`amazon rating`=Rating_mean)
#     select <- dplyr::select
#     dta_brand$Cluster <- as.factor(dta_brand$Cluster)
#     dta_brand_log <- dta_brand %>% select(.,-any_of(c("Sales_Sum" ,'Sales_mean' ,'Review_Num','Brands_Unique')))  %>%
#       pivot_longer(cols=-c("Cluster"),names_to = "attribute",values_to = "score") %>%
#       arrange(Cluster)
# 
#     asin_groups <- split(dta_brand_log, dta_brand_log$Cluster)
#     dta_brand_log$attribute <- as.factor(dta_brand_log$attribute)
#     fac_lis <-  unique(dta_brand_log$attribute)
# 
#     #str(brand_data)
# 
# 
# 
# 
#     p <- plot_ly()
# 
#     # 为每个brand添加一条线
#     for (asin_data in asin_groups) {
# 
#       brand <- unique(asin_data$Cluster )
#       p <- add_trace(p,data=asin_data, x = ~levels(fac_lis), y = ~score,
#                      color=~Cluster, type = 'scatter', mode = 'lines+markers', name = brand,
#                      text = ~Cluster, hoverinfo = 'text',
#                      marker = list(size = 10),  # 设置点的大小
#                      line = list(width = 2),     # 设置线的宽度
#                      visible = "legendonly"  # 默认隐藏所有内容
#       )
#     }
# 
#     p <- layout(p,
#                 title = "Cluster characteristics",
#                 xaxis = list(
#                   title = list(
#                     text = "Attribute",
#                     font = list(size = 20)  # 设置x轴标题字体大小
#                   ),
#                   tickangle = -45  # 旋转x轴文本
#                 ),
#                 yaxis = list(
#                   title = "Score",font = list(size = 20)
#                 )
#                 #           legend = list(
#                 #   itemclick = 'toggleothers', # 点击图例时，切换其他图例
#                 #   traceorder = 'normal'       # 图例的显示顺序
#                 # )
#     )
#     p
# 
#    
#   })
  
  output$Optimal_Price <- renderText({
    # Attempt to extract the optimal price for the selected asin
    req(Optimal_Pricing())
    optimal_pricing_token <- req(Optimal_Pricing())
    
    price <-optimal_pricing_token %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(optinal_price) %>% req()
    
    
    # Check if price is found and has length > 0
    if (length(price) > 0 & price > 0 & price < 100) {
      paste0(round(price,2), " dollars")
    } else {
      "資訊不足"
    }
  })
  
  output$Max_Revenue <- renderText({
    req(Optimal_Pricing())
    optimal_pricing_token <- req(Optimal_Pricing())
    
    price <-optimal_pricing_token %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(optinal_price)%>% req()
    
    max_revenue <-Optimal_Pricing() %>% rename_with(make_names) %>%  
      filter(asin == input$Importance_asin) %>%
      pull(max_revenue)
    
    # Check if price is found and has length > 0
    if (length(price) > 0 & price > 0 & price < 100) {
      paste0(round(max_revenue,2), " dollars")
    } else {
      "資訊不足"
    }
  })
  
  output$Max_Profit <- renderText({
    req(Optimal_Pricing())
    optimal_pricing_token <- req(Optimal_Pricing())
    
    price <-optimal_pricing_token %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(optinal_price)%>% req()
 
    max_profit <-Optimal_Pricing() %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(max_profit)
    
    # Check if price is found and has length > 0
    if (length(price) > 0 & price > 0 & price < 100) {
      paste0(round(max_profit,2), " dollars")
    } else {
      "資訊不足"
    }
  })
  
  output$Optimal_Q <- renderText({
    req(Optimal_Pricing())
    optimal_pricing_token <- req(Optimal_Pricing())
    
    price <-optimal_pricing_token %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(optinal_price)%>% req()
    
    optimal_q <-req(Optimal_Pricing()) %>% rename_with(make_names) %>% 
      filter(asin == input$Importance_asin) %>%
      pull(optimal_q)
    
    # Check if price is found and has length > 0
    if (length(price) > 0 & price > 0 & price < 100) {
      paste0(round(optimal_q), " 個")
    } else {
      "資訊不足"
    }
  })

  output$poltly_Importance <- renderPlotly({
    incidencerate_long_token <- incidencerate_long() %>% filter(brand==brand_name)
    
    #input$Importance_asin==B09HQDR8C1
    
    # 資料處理部分
    data_filtered <- req(incidencerate_long_token)%>% 
      filter(asin == input$Importance_asin) %>%
      mutate(covariate = fct_reorder(covariate, incidence_ratio),
             color = ifelse(incidence_ratio >= 1, "Promotion", "Decline"))
    
    # 設置顏色映射
    color_map <- c("Promotion" = "#4CAF50", "Decline" = "#f68060")
    data_filtered$color <- factor(data_filtered$color, levels = c("Promotion", "Decline"))
    
    # 使用plotly繪製圖表
    plot <- plot_ly(data = data_filtered,
                    x = ~incidence_ratio,
                    y = ~covariate,
                    type = 'bar',
                    orientation = 'h',
                    marker = list(color = ~I(color_map[color])),
                    hoverinfo = 'text',  # 設置懸停時顯示文字
                    hovertext = ~paste('Incidence Ratio:', round(incidence_ratio, 3))) %>%  # 使用hovertext顯示懸停訊息
      layout(title = paste("Incidence Ratio of Factors for asin", input$Importance_asin),
             xaxis = list(title = 'Incidence Ratio (per day)', type = 'log',fixedrange = TRUE),
             yaxis = list(title = '',fixedrange = TRUE),
             barmode = 'overlay',
             showlegend = FALSE,
             plot_bgcolor = 'rgba(255, 255, 255, 0.9)',
             paper_bgcolor = 'rgba(255, 255, 255, 0.9)')
    
    plot
    
    
  })

  output$plotly_Importance_Competiter <- renderPlotly({
    incidencerate_long_competiter_token <- incidencerate_long() %>% filter(brand!=brand_name)
    # 資料處理部分
    data_filtered <- incidencerate_long_competiter_token %>% 
      filter(brand_asin == input$Importance_Competiter_asin) %>%
      mutate(covariate = fct_reorder(covariate, incidence_ratio),
             color = ifelse(incidence_ratio >= 1, "Promotion", "Decline"))
    
    # 設置顏色映射
    color_map <- c("Promotion" = "#4CAF50", "Decline" = "#f68060")
    data_filtered$color <- factor(data_filtered$color, levels = c("Promotion", "Decline"))
    
    # 使用plotly繪製圖表
    plot <- plot_ly(data = data_filtered,
                    x = ~incidence_ratio,
                    y = ~covariate,
                    type = 'bar',
                    orientation = 'h',
                    marker = list(color = ~I(color_map[color])),
                    hoverinfo = 'text',  # 設置懸停時顯示文字
                    hovertext = ~paste('Incidence Ratio:', round(incidence_ratio, 3))) %>%  # 使用hovertext顯示懸停訊息
      layout(title = paste("Incidence Ratio of Factors",input$Importance_Competiter_asin),
             xaxis = list(title = 'Incidence Ratio (per day)', type = 'log',fixedrange = TRUE),
             yaxis = list(title = '',fixedrange = TRUE),
             barmode = 'overlay',
             showlegend = FALSE,
             plot_bgcolor = 'rgba(255, 255, 255, 0.9)',
             paper_bgcolor = 'rgba(255, 255, 255, 0.9)')
    
    plot
  })

  output$plotly_Importance_Fixed <- renderPlotly({
    # 資料處理部分
    data_filtered <<- incidencerate_long_fixed() %>%
      mutate(covariate = fct_reorder(covariate, incidence_ratio),
             color = ifelse(incidence_ratio >= 1, "Promotion", "Decline"))
    
    # 設置顏色映射
    color_map <- c("Promotion" = "#4CAF50", "Decline" = "#f68060")
    data_filtered$color <- factor(data_filtered$color, levels = c("Promotion", "Decline"))
    
    # 使用plotly繪製圖表
    plot <- plot_ly(data = data_filtered,
                    x = ~incidence_ratio,
                    y = ~covariate,
                    type = 'bar',
                    orientation = 'h',
                    marker = list(color = ~I(color_map[color])),
                    hoverinfo = 'text',  # 設置懸停時顯示文字
                    hovertext = ~paste('Incidence Ratio:', round(incidence_ratio, 3))) %>%  # 使用hovertext顯示懸停訊息
      layout(title = paste("Incidence Ratio of Factors"),
             xaxis = list(title = 'Incidence Ratio (per day)', type = 'log',fixedrange = TRUE),
             yaxis = list(title = '',fixedrange = TRUE),
             barmode = 'overlay',
             showlegend = FALSE,
             plot_bgcolor = 'rgba(255, 255, 255, 0.9)',
             paper_bgcolor = 'rgba(255, 255, 255, 0.9)')
    
    plot
  })
  
  
  # Create the map
  output$salesmap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -96, lat = 37.8, zoom = 4)%>%
      htmlwidgets::onRender("
      function(el, x) {
        Shiny.setInputValue('salesmap_initialized', true);
      }
    ")
  })
  
  
  
  # # ---- (1) 全域定義地圖狀態 ----
  # view_state <- reactiveValues(
  #   center = c(lat = 37.8, lng = -96),  # 初始中心
  #   zoom   = 4
  # )
  # 
  # # ---- (2) 更新地圖中心和縮放 ----
  # observeEvent(input$map_center, {
  #   view_state$center <- c(lat = input$map_center$lat, lng = input$map_center$lng)
  # })
  # observeEvent(input$map_zoom, {
  #   view_state$zoom <- input$map_zoom
  # })

  observe({
    if (input$geo_salesmap == "state") {
      
      sales_by_time_state_token <- sales_by_time_state()
      
      sales_by_time_state_token2 <- sales_by_time_state_token %>% 
        group_by(state_filter) %>% # 按 state_filter 分組
        filter(time_scale == max(time_scale, na.rm = TRUE)) %>% # 選擇 time_scale 是最大值的行 
        #（因為timeframe相同所以不會有問題）
        ungroup() # 取消分組
      
      
      map_st <- st_read("app_data/SCD/gz_2010_us_040_00_500k.json", quiet = TRUE) %>%
        left_join(state_dictionary, by = c("NAME" = "name")) %>%
        left_join(sales_by_time_state_token2, by = c("abbreviation" = "state_filter"))
      
      indexvalue_column <- req(input$macro_salesmap)
      indexvalues <- as.numeric(map_st[[ indexvalue_column ]])
      req(indexvalues)
      
      pal <- colorNumeric("YlOrRd", domain = indexvalues)
      
      
      leafletProxy("salesmap", data = map_st) %>%
        clearShapes() %>%  # 清除現有的形狀
        addPolygons(
          fillColor = ~pal(indexvalues),
          weight = 1,
          color = "white",
          fillOpacity = 0.7,
          popup = ~paste(NAME, "<br> Value: ", round(indexvalues, 2))
        ) %>%
        clearControls() %>%  # 清除現有的圖例
        addLegend(
          position = "bottomright",
          pal = pal,
          values = indexvalues,
          title = "Value"
        )
    } else {
      
      sales_by_time_state_token <- sales_by_time_zip()

      indexvalue_column <- req(input$macro_salesmap)
      indexvalues <- as.numeric(sales_by_time_state_token[[ indexvalue_column ]])
      req(indexvalues)
      
      pal <- colorNumeric("YlOrRd", domain = indexvalues)
      
      
      leafletProxy("salesmap", data = sales_by_time_state_token) %>%
        clearShapes() %>%
        clearControls() %>% 
        addCircles(
          lat = ~lat, 
          lng = ~lng, 
          weight = 1, 
          radius = ~(indexvalues / max(indexvalues,na.rm = T) * 100000),  # 使用提取的數值來調整圓圈半徑
          color = "blue",
          fillOpacity = 0.2,
          popup = ~paste("Value: ", round(indexvalues, 2))  # 使用提取的數值在彈出窗口中顯示金額
        )
    }
  }) %>% bindEvent(input$time_scale_map,
                   input$macro_salesmap,
                   input$geo_salesmap,
                   input$salesmap_initialized,
                   sales_by_time_state(),
                   sales_by_time_zip())

#####繪製salesmap
  
  # Create the map
  output$mymap <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = -96, lat = 37.8, zoom = 4)%>%
      htmlwidgets::onRender("
      function(el, x) {
        Shiny.setInputValue('mymap_initialized', true);
      }
    ")
  })
  

  
  observe({
    indexvalue_column <- req(input$macro_map)
    map_dta_token <- map_dta()  # TODO:換成實際資料
    indexvalues <- as.numeric(map_dta_token[[ indexvalue_column ]])
    req(indexvalues)
    
    pal <- colorNumeric("YlOrRd", domain = indexvalues)
    if (input$geo_map == "state") {
      map_st <- st_read("app_data/SCD/gz_2010_us_040_00_500k.json", quiet = TRUE) %>%
        left_join(state_dictionary, by = c("NAME" = "name")) %>%
        left_join(map_dta_token, by = c("abbreviation" = "state"))
      
      leafletProxy("mymap", data = map_st) %>%
        clearShapes() %>%  # 清除現有的形狀
        addPolygons(
          fillColor = ~pal(indexvalues),
          weight = 1,
          color = "white",
          fillOpacity = 0.7,
          popup = ~paste(NAME, "<br> Value: ", round(indexvalues, 2))
        ) %>%
        clearControls() %>%  # 清除現有的圖例
        addLegend(
          position = "bottomright",
          pal = pal,
          values = indexvalues,
          title = "Value"
        )
    } else {
      leafletProxy("mymap", data = map_dta_token) %>%
        clearShapes() %>%
        clearControls() %>% 
        addCircles(
          lat = ~lat, 
          lng = ~lng, 
          weight = 1, 
          radius = ~(indexvalues / max(indexvalues,na.rm = T) * 100000),  # 使用提取的數值來調整圓圈半徑
          color = "blue",
          fillOpacity = 0.2,
          popup = ~paste("Value: ", round(indexvalues, 2))  # 使用提取的數值在彈出窗口中顯示金額
        )
    }
  }) %>% bindEvent(input$time_scale_map,input$macro_map,input$geo_map,input$mymap_initialized,map_dta())

  output$plotly_Property_Potential <- renderPlotly({
    # 示例数据框
    amazon_property_potential_token<- amazon_property_potential()
    print(amazon_property_potential_token)
    data_filtered <- amazon_property_potential_token %>% slice_head(n=18) %>% 
      mutate(covariates = fct_reorder(covariates, incidence_ratio),
             color = (lower_ir>1)+(upper_ir>1))
    
    
    # 假设你的数据框包含 'Lower' 和 'Upper' 列，表示每个条形的范围
    # 设置颜色映射
    color_map <- c("2" = "#4CAF50",  # 绿色
                   "1" = "#B0B0B0",  # 中性灰色
                   "0" = "#f68060")  # 红色
    
    data_filtered$color <- factor(data_filtered$color, levels = c("2", "1","0"))
    
    
    # 创建基础的空图
    # 创建基础的空图
        
    # Assuming data_filtered is your data frame
        
    # Assuming data_filtered is your data frame
    plot_ly(data = data_filtered) %>%
      add_segments(
        x = ~lower_ir, 
        xend = ~upper_ir, 
        y = ~covariates, 
        yend = ~covariates, 
        color = ~color_map[color],  # Set color by category
        hoverinfo = 'text',
        hovertext = ~paste(
          'Incidence Ratio:', round(incidence_ratio, 3), '<br>',
          'Lower Limit:', round(lower_ir, 3), '<br>',
          'Upper Limit:', round(upper_ir, 3)
        ),
        line = list(width = 8)  # Increase bar width
      ) %>%
      layout(
        xaxis = list(title = 'Incidence Ratio (每日)', type = 'log', fixedrange = TRUE),
        yaxis = list(title = '', fixedrange = TRUE),
        showlegend = FALSE,
        plot_bgcolor = 'rgba(255, 255, 255, 0.9)',
        paper_bgcolor = 'rgba(255, 255, 255, 0.9)',
        shapes = list(
          list(
            type = "line",
            x0 = 1, x1 = 1,  # x position for vertical line
            y0 = 0, y1 = 1,  # normalized y-axis to span entire range
            yref = "paper",  # Use paper coordinates for y to span full plot area
            line = list(color = "red", dash = "dash", width = 2)  # Style of the line
          )
        )
      )
  })
  
  
  output$plotly_time_potential <- renderPlotly({

    time_potential_token <- time_potential()
    
    # 示例数据框
    data_filtered <- time_potential_token%>% 
      as_tibble() %>%rename_with(make_names) %>%
      filter(covariates %in% unlist(timeSelect[input$time_potential_Select])) %>% 
      filter(if_all(everything(), ~ !is.na(.))) %>%  # 去掉包含 NA 的行
      filter(if_all(everything(), ~ !is.infinite(.))) %>%
      mutate(covariates = fct_reorder(covariates, incidence_ratio),
             color = (lower_ir>1)+(upper_ir>1))


    # 假设你的数据框包含 'Lower' 和 'Upper' 列，表示每个条形的范围
    # 设置颜色映射
    color_map <- c("2" = "#4CAF50",  # 绿色
                   "1" = "#B0B0B0",  # 中性灰色
                   "0" = "#f68060")  # 红色

    data_filtered$color <- factor(data_filtered$color, levels = c("2", "1","0"))


    # 创建基础的空图
    # 创建基础的空图

    # Assuming data_filtered is your data frame

    # Assuming data_filtered is your data frame
    plot_ly(data = data_filtered) %>%
      add_segments(
        x = ~lower_ir,
        xend = ~upper_ir,
        y = ~covariates,
        yend = ~covariates,
        color = ~color_map[color],  # Set color by category
        hoverinfo = 'text',
        hovertext = ~paste(
          'Incidence Ratio:', round(incidence_ratio, 3), '<br>',
          'Lower Limit:', round(lower_ir, 3), '<br>',
          'Upper Limit:', round(upper_ir, 3)
        ),
        line = list(width = 8)  # Increase bar width
      ) %>%
      layout(
        title = "Relative Incidence Ratio of Factors",
        xaxis = list(title = 'Incidence Ratio (per day)', type = 'log', fixedrange = TRUE),
        yaxis = list(title = '', fixedrange = TRUE),
        showlegend = FALSE,
        plot_bgcolor = 'rgba(255, 255, 255, 0.9)',
        paper_bgcolor = 'rgba(255, 255, 255, 0.9)',
        shapes = list(
          list(
            type = "line",
            x0 = 1, x1 = 1,  # x position for vertical line
            y0 = 0, y1 = 1,  # normalized y-axis to span entire range
            yref = "paper",  # Use paper coordinates for y to span full plot area
            line = list(color = "red", dash = "dash", width = 2)  # Style of the line
          )
        )
      )
  })
  
  
  output$Advertise_Output_Table <- renderDT({
    
    product_category_token<- req(input$product_category)
    
    if (input$distribution_channel=="officialwebsite") {
      advertise_output_dta <- advertise_generation_dta  %>% 
        filter(product_line_id==product_category_token,
          language == input$Advertise_Output_Language,
          media == input$Advertise_Output_Media) %>% select(asin,advertisement)
      
      if (input$product_category=="000"){
        advertise_output_dta <- advertise_generation_dta  %>% 
          filter(language == input$Advertise_Output_Language,
                 media == input$Advertise_Output_Media) %>% select(asin,advertisement)
      }
      
      advertise_output_dta
      
    } else {advertise_output_dta <- NULL}

    req(advertise_output_dta)
  },extensions = 'Buttons'
  , options = list(
    dom = 'Bfrtip',  # 顯示下載按鈕
    buttons = list(
      list(
        extend = 'excel',  # 設定按鈕類型為 CSV
        text = '個性化產品廣告輸出',  # 設定按鈕上顯示的文字
        filename = 'AI產品廣告'  # 設定下載的檔案名稱
      )
    ),  # 設定按鈕類型為 csv
    pageLength = -1,  # 展示所有行
    searching = FALSE,  # 禁用搜尋框
    lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
    info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
    paging = FALSE,  # 禁用分頁
    columnDefs = list(
      list(visible = FALSE, targets = 0)
    )
  ), colnames = c("asin", "廣告文案")
  )
  
  
  output$Advertise_Output_Ind_Table <- renderDT({

    
    sales_by_customer_token <- sales_by_customer()
    
    req(nrow(sales_by_customer_token)>0)
    
    if (input$distribution_channel=="officialwebsite") {
      advertise_filtered_dta <- advertise_generation_dta %>% 
        filter(product_line_id==input$product_category,
               language == input$Advertise_Output_Ind_Language,
               media == input$Advertise_Output_Ind_Media) %>% select(asin,advertisement)
      
      if (input$product_category=="000"){
        advertise_filtered_dta <- advertise_generation_dta  %>% 
          filter(language == input$Advertise_Output_Ind_Language,
                 media == input$Advertise_Output_Ind_Media) %>% select(asin,advertisement)
      }
      
      #下面input沒有加上req會有問題
      filtered_sales_by_customer <- sales_by_customer_token  %>% 
         filter(!is.na(be2) & nesstatus %in% req(input$Advertise_Output_Ind_nes) & be2< req(input$Advertise_Output_Ind_time)) %>%
        group_by(customer_id) %>%
        distinct(customer_id, .keep_all = TRUE)
      
      req(nrow(filtered_sales_by_customer)>0)
      
      ###filtered_sales_by_customer???為什麼會重複
      
      officialwebsite_end_date <- tbl(app_data,"time_range") %>% 
        filter(data_name=="officialwebsite_sales_zip_dta") %>% 
        select(end_date) %>% pull()
      
      if (is.null(filtered_sales_by_customer$customer_id) || length(filtered_sales_by_customer$customer_id) == 0) {
        recommendations <- tibble()  # 返回空的結果
      } else {
        recommendations <- tbl(app_data, "recommendation_asin") %>% 
          filter(customer_id %in% filtered_sales_by_customer$customer_id) %>% 
          distinct(customer_id, .keep_all = TRUE) %>%      # 資料庫層去重
          collect()
      }
      
      filtered_sales_by_customer %>% 
         left_join(recommendations,by=join_by("customer_id"),copy = TRUE) %>%
         select(customer_id,be2,nesstatus,recommendation_1,recommendation_2,recommendation_3) %>% 
         left_join(advertise_filtered_dta %>% rename(advertisement_1=advertisement),  join_by(recommendation_1 == asin),copy = TRUE)%>%
         left_join(advertise_filtered_dta %>% rename(advertisement_2=advertisement),  join_by(recommendation_2 == asin),copy = TRUE)%>%    
         left_join(advertise_filtered_dta %>% rename(advertisement_3=advertisement),  join_by(recommendation_3 == asin),copy = TRUE) %>% 
         arrange(be2) %>% mutate(be2=ceiling(be2)) %>% 
        mutate(best_send_date = officialwebsite_end_date+be2) %>%
        select(customer_id,best_send_date,nesstatus,recommendation_1,advertisement_1,recommendation_2,advertisement_2,recommendation_3,advertisement_3)
         
       
    } else {NULL}
    
  },extensions = 'Buttons'
  , options = list(
    dom = 'Bfrtip',  # 顯示下載按鈕
    buttons = list(
      list(
        extend = 'excel',  # 設定按鈕類型為 CSV
        text = '個人化廣告輸出',  # 設定按鈕上顯示的文字
        filename = 'AI個人化產品廣告'  # 設定下載的檔案名稱
      )
    ),  # 設定按鈕類型為 csv
    pageLength = -1,  # 展示所有行
    searching = FALSE,  # 禁用搜尋框
    lengthChange = FALSE,  # 不顯示「Show [number] entries」選項
    info = FALSE,  # 不顯示「Showing 1 to X of X entries」信息
    paging = FALSE,  # 禁用分頁
    columnDefs = list(
      list(visible = FALSE, targets = c(0,5,7,9))
    )
  ), colnames = c("顧客ID","最適廣告投放時間","NES狀態" ,"推薦產品1", "廣告1", "推薦產品2", "廣告2", "推薦產品3", "廣告3")
  )
  


  output$nes_transition_Plotly <- renderPlotly({
    
    nes_transition_token <- req(nes_transition())
    
    plot_ly(nes_transition_token, 
            x = ~nesstatus_pre, 
            y = ~activation_rate, 
            type = 'bar', 
            color = ~nesstatus_now, 
            colors = rev(brewer.pal(5, "OrRd")),
            text = ~paste("人數：", count, "<br>百分比：", round(activation_rate * 100, 1), "%"),
            hoverinfo = 'text',  # 使滑鼠懸停顯示文本
            marker = list(line = list(width = 1))) %>%
      layout(barmode = 'stack', 
             yaxis = list(title = '轉換nes百分比', tickformat = '.0%', fixedrange = TRUE),  # 將 y 軸顯示為百分比
             xaxis = list(title = '過去nes', fixedrange = TRUE))
    
  })



  # session$onSessionEnded(function() {
  #  #section endded
  #    gc()
  # })

  }
shinyApp(ui, server)
