# Template: Adding 00_principles to Any Company Project

**Purpose**: Step-by-step guide for adding principle system to ANY company in ANY tier
**Audience**: Developers setting up new company projects
**Date**: 2025-10-03
**Status**: UNIVERSAL SETUP TEMPLATE

---

## 🎯 Overview

This template works for **ANY company** in **ANY tier**:
- ✅ l1_basic companies (VitalSigns, InsightForge, etc.)
- ✅ l2_pro companies
- ✅ l3_premium companies (VitalSigns_premium, etc.)
- ✅ l4_enterprise companies (MAMBA, WISER, kitchenMAMA, etc.)

**Key Point**: The process is IDENTICAL regardless of company name or tier.

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] Git installed and configured
- [ ] Git-subrepo installed (`brew install git-subrepo` on macOS)
- [ ] GitHub account with SSH keys configured
- [ ] Access to `https://github.com/kiki830621/ai_martech_global_scripts`
- [ ] Company directory already created in appropriate tier

**Verify Git Subrepo**:
```bash
git subrepo --version
# Should show: git-subrepo version x.x.x
```

**Verify GitHub Access**:
```bash
ssh -T git@github.com
# Should show: Hi username! You've successfully authenticated...
```

---

## 🚀 Setup Process (Step-by-Step)

### Step 1: Navigate to Company Directory

```bash
# Template command (replace {tier} and {company} with your values)
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/{tier}/{company}/

# Example 1: New l1_basic company "ProductMatrix"
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/ProductMatrix/

# Example 2: New l4_enterprise company "GlobalCorp"
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/GlobalCorp/

# Example 3: New l3_premium company "EliteAnalytics"
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l3_premium/EliteAnalytics/

# Verify you're in the right place
pwd
# Should show: .../ai_martech/{tier}/{company}
```

---

### Step 2: Initialize Git Repository (if needed)

```bash
# Check if already a git repository
if [ -d .git ]; then
    echo "Git repository already exists ✓"
else
    echo "Initializing git repository..."
    git init
    git branch -M main
fi

# Verify
git status
# Should show: On branch main
```

---

### Step 3: Add Company GitHub Remote (if needed)

```bash
# Template command (replace {org} and {company_repo})
git remote add origin https://github.com/{org}/{company_repo}.git

# Example 1: l1_basic company
git remote add origin https://github.com/myorg/ProductMatrix.git

# Example 2: l4_enterprise company
git remote add origin https://github.com/enterprise/GlobalCorp.git

# Verify
git remote -v
# Should show:
# origin  https://github.com/{org}/{company_repo}.git (fetch)
# origin  https://github.com/{org}/{company_repo}.git (push)
```

**Note**: If remote already exists, skip this step.

---

### Step 4: Clone Principles as Git Subrepo

```bash
# This command is IDENTICAL for ALL companies
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

# What this does:
# 1. Creates scripts/global_scripts/ directory
# 2. Copies all principles (MP001-MP030+) from GitHub
# 3. Creates .gitrepo file to track sync state
# 4. Adds files to git staging area

# Expected output:
# git-subrepo: 'scripts/global_scripts' cloned from 'https://github.com/kiki830621/ai_martech_global_scripts.git'.
```

**Wait Time**: This may take 30-60 seconds depending on connection speed.

---

### Step 5: Verify Subrepo Setup

```bash
# Check that subrepo was created correctly
echo "Checking subrepo setup..."

# 1. Verify .gitrepo file exists
if [ -f scripts/global_scripts/.gitrepo ]; then
    echo "✓ .gitrepo file exists"
else
    echo "✗ .gitrepo file missing - setup failed"
    exit 1
fi

# 2. Verify principle files exist
if [ -d scripts/global_scripts/00_principles ]; then
    echo "✓ 00_principles directory exists"
    PRINCIPLE_COUNT=$(ls scripts/global_scripts/00_principles/MP*.md 2>/dev/null | wc -l)
    echo "  Found $PRINCIPLE_COUNT principle files"
else
    echo "✗ 00_principles directory missing - setup failed"
    exit 1
fi

# 3. Check subrepo status
git subrepo status scripts/global_scripts
# Should show: scripts/global_scripts is up to date

# 4. View .gitrepo contents
cat scripts/global_scripts/.gitrepo
# Should show:
# [subrepo]
#     remote = https://github.com/kiki830621/ai_martech_global_scripts.git
#     branch = main
#     commit = [commit_hash]
#     ...
```

---

### Step 6: Commit Subrepo Addition

```bash
# Template commit message (customize for your company)
git commit -m "Add global_scripts subrepo to {company}

Initialize principle system for {company} project.

- Added 257+ principles from master repository
- Company: {company}
- Tier: {tier}
- Subrepo remote: github.com/kiki830621/ai_martech_global_scripts

This company now synced with:
- l1_basic: VitalSigns, InsightForge, BrandEdge, TagPilot, etc.
- l3_premium: VitalSigns_premium, BrandEdge_premium, etc.
- l4_enterprise: MAMBA, WISER, QEF_DESIGN, kitchenMAMA, etc.

All companies share the same principles - no company-specific variations.

Per MP001_axiomatization_system"

# Example 1: l1_basic company "ProductMatrix"
git commit -m "Add global_scripts subrepo to ProductMatrix

Initialize principle system for ProductMatrix project.

- Added 257+ principles from master repository
- Company: ProductMatrix
- Tier: l1_basic
- Subrepo remote: github.com/kiki830621/ai_martech_global_scripts

Now synced with VitalSigns, MAMBA, WISER, kitchenMAMA, etc.

Per MP001_axiomatization_system"

# Example 2: l4_enterprise company "GlobalCorp"
git commit -m "Add global_scripts subrepo to GlobalCorp

Initialize principle system for GlobalCorp project.

- Added 257+ principles from master repository
- Company: GlobalCorp
- Tier: l4_enterprise
- Subrepo remote: github.com/kiki830621/ai_martech_global_scripts

Now synced with MAMBA, WISER, kitchenMAMA, VitalSigns, etc.

Per MP001_axiomatization_system"
```

---

### Step 7: Push to Company GitHub Repository

```bash
# Initial push to GitHub
git push -u origin main

# Expected output:
# Enumerating objects: X, done.
# ...
# To https://github.com/{org}/{company_repo}.git
#  * [new branch]      main -> main

# If push fails, check:
# 1. GitHub remote is correct: git remote -v
# 2. You have push access to the repository
# 3. Branch name matches (main vs master)
```

---

### Step 8: Final Verification

```bash
echo "=== Final Setup Verification ==="

# 1. Check git status
echo "[1/5] Git status check..."
git status
# Should show: working tree clean

# 2. Verify subrepo tracking
echo "[2/5] Subrepo status check..."
git subrepo status scripts/global_scripts
# Should show: scripts/global_scripts is up to date

# 3. Count principle files
echo "[3/5] Principle file count..."
PRINCIPLE_COUNT=$(ls scripts/global_scripts/00_principles/MP*.md 2>/dev/null | wc -l | tr -d ' ')
echo "Found $PRINCIPLE_COUNT Meta-Principles"
# Should show: 30+ files

# 4. Verify master sync
echo "[4/5] Master repository sync check..."
MARTECH_ROOT="/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech"
MASTER_COMMIT=$(cd "$MARTECH_ROOT/global_scripts" && git rev-parse --short HEAD)
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' | cut -c1-8)
if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ Synced with master (commit: $MASTER_COMMIT)"
else
    echo "⚠ Out of sync (master: $MASTER_COMMIT, subrepo: $SUBREPO_COMMIT)"
    echo "This is normal if master was updated after your clone"
fi

# 5. GitHub remote check
echo "[5/5] GitHub remote check..."
git remote -v | grep origin
# Should show your company's GitHub repository

echo ""
echo "=== Setup Complete ✓ ==="
echo "Company: {company}"
echo "Tier: {tier}"
echo "Principles: $PRINCIPLE_COUNT files"
echo ""
echo "Next steps:"
echo "1. Start development in this company directory"
echo "2. Run 'git subrepo pull scripts/global_scripts' to get updates"
echo "3. Read scripts/global_scripts/00_principles/INDEX.md for principle overview"
```

---

## 📚 Post-Setup: Using Principles

### Reading Principles

```bash
# View principle index
cat scripts/global_scripts/00_principles/INDEX.md

# Read specific principle
cat scripts/global_scripts/00_principles/MP001_axiomatization_system.md
cat scripts/global_scripts/00_principles/R092_universal_DBI.md

# Search for principles related to topic
grep -r "database" scripts/global_scripts/00_principles/
```

### Applying Principles in Code

```r
# Example: Using R092_universal_DBI in your app

# Load database connection utility
source("scripts/global_scripts/01_db/dbConnect.R")

# Use universal DBI pattern
con <- dbConnect_universal()

# Use tbl2() for data access (per R092)
source("scripts/global_scripts/02_db_utils/fn_tbl2.R")
customers <- tbl2(con, "customers") %>%
  filter(status == "active") %>%
  collect()

# This code works IDENTICALLY in:
# - VitalSigns (l1_basic with DuckDB)
# - MAMBA (l4_enterprise with PostgreSQL)
# - kitchenMAMA (l4_enterprise with PostgreSQL)
# - Your company (any tier, any database)
```

### Syncing Principle Updates

```bash
# Weekly or before major work: pull latest principles
git subrepo pull scripts/global_scripts

# Commit the sync
git commit -m "Sync global_scripts: $(date +%Y-%m-%d)"
git push origin main

# Check if you're behind master
MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse --short HEAD)
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' | cut -c1-8)
if [ "$MASTER_COMMIT" != "$SUBREPO_COMMIT" ]; then
    echo "Principles updated in master - run: git subrepo pull scripts/global_scripts"
fi
```

---

## 🔧 Troubleshooting

### Issue: "git subrepo: command not found"

**Solution**:
```bash
# Install git-subrepo on macOS
brew install git-subrepo

# Or install manually
git clone https://github.com/ingydotnet/git-subrepo ~/.git-subrepo
echo 'source ~/.git-subrepo/.rc' >> ~/.zshrc
source ~/.zshrc

# Verify installation
git subrepo --version
```

---

### Issue: "Permission denied (publickey)"

**Solution**:
```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub:
# 1. Go to github.com → Settings → SSH and GPG keys
# 2. Click "New SSH key"
# 3. Paste your public key

# Test connection
ssh -T git@github.com
# Should show: Hi username! You've successfully authenticated
```

---

### Issue: "scripts/global_scripts already exists"

**Solution**:
```bash
# If you need to re-initialize:
# 1. Remove existing directory
rm -rf scripts/global_scripts

# 2. Re-clone subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts

# 3. Commit
git commit -m "Re-initialize global_scripts subrepo"
```

---

### Issue: "Subrepo shows 'out of sync'"

**Solution**:
```bash
# This is normal - master repository may have been updated
# Simply pull latest changes
git subrepo pull scripts/global_scripts

# Commit the sync
git commit -m "Sync global_scripts with master"
git push origin main
```

---

## ✅ Setup Checklist

Print this checklist and check off each item:

### Pre-Setup
- [ ] Git installed and working
- [ ] Git-subrepo installed (`git subrepo --version` works)
- [ ] SSH keys configured for GitHub
- [ ] Company directory exists in correct tier
- [ ] GitHub repository created for company

### Setup Steps
- [ ] Navigated to company directory
- [ ] Git repository initialized (or already exists)
- [ ] Company GitHub remote added
- [ ] Git subrepo clone command executed successfully
- [ ] .gitrepo file exists in scripts/global_scripts/
- [ ] 00_principles directory exists with 30+ MP files
- [ ] Subrepo commit created
- [ ] Changes pushed to company GitHub repo

### Verification
- [ ] `git status` shows clean working tree
- [ ] `git subrepo status scripts/global_scripts` shows "up to date"
- [ ] `ls scripts/global_scripts/00_principles/MP*.md` shows 30+ files
- [ ] `git remote -v` shows correct company GitHub URL
- [ ] Can read principle files (INDEX.md, MP001.md, etc.)

### Post-Setup
- [ ] Read `scripts/global_scripts/00_principles/INDEX.md`
- [ ] Understand how to apply principles in code
- [ ] Know how to sync principle updates
- [ ] Bookmarked this template for future reference

---

## 📊 Company Examples

### Example 1: VitalSigns (l1_basic)

```bash
cd /path/to/ai_martech/l1_basic/VitalSigns/
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
git commit -m "Add global_scripts subrepo to VitalSigns

- Company: VitalSigns
- Tier: l1_basic
- Now synced with MAMBA, WISER, kitchenMAMA, etc.

Per MP001_axiomatization_system"
git push -u origin main
```

**Status**: ✅ Uses DuckDB, same principles as MAMBA

---

### Example 2: MAMBA (l4_enterprise)

```bash
cd /path/to/ai_martech/l4_enterprise/MAMBA/
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
git commit -m "Add global_scripts subrepo to MAMBA

- Company: MAMBA
- Tier: l4_enterprise
- Now synced with VitalSigns, WISER, kitchenMAMA, etc.

Per MP001_axiomatization_system"
git push -u origin main
```

**Status**: ✅ Uses PostgreSQL, same principles as VitalSigns

---

### Example 3: kitchenMAMA (l4_enterprise)

```bash
cd /path/to/ai_martech/l4_enterprise/kitchenMAMA/
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
git commit -m "Add global_scripts subrepo to kitchenMAMA

- Company: kitchenMAMA
- Tier: l4_enterprise
- Now synced with MAMBA, WISER, VitalSigns, etc.

Per MP001_axiomatization_system"
git push -u origin main
```

**Status**: ✅ Uses PostgreSQL, same principles as MAMBA and VitalSigns

---

### Example 4: InsightForge (l1_basic)

```bash
cd /path/to/ai_martech/l1_basic/InsightForge/
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
git commit -m "Add global_scripts subrepo to InsightForge

- Company: InsightForge
- Tier: l1_basic
- Now synced with VitalSigns, MAMBA, WISER, etc.

Per MP001_axiomatization_system"
git push -u origin main
```

**Status**: ✅ Uses DuckDB, same principles as all other companies

---

## 🎓 Key Principles to Remember

### Principle Equality
- VitalSigns (l1_basic) has **IDENTICAL** principles to MAMBA (l4_enterprise)
- kitchenMAMA has **IDENTICAL** principles to InsightForge
- Tier determines feature complexity, NOT principle content

### Universal Applicability
- MP001 applies to ALL companies
- R092_universal_DBI applies to ALL companies (VitalSigns with DuckDB, MAMBA with PostgreSQL)
- No company-specific principle variations allowed

### Sync Responsibility
- After setup, your company is part of global sync system
- When master principles update, ALL companies should sync
- Use `git subrepo pull scripts/global_scripts` regularly

---

## 📚 Next Steps After Setup

1. **Read Principle Index**:
   ```bash
   cat scripts/global_scripts/00_principles/INDEX.md
   ```

2. **Review Key Principles**:
   - MP001: Axiomatization System
   - R092: Universal DBI
   - [Others relevant to your work]

3. **Apply Principles in Code**:
   - Use `scripts/global_scripts/` modules in your app
   - Follow principle-based patterns
   - Reference principles in commit messages

4. **Stay Synced**:
   ```bash
   # Weekly sync recommended
   git subrepo pull scripts/global_scripts
   git commit -m "Weekly principle sync"
   git push origin main
   ```

5. **Contribute Back** (if needed):
   - If you find principle bugs, fix in your company context
   - Push to GitHub using Model B workflow
   - Immediately notify team to sync all companies

---

## 🔗 Related Documents

- **Architecture**: `docs/ARCHITECTURE_COMPANY_AGNOSTIC.md`
- **Workflows**: `docs/WORKFLOWS_COMPANY_AGNOSTIC.md`
- **Executive Summary**: `docs/GIT_SUBREPO_EXECUTIVE_SUMMARY_UPDATED.md`
- **Principle Index**: `scripts/global_scripts/00_principles/INDEX.md` (after setup)

---

## 🆘 Getting Help

**If Setup Fails**:
1. Re-read this template step-by-step
2. Check troubleshooting section above
3. Verify prerequisites (git-subrepo installed, GitHub access)
4. Ask principle-explorer or principle-coder for help

**If Principles Don't Make Sense**:
1. Read `scripts/global_scripts/00_principles/INDEX.md`
2. Review specific principle files (MP001, R092, etc.)
3. Look at code examples in other companies (VitalSigns, MAMBA)
4. Ask principle-explorer for interpretation

---

**Document**: TEMPLATE_SETUP_COMPANY.md
**Author**: Principle-Explorer
**Date**: 2025-10-03
**Status**: UNIVERSAL SETUP TEMPLATE
**Per**: MP001_axiomatization_system

**Note**: This template works for ANY company (VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc.) in ANY tier (l1_basic, l2_pro, l3_premium, l4_enterprise). The process is IDENTICAL regardless of company name or tier.
