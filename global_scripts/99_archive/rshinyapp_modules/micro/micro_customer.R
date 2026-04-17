# Micro Customer Module
# Shows detailed analysis for individual customers

#' Micro Customer UI Function
#'
#' @param id The module ID
#'
#' @return A UI component
#'
microCustomerUI <- function(id) {
  ns <- NS(id)
  
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
                inputId = ns("dna_customer_name"),
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
                
                # Customer info value boxes
                value_box(
                  title = "顧客資歷",
                  value = textOutput(ns("dna_time_first")),
                  showcase = bs_icon("calendar-event-fill"),
                  p(textOutput(ns("dna_time_first_tonow"), inline = TRUE), "天")
                ),
                value_box(
                  title = "最近購買日(R)",
                  value = textOutput(ns("dna_rlabel")),
                  showcase = bs_icon("calendar-event-fill"),
                  p(textOutput(ns("dna_rvalue"), inline = TRUE), "天前")
                ),
                value_box(
                  title = "購買頻率(F)",
                  value = textOutput(ns("dna_flabel")),
                  showcase = bs_icon("plus-lg"),
                  p(textOutput(ns("dna_fvalue"), inline = TRUE), "次")
                ),
                value_box(
                  title = "購買金額(M)",
                  value = textOutput(ns("dna_mlabel")),
                  showcase = bs_icon("pie-chart"),
                  p(textOutput(ns("dna_mvalue"), inline = TRUE), "美金")
                ),
                value_box(
                  title = "顧客活躍度(CAI)",
                  value = textOutput(ns("dna_cailabel")),
                  showcase = bs_icon("pie-chart"),
                  p("CAI = ", textOutput(ns("dna_cai"), inline = TRUE))
                ),
                value_box(
                  title = "顧客平均購買週期(IPT)",
                  value = div(
                    textOutput(ns("dna_ipt_mean"), inline = TRUE),
                    " 天"
                  ),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "過去價值(PCV)",
                  value = div(
                    textOutput(ns("dna_pcv"), inline = TRUE),
                    " 美金"
                  ),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "顧客終身價值(CLV)",
                  value = div(
                    textOutput(ns("dna_clv"), inline = TRUE),
                    " 美金"
                  ),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "顧客交易穩定度 (CRI)",
                  value = textOutput(ns("dna_cri")),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "顧客停止購買預測",
                  value = textOutput(ns("dna_nrec")),
                  showcase = bs_icon("pie-chart"),
                  p("停止機率 = ", textOutput(ns("dna_nrec_onemin_prob"), inline = TRUE))
                ),
                value_box(
                  title = "顧客狀態(NES)",
                  value = textOutput(ns("dna_nesstatus")),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "新客單價",
                  value = textOutput(ns("dna_nt")),
                  p("美金"),
                  showcase = bs_icon("pie-chart")
                ),
                value_box(
                  title = "主力客單價",
                  value = textOutput(ns("dna_e0t")),
                  p("美金"),
                  showcase = bs_icon("pie-chart")
                )
              )
            )
          )
        )
      )
    )
  )
}

#' Micro Customer Server Function
#'
#' @param id The module ID
#' @param data_source The data source reactive list
#'
#' @return None
#'
microCustomerServer <- function(id, data_source) {
  moduleServer(id, function(input, output, session) {
    # Customer data for dropdown list
    customer_data <- reactive({
      data_source$sales_by_customer()
    })
    
    # Update customer selector with available customers
    observe({
      customers <- customer_data()
      
      if (!is.null(customers) && nrow(customers) > 0) {
        updateSelectizeInput(
          session,
          "dna_customer_name", 
          choices = unique(customers$customer_name),
          selected = customers$customer_name[1]
        )
      }
    })
    
    # Selected customer data
    selected_customer_data <- reactive({
      req(input$dna_customer_name)
      
      customers <- customer_data()
      customers %>% filter(customer_name == input$dna_customer_name)
    })
    
    # Render customer DNA outputs
    observe({
      customer <- selected_customer_data()
      
      if (!is.null(customer) && nrow(customer) > 0) {
        # Customer history metrics
        output$dna_time_first <- renderText({ format(customer$time_first[1], "%Y-%m-%d") })
        output$dna_time_first_tonow <- renderText({ customer$time_first_tonow[1] })
        
        # RFM metrics
        output$dna_rlabel <- renderText({ textRlabel[customer$rlabel[1]] })
        output$dna_rvalue <- renderText({ customer$rvalue[1] })
        output$dna_flabel <- renderText({ textFlabel[customer$flabel[1]] })
        output$dna_fvalue <- renderText({ customer$fvalue[1] })
        output$dna_mlabel <- renderText({ textMlabel[customer$mlabel[1]] })
        output$dna_mvalue <- renderText({ round(customer$mvalue[1], 2) })
        
        # Customer activity metrics
        output$dna_cailabel <- renderText({ textCAIlabel[customer$cailabel[1]] })
        output$dna_cai <- renderText({ round(customer$cai[1], 2) })
        output$dna_ipt_mean <- renderText({ round(customer$ipt_mean[1], 1) })
        
        # Value metrics
        output$dna_pcv <- renderText({ round(customer$pcv[1], 2) })
        output$dna_clv <- renderText({ round(customer$clv[1], 2) })
        output$dna_cri <- renderText({ round(customer$cri[1], 2) })
        
        # Prediction metrics
        output$dna_nrec <- renderText({ ifelse(customer$nrec[1] > 0.5, "高", "低") })
        output$dna_nrec_onemin_prob <- renderText({ scales::percent(customer$nrec[1], accuracy = 0.1) })
        
        # Status metrics
        output$dna_nesstatus <- renderText({ customer$nesstatus[1] })
        
        # Transaction metrics
        output$dna_nt <- renderText({ round(customer$nt[1], 2) })
        output$dna_e0t <- renderText({ round(customer$e0t[1], 2) })
      } else {
        # If no customer data, show placeholders
        output$dna_time_first <- renderText({ "N/A" })
        output$dna_time_first_tonow <- renderText({ "0" })
        output$dna_rlabel <- renderText({ "N/A" })
        output$dna_rvalue <- renderText({ "0" })
        output$dna_flabel <- renderText({ "N/A" })
        output$dna_fvalue <- renderText({ "0" })
        output$dna_mlabel <- renderText({ "N/A" })
        output$dna_mvalue <- renderText({ "0.00" })
        output$dna_cailabel <- renderText({ "N/A" })
        output$dna_cai <- renderText({ "0.00" })
        output$dna_ipt_mean <- renderText({ "0.0" })
        output$dna_pcv <- renderText({ "0.00" })
        output$dna_clv <- renderText({ "0.00" })
        output$dna_cri <- renderText({ "0.00" })
        output$dna_nrec <- renderText({ "N/A" })
        output$dna_nrec_onemin_prob <- renderText({ "0%" })
        output$dna_nesstatus <- renderText({ "N/A" })
        output$dna_nt <- renderText({ "0.00" })
        output$dna_e0t <- renderText({ "0.00" })
      }
    })
  })
}