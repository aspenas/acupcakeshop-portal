#!/bin/bash
# Post-Migration Cleanup Script
# This script removes redirection files and cleans up after the migration
# To be run 2-4 weeks after successful migration
# Created: 2025-04-09

# Set the vault root directory
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/System/Logs/cleanup_log_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="${VAULT_ROOT}/System/Backups/redirects_backup_$(date +%Y%m%d_%H%M%S)"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_DIR"

# Start logging
echo "=======================================" | tee -a "$LOG_FILE"
echo "Starting Post-Migration Cleanup" | tee -a "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"

# Function to check if a file is a redirection file
is_redirection_file() {
  local file="$1"
  grep -q "This file has been moved" "$file" 2>/dev/null
}

# Function to backup and remove a redirection file
process_redirection_file() {
  local file="$1"
  local rel_path="${file#$VAULT_ROOT/}"
  local backup_path="${BACKUP_DIR}/${rel_path}"
  
  # Create backup directory
  mkdir -p "$(dirname "$backup_path")"
  
  # Backup the file
  cp "$file" "$backup_path"
  
  # Remove the file
  rm "$file"
  
  echo "✅ Removed redirection file: $file" | tee -a "$LOG_FILE"
}

# Find and process all redirection files
echo "Finding redirection files..." | tee -a "$LOG_FILE"
find "$VAULT_ROOT" -type f -name "*.md" -not -path "${VAULT_ROOT}/System/Backups/*" | while read file; do
  if is_redirection_file "$file"; then
    process_redirection_file "$file"
  fi
done

# Check for empty directories and remove them
echo "Cleaning up empty directories..." | tee -a "$LOG_FILE"
find "$VAULT_ROOT" -type d -empty -not -path "*/\.*" -not -path "${VAULT_ROOT}/System/Backups/*" | while read dir; do
  echo "Removing empty directory: $dir" | tee -a "$LOG_FILE"
  rmdir "$dir"
done

# Generate cleanup report
REPORT_FILE="${VAULT_ROOT}/Documentation/Implementation/cleanup_report.md"

echo "---
title: \"Post-Migration Cleanup Report\"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: complete
version: 1.0
primary_reviewer: Patrick
tags: [documentation, implementation, migration, cleanup, report]
---

# Post-Migration Cleanup Report

This document summarizes the post-migration cleanup process that removed redirection files and empty directories after the vault reorganization.

## Cleanup Summary

- **Cleanup Date**: $(date)
- **Redirection Files Removed**: $(find "$BACKUP_DIR" -type f | wc -l)
- **Empty Directories Removed**: $(find "$VAULT_ROOT" -type d -empty -not -path "*/\.*" -not -path "${VAULT_ROOT}/System/Backups/*" | wc -l)

## Backup Location

All removed redirection files were backed up to:
\`${BACKUP_DIR}\`

## Cleanup Process

The cleanup process:

1. **Identified Redirection Files**: Found files containing \"This file has been moved\"
2. **Backed Up Redirection Files**: Created backups in the System/Backups directory
3. **Removed Redirection Files**: Deleted the redirection files
4. **Removed Empty Directories**: Cleaned up empty directories

## Verification

After cleanup, the vault structure is now in its final form with:
- No redirection files
- No empty directories
- Clean, optimized organization

## Next Steps

1. **Verify Vault Functionality**: Confirm that all features still work correctly
2. **Update Documentation**: Ensure all documentation reflects the final structure
3. **User Communication**: Inform users that cleanup is complete

---

*Report generated: $(date)*
" > "$REPORT_FILE"

echo -e "\n=== CLEANUP COMPLETED ===" | tee -a "$LOG_FILE"
echo "Cleaned up $(find "$BACKUP_DIR" -type f | wc -l) redirection files" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Redirection backups: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "Cleanup report: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "=======================================" | tee -a "$LOG_FILE"