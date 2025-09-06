#!/bin/bash

##############################################################################
# Common Library Loader
# Description: Main entry point for all common libraries
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
# 
# Usage: source scripts/common/common.sh
##############################################################################

# Get the directory where this script is located
readonly COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all common libraries
source "$COMMON_DIR/config.sh"
source "$COMMON_DIR/logging.sh"
source "$COMMON_DIR/utils.sh"

# Initialize the common system
init_common() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}" .sh)}"
    
    # Initialize configuration
    init_config "$script_name"
    
    # Initialize logging
    init_logging "$script_name"
    
    # Set up signal handlers for cleanup
    trap 'cleanup_temp_files; exit 130' INT TERM
    
    log_debug "Common libraries initialized for script: $script_name"
}

# Show common help information
show_common_help() {
    cat << EOF

Common Options:
    -h, --help      Show help message
    -v, --verbose   Enable verbose output (DEBUG level)
    -q, --quiet     Quiet mode (ERROR level only)
    --log-file FILE Specify log file location
    --config FILE   Specify config file location

Environment Variables:
    LOG_LEVEL       Set logging level (DEBUG, INFO, WARN, ERROR, FATAL)
    LOG_FILE        Set log file location
    CONFIG_DIR      Set configuration directory

EOF
}

# Parse common command line arguments
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                set_log_level "DEBUG"
                set -x
                shift
                ;;
            -q|--quiet)
                set_log_level "ERROR"
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            *)
                # Return unprocessed arguments
                echo "$1"
                shift
                ;;
        esac
    done
}

# Export the main initialization function
export -f init_common show_common_help parse_common_args
