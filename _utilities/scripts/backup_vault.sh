#!/usr/bin/env bash
# backup_vault.sh - Create a comprehensive backup of the vault
#
# This script creates a full, timestamped backup of the vault before
# starting the migration process, with integrity verification.
#
# Dependencies: bash 4+, rsync, find, md5sum

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Timestamp for backup
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Backup directory
readonly BACKUP_DIR="/Users/patricksmith/obsidian/acupcakeshop_backup_${TIMESTAMP}"

# Files to exclude from backup
readonly EXCLUDE_PATTERNS=(
    ".git/*"
    ".DS_Store"
    "*.tmp"
    "*.bak"
    "_utilities/backups/*"
)

# Number of files to sample for verification
readonly VERIFICATION_SAMPLE_SIZE=20

# ======================================================================
# Backup functions
# ======================================================================

# Create a comprehensive backup of the vault
# Returns:
#   0 on success, 1 on failure
create_backup() {
    log_info "Creating comprehensive vault backup..."
    log_info "Backup directory: ${BACKUP_DIR}"
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Build exclude pattern arguments for rsync
    local exclude_args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args+=(--exclude "${pattern}")
    done
    
    # Use rsync to create backup with exclusions
    log_info "Copying files to backup directory..."
    if rsync -av "${exclude_args[@]}" "${VAULT_ROOT}/" "${BACKUP_DIR}/"; then
        log_success "Files copied to backup directory"
    else
        log_error "Failed to copy files to backup directory"
        return 1
    fi
    
    # Create a file inventory for the backup
    log_info "Creating backup inventory..."
    find "${BACKUP_DIR}" -type f | sort > "${BACKUP_DIR}/backup_inventory.txt"
    
    # Get file counts
    local backup_count
    backup_count=$(wc -l < "${BACKUP_DIR}/backup_inventory.txt" | tr -d ' ')
    log_info "Backed up ${backup_count} files"
    
    # Save backup location to log directory
    echo "Vault backup created at: ${BACKUP_DIR}" > "${LOGS_DIR}/backup_location_${TIMESTAMP}.txt"
    
    return 0
}

# Verify backup integrity
# Returns:
#   0 if verification passes, 1 if verification fails
verify_backup() {
    log_info "Verifying backup integrity..."
    local verification_file="${BACKUP_DIR}/backup_verification.txt"
    local status=0
    
    # Create sample list for verification
    local sample_file="${BACKUP_DIR}/verification_sample.txt"
    if [[ -f "${BACKUP_DIR}/backup_inventory.txt" ]]; then
        # Get random sample of files
        sort -R "${BACKUP_DIR}/backup_inventory.txt" | head -n "${VERIFICATION_SAMPLE_SIZE}" > "${sample_file}"
    else
        log_error "Backup inventory not found, cannot verify backup"
        return 1
    fi
    
    # Verify each sample file
    while read -r file; do
        # Skip backup metadata files
        if [[ "${file}" == *"backup_inventory.txt" || "${file}" == *"verification_sample.txt" || "${file}" == *"backup_verification.txt" ]]; then
            continue
        fi
        
        # Get source file path
        local source_file="${file/${BACKUP_DIR}/${VAULT_ROOT}}"
        
        # Skip if source file doesn't exist (e.g., it's a new file in the backup)
        if [[ ! -f "${source_file}" ]]; then
            echo "${file}: SOURCE_MISSING" >> "${verification_file}"
            continue
        fi
        
        # Compare files
        if cmp -s "${source_file}" "${file}"; then
            echo "${file}: OK" >> "${verification_file}"
        else
            echo "${file}: MISMATCH" >> "${verification_file}"
            log_error "Verification failed for: ${file}"
            status=1
        fi
    done < "${sample_file}"
    
    # Report verification results
    if [[ "${status}" -eq 0 ]]; then
        log_success "Backup verification passed"
    else
        log_error "Backup verification failed - some files do not match"
    fi
    
    return "${status}"
}

# Create backup statistics
# Returns:
#   0 on success
create_backup_stats() {
    log_info "Creating backup statistics..."
    local stats_file="${BACKUP_DIR}/backup_stats.txt"
    
    # Generate statistics
    {
        echo "Backup Statistics"
        echo "================="
        echo "Backup created: $(date)"
        echo "Backup directory: ${BACKUP_DIR}"
        echo ""
        echo "File Counts"
        echo "----------"
        echo "Total files: $(find "${BACKUP_DIR}" -type f | wc -l)"
        echo "Markdown files: $(find "${BACKUP_DIR}" -name "*.md" | wc -l)"
        echo "Script files: $(find "${BACKUP_DIR}" -name "*.py" -o -name "*.sh" | wc -l)"
        echo "Asset files: $(find "${BACKUP_DIR}" -path "*/attachments/*" -o -path "*/assets/*" | wc -l)"
        echo ""
        echo "Directory Sizes"
        echo "--------------"
        du -h -d 1 "${BACKUP_DIR}" | sort -hr
        echo ""
        echo "Verification Status"
        echo "-----------------"
        if [[ -f "${BACKUP_DIR}/backup_verification.txt" ]]; then
            grep -c "OK$" "${BACKUP_DIR}/backup_verification.txt" | xargs echo "Verified files:"
            grep -c "MISMATCH$" "${BACKUP_DIR}/backup_verification.txt" | xargs echo "Mismatched files:"
            grep -c "SOURCE_MISSING$" "${BACKUP_DIR}/backup_verification.txt" | xargs echo "New files:"
        else
            echo "Verification not performed"
        fi
        echo ""
        echo "Generated: $(date)"
    } > "${stats_file}"
    
    log_success "Backup statistics created: ${stats_file}"
    return 0
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "backup_vault" "Vault Backup"
    
    # Start backup process
    log_info "Starting vault backup process..."
    
    # Create the backup
    if ! create_backup; then
        log_error "Failed to create backup, aborting"
        finalize_migration_script 1
        return 1
    fi
    
    # Verify backup integrity
    if ! verify_backup; then
        log_warning "Backup verification failed, but continuing with migration"
        # Note: We continue even if verification fails
    fi
    
    # Create backup statistics
    create_backup_stats
    
    # Finalize
    log_success "Backup process completed successfully"
    log_info "Backup location: ${BACKUP_DIR}"
    log_info "Backup location recorded in: ${LOGS_DIR}/backup_location_${TIMESTAMP}.txt"
    
    finalize_migration_script 0
    return 0
}

# Run main function
main "$@"