#!/usr/bin/env bash
# enhanced_fix_links.sh - Enhanced link repair for Obsidian vault
#
# This script provides a more comprehensive fix for broken links in migrated content.
# It handles multiple link formats, special paths, and integrates content maps.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
BROKEN_LINKS="${INVENTORY_DIR}/broken_links.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/enhanced_fix_links_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Enhanced Link Repair Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to scan for links
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

# Create a complete path mapping from original paths to new paths
# This is done by reading the migration tracker database
generate_path_mapping() {
    local tracker_file="${INVENTORY_DIR}/migration_tracker.csv"
    local mapping_file="${INVENTORY_DIR}/path_mapping.txt"
    
    echo "Generating complete path mapping..." | tee -a "$LOG_FILE"
    
    # Check if migration tracker exists
    if [[ ! -f "$tracker_file" ]]; then
        echo "Migration tracker not found: $tracker_file" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # Create mapping file
    > "$mapping_file"
    
    # Skip header line, then process each line in the tracker
    tail -n +2 "$tracker_file" | while IFS=, read -r source_path target_path rest; do
        # Extract just the path relative to the vault root
        local rel_source=${source_path#$VAULT_ROOT}
        local rel_target=${target_path#$VAULT_ROOT}
        
        # Add to mapping file
        echo "$rel_source|$rel_target" >> "$mapping_file"
    done
    
    echo "Generated path mapping with $(wc -l < "$mapping_file") entries" | tee -a "$LOG_FILE"
    return 0
}

# Add manual mapping entries for common paths
add_manual_mappings() {
    local mapping_file="${INVENTORY_DIR}/path_mapping.txt"
    
    echo "Adding manual path mappings..." | tee -a "$LOG_FILE"
    
    # Map of common source paths to new paths
    declare -A PATH_MAPPING
    PATH_MAPPING["/Athlete Financial Empowerment/"]="/content/"
    PATH_MAPPING["/Athlete Financial Empowerment/02-interviews/"]="/content/interviews/"
    PATH_MAPPING["/Athlete Financial Empowerment/04-analysis/"]="/content/research/"
    PATH_MAPPING["/Athlete Financial Empowerment/03-strategy/"]="/content/strategy/"
    PATH_MAPPING["/Athlete Financial Empowerment/05-compliance/"]="/content/compliance/"
    PATH_MAPPING["/Athlete Financial Empowerment/00-project-overview/"]="/content/strategy/"
    PATH_MAPPING["/Athlete Financial Empowerment/01-market-research/"]="/content/research/"
    PATH_MAPPING["/Athlete Financial Empowerment/06-planning/"]="/content/strategy/planning/"
    PATH_MAPPING["/Athlete Financial Empowerment/07-team/"]="/content/strategy/team/"
    PATH_MAPPING["/Dashboards/"]="/resources/dashboards/"
    PATH_MAPPING["/Resources/Dashboards/"]="/resources/dashboards/"
    PATH_MAPPING["/Maps/"]="/atlas/"
    PATH_MAPPING["/Resources/Maps/"]="/atlas/"
    PATH_MAPPING["/Resources/Templates/"]="/resources/templates/"
    PATH_MAPPING["/Templates/"]="/resources/templates/"
    PATH_MAPPING["/_templates/"]="/resources/templates/"
    PATH_MAPPING["/Documentation/"]="/docs/"
    PATH_MAPPING["/System/"]="/docs/system/"
    
    # Add manual content map entries
    # Format: "original_file.md|new_file.md"
    local manual_entries=(
        "/Athlete Financial Empowerment/01-market-research/key-insights.md|/content/research/key-insights.md"
        "/Athlete Financial Empowerment/02-interviews/players/roquan-smith.md|/content/interviews/players/smith-roquan-ravens.md"
        "/maps/map-athlete-interviews.md|/atlas/interview-map.md"
        "/maps/map-competitor-landscape.md|/atlas/research-map.md"
        "/maps/map-service-models.md|/atlas/strategy-map.md"
        "/maps/map-strategic-planning.md|/atlas/strategy-map.md"
        "/Dashboards/competitor-analysis.md|/resources/dashboards/competitor-analysis.md"
        "/Dashboards/project-progress.md|/resources/dashboards/project-progress.md"
    )
    
    # Add directory mappings
    for src_path in "${!PATH_MAPPING[@]}"; do
        echo "${src_path}|${PATH_MAPPING[$src_path]}" >> "$mapping_file"
    done
    
    # Add manual content mappings
    for entry in "${manual_entries[@]}"; do
        echo "$entry" >> "$mapping_file"
    done
    
    # Add special mappings for the atlas maps
    echo "Adding special mappings for atlas content..." | tee -a "$LOG_FILE"
    
    # Interview map entries
    # Format: "Old path|New path"
    local interview_entries=(
        "/content/interviews/players/john-jenkins-raiders-defensive-tackle.md|/content/interviews/players/active/2025/04_april/jenkins-john-raiders-defensive-tackle.md"
        "/content/interviews/players/jaylen-johnson-bears-safety.md|/content/interviews/players/active/2025/04_april/johnson-jaylen-bears-safety.md"
        "/content/interviews/players/aidan-oconnell-raiders-quarterback.md|/content/interviews/players/active/2025/04_april/oconnell-aidan-raiders-quarterback.md"
        "/content/interviews/players/roquan-smith-ravens-linebacker.md|/content/interviews/players/active/2025/04_april/smith-roquan-ravens-linebacker.md"
        "/content/interviews/agents/kevin-conner.md|/content/interviews/agents/2025/04_april/conner-kevin-universal-agent.md"
        "/content/interviews/agents/nicole-lynn.md|/content/interviews/agents/2025/04_april/lynn-nicole-klutch-agent.md"
        "/content/interviews/industry-professionals/lamar-campbell.md|/content/interviews/industry-professionals/2025/04_april/campbell-lamar-financial-advisor.md"
        "/content/interviews/industry-professionals/daryl-nelson.md|/content/interviews/industry-professionals/2025/04_april/nelson-daryl-financial-advisor.md"
    )
    
    # Research map entries
    local research_entries=(
        "/content/research/market-analysis/athlete-financial-needs.md|/content/research/market-analysis/athlete-financial-needs.md"
        "/content/research/market-analysis/existing-service-gaps.md|/content/research/market-analysis/service-gaps.md"
        "/content/research/market-analysis/market-size-analysis.md|/content/research/market-analysis/market-size.md"
        "/content/research/competitor-profiles/integra-wealth-management.md|/content/research/competitor-profiles/integra-wealth.md"
        "/content/research/competitor-profiles/athlete-wealth-partners.md|/content/research/competitor-profiles/athlete-wealth-partners.md"
        "/content/research/competitor-profiles/agent-advisor-models.md|/content/research/competitor-profiles/agent-advisor-models.md"
        "/content/research/industry-analysis/fee-structure-comparison.md|/content/research/industry-analysis/fee-structures.md"
        "/content/research/industry-analysis/service-model-comparison.md|/content/research/industry-analysis/service-models.md"
    )
    
    # Strategy map entries
    local strategy_entries=(
        "/content/strategy/mission-statement.md|/content/strategy/mission-statement.md"
        "/content/strategy/business-model/service-offerings.md|/content/strategy/business-model/service-offerings.md"
        "/content/strategy/business-model/revenue-model.md|/content/strategy/business-model/revenue-model.md"
        "/content/strategy/business-model/competitive-positioning.md|/content/strategy/business-model/competitive-positioning.md"
        "/content/strategy/implementation/phase-one.md|/content/strategy/implementation/phase-one.md"
        "/content/strategy/implementation/phase-two.md|/content/strategy/implementation/phase-two.md"
        "/content/strategy/implementation/phase-three.md|/content/strategy/implementation/phase-three.md"
    )
    
    # Compliance map entries
    local compliance_entries=(
        "/content/compliance/registration/requirements.md|/content/compliance/registration/requirements.md"
        "/content/compliance/registration/application-process.md|/content/compliance/registration/application-process.md"
        "/content/compliance/registration/maintenance-requirements.md|/content/compliance/registration/maintenance-requirements.md"
        "/content/compliance/advisory-board/board-requirements.md|/content/compliance/advisory-board/board-requirements.md"
        "/content/compliance/advisory-board/candidate-research.md|/content/compliance/advisory-board/candidate-research.md"
        "/content/compliance/advisory-board/governance-structure.md|/content/compliance/advisory-board/governance-structure.md"
        "/content/compliance/standards/fiduciary-requirements.md|/content/compliance/standards/fiduciary-requirements.md"
        "/content/compliance/standards/disclosure-requirements.md|/content/compliance/standards/disclosure-requirements.md"
        "/content/compliance/standards/recordkeeping-requirements.md|/content/compliance/standards/recordkeeping-requirements.md"
    )
    
    # Add all the special mappings
    for entry in "${interview_entries[@]}"; do
        echo "$entry" >> "$mapping_file"
    done
    
    for entry in "${research_entries[@]}"; do
        echo "$entry" >> "$mapping_file"
    done
    
    for entry in "${strategy_entries[@]}"; do
        echo "$entry" >> "$mapping_file"
    done
    
    for entry in "${compliance_entries[@]}"; do
        echo "$entry" >> "$mapping_file"
    done
    
    # Add competitor profile mappings
    echo "/Athlete Financial Empowerment/01-market-research/competitor-profiles/advisors/integra-wealth-management.md|/content/research/competitor-profiles/integra-wealth.md" >> "$mapping_file"
    echo "/Athlete Financial Empowerment/01-market-research/competitor-profiles/advisors/ubs-mainsail.md|/content/research/competitor-profiles/ubs-mainsail.md" >> "$mapping_file"
    echo "/Athlete Financial Empowerment/01-market-research/competitor-profiles/advisors/km-capital-management.md|/content/research/competitor-profiles/km-capital.md" >> "$mapping_file"
    echo "/Athlete Financial Empowerment/01-market-research/competitor-profiles/advisors/wme-joel-segal.md|/content/research/competitor-profiles/wme-joel-segal.md" >> "$mapping_file"
    
    # Add documentation mappings
    echo "/docs/template-guide.md|/docs/guides/template-guide.md" >> "$mapping_file"
    echo "/docs/utilities-guide.md|/docs/guides/utilities-guide.md" >> "$mapping_file"
    echo "/docs/frontmatter-standards.md|/docs/guides/frontmatter-standards.md" >> "$mapping_file"
    
    # Add knowledge graph mappings
    echo "/resources/misc/knowledge-graph-enhancement-guide.md|/docs/guides/knowledge-graph-enhancement-guide.md" >> "$mapping_file"
    
    # Remove duplicates
    sort -u "$mapping_file" > "${mapping_file}.tmp"
    mv "${mapping_file}.tmp" "$mapping_file"
    
    echo "Added manual mappings (total: $(wc -l < "$mapping_file") entries)" | tee -a "$LOG_FILE"
    return 0
}

# Find all broken links in the vault
find_broken_links() {
    echo "Scanning for broken links..." | tee -a "$LOG_FILE"
    
    # Clear broken links file
    > "${BROKEN_LINKS}"
    
    # Process each directory to check
    for dir in "${CONTENT_DIRS[@]}"; do
        local dir_path="${dir}"
        
        # Skip if directory doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            echo "Directory not found, skipping: ${dir_path}" | tee -a "$LOG_FILE"
            continue
        fi
        
        echo "Checking links in: ${dir_path}" | tee -a "$LOG_FILE"
        
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
                    echo "${file}:${link}" >> "${BROKEN_LINKS}"
                fi
            done
        done
    done
    
    # Count broken links
    local broken_count
    broken_count=$(wc -l < "${BROKEN_LINKS}" | tr -d ' ')
    
    echo "Found ${broken_count} broken links" | tee -a "$LOG_FILE"
    return 0
}

# Function to update a broken link based on path mapping
resolve_link() {
    local broken_link="$1"
    local mapping_file="${INVENTORY_DIR}/path_mapping.txt"
    local resolved=""
    
    # Remove .md extension for matching
    local link_no_ext="${broken_link%.md}"
    
    # Try different variations of the link
    local variations=(
        "${broken_link}"
        "${link_no_ext}.md"
        "/${broken_link#/}"
        "/${link_no_ext#/}.md"
    )
    
    # Try to find an exact match in the mapping file
    for var in "${variations[@]}"; do
        if grep -q "^${var}|" "$mapping_file"; then
            resolved=$(grep "^${var}|" "$mapping_file" | cut -d '|' -f 2)
            break
        fi
    done
    
    # If no exact match, try to find a partial match using directory mapping
    if [[ -z "$resolved" ]]; then
        while IFS="|" read -r old_path new_path; do
            # Skip empty lines
            [[ -z "$old_path" ]] && continue
            
            # If old_path is a directory prefix of broken_link
            if [[ "$broken_link" == "$old_path"* ]] || [[ "$broken_link" == "/$old_path"* ]]; then
                # Replace the prefix
                resolved="${broken_link/$old_path/$new_path}"
                break
            fi
        done < "$mapping_file"
    fi
    
    # Return the resolved link, or the original if no match found
    if [[ -n "$resolved" ]]; then
        echo "$resolved"
    else
        # Last resort: try to guess a reasonable location
        local base_name=$(basename "$broken_link" .md)
        
        # Special cases based on naming conventions
        if [[ "$base_name" == *"interview"* ]]; then
            echo "/content/interviews/misc/${base_name}.md"
        elif [[ "$base_name" == *"competitor"* ]] || [[ "$base_name" == *"analysis"* ]]; then
            echo "/content/research/misc/${base_name}.md"
        elif [[ "$base_name" == *"model"* ]] || [[ "$base_name" == *"service"* ]]; then
            echo "/content/strategy/business-model/${base_name}.md"
        elif [[ "$base_name" == *"template"* ]]; then
            echo "/resources/templates/${base_name}.md"
        else
            echo "$broken_link"  # Return original link
        fi
    fi
}

# Function to update links in a single file
update_links_in_file() {
    local file="$1"
    local updated=0
    local temp_file="${file}.tmp"
    
    echo "Checking file: $file" | tee -a "$LOG_FILE"
    
    # Check if file has wiki-style links
    if ! grep -q '\[\[' "$file"; then
        echo "  No wiki links found, skipping" | tee -a "$LOG_FILE"
        return 0
    fi
    
    # Extract all wiki links
    local links=$(grep -o '\[\[[^]]*\]\]' "$file" || echo "")
    
    # Create temporary file for modifications
    cp "$file" "$temp_file"
    
    # Process each link
    echo "$links" | while read -r link; do
        # Extract link target and display text
        local original_link="$link"
        link=${link#\[\[}
        link=${link%\]\]}
        
        # Handle link with display text
        local target="$link"
        local display=""
        
        if [[ "$link" == *"|"* ]]; then
            target="${link%%|*}"
            display="${link#*|}"
        fi
        
        # Skip external links
        if [[ "$target" == "http"* ]]; then
            continue
        fi
        
        # Add .md extension if not present
        if [[ ! "$target" == *.md ]]; then
            target="${target}.md"
        fi
        
        # Determine target path
        local target_path
        if [[ "$target" == /* ]]; then
            # Absolute path
            target_path="${VAULT_ROOT}${target}"
        else
            # Relative path
            target_path="$(dirname "${file}")/${target}"
        fi
        
        # Check if target file exists
        local needs_update=false
        if [[ ! -f "$target_path" ]]; then
            needs_update=true
            
            # Try to resolve the link using the mapping
            local new_target=$(resolve_link "$target")
            
            # Create the new link with or without display text
            local new_link
            if [[ -n "$display" ]]; then
                new_link="[[${new_target%%.md}|${display}]]"
            else
                # Use target filename as display text for nicer appearance
                local basename=$(basename "$new_target" .md)
                basename=$(echo "$basename" | tr '-' ' ' | sed 's/\<./\U&/g')
                new_link="[[${new_target%%.md}|${basename}]]"
            fi
            
            # Use sed to replace the link in the file
            sed -i '' "s|${original_link}|${new_link}|g" "$temp_file"
            
            echo "  Updated: $original_link -> $new_link" | tee -a "$LOG_FILE"
            ((updated++))
        fi
    done
    
    # Only replace the original file if changes were made
    if [[ $updated -gt 0 ]]; then
        mv "$temp_file" "$file"
        echo "  Updated $updated links in $file" | tee -a "$LOG_FILE"
    else
        rm "$temp_file"
        echo "  No links needed updating in $file" | tee -a "$LOG_FILE"
    fi
    
    return 0
}

# Process all markdown files in a directory and its subdirectories
process_directory() {
    local dir="$1"
    
    echo "Processing directory: $dir" | tee -a "$LOG_FILE"
    
    # Find all markdown files recursively
    find "$dir" -type f -name "*.md" | while read -r file; do
        update_links_in_file "$file"
    done
}

# Process specific broken links from the inventory file
process_broken_links() {
    if [[ ! -f "$BROKEN_LINKS" ]]; then
        echo "No broken links inventory found, scanning for broken links..." | tee -a "$LOG_FILE"
        find_broken_links
    fi
    
    echo "Processing broken links from inventory..." | tee -a "$LOG_FILE"
    
    local count=0
    local files_updated=0
    local current_file=""
    local last_file=""
    
    # Read each line of the broken links file
    while IFS=":" read -r file_path link_path; do
        ((count++))
        current_file="$file_path"
        
        # Check if file exists
        if [[ ! -f "$file_path" ]]; then
            echo "File not found, skipping: $file_path" | tee -a "$LOG_FILE"
            continue
        fi
        
        # Only update each file once
        if [[ "$current_file" != "$last_file" ]]; then
            update_links_in_file "$file_path"
            last_file="$current_file"
            ((files_updated++))
        fi
    done < "$BROKEN_LINKS"
    
    echo "Processed $count broken links in $files_updated files" | tee -a "$LOG_FILE"
    return 0
}

# Process all content directories
process_all_directories() {
    echo "Processing all content directories..." | tee -a "$LOG_FILE"
    
    # Process each content directory
    for dir in "${CONTENT_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            process_directory "$dir"
        else
            echo "Directory does not exist: $dir" | tee -a "$LOG_FILE"
        fi
    done
    
    return 0
}

# Main processing

# Ensure the inventory directory exists
mkdir -p "${INVENTORY_DIR}"

# Generate and enhance path mapping
generate_path_mapping
add_manual_mappings

# Process only specific broken links
if [[ -f "$BROKEN_LINKS" ]]; then
    echo "Found existing broken links inventory, processing..." | tee -a "$LOG_FILE"
    process_broken_links
else
    echo "No broken links inventory found, processing all directories..." | tee -a "$LOG_FILE"
    process_all_directories
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Link fixing completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Link fixing completed. See log at: $LOG_FILE"