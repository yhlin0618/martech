# TagPilot Pro - Application Architecture Documentation

**Documentation Date**: 2025-10-25
**Application Version**: v18 (bs4Dash)
**Tier**: L2 Professional
**Framework**: R Shiny + bs4Dash
**Last Updated**: 2024-06-23

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Application Overview](#application-overview)
3. [L2 Pro vs L3 Premium Comparison](#l2-pro-vs-l3-premium-comparison)
4. [Architecture & Design Patterns](#architecture--design-patterns)
5. [System Initialization](#system-initialization)
6. [Module Structure](#module-structure)
7. [Data Flow Architecture](#data-flow-architecture)
8. [User Interface Structure](#user-interface-structure)
9. [Server-Side Implementation](#server-side-implementation)
10. [Database Architecture](#database-architecture)
11. [Reactive State Management](#reactive-state-management)
12. [Technical Stack](#technical-stack)
13. [Principle Compliance](#principle-compliance)
14. [Deployment Configuration](#deployment-configuration)

---

## Executive Summary

TagPilot Pro is a **precision marketing platform** designed for the **L2 Professional tier**, providing **Value × Activity 九宮格** (9-grid matrix) analysis for customer segmentation and targeting. Built on the bs4Dash framework, it offers a streamlined approach to customer DNA profiling with a focus on value-activity mapping.

### Key Capabilities:
- Multi-file data upload and processing
- Value × Activity 9-grid matrix analysis
- Customer DNA profiling with visual analytics
- Role-based authentication system
- Real-time database connection monitoring

### Core Analysis Framework:
- **Value Dimension**: Customer value assessment
- **Activity Dimension**: Customer activity level
- **9-Grid Matrix**: Strategic customer segmentation

---

## Application Overview

### Application Identity
- **Name**: Tag Pilot 精準行銷平台
- **Tier**: L2 Professional
- **Primary Purpose**: Value-Activity based customer segmentation
- **Target Users**: Marketing teams, SME businesses, data analysts
- **Deployment**: Posit Connect Cloud / ShinyApps.io

### Core Features
1. **Secure Authentication**: User login with role-based access control
2. **Data Upload**: Multi-file CSV upload support (200MB limit)
3. **DNA Analysis**: Customer DNA profiling with Value × Activity framework
4. **9-Grid Matrix**: Strategic customer segmentation visualization
5. **Visual Analytics**: Interactive dashboards with Plotly visualizations
6. **Database Integration**: Real-time connection to DuckDB/PostgreSQL

---

## L2 Pro vs L3 Premium Comparison

### Key Differences

| Feature | L2 Pro (TagPilot Pro) | L3 Premium (TagPilot Premium) |
|---------|----------------------|-------------------------------|
| **Application Name** | Tag Pilot | TagPilot Premium |
| **Step 2 Analysis** | Value × Activity 九宮格 | T-Series 客戶生命週期 |
| **Analysis Framework** | Value-Activity Matrix | ROS Framework (Risk-Opportunity-Stability) |
| **DNA Module** | `module_dna_multi.R` | `module_dna_multi_premium.R` |
| **Contact Person** | 林郁翔 (yuhsiang@utaipei.edu.tw) | partners@peakededges.com |
| **Target Market** | SME, Professional users | Enterprise, Premium clients |
| **Complexity** | Simplified 9-grid analysis | Advanced T-Series + IPT analysis |
| **Pricing Tier** | Professional | Premium |

### Similarities

Both versions share:
- ✓ Same authentication-gated architecture
- ✓ Same bs4Dash UI framework
- ✓ Same module structure (Login, Upload, DNA)
- ✓ Same database connectivity pattern (R092)
- ✓ Same reactive programming model
- ✓ Same configuration-driven approach
- ✓ Same file upload capacity (200MB)
- ✓ Same step-by-step wizard interface

### Architectural Parity

```
┌─────────────────────────────────────────────────┐
│  L2 Pro & L3 Premium Share Core Architecture   │
├─────────────────────────────────────────────────┤
│  Authentication → Upload → Analysis             │
│  bs4Dash UI → Reactive Server → Database        │
│  Modular Components → Principle-Driven          │
└─────────────────────────────────────────────────┘
```

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
│  Upload Module → Data Ingestion           │
├───────────────────────────────────────────┤
│  DNA Multi → Value × Activity Analysis    │
└───────────────────────────────────────────┘
```

---

## System Initialization

### Initialization Sequence

**File Location**: `/app.R` lines 7-15

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
├── modules/module_dna_multi.R        # Value × Activity 9-grid analysis
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
# UI (lines 342-347)
loginModuleUI("login1",
              app_title = "TagPilot Pro",
              app_icon = "assets/icons/app_icon.png",
              contacts_md = "md/contacts.md",
              background_color = "transparent",
              primary_color = "#17a2b8")

# Server (line 376)
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
# UI (line 185)
uploadModuleUI("upload1")

# Server (line 382)
upload_mod <- uploadModuleServer("upload1", con_global, user_info)

# Data binding (line 384)
sales_data(upload_mod$dna_data())
```

#### 6. DNA Multi Module
**File**: `modules/module_dna_multi.R`
**Purpose**: Value × Activity 9-grid matrix analysis
**Pattern**: R009 (UI-Server-Defaults Triple)
**Features**:
- Customer DNA profiling
- Value dimension analysis
- Activity dimension analysis
- 9-grid matrix visualization
- Strategic segment identification

**Usage in app.R**:
```r
# UI (line 202)
dnaMultiModuleUI("dna_multi1")

# Server (line 395)
dna_mod <- dnaMultiModuleServer("dna_multi1",
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
│  DNA Multi Module                                           │
│  ↓                                                           │
│  Value × Activity Analysis → 9-Grid Matrix                  │
└─────────────────────────────────────────────────────────────┘
```

### Module Data Connection Pattern (R076)

**Principle**: Modules receive **connections**, not pre-filtered data

```r
# Server initialization (lines 362-364)
con_global <- get_con()
db_info <- get_db_info(con_global)
onStop(function() dbDisconnect(con_global))

# Module receives connection
upload_mod <- uploadModuleServer("upload1", con_global, user_info)
dna_mod <- dnaMultiModuleServer("dna_multi1",
                                con_global,      # Connection passed
                                user_info,
                                upload_mod$dna_data)
```

### Reactive Value Flow

```r
# Global reactive values (lines 367-369)
user_info    <- reactiveVal(NULL)   # Login state
sales_data   <- reactiveVal(NULL)   # Upload data

# Module → Reactive binding (lines 377-385)
observe({ user_info(login_mod$user_info()) })
observe({ sales_data(upload_mod$dna_data()) })
```

### Auto-Navigation Pattern

**Feature**: Automatic tab switching after successful upload

```r
# lines 388-392
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

## User Interface Structure

### UI Framework: bs4Dash

**Pattern**: bs4DashPage with header, sidebar, body, and footer

### UI Hierarchy

```
bs4DashPage
├── header (bs4DashNavbar)
│   ├── Brand
│   │   ├── Title: "Tag Pilot"
│   │   └── Image: assets/icons/app_icon.png
│   └── Right UI
│       ├── Database Status Indicator
│       └── User Menu (username + role)
│
├── sidebar (bs4DashSidebar)
��   ├── Welcome Banner
│   │   └── User greeting with role
│   ├── Step Indicator
│   │   ├── Step 1: 上傳資料
│   │   └── Step 2: Value × Activity 九宮格
│   ├── Menu Items
│   │   ├── 資料上傳 (upload)
│   │   ├── Value × Activity 九宮格 (dna_analysis)
│   │   └── 關於我們 (about)
│   └── Logout Button (bottom fixed)
│
├── body (bs4DashBody)
│   ├── Global CSS Styles
│   ├── shinyjs Integration
│   └── Tab Items
│       ├── upload: Upload Module UI
│       ├── dna_analysis: DNA Multi Module UI
│       └── about: Company Information
│
└── footer (bs4DashFooter)
    ├── Left: "Tag Pilot v18 - 精準行銷平台"
    └── Right: "© 2024 All Rights Reserved"
```

### Conditional UI System

**Pattern**: Two-state UI based on authentication

```r
# lines 329-355
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

**Location**: lines 18-72

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
# line 326: Global scripts assets
addResourcePath("assets", "scripts/global_scripts/24_assets")

# lines 372-373: Application images
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
  dna_mod <- dnaMultiModuleServer(...)

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
**Location**: lines 425-437
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
**Location**: lines 413-422
**Features**:
- User icon + username
- Role display
- Authenticated state only

#### 3. Welcome Message
**Output**: `welcome_user`
**Location**: lines 404-410
**Format**: `username (role)`

#### 4. Step Indicator Updates
**Observer**: `input$sidebar_menu`
**Location**: lines 440-450
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
**Location**: lines 453-457
**Actions**:
- Clear `user_info`
- Clear `sales_data`
- Reset login module state

---

## Database Architecture

### Connection Management

**Pattern**: R092 (Universal DBI Approach)

```r
# Database connection (line 362)
con_global <- get_con()

# Connection metadata (line 363)
db_info <- get_db_info(con_global)

# Cleanup on shutdown (line 364)
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

**Location**: lines 84-93, 367-369

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
**Location**: lines 86-93
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
# line 360
options(shiny.maxRequestSize = 200*1024^2)  # 200MB
```

### Resource Paths

```r
# Global scripts assets (line 326)
addResourcePath("assets", "scripts/global_scripts/24_assets")

# Application images (lines 372-373)
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
**Contact**: 林郁翔 (yuhsiang@utaipei.edu.tw)
**Location**: lines 263-309

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

## Value × Activity Framework

### Analysis Dimensions

#### Value Dimension
- **High Value**: Customers with high monetary contribution
- **Medium Value**: Customers with moderate spending
- **Low Value**: Customers with low spending

#### Activity Dimension
- **High Activity**: Frequent engagement/purchases
- **Medium Activity**: Regular but not frequent engagement
- **Low Activity**: Infrequent or dormant customers

### 9-Grid Matrix Segmentation

```
        High Activity │ Medium Activity │ Low Activity
        ──────────────┼─────────────────┼──────────────
High    Champions     │ Potential       │ At Risk
Value   (Retain)      │ Loyalists       │ (Win Back)
        ──────────────┼─────────────────┼──────────────
Medium  Need          │ Average         │ Hibernating
Value   Attention     │ Customers       │ (Re-engage)
        ──────────────┼─────────────────┼──────────────
Low     New           │ Promising       │ Lost
Value   Customers     │ (Develop)       │ (Let Go)
```

### Strategic Actions per Segment

1. **Champions**: VIP treatment, exclusive offers
2. **Potential Loyalists**: Loyalty programs, incentives
3. **At Risk**: Win-back campaigns, special attention
4. **Need Attention**: Re-engagement strategies
5. **Average Customers**: Standard marketing
6. **Hibernating**: Reactivation campaigns
7. **New Customers**: Onboarding, education
8. **Promising**: Development programs
9. **Lost**: Minimal investment or let go

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
| DNA Module (Multi) | `modules/module_dna_multi.R` |
| WO_B Module | `modules/module_wo_b.R` |
| Package Config | `config/packages.R` |
| App Config | `config/config.R` |
| App Icon | `scripts/global_scripts/24_assets/icons/app_icon.png` |

### Key Reactive Values

| Name | Type | Purpose | Location |
|------|------|---------|----------|
| `user_info` | reactiveVal | Logged-in user data | Line 367 |
| `sales_data` | reactiveVal | Uploaded data | Line 369 |
| `facets_rv` | reactiveVal | LLM attributes | Line 84 |
| `progress_info` | reactiveVal | Progress tracking | Line 85 |
| `regression_trigger` | reactiveVal | Tab switching | Line 96 |

### UI Output Reference

| Output ID | Type | Purpose | Location |
|-----------|------|---------|----------|
| `user_logged_in` | reactive | Auth state | Lines 398-401 |
| `welcome_user` | renderText | User greeting | Lines 404-410 |
| `user_menu` | renderUI | User menu | Lines 413-422 |
| `db_status` | renderUI | DB connection | Lines 425-437 |

---

## Upgrade Path to L3 Premium

For organizations requiring advanced analytics, the upgrade path from L2 Pro to L3 Premium includes:

### Enhanced Features in L3 Premium
1. **T-Series Lifecycle Analysis**: Advanced temporal analysis
2. **ROS Framework**: Risk-Opportunity-Stability metrics
3. **IPT Analysis**: Inter-Purchase Time insights
4. **Enhanced Customer Journey**: Detailed lifecycle stages
5. **Premium Support**: Dedicated support channel

### Migration Considerations
- Data schema compatibility: ✓ Compatible
- Module structure: ✓ Same architecture
- User training: Minimal (similar UI)
- Cost: Contact partners@peakededges.com

---

**Document Version**: 1.0
**Last Updated**: 2025-10-25
**Maintained By**: Development Team
**For Questions**: yuhsiang@utaipei.edu.tw

---

*This documentation follows the principle-driven development approach as defined in the global_scripts/00_principles framework. All architectural decisions are traceable to specific principles (MP/P/R codes).*
