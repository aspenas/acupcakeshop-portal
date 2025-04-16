#!/usr/bin/env bash
# ============================================================================
# Test for links.sh
# ============================================================================

# Set up test environment
MAINTENANCE_SCRIPT_DIR="$VAULT_ROOT/scripts/maintenance"
LINKS_SCRIPT="$MAINTENANCE_SCRIPT_DIR/links.sh"

# Create test files
TEST_FILE_VALID_LINKS="$TEST_DIR/test_valid_links.md"
TEST_FILE_BROKEN_LINKS="$TEST_DIR/test_broken_links.md"
TEST_FILE_TEMPLATE_LINKS="$TEST_DIR/test_template_links.md"
TEST_DIR_CONTENT="$TEST_DIR/content"
TEST_DIR_TEMPLATES="$TEST_DIR/templates"

mkdir -p "$TEST_DIR_CONTENT"
mkdir -p "$TEST_DIR_TEMPLATES"
mkdir -p "$TEST_DIR_CONTENT/subfolder"

# Create test files for links to reference
touch "$TEST_DIR_CONTENT/existing-file.md"
touch "$TEST_DIR_CONTENT/subfolder/nested-file.md"

# Create a test file with valid links
cat > "$TEST_FILE_VALID_LINKS" << EOF
---
title: "Test File with Valid Links"
date_created: 2025-01-01
date_modified: 2025-01-01
status: active
tags: [test, links]
---

# Test File with Valid Links

This file has valid links:

- [[existing-file]] - Valid link to file in same directory
- [[subfolder/nested-file]] - Valid link to file in subfolder
- [[../test_valid_links]] - Valid link using relative path
EOF

# Create a test file with broken links
cat > "$TEST_FILE_BROKEN_LINKS" << EOF
---
title: "Test File with Broken Links"
date_created: 2025-01-01
date_modified: 2025-01-01
status: active
tags: [test, links]
---

# Test File with Broken Links

This file has broken links:

- [[nonexistent-file]] - Broken link to file that doesn't exist
- [[subfolder/missing-file]] - Broken link to file in subfolder
- [[wrong path/with spaces]] - Broken link with spaces
EOF

# Create a test file with template-style links
cat > "$TEST_FILE_TEMPLATE_LINKS" << EOF
---
title: "Test Template File"
date_created: 2025-01-01
date_modified: 2025-01-01
status: template
tags: [test, template]
---

# Test Template File

This template has placeholder links:

- [[PLAYER_NAME]] - Template placeholder
- [[TEAM_NAME]] - Template placeholder
- [[POSITION]] - Template placeholder
EOF

# Create additional content files for link verification
cat > "$TEST_DIR_CONTENT/file-with-links.md" << EOF
---
title: "File With Links"
---

# File With Links

- [[existing-file]]
- [[nonexistent-file]]
EOF

cat > "$TEST_DIR_TEMPLATES/template-file.md" << EOF
---
title: "Template File"
status: template
---

# Template File

- [[PLACEHOLDER]]
EOF

# Test that the script exists
assert_file_exists "$LINKS_SCRIPT" "Links script does not exist"

# Test verification of a file with valid links
echo "Testing verification of a file with valid links..."
"$LINKS_SCRIPT" verify "$TEST_FILE_VALID_LINKS" > "$TEST_DIR/verify_valid.log"
assert_file_contains "$TEST_DIR/verify_valid.log" "No broken links found" "Verify valid links failed"

# Test verification of a file with broken links
echo "Testing verification of a file with broken links..."
"$LINKS_SCRIPT" verify "$TEST_FILE_BROKEN_LINKS" > "$TEST_DIR/verify_broken.log"
assert_file_contains "$TEST_DIR/verify_broken.log" "Broken links found" "Verify broken links failed"
assert_file_contains "$TEST_DIR/verify_broken.log" "nonexistent-file" "Failed to detect broken link: nonexistent-file"

# Test fix links in a single file
echo "Testing fixing links in a single file..."
cp "$TEST_FILE_BROKEN_LINKS" "$TEST_DIR/test_fix_links.md"
"$LINKS_SCRIPT" fix "$TEST_DIR/test_fix_links.md" > "$TEST_DIR/fix_links.log"
assert_file_contains "$TEST_DIR/fix_links.log" "Fixing links" "Fix links failed"

# Test link fixing for a file with template-style links
echo "Testing fixing template links..."
cp "$TEST_FILE_TEMPLATE_LINKS" "$TEST_DIR/test_fix_template.md"
"$LINKS_SCRIPT" fix-templates "$TEST_DIR/test_fix_template.md" > "$TEST_DIR/fix_template.log"
assert_file_contains "$TEST_DIR/fix_template.log" "Processing template" "Fix template links failed"
# Template links should remain unchanged since they're intentional placeholders
cat "$TEST_DIR/test_fix_template.md" | grep -q "PLAYER_NAME"
assert "$?" "Template placeholders were incorrectly modified"

# Test fixing links in a directory
echo "Testing fixing links in a directory..."
"$LINKS_SCRIPT" fix-all "$TEST_DIR_CONTENT" > "$TEST_DIR/fix_all.log"
assert_file_contains "$TEST_DIR/fix_all.log" "Fixing all links" "Fix all links failed"

# Test verification of all links in a directory
echo "Testing verification of all links in a directory..."
"$LINKS_SCRIPT" verify-all "$TEST_DIR_CONTENT" > "$TEST_DIR/verify_all.log"
assert_file_contains "$TEST_DIR/verify_all.log" "Verifying links" "Verify all links failed"

# Test generating a report of broken links
echo "Testing generating a report of broken links..."
"$LINKS_SCRIPT" report "$TEST_DIR_CONTENT" > "$TEST_DIR/report.log"
assert_file_contains "$TEST_DIR/report.log" "Link Report" "Link report failed"

echo "All tests passed for links.sh"
exit 0