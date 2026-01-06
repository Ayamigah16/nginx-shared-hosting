#!/bin/bash

# Script to deploy website files to server
# This script copies the website files to the appropriate directories on the server

# Fail-safe settings
set -euo pipefail
IFS=$'\n\t'

# Script directory and log setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/02-deploy-websites-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="${SCRIPT_DIR}/../backups"

# Create directories
mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"

# Redirect output to log
exec 1> >(tee -a "${LOG_FILE}")
exec 2>&1

# Load configuration
if [[ ! -f "${SCRIPT_DIR}/../config.sh" ]]; then
    echo "ERROR: config.sh not found!"
    exit 1
fi
source "${SCRIPT_DIR}/../config.sh"

echo "=================================="
echo "Website Deployment Script"
echo "=================================="
echo "Log file: ${LOG_FILE}"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}[STEP]${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    log_error "Deployment failed. Check log: ${LOG_FILE}"
    rollback_if_needed
    exit 1
}

trap 'error_exit "An error occurred on line $LINENO"' ERR

# Validation functions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
    log_info "Root privileges confirmed"
}

validate_config() {
    log_info "Validating configuration..."
    
    local errors=0
    
    if [[ -z "${DOMAIN1:-}" ]]; then
        log_error "DOMAIN1 not set in config.sh"
        ((errors++))
    fi
    
    if [[ -z "${DOMAIN2:-}" ]]; then
        log_error "DOMAIN2 not set in config.sh"
        ((errors++))
    fi
    
    if [[ -z "${SITE1_ROOT:-}" ]]; then
        log_error "SITE1_ROOT not set in config.sh"
        ((errors++))
    fi
    
    if [[ -z "${SITE2_ROOT:-}" ]]; then
        log_error "SITE2_ROOT not set in config.sh"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        error_exit "Configuration validation failed with $errors error(s)"
    fi
    
    log_info "Configuration validated successfully"
}

check_source_files() {
    log_info "Checking source website files..."
    
    if [[ ! -d "${SCRIPT_DIR}/../websites/site1" ]]; then
        error_exit "Source directory not found: ${SCRIPT_DIR}/../websites/site1"
    fi
    
    if [[ ! -f "${SCRIPT_DIR}/../websites/site1/index.html" ]]; then
        error_exit "index.html not found in site1 directory"
    fi
    
    if [[ ! -d "${SCRIPT_DIR}/../websites/site2" ]]; then
        error_exit "Source directory not found: ${SCRIPT_DIR}/../websites/site2"
    fi
    
    if [[ ! -f "${SCRIPT_DIR}/../websites/site2/index.html" ]]; then
        error_exit "index.html not found in site2 directory"
    fi
    
    log_info "Source files verified"
}

# Backup functions
backup_existing() {
    local site_root="$1"
    local site_name="$2"
    
    if [[ -d "${site_root}" ]] && [[ "$(ls -A ${site_root})" ]]; then
        local backup_path="${BACKUP_DIR}/${site_name}-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing ${site_name} to: ${backup_path}"
        
        if cp -r "${site_root}" "${backup_path}"; then
            log_info "Backup created successfully"
            echo "${backup_path}" >> "${BACKUP_DIR}/backup_list.txt"
        else
            log_warning "Backup failed, but continuing..."
        fi
    else
        log_info "No existing ${site_name} to backup"
    fi
}

rollback_if_needed() {
    if [[ -f "${BACKUP_DIR}/backup_list.txt" ]]; then
        log_warning "Deployment failed. Backups are available in: ${BACKUP_DIR}"
        log_warning "To restore manually, check: ${BACKUP_DIR}/backup_list.txt"
    fi
}

# Deployment functions
create_directories() {
    log_step "Step 1/5: Creating website directories..."
    
    if mkdir -p "${SITE1_ROOT}" "${SITE2_ROOT}"; then
        log_info "Directories created:"
        log_info "  - ${SITE1_ROOT}"
        log_info "  - ${SITE2_ROOT}"
    else
        error_exit "Failed to create website directories"
    fi
}

deploy_site1() {
    log_step "Step 2/5: Deploying Site 1 (${DOMAIN1})..."
    
    backup_existing "${SITE1_ROOT}" "site1"
    
    if cp -r "${SCRIPT_DIR}/../websites/site1/"* "${SITE1_ROOT}/"; then
        local file_count=$(find "${SITE1_ROOT}" -type f | wc -l)
        log_info "Site 1 deployed successfully (${file_count} files)"
    else
        error_exit "Failed to deploy Site 1"
    fi
}

deploy_site2() {
    log_step "Step 3/5: Deploying Site 2 (${DOMAIN2})..."
    
    backup_existing "${SITE2_ROOT}" "site2"
    
    if cp -r "${SCRIPT_DIR}/../websites/site2/"* "${SITE2_ROOT}/"; then
        local file_count=$(find "${SITE2_ROOT}" -type f | wc -l)
        log_info "Site 2 deployed successfully (${file_count} files)"
    else
        error_exit "Failed to deploy Site 2"
    fi
}

set_permissions() {
    log_step "Step 4/5: Setting proper permissions..."
    
    # Check if www-data user exists
    if ! id www-data &>/dev/null; then
        log_warning "www-data user not found, using current user"
        local owner=$(whoami)
    else
        local owner="www-data:www-data"
    fi
    
    if chown -R ${owner} "${SITE1_ROOT}" "${SITE2_ROOT}"; then
        log_info "Ownership set to: ${owner}"
    else
        log_warning "Failed to set ownership (may need manual adjustment)"
    fi
    
    if chmod -R 755 "${SITE1_ROOT}" "${SITE2_ROOT}"; then
        log_info "Permissions set to: 755"
    else
        log_warning "Failed to set permissions (may need manual adjustment)"
    fi
}

verify_deployment() {
    log_step "Step 5/5: Verifying deployment..."
    
    local errors=0
    
    # Check Site 1
    if [[ ! -f "${SITE1_ROOT}/index.html" ]]; then
        log_error "Site 1 index.html not found after deployment"
        ((errors++))
    else
        log_info "✓ Site 1 index.html verified"
    fi
    
    if [[ ! -f "${SITE1_ROOT}/style.css" ]]; then
        log_warning "Site 1 style.css not found"
    else
        log_info "✓ Site 1 style.css verified"
    fi
    
    # Check Site 2
    if [[ ! -f "${SITE2_ROOT}/index.html" ]]; then
        log_error "Site 2 index.html not found after deployment"
        ((errors++))
    else
        log_info "✓ Site 2 index.html verified"
    fi
    
    if [[ ! -f "${SITE2_ROOT}/style.css" ]]; then
        log_warning "Site 2 style.css not found"
    else
        log_info "✓ Site 2 style.css verified"
    fi
    
    if [[ $errors -gt 0 ]]; then
        error_exit "Deployment verification failed with $errors error(s)"
    fi
    
    log_info "Deployment verification passed"
}

display_summary() {
    echo ""
    echo "========================================"
    log_info "Website deployment completed successfully!"
    echo "========================================"
    echo ""
    
    echo "📁 Deployed sites:"
    echo "  Site 1 (${DOMAIN1}): ${SITE1_ROOT}"
    echo "  Site 2 (${DOMAIN2}): ${SITE2_ROOT}"
    echo ""
    
    echo "📊 Deployment log: ${LOG_FILE}"
    
    if [[ -f "${BACKUP_DIR}/backup_list.txt" ]]; then
        echo "💾 Backups saved in: ${BACKUP_DIR}"
    fi
    
    echo ""
    echo "✅ Next step: Configure Nginx virtual hosts"
    echo "   Run: sudo ./03-configure-virtual-hosts.sh"
    echo ""
}

# Main execution
main() {
    log_info "Starting website deployment script..."
    log_info "Timestamp: $(date)"
    echo ""
    
    check_root
    validate_config
    check_source_files
    create_directories
    deploy_site1
    deploy_site2
    set_permissions
    verify_deployment
    display_summary
    
    log_info "Script execution completed successfully"
}

# Run main function
main
