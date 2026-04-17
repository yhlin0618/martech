#!/bin/bash
# execute_all_weeks.sh
# MAMBA Precision Marketing ETL+DRV - Full Week 1-4 Execution

set -e  # Exit on any error

echo "=== MAMBA Precision Marketing ETL+DRV Full Execution ==="
echo "Start: $(date)"
echo ""

# Week 1: ETL
echo "[Week 1] ETL Pipeline..."
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_0IM.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_1ST.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_2TR.R
Rscript scripts/update_scripts/ETL/precision/validate_week1.R

# Week 2: DRV Features
echo "[Week 2] DRV Features..."
Rscript scripts/update_scripts/DRV/all/all_D04_09.R
Rscript scripts/update_scripts/DRV/all/all_D04_07.R
Rscript scripts/update_scripts/DRV/all/validate_week2.R

# Week 3: DRV Poisson
echo "[Week 3] DRV Poisson..."
Rscript scripts/update_scripts/DRV/all/all_D04_08.R
Rscript scripts/update_scripts/DRV/all/validate_week3.R

# Week 4: Validation
echo "[Week 4] Validation..."
Rscript scripts/update_scripts/ETL/precision/generate_variable_name_metadata.R
Rscript scripts/update_scripts/ETL/precision/generate_dummy_encoding_metadata.R
Rscript scripts/update_scripts/DRV/all/generate_time_series_metadata.R
Rscript scripts/update_scripts/ETL/precision/generate_country_metadata.R
Rscript scripts/global_scripts/98_test/validate_precision_etl_drv.R
Rscript scripts/global_scripts/98_test/generate_compliance_report.R
Rscript scripts/update_scripts/DRV/all/validate_week4.R

echo ""
echo "=== Execution Complete ==="
echo "End: $(date)"
echo ""
echo "Check validation/PRINCIPLE_COMPLIANCE_REPORT_*.md for results"
