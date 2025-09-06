#!/bin/bash

##############################################################################
# Script Name: sethost.sh
# Description: Sets the system hostname in network configuration
# Author: Constantin Radulescu
# Version: 3.0
# Last Modified: 2025-09-06
#
# Usage: sudo ./sethost.sh
#
# Requirements:
#   - Root privileges
#   - Red Hat/CentOS/RHEL system with /etc/sysconfig/network
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Not running as root
#   3 - Network config file not found
##############################################################################

set -euo pipefail

# Load common libraries
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/common.sh"

# Initialize common functionality
init_common "sethost"

# Script configuration
readonly NETWORK_CONFIG="/etc/sysconfig/network"

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Sets the system hostname in the network configuration file.
This script reads the current hostname and updates /etc/sysconfig/network.

Requirements:
- Must be run as root
- Red Hat/CentOS/RHEL system

EOF
    show_common_help
}

# Check if network config file exists
check_network_config() {
    if [[ ! -f "$NETWORK_CONFIG" ]]; then
        log_error "Network configuration file not found: $NETWORK_CONFIG"
        log_error "This script is designed for Red Hat/CentOS/RHEL systems"
        exit 3
    fi
}

# Main function
main() {
    # Parse common arguments first
    local remaining_args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                remaining_args+=($(parse_common_args "$1"))
                shift
                ;;
        esac
    done

    log_info "Starting hostname configuration..."

    # Perform checks
    check_root || exit 2
    check_network_config

    # Get current hostname
    local servername
    servername=$(uname -n)
    log_info "Current hostname: $servername"

    # Backup original file
    local backup_path
    backup_path=$(backup_file "$NETWORK_CONFIG")

    # Remove existing HOSTNAME line and add new one
    sed -i '/^HOSTNAME=/d' "$NETWORK_CONFIG"
    echo "HOSTNAME=$servername" >> "$NETWORK_CONFIG"

    # Verify the change
    log_info "Updated network configuration:"
    if grep "HOSTNAME" "$NETWORK_CONFIG"; then
        log_success "Hostname configuration completed successfully"
    else
        log_error "Failed to set hostname"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

