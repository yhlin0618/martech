# TagPilot Premium - Application Architecture Documentation

**Documentation Date**: 2025-10-25
**Application Version**: v18 (bs4Dash)
**Tier**: L3 Premium
**Framework**: R Shiny + bs4Dash
**Last Updated**: 2025-10-25

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Application Overview](#application-overview)
3. [Architecture & Design Patterns](#architecture--design-patterns)
4. [System Initialization](#system-initialization)
5. [Module Structure](#module-structure)
6. [Data Flow Architecture](#data-flow-architecture)
7. [Analysis Logic Architecture](#analysis-logic-architecture)
8. [User Interface Structure](#user-interface-structure)
9. [Server-Side Implementation](#server-side-implementation)
10. [Database Architecture](#database-architecture)
11. [Reactive State Management](#reactive-state-management)
12. [Technical Stack](#technical-stack)
13. [Principle Compliance](#principle-compliance)
14. [Deployment Configuration](#deployment-configuration)

---

## Executive Summary

TagPilot Premium is a **precision marketing platform** that implements the **ROS Framework** (Risk-Opportunity-Stability) for customer lifecycle analysis. Built on the bs4Dash framework, it provides a comprehensive T-Series Insight analysis system for customer DNA profiling and lifecycle management.

### Key Capabilities:
- Multi-file data upload and processing
- T-Series customer lifecycle analysis
- ROS Framework implementation (Risk-Opportunity-Stability)
- IPT (Inter-Purchase Time) analysis
- Customer DNA profiling with visual analytics
- Role-based authentication system
- Real-time database connection monitoring

### ROS Framework Mapping:
- **Risk (R)**: Based on `nrec_prob` (churn probability)
- **Opportunity (O)**: Based on `ipt_mean` (Inter-Purchase Time)
- **Stability (S)**: Based on `cri` (Customer Regularity Index)

---

## Application Overview

### Application Identity
- **Name**: TagPilot Premium 精準行銷平台
- **Primary Purpose**: Customer lifecycle analysis and precision marketing
- **Target Users**: Marketing teams, data analysts, business strategists
- **Deployment**: Posit Connect Cloud / ShinyApps.io

### Core Features
1. **Secure Authentication**: User login with role-based access control
2. **Data Upload**: Multi-file CSV upload support (200MB limit)
3. **DNA Analysis**: Customer DNA profiling with T-Series insights
4. **Lifecycle Tracking**: Customer journey and lifecycle stage analysis
5. **Visual Analytics**: Interactive dashboards with Plotly visualizations
6. **Database Integration**: Real-time connection to DuckDB/PostgreSQL

---

## Architecture & Design Patterns

### Architectural Principles Applied

The application strictly follows the **MP/P/R framework** (257+ documented principles):

#### Meta-Principles (MP)
- **MP016 (Modularity)**: Clear separation of concerns across modules
- **MP048 (Universal Initialization)**: Explicit initialization before use
- **MP052 (Unidirectional Data Flow)**: Database → Server → UI flow
- **MP053 (Feedback Loop)**: Complete user interaction cycles
- **MP054 (UI-Server Correspondence)**: Every UI element has server purpose

#### Principles (P)
- **P001 (Script Separation)**: Clear separation between orchestration and functionality
- **P007 (Bottom-Up Construction)**: Components built before assembly

#### Rules (R)
- **R009 (UI-Server-Defaults Triple)**: Modules have UI, Server, and Defaults
- **R076 (Module Data Connection)**: Modules receive connections, not pre-filtered data
- **R092 (Universal DBI Approach)**: Consistent database interface pattern

### Design Pattern: Authentication-Gated Architecture

```
┌─────────────────────────────────────────────────┐
│  Conditional UI (Login State Detection)        │
├─────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌──────────────────┐  │
│  │  Login Page     │ OR │  Main App UI     │  │
│  │  (Gradient BG)  │    │  (bs4DashPage)   │  │
│  └─────────────────┘    └──────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Modular Component Architecture

```
Global Scripts (Shared Library)
    ↓
┌───────────────────────────────────────────┐
│  Database Connection (get_con)            │
├───────────────────────────────────────────┤
│  Login Module → User Authentication       │
├───────────────────────────────────────────┤
│  Upload Module → Data Ingestion          │
├───────────────────────────────────────────┤
│  DNA Multi Premium → T-Series Analysis    │
└───────────────────────────────────────────┘
```

---

## System Initialization

### Initialization Sequence

**File Location**: `/app.R` lines 12-21

```r
# 1. Load package management
source("config/packages.R")

# 2. Load configuration settings
source("config/config.R")

# 3. Initialize package environment
initialize_packages()

# 4. Validate configuration
validate_config()
```

### Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `config/packages.R` | Package dependency management | Project root |
| `config/config.R` | Application configuration | Project root |

### Package Dependencies

The application uses a **configuration-driven package management system** (R004 principle):

**Core Packages**:
- `shiny` - Reactive web framework
- `bs4Dash` - Dashboard framework (AdminLTE 3.0)
- `shinyjs` - JavaScript integration
- `DBI` - Database interface
- `dplyr` - Data manipulation
- `plotly` - Interactive visualizations
- `DT` - Interactive tables

---

## Module Structure

### Module Hierarchy

```
app.R
├── database/db_connection.R          # Database connectivity
├── utils/data_access.R               # Data access with tbl2 integration
├── modules/module_wo_b.R             # Main analysis module
├── modules/module_upload.R           # Upload functionality
├── modules/module_dna.R              # Basic DNA analysis
├── modules/module_dna_multi_premium.R # Premium T-Series analysis
└── scripts/global_scripts/10_rshinyapp_components/login/login_module.R
```

### Module Details

#### 1. Database Connection Module
**File**: `database/db_connection.R`
**Purpose**: Establish and manage database connections
**Pattern**: R092 (Universal DBI Approach)
**Functions**:
- `get_con()` - Get database connection
- `get_db_info()` - Get connection metadata

#### 2. Data Access Module
**File**: `utils/data_access.R`
**Purpose**: Unified data access interface
**Pattern**: R091 (Universal Data Access Pattern), R116 (tbl2 Enhanced Access)
**Features**:
- Abstract connection types
- Safe NULL/NA handling
- Consistent query interface

#### 3. WO_B Module
**File**: `modules/module_wo_b.R`
**Purpose**: Main analysis functionality
**Scope**: Core analytical operations

#### 4. Login Module
**File**: `scripts/global_scripts/10_rshinyapp_components/login/login_module.R`
**Purpose**: User authentication
**Pattern**: R009 (UI-Server-Defaults Triple)
**Features**:
- Parameterized login interface
- Database-backed authentication
- Session management
- Role-based access

**Usage in app.R**:
```r
# UI (lines 347-353)
loginModuleUI("login1",
              app_title = "TagPilot Premium",
              app_icon = "assets/icons/app_icon.png",
              contacts_md = "md/contacts.md",
              background_color = "transparent",
              primary_color = "#17a2b8")

# Server (line 381)
login_mod <- loginModuleServer("login1", con_global)
```

#### 5. Upload Module
**File**: `modules/module_upload.R`
**Purpose**: Multi-file data upload and processing
**Pattern**: R009 (UI-Server-Defaults Triple)
**Features**:
- Multiple CSV file support
- 200MB file size limit
- Database integration
- Progress tracking

**Usage in app.R**:
```r
# UI (line 190)
uploadModuleUI("upload1")

# Server (line 387)
upload_mod <- uploadModuleServer("upload1", con_global, user_info)

# Data binding (line 389)
sales_data(upload_mod$dna_data())
```

#### 6. DNA Multi Premium Module
**File**: `modules/module_dna_multi_premium.R`
**Purpose**: T-Series Insight customer lifecycle analysis
**Pattern**: R009 (UI-Server-Defaults Triple)
**Features**:
- Customer DNA profiling
- IPT (Inter-Purchase Time) analysis
- T-Series lifecycle tracking
- ROS Framework metrics
- Interactive visualizations

**Usage in app.R**:
```r
# UI (line 207)
dnaMultiPremiumModuleUI("dna_multi1")

# Server (line 400)
dna_mod <- dnaMultiPremiumModuleServer("dna_multi1",
                                       con_global,
                                       user_info,
                                       upload_mod$dna_data)
```

---

## Data Flow Architecture

### Primary Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Database (con_global)                                      │
│  ↓                                                           │
│  get_con() → DuckDB/PostgreSQL Connection                   │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Login Module                                               │
│  ↓                                                           │
│  Authentication → user_info (reactiveVal)                   │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Upload Module                                              │
│  ↓                                                           │
│  File Upload → Database → dna_data (reactive)               │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  DNA Multi Premium Module                                   │
│  ↓                                                           │
│  T-Series Analysis → Visualizations & Insights              │
└─────────────────────────────────────────────────────────────┘
```

### Module Data Connection Pattern (R076)

**Principle**: Modules receive **connections**, not pre-filtered data

```r
# Server initialization (lines 367-369)
con_global <- get_con()
db_info <- get_db_info(con_global)
onStop(function() dbDisconnect(con_global))

# Module receives connection
upload_mod <- uploadModuleServer("upload1", con_global, user_info)
dna_mod <- dnaMultiPremiumModuleServer("dna_multi1",
                                       con_global,      # Connection passed
                                       user_info,
                                       upload_mod$dna_data)
```

### Reactive Value Flow

```r
# Global reactive values (lines 372-374)
user_info    <- reactiveVal(NULL)   # Login state
sales_data   <- reactiveVal(NULL)   # Upload data

# Module → Reactive binding (lines 382-390)
observe({ user_info(login_mod$user_info()) })
observe({ sales_data(upload_mod$dna_data()) })
```

### Auto-Navigation Pattern

**Feature**: Automatic tab switching after successful upload

```r
# lines 393-397
observeEvent(upload_mod$proceed_step(), {
  if (!is.null(upload_mod$proceed_step()) &&
      upload_mod$proceed_step() > 0 &&
      !is.null(upload_mod$dna_data()) &&
      nrow(upload_mod$dna_data()) > 0) {
    updateTabItems(session, "sidebar_menu", "dna_analysis")
  }
}, ignoreInit = TRUE)
```

---

## Analysis Logic Architecture

This section documents the complete data processing and analysis logic across all 7 modules in the TagPilot Premium system.

### Three-Dimensional Customer Segmentation Framework

**Core Concept**: The system uses a **3D customer segmentation model** that combines:
- **Value Level** (高/中/低) - Based on monetary value
- **Activity Level** (高/中/低) - Based on recency and engagement
- **Lifecycle Stage** (newbie/active/sleepy/half_sleepy/dormant/unknown) - Based on time patterns

This creates up to **45 unique customer segments** (3 × 3 × 5 = 45), each requiring specific marketing strategies.

### Module Analysis Flow

```
Module 1: DNA Analysis (Core Layer)
    ↓ Provides: R/F/M/IPT values, lifecycle stages, value/activity levels
Module 2: Customer Base Value
    ↓ Uses: DNA results → Basic value tags
Module 3: RFM Analysis
    ↓ Uses: DNA results → 1-5 scores per dimension
Module 4: Customer Status
    ↓ Uses: DNA results → Lifecycle tags + churn predictions
Module 5: R/S/V Matrix
    ↓ Uses: DNA results → Risk-Stability-Value 3D analysis
Module 6: Lifecycle Prediction
    ↓ Uses: DNA results → Future behavior predictions
Module 7: Advanced Analytics
    ↓ Uses: All above → Cohort/Trend analysis (future)
```

---

### Module 1: DNA Analysis (module_dna_multi_premium.R)

**Purpose**: Core calculation layer that provides all base metrics for downstream modules.

**File**: `modules/module_dna_multi_premium.R`

#### Input Requirements

**Required Fields**:
```r
c("customer_id", "transaction_date", "transaction_amount")
```

**Field Validation**:
- `customer_id`: Non-null string
- `transaction_date`: Valid date format (YYYY-MM-DD)
- `transaction_amount`: Numeric > 0

#### Core Calculations

##### 1. Time-Based Metrics

**Analysis Date**: Last transaction date in dataset
```r
analysis_date <- max(df$transaction_date, na.rm = TRUE)
```

**Recency (r_value)**:
```r
r_value = as.numeric(analysis_date - last_txn_date)
```
- Unit: Days since last transaction
- Lower = More recent customer

**Customer Age**:
```r
customer_age_days = as.numeric(analysis_date - first_txn_date)
```

##### 2. Frequency Metrics

**Transaction Count (ni)**:
```r
ni = n()  # Total number of transactions per customer
```

**Average Inter-Purchase Time (avg_ipt)**:
```r
avg_ipt = if(ni > 1) {
  customer_age_days / (ni - 1)
} else {
  NA_real_
}
```
- Only calculated when ni > 1
- Represents average days between purchases

##### 3. Monetary Metrics

**Total Revenue (m_value)**:
```r
m_value = sum(transaction_amount, na.rm = TRUE)
```

**Average Order Value (aov)**:
```r
aov = mean(transaction_amount, na.rm = TRUE)
```

**Historical Value**:
```r
historical_value = m_value  # Same as total revenue
```

#### Lifecycle Stage Classification

**Logic** (module_dna_multi_premium.R:388-396):

```r
lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 ~ "newbie",              # Single transaction only
  r_value <= 7 ~ "active",          # Within 1 week
  r_value <= 14 ~ "sleepy",         # Within 2 weeks
  r_value <= 21 ~ "half_sleepy",    # Within 3 weeks
  TRUE ~ "dormant"                  # Over 3 weeks
)
```

**Stages Defined**:
- **unknown**: No recency data (data quality issue)
- **newbie**: ni = 1 (first-time customer, no repeat purchase)
- **active**: Last purchase within 7 days
- **sleepy**: Last purchase 8-14 days ago
- **half_sleepy**: Last purchase 15-21 days ago
- **dormant**: Last purchase over 21 days ago

**Critical Decision**: Newbie definition simplified to `ni == 1` only (no time restriction), because:
- If customer only purchased once, they can't be evaluated for activity patterns
- Time-based restrictions (e.g., customer_age_days <= avg_ipt) were removing valid newbies

#### Value Level Classification

**Logic** (percentile-based for dynamic adaptation):

```r
# Calculate percentiles
value_percentile_20 <- quantile(m_value, 0.2, na.rm = TRUE)
value_percentile_80 <- quantile(m_value, 0.8, na.rm = TRUE)

# Classify
value_level = case_when(
  m_value >= value_percentile_80 ~ "高",
  m_value >= value_percentile_20 ~ "中",
  TRUE ~ "低"
)
```

**Distribution**:
- 高 (High): Top 20% of customers by revenue
- 中 (Medium): Middle 60%
- 低 (Low): Bottom 20%

#### Activity Level Classification

**Statistical Reliability Threshold**: `ni >= 4`

**Rationale**:
- Need sufficient data points to calculate reliable activity metrics
- With ni < 4, recency-based calculations become unreliable
- Industry standard for statistical significance in behavioral analysis

**Logic**:

```r
# Only calculate for customers with ni >= 4
activity_level = if_else(
  ni >= 4,
  case_when(
    r_value <= activity_percentile_20 ~ "高",  # Most recent
    r_value <= activity_percentile_80 ~ "中",
    TRUE ~ "低"                                 # Least recent
  ),
  NA_character_  # Not applicable for ni < 4
)
```

**Distribution** (among customers with ni >= 4):
- 高 (High): Top 20% most recent customers
- 中 (Medium): Middle 60%
- 低 (Low): Bottom 20% least recent

#### Grid Combination Logic

**Nine-Grid Framework** (Value × Activity):

```
        Activity High (活躍)  Activity Mid (溫和)  Activity Low (冷淡)
Value ┌─────────────────────┬─────────────────────┬─────────────────────┐
High  │  A1: 王者級客戶      │  A2: 王者休眠        │  A3: 王者流失        │
      ├─────────────────────┼─────────────────────┼─────────────────────┤
Mid   │  B1: 成長潛力        │  B2: 成長停滯        │  B3: 成長衰退        │
      ├─────────────────────┼─────────────────────┼─────────────────────┤
Low   │  C1: 清倉機會        │  C2: 清倉觀望        │  C3: 清倉邊緣        │
      └─────────────────────┴─────────────────────┴─────────────────────┘
```

**Grid Assignment** (module_dna_multi_premium.R:398-414):

```r
grid_position = case_when(
  is.na(activity_level) ~ "無",  # ni < 4
  value_level == "高" & activity_level == "高" ~ "A1",
  value_level == "高" & activity_level == "中" ~ "A2",
  value_level == "高" & activity_level == "低" ~ "A3",
  value_level == "中" & activity_level == "高" ~ "B1",
  value_level == "中" & activity_level == "中" ~ "B2",
  value_level == "中" & activity_level == "低" ~ "B3",
  value_level == "低" & activity_level == "高" ~ "C1",
  value_level == "低" & activity_level == "中" ~ "C2",
  value_level == "低" & activity_level == "低" ~ "C3",
  TRUE ~ "其他"
)
```

**Special Case**: Customers with `ni < 4` get `grid_position = "無"` (not enough data for activity assessment).

#### Newbie Special Handling

**Problem**: Newbies (ni = 1) can't have activity level calculated (requires ni >= 4), so they can't fit in the 9-grid framework.

**Solution**: Display newbie-specific strategies instead of grid (module_dna_multi_premium.R:783-913):

**Newbie Value-Based Segmentation**:

```
A3N: 王者休眠-N (高V 低(無)A 新客)
- Definition: High value first purchase, no repeat interaction
- Strategy: 專屬客服問候 within 48h of first purchase

B3N: 成長停滯-N (中V 低(無)A 新客)
- Definition: Medium value first purchase
- Strategy: 首購加碼券 (limited to 72h after first purchase)

C3N: 清倉邊緣-N (低V 低(無)A 新客)
- Definition: Low value first purchase
- Strategy: 取消後續推播，只留月度新品 EDM
```

**Display Logic** (module_dna_multi_premium.R:783-820):

```r
# When lifecycle selector is "newbie"
if (current_stage == "newbie") {
  # Count newbies by value level
  newbie_by_value <- df %>%
    filter(lifecycle_stage == "newbie") %>%
    group_by(value_level) %>%
    summarise(count = n(), avg_value = mean(m_value), .groups = "drop")

  # Display 3 strategy cards instead of 9-grid
  return(
    fluidRow(
      column(4, A3N_card),
      column(4, B3N_card),
      column(4, C3N_card)
    )
  )
}
```

#### Customer Tag Generation

**Tags Created** (module_dna_multi_premium.R:415-442):

```r
# Basic tags
tag_001_total_transactions = paste0("總交易次數 ", ni, " 次")
tag_002_last_transaction_date = format(last_txn_date, "%Y-%m-%d")
tag_003_recency_days = paste0("距今 ", r_value, " 天")
tag_004_customer_age = paste0("客戶年齡 ", customer_age_days, " 天")

# Value tags
tag_005_total_revenue = paste0("總營收 $", round(m_value, 2))
tag_006_aov = paste0("平均訂單 $", round(aov, 2))

# Time pattern tags
tag_007_avg_ipt = if_else(
  is.na(avg_ipt),
  "平均購買間隔 N/A",
  paste0("平均購買間隔 ", round(avg_ipt, 1), " 天")
)

# Classification tags
tag_008_value_level = paste0("價值層級: ", value_level)
tag_009_activity_level = if_else(
  is.na(activity_level),
  "活躍度: N/A (樣本數不足)",
  paste0("活躍度: ", activity_level)
)
tag_010_lifecycle_stage = paste0("生命週期: ", lifecycle_stage)
tag_011_grid_position = paste0("九宮格位置: ", grid_position)
```

#### Return Value

**Critical**: Module must return reactive data for downstream modules (module_dna_multi_premium.R:826-830):

```r
return(reactive({
  req(values$dna_results)
  values$dna_results$data_by_customer
}))
```

**Without this return statement**: Downstream modules fail with "shinysession missing" error.

---

### Module 2: Customer Base Value (module_customer_base_value.R)

**Purpose**: Analyze basic customer value metrics using IPT, historical value, and AOV.

**File**: `modules/module_customer_base_value.R`

#### Three Basic Value Tags

**Tag 012: IPT-Based Classification**

```r
tag_012_ipt_based_customer = case_when(
  is.na(avg_ipt) | ni == 1 ~ "單次客戶",
  avg_ipt <= 30 ~ "高頻客戶 (≤30天)",
  avg_ipt <= 90 ~ "中頻客戶 (30-90天)",
  TRUE ~ "低頻客戶 (>90天)"
)
```

**Logic**:
- Newbies (ni = 1): Automatically classified as "單次客戶"
- avg_ipt ≤ 30 days: High frequency (purchases at least monthly)
- avg_ipt 30-90 days: Medium frequency (quarterly)
- avg_ipt > 90 days: Low frequency (rare purchasers)

**Tag 013: Historical Value Classification**

```r
# Calculate percentiles
hist_p20 <- quantile(historical_value, 0.2, na.rm = TRUE)
hist_p80 <- quantile(historical_value, 0.8, na.rm = TRUE)

tag_013_historical_value_customer = case_when(
  historical_value >= hist_p80 ~ "高價值客戶 (Top 20%)",
  historical_value >= hist_p20 ~ "中價值客戶 (Mid 60%)",
  TRUE ~ "低價值客戶 (Bottom 20%)"
)
```

**Tag 014: AOV-Based Classification**

```r
# Calculate percentiles
aov_p20 <- quantile(aov, 0.2, na.rm = TRUE)
aov_p80 <- quantile(aov, 0.8, na.rm = TRUE)

tag_014_aov_based_customer = case_when(
  aov >= aov_p80 ~ "高單價客戶 (Top 20%)",
  aov >= aov_p20 ~ "中單價客戶 (Mid 60%)",
  TRUE ~ "低單價客戶 (Bottom 20%)"
)
```

#### Key Insights

**Metrics Displayed**:
- Total unique customers
- Average IPT across all customers
- Average historical value
- Average AOV

**Visualizations**:
1. **Distribution chart**: Count of customers in each tag category
2. **Value distribution**: Box plots showing value spread
3. **Data table**: Downloadable customer list with all 3 tags

---

### Module 3: RFM Analysis (module_rfm_analysis.R)

**Purpose**: Traditional RFM scoring with 1-5 scale per dimension.

**File**: `modules/module_rfm_analysis.R`

#### Statistical Reliability Filter

**Critical Threshold**: Only customers with `ni >= 4` are included in RFM analysis.

```r
# Filter for statistical reliability
df_rfm <- df %>% filter(ni >= 4)
```

**Rationale**:
- RFM analysis requires behavioral patterns
- ni < 4 doesn't provide enough data points
- Consistent with DNA module's activity threshold

#### Scoring Logic

**Recency Score (R)** - Lower days = Higher score:

```r
# Calculate quintiles (reversed for recency)
r_breaks <- quantile(r_value, probs = seq(0, 1, 0.2), na.rm = TRUE)

r_score = case_when(
  r_value <= r_breaks[2] ~ 5,  # Most recent
  r_value <= r_breaks[3] ~ 4,
  r_value <= r_breaks[4] ~ 3,
  r_value <= r_breaks[5] ~ 2,
  TRUE ~ 1                      # Least recent
)
```

**Frequency Score (F)** - Higher ni = Higher score:

```r
# Calculate quintiles
f_breaks <- quantile(ni, probs = seq(0, 1, 0.2), na.rm = TRUE)

f_score = case_when(
  ni >= f_breaks[5] ~ 5,  # Most frequent
  ni >= f_breaks[4] ~ 4,
  ni >= f_breaks[3] ~ 3,
  ni >= f_breaks[2] ~ 2,
  TRUE ~ 1                 # Least frequent
)
```

**Monetary Score (M)** - Higher value = Higher score:

```r
# Calculate quintiles
m_breaks <- quantile(m_value, probs = seq(0, 1, 0.2), na.rm = TRUE)

m_score = case_when(
  m_value >= m_breaks[5] ~ 5,  # Highest value
  m_value >= m_breaks[4] ~ 4,
  m_value >= m_breaks[3] ~ 3,
  m_value >= m_breaks[2] ~ 2,
  TRUE ~ 1                      # Lowest value
)
```

#### RFM Tag Generation

**Tag 015: R Score Tag**
```r
tag_015_recency_score = paste0("R=", r_score)
```

**Tag 016: F Score Tag**
```r
tag_016_frequency_score = paste0("F=", f_score)
```

**Tag 017: M Score Tag**
```r
tag_017_monetary_score = paste0("M=", m_score)
```

**Tag 018: Combined RFM Score**
```r
rfm_combined_score = r_score + f_score + m_score
tag_018_rfm_total_score = paste0("RFM總分=", rfm_combined_score)
```
- Range: 3-15
- Higher = Better customer (recent, frequent, high-value)

**Tag 019: RFM Segment**

```r
tag_019_rfm_segment = case_when(
  r_score >= 4 & f_score >= 4 & m_score >= 4 ~ "Champions (冠軍)",
  r_score >= 3 & f_score >= 3 & m_score >= 3 ~ "Loyal (忠誠)",
  r_score >= 4 & f_score <= 2 ~ "Promising (潛力)",
  r_score <= 2 & f_score >= 4 ~ "At Risk (流失風險)",
  r_score <= 2 & f_score <= 2 ~ "Lost (已流失)",
  TRUE ~ "Others (其他)"
)
```

**Segments Defined**:
- **Champions**: R≥4, F≥4, M≥4 (best customers)
- **Loyal**: R≥3, F≥3, M≥3 (solid performers)
- **Promising**: R≥4, F≤2 (recent but new)
- **At Risk**: R≤2, F≥4 (frequent but dormant)
- **Lost**: R≤2, F≤2 (both dormant and infrequent)
- **Others**: All remaining combinations

#### Key Metrics

```r
# Average scores
avg_r_score <- mean(df_rfm$r_score, na.rm = TRUE)
avg_f_score <- mean(df_rfm$f_score, na.rm = TRUE)
avg_m_score <- mean(df_rfm$m_score, na.rm = TRUE)

# Segment distribution
segment_counts <- df_rfm %>%
  group_by(tag_019_rfm_segment) %>%
  summarise(count = n(), .groups = "drop")
```

---

### Module 4: Customer Status (module_customer_status.R)

**Purpose**: Lifecycle status tags and churn risk prediction.

**File**: `modules/module_customer_status.R`

#### Three Status Tags

**Tag 020: Lifecycle Status Tag** (redundant with lifecycle_stage from DNA)

```r
tag_020_lifecycle_status = case_when(
  lifecycle_stage == "newbie" ~ "新客戶",
  lifecycle_stage == "active" ~ "活躍客戶",
  lifecycle_stage == "sleepy" ~ "沉睡客戶",
  lifecycle_stage == "half_sleepy" ~ "半沉睡客戶",
  lifecycle_stage == "dormant" ~ "流失客戶",
  TRUE ~ "未知狀態"
)
```

**Tag 021: Churn Risk Level**

```r
tag_021_churn_risk = case_when(
  lifecycle_stage %in% c("newbie", "active") ~ "低風險",
  lifecycle_stage == "sleepy" ~ "中風險",
  lifecycle_stage == "half_sleepy" ~ "高風險",
  lifecycle_stage == "dormant" ~ "已流失",
  TRUE ~ "未知"
)
```

**Logic**:
- **低風險**: Active customers (purchased within 7 days) + newbies
- **中風險**: Sleepy (8-14 days since last purchase)
- **高風險**: Half-sleepy (15-21 days)
- **已流失**: Dormant (>21 days)

**Tag 022: Days to Potential Churn**

```r
# Define churn threshold (e.g., 21 days)
churn_threshold <- 21

tag_022_days_to_churn = case_when(
  lifecycle_stage == "dormant" ~ "已流失",
  lifecycle_stage == "newbie" ~ "新客戶 (不適用)",
  is.na(r_value) ~ "N/A",
  TRUE ~ paste0(max(0, churn_threshold - r_value), " 天")
)
```

**Logic**:
- If r_value < 21: Show remaining days until churn threshold
- If r_value >= 21: Already churned
- Newbies: Not applicable (no repeat purchase pattern yet)

#### Key Insights

**Metrics**:
- Count by lifecycle status
- Count by churn risk level
- Average days to churn

**Visualizations**:
1. **Status distribution**: Bar chart of lifecycle stages
2. **Risk distribution**: Pie chart of churn risk levels
3. **Data table**: Customer list with all 3 status tags

---

### Module 5: R/S/V Matrix (module_rsv_matrix.R)

**Purpose**: Three-dimensional Risk-Stability-Value analysis (27 customer types).

**File**: `modules/module_rsv_matrix.R`

#### Three Dimensions

**R (Risk)** - Based on recency:

```r
# Calculate percentiles
r_percentile_20 <- quantile(r_value, 0.2, na.rm = TRUE)
r_percentile_80 <- quantile(r_value, 0.8, na.rm = TRUE)

r_level = case_when(
  r_value <= r_percentile_20 ~ "低",  # Recent = Low risk
  r_value <= r_percentile_80 ~ "中",
  TRUE ~ "高"                          # Dormant = High risk
)

tag_023_churn_risk_level = case_when(
  r_level == "低" ~ "低流失風險",
  r_level == "中" ~ "中流失風險",
  TRUE ~ "高流失風險"
)
```

**S (Stability)** - Based on transaction frequency (with fallback):

**Primary Method** (if ipt_sd field exists):
```r
# Coefficient of Variation (CV) = SD / Mean
stability_cv = ifelse(ipt_mean > 0, ipt_sd / ipt_mean, 0)

s_level = case_when(
  stability_cv <= s_percentile_20 ~ "高",  # Low CV = High stability
  stability_cv <= s_percentile_80 ~ "中",
  TRUE ~ "低"                               # High CV = Low stability
)
```

**Fallback Method** (if ipt_sd doesn't exist):
```r
# Use transaction count as stability proxy
stability_metric = ni

s_level = case_when(
  ni >= s_percentile_80 ~ "高",  # More transactions = Higher stability
  ni >= s_percentile_20 ~ "中",
  TRUE ~ "低"
)
```

**Auto-Detection Logic** (module_rsv_matrix.R:191-226):

```r
mutate(
  # Auto-detect field availability
  stability_metric = if("ipt_sd" %in% names(.)) {
    ifelse(ipt_mean > 0, ipt_sd / ipt_mean, 0)  # CV method
  } else {
    ni  # Fallback: transaction count
  },

  # Adjust classification based on metric used
  s_level = if("ipt_sd" %in% names(.)) {
    # For CV: lower is better
    case_when(
      stability_metric <= s_percentile_20 ~ "高",
      stability_metric <= s_percentile_80 ~ "中",
      TRUE ~ "低"
    )
  } else {
    # For ni: higher is better
    case_when(
      stability_metric >= s_percentile_80 ~ "高",
      stability_metric >= s_percentile_20 ~ "中",
      TRUE ~ "低"
    )
  }
)
```

**Tag 024: Stability Tag**
```r
tag_024_transaction_stability = case_when(
  s_level == "高" ~ "高穩定",
  s_level == "中" ~ "中穩定",
  TRUE ~ "低穩定"
)
```

**V (Value)** - Based on monetary value:

```r
v_percentile_20 <- quantile(m_value, 0.2, na.rm = TRUE)
v_percentile_80 <- quantile(m_value, 0.8, na.rm = TRUE)

v_level = case_when(
  m_value >= v_percentile_80 ~ "高",
  m_value >= v_percentile_20 ~ "中",
  TRUE ~ "低"
)

tag_025_value_tier = case_when(
  v_level == "高" ~ "高價值客戶",
  v_level == "中" ~ "中價值客戶",
  TRUE ~ "低價值客戶"
)
```

#### RSV Combination Matrix

**27 Customer Types** (3 × 3 × 3):

```r
rsv_type = paste0(
  substr(r_level, 1, 1),
  substr(s_level, 1, 1),
  substr(v_level, 1, 1)
)

tag_026_rsv_customer_type = case_when(
  rsv_type == "低高高" ~ "鑽石客戶 (低風險+高穩定+高價值)",
  rsv_type == "低高中" ~ "黃金客戶 (低風險+高穩定+中價值)",
  rsv_type == "低高低" ~ "潛力客戶 (低風險+高穩定+低價值)",
  rsv_type == "高低高" ~ "流失風險VIP (高風險+低穩定+高價值)",
  rsv_type == "高低低" ~ "邊緣客戶 (高風險+低穩定+低價值)",
  # ... 22 more combinations
  TRUE ~ paste0("RSV: ", rsv_type)
)
```

**Key Customer Types**:
- **鑽石客戶** (低高高): Best customers - recent, stable, high-value
- **黃金客戶** (低高中): Solid performers
- **潛力客戶** (低高低): Low value but engaged and stable
- **流失風險VIP** (高低高): High value but at risk
- **邊緣客戶** (高低低): Worst segment

#### Visualizations

1. **3D Scatter Plot**: R × S × V dimensions with color coding
2. **Type Distribution**: Bar chart showing count per RSV type
3. **Heatmap**: R×S grid colored by average value
4. **Data Table**: Downloadable with all RSV metrics

---

### Module 6: Lifecycle Prediction (module_lifecycle_prediction.R)

**Purpose**: Predict future customer behavior and lifecycle transitions.

**File**: `modules/module_lifecycle_prediction.R`

**Note**: Current implementation uses simple average-based predictions. Full predictive modeling requires historical data.

#### Two Prediction Tags

**Tag 027: Next Purchase Prediction**

```r
# Simple average-based prediction
next_purchase_days = if_else(
  is.na(avg_ipt) | ni == 1,
  NA_real_,
  avg_ipt  # Expected days until next purchase
)

tag_027_next_purchase_prediction = case_when(
  is.na(next_purchase_days) ~ "無法預測 (單次客戶)",
  next_purchase_days <= 30 ~ paste0("預計 ", round(next_purchase_days), " 天內回購 (高機率)"),
  next_purchase_days <= 90 ~ paste0("預計 ", round(next_purchase_days), " 天內回購 (中機率)"),
  TRUE ~ paste0("預計 ", round(next_purchase_days), " 天內回購 (低機率)")
)
```

**Tag 028: Lifecycle Stage Prediction**

```r
# Predict next stage based on current position
tag_028_lifecycle_stage_prediction = case_when(
  lifecycle_stage == "newbie" ~ "預測: 若 48h 內回購 → active；否則 → dormant",
  lifecycle_stage == "active" & r_value <= 3 ~ "預測: 維持 active",
  lifecycle_stage == "active" & r_value > 3 ~ "預測: 可能轉 sleepy",
  lifecycle_stage == "sleepy" ~ "預測: 若不介入 → half_sleepy",
  lifecycle_stage == "half_sleepy" ~ "預測: 高風險 → dormant",
  lifecycle_stage == "dormant" ~ "預測: 已流失，需重新激活",
  TRUE ~ "未知"
)
```

**Logic**:
- **Newbie**: Critical 48h window - will become active or dormant
- **Active (r≤3)**: Likely to stay active
- **Active (r>3)**: Risk of becoming sleepy
- **Sleepy**: Without intervention, will progress to half_sleepy
- **Half_sleepy**: High risk of becoming dormant
- **Dormant**: Already lost, needs reactivation campaign

#### Confidence Levels

**Simple Confidence Score**:
```r
prediction_confidence = case_when(
  ni >= 10 ~ "高信心 (10+ 次交易)",
  ni >= 4 ~ "中信心 (4-9 次交易)",
  ni >= 2 ~ "低信心 (2-3 次交易)",
  TRUE ~ "無信心 (單次客戶)"
)
```

**Rationale**: More transaction history = More reliable predictions

#### Key Metrics

- Count of customers by prediction type
- Average predicted days to next purchase
- Distribution of confidence levels

---

### Module 7: Advanced Analytics (module_advanced_analytics.R)

**Purpose**: Cohort analysis, trend detection, and advanced segmentation.

**File**: `modules/module_advanced_analytics.R`

**Current Status**: **Simulated features** - Full implementation requires historical snapshot data.

#### Cohort Analysis (Simulated)

**Cohort Definition**:
```r
# Define cohort by first purchase month
cohort_month = format(first_txn_date, "%Y-%m")
```

**Metrics**:
- Cohort size (unique customers per cohort)
- Cohort retention rate (% still active)
- Cohort LTV (average lifetime value)
- Cohort age (months since first cohort member joined)

**Simulated Retention Calculation**:
```r
# Real retention requires historical snapshots
# Current: Proxy using active vs total ratio
retention_rate = (active_customers / total_customers) * 100
```

#### Trend Detection (Simulated)

**Month-over-Month Trends**:
```r
monthly_metrics <- df %>%
  mutate(txn_month = format(transaction_date, "%Y-%m")) %>%
  group_by(txn_month) %>%
  summarise(
    total_revenue = sum(transaction_amount),
    total_transactions = n(),
    unique_customers = n_distinct(customer_id),
    avg_order_value = mean(transaction_amount),
    .groups = "drop"
  )
```

**Trend Indicators**:
- Revenue growth rate (%)
- Customer acquisition rate
- AOV trend
- Transaction volume trend

#### CLV Prediction (Simplified)

**Simple CLV Formula**:
```r
# Basic CLV = (AOV × Purchase Frequency × Customer Lifespan)
estimated_clv = case_when(
  ni == 1 ~ aov * 1,  # Newbies: Only first purchase
  ni >= 4 ~ aov * ni * (customer_age_days / avg_ipt),  # Projected
  TRUE ~ aov * ni  # Fallback: Just historical
)
```

**Full CLV Model** (requires):
- Historical churn rates
- Discount rate
- Gross margin
- Customer acquisition cost

#### Advanced Segmentation

**RFM × Lifecycle Matrix**:
```r
advanced_segment = paste0(
  tag_019_rfm_segment, " × ", lifecycle_stage
)
```

**Examples**:
- "Champions × active" (best possible)
- "At Risk × sleepy" (needs immediate intervention)
- "Lost × dormant" (reactivation campaign)

**Use Case**: Cross-reference behavioral scores with lifecycle timing for precise targeting.

---

### Cross-Module Data Flow

```
DNA Analysis
├── Calculates: r_value, ni, m_value, avg_ipt, lifecycle_stage, value_level, activity_level
├── Returns: reactive({ data_by_customer })
│
├─→ Customer Base Value
│   └── Uses: avg_ipt, historical_value, aov
│       └── Creates: tag_012, tag_013, tag_014
│
├─→ RFM Analysis
│   └── Uses: r_value, ni, m_value (filters ni >= 4)
│       └── Creates: tag_015, tag_016, tag_017, tag_018, tag_019
│
├─→ Customer Status
│   └── Uses: lifecycle_stage, r_value
│       └── Creates: tag_020, tag_021, tag_022
│
├─→ R/S/V Matrix
│   └── Uses: r_value, ni (or ipt_sd if available), m_value
│       └── Creates: tag_023, tag_024, tag_025, tag_026
│
├─→ Lifecycle Prediction
│   └── Uses: lifecycle_stage, avg_ipt, ni, r_value
│       └── Creates: tag_027, tag_028
│
└─→ Advanced Analytics
    └── Uses: All above + transaction_date, first_txn_date
        └── Creates: Cohort metrics, trends, CLV estimates
```

---

### Key Decision Points in Analysis Logic

#### 1. Newbie Definition
**Decision**: `ni == 1` (simplified from `ni == 1 & customer_age_days <= avg_ipt`)
**Rationale**:
- Single transaction = newbie, regardless of time elapsed
- Time-based restriction was excluding valid first-time customers
- Simplifies logic and aligns with business reality

#### 2. Activity Calculation Threshold
**Decision**: Require `ni >= 4` for activity metrics
**Rationale**:
- Statistical reliability needs multiple data points
- Industry standard for behavioral analysis
- Prevents unreliable classifications from sparse data

#### 3. Percentile-Based Segmentation
**Decision**: Use P20/P80 for all value/activity/risk levels
**Rationale**:
- Dynamic adaptation to actual customer distribution
- Avoids hard-coded thresholds that may not fit all businesses
- Creates balanced segments (20%-60%-20%)

#### 4. Lifecycle Stage Thresholds
**Decision**: 7/14/21 day boundaries for active/sleepy/half_sleepy/dormant
**Rationale**:
- Weekly boundaries align with marketing cycles
- 3-week threshold is industry standard for churn
- Easy to remember and communicate

#### 5. Newbie Display Strategy
**Decision**: Show value-based strategies (A3N/B3N/C3N) instead of grid for newbies
**Rationale**:
- Newbies can't have activity level (ni < 4)
- Focus on second purchase conversion
- Different marketing approach needed for first-time vs repeat customers

#### 6. R/S/V Stability Metric
**Decision**: Auto-detect ipt_sd availability, fallback to ni
**Rationale**:
- DNA module doesn't calculate IPT standard deviation
- Transaction count (ni) is reasonable stability proxy
- Prevents module failure due to missing fields

#### 7. RFM Filtering
**Decision**: Only include customers with `ni >= 4` in RFM analysis
**Rationale**:
- RFM requires behavioral patterns
- Consistent with activity threshold
- Prevents misleading scores from sparse data

#### 8. Prediction Confidence
**Decision**: Base confidence on transaction count (ni)
**Rationale**:
- More history = More reliable predictions
- Simple, interpretable metric
- Aligns with statistical reliability threshold

---

### Logic Consistency Checks

#### ✅ Consistency: Lifecycle Definition
- DNA module defines lifecycle_stage
- Customer Status module uses same definitions
- Lifecycle Prediction references same stages
- **No conflicts**

#### ✅ Consistency: Value Classification
- DNA module calculates value_level (高/中/低)
- R/S/V module recalculates v_level independently
- Customer Base Value uses historical_value
- **All use P20/P80 percentiles - consistent approach**

#### ✅ Consistency: Activity Threshold
- DNA module: activity_level only if `ni >= 4`
- RFM module: filters `ni >= 4`
- **Consistent threshold**

#### ⚠️ Potential Issue: Recency Interpretation
- DNA: Lower r_value = More recent = Higher activity
- RFM: Lower r_value = Higher R score (1-5)
- R/S/V: Lower r_value = Lower risk
- **All consistent but requires careful communication to users**

#### ⚠️ Potential Issue: Newbie Handling
- DNA: newbies get special display (no grid)
- RFM: excludes customers with ni < 4 (includes newbies)
- Customer Status: includes newbies
- **Inconsistent inclusion/exclusion across modules** - may confuse users

---

### Known Limitations

1. **No Historical Snapshots**:
   - Can't calculate true retention rates
   - Can't track lifecycle transitions over time
   - Advanced Analytics uses simulated metrics

2. **Simple Predictions**:
   - Lifecycle Prediction uses average-based estimates
   - No machine learning or statistical modeling
   - Confidence levels are heuristic, not statistical

3. **Missing IPT Variance**:
   - DNA module doesn't calculate ipt_sd
   - R/S/V module must use ni as fallback for stability
   - Less precise stability measurement

4. **Newbie Exclusion**:
   - Newbies excluded from 9-grid analysis
   - Separate display may cause confusion
   - Users might expect all customers in same framework

5. **Static Thresholds**:
   - Lifecycle thresholds (7/14/21 days) are fixed
   - May not fit all business models
   - No industry/category customization

6. **Single-Snapshot Analysis**:
   - All calculations based on current state
   - Can't detect trends or changes over time
   - No time-series forecasting

---

### Usage Recommendations

#### For Accurate Analysis
1. **Ensure data quality**: Validate customer_id, transaction_date, transaction_amount
2. **Sufficient history**: At least 3-6 months of transaction data
3. **Regular updates**: Re-run analysis monthly to track changes
4. **Segment separately**: Analyze newbies separately from repeat customers

#### For Reliable Predictions
1. **Focus on ni >= 4**: Only trust predictions for customers with sufficient history
2. **Business context**: Adjust thresholds based on your industry
3. **Combine modules**: Use multiple perspectives (RFM + R/S/V + Status)
4. **Manual review**: Validate automated tags for high-value customers

#### For Effective Marketing
1. **Newbie strategies**: Implement A3N/B3N/C3N recommendations immediately after first purchase
2. **Lifecycle interventions**: Target sleepy/half_sleepy before they become dormant
3. **RFM targeting**: Focus Champions and Loyal segments for upsell
4. **Risk mitigation**: Immediate action for "流失風險VIP" (high value at risk)

---

## User Interface Structure

### UI Framework: bs4Dash

**Pattern**: bs4DashPage with header, sidebar, body, and footer

### UI Hierarchy

```
bs4DashPage
├── header (bs4DashNavbar)
│   ├── Brand
│   │   ├── Title: "TagPilot Premium"
│   │   └── Image: assets/icons/app_icon.png
│   └── Right UI
│       ├── Database Status Indicator
│       └── User Menu (username + role)
│
├── sidebar (bs4DashSidebar)
│   ├── Welcome Banner
│   │   └── User greeting with role
│   ├── Step Indicator
│   │   ├── Step 1: 上傳資料
│   │   └── Step 2: T-Series 客戶生命週期
│   ├── Menu Items
│   │   ├── 資料上傳 (upload)
│   │   ├── T-Series 客戶生命週期分析 (dna_analysis)
│   │   └── 關於我們 (about)
│   └── Logout Button (bottom fixed)
│
├── body (bs4DashBody)
│   ├── Global CSS Styles
│   ├── shinyjs Integration
│   └── Tab Items
│       ├── upload: Upload Module UI
│       ├── dna_analysis: DNA Multi Premium UI
│       └── about: Company Information
│
└── footer (bs4DashFooter)
    ├── Left: "TagPilot Premium v18 - 精準行銷平台"
    └── Right: "© 2024 All Rights Reserved"
```

### Conditional UI System

**Pattern**: Two-state UI based on authentication

```r
# lines 334-360
ui <- fluidPage(
  useShinyjs(),

  # Login Page (unauthenticated)
  conditionalPanel(
    condition = "output.user_logged_in == false",
    loginModuleUI("login1", ...)
  ),

  # Main App (authenticated)
  conditionalPanel(
    condition = "output.user_logged_in == true",
    main_app_ui  # bs4DashPage
  )
)
```

### Global CSS Customization

**Location**: lines 23-77

**Features**:
- DataTables scrollbar styling (macOS optimization)
- Login container styling
- Step indicator animations
- Welcome banner gradient
- Card elevation and shadows

**Key CSS Classes**:
```css
.dataTables_scrollBody     # Table scrolling
.login-container           # Login page layout
.step-indicator            # Progress visualization
.step-item.active          # Active step (blue)
.step-item.completed       # Completed step (green)
.welcome-banner            # Gradient header
```

### Resource Path Configuration

```r
# line 331: Global scripts assets
addResourcePath("assets", "scripts/global_scripts/24_assets")

# lines 377-378: Application images
images_path <- if (dir.exists("www/images")) "www/images" else "www"
addResourcePath("images", images_path)
```

---

## Server-Side Implementation

### Server Function Structure

```r
server <- function(input, output, session) {
  # 1. Configuration
  options(shiny.maxRequestSize = 200*1024^2)  # 200MB limit

  # 2. Database initialization
  con_global <- get_con()
  db_info <- get_db_info(con_global)
  onStop(function() dbDisconnect(con_global))

  # 3. Reactive state
  user_info <- reactiveVal(NULL)
  sales_data <- reactiveVal(NULL)

  # 4. Module servers
  login_mod <- loginModuleServer(...)
  upload_mod <- uploadModuleServer(...)
  dna_mod <- dnaMultiPremiumModuleServer(...)

  # 5. UI outputs
  output$user_logged_in <- reactive(...)
  output$welcome_user <- renderText(...)
  output$user_menu <- renderUI(...)
  output$db_status <- renderUI(...)

  # 6. Event handlers
  observeEvent(input$sidebar_menu, ...)  # Step indicator
  observeEvent(input$logout, ...)        # Logout
}
```

### Key Server Components

#### 1. Database Status Display
**Output**: `db_status`
**Location**: lines 430-442
**Features**:
- Real-time connection validation
- Visual indicator (green/red)
- Database icon with status text

```r
output$db_status <- renderUI({
  if (dbIsValid(con_global)) {
    span(icon("database"), "資料庫已連接",
         style = "color: #28a745; margin-right: 15px;")
  } else {
    span(icon("database"), "資料庫未連接",
         style = "color: #dc3545; margin-right: 15px;")
  }
})
```

#### 2. User Menu Display
**Output**: `user_menu`
**Location**: lines 418-427
**Features**:
- User icon + username
- Role display
- Authenticated state only

#### 3. Welcome Message
**Output**: `welcome_user`
**Location**: lines 409-415
**Format**: `username (role)`

#### 4. Step Indicator Updates
**Observer**: `input$sidebar_menu`
**Location**: lines 445-455
**Features**:
- Dynamic CSS class updates
- JavaScript integration
- Visual progress feedback

```r
observe({
  if (!is.null(input$sidebar_menu)) {
    runjs("$('.step-item').removeClass('active completed');")
    if (input$sidebar_menu == "upload") {
      runjs("$('#step_1').addClass('active');")
    } else if (input$sidebar_menu == "dna_analysis") {
      runjs("$('#step_1').addClass('completed'); $('#step_2').addClass('active');")
    }
  }
})
```

#### 5. Logout Handler
**Event**: `input$logout`
**Location**: lines 458-462
**Actions**:
- Clear `user_info`
- Clear `sales_data`
- Reset login module state

---

## Database Architecture

### Connection Management

**Pattern**: R092 (Universal DBI Approach)

```r
# Database connection (line 367)
con_global <- get_con()

# Connection metadata (line 368)
db_info <- get_db_info(con_global)

# Cleanup on shutdown (line 369)
onStop(function() dbDisconnect(con_global))
```

### Database Types Supported

1. **DuckDB** (Development/Testing)
   - File-based database
   - Fast analytical queries
   - Embedded database

2. **PostgreSQL** (Production)
   - Client-server architecture
   - Multi-user support
   - ACID compliance

### Data Access Pattern

**Module**: `utils/data_access.R` with tbl2 integration (R116)

**Features**:
- NULL/NA safe operations
- Type-safe queries
- Error handling
- Reactive data binding

---

## Reactive State Management

### Global Reactive Values

**Location**: lines 88-98, 372-374

```r
# LLM-generated attributes
facets_rv <- reactiveVal(NULL)

# Progress tracking
progress_info <- reactiveVal(list(start=NULL, done=0, total=0))

# Tab switching trigger
regression_trigger <- reactiveVal(0)

# User state
user_info <- reactiveVal(NULL)

# Data state
sales_data <- reactiveVal(NULL)
```

### Safe Value Extraction Function

**Function**: `safe_value()`
**Location**: lines 91-98
**Purpose**: Extract numeric values (1-5 scale) safely
**Features**:
- Whitespace trimming
- Regex extraction
- Range validation
- NA handling

```r
safe_value <- function(txt) {
  txt <- trimws(txt)
  num <- str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}
```

### Reactive Dependencies

```
user_info (login_mod)
    ↓
upload_mod (requires user_info)
    ↓
upload_mod$dna_data
    ↓
sales_data (bound to dna_data)
    ↓
dna_mod (analyzes sales_data)
```

---

## Technical Stack

### R Packages

#### Core Framework
- **shiny** (>= 1.7.0) - Reactive web framework
- **bs4Dash** (>= 2.0.0) - Dashboard UI framework
- **shinyjs** - JavaScript integration

#### Data Manipulation
- **dplyr** - Data transformation
- **tidyr** - Data tidying
- **purrr** - Functional programming
- **stringr** - String manipulation

#### Database
- **DBI** - Database interface
- **duckdb** - DuckDB driver
- **RPostgres** - PostgreSQL driver

#### Visualization
- **plotly** - Interactive plots
- **ggplot2** - Static plots
- **DT** - Interactive tables

#### Authentication
- **bcrypt** - Password hashing
- **digest** - Cryptographic hashing

#### Utilities
- **lubridate** - Date/time handling
- **jsonlite** - JSON processing
- **httr** - HTTP requests

### Frontend Technologies

- **AdminLTE 3.0** (via bs4Dash)
- **Bootstrap 4**
- **Font Awesome 5.15.4**
- **jQuery** (for step indicators)
- **Plotly.js** (via plotly R package)
- **DataTables** (via DT R package)

### Backend Technologies

- **R 4.0+** - Primary language
- **DuckDB / PostgreSQL** - Database engines
- **Shiny Server / Posit Connect** - Deployment platforms

---

## Principle Compliance

### Meta-Principles (MP)

| ID | Principle | Implementation |
|----|-----------|----------------|
| **MP016** | Modularity | Clear module separation (login, upload, DNA) |
| **MP048** | Universal Initialization | Explicit package init and config validation |
| **MP052** | Unidirectional Data Flow | Database → Upload → DNA analysis |
| **MP053** | Feedback Loop | Step indicators, status displays |
| **MP054** | UI-Server Correspondence | All UI elements have server logic |

### Principles (P)

| ID | Principle | Implementation |
|----|-----------|----------------|
| **P001** | Script Separation | Config → Modules → App assembly |
| **P007** | Bottom-Up Construction | Modules built independently |

### Rules (R)

| ID | Rule | Implementation |
|----|------|----------------|
| **R004** | YAML Configuration | config/packages.R, config/config.R |
| **R009** | UI-Server-Defaults Triple | All modules follow this pattern |
| **R076** | Module Data Connection | Modules receive `con_global` |
| **R092** | Universal DBI | Consistent `get_con()` pattern |

### Architecture Patterns

1. **Configuration-Driven Development** (R004)
   - Package management externalized
   - Configuration validation on startup

2. **Module Data Connection** (R076)
   - Pass connections, not pre-filtered data
   - Modules handle their own queries

3. **Unidirectional Data Flow** (MP052)
   - Clear data flow direction
   - No circular dependencies

4. **Authentication-Gated UI** (Custom Pattern)
   - Conditional rendering based on auth state
   - Clean separation of login and main app

---

## Deployment Configuration

### File Upload Limits

```r
# line 365
options(shiny.maxRequestSize = 200*1024^2)  # 200MB
```

### Resource Paths

```r
# Global scripts assets (line 331)
addResourcePath("assets", "scripts/global_scripts/24_assets")

# Application images (lines 377-378)
addResourcePath("images", images_path)
```

### Environment Variables Required

Based on database connection pattern:
- `PGHOST` - PostgreSQL host
- `PGPORT` - PostgreSQL port
- `PGUSER` - PostgreSQL username
- `PGPASSWORD` - PostgreSQL password
- `PGDATABASE` - Database name
- `PGSSLMODE` - SSL mode

### Deployment Targets

1. **Primary**: Posit Connect Cloud
2. **Alternative**: ShinyApps.io
3. **Development**: Local with DuckDB

---

## About Company Information

### Company Details
**Name**: 祈鋒行銷科技有限公司 (PeakedEdges Marketing Technology)
**Contact**: partners@peakededges.com
**Location**: lines 269-314

### Services Provided

1. **客群分群建模** (Segmentation Modeling)
2. **意圖辨識與推薦系統** (Intent Detection & Recommendation)
3. **評論內容語意分析** (Sentiment & Aspect Analysis)
4. **行銷活動預測與績效追蹤** (Campaign Forecasting & Tracking)
5. **多管道數據整合與儀表板** (Omni-channel Dashboard & ETL)

### Past Client
**Kitchen Mama** (美商駿旺)
Website: https://shopkitchenmama.com/

---

## Technical Highlights

### 1. Modular Architecture
- Clean separation between modules
- Independent development and testing
- Reusable components

### 2. Principle-Driven Development
- 257+ documented principles applied
- Consistent patterns across codebase
- Maintainable and scalable

### 3. User Experience
- Two-step wizard workflow
- Real-time feedback
- Progress indicators
- Auto-navigation

### 4. Database Integration
- Universal DBI approach
- Connection pooling
- Safe data access with tbl2

### 5. Security
- Database-backed authentication
- Password hashing with bcrypt
- Role-based access control
- Session management

### 6. Performance
- 200MB file upload support
- Reactive programming for efficiency
- Optimized database queries

---

## Development Guidelines

### When Adding New Features

1. **Review Principles**: Check `scripts/global_scripts/00_principles/`
2. **Follow Patterns**: Use existing module patterns
3. **Module Structure**: Implement UI-Server-Defaults triple
4. **Data Flow**: Pass connections, not data
5. **Testing**: Test with mock connections
6. **Documentation**: Update this document

### Common Patterns

#### Creating a New Module
```r
# 1. Create module file
modules/module_new_feature.R

# 2. Implement UI function
newFeatureModuleUI <- function(id) { ... }

# 3. Implement Server function
newFeatureModuleServer <- function(id, con, user_info, ...) { ... }

# 4. Source in app.R
source("modules/module_new_feature.R")

# 5. Add to UI
newFeatureModuleUI("new_feature1")

# 6. Add to Server
new_feature_mod <- newFeatureModuleServer("new_feature1", con_global, user_info)
```

### Debugging Tips

1. **Database Connection**: Check `output$db_status`
2. **User State**: Monitor `user_info()` reactive
3. **Data Flow**: Use browser() in reactive contexts
4. **Module Communication**: Check reactive binding with `observe()`

---

## Appendix

### File Locations Reference

| Component | File Path |
|-----------|-----------|
| Main App | `app.R` |
| Database Connection | `database/db_connection.R` |
| Data Access | `utils/data_access.R` |
| Login Module | `scripts/global_scripts/10_rshinyapp_components/login/login_module.R` |
| Upload Module | `modules/module_upload.R` |
| DNA Module (Basic) | `modules/module_dna.R` |
| DNA Module (Premium) | `modules/module_dna_multi_premium.R` |
| WO_B Module | `modules/module_wo_b.R` |
| Package Config | `config/packages.R` |
| App Config | `config/config.R` |
| App Icon | `scripts/global_scripts/24_assets/icons/app_icon.png` |

### Key Reactive Values

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `user_info` | reactiveVal | Logged-in user data | Line 372 |
| `sales_data` | reactiveVal | Uploaded data | Line 374 |
| `facets_rv` | reactiveVal | LLM attributes | Line 89 |
| `progress_info` | reactiveVal | Progress tracking | Line 90 |
| `regression_trigger` | reactiveVal | Tab switching | Line 101 |

### UI Output Reference

| Output ID | Type | Purpose | Location |
|-----------|------|---------|----------|
| `user_logged_in` | reactive | Auth state | Lines 403-406 |
| `welcome_user` | renderText | User greeting | Lines 409-415 |
| `user_menu` | renderUI | User menu | Lines 418-427 |
| `db_status` | renderUI | DB connection | Lines 430-442 |

---

**Document Version**: 1.0
**Last Updated**: 2025-10-25
**Maintained By**: Development Team
**For Questions**: partners@peakededges.com

---

*This documentation follows the principle-driven development approach as defined in the global_scripts/00_principles framework. All architectural decisions are traceable to specific principles (MP/P/R codes).*
