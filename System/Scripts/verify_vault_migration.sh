#!/bin/bash

# Vault Migration Verification Script
# This script checks for remaining issues after the vault migration fix

# Set the base directory
VAULT_DIR="/Users/patricksmith/obsidian/acupcakeshop"
LOG_FILE="${VAULT_DIR}/System/Logs/migration_verification_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="${VAULT_DIR}/Documentation/Implementation/migration_verification_status.md"

# Create logs directory if it doesn't exist
mkdir -p "${VAULT_DIR}/System/Logs"

# Log function
log() {
  echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "Starting vault migration verification"

# Check for circular redirections
log "Checking for circular redirections..."
CIRCULAR_REDIRECTIONS=$(find "$VAULT_DIR" -type f -name "*.md" -exec grep -l "This file has been moved" {} \; | xargs grep -l "This content is now located at" || true)

if [ -n "$CIRCULAR_REDIRECTIONS" ]; then
  log "Found $(echo "$CIRCULAR_REDIRECTIONS" | wc -l | tr -d ' ') potential circular redirections"
  echo "$CIRCULAR_REDIRECTIONS" >> "$LOG_FILE"
else
  log "No circular redirections found"
fi

# Check for empty files
log "Checking for empty files..."
EMPTY_FILES=$(find "$VAULT_DIR" -type f -name "*.md" -size -50c)

if [ -n "$EMPTY_FILES" ]; then
  log "Found $(echo "$EMPTY_FILES" | wc -l | tr -d ' ') empty or near-empty files"
  echo "$EMPTY_FILES" >> "$LOG_FILE"
else
  log "No empty files found"
fi

# Check for placeholder files
log "Checking for placeholder files..."
PLACEHOLDER_FILES=$(grep -r "Content Placeholder" --include="*.md" "$VAULT_DIR" | cut -d: -f1)
PLACEHOLDER_COUNT=$(echo "$PLACEHOLDER_FILES" | wc -l | tr -d ' ')

log "Found $PLACEHOLDER_COUNT placeholder files that need content restoration"

# Check for redirection files
log "Checking for redirection files..."
REDIRECTION_FILES=$(grep -r "This file has been moved" --include="*.md" "$VAULT_DIR" | cut -d: -f1)
REDIRECTION_COUNT=$(echo "$REDIRECTION_FILES" | wc -l | tr -d ' ')

log "Found $REDIRECTION_COUNT redirection files"

# Generate report
log "Generating verification report..."

cat > "$REPORT_FILE" << EOF
---
title: "Migration Verification Status"
date_created: $(date +%Y-%m-%d)
date_modified: $(date +%Y-%m-%d)
status: active
tags: [migration, verification, report]
---

# Migration Verification Status

> [!NOTE] Technical Report
> This document was automatically generated by the verification script.

## Verification Summary

- **Date**: $(date +%Y-%m-%d\ %H:%M:%S)
- **Circular Redirections**: $([ -n "$CIRCULAR_REDIRECTIONS" ] && echo "$(echo "$CIRCULAR_REDIRECTIONS" | wc -l | tr -d ' ') found" || echo "None found")
- **Empty Files**: $([ -n "$EMPTY_FILES" ] && echo "$(echo "$EMPTY_FILES" | wc -l | tr -d ' ') found" || echo "None found")
- **Placeholder Files**: $PLACEHOLDER_COUNT files with placeholder content
- **Redirection Files**: $REDIRECTION_COUNT redirection notices

## Placeholder Files

These files need content to be restored:

\`\`\`
$PLACEHOLDER_FILES
\`\`\`

## Next Steps

1. **Content Restoration**:
   - Restore content to the placeholder files listed above
   - Use backups or recreate content as needed

2. **Redirection Cleanup**:
   - Plan to remove redirection files after ~2 weeks
   - Run cleanup script after users have adjusted to the new structure

3. **Final Verification**:
   - Run this script again after content restoration to verify all issues resolved

## Log File

Detailed verification log is available at: \`$LOG_FILE\`

---

*Report generated: $(date +%Y-%m-%d\ %H:%M:%S)*
EOF

log "Verification completed and report generated at $REPORT_FILE"

# Make the script executable
chmod +x "$0"

# Exit with status
[ -n "$CIRCULAR_REDIRECTIONS" ] || [ -n "$EMPTY_FILES" ] && exit 1 || exit 0