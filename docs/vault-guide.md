---
title: "Vault Guide"
date_created: 2025-04-15
date_modified: 2025-04-15
status: active
tags: [documentation, guide, organization, vault]
---

---

---

---

# Athlete Financial Empowerment Vault Guide

This guide provides a comprehensive overview of the Athlete Financial Empowerment vault, including its structure, organization, and best practices for using and contributing to the vault.

## Vault Structure

The vault follows a structured organization pattern designed to separate content, resources, and utilities:

```
/acupcakeshop/                    # Vault root
├── atlas/                        # Knowledge maps and navigation
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
```

## Using the Vault

### Navigation

1. **Start with the Atlas**: The atlas provides maps of content for all major areas
2. **Use the Index**: The main `index.md` file provides quicklinks to key content
3. **Search by Tags**: Use tags to find related content across the vault
4. **Follow Links**: Content is extensively cross-linked for easy navigation

### Content Types

1. **Interviews**: Player, agent, and industry professional interviews
2. **Research**: Market analysis, competitor profiles, and industry insights
3. **Strategy**: Business planning, implementation approach, and strategic framework
4. **Compliance**: Regulatory requirements and compliance documentation

### Using Templates

1. **Access Templates**: Templates are stored in `resources/templates/`
2. **Create from Template**: Use Obsidian's template feature to create new content
3. **Maintain Consistency**: Follow the structure and formatting of templates

## Contributing to the Vault

### Content Guidelines

1. **Use Consistent Formatting**: Follow established patterns for each content type
2. **Include Metadata**: Add appropriate YAML frontmatter to all files
3. **Cross-Link Content**: Create bidirectional links between related content
4. **Use Tags Appropriately**: Tag content with relevant, established tags

### Naming Conventions

1. **Files**: Use kebab-case for all filenames (e.g., `player-interview.md`)
2. **Directories**: Use lowercase with hyphens for directory names
3. **Templates**: Include `-template` suffix for all templates

### Best Practices

1. **Regular Backups**: The vault is automatically backed up daily
2. **Folder Hierarchy**: Maintain the established directory structure
3. **Documentation**: Document changes to vault organization
4. **Version Control**: Track major changes with consistent notes

## Performance Considerations

1. **Exclude Utilities**: Utility directories are excluded via `.obsidian-ignore`
2. **Asset Management**: Store images and attachments in `resources/assets/`
3. **Large Files**: Split very large documents into smaller, linked files
4. **Graphs**: Use the local graph view to visualize content relationships

## Tech Stack Integration

1. **Scripts**: Utility scripts in `_utilities/scripts/` should be run externally
2. **Configuration**: System configuration is stored in `_utilities/config/`
3. **Obsidian Settings**: Customized settings for optimal performance

## Related Documentation

- [[organization-standards]] - Detailed standards for content organization
- [[template-guide]] - Guide to using and creating templates
- [[utilities-guide]] - Documentation for utility scripts and tools

---

*This guide was last updated on April 15, 2025*
