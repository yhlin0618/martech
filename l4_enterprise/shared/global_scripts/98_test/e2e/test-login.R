# E2E Test: Login Flow
# Level: L1 (Smoke Test) - run on every commit
#
# Tests the passwordOnly login module:
#   - Correct password grants access
#   - Wrong password shows error
#   - Empty password is rejected
#
# Principles: TD_R007 (E2E testing)

test_that("correct password logs in successfully", {
  app <- shinytest2::AppDriver$new(
    app_dir = getOption("e2e.project_root", getwd()),
    name = "e2e-login-success",
    timeout = 30000,
    load_timeout = 60000,
    seed = 12345
  )
  on.exit(stop_app_safely(app), add = TRUE)

  # Wait for login page
  Sys.sleep(2)

  # Enter correct password

  app$set_inputs(`auth-password` = "VIBE")
  app$click("auth-submit_btn")
  app$wait_for_idle(timeout = 15000)
  Sys.sleep(2)

  # Verify login succeeded: sidebar_menu should have a value
  assert_logged_in(app)
  assert_no_r_errors(app, "login")
})


test_that("wrong password shows error message", {
  app <- shinytest2::AppDriver$new(
    app_dir = getOption("e2e.project_root", getwd()),
    name = "e2e-login-fail",
    timeout = 30000,
    load_timeout = 60000,
    seed = 12345
  )
  on.exit(stop_app_safely(app), add = TRUE)

  Sys.sleep(2)

  # Enter wrong password
  app$set_inputs(`auth-password` = "WRONG_PASSWORD")
  app$click("auth-submit_btn")
  app$wait_for_idle(timeout = 5000)
  Sys.sleep(1)

  # The app pre-initializes sidebar_menu even before login, so validate the
  # login error message instead of relying on sidebar_menu == NULL.
  msg_html <- app$get_html("#auth-msg_container")
  expect_match(msg_html, "密碼錯誤|Incorrect password|剩餘", perl = TRUE)
})


test_that("empty password is rejected", {
  app <- shinytest2::AppDriver$new(
    app_dir = getOption("e2e.project_root", getwd()),
    name = "e2e-login-empty",
    timeout = 30000,
    load_timeout = 60000,
    seed = 12345
  )
  on.exit(stop_app_safely(app), add = TRUE)

  Sys.sleep(2)

  # Click submit without entering password
  app$click("auth-submit_btn")
  app$wait_for_idle(timeout = 5000)
  Sys.sleep(1)

  # Empty password does not submit; the login container should remain present.
  login_html <- app$get_html("#auth-login_container")
  expect_match(login_html, "auth-password", fixed = TRUE)
  assert_no_r_errors(app, "empty password rejection")
})
