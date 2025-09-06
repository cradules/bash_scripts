#!/bin/bash

##############################################################################
# Common Logging Library
# Description: Centralized logging functionality for all scripts
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

# Color codes
readonly LOG_RED='\033[0;31m'
readonly LOG_GREEN='\033[0;32m'
readonly LOG_YELLOW='\033[1;33m'
readonly LOG_BLUE='\033[0;34m'
readonly LOG_PURPLE='\033[0;35m'
readonly LOG_CYAN='\033[0;36m'
readonly LOG_NC='\033[0m' # No Color

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Default configuration
LOG_LEVEL_CURRENT="${LOG_LEVEL_CURRENT:-$LOG_LEVEL_INFO}"
LOG_FILE="${LOG_FILE:-}"
LOG_TO_CONSOLE="${LOG_TO_CONSOLE:-true}"
LOG_WITH_COLOR="${LOG_WITH_COLOR:-true}"
LOG_WITH_TIMESTAMP="${LOG_WITH_TIMESTAMP:-true}"

# Initialize logging
init_logging() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}" .sh)}"
    
    # Set default log file if not specified
    if [[ -z "$LOG_FILE" ]]; then
        local log_dir="${LOG_DIR:-/var/log/bash-scripts}"
        mkdir -p "$log_dir" 2>/dev/null || {
            log_dir="${HOME}/.local/log/bash-scripts"
            mkdir -p "$log_dir"
        }
        LOG_FILE="$log_dir/${script_name}.log"
    fi
    
    # Create log file directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    # Rotate log if it's too large
    rotate_log_if_needed
}

# Rotate log file if it exceeds maximum size
rotate_log_if_needed() {
    local max_size="${MAX_LOG_SIZE:-10M}"
    
    if [[ -f "$LOG_FILE" ]]; then
        local size
        size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        local max_bytes
        
        # Convert size to bytes
        case "$max_size" in
            *K|*k) max_bytes=$((${max_size%[Kk]} * 1024)) ;;
            *M|*m) max_bytes=$((${max_size%[Mm]} * 1024 * 1024)) ;;
            *G|*g) max_bytes=$((${max_size%[Gg]} * 1024 * 1024 * 1024)) ;;
            *) max_bytes="$max_size" ;;
        esac
        
        if [[ $size -gt $max_bytes ]]; then
            mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S)"
            touch "$LOG_FILE"
        fi
    fi
}

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Convert log level number to string
level_to_string() {
    case "$1" in
        $LOG_LEVEL_DEBUG) echo "DEBUG" ;;
        $LOG_LEVEL_INFO)  echo "INFO"  ;;
        $LOG_LEVEL_WARN)  echo "WARN"  ;;
        $LOG_LEVEL_ERROR) echo "ERROR" ;;
        $LOG_LEVEL_FATAL) echo "FATAL" ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Get color for log level
get_level_color() {
    case "$1" in
        $LOG_LEVEL_DEBUG) echo "$LOG_CYAN" ;;
        $LOG_LEVEL_INFO)  echo "$LOG_BLUE" ;;
        $LOG_LEVEL_WARN)  echo "$LOG_YELLOW" ;;
        $LOG_LEVEL_ERROR) echo "$LOG_RED" ;;
        $LOG_LEVEL_FATAL) echo "$LOG_PURPLE" ;;
        *) echo "$LOG_NC" ;;
    esac
}

# Core logging function
_log() {
    local level="$1"
    local message="$2"
    
    # Check if we should log this level
    if [[ $level -lt $LOG_LEVEL_CURRENT ]]; then
        return 0
    fi
    
    local level_str
    level_str=$(level_to_string "$level")
    
    local timestamp=""
    if [[ "$LOG_WITH_TIMESTAMP" == "true" ]]; then
        timestamp="$(get_timestamp) "
    fi
    
    local log_entry="${timestamp}[${level_str}] ${message}"
    
    # Log to console
    if [[ "$LOG_TO_CONSOLE" == "true" ]]; then
        if [[ "$LOG_WITH_COLOR" == "true" && -t 1 ]]; then
            local color
            color=$(get_level_color "$level")
            echo -e "${color}${log_entry}${LOG_NC}"
        else
            echo "$log_entry"
        fi
    fi
    
    # Log to file
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

# Public logging functions
log_debug() {
    _log $LOG_LEVEL_DEBUG "$*"
}

log_info() {
    _log $LOG_LEVEL_INFO "$*"
}

log_warn() {
    _log $LOG_LEVEL_WARN "$*"
}

log_error() {
    _log $LOG_LEVEL_ERROR "$*"
}

log_fatal() {
    _log $LOG_LEVEL_FATAL "$*"
}

# Convenience functions with specific formatting
log_success() {
    if [[ "$LOG_WITH_COLOR" == "true" && -t 1 ]]; then
        echo -e "${LOG_GREEN}[SUCCESS]${LOG_NC} $*"
    else
        echo "[SUCCESS] $*"
    fi
    _log $LOG_LEVEL_INFO "[SUCCESS] $*"
}

log_step() {
    if [[ "$LOG_WITH_COLOR" == "true" && -t 1 ]]; then
        echo -e "${LOG_CYAN}[STEP]${LOG_NC} $*"
    else
        echo "[STEP] $*"
    fi
    _log $LOG_LEVEL_INFO "[STEP] $*"
}

# Set log level from string
set_log_level() {
    case "${1^^}" in
        DEBUG) LOG_LEVEL_CURRENT=$LOG_LEVEL_DEBUG ;;
        INFO)  LOG_LEVEL_CURRENT=$LOG_LEVEL_INFO ;;
        WARN)  LOG_LEVEL_CURRENT=$LOG_LEVEL_WARN ;;
        ERROR) LOG_LEVEL_CURRENT=$LOG_LEVEL_ERROR ;;
        FATAL) LOG_LEVEL_CURRENT=$LOG_LEVEL_FATAL ;;
        *) log_warn "Unknown log level: $1" ;;
    esac
}

# Clean old log files
cleanup_old_logs() {
    local retention_days="${LOG_RETENTION_DAYS:-30}"
    local log_dir
    log_dir="$(dirname "$LOG_FILE")"
    
    if [[ -d "$log_dir" ]]; then
        find "$log_dir" -name "*.log.*" -type f -mtime +$retention_days -delete 2>/dev/null || true
    fi
}

# Export functions for use in other scripts
export -f init_logging log_debug log_info log_warn log_error log_fatal log_success log_step set_log_level
