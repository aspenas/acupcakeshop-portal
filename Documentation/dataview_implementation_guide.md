# Dataview Implementation Guide for Athlete Financial Empowerment Vault

This guide provides ready-to-use Dataview queries specifically designed for your Athlete Financial Empowerment vault.

## Setup Instructions

1. Ensure the Dataview plugin is installed in Obsidian
2. Create a "Dashboards" folder in your vault root
3. Add these query examples to your index files or dedicated dashboard notes

## Interview Insights Dashboard

Create a new file: `/Dashboards/interview-insights.md`

```dataview
TABLE WITHOUT ID
  file.link as "Interview",
  sport as "Sport",
  career_stage as "Career Stage",
  key_insights as "Key Insights"
FROM "Athlete Financial Empowerment/02-interviews"
WHERE contains(file.tags, "#interview") 
SORT date desc
```

## Competitor Analysis Dashboard

Create a new file: `/Dashboards/competitor-analysis.md`

```dataview
TABLE WITHOUT ID
  file.link as "Competitor",
  firm_type as "Type",
  primary_services as "Services",
  athlete_focus as "Athlete Focus (%)",
  strengths as "Key Strengths"
FROM "Athlete Financial Empowerment/01-market-research/competitor-profiles"
SORT athlete_focus desc
```

## Project Status Tracker

Create a new file: `/Dashboards/project-status.md`

```dataview
TABLE WITHOUT ID
  file.link as "Task",
  status as "Status",
  due as "Due Date",
  assigned as "Owner"
FROM "Athlete Financial Empowerment"
WHERE contains(file.tags, "#task") 
SORT due asc
```

## Content Gap Analysis

Add to `/Athlete Financial Empowerment/_index.md`:

```dataview
LIST WITHOUT ID "**Missing:** " + meta(section).missing
FROM "Athlete Financial Empowerment"
WHERE contains(file.tags, "#section") AND meta(section).missing
```

## Recent Activity Tracker

Create a new file: `/Dashboards/recent-activity.md`:

```dataview
TABLE WITHOUT ID
  file.link as "Document",
  file.mtime as "Last Modified"
FROM "Athlete Financial Empowerment"
SORT file.mtime desc
LIMIT 20
```

## Implementation Steps

1. Add YAML frontmatter to your notes to enable these queries:

For interviews:
```yaml
---
sport: "Basketball"
career_stage: "Rookie"
key_insights: "Needs guidance on first contract, concerned about family financial pressure"
date: 2023-04-15
tags: [interview, basketball, rookie]
---
```

For competitor profiles:
```yaml
---
firm_type: "Boutique"
primary_services: ["Investment Management", "Tax Planning", "Contract Negotiation"]
athlete_focus: 85
strengths: "Deep relationships with NBA players, specialized contract expertise"
tags: [competitor, boutique]
---
```

For tasks:
```yaml
---
status: "In Progress"
due: 2025-04-30
assigned: "Patrick"
tags: [task, high-priority]
---
```

For section indexes:
```yaml
---
section:
  missing: "Need competitor comparison matrix"
tags: [section, market-research]
---
```

2. Create each dashboard file shown above
3. Test queries and adjust as needed

## Advanced Queries

### Service Offering Comparison

```dataview
TABLE WITHOUT ID
  file.link as "Competitor",
  choice(contains(primary_services, "Investment Management"), "✓", "✗") as "Investment",
  choice(contains(primary_services, "Tax Planning"), "✓", "✗") as "Tax",
  choice(contains(primary_services, "Estate Planning"), "✓", "✗") as "Estate",
  choice(contains(primary_services, "Contract Negotiation"), "✓", "✗") as "Contract"
FROM "Athlete Financial Empowerment/01-market-research/competitor-profiles"
```

### Career Stage Distribution

```dataview
TABLE WITHOUT ID
  career_stage as "Career Stage",
  count(career_stage) as "Count"
FROM "Athlete Financial Empowerment/02-interviews"
WHERE contains(file.tags, "#interview")
GROUP BY career_stage
