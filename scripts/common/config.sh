#!/bin/bash

##############################################################################
# Common Configuration Library
# Description: Centralized configuration management for all scripts
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

# Default configuration values
readonly DEFAULT_CONFIG_DIR="${HOME}/.config/bash-scripts"
readonly DEFAULT_LOG_DIR="/var/log/bash-scripts"
readonly DEFAULT_TEMP_DIR="/tmp/bash-scripts"

# Create necessary directories
create_directories() {
    local dirs=("$DEFAULT_CONFIG_DIR" "$DEFAULT_LOG_DIR" "$DEFAULT_TEMP_DIR")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null || {
                # Fallback to user-writable locations
                case "$dir" in
                    "$DEFAULT_LOG_DIR")
                        export LOG_DIR="${HOME}/.local/log/bash-scripts"
                        mkdir -p "$LOG_DIR"
                        ;;
                    "$DEFAULT_TEMP_DIR")
                        export TEMP_DIR="${HOME}/.local/tmp/bash-scripts"
                        mkdir -p "$TEMP_DIR"
                        ;;
                esac
            }
        fi
    done
}

# Load configuration from multiple sources
load_config() {
    local script_name="${1:-default}"
    
    # Create directories if needed
    create_directories
    
    # Load from global config file
    local global_config="/etc/bash-scripts/config"
    [[ -f "$global_config" ]] && source "$global_config"
    
    # Load from user config file
    local user_config="$DEFAULT_CONFIG_DIR/config"
    [[ -f "$user_config" ]] && source "$user_config"
    
    # Load script-specific config
    local script_config="$DEFAULT_CONFIG_DIR/${script_name}.conf"
    [[ -f "$script_config" ]] && source "$script_config"
    
    # Load from .env file in script directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    local env_file="$script_dir/.env"
    [[ -f "$env_file" ]] && source "$env_file"
    
    # Load from project root .env
    local project_root
    project_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "$script_dir")"
    local project_env="$project_root/.env"
    [[ -f "$project_env" ]] && source "$project_env"
}

# Validate required environment variables
validate_required_vars() {
    local vars=("$@")
    local missing=()
    
    for var in "${vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required environment variables: ${missing[*]}" >&2
        echo "Please set them in your environment or config file." >&2
        return 1
    fi
}

# Get configuration value with fallback
get_config() {
    local key="$1"
    local default="${2:-}"
    echo "${!key:-$default}"
}

# Set default values for common configurations
set_defaults() {
    # Logging configuration
    export LOG_LEVEL="${LOG_LEVEL:-INFO}"
    export LOG_FORMAT="${LOG_FORMAT:-'[%Y-%m-%d %H:%M:%S] [%LEVEL%] %MESSAGE%'}"
    
    # Database configuration
    export DB_HOST="${DB_HOST:-localhost}"
    export DB_PORT="${DB_PORT:-27017}"
    
    # Hygieia specific defaults
    export HYGIEIA_INSTALL_PATH="${HYGIEIA_INSTALL_PATH:-/usr/local/src/hygieia}"
    export HYGIEIA_USER="${HYGIEIA_USER:-hygieia}"
    export HYGIEIA_DB_NAME="${HYGIEIA_DB_NAME:-dashboarddb}"
    export HYGIEIA_DB_USER="${HYGIEIA_DB_USER:-dashboarduser}"
    
    # VPN defaults
    export VPN_CONFIG_DIR="${VPN_CONFIG_DIR:-/etc/strongswan/swanctl/conf.d}"
    export VPN_CONNECTION_NAME="${VPN_CONNECTION_NAME:-idrac-vpn}"
    
    # System defaults
    export BACKUP_DIR="${BACKUP_DIR:-/var/backups/bash-scripts}"
    export MAX_LOG_SIZE="${MAX_LOG_SIZE:-10M}"
    export LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-30}"
}

# Initialize configuration system
init_config() {
    local script_name="${1:-$(basename "${BASH_SOURCE[1]}" .sh)}"
    
    # Load all configuration sources
    load_config "$script_name"
    
    # Set default values
    set_defaults
    
    # Export commonly used paths
    export CONFIG_DIR="$DEFAULT_CONFIG_DIR"
    export LOG_DIR="${LOG_DIR:-$DEFAULT_LOG_DIR}"
    export TEMP_DIR="${TEMP_DIR:-$DEFAULT_TEMP_DIR}"
}

# Create a sample configuration file
create_sample_config() {
    local config_file="$DEFAULT_CONFIG_DIR/config.sample"
    
    mkdir -p "$DEFAULT_CONFIG_DIR"
    
    cat > "$config_file" << 'EOF'
# Sample Configuration File for Bash Scripts
# Copy this to 'config' and modify as needed

# Logging Configuration
LOG_LEVEL=INFO
LOG_DIR=/var/log/bash-scripts

# Database Configuration
DB_HOST=localhost
DB_PORT=27017

# Hygieia Configuration
HYGIEIA_INSTALL_PATH=/usr/local/src/hygieia
HYGIEIA_USER=hygieia
HYGIEIA_DB_NAME=dashboarddb
HYGIEIA_DB_USER=dashboarduser
HYGIEIA_DB_PASSWORD=your_secure_password

# VPN Configuration
VPN_SERVER_IP=your_vpn_server_ip
VPN_USER=your_username
VPN_PASSWORD=your_password
IPSEC_PSK=your_ipsec_psk

# System Configuration
BACKUP_DIR=/var/backups/bash-scripts
MAX_LOG_SIZE=10M
LOG_RETENTION_DAYS=30
EOF

    echo "Sample configuration created at: $config_file"
}

# Export functions for use in other scripts
export -f load_config validate_required_vars get_config set_defaults init_config
