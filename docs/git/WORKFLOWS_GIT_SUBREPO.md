# Git Subrepo Workflows: Practical Guide

**Purpose**: Quick reference for common git subrepo operations
**Audience**: All developers working with ai_martech principles
**Date**: 2025-10-03
**Related**: ARCHITECTURE_GIT_SUBREPO_CORRECTED.md

---

## 🎯 Quick Command Reference

### Check Sync Status (All Apps)

```bash
# Run status check
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/check_all_sync_status.sh
```

**Output**:
```
=== Global Scripts Sync Status ===
Master Repository:
  Commit: a2610f2e
  Branch: main

Application Status:

l1_basic/VitalSigns                                         ✓ SYNCED (a2610f2e)
l1_basic/InsightForge                                       ⚠ OUT OF SYNC (718047a0 ≠ a2610f2e)
l4_enterprise/MAMBA                                         ✓ SYNCED (a2610f2e)
...
```

---

### Sync All Apps (Automated)

```bash
# Weekly sync (recommended: Monday mornings)
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

**What it does**:
1. Updates master `global_scripts/` from GitHub
2. Syncs all app instances via `git subrepo pull`
3. Commits and pushes changes to each app's GitHub repo
4. Logs all operations

---

## 📝 Workflow Scenarios

### Scenario 1: Adding New Principle (Centralized - RECOMMENDED)

**Context**: You want to add MP031 to the principle system

```bash
# 1. Navigate to master repository
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/global_scripts/

# 2. Create principle file
cat > 00_principles/MP031_new_principle.md << 'EOF'
# MP031: New Principle Name

## Principle Statement
[Clear, concise statement of the principle]

## Rationale
[Why this principle exists]

## Application
[How to apply this principle]

## Related Principles
- MP001_axiomatization_system
- [Other related principles]

## Examples
[Code or conceptual examples]
EOF

# 3. Update INDEX.md
vi 00_principles/INDEX.md
# Add MP031 to appropriate category

# 4. Commit to master
git add 00_principles/MP031_new_principle.md 00_principles/INDEX.md
git commit -m "Add MP031: New Principle Name

- Brief description of what principle addresses
- Why it was needed
- Impact on existing code

Related Principles: MP001
Per MP001_axiomatization_system"

# 5. Push to GitHub
git push origin main

# 6. Sync to all applications
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh
```

---

### Scenario 2: Fixing Principle Bug (Emergency Distributed)

**Context**: You discovered MP015 has incorrect example while working in MAMBA

```bash
# 1. You're working in MAMBA and notice the bug
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/

# 2. Fix the principle directly in app's subrepo
vi scripts/global_scripts/00_principles/MP015_existing_principle.md
# Make the correction

# 3. Commit within the subrepo
cd scripts/global_scripts/
git add 00_principles/MP015_existing_principle.md
git commit -m "HOT-FIX from MAMBA: Correct MP015 database connection example

Issue: Example code had incorrect parameter order in dbConnect() call
Context: Discovered during MAMBA deployment troubleshooting
Impact: Affects all apps using R092_universal_DBI pattern
Fix: Corrected parameter order to match actual DBI interface

Related Principles: MP001, R092
Per MP001_axiomatization_system"
cd ../..

# 4. Push subrepo changes to GitHub
git subrepo push scripts/global_scripts

# 5. IMMEDIATELY sync master repository
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/global_scripts/
git pull origin main

# 6. IMMEDIATELY sync all other apps
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/sync_all_global_scripts.sh

# 7. Notify team (Slack/Email)
# "HOT-FIX: MP015 corrected from MAMBA - all apps synced"
```

---

### Scenario 3: Syncing Single App

**Context**: You want to update just one app (e.g., VitalSigns) without running full sync

```bash
# Navigate to app
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/VitalSigns/

# Check current status
git subrepo status scripts/global_scripts

# Pull latest from GitHub
git subrepo pull scripts/global_scripts

# Commit the sync
git commit -m "Sync global_scripts: $(date +%Y-%m-%d)

Updated to latest principles from master repository

Per MP001_axiomatization_system"

# Push to app's GitHub repo
git push origin main
```

---

### Scenario 4: Checking If App Needs Sync

**Context**: Before deploying MAMBA, verify it has latest principles

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA/

# Get master commit
MASTER_COMMIT=$(cd ../../global_scripts && git rev-parse HEAD)

# Get subrepo commit
SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')

# Compare
if [ "$MASTER_COMMIT" == "$SUBREPO_COMMIT" ]; then
    echo "✓ App is synced with master"
else
    echo "⚠ App is out of sync - run: git subrepo pull scripts/global_scripts"
fi
```

---

### Scenario 5: Resolving Merge Conflict

**Context**: Two apps edited same principle simultaneously

```bash
# Scenario:
# - App A pushed changes to MP020
# - App B also edited MP020
# - App B tries to pull and gets conflict

# In App B
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l1_basic/InsightForge/

# Attempt to pull (will show conflict)
git subrepo pull scripts/global_scripts
# ERROR: Merge conflict in scripts/global_scripts/00_principles/MP020.md

# Enter subrepo to resolve
cd scripts/global_scripts/

# Check conflict
git status
# You will see:
# both modified:   00_principles/MP020.md

# Resolve conflict manually
vi 00_principles/MP020.md

# The file will have conflict markers:
# <<<<<<< HEAD
# [App B's changes]
# =======
# [App A's changes]
# >>>>>>> [commit hash]

# Edit to merge both changes appropriately
# Remove conflict markers
# Save file

# Mark as resolved
git add 00_principles/MP020.md

# Commit resolution
git commit -m "CONFLICT-RESOLUTION: MP020 from InsightForge + [Other App]

Merged changes:
- From InsightForge: [describe InsightForge's changes]
- From [Other App]: [describe other app's changes]
- Resolution: [explain how you merged both sets of changes]

Both changes were valid and complementary. Merged into single coherent principle.

Related Principles: MP001
Per MP001_axiomatization_system"

# Return to app root
cd ../..

# Push resolved version to GitHub
git subrepo push scripts/global_scripts

# Sync master and all other apps
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/global_scripts/
git pull origin main

cd ..
./bash/sync_all_global_scripts.sh
```

---

## 🔧 Troubleshooting

### Problem: "git subrepo command not found"

**Solution**: Install git-subrepo

```bash
# On macOS with Homebrew
brew install git-subrepo

# Or install manually
git clone https://github.com/ingydotnet/git-subrepo /path/to/git-subrepo
echo 'source /path/to/git-subrepo/.rc' >> ~/.bashrc
source ~/.bashrc
```

---

### Problem: "scripts/global_scripts is not a subrepo"

**Solution**: Check `.gitrepo` file exists

```bash
cd /path/to/app/

# Check if .gitrepo exists
ls -la scripts/global_scripts/.gitrepo

# If missing, initialize subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts
```

---

### Problem: "Permission denied (publickey)"

**Solution**: Check GitHub SSH keys

```bash
# Test GitHub connection
ssh -T git@github.com

# If fails, add SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add this to GitHub: Settings → SSH and GPG keys
```

---

### Problem: Sync script shows "Could not push to GitHub"

**Solution**: Check app's git status

```bash
cd /path/to/app/

# Check for uncommitted changes
git status

# Check remote configuration
git remote -v

# Try manual push
git push origin main
# Read error message for specific issue
```

---

## 📊 Monitoring & Maintenance

### Daily Check (Quick)

```bash
# Quick status check (30 seconds)
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/check_all_sync_status.sh | grep "OUT OF SYNC"

# If any output → run sync
# If no output → all apps synced
```

---

### Weekly Sync (Automated)

**Add to crontab**:

```bash
# Edit crontab
crontab -e

# Add line (runs every Monday at 9 AM)
0 9 * * 1 /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/bash/sync_all_global_scripts.sh

# Verify
crontab -l
```

---

### Monthly Audit (Comprehensive)

```bash
# 1. Run full status check
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech
./bash/check_all_sync_status.sh > /tmp/sync_audit_$(date +%Y%m%d).txt

# 2. Review log file
cat bash/logs/sync_global_scripts_*.log | grep "FAILED"

# 3. Check master repository health
cd global_scripts/
git log --oneline -20
git status

# 4. Verify GitHub repository
open "https://github.com/kiki830621/ai_martech_global_scripts"

# 5. Document any issues found
vi docs/SYNC_AUDIT_$(date +%Y%m%d).md
```

---

## 📋 Pre-Deployment Checklist

Before deploying ANY application:

```bash
cd /path/to/app/

# [ ] Check sync status
git subrepo status scripts/global_scripts
# Should say: "scripts/global_scripts is up to date"

# [ ] If not synced, pull latest
git subrepo pull scripts/global_scripts
git commit -m "Pre-deployment sync: global_scripts"
git push origin main

# [ ] Verify principles loaded correctly
# (Run app locally and check that principle-based code works)

# [ ] Document principle versions in deployment log
grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}' > deployment_principles_version.txt
```

---

## 🎓 Best Practices

### DO ✅

1. **Always sync before major work**: `git subrepo pull scripts/global_scripts`
2. **Use centralized workflow for planned changes**: Edit in master, then sync apps
3. **Use distributed workflow only for emergencies**: Hot-fixes from app context
4. **Run status check before deploying**: Ensure app has latest principles
5. **Document all principle changes**: Reference related principles in commits
6. **Notify team of hot-fixes**: Immediate communication when pushing from app

### DON'T ❌

1. **Don't edit principles in multiple apps simultaneously**: Causes conflicts
2. **Don't skip sync after hot-fix**: Other apps need the fix immediately
3. **Don't modify archived principles**: Per MP030_archive_immutability
4. **Don't commit without principle references**: Per MP001_axiomatization_system
5. **Don't deploy without sync check**: May use outdated principles
6. **Don't ignore merge conflicts**: Resolve immediately to prevent principle divergence

---

## 📚 Related Resources

- **Architecture Document**: `docs/ARCHITECTURE_GIT_SUBREPO_CORRECTED.md`
- **Principle Index**: `global_scripts/00_principles/INDEX.md`
- **Sync Script**: `bash/sync_all_global_scripts.sh`
- **Status Checker**: `bash/check_all_sync_status.sh`
- **GitHub Repository**: https://github.com/kiki830621/ai_martech_global_scripts

---

## 🆘 Getting Help

### For Sync Issues
1. Check this workflow guide
2. Run `./bash/check_all_sync_status.sh` for diagnostics
3. Review sync log: `bash/logs/sync_global_scripts_*.log`
4. Contact: principle-explorer or principle-coder

### For Principle Questions
1. Read principle file: `global_scripts/00_principles/MP*.md`
2. Check INDEX.md for related principles
3. Review commit history: `cd global_scripts && git log --grep="MP[0-9]" -20`
4. Ask principle-explorer for interpretation

---

**Last Updated**: 2025-10-03
**Maintainer**: Principle-Explorer
**Review Cycle**: After each major sync operation or monthly
