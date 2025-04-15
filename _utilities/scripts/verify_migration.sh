#!/usr/bin/env bash
# verify_migration.sh - Verify migration completeness and integrity
#
# This script performs comprehensive verification of the migration, including:
# - Checking for unmigrated content
# - Identifying broken links
# - Validating frontmatter standardization
# - Generating a detailed verification report
#
# Dependencies: bash 4+, grep, find, awk

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Directories to verify
readonly VERIFY_DIRS=(
    "content"
    "resources"
    "atlas"
    "docs"
)

# Required frontmatter fields
readonly REQUIRED_FRONTMATTER=(
    "title"
    "date_created"
    "date_modified"
    "status"
    "tags"
)

# Directories to exclude from frontmatter verification
readonly FRONTMATTER_EXCLUDE=(
    "resources/assets"
)

# ======================================================================
# Verification functions
# ======================================================================

# Check for unmigrated content files
# Returns:
#   0 if all content migrated, 1 if unmigrated content found
check_unmigrated_content() {
    local unmigrated_file="${INVENTORY_DIR}/unmigrated_files.txt"
    local status=0
    
    log_info "Checking for unmigrated content..."
    
    # Create inventory of all original markdown files
    log_info "Creating inventory of original markdown files..."
    find "${VAULT_ROOT}" -type f -name "*.md" \
        ! -path "${VAULT_ROOT}/_utilities/*" \
        ! -path "${VAULT_ROOT}/content/*" \
        ! -path "${VAULT_ROOT}/resources/*" \
        ! -path "${VAULT_ROOT}/atlas/*" \
        ! -path "${VAULT_ROOT}/docs/*" \
        ! -path "${VAULT_ROOT}/System/Backups/*" \
        ! -path "${VAULT_ROOT}/backup_*/*" \
        > "${INVENTORY_DIR}/original_files.txt"
    
    # Get count of original files
    local original_count
    original_count=$(wc -l < "${INVENTORY_DIR}/original_files.txt" | tr -d ' ')
    log_info "Found ${original_count} original markdown files"
    
    # Get list of all migrated files from the tracker
    grep -v "^source_path" "${INVENTORY_DIR}/migration_tracker.csv" | cut -d ',' -f 1 > "${INVENTORY_DIR}/migrated_sources.txt"
    
    # Count migrated files
    local migrated_count
    migrated_count=$(wc -l < "${INVENTORY_DIR}/migrated_sources.txt" | tr -d ' ')
    log_info "Found ${migrated_count} migrated source files"
    
    # Find unmigrated files
    if ! comm -23 <(sort "${INVENTORY_DIR}/original_files.txt") <(sort "${INVENTORY_DIR}/migrated_sources.txt") > "${unmigrated_file}"; then
        # Fallback if comm fails
        grep -v -f "${INVENTORY_DIR}/migrated_sources.txt" "${INVENTORY_DIR}/original_files.txt" > "${unmigrated_file}" || true
    fi
    
    # Count unmigrated files
    local unmigrated_count
    unmigrated_count=$(wc -l < "${unmigrated_file}" | tr -d ' ')
    
    if [[ "${unmigrated_count}" -gt 0 ]]; then
        log_warning "Found ${unmigrated_count} unmigrated files"
        status=1
    else
        log_success "All content files have been migrated"
    fi
    
    return "${status}"
}

# Check for broken links in migrated content
# Returns:
#   0 if no broken links, 1 if broken links found
check_broken_links() {
    local broken_links_file="${INVENTORY_DIR}/broken_links.txt"
    local status=0
    
    log_info "Checking for broken links in migrated content..."
    
    # Clear broken links file
    > "${broken_links_file}"
    
    # Process each directory to check
    for dir in "${VERIFY_DIRS[@]}"; do
        local dir_path="${VAULT_ROOT}/${dir}"
        
        # Skip if directory doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            log_warning "Directory not found, skipping: ${dir_path}"
            continue
        fi
        
        log_info "Checking links in: ${dir_path}" "false"
        
        # Find all markdown files
        find "${dir_path}" -type f -name "*.md" | while read -r file; do
            # Extract all wiki-style links
            grep -o '\[\[[^]]*\]\]' "${file}" | while read -r link; do
                # Clean link syntax
                link=${link#\[\[}
                link=${link%\]\]}
                
                # Handle display text
                if [[ "${link}" == *"|"* ]]; then
                    link=${link%%|*}
                fi
                
                # Skip external links
                if [[ "${link}" == "http"* ]]; then
                    continue
                fi
                
                # Add .md extension if not present
                if [[ ! "${link}" == *.md ]]; then
                    link="${link}.md"
                fi
                
                # Determine target path
                local target_path
                if [[ "${link}" == /* ]]; then
                    # Absolute path
                    target_path="${VAULT_ROOT}${link}"
                else
                    # Relative path
                    target_path="$(dirname "${file}")/${link}"
                fi
                
                # Check if target file exists
                if [[ ! -f "${target_path}" ]]; then
                    echo "${file}:${link}" >> "${broken_links_file}"
                fi
            done
        done
    done
    
    # Count broken links
    local broken_count
    broken_count=$(wc -l < "${broken_links_file}" | tr -d ' ')
    
    if [[ "${broken_count}" -gt 0 ]]; then
        log_warning "Found ${broken_count} broken links"
        status=1
    else
        log_success "No broken links found"
    fi
    
    return "${status}"
}

# Check for frontmatter standardization
# Returns:
#   0 if all frontmatter is standardized, 1 if issues found
check_frontmatter() {
    local frontmatter_issues="${INVENTORY_DIR}/frontmatter_issues.txt"
    local status=0
    
    log_info "Checking frontmatter standardization..."
    
    # Clear issues file
    > "${frontmatter_issues}"
    
    # Process each directory to check
    for dir in "${VERIFY_DIRS[@]}"; do
        local dir_path="${VAULT_ROOT}/${dir}"
        
        # Skip if directory doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            log_warning "Directory not found, skipping: ${dir_path}"
            continue
        fi
        
        # Skip excluded directories
        local skip=false
        for excluded in "${FRONTMATTER_EXCLUDE[@]}"; do
            if [[ "${dir}" == "${excluded}"* ]]; then
                log_info "Skipping excluded directory: ${dir_path}" "false"
                skip=true
                break
            fi
        done
        
        [[ "${skip}" == "true" ]] && continue
        
        log_info "Checking frontmatter in: ${dir_path}" "false"
        
        # Find all markdown files
        find "${dir_path}" -type f -name "*.md" | while read -r file; do
            local file_issues=0
            
            # Check if file has frontmatter
            if ! grep -q "^---" "${file}"; then
                echo "${file}:Missing frontmatter completely" >> "${frontmatter_issues}"
                ((file_issues++))
                continue
            fi
            
            # Check for required fields
            for field in "${REQUIRED_FRONTMATTER[@]}"; do
                if ! grep -q "^${field}:" "${file}"; then
                    echo "${file}:Missing required field: ${field}" >> "${frontmatter_issues}"
                    ((file_issues++))
                fi
            done
            
            # Check for standardized date fields
            if grep -q "^created:" "${file}" && ! grep -q "^date_created:" "${file}"; then
                echo "${file}:Non-standardized date field: created (should be date_created)" >> "${frontmatter_issues}"
                ((file_issues++))
            fi
            
            if grep -q "^modified:" "${file}" && ! grep -q "^date_modified:" "${file}"; then
                echo "${file}:Non-standardized date field: modified (should be date_modified)" >> "${frontmatter_issues}"
                ((file_issues++))
            fi
            
            # Additional check for malformed tags
            if grep -q "^tags:" "${file}"; then
                # Check if tags are in proper format
                local tags_line
                tags_line=$(grep "^tags:" "${file}")
                
                if [[ ! "${tags_line}" =~ [,\[\]] ]]; then
                    echo "${file}:Possibly malformed tags: ${tags_line}" >> "${frontmatter_issues}"
                    ((file_issues++))
                fi
            fi
            
            # Log file issues
            if [[ "${file_issues}" -gt 0 ]]; then
                log_warning "Found ${file_issues} frontmatter issues in: ${file}" "false"
            fi
        done
    done
    
    # Count frontmatter issues
    local issues_count
    issues_count=$(wc -l < "${frontmatter_issues}" | tr -d ' ')
    
    if [[ "${issues_count}" -gt 0 ]]; then
        log_warning "Found ${issues_count} frontmatter issues"
        status=1
    else
        log_success "All frontmatter is properly standardized"
    fi
    
    return "${status}"
}

# Generate verification report
# Arguments:
#   $1 - Unmigrated status (0 or 1)
#   $2 - Broken links status (0 or 1)
#   $3 - Frontmatter status (0 or 1)
# Returns:
#   0 on success
generate_verification_report() {
    local unmigrated_status="${1}"
    local links_status="${2}"
    local frontmatter_status="${3}"
    local report_file="${VAULT_ROOT}/docs/migration_verification_report.md"
    local overall_status="success"
    
    # Determine overall status
    if [[ "${unmigrated_status}" -eq 1 || "${links_status}" -eq 1 || "${frontmatter_status}" -eq 1 ]]; then
        overall_status="issues"
    fi
    
    log_info "Generating verification report..."
    
    # Get counts
    local unmigrated_count=$(wc -l < "${INVENTORY_DIR}/unmigrated_files.txt" | tr -d ' ')
    local broken_count=$(wc -l < "${INVENTORY_DIR}/broken_links.txt" | tr -d ' ')
    local issues_count=$(wc -l < "${INVENTORY_DIR}/frontmatter_issues.txt" | tr -d ' ')
    
    # Generate markdown report
    {
        echo "---"
        echo "title: \"Migration Verification Report\""
        echo "date_created: $(date +%Y-%m-%d)"
        echo "date_modified: $(date +%Y-%m-%d)"
        echo "status: active"
        echo "tags: [migration, verification, report]"
        echo "---"
        echo ""
        echo "# Migration Verification Report"
        echo ""
        echo "## Overview"
        echo ""
        echo "This report provides verification results for the vault migration process. It identifies any issues that need to be addressed to ensure a complete and correct migration."
        echo ""
        echo "## Verification Summary"
        echo ""
        echo "- **Overall Status**: ${overall_status^^}"
        echo "- **Unmigrated Content**: ${unmigrated_count} files"
        echo "- **Broken Links**: ${broken_count} links"
        echo "- **Frontmatter Issues**: ${issues_count} issues"
        echo ""
        echo "## Detailed Findings"
        echo ""
        
        # Unmigrated content section
        echo "### Unmigrated Content"
        echo ""
        if [[ "${unmigrated_count}" -gt 0 ]]; then
            echo "The following files have not been migrated from the original structure:"
            echo ""
            echo "```"
            if [[ "${unmigrated_count}" -gt 20 ]]; then
                head -n 20 "${INVENTORY_DIR}/unmigrated_files.txt"
                echo "... and $((unmigrated_count - 20)) more files"
            else
                cat "${INVENTORY_DIR}/unmigrated_files.txt"
            fi
            echo "```"
        else
            echo "All content has been successfully migrated."
        fi
        echo ""
        
        # Broken links section
        echo "### Broken Links"
        echo ""
        if [[ "${broken_count}" -gt 0 ]]; then
            echo "The following broken links were detected in the migrated content:"
            echo ""
            echo "```"
            if [[ "${broken_count}" -gt 20 ]]; then
                head -n 20 "${INVENTORY_DIR}/broken_links.txt"
                echo "... and $((broken_count - 20)) more broken links"
            else
                cat "${INVENTORY_DIR}/broken_links.txt"
            fi
            echo "```"
        else
            echo "No broken links were detected."
        fi
        echo ""
        
        # Frontmatter issues section
        echo "### Frontmatter Issues"
        echo ""
        if [[ "${issues_count}" -gt 0 ]]; then
            echo "The following files have issues with their frontmatter:"
            echo ""
            echo "```"
            if [[ "${issues_count}" -gt 20 ]]; then
                head -n 20 "${INVENTORY_DIR}/frontmatter_issues.txt"
                echo "... and $((issues_count - 20)) more issues"
            else
                cat "${INVENTORY_DIR}/frontmatter_issues.txt"
            fi
            echo "```"
        else
            echo "All files have standardized frontmatter."
        fi
        echo ""
        
        # Recommendations section
        echo "## Recommendations"
        echo ""
        if [[ "${overall_status}" == "issues" ]]; then
            echo "The following actions are recommended to address the issues found:"
            echo ""
            
            if [[ "${unmigrated_status}" -eq 1 ]]; then
                echo "1. **Migrate Remaining Content**: Review the list of unmigrated files and migrate them to the new structure."
                echo "   - Use the migration scripts to migrate the remaining content"
                echo "   - Alternative: Manually copy important files to their appropriate locations"
                echo ""
            fi
            
            if [[ "${links_status}" -eq 1 ]]; then
                echo "2. **Fix Broken Links**: Update the links to point to the correct files in the new structure."
                echo "   - Run the link update script again with updated path mappings"
                echo "   - Manually update links that couldn't be automatically fixed"
                echo ""
            fi
            
            if [[ "${frontmatter_status}" -eq 1 ]]; then
                echo "3. **Standardize Frontmatter**: Add missing frontmatter fields to the identified files."
                echo "   - Run a frontmatter standardization script"
                echo "   - Manually update files with complex frontmatter issues"
                echo ""
            fi
        else
            echo "The migration has been completed successfully with no issues detected. No further action is required."
        fi
        
        # Verification process section
        echo "## Verification Process"
        echo ""
        echo "This report was generated automatically by the \`verify_migration.sh\` script on $(date). The script performed the following checks:"
        echo ""
        echo "1. Identified unmigrated content by comparing original files with the migration tracker"
        echo "2. Searched for broken wiki-style links in all markdown files in the new structure"
        echo "3. Verified standardized frontmatter in all content files"
        echo ""
        
        # Next steps section
        echo "## Next Steps"
        echo ""
        if [[ "${overall_status}" == "issues" ]]; then
            echo "After addressing the issues identified in this report, re-run the verification script to confirm all issues have been resolved:"
            echo ""
            echo "```bash"
            echo "_utilities/scripts/verify_migration.sh"
            echo "```"
        else
            echo "The migration is complete and verified. Users can now fully transition to using the new vault structure."
        fi
        echo ""
        echo "---"
        echo ""
        echo "*Report generated: $(date)*"
    } > "${report_file}"
    
    log_success "Verification report generated: ${report_file}"
    return 0
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "verify_migration" "Migration Verification"
    
    # Start verification
    log_info "Starting migration verification..."
    
    # Run verification checks
    local unmigrated_status=0
    local links_status=0
    local frontmatter_status=0
    
    # Check for unmigrated content
    if ! check_unmigrated_content; then
        unmigrated_status=1
    fi
    
    # Check for broken links
    if ! check_broken_links; then
        links_status=1
    fi
    
    # Check frontmatter standardization
    if ! check_frontmatter; then
        frontmatter_status=1
    fi
    
    # Generate verification report
    generate_verification_report "${unmigrated_status}" "${links_status}" "${frontmatter_status}"
    
    # Determine overall status
    local overall_status=0
    if [[ "${unmigrated_status}" -eq 1 || "${links_status}" -eq 1 || "${frontmatter_status}" -eq 1 ]]; then
        overall_status=1
        log_warning "Verification completed with issues"
    else
        log_success "Verification completed successfully - no issues found"
    fi
    
    # Finalize
    finalize_migration_script "${overall_status}"
    return "${overall_status}"
}

# Run main function
main "$@"