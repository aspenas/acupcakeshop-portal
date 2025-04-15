#!/bin/bash
# Script to migrate interview content to the new structure
# Created: 2025-04-15

# Set paths
VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/02-interviews/players/active/2025/04_april"
TARGET_DIR="${VAULT_ROOT}/content/interviews/players"
LOG_FILE="${VAULT_ROOT}/_utilities/scripts/migration_log_$(date +%Y%m%d_%H%M%S).log"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Interview Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"
echo "Target directory: $TARGET_DIR" | tee -a "$LOG_FILE"

# Function to clean filename
clean_filename() {
  local filename="$1"
  # Extract the key components using simple string manipulation
  local base_name=$(basename "$filename" .md)
  local parts=(${base_name//_/ })
  
  # Format is typically: 2025-04-06_jenkins-john_raiders_defensive-tackle.md
  # We want: jenkins-john-raiders.md
  if [[ ${#parts[@]} -ge 3 ]]; then
    echo "${parts[1]}-${parts[2]}"
  else
    # Fallback to using the original filename if parsing fails
    echo "$base_name"
  fi
}

# Function to migrate a single interview
migrate_interview() {
  local source_file="$1"
  local filename=$(basename "$source_file")
  
  # Generate cleaned filename
  local clean_name=$(clean_filename "$filename")
  local target_file="${TARGET_DIR}/${clean_name}.md"
  
  echo "Migrating: $filename" | tee -a "$LOG_FILE"
  echo "  Source: $source_file" | tee -a "$LOG_FILE"
  echo "  Target: $target_file" | tee -a "$LOG_FILE"
  
  # Copy the file
  cp "$source_file" "$target_file"
  
  # Update frontmatter with date info
  local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
  if [[ -n "$creation_date" ]]; then
    sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
  fi
  
  local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
  if [[ -n "$modified_date" ]]; then
    sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
  fi
  
  echo "  Migration complete" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
}

# Find and migrate all interview files
if [[ -d "$SOURCE_DIR" ]]; then
  echo "Finding interview files in: $SOURCE_DIR" | tee -a "$LOG_FILE"
  
  # Find all markdown files in the source directory
  find "$SOURCE_DIR" -type f -name "*.md" | while read -r file; do
    migrate_interview "$file"
  done
else
  echo "Source directory not found: $SOURCE_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total files migrated: $(find "$TARGET_DIR" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"