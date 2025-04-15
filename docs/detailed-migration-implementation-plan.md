---
title: "Detailed Migration Implementation Plan
Migration Verification Report
Migration Completion Report"
date_created: 2025-04-15
$(date +%Y-%m-%d)
$(date +%Y-%m-%d)
date_modified: 2025-04-15
$(date +%Y-%m-%d)
$(date +%Y-%m-%d)
status: active
active
active
tags: [documentation, migration, implementation, plan, detailed]
[migration, verification, report]
[migration, report, completion]
---

---

---

---

# Detailed Migration Implementation Plan

This document provides a comprehensive, step-by-step plan for migrating all content from the old vault structure to the new organization pattern, with specific safeguards to prevent data loss.

## Pre-Migration Preparation

### 1. Comprehensive Backup (CRITICAL)

```bash
# Create timestamped backup directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/Users/patricksmith/obsidian/acupcakeshop_backup_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"

# Create full backup
rsync -av --exclude ".git" --exclude ".obsidian/workspace" "/Users/patricksmith/obsidian/acupcakeshop/" "$BACKUP_DIR/"

# Verify backup integrity
find "$BACKUP_DIR" -type f | wc -l > "$BACKUP_DIR/file_count.txt"
find "/Users/patricksmith/obsidian/acupcakeshop" -type f | wc -l > "$BACKUP_DIR/original_file_count.txt"

# Document backup location
echo "Backup created at: $BACKUP_DIR" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/logs/backup_location_${TIMESTAMP}.txt"
```

### 2. Content Inventory

Create a complete inventory of all content files to track migration progress:

```bash
# Create inventory directory
mkdir -p "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory"

# Create content inventory files
find "/Users/patricksmith/obsidian/acupcakeshop/Athlete Financial Empowerment" -type f -name "*.md" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/athlete_content_inventory.txt"
find "/Users/patricksmith/obsidian/acupcakeshop/Resources" -type f -name "*.md" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/resources_inventory.txt"
find "/Users/patricksmith/obsidian/acupcakeshop/Documentation" -type f -name "*.md" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/documentation_inventory.txt"
find "/Users/patricksmith/obsidian/acupcakeshop/Maps" -type f -name "*.md" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/maps_inventory.txt"
find "/Users/patricksmith/obsidian/acupcakeshop/Dashboards" -type f -name "*.md" > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/dashboards_inventory.txt"
```

### 3. Migration Tracking Database

Create a tracking database to monitor the status of each file:

```bash
# Create migration tracking CSV
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/migration_tracker.csv" << EOF
source_path,target_path,status,migration_date,verified,notes
EOF

# Populate initial entries
find "/Users/patricksmith/obsidian/acupcakeshop" -type f -name "*.md" | grep -v "_utilities" | while read -r file; do
  echo "$file,,pending,,,initial inventory" >> "/Users/patricksmith/obsidian/acupcakeshop/_utilities/inventory/migration_tracker.csv"
done
```

## Phase 1: Content Migration

### 1. Interview Content Migration

```bash
# Create interview migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_all_interviews.sh" << 'EOF'
#!/bin/bash
# Script to migrate all interview content

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/02-interviews"
TARGET_DIR="${VAULT_ROOT}/content/interviews"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/interview_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Interview Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directories exist
mkdir -p "${TARGET_DIR}/players"
mkdir -p "${TARGET_DIR}/agents"
mkdir -p "${TARGET_DIR}/industry-professionals"

# Function to clean filename
clean_filename() {
  local filename="$1"
  local base_name=$(basename "$filename" .md)
  
  # Handle different naming patterns
  if [[ "$base_name" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}_ ]]; then
    # Extract components from date-prefixed name
    local parts=(${base_name//_/ })
    if [[ ${#parts[@]} -ge 3 ]]; then
      echo "${parts[1]}-${parts[2]}"
    else
      echo "$base_name"
    fi
  else
    # For names without date prefix
    echo "$base_name" | tr '_' '-'
  fi
}

# Function to determine target directory
get_target_subdir() {
  local source_path="$1"
  
  if [[ "$source_path" == *"/players/"* ]]; then
    echo "players"
  elif [[ "$source_path" == *"/agents/"* ]]; then
    echo "agents"
  elif [[ "$source_path" == *"/industry-professionals/"* ]]; then
    echo "industry-professionals"
  else
    # Default to a general directory
    echo "other"
  fi
}

# Function to migrate a single interview
migrate_interview() {
  local source_file="$1"
  local filename=$(basename "$source_file")
  
  # Skip non-content files
  if [[ "$filename" == "_index.md" || "$filename" == "README.md" ]]; then
    echo "Skipping index file: $filename" | tee -a "$LOG_FILE"
    return
  fi
  
  # Generate cleaned filename
  local clean_name=$(clean_filename "$filename")
  local subdir=$(get_target_subdir "$source_file")
  local target_file="${TARGET_DIR}/${subdir}/${clean_name}.md"
  
  echo "Migrating: $filename" | tee -a "$LOG_FILE"
  echo "  Source: $source_file" | tee -a "$LOG_FILE"
  echo "  Target: $target_file" | tee -a "$LOG_FILE"
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
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
  
  # Update tracking database
  echo "$source_file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
  
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
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_all_interviews.sh"
```

### 2. Research Content Migration

```bash
# Create research migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_research.sh" << 'EOF'
#!/bin/bash
# Script to migrate research content

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/01-market-research"
TARGET_DIR="${VAULT_ROOT}/content/research"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/research_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Research Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directories exist
mkdir -p "${TARGET_DIR}/market-analysis"
mkdir -p "${TARGET_DIR}/competitor-profiles"
mkdir -p "${TARGET_DIR}/industry-analysis"

# Function to determine target directory
get_target_subdir() {
  local source_path="$1"
  
  if [[ "$source_path" == *"/competitor-profiles/"* ]]; then
    echo "competitor-profiles"
  elif [[ "$source_path" == *"/industry-analysis/"* ]]; then
    echo "industry-analysis"
  else
    # Default to market analysis
    echo "market-analysis"
  fi
}

# Function to migrate a single research document
migrate_research() {
  local source_file="$1"
  local filename=$(basename "$source_file")
  
  # Skip index files
  if [[ "$filename" == "_index.md" || "$filename" == "README.md" ]]; then
    echo "Skipping index file: $filename" | tee -a "$LOG_FILE"
    return
  fi
  
  # Determine target directory
  local subdir=$(get_target_subdir "$source_file")
  local target_file="${TARGET_DIR}/${subdir}/$(basename "$source_file" | tr '_' '-')"
  
  echo "Migrating: $filename" | tee -a "$LOG_FILE"
  echo "  Source: $source_file" | tee -a "$LOG_FILE"
  echo "  Target: $target_file" | tee -a "$LOG_FILE"
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Copy the file
  cp "$source_file" "$target_file"
  
  # Update frontmatter
  local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
  if [[ -n "$creation_date" ]]; then
    sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
  fi
  
  local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
  if [[ -n "$modified_date" ]]; then
    sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
  fi
  
  # Update tracking database
  echo "$source_file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
  
  echo "  Migration complete" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
}

# Find and migrate all research files
if [[ -d "$SOURCE_DIR" ]]; then
  echo "Finding research files in: $SOURCE_DIR" | tee -a "$LOG_FILE"
  
  # Find all markdown files in the source directory
  find "$SOURCE_DIR" -type f -name "*.md" | while read -r file; do
    migrate_research "$file"
  done
else
  echo "Source directory not found: $SOURCE_DIR" | tee -a "$LOG_FILE"
  exit 1
fi

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total files migrated: $(find "$TARGET_DIR" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_research.sh"
```

### 3. Strategy Content Migration

```bash
# Create strategy migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_strategy.sh" << 'EOF'
#!/bin/bash
# Script to migrate strategy content

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/03-strategy"
PLANNING_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/06-planning"
TARGET_DIR="${VAULT_ROOT}/content/strategy"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/strategy_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Strategy Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directories exist
mkdir -p "${TARGET_DIR}/business-model"
mkdir -p "${TARGET_DIR}/planning"
mkdir -p "${TARGET_DIR}/implementation"

# Function to migrate strategy files
migrate_strategy_files() {
  local source_dir="$1"
  local target_subdir="$2"
  
  if [[ ! -d "$source_dir" ]]; then
    echo "Source directory not found: $source_dir" | tee -a "$LOG_FILE"
    return
  fi
  
  echo "Finding strategy files in: $source_dir" | tee -a "$LOG_FILE"
  
  # Find all markdown files
  find "$source_dir" -type f -name "*.md" | while read -r file; do
    local filename=$(basename "$file")
    
    # Skip index files
    if [[ "$filename" == "_index.md" || "$filename" == "README.md" ]]; then
      echo "Skipping index file: $filename" | tee -a "$LOG_FILE"
      continue
    fi
    
    local target_file="${TARGET_DIR}/${target_subdir}/$(basename "$file" | tr '_' '-')"
    
    echo "Migrating: $filename" | tee -a "$LOG_FILE"
    echo "  Source: $file" | tee -a "$LOG_FILE"
    echo "  Target: $target_file" | tee -a "$LOG_FILE"
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"
    
    # Copy the file
    cp "$file" "$target_file"
    
    # Update frontmatter
    local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
    if [[ -n "$creation_date" ]]; then
      sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
    fi
    
    local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
    if [[ -n "$modified_date" ]]; then
      sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
    fi
    
    # Update tracking database
    echo "$file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
    
    echo "  Migration complete" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
  done
}

# Migrate strategy content from different directories
migrate_strategy_files "$SOURCE_DIR" "business-model"
migrate_strategy_files "$PLANNING_DIR" "planning"

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total files migrated: $(find "$TARGET_DIR" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_strategy.sh"
```

### 4. Compliance Content Migration

```bash
# Create compliance migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_compliance.sh" << 'EOF'
#!/bin/bash
# Script to migrate compliance content

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIR="${VAULT_ROOT}/Athlete Financial Empowerment/05-compliance"
TARGET_DIR="${VAULT_ROOT}/content/compliance"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/compliance_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Compliance Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directories exist
mkdir -p "${TARGET_DIR}/registration"
mkdir -p "${TARGET_DIR}/advisory-board"
mkdir -p "${TARGET_DIR}/standards"

# Function to migrate compliance files
migrate_compliance() {
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Source directory not found: $SOURCE_DIR" | tee -a "$LOG_FILE"
    return
  fi
  
  echo "Finding compliance files in: $SOURCE_DIR" | tee -a "$LOG_FILE"
  
  # Find all markdown files
  find "$SOURCE_DIR" -type f -name "*.md" | while read -r file; do
    local filename=$(basename "$file")
    
    # Skip index files
    if [[ "$filename" == "_index.md" || "$filename" == "README.md" ]]; then
      echo "Skipping index file: $filename" | tee -a "$LOG_FILE"
      continue
    fi
    
    # Determine target subdirectory based on content
    local target_subdir="standards"
    if [[ "$filename" == *"registration"* ]]; then
      target_subdir="registration"
    elif [[ "$filename" == *"advisory"* || "$filename" == *"board"* ]]; then
      target_subdir="advisory-board"
    fi
    
    local target_file="${TARGET_DIR}/${target_subdir}/$(basename "$file" | tr '_' '-')"
    
    echo "Migrating: $filename" | tee -a "$LOG_FILE"
    echo "  Source: $file" | tee -a "$LOG_FILE"
    echo "  Target: $target_file" | tee -a "$LOG_FILE"
    
    # Create target directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"
    
    # Copy the file
    cp "$file" "$target_file"
    
    # Update frontmatter
    local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
    if [[ -n "$creation_date" ]]; then
      sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
    fi
    
    local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
    if [[ -n "$modified_date" ]]; then
      sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
    fi
    
    # Update tracking database
    echo "$file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
    
    echo "  Migration complete" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
  done
}

# Migrate all compliance files
migrate_compliance

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total files migrated: $(find "$TARGET_DIR" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_compliance.sh"
```

## Phase 2: Resource Consolidation

### 1. Template Consolidation

```bash
# Create template migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_templates.sh" << 'EOF'
#!/bin/bash
# Script to consolidate and migrate templates

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIRS=(
  "${VAULT_ROOT}/Athlete Financial Empowerment/_templates"
  "${VAULT_ROOT}/Resources/Templates"
  "${VAULT_ROOT}/Templates"
)
TARGET_DIR="${VAULT_ROOT}/resources/templates"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/template_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Template Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to determine template category
get_template_category() {
  local filename="$1"
  local source_path="$2"
  
  # Determine category based on filename and path
  if [[ "$filename" == *"interview"* || "$source_path" == *"/interview"* ]]; then
    echo "interview"
  elif [[ "$filename" == *"competitor"* || "$source_path" == *"/analysis"* ]]; then
    echo "analysis"
  elif [[ "$filename" == *"task"* || "$source_path" == *"/task"* ]]; then
    echo "task"
  elif [[ "$filename" == *"project"* || "$source_path" == *"/project"* ]]; then
    echo "project"
  else
    echo "system"
  fi
}

# Function to migrate a template
migrate_template() {
  local source_file="$1"
  local filename=$(basename "$source_file")
  
  # Skip non-template files
  if [[ "$filename" == "_index.md" || "$filename" == "README.md" ]]; then
    echo "Skipping index file: $filename" | tee -a "$LOG_FILE"
    return
  fi
  
  # Determine template category
  local category=$(get_template_category "$filename" "$source_file")
  local target_file="${TARGET_DIR}/${category}/$(basename "$source_file" | tr '_' '-')"
  
  # Check if target already exists (from another source)
  if [[ -f "$target_file" ]]; then
    echo "Template already exists: $target_file" | tee -a "$LOG_FILE"
    echo "  Skipping duplicate from: $source_file" | tee -a "$LOG_FILE"
    
    # Update tracking database with skipped status
    echo "$source_file,$target_file,skipped (duplicate),$(date +%Y-%m-%d),no,Duplicate template" >> "$TRACKER"
    return
  fi
  
  echo "Migrating: $filename" | tee -a "$LOG_FILE"
  echo "  Source: $source_file" | tee -a "$LOG_FILE"
  echo "  Target: $target_file" | tee -a "$LOG_FILE"
  echo "  Category: $category" | tee -a "$LOG_FILE"
  
  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target_file")"
  
  # Copy the file
  cp "$source_file" "$target_file"
  
  # Update frontmatter
  local creation_date=$(grep -m 1 "date_created:" "$target_file" | awk '{print $2}')
  if [[ -z "$creation_date" ]]; then
    # If missing, insert after title
    sed -i '' '/^title:/a\\ndate_created: '"$(date +%Y-%m-%d)"'' "$target_file"
  fi
  
  local modified_date=$(grep -m 1 "date_modified:" "$target_file" | awk '{print $2}')
  if [[ -z "$modified_date" ]]; then
    # If missing, insert after date_created
    sed -i '' '/^date_created:/a\\ndate_modified: '"$(date +%Y-%m-%d)"'' "$target_file"
  fi
  
  # Update tracking database
  echo "$source_file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
  
  echo "  Migration complete" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
}

# Process each source directory
for source_dir in "${SOURCE_DIRS[@]}"; do
  if [[ -d "$source_dir" ]]; then
    echo "Processing templates from: $source_dir" | tee -a "$LOG_FILE"
    
    # Find all markdown files recursively
    find "$source_dir" -type f -name "*.md" | while read -r file; do
      migrate_template "$file"
    done
  else
    echo "Source directory not found: $source_dir" | tee -a "$LOG_FILE"
  fi
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total templates migrated: $(find "$TARGET_DIR" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_templates.sh"
```

### 2. Dashboard and Map Migration

```bash
# Create dashboard and map migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_dashboards_maps.sh" << 'EOF'
#!/bin/bash
# Script to migrate dashboards and maps

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
DASHBOARD_SOURCES=(
  "${VAULT_ROOT}/Dashboards"
  "${VAULT_ROOT}/Resources/Dashboards"
)
MAP_SOURCES=(
  "${VAULT_ROOT}/Maps"
  "${VAULT_ROOT}/Resources/Maps"
)
DASHBOARD_TARGET="${VAULT_ROOT}/resources/dashboards"
MAP_TARGET="${VAULT_ROOT}/atlas"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/dashboard_map_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Dashboard and Map Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Function to migrate dashboards
migrate_dashboards() {
  echo "Migrating dashboards..." | tee -a "$LOG_FILE"
  
  # Process each source directory
  for source_dir in "${DASHBOARD_SOURCES[@]}"; do
    if [[ -d "$source_dir" ]]; then
      echo "Processing dashboards from: $source_dir" | tee -a "$LOG_FILE"
      
      # Find all markdown files recursively
      find "$source_dir" -type f -name "*.md" | while read -r file; do
        local filename=$(basename "$file")
        
        # Skip README files
        if [[ "$filename" == "README.md" ]]; then
          echo "Skipping README: $filename" | tee -a "$LOG_FILE"
          continue
        fi
        
        # Determine dashboard category
        local category="project"
        if [[ "$filename" == *"competitor"* ]]; then
          category="competitor"
        elif [[ "$filename" == *"interview"* ]]; then
          category="interview"
        elif [[ "$filename" == *"financial"* ]]; then
          category="financial"
        fi
        
        local target_file="${DASHBOARD_TARGET}/${category}/$(basename "$file" | tr '_' '-')"
        
        # Check if target already exists (from another source)
        if [[ -f "$target_file" ]]; then
          echo "Dashboard already exists: $target_file" | tee -a "$LOG_FILE"
          echo "  Skipping duplicate from: $file" | tee -a "$LOG_FILE"
          
          # Update tracking database with skipped status
          echo "$file,$target_file,skipped (duplicate),$(date +%Y-%m-%d),no,Duplicate dashboard" >> "$TRACKER"
          continue
        }
        
        echo "Migrating: $filename" | tee -a "$LOG_FILE"
        echo "  Source: $file" | tee -a "$LOG_FILE"
        echo "  Target: $target_file" | tee -a "$LOG_FILE"
        
        # Create target directory if it doesn't exist
        mkdir -p "$(dirname "$target_file")"
        
        # Copy the file
        cp "$file" "$target_file"
        
        # Update frontmatter
        local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
        if [[ -n "$creation_date" ]]; then
          sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
        fi
        
        local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
        if [[ -n "$modified_date" ]]; then
          sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
        fi
        
        # Update tracking database
        echo "$file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
        
        echo "  Migration complete" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
      done
    else
      echo "Source directory not found: $source_dir" | tee -a "$LOG_FILE"
    fi
  done
}

# Function to migrate maps
migrate_maps() {
  echo "Migrating maps..." | tee -a "$LOG_FILE"
  
  # Process each source directory
  for source_dir in "${MAP_SOURCES[@]}"; do
    if [[ -d "$source_dir" ]]; then
      echo "Processing maps from: $source_dir" | tee -a "$LOG_FILE"
      
      # Find all markdown files recursively
      find "$source_dir" -type f -name "*.md" | while read -r file; do
        local filename=$(basename "$file")
        
        # Skip README files
        if [[ "$filename" == "README.md" ]]; then
          echo "Skipping README: $filename" | tee -a "$LOG_FILE"
          continue
        fi
        
        local target_file="${MAP_TARGET}/$(basename "$file" | tr '_' '-')"
        
        # Check if target already exists (from another source)
        if [[ -f "$target_file" ]]; then
          echo "Map already exists: $target_file" | tee -a "$LOG_FILE"
          echo "  Skipping duplicate from: $file" | tee -a "$LOG_FILE"
          
          # Update tracking database with skipped status
          echo "$file,$target_file,skipped (duplicate),$(date +%Y-%m-%d),no,Duplicate map" >> "$TRACKER"
          continue
        }
        
        echo "Migrating: $filename" | tee -a "$LOG_FILE"
        echo "  Source: $file" | tee -a "$LOG_FILE"
        echo "  Target: $target_file" | tee -a "$LOG_FILE"
        
        # Copy the file
        cp "$file" "$target_file"
        
        # Update frontmatter
        local creation_date=$(grep -m 1 "created:" "$target_file" | awk '{print $2}')
        if [[ -n "$creation_date" ]]; then
          sed -i '' "s/^created: .*$/date_created: $creation_date/" "$target_file"
        fi
        
        local modified_date=$(grep -m 1 "modified:" "$target_file" | awk '{print $2}')
        if [[ -n "$modified_date" ]]; then
          sed -i '' "s/^modified: .*$/date_modified: $modified_date/" "$target_file"
        fi
        
        # Update tracking database
        echo "$file,$target_file,completed,$(date +%Y-%m-%d),no," >> "$TRACKER"
        
        echo "  Migration complete" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
      done
    else
      echo "Source directory not found: $source_dir" | tee -a "$LOG_FILE"
    fi
  done
}

# Run migrations
migrate_dashboards
migrate_maps

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total dashboards migrated: $(find "$DASHBOARD_TARGET" -type f -name "*.md" | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "Total maps migrated: $(find "$MAP_TARGET" -type f -name "*.md" | wc -l | grep -v "README\|interview-map\|research-map\|strategy-map\|compliance-map" | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_dashboards_maps.sh"
```

### 3. Asset Migration

```bash
# Create asset migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_assets.sh" << 'EOF'
#!/bin/bash
# Script to migrate assets (images, documents, diagrams)

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
SOURCE_DIRS=(
  "${VAULT_ROOT}/attachments"
  "${VAULT_ROOT}/Resources/Attachments"
)
TARGET_DIR="${VAULT_ROOT}/resources/assets"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/asset_migration_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Asset Migration Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Ensure target directories exist
mkdir -p "${TARGET_DIR}/images"
mkdir -p "${TARGET_DIR}/documents"
mkdir -p "${TARGET_DIR}/diagrams"

# Function to determine asset type
get_asset_type() {
  local filename="$1"
  local ext="${filename##*.}"
  
  # Convert extension to lowercase
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  
  # Categorize by extension
  if [[ "$ext" == "png" || "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "gif" || "$ext" == "svg" ]]; then
    echo "images"
  elif [[ "$ext" == "pdf" || "$ext" == "docx" || "$ext" == "xlsx" || "$ext" == "pptx" || "$ext" == "txt" ]]; then
    echo "documents"
  elif [[ "$ext" == "excalidraw" || "$filename" == *"diagram"* || "$filename" == *"chart"* ]]; then
    echo "diagrams"
  else
    # Default to documents
    echo "documents"
  fi
}

# Function to migrate assets
migrate_assets() {
  # Process each source directory
  for source_dir in "${SOURCE_DIRS[@]}"; do
    if [[ -d "$source_dir" ]]; then
      echo "Processing assets from: $source_dir" | tee -a "$LOG_FILE"
      
      # Find all files recursively (excluding .md files which are handled separately)
      find "$source_dir" -type f ! -name "*.md" | while read -r file; do
        local filename=$(basename "$file")
        
        # Skip dotfiles and temporary files
        if [[ "$filename" == .* || "$filename" == *~ ]]; then
          echo "Skipping system file: $filename" | tee -a "$LOG_FILE"
          continue
        fi
        
        # Determine asset type
        local asset_type=$(get_asset_type "$filename")
        local target_file="${TARGET_DIR}/${asset_type}/${filename}"
        
        # Check if target already exists
        if [[ -f "$target_file" ]]; then
          echo "Asset already exists: $target_file" | tee -a "$LOG_FILE"
          echo "  Comparing with: $file" | tee -a "$LOG_FILE"
          
          # Check if files are identical
          if cmp -s "$file" "$target_file"; then
            echo "  Files are identical, skipping" | tee -a "$LOG_FILE"
            echo "$file,$target_file,skipped (identical),$(date +%Y-%m-%d),yes,Files are identical" >> "$TRACKER"
            continue
          else
            # Rename target with a timestamp suffix
            local new_name="${filename%.*}_$(date +%Y%m%d%H%M%S).${filename##*.}"
            target_file="${TARGET_DIR}/${asset_type}/${new_name}"
            echo "  Files differ, renaming to: $new_name" | tee -a "$LOG_FILE"
          fi
        fi
        
        echo "Migrating: $filename" | tee -a "$LOG_FILE"
        echo "  Source: $file" | tee -a "$LOG_FILE"
        echo "  Target: $target_file" | tee -a "$LOG_FILE"
        echo "  Type: $asset_type" | tee -a "$LOG_FILE"
        
        # Create target directory if it doesn't exist
        mkdir -p "$(dirname "$target_file")"
        
        # Copy the file
        cp "$file" "$target_file"
        
        # Update tracking database
        echo "$file,$target_file,completed,$(date +%Y-%m-%d),yes," >> "$TRACKER"
        
        echo "  Migration complete" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
      done
    else
      echo "Source directory not found: $source_dir" | tee -a "$LOG_FILE"
    fi
  done
}

# Run asset migration
migrate_assets

echo "========================================" | tee -a "$LOG_FILE"
echo "Migration completed: $(date)" | tee -a "$LOG_FILE"
echo "Total images migrated: $(find "${TARGET_DIR}/images" -type f | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "Total documents migrated: $(find "${TARGET_DIR}/documents" -type f | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "Total diagrams migrated: $(find "${TARGET_DIR}/diagrams" -type f | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/migrate_assets.sh"
```

## Phase 3: Link Updating

```bash
# Create link updating script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/update_links.sh" << 'EOF'
#!/bin/bash
# Script to update internal links in all markdown files

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/link_update_$(date +%Y%m%d_%H%M%S).log"
TRACKER="${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Link Update Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Build a mapping of old paths to new paths
echo "Building path mapping..." | tee -a "$LOG_FILE"
MAPPING_FILE="${VAULT_ROOT}/_utilities/inventory/path_mapping.csv"
echo "old_path,new_path" > "$MAPPING_FILE"

# Extract mappings from the migration tracker
grep ",completed," "$TRACKER" | cut -d ',' -f 1,2 >> "$MAPPING_FILE"

# Function to update links in a markdown file
update_links() {
  local file="$1"
  local updated=false
  local content=$(<"$file")
  local original_content="$content"
  local changes=0
  
  echo "Processing links in: $file" | tee -a "$LOG_FILE"
  
  # Process each line in the mapping file (skip header)
  tail -n +2 "$MAPPING_FILE" | while IFS=, read -r old_path new_path; do
    # Skip if either path is empty
    if [[ -z "$old_path" || -z "$new_path" ]]; then
      continue
    fi
    
    # Get basenames for linking
    local old_basename=$(basename "$old_path" .md)
    local new_basename=$(basename "$new_path" .md)
    local new_path_no_ext="${new_path%.md}"
    
    # Convert paths relative to vault root for linking
    local old_rel_path="${old_path#$VAULT_ROOT/}"
    local new_rel_path="${new_path#$VAULT_ROOT/}"
    local new_rel_path_no_ext="${new_rel_path%.md}"
    
    # Update direct file links: [[old_file]] to [[new_file]]
    if [[ "$content" == *"[[$old_basename]]"* ]]; then
      content="${content//\[\[$old_basename\]\]/\[\[$new_basename\]\]}"
      ((changes++))
      echo "  Updated simple link: [[$old_basename]] -> [[$new_basename]]" | tee -a "$LOG_FILE"
    fi
    
    # Update links with display text: [[old_file|text]] to [[new_file|text]]
    if [[ "$content" == *"[[$old_basename|"* ]]; then
      content="${content//\[\[$old_basename|/\[\[$new_basename|}"
      ((changes++))
      echo "  Updated display link: [[$old_basename|...]] -> [[$new_basename|...]]" | tee -a "$LOG_FILE"
    fi
    
    # Update path links: [[old/path/file]] to [[new/path/file]]
    if [[ "$content" == *"[[$old_rel_path_no_ext]]"* ]]; then
      content="${content//\[\[$old_rel_path_no_ext\]\]/\[\[$new_rel_path_no_ext\]\]}"
      ((changes++))
      echo "  Updated path link: [[$old_rel_path_no_ext]] -> [[$new_rel_path_no_ext]]" | tee -a "$LOG_FILE"
    fi
    
    # Update path links with display text: [[old/path/file|text]] to [[new/path/file|text]]
    if [[ "$content" == *"[[$old_rel_path_no_ext|"* ]]; then
      content="${content//\[\[$old_rel_path_no_ext|/\[\[$new_rel_path_no_ext|}"
      ((changes++))
      echo "  Updated path display link: [[$old_rel_path_no_ext|...]] -> [[$new_rel_path_no_ext|...]]" | tee -a "$LOG_FILE"
    fi
  done
  
  # Write updated content if changes were made
  if [[ "$content" != "$original_content" ]]; then
    echo "$content" > "$file"
    echo "  Updated $changes links in $file" | tee -a "$LOG_FILE"
    return 0
  else
    echo "  No links updated in $file" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Find all markdown files in the new structure
echo "Updating links in all markdown files..." | tee -a "$LOG_FILE"
find "$VAULT_ROOT" -type f -name "*.md" -not -path "*/_utilities/*" -not -path "*/System/*" -not -path "*/Scripts/*" | while read -r file; do
  update_links "$file"
done

echo "========================================" | tee -a "$LOG_FILE"
echo "Link update completed: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/update_links.sh"
```

## Phase 4: Verification and Validation

```bash
# Create verification script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/verify_migration.sh" << 'EOF'
#!/bin/bash
# Script to verify migration completeness and correctness

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_ROOT}/_utilities/logs/verification_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="${VAULT_ROOT}/docs/migration_verification_report.md"

# Create log header
echo "========================================" | tee -a "$LOG_FILE"
echo "Migration Verification Log" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Check for unmigrated content
check_unmigrated_content() {
  echo "Checking for unmigrated content..." | tee -a "$LOG_FILE"
  
  # Get list of all original markdown files
  find "/Users/patricksmith/obsidian/acupcakeshop" -type f -name "*.md" \
    -not -path "*/_utilities/*" \
    -not -path "*/System/Backups/*" \
    -not -path "*/backup_*/*" \
    -not -path "*/content/*" \
    -not -path "*/resources/*" \
    -not -path "*/atlas/*" \
    -not -path "*/docs/*" \
    > "${VAULT_ROOT}/_utilities/inventory/original_files.txt"
  
  # Get list of all migrated files from the tracker
  cut -d ',' -f 1 "${VAULT_ROOT}/_utilities/inventory/migration_tracker.csv" | grep -v "^source_path$" \
    > "${VAULT_ROOT}/_utilities/inventory/migrated_files.txt"
  
  # Find unmigrated files
  grep -v -f "${VAULT_ROOT}/_utilities/inventory/migrated_files.txt" "${VAULT_ROOT}/_utilities/inventory/original_files.txt" \
    > "${VAULT_ROOT}/_utilities/inventory/unmigrated_files.txt"
  
  # Count unmigrated files
  local unmigrated_count=$(wc -l < "${VAULT_ROOT}/_utilities/inventory/unmigrated_files.txt" | tr -d ' ')
  echo "Found $unmigrated_count unmigrated files" | tee -a "$LOG_FILE"
  
  # Report first 10 unmigrated files
  if [[ $unmigrated_count -gt 0 ]]; then
    echo "First 10 unmigrated files:" | tee -a "$LOG_FILE"
    head -n 10 "${VAULT_ROOT}/_utilities/inventory/unmigrated_files.txt" | tee -a "$LOG_FILE"
  fi
  
  return $unmigrated_count
}

# Check for broken links
check_broken_links() {
  echo "Checking for broken links..." | tee -a "$LOG_FILE"
  
  # Create file for results
  local broken_links_file="${VAULT_ROOT}/_utilities/inventory/broken_links.txt"
  > "$broken_links_file"
  
  # Find all markdown files in the new structure
  find "$VAULT_ROOT" -type f -name "*.md" \
    -not -path "*/_utilities/*" \
    -not -path "*/System/*" \
    -not -path "*/Scripts/*" | while read -r file; do
    
    # Extract all wikilinks
    grep -o '\[\[[^]]*\]\]' "$file" | while read -r link; do
      # Clean up the link
      link=${link#\[\[}
      link=${link%\]\]}
      
      # Handle links with display text
      if [[ "$link" == *"|"* ]]; then
        link=${link%%|*}
      fi
      
      # Handle links with .md extension
      if [[ "$link" != *".md" && "$link" != *"http"* ]]; then
        link="${link}.md"
      fi
      
      # Handle absolute paths
      if [[ "$link" == /* ]]; then
        target="${VAULT_ROOT}${link}"
      else
        # Handle relative paths
        target="$(dirname "$file")/${link}"
      fi
      
      # Check if target exists
      if [[ ! -f "$target" && "$link" != *"http"* ]]; then
        echo "$file: Broken link to $link" >> "$broken_links_file"
      fi
    done
  done
  
  # Count broken links
  local broken_count=$(wc -l < "$broken_links_file" | tr -d ' ')
  echo "Found $broken_count broken links" | tee -a "$LOG_FILE"
  
  # Report first 10 broken links
  if [[ $broken_count -gt 0 ]]; then
    echo "First 10 broken links:" | tee -a "$LOG_FILE"
    head -n 10 "$broken_links_file" | tee -a "$LOG_FILE"
  fi
  
  return $broken_count
}

# Verify frontmatter standardization
check_frontmatter() {
  echo "Checking for non-standard frontmatter..." | tee -a "$LOG_FILE"
  
  # Create file for results
  local frontmatter_issues="${VAULT_ROOT}/_utilities/inventory/frontmatter_issues.txt"
  > "$frontmatter_issues"
  
  # Find all markdown files in the new structure
  find "$VAULT_ROOT" -type f -name "*.md" \
    -not -path "*/_utilities/*" \
    -not -path "*/System/*" \
    -not -path "*/Scripts/*" | while read -r file; do
    
    # Check for required frontmatter fields
    local has_title=$(grep -c "^title:" "$file")
    local has_date_created=$(grep -c "^date_created:" "$file")
    local has_date_modified=$(grep -c "^date_modified:" "$file")
    local has_status=$(grep -c "^status:" "$file")
    local has_tags=$(grep -c "^tags:" "$file")
    
    # Report missing fields
    if [[ $has_title -eq 0 || $has_date_created -eq 0 || $has_date_modified -eq 0 || $has_status -eq 0 || $has_tags -eq 0 ]]; then
      echo "$file: Missing required frontmatter fields" >> "$frontmatter_issues"
      [[ $has_title -eq 0 ]] && echo "  - Missing title" >> "$frontmatter_issues"
      [[ $has_date_created -eq 0 ]] && echo "  - Missing date_created" >> "$frontmatter_issues"
      [[ $has_date_modified -eq 0 ]] && echo "  - Missing date_modified" >> "$frontmatter_issues"
      [[ $has_status -eq 0 ]] && echo "  - Missing status" >> "$frontmatter_issues"
      [[ $has_tags -eq 0 ]] && echo "  - Missing tags" >> "$frontmatter_issues"
    fi
  done
  
  # Count frontmatter issues
  local issues_count=$(grep -c "Missing required" "$frontmatter_issues")
  echo "Found $issues_count files with frontmatter issues" | tee -a "$LOG_FILE"
  
  # Report first 10 issues
  if [[ $issues_count -gt 0 ]]; then
    echo "First 10 frontmatter issues:" | tee -a "$LOG_FILE"
    head -n 30 "$frontmatter_issues" | tee -a "$LOG_FILE"
  fi
  
  return $issues_count
}

# Run verification checks
unmigrated_count=0
broken_links_count=0
frontmatter_issues_count=0

check_unmigrated_content
unmigrated_count=$?

check_broken_links
broken_links_count=$?

check_frontmatter
frontmatter_issues_count=$?

# Generate verification report
cat > "$REPORT_FILE" << EOF
---
title: "Migration Verification Report"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [migration, verification, report]
---

# Migration Verification Report

## Overview

This report provides verification results for the vault migration process. It identifies any issues that need to be addressed to ensure a complete and correct migration.

## Verification Summary

- **Unmigrated Content**: $unmigrated_count files
- **Broken Links**: $broken_links_count links
- **Frontmatter Issues**: $frontmatter_issues_count files

## Detailed Findings

### Unmigrated Content

The following files have not been migrated from the original structure:

$(if [[ $unmigrated_count -gt 0 ]]; then
  echo "\`\`\`"
  cat "${VAULT_ROOT}/_utilities/inventory/unmigrated_files.txt" | head -n 20
  if [[ $unmigrated_count -gt 20 ]]; then
    echo "... and $(($unmigrated_count - 20)) more files"
  fi
  echo "\`\`\`"
else
  echo "All content has been successfully migrated."
fi)

### Broken Links

The following broken links were detected in the migrated content:

$(if [[ $broken_links_count -gt 0 ]]; then
  echo "\`\`\`"
  cat "${VAULT_ROOT}/_utilities/inventory/broken_links.txt" | head -n 20
  if [[ $broken_links_count -gt 20 ]]; then
    echo "... and $(($broken_links_count - 20)) more broken links"
  fi
  echo "\`\`\`"
else
  echo "No broken links were detected."
fi)

### Frontmatter Issues

The following files have issues with their frontmatter:

$(if [[ $frontmatter_issues_count -gt 0 ]]; then
  echo "\`\`\`"
  cat "${VAULT_ROOT}/_utilities/inventory/frontmatter_issues.txt" | head -n 30
  if [[ $frontmatter_issues_count -gt 10 ]]; then
    echo "... and $(($frontmatter_issues_count - 10)) more files with issues"
  fi
  echo "\`\`\`"
else
  echo "All files have standardized frontmatter."
fi)

## Recommendations

$(if [[ $unmigrated_count -gt 0 || $broken_links_count -gt 0 || $frontmatter_issues_count -gt 0 ]]; then
  echo "The following actions are recommended to address the issues found:"
  
  if [[ $unmigrated_count -gt 0 ]]; then
    echo "1. **Migrate Remaining Content**: Review the list of unmigrated files and migrate them to the new structure."
  fi
  
  if [[ $broken_links_count -gt 0 ]]; then
    echo "2. **Fix Broken Links**: Update the links to point to the correct files in the new structure."
  fi
  
  if [[ $frontmatter_issues_count -gt 0 ]]; then
    echo "3. **Standardize Frontmatter**: Add missing frontmatter fields to the identified files."
  fi
else
  echo "The migration has been completed successfully with no issues detected. No further action is required."
fi)

## Verification Process

This report was generated automatically by the \`verify_migration.sh\` script on $(date). The script performed the following checks:

1. Identified unmigrated content by comparing original files with the migration tracker
2. Searched for broken wiki-style links in all markdown files
3. Checked for required frontmatter fields in all markdown files

## Next Steps

$(if [[ $unmigrated_count -gt 0 || $broken_links_count -gt 0 || $frontmatter_issues_count -gt 0 ]]; then
  echo "After addressing the issues identified in this report, re-run the verification script to confirm all issues have been resolved."
else
  echo "The migration is complete and verified. Users can now fully transition to using the new vault structure."
fi)

---

*Report generated: $(date)*
EOF

echo "========================================" | tee -a "$LOG_FILE"
echo "Verification completed: $(date)" | tee -a "$LOG_FILE"
echo "Verification report generated: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/verify_migration.sh"
```

## Phase 5: Master Migration Script

```bash
# Create master migration script
cat > "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/run_full_migration.sh" << 'EOF'
#!/bin/bash
# Master script to run the complete migration process

VAULT_ROOT="/Users/patricksmith/obsidian/acupcakeshop"
LOG_DIR="${VAULT_ROOT}/_utilities/logs"
MASTER_LOG="${LOG_DIR}/master_migration_$(date +%Y%m%d_%H%M%S).log"

# Create logs directory
mkdir -p "$LOG_DIR"

# Function to run a script and log its output
run_script() {
  local script="$1"
  local description="$2"
  
  echo -e "\n========================================" | tee -a "$MASTER_LOG"
  echo "RUNNING: $description" | tee -a "$MASTER_LOG"
  echo "SCRIPT: $script" | tee -a "$MASTER_LOG"
  echo "STARTED: $(date)" | tee -a "$MASTER_LOG"
  echo "========================================" | tee -a "$MASTER_LOG"
  
  # Run the script and capture its output
  if [ -f "$script" ]; then
    "$script" 2>&1 | tee -a "$MASTER_LOG"
    local status=${PIPESTATUS[0]}
    echo -e "\n----------------------------------------" | tee -a "$MASTER_LOG"
    if [ $status -eq 0 ]; then
      echo "STATUS: SUCCESS" | tee -a "$MASTER_LOG"
    else
      echo "STATUS: FAILED (Exit code: $status)" | tee -a "$MASTER_LOG"
      echo "WARNING: Migration process continued despite failure" | tee -a "$MASTER_LOG"
    fi
  else
    echo "ERROR: Script not found: $script" | tee -a "$MASTER_LOG"
  fi
  
  echo "COMPLETED: $(date)" | tee -a "$MASTER_LOG"
  echo "========================================" | tee -a "$MASTER_LOG"
}

# Start master log
echo "========================================" | tee -a "$MASTER_LOG"
echo "MASTER MIGRATION PROCESS" | tee -a "$MASTER_LOG"
echo "STARTED: $(date)" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"

# Create comprehensive backup
echo "Creating comprehensive backup..." | tee -a "$MASTER_LOG"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/Users/patricksmith/obsidian/acupcakeshop_backup_${TIMESTAMP}"
mkdir -p "$BACKUP_DIR"
rsync -av --exclude ".git" --exclude ".obsidian/workspace" "/Users/patricksmith/obsidian/acupcakeshop/" "$BACKUP_DIR/"
echo "Backup created at: $BACKUP_DIR" | tee -a "$MASTER_LOG"
echo "Backup location recorded in: ${LOG_DIR}/backup_location_${TIMESTAMP}.txt" | tee -a "$MASTER_LOG"
echo "Backup created at: $BACKUP_DIR" > "${LOG_DIR}/backup_location_${TIMESTAMP}.txt"

# Phase 1: Content Migration
echo -e "\n========================================" | tee -a "$MASTER_LOG"
echo "PHASE 1: CONTENT MIGRATION" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"

run_script "${VAULT_ROOT}/_utilities/scripts/migrate_all_interviews.sh" "Migrate Interview Content"
run_script "${VAULT_ROOT}/_utilities/scripts/migrate_research.sh" "Migrate Research Content"
run_script "${VAULT_ROOT}/_utilities/scripts/migrate_strategy.sh" "Migrate Strategy Content"
run_script "${VAULT_ROOT}/_utilities/scripts/migrate_compliance.sh" "Migrate Compliance Content"

# Phase 2: Resource Consolidation
echo -e "\n========================================" | tee -a "$MASTER_LOG"
echo "PHASE 2: RESOURCE CONSOLIDATION" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"

run_script "${VAULT_ROOT}/_utilities/scripts/migrate_templates.sh" "Migrate Templates"
run_script "${VAULT_ROOT}/_utilities/scripts/migrate_dashboards_maps.sh" "Migrate Dashboards and Maps"
run_script "${VAULT_ROOT}/_utilities/scripts/migrate_assets.sh" "Migrate Assets"

# Phase 3: Link Updating
echo -e "\n========================================" | tee -a "$MASTER_LOG"
echo "PHASE 3: LINK UPDATING" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"

run_script "${VAULT_ROOT}/_utilities/scripts/update_links.sh" "Update Internal Links"

# Phase 4: Verification
echo -e "\n========================================" | tee -a "$MASTER_LOG"
echo "PHASE 4: VERIFICATION" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"

run_script "${VAULT_ROOT}/_utilities/scripts/verify_migration.sh" "Verify Migration"

# Create migration completion report
cat > "${VAULT_ROOT}/docs/migration_completion_report.md" << END
---
title: "Migration Completion Report"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [migration, report, completion]
---

# Migration Completion Report

## Overview

The vault migration process has been completed. This report provides a summary of the migration process and its outcomes.

## Migration Summary

- **Started**: $(date)
- **Backup Location**: $BACKUP_DIR
- **Migration Log**: $MASTER_LOG

## Migration Statistics

- **Content Files Migrated**: $(find "${VAULT_ROOT}/content" -type f -name "*.md" | wc -l | tr -d ' ') files
- **Templates Migrated**: $(find "${VAULT_ROOT}/resources/templates" -type f -name "*.md" | wc -l | tr -d ' ') files
- **Dashboards Migrated**: $(find "${VAULT_ROOT}/resources/dashboards" -type f -name "*.md" | wc -l | tr -d ' ') files
- **Maps Migrated**: $(find "${VAULT_ROOT}/atlas" -type f -name "*.md" | wc -l | tr -d ' ') files
- **Assets Migrated**: $(find "${VAULT_ROOT}/resources/assets" -type f | wc -l | tr -d ' ') files

## New Vault Structure

\`\`\`
/acupcakeshop/
├── atlas/                        # Knowledge maps and navigation
├── content/                      # Primary knowledge content
│   ├── interviews/               # Interview content
│   ├── research/                 # Research content
│   ├── strategy/                 # Strategic planning
│   └── compliance/               # Regulatory compliance
├── resources/                    # Supporting materials
│   ├── templates/                # Templates
│   ├── assets/                   # Media and attachments
│   └── dashboards/               # Performance dashboards
├── _utilities/                   # Non-content utilities
│   ├── scripts/                  # Automation scripts
│   └── config/                   # Configuration files
└── docs/                         # Vault documentation
\`\`\`

## Verification Results

Please refer to the [Migration Verification Report](migration_verification_report.md) for detailed verification results.

## Next Steps

1. **Review Verification Report**: Address any issues identified in the verification report
2. **User Transition**: Begin using the new vault structure for all content creation and editing
3. **Obsidian Restart**: Restart Obsidian to ensure it recognizes the new structure
4. **Legacy Content**: The original content structure has been preserved in the backup directory

## Conclusion

The vault has been successfully reorganized into a more logical, maintainable structure that separates content from utilities and provides clear navigation pathways. This new structure should improve performance, readability, and maintainability going forward.

---

*Report generated: $(date)*
END

echo -e "\n========================================" | tee -a "$MASTER_LOG"
echo "MIGRATION PROCESS COMPLETED" | tee -a "$MASTER_LOG"
echo "COMPLETED: $(date)" | tee -a "$MASTER_LOG"
echo "MASTER LOG: $MASTER_LOG" | tee -a "$MASTER_LOG"
echo "COMPLETION REPORT: ${VAULT_ROOT}/docs/migration_completion_report.md" | tee -a "$MASTER_LOG"
echo "========================================" | tee -a "$MASTER_LOG"
EOF

chmod +x "/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/run_full_migration.sh"
```

## Migration Plan Summary

### Before Running the Migration

1. **Create Backup**:
   - A comprehensive backup will be created at the beginning of the migration
   - Backup location will be recorded in the logs
   - All original content will be preserved

2. **Migration Tracking**:
   - A detailed tracking database will record migration status
   - Each file will be tracked from source to destination
   - Migration verification will check for missing content

### Step-by-Step Migration Process

1. **Phase 1: Content Migration**:
   - Migrate interview content to content/interviews/
   - Migrate research content to content/research/
   - Migrate strategy content to content/strategy/
   - Migrate compliance content to content/compliance/

2. **Phase 2: Resource Consolidation**:
   - Consolidate templates from all sources to resources/templates/
   - Migrate dashboards and maps to their respective directories
   - Organize assets by type (images, documents, diagrams)

3. **Phase 3: Link Updating**:
   - Update internal links to point to new file locations
   - Preserve all cross-references and link text

4. **Phase 4: Verification**:
   - Check for unmigrated content
   - Identify broken links
   - Verify frontmatter standardization
   - Generate verification report

### Running the Migration

The full migration can be executed by running:

```bash
/Users/patricksmith/obsidian/acupcakeshop/_utilities/scripts/run_full_migration.sh
```

This script will:
1. Create a comprehensive backup
2. Execute all migration scripts in the correct order
3. Update links to maintain references
4. Verify the migration and generate reports
5. Create a migration completion report

### Safety Measures

1. **Comprehensive Backup**:
   - Full backup created before any changes
   - Backup location recorded for recovery if needed

2. **Non-Destructive Process**:
   - Original content is never deleted during migration
   - Files are copied to new locations, not moved

3. **Detailed Logging**:
   - Each step of the migration is logged
   - Migration tracker records status of each file

4. **Verification Checks**:
   - Automated verification identifies any issues
   - Verification report provides guidance for resolving issues

Would you like me to implement a specific part of this plan or make any adjustments to the approach?
