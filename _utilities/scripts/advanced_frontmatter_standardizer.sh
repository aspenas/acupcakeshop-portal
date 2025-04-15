#!/usr/bin/env bash
# advanced_frontmatter_standardizer.sh - Advanced frontmatter standardization
#
# This script standardizes frontmatter across all files with special handling
# for template files and their unique requirements.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
FRONTMATTER_ISSUES="${INVENTORY_DIR}/frontmatter_issues.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/advanced_frontmatter_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"
mkdir -p "${INVENTORY_DIR}"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Advanced Frontmatter Standardization Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to process
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

# Function to get default tags based on file location
get_default_tags() {
    local file_path="$1"
    local is_template="$2"
    local tags="[]"
    
    # For template files, add template tag
    if [[ "$is_template" == "true" ]]; then
        tags="[template"
        
        # Add specialized template tags based on location
        if [[ "$file_path" == *"/templates/interview"* ]]; then
            tags="$tags, interview-template"
        elif [[ "$file_path" == *"/templates/analysis"* ]]; then
            tags="$tags, analysis-template"
        elif [[ "$file_path" == *"/templates/task"* ]]; then
            tags="$tags, task-template"
        elif [[ "$file_path" == *"/templates/project"* ]]; then
            tags="$tags, project-template"
        fi
        
        tags="$tags]"
        return 0
    fi
    
    # Set default tags based on file location for non-template files
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
            
            # Check if this is a template file
            local is_template=false
            if is_template_file "$file"; then
                is_template=true
            fi
            
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
            
            # For template files, check for special template fields
            if [[ "$is_template" == "true" ]]; then
                # Check if the template has variables in the title
                if grep -q "^title:" "${file}" && ! grep -q "{{" "$(grep -A 1 "^title:" "${file}")"; then
                    echo "${file}:Template may need variable in title" >> "${FRONTMATTER_ISSUES}"
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

# Function to merge tags from different formats
merge_tags() {
    local tags="$1"
    local new_tags="$2"
    
    # Remove brackets
    tags="${tags#[}"
    tags="${tags%]}"
    new_tags="${new_tags#[}"
    new_tags="${new_tags%]}"
    
    # Combine tags
    local combined="$tags, $new_tags"
    
    # Remove duplicates
    local unique_tags=$(echo "$combined" | tr ',' '\n' | sed 's/^ *//' | sed 's/ *$//' | sort -u | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//')
    
    # Format as array
    echo "[$unique_tags]"
}

# Handle template variables in frontmatter
process_template_frontmatter() {
    local file="$1"
    local title="$2"
    local date_created="$3"
    local date_modified="$4"
    local status="$5"
    local tags="$6"
    local temp_file="${file}.tmp"
    
    # For template files, preserve template variables
    
    # For title, keep both the title and any template variables
    if [[ "$title" != *"{{"* && "$(basename "$file")" == *"template"* ]]; then
        # Add template variable to title if not present
        if [[ "$(basename "$file")" == *"task"* ]]; then
            title="$title - {{TASK_NAME}}"
        elif [[ "$(basename "$file")" == *"interview"* ]]; then
            title="$title - {{INTERVIEWEE}}"
        elif [[ "$(basename "$file")" == *"weekly"* ]]; then
            title="$title - {{DATE}}"
        fi
    fi
    
    # For template status, use "template" as default
    status="template"
    
    # Generate standardized frontmatter with template awareness
    {
        echo "---"
        echo "title: \"$title\""
        echo "date_created: $date_created"
        echo "date_modified: $date_modified"
        echo "status: $status"
        echo "tags: $tags"
        echo "---"
        echo ""
    } > "$temp_file"
    
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
    local is_template=false
    
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
    
    # Check if this is a template file
    if is_template_file "$file"; then
        is_template=true
        echo "Processing template file: $file" | tee -a "$LOG_FILE"
    else
        echo "Processing file: $file" | tee -a "$LOG_FILE"
    fi
    
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
                # Multi-line format - extract all tag lines
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
    
    # Set status based on file type
    if [[ "$is_template" == "true" ]]; then
        status="template"
    elif [[ -z "$status" ]]; then
        status="active"
    fi
    
    # Set default tags based on content type if missing
    if [[ -z "$tags" ]]; then
        tags=$(get_default_tags "$file" "$is_template")
    else
        # Clean up existing tags format
        tags=$(clean_tags "$tags")
        
        # Add default tags to existing tags
        default_tags=$(get_default_tags "$file" "$is_template")
        if [[ "$default_tags" != "[]" ]]; then
            tags=$(merge_tags "$tags" "$default_tags")
        fi
    fi
    
    # Special handling for template files
    if [[ "$is_template" == "true" ]]; then
        process_template_frontmatter "$file" "$title" "$creation_date" "$modified_date" "$status" "$tags"
    else
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
    fi
    
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

# Process all template files specifically
process_templates() {
    echo "Processing template files specifically..." | tee -a "$LOG_FILE"
    
    # Process each template directory
    for dir in "${TEMPLATE_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "Processing template directory: $dir" | tee -a "$LOG_FILE"
            
            # Find all template files
            find "$dir" -type f -name "*.md" | while read -r file; do
                standardize_file "$file"
            done
        else
            echo "Template directory not found, skipping: $dir" | tee -a "$LOG_FILE"
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
            echo "Directory not found, skipping: $dir" | tee -a "$LOG_FILE"
        fi
    done
    
    return 0
}

# Main processing
# ------------------------------------------------------

# Ensure the inventory directory exists
mkdir -p "${INVENTORY_DIR}"

# Find frontmatter issues first to build the inventory
echo "Building frontmatter issues inventory..." | tee -a "$LOG_FILE"
find_frontmatter_issues

# Process templates first with special handling
process_templates

# Process files with frontmatter issues
process_files_with_issues

# Verify and fix any remaining issues
echo "Verifying frontmatter fixes..." | tee -a "$LOG_FILE"
find_frontmatter_issues

# If there are still issues, run a final pass
if [[ -s "$FRONTMATTER_ISSUES" ]]; then
    remaining=$(wc -l < "$FRONTMATTER_ISSUES" | tr -d ' ')
    echo "Found $remaining remaining frontmatter issues after first pass" | tee -a "$LOG_FILE"
    echo "Running final pass on all content..." | tee -a "$LOG_FILE"
    process_all_directories
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Frontmatter standardization completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Frontmatter standardization completed. See log at: $LOG_FILE"