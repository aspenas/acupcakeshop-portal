#!/usr/bin/env bash
# final_migration_cleanup.sh - Handle remaining unmigrated files
#
# This script migrates any remaining files from the original Obsidian vault that
# haven't been migrated yet and runs a final verification check.
#
# Dependencies: bash, grep, sed, awk

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
INVENTORY_DIR="${VAULT_ROOT}/_utilities/inventory"
UNMIGRATED_FILES="${INVENTORY_DIR}/unmigrated_files.txt"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/final_cleanup_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_ROOT}/_utilities/logs"
mkdir -p "${INVENTORY_DIR}"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Final Migration Cleanup Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to create a migrate a file to its new location
migrate_file() {
    local source_file="$1"
    local target_dir="$2"
    local file_name="$(basename "$source_file")"
    local target_file="${target_dir}/${file_name}"
    
    # Create the target directory if it doesn't exist
    mkdir -p "$target_dir"
    
    # Copy the file to its new location
    cp "$source_file" "$target_file"
    
    echo "  Migrated: $source_file -> $target_file" | tee -a "$LOG_FILE"
    
    # Add standard frontmatter if missing
    if ! grep -q "^---" "$target_file"; then
        local title=$(basename "$source_file" .md | tr '-' ' ' | sed 's/\<./\U&/g')
        local temp_file="${target_file}.tmp"
        
        # Add frontmatter
        {
            echo "---"
            echo "title: \"$title\""
            echo "date_created: $(date +%Y-%m-%d)"
            echo "date_modified: $(date +%Y-%m-%d)"
            echo "status: active"
            echo "tags: [migration, documentation]"
            echo "---"
            echo ""
        } > "$temp_file"
        
        # Append original content
        cat "$target_file" >> "$temp_file"
        
        # Replace original file
        mv "$temp_file" "$target_file"
        
        echo "  Added frontmatter to: $target_file" | tee -a "$LOG_FILE"
    fi
    
    return 0
}

# Function to find unmigrated files
find_unmigrated_files() {
    echo "Finding unmigrated files..." | tee -a "$LOG_FILE"
    
    # Create inventory of all original markdown files
    find "${VAULT_ROOT}" -type f -name "*.md" \
        ! -path "${VAULT_ROOT}/_utilities/*" \
        ! -path "${VAULT_ROOT}/content/*" \
        ! -path "${VAULT_ROOT}/resources/*" \
        ! -path "${VAULT_ROOT}/atlas/*" \
        ! -path "${VAULT_ROOT}/docs/*" \
        ! -path "${VAULT_ROOT}/System/Backups/*" \
        ! -path "${VAULT_ROOT}/backup_*/*" \
        > "${UNMIGRATED_FILES}"
    
    # Count unmigrated files
    local unmigrated_count=$(wc -l < "${UNMIGRATED_FILES}" | tr -d ' ')
    
    echo "Found ${unmigrated_count} unmigrated files" | tee -a "$LOG_FILE"
    return 0
}

# Function to migrate files to appropriate locations
migrate_unmigrated_files() {
    echo "Migrating remaining files..." | tee -a "$LOG_FILE"
    
    # Make sure the unmigrated files list exists
    if [[ ! -f "${UNMIGRATED_FILES}" ]]; then
        find_unmigrated_files
    fi
    
    # Count total files to migrate
    local total_files=$(wc -l < "${UNMIGRATED_FILES}" | tr -d ' ')
    local migrated_count=0
    
    # Process each file
    while IFS= read -r file; do
        # Skip if file doesn't exist
        if [[ ! -f "$file" ]]; then
            echo "File not found, skipping: $file" | tee -a "$LOG_FILE"
            continue
        fi
        
        # Determine appropriate location based on file name and path
        local target_dir=""
        
        if [[ "$file" == *"README"* || "$file" == *"readme"* ]]; then
            # It's a README file, migrate to docs
            target_dir="${VAULT_ROOT}/docs/reference"
        elif [[ "$file" == *"OBSIDIAN_PLUGINS"* ]]; then
            # It's about Obsidian plugins, migrate to docs
            target_dir="${VAULT_ROOT}/docs/reference"
        elif [[ "$file" == *"/scripts/"* ]]; then
            # It's a script documentation, migrate to resources/scripts
            target_dir="${VAULT_ROOT}/resources/scripts"
        elif [[ "$file" == *"/Resources/"* ]]; then
            # It's a resource, migrate to appropriate resources directory
            target_dir="${VAULT_ROOT}/resources/misc"
        else
            # Default target directory for unknown files
            target_dir="${VAULT_ROOT}/docs/misc"
        fi
        
        # Migrate the file
        migrate_file "$file" "$target_dir"
        ((migrated_count++))
        
    done < "${UNMIGRATED_FILES}"
    
    echo "Migrated ${migrated_count} out of ${total_files} files" | tee -a "$LOG_FILE"
    return 0
}

# Run the migration
find_unmigrated_files
migrate_unmigrated_files

# Run standardization scripts
echo "Running standardization scripts..." | tee -a "$LOG_FILE"

# Run the improved link repair script
echo "Running template-aware link repair script..." | tee -a "$LOG_FILE"
bash "${VAULT_ROOT}/_utilities/scripts/template_aware_link_repair.sh"

# Run the improved frontmatter standardization script
echo "Running advanced frontmatter standardizer script..." | tee -a "$LOG_FILE"
bash "${VAULT_ROOT}/_utilities/scripts/advanced_frontmatter_standardizer.sh"

# Run final verification
echo "Running final verification..." | tee -a "$LOG_FILE"
bash "${VAULT_ROOT}/_utilities/scripts/verify_migration.sh"

echo "========================================" | tee -a "$LOG_FILE"
echo "Final cleanup completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "Final cleanup completed. See log at: $LOG_FILE"