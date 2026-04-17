# 📋 Migration Guide: Four-Part to Five-Part Script Structure

## Executive Summary

The system is transitioning from four-part to **five-part script structure as the PRIMARY STANDARD**. This migration eliminates the `autodeinit()` variable access problem by separating reporting (SUMMARIZE) from cleanup (DEINITIALIZE).

**Key Change**: Insert new SUMMARIZE section between TEST and DEINITIALIZE.

## Why Migrate?

### The Problem with Four-Part Structure

```r
# ❌ FOUR-PART PROBLEM: Variables deleted before use
# Part 4: DEINITIALIZE
final_status <- calculate_status()
autodeinit()  # Deletes ALL variables
return(final_status)  # ERROR: final_status doesn't exist!
```

### The Five-Part Solution

```r
# ✅ FIVE-PART SOLUTION: Clean separation
# Part 4: SUMMARIZE
final_status <- calculate_status()  # Variables still exist
message("Status:", final_status)     # Can use variables

# Part 5: DEINITIALIZE
autodeinit()  # Safe - no variables needed after this
```

## Migration Priority

| Priority | Script Type | Action Required | Deadline |
|----------|------------|-----------------|----------|
| 🔴 **CRITICAL** | ETL scripts with return values | Immediate migration | ASAP |
| 🟡 **HIGH** | Scripts being modified | Migrate during update | When touched |
| 🟢 **MEDIUM** | Active development scripts | Schedule migration | Q1 2026 |
| ⚪ **LOW** | Stable legacy scripts | Optional migration | As needed |

## Step-by-Step Migration Guide

### Step 1: Identify Current Structure

```r
# Look for these section markers:
# 1. INITIALIZE
# 2. MAIN  
# 3. TEST
# 4. DEINITIALIZE  <- This needs to be split
```

### Step 2: Analyze DEINITIALIZE Content

Categorize each line in DEINITIALIZE:

| Category | Move to | Examples |
|----------|---------|----------|
| Reporting | SUMMARIZE | `message()`, `print()`, `cat()` |
| Metrics | SUMMARIZE | Final counts, timings, summaries |
| Return prep | SUMMARIZE | `final_status <- ...` |
| Cleanup | DEINITIALIZE | `autodeinit()`, `dbDisconnect()` |

### Step 3: Create SUMMARIZE Section

```r
# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================
# Move all reporting, metrics, and return preparation here

message("📊 EXECUTION SUMMARY")
message(sprintf("  Rows processed: %d", nrow(data)))
message(sprintf("  Success: %s", success))

# Prepare return value (variables still accessible!)
final_return_status <- list(
  success = success,
  rows = nrow(data),
  timestamp = Sys.time()
)
```

### Step 4: Simplify DEINITIALIZE

```r
# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
# ONLY cleanup operations, NO reporting

autodeinit()  # Must be last statement
# No code after this - all variables are gone
```

### Step 5: Update Section Numbers

Update all comments to reflect five parts:
- Part 1: INITIALIZE
- Part 2: MAIN
- Part 3: TEST
- Part 4: SUMMARIZE (new)
- Part 5: DEINITIALIZE

## Common Migration Patterns

### Pattern A: Simple Script

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
message("Script complete")
autodeinit()
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
message("Script complete")

# 5. DEINITIALIZE
autodeinit()
```

### Pattern B: ETL with Return Value

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
final_status <- success_flag
message("Processed:", row_count, "rows")
autodeinit()
invisible(final_status)  # ERROR!
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
final_status <- success_flag
message("Processed:", row_count, "rows")
saveRDS(final_status, "etl_status.rds")  # Or other return method

# 5. DEINITIALIZE
autodeinit()
```

### Pattern C: Complex Reporting

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
# Calculate metrics
elapsed <- Sys.time() - start_time
memory_used <- gc()[2, "(Mb)"]

# Report
message("Time:", elapsed)
message("Memory:", memory_used)

# Cleanup
autodeinit()
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
# Calculate metrics
elapsed <- Sys.time() - start_time
memory_used <- gc()[2, "(Mb)"]

# Report
message("Time:", elapsed)
message("Memory:", memory_used)

# 5. DEINITIALIZE
autodeinit()
```

## Validation Checklist

After migration, verify:

- [ ] Script has exactly 5 parts with clear headers
- [ ] All reporting is in SUMMARIZE (Part 4)
- [ ] DEINITIALIZE (Part 5) only has cleanup
- [ ] `autodeinit()` is the last statement
- [ ] No variable references after `autodeinit()`
- [ ] Return values are handled properly
- [ ] Script still runs successfully
- [ ] Tests still pass

## Quick Reference Card

```
FOUR-PART (Legacy)          →  FIVE-PART (Primary)
==================             ====================
1. INITIALIZE                  1. INITIALIZE
2. MAIN                        2. MAIN  
3. TEST                        3. TEST
4. DEINITIALIZE                4. SUMMARIZE (NEW!)
   - Reporting                    - All reporting
   - Metrics                      - All metrics  
   - Returns                      - All returns
   - Cleanup                   5. DEINITIALIZE
                                  - ONLY cleanup
```

## Automated Migration Helper

```r
# Function to check if script needs migration
check_migration_needed <- function(script_path) {
  lines <- readLines(script_path)
  
  # Check for SUMMARIZE section
  has_summarize <- any(grepl("PART 4: SUMMARIZE", lines))
  
  # Check for autodeinit
  has_autodeinit <- any(grepl("autodeinit\\(\\)", lines))
  
  if (!has_summarize && has_autodeinit) {
    return(list(
      needs_migration = TRUE,
      reason = "Four-part structure with autodeinit detected"
    ))
  }
  
  return(list(needs_migration = FALSE))
}

# Usage
result <- check_migration_needed("your_script.R")
if (result$needs_migration) {
  message("Migration needed: ", result$reason)
}
```

## Common Mistakes to Avoid

### ❌ Don't: Leave reporting in DEINITIALIZE
```r
# 5. DEINITIALIZE
message("Final status:", status)  # WRONG!
autodeinit()
```

### ✅ Do: Move all reporting to SUMMARIZE
```r
# 4. SUMMARIZE
message("Final status:", status)  # CORRECT!

# 5. DEINITIALIZE
autodeinit()
```

### ❌ Don't: Access variables after autodeinit
```r
autodeinit()
print(summary)  # ERROR: summary doesn't exist
```

### ✅ Do: Complete all operations before autodeinit
```r
print(summary)  # Do this first
autodeinit()    # Then cleanup
```

## Support Resources

- **Primary Standard**: [MP104 Script Organization Evolution](natural/en/part1_principles/CH00_fundamental_principles/02_structure_organization/MP104_script_organization_evolution.qmd)
- **Five-Part Rule**: [DEV_R033 Five-Part Structure](natural/en/part1_principles/CH03_development_methodology/rules/DEV_R033_five_part_script_structure.qmd)
- **autodeinit Behavior**: [MP103 autodeinit](natural/en/part1_principles/CH00_fundamental_principles/02_structure_organization/MP103_autodeinit_behavior.qmd)
- **Template**: `template_update_script_five_part.R`

## Migration Timeline

| Phase | Period | Goal |
|-------|--------|------|
| **Phase 1** | Now - Q4 2025 | All new scripts use five-part |
| **Phase 2** | Q1 2026 | ETL scripts migrated |
| **Phase 3** | Q2 2026 | Active scripts migrated |
| **Phase 4** | Q3 2026 | Legacy scripts evaluated |
| **Phase 5** | Q4 2026 | System fully migrated |

## Questions?

If you encounter issues during migration:

1. Check this guide first
2. Review the principles documentation
3. Use the five-part template as reference
4. Test thoroughly after migration

Remember: **The five-part structure is the PRIMARY STANDARD**. All new scripts MUST use it.

---

*Last Updated: 2025-08-28*  
*Status: Active Migration in Progress*