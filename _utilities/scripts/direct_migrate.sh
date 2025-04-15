#!/usr/bin/env bash
# direct_migrate.sh - Direct migration of unmigrated content
#
# This script performs a simple direct migration of unmigrated content
# without relying on the tracker database.
#
# Dependencies: bash, find, cp, mkdir

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
UNMIGRATED_FILES="${INVENTORY_DIR}/unmigrated_files.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/direct_migrate_$(date +%Y%m%d_%H%M%S).log"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Direct Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Mapping of source directories to target directories
declare -A DIR_MAPPING
DIR_MAPPING["/Athlete Financial Empowerment/00-project-overview"]="/content/strategy"
DIR_MAPPING["/Athlete Financial Empowerment/01-market-research"]="/content/research"
DIR_MAPPING["/Athlete Financial Empowerment/01-education"]="/content/research/education"
DIR_MAPPING["/Athlete Financial Empowerment/02-interviews"]="/content/interviews"
DIR_MAPPING["/Athlete Financial Empowerment/03-strategy"]="/content/strategy"
DIR_MAPPING["/Athlete Financial Empowerment/04-analysis"]="/content/research"
DIR_MAPPING["/Athlete Financial Empowerment/05-compliance"]="/content/compliance"
DIR_MAPPING["/Athlete Financial Empowerment/06-planning"]="/content/strategy/planning"
DIR_MAPPING["/Athlete Financial Empowerment/07-team"]="/content/strategy/team"
DIR_MAPPING["/Athlete Financial Empowerment/_templates"]="/resources/templates"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/interview-templates"]="/resources/templates/interview"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/analysis-templates"]="/resources/templates/analysis"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/task-templates"]="/resources/templates/task"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/competitor-templates"]="/resources/templates/analysis"
DIR_MAPPING["/Maps"]="/atlas"
DIR_MAPPING["/Dashboards"]="/resources/dashboards"
DIR_MAPPING["/Resources/Dashboards"]="/resources/dashboards"
DIR_MAPPING["/Resources/Maps"]="/atlas"
DIR_MAPPING["/Resources/Templates"]="/resources/templates"

# Function to clean filename
clean_filename() {
    local filename="$1"
    local base_name=$(basename "$filename" .md)
    
    # Handle special cases
    if [[ "$base_name" == "_index" ]]; then
        echo "README"
    else
        # Replace underscores with hyphens
        echo "${base_name}" | tr '_' '-'
    fi
}

# Process each file in the unmigrated list
process_unmigrated_files() {
    if [[ ! -f "$UNMIGRATED_FILES" ]]; then
        echo "Unmigrated files list not found: $UNMIGRATED_FILES" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "Processing unmigrated files from: $UNMIGRATED_FILES" | tee -a "$LOG_FILE"
    echo "Found $(wc -l < "$UNMIGRATED_FILES") files to process" | tee -a "$LOG_FILE"
    
    # Process each file
    while IFS= read -r file_path; do
        # Skip if file doesn't exist
        if [[ ! -f "$file_path" ]]; then
            echo "File not found, skipping: $file_path" | tee -a "$LOG_FILE"
            continue
        fi
        
        # Determine target directory
        target_dir=""
        for src_dir in "${!DIR_MAPPING[@]}"; do
            if [[ "$file_path" == *"$src_dir"* ]]; then
                target_dir="${VAULT_ROOT}${DIR_MAPPING[$src_dir]}"
                relative_path="${file_path#*$src_dir/}"
                relative_dir=$(dirname "$relative_path")
                
                # If it's just a filename with no directory
                if [[ "$relative_dir" == "." ]]; then
                    relative_dir=""
                fi
                
                # Combine to get final target directory
                if [[ -n "$relative_dir" ]]; then
                    target_dir="${target_dir}/${relative_dir}"
                fi
                
                break
            fi
        done
        
        # If no matching directory found, use a default
        if [[ -z "$target_dir" ]]; then
            if [[ "$file_path" == *"/Athlete Financial Empowerment/"* ]]; then
                target_dir="${VAULT_ROOT}/content"
            else
                target_dir="${VAULT_ROOT}/resources/misc"
            fi
        fi
        
        # Clean the filename
        base_name=$(basename "$file_path")
        clean_name=$(clean_filename "$base_name")
        target_file="${target_dir}/${clean_name}.md"
        
        # Create target directory
        mkdir -p "$target_dir"
        
        # Copy the file
        echo "Migrating: $file_path -> $target_file" | tee -a "$LOG_FILE"
        cp "$file_path" "$target_file"
        
        # Basic frontmatter standardization
        temp_file="${target_file}.tmp"
        
        # Check if file has frontmatter
        if grep -q "^---" "$target_file"; then
            # File has frontmatter, ensure dates use standardized format
            # Convert created: to date_created:
            sed -i '' 's/^created:/date_created:/g' "$target_file"
            # Convert modified: to date_modified:
            sed -i '' 's/^modified:/date_modified:/g' "$target_file"
        else
            # File doesn't have frontmatter, add basic frontmatter
            title=$(basename "$target_file" .md | tr '-' ' ' | sed 's/\<./\U&/g')
            echo "---" > "$temp_file"
            echo "title: \"$title\"" >> "$temp_file"
            echo "date_created: $(date +%Y-%m-%d)" >> "$temp_file"
            echo "date_modified: $(date +%Y-%m-%d)" >> "$temp_file"
            echo "status: active" >> "$temp_file"
            echo "tags: []" >> "$temp_file"
            echo "---" >> "$temp_file"
            echo "" >> "$temp_file"
            
            # Append original content
            cat "$target_file" >> "$temp_file"
            mv "$temp_file" "$target_file"
        fi
    done < "$UNMIGRATED_FILES"
    
    echo "Processing completed" | tee -a "$LOG_FILE"
    return 0
}

# Create missing directories first
for dir in "${DIR_MAPPING[@]}"; do
    mkdir -p "${VAULT_ROOT}${dir}"
    echo "Ensured directory exists: ${VAULT_ROOT}${dir}" | tee -a "$LOG_FILE"
done

# Process unmigrated files
if process_unmigrated_files; then
    echo "Direct migration completed successfully" | tee -a "$LOG_FILE"
else
    echo "Direct migration completed with errors" | tee -a "$LOG_FILE"
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"