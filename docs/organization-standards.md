---
title: "Organization Standards
Descriptive Title"
date_created: 2025-04-15
YYYY-MM-DD
date_modified: 2025-04-15
YYYY-MM-DD
status: active
draft|active|archived
tags: [documentation, standards, organization, vault]
[tag1, tag2, tag3]
---

---

---

---

# Organization Standards

This document defines the standards for organizing and formatting content within the Athlete Financial Empowerment vault.

## File Organization

### Directory Structure

- Store files in the most specific applicable directory
- Maintain the established directory hierarchy
- Do not create new top-level directories without consensus

### File Naming

- Use kebab-case for all filenames (e.g., `player-interview.md`)
- Include relevant prefixes or suffixes for special file types:
  - Templates: `-template` suffix (e.g., `interview-template.md`)
  - README files: `README.md` for directory documentation
  - Index files: `index.md` for content indexes
- Use descriptive names that reflect content

## Content Formatting

### YAML Frontmatter

All files should include standardized YAML frontmatter with the following fields:

```yaml
---
title: "Descriptive Title"
date_created: YYYY-MM-DD
date_modified: YYYY-MM-DD
status: draft|active|archived
tags: [tag1, tag2, tag3]
---
```

Additional fields may be included as appropriate for specific content types:

```yaml
# For interviews
type: interview
interviewer: "Interviewer Name"
subject: "Subject Name"
subject_role: "Subject Role"

# For analysis documents
primary_author: "Author Name"
version: 1.0
```

### Markdown Formatting

- Use ATX-style headers (`#` syntax) for section headers
- Maintain a logical header hierarchy (don't skip levels)
- Use lists, tables, and callouts appropriately
- Wrap code blocks in triple backticks with language specification
- Use emphasis sparingly and consistently

### Link Formatting

- Use wiki-style links for internal references: `[[file-name]]`
- Include link text for clarity: `[[file-name|Descriptive Text]]`
- Use descriptive link text that provides context
- For external links, use full URLs with descriptive text

## Metadata Standards

### Tags

- Use established tags from the tag hierarchy
- Keep tags lowercase and use hyphens for multi-word tags
- Limit tags to 5-7 per document (focus on most relevant)
- Include content type tags (e.g., `interview`, `analysis`)

Primary tag categories:
- Content type: `interview`, `research`, `analysis`, `strategy`
- Subject matter: `financial`, `athlete`, `advisor`, `education`
- Status: `draft`, `active`, `archived`, `approved`
- Sports: `football`, `basketball`, `baseball`, etc.

### Status Values

- `draft`: Content in progress, not yet finalized
- `active`: Current, approved content
- `archived`: Outdated or superseded content
- `review`: Content awaiting review

## Templates

- Use established templates for all content types
- Maintain consistent structure within each content type
- Do not modify templates without consensus
- Store all templates in `resources/templates/`

## Reference Materials

Refer to the following resources for additional guidance:

- [[vault-guide]] - Comprehensive vault usage guide
- [[template-guide]] - Detailed guide for template usage
- [[frontmatter-standards]] - Detailed frontmatter specifications

## Implementation

- New content should follow these standards immediately
- Existing content should be migrated as encountered
- Documentation should be updated to reflect any changes to these standards

---

*Standards last updated: April 15, 2025*
