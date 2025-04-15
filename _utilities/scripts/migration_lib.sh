#!/usr/bin/env bash
# migration_lib.sh - Core functions for the vault migration process
# 
# This library provides robust utilities for error handling, logging,
# validation, and safe file operations used throughout the migration scripts.
#
# Dependencies: bash 4+, rsync, find, grep, sed

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# ======================================================================
# Constants and configuration
# ======================================================================

# Base paths
readonly VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
readonly UTILITIES_DIR="${VAULT_ROOT}/_utilities"
readonly SCRIPTS_DIR="${UTILITIES_DIR}/scripts"
readonly LOGS_DIR="${UTILITIES_DIR}/logs"
readonly INVENTORY_DIR="${UTILITIES_DIR}/inventory"
readonly BACKUPS_DIR="${UTILITIES_DIR}/backups"
readonly CONFIG_DIR="${UTILITIES_DIR}/config"

# Script tracing (uncomment for debug mode)
# export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
# set -x

# ======================================================================
# Logging functions
# ======================================================================

# Initialize logging for a script
# Arguments:
#   $1 - Script name
#   $2 - Optional log file name (if different from script name)
# Returns:
#   Sets global LOG_FILE variable
init_logging() {
    local script_name="${1}"
    local log_name="${2:-${script_name}}"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Create logs directory if it doesn't exist
    mkdir -p "${LOGS_DIR}"
    
    # Set global log file path
    LOG_FILE="${LOGS_DIR}/${log_name}_${timestamp}.log"
    
    # Start log with header
    {
        echo "========================================================================"
        echo "LOG: ${script_name}"
        echo "STARTED: $(date)"
        echo "USER: $(whoami)"
        echo "PID: $$"
        echo "========================================================================"
        echo ""
    } > "${LOG_FILE}"
    
    # Print log file location
    echo "Logging to: ${LOG_FILE}" >&2
    
    return 0
}

# Log a message to file and (optionally) to stdout
# Arguments:
#   $1 - Log message
#   $2 - Optional log level (INFO, WARNING, ERROR, SUCCESS) - defaults to INFO
#   $3 - Optional flag to echo to stdout (true/false) - defaults to true
log_message() {
    local message="${1}"
    local level="${2:-INFO}"
    local echo_to_stdout="${3:-true}"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Ensure LOG_FILE is defined
    if [[ -z "${LOG_FILE:-}" ]]; then
        echo "Error: LOG_FILE not defined. Call init_logging first." >&2
        return 1
    fi
    
    # Format message with timestamp and level
    local formatted_message="[${timestamp}] [${level}] ${message}"
    
    # Write to log file
    echo "${formatted_message}" >> "${LOG_FILE}"
    
    # Echo to stdout if requested
    if [[ "${echo_to_stdout}" == "true" ]]; then
        # Color output based on level
        case "${level}" in
            ERROR)
                echo -e "\033[31m${formatted_message}\033[0m" >&2
                ;;
            WARNING)
                echo -e "\033[33m${formatted_message}\033[0m" >&2
                ;;
            SUCCESS)
                echo -e "\033[32m${formatted_message}\033[0m" >&2
                ;;
            *)
                echo "${formatted_message}" >&2
                ;;
        esac
    fi
    
    return 0
}

# Log an info message
# Arguments:
#   $1 - Log message
#   $2 - Optional flag to echo to stdout (true/false) - defaults to true
log_info() {
    log_message "${1}" "INFO" "${2:-true}"
}

# Log a warning message
# Arguments:
#   $1 - Log message
#   $2 - Optional flag to echo to stdout (true/false) - defaults to true
log_warning() {
    log_message "${1}" "WARNING" "${2:-true}"
}

# Log an error message
# Arguments:
#   $1 - Log message
#   $2 - Optional flag to echo to stdout (true/false) - defaults to true
log_error() {
    log_message "${1}" "ERROR" "${2:-true}"
}

# Log a success message
# Arguments:
#   $1 - Log message
#   $2 - Optional flag to echo to stdout (true/false) - defaults to true
log_success() {
    log_message "${1}" "SUCCESS" "${2:-true}"
}

# Log script completion
# Arguments:
#   $1 - Optional exit status (defaults to 0)
log_completion() {
    local status="${1:-0}"
    
    {
        echo ""
        echo "========================================================================"
        echo "COMPLETED: $(date)"
        echo "STATUS: ${status}"
        echo "========================================================================"
    } >> "${LOG_FILE}"
    
    if [[ "${status}" -eq 0 ]]; then
        log_success "Script completed successfully."
    else
        log_error "Script completed with errors (status: ${status})."
    fi
    
    return 0
}

# ======================================================================
# Error handling functions
# ======================================================================

# Global error handler
# Called automatically on error via trap (when strict mode fails)
error_handler() {
    local error_code="$?"
    local line_number="$1"
    local command="$2"
    local script_name="${0##*/}"
    
    # Log the error
    log_error "Error occurred in ${script_name}:${line_number}: '${command}' (exit code: ${error_code})"
    
    # Print stack trace
    local i=0
    local frame
    echo "Stack trace:" >> "${LOG_FILE}"
    while frame=$(caller "$i"); do
        echo "  $frame" >> "${LOG_FILE}"
        ((i++))
    done
    
    log_completion "${error_code}"
    
    # Exit with error code
    exit "${error_code}"
}

# Set up error handling
setup_error_handling() {
    trap 'error_handler "${LINENO}" "${BASH_COMMAND}"' ERR
}

# Safe execution with error handling
# Arguments:
#   $@ - Command to execute with arguments
# Returns:
#   Command's exit code
safe_exec() {
    local cmd_output
    local cmd_status
    
    # Execute command and capture output and status
    if ! cmd_output=$("$@" 2>&1); then
        cmd_status=$?
        log_error "Command failed: $*"
        log_error "Output: ${cmd_output}"
        return "${cmd_status}"
    fi
    
    # Success - log the output
    log_info "Command successful: $*"
    log_info "Output: ${cmd_output}" "false"
    
    return 0
}

# ======================================================================
# Validation functions
# ======================================================================

# Validate a directory exists and is writable
# Arguments:
#   $1 - Directory path
# Returns:
#   0 if directory exists and is writable, 1 otherwise
validate_directory() {
    local dir="${1}"
    
    if [[ ! -d "${dir}" ]]; then
        log_error "Directory does not exist: ${dir}"
        return 1
    fi
    
    if [[ ! -w "${dir}" ]]; then
        log_error "Directory not writable: ${dir}"
        return 1
    fi
    
    log_info "Validated directory: ${dir}" "false"
    return 0
}

# Validate a file exists and is readable
# Arguments:
#   $1 - File path
# Returns:
#   0 if file exists and is readable, 1 otherwise
validate_file() {
    local file="${1}"
    
    if [[ ! -f "${file}" ]]; then
        log_error "File does not exist: ${file}"
        return 1
    fi
    
    if [[ ! -r "${file}" ]]; then
        log_error "File not readable: ${file}"
        return 1
    fi
    
    log_info "Validated file: ${file}" "false"
    return 0
}

# Validate string is not empty
# Arguments:
#   $1 - String to validate
#   $2 - Variable name for error message
# Returns:
#   0 if string is not empty, 1 otherwise
validate_not_empty() {
    local value="${1}"
    local var_name="${2:-value}"
    
    if [[ -z "${value}" ]]; then
        log_error "${var_name} cannot be empty"
        return 1
    fi
    
    return 0
}

# ======================================================================
# File operation functions
# ======================================================================

# Create a backup of a file
# Arguments:
#   $1 - File path
# Returns:
#   0 on success, 1 on failure
backup_file() {
    local file="${1}"
    local backup_file="${BACKUPS_DIR}/$(basename "${file}")_$(date +%Y%m%d_%H%M%S).bak"
    
    # Ensure backup directory exists
    mkdir -p "${BACKUPS_DIR}"
    
    if [[ ! -f "${file}" ]]; then
        log_warning "File does not exist, cannot backup: ${file}"
        return 0
    fi
    
    # Create backup
    if cp -p "${file}" "${backup_file}"; then
        log_info "Backed up file: ${file} -> ${backup_file}" "false"
        return 0
    else
        log_error "Failed to backup file: ${file}"
        return 1
    fi
}

# Copy a file with safety checks
# Arguments:
#   $1 - Source file
#   $2 - Destination file
# Returns:
#   0 on success, 1 on failure
safe_copy() {
    local source="${1}"
    local destination="${2}"
    
    # Validate source exists
    if [[ ! -f "${source}" ]]; then
        log_error "Source file does not exist: ${source}"
        return 1
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "${destination}")"
    
    # Backup destination if it exists
    if [[ -f "${destination}" ]]; then
        backup_file "${destination}"
    fi
    
    # Copy file
    if cp -p "${source}" "${destination}"; then
        log_info "Copied file: ${source} -> ${destination}" "false"
        return 0
    else
        log_error "Failed to copy file: ${source} -> ${destination}"
        return 1
    fi
}

# Create a full backup of the vault
# Returns:
#   0 on success, 1 on failure
create_vault_backup() {
    local timestamp
    local backup_dir
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="/Users/patricksmith/obsidian/acupcakeshop_backup_${timestamp}"
    
    log_info "Creating full vault backup to: ${backup_dir}"
    
    # Create backup directory
    mkdir -p "${backup_dir}"
    
    # Use rsync for efficient backup
    if rsync -av --exclude "_utilities/backups" --exclude ".git" "${VAULT_ROOT}/" "${backup_dir}/"; then
        # Save backup location to file
        echo "Vault backup created at: ${backup_dir}" > "${LOGS_DIR}/backup_location_${timestamp}.txt"
        log_success "Vault backup created successfully at: ${backup_dir}"
        return 0
    else
        log_error "Failed to create vault backup"
        return 1
    fi
}

# ======================================================================
# Migration tracking functions
# ======================================================================

# Initialize migration tracking database
# Returns:
#   0 on success, 1 on failure
init_migration_tracker() {
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    
    # Ensure inventory directory exists
    mkdir -p "${INVENTORY_DIR}"
    
    # Create or reset tracking file
    {
        echo "source_path,target_path,status,migration_date,verified,notes"
    } > "${tracker}"
    
    log_info "Initialized migration tracker: ${tracker}"
    return 0
}

# Record a migration action in the tracking database
# Arguments:
#   $1 - Source path
#   $2 - Target path
#   $3 - Status (pending, completed, skipped, failed)
#   $4 - Optional notes
# Returns:
#   0 on success, 1 on failure
record_migration() {
    local source="${1}"
    local target="${2}"
    local status="${3}"
    local notes="${4:-}"
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    local migration_date
    
    migration_date=$(date +%Y-%m-%d)
    
    # Validate tracker exists
    if [[ ! -f "${tracker}" ]]; then
        log_error "Migration tracker not found: ${tracker}"
        return 1
    fi
    
    # Record migration
    {
        echo "${source},${target},${status},${migration_date},no,${notes}"
    } >> "${tracker}"
    
    log_info "Recorded migration: ${source} -> ${target} (${status})" "false"
    return 0
}

# Update a migration record in the tracking database
# Arguments:
#   $1 - Source path
#   $2 - New status
#   $3 - Optional notes
# Returns:
#   0 on success, 1 on failure
update_migration_status() {
    local source="${1}"
    local status="${2}"
    local notes="${3:-}"
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    local temp_file="${INVENTORY_DIR}/tracker_temp_$$.csv"
    
    # Validate tracker exists
    if [[ ! -f "${tracker}" ]]; then
        log_error "Migration tracker not found: ${tracker}"
        return 1
    fi
    
    # Update status
    awk -F, -v source="${source}" -v status="${status}" -v notes="${notes}" '
        BEGIN { OFS = "," }
        NR == 1 { print; next }
        $1 == source { 
            $3 = status
            if (notes != "") { $6 = notes }
            print
            found = 1
            next
        }
        { print }
        END { if (!found) exit 1 }
    ' "${tracker}" > "${temp_file}"
    
    if [[ $? -ne 0 ]]; then
        log_error "Source file not found in tracker: ${source}"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Replace original file
    mv "${temp_file}" "${tracker}"
    
    log_info "Updated migration status for ${source} to ${status}" "false"
    return 0
}

# Mark a migration record as verified
# Arguments:
#   $1 - Target path
# Returns:
#   0 on success, 1 on failure
mark_migration_verified() {
    local target="${1}"
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    local temp_file="${INVENTORY_DIR}/tracker_temp_$$.csv"
    
    # Validate tracker exists
    if [[ ! -f "${tracker}" ]]; then
        log_error "Migration tracker not found: ${tracker}"
        return 1
    fi
    
    # Update verification status
    awk -F, -v target="${target}" '
        BEGIN { OFS = "," }
        NR == 1 { print; next }
        $2 == target { 
            $5 = "yes"
            print
            found = 1
            next
        }
        { print }
        END { if (!found) exit 1 }
    ' "${tracker}" > "${temp_file}"
    
    if [[ $? -ne 0 ]]; then
        log_error "Target file not found in tracker: ${target}"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Replace original file
    mv "${temp_file}" "${tracker}"
    
    log_info "Marked migration as verified for ${target}" "false"
    return 0
}

# ======================================================================
# Initialization
# ======================================================================

# Initialize a migration script
# Arguments:
#   $1 - Script name for logging
#   $2 - Optional description for logging
# Returns:
#   0 on success
init_migration_script() {
    local script_name="${1}"
    local description="${2:-}"
    
    # Initialize logging
    init_logging "${script_name}"
    
    # Setup error handling
    setup_error_handling
    
    # Log script start
    log_info "Starting script: ${script_name}"
    if [[ -n "${description}" ]]; then
        log_info "Description: ${description}"
    fi
    
    # Validate essential directories
    validate_directory "${VAULT_ROOT}" || return 1
    validate_directory "${UTILITIES_DIR}" || return 1
    validate_directory "${SCRIPTS_DIR}" || return 1
    
    # Ensure all utility directories exist
    mkdir -p "${LOGS_DIR}" "${INVENTORY_DIR}" "${BACKUPS_DIR}" "${CONFIG_DIR}"
    
    return 0
}

# Cleanup and finalize a migration script
# Arguments:
#   $1 - Optional exit status (defaults to 0)
finalize_migration_script() {
    local status="${1:-0}"
    
    # Log completion
    log_completion "${status}"
    
    return "${status}"
}

# ======================================================================
# Script execution
# ======================================================================

# If the script is being run directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize
    init_migration_script "migration_lib"
    
    # Test function
    log_info "Migration library loaded successfully. This script is meant to be sourced, not executed directly."
    
    # Finalize
    finalize_migration_script 0
fi