---
title: "Content Management Guide"
date_created: 2025-04-16
date_modified: 2025-04-16
status: active
tags: [documentation, implementation, content, management, guide]
---

# Content Management Guide

## Overview

This guide describes the content management tools implemented in the Athlete Financial Empowerment vault. These tools help streamline the creation of new content, ensure consistency, and maintain the vault's structure.

## Available Tools

The vault includes the following content management tools:

1. **Template Application**: Apply templates to create new content
2. **Interview Creation**: Create structured interview files
3. **Content Organization**: Tools for organizing and managing content

## Using Templates

Templates are pre-defined files with standard structure and formatting that can be used as starting points for new content. The vault includes templates for various types of content, including interviews, analysis, and project management.

### Listing Available Templates

To see what templates are available, use the `list-templates` command:

```bash
./scripts/maintenance.sh list-templates
```

This will show the available template categories. To see templates in a specific category, add the category name:

```bash
./scripts/maintenance.sh list-templates interview
```

### Applying Templates

To create new content using a template, use the `apply-template` command:

```bash
./scripts/maintenance.sh apply-template <template> <destination>
```

For example:

```bash
./scripts/maintenance.sh apply-template interview/player-interview-template.md content/interviews/smith-john.md
```

This will:
1. Copy the template to the specified destination
2. Update the frontmatter with current dates
3. Set the status to "draft"
4. Provide guidance on additional updates needed

## Creating Interviews

The vault includes specialized tools for creating interview files, which are a core part of the Athlete Financial Empowerment project.

### Player Interviews

To create a new player interview:

```bash
./scripts/maintenance.sh create-interview player <first> <last> <team> <position>
```

For example:

```bash
./scripts/maintenance.sh create-interview player John Smith Vikings Quarterback
```

This will:
1. Create a new interview file in the appropriate directory
2. Apply the player interview template
3. Update frontmatter with the player's information
4. Add the interview to the interview map for navigation
5. Add appropriate tags for categorization

### Agent Interviews

To create a new agent interview:

```bash
./scripts/maintenance.sh create-interview agent <first> <last> <agency>
```

For example:

```bash
./scripts/maintenance.sh create-interview agent David Johnson ProSports
```

### Financial Advisor Interviews

To create a new financial advisor interview:

```bash
./scripts/maintenance.sh create-interview advisor <first> <last> <company>
```

For example:

```bash
./scripts/maintenance.sh create-interview advisor Michael Williams CapitalAdvisors
```

## Content Organization

### Directory Structure

Content is organized into the following main directories:

- **`content/interviews/`**: Contains interview files organized by type (players, agents, industry-professionals)
- **`content/research/`**: Contains research and analysis documents
- **`content/strategy/`**: Contains strategic planning documents
- **`content/compliance/`**: Contains regulatory compliance documents

Each of these directories has subdirectories for specific categories of content.

### File Naming Conventions

The content management tools enforce the following naming conventions:

- **Player interviews**: `firstname-lastname-team-position.md`
- **Agent interviews**: `firstname-lastname-agency-agent.md`
- **Advisor interviews**: `firstname-lastname-company-financial-advisor.md`

All names are converted to kebab-case (lowercase with hyphens) for consistency.

### Content Maps

The content management tools automatically update the following maps:

- **`atlas/interview-map.md`**: Contains links to all interviews
- **`atlas/research-map.md`**: Contains links to research and analysis documents
- **`atlas/strategy-map.md`**: Contains links to strategic planning documents
- **`atlas/compliance-map.md`**: Contains links to compliance documents

## Best Practices

### Content Creation Workflow

1. **Choose the Right Template**: Select the appropriate template for your content
2. **Apply the Template**: Use the `apply-template` or `create-interview` command
3. **Add Specific Content**: Fill in the content, following the template structure
4. **Update Frontmatter**: Ensure all frontmatter fields are properly filled
5. **Update Status**: Change the status from "draft" to "active" when complete
6. **Verify Links**: Ensure all links to the new content work properly

### Frontmatter Standards

All content should include the following frontmatter fields:

```yaml
---
title: "Document Title"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: active
tags: [tag1, tag2, tag3]
---
```

The `status` field should be one of:
- `draft`: Content in progress
- `active`: Completed, current content
- `archived`: Historical content no longer actively used
- `template`: Template files

### Tagging Standards

Use the following tag categories:
- **Content Type**: `interview`, `research`, `strategy`, `compliance`
- **Subject**: `player`, `agent`, `financial-advisor`
- **Sport**: `football`, `basketball`, `baseball`
- **Status**: `draft`, `active`, `archived`

## Troubleshooting

### Common Issues

- **Template Not Found**: Ensure you're using the correct template path
- **File Already Exists**: Decide whether to overwrite or choose a different name
- **Map Not Updated**: Check if the atlas map file exists and has the expected structure

### Getting Help

For more information about the content management tools, use the help command:

```bash
./scripts/maintenance.sh help
```

For specific help with a command:

```bash
./scripts/content/template_apply.sh help
./scripts/content/create_interview.sh help
```

---

*Guide created: April 16, 2025*