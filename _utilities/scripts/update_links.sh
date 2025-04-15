#!/usr/bin/env bash
# update_links.sh - Update internal links in markdown files
#
# This script updates internal wiki-style links in markdown files to reflect
# the new file locations after migration. It maintains proper references
# between files while preserving link text.
#
# Dependencies: bash 4+, sed, awk, grep, find

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Types of links to update
# 1. [[filename]] - Simple filename links
# 2. [[filename|display text]] - Links with display text 
# 3. [[path/to/file]] - Path-based links
# 4. [[path/to/file|display text]] - Path links with display text

# Directories to process for link updates
readonly UPDATE_DIRS=(
    "content"
    "resources/templates"
    "resources/dashboards"
    "atlas"
    "docs"
)

# Maximum files to process in parallel
readonly MAX_PARALLEL=4

# ======================================================================
# Link processing functions
# ======================================================================

# Build a mapping of old file paths to new file paths
# Returns:
#   0 on success, 1 on failure
# Creates:
#   ${INVENTORY_DIR}/path_mapping.csv
build_path_mapping() {
    local mapping_file="${INVENTORY_DIR}/path_mapping.csv"
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    
    log_info "Building file path mapping..."
    
    # Create mapping file header
    {
        echo "old_path,new_path,old_filename,new_filename"
    } > "${mapping_file}"
    
    # Extract completed migrations from tracker
    log_info "Extracting paths from migration tracker..."
    awk -F, -v vault="${VAULT_ROOT}/" '
        BEGIN { OFS = "," }
        NR > 1 && $3 == "completed" { 
            # Extract relative paths
            old_rel_path = $1
            new_rel_path = $2
            
            # Remove vault root prefix if present
            gsub(vault, "", old_rel_path)
            gsub(vault, "", new_rel_path)
            
            # Extract filenames
            old_filename = old_rel_path
            new_filename = new_rel_path
            
            # Remove directory part
            sub(".*/", "", old_filename)
            sub(".*/", "", new_filename)
            
            # Output mapping entry
            print old_rel_path, new_rel_path, old_filename, new_filename
        }
    ' "${tracker}" >> "${mapping_file}"
    
    # Count mappings
    local mapping_count
    mapping_count=$(wc -l < "${mapping_file}")
    ((mapping_count--))  # Subtract header line
    
    if [[ "${mapping_count}" -eq 0 ]]; then
        log_error "No path mappings found, cannot update links"
        return 1
    fi
    
    log_success "Created file path mapping with ${mapping_count} entries"
    return 0
}

# Process a file to update its internal links
# Arguments:
#   $1 - File path
# Returns:
#   0 on success, 1 on failure
update_file_links() {
    local file="${1}"
    local mapping_file="${INVENTORY_DIR}/path_mapping.csv"
    local temp_file="${file}.tmp"
    local link_count=0
    local updated_count=0
    
    # Skip the mapping file itself
    if [[ "${file}" == "${mapping_file}" ]]; then
        return 0
    fi
    
    log_info "Processing links in: ${file}" "false"
    
    # Create a temporary copy of the file
    cp "${file}" "${temp_file}"
    
    # Extract all wiki-style links
    local links
    links=$(grep -o '\[\[[^]]*\]\]' "${file}" || echo "")
    
    if [[ -z "${links}" ]]; then
        log_info "No links found in: ${file}" "false"
        rm -f "${temp_file}"
        return 0
    fi
    
    # Count total links
    link_count=$(echo "${links}" | wc -l)
    
    # Process each link
    echo "${links}" | while read -r link; do
        # Extract link target and display text
        local link_target
        local display_text
        local has_display_text=false
        
        # Remove brackets
        link=${link#\[\[}
        link=${link%\]\]}
        
        # Check if link has display text
        if [[ "${link}" == *"|"* ]]; then
            link_target="${link%%|*}"
            display_text="${link#*|}"
            has_display_text=true
        else
            link_target="${link}"
            display_text=""
        fi
        
        # Normalize link path
        local normalized_target="${link_target}"
        
        # Check if target already has .md extension
        if [[ ! "${normalized_target}" == *.md ]]; then
            normalized_target="${normalized_target}.md"
        fi
        
        # Try to find matching mappings
        # 1. First try direct path match
        # 2. Then try filename match
        local found_match=false
        local new_target=""
        
        # Try direct path match first
        awk -F, -v target="${normalized_target}" -v vault="${VAULT_ROOT}/" '
            NR > 1 && ($1 == target || vault $1 == target) { 
                print $2
                exit 0
            }
        ' "${mapping_file}" > "${INVENTORY_DIR}/match.tmp"
        
        if [[ -s "${INVENTORY_DIR}/match.tmp" ]]; then
            new_target=$(cat "${INVENTORY_DIR}/match.tmp")
            found_match=true
        else
            # If no direct path match, try filename match
            local target_filename
            target_filename=$(basename "${normalized_target}")
            
            awk -F, -v filename="${target_filename}" '
                NR > 1 && $3 == filename { 
                    print $2
                    exit 0
                }
            ' "${mapping_file}" > "${INVENTORY_DIR}/match.tmp"
            
            if [[ -s "${INVENTORY_DIR}/match.tmp" ]]; then
                new_target=$(cat "${INVENTORY_DIR}/match.tmp")
                found_match=true
            fi
        fi
        
        rm -f "${INVENTORY_DIR}/match.tmp"
        
        # Update the link if a match was found
        if [[ "${found_match}" == "true" && -n "${new_target}" ]]; then
            # Remove .md extension for cleaner links
            new_target="${new_target%.md}"
            
            # Construct new link syntax
            local new_link
            if [[ "${has_display_text}" == "true" ]]; then
                new_link="[[${new_target}|${display_text}]]"
            else
                # For filename-only links, use the basename
                if [[ "${link_target}" != *"/"* ]]; then
                    local new_basename
                    new_basename=$(basename "${new_target}")
                    new_link="[[${new_target}|${new_basename}]]"
                else
                    new_link="[[${new_target}]]"
                fi
            fi
            
            # Replace the link in the file
            local original_link="\\[\\[${link_target//\//\\/}\\]\\]"
            if [[ "${has_display_text}" == "true" ]]; then
                original_link="\\[\\[${link_target//\//\\/}|${display_text}\\]\\]"
            fi
            
            # Use sed to replace the link
            sed -i.bak "s/${original_link}/${new_link//\//\\/}/g" "${temp_file}"
            rm -f "${temp_file}.bak"
            
            log_info "Updated link: [[${link_target}]] -> ${new_link}" "false"
            ((updated_count++))
        else
            log_warning "No mapping found for link: [[${link_target}]]" "false"
        fi
    done
    
    # Check if any links were updated
    if [[ "${updated_count}" -gt 0 ]]; then
        # Replace the original file with the updated version
        mv "${temp_file}" "${file}"
        log_info "Updated ${updated_count}/${link_count} links in: ${file}" "false"
        return 0
    else
        # No links updated, keep original file
        rm -f "${temp_file}"
        log_info "No links updated in: ${file}" "false"
        return 0
    fi
}

# Update links in all markdown files in the new structure
# Returns:
#   0 on success, 1 on failure
update_all_links() {
    local status=0
    local pids=()
    local current=0
    local total_files=0
    
    # Count total files to process
    for dir in "${UPDATE_DIRS[@]}"; do
        local dir_count
        dir_count=$(find "${VAULT_ROOT}/${dir}" -type f -name "*.md" | wc -l)
        ((total_files += dir_count))
    done
    
    log_info "Updating links in ${total_files} markdown files..."
    
    # Process each directory
    for dir in "${UPDATE_DIRS[@]}"; do
        local dir_path="${VAULT_ROOT}/${dir}"
        
        # Skip if directory doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            log_warning "Directory not found, skipping: ${dir_path}"
            continue
        fi
        
        log_info "Processing files in: ${dir_path}"
        
        # Find all markdown files
        find "${dir_path}" -type f -name "*.md" | while read -r file; do
            # Process file in background
            update_file_links "${file}" &
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
    init_migration_script "update_links" "Internal Link Updating"
    
    # Start link updating
    log_info "Starting link updating process..."
    
    # Build path mapping
    if ! build_path_mapping; then
        log_error "Failed to build path mapping, aborting link update"
        finalize_migration_script 1
        return 1
    fi
    
    # Update all links
    if update_all_links; then
        log_success "Link updating completed successfully"
        finalize_migration_script 0
        return 0
    else
        log_error "Link updating completed with errors"
        finalize_migration_script 1
        return 1
    fi
}

# Run main function
main "$@"