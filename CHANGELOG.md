# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-09-06

### 🚀 Major Modernization Release

This release represents a complete modernization of the bash scripts repository with significant improvements in structure, security, and maintainability.

### Added

#### Repository Structure
- **New organized directory structure** with logical categorization
  - `scripts/infrastructure/` - Infrastructure and installation scripts
  - `scripts/security/` - Security and VPN configuration
  - `scripts/monitoring/` - Monitoring and dashboard tools
  - `scripts/system/` - System administration scripts
  - `scripts/development/` - Development tools and environment setup
  - `scripts/media/` - Media and camera-related scripts
  - `scripts/common/` - Shared libraries and utilities

#### Common Libraries System
- **`scripts/common/common.sh`** - Main library loader
- **`scripts/common/config.sh`** - Centralized configuration management
- **`scripts/common/logging.sh`** - Standardized logging with colors and levels
- **`scripts/common/utils.sh`** - Common utility functions

#### Testing Framework
- **`tests/test-framework.sh`** - Lightweight testing framework for bash scripts
- **`tests/run-tests.sh`** - Test runner with filtering and verbose options
- **`tests/test_sethost.sh`** - Example test suite for sethost.sh script

#### Configuration Management
- **`.env.example`** - Template for environment variables
- **`templates/`** directory with configuration templates
- **Environment variable support** for all sensitive configuration

#### Documentation
- **Comprehensive README.md** with usage examples and setup instructions
- **Script header templates** with standardized documentation format
- **Inline documentation** for all functions and complex logic

### Changed

#### Security Improvements
- **Removed hardcoded passwords** from all scripts
- **Environment variable configuration** for sensitive data
- **Sanitized domain names** and personal information
- **Input validation** and error checking

#### Script Modernization
- **Standardized headers** with version, author, and usage information
- **Error handling** with `set -euo pipefail`
- **Consistent logging** using common libraries
- **Improved argument parsing** with help options
- **Backup functionality** before making changes

#### Specific Script Updates
- **`sethost.sh`** - Complete rewrite with error handling and common libraries
- **`install-hygieia.sh`** - Added environment variable support for database credentials
- **`l2p-vpn-setup.sh`** - Environment variable configuration for VPN settings
- **`initapi.sh`** - Removed hardcoded encryption password

### Moved

#### File Reorganization
- **Docker scripts** → `scripts/infrastructure/docker/`
- **Installation scripts** → `scripts/infrastructure/install-scripts/`
- **GitLab configs** → `scripts/infrastructure/gitlab/`
- **Kerberos scripts** → `scripts/security/kerberos_scripts/`
- **VPN setup** → `scripts/security/l2p-vpn-setup/`
- **Hygieia tools** → `scripts/monitoring/hygieia/`
- **Camera console** → `scripts/media/camera_console/`
- **Restreamer** → `scripts/media/restreamer/`
- **Solr tools** → `scripts/development/solr-tools/`
- **Environment setup** → `scripts/development/set-environment/`
- **System scripts** → `scripts/system/`

#### Configuration Files
- **Apache vhost config** → `templates/default.apache-vhost.conf.template`
- **Docker compose** → `templates/docker-compose.yaml.template`
- **Kerberos config** → `configs/examples/kerberos.conf`

### Removed

#### Security Cleanup
- **Hardcoded passwords** in Hygieia scripts
- **Database credentials** in installation scripts
- **Personal domain names** from configuration files
- **Sensitive configuration data** from version control

#### Obsolete Files
- **Generic GitHub Pages README** replaced with project-specific documentation
- **Unused configuration files** consolidated into templates

### Fixed

#### Script Issues
- **Syntax errors** and bash best practices violations
- **Missing error handling** in critical operations
- **Inconsistent exit codes** and return values
- **Path handling** and directory creation issues

#### Security Vulnerabilities
- **Credential exposure** in script files
- **Insufficient input validation**
- **Missing file permission checks**
- **Unsafe temporary file handling**

## [1.0.0] - Previous Version

### Initial State
- Collection of various bash scripts for system administration
- Basic functionality for infrastructure setup and monitoring
- Scripts scattered across different directories
- Minimal documentation and error handling

---

## Migration Guide

### For Existing Users

1. **Update your environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Update script paths**:
   - Old: `./sethost.sh` → New: `scripts/system/sethost.sh`
   - Old: `./install-hygieia.sh` → New: `scripts/infrastructure/install-scripts/install-hygieia.sh`

3. **Set environment variables**:
   ```bash
   # Instead of editing scripts directly, use environment variables
   export HYGIEIA_DB_PASSWORD="your_password"
   export VPN_SERVER_IP="your_server_ip"
   ```

4. **Run tests**:
   ```bash
   tests/run-tests.sh
   ```

### Breaking Changes

- **Script locations changed** - Update any automation that calls scripts directly
- **Configuration method changed** - Use environment variables instead of editing scripts
- **Some script arguments changed** - Check `--help` for updated usage

### Compatibility

- **Backward compatibility** maintained for core functionality
- **New features** available through common libraries
- **Legacy scripts** still functional but deprecated
