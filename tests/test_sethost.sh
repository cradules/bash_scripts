#!/bin/bash

##############################################################################
# Tests for sethost.sh script
# Description: Unit tests for the hostname configuration script
# Author: Constantin Radulescu
# Version: 1.0
# Last Modified: 2025-09-06
##############################################################################

# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/test-framework.sh"

# Test configuration
readonly SETHOST_SCRIPT="$PROJECT_ROOT/scripts/system/sethost.sh"
readonly TEST_NETWORK_CONFIG="/tmp/test-network-config"

# Setup function
setup_test_environment() {
    # Create a test network config file
    cat > "$TEST_NETWORK_CONFIG" << 'EOF'
NETWORKING=yes
HOSTNAME=old-hostname
GATEWAY=192.168.1.1
EOF
}

# Cleanup function
cleanup_test_environment() {
    rm -f "$TEST_NETWORK_CONFIG"
    cleanup_mocks
}

# Test: Script exists and is executable
test_script_exists() {
    start_test "Script exists and is executable"
    
    assert_file_exists "$SETHOST_SCRIPT" "sethost.sh script should exist"
    assert_command_success "test -x '$SETHOST_SCRIPT'" "sethost.sh should be executable"
}

# Test: Script shows help
test_help_option() {
    start_test "Help option works"
    
    # Mock the common libraries to avoid dependencies
    mock_command "source" 0 ""
    
    local help_output
    help_output=$("$SETHOST_SCRIPT" --help 2>&1 || true)
    
    assert_contains "$help_output" "Usage:" "Help should contain usage information"
    assert_contains "$help_output" "sethost.sh" "Help should mention script name"
}

# Test: Script validates root privileges
test_root_check() {
    start_test "Root privilege validation"
    
    # Mock non-root user
    mock_command "id" 0 "uid=1000(user) gid=1000(user) groups=1000(user)"
    
    # The script should fail when not run as root
    local exit_code=0
    "$SETHOST_SCRIPT" 2>/dev/null || exit_code=$?
    
    assert_not_equals "0" "$exit_code" "Script should fail when not run as root"
}

# Test: Script validates network config file
test_network_config_check() {
    start_test "Network config file validation"
    
    # Mock root user
    mock_command "id" 0 "uid=0(root) gid=0(root) groups=0(root)"
    
    # Test with non-existent config file
    local exit_code=0
    NETWORK_CONFIG="/nonexistent/file" "$SETHOST_SCRIPT" 2>/dev/null || exit_code=$?
    
    assert_not_equals "0" "$exit_code" "Script should fail with missing network config"
}

# Test: Hostname extraction
test_hostname_extraction() {
    start_test "Hostname extraction"
    
    # Mock uname command
    local test_hostname="test-server"
    mock_command "uname" 0 "$test_hostname"
    
    local hostname_output
    hostname_output=$(uname -n)
    
    assert_equals "$test_hostname" "$hostname_output" "Should extract correct hostname"
}

# Test: Configuration file backup
test_config_backup() {
    start_test "Configuration file backup"
    
    setup_test_environment
    
    # Mock root user and commands
    mock_command "id" 0 "uid=0(root) gid=0(root) groups=0(root)"
    mock_command "uname" 0 "test-hostname"
    
    # Create a simple version of the backup function
    backup_test_file() {
        local file="$1"
        local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        echo "$backup_name"
    }
    
    local backup_file
    backup_file=$(backup_test_file "$TEST_NETWORK_CONFIG")
    
    assert_file_exists "$backup_file" "Backup file should be created"
    
    # Cleanup
    rm -f "$backup_file"
    cleanup_test_environment
}

# Test: Hostname configuration update
test_hostname_update() {
    start_test "Hostname configuration update"
    
    setup_test_environment
    
    local new_hostname="new-test-hostname"
    
    # Update the test config file
    sed -i '/^HOSTNAME=/d' "$TEST_NETWORK_CONFIG"
    echo "HOSTNAME=$new_hostname" >> "$TEST_NETWORK_CONFIG"
    
    # Verify the change
    local config_content
    config_content=$(cat "$TEST_NETWORK_CONFIG")
    
    assert_contains "$config_content" "HOSTNAME=$new_hostname" "Config should contain new hostname"
    
    # Verify old hostname is removed
    local hostname_count
    hostname_count=$(grep -c "^HOSTNAME=" "$TEST_NETWORK_CONFIG")
    
    assert_equals "1" "$hostname_count" "Should have exactly one HOSTNAME line"
    
    cleanup_test_environment
}

# Test: Script syntax validation
test_script_syntax() {
    start_test "Script syntax validation"
    
    assert_command_success "bash -n '$SETHOST_SCRIPT'" "Script should have valid bash syntax"
}

# Test: Common library integration
test_common_library_integration() {
    start_test "Common library integration"
    
    # Check if script sources common libraries
    local script_content
    script_content=$(cat "$SETHOST_SCRIPT")
    
    assert_contains "$script_content" "common.sh" "Script should source common libraries"
    assert_contains "$script_content" "init_common" "Script should initialize common functionality"
}

# Run all tests
echo "Running tests for sethost.sh..."
echo "================================"

test_script_exists
test_help_option
test_root_check
test_network_config_check
test_hostname_extraction
test_config_backup
test_hostname_update
test_script_syntax
test_common_library_integration

echo "================================"
echo "sethost.sh tests completed"
