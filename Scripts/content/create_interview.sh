#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Interview Creation Script
# ============================================================================
# Purpose: Creates new interview files and related content
# Usage:
#   ./create_interview.sh player <name> <team> <position> - Create a player interview
#   ./create_interview.sh agent <name> <agency> - Create an agent interview
#   ./create_interview.sh advisor <name> <company> - Create a financial advisor interview
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/create_interview_${TIMESTAMP}.log"
TEMPLATES_DIR="$VAULT_ROOT/Resources/Templates"

# Templates paths
PLAYER_TEMPLATE="$TEMPLATES_DIR/Interview/player-interview-template.md"
AGENT_TEMPLATE="$TEMPLATES_DIR/Interview/agent-interview-template.md"
ADVISOR_TEMPLATE="$TEMPLATES_DIR/Interview/cap-strategist-interview-template.md"

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
Interview Creation

Usage: ./create_interview.sh [type] [options]

Types:
  player <first> <last> <team> <position> - Create a player interview
  agent <first> <last> <agency> - Create an agent interview
  advisor <first> <last> <company> - Create a financial advisor interview
  help - Show this help message

Examples:
  ./create_interview.sh player John Smith Vikings Quarterback
  ./create_interview.sh agent David Johnson ProSports
  ./create_interview.sh advisor Michael Williams CapitalAdvisors
EOF
}

# Convert text to kebab case (lowercase with hyphens)
to_kebab_case() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//'
}

# ============================================================================
# Core Functions
# ============================================================================

# Create a player interview
create_player_interview() {
  local first_name="$1"
  local last_name="$2"
  local team="$3"
  local position="$4"
  
  # Format name and path elements
  local player_name="$first_name $last_name"
  local player_name_kebab="$(to_kebab_case "$first_name")-$(to_kebab_case "$last_name")"
  local team_kebab="$(to_kebab_case "$team")"
  local position_kebab="$(to_kebab_case "$position")"
  
  # Create file path
  local today=$(date +"%Y-%m-%d")
  local year=$(date +"%Y")
  local month_name=$(date +"%m_%B" | tr '[:upper:]' '[:lower:]')
  
  local interview_dir="$VAULT_ROOT/content/interviews/players/active/$year/$month_name"
  local interview_file="$interview_dir/$player_name_kebab-$team_kebab-$position_kebab.md"
  
  # Create directory if it doesn't exist
  if [ ! -d "$interview_dir" ]; then
    log_info "Creating directory: $interview_dir"
    mkdir -p "$interview_dir"
  fi
  
  # Check if file already exists
  if [ -f "$interview_file" ]; then
    log_warning "Interview file already exists: $interview_file"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
      log_info "Operation canceled"
      return 0
    fi
  fi
  
  # Copy template to destination
  log_info "Creating player interview for $player_name"
  cp "$PLAYER_TEMPLATE" "$interview_file"
  
  # Update frontmatter
  local file_title="Player Interview - $player_name ($team $position)"
  
  # Update frontmatter fields
  sed -i '' "s/^title:.*$/title: \"$file_title\"/" "$interview_file"
  sed -i '' "s/^date_created:.*$/date_created: $today/" "$interview_file"
  sed -i '' "s/^date_modified:.*$/date_modified: $today/" "$interview_file"
  sed -i '' "s/^status:.*$/status: draft/" "$interview_file"
  sed -i '' "s/^tags:.*$/tags: [interview, player, $team_kebab, $position_kebab, draft]/" "$interview_file"
  
  # Add file to atlas map
  local map_file="$VAULT_ROOT/atlas/interview-map.md"
  
  if [ -f "$map_file" ]; then
    log_info "Updating interview map: $map_file"
    
    # Check if entry already exists
    if ! grep -q "$player_name_kebab" "$map_file"; then
      # Insert new entry under the Players section
      local relative_path="content/interviews/players/active/$year/$month_name/$player_name_kebab-$team_kebab-$position_kebab"
      
      # Find the Players section in the map file
      local insert_line=$(grep -n "## Players" "$map_file" | head -1 | cut -d: -f1)
      
      if [ -n "$insert_line" ]; then
        # Insert two lines after the heading
        insert_line=$((insert_line + 2))
        
        # Insert the new entry
        sed -i '' "${insert_line}a\\
- [[${relative_path}|${player_name} (${team} ${position})]]" "$map_file"
        
        log_success "Added entry to interview map"
      else
        log_warning "Could not find Players section in interview map"
      fi
    fi
  else
    log_warning "Interview map not found: $map_file"
  fi
  
  log_success "Created player interview: $interview_file"
  log_info "Remember to:"
  log_info "1. Add interview details and notes"
  log_info "2. Update the status from 'draft' to 'active' when complete"
  
  return 0
}

# Create an agent interview
create_agent_interview() {
  local first_name="$1"
  local last_name="$2"
  local agency="$3"
  
  # Format name and path elements
  local agent_name="$first_name $last_name"
  local agent_name_kebab="$(to_kebab_case "$first_name")-$(to_kebab_case "$last_name")"
  local agency_kebab="$(to_kebab_case "$agency")"
  
  # Create file path
  local today=$(date +"%Y-%m-%d")
  local year=$(date +"%Y")
  local month_name=$(date +"%m_%B" | tr '[:upper:]' '[:lower:]')
  
  local interview_dir="$VAULT_ROOT/content/interviews/agents/$year/$month_name"
  local interview_file="$interview_dir/$agent_name_kebab-$agency_kebab-agent.md"
  
  # Create directory if it doesn't exist
  if [ ! -d "$interview_dir" ]; then
    log_info "Creating directory: $interview_dir"
    mkdir -p "$interview_dir"
  fi
  
  # Check if file already exists
  if [ -f "$interview_file" ]; then
    log_warning "Interview file already exists: $interview_file"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
      log_info "Operation canceled"
      return 0
    fi
  fi
  
  # Copy template to destination
  log_info "Creating agent interview for $agent_name"
  cp "$AGENT_TEMPLATE" "$interview_file"
  
  # Update frontmatter
  local file_title="Agent Interview - $agent_name ($agency)"
  
  # Update frontmatter fields
  sed -i '' "s/^title:.*$/title: \"$file_title\"/" "$interview_file"
  sed -i '' "s/^date_created:.*$/date_created: $today/" "$interview_file"
  sed -i '' "s/^date_modified:.*$/date_modified: $today/" "$interview_file"
  sed -i '' "s/^status:.*$/status: draft/" "$interview_file"
  sed -i '' "s/^tags:.*$/tags: [interview, agent, $agency_kebab, draft]/" "$interview_file"
  
  log_success "Created agent interview: $interview_file"
  log_info "Remember to:"
  log_info "1. Add interview details and notes"
  log_info "2. Update the status from 'draft' to 'active' when complete"
  
  return 0
}

# Create a financial advisor interview
create_advisor_interview() {
  local first_name="$1"
  local last_name="$2"
  local company="$3"
  
  # Format name and path elements
  local advisor_name="$first_name $last_name"
  local advisor_name_kebab="$(to_kebab_case "$first_name")-$(to_kebab_case "$last_name")"
  local company_kebab="$(to_kebab_case "$company")"
  
  # Create file path
  local today=$(date +"%Y-%m-%d")
  local year=$(date +"%Y")
  local month_name=$(date +"%m_%B" | tr '[:upper:]' '[:lower:]')
  
  local interview_dir="$VAULT_ROOT/content/interviews/industry-professionals/$year/$month_name"
  local interview_file="$interview_dir/$advisor_name_kebab-$company_kebab-financial-advisor.md"
  
  # Create directory if it doesn't exist
  if [ ! -d "$interview_dir" ]; then
    log_info "Creating directory: $interview_dir"
    mkdir -p "$interview_dir"
  fi
  
  # Check if file already exists
  if [ -f "$interview_file" ]; then
    log_warning "Interview file already exists: $interview_file"
    read -p "Overwrite? (y/n): " overwrite
    if [ "$overwrite" != "y" ]; then
      log_info "Operation canceled"
      return 0
    fi
  fi
  
  # Copy template to destination
  log_info "Creating financial advisor interview for $advisor_name"
  cp "$ADVISOR_TEMPLATE" "$interview_file"
  
  # Update frontmatter
  local file_title="Financial Advisor Interview - $advisor_name ($company)"
  
  # Update frontmatter fields
  sed -i '' "s/^title:.*$/title: \"$file_title\"/" "$interview_file"
  sed -i '' "s/^date_created:.*$/date_created: $today/" "$interview_file"
  sed -i '' "s/^date_modified:.*$/date_modified: $today/" "$interview_file"
  sed -i '' "s/^status:.*$/status: draft/" "$interview_file"
  sed -i '' "s/^tags:.*$/tags: [interview, financial-advisor, $company_kebab, draft]/" "$interview_file"
  
  log_success "Created financial advisor interview: $interview_file"
  log_info "Remember to:"
  log_info "1. Add interview details and notes"
  log_info "2. Update the status from 'draft' to 'active' when complete"
  
  return 0
}

# ============================================================================
# Command Handling
# ============================================================================
log_info "Starting interview creation script"
log_info "Vault root: $VAULT_ROOT"
log_info "Log file: $LOG_FILE"

# Parse command
COMMAND="$1"
shift || true

case "$COMMAND" in
  player)
    if [ $# -lt 4 ]; then
      log_error "Missing required arguments for player interview"
      show_help
      exit 1
    fi
    create_player_interview "$1" "$2" "$3" "$4"
    ;;
  agent)
    if [ $# -lt 3 ]; then
      log_error "Missing required arguments for agent interview"
      show_help
      exit 1
    fi
    create_agent_interview "$1" "$2" "$3"
    ;;
  advisor)
    if [ $# -lt 3 ]; then
      log_error "Missing required arguments for advisor interview"
      show_help
      exit 1
    fi
    create_advisor_interview "$1" "$2" "$3"
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

log_info "Interview creation script completed"
exit 0