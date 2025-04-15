#!/usr/bin/env bash
# prepare_migration.sh - Prepare environment for migration
#
# This script prepares the migration environment, including:
# - Creating inventory of source files
# - Validating scripts and permissions
# - Initializing the migration tracker
# - Creating the new directory structure
#
# Dependencies: bash 4+, find, wc, chmod

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Directories to create in the new structure
readonly NEW_DIRECTORIES=(
    "atlas:Knowledge maps and navigation"
    "content:Primary knowledge content"
    "content/interviews:Interview content"
    "content/interviews/players:Player interviews"
    "content/interviews/agents:Agent interviews"
    "content/interviews/industry-professionals:Industry professional interviews"
    "content/research:Research content"
    "content/research/market-analysis:Market analysis"
    "content/research/competitor-profiles:Competitor profiles"
    "content/research/industry-analysis:Industry analysis"
    "content/strategy:Strategic planning"
    "content/strategy/business-model:Business model"
    "content/strategy/planning:Planning"
    "content/strategy/implementation:Implementation"
    "content/compliance:Regulatory compliance"
    "content/compliance/registration:Registration requirements"
    "content/compliance/advisory-board:Advisory board"
    "content/compliance/standards:Regulatory standards"
    "resources:Supporting materials"
    "resources/templates:Templates"
    "resources/templates/interview:Interview templates"
    "resources/templates/analysis:Analysis templates"
    "resources/templates/project:Project templates"
    "resources/templates/task:Task templates"
    "resources/templates/system:System templates"
    "resources/assets:Media and attachments"
    "resources/assets/images:Images"
    "resources/assets/documents:Documents"
    "resources/assets/diagrams:Diagrams"
    "resources/dashboards:Performance dashboards"
    "resources/dashboards/project:Project dashboards"
    "resources/dashboards/competitor:Competitor dashboards"
    "resources/dashboards/financial:Financial dashboards"
    "resources/dashboards/interview:Interview dashboards"
    "docs:Vault documentation"
)

# Scripts that must be executable
readonly REQUIRED_SCRIPTS=(
    "migration_lib.sh"
    "migration_core.sh"
    "backup_vault.sh"
    "prepare_migration.sh"
    "migrate_content.sh"
    "migrate_resources.sh"
    "update_links.sh"
    "verify_migration.sh"
    "generate_reports.sh"
)

# ======================================================================
# Preparation functions
# ======================================================================

# Create directory structure for new vault organization
# Returns:
#   0 on success, 1 on failure
create_directory_structure() {
    log_info "Creating directory structure for the new organization..."
    
    for dir_entry in "${NEW_DIRECTORIES[@]}"; do
        # Split entry into directory path and description
        local dir_path="${dir_entry%%:*}"
        local dir_desc="${dir_entry#*:}"
        local full_path="${VAULT_ROOT}/${dir_path}"
        
        # Create directory
        mkdir -p "${full_path}"
        log_info "Created directory: ${dir_path}" "false"
        
        # Create README.md if not exists
        local readme_path="${full_path}/README.md"
        if [[ ! -f "${readme_path}" ]]; then
            {
                echo "---"
                echo "title: \"${dir_desc}\""
                echo "date_created: $(date +%Y-%m-%d)"
                echo "date_modified: $(date +%Y-%m-%d)"
                echo "status: active"
                echo "tags: [${dir_path/\//-}]"
                echo "---"
                echo ""
                echo "# ${dir_desc}"
                echo ""
                echo "This directory is part of the new vault structure created during migration."
                echo ""
                echo "## Purpose"
                echo ""
                echo "${dir_desc}."
                echo ""
                echo "## Contents"
                echo ""
                echo "This directory will contain the following types of files:"
                echo ""
                echo "- TODO: Add content types after migration"
                echo ""
                echo "## Related Directories"
                echo ""
                echo "- TODO: Add related directories after migration"
                echo ""
                echo "---"
                echo ""
                echo "*Directory created: $(date +%Y-%m-%d)*"
            } > "${readme_path}"
            log_info "Created README: ${readme_path}" "false"
        fi
    done
    
    log_success "Directory structure created successfully"
    return 0
}

# Validate and fix script permissions
# Returns:
#   0 on success, 1 if critical issues found
validate_script_permissions() {
    log_info "Validating script permissions..."
    local status=0
    
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        local script_path="${SCRIPTS_DIR}/${script}"
        
        # Check if script exists
        if [[ ! -f "${script_path}" ]]; then
            log_error "Required script not found: ${script}"
            status=1
            continue
        fi
        
        # Check if script is executable
        if [[ ! -x "${script_path}" ]]; then
            log_warning "Script not executable: ${script}"
            chmod +x "${script_path}"
            
            if [[ -x "${script_path}" ]]; then
                log_info "Fixed permissions for: ${script}"
            else
                log_error "Failed to make script executable: ${script}"
                status=1
            fi
        else
            log_info "Script validated: ${script}" "false"
        fi
    done
    
    if [[ "${status}" -eq 0 ]]; then
        log_success "All scripts have correct permissions"
    else
        log_error "Some scripts have permission issues"
    fi
    
    return "${status}"
}

# Create inventory of source files
# Returns:
#   0 on success
create_source_inventory() {
    log_info "Creating inventory of source files..."
    
    # Ensure inventory directory exists
    mkdir -p "${INVENTORY_DIR}"
    
    # Create inventory of content files
    log_info "Creating content inventory..."
    find "${VAULT_ROOT}/Athlete Financial Empowerment" -type f -name "*.md" > "${INVENTORY_DIR}/content_inventory.txt"
    log_info "Found $(wc -l < "${INVENTORY_DIR}/content_inventory.txt" | tr -d ' ') content files"
    
    # Create inventory of template files
    log_info "Creating templates inventory..."
    {
        find "${VAULT_ROOT}" -path "*/_templates/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -path "*/Templates/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -path "*/templates/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -name "*template*.md"
    } > "${INVENTORY_DIR}/templates_inventory.txt"
    log_info "Found $(wc -l < "${INVENTORY_DIR}/templates_inventory.txt" | tr -d ' ') template files"
    
    # Create inventory of dashboard and map files
    log_info "Creating dashboards and maps inventory..."
    {
        find "${VAULT_ROOT}" -path "*/Dashboards/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -path "*/dashboards/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -path "*/Maps/*" -type f -name "*.md"
        find "${VAULT_ROOT}" -path "*/maps/*" -type f -name "*.md"
    } > "${INVENTORY_DIR}/dashboards_maps_inventory.txt"
    log_info "Found $(wc -l < "${INVENTORY_DIR}/dashboards_maps_inventory.txt" | tr -d ' ') dashboard and map files"
    
    # Create inventory of asset files
    log_info "Creating assets inventory..."
    {
        find "${VAULT_ROOT}" -path "*/attachments/*" -type f ! -name "*.md"
        find "${VAULT_ROOT}" -path "*/Attachments/*" -type f ! -name "*.md"
        find "${VAULT_ROOT}" -path "*/assets/*" -type f ! -name "*.md"
        find "${VAULT_ROOT}" -path "*/Assets/*" -type f ! -name "*.md"
    } > "${INVENTORY_DIR}/assets_inventory.txt"
    log_info "Found $(wc -l < "${INVENTORY_DIR}/assets_inventory.txt" | tr -d ' ') asset files"
    
    log_success "Source inventory created successfully"
    return 0
}

# Initialize the migration tracker
# Returns:
#   0 on success
initialize_migration_tracker() {
    log_info "Initializing migration tracker..."
    
    # Create the migration tracker
    init_migration_tracker
    
    log_success "Migration tracker initialized successfully"
    return 0
}

# Create the .obsidian-ignore file
# Returns:
#   0 on success
create_obsidian_ignore() {
    log_info "Creating .obsidian-ignore file..."
    local ignore_file="${VAULT_ROOT}/.obsidian-ignore"
    
    # Create or update the .obsidian-ignore file
    {
        echo "# Obsidian ignore file"
        echo "# This file tells Obsidian which directories to skip when indexing"
        echo "# It improves performance and prevents indexing of utility files"
        echo ""
        echo "# Utility directories"
        echo "_utilities/"
        echo "System/"
        echo "Scripts/"
        echo ""
        echo "# Backup directories"
        echo "backup_*/"
        echo "*.bak"
        echo ""
        echo "# Temporary files"
        echo "*.tmp"
        echo ".DS_Store"
        echo ""
        echo "# Log files"
        echo "*.log"
    } > "${ignore_file}"
    
    log_success "Created .obsidian-ignore file: ${ignore_file}"
    return 0
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "prepare_migration" "Migration Preparation"
    
    # Start preparation
    log_info "Starting migration preparation..."
    
    # Create directory structure
    if ! create_directory_structure; then
        log_error "Failed to create directory structure"
        finalize_migration_script 1
        return 1
    fi
    
    # Validate script permissions
    if ! validate_script_permissions; then
        log_error "Failed to validate script permissions"
        finalize_migration_script 1
        return 1
    fi
    
    # Create source inventory
    if ! create_source_inventory; then
        log_error "Failed to create source inventory"
        finalize_migration_script 1
        return 1
    fi
    
    # Initialize migration tracker
    if ! initialize_migration_tracker; then
        log_error "Failed to initialize migration tracker"
        finalize_migration_script 1
        return 1
    fi
    
    # Create .obsidian-ignore file
    if ! create_obsidian_ignore; then
        log_warning "Failed to create .obsidian-ignore file"
        # Not critical, so we continue
    fi
    
    # Finalize
    log_success "Migration preparation completed successfully"
    finalize_migration_script 0
    return 0
}

# Run main function
main "$@"