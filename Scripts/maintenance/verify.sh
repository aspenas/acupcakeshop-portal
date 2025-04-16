#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Vault Integrity Verification
# ============================================================================
# Purpose: Verifies the integrity of the Obsidian vault structure and content
# Usage:
#   ./verify.sh integrity - Verify overall vault integrity
#   ./verify.sh links - Verify links in vault
#   ./verify.sh frontmatter - Verify frontmatter in vault
#   ./verify.sh structure - Verify vault structure
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/verify_${TIMESTAMP}.log"
VERIFICATION_REPORT="$VAULT_ROOT/docs/system/verification_report_${TIMESTAMP}.md"

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"
mkdir -p "$(dirname "$VERIFICATION_REPORT")"

# Expected top-level directories
declare -a EXPECTED_DIRECTORIES=(
  "atlas"
  "content"
  "resources"
  "docs"
  "scripts"
  "_utilities"
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
Vault Integrity Verification

Usage: ./verify.sh [command] [options]

Commands:
  integrity            - Verify overall vault integrity
  links                - Verify links in vault
  frontmatter          - Verify frontmatter in vault
  structure            - Verify vault structure
  report [--detailed]  - Generate verification report
  help                 - Show this help message

Examples:
  ./verify.sh integrity
  ./verify.sh links
  ./verify.sh frontmatter
  ./verify.sh structure
  ./verify.sh report --detailed
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# Verify vault structure
verify_structure() {
  log_info "Verifying vault structure"
  
  local structure_issues=0
  
  # Check for expected top-level directories
  for dir in "${EXPECTED_DIRECTORIES[@]}"; do
    if [ ! -d "$VAULT_ROOT/$dir" ]; then
      log_error "Missing expected directory: $dir"
      structure_issues=$((structure_issues + 1))
    else
      log_success "Found expected directory: $dir"
    fi
  done
  
  # Check for index.md file
  if [ ! -f "$VAULT_ROOT/index.md" ]; then
    log_error "Missing index.md file at vault root"
    structure_issues=$((structure_issues + 1))
  else
    log_success "Found index.md file at vault root"
  fi
  
  # Check for README files in key directories
  for dir in "${EXPECTED_DIRECTORIES[@]}"; do
    if [ -d "$VAULT_ROOT/$dir" ] && [ ! -f "$VAULT_ROOT/$dir/README.md" ]; then
      log_warning "Missing README.md file in $dir directory"
      structure_issues=$((structure_issues + 1))
    elif [ -d "$VAULT_ROOT/$dir" ]; then
      log_success "Found README.md file in $dir directory"
    fi
  done
  
  if [ "$structure_issues" -gt 0 ]; then
    log_warning "Found $structure_issues vault structure issue(s)"
    return 1
  else
    log_success "Vault structure verification passed"
    return 0
  fi
}

# Verify links in vault
verify_links() {
  log_info "Verifying links in vault"
  
  local link_issues=0
  local issues_file=$(mktemp)
  
  # Find all markdown files
  while IFS= read -r file; do
    log_info "Checking links in $file"
    
    # Extract all wiki links
    local links=$(grep -o "\[\[[^]]*\]\]" "$file" || echo "")
    
    if [ -z "$links" ]; then
      log_info "No links found in $file"
      continue
    fi
    
    # Check each link
    echo "$links" | while IFS= read -r link; do
      # Extract the link target
      local target=$(echo "$link" | sed -E 's/\[\[([^|#\]]*)[|#]?.*/\1/')
      
      # Skip empty targets
      if [ -z "$target" ]; then
        continue
      fi
      
      # Check if it's a section link
      if [[ "$target" == *#* ]]; then
        # Extract file part
        local file_part="${target%%#*}"
        
        # Skip if file part is empty (internal section link)
        if [ -z "$file_part" ]; then
          continue
        fi
        
        # Check if the file exists
        if [ ! -f "$VAULT_ROOT/$file_part" ] && [ ! -f "$VAULT_ROOT/${file_part}.md" ]; then
          log_warning "Broken link in $file: $link (target file not found)"
          echo "$file,$link,$target,file_not_found" >> "$issues_file"
          link_issues=$((link_issues + 1))
        fi
      else
        # Direct file link
        # Check if the file exists (with or without .md extension)
        if [ ! -f "$VAULT_ROOT/$target" ] && [ ! -f "$VAULT_ROOT/${target}.md" ]; then
          log_warning "Broken link in $file: $link (target file not found)"
          echo "$file,$link,$target,file_not_found" >> "$issues_file"
          link_issues=$((link_issues + 1))
        fi
      fi
    done
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  if [ "$link_issues" -gt 0 ]; then
    log_warning "Found $link_issues broken link(s)"
    log_info "Issues saved to: $issues_file"
    return 1
  else
    log_success "Link verification passed: No broken links found"
    rm "$issues_file"
    return 0
  fi
}

# Verify frontmatter in vault
verify_frontmatter() {
  log_info "Verifying frontmatter in vault"
  
  local frontmatter_issues=0
  local issues_file=$(mktemp)
  
  # Create CSV header
  echo "file,issue" > "$issues_file"
  
  # Find all markdown files
  while IFS= read -r file; do
    # Check if file has YAML frontmatter
    if ! grep -q "^---" "$file"; then
      log_warning "Missing frontmatter in $file"
      echo "$file,missing_frontmatter" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
      continue
    fi
    
    # Extract frontmatter
    local frontmatter_start=$(grep -n "^---" "$file" | head -1 | cut -d: -f1)
    local frontmatter_end=$(grep -n "^---" "$file" | head -2 | tail -1 | cut -d: -f1)
    
    if [ -z "$frontmatter_end" ] || [ "$frontmatter_start" = "$frontmatter_end" ]; then
      log_warning "Invalid frontmatter in $file (missing closing ---)"
      echo "$file,invalid_frontmatter" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
      continue
    fi
    
    # Check required fields
    local frontmatter=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$file")
    
    if ! echo "$frontmatter" | grep -q "^title:"; then
      log_warning "Missing title field in $file"
      echo "$file,missing_title" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^date_created:"; then
      log_warning "Missing date_created field in $file"
      echo "$file,missing_date_created" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^date_modified:"; then
      log_warning "Missing date_modified field in $file"
      echo "$file,missing_date_modified" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^status:"; then
      log_warning "Missing status field in $file"
      echo "$file,missing_status" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
    fi
    
    if ! echo "$frontmatter" | grep -q "^tags:"; then
      log_warning "Missing tags field in $file"
      echo "$file,missing_tags" >> "$issues_file"
      frontmatter_issues=$((frontmatter_issues + 1))
    fi
    
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  if [ "$frontmatter_issues" -gt 0 ]; then
    log_warning "Found $frontmatter_issues frontmatter issue(s)"
    log_info "Issues saved to: $issues_file"
    return 1
  else
    log_success "Frontmatter verification passed: No issues found"
    rm "$issues_file"
    return 0
  fi
}

# Verify overall vault integrity
verify_integrity() {
  log_info "Verifying overall vault integrity"
  
  local integrity_issues=0
  
  # Verify structure
  verify_structure
  if [ $? -ne 0 ]; then
    integrity_issues=$((integrity_issues + 1))
  fi
  
  # Verify links
  verify_links
  if [ $? -ne 0 ]; then
    integrity_issues=$((integrity_issues + 1))
  fi
  
  # Verify frontmatter
  verify_frontmatter
  if [ $? -ne 0 ]; then
    integrity_issues=$((integrity_issues + 1))
  fi
  
  if [ "$integrity_issues" -gt 0 ]; then
    log_warning "Found $integrity_issues integrity issue area(s)"
    return 1
  else
    log_success "Vault integrity verification passed: No issues found"
    return 0
  fi
}

# Generate a verification report
generate_report() {
  local detailed="${1:-false}"
  local today=$(date +"%Y-%m-%d")
  
  log_info "Generating verification report (detailed=$detailed)"
  
  # Create report file
  cat > "$VERIFICATION_REPORT" << EOF
---
title: "Vault Verification Report"
date_created: $today
date_modified: $today
status: active
tags: [documentation, system, verification, report]
---

# Vault Verification Report

This report provides an overview of the verification results for the Athlete Financial Empowerment vault.

## Summary

This report was generated on $today.

EOF
  
  # Verify structure and add to report
  cat >> "$VERIFICATION_REPORT" << EOF
## Structure Verification

EOF
  
  local structure_issues=0
  local structure_log=$(mktemp)
  
  # Capture structure verification output
  verify_structure > "$structure_log" 2>&1
  structure_result=$?
  
  if [ "$structure_result" -eq 0 ]; then
    cat >> "$VERIFICATION_REPORT" << EOF
✅ **Structure verification passed**

All expected directories and files are present.

EOF
  else
    # Count issues
    structure_issues=$(grep -c "Missing\|Issue" "$structure_log" || echo "0")
    
    cat >> "$VERIFICATION_REPORT" << EOF
❌ **Structure verification failed**

Found $structure_issues structure issue(s):

EOF
    
    # Add issues to report if detailed
    if [ "$detailed" = "true" ]; then
      grep "Missing\|Issue" "$structure_log" | sed 's/\x1b\[[0-9;]*m//g' | while IFS= read -r line; do
        echo "- ${line#*] }" >> "$VERIFICATION_REPORT"
      done
    else
      echo "Run with --detailed for issue details." >> "$VERIFICATION_REPORT"
    fi
    
    echo "" >> "$VERIFICATION_REPORT"
  fi
  
  # Verify links and add to report
  cat >> "$VERIFICATION_REPORT" << EOF
## Link Verification

EOF
  
  local link_issues=0
  local link_log=$(mktemp)
  
  # Capture link verification output
  verify_links > "$link_log" 2>&1
  link_result=$?
  
  if [ "$link_result" -eq 0 ]; then
    cat >> "$VERIFICATION_REPORT" << EOF
✅ **Link verification passed**

No broken links found.

EOF
  else
    # Count issues
    link_issues=$(grep -c "Broken link" "$link_log" || echo "0")
    
    cat >> "$VERIFICATION_REPORT" << EOF
❌ **Link verification failed**

Found $link_issues broken link(s):

EOF
    
    # Add issues to report if detailed
    if [ "$detailed" = "true" ]; then
      grep "Broken link" "$link_log" | sed 's/\x1b\[[0-9;]*m//g' | while IFS= read -r line; do
        echo "- ${line#*] }" >> "$VERIFICATION_REPORT"
      done
    else
      echo "Run with --detailed for issue details." >> "$VERIFICATION_REPORT"
    fi
    
    echo "" >> "$VERIFICATION_REPORT"
  fi
  
  # Verify frontmatter and add to report
  cat >> "$VERIFICATION_REPORT" << EOF
## Frontmatter Verification

EOF
  
  local frontmatter_issues=0
  local frontmatter_log=$(mktemp)
  
  # Capture frontmatter verification output
  verify_frontmatter > "$frontmatter_log" 2>&1
  frontmatter_result=$?
  
  if [ "$frontmatter_result" -eq 0 ]; then
    cat >> "$VERIFICATION_REPORT" << EOF
✅ **Frontmatter verification passed**

All files have proper frontmatter.

EOF
  else
    # Count issues
    frontmatter_issues=$(grep -c "Missing\|Invalid" "$frontmatter_log" || echo "0")
    
    cat >> "$VERIFICATION_REPORT" << EOF
❌ **Frontmatter verification failed**

Found $frontmatter_issues frontmatter issue(s):

EOF
    
    # Add issues to report if detailed
    if [ "$detailed" = "true" ]; then
      grep "Missing\|Invalid" "$frontmatter_log" | sed 's/\x1b\[[0-9;]*m//g' | while IFS= read -r line; do
        echo "- ${line#*] }" >> "$VERIFICATION_REPORT"
      done
    else
      echo "Run with --detailed for issue details." >> "$VERIFICATION_REPORT"
    fi
    
    echo "" >> "$VERIFICATION_REPORT"
  fi
  
  # Add overall summary
  cat >> "$VERIFICATION_REPORT" << EOF
## Overall Results

EOF
  
  local total_issues=$((structure_issues + link_issues + frontmatter_issues))
  
  if [ "$total_issues" -eq 0 ]; then
    cat >> "$VERIFICATION_REPORT" << EOF
✅ **All verification checks passed**

The vault is in good condition with no detected issues.
EOF
  else
    cat >> "$VERIFICATION_REPORT" << EOF
❌ **Verification checks failed**

Found a total of $total_issues issue(s):
- Structure Issues: $structure_issues
- Broken Links: $link_issues
- Frontmatter Issues: $frontmatter_issues

## Recommendations

1. Fix frontmatter issues with `./scripts/maintenance.sh standardize-yaml`
2. Fix broken links with `./scripts/maintenance.sh fix-links`
3. Add missing directories and files for proper structure
EOF
  fi
  
  # Add footer
  cat >> "$VERIFICATION_REPORT" << EOF

---

*Report generated: $today*
EOF
  
  # Clean up temporary files
  rm "$structure_log" "$link_log" "$frontmatter_log"
  
  log_success "Verification report saved to: $VERIFICATION_REPORT"
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting verify script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  integrity)
    verify_integrity
    ;;
  links)
    verify_links
    ;;
  frontmatter)
    verify_frontmatter
    ;;
  structure)
    verify_structure
    ;;
  report)
    detailed="false"
    if [[ "$1" == "--detailed" ]]; then
      detailed="true"
      shift
    fi
    generate_report "$detailed"
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

log_info "Verify script completed"
exit 0