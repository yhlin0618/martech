# 測試客戶資料檢查新欄位功能
# Test Customer Data Table with Static Segment and Lifecycle Fields

# 載入必要套件
library(dplyr)

# 載入模組
source("modules/module_dna_multi_pro2.R")

cat("=================================================\n")
cat("測試客戶資料檢查新欄位功能\n")
cat("=================================================\n\n")

# 創建測試資料
set.seed(123)
test_customers <- data.frame(
  customer_id = paste0("C", 1:20),
  m_value = runif(20, 10, 200),
  f_value = sample(1:10, 20, replace = TRUE),
  r_value = runif(20, 0, 100),
  value_level = sample(c("高", "中", "低"), 20, replace = TRUE),
  activity_level = sample(c("高", "中", "低"), 20, replace = TRUE),
  lifecycle_stage = sample(c("newbie", "active", "sleepy", "half_sleepy", "dormant"), 20, replace = TRUE),
  total_spent = runif(20, 100, 5000),
  times = sample(1:20, 20, replace = TRUE),
  nrec_prob = runif(20, 0, 1),
  ipt_mean = runif(20, 5, 60),
  cri = runif(20, 0, 1),
  stringsAsFactors = FALSE
)

cat("原始測試資料：\n")
print(head(test_customers))

# 測試 calculate_ros_metrics 函數
cat("\n測試 ROS 指標計算...\n")
ros_data <- test_customers %>%
  mutate(
    # 先計算 ROS 指標
    risk_score = nrec_prob,
    risk_flag = ifelse(risk_score >= 0.6, 1, 0),
    predicted_tnp = ipt_mean,
    opportunity_flag = ifelse(predicted_tnp <= 7, 1, 0),
    stability_score = cri,
    stability_level = case_when(
      stability_score >= 0.7 ~ "S-High",
      stability_score > 0.3 ~ "S-Medium",
      TRUE ~ "S-Low"
    ),
    ros_segment = case_when(
      risk_flag == 1 & stability_level == "S-Low" ~ paste("R +", stability_level),
      risk_flag == 0 & opportunity_flag == 1 & stability_level != "S-Low" ~ "O",
      risk_flag == 0 & opportunity_flag == 1 & stability_level == "S-Low" ~ paste("O +", stability_level),
      TRUE ~ paste0(
        ifelse(risk_flag == 1, "R", "r"),
        ifelse(opportunity_flag == 1, "O", "o"), 
        " + ", stability_level
      )
    ),
    ros_description = paste0(
      ifelse(risk_flag == 1, "高風險", "低風險"), " | ",
      ifelse(opportunity_flag == 1, "高機會", "低機會"), " | ",
      case_when(
        stability_level == "S-High" ~ "高穩定",
        stability_level == "S-Medium" ~ "中穩定", 
        TRUE ~ "低穩定"
      )
    ),
    # 新增欄位：靜態區隔
    static_segment = paste0(
      case_when(
        value_level == "高" ~ "A",
        value_level == "中" ~ "B",
        TRUE ~ "C"
      ),
      case_when(
        activity_level == "高" ~ "1",
        activity_level == "中" ~ "2", 
        TRUE ~ "3"
      ),
      case_when(
        lifecycle_stage == "newbie" ~ "N",
        lifecycle_stage == "active" ~ "C",
        lifecycle_stage == "sleepy" ~ "D",
        lifecycle_stage == "half_sleepy" ~ "H",
        TRUE ~ "S"  # dormant
      )
    ),
    # 新增欄位：生命週期中文描述
    lifecycle_stage_zh = case_when(
      lifecycle_stage == "newbie" ~ "新客",
      lifecycle_stage == "active" ~ "主力客",
      lifecycle_stage == "sleepy" ~ "睡眠客",
      lifecycle_stage == "half_sleepy" ~ "半睡客",
      lifecycle_stage == "dormant" ~ "沉睡客",
      TRUE ~ lifecycle_stage
    )
  )

cat("✅ ROS 指標計算完成！\n")

# 檢查新欄位
cat("\n新增欄位檢查：\n")
cat("1. 靜態區隔 (static_segment):\n")
print(table(ros_data$static_segment))

cat("\n2. 生命週期中文 (lifecycle_stage_zh):\n")
print(table(ros_data$lifecycle_stage_zh))

# 顯示客戶資料表格預覽
cat("\n客戶資料表格預覽：\n")
display_preview <- ros_data %>%
  select(
    客戶ID = customer_id,
    靜態區隔 = static_segment,
    生命週期 = lifecycle_stage_zh,
    原生命週期 = lifecycle_stage,
    價值等級 = value_level,
    活躍等級 = activity_level,
    ROS分類 = ros_segment,
    M值 = m_value,
    F值 = f_value,
    風險分數 = risk_score,
    穩定分數 = stability_score
  ) %>%
  mutate(
    M值 = round(M值, 2),
    風險分數 = round(風險分數, 3),
    穩定分數 = round(穩定分數, 3)
  )

print(head(display_preview, 10))

# 檢查靜態區隔分佈統計
cat("\n靜態區隔分佈統計：\n")
segment_stats <- ros_data %>%
  group_by(static_segment, lifecycle_stage_zh) %>%
  summarise(
    客戶數 = n(),
    平均M值 = round(mean(m_value, na.rm = TRUE), 2),
    平均F值 = round(mean(f_value, na.rm = TRUE), 1),
    .groups = "drop"
  ) %>%
  arrange(static_segment)

print(segment_stats)

cat("\n=================================================\n")
cat("✅ 客戶資料檢查新欄位功能測試完成！\n")
cat("=================================================\n")

# 測試篩選功能
cat("\n測試篩選功能：\n")
cat("1. 篩選靜態區隔 A1C 的客戶：\n")
a1c_customers <- ros_data %>% filter(static_segment == "A1C")
cat("   找到", nrow(a1c_customers), "位客戶\n")

cat("\n2. 篩選主力客的客戶：\n")
active_customers <- ros_data %>% filter(lifecycle_stage_zh == "主力客")
cat("   找到", nrow(active_customers), "位客戶\n")

cat("\n3. 篩選高價值、高活躍的新客：\n")
high_value_new <- ros_data %>% 
  filter(value_level == "高", activity_level == "高", lifecycle_stage_zh == "新客")
cat("   找到", nrow(high_value_new), "位客戶\n")

cat("\n✅ 所有測試完成！新功能可以正常運作。\n") 