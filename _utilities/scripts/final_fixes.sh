#!/usr/bin/env bash
# final_fixes.sh - Perform final fixes for the migration
#
# This script addresses the remaining issues identified in the verification report.
#
# Dependencies: bash, cp, mkdir, sed

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/final_fixes_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Final Migration Fixes Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Fix remaining unmigrated files
fix_remaining_unmigrated() {
    echo "Fixing remaining unmigrated files..." | tee -a "$LOG_FILE"
    
    # Create the scripts directory if it doesn't exist
    mkdir -p "${VAULT_ROOT}/resources/scripts"
    
    # Copy the remaining files to their new location
    cp "${VAULT_ROOT}/Resources/scripts/Automation.md" "${VAULT_ROOT}/resources/scripts/automation.md"
    cp "${VAULT_ROOT}/Resources/scripts/Installation.md" "${VAULT_ROOT}/resources/scripts/installation.md"
    cp "${VAULT_ROOT}/Resources/scripts/Maintenance.md" "${VAULT_ROOT}/resources/scripts/maintenance.md"
    cp "${VAULT_ROOT}/Resources/scripts/Readme.md" "${VAULT_ROOT}/resources/scripts/README.md"
    
    # Add proper frontmatter to each file
    for file in "${VAULT_ROOT}/resources/scripts"/*.md; do
        # Get the base name without extension
        base_name=$(basename "$file" .md)
        title=$(echo "$base_name" | tr '-' ' ' | sed 's/\<./\U&/g')
        
        # Create temp file with proper frontmatter
        temp_file="${file}.tmp"
        {
            echo "---"
            echo "title: \"$title\""
            echo "date_created: $(date +%Y-%m-%d)"
            echo "date_modified: $(date +%Y-%m-%d)"
            echo "status: active"
            echo "tags: [scripts, documentation]"
            echo "---"
            echo ""
        } > "$temp_file"
        
        # Add existing content
        cat "$file" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$file"
        
        echo "Fixed frontmatter in $file" | tee -a "$LOG_FILE"
    done
    
    echo "All remaining unmigrated files have been fixed" | tee -a "$LOG_FILE"
}

# Create missing files for broken links
create_missing_files() {
    echo "Creating missing files for broken links..." | tee -a "$LOG_FILE"
    
    # Directories to create
    declare -a dirs=(
        "${VAULT_ROOT}/content/research/competitor-profiles"
        "${VAULT_ROOT}/content/research/industry-analysis"
        "${VAULT_ROOT}/content/strategy/business-model"
        "${VAULT_ROOT}/content/strategy/implementation"
        "${VAULT_ROOT}/content/compliance/registration"
        "${VAULT_ROOT}/content/compliance/advisory-board"
        "${VAULT_ROOT}/content/compliance/standards"
        "${VAULT_ROOT}/content/interviews/players/active/2025/04_april"
        "${VAULT_ROOT}/content/interviews/agents/2025/04_april"
        "${VAULT_ROOT}/content/interviews/industry-professionals/2025/04_april"
    )
    
    # Create directories
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        echo "Created directory: $dir" | tee -a "$LOG_FILE"
    done
    
    # Files to create with placeholder content and appropriate frontmatter
    declare -a files=(
        # Research files
        "${VAULT_ROOT}/content/research/market-analysis/athlete-financial-needs.md:Athlete Financial Needs:research, market-analysis, financial-needs"
        "${VAULT_ROOT}/content/research/market-analysis/service-gaps.md:Service Gaps Analysis:research, market-analysis, service-gaps"
        "${VAULT_ROOT}/content/research/market-analysis/market-size.md:Market Size Analysis:research, market-analysis, market-size"
        "${VAULT_ROOT}/content/research/competitor-profiles/integra-wealth.md:Integra Wealth Management:research, competitor, analysis"
        "${VAULT_ROOT}/content/research/competitor-profiles/athlete-wealth-partners.md:Athlete Wealth Partners:research, competitor, analysis"
        "${VAULT_ROOT}/content/research/competitor-profiles/agent-advisor-models.md:Agent-Advisor Models:research, competitor, analysis"
        "${VAULT_ROOT}/content/research/industry-analysis/fee-structures.md:Fee Structure Comparison:research, industry, fee-structure"
        "${VAULT_ROOT}/content/research/industry-analysis/service-models.md:Service Model Comparison:research, industry, service-models"
        
        # Strategy files
        "${VAULT_ROOT}/content/strategy/mission-statement.md:Mission Statement:strategy, mission, vision"
        "${VAULT_ROOT}/content/strategy/business-model/service-offerings.md:Service Offerings:strategy, business-model, services"
        "${VAULT_ROOT}/content/strategy/business-model/revenue-model.md:Revenue Model:strategy, business-model, revenue"
        "${VAULT_ROOT}/content/strategy/business-model/competitive-positioning.md:Competitive Positioning:strategy, business-model, competition"
        "${VAULT_ROOT}/content/strategy/implementation/phase-one.md:Implementation Phase One:strategy, implementation, phase-one"
        "${VAULT_ROOT}/content/strategy/implementation/phase-two.md:Implementation Phase Two:strategy, implementation, phase-two"
        "${VAULT_ROOT}/content/strategy/implementation/phase-three.md:Implementation Phase Three:strategy, implementation, phase-three"
        
        # Compliance files
        "${VAULT_ROOT}/content/compliance/registration/requirements.md:Registration Requirements:compliance, registration, requirements"
        "${VAULT_ROOT}/content/compliance/registration/application-process.md:Application Process:compliance, registration, application"
        "${VAULT_ROOT}/content/compliance/registration/maintenance-requirements.md:Maintenance Requirements:compliance, registration, maintenance"
        "${VAULT_ROOT}/content/compliance/advisory-board/board-requirements.md:Advisory Board Requirements:compliance, advisory-board, requirements"
        "${VAULT_ROOT}/content/compliance/advisory-board/candidate-research.md:Advisory Board Candidate Research:compliance, advisory-board, candidates"
        "${VAULT_ROOT}/content/compliance/advisory-board/governance-structure.md:Governance Structure:compliance, advisory-board, governance"
        "${VAULT_ROOT}/content/compliance/standards/fiduciary-requirements.md:Fiduciary Requirements:compliance, standards, fiduciary"
        "${VAULT_ROOT}/content/compliance/standards/disclosure-requirements.md:Disclosure Requirements:compliance, standards, disclosure"
        "${VAULT_ROOT}/content/compliance/standards/recordkeeping-requirements.md:Recordkeeping Requirements:compliance, standards, recordkeeping"
        
        # Interview files - players
        "${VAULT_ROOT}/content/interviews/players/active/2025/04_april/jenkins-john-raiders-defensive-tackle.md:John Jenkins - Raiders Defensive Tackle Interview:interview, player, raiders, defensive-tackle"
        "${VAULT_ROOT}/content/interviews/players/active/2025/04_april/johnson-jaylen-bears-safety.md:Jaylen Johnson - Bears Safety Interview:interview, player, bears, safety"
        "${VAULT_ROOT}/content/interviews/players/active/2025/04_april/oconnell-aidan-raiders-quarterback.md:Aidan O'Connell - Raiders Quarterback Interview:interview, player, raiders, quarterback"
        "${VAULT_ROOT}/content/interviews/players/active/2025/04_april/smith-roquan-ravens-linebacker.md:Roquan Smith - Ravens Linebacker Interview:interview, player, ravens, linebacker"
        
        # Interview files - agents & professionals
        "${VAULT_ROOT}/content/interviews/agents/2025/04_april/conner-kevin-universal-agent.md:Kevin Conner - Universal Sports Agent Interview:interview, agent, universal"
        "${VAULT_ROOT}/content/interviews/agents/2025/04_april/lynn-nicole-klutch-agent.md:Nicole Lynn - Klutch Sports Agent Interview:interview, agent, klutch"
        "${VAULT_ROOT}/content/interviews/industry-professionals/2025/04_april/campbell-lamar-financial-advisor.md:Lamar Campbell - Financial Advisor Interview:interview, industry-professional, financial-advisor"
        "${VAULT_ROOT}/content/interviews/industry-professionals/2025/04_april/nelson-daryl-financial-advisor.md:Daryl Nelson - Financial Advisor Interview:interview, industry-professional, financial-advisor"
    )
    
    # Create files with placeholder content
    for entry in "${files[@]}"; do
        IFS=':' read -r file title tags <<< "$entry"
        
        # Create the template file with proper frontmatter
        {
            echo "---"
            echo "title: \"$title\""
            echo "date_created: $(date +%Y-%m-%d)"
            echo "date_modified: $(date +%Y-%m-%d)"
            echo "status: active"
            echo "tags: [$tags]"
            echo "---"
            echo ""
            echo "# $title"
            echo ""
            echo "*This is a placeholder file created during migration to maintain link integrity. Content to be added later.*"
            echo ""
        } > "$file"
        
        echo "Created placeholder file: $file" | tee -a "$LOG_FILE"
    done
    
    echo "Created all missing files for broken links" | tee -a "$LOG_FILE"
}

# Run the fixes
fix_remaining_unmigrated
create_missing_files

# Run the enhanced standardize frontmatter script again
if [[ -x "${VAULT_ROOT}/_utilities/scripts/enhanced_standardize_frontmatter.sh" ]]; then
    echo "Running enhanced frontmatter standardization again..." | tee -a "$LOG_FILE"
    "${VAULT_ROOT}/_utilities/scripts/enhanced_standardize_frontmatter.sh" | tee -a "$LOG_FILE"
fi

# Run the enhanced link fixing script again
if [[ -x "${VAULT_ROOT}/_utilities/scripts/enhanced_fix_links.sh" ]]; then
    echo "Running enhanced link fixing again..." | tee -a "$LOG_FILE"
    "${VAULT_ROOT}/_utilities/scripts/enhanced_fix_links.sh" | tee -a "$LOG_FILE"
fi

# Run the verification script
if [[ -x "${VAULT_ROOT}/_utilities/scripts/verify_migration.sh" ]]; then
    echo "Running verification..." | tee -a "$LOG_FILE"
    "${VAULT_ROOT}/_utilities/scripts/verify_migration.sh" | tee -a "$LOG_FILE"
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Final fixes completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Final fixes completed. See log at: $LOG_FILE"