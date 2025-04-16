#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Link Fixing and Verification
# ============================================================================
# Purpose: Fixes and verifies internal links in Obsidian markdown files
# Usage:
#   ./links.sh fix <file> - Fix links in a single file
#   ./links.sh fix-all - Fix links in all files
#   ./links.sh verify <file> - Verify links in a file
#   ./links.sh verify-all - Verify links in all files
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/links_${TIMESTAMP}.log"

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
Link Fixing and Verification

Usage: ./links.sh [command] [options]

Commands:
  fix <file>          - Fix links in a single file
  fix-all             - Fix links in all files
  fix-templates       - Fix links in template files
  verify <file>       - Verify links in a file
  verify-all          - Verify links in all files
  help                - Show this help message

Examples:
  ./links.sh fix content/research/file.md
  ./links.sh fix-all
  ./links.sh verify content/research/file.md
  ./links.sh verify-all
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# Fix links in a single file
fix_links() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    log_error "Error: File does not exist: $file"
    return 1
  fi
  
  log_info "Fixing links in $file"
  
  # Create temporary file
  local tmp_file=$(mktemp)
  
  # Regular expression for Obsidian wiki links
  local link_regex='\[\[([^|\]]+)(\|[^\]]+)?\]\]'
  
  # Process file line by line
  while IFS= read -r line; do
    # Check if line contains wiki links
    if [[ "$line" =~ $link_regex ]]; then
      # Process each link in the line
      while [[ "$line" =~ $link_regex ]]; do
        link="${BASH_REMATCH[1]}"
        display="${BASH_REMATCH[2]}"
        
        # Fix common issues with links
        fixed_link="${link}"
        
        # Fix spaces in links (should be dashes or underscores)
        fixed_link="${fixed_link// /-}"
        
        # Fix uppercase in links (should be lowercase)
        fixed_link="${fixed_link,,}"
        
        # Adjust file extension if missing (.md)
        if [[ "$fixed_link" != *.md && "$fixed_link" != */* && "$fixed_link" != *\\* ]]; then
          fixed_link="${fixed_link}.md"
        fi
        
        # Replace the original link with the fixed link
        if [ "$link" != "$fixed_link" ]; then
          if [ -n "$display" ]; then
            # Preserve display text
            line="${line/\[\[$link$display\]\]/\[\[$fixed_link$display\]\]}"
          else
            line="${line/\[\[$link\]\]/\[\[$fixed_link\]\]}"
          fi
          log_info "  Fixed link: $link -> $fixed_link"
        fi
        
        # Remove the processed link to find the next one
        remainder="${line/\[\[$link$display\]\]/}"
        if [ "$remainder" = "$line" ]; then
          break
        fi
        line="$remainder"
      done
    fi
    
    # Write the processed line to the temporary file
    echo "$line" >> "$tmp_file"
  done < "$file"
  
  # Replace original file
  mv "$tmp_file" "$file"
  
  log_success "Fixed links in $file"
  return 0
}

# Fix links in all files
fix_all_links() {
  local include_templates="${1:-false}"
  
  log_info "Fixing links in all markdown files"
  
  # Find all markdown files
  local count=0
  local template_pattern=""
  
  if [ "$include_templates" = "false" ]; then
    # Exclude template files
    template_pattern="-not -path '*template*'"
  fi
  
  while IFS= read -r file; do
    fix_links "$file"
    count=$((count + 1))
  done < <(eval "find \"$VAULT_ROOT\" -name \"*.md\" -type f -not -path \"*/\\.*\" $template_pattern")
  
  log_success "Fixed links in $count files"
  return 0
}

# Fix links in template files
fix_template_links() {
  log_info "Fixing links in template files"
  
  # Find template files
  local count=0
  while IFS= read -r file; do
    fix_links "$file"
    count=$((count + 1))
  done < <(find "$VAULT_ROOT" -name "*template*.md" -type f -not -path "*/\.*")
  
  log_success "Fixed links in $count template files"
  return 0
}

# Verify links in a file
verify_links() {
  local file="$1"
  local broken_links=0
  
  if [ ! -f "$file" ]; then
    log_error "Error: File does not exist: $file"
    return 1
  fi
  
  log_info "Verifying links in $file"
  
  # Regular expression for Obsidian wiki links
  local link_regex='\[\[([^|\]]+)(\|[^\]]+)?\]\]'
  
  # Process file line by line
  while IFS= read -r line; do
    # Check if line contains wiki links
    if [[ "$line" =~ $link_regex ]]; then
      # Process each link in the line
      while [[ "$line" =~ $link_regex ]]; do
        link="${BASH_REMATCH[1]}"
        display="${BASH_REMATCH[2]}"
        
        # Check if the link is to a file or a section
        if [[ "$link" == *#* ]]; then
          # Section link, extract the file part
          file_part="${link%%#*}"
          if [ -n "$file_part" ]; then
            # Check if the file exists
            if [ ! -f "$VAULT_ROOT/$file_part" ]; then
              log_warning "  Broken link: $link (file not found)"
              broken_links=$((broken_links + 1))
            fi
          fi
        else
          # Direct file link
          target_file="$VAULT_ROOT/$link"
          
          # Try with and without .md extension
          if [ ! -f "$target_file" ] && [ ! -f "${target_file}.md" ]; then
            log_warning "  Broken link: $link (file not found)"
            broken_links=$((broken_links + 1))
          fi
        fi
        
        # Remove the processed link to find the next one
        remainder="${line/\[\[$link$display\]\]/}"
        if [ "$remainder" = "$line" ]; then
          break
        fi
        line="$remainder"
      done
    fi
  done < "$file"
  
  if [ "$broken_links" -gt 0 ]; then
    log_warning "Found $broken_links broken link(s) in $file"
    return 1
  else
    log_success "No broken links found in $file"
    return 0
  fi
}

# Verify links in all files
verify_all_links() {
  log_info "Verifying links in all markdown files"
  
  # Find all markdown files
  local count=0
  local broken_count=0
  
  while IFS= read -r file; do
    verify_links "$file" > /dev/null
    result=$?
    count=$((count + 1))
    
    if [ "$result" -ne 0 ]; then
      broken_count=$((broken_count + 1))
    fi
  done < <(find "$VAULT_ROOT" -name "*.md" -type f -not -path "*/\.*")
  
  if [ "$broken_count" -gt 0 ]; then
    log_warning "Found $broken_count file(s) with broken links (out of $count files)"
  else
    log_success "No broken links found in $count files"
  fi
  
  return 0
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting links script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  fix)
    if [ -z "$1" ]; then
      log_error "Error: No file specified"
      show_help
      exit 1
    fi
    fix_links "$1"
    ;;
  fix-all)
    fix_all_links "false"
    ;;
  fix-templates)
    fix_template_links
    ;;
  verify)
    if [ -z "$1" ]; then
      log_error "Error: No file specified"
      show_help
      exit 1
    fi
    verify_links "$1"
    ;;
  verify-all)
    verify_all_links
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

log_info "Links script completed"
exit 0