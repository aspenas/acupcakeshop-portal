#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Template Application Script
# ============================================================================
# Purpose: Helps users apply templates to create new content
# Usage:
#   ./template_apply.sh list - List available templates
#   ./template_apply.sh apply <template> <destination> - Apply a template
#   ./template_apply.sh help - Show help information
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/template_apply_${TIMESTAMP}.log"
TEMPLATES_DIR="$VAULT_ROOT/Resources/Templates"

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
Template Application

Usage: ./template_apply.sh [command] [options]

Commands:
  list [category]        - List available templates (optionally from a specific category)
  apply <template> <destination> - Apply a template to create new content
  help                   - Show this help message

Available template categories:
  interview              - Interview templates
  analysis               - Analysis templates
  project                - Project management templates
  system                 - System templates

Examples:
  ./template_apply.sh list
  ./template_apply.sh list interview
  ./template_apply.sh apply interview/player-interview-template.md content/interviews/players/smith-john.md
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# List available templates
list_templates() {
  local category="${1:-}"
  
  log_info "Listing available templates"
  
  if [ -n "$category" ]; then
    log_info "Category: $category"
    
    # Check if category directory exists
    local category_dir="$TEMPLATES_DIR/$category"
    if [ ! -d "$category_dir" ]; then
      # Try case-insensitive match
      category_dir=$(find "$TEMPLATES_DIR" -type d -iname "$category" | head -1)
      
      if [ -z "$category_dir" ]; then
        log_error "Category not found: $category"
        log_info "Available categories:"
        find "$TEMPLATES_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
          echo "  - $(basename "$dir")"
        done
        return 1
      fi
    fi
    
    # List templates in the category
    log_info "Templates in category $category:"
    find "$category_dir" -name "*.md" -type f | sort | while read -r template; do
      local template_name=$(basename "$template")
      local template_path="$category/$(basename "$template")"
      local title=$(grep "^title:" "$template" | sed 's/^title: *//' | tr -d '"')
      
      echo "  - $template_path: $title"
    done
  else
    # List all categories
    log_info "Template categories:"
    find "$TEMPLATES_DIR" -mindepth 1 -maxdepth 1 -type d | sort | while read -r dir; do
      local category_name=$(basename "$dir")
      local template_count=$(find "$dir" -name "*.md" -type f | wc -l)
      
      echo "  - $category_name ($template_count templates)"
    done
    
    log_info "For specific templates in a category, use:"
    log_info "  ./template_apply.sh list <category>"
  fi
}

# Apply a template to create new content
apply_template() {
  local template_path="$1"
  local destination="$2"
  
  # Validate template path
  local full_template_path="$TEMPLATES_DIR/$template_path"
  if [ ! -f "$full_template_path" ]; then
    log_error "Template not found: $template_path"
    return 1
  fi
  
  # Validate destination path
  local full_destination_path="$VAULT_ROOT/$destination"
  local destination_dir=$(dirname "$full_destination_path")
  
  # Create destination directory if it doesn't exist
  if [ ! -d "$destination_dir" ]; then
    log_info "Creating directory: $destination_dir"
    mkdir -p "$destination_dir"
  fi
  
  # Check if destination file already exists
  if [ -f "$full_destination_path" ]; then
    log_warning "Destination file already exists: $destination"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
      log_info "Operation canceled"
      return 0
    fi
  fi
  
  # Copy template to destination
  log_info "Applying template $template_path to $destination"
  cp "$full_template_path" "$full_destination_path"
  
  # Update frontmatter
  local today=$(date +"%Y-%m-%d")
  local title=$(basename "$destination" .md | tr '-' ' ' | sed -E 's/\b\w/\U&/g')
  
  # Update date fields
  sed -i '' "s/^date_created:.*$/date_created: $today/" "$full_destination_path"
  sed -i '' "s/^date_modified:.*$/date_modified: $today/" "$full_destination_path"
  
  # Update status from template to active or draft
  sed -i '' "s/^status:.*template.*$/status: draft/" "$full_destination_path"
  
  log_success "Template applied successfully to $destination"
  log_info "Remember to:"
  log_info "1. Review and update the content"
  log_info "2. Update the title and tags in the frontmatter"
  log_info "3. Change the status from 'draft' to 'active' when ready"
  
  return 0
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting template apply script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  list)
    list_templates "$1"
    ;;
  apply)
    if [ -z "$1" ] || [ -z "$2" ]; then
      log_error "Missing required arguments for apply command"
      show_help
      exit 1
    fi
    apply_template "$1" "$2"
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

log_info "Template apply script completed"
exit 0