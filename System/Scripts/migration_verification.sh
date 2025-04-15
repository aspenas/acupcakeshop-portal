#!/bin/bash
# Migration Verification Script
# This script verifies the vault reorganization was successful and generates a report
# Created: 2025-04-09

# Set the vault root directory
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
REPORT_FILE="${VAULT_ROOT}/System/verification_report_$(date +%Y%m%d_%H%M%S).md"

# Function to check if a directory exists and count files
check_directory() {
  local dir="$1"
  if [ -d "$dir" ]; then
    local file_count=$(find "$dir" -type f | wc -l)
    echo "✅ Directory exists: $dir (contains $file_count files)"
  else
    echo "❌ Directory missing: $dir"
  fi
}

# Function to check if specified files exist in a directory
check_files_in_directory() {
  local dir="$1"
  shift
  local all_found=true
  
  for file in "$@"; do
    if [ -f "${dir}/${file}" ]; then
      echo "✅ File exists: ${dir}/${file}"
    else
      echo "❌ File missing: ${dir}/${file}"
      all_found=false
    fi
  done
  
  if $all_found; then
    echo "✅ All expected files found in $dir"
  else
    echo "⚠️ Some expected files missing from $dir"
  fi
}

# Generate report header
cat > "$REPORT_FILE" << EOF
# Vault Migration Verification Report

Generated: $(date)

This report verifies that the vault reorganization was completed successfully.

## Directory Structure Verification

EOF

# Check main directories
echo -e "\n--- Checking Main Directories ---" | tee -a "$REPORT_FILE"
for dir in "System" "Resources" "Documentation" "System/Scripts" "System/Backups" "Resources/Templates" "Resources/Dashboards" "Resources/Maps" "Resources/Visualizations" "Resources/Attachments" "Documentation/Implementation" "Documentation/Guides" "Documentation/Reference" "Documentation/System"; do
  check_directory "${VAULT_ROOT}/${dir}" | tee -a "$REPORT_FILE"
done

# Check script directories
echo -e "\n--- Checking Script Directories ---" | tee -a "$REPORT_FILE"
for dir in "System/Scripts/Automation" "System/Scripts/Maintenance" "System/Scripts/Installation"; do
  check_directory "${VAULT_ROOT}/${dir}" | tee -a "$REPORT_FILE"
done

# Check template directories
echo -e "\n--- Checking Template Directories ---" | tee -a "$REPORT_FILE"
for dir in "Resources/Templates/Client" "Resources/Templates/Analysis" "Resources/Templates/Project" "Resources/Templates/System" "Resources/Templates/Interview" "Resources/Templates/Task"; do
  check_directory "${VAULT_ROOT}/${dir}" | tee -a "$REPORT_FILE"
done

# Generate the key files section
cat >> "$REPORT_FILE" << EOF

## Key Files Verification

EOF

# Check key script files
echo -e "\n--- Checking Key Script Files ---" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/System/Scripts/Maintenance" "batch_standardize_yaml.sh" "standardize_yaml.sh" "yaml_standardization.sh" "tag_audit.sh" "standardize_km_files.sh" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/System/Scripts/Installation" "install_recommended_plugins.sh" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/System/Scripts/Automation" "obsidian_automation.sh" "create_interview.sh" | tee -a "$REPORT_FILE"

# Check key documentation files
echo -e "\n--- Checking Key Documentation Files ---" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/Documentation/Implementation" "implementation_status.md" "enhancement_summary.md" "deployment_package.md" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/Documentation/Guides" "plugin_installation_guide.md" "graph_view_optimization.md" "first_phase_plugin_guide.md" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/Documentation/Reference" "tag_system.md" "yaml_frontmatter_guide.md" | tee -a "$REPORT_FILE"

# Check migration artifacts
echo -e "\n--- Checking Migration Artifacts ---" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/Documentation/Implementation" "migration_report.md" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/System" "index.md" | tee -a "$REPORT_FILE"
check_files_in_directory "${VAULT_ROOT}/Resources" "index.md" | tee -a "$REPORT_FILE"

# Count files in each directory
echo -e "\n--- File Count by Directory ---" | tee -a "$REPORT_FILE"
echo "System Files: $(find "${VAULT_ROOT}/System" -type f | wc -l)" | tee -a "$REPORT_FILE"
echo "Resource Files: $(find "${VAULT_ROOT}/Resources" -type f | wc -l)" | tee -a "$REPORT_FILE"
echo "Documentation Files: $(find "${VAULT_ROOT}/Documentation" -type f | wc -l)" | tee -a "$REPORT_FILE"
echo "Total Files: $(find "${VAULT_ROOT}" -type f -not -path "*/\.*" -not -path "*/System/Backups/*" | wc -l)" | tee -a "$REPORT_FILE"

# Check for redirection files
echo -e "\n--- Checking Redirection Files ---" | tee -a "$REPORT_FILE"
redirect_count=$(grep -r "This file has been moved" "${VAULT_ROOT}" --include="*.md" | wc -l)
echo "Redirection Files: $redirect_count" | tee -a "$REPORT_FILE"

# Recommend next steps
cat >> "$REPORT_FILE" << EOF

## Recommendations

Based on the verification results, the following actions are recommended:

1. **Link Verification**: Use the update_links.sh script to ensure all internal links are updated
2. **Broken Link Check**: Check for broken links using Obsidian's built-in check
3. **Index Updates**: Update index files with links to the new file locations
4. **Documentation Update**: Update any documentation referencing the old file structure
5. **Cleanup**: After confirming everything works (~2 weeks), remove redirection files

## Conclusion

The vault reorganization appears to be $(if [ -d "${VAULT_ROOT}/System" ] && [ -d "${VAULT_ROOT}/Resources" ] && [ -d "${VAULT_ROOT}/Documentation" ]; then echo "successful"; else echo "incomplete"; fi). Follow the recommendations above to complete the migration process.

---

Report generated: $(date)
EOF

echo -e "\n--- Verification Complete ---"
echo "Verification report created at: $REPORT_FILE"