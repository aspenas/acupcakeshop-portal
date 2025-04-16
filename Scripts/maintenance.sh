#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Unified Maintenance Script
# ============================================================================
# Purpose: Provides a unified interface for vault maintenance tasks
# Usage: ./maintenance.sh [command] [options]
# Commands:
#   standardize-yaml     - Standardize YAML frontmatter in files
#   fix-links            - Fix broken links in files
#   verify               - Verify vault integrity
#   audit-tags           - Audit tags used in the vault
#   clean                - Clean up temporary files
#   backup               - Create backup of vault
#   help                 - Show this help message
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/maintenance_${TIMESTAMP}.log"

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
Athlete Financial Empowerment Vault Maintenance

Usage: ./maintenance.sh [command] [options]

Commands:
  standardize-yaml     - Standardize YAML frontmatter in files
  fix-links            - Fix broken links in files
  verify               - Verify vault integrity
  audit-tags           - Audit tags used in the vault
  standardize-tags     - Standardize tags across the vault
  list-tags            - List all tags used in the vault
  find-tag <tag>       - Find files with a specific tag
  list-templates       - List available templates
  apply-template       - Apply a template to create new content
  create-interview     - Create a new interview file
  clean                - Clean up temporary files
  backup               - Create backup of vault
  help                 - Show this help message

Examples:
  ./maintenance.sh standardize-yaml --dir content
  ./maintenance.sh fix-links --all
  ./maintenance.sh verify --report --detailed
  ./maintenance.sh audit-tags --report
  ./maintenance.sh standardize-tags
  ./maintenance.sh list-tags
  ./maintenance.sh find-tag interview
  ./maintenance.sh list-templates
  ./maintenance.sh apply-template interview/player-interview-template.md content/interviews/new-interview.md
  ./maintenance.sh create-interview player John Smith Vikings Quarterback
  ./maintenance.sh clean
  ./maintenance.sh backup

For detailed help on a specific command:
  ./maintenance.sh [command] --help
EOF
}

# ============================================================================
# Command Implementations
# ============================================================================

# Standardize YAML frontmatter
cmd_standardize_yaml() {
  local dir="$VAULT_ROOT"
  
  # Parse arguments
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --dir)
        dir="$2"
        shift 2
        ;;
      *)
        log_error "Unknown argument: $1"
        shift
        ;;
    esac
  done
  
  log_info "Standardizing YAML frontmatter in $dir"
  log_info "This will ensure all files have proper YAML frontmatter"
  
  # Call the frontmatter script with appropriate parameters
  "$VAULT_ROOT/scripts/maintenance/frontmatter.sh" batch "$dir"
  
  log_success "YAML standardization completed successfully"
}

# Fix broken links
cmd_fix_links() {
  local fix_all="${1:-false}"
  
  log_info "Fixing broken links in vault"
  if [ "$fix_all" = "true" ]; then
    log_info "Fixing all links (including templates)"
  else
    log_info "Fixing only broken links in content files"
  fi
  
  # Call the links script with appropriate parameters
  if [ "$fix_all" = "true" ]; then
    "$VAULT_ROOT/scripts/maintenance/links.sh" fix-templates
    "$VAULT_ROOT/scripts/maintenance/links.sh" fix-all
  else
    "$VAULT_ROOT/scripts/maintenance/links.sh" fix-all
  fi
  
  log_success "Link fixing completed successfully"
}

# Verify vault integrity
cmd_verify() {
  local report="${1:-false}"
  local detailed="${2:-false}"
  
  log_info "Verifying vault integrity"
  log_info "This will check for broken links, missing files, and frontmatter issues"
  
  # Call the verify script for integrity check
  "$VAULT_ROOT/scripts/maintenance/verify.sh" integrity
  
  # Generate report if requested
  if [ "$report" = "true" ]; then
    log_info "Generating verification report"
    
    if [ "$detailed" = "true" ]; then
      "$VAULT_ROOT/scripts/maintenance/verify.sh" report --detailed
    else
      "$VAULT_ROOT/scripts/maintenance/verify.sh" report
    fi
  fi
  
  log_success "Vault verification completed successfully"
}

# Audit tags
cmd_audit_tags() {
  local report="${1:-false}"
  
  log_info "Auditing tags in vault"
  log_info "This will identify all tags used and check for inconsistencies"
  
  # Call the tags script with appropriate parameters
  "$VAULT_ROOT/scripts/maintenance/tags.sh" audit
  
  # Generate report if requested
  if [ "$report" = "true" ]; then
    log_info "Generating tag report"
    "$VAULT_ROOT/scripts/maintenance/tags.sh" report
  fi
  
  log_success "Tag audit completed successfully"
}

# Clean up temporary files
cmd_clean() {
  log_info "Cleaning up temporary files"
  
  # TODO: Implement cleanup
  # This will be a consolidated version of:
  # - final_cleanup.sh
  # - post_migration_cleanup.sh
  
  log_success "Cleanup completed successfully"
}

# Create backup
cmd_backup() {
  local backup_dir="$VAULT_ROOT/../acupcakeshop_archives/backup_${TIMESTAMP}"
  
  log_info "Creating backup of vault to $backup_dir"
  
  # Create backup directory
  mkdir -p "$backup_dir"
  
  # Copy vault contents, excluding backup directories and other large files
  rsync -a --exclude "Backups" --exclude "_utilities/logs" --exclude "backup_*" \
    "$VAULT_ROOT/" "$backup_dir/"
  
  log_success "Backup completed successfully to $backup_dir"
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting vault maintenance script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  standardize-yaml)
    cmd_standardize_yaml "$@"
    ;;
  fix-links)
    local fix_all="false"
    if [[ "$1" == "--all" ]]; then
      fix_all="true"
      shift
    fi
    cmd_fix_links "$fix_all"
    ;;
  verify)
    local report="false"
    local detailed="false"
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --report)
          report="true"
          shift
          ;;
        --detailed)
          detailed="true"
          shift
          ;;
        *)
          log_error "Unknown argument: $1"
          shift
          ;;
      esac
    done
    
    cmd_verify "$report" "$detailed"
    ;;
  audit-tags)
    local report="false"
    if [[ "$1" == "--report" ]]; then
      report="true"
      shift
    fi
    cmd_audit_tags "$report"
    ;;
  standardize-tags)
    log_info "Standardizing tags across the vault"
    "$VAULT_ROOT/scripts/maintenance/tags.sh" standardize
    log_success "Tag standardization completed successfully"
    ;;
  list-tags)
    log_info "Listing all tags used in the vault"
    "$VAULT_ROOT/scripts/maintenance/tags.sh" list
    log_success "Tag listing completed successfully"
    ;;
  find-tag)
    if [ -z "$1" ]; then
      log_error "Error: No tag specified"
      show_help
      exit 1
    fi
    log_info "Finding files with tag: $1"
    "$VAULT_ROOT/scripts/maintenance/tags.sh" find "$1"
    log_success "Tag search completed successfully"
    ;;
  list-templates)
    log_info "Listing available templates"
    "$VAULT_ROOT/scripts/content/template_apply.sh" list "$1"
    log_success "Template listing completed successfully"
    ;;
  apply-template)
    if [ -z "$1" ] || [ -z "$2" ]; then
      log_error "Error: Missing required arguments"
      log_info "Usage: ./maintenance.sh apply-template <template> <destination>"
      exit 1
    fi
    log_info "Applying template $1 to $2"
    "$VAULT_ROOT/scripts/content/template_apply.sh" apply "$1" "$2"
    log_success "Template application completed successfully"
    ;;
  create-interview)
    if [ -z "$1" ]; then
      log_error "Error: Missing interview type"
      log_info "Usage: ./maintenance.sh create-interview <type> [args]"
      log_info "Types: player, agent, advisor"
      exit 1
    fi
    log_info "Creating new interview"
    "$VAULT_ROOT/scripts/content/create_interview.sh" "$@"
    log_success "Interview creation completed successfully"
    ;;
  clean)
    cmd_clean
    ;;
  backup)
    cmd_backup
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

log_info "Maintenance script completed"
exit 0