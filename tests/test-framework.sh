#!/bin/bash

##############################################################################
# Simple Testing Framework for Bash Scripts
# Description: Lightweight testing framework for bash script validation
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

set -euo pipefail

# Test framework configuration
readonly TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$TEST_DIR")"

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Colors for output
readonly T_RED='\033[0;31m'
readonly T_GREEN='\033[0;32m'
readonly T_YELLOW='\033[1;33m'
readonly T_BLUE='\033[0;34m'
readonly T_NC='\033[0m'

# Test output functions
test_info() {
    echo -e "${T_BLUE}[INFO]${T_NC} $*"
}

test_pass() {
    echo -e "${T_GREEN}[PASS]${T_NC} $*"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${T_RED}[FAIL]${T_NC} $*"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${T_YELLOW}[WARN]${T_NC} $*"
}

# Start a test case
start_test() {
    CURRENT_TEST="$1"
    ((TESTS_RUN++))
    test_info "Running test: $CURRENT_TEST"
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        test_pass "$CURRENT_TEST: $message"
    else
        test_fail "$CURRENT_TEST: $message (expected: '$expected', got: '$actual')"
    fi
}

assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$expected" != "$actual" ]]; then
        test_pass "$CURRENT_TEST: $message"
    else
        test_fail "$CURRENT_TEST: $message (both values: '$expected')"
    fi
}

assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    if [[ $condition -eq 0 ]]; then
        test_pass "$CURRENT_TEST: $message"
    else
        test_fail "$CURRENT_TEST: $message"
    fi
}

assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if [[ $condition -ne 0 ]]; then
        test_pass "$CURRENT_TEST: $message"
    else
        test_fail "$CURRENT_TEST: $message"
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"
    
    if [[ -f "$file" ]]; then
        test_pass "$CURRENT_TEST: $message ($file)"
    else
        test_fail "$CURRENT_TEST: $message ($file)"
    fi
}

assert_file_not_exists() {
    local file="$1"
    local message="${2:-File should not exist}"
    
    if [[ ! -f "$file" ]]; then
        test_pass "$CURRENT_TEST: $message ($file)"
    else
        test_fail "$CURRENT_TEST: $message ($file)"
    fi
}

assert_command_success() {
    local command="$1"
    local message="${2:-Command should succeed}"
    
    if eval "$command" &>/dev/null; then
        test_pass "$CURRENT_TEST: $message ($command)"
    else
        test_fail "$CURRENT_TEST: $message ($command)"
    fi
}

assert_command_fails() {
    local command="$1"
    local message="${2:-Command should fail}"
    
    if ! eval "$command" &>/dev/null; then
        test_pass "$CURRENT_TEST: $message ($command)"
    else
        test_fail "$CURRENT_TEST: $message ($command)"
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        test_pass "$CURRENT_TEST: $message"
    else
        test_fail "$CURRENT_TEST: $message ('$haystack' should contain '$needle')"
    fi
}

# Mock functions for testing
mock_command() {
    local command="$1"
    local return_code="${2:-0}"
    local output="${3:-}"
    
    # Create a temporary mock script
    local mock_dir="/tmp/test-mocks"
    mkdir -p "$mock_dir"
    
    cat > "$mock_dir/$command" << EOF
#!/bin/bash
echo "$output"
exit $return_code
EOF
    chmod +x "$mock_dir/$command"
    
    # Add mock directory to PATH
    export PATH="$mock_dir:$PATH"
}

cleanup_mocks() {
    rm -rf /tmp/test-mocks
}

# Test runner
run_test_file() {
    local test_file="$1"
    
    if [[ ! -f "$test_file" ]]; then
        test_fail "Test file not found: $test_file"
        return 1
    fi
    
    test_info "Running test file: $(basename "$test_file")"
    
    # Source the test file
    source "$test_file"
    
    # Clean up after tests
    cleanup_mocks
}

# Test discovery and execution
run_all_tests() {
    test_info "Discovering tests in $TEST_DIR"
    
    # Find all test files
    local test_files=()
    while IFS= read -r -d '' file; do
        test_files+=("$file")
    done < <(find "$TEST_DIR" -name "test_*.sh" -type f -print0)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        test_warn "No test files found"
        return 0
    fi
    
    # Run each test file
    for test_file in "${test_files[@]}"; do
        run_test_file "$test_file"
    done
}

# Test summary
show_test_summary() {
    echo
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Tests run: $TESTS_RUN"
    echo -e "Passed: ${T_GREEN}$TESTS_PASSED${T_NC}"
    echo -e "Failed: ${T_RED}$TESTS_FAILED${T_NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${T_GREEN}All tests passed!${T_NC}"
        return 0
    else
        echo -e "${T_RED}Some tests failed!${T_NC}"
        return 1
    fi
}

# Main test runner
main() {
    case "${1:-all}" in
        all)
            run_all_tests
            ;;
        *)
            run_test_file "$1"
            ;;
    esac
    
    show_test_summary
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
