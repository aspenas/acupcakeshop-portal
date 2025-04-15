#!/usr/bin/env bash
# standardize_frontmatter.sh - Standardize frontmatter across all content files
#
# This script scans all markdown files in the content directories and ensures
# they have standardized frontmatter with required fields.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/standardize_frontmatter_$(date +%Y%m%d_%H%M%S).log"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Frontmatter Standardization Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Directories to process
CONTENT_DIRS=(
    "${VAULT_ROOT}/content"
    "${VAULT_ROOT}/resources/templates"
    "${VAULT_ROOT}/resources/dashboards"
    "${VAULT_ROOT}/atlas"
    "${VAULT_ROOT}/docs"
)

# Files to skip (patterns)
SKIP_PATTERNS=(
    ".DS_Store"
    "*.tmp"
    "*.bak"
)

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
    
    echo "Processing file: $file" | tee -a "$LOG_FILE"
    
    # Skip file if it matches patterns to ignore
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$(basename "$file")" == $pattern ]]; then
            echo "  Skipping file: $file (matches pattern $pattern)" | tee -a "$LOG_FILE"
            return 0
        fi
    done
    
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
        
        # Extract tags
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
    [[ -z "$tags" ]] && tags="[]"
    
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
    
    # Find all markdown files
    find "$dir" -type f -name "*.md" | while read -r file; do
        standardize_file "$file"
    done
}

# Process all directories
echo "Starting frontmatter standardization in ${#CONTENT_DIRS[@]} directories..." | tee -a "$LOG_FILE"

for dir in "${CONTENT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        process_directory "$dir"
    else
        echo "Directory not found, skipping: $dir" | tee -a "$LOG_FILE"
    fi
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Frontmatter standardization completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Frontmatter standardization completed. See log at: $LOG_FILE"