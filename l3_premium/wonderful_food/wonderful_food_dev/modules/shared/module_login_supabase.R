# ==============================================================================
# Supabase Login Module for Shiny
# File: modules/shared/module_login_supabase.R
# Purpose: Shiny module for user authentication via Supabase
# Date: 2025-01-19
# Replaces: modules/module_login.R (bcrypt-based)
# ==============================================================================

library(shiny)
library(bs4Dash)

# Load Supabase authentication functions
# Note: Ensure this is sourced before using the module
# source("modules/shared/module_supabase_auth.R")

# ==============================================================================
# UI Component
# ==============================================================================

#' Login Module UI
#'
#' @param id Module namespace ID
#' @param title Login box title (default: "登入")
#' @param show_language_selector Whether to show language dropdown
#' @return Shiny UI elements for login form
loginSupabaseUI <- function(id, title = "登入", show_language_selector = TRUE) {
  ns <- NS(id)

  div(
    class = "login-wrapper",
    style = "display: flex; justify-content: center; align-items: center; min-height: 80vh;",

    bs4Card(
      title = title,
      status = "primary",
      solidHeader = TRUE,
      width = 4,
      collapsible = FALSE,

      # Language selector (optional)
      if (show_language_selector) {
        div(
          class = "mb-3",
          selectInput(
            ns("language"),
            label = NULL,
            choices = c(
              "\u4e2d\u6587" = "chinese",
              "English" = "english",
              "\u65e5\u672c\u8a9e" = "japanese"
            ),
            selected = "chinese",
            width = "100%"
          )
        )
      },

      # Username input
      div(
        class = "mb-3",
        textInput(
          ns("username"),
          label = "\u5e33\u865f",
          placeholder = "\u8acb\u8f38\u5165\u5e33\u865f",
          width = "100%"
        )
      ),

      # Password input
      div(
        class = "mb-3",
        passwordInput(
          ns("password"),
          label = "\u5bc6\u78bc",
          placeholder = "\u8acb\u8f38\u5165\u5bc6\u78bc",
          width = "100%"
        )
      ),

      # Error message placeholder
      uiOutput(ns("error_msg")),

      # Login info placeholder (remaining logins)
      uiOutput(ns("login_info")),

      # Login button
      div(
        class = "d-grid gap-2",
        actionButton(
          ns("login_btn"),
          label = "\u767b\u5165",
          class = "btn-primary btn-lg",
          width = "100%"
        )
      )
    )
  )
}

# ==============================================================================
# Server Component
# ==============================================================================

#' Login Module Server (Compatible Interface)
#'
#' @param id Module namespace ID
#' @param app_name App name for login limit tracking (e.g., "brandedge")
#' @param lang_texts Optional language texts (for compatibility with existing modules)
#' @param on_login_success Optional callback function when login succeeds
#' @return reactiveValues list with user_info(), logged_in(), and logout() for compatibility
#'
#' @examples
#' # In server function:
#' login_result <- loginSupabaseServer("login", app_name = "brandedge")
#'
#' observe({
#'   if (!is.null(login_result$user_info())) {
#'     # User is logged in
#'     showNotification("Welcome!")
#'   }
#' })
loginSupabaseServer <- function(id, app_name, lang_texts = NULL, on_login_success = NULL) {
  moduleServer(id, function(input, output, session) {

    # Reactive values for compatibility with existing interface
    rv <- reactiveValues(
      user_info = NULL,
      logged_in = FALSE
    )

    # Reactive accessors (for compatibility)
    user_info_reactive <- reactive({ rv$user_info })
    logged_in_reactive <- reactive({ rv$logged_in })

    # Clear error when user types
    observeEvent(c(input$username, input$password), {
      output$error_msg <- renderUI(NULL)
    }, ignoreInit = TRUE)

    # Login button handler
    observeEvent(input$login_btn, {
      message("🔐 [DEBUG] Login button clicked!")

      # Validate inputs
      username <- trimws(input$username)
      password <- input$password

      message(sprintf("🔐 [DEBUG] Username: '%s', Password length: %d", username, nchar(password)))

      if (username == "" || password == "") {
        output$error_msg <- renderUI({
          div(
            class = "alert alert-warning",
            role = "alert",
            icon("exclamation-triangle"),
            " \u8acb\u8f38\u5165\u5e33\u865f\u548c\u5bc6\u78bc"
          )
        })
        return()
      }

      # Attempt login via Supabase
      message("🔐 [DEBUG] Calling login_user()...")
      login_result <- tryCatch({
        login_user(username, password, app_name)
      }, error = function(e) {
        message(sprintf("🔐 [ERROR] login_user() failed: %s", e$message))
        list(success = FALSE, error = e$message)
      })
      message(sprintf("🔐 [DEBUG] login_result: success=%s, allowed=%s",
                      isTRUE(login_result$success),
                      isTRUE(login_result$allowed)))

      # Check authentication
      if (!isTRUE(login_result$success)) {
        output$error_msg <- renderUI({
          div(
            class = "alert alert-danger",
            role = "alert",
            icon("times-circle"),
            " \u5e33\u865f\u6216\u5bc6\u78bc\u932f\u8aa4"
          )
        })
        return()
      }

      # Check login limit
      if (!isTRUE(login_result$allowed)) {
        output$error_msg <- renderUI({
          div(
            class = "alert alert-danger",
            role = "alert",
            icon("ban"),
            " \u767b\u5165\u6b21\u6578\u5df2\u9054\u4e0a\u9650\uff0c\u8acb\u806f\u7e6b\u7ba1\u7406\u54e1"
          )
        })
        return()
      }

      # Login successful!
      user_info <- list(
        authenticated = TRUE,
        user_id = login_result$user_id,
        username = login_result$username,
        role = login_result$role,
        display_name = login_result$display_name,
        company = login_result$company,
        is_admin = isTRUE(login_result$is_admin),
        remaining_logins = login_result$remaining_logins,
        selected_language = input$language %||% "chinese"
      )

      # Update reactive values (compatible interface)
      message("🔐 [DEBUG] Updating reactive values...")
      rv$user_info <- user_info
      rv$logged_in <- TRUE
      message(sprintf("🔐 [DEBUG] rv$logged_in = %s, rv$user_info$username = %s",
                      rv$logged_in, rv$user_info$username))

      # Show remaining logins info (for non-admin)
      if (!user_info$is_admin && !is.null(user_info$remaining_logins)) {
        output$login_info <- renderUI({
          div(
            class = "alert alert-info",
            role = "alert",
            icon("info-circle"),
            sprintf(" \u5269\u9918\u767b\u5165\u6b21\u6578\uff1a%d", user_info$remaining_logins)
          )
        })
      }

      # Call success callback if provided
      if (is.function(on_login_success)) {
        on_login_success(user_info)
      }

      # Log successful login
      message(sprintf(
        "[LOGIN] User '%s' (%s) logged into %s. Remaining: %s",
        username,
        user_info$role,
        app_name,
        ifelse(user_info$is_admin, "unlimited", as.character(user_info$remaining_logins))
      ))
    })

    # Logout function (compatible interface)
    logout_fn <- function() {
      rv$user_info <- NULL
      rv$logged_in <- FALSE
      message("[LOGOUT] User logged out via Supabase module")
    }

    # Return compatible interface (same as existing loginModuleServer)
    return(list(
      user_info = user_info_reactive,
      logged_in = logged_in_reactive,
      logout = logout_fn
    ))
  })
}

# ==============================================================================
# Helper: Logout Handler
# ==============================================================================

#' Create a logout observer
#'
#' @param logout_button_id The ID of the logout button (with namespace)
#' @param user_data The reactive value from loginSupabaseServer
#' @param session The Shiny session
#'
#' @examples
#' # In server:
#' observeEvent(input$logout_btn, {
#'   user_data(NULL)
#'   session$reload()
#' })
create_logout_handler <- function(logout_button_id, user_data, session) {
  observeEvent(session$input[[logout_button_id]], {
    user_data(NULL)
    session$reload()
  })
}

# ==============================================================================
# Conditional UI Helper
# ==============================================================================

#' Render login UI or main content based on authentication status
#'
#' @param user_data Reactive value from loginSupabaseServer
#' @param login_ui UI to show when not logged in
#' @param main_ui UI to show when logged in
#' @return Reactive UI
#'
#' @examples
#' output$main_content <- renderUI({
#'   conditionalLoginUI(
#'     user_data(),
#'     login_ui = loginSupabaseUI("login"),
#'     main_ui = dashboardPage(...)
#'   )
#' })
conditionalLoginUI <- function(user_data, login_ui, main_ui) {
  if (is.null(user_data) || !isTRUE(user_data$authenticated)) {
    return(login_ui)
  } else {
    return(main_ui)
  }
}

# ==============================================================================
# Integration Example (for reference)
# ==============================================================================

# Example usage in app.R:
#
# library(shiny)
# library(bs4Dash)
#
# # Source modules
# source("modules/shared/module_supabase_auth.R")
# source("modules/shared/module_login_supabase.R")
#
# ui <- dashboardPage(
#   header = dashboardHeader(title = "My App"),
#   sidebar = dashboardSidebar(disable = TRUE),
#   body = dashboardBody(
#     uiOutput("content")
#   )
# )
#
# server <- function(input, output, session) {
#   # Login module
#   user <- loginSupabaseServer("login", app_name = "brandedge")
#
#   # Conditional content
#   output$content <- renderUI({
#     if (is.null(user()) || !user()$authenticated) {
#       loginSupabaseUI("login")
#     } else {
#       # Main app content
#       div(
#         h1(paste("Welcome,", user()$display_name)),
#         p(paste("Role:", user()$role)),
#         actionButton("logout", "Logout")
#       )
#     }
#   })
#
#   # Logout handler
#   observeEvent(input$logout, {
#     user(NULL)
#     session$reload()
#   })
# }
#
# shinyApp(ui, server)
