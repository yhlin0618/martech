# Test script for ROS Module
# This script tests the new module_dna_multi_pro2.R

library(shiny)
library(dplyr)

# Source the new module
source("modules/module_dna_multi_pro2.R")

# Create sample data for testing
create_test_data <- function() {
  set.seed(123)
  n_customers <- 100
  
  # Create sample transaction data
  transactions <- data.frame(
    customer_id = rep(1:n_customers, each = sample(1:10, n_customers, replace = TRUE)),
    payment_time = Sys.time() - runif(n_customers * 5, 0, 365) * 24 * 3600,
    lineitem_price = runif(n_customers * 5, 10, 200)
  ) %>%
    arrange(customer_id, payment_time)
  
  return(transactions)
}

# Test UI function
test_ui <- function() {
  ui <- fluidPage(
    titlePanel("ROS Module Test"),
    dnaMultiPro2ModuleUI("test_module")
  )
  
  server <- function(input, output, session) {
    # Create test data
    test_data <- reactive({
      create_test_data()
    })
    
    # Initialize the module
    dnaMultiPro2ModuleServer("test_module", con = NULL, user_info = reactive(NULL), uploaded_dna_data = test_data)
  }
  
  shinyApp(ui = ui, server = server)
}

# Function to test ROS calculation
test_ros_calculation <- function() {
  # Create sample DNA data
  sample_dna_data <- data.frame(
    customer_id = 1:20,
    nrec_prob = runif(20, 0, 1),
    ipt = runif(20, 1, 30),
    ipt_mean = runif(20, 1, 30),
    cri = runif(20, 0, 1),
    m_value = runif(20, 10, 100),
    f_value = sample(1:20, 20, replace = TRUE),
    r_value = runif(20, 1, 100),
    stringsAsFactors = FALSE
  )
  
  # Test ROS calculation function
  calculate_ros_metrics <- function(dna_data, risk_threshold = 0.6, opportunity_threshold = 7, stability_low = 0.3, stability_high = 0.7) {
    # 先檢查並新增缺失的欄位
    if (!"nrec_prob" %in% names(dna_data)) {
      dna_data$nrec_prob <- 0
    }
    if (!"ipt_mean" %in% names(dna_data) && !"ipt" %in% names(dna_data)) {
      dna_data$ipt_mean <- 30
    }
    if (!"cri" %in% names(dna_data)) {
      dna_data$cri <- 0.5
    }
    
    dna_data %>%
      mutate(
        # Risk 評分 (基於流失機率)
        risk_score = ifelse(is.na(nrec_prob), 0, nrec_prob),
        risk_flag = ifelse(risk_score >= risk_threshold, 1, 0),
        
        # Opportunity 評分 (基於預期購買間隔)
        predicted_tnp = case_when(
          !is.na(ipt_mean) ~ ipt_mean,
          !is.na(ipt) ~ ipt,
          TRUE ~ 30
        ),
        opportunity_flag = ifelse(predicted_tnp <= opportunity_threshold, 1, 0),
        
        # Stability 評分 (基於規律性指數)
        stability_score = ifelse(is.na(cri), 0.5, cri),
        stability_level = case_when(
          stability_score >= stability_high ~ "S-High",   # 穩定度 ≥ 0.7
          stability_score > stability_low ~ "S-Medium",   # 0.3 < 穩定度 < 0.7
          TRUE ~ "S-Low"                                  # 穩定度 ≤ 0.3
        ),
        
        # ROS 綜合分類
        ros_segment = case_when(
          # Baseline 組合：R=1 且 S=Low
          risk_flag == 1 & stability_level == "S-Low" ~ paste("R +", stability_level),
          # Baseline 組合：只有 O=1
          risk_flag == 0 & opportunity_flag == 1 & stability_level != "S-Low" ~ "O",
          risk_flag == 0 & opportunity_flag == 1 & stability_level == "S-Low" ~ paste("O +", stability_level),
          # 一般組合
          TRUE ~ paste0(
            ifelse(risk_flag == 1, "R", "r"),
            ifelse(opportunity_flag == 1, "O", "o"), 
            " + ", stability_level
          )
        ),
        
        # ROS 描述
        ros_description = paste0(
          ifelse(risk_flag == 1, "高風險", "低風險"), " | ",
          ifelse(opportunity_flag == 1, "高機會", "低機會"), " | ",
          case_when(
            stability_level == "S-High" ~ "高穩定",
            stability_level == "S-Medium" ~ "中穩定", 
            TRUE ~ "低穩定"
          )
        )
      )
  }
  
  # Test the calculation
  result <- calculate_ros_metrics(sample_dna_data)
  
  # Print results
  cat("ROS Calculation Test Results:\n")
  cat("Number of customers:", nrow(result), "\n")
  cat("ROS segments found:", length(unique(result$ros_segment)), "\n")
  cat("Unique ROS segments:", paste(unique(result$ros_segment), collapse = ", "), "\n")
  
  # Show distribution
  ros_dist <- table(result$ros_segment)
  cat("\nROS Distribution:\n")
  print(ros_dist)
  
  return(result)
}

# Run tests
if (interactive()) {
  cat("Testing ROS calculation...\n")
  test_result <- test_ros_calculation()
  
  cat("\nTo test the full UI, run: test_ui()\n")
  cat("Note: You'll need a database connection for full functionality.\n")
} else {
  cat("Test script loaded. Run test_ros_calculation() or test_ui() to test.\n")
} 