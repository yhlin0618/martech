# Part 1: System Architecture & Data Flow

**Document Version**: v1.0
**Created**: 2025-11-06
**For**: logic_v20251106.md

---

## 1. Application Structure Overview

### 1.1 Main Application File: app.R

**Location**: `/app.R`
**Lines**: 770 lines total

**Key Components**:
```r
# System Initialization (Lines 12-20)
source("config/packages.R")
source("config/config.R")
initialize_packages()
validate_config()

# Module Loading (Lines 79-96)
source("database/db_connection.R")
source("utils/data_access.R")
source("modules/module_wo_b.R")
source("modules/module_upload.R")
source("modules/module_dna_multi_premium_v2.R")  # ⭐ Core DNA Analysis
source("modules/module_customer_base_value.R")
source("modules/module_customer_value_analysis.R")
source("modules/module_customer_activity.R")
source("modules/module_customer_status.R")
source("modules/module_rsv_matrix.R")
source("modules/module_lifecycle_prediction.R")
source("modules/module_advanced_analytics.R")
```

### 1.2 UI Structure (bs4Dash Framework)

**Header** (Lines 121-134):
- Title: "TagPilot Premium"
- Database status indicator
- User menu

**Sidebar** (Lines 137-226):
- Welcome banner with username
- Step indicator (1. 上傳 → 2. 九宮格 → 3. 詳細分析)
- Navigation menu with 9 tabs

**Body** (Lines 229-522):
- Tab 1: 資料上傳 (Data Upload)
- Tab 2: 顧客價值與動態市場區隔分析 (DNA Analysis - 九宮格)
- Tab 3: 顧客基礎價值 (Base Value)
- Tab 4: 顧客價值 (RFM Analysis)
- Tab 5: 顧客活躍度 (CAI Analysis)
- Tab 6: 顧客動態 (Customer Status)
- Tab 7: R/S/V 生命力矩陣 (RSV Matrix)
- Tab 8: 生命週期預測 (Lifecycle Prediction)
- Tab 9: 進階分析 (Advanced Analytics)

---

## 2. Complete Data Flow

### 2.1 High-Level Data Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  Step 1: Data Upload (module_upload.R)                     │
│  Input: CSV files with transaction data                    │
│  Output: Combined transaction dataset                      │
└───────────────────┬─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 2: DNA Analysis Engine (module_dna_multi_premium_v2) │
│  Calls: analyze_customer_dynamics_new()                    │
│  Output: customer_data with RFM + customer_dynamics        │
└───────────────────┬─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 3: Calculate Segmentation                            │
│  - value_level (低/中/高) via P20/P80 with edge cases      │
│  - activity_level (低/中/高) via CAI for ni≥4             │
│  - customer_dynamics (newbie/active/sleepy/half/dormant)   │
│  Output: customer_data with segmentation columns           │
└───────────────────┬─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Step 4: Calculate 38+ Customer Tags                       │
│  Calls: calculate_all_customer_tags()                      │
│  Output: customer_data with all tag_XXX columns            │
└───────────────────┬─────────────────────────────────────────┘
                    ↓
         ┌──────────┴──────────┐
         ↓                     ↓
┌─────────────────┐  ┌─────────────────┐
│  Module Chain   │  │  Visualization  │
│  (6 modules)    │  │  (Nine-Grid)    │
└─────────────────┘  └─────────────────┘
```

### 2.2 Server-Side Data Flow (app.R Lines 566-627)

```r
# 1. Database Connection (Line 570)
con_global <- get_con()

# 2. Login Module (Lines 584-587)
login_mod <- loginModuleServer("login1", con_global)
user_info <- login_mod$user_info()

# 3. Upload Module (Lines 590-600)
upload_mod <- uploadModuleServer("upload1", con_global, user_info)
sales_data <- upload_mod$dna_data()  # Transaction data

# Auto-navigate to RFM page after upload (Lines 596-600)
observeEvent(upload_mod$proceed_step(), {
  if (upload_mod$proceed_step() > 0 && nrow(upload_mod$dna_data()) > 0) {
    updateTabItems(session, "sidebar_menu", "rfm_analysis")
  }
})

# 4. DNA Analysis Module (Line 603) ⭐ CRITICAL
dna_mod <- dnaMultiPremiumModuleServer("dna_multi1", con_global, user_info, upload_mod$dna_data)

# 5. Six-Module Chain (Lines 609-627)
base_value_data <- customerBaseValueServer("base_value_module", dna_mod)
rfm_data <- customerValueAnalysisServer("rfm_module", base_value_data)
customerActivityServer("customer_activity", rfm_data)
status_data <- customerStatusServer("status_module", rfm_data)
rsv_data <- rsvMatrixServer("rsv_module", status_data)
prediction_data <- lifecyclePredictionServer("prediction_module", rsv_data)
advanced_data <- advancedAnalyticsServer("advanced_module", prediction_data)
```

### 2.3 Data Dependencies Between Modules

```
upload_mod$dna_data()
    ↓
dna_mod (DNA Analysis + Z-Score + Segmentation + Tags)
    ├─→ values$dna_results$data_by_customer (all data)
    └─→ values$processed_data (for downstream)
        ↓
base_value_data (Base Value Calculations)
    ├─→ Purchase cycle segmentation
    ├─→ Past value segmentation
    └─→ AOV analysis
        ↓
rfm_data (RFM Analysis)
    ├─→ tag_009_rfm_r
    ├─→ tag_010_rfm_f
    ├─→ tag_011_rfm_m
    ├─→ tag_012_rfm_score
    └─→ tag_013_value_segment
        ↓
customerActivity (CAI Analysis)
    └─→ CAI-based insights
        ↓
status_data (Customer Status)
    ├─→ tag_017_customer_dynamics (中文)
    ├─→ tag_018_churn_risk
    └─→ tag_019_days_to_churn
        ↓
rsv_data (RSV Matrix)
    ├─→ Risk dimension
    ├─→ Stability dimension
    └─→ Value dimension
        ↓
prediction_data (Lifecycle Prediction)
    ├─→ tag_030_next_purchase_amount
    └─→ tag_031_next_purchase_date
        ↓
advanced_data (Advanced Analytics)
    └─→ Historical cohort analysis
```

### 2.4 Reactive Data Passing Pattern

**Pattern Used**: Each module returns a reactive expression containing processed data.

**Example**:
```r
# Module definition (in module file)
moduleServer <- function(id, input_data) {
  moduleServer(id, function(input, output, session) {
    values <- reactiveValues(processed_data = NULL)

    observe({
      req(input_data())  # Wait for input data
      values$processed_data <- input_data() %>%
        # ... processing ...
    })

    # Return reactive for next module
    return(reactive({ values$processed_data }))
  })
}

# Module chain (in app.R)
module_a <- moduleAServer("a", input_reactive)
module_b <- moduleBServer("b", module_a)  # Receives module_a's output
module_c <- moduleCServer("c", module_b)  # Receives module_b's output
```

---

## 3. File Structure

```
TagPilot_premium/
├── app.R                           # Main application (770 lines)
├── config/
│   ├── packages.R                  # Package management
│   ├── config.R                    # Configuration settings
│   └── customer_dynamics_config.R  # Z-score parameters
├── database/
│   └── db_connection.R             # PostgreSQL connection
├── utils/                          # ⭐ Core utility functions
│   ├── analyze_customer_dynamics_new.R  # Z-score algorithm (600+ lines)
│   ├── calculate_customer_tags.R        # Tag calculations (323 lines)
│   └── data_access.R                    # Database access
├── modules/                        # ⭐ UI/Server modules
│   ├── module_upload.R             # Data upload
│   ├── module_dna_multi_premium_v2.R    # DNA analysis (1200+ lines)
│   ├── module_customer_base_value.R     # Base value analysis
│   ├── module_customer_value_analysis.R # RFM analysis
│   ├── module_customer_activity.R       # CAI analysis
│   ├── module_customer_status.R         # Customer status
│   ├── module_rsv_matrix.R              # RSV matrix
│   ├── module_lifecycle_prediction.R    # Lifecycle prediction
│   └── module_advanced_analytics.R      # Advanced analytics
├── scripts/global_scripts/         # Shared global scripts
│   ├── 04_utils/
│   │   ├── fn_analysis_dna.R       # Legacy DNA analysis
│   │   ├── fn_left_join_remove_duplicate2.R
│   │   └── fn_fct_na_value_to_level.R
│   └── 10_rshinyapp_components/
│       └── login/login_module.R    # Login component
└── documents/
    └── 02_architecture/
        ├── logic.md                # Previous logic documentation
        ├── logic_revised.md        # Revised logic (Z-score)
        └── logic_v20251106.md      # This comprehensive document
```

---

## 4. Key Data Structures

### 4.1 Transaction Data (Input from CSV)

**Required Columns**:
```r
customer_id         # Character - Unique customer identifier
payment_time        # POSIXct - Transaction timestamp (or transaction_date)
lineitem_price      # Numeric - Transaction amount (or transaction_amount)
```

**Optional Columns**:
```r
order_id            # Character - Order identifier
product_id          # Character - Product identifier
platform_id         # Character - Sales platform
```

**Example**:
```
customer_id | payment_time       | lineitem_price
------------|-------------------|---------------
CUST001     | 2024-01-15 10:30  | 1200.00
CUST001     | 2024-02-10 14:20  | 850.00
CUST002     | 2024-01-20 09:15  | 3500.00
```

### 4.2 Customer Summary Data (After DNA Analysis)

**Core Metrics from analyze_customer_dynamics_new()**:
```r
customer_id          # Character
ni                   # Numeric - Number of transactions
time_first           # Date - First purchase date
time_last            # Date - Last purchase date
r_value              # Numeric - Recency (days since last purchase)
f_value              # Numeric - Frequency (transaction count)
m_value              # Numeric - Monetary (average transaction value)
ipt                  # Numeric - Inter-Purchase Time (average days between purchases)
customer_age_days    # Numeric - Days since first purchase
total_spent          # Numeric - Total amount spent
```

**Z-Score Metrics**:
```r
F_i_w                # Numeric - Transactions in last W days
z_i                  # Numeric - Z-score for customer activity
```

**Segmentation Columns**:
```r
customer_dynamics    # Character - newbie/active/sleepy/half_sleepy/dormant
value_level          # Character - 低/中/高
activity_level       # Character - 低/中/高 (NA for ni < 4)
grid_position        # Character - A1-C3 or "無"
```

### 4.3 Tagged Customer Data (After calculate_all_customer_tags())

**38+ Customer Tags** organized in 6 categories:
```r
# Base Value Tags (tag_001-004)
tag_001_avg_purchase_cycle
tag_003_historical_total_value
tag_004_avg_order_value

# RFM Tags (tag_009-013)
tag_009_rfm_r
tag_010_rfm_f
tag_011_rfm_m
tag_012_rfm_score
tag_013_value_segment

# Status Tags (tag_017-019)
tag_017_customer_dynamics  # Chinese labels
tag_018_churn_risk
tag_019_days_to_churn

# Prediction Tags (tag_030-031)
tag_030_next_purchase_amount
tag_031_next_purchase_date

# RSV Tags (tag_032-034)
tag_032_dormancy_risk
tag_033_transaction_stability
tag_034_customer_lifetime_value

# ... and more
```

---

## 5. Critical Configuration Files

### 5.1 customer_dynamics_config.R

**Purpose**: Configure Z-score algorithm parameters

**Key Parameters**:
```r
method = "auto"              # "auto", "z_score", or "fixed_threshold"
k = 2.5                      # Tolerance multiplier for W calculation
min_window = 90              # Minimum observation window (days)
active_threshold = 0.5       # Z-score threshold for active
sleepy_threshold = -1.0      # Z-score threshold for sleepy
half_sleepy_threshold = -1.5 # Z-score threshold for half-sleepy
use_recency_guardrail = TRUE # Apply R≤7 check for active
```

### 5.2 packages.R

**Purpose**: Manage all R package dependencies

**Core Packages**:
```r
shiny, bs4Dash               # UI framework
dplyr, tidyverse             # Data manipulation
DBI, RPostgres               # Database
plotly, DT                   # Visualization
readxl                       # Excel import
future, furrr                # Async processing
bcrypt                       # Authentication
```

---

## 6. External Dependencies

### 6.1 Database (PostgreSQL)

**Connection**: `database/db_connection.R`
**Tables Used**:
- `users` - User authentication
- `tbl2` - (Optional) Pre-processed customer data

### 6.2 Global Scripts (Submodule)

**Path**: `scripts/global_scripts/`
**Repository**: `https://github.com/kiki830621/ai_martech_global_scripts.git`

**Key Functions Used**:
- `fn_analysis_dna.R` - Legacy DNA analysis (still used for certain calculations)
- `fn_left_join_remove_duplicate2.R` - Safe join operations
- `fn_fct_na_value_to_level.R` - NA handling utilities

---

**End of Part 1**
