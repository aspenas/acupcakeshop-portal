#!/usr/bin/env bash
# simple_link_repair.sh - Simple but effective link repair
#
# This script handles the most common link issues without complex logic

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/simple_link_repair_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Simple Link Repair Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to scan
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

# Create placeholder directories for common missing targets
mkdir -p "${VAULT_ROOT}/content/interviews/misc"
mkdir -p "${VAULT_ROOT}/content/research/misc"
mkdir -p "${VAULT_ROOT}/content/strategy/misc"
mkdir -p "${VAULT_ROOT}/content/compliance/misc"
mkdir -p "${VAULT_ROOT}/resources/templates/misc"
mkdir -p "${VAULT_ROOT}/resources/dashboards/misc"
mkdir -p "${VAULT_ROOT}/docs/misc"

# Create a few critical placeholder files
echo "Creating placeholder files for common broken links..." | tee -a "$LOG_FILE"

# Create placeholder files - a few important ones
create_placeholder() {
    local path="$1"
    local title="$2"
    
    # Create the file if it doesn't exist
    if [[ ! -f "$path" ]]; then
        mkdir -p "$(dirname "$path")"
        
        # Create a basic file with frontmatter
        cat > "$path" << EOF
---
title: "$title"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: placeholder
tags: [placeholder, migration]
---

# $title

*This is a placeholder file created during migration to resolve broken links. Content needs to be added.*
EOF
        
        echo "Created placeholder: $path" | tee -a "$LOG_FILE"
    fi
}

# Create placeholders for common broken links
create_placeholder "${VAULT_ROOT}/content/research/misc/fee-only-advisory-model.md" "Fee-Only Advisory Model"
create_placeholder "${VAULT_ROOT}/content/research/misc/aum-based-model.md" "AUM-Based Model"
create_placeholder "${VAULT_ROOT}/content/research/misc/hybrid-service-model.md" "Hybrid Service Model"
create_placeholder "${VAULT_ROOT}/content/research/competitor-profiles/integra-wealth.md" "Competitor Analysis: Integra Wealth"
create_placeholder "${VAULT_ROOT}/content/research/competitor-profiles/ubs-mainsail.md" "Competitor Analysis: UBS Mainsail"
create_placeholder "${VAULT_ROOT}/content/research/industry-analysis/service-model-comparison-matrix.md" "Service Model Comparison Matrix"
create_placeholder "${VAULT_ROOT}/content/interviews/players/active/smith-roquan-advisory-preferences.md" "Interview: Roquan Smith - Advisory Preferences"
create_placeholder "${VAULT_ROOT}/content/interviews/players/active/harris-chris-post-career-advisory-needs.md" "Interview: Chris Harris - Post-Career Advisory Needs"
create_placeholder "${VAULT_ROOT}/content/research/misc/athlete-risk-factors.md" "Athlete Risk Factors"
create_placeholder "${VAULT_ROOT}/content/research/misc/risk-assessment-framework.md" "Risk Assessment Framework"
create_placeholder "${VAULT_ROOT}/content/research/misc/career-stage-risk-variables.md" "Career Stage Risk Variables"
create_placeholder "${VAULT_ROOT}/content/research/misc/case-study-nfl-rookie-risk-profile.md" "Case Study: NFL Rookie Risk Profile"
create_placeholder "${VAULT_ROOT}/content/interviews/misc/financial-risk-perceptions.md" "Interview: Financial Risk Perceptions"
create_placeholder "${VAULT_ROOT}/content/interviews/players/active/smith-roquan.md" "Interview: Roquan Smith"
create_placeholder "${VAULT_ROOT}/content/research/misc/trust-framework-in-advisory-relationships.md" "Trust Framework in Advisory Relationships"
create_placeholder "${VAULT_ROOT}/content/research/misc/background-verification-methods.md" "Background Verification Methods"
create_placeholder "${VAULT_ROOT}/content/research/misc/advisor-selection-checklist.md" "Advisor Selection Checklist"
create_placeholder "${VAULT_ROOT}/content/research/misc/red-flags-in-advisory-relationships.md" "Red Flags in Advisory Relationships"

# Create missing docs
create_placeholder "${VAULT_ROOT}/docs/guides/template-guide.md" "Template Guide"
create_placeholder "${VAULT_ROOT}/docs/guides/utilities-guide.md" "Utilities Guide"
create_placeholder "${VAULT_ROOT}/docs/guides/frontmatter-standards.md" "Frontmatter Standards"

# Simpler function to update all wiki links in a file
fix_links_in_file() {
    local file="$1"
    echo "Checking file: $file" | tee -a "$LOG_FILE"
    
    # Skip files that don't exist
    if [[ ! -f "$file" ]]; then
        echo "  File not found, skipping: $file" | tee -a "$LOG_FILE"
        return
    fi
    
    # Use awk to find and display broken links - we won't try to auto-fix
    # Just make a list of what's broken for manual fixing
    grep -o '\[\[[^]]*\]\]' "$file" 2>/dev/null | while read -r link; do
        # Clean link syntax for processing
        clean_link=${link#\[\[}
        clean_link=${clean_link%\]\]}
        
        # Skip links with variables or bash code
        if [[ "$clean_link" == *"{{"* || "$clean_link" == *"}}"* || 
              "$clean_link" == *"${"* || "$clean_link" == *"$(("* || 
              "$clean_link" == *"$("* ]]; then
            continue
        fi
        
        # Handle display text
        target="$clean_link"
        if [[ "$clean_link" == *"|"* ]]; then
            target="${clean_link%%|*}"
        fi
        
        # Skip external links
        if [[ "$target" == "http"* ]]; then
            continue
        fi
        
        # Add .md extension if not present
        if [[ ! "$target" == *.md ]]; then
            target="${target}.md"
        fi
        
        # Determine full target path
        target_path=""
        if [[ "$target" == /* ]]; then
            # Absolute path
            target_path="${VAULT_ROOT}${target}"
        else
            # Relative path
            target_path="$(dirname "$file")/${target}"
        fi
        
        # Check if target exists
        if [[ ! -f "$target_path" ]]; then
            echo "  Broken link in $file: $link -> $target_path" | tee -a "$LOG_FILE"
        fi
    done
}

# Process all files in a directory recursively
process_directory() {
    local dir="$1"
    echo "Processing directory: $dir" | tee -a "$LOG_FILE"
    
    # Find all markdown files
    find "$dir" -type f -name "*.md" | while read -r file; do
        fix_links_in_file "$file"
    done
}

# Process all content directories
echo "Starting link check..." | tee -a "$LOG_FILE"

for dir in "${CONTENT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        process_directory "$dir"
    else
        echo "Directory not found: $dir" | tee -a "$LOG_FILE"
    fi
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Link repair completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Link checking completed. See log at: $LOG_FILE"