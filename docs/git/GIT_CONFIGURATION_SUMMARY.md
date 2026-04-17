# Git Configuration Summary

## Repository Architecture Overview

This document provides a comprehensive overview of the Git configuration and synchronization strategy for the `ai_martech` project.

## 🏗️ Multi-Level Git Subrepo Structure

### Main Repository: `ai_martech`
- **Type**: Git repository with subrepos (not submodules)
- **Strategy**: Simplified user experience with nested dependencies
- **Total Subrepos**: 18

### Repository Hierarchy

```
ai_martech/ (main repo)
├── global_scripts/ (subrepo - shared modules)
│   └── 16_NSQL_Language/ (nested subrepo)
├── l1_basic/
│   ├── InsightForge/ (subrepo)
│   │   └── scripts/global_scripts/ (subrepo copy)
│   ├── positioning_app/ (subrepo)
│   │   └── scripts/global_scripts/ (subrepo copy)
│   ├── TagPilot/ (subrepo)
│   │   └── scripts/global_scripts/ (subrepo copy)
│   └── VitalSigns/ (subrepo)
│       └── scripts/global_scripts/ (subrepo copy)
├── l2_pro/
│   └── TagPilot/ (subrepo)
│       └── scripts/global_scripts/ (subrepo copy)
└── l4_enterprise/
    └── WISER/ (subrepo)
        └── scripts/global_scripts/ (subrepo copy)
```

## 🔄 Multi-Copy Synchronization Challenge

### The Problem
- `global_scripts` exists in multiple independent copies
- Each copy has its own `.gitrepo` file with different commit SHAs
- Modifying one copy doesn't automatically sync others
- Manual synchronization would be error-prone and time-consuming

### The Solution
- Automated synchronization workflow: `push --ALL` → `pull --ALL` → `commit`
- Implemented in `bash/subrepo_sync.sh` with AI assistance
- Ensures all copies stay synchronized with proper dependency ordering

## 📋 Synchronization Workflow Details

### Primary Sync Script: `bash/subrepo_sync.sh`

#### 7-Step Process

1. **Clean Working Directory**
   - Auto-commits uncommitted changes
   - AI-generated commit messages using Claude Code
   - Three modes: auto (default), manual, interactive

2. **Push Phase (Author Date + Depth Sorted)**
   - Sorts by Git author timestamp (oldest first)
   - Then by directory depth (deepest first)
   - Three-phase retry strategy:
     - Phase 1: Normal push
     - Phase 2: Retry failed pushes
     - Phase 3: Force push if needed

3. **Pull Phase (BFS Order)**
   - Breadth-First Search ordering
   - Processes shallow repos before deep ones
   - Automatic conflict detection
   - Interactive resolution options

4. **Commit .gitrepo Updates**
   - Updates all `.gitrepo` files atomically
   - Single commit for consistency

5. **Push Main Repository**
   - Ensures remote is updated

6. **Generate Summary**
   - Claude Code sync report
   - Success/failure statistics
   - Detailed operation log

7. **Optional Manual Review**
   - For interactive mode only

### Ordering Strategies

#### Push Order (Dependencies First)
1. Sort by author date (oldest commits first)
2. Sort by depth (deepest directories first)
3. Ensures dependencies are pushed before dependents

#### Pull Order (BFS)
1. Level 0: Root subrepos
2. Level 1: First-level nested subrepos
3. Level 2+: Deeper nested subrepos
4. Prevents dependency conflicts

## 🤖 AI Integration Features

### Intelligent Commit Messages
- Claude Code analyzes file changes
- Pattern-based message generation:
  - `app.R` → "update application"
  - `global_scripts/` → "sync modules and assets"
  - `.md` files → "update documentation"
  - Config files → "update configuration"

### Conflict Resolution
- Automatic conflict detection
- Four resolution options:
  1. Manual editing
  2. Use local version
  3. Use remote version
  4. Skip repository
- File-type specific review suggestions

## 🛠️ Usage Commands

### Basic Synchronization
```bash
# Default (auto mode)
./bash/subrepo_sync.sh

# Manual commit messages
./bash/subrepo_sync.sh manual

# Interactive mode
./bash/subrepo_sync.sh interactive
```

### Claude Code Integration
```bash
# Slash command in settings.local.json
/SYNC              # Default auto mode
/SYNC manual       # Manual commit messages
/SYNC interactive  # Full interactive mode
```

### Safety Checks
```bash
# Pre-push validation
./bash/check_before_push.sh

# Interactive sync (legacy)
./bash/sync_all_repos.sh

# Quick sync (deprecated)
./bash/quick_sync_all.sh
```

## 📊 Current Repository Status

### Subrepo List
1. **Core Module**: `global_scripts`
2. **L1 Basic Apps**: InsightForge, positioning_app, TagPilot, VitalSigns
3. **L2 Pro Apps**: TagPilot
4. **L3 Enterprise Apps**: WISER
5. **Nested**: `16_NSQL_Language` (inside global_scripts)
6. **App Copies**: Each app's `scripts/global_scripts`

### Synchronization Health
- All subrepos synchronized as of last run
- No pending conflicts
- Clean working directories across all repos

## 🎯 Best Practices

### Daily Workflow
1. **Morning Sync**: Start day with `./bash/subrepo_sync.sh`
2. **Before Major Changes**: Run safety checks
3. **Evening Sync**: End day with synchronization
4. **Weekly Review**: Check sync logs for issues

### Development Guidelines
1. **Always use sync scripts** - avoid manual git subrepo commands
2. **Commit frequently** - smaller commits sync better
3. **Use auto mode** for routine operations
4. **Switch to interactive** for complex changes
5. **Monitor AI summaries** for unexpected changes

### Troubleshooting
1. **Conflicts**: Use interactive mode for resolution
2. **Failed pushes**: Script auto-retries with force option
3. **Stale copies**: Full sync resolves inconsistencies
4. **Large changes**: Consider manual mode for commit messages

## 📈 Performance Optimization

### Parallel Operations
- Sync script processes repos sequentially for safety
- Future enhancement: parallel push/pull for independent repos

### Caching
- Git objects cached locally
- Reduces network traffic for frequent syncs

### Incremental Updates
- Only changed repos are pushed/pulled
- Skips up-to-date repositories automatically

## 🔒 Security Considerations

### Access Control
- Each subrepo can have different access permissions
- Sync respects repository-level security

### Sensitive Data
- Pre-push checks prevent accidental commits
- Environment variables never synced
- Customer data excluded via .gitignore

## 📚 Related Documentation

- [Subrepo Documentation](https://github.com/ingydotnet/git-subrepo)
- [Project CLAUDE.md](../CLAUDE.md) - AI development guidelines
- [Principles README](global_scripts/00_principles/README.md) - Architecture principles

## 🚀 Future Enhancements

### Planned Features
1. Parallel synchronization for independent repos
2. Automated conflict resolution for common patterns
3. Sync status dashboard
4. Integration with CI/CD pipelines
5. Selective sync for specific subrepos

### Under Consideration
- Webhook-based auto-sync
- Sync scheduling via cron
- Mobile notifications for sync status
- Graphical sync visualization

---

Last Updated: 2025-07-09
Maintained by: AI MarTech Team