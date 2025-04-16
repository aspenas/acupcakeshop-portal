#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# GitHub Sync Script
# ============================================================================
# Purpose: Handles synchronization of vault content with GitHub
# Usage:
#   ./github.sh sync - Sync vault with GitHub
#   ./github.sh status - Check sync status
#   ./github.sh help - Show help information
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/github_sync_${TIMESTAMP}.log"

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
GitHub Sync

Usage: ./github.sh [command] [options]

Commands:
  sync                  - Sync vault with GitHub
  status                - Check sync status
  help                  - Show this help message

Options:
  --message <message>   - Custom commit message (for sync command)
  --dry-run             - Show what would be done, but don't make changes
  --force               - Force push changes (use with caution)

Examples:
  ./github.sh sync
  ./github.sh sync --message "Updated player interviews"
  ./github.sh status
EOF
}

# ============================================================================
# Core Functions
# ============================================================================

# Check the sync status with GitHub
check_status() {
  local dry_run="${1:-false}"
  
  log_info "Checking sync status with GitHub"
  
  # Fetch latest changes from the remote
  if [ "$dry_run" = "false" ]; then
    log_info "Fetching latest changes from GitHub..."
    git fetch origin
  else
    log_info "Would fetch latest changes from GitHub (dry run)"
  fi
  
  # Check if the local main branch is behind the remote main branch
  if [ "$dry_run" = "false" ]; then
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "")
    
    if [ -z "$REMOTE" ]; then
      log_warning "Remote branch 'origin/main' not found. Is this repository connected to GitHub?"
      return 1
    fi
    
    if [ "$LOCAL" != "$REMOTE" ]; then
      log_warning "Local branch is not up-to-date with origin/main."
      log_info "Local:  $LOCAL"
      log_info "Remote: $REMOTE"
      
      # Check if there are unpushed commits
      local unpushed=$(git log origin/main..HEAD --oneline 2>/dev/null)
      if [ -n "$unpushed" ]; then
        log_info "Unpushed commits:"
        echo "$unpushed"
      fi
      
      # Check if there are unpulled commits
      local unpulled=$(git log HEAD..origin/main --oneline 2>/dev/null)
      if [ -n "$unpulled" ]; then
        log_info "Unpulled commits:"
        echo "$unpulled"
      fi
    else
      log_success "Local branch is up-to-date with origin/main."
    fi
  else
    log_info "Would check if local branch is up-to-date (dry run)"
  fi
  
  # Check for uncommitted changes
  if [ "$dry_run" = "false" ]; then
    if git diff-index --quiet HEAD --; then
      log_success "No uncommitted changes."
    else
      log_warning "Uncommitted changes detected:"
      git status --short
    fi
  else
    log_info "Would check for uncommitted changes (dry run)"
  fi
}

# Sync vault with GitHub
sync_vault() {
  local message="${1:-}"
  local dry_run="${2:-false}"
  local force="${3:-false}"
  
  log_info "Syncing vault with GitHub"
  
  # Fetch latest changes from the remote
  if [ "$dry_run" = "false" ]; then
    log_info "Fetching latest changes from GitHub..."
    git fetch origin
  else
    log_info "Would fetch latest changes from GitHub (dry run)"
  fi
  
  # Check if the local main branch is behind the remote main branch
  if [ "$dry_run" = "false" ]; then
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "")
    
    if [ -z "$REMOTE" ]; then
      log_error "Remote branch 'origin/main' not found. Is this repository connected to GitHub?"
      return 1
    fi
    
    if [ "$LOCAL" != "$REMOTE" ]; then
      log_warning "Local branch is not up-to-date with origin/main. Attempting fast-forward merge..."
      
      # Try a fast-forward merge only to avoid complex merge conflicts automatically
      if git merge --ff-only origin/main; then
        log_success "Merged origin/main."
      else
        log_error "Could not fast-forward merge. Please resolve conflicts manually."
        return 1
      fi
    else
      log_success "Local branch is up-to-date with origin/main."
    fi
  else
    log_info "Would check if merge is needed (dry run)"
  fi
  
  # Add all changes (including new files, deletions, modifications)
  if [ "$dry_run" = "false" ]; then
    log_info "Adding all changes to git..."
    git add .
  else
    log_info "Would add all changes to git (dry run)"
  fi
  
  # Check if there are any changes to commit
  if [ "$dry_run" = "false" ]; then
    if git diff-index --quiet HEAD --; then
      log_info "No changes to commit."
      return 0
    fi
  else
    log_info "Would check if there are changes to commit (dry run)"
  fi
  
  # Prepare commit message
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S %Z")
  local commit_msg="${message:-"Automated vault sync: $timestamp"}"
  
  # Commit changes
  if [ "$dry_run" = "false" ]; then
    log_info "Committing changes with message: '$commit_msg'"
    git commit -m "$commit_msg"
  else
    log_info "Would commit changes with message: '$commit_msg' (dry run)"
  fi
  
  # Push changes to the main branch
  if [ "$dry_run" = "false" ]; then
    log_info "Pushing changes to origin main..."
    
    if [ "$force" = "true" ]; then
      log_warning "Force pushing changes to GitHub..."
      if git push -f origin main; then
        log_success "Successfully force pushed changes to GitHub."
      else
        log_error "Failed to force push changes to GitHub."
        return 1
      fi
    else
      if git push origin main; then
        log_success "Successfully pushed changes to GitHub."
      else
        log_error "Failed to push changes to GitHub."
        return 1
      fi
    fi
  else
    log_info "Would push changes to origin main (dry run)"
  fi
  
  log_success "Vault sync completed successfully"
  return 0
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting GitHub sync script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  sync)
    # Parse arguments
    local message=""
    local dry_run="false"
    local force="false"
    
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --message)
          message="$2"
          shift 2
          ;;
        --dry-run)
          dry_run="true"
          shift
          ;;
        --force)
          force="true"
          shift
          ;;
        *)
          log_error "Unknown argument: $1"
          shift
          ;;
      esac
    done
    
    sync_vault "$message" "$dry_run" "$force"
    ;;
  status)
    # Parse arguments
    local dry_run="false"
    
    while [[ "$#" -gt 0 ]]; do
      case $1 in
        --dry-run)
          dry_run="true"
          shift
          ;;
        *)
          log_error "Unknown argument: $1"
          shift
          ;;
      esac
    done
    
    check_status "$dry_run"
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

log_info "GitHub sync script completed"
exit 0