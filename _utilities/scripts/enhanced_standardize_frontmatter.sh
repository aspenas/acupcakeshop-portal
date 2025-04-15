#!/usr/bin/env bash
# enhanced_standardize_frontmatter.sh - Enhanced frontmatter standardization
#
# This script provides a more comprehensive fix for frontmatter issues,
# handling various frontmatter formats and special cases.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
FRONTMATTER_ISSUES="${INVENTORY_DIR}/frontmatter_issues.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/enhanced_frontmatter_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Enhanced Frontmatter Standardization Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to process
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

# Files to skip (patterns)
SKIP_PATTERNS=(
    ".DS_Store"
    "*.tmp"
    "*.bak"
    "*.excalidraw"
    "*.canvas"
)

# Skip directories that should not have frontmatter
SKIP_DIRS=(
    "${VAULT_ROOT}/resources/assets/images"
    "${VAULT_ROOT}/resources/assets/diagrams"
    "${VAULT_ROOT}/resources/assets/documents"
    "${VAULT_ROOT}/_utilities"
)

# Set default tag sets for different content types
get_default_tags() {
    local file_path="$1"
    local tags="[]"
    
    # Set default tags based on file location
    if [[ "$file_path" == */content/interviews/* ]]; then
        tags="[interview, athlete]"
    elif [[ "$file_path" == */content/research/* ]]; then
        tags="[research]"
    elif [[ "$file_path" == */content/strategy/* ]]; then
        tags="[strategy]"
    elif [[ "$file_path" == */content/compliance/* ]]; then
        tags="[compliance]"
    elif [[ "$file_path" == */atlas/* ]]; then
        tags="[atlas, map, moc]"
    elif [[ "$file_path" == */resources/templates/* ]]; then
        tags="[template]"
    elif [[ "$file_path" == */resources/dashboards/* ]]; then
        tags="[dashboard]"
    elif [[ "$file_path" == */docs/* ]]; then
        tags="[documentation]"
    fi
    
    echo "$tags"
}

# Function to scan for specific frontmatter issues
find_frontmatter_issues() {
    echo "Scanning for frontmatter issues..." | tee -a "$LOG_FILE"
    
    # Clear issues file
    > "${FRONTMATTER_ISSUES}"
    
    # Process each directory to check
    for dir in "${CONTENT_DIRS[@]}"; do
        local dir_path="${dir}"
        
        # Skip if directory doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            echo "Directory not found, skipping: ${dir_path}" | tee -a "$LOG_FILE"
            continue
        fi
        
        # Skip excluded directories
        local skip=false
        for excluded in "${SKIP_DIRS[@]}"; do
            if [[ "${dir_path}" == "${excluded}"* ]]; then
                echo "Skipping excluded directory: ${dir_path}" | tee -a "$LOG_FILE"
                skip=true
                break
            fi
        done
        
        [[ "${skip}" == "true" ]] && continue
        
        echo "Checking frontmatter in: ${dir_path}" | tee -a "$LOG_FILE"
        
        # Find all markdown files
        find "${dir_path}" -type f -name "*.md" | while read -r file; do
            local file_issues=0
            
            # Skip file if it matches patterns to ignore
            for pattern in "${SKIP_PATTERNS[@]}"; do
                if [[ "$(basename "$file")" == $pattern ]]; then
                    echo "  Skipping file: $file (matches pattern $pattern)" | tee -a "$LOG_FILE"
                    continue 2
                fi
            done
            
            # Check if file has frontmatter
            if ! grep -q "^---" "${file}"; then
                echo "${file}:Missing frontmatter completely" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
                continue
            fi
            
            # Check for required fields
            if ! grep -q "^title:" "${file}"; then
                echo "${file}:Missing required field: title" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            fi
            
            if ! grep -q "^date_created:" "${file}" && ! grep -q "^created:" "${file}"; then
                echo "${file}:Missing required field: date_created" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            elif grep -q "^created:" "${file}" && ! grep -q "^date_created:" "${file}"; then
                echo "${file}:Non-standardized date field: created (should be date_created)" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            fi
            
            if ! grep -q "^date_modified:" "${file}" && ! grep -q "^modified:" "${file}"; then
                echo "${file}:Missing required field: date_modified" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            elif grep -q "^modified:" "${file}" && ! grep -q "^date_modified:" "${file}"; then
                echo "${file}:Non-standardized date field: modified (should be date_modified)" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            fi
            
            if ! grep -q "^status:" "${file}"; then
                echo "${file}:Missing required field: status" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            fi
            
            if ! grep -q "^tags:" "${file}"; then
                echo "${file}:Missing required field: tags" >> "${FRONTMATTER_ISSUES}"
                ((file_issues++))
            else
                # Check if tags are in proper format
                local tags_line
                tags_line=$(grep "^tags:" "${file}")
                
                if [[ ! "${tags_line}" =~ [,\[\]] ]]; then
                    echo "${file}:Possibly malformed tags: ${tags_line}" >> "${FRONTMATTER_ISSUES}"
                    ((file_issues++))
                fi
            fi
            
            # Log file issues
            if [[ "${file_issues}" -gt 0 ]]; then
                echo "  Found ${file_issues} frontmatter issues in: ${file}" | tee -a "$LOG_FILE"
            fi
        done
    done
    
    # Count frontmatter issues
    local issues_count
    issues_count=$(wc -l < "${FRONTMATTER_ISSUES}" | tr -d ' ')
    
    echo "Found ${issues_count} frontmatter issues" | tee -a "$LOG_FILE"
    return 0
}

# Advanced function to clean and standardize tag formats
clean_tags() {
    local tags="$1"
    local result=""
    
    # Remove any leading/trailing spaces
    tags=$(echo "$tags" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # If empty, return empty array
    if [[ -z "$tags" ]]; then
        echo "[]"
        return 0
    fi
    
    # If already in array format [tag1, tag2], just return it
    if [[ "$tags" =~ ^\[.*\]$ ]]; then
        echo "$tags"
        return 0
    fi
    
    # Convert to array format
    echo "[$tags]"
    return 0
}

# Standardize frontmatter in a single file
standardize_file() {
    local file="$1"
    local temp_file="${file}.tmp"
    local has_frontmatter=false
    local creation_date=""
    local modified_date=""
    local title=""
    local status=""
    local tags=""
    
    # Skip file if it matches patterns to ignore
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "$file")" == $pattern ]]; then
            echo "  Skipping file: $file (matches pattern $pattern)" | tee -a "$LOG_FILE"
            return 0
        fi
    done
    
    # Skip directories that should not have frontmatter
    for skip_dir in "${SKIP_DIRS[@]}"; do
        if [[ "$file" == "$skip_dir"* ]]; then
            echo "  Skipping file in excluded directory: $file" | tee -a "$LOG_FILE"
            return 0
        fi
    done
    
    echo "Processing file: $file" | tee -a "$LOG_FILE"
    
    # Check if file has frontmatter
    if grep -q "^---" "$file"; then
        has_frontmatter=true
        
        # Extract existing frontmatter values
        if grep -q -i "^date_created:" "$file"; then
            creation_date=$(grep -i "^date_created:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        elif grep -q -i "^created:" "$file"; then
            creation_date=$(grep -i "^created:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        fi
        
        if grep -q -i "^date_modified:" "$file"; then
            modified_date=$(grep -i "^date_modified:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        elif grep -q -i "^modified:" "$file"; then
            modified_date=$(grep -i "^modified:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        fi
        
        title=$(grep -i "^title:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        status=$(grep -i "^status:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' | tr -d '"' || echo "")
        
        # Extract tags - handle different formats
        if grep -q "^tags:" "$file"; then
            # Get tags section - handle both single line and multi-line formats
            if grep -q "^tags:.*\[" "$file"; then
                # Single line array format: tags: [tag1, tag2]
                tags=$(grep -i "^tags:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' || echo "")
            else
                # Multi-line format
                tags=$(awk '/^tags:/,/^[^-]/' "$file" | sed '$d' | sed 's/^tags: *//')
                
                # If it doesn't end with a newline, it might be a single line format
                if ! echo "$tags" | grep -q "]"; then
                    tags="[$tags]"
                fi
            fi
        fi
    fi
    
    # Set default values if missing
    [[ -z "$creation_date" ]] && creation_date=$(date +%Y-%m-%d)
    [[ -z "$modified_date" ]] && modified_date=$(date +%Y-%m-%d)
    [[ -z "$title" ]] && title=$(basename "$file" .md | tr '-' ' ' | sed 's/\<./\U&/g')
    [[ -z "$status" ]] && status="active"
    
    # Set default tags based on content type if missing
    if [[ -z "$tags" ]]; then
        tags=$(get_default_tags "$file")
    else
        # Clean up existing tags format
        tags=$(clean_tags "$tags")
    fi
    
    # Generate standardized frontmatter
    {
        echo "---"
        echo "title: \"$title\""
        echo "date_created: $creation_date"
        echo "date_modified: $modified_date"
        echo "status: $status"
        echo "tags: $tags"
        echo "---"
        echo ""
    } > "$temp_file"
    
    # Append content after frontmatter
    if [[ "$has_frontmatter" == "true" ]]; then
        # Skip existing frontmatter when appending
        awk 'BEGIN{f=0} /^---$/{f++} f>=2 || (f==0 && NR>1){print}' "$file" >> "$temp_file"
    else
        # Append entire file content
        cat "$file" >> "$temp_file"
    fi
    
    # Replace original file
    mv "$temp_file" "$file"
    
    echo "  Standardized frontmatter in: $file" | tee -a "$LOG_FILE"
    return 0
}

# Process all files in a directory
process_directory() {
    local dir="$1"
    
    echo "Processing directory: $dir" | tee -a "$LOG_FILE"
    
    # Skip directories that should not have frontmatter
    for skip_dir in "${SKIP_DIRS[@]}"; do
        if [[ "$dir" == "$skip_dir"* ]]; then
            echo "Skipping excluded directory: $dir" | tee -a "$LOG_FILE"
            return 0
        fi
    done
    
    # Find all markdown files
    find "$dir" -type f -name "*.md" | while read -r file; do
        standardize_file "$file"
    done
}

# Process specific files with frontmatter issues
process_files_with_issues() {
    if [[ ! -f "$FRONTMATTER_ISSUES" ]]; then
        echo "No frontmatter issues inventory found, scanning for issues..." | tee -a "$LOG_FILE"
        find_frontmatter_issues
    fi
    
    echo "Processing files with frontmatter issues..." | tee -a "$LOG_FILE"
    
    local count=0
    local files_processed=0
    local files_list=()
    
    # Read each line of the issues file and extract unique file paths
    while IFS=":" read -r file_path rest; do
        # Skip if already in the list
        if [[ " ${files_list[*]} " == *" ${file_path} "* ]]; then
            continue
        fi
        
        # Add to the list
        files_list+=("$file_path")
        
        # Check if file exists
        if [[ ! -f "$file_path" ]]; then
            echo "File not found, skipping: $file_path" | tee -a "$LOG_FILE"
            continue
        fi
        
        # Standardize the file
        standardize_file "$file_path"
        ((files_processed++))
    done < "$FRONTMATTER_ISSUES"
    
    echo "Processed $files_processed files with frontmatter issues" | tee -a "$LOG_FILE"
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
            echo "Directory not found, skipping: $dir" | tee -a "$LOG_FILE"
        fi
    done
    
    return 0
}

# Main processing

# Ensure the inventory directory exists
mkdir -p "${INVENTORY_DIR}"

# Process only specific files with frontmatter issues if list exists
if [[ -f "$FRONTMATTER_ISSUES" ]]; then
    echo "Found existing frontmatter issues inventory, processing..." | tee -a "$LOG_FILE"
    process_files_with_issues
else
    echo "No frontmatter issues inventory found, processing all directories..." | tee -a "$LOG_FILE"
    process_all_directories
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Frontmatter standardization completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Frontmatter standardization completed. See log at: $LOG_FILE"