---
title: "Document Title
Analysis: Topic
Interview: Name (Organization)
Competitor Profile: Organization Name
Dashboard: Topic
Map of Content: Topic
Strategy: Topic
Task: Description
'Competitor Profile: Example'
Competitor Profile: Example"
date_created: YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
2025-04-05
2025-04-05
date_modified: YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
YYYY-MM-DD
2025-04-06
2025-04-06
status: [draft, in_progress, review, complete]
[draft, in_progress, review, complete]
[draft, in_progress, review, complete]
[draft, in_progress, review, complete]
[draft, in_progress, review, complete]
[not_started, in_progress, review, complete, blocked]
approved
complete
tags: [tag1, tag2, tag3]
[analysis, specific-tags]
[interview, specific-tags]
[competitor, profile, specific-tags]
[dashboard, specific-tags]
[MOC, navigation, specific-tags]
[strategy, specific-tags]
[task, specific-tags]

[competitor, profile, analysis, advisor]
---

---

---

---

---

---


This document defines the standard YAML frontmatter structure for different document types in the Athlete Financial Empowerment Obsidian vault.

## Core Fields for All Documents

All documents should include these required fields:

```yaml
---
```

## Document Type-Specific Fields

### Analysis Documents

```yaml
---
title: "Analysis: Topic"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: [draft, in_progress, review, complete]
analysis_type: [competitor, market, service, strategy]
subject: "Subject being analyzed"
methodology: "Brief methodology description"
author: "Author name"
tags: [analysis, specific-tags]
---
```

### Interview Documents

```yaml
---
title: "Interview: Name (Organization)"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: [draft, in_progress, review, complete]
interview_date: YYYY-MM-DD
interviewee: "Person's name"
organization: "Organization name"
role: "Person's role"
interview_type: [athlete, agent, advisor, team-personnel]
career_stage: [rookie, early-career, mid-career, late-career, post-career] # For athletes only
key_topics: [topic1, topic2, topic3]
tags: [interview, specific-tags]
---
```

### Competitor Profile Documents

```yaml
---
title: "Competitor Profile: Organization Name"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: [draft, in_progress, review, complete]
competitor_type: [advisor, agent, institution, boutique, agent-affiliated]
primary_services: [service1, service2, service3]
athlete_focus: Percentage # 0-100
key_strengths: [strength1, strength2]
founded: YYYY
location: "Primary location"
tags: [competitor, profile, specific-tags]
---
```

### Dashboard Documents

```yaml
---
title: "Dashboard: Topic"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
update_frequency: [daily, weekly, monthly]
dashboard_type: [analysis, status, metrics]
data_sources: [source1, source2, source3]
tags: [dashboard, specific-tags]
---
```

### Map of Content (MOC) Documents

```yaml
---
title: "Map of Content: Topic"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
map_category: [topic, project, resource]
map_scope: "Brief description of scope"
tags: [MOC, navigation, specific-tags]
---
```

### Strategy Documents

```yaml
---
title: "Strategy: Topic"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: [draft, in_progress, review, complete]
strategy_type: [business-model, positioning, implementation]
timeline: [short-term, mid-term, long-term]
stakeholders: [stakeholder1, stakeholder2]
priority: [high, medium, low]
tags: [strategy, specific-tags]
---
```

### Task & Project Documents

```yaml
---
title: "Task: Description"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: [not_started, in_progress, review, complete, blocked]
due_date: YYYY-MM-DD
assignee: "Person's name"
priority: [high, medium, low]
related_project: "Project name"
dependencies: [dependency1, dependency2]
tags: [task, specific-tags]
---
```

## Field Definitions

### Core Fields

- **title**: Clear, descriptive title following type-specific format
- **date_created**: Date the document was first created (YYYY-MM-DD)
- **date_modified**: Date the document was last updated (YYYY-MM-DD)
- **status**: Current document status
- **tags**: Array of relevant tags, following tag hierarchy

### Special Field Formats

- **Dates**: Always use YYYY-MM-DD format (e.g., 2025-04-08)
- **Arrays**: Use [item1, item2, item3] format
- **Percentages**: Use numeric values without the % symbol (e.g., 75 instead of 75%)
- **Status**: Use snake_case for multi-word statuses (e.g., in_progress, not in progress)

## Implementation Process

To standardize YAML frontmatter across the vault:

1. Create a new document using the appropriate template
2. For existing documents, update the frontmatter to match the standard
3. Run the YAML standardization script to audit compliance
4. Fix any inconsistencies identified by the script
5. Perform regular audits to maintain standardization

## YAML Standardization Script

```bash
#!/bin/bash

VAULT_PATH="/Users/patricksmith/obsidian/acupcakeshop"

# Function to check YAML frontmatter in markdown files
check_frontmatter() {
  echo "Checking YAML frontmatter in markdown files..."
  echo
  
  # Find all markdown files
  find "$VAULT_PATH" -name "*.md" | while read -r file; do
    # Extract YAML frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$file")
    
    # Skip files without frontmatter
    if [ -z "$frontmatter" ]; then
      echo "⚠️  No frontmatter found in: $file"
      continue
    fi
    
    # Check for required fields
    missing_fields=""
    
    # Check title
    if ! echo "$frontmatter" | grep -q "title:"; then
      missing_fields="$missing_fields title"
    fi
    
    # Check date_created
    if ! echo "$frontmatter" | grep -q "date_created:" && ! echo "$frontmatter" | grep -q "created:"; then
      missing_fields="$missing_fields date_created"
    fi
    
    # Check modified date
    if ! echo "$frontmatter" | grep -q "date_modified:" && ! echo "$frontmatter" | grep -q "modified:"; then
      missing_fields="$missing_fields date_modified"
    fi
    
    # Check tags
    if ! echo "$frontmatter" | grep -q "tags:"; then
      missing_fields="$missing_fields tags"
    fi
    
    # Report missing fields
    if [ -n "$missing_fields" ]; then
      echo "❌ Missing fields in: $file"
      echo "   Missing:$missing_fields"
    fi
    
    # Check for field naming inconsistencies
    if echo "$frontmatter" | grep -q "created:" && ! echo "$frontmatter" | grep -q "date_created:"; then
      echo "⚠️  Non-standard field 'created' in: $file (use 'date_created')"
    fi
    
    if echo "$frontmatter" | grep -q "modified:" && ! echo "$frontmatter" | grep -q "date_modified:"; then
      echo "⚠️  Non-standard field 'modified' in: $file (use 'date_modified')"
    fi
    
    # Check date format
    date_fields=$(echo "$frontmatter" | grep -E "(date_created|date_modified|created|modified|date|due_date):")
    
    if echo "$date_fields" | grep -qv -E "[0-9]{4}-[0-9]{2}-[0-9]{2}"; then
      echo "⚠️  Non-standard date format in: $file (use YYYY-MM-DD)"
    fi
  done
}

# Run the checks
check_frontmatter
```

## YAML Conversion Examples

### Before Standardization

```yaml
---
date_created: 2025-04-05
date_modified: 2025-04-06
status: approved
tags:
- analysis
- competitor
title: 'Competitor Profile: Example'
---
```

### After Standardization

```yaml
---
title: "Competitor Profile: Example"
date_created: 2025-04-05
date_modified: 2025-04-06
status: complete
competitor_type: advisor
primary_services: [investment, tax, estate]
athlete_focus: 75
tags: [competitor, profile, analysis, advisor]
---
```

## Best Practices

1. **Consistency**: Always use the standard format for your document type
2. **Completeness**: Include all required fields
3. **Clarity**: Use descriptive values that enhance searchability
4. **Maintenance**: Update the modified date whenever making significant changes
5. **Specificity**: Use specific rather than general tags
6. **Hierarchy**: Follow the established tag hierarchy

By following these standards, we'll ensure consistent metadata across the vault, which improves searchability, filtering, and database-like functionality through Dataview queries.
