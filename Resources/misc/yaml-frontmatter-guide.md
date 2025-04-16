---
title: "Document Title
Document Title             # Clear, descriptive title
Interview: John Smith
Competitor: Integra Wealth
Business Model Framework
Complete Competitor Analysis
Interview: Roquan Smith (Ravens)
Competitor: Integra Private Wealth Management
Business Model Overview"
date_created: 2025-04-15
date_modified: 2025-04-15
status: draft                       # draft, in-progress, review, completed, archived
draft                       # draft, in-progress, review, completed, archived
completed
in-progress
completed
approved
approved
tags: [tag1, tag2]
[primary-tag, secondary-tag]  # At least one tag from the tagging system
[interview, athlete, football, tax]
[competitor, analysis, financial]
[strategy, business-model, financial, planning]
[task, competitor, analysis, priority:high]
[interview, athlete, football, financial, advisor, status:completed]
[competitor, analysis, financial, investment, research, status:completed]
[strategy, business-model, financial, planning, status:completed]
---

---

---

---

---

---


This guide provides instructions on using YAML frontmatter to enhance your Obsidian notes and enable powerful queries.

## What is YAML Frontmatter?

YAML frontmatter is structured metadata at the beginning of a markdown file, enclosed between triple-dashed lines (`---`):

```yaml
---
```

This metadata provides additional information about the document that can be used for organization, filtering, and querying.

## Standard Frontmatter Fields

Every document in the vault should include these standardized fields:

### Required Fields
```yaml
---
title: "Document Title"             # Clear, descriptive title
date: 2025-04-08                    # Creation date in YYYY-MM-DD format
tags: [primary-tag, secondary-tag]  # At least one tag from the tagging system
---
```

### Optional Common Fields
```yaml
---
status: draft                       # draft, in-progress, review, completed, archived
author: "Your Name"                 # Document author or contributor
priority: high                      # high, medium, low
due: 2025-05-01                     # Due date for tasks/deliverables
last_updated: 2025-04-08            # When the document was last updated
related: ["file1.md", "file2.md"]   # Related documents
completion: 75                      # Percent complete (0-100)
---
```

## Document Type-Specific Fields

### Interviews
```yaml
---
title: "Interview: John Smith"
date: 2025-04-08
interview_date: 2025-04-01          # When the interview was conducted
sport: "Football"                   # Athlete's sport
team: "Ravens"                      # Team affiliation
position: "Linebacker"              # Player position
career_stage: "Mid-Career"          # Rookie, Early-Career, Mid-Career, Late-Career, Post-Career
key_insights: "Focus on tax planning and real estate investments"
key_themes: ["tax-planning", "real-estate", "family-office"]
tags: [interview, athlete, football, tax]
---
```

### Competitor Profiles
```yaml
---
title: "Competitor: Integra Wealth"
date: 2025-04-08
firm_type: "Boutique"               # Boutique, Institutional, Agency, Independent
primary_services: ["Investment Management", "Tax Planning", "Contract Negotiation"] 
athlete_focus: 85                   # Percentage of athlete clients (0-100)
strengths: "Deep relationships with NBA players, specialized contract expertise"
weaknesses: "Limited alternative investment options, smaller team size"
tags: [competitor, analysis, financial]
---
```

### Strategy Documents
```yaml
---
title: "Business Model Framework"
date: 2025-04-08
status: "completed"
priority: "high"
stakeholders: ["Executive Team", "Advisory Board"]
impact_level: "transformational"    # incremental, substantial, transformational
implementation_timeframe: "6 months"
tags: [strategy, business-model, financial, planning]
---
```

### Task Documents
```yaml
---
title: "Complete Competitor Analysis"
date: 2025-04-08
status: "in-progress"
due: 2025-04-30
assigned: "Patrick"
priority: "high"
dependent_tasks: ["Research Competitors", "Interview Agents"]
completion: 60
tags: [task, competitor, analysis, priority:high]
---
```

## Using Frontmatter with Dataview

Standardized frontmatter enables powerful queries using the Dataview plugin:

### Filtering by Properties
```dataview
TABLE 
  firm_type as "Type",
  primary_services as "Services",
  athlete_focus as "Athlete Focus (%)"
FROM "Athlete Financial Empowerment/01-market-research"
WHERE contains(file.tags, "#competitor") 
WHERE athlete_focus > 75
SORT athlete_focus DESC
```

### Grouping and Counting
```dataview
TABLE count() as "Count"
FROM "Athlete Financial Empowerment/02-interviews"
WHERE contains(file.tags, "#interview")
GROUP BY career_stage
SORT count() DESC
```

### Complex Queries
```dataview
TABLE
  assigned as "Owner",
  due as "Due Date",
  completion as "Progress",
  choice(completion > 75, "🟢", choice(completion > 25, "🟡", "🔴")) as "Status"
FROM "Athlete Financial Empowerment"
WHERE contains(file.tags, "#task") AND !contains(file.tags, "#completed")
WHERE due <= date(today) + dur(14 days)
SORT due ASC
```

## Implementation Steps

1. **Review Existing Documents**
   - Open each document and check for existing frontmatter
   - If none exists, add the standard required fields
   - If it exists, ensure it follows the standardized format

2. **Add Document-Specific Fields**
   - Add the relevant type-specific fields based on document type
   - Ensure consistency in field naming and formatting

3. **Create Templates**
   - Update templates to include appropriate frontmatter
   - Use Templater plugin variables to auto-fill dates and other fields

4. **Verify with Dataview**
   - Test your frontmatter using Dataview queries
   - Adjust fields as needed for consistency and query functionality

## Tips for Effective Frontmatter

1. **Be Consistent**
   - Use the same field names and formatting throughout the vault
   - Follow the conventions in this guide for all documents

2. **Keep it Relevant**
   - Only include fields that provide valuable metadata
   - Don't duplicate information that's already in the document body

3. **Use Structured Data Types**
   - Use lists for multiple values: `tags: [tag1, tag2]`
   - Use consistent date formats: `YYYY-MM-DD`
   - Use numbers for numeric values: `completion: 75`

4. **Update Regularly**
   - Keep status, completion, and last_updated fields current
   - Review and update frontmatter when document content changes

## Examples

### Interview Document
```yaml
---
title: "Interview: Roquan Smith (Ravens)"
date: 2025-04-06
interview_date: 2025-04-02
sport: "Football"
team: "Ravens"
position: "Linebacker"
career_stage: "Mid-Career"
key_insights: "Focus on trust relationship over institutional reputation"
key_themes: [fee-structure, advisor-relationship, budget-planning]
status: completed
tags: [interview, athlete, football, financial, advisor, status:completed]
---
```

### Competitor Profile
```yaml
---
title: "Competitor: Integra Private Wealth Management"
date: 2025-04-05
firm_type: "Boutique"
primary_services: ["Wealth Management", "Contract Analysis", "Tax Planning"]
athlete_focus: 85
strengths: "Founder's credibility as former NFL player creates immediate trust"
weaknesses: "Higher fee structure than institutional competitors"
status: approved
tags: [competitor, analysis, financial, investment, research, status:completed]
---
```

### Strategy Document
```yaml
---
title: "Business Model Overview"
date: 2025-04-05
status: approved
priority: high
impact_level: transformational
implementation_timeframe: "12 months"
tags: [strategy, business-model, financial, planning, status:completed]
---
```

## Troubleshooting

- **Frontmatter Not Recognized**: Ensure there are triple dashes above and below, with no spaces before the first `---`
- **Dataview Query Not Working**: Check field names for exact matches and capitalization
- **Templater Variables Not Expanding**: Verify Templater syntax and that the plugin is enabled
- **YAML Parsing Errors**: Check for proper indentation and avoid using `:` in field values

By implementing consistent YAML frontmatter throughout the vault, you'll enhance organization and enable powerful querying capabilities that will make your knowledge base more valuable and easier to navigate.
