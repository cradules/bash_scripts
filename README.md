# Bash Scripts Collection

A modernized collection of bash scripts for system administration, infrastructure setup, and development tools.

## 🚀 Overview

This repository contains a curated collection of bash scripts organized into logical categories. All scripts have been modernized with:

- **Standardized structure** with consistent headers and documentation
- **Error handling** and input validation
- **Configuration management** using environment variables
- **Common libraries** for logging, utilities, and configuration
- **Testing framework** for script validation
- **Security improvements** with sensitive data removed

## 📁 Repository Structure

```
├── scripts/
│   ├── common/           # Shared libraries and utilities
│   ├── development/      # Development tools and environment setup
│   ├── infrastructure/   # Infrastructure and installation scripts
│   ├── media/           # Media and camera-related scripts
│   ├── monitoring/      # Monitoring and dashboard tools
│   ├── security/        # Security and VPN configuration
│   └── system/          # System administration scripts
├── templates/           # Configuration templates
├── configs/            # Configuration examples
├── tests/              # Test suite
└── docs/               # Additional documentation
```

## 🛠️ Script Categories

### Infrastructure (`scripts/infrastructure/`)
- **Docker installation and setup**
- **Kubernetes cluster configuration**
- **Database installations** (MongoDB, PostgreSQL)
- **Hygieia dashboard deployment**

### Security (`scripts/security/`)
- **Kerberos authentication setup**
- **L2TP/IPsec VPN client configuration**
- **SSL/TLS certificate management**

### Monitoring (`scripts/monitoring/`)
- **Hygieia dashboard services**
- **System monitoring tools**
- **Log management utilities**

### System (`scripts/system/`)
- **Hostname configuration**
- **Network setup utilities**
- **System maintenance scripts**

### Development (`scripts/development/`)
- **Solr search tools**
- **Environment setup scripts**
- **Auto-completion utilities**

### Media (`scripts/media/`)
- **Camera console interfaces**
- **Video streaming tools**
- **Media processing utilities**

## 🔧 Prerequisites

### System Requirements
- **Linux distribution**: Red Hat/CentOS/RHEL/Fedora (primary), Ubuntu/Debian (partial support)
- **Bash**: Version 4.0 or higher
- **Root privileges**: Required for most system-level scripts

### Required Packages
```bash
# Red Hat/CentOS/RHEL/Fedora
sudo dnf install -y git curl wget

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git curl wget
```

## ⚙️ Configuration

### Environment Variables
Copy the example environment file and configure your settings:

```bash
cp .env.example .env
# Edit .env with your specific configuration
```

### Key Configuration Variables
```bash
# Hygieia Configuration
HYGIEIA_ENCRYPTOR_PASSWORD=your_secure_password
HYGIEIA_DB_USER=dashboarduser
HYGIEIA_DB_PASSWORD=your_database_password

# VPN Configuration
VPN_SERVER_IP=your_vpn_server_ip
VPN_USER=your_username
VPN_PASSWORD=your_password
IPSEC_PSK=your_ipsec_psk

# Logging Configuration
LOG_LEVEL=INFO
LOG_DIR=/var/log/bash-scripts
```

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/cradules/bash_scripts.git
cd bash_scripts
```

### 2. Set Up Configuration
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Run a Script
```bash
# Example: Configure system hostname
sudo scripts/system/sethost.sh

# Example: Install Hygieia dashboard
sudo scripts/infrastructure/install-scripts/install-hygieia.sh sdb
```

### 4. Run Tests
```bash
# Run all tests
tests/run-tests.sh

# Run specific test
tests/run-tests.sh test_sethost.sh

# Run tests with verbose output
tests/run-tests.sh --verbose
```

## 📖 Detailed Usage

### Common Libraries

All scripts use shared libraries located in `scripts/common/`:

- **`common.sh`**: Main library loader
- **`config.sh`**: Configuration management
- **`logging.sh`**: Centralized logging
- **`utils.sh`**: Common utility functions

#### Using Common Libraries in Your Scripts
```bash
#!/bin/bash
# Load common libraries
source "$(dirname "${BASH_SOURCE[0]}")/../common/common.sh"

# Initialize common functionality
init_common "my-script"

# Use logging functions
log_info "Starting script execution"
log_error "Something went wrong"
log_success "Operation completed"

# Use utility functions
check_root || exit 2
check_dependencies "curl" "wget" "git"
```

### Script Examples

#### System Hostname Configuration
```bash
# Configure system hostname
sudo scripts/system/sethost.sh

# With verbose logging
sudo scripts/system/sethost.sh --verbose

# Show help
scripts/system/sethost.sh --help
```

#### Hygieia Dashboard Installation
```bash
# Install on device sdb with environment variables
export HYGIEIA_DB_PASSWORD="secure_password"
sudo scripts/infrastructure/install-scripts/install-hygieia.sh sdb
```

#### VPN Setup
```bash
# Configure environment variables
export VPN_SERVER_IP="192.168.1.100"
export VPN_USER="myuser"
export VPN_PASSWORD="mypassword"
export IPSEC_PSK="shared_secret"

# Run VPN setup
sudo scripts/security/l2p-vpn-setup/l2p-vpn-setup.sh
```

## 🧪 Testing

### Running Tests
The repository includes a comprehensive testing framework:

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test file
./tests/run-tests.sh test_sethost.sh

# Run tests matching a pattern
./tests/run-tests.sh --filter sethost

# List available tests
./tests/run-tests.sh --list

# Verbose test output
./tests/run-tests.sh --verbose
```

### Writing Tests
Create new test files in the `tests/` directory following the naming convention `test_*.sh`:

```bash
#!/bin/bash
# Load test framework
source "$(dirname "${BASH_SOURCE[0]}")/test-framework.sh"

# Write test functions
test_my_function() {
    start_test "My function test"

    # Test assertions
    assert_equals "expected" "actual" "Values should match"
    assert_true 0 "Command should succeed"
    assert_file_exists "/path/to/file" "File should exist"
}

# Run the test
test_my_function
```

## 🔒 Security

### Sensitive Data Handling
- **No hardcoded passwords**: All sensitive data uses environment variables
- **Configuration templates**: Sensitive configs are templated
- **Backup creation**: Original files are backed up before modification
- **Input validation**: All user inputs are validated

### Environment Variables
Store sensitive configuration in environment variables or `.env` files:

```bash
# Create .env file (never commit this)
cp .env.example .env
chmod 600 .env

# Source environment variables
source .env
```

## 🤝 Contributing

### Code Standards
1. **Use the common libraries** for consistency
2. **Follow the script template** in `templates/script-header.template`
3. **Add proper error handling** and input validation
4. **Write tests** for new functionality
5. **Update documentation** for new scripts

### Adding New Scripts
1. Place scripts in appropriate category directory
2. Use the standard header template
3. Source common libraries
4. Add configuration to `.env.example`
5. Write tests in `tests/test_*.sh`
6. Update this README

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes following the standards
4. Add/update tests
5. Update documentation
6. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Common Issues
- **Permission denied**: Ensure scripts are executable (`chmod +x script.sh`)
- **Missing dependencies**: Install required packages for your distribution
- **Configuration errors**: Check environment variables in `.env`

### Getting Help
1. Check the script's help: `script.sh --help`
2. Review the logs in `/var/log/bash-scripts/`
3. Run tests to validate setup: `tests/run-tests.sh`
4. Open an issue on GitHub

## 📊 Project Status

- ✅ **Modernized structure** with logical organization
- ✅ **Security improvements** with sensitive data removed
- ✅ **Common libraries** for consistency
- ✅ **Testing framework** for validation
- ✅ **Comprehensive documentation**
- 🔄 **Ongoing**: Additional script modernization
- 🔄 **Ongoing**: Extended test coverage

---

**Last Updated**: 2025-09-06
**Version**: 2.0
**Maintainer**: Constantin Radulescu
