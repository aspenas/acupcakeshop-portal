#!/usr/bin/env bash
# generate_reports.sh - Generate migration reports
#
# This script generates comprehensive reports about the migration, including:
# - Migration completion report
# - Migration summary
# - User guide for the new structure
#
# Dependencies: bash 4+, find, wc, grep

# Source the migration library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/migration_lib.sh"

# ======================================================================
# Configuration
# ======================================================================

# Report file paths
readonly COMPLETION_REPORT="${VAULT_ROOT}/docs/migration_completion_report.md"
readonly SUMMARY_REPORT="${VAULT_ROOT}/docs/migration_summary.md"
readonly USER_GUIDE="${VAULT_ROOT}/docs/vault_user_guide.md"

# ======================================================================
# Report generation functions
# ======================================================================

# Generate migration completion report
# Returns:
#   0 on success
generate_completion_report() {
    log_info "Generating migration completion report..."
    
    # Get statistics from migration
    local tracker="${INVENTORY_DIR}/migration_tracker.csv"
    local total_processed=$(grep -c "," "${tracker}" || echo 0)
    ((total_processed--))  # Subtract header line
    
    local completed=$(grep -c ",completed," "${tracker}" || echo 0)
    local skipped=$(grep -c ",skipped," "${tracker}" || echo 0)
    local failed=$(grep -c ",failed," "${tracker}" || echo 0)
    local pending=$(grep -c ",pending," "${tracker}" || echo 0)
    
    # Get counts by directory
    local content_files=$(grep -c ",content/," "${tracker}" || echo 0)
    local template_files=$(grep -c ",resources/templates/," "${tracker}" || echo 0)
    local dashboard_files=$(grep -c ",resources/dashboards/," "${tracker}" || echo 0)
    local atlas_files=$(grep -c ",atlas/," "${tracker}" || echo 0)
    local asset_files=$(grep -c ",resources/assets/," "${tracker}" || echo 0)
    
    # Find backup location
    local backup_file=$(ls -t "${LOGS_DIR}"/backup_location_*.txt 2>/dev/null | head -n1)
    local backup_location=""
    if [[ -f "${backup_file}" ]]; then
        backup_location=$(cat "${backup_file}")
    else
        backup_location="Unknown (backup location file not found)"
    fi
    
    # Generate report
    {
        echo "---"
        echo "title: \"Migration Completion Report\""
        echo "date_created: $(date +%Y-%m-%d)"
        echo "date_modified: $(date +%Y-%m-%d)"
        echo "status: active"
        echo "tags: [migration, report, documentation]"
        echo "---"
        echo ""
        echo "# Migration Completion Report"
        echo ""
        echo "## Overview"
        echo ""
        echo "This report summarizes the vault migration process from the old structure to the new organization pattern. The migration was designed to improve navigation, maintainability, and performance of the vault."
        echo ""
        echo "## Migration Statistics"
        echo ""
        echo "- **Migration Date**: $(date +%Y-%m-%d)"
        echo "- **Total Files Processed**: ${total_processed}"
        echo "- **Successfully Migrated**: ${completed}"
        echo "- **Skipped Files**: ${skipped}"
        echo "- **Failed Migrations**: ${failed}"
        echo "- **Pending Migrations**: ${pending}"
        echo ""
        echo "### File Counts by Category"
        echo ""
        echo "- **Content Files**: ${content_files}"
        echo "- **Template Files**: ${template_files}"
        echo "- **Dashboard Files**: ${dashboard_files}"
        echo "- **Map Files**: ${atlas_files}"
        echo "- **Asset Files**: ${asset_files}"
        echo ""
        echo "## Pre-Migration Backup"
        echo ""
        echo "A comprehensive backup was created before the migration:"
        echo ""
        echo "- **Backup Location**: ${backup_location}"
        echo ""
        echo "## New Directory Structure"
        echo ""
        echo "The vault has been reorganized into the following structure:"
        echo ""
        echo "```"
        echo "/acupcakeshop/"
        echo "├── atlas/                        # Knowledge maps and navigation"
        echo "├── content/                      # Primary knowledge content"
        echo "│   ├── interviews/               # Interview transcripts and analysis"
        echo "│   ├── research/                 # Research and competitor analysis"
        echo "│   ├── strategy/                 # Strategic planning and business model"
        echo "│   └── compliance/               # Regulatory compliance documentation"
        echo "├── resources/                    # Supporting materials"
        echo "│   ├── templates/                # Templates for content creation"
        echo "│   ├── assets/                   # Images, documents, and diagrams"
        echo "│   └── dashboards/               # Performance dashboards"
        echo "├── _utilities/                   # Non-content utility tools"
        echo "│   ├── scripts/                  # Automation scripts"
        echo "│   └── config/                   # Configuration files"
        echo "└── docs/                         # Vault documentation"
        echo "```"
        echo ""
        echo "## Key Improvements"
        echo ""
        echo "1. **Logical Organization**: Content is organized by type and purpose"
        echo "2. **Improved Navigation**: Atlas provides maps of content for easier navigation"
        echo "3. **Consolidated Resources**: Templates and assets are consolidated in a single location"
        echo "4. **Performance Optimization**: Utility files excluded from Obsidian indexing"
        echo "5. **Standardized Metadata**: Consistent frontmatter across all content"
        echo ""
        echo "## Verification Results"
        echo ""
        echo "See the [Migration Verification Report](migration_verification_report.md) for detailed verification results and any issues that need attention."
        echo ""
        echo "## Next Steps"
        echo ""
        echo "1. **Address Verification Issues**: Fix any issues identified in the verification report"
        echo "2. **User Guidance**: Refer to the [Vault User Guide](vault_user_guide.md) for information on using the new structure"
        echo "3. **Obsidian Restart**: Restart Obsidian to ensure it recognizes the new structure"
        echo ""
        echo "---"
        echo ""
        echo "*Report generated: $(date)*"
    } > "${COMPLETION_REPORT}"
    
    log_success "Generated completion report: ${COMPLETION_REPORT}"
    return 0
}

# Generate migration summary
# Returns:
#   0 on success
generate_summary_report() {
    log_info "Generating migration summary report..."
    
    # Get file counts for each category
    local content_count=$(find "${VAULT_ROOT}/content" -type f -name "*.md" | wc -l | tr -d ' ')
    local template_count=$(find "${VAULT_ROOT}/resources/templates" -type f -name "*.md" | wc -l | tr -d ' ')
    local dashboard_count=$(find "${VAULT_ROOT}/resources/dashboards" -type f -name "*.md" | wc -l | tr -d ' ')
    local atlas_count=$(find "${VAULT_ROOT}/atlas" -type f -name "*.md" | wc -l | tr -d ' ')
    local asset_count=$(find "${VAULT_ROOT}/resources/assets" -type f | wc -l | tr -d ' ')
    
    # Generate report
    {
        echo "---"
        echo "title: \"Migration Summary\""
        echo "date_created: $(date +%Y-%m-%d)"
        echo "date_modified: $(date +%Y-%m-%d)"
        echo "status: active"
        echo "tags: [migration, summary, documentation]"
        echo "---"
        echo ""
        echo "# Migration Summary"
        echo ""
        echo "## Overview"
        echo ""
        echo "The vault has been reorganized into a more logical, maintainable structure that separates content from utilities and provides clear navigation pathways."
        echo ""
        echo "## Key Statistics"
        echo ""
        echo "- **Content Files**: ${content_count} markdown files"
        echo "- **Templates**: ${template_count} templates"
        echo "- **Dashboards**: ${dashboard_count} dashboard files"
        echo "- **Maps**: ${atlas_count} map files"
        echo "- **Assets**: ${asset_count} media files"
        echo ""
        echo "## Directory Structure"
        echo ""
        echo "The new vault structure organizes content by type and purpose:"
        echo ""
        echo "- **Atlas**: Knowledge maps for navigating the vault"
        echo "- **Content**: Primary knowledge content organized by type"
        echo "- **Resources**: Templates, assets, and dashboards"
        echo "- **Docs**: Documentation about the vault"
        echo ""
        echo "## Benefits"
        echo ""
        echo "The new structure provides the following benefits:"
        echo ""
        echo "1. **Improved Navigation**: Clear pathways to find content"
        echo "2. **Better Performance**: Utilities excluded from indexing"
        echo "3. **Easier Maintenance**: Logical organization of content"
        echo "4. **Content Clarity**: Separation of content from utilities"
        echo ""
        echo "## Using the New Structure"
        echo ""
        echo "Start with the atlas maps to navigate the vault:"
        echo ""
        echo "- [[/atlas/interview-map|Interview Map]]"
        echo "- [[/atlas/research-map|Research Map]]"
        echo "- [[/atlas/strategy-map|Strategy Map]]"
        echo "- [[/atlas/compliance-map|Compliance Map]]"
        echo ""
        echo "For more detailed information, refer to the [Vault User Guide](vault_user_guide.md)."
        echo ""
        echo "---"
        echo ""
        echo "*Summary generated: $(date)*"
    } > "${SUMMARY_REPORT}"
    
    log_success "Generated summary report: ${SUMMARY_REPORT}"
    return 0
}

# Generate user guide
# Returns:
#   0 on success
generate_user_guide() {
    log_info "Generating vault user guide..."
    
    # Generate guide
    {
        echo "---"
        echo "title: \"Vault User Guide\""
        echo "date_created: $(date +%Y-%m-%d)"
        echo "date_modified: $(date +%Y-%m-%d)"
        echo "status: active"
        echo "tags: [documentation, guide, vault]"
        echo "---"
        echo ""
        echo "# Vault User Guide"
        echo ""
        echo "## Introduction"
        echo ""
        echo "This guide provides information on using the newly reorganized vault structure. It covers navigation, content organization, and best practices for working with the vault."
        echo ""
        echo "## Vault Structure"
        echo ""
        echo "The vault follows a structured organization pattern designed to separate content, resources, and utilities:"
        echo ""
        echo "```"
        echo "/acupcakeshop/"
        echo "├── atlas/                        # Knowledge maps and navigation"
        echo "│   ├── interview-map.md          # Map of all interviews and insights"
        echo "│   ├── research-map.md           # Map of research and analysis"
        echo "│   ├── strategy-map.md           # Strategic planning framework"
        echo "│   └── compliance-map.md         # Regulatory compliance considerations"
        echo "├── content/                      # Primary knowledge content"
        echo "│   ├── interviews/               # Interview transcripts and summaries"
        echo "│   ├── research/                 # Market research and analysis"
        echo "│   ├── strategy/                 # Business planning and strategy"
        echo "│   └── compliance/               # Regulatory requirements documentation"
        echo "├── resources/                    # Supporting materials"
        echo "│   ├── templates/                # Reusable templates"
        echo "│   ├── assets/                   # Images, diagrams, and attachments"
        echo "│   └── dashboards/               # Performance dashboards"
        echo "├── _utilities/                   # Non-content utility tools"
        echo "│   ├── scripts/                  # Automation scripts"
        echo "│   └── config/                   # Configuration files"
        echo "└── docs/                         # Vault documentation"
        echo "```"
        echo ""
        echo "## Navigating the Vault"
        echo ""
        echo "### Starting Points"
        echo ""
        echo "The best way to navigate the vault is through the atlas maps:"
        echo ""
        echo "1. **[[/atlas/interview-map|Interview Map]]**: Provides an overview of all interviews with key insights"
        echo "2. **[[/atlas/research-map|Research Map]]**: Maps out the market research and competitor analysis"
        echo "3. **[[/atlas/strategy-map|Strategy Map]]**: Outlines the strategic planning framework"
        echo "4. **[[/atlas/compliance-map|Compliance Map]]**: Details regulatory compliance considerations"
        echo ""
        echo "### Finding Content"
        echo ""
        echo "Content is organized by type, making it easy to find specific information:"
        echo ""
        echo "- **Interviews**: Located in `content/interviews/`, organized by interviewee type"
        echo "- **Research**: Located in `content/research/`, organized by research type"
        echo "- **Strategy**: Located in `content/strategy/`, organized by strategic area"
        echo "- **Compliance**: Located in `content/compliance/`, organized by regulatory area"
        echo ""
        echo "### Using Resources"
        echo ""
        echo "Resources are organized by type:"
        echo ""
        echo "- **Templates**: Located in `resources/templates/`, organized by use case"
        echo "- **Assets**: Located in `resources/assets/`, organized by media type"
        echo "- **Dashboards**: Located in `resources/dashboards/`, organized by focus area"
        echo ""
        echo "## Creating New Content"
        echo ""
        echo "### Using Templates"
        echo ""
        echo "Templates are available for common content types:"
        echo ""
        echo "1. Navigate to `resources/templates/` to find the appropriate template"
        echo "2. Copy the template to the correct location in the `content/` directory"
        echo "3. Rename the file according to the established naming convention (kebab-case)"
        echo "4. Update the frontmatter with appropriate metadata"
        echo ""
        echo "### Frontmatter Standards"
        echo ""
        echo "All content files should include standardized frontmatter with the following fields:"
        echo ""
        echo "```yaml"
        echo "---"
        echo "title: \"Descriptive Title\""
        echo "date_created: YYYY-MM-DD"
        echo "date_modified: YYYY-MM-DD"
        echo "status: draft|active|archived"
        echo "tags: [tag1, tag2, tag3]"
        echo "---"
        echo "```"
        echo ""
        echo "### Status Values"
        echo ""
        echo "Use the following status values to indicate the state of content:"
        echo ""
        echo "- `draft`: Content that is in progress"
        echo "- `active`: Current, approved content"
        echo "- `archived`: Outdated or superseded content"
        echo ""
        echo "## Best Practices"
        echo ""
        echo "### Naming Conventions"
        echo ""
        echo "- Use kebab-case for all filenames (e.g., `player-interview.md`)"
        echo "- Use descriptive names that reflect content"
        echo "- Include relevant prefixes or suffixes for special file types"
        echo ""
        echo "### Cross-Linking"
        echo ""
        echo "- Use wiki-style links to cross-reference related content"
        echo "- Include link text for clarity: `[[file-name|Descriptive Text]]`"
        echo "- Use the atlas maps as central navigation hubs"
        echo ""
        echo "### Performance Considerations"
        echo ""
        echo "- The `.obsidian-ignore` file excludes utility directories from indexing"
        echo "- Store images and attachments in `resources/assets/`"
        echo "- Split very large documents into smaller, linked files"
        echo ""
        echo "## Troubleshooting"
        echo ""
        echo "### Broken Links"
        echo ""
        echo "If you encounter broken links:"
        echo ""
        echo "1. Check the [Migration Verification Report](migration_verification_report.md) for known issues"
        echo "2. Update the link to point to the correct location in the new structure"
        echo "3. Report persistent issues for further investigation"
        echo ""
        echo "### Missing Content"
        echo ""
        echo "If you cannot find content that you know should exist:"
        echo ""
        echo "1. Check the atlas maps for navigation to the content"
        echo "2. Search for the content by title or keywords"
        echo "3. Check the original backup if necessary: ${backup_location}"
        echo ""
        echo "## Getting Help"
        echo ""
        echo "For additional help with the vault:"
        echo ""
        echo "1. Refer to the [Migration Completion Report](migration_completion_report.md) for background on the reorganization"
        echo "2. Check the [Migration Verification Report](migration_verification_report.md) for known issues"
        echo "3. Contact the vault administrator for further assistance"
        echo ""
        echo "---"
        echo ""
        echo "*Guide generated: $(date)*"
    } > "${USER_GUIDE}"
    
    log_success "Generated user guide: ${USER_GUIDE}"
    return 0
}

# ======================================================================
# Main function
# ======================================================================

main() {
    # Initialize
    init_migration_script "generate_reports" "Report Generation"
    
    # Start report generation
    log_info "Starting report generation..."
    
    # Generate reports
    local status=0
    
    # Generate completion report
    if ! generate_completion_report; then
        log_error "Failed to generate completion report"
        status=1
    fi
    
    # Generate summary report
    if ! generate_summary_report; then
        log_error "Failed to generate summary report"
        status=1
    fi
    
    # Generate user guide
    if ! generate_user_guide; then
        log_error "Failed to generate user guide"
        status=1
    fi
    
    # Finalize
    if [[ "${status}" -eq 0 ]]; then
        log_success "Report generation completed successfully"
        finalize_migration_script 0
        return 0
    else
        log_error "Report generation completed with errors"
        finalize_migration_script 1
        return 1
    fi
}

# Run main function
main "$@"