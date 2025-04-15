# Advanced Template Implementation Guide for Athlete Financial Empowerment

Ready-to-use templates to standardize your documentation across the vault.

## Setup Instructions

1. Install the Templater plugin (preferred) or use Obsidian's core Templates plugin
2. Create a `/Templates` folder in your vault root 
3. Add these template files to that folder

## Meeting Notes Template

Create file: `/Templates/meeting-notes.md`

```markdown
---
title: "Meeting: {{title}}"
date: {{date:YYYY-MM-DD}}
participants: []
meeting_type: [Client, Team, Partner, Prospect]
follow_up_required: false
follow_up_date: 
tags: [meeting]
---

# Meeting: {{title}}

## Overview
- **Date:** {{date:YYYY-MM-DD}}
- **Time:** 
- **Location:** 
- **Meeting Type:** 
- **Participants:** 

## Agenda
1. 
2. 
3. 

## Discussion Points
### Topic 1
- 

### Topic 2
- 

## Key Insights
- 

## Action Items
- [ ] Task 1 - Owner: | Due: 
- [ ] Task 2 - Owner: | Due: 

## Follow-up
- Next meeting date:
- Items to address:

## Notes
```

## Client Analysis Template

Create file: `/Templates/client-analysis.md`

```markdown
---
title: "Client Analysis: {{title}}"
date: {{date:YYYY-MM-DD}}
client: 
sport: 
career_stage: [Rookie, Early Career, Peak Career, Late Career, Post-Career]
primary_concerns: []
key_priorities: []
risk_tolerance: [Conservative, Moderate-Conservative, Moderate, Moderate-Aggressive, Aggressive]
tags: [client, analysis]
---

# Client Analysis: {{title}}

## Client Profile
- **Name:** 
- **Sport:** 
- **Team/Organization:** 
- **Career Stage:** 
- **Age:** 
- **Years Pro:** 
- **Contract Status:** 

## Financial Snapshot
- **Current Contract:** 
- **Contract Length:** 
- **Endorsement Income:** 
- **Total Net Worth:** 
- **Cash Reserves:** 
- **Investment Portfolio:** 
- **Liabilities:** 

## Family & Support Structure
- **Family Situation:** 
- **Supporting:** 
- **Key Advisors:** 
- **Decision Makers:** 

## Current Challenges
- 

## Immediate Needs
- 

## Long-term Goals
- 

## Risk Assessment
- **Investment Risk Tolerance:** 
- **Career Risk Factors:** 
- **Family Risk Factors:** 
- **Liquidity Needs:** 

## Recommended Strategy
- **Core Focus Areas:**
  1. 
  2. 
  3. 

- **Key Action Items:**
  - [ ] 
  - [ ] 
  - [ ] 

## Implementation Timeline
- **Phase 1 (0-30 days):**
  - 

- **Phase 2 (30-90 days):**
  - 

- **Phase 3 (90+ days):**
  - 

## Notes & Observations
```

## Weekly Status Report Template

Create file: `/Templates/weekly-status.md`

```markdown
---
title: "Weekly Status: {{date:YYYY-MM-DD}}"
date: {{date:YYYY-MM-DD}}
week_number: {{date:ww}}
next_report_date: {{date+7:YYYY-MM-DD}}
tags: [status, weekly]
---

# Weekly Status Report: Week {{date:ww}}, {{date:YYYY}}

## Executive Summary
- 

## Client Highlights
- **New Clients:** 
- **Key Client Meetings:** 
- **Significant Client Developments:** 

## Project Updates
### Project 1 Name
- **Status:** [On Track/At Risk/Delayed]
- **Progress:** 
- **Next Steps:** 
- **Blockers:** 

### Project 2 Name
- **Status:** [On Track/At Risk/Delayed]
- **Progress:** 
- **Next Steps:** 
- **Blockers:** 

## Team Updates
- **Achievements:** 
- **Challenges:** 
- **Resources Needed:** 

## Market & Competitor Insights
- 

## Upcoming Events & Deadlines
- [ ] {{date+3:YYYY-MM-DD}}: 
- [ ] {{date+5:YYYY-MM-DD}}: 
- [ ] {{date+10:YYYY-MM-DD}}: 

## Focus for Next Week
1. 
2. 
3. 

## Notes
```

## Service Offering Template

Create file: `/Templates/service-offering.md`

```markdown
---
title: "Service: {{title}}"
service_category: [Financial Planning, Investment Management, Tax Planning, Estate Planning, Career Management, Education]
client_stages: [Rookie, Early Career, Peak Career, Late Career, Post-Career]
key_benefits: []
delivery_method: [One-on-one, Group, Digital, Hybrid]
tags: [service]
---

# Service: {{title}}

## Service Overview
- **Category:** 
- **Target Client Stages:** 
- **Delivery Method:** 
- **Typical Timeline:** 
- **Key Team Members:** 

## Client Need Addressed
- 

## Service Components
1. 
2. 
3. 

## Delivery Process
1. **Initial Phase:**
   - 
   
2. **Implementation Phase:**
   - 
   
3. **Ongoing Management:**
   - 

## Value Proposition
- 

## Pricing Structure
- 

## Success Metrics
- 

## Client Examples
- 

## Competitive Differentiation
- 

## Marketing Messaging
- **Key Headline:** 
- **Supporting Points:**
  - 
  - 
  - 

## Related Services
- 

## Resources Required
- 

## Notes
```

## Dashboard Template

Create file: `/Templates/dashboard.md`

```markdown
---
title: "Dashboard: {{title}}"
date_created: {{date:YYYY-MM-DD}}
last_updated: {{date:YYYY-MM-DD}}
update_frequency: [Daily, Weekly, Monthly, Quarterly]
data_sources: []
tags: [dashboard]
---

# Dashboard: {{title}}

## Overview

This dashboard provides visibility into {{title}}. Last updated: {{date:YYYY-MM-DD}}.

## Key Metrics

### Metric 1
```dataview
TABLE WITHOUT ID
  metric_name as "Metric",
  metric_value as "Value",
  trend as "Trend"
FROM "path/to/data"
WHERE metric_category = "category1"
LIMIT 5
```

### Metric 2
```dataview
TABLE WITHOUT ID
  metric_name as "Metric",
  metric_value as "Value",
  trend as "Trend"
FROM "path/to/data"
WHERE metric_category = "category2"
LIMIT 5
```

## Recent Activity

```dataview
TABLE WITHOUT ID
  file.link as "Item",
  date as "Date",
  status as "Status"
FROM "relevant/path"
WHERE contains(file.tags, "#relevant-tag")
SORT date desc
LIMIT 10
```

## Issues & Risks

- [ ] Issue 1
- [ ] Issue 2

## Next Steps

- [ ] Step 1 - Due: 
- [ ] Step 2 - Due: 

## Notes & Analysis

```

## Implementation Steps

1. Create the `/Templates` folder in your vault root
2. Add each template file with the content provided
3. If using Templater:
   - Install the plugin through Obsidian's Community Plugins
   - Configure the template folder location in Settings > Templater
   - Setup hotkeys for quick template insertion
   
4. If using core Templates plugin:
   - Enable the Templates core plugin in Settings > Core plugins
   - Set the template folder location in Settings > Templates
   
5. Customize templates with your specific fields and needs
6. Create template insertion commands or hotkeys for efficiency

## Advanced Templater Features

If using Templater, you can enhance these templates with dynamic content:

```javascript
// Current date in specific format
<% tp.date.now("YYYY-MM-DD") %>

// Date calculations (next quarter)
<% tp.date.now("YYYY-MM-DD", 90) %>

// Prompts for user input
<% tp.system.prompt("Enter client name") %>

// Generate a selection menu
<% tp.system.suggester(["Option 1", "Option 2"], ["value1", "value2"]) %>

// File title without extension
<% tp.file.title %>

// Current filename
<% tp.file.filename %>

// Insert content from another file
<% tp.file.include("[[AnotherNote]]") %>
```

Add these to your templates to create more interactive and dynamic documents.