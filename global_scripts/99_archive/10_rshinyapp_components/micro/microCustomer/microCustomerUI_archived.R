# THIS FILE HAS BEEN ARCHIVED FOLLOWING R28 ARCHIVING STANDARD
# Date archived: 2025-04-07
# Reason: Combined into microCustomer.R under P15 Debug Efficiency Exception
# Replacement: microCustomer.R (contains UI, server, and defaults)

#' Micro Customer UI Component
#'
#' This component provides the UI elements for displaying detailed customer analytics
#' in the micro-level view of the application.
#'
#' IMPORTANT: According to the UI-Server Pairing Rule, this UI component MUST be used with
#' its corresponding server component microCustomerServer(). All outputs defined here
#' must be fulfilled by the server component to avoid broken displays.
#'
#' @param id The module ID
#'
#' @return A UI component
#' @export
microCustomerUI <- function(id) {
  ns <- NS(id)
  
  nav_panel(
    title = "微觀",
    bs4Dash::bs4Card(
      full_screen = TRUE,
      bs4Dash::bs4CardBody(
        # Header: Customer Name and Email
        fluidRow(
          column(12,
                 div(
                   class = "customer-profile-header",
                   style = "margin-bottom: 15px; padding-bottom: 15px; border-bottom: 1px solid #eee; text-align: center;",
                   div(
                     style = "font-size: 1.4rem; font-weight: 600;",
                     htmlOutput(ns("customer_name"))
                   ),
                   div(
                     style = "font-size: 1rem; color: #666;",
                     htmlOutput(ns("customer_email"))
                   )
                 )
          )
        ),
        # Row 1: 顧客資歷、最近購買日(R)、購買頻率(F)
        fluidRow(
          column(4, bs4Dash::valueBoxOutput(ns("dna_time_first"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_recency"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_frequency"), width = 12))
        ),
        # Row 2: 購買金額(M)、顧客活躍度(CAI)、顧客平均購買週期(IPT)
        fluidRow(
          column(4, bs4Dash::valueBoxOutput(ns("dna_monetary"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_cai"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_ipt"), width = 12))
        ),
        # Row 3: 過去價值(PCV)、顧客終身價值(CLV)、顧客交易穩定度 (CRI)
        fluidRow(
          column(4, bs4Dash::valueBoxOutput(ns("dna_pcv"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_clv"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_cri"), width = 12))
        ),
        # Row 4: 顧客狀態(NES)、新客單價、主力客單價
        fluidRow(
          column(4, bs4Dash::valueBoxOutput(ns("dna_nes"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_nt"), width = 12)),
          column(4, bs4Dash::valueBoxOutput(ns("dna_e0t"), width = 12))
        )
      )
    )
  )
}