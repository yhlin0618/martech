# Git Subrepo Workflows: Company-Agnostic Guide

**Purpose**: Universal workflow patterns for ANY company in ANY tier
**Audience**: All developers working with ai_martech principles
**Date**: 2025-10-03
**Status**: COMPANY-AGNOSTIC WORKFLOW PATTERNS
**Supersedes**: WORKFLOWS_GIT_SUBREPO.md (MAMBA-centric version)

---

## 🎯 Critical Understanding

### Company Name is a VARIABLE

**When you see**: `{company}`, `{tier}`, or `[companyname]`
**It means**: Replace with YOUR actual company name

**Examples of VALID companies**:
- l1_basic: VitalSigns, InsightForge, BrandEdge, TagPilot, positioning_app, latex_test
- l3_premium: VitalSigns_premium, BrandEdge_premium, InsightForge_premium
- l4_enterprise: MAMBA, WISER, QEF_DESIGN, kitchenMAMA

**Key Point**: This guide works for ALL of them. MAMBA is NOT special.

---

## 🚀 Quick Command Reference

### Auto-Detect Current Company

```bash
# Run this from ANY company directory to see where you are
pwd | sed 's|.*/ai_martech/||'

# Example outputs:
# - l1_basic/VitalSigns/scripts/...
# - l4_enterprise/MAMBA/...
# - l4_enterprise/kitchenMAMA/...
# - l1_basic/InsightForge/...
```

### Check Sync Status (All Companies)

```bash
# Works regardless of where you are
cd /path/to/ai_martech
./bash/check_all_sync_status.sh

# Shows status for:
# - VitalSigns ✅ or ⚠️
# - InsightForge ✅ or ⚠️
# - MAMBA ✅ or ⚠️
# - WISER ✅ or ⚠️
# - kitchenMAMA ✅ or ⚠️
# - ALL other companies
```

### Sync All Companies (Automated)

```bash
# Updates VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc. automatically
cd /path/to/ai_martech
./bash/sync_all_global_scripts.sh
```

---

## 📝 Workflow Scenarios (Multi-Company Examples)

### Scenario 1: Adding New Principle (Affects ALL Companies)

**Context**: You want to add MP031 - affects VitalSigns, MAMBA, WISER, kitchenMAMA, etc.

```bash
# 1. Navigate to master repository (company-agnostic location)
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/global_scripts/

# 2. Create principle file
cat > 00_principles/MP031_new_principle.md << 'EOF'
# MP031: New Principle Name

## Principle Statement
[Clear statement applicable to ALL companies]

## Application
This principle applies to:
- l1_basic companies (VitalSigns, InsightForge, etc.)
- l3_premium companies
- l4_enterprise companies (MAMBA, WISER, kitchenMAMA, etc.)
- ALL future companies

## Examples

### Example 1: l1_basic/VitalSigns
[Code example specific to VitalSigns]

### Example 2: l4_enterprise/MAMBA
[Code example specific to MAMBA]

### Example 3: l4_enterprise/kitchenMAMA
[Code example specific to kitchenMAMA]

All examples follow same principle, adapted to company context.
EOF

# 3. Update INDEX.md
vi 00_principles/INDEX.md
# Add MP031 to appropriate category

# 4. Commit to master
git add 00_principles/MP031_new_principle.md 00_principles/INDEX.md
git commit -m "Add MP031: New Principle Name

Applies to: ALL companies (tier-agnostic, company-agnostic)
Impact: VitalSigns, InsightForge, MAMBA, WISER, kitchenMAMA, etc.
Related Principles: MP001

Per MP001_axiomatization_system"

# 5. Push to GitHub
git push origin main

# 6. Sync to ALL companies (VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc.)
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

**What Happens**:
```
Updating master global_scripts... ✓
Syncing l1_basic/VitalSigns... ✓
Syncing l1_basic/InsightForge... ✓
Syncing l1_basic/BrandEdge... ✓
Syncing l4_enterprise/MAMBA... ✓
Syncing l4_enterprise/WISER... ✓
Syncing l4_enterprise/kitchenMAMA... ✓
All companies synced successfully!
```

---

### Scenario 2: Emergency Fix from ANY Company

**Template** (works for VitalSigns, MAMBA, WISER, kitchenMAMA, etc.):

```bash
# TEMPLATE: Replace {tier} and {company} with your actual values

# 1. You're working in ANY company and notice a bug
cd /path/to/ai_martech/{tier}/{company}/

# 2. Fix the principle in your company's subrepo
vi scripts/global_scripts/00_principles/MP015.md

# 3. Commit within the subrepo
cd scripts/global_scripts/
git add 00_principles/MP015.md
git commit -m "HOT-FIX from {company}: Correct MP015 example

Issue: [Description]
Context: Discovered during {company} [operation]
Impact: Affects ALL companies (VitalSigns, MAMBA, WISER, kitchenMAMA, etc.)
Fix: [What was changed]

Per MP001_axiomatization_system"
cd ../..

# 4. Push to GitHub
git subrepo push scripts/global_scripts

# 5. IMMEDIATELY sync to master + all other companies
cd /path/to/ai_martech/global_scripts/
git pull origin main
cd ..
./bash/sync_all_global_scripts.sh

# 6. Notify team
echo "HOT-FIX from {company} synced to all companies"
```

**Concrete Example 1: Fix from VitalSigns (l1_basic)**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/VitalSigns/

vi scripts/global_scripts/00_principles/MP015.md

cd scripts/global_scripts/
git add 00_principles/MP015.md
git commit -m "HOT-FIX from VitalSigns: Correct MP015 database example

Issue: Example code used deprecated DBI syntax
Context: Discovered during VitalSigns production deployment
Impact: Affects all companies using R092_universal_DBI (MAMBA, WISER, kitchenMAMA, InsightForge, etc.)
Fix: Updated to current DBI::dbConnect() syntax

Per MP001_axiomatization_system, R092_universal_DBI"
cd ../..

git subrepo push scripts/global_scripts

cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/global_scripts/
git pull origin main
cd ..
./bash/sync_all_global_scripts.sh
```

**Concrete Example 2: Fix from MAMBA (l4_enterprise)**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/

vi scripts/global_scripts/02_db_utils/fn_tbl2.R

cd scripts/global_scripts/
git add 02_db_utils/fn_tbl2.R
git commit -m "HOT-FIX from MAMBA: Fix tbl2() parameter validation

Issue: Missing NULL check caused crashes
Context: Discovered during MAMBA customer segmentation analysis
Impact: Affects all companies using tbl2() (VitalSigns, WISER, kitchenMAMA, InsightForge, etc.)
Fix: Added if(is.null(con)) stop() validation

Per R092_universal_DBI"
cd ../..

git subrepo push scripts/global_scripts

cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

**Concrete Example 3: Fix from kitchenMAMA (l4_enterprise)**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/kitchenMAMA/

vi scripts/global_scripts/01_db/dbConnect.R

cd scripts/global_scripts/
git add 01_db/dbConnect.R
git commit -m "HOT-FIX from kitchenMAMA: Add PostgreSQL SSL mode support

Issue: Connection failed without SSL configuration
Context: Discovered during kitchenMAMA RDS migration
Impact: Affects all companies using PostgreSQL (MAMBA, WISER, VitalSigns, etc.)
Fix: Added sslmode parameter to connection string

Per R092_universal_DBI"
cd ../..

git subrepo push scripts/global_scripts

cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

**Concrete Example 4: Fix from WISER (l4_enterprise)**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/WISER/

vi scripts/global_scripts/04_utils/fn_analyze_text.R

cd scripts/global_scripts/
git add 04_utils/fn_analyze_text.R
git commit -m "HOT-FIX from WISER: Handle UTF-8 encoding in text analysis

Issue: Non-ASCII characters caused encoding errors
Context: Discovered during WISER Chinese text processing
Impact: Affects all companies with international text (kitchenMAMA, MAMBA, InsightForge, etc.)
Fix: Added encoding parameter with UTF-8 default

Per MP001_axiomatization_system"
cd ../..

git subrepo push scripts/global_scripts

cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

---

### Scenario 3: Syncing Single Company

**Template** (works for any company):

```bash
# Navigate to YOUR company (replace {tier} and {company})
cd /path/to/ai_martech/{tier}/{company}/

# Check current status
git subrepo status scripts/global_scripts

# Pull latest from GitHub
git subrepo pull scripts/global_scripts

# Commit the sync
git commit -m "Sync global_scripts: $(date +%Y-%m-%d)

Updated to latest principles from master repository
Company: {company}
Tier: {tier}

Per MP001_axiomatization_system"

# Push to company's GitHub repo
git push origin main
```

**Example 1: Sync VitalSigns only**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/VitalSigns/
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts
git commit -m "Sync global_scripts: $(date +%Y-%m-%d) - VitalSigns"
git push origin main
```

**Example 2: Sync MAMBA only**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts
git commit -m "Sync global_scripts: $(date +%Y-%m-%d) - MAMBA"
git push origin main
```

**Example 3: Sync kitchenMAMA only**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/kitchenMAMA/
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts
git commit -m "Sync global_scripts: $(date +%Y-%m-%d) - kitchenMAMA"
git push origin main
```

**Example 4: Sync InsightForge only**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/InsightForge/
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts
git commit -m "Sync global_scripts: $(date +%Y-%m-%d) - InsightForge"
git push origin main
```

---

### Scenario 4: Pre-Deployment Sync Check

**Template** (before deploying ANY company):

```bash
# Check if YOUR company needs sync
cd /path/to/ai_martech/{tier}/{company}/

# Get master commit
MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse HEAD)

# Get company's subrepo commit
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')

# Compare
if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ {company} is synced with master - safe to deploy"
else
    echo "⚠ {company} is out of sync - run: git subrepo pull scripts/global_scripts"
    exit 1
fi
```

**Example 1: Pre-deploy VitalSigns**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/VitalSigns/

MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse HEAD)
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')

if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ VitalSigns is synced - deploying..."
    # Continue with deployment
else
    echo "⚠ VitalSigns out of sync - syncing first..."
    git subrepo pull scripts/global_scripts
    git commit -m "Pre-deployment sync: VitalSigns"
    git push origin main
fi
```

**Example 2: Pre-deploy MAMBA**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/

MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse HEAD)
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')

if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ MAMBA is synced - deploying..."
else
    echo "⚠ MAMBA out of sync - syncing first..."
    git subrepo pull scripts/global_scripts
    git commit -m "Pre-deployment sync: MAMBA"
    git push origin main
fi
```

**Example 3: Pre-deploy kitchenMAMA**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/kitchenMAMA/

MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse HEAD)
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')

if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ kitchenMAMA is synced - deploying..."
else
    echo "⚠ kitchenMAMA out of sync - syncing first..."
    git subrepo pull scripts/global_scripts
    git commit -m "Pre-deployment sync: kitchenMAMA"
    git push origin main
fi
```

---

### Scenario 5: Adding New Company to Principle System

**Template** (works for ANY new company in ANY tier):

```bash
# Step 1: Navigate to new company directory
cd /path/to/ai_martech/{tier}/{new_company}/

# Step 2: Initialize git if needed
git init
git remote add origin https://github.com/{org}/{new_company}.git

# Step 3: Clone principles as subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

# Step 4: Verify setup
ls scripts/global_scripts/.gitrepo  # Should exist
git subrepo status scripts/global_scripts  # Should show "up to date"

# Step 5: Commit and push
git commit -m "Add global_scripts subrepo to {new_company}

Includes 257+ principles from master repository
Company: {new_company}
Tier: {tier}

This company now synced with:
- l1_basic: VitalSigns, InsightForge, BrandEdge, etc.
- l4_enterprise: MAMBA, WISER, kitchenMAMA, etc.

Per MP001_axiomatization_system"
git push origin main

# Done! New company now part of global sync system
```

**Example 1: Add principles to new l1_basic company "ProductMatrix"**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/ProductMatrix/

git init
git remote add origin https://github.com/myorg/ProductMatrix.git

git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

git commit -m "Add global_scripts subrepo to ProductMatrix

Now synced with VitalSigns, InsightForge, MAMBA, WISER, kitchenMAMA, etc.
Tier: l1_basic
Company: ProductMatrix

Per MP001_axiomatization_system"
git push origin main
```

**Example 2: Add principles to new l4_enterprise company "MegaCorp"**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MegaCorp/

git init
git remote add origin https://github.com/enterprise/MegaCorp.git

git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

git commit -m "Add global_scripts subrepo to MegaCorp

Now synced with MAMBA, WISER, kitchenMAMA, VitalSigns, etc.
Tier: l4_enterprise
Company: MegaCorp

Per MP001_axiomatization_system"
git push origin main
```

**Example 3: Add principles to new l3_premium company "EliteAnalytics"**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l3_premium/EliteAnalytics/

git init
git remote add origin https://github.com/premium/EliteAnalytics.git

git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

git commit -m "Add global_scripts subrepo to EliteAnalytics

Now synced with all companies across all tiers
Tier: l3_premium
Company: EliteAnalytics

Per MP001_axiomatization_system"
git push origin main
```

---

## 🔧 Auto-Detection Scripts

### Detect Current Company from Any Directory

```bash
#!/bin/bash
# File: bash/detect_current_company.sh

detect_company() {
    local current_path=$(pwd)

    # Check if we're inside ai_martech
    if [[ ! "$current_path" =~ ai_martech ]]; then
        echo "ERROR: Not inside ai_martech directory"
        return 1
    fi

    # Extract tier and company
    local tier=$(echo "$current_path" | sed -n 's|.*/ai_martech/\([^/]*\)/.*|\1|p')
    local company=$(echo "$current_path" | sed -n 's|.*/ai_martech/[^/]*/\([^/]*\)/.*|\1|p')

    if [ -z "$tier" ] || [ -z "$company" ]; then
        echo "ERROR: Could not detect tier/company from path"
        return 1
    fi

    echo "Tier: $tier"
    echo "Company: $company"
    echo "Full Path: $tier/$company"
}

# Usage example
detect_company
```

**Output Examples**:

```bash
# If run from VitalSigns
cd /path/to/ai_martech/l1_basic/VitalSigns/scripts/
./detect_current_company.sh
# Output:
# Tier: l1_basic
# Company: VitalSigns
# Full Path: l1_basic/VitalSigns

# If run from MAMBA
cd /path/to/ai_martech/l4_enterprise/MAMBA/app/
./detect_current_company.sh
# Output:
# Tier: l4_enterprise
# Company: MAMBA
# Full Path: l4_enterprise/MAMBA

# If run from kitchenMAMA
cd /path/to/ai_martech/l4_enterprise/kitchenMAMA/tests/
./detect_current_company.sh
# Output:
# Tier: l4_enterprise
# Company: kitchenMAMA
# Full Path: l4_enterprise/kitchenMAMA
```

---

### Context-Aware Sync Script

```bash
#!/bin/bash
# File: bash/sync_current_company.sh
# Syncs whichever company you're currently in

CURRENT_PATH=$(pwd)

# Detect tier and company
TIER=$(echo "$CURRENT_PATH" | sed -n 's|.*/ai_martech/\([^/]*\)/.*|\1|p')
COMPANY=$(echo "$CURRENT_PATH" | sed -n 's|.*/ai_martech/[^/]*/\([^/]*\)/.*|\1|p')

if [ -z "$TIER" ] || [ -z "$COMPANY" ]; then
    echo "ERROR: Could not detect company from current directory"
    echo "Make sure you're inside a company directory like:"
    echo "  - l1_basic/VitalSigns/"
    echo "  - l4_enterprise/MAMBA/"
    echo "  - l4_enterprise/kitchenMAMA/"
    exit 1
fi

echo "Detected company: $TIER/$COMPANY"
echo "Syncing global_scripts for $COMPANY..."

# Navigate to company root
MARTECH_ROOT="/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech"
cd "$MARTECH_ROOT/$TIER/$COMPANY"

# Sync
git subrepo pull scripts/global_scripts
git commit -m "Sync global_scripts: $(date +%Y-%m-%d) - $COMPANY" || echo "Already up to date"
git push origin main

echo "✓ $COMPANY synced successfully"
```

**Usage Examples**:

```bash
# Example 1: Sync from VitalSigns
cd /path/to/ai_martech/l1_basic/VitalSigns/app/
./bash/sync_current_company.sh
# Output: Detected company: l1_basic/VitalSigns
#         Syncing global_scripts for VitalSigns...
#         ✓ VitalSigns synced successfully

# Example 2: Sync from MAMBA
cd /path/to/ai_martech/l4_enterprise/MAMBA/tests/
./bash/sync_current_company.sh
# Output: Detected company: l4_enterprise/MAMBA
#         Syncing global_scripts for MAMBA...
#         ✓ MAMBA synced successfully

# Example 3: Sync from kitchenMAMA
cd /path/to/ai_martech/l4_enterprise/kitchenMAMA/
./bash/sync_current_company.sh
# Output: Detected company: l4_enterprise/kitchenMAMA
#         Syncing global_scripts for kitchenMAMA...
#         ✓ kitchenMAMA synced successfully
```

---

## 📊 Multi-Company Status Monitoring

### Dashboard Output Example

```bash
./bash/check_all_sync_status.sh

# Example output showing multi-company status:

=== Global Scripts Sync Status ===
Master Repository:
  Commit: a2610f2e
  Branch: main

Application Status:

Tier: l1_basic
  VitalSigns                                                    ✅ SYNCED (a2610f2e)
  InsightForge                                                  ⚠️  OUT OF SYNC (718047a0)
  BrandEdge                                                     ✅ SYNCED (a2610f2e)
  TagPilot                                                      ✅ SYNCED (a2610f2e)
  positioning_app                                               ✅ SYNCED (a2610f2e)
  latex_test                                                    ⚠️  OUT OF SYNC (5f3c8291)

Tier: l3_premium
  VitalSigns_premium                                            ✅ SYNCED (a2610f2e)
  BrandEdge_premium                                             ✅ SYNCED (a2610f2e)
  InsightForge_premium                                          ✅ SYNCED (a2610f2e)

Tier: l4_enterprise
  MAMBA                                                         ⚠️  OUT OF SYNC (9a1b2c3d)
  WISER                                                         ✅ SYNCED (a2610f2e)
  QEF_DESIGN                                                    ✅ SYNCED (a2610f2e)
  kitchenMAMA                                                   ✅ SYNCED (a2610f2e)

=== Summary ===
Total Companies: 14
Synced: 11 ✅
Out of Sync: 3 ⚠️

Companies needing sync:
  - l1_basic/InsightForge
  - l1_basic/latex_test
  - l4_enterprise/MAMBA

Run: ./bash/sync_all_global_scripts.sh
```

---

## 🎓 Best Practices (Universal)

### DO ✅

1. **Use master for planned changes**: Edit in `global_scripts/`, sync to all companies
2. **Sync before deployment**: Always check YOUR company is synced before deploying
3. **Auto-detect company**: Use detection scripts instead of hard-coding paths
4. **Document hot-fixes**: Clearly state which company found the issue
5. **Test across companies**: If fixing for MAMBA, consider impact on VitalSigns, WISER, etc.
6. **Reference principles**: Always cite MP/P/R numbers in commits

### DON'T ❌

1. **Don't assume MAMBA is special**: VitalSigns, WISER, kitchenMAMA are equally valid
2. **Don't hard-code company names**: Use variables `{tier}/{company}` in scripts
3. **Don't skip other companies**: If you fix for one, sync to all
4. **Don't ignore tier diversity**: Test changes in both l1_basic AND l4_enterprise contexts
5. **Don't deploy without sync check**: Outdated principles cause bugs
6. **Don't create company-specific principles**: All principles must be universal

---

## 📋 Pre-Deployment Checklist (Universal Template)

```bash
# Template: Works for ANY company in ANY tier

cd /path/to/ai_martech/{tier}/{company}/

echo "Pre-deployment checklist for {company}..."

# 1. Check sync status
echo "[1/5] Checking if {company} is synced with master..."
git subrepo status scripts/global_scripts

# 2. Sync if needed
echo "[2/5] Syncing if needed..."
git subrepo pull scripts/global_scripts || echo "Already synced"

# 3. Verify principle version
echo "[3/5] Recording principle version..."
grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' > deployment_principles_version.txt
echo "Deploying with principles version: $(cat deployment_principles_version.txt)"

# 4. Run tests (if applicable)
echo "[4/5] Running tests..."
# Add company-specific test commands here

# 5. Final confirmation
echo "[5/5] {company} ready for deployment ✓"
```

**Example: VitalSigns deployment**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/VitalSigns/
echo "Pre-deployment checklist for VitalSigns..."
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts || echo "Already synced"
grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' > deployment_principles_version.txt
echo "VitalSigns ready for deployment ✓"
```

**Example: MAMBA deployment**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/
echo "Pre-deployment checklist for MAMBA..."
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts || echo "Already synced"
grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' > deployment_principles_version.txt
echo "MAMBA ready for deployment ✓"
```

**Example: kitchenMAMA deployment**

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/kitchenMAMA/
echo "Pre-deployment checklist for kitchenMAMA..."
git subrepo status scripts/global_scripts
git subrepo pull scripts/global_scripts || echo "Already synced"
grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' > deployment_principles_version.txt
echo "kitchenMAMA ready for deployment ✓"
```

---

## 🆘 Troubleshooting (Company-Agnostic)

### Problem: "Which company am I in?"

**Solution**: Run detection script

```bash
pwd | sed 's|.*/ai_martech/||'

# Examples:
# l1_basic/VitalSigns/scripts/...
# l4_enterprise/MAMBA/app/...
# l4_enterprise/kitchenMAMA/tests/...
```

### Problem: "How do I sync just my company?"

**Solution**: Use context-aware sync

```bash
cd /path/to/ai_martech/{tier}/{company}/
git subrepo pull scripts/global_scripts
git commit -m "Sync: $(date +%Y-%m-%d)" || true
git push origin main
```

### Problem: "Which companies are affected by my change?"

**Solution**: ALL companies are affected

```bash
# Any principle change affects:
# - l1_basic: VitalSigns, InsightForge, BrandEdge, TagPilot, etc.
# - l3_premium: VitalSigns_premium, BrandEdge_premium, etc.
# - l4_enterprise: MAMBA, WISER, QEF_DESIGN, kitchenMAMA, etc.

# Always sync all companies after changes
./bash/sync_all_global_scripts.sh
```

---

## 📚 Related Documents

- **Architecture**: `docs/ARCHITECTURE_COMPANY_AGNOSTIC.md`
- **Setup Template**: `docs/TEMPLATE_SETUP_COMPANY.md` (to be created)
- **Executive Summary**: `docs/GIT_SUBREPO_EXECUTIVE_SUMMARY_UPDATED.md` (to be created)
- **Principle Index**: `global_scripts/00_principles/INDEX.md`

---

## 🎯 Summary

### Key Takeaways

1. **Company-Agnostic**: All workflows work for VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc.
2. **Tier-Agnostic**: Same patterns apply to l1_basic, l3_premium, l4_enterprise
3. **Auto-Detection**: Use scripts to detect current company instead of hard-coding
4. **Universal Sync**: Changes affect ALL companies - always sync all
5. **Template-Based**: Use `{tier}/{company}` placeholders in documentation

### Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│  Command                          Purpose                    │
├─────────────────────────────────────────────────────────────┤
│  pwd | sed 's|.*/ai_martech/||'  Detect current company     │
│  ./bash/check_all_sync_status.sh Check all companies        │
│  ./bash/sync_all_global_scripts.sh Sync all companies       │
│  git subrepo pull ...             Sync current company      │
│  git subrepo push ...             Push from current company │
└─────────────────────────────────────────────────────────────┘
```

---

**Document**: WORKFLOWS_COMPANY_AGNOSTIC.md
**Author**: Principle-Explorer
**Date**: 2025-10-03
**Status**: CORRECTED - Universal Workflow Patterns
**Per**: MP001_axiomatization_system

**Note**: This document supersedes WORKFLOWS_GIT_SUBREPO.md which incorrectly used MAMBA-centric examples.
