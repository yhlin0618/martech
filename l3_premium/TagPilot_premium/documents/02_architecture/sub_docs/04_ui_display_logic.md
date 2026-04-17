# Part 4: UI Components & Display Logic

**Document Version**: v1.0
**Created**: 2025-11-06
**For**: logic_v20251106.md

---

## 1. Common UI Patterns

### 1.1 ValueBox Pattern (bs4Dash)

**Purpose**: Display single numeric metrics prominently

**Example from Customer Base Value Module** (Lines 432-454):

```r
output$newbie_aov_box <- renderbs4ValueBox({
  req(values$processed_data)

  # Calculate newbie AOV
  newbie_avg <- values$processed_data %>%
    filter(customer_dynamics == "newbie") %>%
    pull(m_value) %>%
    mean(na.rm = TRUE)

  # Format with thousand separator
  formatted_value <- format(round(newbie_avg, 0), big.mark = ",")

  bs4ValueBox(
    value = paste0("$", formatted_value),
    subtitle = "新客平均客單價",
    icon = icon("user-plus"),
    color = "success",
    width = 6
  )
})
```

**Display**:
```
┌─────────────────────────┐
│  👤                      │
│  $1,234                 │
│  新客平均客單價           │
└─────────────────────────┘
```

### 1.2 Plotly Chart Pattern

**Purpose**: Interactive visualizations with hover tooltips

**Example: RFM Heatmap** (module_customer_value_analysis.R, Lines 522-605):

```r
output$rfm_heatmap <- renderPlotly({
  req(values$processed_data)

  # Filter for customers with RFM scores
  plot_data <- values$processed_data %>%
    filter(!is.na(tag_012_rfm_score)) %>%
    arrange(desc(tag_012_rfm_score))  # Sort by score

  # Create bubble plot
  plot_ly(
    data = plot_data,
    x = ~tag_011_rfm_m,              # X-axis: Monetary value
    y = ~tag_010_rfm_f,              # Y-axis: Frequency (times)
    size = ~tag_009_rfm_r,           # Bubble size: Recency
    color = ~tag_013_value_segment,  # Color: Value segment
    colors = c("低" = "#dc3545", "中" = "#ffc107", "高" = "#28a745"),
    text = ~paste0(
      "Customer: ", customer_id, "<br>",
      "M值（購買金額）: $", format(round(tag_011_rfm_m, 0), big.mark = ","), "<br>",
      "F值（頻率）: ", tag_010_rfm_f, " 次<br>",
      "R值（新近度）: ", tag_009_rfm_r, " 天<br>",
      "RFM總分: ", tag_012_rfm_score
    ),
    hoverinfo = "text",
    type = "scatter",
    mode = "markers"
  ) %>%
    layout(
      xaxis = list(title = "購買金額 (M)"),
      yaxis = list(title = "頻率 (F) - 次"),
      title = "",
      hovermode = "closest"
    )
})
```

**Display Features**:
- X-axis: M value (monetary)
- Y-axis: F value (frequency)
- Bubble size: R value (recency)
- Color: Value segment (低/中/高)
- Hover tooltip: Shows all RFM details

### 1.3 DataTable Pattern (DT)

**Purpose**: Display tabular data with sorting/filtering

**Example: Customer Table** (module_customer_value_analysis.R, Lines 609-678):

```r
output$customer_table <- renderDT({
  req(values$processed_data)

  # Select columns for display
  display_data <- values$processed_data %>%
    filter(!is.na(tag_012_rfm_score)) %>%
    arrange(desc(tag_012_rfm_score)) %>%  # Sort by RFM score
    select(
      `客戶ID` = customer_id,
      `R值（天）` = tag_009_rfm_r,
      `F值（次）` = tag_010_rfm_f,
      `M值（元）` = tag_011_rfm_m,
      `RFM總分` = tag_012_rfm_score,
      `價值分群` = tag_013_value_segment
    ) %>%
    head(100)  # Show top 100

  # Format M value with thousand separator
  display_data <- display_data %>%
    mutate(
      `M值（元）` = format(round(`M值（元）`, 0), big.mark = ",")
    )

  # Render DataTable
  datatable(
    display_data,
    options = list(
      pageLength = 10,
      scrollX = TRUE,
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel')
    ),
    rownames = FALSE,
    class = "table table-striped table-hover"
  )
})
```

**Display Features**:
- Pagination (10 rows per page)
- Horizontal scrolling
- Column sorting
- Export buttons (copy/CSV/Excel)
- Striped rows for readability

---

## 2. Module-Specific UI Logic

### 2.1 DNA Module: Nine-Grid Display

**File**: `modules/module_dna_multi_premium_v2.R`
**Lines**: 673-850

#### Grid Card Generation Function

```r
generate_grid_card <- function(grid_pos, title, data, selected_dynamics) {
  # Extract position components
  value_char <- substr(grid_pos, 1, 1)  # A, B, or C
  activity_num <- substr(grid_pos, 2, 2)  # 1, 2, or 3

  value_level <- switch(value_char,
    "A" = "高",
    "B" = "中",
    "C" = "低"
  )

  activity_level <- switch(activity_num,
    "1" = "高",
    "2" = "中",
    "3" = "低"
  )

  # Filter customers in this grid cell
  cell_customers <- data %>%
    filter(value_level == !!value_level & activity_level == !!activity_level)

  # Count customers
  customer_count <- nrow(cell_customers)

  # Calculate averages
  avg_m <- if (customer_count > 0) {
    mean(cell_customers$m_value, na.rm = TRUE)
  } else {
    0
  }

  avg_f <- if (customer_count > 0) {
    mean(cell_customers$f_value, na.rm = TRUE)
  } else {
    0
  }

  # Get strategy for this position
  strategy_key <- paste0(grid_pos, substr(selected_dynamics, 1, 1))  # e.g., "A1N", "B2C"
  strategy <- get_strategy(strategy_key)

  # Determine color based on value level
  color_class <- switch(value_char,
    "A" = "success",   # Green for high value
    "B" = "warning",   # Yellow for mid value
    "C" = "danger"     # Red for low value
  )

  # Generate card HTML
  bs4Card(
    title = title,
    status = color_class,
    solidHeader = TRUE,
    width = 12,
    HTML(paste0(
      '<div style="text-align: center; padding: 15px;">',
      '<h3>', strategy$icon, ' ', strategy$title, '</h3>',
      '<div style="font-size: 28px; font-weight: bold; margin: 20px 0;">',
      customer_count, ' 位客戶',
      '</div>',
      '<div style="color: #666; margin: 15px 0;">',
      '平均M值: ', format(round(avg_m, 0), big.mark = ","), ' 元<br>',
      '平均F值: ', round(avg_f, 1), ' 次',
      '</div>',
      '<div style="background: #f8f9fa; padding: 10px; border-radius: 5px; margin: 15px 0;">',
      '<strong>建議策略：</strong><br>', strategy$action,
      '</div>',
      '<div style="color: #888; font-size: 12px;">',
      'KPI: ', strategy$kpi,
      '</div>',
      '</div>'
    ))
  )
}
```

#### Strategy Database (45 Strategies)

**Function**: `get_strategy()`
**Location**: Lines 1031-1250+

**Strategy Key Format**: `{Grid Position}{Lifecycle Initial}`
- Grid Position: A1-C3 (9 positions)
- Lifecycle: N (newbie), C (active), D (sleepy), H (half-sleepy), S (dormant)

**Total**: 9 positions × 5 lifecycles = 45 strategies

**Example Strategies**:

```r
strategies <- list(
  # A1C = High Value × High Activity × Active Customer
  "A1C" = list(
    title = "王者引擎-C",
    action = "VIP 社群 + 新品搶先權",
    icon = "crown",
    kpi = "高V 高A 主力"
  ),

  # B2D = Mid Value × Mid Activity × Sleepy Customer
  "B2D" = list(
    title = "成長常規-D",
    action = "品類換血建議 + 搭售優惠",
    icon = "chart-line",
    kpi = "中V 中A 瞌睡"
  ),

  # C3S = Low Value × Low Activity × Dormant Customer
  "C3S" = list(
    title = "清倉邊緣-S",
    action = "名單除重/不再接觸",
    icon = "trash",
    kpi = "低V 低A 沉睡"
  )
)
```

#### Dynamic Grid Layout

```r
output$grid_matrix <- renderUI({
  req(values$dna_results, input$selected_dynamics)

  # Filter data by selected lifecycle
  filtered_data <- values$dna_results$data_by_customer %>%
    filter(customer_dynamics == input$selected_dynamics)

  # Chinese lifecycle name
  lifecycle_label <- switch(input$selected_dynamics,
    "newbie" = "新客",
    "active" = "主力客",
    "sleepy" = "瞌睡客",
    "half_sleepy" = "半睡客",
    "dormant" = "沉睡客"
  )

  div(
    h4(paste("生命週期階段:", lifecycle_label),
       style = "text-align: center; margin: 20px 0;"),

    # High Value Row
    fluidRow(
      column(4, generate_grid_card("A1", "高價值 × 高活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("A2", "高價值 × 中活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("A3", "高價值 × 低活躍", filtered_data, input$selected_dynamics))
    ),

    # Mid Value Row
    fluidRow(
      column(4, generate_grid_card("B1", "中價值 × 高活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("B2", "中價值 × 中活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("B3", "中價值 × 低活躍", filtered_data, input$selected_dynamics))
    ),

    # Low Value Row
    fluidRow(
      column(4, generate_grid_card("C1", "低價值 × 高活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("C2", "低價值 × 中活躍", filtered_data, input$selected_dynamics)),
      column(4, generate_grid_card("C3", "低價值 × 低活躍", filtered_data, input$selected_dynamics))
    )
  )
})
```

**User Interaction Flow**:
1. User selects lifecycle stage (新客/主力客/etc) via radio buttons
2. Grid updates to show only customers in that lifecycle
3. Each of 9 cells shows:
   - Customer count
   - Average M and F values
   - Tailored marketing strategy
   - KPI target

### 2.2 Customer Status Module: Churn Distribution

**File**: `modules/module_customer_status.R`
**Lines**: 289-371

#### Lifecycle Distribution Bar Chart

```r
output$lifecycle_dist <- renderPlotly({
  req(values$processed_data)

  # Count customers by lifecycle
  lifecycle_counts <- values$processed_data %>%
    count(tag_017_customer_dynamics) %>%
    mutate(
      percentage = round(100 * n / sum(n), 1)
    )

  # Chinese labels with counts
  lifecycle_counts <- lifecycle_counts %>%
    mutate(
      label = paste0(tag_017_customer_dynamics, "\n", n, " 人 (", percentage, "%)")
    )

  # Color mapping
  colors <- c(
    "新客" = "#28a745",      # Green
    "主力客" = "#007bff",    # Blue
    "睡眠客" = "#ffc107",    # Yellow
    "半睡客" = "#fd7e14",    # Orange
    "沉睡客" = "#dc3545"     # Red
  )

  plot_ly(
    data = lifecycle_counts,
    x = ~tag_017_customer_dynamics,
    y = ~n,
    type = "bar",
    marker = list(
      color = ~colors[tag_017_customer_dynamics]
    ),
    text = ~label,
    textposition = "outside",
    hoverinfo = "text",
    hovertext = ~paste0(
      tag_017_customer_dynamics, "<br>",
      "客戶數: ", n, "<br>",
      "佔比: ", percentage, "%"
    )
  ) %>%
    layout(
      xaxis = list(title = "生命週期階段"),
      yaxis = list(title = "客戶數"),
      showlegend = FALSE
    )
})
```

**Display**:
```
客戶數
 │
 │     ████
 │     ████  ██
 │ ██  ████  ██  ██
 │ ██  ████  ██  ██  ██
 └─────────────────────────
   新客 主力 睡眠 半睡 沉睡
```

#### Churn Risk Pie Chart

```r
output$churn_risk_pie <- renderPlotly({
  req(values$processed_data)

  # Count by churn risk level
  risk_counts <- values$processed_data %>%
    filter(!is.na(tag_018_churn_risk)) %>%
    count(tag_018_churn_risk) %>%
    mutate(percentage = round(100 * n / sum(n), 1))

  # Color mapping
  risk_colors <- c(
    "高風險" = "#dc3545",
    "中風險" = "#ffc107",
    "低風險" = "#28a745",
    "新客（無法評估）" = "#6c757d"
  )

  plot_ly(
    data = risk_counts,
    labels = ~tag_018_churn_risk,
    values = ~n,
    type = "pie",
    marker = list(colors = ~risk_colors[tag_018_churn_risk]),
    textinfo = "label+percent",
    hoverinfo = "text",
    hovertext = ~paste0(
      tag_018_churn_risk, "<br>",
      "客戶數: ", n, " (", percentage, "%)"
    )
  ) %>%
    layout(
      title = "",
      showlegend = TRUE
    )
})
```

#### Days to Churn Histogram

```r
output$days_to_churn_hist <- renderPlotly({
  req(values$processed_data)

  # Filter out NA values
  churn_data <- values$processed_data %>%
    filter(!is.na(tag_019_days_to_churn))

  plot_ly(
    x = churn_data$tag_019_days_to_churn,
    type = "histogram",
    marker = list(color = "#dc3545"),
    nbinsx = 30
  ) %>%
    layout(
      xaxis = list(title = "預測多少天後"),
      yaxis = list(title = "會流失多少客戶數"),
      title = ""
    )
})
```

**Display Logic**:
- X-axis: Days until predicted churn (tag_019)
- Y-axis: Count of customers
- Bins: 30 bins for smooth distribution
- Color: Red (#dc3545) to emphasize urgency

---

## 3. Number Formatting & Display

### 3.1 Currency Formatting

**Pattern**: Add thousand separators and currency symbol

**Example**:
```r
# Format monetary values
formatted_amount <- format(round(amount, 0), big.mark = ",")
display_text <- paste0("$", formatted_amount)

# Examples:
# 1234.56 → "$1,235"
# 1000000 → "$1,000,000"
```

**Usage in ValueBox**:
```r
bs4ValueBox(
  value = paste0("$", format(round(avg_m, 0), big.mark = ",")),
  subtitle = "平均消費金額",
  icon = icon("dollar-sign"),
  color = "success"
)
```

### 3.2 Percentage Formatting

**Pattern**: Round to 1 decimal place and add % symbol

**Example**:
```r
# Calculate percentage
percentage <- 100 * count / total

# Format
formatted_pct <- paste0(round(percentage, 1), "%")

# Examples:
# 0.2567 → "25.7%"
# 0.8 → "80.0%"
```

### 3.3 Large Number Abbreviation

**Pattern**: Use K, M, B suffixes for large numbers

**Example**:
```r
format_large_number <- function(num) {
  if (num >= 1e9) {
    paste0(round(num / 1e9, 1), "B")
  } else if (num >= 1e6) {
    paste0(round(num / 1e6, 1), "M")
  } else if (num >= 1e3) {
    paste0(round(num / 1e3, 1), "K")
  } else {
    as.character(round(num, 0))
  }
}

# Examples:
# 1234 → "1.2K"
# 1234567 → "1.2M"
# 1234567890 → "1.2B"
```

### 3.4 Date Formatting

**Pattern**: Display in readable Chinese format

**Example**:
```r
# Format date
formatted_date <- format(date_obj, "%Y年%m月%d日")

# Examples:
# 2024-12-31 → "2024年12月31日"

# For relative dates
days_diff <- as.numeric(difftime(target_date, Sys.Date(), units = "days"))
if (days_diff > 0) {
  label <- paste0(round(days_diff, 0), " 天後")
} else {
  label <- paste0(abs(round(days_diff, 0)), " 天前")
}
```

---

## 4. Conditional Display Logic

### 4.1 ConditionalPanel Pattern

**Purpose**: Show/hide UI elements based on reactive conditions

**Example: Show Results After Analysis**

```r
# In UI
conditionalPanel(
  condition = paste0("output['", ns("show_results"), "'] == true"),
  # ... results UI ...
)

# In Server
output$show_results <- reactive({
  !is.null(values$dna_results)
})
outputOptions(output, "show_results", suspendWhenHidden = FALSE)
```

**Example: Show Warning for Low Data Quality**

```r
# In UI
conditionalPanel(
  condition = paste0("output['", ns("has_quality_issues"), "'] == true"),
  wellPanel(
    style = "background-color: #fff3cd;",
    uiOutput(ns("quality_warnings"))
  )
)

# In Server
output$has_quality_issues <- reactive({
  length(values$data_quality_issues) > 0
})

output$quality_warnings <- renderUI({
  issues <- values$data_quality_issues

  warnings_html <- lapply(issues, function(issue) {
    icon_type <- if (issue$type == "warning") "exclamation-triangle" else "info-circle"
    color <- if (issue$type == "warning") "#856404" else "#004085"

    tags$div(
      style = paste0("margin-bottom: 10px; color: ", color, ";"),
      tags$strong(icon(icon_type), " ", issue$title),
      tags$p(issue$message, style = "margin-top: 5px;")
    )
  })

  do.call(tagList, warnings_html)
})
```

### 4.2 Dynamic UI Generation

**Purpose**: Generate UI elements based on data

**Example: Dynamic Radio Buttons for Lifecycles**

```r
output$customer_dynamics_selector <- renderUI({
  req(values$dna_results)

  # Count customers in each lifecycle
  dynamics_counts <- values$dna_results$data_by_customer %>%
    count(customer_dynamics) %>%
    arrange(desc(n))

  # Generate choices with counts
  choices <- setNames(
    dynamics_counts$customer_dynamics,
    paste0(
      dynamics_counts$customer_dynamics, " (",
      dynamics_counts$n, " 人)"
    )
  )

  radioButtons(
    ns("selected_dynamics"),
    label = "選擇顧客動態：",
    choices = choices,
    selected = "active",
    inline = TRUE
  )
})
```

**Output**:
```
選擇顧客動態：
⚪ newbie (1234 人)  ⚪ active (5678 人)  ⚪ sleepy (910 人) ...
```

---

## 5. Download Handlers

### 5.1 CSV Download

**Purpose**: Export full dataset with all tags

**Example from RFM Module**:

```r
output$download_data <- downloadHandler(
  filename = function() {
    paste0("RFM_analysis_", Sys.Date(), ".csv")
  },
  content = function(file) {
    # Prepare data
    export_data <- values$processed_data %>%
      select(
        customer_id,
        tag_009_rfm_r,
        tag_010_rfm_f,
        tag_011_rfm_m,
        tag_012_rfm_score,
        tag_013_value_segment,
        customer_dynamics,
        ni,
        ipt,
        total_spent
      )

    # Write CSV with UTF-8 BOM (for Excel compatibility)
    write.csv(
      export_data,
      file,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )

    # Add BOM
    con <- file(file, "r+b")
    content <- readBin(con, "raw", file.info(file)$size)
    seek(con, 0)
    writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), content), con)
    close(con)
  }
)
```

**Features**:
- Dynamic filename with current date
- UTF-8 BOM for Excel Chinese character support
- Selected columns for clarity

---

**End of Part 4**
