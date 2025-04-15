#!/usr/bin/env bash
# simple_frontmatter_fix.sh - Simple frontmatter standardization
#
# This script standardizes frontmatter across all files

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/simple_frontmatter_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Simple Frontmatter Fix Log" | tee -a "$LOG_FILE"
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

# Get default tags based on file location
get_default_tags() {
    local file_path="$1"
    local tags="[]"
    
    # Set default tags based on file location
    if [[ "$file_path" == */content/interviews/* ]]; then
        tags="[interview, content]"
    elif [[ "$file_path" == */content/research/* ]]; then
        tags="[research, content]"
    elif [[ "$file_path" == */content/strategy/* ]]; then
        tags="[strategy, content]"
    elif [[ "$file_path" == */content/compliance/* ]]; then
        tags="[compliance, content]"
    elif [[ "$file_path" == */atlas/* ]]; then
        tags="[atlas, map, navigation]"
    elif [[ "$file_path" == */resources/templates/* ]]; then
        tags="[template, resource]"
    elif [[ "$file_path" == */resources/dashboards/* ]]; then
        tags="[dashboard, resource]"
    elif [[ "$file_path" == */docs/* ]]; then
        tags="[documentation, guide]"
    fi
    
    echo "$tags"
}

# Standardize frontmatter in a file
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
        
        # Extract tags (simple approach)
        if grep -q "^tags:" "$file"; then
            tags=$(grep -i "^tags:" "$file" | cut -d ':' -f 2- | sed 's/^ *//' || echo "")
        fi
    fi
    
    # Set default values if missing
    [[ -z "$creation_date" ]] && creation_date=$(date +%Y-%m-%d)
    [[ -z "$modified_date" ]] && modified_date=$(date +%Y-%m-%d)
    [[ -z "$title" ]] && title=$(basename "$file" .md | tr '-' ' ' | sed 's/\<./\U&/g')
    [[ -z "$status" ]] && status="active"
    
    # Set default tags based on location if missing
    [[ -z "$tags" || "$tags" == "[]" ]] && tags=$(get_default_tags "$file")
    
    # Ensure tags are in array format
    if [[ ! "$tags" =~ ^\[.*\]$ ]]; then
        tags="[$tags]"
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

# Process a directory recursively
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

# Process all content directories
echo "Starting frontmatter standardization..." | tee -a "$LOG_FILE"

for dir in "${CONTENT_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        process_directory "$dir"
    else
        echo "Directory not found: $dir" | tee -a "$LOG_FILE"
    fi
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Frontmatter standardization completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Frontmatter standardization completed. See log at: $LOG_FILE"