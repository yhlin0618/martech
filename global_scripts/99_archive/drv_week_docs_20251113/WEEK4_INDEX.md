# Week 4: Validation Framework - Quick Reference

**Status**: ✅ COMPLETE  
**Total Files**: 9 (7 scripts + 2 docs)

---

## Quick Navigation

### 🔧 Core Utilities

| File | Purpose | Location |
|------|---------|----------|
| **Validation Template** | Reusable framework for all domains | `scripts/global_scripts/04_utils/fn_validate_etl_drv_template.R` |
| **Master Validator** | Validates precision ETL+DRV | `scripts/global_scripts/98_test/validate_precision_etl_drv.R` |
| **Report Generator** | Creates compliance markdown reports | `scripts/global_scripts/98_test/generate_compliance_report.R` |

### 📊 Metadata Generators

| File | Output | Purpose |
|------|--------|---------|
| **Variable Names** | `metadata/variable_name_transformations.csv` | Documents 1ST→2TR transformations |
| **Dummy Encoding** | `metadata/dummy_encoding_metadata.csv` | Documents categorical→binary encoding |
| **Time Series** | `metadata/time_series_filling_stats.csv` | Documents R117 REAL vs FILLED data |
| **Country Extraction** | `metadata/country_extraction_metadata.csv` | Documents currency→country mappings |

**Files**:
- `scripts/update_scripts/ETL/precision/generate_variable_name_metadata.R`
- `scripts/update_scripts/ETL/precision/generate_dummy_encoding_metadata.R`
- `scripts/update_scripts/DRV/all/generate_time_series_metadata.R`
- `scripts/update_scripts/ETL/precision/generate_country_metadata.R`

### ✅ Validation

| File | Purpose |
|------|---------|
| **Week 4 Validator** | Self-validates all Week 4 deliverables |

**File**: `scripts/update_scripts/DRV/all/validate_week4.R`

### 📚 Documentation

| File | Content |
|------|---------|
| **README** | Complete usage guide, troubleshooting |
| **Completion Report** | Week 4 summary and achievements |
| **Index** | This file - quick reference |

**Files**:
- `scripts/update_scripts/DRV/all/README_WEEK4.md`
- `scripts/update_scripts/DRV/all/WEEK4_COMPLETION_REPORT.md`
- `scripts/update_scripts/DRV/all/WEEK4_INDEX.md`

---

## Quick Start

### Run Complete Validation Workflow

```bash
# 1. Generate metadata (4 scripts)
Rscript scripts/update_scripts/ETL/precision/generate_variable_name_metadata.R
Rscript scripts/update_scripts/ETL/precision/generate_dummy_encoding_metadata.R
Rscript scripts/update_scripts/DRV/all/generate_time_series_metadata.R
Rscript scripts/update_scripts/ETL/precision/generate_country_metadata.R

# 2. Run master validation
Rscript scripts/global_scripts/98_test/validate_precision_etl_drv.R

# 3. Generate compliance report
Rscript scripts/global_scripts/98_test/generate_compliance_report.R

# 4. Validate Week 4
Rscript scripts/update_scripts/DRV/all/validate_week4.R
```

### Run Single Components

```bash
# Just validate (no metadata)
Rscript scripts/global_scripts/98_test/validate_precision_etl_drv.R

# Just generate compliance report
Rscript scripts/global_scripts/98_test/generate_compliance_report.R

# Just check Week 4 deliverables
Rscript scripts/update_scripts/DRV/all/validate_week4.R
```

---

## Principle Coverage

| Principle | What It Validates | Script |
|-----------|-------------------|--------|
| **MP029** | No fake data, R117/R118 compliance | All validators |
| **MP108** | ETL 0IM→1ST→2TR separation | `validate_precision_etl_drv.R` |
| **MP109** | DRV layer separation | `validate_precision_etl_drv.R` |
| **MP064** | ETL-DRV boundary enforcement | `validate_precision_etl_drv.R` |
| **MP102** | Metadata completeness | All metadata generators |
| **R116** | Currency standardization (USD) | `validate_precision_etl_drv.R` |
| **R117** | Time series transparency | `generate_time_series_metadata.R` |
| **R118** | Statistical significance docs | `validate_precision_etl_drv.R` |

---

## Output Files

### Validation Results

| File | Contains |
|------|----------|
| `validation/precision_etl_drv_validation_[timestamp].csv` | Detailed check results |
| `validation/precision_etl_drv_summary_[timestamp].txt` | Text summary |
| `validation/PRINCIPLE_COMPLIANCE_REPORT_[timestamp].md` | Markdown report |
| `validation/week4_validation_[timestamp].csv` | Week 4 check results |

### Metadata Files

| File | Contains |
|------|----------|
| `metadata/variable_name_transformations.csv` | Variable name mappings |
| `metadata/dummy_encoding_metadata.csv` | Dummy variable creation |
| `metadata/time_series_filling_stats.csv` | Fill rate statistics |
| `metadata/country_extraction_metadata.csv` | Currency→country mappings |

---

## Common Tasks

### Check Compliance Rate

```bash
# Run master validation (shows compliance rate at end)
Rscript scripts/global_scripts/98_test/validate_precision_etl_drv.R
```

### View Compliance Report

```bash
# Generate report
Rscript scripts/global_scripts/98_test/generate_compliance_report.R

# Find latest report
ls -lt validation/PRINCIPLE_COMPLIANCE_REPORT_*.md | head -1
```

### Check Specific Metadata

```bash
# Variable transformations
cat metadata/variable_name_transformations.csv | head -20

# Time series fill rates
cat metadata/time_series_filling_stats.csv | head -10
```

### Verify Week 4 Complete

```bash
# Run Week 4 validator
Rscript scripts/update_scripts/DRV/all/validate_week4.R
# Should output: "✅ WEEK 4 VALIDATION PASSED"
```

---

## Troubleshooting

### "File not found" errors

**Problem**: Database or ETL outputs missing  
**Solution**: Run Weeks 1-3 scripts first

```bash
# Week 1 (ETL)
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_0IM.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_1ST.R
Rscript scripts/update_scripts/ETL/precision/precision_ETL_product_profiles_2TR.R

# Week 2-3 (DRV)
Rscript scripts/update_scripts/DRV/all/all_D04_09.R
Rscript scripts/update_scripts/DRV/all/all_D04_07.R
Rscript scripts/update_scripts/DRV/all/all_D04_08.R
```

### Metadata files empty

**Problem**: Source data not processed  
**Solution**: Run ETL+DRV first (see above)

### Compliance rate < 95%

**Problem**: Principle violations in code  
**Solution**: Check compliance report for specific failures

```bash
# View detailed report
cat validation/PRINCIPLE_COMPLIANCE_REPORT_*.md | tail -100
```

---

## For More Information

- **Detailed Usage**: See `README_WEEK4.md`
- **Implementation Report**: See `WEEK4_COMPLETION_REPORT.md`
- **Redesign Document**: `docs/suggestion/MAMBA/20251021/MAMBA_PRECISION_MARKETING_PRINCIPLE_BASED_REDESIGN.md`

---

**Last Updated**: 2025-11-13  
**Week 4 Status**: ✅ COMPLETE
