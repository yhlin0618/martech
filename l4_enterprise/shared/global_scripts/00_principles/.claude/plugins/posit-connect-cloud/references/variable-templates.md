# Variable Templates for Posit Connect

## Current Standard: SUPABASE_DB_* Variables

**db_connection.R** reads these environment variables:

```bash
SUPABASE_DB_HOST=db.oziernubrqgqthjksbii.supabase.co
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=nuvpa6-dufqUq-pichez
```

### Verification in R

```r
# Check environment variables loaded
Sys.getenv("SUPABASE_DB_HOST")
Sys.getenv("SUPABASE_DB_PORT")
Sys.getenv("SUPABASE_DB_NAME")
Sys.getenv("SUPABASE_DB_USER")
Sys.getenv("SUPABASE_DB_PASSWORD")

# Validation
stopifnot(nzchar(Sys.getenv("SUPABASE_DB_HOST")))
```

## Legacy Variables (DEPRECATED)

These old PG* variables are **NO LONGER USED**:

```bash
# DO NOT USE - Legacy format
PGHOST=db.oziernubrqgqthjksbii.supabase.co
PGPORT=5432
PGUSER=postgres
PGPASSWORD=your-password
PGDATABASE=postgres
PGSSLMODE=require
```

**Note:** If both SUPABASE_DB_* and PG* variables exist, the app will use SUPABASE_DB_*.
Legacy PG* variables can be safely deleted.

## OpenAI Integration

```bash
OPENAI_API_KEY=sk-...
```

## Local Development (.env files)

Location: `sandbox_test/env/{app}/.env`

## App Instance Mapping

| App Type | Instances | URL Pattern |
|----------|-----------|-------------|
| BrandEdge | 00-04 | `kyleyhl-sandbox-brandedge{NN}` |
| InsightForge | 00-04 | `kyleyhl-sandbox-insightforge{NN}` |
| TagPilot | 00-05 | `kyleyhl-sandbox-tagpilot{NN}` |
| VitalSigns | 00-04 | `kyleyhl-sandbox-vitalsigns{NN}` |

**Total:** 21 app instances
