#!/usr/bin/env bash
# ============================================================================
# Athlete Financial Empowerment Vault
# Test Framework
# ============================================================================
# Purpose: Simple testing framework for shell scripts
# Usage:
#   ./test_framework.sh <test_file>
# ============================================================================

set -e  # Exit on error

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOGS_DIR="$VAULT_ROOT/_utilities/logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOGS_DIR/test_${TIMESTAMP}.log"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory if it doesn't exist
mkdir -p "$LOGS_DIR"

# ============================================================================
# Utility Functions
# ============================================================================
log() {
  local message="$1"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log_success() {
  log "${GREEN}✓ $1${NC}"
}

log_error() {
  log "${RED}✗ $1${NC}"
}

log_warning() {
  log "${YELLOW}⚠ $1${NC}"
}

log_info() {
  log "${BLUE}ℹ $1${NC}"
}

show_help() {
  cat << EOF
Test Framework

Usage: ./test_framework.sh [options] [test_file]

Options:
  --all                 - Run all tests
  --help                - Show this help message

Examples:
  ./test_framework.sh tests/test_frontmatter.sh
  ./test_framework.sh --all
EOF
}

# Test Assertion Functions
# These functions are used in the test files

# Assert that a condition is true
assert() {
  local condition="$1"
  local message="${2:-Assertion failed}"
  
  if eval "$condition"; then
    echo "${GREEN}✓ ${message}${NC}"
    return 0
  else
    echo "${RED}✗ ${message}${NC}"
    return 1
  fi
}

# Assert that two values are equal
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"
  
  if [ "$expected" = "$actual" ]; then
    echo "${GREEN}✓ Values are equal: '$expected'${NC}"
    return 0
  else
    echo "${RED}✗ ${message}${NC}"
    return 1
  fi
}

# Assert that a file exists
assert_file_exists() {
  local file="$1"
  local message="${2:-File does not exist: '$file'}"
  
  if [ -f "$file" ]; then
    echo "${GREEN}✓ File exists: '$file'${NC}"
    return 0
  else
    echo "${RED}✗ ${message}${NC}"
    return 1
  fi
}

# Assert that a directory exists
assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory does not exist: '$dir'}"
  
  if [ -d "$dir" ]; then
    echo "${GREEN}✓ Directory exists: '$dir'${NC}"
    return 0
  else
    echo "${RED}✗ ${message}${NC}"
    return 1
  fi
}

# Assert that a file contains a pattern
assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File '$file' does not contain pattern: '$pattern'}"
  
  if grep -q "$pattern" "$file"; then
    echo "${GREEN}✓ File '$file' contains pattern: '$pattern'${NC}"
    return 0
  else
    echo "${RED}✗ ${message}${NC}"
    return 1
  fi
}

# Run a test and capture the result
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .sh)
  
  log_info "Running test: $test_name"
  
  # Create a temporary directory for test artifacts
  local test_dir=$(mktemp -d)
  
  # Set up test environment variables
  export TEST_DIR="$test_dir"
  export VAULT_ROOT
  export assert
  export assert_equals
  export assert_file_exists
  export assert_dir_exists
  export assert_file_contains
  
  # Run the test
  local result=0
  (source "$test_file") || result=$?
  
  # Cleanup
  rm -rf "$test_dir"
  
  # Return the result
  if [ $result -eq 0 ]; then
    log_success "Test passed: $test_name"
    return 0
  else
    log_error "Test failed: $test_name"
    return 1
  fi
}

# Run all tests in the tests directory
run_all_tests() {
  log_info "Running all tests"
  
  local passed=0
  local failed=0
  local total=0
  
  for test_file in "$SCRIPT_DIR"/*.sh; do
    # Skip the test framework itself
    if [ "$(basename "$test_file")" = "$(basename "$0")" ]; then
      continue
    fi
    
    run_test "$test_file"
    
    if [ $? -eq 0 ]; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
    fi
    
    total=$((total + 1))
  done
  
  log_info "Test results: $passed passed, $failed failed, $total total"
  
  if [ $failed -eq 0 ]; then
    log_success "All tests passed"
    return 0
  else
    log_error "Some tests failed"
    return 1
  fi
}

# ============================================================================
# Main
# ============================================================================
log_info "Starting test framework"

# Parse command-line arguments
if [ $# -eq 0 ]; then
  log_error "No test file specified"
  show_help
  exit 1
fi

case "$1" in
  --all)
    run_all_tests
    ;;
  --help|-h)
    show_help
    ;;
  *)
    run_test "$1"
    ;;
esac

log_info "Test framework completed"
exit $?