# Script Improvements Documentation

## Overview

All deployment scripts have been enhanced with:
- ✅ **Fail-safe mechanisms** (set -euo pipefail)
- ✅ **Function-based architecture**
- ✅ **Organized logging** (timestamped log files)
- ✅ **Backup/rollback capabilities**
- ✅ **Comprehensive error handling**
- ✅ **Input validation**
- ✅ **Progress tracking**

## Fail-Safe Features

### 1. Strict Error Handling

```bash
set -euo pipefail  # Exit on error, undefined variables, and pipe failures
IFS=$'\n\t'        # Set Internal Field Separator
```

### 2. Error Trapping

```bash
trap 'error_exit "An error occurred on line $LINENO"' ERR
```

### 3. Validation Functions

Each script includes:
- `check_root()` - Verify sudo/root privileges
- `validate_config()` - Check configuration values
- `check_dependencies()` - Verify required tools

## Logging System

### Log File Structure

```
logs/
├── 01-install-nginx-20260106-143022.log
├── 02-deploy-websites-20260106-143145.log
├── 03-configure-virtual-hosts-20260106-143230.log
├── 04-setup-ssl-20260106-143315.log
└── 05-validate-ssl-20260106-143400.log
```

### Log Format

```
[2026-01-06 14:30:22] [INFO] Starting Nginx installation...
[2026-01-06 14:30:23] [STEP] Step 1/7: Updating package list...
[2026-01-06 14:30:45] [INFO] Package list updated successfully
[2026-01-06 14:30:46] [WARNING] UFW not installed, skipping firewall
[2026-01-06 14:30:47] [ERROR] Failed to start Nginx service
```

### Logging Functions

```bash
log_info()     # Green - Success messages
log_warning()  # Yellow - Non-critical issues
log_error()    # Red - Errors
log_step()     # Blue - Major steps
```

## Function Organization

### Script Structure

```bash
# 1. Header & Setup
#!/bin/bash
set -euo pipefail

# 2. Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_DIR}/script-name-$(date +%Y%m%d-%H%M%S).log"

# 3. Logging Functions
log_info() { ... }
log_error() { ... }

# 4. Error Handlers
error_exit() { ... }
trap 'error_exit "..."' ERR

# 5. Validation Functions
check_root() { ... }
validate_config() { ... }

# 6. Backup Functions
backup_existing() { ... }
rollback_if_needed() { ... }

# 7. Core Functions
install_package() { ... }
configure_service() { ... }
verify_installation() { ... }

# 8. Summary Function
display_summary() { ... }

# 9. Main Function
main() {
    log_info "Starting..."
    check_root
    validate_config
    install_package
    configure_service
    verify_installation
    display_summary
}

# 10. Execute
main
```

## Backup System

### Automatic Backups

Scripts automatically create backups before making changes:

```bash
backup_existing() {
    local backup_path="${BACKUP_DIR}/${site_name}-$(date +%Y%m%d-%H%M%S)"
    cp -r "${site_root}" "${backup_path}"
    echo "${backup_path}" >> "${BACKUP_DIR}/backup_list.txt"
}
```

### Backup Directory Structure

```
backups/
├── site1-20260106-143145/
│   ├── index.html
│   └── style.css
├── site2-20260106-143145/
│   ├── index.html
│   └── style.css
├── nginx-configs/
│   └── nginx-backup-20260106-143230/
│       ├── sites-available/
│       └── sites-enabled/
└── backup_list.txt
```

### Rollback Function

```bash
rollback_if_needed() {
    if [[ -f "${BACKUP_DIR}/backup_list.txt" ]]; then
        log_warning "Deployment failed. Backups available in: ${BACKUP_DIR}"
        log_warning "To restore: cp -r ${backup_path}/* ${site_root}/"
    fi
}
```

## Improved Scripts

### 01-install-nginx.sh

**Functions:**
- `check_root()` - Verify permissions
- `check_package_manager()` - Verify apt available
- `update_packages()` - Update package list
- `install_nginx()` - Install Nginx package
- `verify_installation()` - Confirm installation
- `start_nginx()` - Start and enable service
- `check_nginx_status()` - Verify running
- `configure_firewall()` - Setup UFW rules
- `test_configuration()` - Run nginx -t
- `display_summary()` - Show results

**Fail-Safe Features:**
- Checks for existing installation
- Validates each step
- Provides rollback info
- Detailed error messages

### 02-deploy-websites.sh

**Functions:**
- `check_root()` - Verify permissions
- `validate_config()` - Check config.sh values
- `check_source_files()` - Verify website files exist
- `backup_existing()` - Backup current sites
- `create_directories()` - Create web roots
- `deploy_site1()` - Deploy first site
- `deploy_site2()` - Deploy second site
- `set_permissions()` - Set ownership/permissions
- `verify_deployment()` - Confirm files deployed
- `rollback_if_needed()` - Restore on failure
- `display_summary()` - Show results

**Fail-Safe Features:**
- Automatic backups before deployment
- File count verification
- Permission checks
- Rollback capability

### 03-configure-virtual-hosts.sh

**Functions:**
- `check_root()` - Verify permissions
- `check_nginx()` - Verify Nginx installed
- `validate_config()` - Check configuration
- `check_template_files()` - Verify templates exist
- `backup_nginx_configs()` - Backup existing configs
- `create_site_config()` - Generate site configs
- `enable_site()` - Create symlinks
- `disable_default_site()` - Remove default
- `test_nginx_config()` - Run nginx -t
- `reload_nginx()` - Reload service
- `verify_configs()` - Confirm setup
- `rollback_configs()` - Restore on failure
- `display_summary()` - Show results

**Fail-Safe Features:**
- Config backup before changes
- Validation at each step
- Nginx config test before reload
- Rollback instructions

### 04-setup-ssl.sh

**Functions:**
- `check_root()` - Verify permissions
- `check_nginx()` - Verify Nginx running
- `validate_email()` - Check email format
- `check_dns_resolution()` - Test DNS lookup
- `verify_dns_setup()` - Check all domains
- `install_certbot()` - Install certbot
- `obtain_individual_certificates()` - Get certs
- `setup_wildcard_certificates()` - Wildcard info
- `configure_auto_renewal()` - Setup timer
- `verify_ssl_installation()` - Check cert files
- `test_nginx_ssl()` - Validate config
- `display_ssl_info()` - Show cert details
- `display_summary()` - Show results

**Fail-Safe Features:**
- DNS verification before cert request
- Email validation
- Dry-run renewal test
- Certificate file verification
- No changes if DNS not ready

## Error Handling Examples

### Configuration Validation

```bash
validate_config() {
    local errors=0
    
    if [[ -z "${DOMAIN1:-}" ]]; then
        log_error "DOMAIN1 not set"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        error_exit "Configuration validation failed with $errors error(s)"
    fi
}
```

### Command Validation

```bash
install_nginx() {
    if apt install -y nginx; then
        log_info "Nginx installed successfully"
    else
        error_exit "Failed to install Nginx"
    fi
}
```

### File Validation

```bash
if [[ ! -f "${SITE1_ROOT}/index.html" ]]; then
    log_error "index.html not found"
    ((errors++))
fi
```

## Usage Examples

### View Logs

```bash
# View most recent log
tail -f logs/$(ls -t logs/*.log | head -1)

# View specific script
tail -f logs/01-install-nginx-*.log

# Search for errors
grep -i error logs/*.log
```

### Restore from Backup

```bash
# List backups
ls -lt backups/

# Restore site
sudo cp -r backups/site1-20260106-143145/* /var/www/site1/

# Fix permissions
sudo chown -R www-data:www-data /var/www/site1
```

## Best Practices

### 1. Always Check Prerequisites

```bash
check_dependencies() {
    local missing=()
    
    command -v nginx &>/dev/null || missing+=("nginx")
    command -v certbot &>/dev/null || missing+=("certbot")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error_exit "Missing: ${missing[*]}"
    fi
}
```

### 2. Validate Before Action

```bash
# Bad
apt install -y nginx

# Good
if apt install -y nginx; then
    log_info "Installation successful"
else
    error_exit "Installation failed"
fi
```

### 3. Provide Clear Error Messages

```bash
# Bad
error_exit "Failed"

# Good
error_exit "Failed to install Nginx. Check internet connection and try: apt update"
```

### 4. Always Log Important Actions

```bash
log_step "Step 3/7: Deploying website files..."
if cp -r source/* dest/; then
    log_info "✓ Deployed ${file_count} files"
else
    error_exit "Failed to copy files"
fi
```

## Troubleshooting

### If a Script Fails

1. **Check the log file** (path shown in error message)
2. **Look for ERROR or WARNING messages**
3. **Note the line number** where failure occurred
4. **Check if backup was created** (backups/ directory)
5. **Restore if needed** (follow backup README)

### Common Issues

**Permission Denied**
```bash
# Solution: Run with sudo
sudo ./script.sh
```

**Configuration Not Found**
```bash
# Solution: Run from correct directory
cd /path/to/nginx-shared-hosting/scripts
sudo ./script.sh
```

**DNS Not Resolved**
```bash
# Solution: Wait for DNS propagation
# Test with: nslookup your-domain.com
```

## Summary

All scripts now include:
- ✅ Structured functions for maintainability
- ✅ Comprehensive error handling
- ✅ Timestamped logging
- ✅ Automatic backups
- ✅ Input validation
- ✅ Clear progress indicators
- ✅ Detailed summaries
- ✅ Rollback capabilities

This makes the deployment process:
- **Safer** - Backups and validation
- **More reliable** - Error handling
- **Easier to debug** - Detailed logs
- **Maintainable** - Function-based code
- **User-friendly** - Clear messages
