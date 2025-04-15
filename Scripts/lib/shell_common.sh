#!/bin/bash
# shell_common.sh
# Common Shell Utility Functions for Obsidian Vault Scripts

# Ensure script fails on error
set -e

# Configuration
# Get the directory of this script and set the vault path relative to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_PATH="${VAULT_PATH:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SCRIPT_DB_PATH="$VAULT_PATH/System/Configuration/script_database.csv"
LOG_DIR="$VAULT_PATH/System/Logs"
CONFIG_DIR="$VAULT_PATH/System/Configuration"
BACKUP_DIR="$VAULT_PATH/System/Backups"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$CONFIG_DIR" "$BACKUP_DIR"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NCOLOR='\033[0m' # No Color

# Exit codes
CODE_SUCCESS=0
CODE_ERROR=1
CODE_CONFIG_ERROR=2
CODE_DEPENDENCY_ERROR=3
CODE_PERMISSION_ERROR=4
CODE_FILE_ERROR=5
CODE_NETWORK_ERROR=6
CODE_VALIDATION_ERROR=7
CODE_TIMEOUT_ERROR=8
CODE_USER_ABORT=9

# Logging functions
init_logging() {
  SCRIPT_NAME=$1
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_${TIMESTAMP}.log"
  mkdir -p "$LOG_DIR"
  
  # Initialize log
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] INFO: Logging initialized for $SCRIPT_NAME" > "$LOG_FILE"
  
  # Export for child processes
  export SCRIPT_LOG_FILE="$LOG_FILE"
}

log() {
  local level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Colors for console output
  case "$level" in
    "DEBUG")
      level_color="$BLUE"
      ;;
    "INFO")
      level_color="$WHITE"
      ;;
    "SUCCESS")
      level_color="$GREEN"
      ;;
    "WARNING")
      level_color="$YELLOW"
      ;;
    "ERROR")
      level_color="$RED"
      ;;
    "CRITICAL")
      level_color="$PURPLE"
      ;;
    *)
      level_color="$WHITE"
      ;;
  esac
  
  # Console output with color
  echo -e "${level_color}[${timestamp}] ${level}: ${message}${NCOLOR}"
  
  # Log file output
  if [ -n "$SCRIPT_LOG_FILE" ] && [ -f "$SCRIPT_LOG_FILE" ]; then
    echo "[${timestamp}] ${level}: ${message}" >> "$SCRIPT_LOG_FILE"
  fi
}

log_debug() {
  log "DEBUG" "$1"
}

log_info() {
  log "INFO" "$1"
}

log_success() {
  log "SUCCESS" "$1"
}

log_warning() {
  log "WARNING" "$1"
}

log_error() {
  log "ERROR" "$1"
}

log_critical() {
  log "CRITICAL" "$1"
}

rotate_logs() {
  local max_logs=${1:-30}
  local log_count=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
  
  if [ "$log_count" -gt "$max_logs" ]; then
    log_info "Rotating logs, keeping $max_logs most recent"
    ls -t "$LOG_DIR"/*.log | tail -n +$((max_logs+1)) | xargs rm -f
    return 0
  else
    log_debug "Log rotation not needed ($log_count logs)"
    return 0
  fi
}

# Script database functions
update_script_last_run() {
  local script_path=$1
  local run_date=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Check if database exists
  if [ ! -f "$SCRIPT_DB_PATH" ]; then
    log_error "Script database not found at $SCRIPT_DB_PATH"
    return 1
  fi
  
  # Get temporary file
  local temp_file=$(mktemp)
  
  # Updated database with new run date
  awk -F, -v path="$script_path" -v date="$run_date" '
    # Print header as is
    NR == 1 {
      print $0
      next
    }
    # For matching script, update Last Run column (assuming it is the 4th column)
    $1 == path {
      $4 = date
      gsub(/ /, "_", $4)  # Replace spaces with underscores for CSV compatibility
      updated = 1
    }
    # Print all rows
    { 
      # Count fields
      fields = 0
      for (i=1; i<=NF; i++) {
        fields++
      }
      
      # Build output
      output = $1
      for (i=2; i<=fields; i++) {
        output = output "," $i
      }
      print output
    }
    END {
      if (!updated) {
        print "Warning: Script path " path " not found in database"
      }
    }' OFS=, "$SCRIPT_DB_PATH" > "$temp_file"
  
  # Replace database with updated version
  mv "$temp_file" "$SCRIPT_DB_PATH"
  
  log_debug "Updated last run date for $script_path to $run_date"
  return 0
}

# Dependency checking functions
check_command() {
  local cmd=$1
  local package=$2
  
  if ! command -v "$cmd" &> /dev/null; then
    log_error "Required command '$cmd' not found"
    if [ -n "$package" ]; then
      log_info "You may need to install package '$package'"
    fi
    return 1
  else
    log_debug "Command '$cmd' is available"
    return 0
  fi
}

check_python_module() {
  local module=$1
  local package=${2:-$module}
  
  if ! python -c "import $module" &> /dev/null; then
    log_error "Required Python module '$module' not found"
    log_info "You may need to run: pip install $package"
    return 1
  else
    log_debug "Python module '$module' is available"
    return 0
  fi
}

check_file() {
  local file_path=$1
  local message=$2
  
  if [ ! -f "$file_path" ]; then
    if [ -n "$message" ]; then
      log_error "$message"
    else
      log_error "Required file '$file_path' not found"
    fi
    return 1
  else
    log_debug "File '$file_path' is available"
    return 0
  fi
}

check_dir() {
  local dir_path=$1
  local message=$2
  
  if [ ! -d "$dir_path" ]; then
    if [ -n "$message" ]; then
      log_error "$message"
    else
      log_error "Required directory '$dir_path' not found"
    fi
    return 1
  else
    log_debug "Directory '$dir_path' is available"
    return 0
  fi
}

# File operations
backup_file() {
  local file_path=$1
  local backup_dir=${2:-"$BACKUP_DIR"}
  
  if [ ! -f "$file_path" ]; then
    log_error "Cannot backup non-existent file: $file_path"
    return 1
  fi
  
  # Create backup dir if it doesn't exist
  mkdir -p "$backup_dir"
  
  # Create backup filename with timestamp
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local filename=$(basename "$file_path")
  local backup_path="$backup_dir/${filename}.${timestamp}.bak"
  
  # Copy file
  cp "$file_path" "$backup_path"
  
  if [ $? -eq 0 ]; then
    log_debug "Created backup at $backup_path"
    return 0
  else
    log_error "Failed to create backup of $file_path"
    return 1
  fi
}

restore_from_backup() {
  local file_path=$1
  local backup_path=$2
  
  if [ -z "$backup_path" ]; then
    # Find most recent backup
    local filename=$(basename "$file_path")
    backup_path=$(ls -t "$BACKUP_DIR/${filename}."*.bak 2>/dev/null | head -n 1)
    
    if [ -z "$backup_path" ]; then
      log_error "No backup found for $file_path"
      return 1
    fi
  fi
  
  if [ ! -f "$backup_path" ]; then
    log_error "Backup file not found: $backup_path"
    return 1
  fi
  
  # Backup current file before restoring
  if [ -f "$file_path" ]; then
    backup_file "$file_path" "$BACKUP_DIR/restore_backups"
  fi
  
  # Restore from backup
  cp "$backup_path" "$file_path"
  
  if [ $? -eq 0 ]; then
    log_info "Restored $file_path from backup $backup_path"
    return 0
  else
    log_error "Failed to restore from backup $backup_path"
    return 1
  fi
}

# Config functions
read_json_config() {
  local config_file=$1
  local key=$2
  local default_value=$3
  
  if [ ! -f "$config_file" ]; then
    log_error "Config file not found: $config_file"
    echo "$default_value"
    return 1
  fi
  
  # Try to parse JSON with Python
  if command -v python &> /dev/null; then
    value=$(python -c "import json; f=open('$config_file'); data=json.load(f); f.close(); print(data.get('$key', '$default_value'))" 2>/dev/null)
    if [ $? -eq 0 ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Fallback to grep and awk
  value=$(grep -o "\"$key\"\s*:\s*\"[^\"]\+\"" "$config_file" | awk -F\" '{print $4}')
  if [ -n "$value" ]; then
    echo "$value"
    return 0
  fi
  
  # Return default if key not found
  echo "$default_value"
  return 0
}

# User interaction functions
confirm() {
  local message=${1:-"Continue?"}
  local default=${2:-"n"}
  
  if [ "$default" = "y" ]; then
    prompt="$message [Y/n]: "
  else
    prompt="$message [y/N]: "
  fi
  
  read -p "$prompt" response
  response=${response,,}  # Convert to lowercase
  
  if [ -z "$response" ]; then
    response=$default
  fi
  
  if [[ "$response" =~ ^(yes|y)$ ]]; then
    return 0
  else
    return 1
  fi
}

show_spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\\'
  
  while [ "$(ps a | awk '{print $1}' | grep -c "^$pid$")" -eq 1 ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Cleanup and trap functions
cleanup() {
  log_debug "Cleaning up temporary files"
  
  # Delete any temp files created by mktemp
  rm -f /tmp/vault_script_*.tmp 2>/dev/null
  
  # Add custom cleanup tasks here
  
  log_info "Script completed"
}

# Register cleanup on exit
trap cleanup EXIT

# Handle interrupts gracefully
trap "log_warning 'Script interrupted by user'; exit $CODE_USER_ABORT" INT

# Error handling function
handle_error() {
  local exit_code=$?
  local line_number=$1
  log_error "Error on line $line_number: Command exited with status $exit_code"
  exit $exit_code
}

# Uncomment to enable more error catching
# trap 'handle_error ${LINENO}' ERR

# Usage: run_script "script_path" [args...]
run_script() {
  local script_path=$1
  shift  # Remove first argument
  
  if [ ! -f "$script_path" ]; then
    log_error "Script not found: $script_path"
    return $CODE_FILE_ERROR
  fi
  
  log_info "Running script: $script_path $@"
  
  # Determine how to run based on file extension
  case "$script_path" in
    *.sh)
      bash "$script_path" "$@"
      ;;
    *.py)
      python "$script_path" "$@"
      ;;
    *.js)
      node "$script_path" "$@"
      ;;
    *)
      log_error "Unknown script type: $script_path"
      return $CODE_ERROR
      ;;
  esac
  
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    log_success "Script completed successfully: $script_path"
    update_script_last_run "$script_path"
  else
    log_error "Script failed with exit code $exit_code: $script_path"
  fi
  
  return $exit_code
}

# Print script banner
print_banner() {
  local script_name=$1
  local version=${2:-"1.0.0"}
  local width=${3:-60}
  
  local padding=$(( (width - ${#script_name} - ${#version} - 4) / 2 ))
  local padding_str=$(printf '%*s' "$padding" '')
  
  echo
  echo "$(printf '%*s' "$width" '' | tr ' ' '=')"
  echo "=$padding_str $script_name v$version $padding_str="
  echo "$(printf '%*s' "$width" '' | tr ' ' '=')"
  echo
}

# Main function for scripts to implement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Script is being executed directly
  echo "This is a library file and should be sourced by other scripts, not executed directly."
  exit $CODE_ERROR
fi