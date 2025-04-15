---
title: "Content Creation Workflow"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, workflow, guide, content]
---

# Content Creation Workflow

## Overview

This guide provides step-by-step workflows for creating, organizing, and maintaining different types of content in the Athlete Financial Empowerment vault. Following these workflows ensures consistent organization and easy discovery of content.

## General Content Creation Process

### 1. Planning

1. **Determine content type**: Identify what type of content you're creating (interview, research, strategy, compliance)
2. **Check existing content**: Review atlas maps to see if similar content already exists
3. **Select template**: Choose the appropriate template for your content type
4. **Identify location**: Determine the correct directory for your content

### 2. Content Creation

1. **Copy template**: Copy the appropriate template from the `/resources/templates/` directory
2. **Create file**: Place the file in the correct directory using proper naming conventions
3. **Complete frontmatter**: Fill in all required frontmatter fields
4. **Draft content**: Create your content following template structure
5. **Add internal links**: Link to related content using wiki-style links

### 3. Review and Finalization

1. **Proofread**: Check content for errors and clarity
2. **Verify links**: Ensure all internal links point to correct targets
3. **Update frontmatter**: Set status to "active" and update modification date
4. **Add to atlas**: Update relevant atlas map with link to your content

## Specific Workflows

### Interview Content

#### Creating a New Interview Record

1. **Select template**: Navigate to `/resources/templates/interview/` and choose the appropriate template:
   - `player-interview-template.md` for player interviews
   - `agent-interview-template.md` for agent interviews
   - `industry-professional-template.md` for industry professionals

2. **Create file**: Place in the correct directory using this naming convention:
   ```
   /content/interviews/[type]/[year]/[month]/yyyy-mm-dd-lastname-firstname-team-position.md
   ```
   For example:
   ```
   /content/interviews/players/active/2025/04_april/2025-04-10-smith-john-raiders-quarterback.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Interview: John Smith - Raiders Quarterback"
   date_created: 2025-04-10
   date_modified: 2025-04-10
   status: active
   tags: [interview, player, raiders, quarterback, football]
   ---
   ```

4. **Update atlas**: Add a link to the interview in `/atlas/interview-map.md`

#### Interview Content Structure

Ensure your interview contains these sections:

- **Interview Details**: Date, location, interviewer, interviewee
- **Background**: Brief background of the interviewee
- **Key Insights**: Bullet points of main takeaways
- **Transcript**: Full or summarized conversation
- **Follow-up**: Action items or follow-up questions
- **Related Resources**: Links to related content

### Research Content

#### Creating Market Analysis

1. **Select template**: Use `/resources/templates/analysis/market-analysis-template.md`

2. **Create file**: Place in market analysis directory with descriptive name:
   ```
   /content/research/market-analysis/topic-focus-analysis.md
   ```
   For example:
   ```
   /content/research/market-analysis/rookie-advisory-needs-analysis.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Rookie Advisory Needs Analysis"
   date_created: 2025-04-15
   date_modified: 2025-04-15
   status: active
   tags: [research, market-analysis, rookie, advisory, needs]
   ---
   ```

4. **Update atlas**: Add to `/atlas/research-map.md`

#### Creating Competitor Profile

1. **Select template**: Use `/resources/templates/analysis/competitor-profile-template.md`

2. **Create file**: Place in competitor profiles directory:
   ```
   /content/research/competitor-profiles/company-name.md
   ```
   For example:
   ```
   /content/research/competitor-profiles/integra-wealth.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Competitor Profile: Integra Wealth"
   date_created: 2025-04-15
   date_modified: 2025-04-15
   status: active
   tags: [research, competitor, financial-advisor, wealth-management]
   ---
   ```

4. **Update atlas**: Add to `/atlas/research-map.md`

### Strategy Content

#### Creating Strategy Documents

1. **Select template**: Use `/resources/templates/strategy-document-template.md`

2. **Create file**: Place in appropriate strategy directory:
   ```
   /content/strategy/business-model/topic-name.md
   ```
   For example:
   ```
   /content/strategy/business-model/service-offerings.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Service Offerings"
   date_created: 2025-04-15
   date_modified: 2025-04-15
   status: active
   tags: [strategy, business-model, services, offerings]
   ---
   ```

4. **Update atlas**: Add to `/atlas/strategy-map.md`

#### Implementation Planning

1. **Select template**: Use `/resources/templates/implementation-plan-template.md`

2. **Create file**: Place in implementation directory:
   ```
   /content/strategy/implementation/phase-name.md
   ```
   For example:
   ```
   /content/strategy/implementation/phase-one.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Implementation: Phase One"
   date_created: 2025-04-15
   date_modified: 2025-04-15
   status: active
   tags: [strategy, implementation, phase-one, timeline]
   ---
   ```

4. **Update atlas**: Add to `/atlas/strategy-map.md`

### Compliance Content

#### Creating Compliance Documents

1. **Select template**: Use `/resources/templates/compliance-document-template.md`

2. **Create file**: Place in appropriate compliance directory:
   ```
   /content/compliance/[section]/document-name.md
   ```
   For example:
   ```
   /content/compliance/registration/application-process.md
   ```

3. **Complete frontmatter**:
   ```yaml
   ---
   title: "Registration: Application Process"
   date_created: 2025-04-15
   date_modified: 2025-04-15
   status: active
   tags: [compliance, registration, application, process]
   ---
   ```

4. **Update atlas**: Add to `/atlas/compliance-map.md`

## Atlas Map Maintenance

### Updating Atlas Maps

Atlas maps should be updated whenever you add significant new content:

1. **Navigate to atlas**: Open the relevant atlas map:
   - `/atlas/interview-map.md` for interviews
   - `/atlas/research-map.md` for research
   - `/atlas/strategy-map.md` for strategy
   - `/atlas/compliance-map.md` for compliance

2. **Add link**: Add a link to your new content under the appropriate section

3. **Organize by category**: Keep links organized by category and subcategory

4. **Include description**: Add a brief description of the content when useful

### Atlas Map Format

Follow this format when adding to atlas maps:

```markdown
## Category Name

### Subcategory Name

- [[/path/to/content|Display Name]] - Brief description of content
- [[/path/to/content|Display Name]] - Brief description of content
```

For example:

```markdown
## Player Interviews

### NFL Players

- [[/content/interviews/players/active/2025/04_april/2025-04-10-smith-john-raiders-quarterback|John Smith - Raiders QB]] - Discussion of financial planning for rookie contracts
- [[/content/interviews/players/active/2025/04_april/2025-04-12-johnson-michael-bears-linebacker|Michael Johnson - Bears LB]] - Insights on mid-career investment strategies
```

## Frontmatter Field Guidelines

### Standard Fields

- **title**: Should be clear and descriptive
  - For interviews: "Interview: Name - Team Position"
  - For analysis: "Analysis: Specific Topic"
  - For strategy: "Strategy: Component Name"

- **date_created**: Use YYYY-MM-DD format for creation date

- **date_modified**: Update whenever content changes

- **status**: Use one of these values:
  - `active`: Current, relevant content
  - `draft`: Content still being developed
  - `archived`: Historical content no longer actively used
  - `template`: Template files

- **tags**: Include 3-5 relevant tags:
  - At least one content type tag (interview, research, strategy, compliance)
  - Subject-specific tags (football, investment, retirement, etc.)
  - Status tags if needed (in-progress, needs-review)

## File Naming Conventions

### General Rules

- Use kebab-case (lowercase with hyphens)
- Be descriptive but concise
- Avoid special characters except hyphens
- Use consistent patterns for similar content types

### Content-Specific Patterns

- **Interviews**: `yyyy-mm-dd-lastname-firstname-team-position.md`
- **Research**: `topic-focus-analysis.md`
- **Competitor Profiles**: `company-name.md`
- **Strategy**: `component-name.md`
- **Compliance**: `topic-name.md`

## Link Management

### Best Practices

- **Use descriptive display text**: `[[file-path|Descriptive Text]]` instead of just `[[file-path]]`
- **Link related content**: Create connections between related documents
- **Avoid broken links**: Verify links point to existing files
- **Use absolute paths for cross-section links**: Start with `/` for links to different sections

### Link Examples

```markdown
<!-- Link to an interview -->
[[/content/interviews/players/active/2025/04_april/2025-04-10-smith-john-raiders-quarterback|John Smith Interview]]

<!-- Link to research -->
[[/content/research/market-analysis/rookie-advisory-needs|Rookie Advisory Needs]]

<!-- Link to related content in the same directory (relative link) -->
[[player-compensation-analysis|Player Compensation Analysis]]
```

## Content Maintenance

### Regular Tasks

1. **Update modification dates**: Keep `date_modified` current
2. **Review content status**: Update status as content evolves
3. **Check for broken links**: Regularly verify links work
4. **Update atlas maps**: Ensure atlas maps reflect current content

### Archiving Content

For outdated content:

1. **Update status**: Change status to `archived`
2. **Update modification date**: Set to archival date
3. **Remove from active atlas maps**: Consider moving to an archive section
4. **Add archive note**: Add a note indicating why the content was archived

## Obsidian-Specific Tips

### Navigation

- Use atlas maps for high-level navigation
- Use graph view to visualize content connections
- Create dashboard notes for frequently accessed content

### Plugins

- Use Dataview for creating dynamic content lists
- Use Templater for advanced template functionality
- Use Daily Notes for regular content creation

### Performance

- Store large assets in the assets directory
- Use links instead of embedding large content
- Limit the use of large embedded images or files

---

*This workflow guide was created as part of the vault restructuring and migration process. Last updated: April 15, 2025.*