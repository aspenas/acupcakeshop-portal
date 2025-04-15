#!/bin/bash

# YAML standardization script
# Standardizes YAML frontmatter in Obsidian markdown files

file=$1

if [ ! -f "$file" ]; then
  echo "Error: File does not exist"
  exit 1
fi

# Check if file has YAML frontmatter
if ! grep -q "^---" "$file"; then
  echo "No YAML frontmatter found in $file"
  exit 0
fi

# Extract frontmatter
frontmatter=$(sed -n "/^---$/,/^---$/p" "$file")

# Standardize date fields
frontmatter=$(echo "$frontmatter" | sed "s/^date: /date_created: /")
frontmatter=$(echo "$frontmatter" | sed "s/^updated: /date_modified: /")

# Add status field if missing
if ! echo "$frontmatter" | grep -q "^status:"; then
  frontmatter=$(echo "$frontmatter" | sed "/^---$/a\\
status: active")
fi

# Create temporary file
tmp_file=$(mktemp)

# Write standardized frontmatter
echo "$frontmatter" > "$tmp_file"

# Append content after frontmatter
sed -n "/^---$/,/^---$/!p" "$file" | sed "1d" >> "$tmp_file"

# Replace original file
mv "$tmp_file" "$file"

echo "Standardized YAML in $file"
