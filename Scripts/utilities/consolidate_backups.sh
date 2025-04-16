#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Backup Consolidation Script
# ============================================================================
# Purpose: Consolidates multiple backup directories into a structured archive
# Usage: ./consolidate_backups.sh
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCHIVE_ROOT="$VAULT_ROOT/../acupcakeshop_archives"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/consolidate_backups_${TIMESTAMP}.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"
mkdir -p "$ARCHIVE_ROOT/backups"
mkdir -p "$ARCHIVE_ROOT/logs"

# ============================================================================
# Utility Functions
# ============================================================================
log() {
  local message="$1"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log_success() {
  log "\033[0;32m✓ $1\033[0m"  # Green
}

log_error() {
  log "\033[0;31m✗ $1\033[0m"  # Red
}

log_warning() {
  log "\033[0;33m⚠ $1\033[0m"  # Yellow
}

log_info() {
  log "\033[0;34mℹ $1\033[0m"  # Blue
}

# ============================================================================
# Main Script
# ============================================================================
log_info "Starting backup consolidation"
log_info "Vault root: $VAULT_ROOT"
log_info "Archive root: $ARCHIVE_ROOT"
log_info "Log file: $LOG_FILE"

# Step 1: Move backup directories to archive
log_info "Moving backup directories to archive"

# List of backup directory patterns to move
BACKUP_PATTERNS=(
  "*pre_migration*"
  "*backup_*"
  "*pre_cleanup*"
  "*before_fix*"
  "*script_fixes*"
)

# Create an archive directory for this consolidation
ARCHIVE_DIR="$ARCHIVE_ROOT/backups/consolidated_${TIMESTAMP}"
mkdir -p "$ARCHIVE_DIR"
log_info "Created archive directory: $ARCHIVE_DIR"

# Move each backup directory
for pattern in "${BACKUP_PATTERNS[@]}"; do
  log_info "Processing pattern: $pattern"
  
  # Find directories matching the pattern
  mapfile -t dirs < <(find "$VAULT_ROOT" -type d -name "$pattern" | grep -v "_utilities")
  
  # Move each directory
  for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
      dir_name=$(basename "$dir")
      parent_dir=$(dirname "$dir")
      parent_name=$(basename "$parent_dir")
      
      # Create target directory with parent context
      target_dir="$ARCHIVE_DIR/${parent_name}_${dir_name}"
      mkdir -p "$target_dir"
      
      log_info "Moving $dir to $target_dir"
      
      # Copy contents (safer than move)
      rsync -a "$dir/" "$target_dir/"
      
      # Create a placeholder in the original location
      rm -rf "$dir"
      mkdir -p "$dir"
      cat > "$dir/README.md" << EOF
---
title: "Archived Content"
date_created: $(date +"%Y-%m-%d")
date_modified: $(date +"%Y-%m-%d")
status: archived
tags: [archived, placeholder]
---

# Archived Content

This directory was archived during the vault cleanup process.

- Original location: $dir
- Archive location: $target_dir
- Archive date: $(date +"%Y-%m-%d")

The content was moved to simplify the vault structure and improve performance.
EOF
      
      log_success "Moved $dir to archive and created placeholder"
    fi
  done
done

# Step 2: Move log files to archive
log_info "Moving log files to archive"

# Create logs archive directory
LOGS_ARCHIVE_DIR="$ARCHIVE_ROOT/logs/consolidated_${TIMESTAMP}"
mkdir -p "$LOGS_ARCHIVE_DIR"
log_info "Created logs archive directory: $LOGS_ARCHIVE_DIR"

# Find log files (excluding _utilities/logs)
mapfile -t log_files < <(find "$VAULT_ROOT" -name "*.log" -o -name "*.bak" | grep -v "_utilities/logs")

# Move each log file
for file in "${log_files[@]}"; do
  if [ -f "$file" ]; then
    file_name=$(basename "$file")
    parent_dir=$(dirname "$file")
    parent_name=$(basename "$parent_dir")
    
    # Create target directory structure
    target_file="$LOGS_ARCHIVE_DIR/${parent_name}_${file_name}"
    mkdir -p "$(dirname "$target_file")"
    
    log_info "Moving $file to $target_file"
    
    # Copy file (safer than move)
    cp "$file" "$target_file"
    
    # Remove original
    rm "$file"
    
    log_success "Moved $file to archive"
  fi
done

log_success "Backup consolidation completed successfully"
log_info "Archived directories to: $ARCHIVE_DIR"
log_info "Archived logs to: $LOGS_ARCHIVE_DIR"
exit 0