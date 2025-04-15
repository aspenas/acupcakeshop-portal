#!/usr/bin/env bash
# migrate_remaining.sh - Migrate remaining unmigrated content files
#
# This script handles the migration of remaining unmigrated files
# including templates, index files, and other content not handled
# by the initial migration.
#
# Dependencies: bash 4+, find, grep, sed

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Source directories with more comprehensive mappings
readonly SOURCE_DIRS=(
    # Content directories
    "${VAULT_ROOT}/Athlete Financial Empowerment/00-project-overview:content/strategy"
    "${VAULT_ROOT}/Athlete Financial Empowerment/01-market-research:content/research"
    "${VAULT_ROOT}/Athlete Financial Empowerment/01-education:content/research/education"
    "${VAULT_ROOT}/Athlete Financial Empowerment/02-interviews:content/interviews"
    "${VAULT_ROOT}/Athlete Financial Empowerment/03-strategy:content/strategy"
    "${VAULT_ROOT}/Athlete Financial Empowerment/04-analysis:content/research"
    "${VAULT_ROOT}/Athlete Financial Empowerment/05-compliance:content/compliance"
    "${VAULT_ROOT}/Athlete Financial Empowerment/06-planning:content/strategy/planning"
    "${VAULT_ROOT}/Athlete Financial Empowerment/07-team:content/strategy/team"
    
    # Template directories
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates:resources/templates"
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates/interview-templates:resources/templates/interview"
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates/analysis-templates:resources/templates/analysis"
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates/task-templates:resources/templates/task"
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates/competitor-templates:resources/templates/analysis"
    
    # Any other directories
    "${VAULT_ROOT}/Athlete Financial Empowerment/projects:content/strategy/projects"
    "${VAULT_ROOT}/Athlete Financial Empowerment:content"
)

# Files to include (we'll adapt the approach to migrate all files)
readonly SKIP_PATTERNS=(
    ".DS_Store"
    "*.tmp"
    "*.bak"
)

# Maximum number of parallel operations
readonly MAX_PARALLEL=4

# ======================================================================
# Enhanced migration functions
# ======================================================================

# Migrate a single file
# Arguments:
#   $1 - Source file path
#   $2 - Target directory base
# Returns:
#   0 on success, 1 on failure
migrate_file() {
    local source_file="${1}"
    local target_dir_base="${2}"
    local log_prefix="[$(basename "${source_file}")] "
    
    # Skip file patterns
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "${source_file}")" == ${pattern} ]]; then
            log_info "${log_prefix}Skipping file: ${source_file}" "false"
            record_migration "${source_file}" "" "skipped" "Matched skip pattern: ${pattern}"
            return 0
        fi
    done
    
    # Determine target subdirectory
    local target_subdir="${target_dir_base}"
    
    # Clean filename
    local clean_name
    clean_name=$(clean_filename "${source_file}")
    
    # Form target path
    local target_file="${VAULT_ROOT}/${target_subdir}/${clean_name}.md"
    
    # Create target directory if needed
    mkdir -p "$(dirname "${target_file}")"
    
    # Log migration
    log_info "${log_prefix}Migrating: ${source_file} -> ${target_file}" "false"
    
    # Record pending migration
    record_migration "${source_file}" "${target_file}" "pending"
    
    # Copy the file
    if ! cp "${source_file}" "${target_file}"; then
        log_error "${log_prefix}Failed to copy file: ${source_file} -> ${target_file}"
        update_migration_status "${source_file}" "failed" "Copy failed"
        return 1
    fi
    
    # Standardize frontmatter
    if ! standardize_frontmatter "${target_file}"; then
        log_warning "${log_prefix}Failed to standardize frontmatter: ${target_file}"
        # Continue despite frontmatter issues
    fi
    
    # Update migration record
    update_migration_status "${source_file}" "completed"
    
    # Log success
    log_info "${log_prefix}Migration completed: ${source_file}" "false"
    return 0
}

# Process a source directory - revised to handle all files including _index.md files
# Arguments:
#   $1 - Source directory entry (format: source:target)
# Returns:
#   0 on success, non-zero on failure
process_source_directory() {
    local entry="${1}"
    local source_dir="${entry%%:*}"
    local target_dir="${entry#*:}"
    local status=0
    
    # Validate source directory exists
    if [[ ! -d "${source_dir}" ]]; then
        log_warning "Source directory not found: ${source_dir}"
        return 0 # Not a failure, just nothing to process
    fi
    
    log_info "Processing directory: ${source_dir} -> ${target_dir}"
    
    # Check for unmigrated files
    local unmigrated_files="${INVENTORY_DIR}/unmigrated_files.txt"
    
    # Find all markdown files in the source directory
    find "${source_dir}" -type f -name "*.md" | while read -r file; do
        # Check if file is in unmigrated files list
        if grep -q "^${file}$" "${unmigrated_files}" 2>/dev/null; then
            if ! migrate_file "${file}" "${target_dir}"; then
                status=1
            fi
        fi
    done
    
    return "${status}"
}

# Clean a filename for the new structure - adapted to handle index files
# Arguments:
#   $1 - Original filename
# Returns:
#   Cleaned filename (printed to stdout)
clean_filename() {
    local filename="${1}"
    local basename
    
    # Get basename without extension
    basename=$(basename "${filename}" .md)
    
    # Handle special cases
    if [[ "${basename}" == "_index" ]]; then
        # Keep index files as README.md in the new structure
        basename="README"
    elif [[ "${basename}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_ ]]; then
        # Remove date prefix for cleaner names in new structure
        basename="${basename#*_}"
    fi
    
    # Replace underscores with hyphens
    basename=$(echo "${basename}" | tr '_' '-')
    
    # Return cleaned name
    echo "${basename}"
}

# Standardize the frontmatter of a file
# Arguments:
#   $1 - File path
# Returns:
#   0 on success, 1 on failure
standardize_frontmatter() {
    local file="${1}"
    local temp_file="${file}.tmp"
    local has_frontmatter=false
    local creation_date=""
    local modified_date=""
    local title=""
    local status=""
    local tags=""
    
    # Check if file exists
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        return 1
    fi
    
    # Check if file has frontmatter
    if grep -q "^---" "${file}"; then
        has_frontmatter=true
        
        # Extract existing frontmatter values
        creation_date=$(grep -i "^created:" "${file}" | awk '{print $2}' | tr -d '"' || echo "")
        modified_date=$(grep -i "^modified:" "${file}" | awk '{print $2}' | tr -d '"' || echo "")
        title=$(grep -i "^title:" "${file}" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        status=$(grep -i "^status:" "${file}" | awk '{print $2}' | tr -d '"' || echo "")
        
        # Extract tags
        if grep -q "^tags:" "${file}"; then
            # Get tags section
            tags=$(awk '/^tags:/,/^[^-]/' "${file}" | sed '$d' | sed 's/^tags: *//')
        fi
    fi
    
    # Set default values if missing
    [[ -z "${creation_date}" ]] && creation_date=$(date +%Y-%m-%d)
    [[ -z "${modified_date}" ]] && modified_date=$(date +%Y-%m-%d)
    [[ -z "${title}" ]] && title=$(basename "${file}" .md | tr '-' ' ' | sed 's/\<./\U&/g')
    [[ -z "${status}" ]] && status="active"
    
    # Generate standardized frontmatter
    {
        echo "---"
        echo "title: \"${title}\""
        echo "date_created: ${creation_date}"
        echo "date_modified: ${modified_date}"
        echo "status: ${status}"
        
        # Handle tags
        echo "tags: ${tags}"
        
        echo "---"
        echo ""
    } > "${temp_file}"
    
    # Append content after frontmatter
    if [[ "${has_frontmatter}" == "true" ]]; then
        # Skip existing frontmatter when appending
        awk 'BEGIN{f=0} /^---$/{f++} f>=2 || (f==0 && NR>1){print}' "${file}" >> "${temp_file}"
    else
        # Append entire file content
        cat "${file}" >> "${temp_file}"
    fi
    
    # Replace original file
    mv "${temp_file}" "${file}"
    
    return 0
}

# Run migration for all unmigrated files
# Returns:
#   0 on success, non-zero on failure
migrate_all_remaining() {
    local status=0
    local pids=()
    local source_count=${#SOURCE_DIRS[@]}
    local i=0
    
    log_info "Migrating content from ${source_count} source directories..."
    
    # Process source directories with parallelism
    for entry in "${SOURCE_DIRS[@]}"; do
        # Start migration process in background
        process_source_directory "${entry}" &
        pids+=($!)
        ((i++))
        
        # Limit parallel processes
        if [[ ${i} -ge ${MAX_PARALLEL} || ${i} -eq ${source_count} ]]; then
            # Wait for all processes to complete
            for pid in "${pids[@]}"; do
                wait "${pid}" || status=1
            done
            # Reset for next batch
            pids=()
            i=0
        fi
    done
    
    # Wait for any remaining processes
    for pid in "${pids[@]}"; do
        wait "${pid}" || status=1
    done
    
    return "${status}"
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "migrate_remaining" "Remaining Content Migration"
    
    # Start migration
    log_info "Starting migration of remaining content..."
    
    # Migrate all remaining content
    if migrate_all_remaining; then
        log_success "Remaining content migration completed successfully"
        finalize_migration_script 0
        return 0
    else
        log_error "Remaining content migration completed with errors"
        finalize_migration_script 1
        return 1
    fi
}

# Run main function
main "$@"