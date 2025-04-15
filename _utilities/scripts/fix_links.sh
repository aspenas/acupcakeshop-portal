#!/usr/bin/env bash
# fix_links.sh - Fix broken links in migrated content
#
# This script scans all markdown files in the new directory structure
# and updates internal wiki-style links to maintain correct references.
#
# Dependencies: bash, grep, sed

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/fix_links_$(date +%Y%m%d_%H%M%S).log"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Link Repair Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to scan for links
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

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
        
        # Check if this is a link that needs updating
        local needs_update=false
        local new_target="$target"
        
        # Check for paths that need mapping
        for old_path in "${!PATH_MAPPING[@]}"; do
            if [[ "$target" == "$old_path"* ]]; then
                # Replace old path with new path
                new_target="${PATH_MAPPING[$old_path]}${target#$old_path}"
                needs_update=true
                break
            fi
        done
        
        # Clean up common patterns in links
        if [[ "$new_target" == *"_index"* ]]; then
            # Convert _index to README
            new_target="${new_target/_index/README}"
            needs_update=true
        fi
        
        # Reformat date prefixed filenames
        if [[ "$new_target" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})_(.+) ]]; then
            new_target="${new_target/${BASH_REMATCH[0]}/${BASH_REMATCH[1]}-${BASH_REMATCH[2]}}"
            new_target=$(echo "$new_target" | tr '_' '-')
            needs_update=true
        fi
        
        # Update link in file if needed
        if [[ "$needs_update" == "true" ]]; then
            local new_link
            
            # Create the new link with or without display text
            if [[ -n "$display" ]]; then
                new_link="[[${new_target}|${display}]]"
            else
                # Use target filename as display text for nicer appearance
                local basename=$(basename "$new_target" .md)
                new_link="[[${new_target}|${basename}]]"
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

# Main processing
echo "Starting link fixes in ${#CONTENT_DIRS[@]} directories..." | tee -a "$LOG_FILE"

# Process each content directory
for dir in "${CONTENT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        process_directory "$dir"
    else
        echo "Directory does not exist: $dir" | tee -a "$LOG_FILE"
    fi
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Link fixing completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Link fixing completed. See log at: $LOG_FILE"