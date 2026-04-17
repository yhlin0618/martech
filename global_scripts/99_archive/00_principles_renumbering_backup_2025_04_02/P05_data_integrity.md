---
id: "P05"
title: "Data Integrity"
type: "principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "P03": "Project Principles"
  - "MP01": "Primitive Terms and Definitions"
influences:
  - "P07": "App Construction Principles"
  - "MP23": "Data Source Hierarchy"
  - "P25": "Authentic Context Testing"
---

# Data Integrity Principles

## 1. Data Flow and Storage Locations

### Data Storage Locations

The project uses multiple locations to store data at different stages of processing:

| Location | Path | Description |
|----------|------|-------------|
| External Raw Data Files | `/rawdata_[companyname]/` | Original source files exactly as received from external sources |
| External Raw Data DB | DuckDB `external_raw_data` database | Data collected via web crawling/scraping stored without modification |
| Raw Data DB | DuckDB `raw_data` database | Raw data imported without modification |
| Cleansed Data DB | DuckDB `cleansed_data` database | Data after basic cleaning operations |
| Processed Data DB | DuckDB `processed_data` database | Fully transformed data with business logic applied |
| Processed Data Files | `/precision_marketing_[companyname]/data/` | Intermediate processed files for analysis |
| App Data DB | DuckDB `app_data` database | Optimized data structures for the Shiny app |
| App Data Files | `/precision_marketing_app/app_data/` | Application-specific data files (RDS, etc.) |
| SCD Type 0 | `/global_scripts/30_global_data/scd_type0/` | Constant reference data that never changes (like map files) |
| SCD Type 1 | `/precision_marketing_app/app_data/scd_type1/` | Slowly Changing Dimension data with full replacement |
| SCD Type 1 DB | `/global_scripts/30_global_data/global_scd_type1.duckdb` | Global SCD Type 1 database for shared reference data |
| SCD Type 2 | `/precision_marketing_app/app_data/scd_type2/` | Slowly Changing Dimension data with history preservation |
| Snapshot DB | DuckDB `snapshot_data` database | Point-in-time snapshots of key datasets for auditing and rollback |

### Complete Data Flow

All data must follow a strict processing flow through well-defined stages:

```
                      ┌─────────────────┐
External       rawdata_[companyname]/   │   
  Files  →→→  (external raw files)  →→→ │                                            
                                         │                                             
External      Web Crawling/Scraping     │  external_raw_data DB   raw_data DB   cleansed_data DB   processed_data DB
  Web  →→→        Module           →→→ │ →→→       (0)        →→→    (1)    →→→      (2)       →→→       (3)       
 Sources                                 │                                                           ↓
                      Import Module      │                     ←← ←← ←← ←← ←← ←← ←← ←← ←← ←┘
                      └─────────────────┘                     ↓
                                        precision_marketing_[companyname]/data/
                                                  (processed files)
                                                        ↓
                 precision_marketing_app/app_data/   app_data DB       snapshot_data DB
                            (app files)          →→→    (4)      ←→→→      (5)
                                 ↓
  global_scripts/30_global_data/      /app_data/scd_type1/   /app_data/scd_type2/
   /scd_type0/  global_scd_type1.duckdb  (basic parameters)   (historical parameters)
  (constant)        (global refs)
```

0. **external_raw_data DB**: Data collected via web crawling/scraping stored without modification
1. **raw_data DB**: Original data imported exactly as received without any modifications
2. **cleansed_data DB**: Data after basic cleaning (types, missing values, deduplication)
3. **processed_data DB**: Fully transformed data with business logic applied 
4. **app_data DB**: Optimized data structures specifically for the application
5. **snapshot_data DB**: Point-in-time snapshots of key datasets for auditing and rollback purposes

### Database and Directory Roles

Each storage location has a specific purpose and data handling requirements:

| Location | Purpose | Modifications Allowed |
|----------|---------|----------------------|
| rawdata_[companyname]/ (External Raw Data Files) | Store original external files | NONE |
| external_raw_data DB | Store web crawled/scraped data | NONE |
| raw_data DB | Initial data import | NONE |
| cleansed_data DB | Basic data cleaning | Format standardization only |
| processed_data DB | Business logic processing | Full transformation |
| precision_marketing_[companyname]/data/ | Analysis-ready datasets | Full transformation |
| precision_marketing_app/app_data/ | App-specific data files | Optimized for app use |
| app_data DB | Application database | Any needed for app functionality |
| snapshot_data DB | Point-in-time data snapshots | NONE (read-only snapshots) |

## 2. Raw Data Sanctity

### CRITICAL: Raw Data Must Never Be Modified

External raw data files (in `rawdata_[companyname]/`), web crawled/scraped data (in `external_raw_data` database), and raw data database tables (in `raw_data` database) represent the original source of truth and **must never be modified under any circumstances**. This is a fundamental principle of data integrity.

#### For External Raw Data Files:
- **✅ DO:** Keep original raw files exactly as received in the `rawdata_[companyname]/` directory
- **❌ NEVER:** Edit, rename, or "fix" raw files, even if they contain obvious errors
- **✅ DO:** Create file catalogs documenting received files with timestamps and checksums

#### For External Raw Data Database:
- **✅ DO:** Store web crawled/scraped data exactly as collected in the `external_raw_data` database
- **❌ NEVER:** Modify scraped data tables once imported
- **✅ DO:** Include metadata about the scraping source, time, and method
- **✅ DO:** Document any issues with scraped data in a separate validation report

#### For Raw Data Database:
- **✅ DO:** Import raw data exactly as received into the `raw_data` database
- **❌ NEVER:** Modify raw data tables once imported
- **✅ DO:** Document any issues with raw data in a separate validation report

### Module0. Web Crawling/Scraping Module

The process of collecting data from web sources is a distinct module:

```
                       ┌─────────────────────────────────┐
External Web  →  Web Crawling/Scraping  →  external_raw_data DB  →  Validation Report
  Sources         (extraction process)     (scraped data preserved)   (document issues)
                       └─────────────────────────────────┘
```

The Web Crawling/Scraping Module:
- Takes web sources (URLs, APIs, etc.) as input
- Extracts data using appropriate techniques (scraping, API calls)
- Records complete metadata about the collection process
- Stores data in unchanged form in the external_raw_data database
- Logs all activities for auditability
- Generates validation reports highlighting any issues
- Includes rate limiting and respectful scraping practices

### Module1.1. Raw Data Import Module

The import process from raw files to the raw_data database is a distinct module:

```
                       ┌─────────────────────────────────┐
External Files → rawdata_[companyname]/ →  Import    →  raw_data Database → Validation Report
            (preserve external raw files)  Module     (raw data preserved)   (document issues)
                       └─────────────────────────────────┘
```

The Import Module:
- Takes raw files from rawdata_[companyname]/ as input
- Validates file checksums to ensure integrity
- Catalogs files with timestamps and metadata
- Imports data in unchanged form into raw_data database
- Logs all activities for auditability
- Generates validation reports highlighting any issues

### Raw Data Verification

When receiving new external raw data:
1. Save the original files to `rawdata_[companyname]/` without modification
2. Calculate checksums to verify file integrity
3. Document the received files with timestamps in the data catalog
4. Import the data as-is into the `raw_data` database
5. Validate the imported data and document any issues
6. Process the data through the established data flow

## 3. Data Cleansing Process

- Data from raw_data should be cleansed into cleansed_data database
- Only standardization and basic cleaning should be performed:
  - Converting data types
  - Standardizing formats (dates, numbers, etc.)
  - Handling missing values
  - Removing duplicates
  - Character encoding standardization
- No business logic or transformations should be applied at this stage
- All cleansing operations must be scripted and reproducible

### Cleansing Process Flow

The cleansing process is also a distinct module:

```
                       ┌─────────────────────────────────┐
raw_data Database  →   │    Cleansing Module    →    cleansed_data Database → Validation Report
 (original data)       │   (standardization)         (cleaned data)        (document actions)
                       └─────────────────────────────────┘
```

The Cleansing Module:
- Reads data from the raw_data database
- Applies standard cleaning operations without business logic
- Standardizes formats, data types, and encodings
- Removes duplicates and handles missing values
- Logs all transformations for reproducibility
- Outputs to the cleansed_data database
- Generates validation reports of changes made

## 4. Database Management

### Schema and Import Process

- Database tables should be created with proper schemas before importing data
- Data validation should occur during the import process, not by changing source files
- When source data errors are found, document them and handle them in processing scripts

### Connection Management

- **IMPORTANT**: All database connections must be managed through 100g_dbConnect_from_list.R
- Never create direct database connections in application code or scripts
- Always close connections using dbDisconnect_all from 103g_dbDisconnect_all.R

### Database Connection Flow

The centralized database connection management ensures:

1. Consistent database paths across the application
2. Proper error handling for connection issues
3. Automatic directory creation when needed
4. Connection tracking for proper cleanup

```
                                         Data Processing Modules
                                         ┌────────────────────┐
                                         │                    │
                                         │   Import Module    │
                                         │                    │
                                         │  Cleansing Module  │
                                         │                    │
                                         │ Processing Module  │
                                         │                    │
                                         └────────────────────┘
                                                  ↑ ↓
                                      Standardized Connections
                                                  ↑ ↓
                                         ┌────────────────────┐
                             ┌─> external_raw_data           │
                             │           │                    │
                             ├─> raw_data│                    │
                             │           │                    │
                             ├─> cleansed_data               │
                             │           │                    │
100g_dbConnect_from_list.R ──┼─> processed_data              │
                             │           │                    │
                             ├─> app_data│                    │
                             │           │                    │
                             ├─> global_scd_type1            │
                             │           │                    │
                             └─> snapshot_data               │
                                         └────────────────────┘
```

### Example Connection Usage

```r
# Import the connection function
source("update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R")
source("update_scripts/global_scripts/02_db_utils/103g_dbDisconnect_all.R")

# Connect to databases
external_raw_data <- dbConnect_from_list("external_raw_data", read_only = TRUE)
raw_data <- dbConnect_from_list("raw_data", read_only = TRUE)
cleansed_data <- dbConnect_from_list("cleansed_data", read_only = FALSE)
snapshot_data <- dbConnect_from_list("snapshot_data", read_only = TRUE)

# Use the connections
scraped_data <- dbGetQuery(external_raw_data, "SELECT * FROM competitor_prices")
raw_table <- dbGetQuery(raw_data, "SELECT * FROM raw_customer_table")
dbExecute(cleansed_data, "CREATE TABLE IF NOT EXISTS cleansed_customer_table (...)")

# Query a specific data snapshot for comparison
historical_data <- dbGetQuery(snapshot_data, 
  "SELECT * FROM customer_weekly_2023_06_10_000000")

# Properly close all connections when done
dbDisconnect_all()
```

## 5. Version Control

- Raw data files should be tracked in version control by path only, not content
- Processing scripts that transform data should be carefully version controlled
- Changes to processing logic must be documented in commit messages

## 6. Reproducibility

- All data processing must be reproducible from raw data sources
- Scripts should be deterministic - the same input should produce the same output
- Processing steps should be logged for audit purposes

## 7. Error Handling

When errors are encountered in raw data:
1. Document the error in a log file
2. Implement appropriate handling in the processing script
3. Never modify the raw data
4. Consider creating a "data issues" document for the project

Remember:
> "Raw data is sacred - our interpretation of it may change, but the original data must remain untouched."

## 8. Slowly Changing Dimension (SCD) Data

The application uses Slowly Changing Dimension (SCD) data to manage reference data and parameters that change at different rates.

### SCD Type 0 - Constant Reference Data

SCD Type 0 data represents reference data that never changes.

#### Location and Contents
- Stored in `/global_scripts/30_global_data/scd_type0/`
- Contains permanent reference data such as:
  - `gz_2010_us_040_00_500k.json`: US state geospatial boundaries
  - `gz_2010_us_050_00_500k.json`: US county geospatial boundaries

#### Usage Principles
- This data is considered immutable and never changes
- Used for geographical references, industry codes, and other standard classifications
- Should be loaded directly from the source files when needed
- All access should be read-only

```r
# Example of loading SCD Type 0 geographical data
us_states <- jsonlite::read_json("global_scripts/30_global_data/scd_type0/gz_2010_us_040_00_500k.json")
```

### SCD Type 1 - Basic Application Parameters

SCD Type 1 data represents parameters where only the current values are needed and historical values are not preserved.

#### Local SCD Type 1 Location and Contents
- Stored in `/precision_marketing_app/app_data/scd_type1/`
- Contains essential app configuration parameters:
  - `product_line.xlsx`: Defines product categories and hierarchies
  - `source.xlsx`: Specifies data sources and their configurations

#### Global SCD Type 1 Database
- Stored in `/global_scripts/30_global_data/global_scd_type1.duckdb`
- Contains shared reference data used across multiple applications
- Provides standardized lookup tables for common dimensions

#### Usage Principles
- These files contain basic parameters critical for app functionality
- When values change, the entire record is replaced (no history is preserved)
- Updates to these files should be carefully tracked in version control
- All access to this data should use read-only connections
- Use the standardized connection methods:

```r
# Load local SCD Type 1 data
product_line <- readxl::read_excel("app_data/scd_type1/product_line.xlsx")
sources <- readxl::read_excel("app_data/scd_type1/source.xlsx")

# Connect to global SCD Type 1 database
source("update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R")
global_scd <- dbConnect(duckdb::duckdb(), 
                       "global_scripts/30_global_data/global_scd_type1.duckdb", 
                       read_only = TRUE)

# Query global reference data
standard_regions <- dbGetQuery(global_scd, "SELECT * FROM standard_regions")
dbDisconnect(global_scd)
```

### SCD Type 2 - Historical Parameter Changes

SCD Type 2 data represents parameters where the history of changes must be preserved.

#### Location and Usage
- Stored in `/precision_marketing_app/app_data/scd_type2/`
- Used for parameters where change history is important
- Each record contains effective date ranges (start_date and end_date)
- For any given date, only one record should be active

#### Implementation
- Always include date range columns (start_date, end_date)
- When a parameter changes, create a new record with updated values
- Set the end_date of the old record and the start_date of the new record
- Ensure no date range gaps or overlaps for the same parameter

#### Querying SCD Type 2 Data
```r
# Example of querying SCD Type 2 data for a specific date
effective_parameters <- function(parameter_table, query_date = Sys.Date()) {
  parameter_table %>%
    filter(start_date <= query_date, 
           (is.na(end_date) | end_date >= query_date))
}
```

## 9. Data Snapshots

The application uses a snapshot system to create point-in-time copies of critical data for auditing, error recovery, and historical analysis purposes.

### Snapshot Database

- Stored in DuckDB `snapshot_data` database
- Contains read-only, timestamped copies of data at specific points in time
- Provides ability to recover from errors and track data evolution

### Snapshot Types and Frequency

#### Regular Scheduled Snapshots
- **Daily Snapshots**: Created daily for critical operational tables
- **Weekly Snapshots**: Full system snapshots taken weekly
- **Monthly Snapshots**: Complete system snapshots preserved for a minimum of 12 months

#### Special Event Snapshots
- **Pre-Update Snapshots**: Taken immediately before major updates or data migrations
- **Post-Processing Snapshots**: Taken after completion of ETL processes
- **Milestone Snapshots**: Taken at significant business milestones

### Snapshot Naming Convention

All snapshots follow a standardized naming convention:
```
{table_name}_{snapshot_type}_{YYYY_MM_DD_HHMMSS}
```

For example:
- `customer_daily_2023_06_15_080000`
- `sales_analysis_pre_update_2023_06_14_235959`
- `complete_monthly_2023_06_01_000000`

### Snapshot Access and Usage

Snapshots are read-only and should never be modified. They serve multiple purposes:

1. **Data Recovery**: Ability to restore data to a previous state if errors occur
2. **Audit Trail**: Historical record of data state at specific points in time
3. **Trend Analysis**: Ability to compare data across different time periods
4. **Troubleshooting**: Insight into data state before and after issues arose

```r
# Example of querying a specific snapshot
source("update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R")
snapshot_db <- dbConnect_from_list("snapshot_data", read_only = TRUE)

# Get data from a specific snapshot
historical_data <- dbGetQuery(snapshot_db, 
  "SELECT * FROM customer_daily_2023_06_15_080000")

# Compare with current data
current_data <- dbGetQuery(app_data, "SELECT * FROM customer")
comparison <- compare_datasets(historical_data, current_data)

dbDisconnect_all()
```

### Snapshot Retention Policy

- Daily snapshots: Retained for 30 days
- Weekly snapshots: Retained for 90 days
- Monthly snapshots: Retained for 12 months
- Pre-update and milestone snapshots: Retained for 24 months

### Creating Snapshots

Snapshots should be created using the standardized snapshot functions:

```r
# Create a snapshot of a specific table
create_table_snapshot <- function(db_connection, table_name, snapshot_type = "manual") {
  timestamp <- format(Sys.time(), "%Y_%m_%d_%H%M%S")
  snapshot_name <- paste0(table_name, "_", snapshot_type, "_", timestamp)
  
  # Connect to snapshot database
  snapshot_db <- dbConnect_from_list("snapshot_data", read_only = FALSE)
  
  # Create the snapshot
  dbExecute(snapshot_db, sprintf(
    "CREATE TABLE %s AS SELECT * FROM %s", 
    snapshot_name, table_name
  ))
  
  # Log the snapshot creation
  log_snapshot_creation(table_name, snapshot_type, timestamp)
  
  dbDisconnect(snapshot_db)
  return(snapshot_name)
}
```