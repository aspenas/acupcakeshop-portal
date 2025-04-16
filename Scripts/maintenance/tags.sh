#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Tag Auditing and Management
# ============================================================================
# Purpose: Audits, standardizes, and manages tags in Obsidian markdown files
# Usage:
#   ./tags.sh audit - Audit tags across the vault
#   ./tags.sh standardize - Standardize tags across the vault
#   ./tags.sh list - List all tags used in the vault
#   ./tags.sh find <tag> - Find files with a specific tag
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/tags_${TIMESTAMP}.log"
TAG_INVENTORY_FILE="$VAULT_ROOT/_utilities/inventory/tag_inventory.csv"
TAG_ISSUES_FILE="$VAULT_ROOT/_utilities/inventory/tag_issues.csv"

# Create logs and inventory directories if they don't exist
mkdir -p "$LOGS_DIR"
mkdir -p "$(dirname "$TAG_INVENTORY_FILE")"

# Known tag categories for standardization
declare -a PRIMARY_TAGS=(
  "interview" "research" "strategy" "compliance"
  "active" "draft" "archived" "template" "placeholder"
  "in-progress" "completed" "pending-review"
)

declare -a SECONDARY_TAGS=(
  "player" "agent" "industry-professional"
  "competitor" "market-analysis" "industry"
  "football" "basketball" "baseball"
  "advisor" "athlete" "coach"
)

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
Tag Auditing and Management

Usage: ./tags.sh [command] [options]

Commands:
  audit                - Audit tags across the vault
  standardize          - Standardize tags across the vault
  list                 - List all tags used in the vault
  find <tag>           - Find files with a specific tag
  report [--format=md] - Generate tag usage report
  help                 - Show this help message

Examples:
  ./tags.sh audit
  ./tags.sh standardize
  ./tags.sh list
  ./tags.sh find interview
  ./tags.sh report --format=md
EOF
}

# Extract all tags from a file
extract_tags() {
  local file="$1"
  local tags=""
  
  # Check if file exists
  if [ ! -f "$file" ]; then
    return 1
  fi
  
  # Extract tags from frontmatter
  if grep -q "^---" "$file"; then
    # Extract frontmatter
    local frontmatter_start=$(grep -n "^---" "$file" | head -1 | cut -d: -f1)
    local frontmatter_end=$(grep -n "^---" "$file" | head -2 | tail -1 | cut -d: -f1)
    
    if [ -n "$frontmatter_end" ] && [ "$frontmatter_start" != "$frontmatter_end" ]; then
      # Look for tags in frontmatter
      local tag_line=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$file" | grep "^tags:")
      
      if [ -n "$tag_line" ]; then
        # Extract tag values
        tags=$(echo "$tag_line" | sed -E 's/^tags:\s*(\[|\[\"|\[\[)//g' | sed -E 's/(\]|\"\]|\]\])$//g')
        
        # Clean up tag formatting
        tags=$(echo "$tags" | tr -d '[],\"' | tr -s ' ')
      fi
    fi
  fi
  
  echo "$tags"
}

# ============================================================================
# Core Functions
# ============================================================================

# Audit tags across the vault
audit_tags() {
  log_info "Auditing tags across the vault"
  
  # Create CSV headers
  echo "file_path,tag,standardized,issue_type" > "$TAG_ISSUES_FILE"
  
  # Process all markdown files
  local files_processed=0
  local files_with_issues=0
  local tag_issues=0
  
  while IFS= read -r file; do
    files_processed=$((files_processed + 1))
    local file_has_issues=0
    
    # Extract all tags from the file
    local raw_tags=$(extract_tags "$file")
    
    if [ -z "$raw_tags" ]; then
      # Missing tags
      echo "$file,,missing,File has no tags" >> "$TAG_ISSUES_FILE"
      file_has_issues=1
      tag_issues=$((tag_issues + 1))
    else
      # Process each tag
      for tag in $raw_tags; do
        # Check for inconsistent formatting
        local standardized_tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
        
        if [ "$tag" != "$standardized_tag" ]; then
          # Inconsistent formatting
          echo "$file,$tag,$standardized_tag,formatting" >> "$TAG_ISSUES_FILE"
          file_has_issues=1
          tag_issues=$((tag_issues + 1))
        fi
        
        # Check for non-standard tags
        local is_standard=0
        
        # Check primary tags
        for std_tag in "${PRIMARY_TAGS[@]}"; do
          if [ "$standardized_tag" = "$std_tag" ]; then
            is_standard=1
            break
          fi
        done
        
        # Check secondary tags if not found in primary
        if [ "$is_standard" -eq 0 ]; then
          for std_tag in "${SECONDARY_TAGS[@]}"; do
            if [ "$standardized_tag" = "$std_tag" ]; then
              is_standard=1
              break
            fi
          done
        fi
        
        if [ "$is_standard" -eq 0 ]; then
          # Non-standard tag
          echo "$file,$tag,$standardized_tag,non-standard" >> "$TAG_ISSUES_FILE"
          file_has_issues=1
          tag_issues=$((tag_issues + 1))
        fi
      done
    fi
    
    if [ "$file_has_issues" -eq 1 ]; then
      files_with_issues=$((files_with_issues + 1))
    fi
    
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  log_info "Audit complete: Processed $files_processed files"
  
  if [ "$tag_issues" -gt 0 ]; then
    log_warning "Found $tag_issues tag issues in $files_with_issues files"
    log_info "Issues saved to: $TAG_ISSUES_FILE"
  else
    log_success "No tag issues found"
  fi
}

# Standardize tags across the vault
standardize_tags() {
  log_info "Standardizing tags across the vault"
  
  # First perform an audit if issues file doesn't exist
  if [ ! -f "$TAG_ISSUES_FILE" ]; then
    log_info "Running tag audit first"
    audit_tags
  fi
  
  # Check if there are any issues to fix
  local issue_count=$(grep -c "^" "$TAG_ISSUES_FILE" || echo "0")
  
  if [ "$issue_count" -eq 1 ]; then
    # Only the header row exists
    log_success "No tag issues to fix"
    return 0
  fi
  
  # Process each issue in the CSV file (skip header)
  local fixed_files=0
  local fixed_issues=0
  
  # Read headers separately 
  read -r header < "$TAG_ISSUES_FILE"
  
  # Process the rest of the CSV
  local prev_file=""
  local changes=""
  
  while IFS=, read -r file_path tag standardized issue_type; do
    # Skip empty lines
    if [ -z "$file_path" ]; then
      continue
    fi
    
    # Check if we need to write changes for the previous file
    if [ -n "$prev_file" ] && [ "$prev_file" != "$file_path" ] && [ -n "$changes" ]; then
      # Apply changes to the previous file
      local tmp_file=$(mktemp)
      
      # Extract frontmatter
      local frontmatter_start=$(grep -n "^---" "$prev_file" | head -1 | cut -d: -f1)
      local frontmatter_end=$(grep -n "^---" "$prev_file" | head -2 | tail -1 | cut -d: -f1)
      
      if [ -n "$frontmatter_end" ] && [ "$frontmatter_start" != "$frontmatter_end" ]; then
        # Extract and modify the frontmatter
        local frontmatter=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$prev_file")
        
        # Update the tags line
        local new_frontmatter=$(echo "$frontmatter" | sed "s/^tags:.*$/tags: [$changes]/g")
        
        # Write the modified frontmatter
        echo "$new_frontmatter" > "$tmp_file"
        
        # Append content after frontmatter
        if [ "$frontmatter_end" -lt "$(wc -l < "$prev_file")" ]; then
          sed -n "$((frontmatter_end+1)),\$p" "$prev_file" >> "$tmp_file"
        fi
        
        # Replace original file
        mv "$tmp_file" "$prev_file"
        
        log_success "Standardized tags in $prev_file"
        fixed_files=$((fixed_files + 1))
      fi
      
      # Reset changes for the new file
      changes=""
    fi
    
    # Process current file
    if [ "$issue_type" = "missing" ]; then
      # Add default tags for files with missing tags
      changes="index, documentation"
    elif [ "$issue_type" = "formatting" ] || [ "$issue_type" = "non-standard" ]; then
      # Standardize the tag
      if [ -z "$changes" ]; then
        changes="\"$standardized\""
      else
        changes="$changes, \"$standardized\""
      fi
      
      fixed_issues=$((fixed_issues + 1))
    fi
    
    # Remember the current file for the next iteration
    prev_file="$file_path"
    
  done < <(tail -n +2 "$TAG_ISSUES_FILE")
  
  # Handle the last file
  if [ -n "$prev_file" ] && [ -n "$changes" ]; then
    # Apply changes to the last file
    local tmp_file=$(mktemp)
    
    # Extract frontmatter
    local frontmatter_start=$(grep -n "^---" "$prev_file" | head -1 | cut -d: -f1)
    local frontmatter_end=$(grep -n "^---" "$prev_file" | head -2 | tail -1 | cut -d: -f1)
    
    if [ -n "$frontmatter_end" ] && [ "$frontmatter_start" != "$frontmatter_end" ]; then
      # Extract and modify the frontmatter
      local frontmatter=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$prev_file")
      
      # Update the tags line
      local new_frontmatter=$(echo "$frontmatter" | sed "s/^tags:.*$/tags: [$changes]/g")
      
      # Write the modified frontmatter
      echo "$new_frontmatter" > "$tmp_file"
      
      # Append content after frontmatter
      if [ "$frontmatter_end" -lt "$(wc -l < "$prev_file")" ]; then
        sed -n "$((frontmatter_end+1)),\$p" "$prev_file" >> "$tmp_file"
      fi
      
      # Replace original file
      mv "$tmp_file" "$prev_file"
      
      log_success "Standardized tags in $prev_file"
      fixed_files=$((fixed_files + 1))
    fi
  fi
  
  log_success "Standardized $fixed_issues tag issues in $fixed_files files"
}

# List all tags used in the vault
list_tags() {
  log_info "Listing all tags used in the vault"
  
  # Create CSV headers
  echo "tag,count,files" > "$TAG_INVENTORY_FILE"
  
  # Temporary file for all tags
  local all_tags_file=$(mktemp)
  
  # Extract tags from all files
  while IFS= read -r file; do
    local tags=$(extract_tags "$file")
    for tag in $tags; do
      # Standardize tag format for consistency
      local standardized_tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
      echo "$standardized_tag,$file" >> "$all_tags_file"
    done
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  # Count occurrences of each tag
  local tag_count_file=$(mktemp)
  sort "$all_tags_file" | cut -d, -f1 | uniq -c | sort -nr > "$tag_count_file"
  
  # For each tag, list the files that use it
  while read -r count tag; do
    # Format count (remove leading spaces)
    count=$(echo "$count" | tr -d ' ')
    
    # Get files using this tag
    local files=$(grep "^$tag," "$all_tags_file" | cut -d, -f2 | tr '\n' '|' | sed 's/|$//')
    
    # Add to inventory
    echo "$tag,$count,\"$files\"" >> "$TAG_INVENTORY_FILE"
    
    # Output to console
    log_info "Tag: $tag - Used in $count files"
  done < "$tag_count_file"
  
  # Clean up temporary files
  rm "$all_tags_file" "$tag_count_file"
  
  log_success "Tag inventory saved to: $TAG_INVENTORY_FILE"
}

# Find files with a specific tag
find_files_with_tag() {
  local tag="$1"
  
  if [ -z "$tag" ]; then
    log_error "Error: No tag specified"
    return 1
  fi
  
  log_info "Finding files with tag: $tag"
  
  # Standardize the tag for searching
  local standardized_tag=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
  
  # Find files with the tag
  local count=0
  local file_list=""
  
  while IFS= read -r file; do
    local tags=$(extract_tags "$file")
    for file_tag in $tags; do
      # Standardize tag for comparison
      local std_file_tag=$(echo "$file_tag" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
      
      if [ "$std_file_tag" = "$standardized_tag" ]; then
        log_info "  $file"
        count=$((count + 1))
        file_list="$file_list$file\n"
        break
      fi
    done
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  if [ "$count" -eq 0 ]; then
    log_warning "No files found with tag: $tag"
  else
    log_success "Found $count files with tag: $tag"
    
    # Save the results to a file
    local results_file="$VAULT_ROOT/_utilities/inventory/tag_search_${standardized_tag}_${TIMESTAMP}.txt"
    echo -e "$file_list" > "$results_file"
    log_info "Results saved to: $results_file"
  fi
}

# Generate a tag usage report
generate_report() {
  local format="${1:-md}"
  
  log_info "Generating tag usage report in $format format"
  
  # First ensure we have up-to-date tag inventory
  if [ ! -f "$TAG_INVENTORY_FILE" ] || [ "$(find "$TAG_INVENTORY_FILE" -mtime +1)" ]; then
    log_info "Updating tag inventory"
    list_tags > /dev/null
  fi
  
  local report_file="$VAULT_ROOT/docs/system/tag_usage_report.${format}"
  local today=$(date +"%Y-%m-%d")
  
  if [ "$format" = "md" ]; then
    # Create Markdown report
    cat > "$report_file" << EOF
---
title: "Tag Usage Report"
date_created: $today
date_modified: $today
status: active
tags: [documentation, system, tags, report]
---

# Tag Usage Report

This report provides an overview of tags used throughout the Athlete Financial Empowerment vault.

## Summary

This report was generated on $today.

## Tag Frequency

The following table shows the frequency of tag usage across the vault:

| Tag | Count | 
|-----|-------|
EOF
    
    # Add tag data (skip header row)
    tail -n +2 "$TAG_INVENTORY_FILE" | while IFS=, read -r tag count files; do
      echo "| $tag | $count |" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Primary Tags

The following primary tags are recommended for use throughout the vault:

EOF
    
    # Add primary tags
    for tag in "${PRIMARY_TAGS[@]}"; do
      echo "- \`$tag\`" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Secondary Tags

The following secondary tags are also recommended:

EOF
    
    # Add secondary tags
    for tag in "${SECONDARY_TAGS[@]}"; do
      echo "- \`$tag\`" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

## Tag Usage Guidelines

When applying tags to content, follow these guidelines:

1. Use the recommended primary and secondary tags whenever possible
2. Use kebab-case for all tags (e.g., \`interview-summary\` instead of \`InterviewSummary\`)
3. Include at least one content type tag and one status tag
4. Be consistent with tag naming and capitalization

---

*Report generated: $today*
EOF
    
    log_success "Markdown report saved to: $report_file"
  else
    log_error "Unsupported report format: $format"
    return 1
  fi
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting tags script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  audit)
    audit_tags
    ;;
  standardize)
    standardize_tags
    ;;
  list)
    list_tags
    ;;
  find)
    if [ -z "$1" ]; then
      log_error "Error: No tag specified"
      show_help
      exit 1
    fi
    find_files_with_tag "$1"
    ;;
  report)
    format="md"
    if [[ "$1" == --format=* ]]; then
      format="${1#--format=}"
    fi
    generate_report "$format"
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

log_info "Tags script completed"
exit 0