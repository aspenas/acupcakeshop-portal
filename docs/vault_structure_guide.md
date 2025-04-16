---
title: "Vault Structure Guide
Document Title"
date_created: 2025-04-15
YYYY-MM-DD
date_modified: 2025-04-15
YYYY-MM-DD
status: active
active   # active, draft, archived, template
tags: [[tag1, documentation, guide, organization], structure, tag2, tag3, tag3]]
---

---

---

# Vault Structure Guide

## Overview

This guide provides a comprehensive overview of the Athlete Financial Empowerment vault's structure, organization principles, and best practices. It serves as the central reference for understanding how content is organized and maintained.

## Directory Structure

The vault follows a logical, hierarchical organization with clear separation of concerns:

```
/acupcakeshop/                     # Root directory
├── atlas/                         # Knowledge maps and navigation
│   ├── interview-map.md           # Map of all interviews
│   ├── research-map.md            # Map of research content
│   ├── strategy-map.md            # Map of strategy content
│   └── compliance-map.md          # Map of compliance content
├── content/                       # Primary knowledge content
│   ├── interviews/                # All interview transcripts and analyses
│   │   ├── players/               # Player interviews
│   │   ├── agents/                # Agent interviews
│   │   └── industry-professionals/  # Industry professional interviews
│   ├── research/                  # Market research and analysis
│   │   ├── market-analysis/       # Market analysis documents
│   │   ├── competitor-profiles/   # Competitor analysis
│   │   └── industry-analysis/     # Industry trends and analysis
│   ├── strategy/                  # Business strategy documents
│   │   ├── business-model/        # Business model documentation
│   │   ├── implementation/        # Implementation plans
│   │   ├── planning/              # Planning documents
│   │   └── team/                  # Team organization
│   └── compliance/                # Regulatory and compliance docs
│       ├── registration/          # Registration requirements
│       ├── advisory-board/        # Advisory board documentation
│       └── standards/             # Industry standards
├── resources/                     # Supporting materials
│   ├── templates/                 # All templates in one location
│   │   ├── interview/             # Interview templates
│   │   ├── analysis/              # Analysis templates
│   │   ├── task/                  # Task templates
│   │   └── project/               # Project templates
│   ├── assets/                    # Images, diagrams, documents
│   │   ├── images/                # Image files
│   │   ├── diagrams/              # Diagrams and charts
│   │   └── documents/             # External documents
│   ├── dashboards/                # Performance dashboards
│   └── scripts/                   # Utility scripts
├── _utilities/                    # Non-content utilities
│   ├── scripts/                   # Maintenance scripts
│   ├── logs/                      # Log files
│   └── inventory/                 # Inventory and tracking files
└── docs/                          # Vault documentation
    ├── guides/                    # User guides
    ├── reference/                 # Reference documentation
    └── system/                    # System documentation
```

## Organization Principles

### 1. Separation of Concerns

The vault follows clear separation between:

- **Content**: Primary knowledge content (interviews, research, strategy, compliance)
- **Navigation**: Maps and wayfinding aids in the atlas directory
- **Resources**: Supporting materials (templates, dashboards, assets)
- **Documentation**: Guides and reference materials
- **Utilities**: Scripts and maintenance tools

### 2. Content Organization

Content is organized by type and purpose:

- **Interviews**: Organized by interviewee type (players, agents, industry professionals)
- **Research**: Market analysis, competitor profiles, and industry analysis
- **Strategy**: Business model, implementation plans, and planning documents
- **Compliance**: Registration requirements, advisory board, and standards

### 3. Hierarchical Navigation

- **Atlas Maps**: Provide high-level navigation to content areas
- **README Files**: Each directory contains a README file explaining its purpose
- **Content Maps**: Each major content area has a dedicated map

## File Naming Conventions

### Standard Format

Files follow these naming conventions:

- **Kebab-case**: Words separated by hyphens (e.g., `player-interview.md`)
- **Descriptive names**: Names should clearly indicate the content
- **No spaces or special characters**: Only letters, numbers, and hyphens
- **Lower case**: All filenames should be lowercase

### Special Formats

- **Interview Files**: `yyyy-mm-dd-lastname-firstname-team-position.md`
- **Template Files**: `content-type-template.md` (e.g., `interview-template.md`)
- **README Files**: Each directory should have a `README.md` file

## Frontmatter Standards

All content files must include standardized frontmatter:

```yaml
---
title: "Document Title"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: active   # active, draft, archived, template
tags: [tag1, tag2, tag3]
---
```

### Required Fields

- **title**: Descriptive title of the document
- **date_created**: Creation date in YYYY-MM-DD format
- **date_modified**: Last modification date in YYYY-MM-DD format
- **status**: Content status (active, draft, archived, template)
- **tags**: Array of tags for categorization

### Status Values

- **active**: Current, up-to-date content
- **draft**: Content in progress
- **archived**: Historical content no longer actively used
- **template**: Template files for creating new content
- **placeholder**: Placeholder files created during migration

## Tagging System

Tags help categorize and find content across the vault:

### Primary Tags

- **Content Type**: interview, research, strategy, compliance
- **Content Status**: active, draft, archived
- **Progress**: in-progress, completed, pending-review

### Secondary Tags

- **Interview Type**: player, agent, industry-professional
- **Research Type**: competitor, market-analysis, industry
- **Sport Type**: football, basketball, baseball, etc.
- **Role**: advisor, athlete, coach, etc.

## Linking Practices

Internal links should follow these practices:

### Link Format

- **Wiki-style links**: Use `[[target-file]]` format
- **Display text**: Include display text for readability: `[[target-file|Display Text]]`
- **Relative links**: Use relative links when linking within the same section
- **Absolute links**: Use absolute paths starting with `/` for cross-section links

### Link Examples

```markdown
<!-- Link to a file in the same directory -->
[[player-interview-guide]]

<!-- Link to a file with display text -->
[[player-interview-guide|Guide to Player Interviews]]

<!-- Link to a file in a different section (absolute path) -->
[[/content/interviews/players/smith-john-raiders-quarterback|John Smith Interview]]
```

## Templates

Templates provide standardized formats for creating new content:

### Using Templates

1. Navigate to `/resources/templates/` directory
2. Copy the appropriate template for your content type
3. Fill in the required fields and remove any instructional comments

### Template Examples

- **Interview templates**: `/resources/templates/interview/player-interview-template.md`
- **Analysis templates**: `/resources/templates/analysis/competitor-profile-template.md`
- **Task templates**: `/resources/templates/task/task-template.md`

## Maintenance Guidelines

### Regular Maintenance Tasks

1. **Update modification dates**: Keep date_modified field current
2. **Fix broken links**: Regularly check and fix broken links
3. **Standardize frontmatter**: Ensure all files have proper frontmatter
4. **Update atlas maps**: Keep navigation maps current as content changes

### Maintenance Scripts

The following scripts are available in the `_utilities/scripts/` directory:

- **template_aware_link_repair.sh**: Fix broken links including in templates
- **advanced_frontmatter_standardizer.sh**: Standardize frontmatter
- **verify_migration.sh**: Verify vault structure integrity

## Content Creation Workflow

### Creating New Content

1. **Choose a template**: Select the appropriate template for your content
2. **Place in correct location**: Save the file in the appropriate directory
3. **Add frontmatter**: Include all required frontmatter fields
4. **Add to atlas**: Update the relevant atlas map with a link to your content

### Content Types and Locations

- **Interviews**: Place in `/content/interviews/[type]/` directory
- **Research**: Place in `/content/research/[type]/` directory
- **Strategy**: Place in `/content/strategy/[type]/` directory
- **Compliance**: Place in `/content/compliance/[type]/` directory

## Best Practices

### Organization

- **Follow the structure**: Maintain the established directory structure
- **Use proper naming**: Follow file naming conventions
- **Add README files**: Create README files for new directories
- **Update atlas maps**: Keep navigation maps current

### Content Management

- **Standardized metadata**: Use consistent frontmatter
- **Descriptive names**: Use clear, descriptive filenames
- **Regular backups**: Back up content regularly
- **Version tracking**: Note significant changes in content

### Performance

- **Optimize images**: Keep image sizes reasonable
- **Separate assets**: Store large assets in the assets directory
- **Limit embeds**: Use links instead of embedding when possible
- **Regular cleanup**: Archive or remove unused content

## Troubleshooting

### Common Issues

- **Broken links**: Run the link repair script to fix broken links
- **Missing frontmatter**: Run the frontmatter standardizer script
- **Navigation difficulties**: Check atlas maps for current navigation
- **Performance issues**: Ensure large files are properly located in assets

### Support Resources

- **Documentation**: Refer to files in the `/docs/` directory
- **Scripts**: Use maintenance scripts in `/_utilities/scripts/`
- **Logs**: Check logs in `/_utilities/logs/` for error information

---

*This guide was created as part of the vault restructuring and migration process. Last updated: April 15, 2025.*
