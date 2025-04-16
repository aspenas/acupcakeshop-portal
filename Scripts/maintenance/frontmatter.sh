#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# YAML Frontmatter Standardization
# ============================================================================
# Purpose: Standardizes YAML frontmatter in Obsidian markdown files
# Usage:
#   ./frontmatter.sh standardize <file> - Standardize a single file
#   ./frontmatter.sh batch <directory> - Process all files in a directory
#   ./frontmatter.sh verify <file> - Verify frontmatter in a file
#   ./frontmatter.sh repair-all - Find and fix all frontmatter issues
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/frontmatter_${TIMESTAMP}.log"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

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

show_help() {
  cat << EOF
YAML Frontmatter Standardization

Usage: ./frontmatter.sh [command] [options]

Commands:
  standardize <file>       - Standardize frontmatter in a single file
  batch <directory>        - Process all markdown files in a directory
  verify <file>            - Verify frontmatter in a file
  repair-all               - Find and fix all frontmatter issues in vault
  help                     - Show this help message

Examples:
  ./frontmatter.sh standardize content/research/file.md
  ./frontmatter.sh batch content/research
  ./frontmatter.sh verify content/research/file.md
  ./frontmatter.sh repair-all
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# Standardize frontmatter in a single file
standardize_frontmatter() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    log_error "Error: File does not exist: $file"
    return 1
  fi
  
  log_info "Processing file: $file"
  
  # Check if file has YAML frontmatter
  if ! grep -q "^---" "$file"; then
    log_warning "No YAML frontmatter found in $file"
    
    # Add basic frontmatter if missing
    local filename=$(basename "$file" .md)
    local today=$(date +"%Y-%m-%d")
    
    local tmp_file=$(mktemp)
    cat > "$tmp_file" << EOF
---
title: "${filename}"
date_created: ${today}
date_modified: ${today}
status: active
tags: []
---

EOF
    
    # Append original content
    cat "$file" >> "$tmp_file"
    
    # Replace original file
    mv "$tmp_file" "$file"
    
    log_success "Added basic frontmatter to $file"
    return 0
  fi
  
  # Create temporary file
  local tmp_file=$(mktemp)
  
  # Extract frontmatter and content
  local frontmatter_start=$(grep -n "^---" "$file" | head -1 | cut -d: -f1)
  local frontmatter_end=$(grep -n "^---" "$file" | head -2 | tail -1 | cut -d: -f1)
  
  if [ -z "$frontmatter_end" ] || [ "$frontmatter_start" = "$frontmatter_end" ]; then
    log_error "Invalid frontmatter in $file (missing closing ---)"
    return 1
  fi
  
  # Extract frontmatter
  local frontmatter=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$file")
  
  # Standardize date fields
  frontmatter=$(echo "$frontmatter" | sed "s/^date: /date_created: /")
  frontmatter=$(echo "$frontmatter" | sed "s/^updated: /date_modified: /")
  frontmatter=$(echo "$frontmatter" | sed "s/^modified: /date_modified: /")
  frontmatter=$(echo "$frontmatter" | sed "s/^created: /date_created: /")
  
  # Fix malformed dates (convert YYYY-MM-DD to proper format)
  frontmatter=$(echo "$frontmatter" | sed -E "s/^(date_[^:]+: )([0-9]{4})-([0-9]{2})-([0-9]{2})/\1\2-\3-\4/g")
  
  # Add missing fields if needed
  
  # Date created
  if ! echo "$frontmatter" | grep -q "date_created:"; then
    today=$(date +"%Y-%m-%d")
    frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
date_created: $today")
  fi
  
  # Date modified
  if ! echo "$frontmatter" | grep -q "date_modified:"; then
    today=$(date +"%Y-%m-%d")
    frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
date_modified: $today")
  fi
  
  # Status field
  if ! echo "$frontmatter" | grep -q "^status:"; then
    frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
status: active")
  fi
  
  # Title field
  if ! echo "$frontmatter" | grep -q "^title:"; then
    filename=$(basename "$file" .md)
    title=$(echo "$filename" | sed -E 's/[-_]/ /g' | sed -E 's/\b\w/\U&/g')
    frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
title: \"$title\"")
  fi
  
  # Tags field
  if ! echo "$frontmatter" | grep -q "^tags:"; then
    frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
tags: []")
  fi
  
  # Format tags consistently (list format)
  if echo "$frontmatter" | grep -q "^tags:.*\["; then
    # Already in list format, leave as is
    :
  else
    # Convert tag string to list format
    tags_line=$(echo "$frontmatter" | grep "^tags:")
    if [ -n "$tags_line" ]; then
      tags_value=$(echo "$tags_line" | sed "s/^tags: //")
      tags_list="tags: [$tags_value]"
      frontmatter=$(echo "$frontmatter" | sed "s/^tags:.*/$tags_list/")
    fi
  fi
  
  # Write standardized frontmatter to temporary file
  echo "$frontmatter" > "$tmp_file"
  
  # Append content after frontmatter
  if [ "$frontmatter_end" -lt "$(wc -l < "$file")" ]; then
    sed -n "$((frontmatter_end+1)),\$p" "$file" >> "$tmp_file"
  fi
  
  # Replace original file
  mv "$tmp_file" "$file"
  
  log_success "Standardized YAML in $file"
  return 0
}

# Process all markdown files in a directory
batch_standardize() {
  local directory="${1:-$VAULT_ROOT}"
  
  if [ ! -d "$directory" ]; then
    log_error "Error: Directory does not exist: $directory"
    return 1
  fi
  
  log_info "Batch processing directory: $directory"
  
  # Find all markdown files
  local count=0
  while IFS= read -r file; do
    standardize_frontmatter "$file"
    count=$((count + 1))
  done < <(find "$directory" -name "*.md" -type f -not -path "*/\.*")
  
  log_success "Processed $count files in $directory"
  return 0
}

# Verify frontmatter in a file
verify_frontmatter() {
  local file="$1"
  local issues=0
  
  if [ ! -f "$file" ]; then
    log_error "Error: File does not exist: $file"
    return 1
  fi
  
  log_info "Verifying frontmatter in $file"
  
  # Check if file has YAML frontmatter
  if ! grep -q "^---" "$file"; then
    log_error "No YAML frontmatter found in $file"
    return 1
  fi
  
  # Extract frontmatter
  local frontmatter_start=$(grep -n "^---" "$file" | head -1 | cut -d: -f1)
  local frontmatter_end=$(grep -n "^---" "$file" | head -2 | tail -1 | cut -d: -f1)
  
  if [ -z "$frontmatter_end" ] || [ "$frontmatter_start" = "$frontmatter_end" ]; then
    log_error "Invalid frontmatter in $file (missing closing ---)"
    return 1
  fi
  
  # Check required fields
  if ! sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep -q "^title:"; then
    log_warning "Missing title field in $file"
    issues=$((issues + 1))
  fi
  
  if ! sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep -q "^date_created:"; then
    log_warning "Missing date_created field in $file"
    issues=$((issues + 1))
  fi
  
  if ! sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep -q "^date_modified:"; then
    log_warning "Missing date_modified field in $file"
    issues=$((issues + 1))
  fi
  
  if ! sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep -q "^status:"; then
    log_warning "Missing status field in $file"
    issues=$((issues + 1))
  fi
  
  if ! sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep -q "^tags:"; then
    log_warning "Missing tags field in $file"
    issues=$((issues + 1))
  fi
  
  if [ "$issues" -gt 0 ]; then
    log_warning "Found $issues issue(s) in $file"
    return 1
  else
    log_success "Frontmatter verified in $file (no issues found)"
    return 0
  fi
}

# Find and fix all frontmatter issues in vault
repair_all() {
  log_info "Finding and fixing all frontmatter issues in vault"
  
  # First, check for files without frontmatter
  log_info "Checking for files without frontmatter"
  local count=0
  while IFS= read -r file; do
    if ! grep -q "^---" "$file"; then
      log_warning "No frontmatter in $file"
      standardize_frontmatter "$file"
      count=$((count + 1))
    fi
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  log_info "Added frontmatter to $count files"
  
  # Now check for files with incomplete frontmatter
  log_info "Checking for files with incomplete frontmatter"
  count=0
  while IFS= read -r file; do
    if grep -q "^---" "$file"; then
      if ! verify_frontmatter "$file" > /dev/null 2>&1; then
        standardize_frontmatter "$file"
        count=$((count + 1))
      fi
    fi
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  log_info "Fixed frontmatter in $count files"
  
  log_success "Completed frontmatter repair"
  return 0
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting frontmatter script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  standardize)
    if [ -z "$1" ]; then
      log_error "Error: No file specified"
      show_help
      exit 1
    fi
    standardize_frontmatter "$1"
    ;;
  batch)
    batch_standardize "${1:-$VAULT_ROOT}"
    ;;
  verify)
    if [ -z "$1" ]; then
      log_error "Error: No file specified"
      show_help
      exit 1
    fi
    verify_frontmatter "$1"
    ;;
  repair-all)
    repair_all
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    log_error "Unknown command: $COMMAND"
    show_help
    exit 1
    ;;
esac

log_info "Frontmatter script completed"
exit 0