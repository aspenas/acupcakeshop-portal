#!/usr/bin/env bash
# enhanced_direct_migrate.sh - Enhanced direct migration for unmigrated content
#
# This script performs a direct migration of all unmigrated content without relying
# on the tracker database, addressing issues found during verification.
#
# Dependencies: bash, find, cp, mkdir, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
UNMIGRATED_FILES="${INVENTORY_DIR}/unmigrated_files.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/enhanced_direct_migrate_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Enhanced Direct Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Mapping of source directories to target directories
declare -A DIR_MAPPING
# Main content sections
DIR_MAPPING["/Athlete Financial Empowerment/00-project-overview"]="/content/strategy"
DIR_MAPPING["/Athlete Financial Empowerment/01-market-research"]="/content/research"
DIR_MAPPING["/Athlete Financial Empowerment/01-education"]="/content/research/education"
DIR_MAPPING["/Athlete Financial Empowerment/02-interviews"]="/content/interviews"
DIR_MAPPING["/Athlete Financial Empowerment/03-strategy"]="/content/strategy"
DIR_MAPPING["/Athlete Financial Empowerment/04-analysis"]="/content/research"
DIR_MAPPING["/Athlete Financial Empowerment/05-compliance"]="/content/compliance"
DIR_MAPPING["/Athlete Financial Empowerment/06-planning"]="/content/strategy/planning"
DIR_MAPPING["/Athlete Financial Empowerment/07-team"]="/content/strategy/team"

# Templates and resources
DIR_MAPPING["/Athlete Financial Empowerment/_templates"]="/resources/templates"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/interview-templates"]="/resources/templates/interview"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/analysis-templates"]="/resources/templates/analysis"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/task-templates"]="/resources/templates/task"
DIR_MAPPING["/Athlete Financial Empowerment/_templates/competitor-templates"]="/resources/templates/analysis"

# Maps and dashboards
DIR_MAPPING["/Maps"]="/atlas"
DIR_MAPPING["/Dashboards"]="/resources/dashboards"
DIR_MAPPING["/Resources/Dashboards"]="/resources/dashboards"
DIR_MAPPING["/Resources/Maps"]="/atlas"
DIR_MAPPING["/Resources/Templates"]="/resources/templates"

# System and documentation
DIR_MAPPING["/Documentation"]="/docs"
DIR_MAPPING["/Documentation/Guides"]="/docs/guides"
DIR_MAPPING["/Documentation/Implementation"]="/docs/implementation"
DIR_MAPPING["/Documentation/Reference"]="/docs/reference"
DIR_MAPPING["/Documentation/System"]="/docs/system"
DIR_MAPPING["/System"]="/docs/system"
DIR_MAPPING["/System/PerformanceReports"]="/docs/system/performance"
DIR_MAPPING["/System/Scripts"]="/docs/system/scripts"

# Resources
DIR_MAPPING["/Resources/misc"]="/resources/misc"
DIR_MAPPING["/Resources/Visualizations"]="/resources/visualizations"
DIR_MAPPING["/Resources/assets"]="/resources/assets"
DIR_MAPPING["/Resources/assets/images"]="/resources/assets/images"
DIR_MAPPING["/Resources/assets/diagrams"]="/resources/assets/diagrams"
DIR_MAPPING["/Resources/assets/documents"]="/resources/assets/documents"

# Scripts
DIR_MAPPING["/Scripts"]="/resources/scripts"

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

# Generate missing migration tracker file if needed
generate_migration_tracker() {
    local tracker_file="${INVENTORY_DIR}/migration_tracker.csv"
    if [[ ! -f "$tracker_file" ]]; then
        echo "Migration tracker not found, creating empty tracker..." | tee -a "$LOG_FILE"
        mkdir -p "${INVENTORY_DIR}"
        echo "source_path,target_path,status,migration_date" > "$tracker_file"
    fi
}

# Generate unmigrated files list if it doesn't exist
generate_unmigrated_list() {
    if [[ ! -f "$UNMIGRATED_FILES" ]]; then
        echo "Unmigrated files list not found, generating..." | tee -a "$LOG_FILE"
        
        # Create inventory directory if it doesn't exist
        mkdir -p "${INVENTORY_DIR}"
        
        # Find all markdown files in original structure
        find "${VAULT_ROOT}" -type f -name "*.md" \
            ! -path "${VAULT_ROOT}/_utilities/*" \
            ! -path "${VAULT_ROOT}/content/*" \
            ! -path "${VAULT_ROOT}/resources/*" \
            ! -path "${VAULT_ROOT}/atlas/*" \
            ! -path "${VAULT_ROOT}/docs/*" \
            > "${UNMIGRATED_FILES}"
        
        echo "Found $(wc -l < "$UNMIGRATED_FILES") files to migrate" | tee -a "$LOG_FILE"
    else
        echo "Using existing unmigrated files list: $UNMIGRATED_FILES" | tee -a "$LOG_FILE"
        echo "Found $(wc -l < "$UNMIGRATED_FILES") files to process" | tee -a "$LOG_FILE"
    fi
}

# Standardize frontmatter in a file
standardize_frontmatter() {
    local file="$1"
    local temp_file="${file}.tmp"
    local has_frontmatter=false
    local creation_date=""
    local modified_date=""
    local title=""
    local status=""
    local tags=""
    
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
    
    return 0
}

# Process each file in the unmigrated list
process_unmigrated_files() {
    local tracker_file="${INVENTORY_DIR}/migration_tracker.csv"
    local count=0
    local skipped=0
    local migrated=0
    local migration_date=$(date +%Y-%m-%d\ %H:%M:%S)
    
    echo "Processing unmigrated files from: $UNMIGRATED_FILES" | tee -a "$LOG_FILE"
    
    # Process each file
    while IFS= read -r file_path; do
        # Skip if file doesn't exist
        if [[ ! -f "$file_path" ]]; then
            echo "File not found, skipping: $file_path" | tee -a "$LOG_FILE"
            ((skipped++))
            continue
        fi
        
        ((count++))
        echo "Processing file $count: $file_path" | tee -a "$LOG_FILE"
        
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
                target_dir="${VAULT_ROOT}/content/misc"
            elif [[ "$file_path" == *"/Documentation/"* ]]; then
                target_dir="${VAULT_ROOT}/docs/misc"
            elif [[ "$file_path" == *"/System/"* ]]; then
                target_dir="${VAULT_ROOT}/docs/system/misc"
            elif [[ "$file_path" == *"/Scripts/"* ]]; then
                target_dir="${VAULT_ROOT}/resources/scripts"
            elif [[ "$file_path" == *"/Resources/"* ]]; then
                target_dir="${VAULT_ROOT}/resources/misc"
            else
                # For top-level files like index.md
                target_dir="${VAULT_ROOT}/docs"
            fi
        fi
        
        # Clean the filename and create target path
        base_name=$(basename "$file_path")
        clean_name=$(clean_filename "$base_name")
        target_file="${target_dir}/${clean_name}.md"
        
        # Create target directory
        mkdir -p "$target_dir"
        
        # Copy the file
        echo "  Migrating: $file_path -> $target_file" | tee -a "$LOG_FILE"
        cp "$file_path" "$target_file"
        
        # Standardize frontmatter
        standardize_frontmatter "$target_file"
        
        # Update migration tracker
        echo "${file_path},${target_file},complete,${migration_date}" >> "$tracker_file"
        
        ((migrated++))
    done < "$UNMIGRATED_FILES"
    
    echo "Processed $count files total ($migrated migrated, $skipped skipped)" | tee -a "$LOG_FILE"
    return 0
}

# Main execution

# Ensure the inventory directory exists
mkdir -p "${INVENTORY_DIR}"

# Generate migration tracker if needed
generate_migration_tracker

# Generate unmigrated files list if needed
generate_unmigrated_list

# Create missing directories first
echo "Ensuring all target directories exist..." | tee -a "$LOG_FILE"
for dir in "${DIR_MAPPING[@]}"; do
    mkdir -p "${VAULT_ROOT}${dir}"
    echo "Ensured directory exists: ${VAULT_ROOT}${dir}" | tee -a "$LOG_FILE"
done

# Create additional common directories
mkdir -p "${VAULT_ROOT}/content/misc"
mkdir -p "${VAULT_ROOT}/docs/misc"
mkdir -p "${VAULT_ROOT}/docs/system/misc"
mkdir -p "${VAULT_ROOT}/resources/misc"

# Process unmigrated files
if process_unmigrated_files; then
    echo "Enhanced direct migration completed successfully" | tee -a "$LOG_FILE"
else
    echo "Enhanced direct migration completed with errors" | tee -a "$LOG_FILE"
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"