# L3 Premium Directory

This directory contains premium-tier applications with advanced features between L2 Pro and L4 Enterprise levels.

## 📁 Directory Structure

### Current Applications
- `TagPilot_premium/` - Customer DNA analysis (Premium version)
- `VitalSigns_premium/` - Customer health monitoring (Premium version)
- `InsightForge_premium/` - Data insights platform (Premium version)
- `BrandEdge_premium/` - Brand analysis and positioning (Premium version)
- `sandbox/` - Development and testing environment
- `wonderful_food/` - Client-specific applications for Wonderful Food

### Support Directories
- `template/` - Template files for new premium applications
- `archive/` - Archived premium applications
- `data/` - Shared data resources for premium applications

## 🚀 Creating New L3 Premium Applications

### Step 1: Copy Existing Application as Template
```bash
# Choose an existing app as template (e.g., TagPilot_premium)
cp -r TagPilot_premium [new_app_name]_premium
cd [new_app_name]_premium
```

### Step 2: Clean Old Files
```bash
# Remove old Git and RStudio files
rm -rf .git .Rproj.user *.Rproj
rm -rf archive/* data/test_data/*
```

### Step 3: Initialize Git Repository
```bash
git init
```

### Step 4: Set Up Git Subrepo for global_scripts
```bash
# Remove existing global_scripts directory if present
rm -rf scripts/global_scripts

# Commit current state before adding subrepo
git add -A
git commit -m "Initial commit: [App Name] Premium"

# Clone global_scripts as subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts --branch=main
```

### Step 5: Create GitHub Repository and Push
```bash
# Create private GitHub repository using GitHub CLI
gh repo create [app_name]_premium --private --source=. --remote=origin --push

# Or if you want to create manually and then push:
git remote add origin https://github.com/[username]/[app_name]_premium.git
git push -u origin main
```

## 📦 Working with Git Subrepo

### Update global_scripts from Remote
```bash
# Pull latest changes from global_scripts repository
git subrepo pull scripts/global_scripts
```

### Push Local Changes to global_scripts
```bash
# Push your changes to the global_scripts repository (requires permission)
git subrepo push scripts/global_scripts
```

### Check Subrepo Status
```bash
# View current status of the subrepo
git subrepo status scripts/global_scripts
```

### Troubleshooting Subrepo
If you get error: `No 'scripts/global_scripts/.gitrepo' file`, the subrepo needs to be initialized:

```bash
# Remove existing directory
rm -rf scripts/global_scripts

# Commit the removal
git add -A && git commit -m "Remove global_scripts to prepare for subrepo"

# Clone as subrepo
git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts --branch=main
```

## 🏷️ Naming Conventions

### Standard Applications
- Format: `[AppName]_premium`
- Examples: `TagPilot_premium`, `InsightForge_premium`

### Client-Specific Applications
- Format: `[client_name]_[AppName]_premium`
- Example: `wonderful_food_BrandEdge_premium`

## 📝 app_config.yaml Template

```yaml
app_info:
  name: "[App Name] Premium"
  version: "1.0.0"
  tier: "l3_premium"

database:
  type: "postgresql"
  test_mode: false

deployment:
  target: "connect"
  account: "kyle-lin"

theme:
  primary_color: "#007bff"
  bootswatch: "cosmo"
```

## 🔧 Development Workflow

1. **Local Development**: Work in your app directory
2. **Update global_scripts**: Use `git subrepo pull` to get latest shared code
3. **Test Locally**: Run `Rscript app.R` or use RStudio
4. **Commit Changes**: Regular git commits to track progress
5. **Push to GitHub**: Keep remote repository updated
6. **Deploy**: Use Posit Connect Cloud for deployment

## ⚠️ Important Notes

1. **Git Subrepo Required**: All L3 Premium apps should use git subrepo for `global_scripts`
2. **Private Repositories**: Use `--private` flag when creating GitHub repos
3. **Environment Variables**: Never commit `.env` files
4. **Data Protection**: Add large data files to `.gitignore`
5. **Consistent Structure**: Follow the standard app structure for maintainability

