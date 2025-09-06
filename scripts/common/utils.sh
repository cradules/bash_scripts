#!/bin/bash

##############################################################################
# Common Utilities Library
# Description: Common utility functions for all scripts
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        return 1
    fi
}

# Check if commands exist
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -ne 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_error "Please install them and try again."
        return 1
    fi
}

# Check if a service is running
is_service_running() {
    local service="$1"
    systemctl is-active --quiet "$service"
}

# Check if a port is open
is_port_open() {
    local host="${1:-localhost}"
    local port="$2"
    local timeout="${3:-5}"
    
    timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
}

# Wait for a service to be ready
wait_for_service() {
    local service="$1"
    local timeout="${2:-60}"
    local interval="${3:-2}"
    
    log_info "Waiting for service $service to be ready..."
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if is_service_running "$service"; then
            log_success "Service $service is ready"
            return 0
        fi
        
        sleep "$interval"
        count=$((count + interval))
    done
    
    log_error "Service $service failed to start within $timeout seconds"
    return 1
}

# Wait for a port to be open
wait_for_port() {
    local host="${1:-localhost}"
    local port="$2"
    local timeout="${3:-60}"
    local interval="${4:-2}"
    
    log_info "Waiting for $host:$port to be available..."
    
    local count=0
    while [[ $count -lt $timeout ]]; do
        if is_port_open "$host" "$port" 1; then
            log_success "Port $host:$port is available"
            return 0
        fi
        
        sleep "$interval"
        count=$((count + interval))
    done
    
    log_error "Port $host:$port not available within $timeout seconds"
    return 1
}

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")}"
    
    if [[ ! -f "$file" ]]; then
        log_warn "File $file does not exist, skipping backup"
        return 0
    fi
    
    local backup_name
    backup_name="$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
    local backup_path="$backup_dir/$backup_name"
    
    mkdir -p "$backup_dir"
    
    if cp "$file" "$backup_path"; then
        log_info "Created backup: $backup_path"
        echo "$backup_path"
    else
        log_error "Failed to create backup of $file"
        return 1
    fi
}

# Download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local retries="${3:-3}"
    local timeout="${4:-30}"
    
    local attempt=1
    while [[ $attempt -le $retries ]]; do
        log_info "Downloading $url (attempt $attempt/$retries)..."
        
        if command -v curl &> /dev/null; then
            if curl -L --connect-timeout "$timeout" --max-time $((timeout * 2)) -o "$output" "$url"; then
                log_success "Downloaded $url to $output"
                return 0
            fi
        elif command -v wget &> /dev/null; then
            if wget --timeout="$timeout" -O "$output" "$url"; then
                log_success "Downloaded $url to $output"
                return 0
            fi
        else
            log_error "Neither curl nor wget is available"
            return 1
        fi
        
        log_warn "Download attempt $attempt failed"
        attempt=$((attempt + 1))
        [[ $attempt -le $retries ]] && sleep 2
    done
    
    log_error "Failed to download $url after $retries attempts"
    return 1
}

# Get system information
get_os_info() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID $VERSION_ID"
    elif [[ -f /etc/redhat-release ]]; then
        cat /etc/redhat-release
    else
        uname -s
    fi
}

# Check if package is installed (works with yum/dnf and apt)
is_package_installed() {
    local package="$1"
    
    if command -v rpm &> /dev/null; then
        rpm -q "$package" &> /dev/null
    elif command -v dpkg &> /dev/null; then
        dpkg -l "$package" &> /dev/null 2>&1
    else
        log_warn "Cannot determine package manager"
        return 1
    fi
}

# Install package using appropriate package manager
install_package() {
    local package="$1"
    
    if is_package_installed "$package"; then
        log_info "Package $package is already installed"
        return 0
    fi
    
    log_info "Installing package: $package"
    
    if command -v dnf &> /dev/null; then
        dnf install -y "$package"
    elif command -v yum &> /dev/null; then
        yum install -y "$package"
    elif command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y "$package"
    else
        log_error "No supported package manager found"
        return 1
    fi
}

# Generate random password
generate_password() {
    local length="${1:-16}"
    local chars='A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?'
    
    if command -v openssl &> /dev/null; then
        openssl rand -base64 32 | tr -d "=+/" | cut -c1-"$length"
    elif [[ -c /dev/urandom ]]; then
        tr -dc "$chars" < /dev/urandom | head -c"$length"
    else
        log_error "Cannot generate random password"
        return 1
    fi
}

# Validate IP address
is_valid_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    if [[ $ip =~ $regex ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Cleanup function for temporary files
cleanup_temp_files() {
    local temp_dir="${TEMP_DIR:-/tmp/bash-scripts}"
    if [[ -d "$temp_dir" ]]; then
        find "$temp_dir" -type f -mtime +1 -delete 2>/dev/null || true
    fi
}

# Export functions for use in other scripts
export -f check_root check_dependencies is_service_running is_port_open
export -f wait_for_service wait_for_port backup_file download_file
export -f get_os_info is_package_installed install_package
export -f generate_password is_valid_ip cleanup_temp_files
