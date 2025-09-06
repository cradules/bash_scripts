#!/bin/bash

##############################################################################
# Test Runner
# Description: Main test runner for all bash scripts
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

set -euo pipefail

# Load test framework
readonly TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/test-framework.sh"

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [TEST_FILE]

Run tests for bash scripts in this repository.

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -f, --filter    Run only tests matching pattern
    --list          List available tests

Arguments:
    TEST_FILE       Specific test file to run (optional)

Examples:
    $(basename "$0")                    # Run all tests
    $(basename "$0") test_sethost.sh    # Run specific test
    $(basename "$0") --filter sethost   # Run tests matching pattern

EOF
}

list_tests() {
    echo "Available tests:"
    find "$TEST_DIR" -name "test_*.sh" -type f | while read -r test_file; do
        echo "  $(basename "$test_file")"
    done
}

main() {
    local verbose=false
    local filter=""
    local test_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -f|--filter)
                filter="$2"
                shift 2
                ;;
            --list)
                list_tests
                exit 0
                ;;
            test_*.sh)
                test_file="$1"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Set verbose mode
    if [[ "$verbose" == "true" ]]; then
        set -x
    fi
    
    echo "Bash Scripts Test Suite"
    echo "======================="
    echo
    
    # Run specific test file or all tests
    if [[ -n "$test_file" ]]; then
        if [[ -n "$filter" && "$test_file" != *"$filter"* ]]; then
            echo "Test file $test_file does not match filter $filter"
            exit 1
        fi
        run_test_file "$TEST_DIR/$test_file"
    elif [[ -n "$filter" ]]; then
        # Run tests matching filter
        local found=false
        find "$TEST_DIR" -name "test_*.sh" -type f | while read -r file; do
            if [[ "$(basename "$file")" == *"$filter"* ]]; then
                run_test_file "$file"
                found=true
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            echo "No tests found matching filter: $filter"
            exit 1
        fi
    else
        # Run all tests
        run_all_tests
    fi
    
    # Show summary and exit with appropriate code
    if show_test_summary; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
