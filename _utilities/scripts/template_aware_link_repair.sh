#!/usr/bin/env bash
# template_aware_link_repair.sh - Advanced link repair for template files
#
# This script specifically handles template variables and special syntax in
# template files while repairing broken links in Obsidian files.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
BROKEN_LINKS="${INVENTORY_DIR}/broken_links.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/template_link_repair_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"
mkdir -p "${INVENTORY_DIR}"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Template-Aware Link Repair Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to scan for links
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

# Template directories that need special handling
TEMPLATE_DIRS=(
    "${VAULT_ROOT}/resources/templates"
)

# Template variable patterns to preserve
TEMPLATE_VARS=(
    "{{RELATED_TASK_[0-9]}}"
    "{{DEPENDENCY_[0-9]}}"
    "{{PROJECT_TAG}}"
    "{{TASK_NAME}}"
    "{{TASK_DESCRIPTION}}"
    "{{DUE_DATE}}"
    "{{PRIORITY}}"
    "{{ASSIGNED_TO}}"
    "{{STATUS}}"
    "{{DATE}}"
    "{{TIME}}"
    "{{WEEKLY_STATUS}}"
    "{{TITLE}}"
)

# Function to check if a file is a template file
is_template_file() {
    local file="$1"
    
    # Check if file is in template directories
    for template_dir in "${TEMPLATE_DIRS[@]}"; do
        if [[ "$file" == "$template_dir"* ]]; then
            return 0  # It's a template file
        fi
    done
    
    # Also check if filename contains "template"
    if [[ "$(basename "$file")" == *"template"* ]]; then
        return 0  # It's a template file
    fi
    
    return 1  # Not a template file
}

# Function to check if a link contains template variables
contains_template_vars() {
    local link="$1"
    
    for var_pattern in "${TEMPLATE_VARS[@]}"; do
        if [[ "$link" == *"$var_pattern"* ]]; then
            return 0  # Contains template variables
        fi
    done
    
    return 1  # No template variables
}

# Function to find broken links in the vault
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
            # Special handling for template files
            local is_template=false
            if is_template_file "$file"; then
                is_template=true
                echo "  Processing template file: $file" | tee -a "$LOG_FILE"
            fi
            
            # Extract all wiki-style links
            grep -o '\[\[[^]]*\]\]' "${file}" 2>/dev/null | while read -r link; do
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
                
                # Skip links with template variables if this is a template file
                if [[ "$is_template" == "true" ]] && contains_template_vars "$link"; then
                    echo "  Skipping template variable link: $link" | tee -a "$LOG_FILE"
                    continue
                fi
                
                # Skip bash variable patterns in scripts
                if [[ "$link" == *"${"* || "$link" == *"$(("* || "$link" == *"$("* ]]; then
                    echo "  Skipping script variable: $link" | tee -a "$LOG_FILE"
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
                    
                    # If in a template file, add note about it being a template
                    if [[ "$is_template" == "true" ]]; then
                        echo "  Template broken link: ${file}:${link}" | tee -a "$LOG_FILE"
                    fi
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

# Function to safely update text with sed
safe_sed_replace() {
    local file="$1"
    local search="$2"
    local replace="$3"
    local temp_file="${file}.tmp"
    
    # Escape characters for sed
    search=$(echo "$search" | sed 's/[][\/$*.^|]/\\&/g')
    replace=$(echo "$replace" | sed 's/[][\/$*.^|]/\\&/g')
    
    # Replace the text
    sed "s/${search}/${replace}/g" "$file" > "$temp_file"
    
    # Check if the replacement worked
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$file"
        return 0
    else
        rm "$temp_file"
        return 1
    fi
}

# Function to update links in a single file
update_links_in_file() {
    local file="$1"
    local updated=0
    local skipped=0
    local is_template=false
    
    # Check if this is a template file
    if is_template_file "$file"; then
        is_template=true
        echo "Updating template file: $file" | tee -a "$LOG_FILE"
    else
        echo "Updating file: $file" | tee -a "$LOG_FILE"
    fi
    
    # Extract all wiki-style links
    grep -o '\[\[[^]]*\]\]' "${file}" 2>/dev/null | while read -r original_link; do
        # Clean link syntax for processing
        link=${original_link#\[\[}
        link=${link%\]\]}
        
        # Handle display text
        local display=""
        local target="$link"
        
        if [[ "${link}" == *"|"* ]]; then
            target="${link%%|*}"
            display="${link#*|}"
        fi
        
        # Skip external links
        if [[ "${target}" == "http"* ]]; then
            continue
        fi
        
        # Skip template variables in template files
        if [[ "$is_template" == "true" ]] && (contains_template_vars "$target" || contains_template_vars "$display"); then
            echo "  Skipping template variable: $original_link" | tee -a "$LOG_FILE"
            ((skipped++))
            continue
        fi
        
        # Skip bash variables in code files
        if [[ "$target" == *"${"* || "$target" == *"$(("* || "$target" == *"$("* ]]; then
            echo "  Skipping script variable: $original_link" | tee -a "$LOG_FILE"
            ((skipped++))
            continue
        fi
        
        # Add .md extension if not present
        if [[ ! "$target" == *.md ]]; then
            new_target="${target}.md"
        else
            new_target="$target"
        fi
        
        # Determine target path
        local target_path
        if [[ "${new_target}" == /* ]]; then
            # Absolute path
            target_path="${VAULT_ROOT}${new_target}"
        else
            # Relative path
            target_path="$(dirname "${file}")/${new_target}"
        fi
        
        # Check if target file exists
        if [[ ! -f "${target_path}" ]]; then
            # Resolve broken link
            
            # For template files, if it's a template link, just add a placeholder
            if [[ "$is_template" == "true" ]] && [[ "$target" == *"template"* || "$file" == *"template"* ]]; then
                # Just add a display name to make it look better in Obsidian
                local clean_target=$(basename "$target" .md | tr '-' ' ' | sed 's/\<./\U&/g')
                
                if [[ -n "$display" ]]; then
                    # Keep existing display text
                    new_link="[[${target}|${display}]]"
                else
                    # Add display text
                    new_link="[[${target}|${clean_target}]]"
                fi
                
                # Replace in file
                if safe_sed_replace "$file" "$original_link" "$new_link"; then
                    echo "  Template link enhanced: $original_link -> $new_link" | tee -a "$LOG_FILE"
                    ((updated++))
                else
                    echo "  Failed to update template link: $original_link" | tee -a "$LOG_FILE"
                fi
                
                continue
            fi
            
            # For regular files, try to find a correct target
            
            # Try to find a matching file in the vault
            local section=""
            local new_path=""
            
            # Determine the most likely section based on file content
            if [[ "$target" == *"interview"* ]]; then
                section="interviews"
                new_path="/content/interviews/misc/${target}"
            elif [[ "$target" == *"competitor"* || "$target" == *"analysis"* ]]; then
                section="research"
                new_path="/content/research/misc/${target}"
            elif [[ "$target" == *"strategy"* || "$target" == *"planning"* ]]; then
                section="strategy"
                new_path="/content/strategy/misc/${target}"
            elif [[ "$target" == *"compliance"* || "$target" == *"regulatory"* ]]; then
                section="compliance"
                new_path="/content/compliance/misc/${target}"
            elif [[ "$target" == *"template"* ]]; then
                section="templates"
                new_path="/resources/templates/misc/${target}"
            elif [[ "$target" == *"dashboard"* ]]; then
                section="dashboards"
                new_path="/resources/dashboards/misc/${target}"
            else
                # Default to docs for unrecognized patterns
                section="docs"
                new_path="/docs/misc/${target}"
            fi
            
            # Create the new link with appropriate display text
            if [[ -n "$display" ]]; then
                # Keep existing display text
                new_link="[[${new_path}|${display}]]"
            else
                # Use filename as display text
                local clean_name=$(basename "$target" .md | tr '-' ' ' | sed 's/\<./\U&/g')
                new_link="[[${new_path}|${clean_name}]]"
            fi
            
            # Replace in file
            if safe_sed_replace "$file" "$original_link" "$new_link"; then
                echo "  Updated: $original_link -> $new_link" | tee -a "$LOG_FILE"
                ((updated++))
            else
                echo "  Failed to update link: $original_link" | tee -a "$LOG_FILE"
            fi
        else
            # Target file exists, make sure it has display text for better readability
            if [[ -z "$display" ]]; then
                # Add display text for better readability
                local clean_name=$(basename "$target" .md | tr '-' ' ' | sed 's/\<./\U&/g')
                new_link="[[${target}|${clean_name}]]"
                
                # Replace in file
                if safe_sed_replace "$file" "$original_link" "$new_link"; then
                    echo "  Enhanced: $original_link -> $new_link" | tee -a "$LOG_FILE"
                    ((updated++))
                fi
            fi
        fi
    done
    
    echo "  Updated $updated links in $file, skipped $skipped" | tee -a "$LOG_FILE"
    return 0
}

# Create placeholder files for common broken links
create_placeholder_files() {
    echo "Creating placeholder files for common broken link targets..." | tee -a "$LOG_FILE"
    
    # Extract unique broken link targets
    local temp_targets="${INVENTORY_DIR}/broken_link_targets.txt"
    cut -d ':' -f 2 "${BROKEN_LINKS}" | sort | uniq > "$temp_targets"
    
    # Skip placeholder creation for template variables
    for var_pattern in "${TEMPLATE_VARS[@]}"; do
        sed -i '' "/$var_pattern/d" "$temp_targets"
    done
    
    # Skip bash variables
    sed -i '' '/\${/d' "$temp_targets"
    sed -i '' '/\$(/d' "$temp_targets"
    
    # Count targets
    local target_count=$(wc -l < "$temp_targets" | tr -d ' ')
    echo "Found $target_count unique broken link targets" | tee -a "$LOG_FILE"
    
    # Process each target
    local created=0
    while IFS= read -r target; do
        # Skip if target is empty
        [[ -z "$target" ]] && continue
        
        # Skip if it looks like a template variable
        [[ "$target" == *"{{"* || "$target" == *"}}"* ]] && continue
        
        # Skip if it has bash variables
        [[ "$target" == *"${"* || "$target" == *"$("* ]] && continue
        
        # Determine the most likely section based on file content
        local section=""
        local new_path=""
        
        if [[ "$target" == *"interview"* ]]; then
            new_path="${VAULT_ROOT}/content/interviews/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        elif [[ "$target" == *"competitor"* || "$target" == *"analysis"* ]]; then
            new_path="${VAULT_ROOT}/content/research/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        elif [[ "$target" == *"strategy"* || "$target" == *"planning"* ]]; then
            new_path="${VAULT_ROOT}/content/strategy/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")" 
        elif [[ "$target" == *"compliance"* || "$target" == *"regulatory"* ]]; then
            new_path="${VAULT_ROOT}/content/compliance/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        elif [[ "$target" == *"template"* ]]; then
            new_path="${VAULT_ROOT}/resources/templates/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        elif [[ "$target" == *"dashboard"* ]]; then
            new_path="${VAULT_ROOT}/resources/dashboards/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        else
            # Default to docs for unrecognized patterns
            new_path="${VAULT_ROOT}/docs/misc/$(basename "$target")"
            mkdir -p "$(dirname "$new_path")"
        fi
        
        # Only create file if it doesn't already exist
        if [[ ! -f "$new_path" ]]; then
            # Create title from filename
            local title=$(basename "$target" .md | tr '-' ' ' | sed 's/\<./\U&/g')
            
            # Create placeholder file
            {
                echo "---"
                echo "title: \"$title\""
                echo "date_created: $(date +%Y-%m-%d)"
                echo "date_modified: $(date +%Y-%m-%d)"
                echo "status: placeholder"
                echo "tags: [placeholder, migration]"
                echo "---"
                echo ""
                echo "# $title"
                echo ""
                echo "*This is a placeholder file created during migration to resolve broken links. Content needs to be added.*"
                echo ""
            } > "$new_path"
            
            echo "  Created placeholder file: $new_path" | tee -a "$LOG_FILE"
            ((created++))
        fi
    done < "$temp_targets"
    
    echo "Created $created placeholder files to resolve broken links" | tee -a "$LOG_FILE"
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
    
    # First create placeholder files for common link targets
    create_placeholder_files
    
    # Process files with broken links
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

# Process all template files specifically
process_templates() {
    echo "Processing template files specifically..." | tee -a "$LOG_FILE"
    
    # Process each template directory
    for dir in "${TEMPLATE_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            # Find all template files
            find "$dir" -type f -name "*.md" | while read -r file; do
                # Special processing for template files
                update_links_in_file "$file"
            done
        fi
    done
    
    echo "Template processing completed" | tee -a "$LOG_FILE"
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
# ------------------------------------------------------

# Ensure the inventory directory exists
mkdir -p "${INVENTORY_DIR}"

# Find broken links first to build the inventory
echo "Building broken links inventory..." | tee -a "$LOG_FILE"
find_broken_links

# First, create placeholder files for common broken links
create_placeholder_files

# Process templates first with special handling
process_templates

# Process files with broken links
process_broken_links

# Verify and fix any remaining issues
echo "Verifying link fixes..." | tee -a "$LOG_FILE"
find_broken_links

# If there are still broken links, run a final pass
if [[ -s "$BROKEN_LINKS" ]]; then
    remaining=$(wc -l < "$BROKEN_LINKS" | tr -d ' ')
    echo "Found $remaining remaining broken links after first pass" | tee -a "$LOG_FILE"
    echo "Running final pass on all content..." | tee -a "$LOG_FILE"
    process_all_directories
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Link repair completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Link repair completed. See log at: $LOG_FILE"