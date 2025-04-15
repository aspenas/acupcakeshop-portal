---
title: "Migration Execution Guide"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [migration, guide, execution, implementation]
---

---

---

---

# Migration Execution Guide

This guide provides step-by-step instructions for executing the vault migration process. It is designed to be followed sequentially to ensure a smooth migration with maximum data safety and integrity.

## Before You Begin

Before starting the migration, ensure:

1. **Close Obsidian**: Ensure Obsidian is completely closed to prevent any conflicts during migration
2. **Create a manual backup**: Though the migration will create a comprehensive backup, it's recommended to make your own backup as well
3. **Check disk space**: Ensure you have at least twice the vault's size in free disk space
4. **Set aside time**: The migration may take 15-30 minutes depending on vault size
5. **Note down any critical files**: Be aware of any essential files you'll need immediately after migration

## Migration Process

The migration consists of several phases, all managed by the migration scripts:

1. **Backup**: Create a comprehensive backup of the entire vault
2. **Preparation**: Set up the environment and create tracking inventory
3. **Content Migration**: Move content files to their new locations
4. **Resource Migration**: Consolidate and migrate templates, dashboards, and assets
5. **Link Updates**: Update internal links to maintain references
6. **Verification**: Check for unmigrated content and broken links
7. **Reporting**: Generate detailed reports on the migration

## Execution Steps

### Step 1: Run the Master Migration Script

The entire migration process can be run with a single command:

```bash
cd /Users/patricksmith/obsidian/acupcakeshop
_utilities/scripts/migration_core.sh
```

This script will:
1. Create a comprehensive backup of your vault
2. Run all migration phases in the correct order
3. Generate reports on the migration

### Step 2: Monitor Progress

The migration will log detailed information about each step. You can monitor progress in two ways:

1. **Watch the console output**: The script will display progress information
2. **Check the log files**: Logs are stored in `_utilities/logs/`

### Step 3: Review Verification Report

After migration completes, review the verification report:

```
/Users/patricksmith/obsidian/acupcakeshop/docs/migration_verification_report.md
```

This report will identify:
- Any unmigrated content
- Broken links in the migrated content
- Issues with frontmatter standardization

### Step 4: Address Any Issues

If the verification report identifies issues:

1. For unmigrated content:
   - Check if the content is important
   - Manually migrate critical content to the appropriate location

2. For broken links:
   - Edit the affected files
   - Update links to point to the correct locations

3. For frontmatter issues:
   - Edit the affected files
   - Add or correct the required frontmatter fields

### Step 5: Verify the New Structure

1. Open Obsidian and explore the new vault structure
2. Navigate using the atlas maps in the `atlas/` directory
3. Ensure critical content is accessible
4. Test various links to ensure they work correctly

## Fallback Plan

If you encounter critical issues during or after migration:

1. Close Obsidian
2. Find the backup location in `_utilities/logs/backup_location_*.txt`
3. Restore the backup if necessary

## Post-Migration Steps

After successfully completing the migration:

1. **Update External References**: If you have external links to files in the vault, update them
2. **Clean Up Old Files**: Once everything is working correctly, consider removing old redirects
3. **Document Customizations**: Document any manual changes made during migration
4. **Regular Backups**: Set up a regular backup routine for the reorganized vault

## Additional Resources

For more information, refer to:

- [Migration Completion Report](/docs/migration_completion_report.md): Summary of the migration process
- [Vault User Guide](/docs/vault_user_guide.md): Guide to using the new vault structure
- [Vault Reorganization Plan](/docs/vault_reorganization_plan.md): Original plan for the reorganization

---

*Guide created: April 15, 2025*
