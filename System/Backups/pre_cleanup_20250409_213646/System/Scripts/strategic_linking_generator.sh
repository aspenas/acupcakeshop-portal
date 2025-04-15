#!/bin/bash

# Strategic Linking Generator Script
# This script scans Obsidian vault files and suggests strategic linking opportunities
# based on content relationships and the Strategic Linking Guide patterns.

VAULT_PATH="/Users/patricksmith/obsidian/acupcakeshop"
OUTPUT_FILE="$VAULT_PATH/strategic_linking_report.md"

echo "=== Strategic Linking Generator ==="
echo "Vault: $VAULT_PATH"
echo "Analyzing content relationships..."

# Create output report header
cat > "$OUTPUT_FILE" << EOL
---
title: "Strategic Linking Opportunities Report"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [report, linking, relationships, knowledge-graph]
---

# Strategic Linking Opportunities Report

This report identifies potential strategic linking opportunities across the Athlete Financial Empowerment knowledge vault based on content relationships and the patterns defined in the [Strategic Linking Guide](Documentation/Guides/strategic_linking_guide.md).

## Methodology

This analysis scans files for related keywords, topics, and concepts to identify potential linking opportunities that would enhance the knowledge graph and improve navigation. The suggestions are organized by content type and relationship strength.

## Key Linking Opportunities

EOL

# Function to find related content based on keywords
find_related_content() {
  local source_file="$1"
  local source_name=$(basename "$source_file" .md)
  local source_dir=$(dirname "$source_file")
  local source_content=$(cat "$source_file" 2>/dev/null)
  local keywords=()
  
  # Extract key terms from the file
  keywords+=( $(echo "$source_content" | grep -oE "[A-Z][a-z]+ [A-Z][a-z]+" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "athlete" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "financial" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "competitor" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "interview" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "analysis" | sort -u) )
  keywords+=( $(echo "$source_content" | grep -o "service" | sort -u) )
  
  echo "### $source_name" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "**File Path**: $source_file" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "**Potential Relationships**:" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  
  # Track if we found any relationships
  local found_relationships=0
  
  # Look for related files based on keywords
  for keyword in "${keywords[@]}"; do
    if [ -n "$keyword" ]; then
      # Find files containing this keyword, excluding the source file itself
      related_files=$(grep -l "$keyword" "$VAULT_PATH"/*.md "$VAULT_PATH"/*/*.md "$VAULT_PATH"/*/*/*.md 2>/dev/null | grep -v "$source_file")
      
      if [ -n "$related_files" ]; then
        found_relationships=1
        echo "- **Based on '$keyword'**:" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Limit to top 3 most relevant files
        count=0
        while read -r related_file; do
          if [ $count -lt 3 ]; then
            rel_path=${related_file#"$VAULT_PATH/"}
            rel_name=$(basename "$related_file" .md)
            
            # Suggest appropriate linking text
            if [[ "$rel_path" == *"dashboard"* ]]; then
              link_text="For visualization and metrics, see [[$rel_path|$rel_name Dashboard]]"
            elif [[ "$rel_path" == *"map"* ]]; then
              link_text="For conceptual overview, see [[$rel_path|$rel_name Map]]"
            elif [[ "$rel_path" == *"competitor"* ]]; then
              link_text="Related competitor information: [[$rel_path|$rel_name]]"
            elif [[ "$rel_path" == *"interview"* ]]; then
              link_text="Related interview insights: [[$rel_path|$rel_name]]"
            elif [[ "$rel_path" == *"analysis"* ]]; then
              link_text="For detailed analysis, see [[$rel_path|$rel_name]]"
            else
              link_text="Related content: [[$rel_path|$rel_name]]"
            fi
            
            echo "  - $link_text" >> "$OUTPUT_FILE"
            ((count++))
          fi
        done <<< "$related_files"
        echo "" >> "$OUTPUT_FILE"
      fi
    fi
  done
  
  # Check for bidirectional linking opportunities
  if [ $found_relationships -eq 1 ]; then
    echo "**Bidirectional Linking Recommendations**:" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "Consider adding links back to this document from the related files to strengthen the knowledge graph." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  else
    echo "No strong relationships identified. Consider manually reviewing this document for potential connections." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
  fi
  
  echo "---" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
}

# Process key document types
echo "## Competitor Profiles" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process competitor profiles
for file in "$VAULT_PATH/Athlete Financial Empowerment/01-market-research/competitor-profiles/advisors"/*.md; do
  if [[ "$file" != *"_index"* ]] && [[ "$file" != *".bak" ]]; then
    find_related_content "$file"
  fi
done

echo "## Dashboards" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process dashboards
for file in "$VAULT_PATH/Dashboards"/*.md; do
  if [[ "$file" != *"index"* ]] && [[ "$file" != *".bak" ]]; then
    find_related_content "$file"
  fi
done

echo "## Mind Maps" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Process mind maps
for file in "$VAULT_PATH/Maps"/*.md; do
  if [[ "$file" != *"README"* ]] && [[ "$file" != *".bak" ]]; then
    find_related_content "$file"
  fi
done

# Finalize the report
cat >> "$OUTPUT_FILE" << EOL
## Implementation Recommendations

1. **Prioritize High-Value Links**
   - Focus on creating links between key dashboards and their source content
   - Ensure bidirectional links between related competitor profiles
   - Connect mind maps to detailed content they visualize

2. **Add Context to Links**
   - Use descriptive link text that explains the relationship
   - Group related links in dedicated "Related Content" sections
   - Consider using admonition blocks to highlight important connections

3. **Monitor Link Effectiveness**
   - Review the graph view regularly to identify isolated content
   - Check for broken or outdated links
   - Update links as content evolves

## Next Steps

1. Review this report and identify priority linking opportunities
2. Implement suggested links, adding appropriate context
3. Run the Strategic Linking Generator again after implementing to identify new opportunities
4. Consider visualizing the enhanced knowledge graph to verify improvement

---

*Report generated on: $(date +%Y-%m-%d)*
EOL

echo "Analysis complete!"
echo "Report generated at: $OUTPUT_FILE"
echo "Next steps:"
echo "1. Review the report"
echo "2. Implement priority linking opportunities"
echo "3. Run the script again to identify new relationships"
echo "============================="