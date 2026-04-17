# L4 Enterprise

Enterprise-level AI MarTech applications for large organizations.

## Current Applications

| Company | Path | Status | Description |
|---------|------|--------|-------------|
| D_RACING | `D_RACING/` | Active | 技詮賽車精品 — 精準行銷儀表板 |
| MAMBA | `MAMBA/` | Active | MAMBA 精準行銷平台 |
| QEF_DESIGN | `QEF_DESIGN/` | Active | 向創設計精準行銷平台 |
| URBANER | `URBANER/` | Active | 奧本電剪精準行銷平台 |
| WISER | `WISER/` | Active | WISER 精準行銷平台（原始模板） |
| kitchenMAMA | `kitchenMAMA/` | Active | 美食鍋精準行銷平台 |

### Feature Development Reference

新功能開發時，應參考 **kitchenMAMA (KM)** 的舊版精準行銷專案，該專案包含許多尚未移植到現行架構的功能模組：

- **位置**: `kitchenMAMA/archive/precision_marketing_KitchenMAMA/`
- **關鍵參考檔案**:
  - `precision_marketing_app_modular/R/modules/macro/macro_awakening_matrix.R` — NES 覺醒率轉換矩陣
  - `precision_marketing_app/survival_analysis_app/modules/survival_analysis_module.R` — KM + Cox PH 生存分析（862 行）
- 詳見 `CLAUDE.md` 的 KM Legacy Reference 區塊

## Building New Enterprise Applications

### Architecture Overview

L4 Enterprise applications follow a standardized architecture pattern based on the WISER template. Each application includes:

- **Modular Components**: Micro/Macro/Position analysis modules
- **Configuration-Driven**: YAML-based application settings
- **Universal Data Access**: tbl2() pattern for database operations
- **Principle-Based**: 257+ documented principles (MP-P-R system)
- **Component Library**: 30+ reusable Shiny components

### Quick Start for New Projects

**Prerequisites:**
- GitHub CLI installed (`brew install gh` on macOS)
- GitHub CLI authenticated (`gh auth login`)

**Important Note on Naming:**
- Company names are **proper nouns** - preserve exact capitalization (e.g., QEF_DESIGN, not qef_design)
- This applies to directory names, especially `rawdata_[COMPANY_NAME]`
- Repository names follow GitHub convention (lowercase with hyphens)

#### Step 1: Copy Complete WISER Template
```bash
# Create new project by copying complete WISER structure
cp -r l4_enterprise/WISER l4_enterprise/NEW_PROJECT_NAME
cd l4_enterprise/NEW_PROJECT_NAME

# Keep all data files as reference for now
# We'll handle data cleanup in Step 4 after configuration
echo "✅ WISER template copied with all reference data intact"

# Clear only the company-specific ETL scripts
rm -rf scripts/update_scripts/*
# Keep the directory structure for new ETL scripts
mkdir -p scripts/update_scripts/import
mkdir -p scripts/update_scripts/stage
mkdir -p scripts/update_scripts/transform
mkdir -p scripts/update_scripts/process

echo "✅ ETL scripts directory structure prepared"
```

#### Step 2: Setup Git Repository and Subrepos
```bash
# Remove copied Git subrepo metadata
rm -rf scripts/global_scripts/.git*
rm -rf scripts/update_scripts/.git*
rm -f scripts/global_scripts/.gitrepo
rm -f scripts/update_scripts/.gitrepo

# Initialize new Git repository
git init
git remote add origin git@github.com:your-org/NEW_PROJECT_NAME.git

# Reinitialize global_scripts subrepo
git subrepo clone ../../global_scripts scripts/global_scripts

# Option 1: If update_scripts is a separate subrepo
# Create new repository first: https://github.com/your-org/NEW_PROJECT_update_scripts
# git subrepo clone git@github.com:your-org/NEW_PROJECT_update_scripts.git scripts/update_scripts

# Option 2: If update_scripts is regular directory (recommended for new projects)
# Keep as regular directory structure (already created in Step 1)
```

#### Step 3: Interactive Application Configuration

This step will guide you through configuring your application by reviewing and customizing the copied `app_config.yaml` file. We'll go through each section systematically.

**Interactive Configuration Process:**

Open the `app_config.yaml` file in your project directory and follow these guided questions:

##### 3.1 Basic Application Information
```yaml
# Current WISER settings:
app:
  name: "WISER Enterprise Platform"           # ← Change this to your company name
  version: "1.0.0"                           # ← Keep or update version
  tier: "l4_enterprise"                      # ← Keep as l4_enterprise
  description: "Complete precision marketing solution for enterprise clients"  # ← Update description

brand_name: "WISER"                          # ← Change to your company/brand name
language: "zh_TW.UTF-8"                     # ← Change if needed (en_US.UTF-8 for English)
```

**Questions to ask yourself:**
- What is your company/application name?
- What brand name should appear in the UI?
- What language do you need? (zh_TW.UTF-8 for Traditional Chinese, en_US.UTF-8 for English)

##### 3.2 Data Sources Configuration
```yaml
# Current WISER settings:
RAW_DATA_DIR: "./data/local_data/rawdata_WISER"  # ← Change to your raw data directory
parameters_folder: "default"                     # ← Usually keep as "default"

platform:                                       # ← Select your sales platforms
  - amz                                         # Amazon
  - officialwebsite                            # Official website
  # Other options: eby (eBay), sho (Shopify), cyb (Cyberbiz)
```

**Questions to ask yourself:**
- Where is your raw data stored? (Change the directory path)
- Which sales platforms do you use?
  - `amz` for Amazon
  - `eby` for eBay  
  - `officialwebsite` for official website
  - `sho` for Shopify
  - `cyb` for Cyberbiz
  - Or add custom platform identifiers

##### 3.3 Google Sheets Integration
```yaml
# Current WISER settings:
googlesheet:
  product_profile: "16-k48xxFzSZm2p8j9SZf4V041fldcYnR8ectjsjuxZQ"    # ← Your product profile sheet ID
  comment_property: "168GviZntUk2u12Agjh6Mi1yBMpNY-SQDT4y9p71QQ74"   # ← Your comment property sheet ID
```

**Questions to ask yourself:**
- Do you have Google Sheets with product profiles? (Extract ID from the URL)
- Do you have Google Sheets with comment properties? (Extract ID from the URL)
- Google Sheet ID is the long string in the URL: `https://docs.google.com/spreadsheets/d/[ID_HERE]/edit`

##### 3.4 Component Selection
```yaml
# Current WISER settings - customize based on your needs:
components:
  micro:                                       # ← Customer-level analysis
    microCustomer:
      primary: customer_details               # ← Your customer data table name
      history: customer_history               # ← Your customer history table name
    sales: sales_by_customer_dta             # ← Your sales data table name
  
  macro:                                      # ← Market trend analysis  
    trends:
      data_source: sales_trends               # ← Your trend data source
      parameters:
        show_kpi: true                        # ← Show KPI indicators?
        refresh_interval: 300                 # ← Refresh every 5 minutes
```

**Questions to ask yourself:**
- **Do you need customer-level analysis?** (microCustomer component)
  - What are your customer data table names?
  - Do you need RFM analysis, customer DNA, segmentation?
  
- **Do you need market trend analysis?** (macro trends component)
  - What is your sales trend data source?
  - Do you want to show KPI indicators?
  - How often should data refresh? (300 = 5 minutes)

- **Do you need brand positioning analysis?** (Add if needed)
  ```yaml
  position:
    positionAnalysis:
      enabled: true
      data_source: position_data
      features: ["competitive", "positioning", "share"]
  ```

- **Do you need statistical modeling?** (Add if needed)
  ```yaml
  poisson:
    poissonAnalysis:
      enabled: true
      data_source: event_data
      features: ["modeling", "prediction", "events"]
  ```

##### 3.5 Deployment Configuration
```yaml
# Current WISER settings:
deployment:
  target: "posit_connect"                     # ← Keep as posit_connect
  url: "https://connect.posit.cloud"          # ← Usually keep the same
  account_name: "kyle-lin"                    # ← Change to your Posit Connect account
  app_name: "wiser-enterprise"                # ← Change to your app name (lowercase, hyphens)
  app_id: "wiser-enterprise"                  # ← Usually same as app_name
  title: "WISER Enterprise Platform"          # ← Change to your app title (display name)
```

**Questions to ask yourself:**
- What is your Posit Connect account name?
- What should your app be called? (Use lowercase with hyphens for app_name)
- What is the display title for your application?

##### 3.6 Environment Variables Setup
```bash
# Create .env file in your project root with:
OPENAI_API_KEY=your_openai_api_key_here
PGHOST=your_database_host
PGPORT=5432
PGUSER=your_database_user
PGPASSWORD=your_database_password
PGDATABASE=your_database_name
PGSSLMODE=require
```

**Questions to ask yourself:**
- Do you have an OpenAI API key for AI features?
- What are your database connection details?
- Do you need other environment variables?

##### 3.7 Theme and UI Configuration
```yaml
# Current WISER settings:
theme:
  version: 5                                  # ← Keep as 5 for Bootstrap 5
  bootswatch: cosmo                          # ← Change theme if desired
layout: navbar                              # ← Keep as navbar
```

**Available bootswatch themes:**
- `cosmo` (current) - Clean, modern blue theme
- `flatly` - Flat, modern design
- `united` - Orange accents, Ubuntu font
- `cerulean` - Blue gradient theme
- `journal` - Newspaper-style theme
- `readable` - High contrast, readable theme

**Quick Configuration Script:**
```bash
# You can create a simple script to help with configuration:
echo "Let's configure your app_config.yaml step by step..."
echo "Current app name: $(grep 'name:' app_config.yaml | head -1)"
echo "Do you want to change it? (y/n)"
# ... continue with other settings
```

**Final Checklist:**
- [ ] Updated app name and brand_name
- [ ] Configured data directory paths
- [ ] Selected appropriate platforms
- [ ] Added Google Sheets IDs (if applicable)
- [ ] Configured components based on analysis needs
- [ ] Set up deployment settings
- [ ] Created .env file with required variables
- [ ] Chosen appropriate theme

#### Step 4: Setup Data Pipeline and Clean Reference Data

Now that your application is configured, let's set up your data pipeline and replace WISER's reference data with your own.

##### 4.1 Review WISER Data Structure
```bash
# First, examine the WISER data structure to understand the pattern
ls -la data/
# You should see:
# data/app_data/               - Application-ready data
# data/database_to_csv/        - Database export files (raw/staged/transformed/processed)
# data/local_data/             - Local data files including rawdata_WISER
```

##### 4.2 Rename Company-Specific Data Directory
```bash
# Interactive setup - get your company name
echo "🏢 Setting up company-specific data directory..."
echo "Current raw data directory: data/local_data/rawdata_WISER"
echo ""
echo "Enter your company name (will be used for rawdata directory):"
read -p "Company name: " COMPANY_NAME

# Validate company name
if [ -z "$COMPANY_NAME" ]; then
    echo "❌ Company name cannot be empty. Please run this step again."
    exit 1
fi

# IMPORTANT: Keep company name as-is for directory (it's a proper noun)
# Only convert for GitHub repository name
SAFE_COMPANY_NAME_FOR_REPO=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g')

echo "Company name: $COMPANY_NAME"
echo "Directory name: rawdata_$COMPANY_NAME"  # Keep proper noun capitalization
echo ""
echo "This will:"
echo "1. Rename data/local_data/rawdata_WISER to data/local_data/rawdata_$COMPANY_NAME"
echo "2. Update app_config.yaml RAW_DATA_DIR setting"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Rename the directory (keeping proper noun capitalization)
    mv data/local_data/rawdata_WISER data/local_data/rawdata_$COMPANY_NAME
    
    # Update app_config.yaml
    sed -i '' "s|RAW_DATA_DIR: \"./data/local_data/rawdata_WISER\"|RAW_DATA_DIR: \"./data/local_data/rawdata_$COMPANY_NAME\"|g" app_config.yaml
    
    echo "✅ Data directory renamed and configuration updated"
    echo "✅ New raw data directory: data/local_data/rawdata_$COMPANY_NAME"
    
    # Verify the change
    echo "📋 Verification:"
    echo "Directory exists: $([ -d "data/local_data/rawdata_$COMPANY_NAME" ] && echo "✅ YES" || echo "❌ NO")"
    echo "Config updated: $(grep -c "rawdata_$COMPANY_NAME" app_config.yaml > 0 && echo "✅ YES" || echo "❌ NO")"
else
    echo "❌ Operation cancelled. Keeping original WISER directory."
fi
```

##### 4.3 Choose Data Handling Strategy
```bash
# Let user choose how to handle WISER reference data
echo "🎯 Choose your data handling strategy:"
echo ""
echo "1. Keep WISER data as reference (recommended for learning)"
echo "   - Rename existing data folders to include '_WISER_reference'"
echo "   - Create new empty directories for your data"
echo "   - You can study WISER's data structure while building your own"
echo ""
echo "2. Clean all WISER data (start fresh)"
echo "   - Remove all WISER data files completely"
echo "   - Keep only directory structure"
echo "   - Faster setup but no reference data"
echo ""
read -p "Enter your choice (1 or 2): " -n 1 -r
echo
case $REPLY in
    1)
        echo "📚 Keeping WISER data as reference..."
        
        # Rename WISER data in database_to_csv to include reference suffix
        cd data/database_to_csv/
        for dir in raw_data staged_data transformed_data processed_data app_data; do
            if [ -d "$dir" ]; then
                mv "$dir" "${dir}_WISER_reference"
                mkdir "$dir"
                echo "✅ Renamed $dir to ${dir}_WISER_reference and created new empty $dir"
            fi
        done
        cd ../..
        
        # Create backup of rawdata content
        RAWDATA_DIR=$(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
        if [ -d "$RAWDATA_DIR" ]; then
            echo "📋 WISER rawdata preserved in: $RAWDATA_DIR"
            echo "📋 You can study its structure: amazon_sales/, amazon_reviews/, competitor_sales/"
        fi
        
        echo "✅ Reference data preserved, new empty directories created"
        ;;
    2)
        echo "🧹 Cleaning all WISER data..."
        
        # Clear rawdata directory contents
        RAWDATA_DIR=$(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
        if [ -d "$RAWDATA_DIR" ]; then
            rm -rf "$RAWDATA_DIR"/*
            echo "✅ Cleared rawdata directory: $RAWDATA_DIR"
        fi
        
        # Clear database_to_csv directories
        cd data/database_to_csv/
        for dir in raw_data staged_data transformed_data processed_data app_data; do
            if [ -d "$dir" ]; then
                rm -rf "$dir"/*
                echo "✅ Cleared $dir"
            fi
        done
        cd ../..
        
        # Clear app_data
        rm -rf data/app_data/*
        
        # Remove specific file types
        find data/ -name "*.duckdb" -delete
        find data/ -name "*.csv" -delete
        find data/ -name "*.xlsx" -delete
        find data/ -name "*.rds" -delete
        find data/ -name "*.parquet" -delete
        
        echo "✅ All WISER data cleaned"
        ;;
    *)
        echo "❌ Invalid choice. Please run this step again."
        exit 1
        ;;
esac
```

##### 4.4 Initialize Your Data Pipeline
```bash
# Create your own empty DuckDB databases for each stage
echo "🔧 Initializing data pipeline structure..."

# Create DuckDB databases in database_to_csv directories
touch data/database_to_csv/raw_data/raw_data.duckdb
touch data/database_to_csv/staged_data/staged_data.duckdb
touch data/database_to_csv/transformed_data/transformed_data.duckdb
touch data/database_to_csv/processed_data/processed_data.duckdb
touch data/database_to_csv/app_data/app_data.duckdb

# Create platform-specific directories in your rawdata directory
RAWDATA_DIR=$(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
if [ -d "$RAWDATA_DIR" ]; then
    echo "📁 Creating platform-specific directories in: $RAWDATA_DIR"
    
    # Check Step 3 configuration for platforms
    if grep -q "amz" app_config.yaml; then
        mkdir -p "$RAWDATA_DIR/amazon_sales"
        mkdir -p "$RAWDATA_DIR/amazon_reviews"
        mkdir -p "$RAWDATA_DIR/amazon_demographic"
        echo "✅ Created Amazon data directories"
    fi
    
    if grep -q "eby" app_config.yaml; then
        mkdir -p "$RAWDATA_DIR/ebay_sales"
        mkdir -p "$RAWDATA_DIR/ebay_reviews"
        echo "✅ Created eBay data directories"
    fi
    
    if grep -q "officialwebsite" app_config.yaml; then
        mkdir -p "$RAWDATA_DIR/official_sales"
        mkdir -p "$RAWDATA_DIR/official_orders"
        echo "✅ Created official website data directories"
    fi
    
    if grep -q "sho" app_config.yaml; then
        mkdir -p "$RAWDATA_DIR/shopify_sales"
        mkdir -p "$RAWDATA_DIR/shopify_orders"
        echo "✅ Created Shopify data directories"
    fi
    
    if grep -q "cyb" app_config.yaml; then
        mkdir -p "$RAWDATA_DIR/cyberbiz_sales"
        mkdir -p "$RAWDATA_DIR/cyberbiz_orders"
        echo "✅ Created Cyberbiz data directories"
    fi
    
    # Create common directories regardless of platform
    mkdir -p "$RAWDATA_DIR/competitor_sales"
    mkdir -p "$RAWDATA_DIR/product_info"
    echo "✅ Created common data directories"
fi

echo "✅ Data pipeline structure initialized"
```

##### 4.5 Configure ETL Scripts
```bash
# Copy and modify WISER ETL scripts as templates for your data sources
echo "📝 Setting up ETL scripts..."

# Create ETL scripts based on your configured platforms
RAWDATA_DIR=$(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)

# Check if we kept WISER reference data to use as templates
if [ -d "../WISER/scripts/update_scripts/import" ]; then
    echo "📋 WISER ETL scripts available as templates in: ../WISER/scripts/update_scripts/import"
    echo "💡 You can copy and modify these scripts for your data sources"
    echo ""
    ls -la ../WISER/scripts/update_scripts/import/
    echo ""
    echo "Example commands to copy templates:"
    
    if grep -q "amz" app_config.yaml; then
        echo "# For Amazon:"
        echo "cp ../WISER/scripts/update_scripts/import/*amazon* scripts/update_scripts/import/"
    fi
    
    if grep -q "eby" app_config.yaml; then
        echo "# For eBay:"
        echo "cp ../WISER/scripts/update_scripts/import/*ebay* scripts/update_scripts/import/"
    fi
    
    if grep -q "officialwebsite" app_config.yaml; then
        echo "# For official website:"
        echo "cp ../WISER/scripts/update_scripts/import/*official* scripts/update_scripts/import/"
    fi
fi

# Create comprehensive ETL documentation
cat > scripts/update_scripts/README.md << EOF
# ETL Pipeline Documentation

## Directory Structure
- \`import/\` - Data import scripts (external sources → raw data)
- \`stage/\` - Data staging scripts (raw data → staged data)
- \`transform/\` - Data transformation scripts (staged data → transformed data)
- \`process/\` - Data processing scripts (transformed data → processed data)

## Data Flow
1. **Import**: Raw data from external sources → \`${RAWDATA_DIR}/\`
2. **Stage**: Raw data → \`data/database_to_csv/staged_data/\`
3. **Transform**: Staged data → \`data/database_to_csv/transformed_data/\`
4. **Process**: Transformed data → \`data/database_to_csv/processed_data/\`
5. **App Data**: Processed data → \`data/database_to_csv/app_data/\`

## Platform-Specific Guidelines

### Amazon (amz)
- Sales data: \`${RAWDATA_DIR}/amazon_sales/\`
- Reviews data: \`${RAWDATA_DIR}/amazon_reviews/\`
- Demographic data: \`${RAWDATA_DIR}/amazon_demographic/\`

### eBay (eby)
- Sales data: \`${RAWDATA_DIR}/ebay_sales/\`
- Reviews data: \`${RAWDATA_DIR}/ebay_reviews/\`

### Official Website (officialwebsite)
- Sales data: \`${RAWDATA_DIR}/official_sales/\`
- Orders data: \`${RAWDATA_DIR}/official_orders/\`

### Common Data
- Competitor sales: \`${RAWDATA_DIR}/competitor_sales/\`
- Product info: \`${RAWDATA_DIR}/product_info/\`

## Script Naming Convention
- \`import_[platform]_[datatype].R\` - Import scripts
- \`stage_[platform]_[datatype].R\` - Staging scripts  
- \`transform_[datatype].R\` - Transformation scripts
- \`process_[datatype].R\` - Processing scripts

## Development Notes
- Update \`RAW_DATA_DIR\` in app_config.yaml: \`${RAWDATA_DIR}\`
- Use \`global_scripts/\` functions for common operations
- Follow DuckDB patterns for data storage
- Implement error handling and logging
EOF

# Create individual stage directories with placeholder files
echo "📁 Creating ETL stage directories..."
mkdir -p scripts/update_scripts/import
mkdir -p scripts/update_scripts/stage
mkdir -p scripts/update_scripts/transform
mkdir -p scripts/update_scripts/process

# Create placeholder files for each stage
cat > scripts/update_scripts/import/README.md << 'EOF'
# Import Scripts

Place your data import scripts here. These scripts read raw data from external sources and save to the rawdata directory.

Example scripts:
- import_amazon_sales.R
- import_ebay_sales.R
- import_official_orders.R
EOF

cat > scripts/update_scripts/stage/README.md << 'EOF'
# Stage Scripts

Place your data staging scripts here. These scripts clean and validate raw data.

Example scripts:
- stage_amazon_sales.R
- stage_ebay_sales.R
- stage_official_orders.R
EOF

cat > scripts/update_scripts/transform/README.md << 'EOF'
# Transform Scripts

Place your data transformation scripts here. These scripts apply business logic and calculations.

Example scripts:
- transform_sales_data.R
- transform_customer_data.R
- transform_product_data.R
EOF

cat > scripts/update_scripts/process/README.md << 'EOF'
# Process Scripts

Place your data processing scripts here. These scripts create application-ready data.

Example scripts:
- process_customer_dna.R
- process_rfm_analysis.R
- process_trend_analysis.R
EOF

echo "✅ ETL scripts structure and documentation created"
```

##### 4.6 Test Data Pipeline Structure
```bash
# Test that your data pipeline structure is correct
echo "🔍 Testing data pipeline structure..."

# Get current RAW_DATA_DIR from configuration
RAWDATA_DIR=$(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)

echo "📋 Data Pipeline Structure Verification:"
echo "=================================="
echo ""

# Check main data directories
echo "Main data directories:"
find data/ -maxdepth 1 -type d | sort

echo ""
echo "Database files:"
find data/ -name "*.duckdb" | sort

echo ""
echo "Raw data directory structure:"
if [ -d "$RAWDATA_DIR" ]; then
    echo "✅ Raw data directory exists: $RAWDATA_DIR"
    find "$RAWDATA_DIR" -type d | sort
else
    echo "❌ Raw data directory not found: $RAWDATA_DIR"
fi

echo ""
echo "ETL scripts structure:"
find scripts/update_scripts/ -type d | sort

echo ""
echo "Configuration verification:"
echo "RAW_DATA_DIR: $(grep "RAW_DATA_DIR" app_config.yaml)"
echo "Platforms: $(grep -A 5 "platform:" app_config.yaml | grep -E "^\s*-" | tr -d '- ')"

echo ""
echo "✅ Data pipeline structure verified"
```

##### 4.7 Create Data Pipeline Summary
```bash
# Create a summary of your data pipeline setup
echo "📄 Creating data pipeline summary..."

cat > data_pipeline_summary.md << EOF
# Data Pipeline Summary

## Configuration
- **Company**: $(grep "brand_name" app_config.yaml | cut -d'"' -f2)
- **Raw Data Directory**: $(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
- **Platforms**: $(grep -A 5 "platform:" app_config.yaml | grep -E "^\s*-" | tr -d '- ' | paste -sd ',' -)

## Directory Structure
\`\`\`
data/
├── app_data/                    # Application-ready data
├── database_to_csv/             # ETL pipeline databases
│   ├── raw_data/               # Raw data stage
│   ├── staged_data/            # Staged data stage
│   ├── transformed_data/       # Transformed data stage
│   ├── processed_data/         # Processed data stage
│   └── app_data/               # Final app data stage
└── local_data/                 # Local data storage
    └── rawdata_[company]/      # Company-specific raw data
\`\`\`

## ETL Pipeline
1. **Import**: External sources → rawdata_[company]/
2. **Stage**: Raw data → staged_data/
3. **Transform**: Staged data → transformed_data/
4. **Process**: Transformed data → processed_data/
5. **App Data**: Processed data → app_data/

## Next Steps
1. Add your actual data files to the rawdata directory
2. Create or modify ETL scripts in scripts/update_scripts/
3. Test the data pipeline with sample data
4. Configure database connections in .env file
5. Run the application to verify data flow

## Important Files
- \`app_config.yaml\` - Main configuration file
- \`scripts/update_scripts/README.md\` - ETL documentation
- \`.env\` - Environment variables (create if needed)
- \`data_pipeline_summary.md\` - This summary file
EOF

echo "✅ Data pipeline summary created: data_pipeline_summary.md"
```

**Data Pipeline Checklist:**
- [ ] Reviewed WISER data structure
- [ ] Renamed rawdata directory to company-specific name
- [ ] Chose data handling strategy (keep reference vs clean)
- [ ] Initialized data pipeline structure
- [ ] Created platform-specific directories
- [ ] Set up ETL scripts structure and documentation
- [ ] Verified data pipeline structure
- [ ] Created data pipeline summary document

#### Step 5: GitHub Repository Setup and Initial Commit

Now let's set up the GitHub repository and make the initial commit for your new L3 Enterprise application.

##### 5.1 Prepare GitHub Repository
```bash
# Get company name from configuration for repository naming
COMPANY_NAME=$(grep "brand_name" app_config.yaml | cut -d'"' -f2)
# Only convert to lowercase for GitHub repo name (not for directories)
SAFE_COMPANY_NAME_FOR_REPO=$(echo "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g')
REPO_NAME="ai_martech_l3_app_${SAFE_COMPANY_NAME_FOR_REPO}"

echo "🔗 GitHub Repository Setup"
echo "========================="
echo "Company: $COMPANY_NAME"
echo "Repository name: $REPO_NAME"
echo "Expected repository URL: git@github.com:kiki830621/${REPO_NAME}.git"
echo ""

# Option 1: Automatic creation using GitHub CLI (recommended)
echo "📋 Option 1: Automatic creation with GitHub CLI"
echo "------------------------------------------------"
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI detected. Creating repository automatically..."
    
    # Create private repository using GitHub CLI
    gh repo create kiki830621/${REPO_NAME} \
        --private \
        --description "L3 Enterprise AI MarTech application for $COMPANY_NAME" \
        --clone=false
    
    if [ $? -eq 0 ]; then
        echo "✅ Repository created successfully!"
    else
        echo "⚠️  Repository might already exist or creation failed."
        echo "Continuing with existing repository..."
    fi
else
    echo "❌ GitHub CLI not installed."
    echo "Install it with: brew install gh"
    echo "Then authenticate with: gh auth login"
fi

echo ""
echo "📋 Option 2: Manual creation (if GitHub CLI is not available)"
echo "-------------------------------------------------------------"
echo "1. Go to https://github.com/kiki830621"
echo "2. Create a new repository named: $REPO_NAME"
echo "3. Make it private (recommended for enterprise applications)"
echo "4. Do NOT initialize with README, .gitignore, or license"
echo ""

# Confirm repository exists before proceeding
read -p "Repository ready? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please ensure the repository exists, then run this step again."
    exit 1
fi
```

##### 5.2 Update Remote Origin
```bash
# Update the remote origin to point to your new repository
echo "🔄 Updating Git remote origin..."

# Remove existing remote if it exists
git remote remove origin 2>/dev/null || true

# Add new remote
git remote add origin git@github.com:kiki830621/${REPO_NAME}.git

# Verify remote was added correctly
echo "✅ Remote origin updated:"
git remote -v
```

##### 5.3 Prepare Initial Commit
```bash
# Prepare files for initial commit
echo "📝 Preparing initial commit..."

# Create .gitignore file appropriate for L3 Enterprise applications
cat > .gitignore << 'EOF'
# Environment variables
.env
.env.local
.env.production

# Data files
data/local_data/rawdata_*/
data/database_to_csv/*/
data/app_data/
*.duckdb
*.csv
*.xlsx
*.rds
*.parquet

# R specific
.Rproj.user/
.Rhistory
.RData
.Ruserdata
rsconnect/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Node modules (if any)
node_modules/

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
EOF

# Create initial README for the repository
cat > README.md << EOF
# $COMPANY_NAME L3 Enterprise Application

This is an L3 Enterprise-level AI MarTech application based on the WISER template.

## Application Information
- **Company**: $COMPANY_NAME
- **Tier**: L3 Enterprise
- **Raw Data Directory**: $(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
- **Platforms**: $(grep -A 5 "platform:" app_config.yaml | grep -E "^\s*-" | tr -d '- ' | paste -sd ',' -)

## Quick Start
\`\`\`bash
# Install dependencies
# Add your R package installation commands here

# Set up environment variables
cp .env.example .env
# Edit .env file with your credentials

# Run the application
Rscript app.R
\`\`\`

## Data Pipeline
See \`data_pipeline_summary.md\` for detailed information about the data pipeline structure.

## ETL Scripts
ETL scripts are organized in \`scripts/update_scripts/\`:
- \`import/\` - Data import scripts
- \`stage/\` - Data staging scripts
- \`transform/\` - Data transformation scripts
- \`process/\` - Data processing scripts

## Configuration
- \`app_config.yaml\` - Main application configuration
- \`.env\` - Environment variables (not committed)

## Deployment
This application is configured for deployment to Posit Connect.
See \`app_config.yaml\` for deployment settings.

---
Generated from WISER L3 Enterprise template
EOF

# Create .env.example for reference
cat > .env.example << 'EOF'
# OpenAI API Key
OPENAI_API_KEY=your_openai_api_key_here

# Database Configuration
PGHOST=your_database_host
PGPORT=5432
PGUSER=your_database_user
PGPASSWORD=your_database_password
PGDATABASE=your_database_name
PGSSLMODE=require

# Optional: Additional environment variables
# Add any other environment variables your application needs
EOF

echo "✅ Initial files prepared"
```

##### 5.4 Create Initial Commit
```bash
# Add all files to staging
echo "📦 Creating initial commit..."

git add .
git status

# Create initial commit
git commit -m "Initial L3 Enterprise application setup for $COMPANY_NAME

- Copied from WISER template
- Updated company branding and configuration
- Set up data pipeline structure
- Configured ETL scripts framework
- Ready for data integration and customization

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✅ Initial commit created"
```

##### 5.5 Push to GitHub
```bash
# Push to GitHub
echo "🚀 Pushing to GitHub..."

# Push to main branch
git push -u origin main

# Verify push was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully pushed to GitHub!"
    echo "📍 Repository URL: https://github.com/kiki830621/${REPO_NAME}"
    echo "📍 Clone URL: git@github.com:kiki830621/${REPO_NAME}.git"
else
    echo "❌ Failed to push to GitHub. Please check:"
    echo "1. SSH keys are configured correctly"
    echo "2. Repository exists and is accessible"
    echo "3. You have write permissions to the repository"
    exit 1
fi
```

##### 5.6 Create Project Summary
```bash
# Create final project summary
echo "📋 Creating project summary..."

cat > project_setup_summary.md << EOF
# $COMPANY_NAME L3 Enterprise Application Setup Summary

## Project Information
- **Project Name**: $COMPANY_NAME L3 Enterprise Application
- **Repository**: git@github.com:kiki830621/${REPO_NAME}.git
- **Setup Date**: $(date '+%Y-%m-%d %H:%M:%S')
- **Template**: WISER L3 Enterprise

## Configuration Summary
- **Company**: $COMPANY_NAME
- **Application Name**: $(grep "name:" app_config.yaml | head -1 | cut -d'"' -f2)
- **Version**: $(grep "version:" app_config.yaml | cut -d'"' -f2)
- **Language**: $(grep "language:" app_config.yaml | cut -d'"' -f2)
- **Theme**: $(grep "bootswatch:" app_config.yaml | cut -d' ' -f2)

## Data Configuration
- **Raw Data Directory**: $(grep "RAW_DATA_DIR" app_config.yaml | cut -d'"' -f2)
- **Platforms**: $(grep -A 5 "platform:" app_config.yaml | grep -E "^\s*-" | tr -d '- ' | paste -sd ',' -)

## Deployment Configuration
- **Target**: $(grep "target:" app_config.yaml | cut -d'"' -f2)
- **Account**: $(grep "account_name:" app_config.yaml | cut -d'"' -f2)
- **App Name**: $(grep "app_name:" app_config.yaml | cut -d'"' -f2)

## Next Steps
1. Add your actual data files to the rawdata directory
2. Configure .env file with your credentials
3. Develop or modify ETL scripts in scripts/update_scripts/
4. Test the application with your data
5. Deploy to Posit Connect
6. Set up automated data pipeline

## Important Files
- \`app_config.yaml\` - Main configuration
- \`data_pipeline_summary.md\` - Data pipeline documentation
- \`project_setup_summary.md\` - This summary
- \`README.md\` - Repository README
- \`.env.example\` - Environment variables template

## Support
- Original WISER template: l4_enterprise/WISER/
- Global scripts: scripts/global_scripts/
- Principles documentation: scripts/global_scripts/00_principles/
EOF

echo "✅ Project summary created: project_setup_summary.md"
echo ""
echo "🎉 L3 Enterprise application setup complete!"
echo "📍 Repository: https://github.com/kiki830621/${REPO_NAME}"
echo "📋 Next: Add your data and customize the application"
```

**GitHub Setup Checklist:**
- [ ] Created GitHub repository with correct naming convention
- [ ] Updated Git remote origin to point to new repository
- [ ] Prepared initial commit with all necessary files
- [ ] Created .gitignore, README.md, and .env.example
- [ ] Pushed initial commit to GitHub
- [ ] Created project setup summary document

#### Step 6: Development Process
```r
# Source global scripts
source("scripts/global_scripts/00_principles/README.md")  # Review principles
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")   # Universal data access
source("scripts/global_scripts/03_config/load_config.R")  # Load configuration

# Load app configuration
config <- load_app_config("app_config.yaml")

# Use existing components
source("scripts/global_scripts/10_rshinyapp_components/micro/microCustomer.R")
```

### Development Workflow

#### 1. Prerequisites Check
- [ ] Read `global_scripts/00_principles/README.md`
- [ ] Understand tbl2() universal data access pattern
- [ ] Review existing components in `10_rshinyapp_components/`
- [ ] Setup environment variables (OPENAI_API_KEY, database credentials)

#### 2. Git Repository Setup
- [ ] Remove copied Git subrepo metadata files
- [ ] Initialize new Git repository for the project
- [ ] Add remote origin for the new project
- [ ] Reinitialize `global_scripts` subrepo
- [ ] Setup `update_scripts` (as subrepo or regular directory)
- [ ] Create initial commit

#### 3. Application Configuration
- [ ] Open `app_config.yaml` and review current WISER settings
- [ ] Configure basic application information (name, brand, language)
- [ ] Set up data sources configuration (RAW_DATA_DIR, platforms)
- [ ] Configure Google Sheets integration (if applicable)
- [ ] Select and configure required components (micro/macro/position/poisson)
- [ ] Update deployment settings (account_name, app_name, title)
- [ ] Create .env file with required environment variables
- [ ] Choose appropriate theme and UI settings
- [ ] Complete final configuration checklist

#### 4. Data Pipeline Configuration
- [ ] Review WISER data structure to understand the pattern
- [ ] Rename rawdata directory to company-specific name
- [ ] Choose data handling strategy (keep reference vs clean)
- [ ] Initialize data pipeline structure with DuckDB databases
- [ ] Create platform-specific directories based on your configuration
- [ ] Set up ETL scripts structure and documentation
- [ ] Test and verify data pipeline structure
- [ ] Create data pipeline summary document

#### 5. GitHub Repository Setup
- [ ] Create GitHub repository with correct naming convention
- [ ] Update Git remote origin to point to new repository
- [ ] Prepare initial commit with all necessary files
- [ ] Create .gitignore, README.md, and .env.example
- [ ] Push initial commit to GitHub
- [ ] Create project setup summary document

#### 6. UI Component Development
- [ ] Source required components from `10_rshinyapp_components/` based on Step 3 selections
- [ ] Configure enabled components in your application
- [ ] Follow UI-Server-Defaults triple pattern (R09)
- [ ] Implement Union pattern for component composition
- [ ] Test component integration and data flow

#### 7. Business Logic Implementation
- [ ] Implement company-specific analysis functions
- [ ] Configure AI integration (OpenAI API)
- [ ] Add custom visualizations and reports
- [ ] Setup reactive data flows

#### 8. Testing and Validation
- [ ] Execute `global_scripts/98_test/test_database.R`
- [ ] Test complete application flow
- [ ] Validate with sample customer data
- [ ] Performance testing with enterprise data volumes

#### 9. Deployment Preparation
- [ ] Configure Posit Connect deployment settings
- [ ] Setup environment variables and security
- [ ] Create user documentation
- [ ] Execute `scripts/check_before_push.sh` safety checks

### Key Development Patterns

#### Universal Data Access Pattern
```r
# Always use tbl2() instead of dplyr::tbl()
source("scripts/global_scripts/02_db_utils/tbl2/fn_tbl2.R")

# Works with databases, lists, functions, reactive expressions
customer_data <- tbl2(conn, "customers") %>%
  filter(segment == "enterprise") %>%
  collect()
```

#### Configuration-Driven Development
```r
# Load settings from YAML
config <- load_app_config("app_config.yaml")
db_config <- config$database
ui_theme <- config$theme$bootswatch
```

#### Component Composition
```r
# Use existing components following Union pattern
source("scripts/global_scripts/10_rshinyapp_components/micro/microCustomer.R")
source("scripts/global_scripts/10_rshinyapp_components/macro/macroTrend.R")
```

### Common Pitfalls to Avoid

1. **Don't skip principles review**: Always check `00_principles/README.md` first
2. **Don't create new components**: Use existing `10_rshinyapp_components/` library
3. **Don't use dplyr::tbl()**: Always use `tbl2()` for universal data access
4. **Don't hardcode configurations**: Use `app_config.yaml` for all settings
5. **Don't skip safety checks**: Run `scripts/check_before_push.sh` before commits

### Repository Synchronization

```bash
# Use Claude Code intelligent sync (recommended)
./scripts/subrepo_sync.sh

# Features: Smart commit messages + Author Date sorting
# Process: git subrepo push --ALL → pull --ALL → commit
```

### Git Subrepo Management

#### Initial Setup for New Projects
```bash
# After copying WISER, reinitialize subrepos
cd l4_enterprise/NEW_PROJECT_NAME

# Remove copied subrepo metadata
rm -rf scripts/global_scripts/.git*
rm -f scripts/global_scripts/.gitrepo

# Clone global_scripts subrepo
git subrepo clone ../../global_scripts scripts/global_scripts

# For update_scripts (if it's a separate subrepo)
# Create new repository first on GitHub/GitLab
# git subrepo clone git@github.com:your-org/NEW_PROJECT_update_scripts.git scripts/update_scripts
```

#### Ongoing Subrepo Operations
```bash
# Push changes to subrepos
git subrepo push scripts/global_scripts
git subrepo push scripts/update_scripts

# Pull updates from subrepos
git subrepo pull scripts/global_scripts
git subrepo pull scripts/update_scripts

# Check subrepo status
git subrepo status
```

## Documentation

- [Product Tier Details](../docs/PRODUCT_TIERS_L3_ENTERPRISE.md)
- [Architecture Notes](../docs/L3_ENTERPRISE_ARCHITECTURE_NOTES.md)
- [Global Scripts Principles](../global_scripts/00_principles/README.md)

## Quick Start

```bash
cd WISER
Rscript app.R
```