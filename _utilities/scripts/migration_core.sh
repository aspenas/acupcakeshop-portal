#!/usr/bin/env bash
# migration_core.sh - Core migration manager script
#
# This script manages the overall migration process, including:
# - Creating a full vault backup
# - Setting up the migration environment
# - Running migration phases in the correct order
# - Generating migration reports
#
# Dependencies: bash 4+, rsync, coreutils

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Migration phases and corresponding scripts
readonly MIGRATION_PHASES=(
    "1_backup:backup_vault.sh:Create full vault backup"
    "2_prepare:prepare_migration.sh:Prepare migration environment"
    "3_content:migrate_content.sh:Migrate content files"
    "4_resources:migrate_resources.sh:Migrate resources"
    "5_links:update_links.sh:Update internal links"
    "6_verify:verify_migration.sh:Verify migration completeness"
    "7_report:generate_reports.sh:Generate migration reports"
)

# Directory paths for the new structure
readonly NEW_DIRECTORIES=(
    "atlas:Knowledge maps and navigation"
    "content:Primary knowledge content"
    "content/interviews:Interview content"
    "content/research:Research content"
    "content/strategy:Strategic planning"
    "content/compliance:Regulatory compliance"
    "resources:Supporting materials"
    "resources/templates:Templates"
    "resources/assets:Media and attachments"
    "resources/dashboards:Performance dashboards"
    "_utilities:Non-content utilities"
    "_utilities/scripts:Automation scripts"
    "_utilities/config:Configuration files"
    "docs:Vault documentation"
)

# ======================================================================
# Migration functions
# ======================================================================

# Create the new directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    for dir_entry in "${NEW_DIRECTORIES[@]}"; do
        # Split entry into directory name and description
        local dir_name="${dir_entry%%:*}"
        local dir_desc="${dir_entry#*:}"
        local full_path="${VAULT_ROOT}/${dir_name}"
        
        # Create directory
        log_info "Creating directory: ${dir_name} (${dir_desc})"
        mkdir -p "${full_path}"
        
        # Create README stub if not exists
        local readme_path="${full_path}/README.md"
        if [[ ! -f "${readme_path}" ]]; then
            {
                echo "---"
                echo "title: \"${dir_desc}\""
                echo "date_created: $(date +%Y-%m-%d)"
                echo "date_modified: $(date +%Y-%m-%d)"
                echo "status: active"
                echo "tags: [directory, ${dir_name}]"
                echo "---"
                echo ""
                echo "# ${dir_desc}"
                echo ""
                echo "This directory is part of the migrated vault structure."
                echo ""
                echo "## Purpose"
                echo ""
                echo "${dir_desc}"
                echo ""
                echo "## Contents"
                echo ""
                echo "* TODO: Document contents after migration"
                echo ""
                echo "---"
                echo ""
                echo "*Directory created: $(date +%Y-%m-%d)*"
            } > "${readme_path}"
            log_info "Created README stub: ${readme_path}" "false"
        fi
    done
    
    log_success "Directory structure created successfully"
    return 0
}

# Validate all required scripts exist
validate_migration_scripts() {
    log_info "Validating migration scripts..."
    local missing_scripts=0
    
    for phase_entry in "${MIGRATION_PHASES[@]}"; do
        local script_name="${phase_entry#*:}"
        script_name="${script_name%%:*}"
        local script_path="${SCRIPTS_DIR}/${script_name}"
        
        if [[ ! -f "${script_path}" ]]; then
            log_error "Missing migration script: ${script_name}"
            ((missing_scripts++))
        elif [[ ! -x "${script_path}" ]]; then
            log_warning "Migration script not executable: ${script_name}"
            chmod +x "${script_path}" && log_info "Made executable: ${script_name}" || log_error "Failed to make executable: ${script_name}"
        fi
    done
    
    if [[ "${missing_scripts}" -gt 0 ]]; then
        log_error "${missing_scripts} migration scripts are missing"
        return 1
    fi
    
    log_success "All migration scripts validated successfully"
    return 0
}

# Create the migration inventory
create_migration_inventory() {
    log_info "Creating migration inventory..."
    
    # Ensure inventory directory exists
    mkdir -p "${INVENTORY_DIR}"
    
    # Create inventory of source files
    local content_inventory="${INVENTORY_DIR}/content_inventory.txt"
    local templates_inventory="${INVENTORY_DIR}/templates_inventory.txt"
    local resources_inventory="${INVENTORY_DIR}/resources_inventory.txt"
    local assets_inventory="${INVENTORY_DIR}/assets_inventory.txt"
    
    log_info "Finding content files..."
    find "${VAULT_ROOT}/Athlete Financial Empowerment" -type f -name "*.md" > "${content_inventory}"
    log_info "Found $(wc -l < "${content_inventory}") content files" "false"
    
    log_info "Finding template files..."
    find "${VAULT_ROOT}" -path "*/*template*/*" -type f -name "*.md" > "${templates_inventory}"
    find "${VAULT_ROOT}" -name "*template*.md" >> "${templates_inventory}"
    log_info "Found $(wc -l < "${templates_inventory}") template files" "false"
    
    log_info "Finding resource files..."
    find "${VAULT_ROOT}/Resources" -type f -name "*.md" > "${resources_inventory}"
    find "${VAULT_ROOT}/Dashboards" -type f -name "*.md" >> "${resources_inventory}"
    find "${VAULT_ROOT}/Maps" -type f -name "*.md" >> "${resources_inventory}"
    log_info "Found $(wc -l < "${resources_inventory}") resource files" "false"
    
    log_info "Finding asset files..."
    find "${VAULT_ROOT}" -path "*/attachments/*" -type f ! -name "*.md" > "${assets_inventory}"
    find "${VAULT_ROOT}" -path "*/Resources/Attachments/*" -type f ! -name "*.md" >> "${assets_inventory}"
    log_info "Found $(wc -l < "${assets_inventory}") asset files" "false"
    
    # Initialize migration tracker
    init_migration_tracker
    
    log_success "Migration inventory created successfully"
    return 0
}

# Run a migration phase
run_migration_phase() {
    local phase_num="${1}"
    local phase_entry=""
    
    # Find the phase entry
    for entry in "${MIGRATION_PHASES[@]}"; do
        if [[ "${entry}" == "${phase_num}"* ]]; then
            phase_entry="${entry}"
            break
        fi
    done
    
    if [[ -z "${phase_entry}" ]]; then
        log_error "Migration phase not found: ${phase_num}"
        return 1
    fi
    
    # Extract phase information
    local phase_id="${phase_entry%%:*}"
    local script_name="${phase_entry#*:}"
    script_name="${script_name%%:*}"
    local phase_desc="${phase_entry##*:}"
    local script_path="${SCRIPTS_DIR}/${script_name}"
    
    # Log phase start
    log_info "========================================================================"
    log_info "Starting migration phase ${phase_id}: ${phase_desc}"
    log_info "========================================================================"
    
    # Run the phase script
    if [[ -x "${script_path}" ]]; then
        if "${script_path}"; then
            log_success "Migration phase ${phase_id} completed successfully: ${phase_desc}"
            return 0
        else
            local status=$?
            log_error "Migration phase ${phase_id} failed with status ${status}: ${phase_desc}"
            return "${status}"
        fi
    else
        log_error "Migration script not executable: ${script_path}"
        return 1
    fi
}

# Generate overall migration summary
generate_migration_summary() {
    local summary_file="${VAULT_ROOT}/docs/migration_summary.md"
    local migration_date=$(date +%Y-%m-%d)
    local total_files_migrated=0
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    
    # Count migrated files by status
    local completed=$(grep -c ",completed," "${tracker}" || echo 0)
    local skipped=$(grep -c ",skipped," "${tracker}" || echo 0)
    local failed=$(grep -c ",failed," "${tracker}" || echo 0)
    local pending=$(grep -c ",pending," "${tracker}" || echo 0)
    
    total_files_migrated=$((completed + skipped))
    
    # Generate summary markdown
    {
        echo "---"
        echo "title: \"Migration Summary\""
        echo "date_created: ${migration_date}"
        echo "date_modified: ${migration_date}"
        echo "status: active"
        echo "tags: [migration, summary, report]"
        echo "---"
        echo ""
        echo "# Vault Migration Summary"
        echo ""
        echo "## Overview"
        echo ""
        echo "The vault migration process has been completed. This report provides a summary of the migration results."
        echo ""
        echo "## Migration Statistics"
        echo ""
        echo "- **Date**: ${migration_date}"
        echo "- **Total Files Processed**: $((completed + skipped + failed + pending))"
        echo "- **Successfully Migrated**: ${completed}"
        echo "- **Skipped Files**: ${skipped}"
        echo "- **Failed Migrations**: ${failed}"
        echo "- **Pending Migrations**: ${pending}"
        echo ""
        echo "## New Vault Structure"
        echo ""
        echo "\`\`\`"
        echo "/acupcakeshop/"
        for dir_entry in "${NEW_DIRECTORIES[@]}"; do
            local dir_name="${dir_entry%%:*}"
            local dir_desc="${dir_entry#*:}"
            
            # Calculate indentation based on depth
            local depth=$(tr -cd '/' <<< "${dir_name}" | wc -c)
            local indent=""
            for ((i=0; i<depth; i++)); do
                indent="${indent}  "
            done
            
            # Extract last component of path
            local display_name=$(basename "${dir_name}")
            echo "${indent}├── ${display_name}/ - ${dir_desc}"
        done
        echo "\`\`\`"
        echo ""
        echo "## Migration Results by Category"
        echo ""
        echo "### Content Files"
        echo ""
        echo "- **Total Content Files**: $(wc -l < "${INVENTORY_DIR}/content_inventory.txt")"
        echo "- **Migrated Content Files**: $(grep ",content/," "${tracker}" | grep -c ",completed," || echo 0)"
        echo ""
        echo "### Templates"
        echo ""
        echo "- **Total Template Files**: $(wc -l < "${INVENTORY_DIR}/templates_inventory.txt")"
        echo "- **Migrated Template Files**: $(grep ",resources/templates/," "${tracker}" | grep -c ",completed," || echo 0)"
        echo ""
        echo "### Resources"
        echo ""
        echo "- **Total Resource Files**: $(wc -l < "${INVENTORY_DIR}/resources_inventory.txt")"
        echo "- **Migrated Dashboards**: $(grep ",resources/dashboards/," "${tracker}" | grep -c ",completed," || echo 0)"
        echo "- **Migrated Maps**: $(grep ",atlas/," "${tracker}" | grep -c ",completed," || echo 0)"
        echo ""
        echo "### Assets"
        echo ""
        echo "- **Total Asset Files**: $(wc -l < "${INVENTORY_DIR}/assets_inventory.txt")"
        echo "- **Migrated Asset Files**: $(grep ",resources/assets/," "${tracker}" | grep -c ",completed," || echo 0)"
        echo ""
        echo "## Next Steps"
        echo ""
        echo "1. Review the [Verification Report](migration_verification_report.md) for details on any issues"
        echo "2. Address any failed migrations or identified issues"
        echo "3. Begin using the new vault structure for all content"
        echo "4. Consider running a final verification after manual fixes"
        echo ""
        echo "---"
        echo ""
        echo "*Summary generated: $(date)*"
    } > "${summary_file}"
    
    log_success "Migration summary generated: ${summary_file}"
    return 0
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "migration_core" "Core Migration Manager"
    
    # Create the vault backup first for safety
    log_info "Creating comprehensive vault backup..."
    if ! create_vault_backup; then
        log_error "Failed to create vault backup, aborting migration"
        finalize_migration_script 1
        return 1
    fi
    
    # Create directory structure
    if ! create_directory_structure; then
        log_error "Failed to create directory structure, aborting migration"
        finalize_migration_script 1
        return 1
    fi
    
    # Validate migration scripts
    if ! validate_migration_scripts; then
        log_error "Failed to validate migration scripts, aborting migration"
        finalize_migration_script 1
        return 1
    fi
    
    # Create migration inventory
    if ! create_migration_inventory; then
        log_error "Failed to create migration inventory, aborting migration"
        finalize_migration_script 1
        return 1
    fi
    
    # Execute each migration phase
    local phase_status=0
    for phase_entry in "${MIGRATION_PHASES[@]}"; do
        local phase_id="${phase_entry%%:*}"
        
        if ! run_migration_phase "${phase_id}"; then
            phase_status=$?
            log_error "Migration phase ${phase_id} failed, continuing with next phase"
            # Continue with next phase instead of aborting
        fi
    done
    
    # Generate migration summary
    generate_migration_summary
    
    # Finalize
    if [[ "${phase_status}" -eq 0 ]]; then
        log_success "Migration completed successfully"
        finalize_migration_script 0
        return 0
    else
        log_warning "Migration completed with some issues (status: ${phase_status})"
        finalize_migration_script "${phase_status}"
        return "${phase_status}"
    fi
}

# Run main function
main "$@"