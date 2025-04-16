#!/usr/bin/env bash
# ============================================================================
# Test for template_apply.sh
# ============================================================================

# Set up test environment
CONTENT_SCRIPT_DIR="$VAULT_ROOT/scripts/content"
TEMPLATE_APPLY_SCRIPT="$CONTENT_SCRIPT_DIR/template_apply.sh"
TEST_TEMPLATE="Interview/player-interview-template.md"
TEST_DESTINATION="$TEST_DIR/test-interview.md"

# Test that the script exists
assert_file_exists "$TEMPLATE_APPLY_SCRIPT" "Template apply script does not exist"

# Test listing templates
echo "Testing listing templates..."
"$TEMPLATE_APPLY_SCRIPT" list > "$TEST_DIR/template_list.log"
assert_file_contains "$TEST_DIR/template_list.log" "Template categories" "Template list command failed"

# Test listing specific category
echo "Testing listing specific category..."
"$TEMPLATE_APPLY_SCRIPT" list Interview > "$TEST_DIR/category_list.log"
assert_file_contains "$TEST_DIR/category_list.log" "Templates in category Interview" "Category list command failed"

# Test applying a template
echo "Testing applying a template..."
"$TEMPLATE_APPLY_SCRIPT" apply "$TEST_TEMPLATE" "$TEST_DESTINATION" > "$TEST_DIR/apply.log"
assert_file_exists "$TEST_DESTINATION" "Template application failed to create the file"

# Test that the template was applied correctly
today=$(date +"%Y-%m-%d")
assert_file_contains "$TEST_DESTINATION" "date_created: $today" "Template doesn't have today's date"
assert_file_contains "$TEST_DESTINATION" "status: draft" "Template doesn't have draft status"

echo "All tests passed for template_apply.sh"
exit 0