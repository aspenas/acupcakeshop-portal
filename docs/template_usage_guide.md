---
title: "Template Usage Guide
Template Name"
date_created: 2025-04-15
YYYY-MM-DD
date_modified: 2025-04-15
YYYY-MM-DD
status: template
tags: [[template, documentation, guide, template-type, templates]]]
---

---

---

---

# Template Usage Guide

## Overview

Templates are essential for maintaining consistency across the Athlete Financial Empowerment vault. This guide explains how to use, customize, and create templates for different content types.

## Template Directory Structure

All templates are centralized in the `/resources/templates/` directory, organized by content type:

```
/resources/templates/
├── interview/             # Interview templates
│   ├── player-interview-template.md
│   ├── agent-interview-template.md
│   └── industry-professional-template.md
├── analysis/              # Analysis templates
│   ├── competitor-profile-template.md
│   ├── market-analysis-template.md
│   └── service-comparison-template.md
├── task/                  # Task templates
│   ├── task-template.md
│   └── project-task-template.md
└── project/               # Project templates
    ├── weekly-status-template.md
    └── project-plan-template.md
```

## Using Templates

### Basic Template Usage

1. **Navigate to template**: Find the appropriate template in the `/resources/templates/` directory
2. **Copy template**: Copy the template file content
3. **Create new file**: Create a new file in the appropriate content directory
4. **Paste and customize**: Paste the template content and customize as needed
5. **Update frontmatter**: Update title, dates, status, and tags
6. **Remove instructions**: Delete any instructional comments

### Template Variables

Templates may contain variables in double curly braces. Replace these with your content:

```
{{VARIABLE_NAME}} → Your specific content
```

Common variables:

- `{{TITLE}}`: Document title
- `{{DATE}}`: Current date
- `{{INTERVIEWEE}}`: Name of interviewee
- `{{TASK_NAME}}`: Name of task
- `{{PROJECT_NAME}}`: Name of project

## Template Types and Usage

### Interview Templates

#### Player Interview Template

**Location**: `/resources/templates/interview/player-interview-template.md`

**Purpose**: Standardized format for player interviews

**Structure**:
- Interview metadata (date, location, interviewer)
- Player background
- Interview questions and responses
- Key insights
- Action items

**Example usage**:
```markdown
# Interview: {{PLAYER_NAME}} - {{TEAM}} {{POSITION}}

## Interview Details
- **Date**: {{DATE}}
- **Location**: {{LOCATION}}
- **Interviewer**: {{INTERVIEWER}}
- **Interviewee**: {{PLAYER_NAME}}

## Player Background
{{PLAYER_BACKGROUND}}

## Interview Summary
{{INTERVIEW_SUMMARY}}

## Key Questions and Responses
### Financial Planning
{{FINANCIAL_PLANNING_RESPONSES}}

### Investment Strategy
{{INVESTMENT_STRATEGY_RESPONSES}}

### Post-Career Planning
{{POST_CAREER_PLANNING_RESPONSES}}

## Key Insights
- {{INSIGHT_1}}
- {{INSIGHT_2}}
- {{INSIGHT_3}}

## Action Items
- {{ACTION_ITEM_1}}
- {{ACTION_ITEM_2}}
```

#### Agent Interview Template

**Location**: `/resources/templates/interview/agent-interview-template.md`

**Purpose**: Standardized format for agent interviews

**Structure**:
- Interview metadata
- Agent background and client portfolio
- Interview questions and responses
- Key insights
- Action items

### Analysis Templates

#### Competitor Profile Template

**Location**: `/resources/templates/analysis/competitor-profile-template.md`

**Purpose**: Standardized format for analyzing competitors

**Structure**:
- Company overview
- Service offerings
- Pricing model
- Client base
- Strengths and weaknesses
- Competitive positioning

**Example usage**:
```markdown
# Competitor Profile: {{COMPANY_NAME}}

## Company Overview
- **Name**: {{COMPANY_NAME}}
- **Founded**: {{FOUNDING_YEAR}}
- **Location**: {{HEADQUARTERS}}
- **Size**: {{COMPANY_SIZE}}

## Service Offerings
{{SERVICE_OFFERINGS}}

## Pricing Model
{{PRICING_MODEL}}

## Client Base
{{CLIENT_BASE}}

## Strengths
- {{STRENGTH_1}}
- {{STRENGTH_2}}
- {{STRENGTH_3}}

## Weaknesses
- {{WEAKNESS_1}}
- {{WEAKNESS_2}}
- {{WEAKNESS_3}}

## Competitive Positioning
{{COMPETITIVE_POSITIONING}}

## Strategic Implications
{{STRATEGIC_IMPLICATIONS}}
```

#### Market Analysis Template

**Location**: `/resources/templates/analysis/market-analysis-template.md`

**Purpose**: Standardized format for market analysis

**Structure**:
- Market overview
- Market size and growth
- Customer segments
- Competitors
- Market trends
- Opportunities and challenges

### Task Templates

#### Task Template

**Location**: `/resources/templates/task/task-template.md`

**Purpose**: Standardized format for tracking tasks

**Structure**:
- Task details (name, description, due date)
- Status and priority
- Related tasks and dependencies
- Notes and progress updates

**Example usage**:
```markdown
# Task: {{TASK_NAME}}

## Task Details
- **Description**: {{TASK_DESCRIPTION}}
- **Due Date**: {{DUE_DATE}}
- **Assigned To**: {{ASSIGNED_TO}}
- **Priority**: {{PRIORITY}} (High/Medium/Low)
- **Status**: {{STATUS}} (Not Started/In Progress/Complete)

## Related Tasks
- [[{{RELATED_TASK_1}}]]
- [[{{RELATED_TASK_2}}]]

## Dependencies
- [[{{DEPENDENCY_1}}]]
- [[{{DEPENDENCY_2}}]]

## Notes
{{NOTES}}

## Progress Updates
- {{DATE}}: {{UPDATE}}
```

### Project Templates

#### Weekly Status Template

**Location**: `/resources/templates/project/weekly-status-template.md`

**Purpose**: Standardized format for weekly status reports

**Structure**:
- Week overview
- Accomplishments
- Challenges
- Next steps
- Resources needed

**Example usage**:
```markdown
# Weekly Status: Week of {{DATE}}

## Overview
{{WEEKLY_OVERVIEW}}

## Accomplishments
- {{ACCOMPLISHMENT_1}}
- {{ACCOMPLISHMENT_2}}
- {{ACCOMPLISHMENT_3}}

## Challenges
- {{CHALLENGE_1}}
- {{CHALLENGE_2}}

## Next Steps
- {{NEXT_STEP_1}}
- {{NEXT_STEP_2}}
- {{NEXT_STEP_3}}

## Resources Needed
{{RESOURCES_NEEDED}}
```

## Customizing Templates

### Modifying Existing Templates

To customize an existing template:

1. **Copy the template**: Make a copy of the original template
2. **Modify as needed**: Add, remove, or change sections
3. **Preserve variables**: Keep the variable format consistent
4. **Update frontmatter**: Ensure frontmatter is complete
5. **Document changes**: Add comments explaining significant changes

### Creating New Templates

To create a new template:

1. **Choose a base**: Start with an existing template if possible
2. **Structure content**: Organize content in logical sections
3. **Add variables**: Use consistent variable formatting
4. **Add frontmatter**: Include all required frontmatter fields
5. **Add instructions**: Include clear usage instructions
6. **Place in template directory**: Save in appropriate template directory

### Template Frontmatter

All templates should have this frontmatter:

```yaml
---
title: "Template Name"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: template
tags: [template, template-type]
---
```

## Template Variables Best Practices

### Variable Formatting

- **Use ALL_CAPS**: Makes variables easy to identify
- **Use underscores for spaces**: `TASK_NAME` instead of `TASK-NAME`
- **Use descriptive names**: `PLAYER_BACKGROUND` instead of `BG`
- **Use consistent syntax**: Double curly braces `{{VARIABLE_NAME}}`

### Variable Usage Instructions

Include instructions for each variable:

```markdown
<!-- 
INSTRUCTIONS:
- {{PLAYER_NAME}}: Full name of the player
- {{TEAM}}: Current team name
- {{POSITION}}: Player's position
-->
```

## Advanced Template Usage

### Template Sections

Templates are organized into sections:

1. **Frontmatter**: Metadata at the top of the file
2. **Instructions**: Usage guidelines (to be removed)
3. **Structure**: The content organization
4. **Variables**: Placeholders for custom content

### Template Inheritance

Templates can build on other templates:

1. **Base templates**: General structure for a content type
2. **Specialized templates**: Extensions of base templates for specific uses
3. **Custom templates**: Further customized for specific needs

### Template Maintenance

Regular maintenance is important:

1. **Review templates**: Periodically review all templates
2. **Update as needed**: Modify based on user feedback
3. **Document changes**: Keep a record of significant changes
4. **Version control**: Consider versioning for major changes

## Practical Examples

### Example 1: Creating an Interview Record

1. Copy content from `/resources/templates/interview/player-interview-template.md`
2. Create new file at `/content/interviews/players/active/2025/04_april/2025-04-15-doe-john-chiefs-quarterback.md`
3. Replace all variables:
   - `{{PLAYER_NAME}}` → "John Doe"
   - `{{TEAM}}` → "Chiefs"
   - `{{POSITION}}` → "Quarterback"
   - `{{DATE}}` → "2025-04-15"
   - etc.
4. Update frontmatter with appropriate title, dates, and tags
5. Remove all instructional comments

### Example 2: Creating a Competitor Analysis

1. Copy content from `/resources/templates/analysis/competitor-profile-template.md`
2. Create new file at `/content/research/competitor-profiles/apex-financial.md`
3. Replace all variables with specific content about Apex Financial
4. Update frontmatter with appropriate title, dates, and tags
5. Remove all instructional comments

## Template Directory Reference

| Content Type | Template Location | Primary Use Case |
|--------------|-------------------|------------------|
| Player Interview | `/resources/templates/interview/player-interview-template.md` | Interviews with current or former players |
| Agent Interview | `/resources/templates/interview/agent-interview-template.md` | Interviews with player agents |
| Industry Professional | `/resources/templates/interview/industry-professional-template.md` | Interviews with financial advisors, etc. |
| Competitor Profile | `/resources/templates/analysis/competitor-profile-template.md` | Analysis of competitor companies |
| Market Analysis | `/resources/templates/analysis/market-analysis-template.md` | Analysis of market segments or opportunities |
| Service Comparison | `/resources/templates/analysis/service-comparison-template.md` | Comparison of service offerings |
| Task | `/resources/templates/task/task-template.md` | Individual task tracking |
| Project Task | `/resources/templates/task/project-task-template.md` | Project-specific tasks |
| Weekly Status | `/resources/templates/project/weekly-status-template.md` | Weekly project updates |
| Project Plan | `/resources/templates/project/project-plan-template.md` | Overall project planning |

---

*This template guide was created as part of the vault restructuring and migration process. Last updated: April 15, 2025.*
