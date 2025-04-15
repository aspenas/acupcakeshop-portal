#!/bin/bash
# Create a comprehensive backup of the vault

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/Users/patricksmith/obsidian/acupcakeshop/System/Backups/vault_backup_${TIMESTAMP}"
LOG_FILE="/Users/patricksmith/obsidian/acupcakeshop/System/Logs/backup_${TIMESTAMP}.log"

echo "Creating backup at $BACKUP_DIR" | tee -a "$LOG_FILE"
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Copy all files except .obsidian directory to backup
rsync -av --exclude ".obsidian" "/Users/patricksmith/obsidian/acupcakeshop/" "$BACKUP_DIR/" >> "$LOG_FILE" 2>&1

echo "Backup completed at $(date)" | tee -a "$LOG_FILE"
echo "Backup location: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"

# Create backup report
mkdir -p "/Users/patricksmith/obsidian/acupcakeshop/System/Backups"
cat > "/Users/patricksmith/obsidian/acupcakeshop/System/Backups/backup_report_${TIMESTAMP}.md" << CONTENT
---
title: "Vault Backup Report"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: complete
---

# Vault Backup Report

- **Date**: $(date +%Y-%m-%d\ %H:%M:%S)
- **Backup Location**: \`$BACKUP_DIR\`
- **Log File**: \`$LOG_FILE\`

This backup was created before migration operations as a safety measure.

To restore this backup if needed:
1. Create a backup of the current state
2. Copy all files from \`$BACKUP_DIR\` to the vault directory
3. Restart Obsidian to load the restored state

---

*Backup created: $(date +%Y-%m-%d\ %H:%M:%S)*
CONTENT

echo "Backup report created."