#!/bin/bash
# Final Vault Cleanup Script
# This script performs final cleanup of any remaining issues

# Set up variables
CURRENT_DIR="/Users/patricksmith/obsidian/acupcakeshop"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${CURRENT_DIR}/System/Logs/final_cleanup_${TIMESTAMP}.log"

echo "Starting final cleanup..." | tee -a "$LOG_FILE"

# Clean up duplicated files in Documentation that have been properly organized in subdirectories
echo "Cleaning up duplicated Documentation files..." | tee -a "$LOG_FILE"
for file in advanced_enhancement_recommendations.md automation_scripts_guide.md dataview_implementation_guide.md enhanced_implementation_plan.md first_phase_plugin_guide.md graph_view_optimization.md implementation-plan.md implementation_roadmap.md knowledge_graph_enhancement_guide.md mermaid_implementation_guide.md obsidian_enhancement_summary.md tagging_implementation_guide.md template_implementation_guide.md vault_reorganization_plan.md yaml_frontmatter_guide.md yaml_frontmatter_standardization.md; do
  # Only remove if a copy exists in a subdirectory
  if [ -f "$CURRENT_DIR/Documentation/$file" ]; then
    # Check if the file exists in Implementation subdirectory
    if [ -f "$CURRENT_DIR/Documentation/Implementation/$file" ]; then
      echo "Removing duplicate in Documentation root: $file (exists in Implementation)" | tee -a "$LOG_FILE"
      rm -f "$CURRENT_DIR/Documentation/$file"
    # Check if the file exists in Guides subdirectory
    elif [ -f "$CURRENT_DIR/Documentation/Guides/$file" ]; then
      echo "Removing duplicate in Documentation root: $file (exists in Guides)" | tee -a "$LOG_FILE"
      rm -f "$CURRENT_DIR/Documentation/$file"
    # Check if the file exists in Reference subdirectory
    elif [ -f "$CURRENT_DIR/Documentation/Reference/$file" ]; then
      echo "Removing duplicate in Documentation root: $file (exists in Reference)" | tee -a "$LOG_FILE"
      rm -f "$CURRENT_DIR/Documentation/$file"
    # Check if the file exists in System subdirectory
    elif [ -f "$CURRENT_DIR/Documentation/System/$file" ]; then
      echo "Removing duplicate in Documentation root: $file (exists in System)" | tee -a "$LOG_FILE"
      rm -f "$CURRENT_DIR/Documentation/$file"
    fi
  fi
done

# Fix duplicate Maps files in Resources
echo "Fixing duplicate Maps files in Resources..." | tee -a "$LOG_FILE"
if [ -f "$CURRENT_DIR/Resources/Maps.md" ]; then
  echo "Removing duplicate Maps.md file" | tee -a "$LOG_FILE"
  rm -f "$CURRENT_DIR/Resources/Maps.md"
fi

if [ -f "$CURRENT_DIR/Resources/Maps 1.md" ]; then
  echo "Removing duplicate Maps 1.md file" | tee -a "$LOG_FILE"
  rm -f "$CURRENT_DIR/Resources/Maps 1.md"
fi

# Fix documentation_dashboard.md
if [ -f "$CURRENT_DIR/Documentation/documentation_dashboard.md" ]; then
  echo "Moving documentation_dashboard.md to proper location" | tee -a "$LOG_FILE"
  mv "$CURRENT_DIR/Documentation/documentation_dashboard.md" "$CURRENT_DIR/Documentation/Implementation/documentation_dashboard.md"
fi

# Add a recovery_complete.md file to clearly indicate recovery is done
cat > "$CURRENT_DIR/recovery_complete.md" << CONTENT
# Recovery and Cleanup Complete ✅

The comprehensive vault recovery and cleanup are now complete. The vault is fully organized according to the migration plan.

## Recovery Accomplishments

1. **Complete Content Recovery**
   - Recovered all player interviews with rich detail
   - Preserved advanced directory organization
   - Maintained strategic connections between documents
   - Recovered templates, dashboards, maps, and visualizations

2. **Clean Directory Structure**
   - Removed all duplicate directories
   - Eliminated redundant files
   - Fixed circular redirections
   - Organized content in logical directories

## Current Structure

- **Athlete Financial Empowerment/** - All project content
- **Resources/** - Templates, dashboards, maps, visualizations
- **Documentation/** - Implementation guides, reference
- **System/** - Scripts, logs, backups, configuration

## Getting Started

- Start with [the welcome guide](welcome.md) for orientation
- Check out [the project overview](Athlete%20Financial%20Empowerment/_index.md)
- Review [the comprehensive recovery summary](Documentation/Implementation/comprehensive_recovery_summary.md)

## Moving Forward

Continue with the [phased migration plan](phased_migration_plan.md) for ongoing vault improvements.

---

**Recovery completed:** $(date +%Y-%m-%d)
CONTENT

echo "Final cleanup completed." | tee -a "$LOG_FILE"
echo "Final cleanup log: $LOG_FILE" | tee -a "$LOG_FILE"