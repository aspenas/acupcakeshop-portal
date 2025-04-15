#!/usr/bin/env bash
# migrate_resources.sh - Migrate resource files to new structure
#
# This script handles the migration of resource files, including:
# - Templates from multiple source directories
# - Dashboards and visualizations
# - Maps and navigation aids
# - Assets (images, documents, etc.)
#
# Dependencies: bash 4+, sed, awk, find, grep

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Template source directories and target mappings
readonly TEMPLATE_SOURCES=(
    "${VAULT_ROOT}/Athlete Financial Empowerment/_templates:interview:Interview templates from main content"
    "${VAULT_ROOT}/Resources/Templates:system:Templates from Resources directory"
    "${VAULT_ROOT}/Templates:system:Templates from root Templates directory"
)

# Dashboard source directories and target mappings
readonly DASHBOARD_SOURCES=(
    "${VAULT_ROOT}/Dashboards:project:Dashboards from root directory"
    "${VAULT_ROOT}/Resources/Dashboards:project:Dashboards from Resources directory"
)

# Map source directories and target mappings
readonly MAP_SOURCES=(
    "${VAULT_ROOT}/Maps:atlas:Maps from root directory"
    "${VAULT_ROOT}/Resources/Maps:atlas:Maps from Resources directory"
)

# Asset source directories and target mappings
readonly ASSET_SOURCES=(
    "${VAULT_ROOT}/attachments:resources/assets:Attachments from root directory"
    "${VAULT_ROOT}/Resources/Attachments:resources/assets:Attachments from Resources directory"
)

# File patterns to skip
readonly SKIP_PATTERNS=(
    "_index.md"
    ".DS_Store"
    "*.tmp"
    "*.bak"
)

# Maximum number of parallel operations
readonly MAX_PARALLEL=4

# ======================================================================
# Helper functions
# ======================================================================

# Determine template category based on filename and content
# Arguments:
#   $1 - File path
# Returns:
#   Category name (interview, analysis, project, task, system)
determine_template_category() {
    local file="${1}"
    local filename
    local content_preview
    
    filename=$(basename "${file}" | tr '[:upper:]' '[:lower:]')
    content_preview=$(head -n 20 "${file}" 2>/dev/null)
    
    # Determine category based on filename and content
    if [[ "${filename}" == *"interview"* ]] || grep -q "interview\|player\|agent" <<< "${content_preview}"; then
        echo "interview"
    elif [[ "${filename}" == *"competitor"* || "${filename}" == *"analysis"* ]] || grep -q "competitor\|analysis\|research" <<< "${content_preview}"; then
        echo "analysis" 
    elif [[ "${filename}" == *"project"* ]] || grep -q "project\|plan\|timeline" <<< "${content_preview}"; then
        echo "project"
    elif [[ "${filename}" == *"task"* ]] || grep -q "task\|todo\|assignee" <<< "${content_preview}"; then
        echo "task"
    else
        echo "system"
    fi
}

# Determine dashboard category based on filename and content
# Arguments:
#   $1 - File path
# Returns:
#   Category name (project, competitor, financial, interview)
determine_dashboard_category() {
    local file="${1}"
    local filename
    local content_preview
    
    filename=$(basename "${file}" | tr '[:upper:]' '[:lower:]')
    content_preview=$(head -n 20 "${file}" 2>/dev/null)
    
    # Determine category based on filename and content
    if [[ "${filename}" == *"competitor"* ]] || grep -q "competitor\|market\|analysis" <<< "${content_preview}"; then
        echo "competitor"
    elif [[ "${filename}" == *"financial"* || "${filename}" == *"finance"* ]] || grep -q "financial\|money\|budget" <<< "${content_preview}"; then
        echo "financial"
    elif [[ "${filename}" == *"interview"* ]] || grep -q "interview\|player\|agent" <<< "${content_preview}"; then
        echo "interview"
    else
        echo "project"
    fi
}

# Determine asset type based on filename
# Arguments:
#   $1 - File path
# Returns:
#   Asset type (images, documents, diagrams)
determine_asset_type() {
    local file="${1}"
    local extension
    
    # Get file extension (lowercase)
    extension=$(basename "${file}" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
    
    # Determine type based on extension
    case "${extension}" in
        jpg|jpeg|png|gif|svg|webp)
            echo "images"
            ;;
        pdf|doc|docx|txt|rtf|odt|pages)
            echo "documents"
            ;;
        excalidraw|drawio|vsdx|mmd)
            echo "diagrams"
            ;;
        *)
            # Default to documents
            echo "documents"
            ;;
    esac
}

# Clean a filename for the new structure
# Arguments:
#   $1 - Original filename
# Returns:
#   Cleaned filename (printed to stdout)
clean_filename() {
    local filename="${1}"
    local basename
    
    # Get basename without extension
    basename=$(basename "${filename}")
    local name="${basename%.*}"
    local ext="${basename##*.}"
    
    # Replace underscores with hyphens in name part
    name=$(echo "${name}" | tr '_' '-')
    
    # Return cleaned name with original extension
    echo "${name}.${ext}"
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

# ======================================================================
# Migration functions
# ======================================================================

# Migrate a template file
# Arguments:
#   $1 - Source file path
#   $2 - Default category
# Returns:
#   0 on success, 1 on failure
migrate_template() {
    local source_file="${1}"
    local default_category="${2}"
    local log_prefix="[Template] "
    
    # Skip file patterns
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "${source_file}")" == ${pattern} ]]; then
            log_info "${log_prefix}Skipping file: ${source_file}" "false"
            record_migration "${source_file}" "" "skipped" "Matched skip pattern: ${pattern}"
            return 0
        fi
    done
    
    # Determine actual category - if possible
    local category="${default_category}"
    if [[ "${category}" == "auto" ]]; then
        category=$(determine_template_category "${source_file}")
    fi
    
    # Form target path
    local cleaned_name
    cleaned_name=$(clean_filename "${source_file}")
    local target_file="${VAULT_ROOT}/resources/templates/${category}/${cleaned_name}"
    
    # Create target directory if needed
    mkdir -p "$(dirname "${target_file}")"
    
    # Check if target already exists
    if [[ -f "${target_file}" ]]; then
        log_warning "${log_prefix}Target file already exists: ${target_file}"
        
        # Compare files
        if cmp -s "${source_file}" "${target_file}"; then
            log_info "${log_prefix}Files are identical, skipping: ${source_file}" "false"
            record_migration "${source_file}" "${target_file}" "skipped" "Duplicate file (identical)"
            return 0
        else
            # Create unique name
            local timestamp
            timestamp=$(date +%Y%m%d%H%M%S)
            local name="${cleaned_name%.*}"
            local ext="${cleaned_name##*.}"
            target_file="${VAULT_ROOT}/resources/templates/${category}/${name}_${timestamp}.${ext}"
            log_warning "${log_prefix}Creating unique filename: ${target_file}"
        fi
    fi
    
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

# Migrate a dashboard file
# Arguments:
#   $1 - Source file path
#   $2 - Default category
# Returns:
#   0 on success, 1 on failure
migrate_dashboard() {
    local source_file="${1}"
    local default_category="${2}"
    local log_prefix="[Dashboard] "
    
    # Skip file patterns
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "${source_file}")" == ${pattern} ]]; then
            log_info "${log_prefix}Skipping file: ${source_file}" "false"
            record_migration "${source_file}" "" "skipped" "Matched skip pattern: ${pattern}"
            return 0
        fi
    done
    
    # Determine actual category - if possible
    local category="${default_category}"
    if [[ "${category}" == "auto" ]]; then
        category=$(determine_dashboard_category "${source_file}")
    fi
    
    # Form target path
    local cleaned_name
    cleaned_name=$(clean_filename "${source_file}")
    local target_file="${VAULT_ROOT}/resources/dashboards/${category}/${cleaned_name}"
    
    # Create target directory if needed
    mkdir -p "$(dirname "${target_file}")"
    
    # Check if target already exists
    if [[ -f "${target_file}" ]]; then
        log_warning "${log_prefix}Target file already exists: ${target_file}"
        
        # Compare files
        if cmp -s "${source_file}" "${target_file}"; then
            log_info "${log_prefix}Files are identical, skipping: ${source_file}" "false"
            record_migration "${source_file}" "${target_file}" "skipped" "Duplicate file (identical)"
            return 0
        else
            # Create unique name
            local timestamp
            timestamp=$(date +%Y%m%d%H%M%S)
            local name="${cleaned_name%.*}"
            local ext="${cleaned_name##*.}"
            target_file="${VAULT_ROOT}/resources/dashboards/${category}/${name}_${timestamp}.${ext}"
            log_warning "${log_prefix}Creating unique filename: ${target_file}"
        fi
    fi
    
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

# Migrate a map file
# Arguments:
#   $1 - Source file path
#   $2 - Target directory
# Returns:
#   0 on success, 1 on failure
migrate_map() {
    local source_file="${1}"
    local target_dir="${2}"
    local log_prefix="[Map] "
    
    # Skip file patterns
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "${source_file}")" == ${pattern} ]]; then
            log_info "${log_prefix}Skipping file: ${source_file}" "false"
            record_migration "${source_file}" "" "skipped" "Matched skip pattern: ${pattern}"
            return 0
        fi
    done
    
    # Skip if it's a README file
    if [[ "$(basename "${source_file}")" == "README.md" ]]; then
        log_info "${log_prefix}Skipping README file: ${source_file}" "false"
        record_migration "${source_file}" "" "skipped" "README file"
        return 0
    fi
    
    # Form target path
    local cleaned_name
    cleaned_name=$(clean_filename "${source_file}")
    local target_file="${VAULT_ROOT}/${target_dir}/${cleaned_name}"
    
    # Check if this would conflict with our generated atlas files
    for reserved in "interview-map.md" "research-map.md" "strategy-map.md" "compliance-map.md"; do
        if [[ "$(basename "${target_file}")" == "${reserved}" ]]; then
            # Use a different name to avoid conflict
            local name="${cleaned_name%.*}"
            local ext="${cleaned_name##*.}"
            target_file="${VAULT_ROOT}/${target_dir}/original-${name}.${ext}"
            log_warning "${log_prefix}Renaming to avoid conflict with generated atlas file: ${target_file}"
            break
        fi
    done
    
    # Create target directory if needed
    mkdir -p "$(dirname "${target_file}")"
    
    # Check if target already exists
    if [[ -f "${target_file}" ]]; then
        log_warning "${log_prefix}Target file already exists: ${target_file}"
        
        # Compare files
        if cmp -s "${source_file}" "${target_file}"; then
            log_info "${log_prefix}Files are identical, skipping: ${source_file}" "false"
            record_migration "${source_file}" "${target_file}" "skipped" "Duplicate file (identical)"
            return 0
        else
            # Create unique name
            local timestamp
            timestamp=$(date +%Y%m%d%H%M%S)
            local name="${cleaned_name%.*}"
            local ext="${cleaned_name##*.}"
            target_file="${VAULT_ROOT}/${target_dir}/${name}_${timestamp}.${ext}"
            log_warning "${log_prefix}Creating unique filename: ${target_file}"
        fi
    fi
    
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

# Migrate an asset file
# Arguments:
#   $1 - Source file path
#   $2 - Target base directory
# Returns:
#   0 on success, 1 on failure
migrate_asset() {
    local source_file="${1}"
    local target_base="${2}"
    local log_prefix="[Asset] "
    
    # Skip file patterns
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "${source_file}")" == ${pattern} ]]; then
            log_info "${log_prefix}Skipping file: ${source_file}" "false"
            record_migration "${source_file}" "" "skipped" "Matched skip pattern: ${pattern}"
            return 0
        fi
    done
    
    # Determine asset type
    local asset_type
    asset_type=$(determine_asset_type "${source_file}")
    
    # Form target path
    local cleaned_name
    cleaned_name=$(clean_filename "${source_file}")
    local target_file="${VAULT_ROOT}/${target_base}/${asset_type}/${cleaned_name}"
    
    # Create target directory if needed
    mkdir -p "$(dirname "${target_file}")"
    
    # Check if target already exists
    if [[ -f "${target_file}" ]]; then
        # For assets, we use the file checksum to detect duplicates
        local source_md5
        local target_md5
        source_md5=$(md5sum "${source_file}" | awk '{print $1}')
        target_md5=$(md5sum "${target_file}" | awk '{print $1}')
        
        if [[ "${source_md5}" == "${target_md5}" ]]; then
            log_info "${log_prefix}Files are identical, skipping: ${source_file}" "false"
            record_migration "${source_file}" "${target_file}" "skipped" "Duplicate file (identical)"
            return 0
        else
            # Create unique name
            local timestamp
            timestamp=$(date +%Y%m%d%H%M%S)
            local name="${cleaned_name%.*}"
            local ext="${cleaned_name##*.}"
            target_file="${VAULT_ROOT}/${target_base}/${asset_type}/${name}_${timestamp}.${ext}"
            log_warning "${log_prefix}Creating unique filename: ${target_file}"
        fi
    fi
    
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
    
    # Update migration record
    update_migration_status "${source_file}" "completed"
    
    # Log success
    log_info "${log_prefix}Migration completed: ${source_file}" "false"
    return 0
}

# ======================================================================
# Migration orchestration functions
# ======================================================================

# Process templates from all sources
# Returns:
#   0 on success, non-zero on failure
process_templates() {
    local status=0
    local pids=()
    local current=0
    
    log_info "Processing templates from ${#TEMPLATE_SOURCES[@]} sources..."
    
    for entry in "${TEMPLATE_SOURCES[@]}"; do
        local parts
        IFS=':' read -ra parts <<< "${entry}"
        local source_dir="${parts[0]}"
        local default_category="${parts[1]}"
        
        # Validate source directory exists
        if [[ ! -d "${source_dir}" ]]; then
            log_warning "Template source directory not found: ${source_dir}"
            continue
        fi
        
        log_info "Scanning templates in ${source_dir} (default category: ${default_category})"
        
        # Find all markdown files recursively
        find "${source_dir}" -type f -name "*.md" | while read -r file; do
            # Skip README and index files
            if [[ "$(basename "${file}")" == "README.md" || "$(basename "${file}")" == "_index.md" ]]; then
                continue
            fi
            
            # Migrate in background
            migrate_template "${file}" "${default_category}" &
            pids+=($!)
            ((current++))
            
            # Limit parallel processes
            if [[ ${current} -ge ${MAX_PARALLEL} ]]; then
                # Wait for all processes to complete
                for pid in "${pids[@]}"; do
                    wait "${pid}" || status=1
                done
                # Reset for next batch
                pids=()
                current=0
            fi
        done
    done
    
    # Wait for any remaining processes
    for pid in "${pids[@]}"; do
        wait "${pid}" || status=1
    done
    
    return "${status}"
}

# Process dashboards from all sources
# Returns:
#   0 on success, non-zero on failure
process_dashboards() {
    local status=0
    local pids=()
    local current=0
    
    log_info "Processing dashboards from ${#DASHBOARD_SOURCES[@]} sources..."
    
    for entry in "${DASHBOARD_SOURCES[@]}"; do
        local parts
        IFS=':' read -ra parts <<< "${entry}"
        local source_dir="${parts[0]}"
        local default_category="${parts[1]}"
        
        # Validate source directory exists
        if [[ ! -d "${source_dir}" ]]; then
            log_warning "Dashboard source directory not found: ${source_dir}"
            continue
        fi
        
        log_info "Scanning dashboards in ${source_dir} (default category: ${default_category})"
        
        # Find all markdown files recursively
        find "${source_dir}" -type f -name "*.md" | while read -r file; do
            # Skip README and index files
            if [[ "$(basename "${file}")" == "README.md" || "$(basename "${file}")" == "_index.md" ]]; then
                continue
            fi
            
            # Migrate in background
            migrate_dashboard "${file}" "${default_category}" &
            pids+=($!)
            ((current++))
            
            # Limit parallel processes
            if [[ ${current} -ge ${MAX_PARALLEL} ]]; then
                # Wait for all processes to complete
                for pid in "${pids[@]}"; do
                    wait "${pid}" || status=1
                done
                # Reset for next batch
                pids=()
                current=0
            fi
        done
    done
    
    # Wait for any remaining processes
    for pid in "${pids[@]}"; do
        wait "${pid}" || status=1
    done
    
    return "${status}"
}

# Process maps from all sources
# Returns:
#   0 on success, non-zero on failure
process_maps() {
    local status=0
    local pids=()
    local current=0
    
    log_info "Processing maps from ${#MAP_SOURCES[@]} sources..."
    
    for entry in "${MAP_SOURCES[@]}"; do
        local parts
        IFS=':' read -ra parts <<< "${entry}"
        local source_dir="${parts[0]}"
        local target_dir="${parts[1]}"
        
        # Validate source directory exists
        if [[ ! -d "${source_dir}" ]]; then
            log_warning "Map source directory not found: ${source_dir}"
            continue
        fi
        
        log_info "Scanning maps in ${source_dir} (target directory: ${target_dir})"
        
        # Find all markdown files recursively
        find "${source_dir}" -type f -name "*.md" | while read -r file; do
            # Migrate in background
            migrate_map "${file}" "${target_dir}" &
            pids+=($!)
            ((current++))
            
            # Limit parallel processes
            if [[ ${current} -ge ${MAX_PARALLEL} ]]; then
                # Wait for all processes to complete
                for pid in "${pids[@]}"; do
                    wait "${pid}" || status=1
                done
                # Reset for next batch
                pids=()
                current=0
            fi
        done
    done
    
    # Wait for any remaining processes
    for pid in "${pids[@]}"; do
        wait "${pid}" || status=1
    done
    
    return "${status}"
}

# Process assets from all sources
# Returns:
#   0 on success, non-zero on failure
process_assets() {
    local status=0
    local pids=()
    local current=0
    
    log_info "Processing assets from ${#ASSET_SOURCES[@]} sources..."
    
    for entry in "${ASSET_SOURCES[@]}"; do
        local parts
        IFS=':' read -ra parts <<< "${entry}"
        local source_dir="${parts[0]}"
        local target_dir="${parts[1]}"
        
        # Validate source directory exists
        if [[ ! -d "${source_dir}" ]]; then
            log_warning "Asset source directory not found: ${source_dir}"
            continue
        fi
        
        log_info "Scanning assets in ${source_dir} (target directory: ${target_dir})"
        
        # Find all files recursively (excluding markdown)
        find "${source_dir}" -type f ! -name "*.md" | while read -r file; do
            # Migrate in background
            migrate_asset "${file}" "${target_dir}" &
            pids+=($!)
            ((current++))
            
            # Limit parallel processes
            if [[ ${current} -ge ${MAX_PARALLEL} ]]; then
                # Wait for all processes to complete
                for pid in "${pids[@]}"; do
                    wait "${pid}" || status=1
                done
                # Reset for next batch
                pids=()
                current=0
            fi
        done
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
    init_migration_script "migrate_resources" "Resource Migration"
    
    # Start migration
    log_info "Starting resource migration..."
    
    # Process resources by type
    local status=0
    
    # Migrate templates
    log_info "Migrating templates..."
    process_templates || status=1
    
    # Migrate dashboards
    log_info "Migrating dashboards..."
    process_dashboards || status=1
    
    # Migrate maps
    log_info "Migrating maps..."
    process_maps || status=1
    
    # Migrate assets
    log_info "Migrating assets..."
    process_assets || status=1
    
    # Finalize
    if [[ "${status}" -eq 0 ]]; then
        log_success "Resource migration completed successfully"
        finalize_migration_script 0
        return 0
    else
        log_error "Resource migration completed with errors"
        finalize_migration_script 1
        return 1
    fi
}

# Run main function
main "$@"