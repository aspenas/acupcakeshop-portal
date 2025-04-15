#!/bin/bash
# Standardize YAML frontmatter across vault files
# Run with: ./standardize_yaml.sh <directory>

DIR=${1:-/Users/patricksmith/obsidian/acupcakeshop}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/Users/patricksmith/obsidian/acupcakeshop/backup_${TIMESTAMP}"
LOG_FILE="/Users/patricksmith/obsidian/acupcakeshop/yaml_standardization_${TIMESTAMP}.log"

# Create backup
mkdir -p "$BACKUP_DIR"
echo "Creating backup at $BACKUP_DIR"
cp -r "$DIR" "$BACKUP_DIR"

# Process each markdown file
find "$DIR" -name "*.md" | while read -r file; do
  # Skip files in backup directory
  if [[ "$file" == *"$BACKUP_DIR"* ]]; then
    continue
  fi

  echo "Processing $file" >> "$LOG_FILE"
  
  # Check if file has YAML frontmatter
  if grep -q "^---" "$file"; then
    # File has frontmatter
    echo "  Has frontmatter" >> "$LOG_FILE"
    
    # Convert to standard format
    # This is a simplified version, actual implementation would use more sophisticated parsing
    sed -i '' 's/^title: *"\(.*\)"/title: "\1"/' "$file"
    sed -i '' 's/^created:/date_created:/' "$file"
    sed -i '' 's/^modified:/date_modified:/' "$file"
    
    # Ensure date_created exists
    if ! grep -q "date_created:" "$file"; then
      # Add date_created after title
      sed -i '' '/^title:/a\
date_created: '$(date +%Y-%m-%d)'' "$file"
    fi
    
    # Ensure date_modified exists
    if ! grep -q "date_modified:" "$file"; then
      # Add date_modified after date_created or title
      if grep -q "date_created:" "$file"; then
        sed -i '' '/^date_created:/a\
date_modified: '$(date +%Y-%m-%d)'' "$file"
      else
        sed -i '' '/^title:/a\
date_modified: '$(date +%Y-%m-%d)'' "$file"
      fi
    fi
    
    # Ensure status exists
    if ! grep -q "status:" "$file"; then
      sed -i '' '/^date_modified:/a\
status: active' "$file"
    fi
    
  else
    # File has no frontmatter
    echo "  No frontmatter, adding" >> "$LOG_FILE"
    
    # Extract title from first heading or filename
    TITLE=$(grep -m 1 "^# " "$file" | sed 's/^# //' || basename "$file" .md | sed 's/-/ /g' | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    
    # Create temporary file with new frontmatter
    TEMP_FILE=$(mktemp)
    echo "---" > "$TEMP_FILE"
    echo "title: \"$TITLE\"" >> "$TEMP_FILE"
    echo "date_created: $(date +%Y-%m-%d)" >> "$TEMP_FILE"
    echo "date_modified: $(date +%Y-%m-%d)" >> "$TEMP_FILE"
    echo "status: active" >> "$TEMP_FILE"
    echo "---" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    cat "$file" >> "$TEMP_FILE"
    
    # Replace original file
    mv "$TEMP_FILE" "$file"
  fi
done

echo "Standardization complete. Log file: $LOG_FILE"