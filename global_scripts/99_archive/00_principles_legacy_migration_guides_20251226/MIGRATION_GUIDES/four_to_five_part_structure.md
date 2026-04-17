# Migration Guide: Four-Part to Five-Part Script Structure

## Executive Summary

This guide provides step-by-step instructions for migrating scripts from the four-part structure (DEV_R032) to the new five-part structure (DEV_R033). The five-part structure solves the autodeinit() variable access problem by separating reporting (SUMMARIZE) from cleanup (DEINITIALIZE).

## Why Migrate?

### Problems with Four-Part Structure
- **autodeinit() Variable Access**: Cannot access variables after autodeinit() in DEINITIALIZE
- **Mixed Concerns**: Reporting and cleanup mixed in single section
- **Complex Workarounds**: Requires awkward patterns for ETL return values
- **Debugging Difficulty**: Cannot skip cleanup without losing reporting

### Benefits of Five-Part Structure
- ✅ **Clean Separation**: Reporting in SUMMARIZE, cleanup in DEINITIALIZE
- ✅ **No Variable Access Issues**: All variables available in SUMMARIZE
- ✅ **Simple Return Values**: Prepare returns in SUMMARIZE before cleanup
- ✅ **Better Debugging**: Can skip DEINITIALIZE while keeping SUMMARIZE
- ✅ **Clearer Code**: Each section has single responsibility

## Migration Priority

### High Priority (Migrate Immediately)
- ETL scripts that return values
- Scripts with complex reporting in DEINITIALIZE
- Scripts experiencing autodeinit() errors
- Frequently modified scripts

### Medium Priority (Migrate When Modified)
- Scripts with moderate reporting needs
- Pipeline orchestration scripts
- Scripts under active development

### Low Priority (Optional Migration)
- Simple scripts with minimal reporting
- Stable legacy scripts
- Scripts scheduled for deprecation

## Step-by-Step Migration Process

### Step 1: Analyze Current DEINITIALIZE Section

Identify the different types of code in your current DEINITIALIZE:

```r
# CURRENT: Four-Part Structure DEINITIALIZE
# 4. DEINITIALIZE
tryCatch({
  # A. REPORTING CODE (move to SUMMARIZE)
  message("Summary: Processing complete")
  message(sprintf("Rows processed: %d", nrow(df_data)))
  total_time <- as.numeric(Sys.time() - start_time, units = "secs")
  
  # B. RETURN VALUE PREP (move to SUMMARIZE)
  final_status <- list(
    success = !main_error,
    rows = nrow(df_data),
    time = total_time
  )
  
  # C. CLEANUP CODE (keep in DEINITIALIZE)
  if (exists("con")) {
    dbDisconnect(con)
  }
  
  # D. autodeinit() (keep in DEINITIALIZE)
  autodeinit()
  
  # E. PROBLEMATIC CODE (fix or remove)
  return(final_status)  # ERROR: Variable doesn't exist!
  
}, error = function(e) {
  message("Error in cleanup: ", e$message)
})
```

### Step 2: Create SUMMARIZE Section

Move all reporting and return value preparation to new SUMMARIZE:

```r
# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================
message("SUMMARIZE: Generating final report...")
summary_start <- Sys.time()

# All reporting code (from A above)
message("Summary: Processing complete")
message(sprintf("Rows processed: %d", nrow(df_data)))
total_time <- as.numeric(Sys.time() - start_time, units = "secs")

# Return value preparation (from B above)
final_status <- list(
  success = !main_error,
  rows = nrow(df_data),
  time = total_time
)

# Additional reporting you can now safely add
message("=" * 70)
message("📊 EXECUTION SUMMARY")
message(sprintf("  Status: %s", ifelse(final_status$success, "SUCCESS", "FAILED")))
message(sprintf("  Total Time: %.2fs", total_time))
message("=" * 70)

# Save metrics if needed
if (Sys.getenv("SAVE_METRICS") == "TRUE") {
  saveRDS(final_status, "metrics.rds")
}

summary_elapsed <- as.numeric(Sys.time() - summary_start, units = "secs")
message(sprintf("SUMMARIZE: Complete (%.2fs)", summary_elapsed))
```

### Step 3: Simplify DEINITIALIZE Section

Keep only cleanup operations in DEINITIALIZE:

```r
# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
# MANDATORY: Only cleanup, no reporting or variable access

message("DEINITIALIZE: Cleaning up resources...")

# Connection cleanup (from C above)
if (exists("con") && inherits(con, "DBIConnection")) {
  if (DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con)
    message("  Database connection closed")
  }
}

# Final cleanup - removes ALL variables (from D above)
autodeinit()
# No code after this line!
```

### Step 4: Update Section Numbers and Headers

Update all section headers to reflect five parts:

```r
# ==============================================================================
# PART 1: INITIALIZE
# ==============================================================================

# ==============================================================================
# PART 2: MAIN
# ==============================================================================

# ==============================================================================
# PART 3: TEST
# ==============================================================================

# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================

# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
```

## Common Migration Patterns

### Pattern A: Simple Reporting Migration

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
message("Processed", nrow(data), "rows")
autodeinit()
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
message("Processed", nrow(data), "rows")

# 5. DEINITIALIZE
autodeinit()
```

### Pattern B: ETL Return Value Migration

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
final_status <- compute_status()
autodeinit()
invisible(final_status)  # ERROR!
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
final_status <- compute_status()
saveRDS(final_status, "etl_status.rds")

# 5. DEINITIALIZE
autodeinit()
```

### Pattern C: Complex Metrics Migration

**Before (Four-Part):**
```r
# 4. DEINITIALIZE
# Complex mix of reporting and cleanup
gc_before <- gc()
message("Memory before:", gc_before[2, "(Mb)"])

if (exists("con")) dbDisconnect(con)

gc_after <- gc()
message("Memory after:", gc_after[2, "(Mb)"])  

autodeinit()
message("Freed:", gc_before[2,2] - gc_after[2,2])  # ERROR!
```

**After (Five-Part):**
```r
# 4. SUMMARIZE
gc_stats <- gc()
message("Memory usage:", gc_stats[2, "(Mb)"], "MB")
memory_before_cleanup <- gc_stats[2, "(Mb)"]

# 5. DEINITIALIZE
if (exists("con")) dbDisconnect(con)
autodeinit()
```

## Validation Checklist

After migration, verify:

- [ ] Script has exactly 5 clearly marked parts
- [ ] All reporting moved to SUMMARIZE (Part 4)
- [ ] All cleanup kept in DEINITIALIZE (Part 5)
- [ ] No variable references after autodeinit()
- [ ] Return values handled appropriately
- [ ] Script runs without errors
- [ ] Output matches pre-migration behavior

## Testing Your Migration

Run this validation function:

```r
validate_migration <- function(script_path) {
  source("scripts/global_scripts/00_principles/utils/validate_five_part.R")
  
  result <- validate_five_part_structure(script_path)
  
  if (result$valid) {
    message("✅ Migration successful!")
  } else {
    message("❌ Issues found:")
    for (issue in result$issues) {
      message("  - ", issue)
    }
  }
  
  return(result$valid)
}

# Use:
validate_migration("your_script.R")
```

## Rollback Plan

If migration causes issues:

1. **Keep original backup**: Always backup before migrating
2. **Revert structure**: Recombine SUMMARIZE back into DEINITIALIZE
3. **Apply workarounds**: Use DM_R036 patterns for return values
4. **Document issues**: Report problems for principle refinement

## Migration Tools

### Automated Migration Assistant (Coming Soon)

```r
# Future tool preview
migrate_to_five_part <- function(script_path) {
  # Reads four-part script
  # Identifies DEINITIALIZE components
  # Splits into SUMMARIZE and DEINITIALIZE
  # Writes migrated script
  # Validates result
}
```

### Manual Migration Template

```r
# Use this template for manual migration
source("scripts/global_scripts/00_principles/templates/five_part_template.R")
```

## FAQ

### Q: Do I have to migrate all scripts?

No. Migration is recommended but not mandatory. Focus on:
- Scripts with autodeinit() issues
- ETL scripts needing return values
- Actively developed scripts

### Q: Can four-part and five-part scripts coexist?

Yes. The system supports both structures. Teams can migrate gradually.

### Q: What if SUMMARIZE is empty?

Include an empty section with explanation:

```r
# PART 4: SUMMARIZE
# No summary needed for this simple operation
```

### Q: How do I handle existing return statements?

- If after autodeinit(): Move to SUMMARIZE or use file-based approach
- If simple cleanup: Consider skipping autodeinit()
- If complex: Use selective cleanup pattern

## Support

For migration assistance:
1. Review DEV_R033 documentation
2. Check example migrations in `/examples/migration/`
3. Consult principle-debugger agent
4. Submit questions to architecture team

## Conclusion

The five-part structure migration is straightforward and provides significant benefits. Focus on high-value scripts first, and migrate others opportunistically. The improved separation of concerns and elimination of autodeinit() issues make this a worthwhile architectural improvement.

---

**Last Updated**: 2025-08-28
**Version**: 1.0
**Status**: Active Migration Period