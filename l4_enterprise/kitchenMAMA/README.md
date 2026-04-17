# kitchenMAMA L3 Enterprise Application

This is an L3 Enterprise-level AI MarTech application based on the WISER template.

## Application Information
- **Company**: kitchenMAMA
- **Tier**: L3 Enterprise
- **Raw Data Directory**: ./data/local_data/rawdata_kitchenmama
- **Platforms**: amz, officialwebsite

## Quick Start
```bash
# Install dependencies
# Add your R package installation commands here

# Set up environment variables
cp .env.example .env
# Edit .env file with your credentials

# Run the application
Rscript app.R
```

## Data Pipeline
See `data_pipeline_summary.md` for detailed information about the data pipeline structure.

## ETL Scripts
ETL scripts are organized in `scripts/update_scripts/`:
- `import/` - Data import scripts
- `stage/` - Data staging scripts
- `transform/` - Data transformation scripts
- `process/` - Data processing scripts

## Configuration
- `app_config.yaml` - Main application configuration
- `.env` - Environment variables (not committed)

## Deployment
This application is configured for deployment to Posit Connect.
See `app_config.yaml` for deployment settings.

---
Generated from WISER L3 Enterprise template