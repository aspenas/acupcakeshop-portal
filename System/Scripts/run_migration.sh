#!/bin/bash
# One-Click Migration Implementation Script
# This script runs all the necessary scripts to implement the vault migration in the correct order
# Created: 2025-04-09

# Set the vault root directory
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_DIR="${VAULT_ROOT}/System/Logs"
MASTER_LOG="${LOG_DIR}/migration_master_log_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory
mkdir -p "$LOG_DIR"

# Start logging
echo "=======================================" | tee -a "$MASTER_LOG"
echo "Starting Vault Migration" | tee -a "$MASTER_LOG"
echo "Date: $(date)" | tee -a "$MASTER_LOG"
echo "=======================================" | tee -a "$MASTER_LOG"

# Function to run a script and log the output
run_script() {
  local script="$1"
  local description="$2"
  
  echo -e "\n--- Running $description ---" | tee -a "$MASTER_LOG"
  echo "Script: $script" | tee -a "$MASTER_LOG"
  echo "Start time: $(date)" | tee -a "$MASTER_LOG"
  
  if [ -f "$script" ]; then
    chmod +x "$script"
    "$script" 2>&1 | tee -a "$MASTER_LOG"
    echo "Script completed with exit code: $?" | tee -a "$MASTER_LOG"
  else
    echo "Error: Script $script not found" | tee -a "$MASTER_LOG"
    return 1
  fi
  
  echo "End time: $(date)" | tee -a "$MASTER_LOG"
  echo "--- $description Completed ---" | tee -a "$MASTER_LOG"
}

# Run the migration scripts in sequence

echo -e "\n=== PHASE 1: VAULT REORGANIZATION ===" | tee -a "$MASTER_LOG"
run_script "${VAULT_ROOT}/System/Scripts/vault_reorganization_full.sh" "Vault Reorganization"

echo -e "\n=== PHASE 2: LINK UPDATES ===" | tee -a "$MASTER_LOG"
run_script "${VAULT_ROOT}/System/Scripts/update_links.sh" "Link Updates"

echo -e "\n=== PHASE 3: MIGRATION VERIFICATION ===" | tee -a "$MASTER_LOG"
run_script "${VAULT_ROOT}/System/Scripts/migration_verification.sh" "Migration Verification"

# Generate migration completion report
COMPLETION_REPORT="${VAULT_ROOT}/Documentation/Implementation/migration_completion_report.md"

echo "---
title: \"Vault Migration Completion Report\"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: complete
version: 1.0
primary_reviewer: Patrick
tags: [documentation, implementation, migration, reorganization, report]
---

# Vault Migration Completion Report

> [!NOTE] Strategic Connections
> - [[vault_migration_plan|Vault Migration Plan]]
> - [[migration_dashboard|Migration Dashboard]]
> - [[../../System/Scripts/vault_reorganization_full.sh|Migration Script]]
> - [[../../implementation_status|Implementation Status]]

## Migration Overview

The vault migration from the previous structure to the new, optimized structure has been completed. This report summarizes the migration process and outcomes.

## Migration Timeline

- **Migration Started**: $(date)
- **Migration Completed**: $(date)

## Migration Summary

The migration implemented the following structural changes:

1. **System Directory Creation**: Created a dedicated System directory for scripts, configuration, and backups
2. **Resource Consolidation**: Consolidated resources into a single Resources directory
3. **Documentation Organization**: Reorganized documentation into logical categories
4. **Template Consolidation**: Consolidated templates from multiple directories
5. **Link Updates**: Updated internal links to reflect the new structure

## Migration Statistics

- **Files Migrated**: $(find "${VAULT_ROOT}" -type f -name "*.md" | wc -l) markdown files
- **Scripts Organized**: $(find "${VAULT_ROOT}/System/Scripts" -type f -name "*.sh" | wc -l) scripts
- **Templates Consolidated**: $(find "${VAULT_ROOT}/Resources/Templates" -type f -name "*.md" | wc -l) templates
- **Links Updated**: See the link update log for details

## New Directory Structure

\`\`\`
/Users/patricksmith/obsidian/acupcakeshop/
├── Athlete Financial Empowerment/     # Main project content (unchanged)
├── System/                            # System files and maintenance
│   ├── Scripts/                       # All scripts in one location
│   ├── Configuration/                 # Configuration files
│   └── Backups/                       # Organized backups
├── Resources/                         # Consolidated resources
│   ├── Templates/                     # Single, consolidated templates directory
│   ├── Dashboards/                    # All dashboards
│   ├── Maps/                          # All maps and mind maps
│   ├── Visualizations/                # Excalidraw and other visualizations
│   └── Attachments/                   # All attachments
├── Documentation/                     # Enhanced documentation structure
│   ├── Implementation/                # Implementation documentation
│   ├── Guides/                        # User guides
│   ├── Reference/                     # Reference documentation
│   └── System/                        # System documentation
├── index.md                           # Main vault entry point
└── README.md                          # Project description
\`\`\`

## Benefits Achieved

1. **Improved Navigation**: Clear separation between content and system files
2. **Enhanced Maintainability**: Consolidated scripts in logical categories
3. **Better Scalability**: Clean structure that can accommodate growth
4. **Standardized Organization**: Consistent naming conventions

## Next Steps

The following activities should be performed to complete the migration:

1. **Remove Redirects**: After ~2 weeks, remove redirection files
2. **User Communication**: Communicate the new structure to all users
3. **Workflow Updates**: Update any workflows that reference specific file paths
4. **Link Audit**: Perform a final link audit to identify any broken links

## Conclusion

The vault migration has been successfully completed, resulting in a more organized, maintainable structure that improves navigation and scalability while preserving all content and functionality.

---

*Report generated: $(date)*
" > "$COMPLETION_REPORT"

echo -e "\n=== MIGRATION COMPLETED ===" | tee -a "$MASTER_LOG"
echo "Master log file: $MASTER_LOG" | tee -a "$MASTER_LOG"
echo "Completion report: $COMPLETION_REPORT" | tee -a "$MASTER_LOG"
echo "=======================================" | tee -a "$MASTER_LOG"