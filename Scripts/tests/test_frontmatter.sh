#!/usr/bin/env bash
# ============================================================================
# Test for frontmatter.sh
# ============================================================================

# Set up test environment
MAINTENANCE_SCRIPT_DIR="$VAULT_ROOT/scripts/maintenance"
FRONTMATTER_SCRIPT="$MAINTENANCE_SCRIPT_DIR/frontmatter.sh"

# Create test files
TEST_FILE="$TEST_DIR/test_frontmatter.md"
TEST_FILE_NO_FRONTMATTER="$TEST_DIR/test_no_frontmatter.md"
TEST_FILE_INVALID_FRONTMATTER="$TEST_DIR/test_invalid_frontmatter.md"
TEST_DIR_FILES="$TEST_DIR/files"

mkdir -p "$TEST_DIR_FILES"

# Create a test file with valid frontmatter
cat > "$TEST_FILE" << EOF
---
title: "Test File"
date_created: 2025-01-01
date_modified: 2025-01-01
status: draft
tags: [test, frontmatter]
---

# Test File

This is a test file with valid frontmatter.
EOF

# Create a test file with no frontmatter
cat > "$TEST_FILE_NO_FRONTMATTER" << EOF
# Test File Without Frontmatter

This is a test file without any frontmatter.
EOF

# Create a test file with invalid frontmatter
cat > "$TEST_FILE_INVALID_FRONTMATTER" << EOF
---
title: "Test File"
date_created: invalid-date
status: unknown-status
---

# Test File with Invalid Frontmatter

This is a test file with invalid frontmatter.
EOF

# Create multiple test files in a directory
for i in {1..3}; do
  cat > "$TEST_DIR_FILES/test_file_$i.md" << EOF
---
title: "Test File $i"
date_created: 2025-01-01
date_modified: 2025-01-01
status: draft
tags: [test, file$i]
---

# Test File $i

This is test file $i.
EOF
done

# Test that the script exists
assert_file_exists "$FRONTMATTER_SCRIPT" "Frontmatter script does not exist"

# Test standardizing a single file
echo "Testing standardizing a single file..."
"$FRONTMATTER_SCRIPT" standardize "$TEST_FILE" > "$TEST_DIR/standardize.log"
assert_file_contains "$TEST_DIR/standardize.log" "Standardizing frontmatter" "Standardize command failed"

# Test verifying a file with valid frontmatter
echo "Testing verifying a file with valid frontmatter..."
"$FRONTMATTER_SCRIPT" verify "$TEST_FILE" > "$TEST_DIR/verify_valid.log"
assert_file_contains "$TEST_DIR/verify_valid.log" "Frontmatter is valid" "Verify valid frontmatter failed"

# Test verifying a file with no frontmatter
echo "Testing verifying a file with no frontmatter..."
"$FRONTMATTER_SCRIPT" verify "$TEST_FILE_NO_FRONTMATTER" > "$TEST_DIR/verify_none.log"
assert_file_contains "$TEST_DIR/verify_none.log" "No frontmatter found" "Verify no frontmatter failed"

# Test verifying a file with invalid frontmatter
echo "Testing verifying a file with invalid frontmatter..."
"$FRONTMATTER_SCRIPT" verify "$TEST_FILE_INVALID_FRONTMATTER" > "$TEST_DIR/verify_invalid.log"
assert_file_contains "$TEST_DIR/verify_invalid.log" "Invalid" "Verify invalid frontmatter failed"

# Test batch processing
echo "Testing batch processing of multiple files..."
"$FRONTMATTER_SCRIPT" batch "$TEST_DIR_FILES" > "$TEST_DIR/batch.log"
assert_file_contains "$TEST_DIR/batch.log" "Processing directory" "Batch processing failed"
assert_file_contains "$TEST_DIR/batch.log" "test_file_1.md" "Batch processing failed to process test_file_1.md"
assert_file_contains "$TEST_DIR/batch.log" "test_file_2.md" "Batch processing failed to process test_file_2.md"
assert_file_contains "$TEST_DIR/batch.log" "test_file_3.md" "Batch processing failed to process test_file_3.md"

# Test fixing a file with no frontmatter
echo "Testing fixing a file with no frontmatter..."
TODAY=$(date +"%Y-%m-%d")
"$FRONTMATTER_SCRIPT" fix "$TEST_FILE_NO_FRONTMATTER" > "$TEST_DIR/fix.log"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "---" "Fix did not add frontmatter delimiter"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "title:" "Fix did not add title field"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "date_created: $TODAY" "Fix did not add date_created field with today's date"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "date_modified: $TODAY" "Fix did not add date_modified field with today's date"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "status:" "Fix did not add status field"
assert_file_contains "$TEST_FILE_NO_FRONTMATTER" "tags:" "Fix did not add tags field"

# Test fixing a file with invalid frontmatter
echo "Testing fixing a file with invalid frontmatter..."
"$FRONTMATTER_SCRIPT" fix "$TEST_FILE_INVALID_FRONTMATTER" > "$TEST_DIR/fix_invalid.log"
assert_file_contains "$TEST_FILE_INVALID_FRONTMATTER" "date_created: $TODAY" "Fix did not correct invalid date_created field"
assert_file_contains "$TEST_FILE_INVALID_FRONTMATTER" "status: draft" "Fix did not correct invalid status field"

echo "All tests passed for frontmatter.sh"
exit 0