#!/bin/bash

# Batch YAML standardization script for Obsidian vault
# Applies standardization to all markdown files in a directory

VAULT_DIR="/Users/patricksmith/obsidian/acupcakeshop"

find "$VAULT_DIR" -name "*.md" -type f -not -path "*/\.*" | while read file; do
  echo "Standardizing $file"
  bash "$VAULT_DIR/System/Scripts/Maintenance/standardize_yaml.sh" "$file"
done

echo "Batch standardization complete"
