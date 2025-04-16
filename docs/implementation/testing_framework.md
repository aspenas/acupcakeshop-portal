---
title: "Testing Framework Guide"
date_created: 2025-04-16
date_modified: 2025-04-16
status: active
tags: [documentation, implementation, testing, scripts]
---

# Testing Framework Guide

## Overview

This guide describes the testing framework implemented for the Athlete Financial Empowerment vault's maintenance scripts. The framework provides a structured approach to testing shell scripts to ensure reliability and catch issues early.

## Getting Started

The testing framework is located in the `scripts/tests` directory and consists of:

- `test_framework.sh`: The main testing framework script
- Individual test files for specific scripts or features

### Running Tests

To run a specific test:

```bash
./scripts/tests/test_framework.sh scripts/tests/test_template_apply.sh
```

To run all tests:

```bash
./scripts/tests/test_framework.sh --all
```

## Creating Tests

### Test File Structure

Test files should follow this structure:

1. Set up the test environment
2. Run tests with assertions
3. Clean up (if necessary)

Example test file:

```bash
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

# Run tests with assertions
echo "Testing applying a template..."
"$TEMPLATE_APPLY_SCRIPT" apply "$TEST_TEMPLATE" "$TEST_DESTINATION" > "$TEST_DIR/apply.log"
assert_file_exists "$TEST_DESTINATION" "Template application failed to create the file"

# Test that the template was applied correctly
today=$(date +"%Y-%m-%d")
assert_file_contains "$TEST_DESTINATION" "date_created: $today" "Template doesn't have today's date"

echo "All tests passed for template_apply.sh"
exit 0
```

### Available Assertions

The testing framework provides the following assertion functions:

- **`assert`**: Assert that a condition is true
  ```bash
  assert "[ 1 -eq 1 ]" "One should equal one"
  ```

- **`assert_equals`**: Assert that two values are equal
  ```bash
  assert_equals "expected" "actual" "Values should be equal"
  ```

- **`assert_file_exists`**: Assert that a file exists
  ```bash
  assert_file_exists "/path/to/file" "File should exist"
  ```

- **`assert_dir_exists`**: Assert that a directory exists
  ```bash
  assert_dir_exists "/path/to/directory" "Directory should exist"
  ```

- **`assert_file_contains`**: Assert that a file contains a pattern
  ```bash
  assert_file_contains "/path/to/file" "pattern" "File should contain pattern"
  ```

### Test Environment

Each test runs in an isolated environment with the following variables:

- **`$TEST_DIR`**: A temporary directory for test artifacts
- **`$VAULT_ROOT`**: The root directory of the vault
- Various assertion functions

## Test-Driven Development

When adding new features or fixing bugs, consider using a test-driven development approach:

1. Write a test that fails due to the missing feature or bug
2. Implement the feature or fix the bug
3. Run the test to ensure it passes
4. Refactor as needed, ensuring tests continue to pass

## Continuous Integration

The testing framework is designed to work in a continuous integration environment. You can add CI configuration to run tests automatically on each commit or pull request.

Example CI configuration:

```yaml
name: Run Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run all tests
      run: ./scripts/tests/test_framework.sh --all
```

## Best Practices

### Writing Effective Tests

- **Test One Thing**: Each test should test one specific feature or behavior
- **Use Descriptive Names**: Test file names should describe what they're testing
- **Include Clear Messages**: Assertion messages should explain what's being tested
- **Isolate Tests**: Tests should not depend on each other
- **Clean Up**: Tests should clean up after themselves

### Test Coverage

Aim to test the following for each script:

1. **Basic functionality**: Does the script do what it's supposed to do?
2. **Edge cases**: Does the script handle unusual inputs correctly?
3. **Error handling**: Does the script report errors properly?
4. **Integration**: Does the script work with other scripts?

## Troubleshooting

### Common Test Failures

- **File not found**: Check the file paths in your test
- **Command not found**: Make sure the script you're testing is executable
- **Permission denied**: Check the permissions of the files you're testing

### Debugging Tests

To debug a failing test:

1. Run the test with more verbose output
2. Check the test logs in `_utilities/logs/`
3. Add echo statements to the test to see what's happening

---

*Guide created: April 16, 2025*