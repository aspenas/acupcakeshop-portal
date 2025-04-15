---
title: "Interview with John Smith
Elite Athlete Advisors
Investment Management Service Offering
Contract Structure Analysis
Understanding Endorsement Valuation
Develop Competitor Comparison Matrix"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [interviews, athlete, basketball, rookie, complete]
[market-research, profile, boutique, complete]
[service-model, process, investment, in-progress]
[analysis, summary, contract, complete]
[education, resource, endorsement, athlete, complete]
[admin, task, market-research, priority, in-progress]
---

---


A comprehensive tagging framework designed specifically for your Athlete Financial Empowerment vault.

## Tagging Framework Overview

```
# Primary Category Tags
#market-research    #interviews    #service-model    #analysis    #education    #admin

# Content Type Tags
#profile    #summary    #dashboard    #template    #meeting    #resource    #process

# Status Tags
#draft    #in-progress    #complete    #needs-review    #archived

# Subject Matter Tags
#investment    #tax    #estate    #contract    #endorsement    #education    #retirement

# Entity Type Tags
#athlete    #advisor    #agent    #family    #team    #institution    #boutique

# Project Management Tags
#task    #milestone    #blocker    #priority    #next-action
```

## Implementation Instructions

1. Create a new note in your vault root called `tag-system.md`
2. Copy the tagging framework above into this file for reference
3. Begin implementing tags in your existing notes using the following guidelines

## Tagging Guidelines

### Tag Usage Rules
- Apply 3-5 tags per note for optimal organization
- Always include at least one primary category tag
- Combine tags from different categories for precise filtering
- Use lowercase, hyphenated format consistently
- Don't create new tags outside the framework without updating the system doc

### Tag Application Patterns

#### For Interview Notes
```yaml
---
```

#### For Competitor Profiles
```yaml
---
title: "Elite Athlete Advisors"
date: 2025-03-15
tags: [market-research, profile, boutique, complete]
---
```

#### For Service Model Documents
```yaml
---
title: "Investment Management Service Offering"
date: 2025-03-20
tags: [service-model, process, investment, in-progress]
---
```

#### For Analysis Documents
```yaml
---
title: "Contract Structure Analysis"
date: 2025-03-22
tags: [analysis, summary, contract, complete]
---
```

#### For Educational Content
```yaml
---
title: "Understanding Endorsement Valuation"
date: 2025-03-25
tags: [education, resource, endorsement, athlete, complete]
---
```

#### For Tasks and Action Items
```yaml
---
title: "Develop Competitor Comparison Matrix"
date: 2025-04-02
tags: [admin, task, market-research, priority, in-progress]
---
```

## Dataview Queries Using Tags

Add these queries to your dashboards to surface content using the tagging system:

### Tasks Dashboard Query
```dataview
TABLE WITHOUT ID
  file.link as "Task",
  file.ctime as "Created",
  choice(contains(file.tags, "#in-progress"), "🔄", choice(contains(file.tags, "#complete"), "✅", "📝")) as "Status"
FROM #task
SORT file.ctime desc
```

### Content by Category Query
```dataview
TABLE WITHOUT ID
  file.link as "Document",
  map(filter(file.tags, (t) => startswith(t, "#")), (t) => substring(t, 1)) as "Tags"
FROM #market-research
GROUP BY choice(contains(file.tags, "#profile"), "Profiles", choice(contains(file.tags, "#summary"), "Summaries", "Other"))
```

### Content Status Overview
```dataview
TABLE WITHOUT ID
  length(rows) as "Count"
FROM ""
WHERE contains(file.tags, tag)
GROUP BY choice(contains(file.tags, "#draft"), "📝 Draft", 
         choice(contains(file.tags, "#in-progress"), "🔄 In Progress", 
         choice(contains(file.tags, "#complete"), "✅ Complete", 
         choice(contains(file.tags, "#needs-review"), "👀 Needs Review", 
         choice(contains(file.tags, "#archived"), "🗄️ Archived", 
         "🏷️ Untagged")))))
SORT length(rows) desc
```

## Tag Migration Plan

Follow this process to implement the tagging system across your vault:

1. **Phase 1: Core Structure**
   - Add primary category tags to all existing files
   - Add status tags to all existing files
   - Create the tag system reference file

2. **Phase 2: Detailed Classification**
   - Add content type tags to all files
   - Add subject matter tags to key documents
   - Add entity type tags where applicable

3. **Phase 3: Advanced Organization**
   - Add project management tags to action items
   - Create tag-based dashboards using Dataview
   - Review and refine tags for consistency

4. **Phase 4: Maintenance**
   - Review tag usage monthly
   - Update the tag system as needs evolve
   - Document tag definitions for team clarity

## Best Practices for Ongoing Tag Management

1. **Start with structure**
   - Always apply primary category and status tags at minimum
   - Consider what questions you'll want to answer with your tags

2. **Maintain consistency**
   - Use established tags rather than creating similar variants
   - Follow the formatting conventions exactly

3. **Purpose-driven tagging**
   - Tag for retrieval and organization purposes
   - Consider both browsing and searching use cases

4. **Evolve thoughtfully**
   - Document new tags when you create them
   - Review periodically to consolidate similar tags

5. **Integrate with workflows**
   - Use templates to ensure consistent tag application
   - Create dashboards based on tag combinations

## Tag-Based Dashboards to Create

1. **Project Status Dashboard**
   - Filter by #task and status tags
   - Group by priority or category

2. **Content Inventory Dashboard**
   - Group by primary category and content type
   - Show completion status

3. **Subject Matter Dashboard**
   - Filter by subject tags
   - Group by content type

4. **Entity-Focused Dashboard**
   - Filter by entity type tags
   - Show related content across categories
