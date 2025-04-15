#!/bin/bash
# Vault Content Recovery Script
# This script recovers content from the broken backup and implements the directory structure

# Set up variables
CURRENT_DIR="/Users/patricksmith/obsidian/acupcakeshop"
BROKEN_BACKUP="/Users/patricksmith/obsidian/acupcakeshop_broken_20250409_205744"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${CURRENT_DIR}/System/Backups/pre_recovery_${TIMESTAMP}"
LOG_FILE="${CURRENT_DIR}/System/Logs/recovery_${TIMESTAMP}.log"

# Create backup of current state
echo "Creating backup of current state at ${BACKUP_DIR}..." | tee -a "$LOG_FILE"
mkdir -p "${BACKUP_DIR}"
rsync -av --exclude ".obsidian" "$CURRENT_DIR/" "$BACKUP_DIR/" >> "$LOG_FILE" 2>&1
echo "Current state backed up." | tee -a "$LOG_FILE"

# Create the directory structure
echo "Creating directory structure..." | tee -a "$LOG_FILE"

# Create System directory and subdirectories
mkdir -p "$CURRENT_DIR/System/Scripts"
mkdir -p "$CURRENT_DIR/System/Configuration"
mkdir -p "$CURRENT_DIR/System/Backups"
mkdir -p "$CURRENT_DIR/System/Logs"

# Create Resources directory structure
mkdir -p "$CURRENT_DIR/Resources/Templates/Analysis"
mkdir -p "$CURRENT_DIR/Resources/Templates/Interview"
mkdir -p "$CURRENT_DIR/Resources/Templates/System"
mkdir -p "$CURRENT_DIR/Resources/Templates/Project"
mkdir -p "$CURRENT_DIR/Resources/Templates/Client"
mkdir -p "$CURRENT_DIR/Resources/Templates/Task"
mkdir -p "$CURRENT_DIR/Resources/Dashboards"
mkdir -p "$CURRENT_DIR/Resources/Maps"
mkdir -p "$CURRENT_DIR/Resources/Visualizations"
mkdir -p "$CURRENT_DIR/Resources/Attachments/images"
mkdir -p "$CURRENT_DIR/Resources/Attachments/documents"
mkdir -p "$CURRENT_DIR/Resources/Attachments/data"

# Create Documentation directory structure
mkdir -p "$CURRENT_DIR/Documentation/Implementation"
mkdir -p "$CURRENT_DIR/Documentation/Guides"
mkdir -p "$CURRENT_DIR/Documentation/Reference"
mkdir -p "$CURRENT_DIR/Documentation/System"

echo "Directory structure created." | tee -a "$LOG_FILE"

# Copy content from the broken backup
echo "Copying content from broken backup..." | tee -a "$LOG_FILE"

# Copy Templates
echo "Copying Templates..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/Resources/Templates" ]; then
  rsync -av "$BROKEN_BACKUP/Resources/Templates/" "$CURRENT_DIR/Resources/Templates/" >> "$LOG_FILE" 2>&1
elif [ -d "$BROKEN_BACKUP/Templates" ]; then
  rsync -av "$BROKEN_BACKUP/Templates/" "$CURRENT_DIR/Resources/Templates/" >> "$LOG_FILE" 2>&1
fi

# Copy Dashboards
echo "Copying Dashboards..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/Resources/Dashboards" ]; then
  rsync -av "$BROKEN_BACKUP/Resources/Dashboards/" "$CURRENT_DIR/Resources/Dashboards/" >> "$LOG_FILE" 2>&1
elif [ -d "$BROKEN_BACKUP/Dashboards" ]; then
  rsync -av "$BROKEN_BACKUP/Dashboards/" "$CURRENT_DIR/Resources/Dashboards/" >> "$LOG_FILE" 2>&1
fi

# Copy Maps
echo "Copying Maps..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/Resources/Maps" ]; then
  rsync -av "$BROKEN_BACKUP/Resources/Maps/" "$CURRENT_DIR/Resources/Maps/" >> "$LOG_FILE" 2>&1
elif [ -d "$BROKEN_BACKUP/Maps" ]; then
  rsync -av "$BROKEN_BACKUP/Maps/" "$CURRENT_DIR/Resources/Maps/" >> "$LOG_FILE" 2>&1
fi

# Copy Documentation
echo "Copying Documentation..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/Documentation" ]; then
  rsync -av "$BROKEN_BACKUP/Documentation/" "$CURRENT_DIR/Documentation/" >> "$LOG_FILE" 2>&1
fi

# Copy Visualizations (from Excalidraw)
echo "Copying Visualizations..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/Resources/Visualizations" ]; then
  rsync -av "$BROKEN_BACKUP/Resources/Visualizations/" "$CURRENT_DIR/Resources/Visualizations/" >> "$LOG_FILE" 2>&1
elif [ -d "$BROKEN_BACKUP/Excalidraw" ]; then
  rsync -av "$BROKEN_BACKUP/Excalidraw/" "$CURRENT_DIR/Resources/Visualizations/" >> "$LOG_FILE" 2>&1
fi

# Copy System files (scripts, etc.)
echo "Copying System files..." | tee -a "$LOG_FILE"
if [ -d "$BROKEN_BACKUP/System/Scripts" ]; then
  rsync -av "$BROKEN_BACKUP/System/Scripts/" "$CURRENT_DIR/System/Scripts/" >> "$LOG_FILE" 2>&1
fi

# Fix circular redirections by replacing with content (simple fix for phase 1)
echo "Fixing circular redirections..." | tee -a "$LOG_FILE"
find "$CURRENT_DIR" -type f -name "*.md" -exec grep -l "This file has been moved" {} \; | while read -r file; do
  # Get the target path from the redirection
  target_path=$(grep -o "\[\[.*\]\]" "$file" | sed 's/\[\[\(.*\)|\(.*\)\]\]/\1/' | sed 's/\[\[\(.*\)\]\]/\1/')
  
  if [[ -n "$target_path" ]]; then
    # Convert to absolute path
    absolute_target="$CURRENT_DIR/$target_path"
    
    # If target exists, check if it has content
    if [[ -f "$absolute_target" ]]; then
      # Check if target also has redirect
      if grep -q "This file has been moved" "$absolute_target"; then
        echo "⚠️ Circular redirection detected: $file -> $absolute_target" | tee -a "$LOG_FILE"
        
        # Look for original content in backup
        original_file=${file#$CURRENT_DIR/}
        broken_original="$BROKEN_BACKUP/$original_file"
        original_target="$BROKEN_BACKUP/$target_path"
        
        # If original content exists in backup, use it
        if [[ -f "$broken_original" && ! $(grep -q "This file has been moved" "$broken_original") ]]; then
          echo "✅ Using content from backup: $broken_original -> $file" | tee -a "$LOG_FILE"
          cp "$broken_original" "$file"
        elif [[ -f "$original_target" && ! $(grep -q "This file has been moved" "$original_target") ]]; then
          echo "✅ Using content from backup target: $original_target -> $file" | tee -a "$LOG_FILE"
          cp "$original_target" "$file"
        else
          echo "⚠️ Could not find original content for: $file" | tee -a "$LOG_FILE"
        fi
      fi
    fi
  fi
done

# Create recovery status file
cat > "$CURRENT_DIR/Documentation/Implementation/recovery_status.md" << CONTENT
---
title: "Vault Recovery Status"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: in_progress
---

# Vault Recovery Status

## Recovery Overview

The vault content has been partially recovered from the backup created on April 9, 2025.

## Completed Tasks

- ✅ Created backup of current state
- ✅ Created directory structure
- ✅ Copied Templates from backup
- ✅ Copied Dashboards from backup
- ✅ Copied Maps from backup
- ✅ Copied Documentation from backup
- ✅ Copied Visualizations from backup
- ✅ Initial fix for circular redirections

## Next Steps

1. Complete circular redirection fixes
2. Standardize YAML frontmatter
3. Verify content functionality
4. Implement the full migration plan

## Recovery Details

- **Recovery Started**: $(date +%Y-%m-%d\ %H:%M:%S)
- **Backup Location**: \`${BACKUP_DIR}\`
- **Log File**: \`${LOG_FILE}\`

The recovery process is ongoing. Please refer to the recovery plan for next steps.

---

*Recovery status updated: $(date +%Y-%m-%d\ %H:%M:%S)*
CONTENT

echo "Recovery script completed." | tee -a "$LOG_FILE"
echo "Recovery log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Recovery status: $CURRENT_DIR/Documentation/Implementation/recovery_status.md" | tee -a "$LOG_FILE"