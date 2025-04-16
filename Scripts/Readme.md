---
title: "Vault Maintenance Scripts"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, scripts, maintenance]
---

# Vault Maintenance Scripts

This directory contains a unified set of maintenance scripts for the Athlete Financial Empowerment vault.

## Overview

The scripts have been consolidated and organized to provide a more streamlined and maintainable approach to vault management. Rather than having multiple overlapping scripts, we now have a single entry point (`maintenance.sh`) that provides access to all maintenance functions.

## Directory Structure

```
/scripts
├── maintenance.sh           # Main entry point for all maintenance tasks
├── maintenance/             # Core maintenance functionality
│   ├── frontmatter.sh       # YAML frontmatter standardization
│   ├── links.sh             # Link fixing and verification
│   ├── tags.sh              # Tag auditing and management
│   └── verify.sh            # Vault integrity verification
├── sync/                    # Synchronization scripts
│   └── github.sh            # GitHub synchronization
├── migration/               # Migration-related scripts
│   ├── lib.sh               # Shared migration functions
│   └── verify.sh            # Migration verification
├── utilities/               # Utility scripts
│   ├── consolidate_backups.sh  # Backup consolidation
│   └── prepare_release.sh   # Release preparation
├── content/                 # Content management scripts
│   ├── create_interview.sh  # Interview creation
│   └── template_apply.sh    # Template application
├── tests/                   # Test scripts
│   ├── test_framework.sh    # Testing framework
│   ├── test_frontmatter.sh  # Tests for frontmatter.sh
│   ├── test_links.sh        # Tests for links.sh
│   └── test_template_apply.sh # Tests for template_apply.sh
└── legacy/                  # Original scripts (for reference)
```

## Main Commands

The `maintenance.sh` script provides a unified interface to all maintenance tasks:

- `./maintenance.sh standardize-yaml` - Standardize YAML frontmatter in files
- `./maintenance.sh fix-links` - Fix broken links in files
- `./maintenance.sh verify` - Verify vault integrity
- `./maintenance.sh audit-tags` - Audit tags used in the vault
- `./maintenance.sh sync` - Sync vault changes with GitHub
- `./maintenance.sh sync-status` - Check GitHub sync status
- `./maintenance.sh clean` - Clean up temporary files
- `./maintenance.sh backup` - Create backup of vault

## Usage Examples

### Standardize YAML Frontmatter

```bash
./maintenance.sh standardize-yaml --dir content
```

This will ensure all files in the content directory have properly formatted YAML frontmatter.

### Fix Broken Links

```bash
./maintenance.sh fix-links --all
```

This will scan the vault for broken links and fix them, including links in templates.

### Verify Vault Integrity

```bash
./maintenance.sh verify
```

This will check the vault for broken links, missing files, and frontmatter issues.

### Audit Tags

```bash
./maintenance.sh audit-tags
```

This will identify all tags used in the vault and check for inconsistencies.

### Clean Up Temporary Files

```bash
./maintenance.sh clean
```

This will remove temporary files and clean up the vault.

### Create Backup

```bash
./maintenance.sh backup
```

This will create a backup of the vault.

### Sync with GitHub

```bash
./maintenance.sh sync
```

This will sync the vault with GitHub, committing and pushing all changes with an automated commit message.

For a custom commit message:

```bash
./maintenance.sh sync --message "Updated player interviews"
```

### Check GitHub Sync Status

```bash
./maintenance.sh sync-status
```

This will check the sync status with GitHub, showing information about uncommitted changes and whether the local branch is up-to-date with the remote.

## Script Consolidation Plan

The original scripts have been consolidated according to the following plan:

1. **YAML Standardization**
   - `batch_standardize_yaml.sh`
   - `standardize_yaml.sh`
   - `yaml_standardization.sh`
   
   Consolidated into `maintenance/frontmatter.sh`

2. **Link Fixing**
   - `fix_links.sh`
   - `enhanced_fix_links.sh`
   - `template_aware_link_repair.sh`
   
   Consolidated into `maintenance/links.sh`

3. **Vault Verification**
   - `verify_migration.sh`
   - `migration_verification.sh`
   
   Consolidated into `maintenance/verify.sh`

4. **Tag Auditing**
   - `tag_audit.sh`
   
   Consolidated into `maintenance/tags.sh`

5. **GitHub Sync**
   - `sync_vault.sh`
   
   Consolidated into `sync/github.sh`

## Best Practices

When working with these scripts:

1. Always run from the vault root directory
2. Check the logs in `_utilities/logs` for detailed output
3. Consider running in `--dry-run` mode first for potentially destructive operations
4. Create a backup before making significant changes

## Development

When adding new functionality:

1. Add it to the appropriate module in the `maintenance` directory
2. Update the main `maintenance.sh` script to expose the new functionality
3. Update this documentation with usage examples
4. Add appropriate logging and error handling

---

*Last updated: April 15, 2025*
EOF < /dev/null