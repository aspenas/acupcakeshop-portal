---
title: "Vault User Guide"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, guide, vault]
---

---

---

---

# Vault User Guide

## Introduction

This guide provides information on using the newly reorganized vault structure. It covers navigation, content organization, and best practices for working with the vault.

## Vault Structure

The vault follows a structured organization pattern designed to separate content, resources, and utilities:

│   ├── interview-map.md          # Map of all interviews and insights
│   ├── research-map.md           # Map of research and analysis
│   ├── strategy-map.md           # Strategic planning framework
│   └── compliance-map.md         # Regulatory compliance considerations
├── content/                      # Primary knowledge content
│   ├── interviews/               # Interview transcripts and summaries
│   ├── research/                 # Market research and analysis
│   ├── strategy/                 # Business planning and strategy
│   └── compliance/               # Regulatory requirements documentation
├── resources/                    # Supporting materials
│   ├── templates/                # Reusable templates
│   ├── assets/                   # Images, diagrams, and attachments
│   └── dashboards/               # Performance dashboards
├── _utilities/                   # Non-content utility tools
│   ├── scripts/                  # Automation scripts
│   └── config/                   # Configuration files
└── docs/                         # Vault documentation

## Navigating the Vault

### Starting Points

The best way to navigate the vault is through the atlas maps:

1. **[[/atlas/interview-map|Interview Map]]**: Provides an overview of all interviews with key insights
2. **[[/atlas/research-map|Research Map]]**: Maps out the market research and competitor analysis
3. **[[/atlas/strategy-map|Strategy Map]]**: Outlines the strategic planning framework
4. **[[/atlas/compliance-map|Compliance Map]]**: Details regulatory compliance considerations

### Finding Content

Content is organized by type, making it easy to find specific information:

- **Interviews**: Located in , organized by interviewee type
- **Research**: Located in , organized by research type
- **Strategy**: Located in , organized by strategic area
- **Compliance**: Located in , organized by regulatory area

### Using Resources

Resources are organized by type:

- **Templates**: Located in , organized by use case
- **Assets**: Located in , organized by media type
- **Dashboards**: Located in , organized by focus area

## Creating New Content

### Using Templates

Templates are available for common content types:

1. Navigate to  to find the appropriate template
2. Copy the template to the correct location in the  directory
3. Rename the file according to the established naming convention (kebab-case)
4. Update the frontmatter with appropriate metadata

### Frontmatter Standards

All content files should include standardized frontmatter with the following fields:



### Status Values

Use the following status values to indicate the state of content:

- : Content that is in progress
- : Current, approved content
- : Outdated or superseded content

## Best Practices

### Naming Conventions

- Use kebab-case for all filenames (e.g., )
- Use descriptive names that reflect content
- Include relevant prefixes or suffixes for special file types

### Cross-Linking

- Use wiki-style links to cross-reference related content
- Include link text for clarity: 
- Use the atlas maps as central navigation hubs

### Performance Considerations

- The  file excludes utility directories from indexing
- Store images and attachments in 
- Split very large documents into smaller, linked files

## Troubleshooting

### Broken Links

If you encounter broken links:

1. Check the [Migration Verification Report](migration_verification_report.md) for known issues
2. Update the link to point to the correct location in the new structure
3. Report persistent issues for further investigation

### Missing Content

If you cannot find content that you know should exist:

1. Check the atlas maps for navigation to the content
2. Search for the content by title or keywords
