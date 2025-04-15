#!/bin/bash

# Vault Reorganization Implementation Script
# This script helps implement the vault reorganization plan by creating the
# necessary directory structure and providing guidance for the migration.

VAULT_PATH="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="$VAULT_PATH/System/reorganization_log.md"

echo "=== Vault Reorganization Implementation ==="
echo "Vault: $VAULT_PATH"
echo

# Function to safely create directories
create_directory() {
  local dir_path="$1"
  if [ ! -d "$dir_path" ]; then
    echo "Creating directory: $dir_path"
    mkdir -p "$dir_path"
    echo "✅ Created: $dir_path"
  else
    echo "✅ Directory already exists: $dir_path"
  fi
}

# Function to log the reorganization progress
log_action() {
  local action="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  if [ ! -f "$LOG_FILE" ]; then
    # Create log file with header if it doesn't exist
    cat > "$LOG_FILE" << EOL
---
title: "Vault Reorganization Log"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [log, reorganization, implementation]
---

# Vault Reorganization Implementation Log

This document tracks the implementation progress of the vault reorganization plan.

## Implementation Actions

| Timestamp | Action | Status |
|-----------|--------|--------|
EOL
  fi
  
  # Append the action to the log
  echo "| $timestamp | $action | ✅ Completed |" >> "$LOG_FILE"
}

# Create the new directory structure
echo "Creating new directory structure..."

# System directories
create_directory "$VAULT_PATH/System/Scripts/Automation"
create_directory "$VAULT_PATH/System/Scripts/Maintenance"
create_directory "$VAULT_PATH/System/Scripts/Installation"
create_directory "$VAULT_PATH/System/Configuration"
create_directory "$VAULT_PATH/System/Backups"

log_action "Created System directory structure"

# Resources directories
create_directory "$VAULT_PATH/Resources/Templates"
create_directory "$VAULT_PATH/Resources/Dashboards"
create_directory "$VAULT_PATH/Resources/Maps"
create_directory "$VAULT_PATH/Resources/Visualizations"
create_directory "$VAULT_PATH/Resources/Attachments"

log_action "Created Resources directory structure"

# Documentation directories
create_directory "$VAULT_PATH/Documentation/Implementation"
create_directory "$VAULT_PATH/Documentation/Guides"
create_directory "$VAULT_PATH/Documentation/Reference"
create_directory "$VAULT_PATH/Documentation/System"

log_action "Created Documentation directory structure"

# Create migration guide
MIGRATION_GUIDE="$VAULT_PATH/System/migration_guide.md"

cat > "$MIGRATION_GUIDE" << EOL
---
title: "Migration Guide for Vault Reorganization"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [documentation, migration, reorganization, guide]
---

# Migration Guide for Vault Reorganization

This document provides step-by-step instructions for implementing the vault reorganization plan. The directory structure has already been created, and now files need to be migrated to their new locations.

## Migration Process

1. **Backup First**
   - Create a complete backup of the vault before proceeding
   - Verify the backup is complete and accessible

2. **Use Obsidian for File Moves**
   - When possible, use Obsidian's file explorer to move files
   - This will automatically update internal links

3. **Follow the File Relocation Map**
   - Refer to the [Vault Reorganization Plan](../Documentation/vault_reorganization_plan.md) for the detailed file relocation map
   - Move files according to the specified mapping

## File Relocation Tasks

### Scripts Migration

- [ ] Move \`batch_standardize_yaml.sh\` to \`/System/Scripts/Maintenance/\`
- [ ] Move \`standardize_yaml.sh\` to \`/System/Scripts/Maintenance/\`
- [ ] Move \`yaml_standardization.sh\` to \`/System/Scripts/Maintenance/\`
- [ ] Move \`tag_audit.sh\` to \`/System/Scripts/Maintenance/\`
- [ ] Move \`standardize_km_files.sh\` to \`/System/Scripts/Maintenance/\`
- [ ] Move \`install_recommended_plugins.sh\` to \`/System/Scripts/Installation/\`
- [ ] Move \`obsidian_automation.sh\` to \`/System/Scripts/Automation/\`
- [ ] Move \`Athlete Financial Empowerment/create_interview.sh\` to \`/System/Scripts/Automation/\`

### Documentation Migration

- [ ] Move \`enhancement_summary.md\` to \`/Documentation/Implementation/\`
- [ ] Move \`implementation_status.md\` to \`/Documentation/Implementation/\`
- [ ] Move \`obsidian_deployment_package.md\` to \`/Documentation/Implementation/\`
- [ ] Move \`plugin_installation_guide.md\` to \`/Documentation/Guides/\`
- [ ] Move \`tag-system.md\` to \`/Documentation/Reference/\`
- [ ] Move \`yaml_audit_results.md\` to \`/System/\`

### Resource Migration

- [ ] Merge \`Templates/\` and \`Athlete Financial Empowerment/_templates/\` into \`/Resources/Templates/\`
- [ ] Move \`Dashboards/\` to \`/Resources/Dashboards/\`
- [ ] Move \`Maps/\` to \`/Resources/Maps/\`
- [ ] Move \`Excalidraw/\` to \`/Resources/Visualizations/\`
- [ ] Move \`attachments/\` to \`/Resources/Attachments/\`

## Link Update Process

After moving files, check and update links in these key documents:

1. Main index.md
2. Documentation index files
3. Dashboard files
4. Mind maps
5. Project and task files

## Verification Steps

After completing the migration:

1. Test all links in key documents
2. Verify all Dataview queries still function
3. Check the graph view for isolated nodes
4. Test all scripts in their new locations

## Rollback Plan

If issues are encountered:

1. Stop the migration process
2. Document the specific problem
3. Restore the affected files from backup
4. Revise the migration approach

## Completion Checklist

- [ ] All files moved to their new locations
- [ ] All links verified and working
- [ ] All Dataview queries functioning
- [ ] All scripts tested in new locations
- [ ] Graph view shows proper connections
- [ ] Implementation status document updated
- [ ] Backup copies archived

---

*Guide created: $(date +%Y-%m-%d)*  
*Last modified: $(date +%Y-%m-%d)*
EOL

log_action "Created migration guide at $MIGRATION_GUIDE"

echo
echo "Directory structure creation complete!"
echo "Migration guide created at: $MIGRATION_GUIDE"
echo "Reorganization log started at: $LOG_FILE"
echo
echo "Next steps:"
echo "1. Review the migration guide"
echo "2. Create a complete vault backup"
echo "3. Follow the steps in the migration guide to move files"
echo "4. Verify all links and functionality after migration"
echo
echo "============================="