#!/bin/bash
set -euo pipefail

# ================================================================================
# Nginx Installation and Configuration Script
# Ubuntu/Debian - Setup Nginx for multiple virtual hosts
# ================================================================================

# Script directory and log setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/01-install-nginx-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir -p "${LOG_DIR}"

# Redirect output to both console and log file
exec 1> >(tee -a "${LOG_FILE}")
exec 2>&1

echo "================================================================================"
echo "                    Nginx Multi-Site Installation Script"
echo "================================================================================"
echo "Log file: ${LOG_FILE}"
echo "Started: $(date)"
echo "================================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================================================================================
# Logging Functions
# ================================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

error_exit() {
    log_error "$1"
    log_error "Installation failed. Check log: ${LOG_FILE}"
    exit 1
}

# Trap errors
trap 'error_exit "An error occurred on line $LINENO"' ERR

# ================================================================================
# Validation Functions
# ================================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo"
    fi
    log_info "Root privileges confirmed"
}

check_package_manager() {
    if ! command -v apt &> /dev/null; then
        error_exit "APT package manager not found. This script is for Debian/Ubuntu systems."
    fi
    log_info "Package manager (apt) available"
}

is_package_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# ================================================================================
# System Update Functions
# ================================================================================

update_packages() {
    log_step "Step 1/7: Updating package lists..."
    
    if sudo apt update; then
        log_success "Package lists updated successfully"
    else
        error_exit "Failed to update package lists"
    fi
}

# ================================================================================
# Nginx Installation Functions
# ================================================================================

install_nginx() {
    log_step "Step 2/7: Installing Nginx..."
    
    if command -v nginx &> /dev/null; then
        local version=$(nginx -v 2>&1 | cut -d'/' -f2)
        log_warning "Nginx already installed (version: ${version})"
        return 0
    fi
    
    if sudo apt install -y nginx; then
        log_success "Nginx installed successfully"
    else
        error_exit "Failed to install Nginx"
    fi
}

verify_installation() {
    log_step "Step 3/7: Verifying Nginx installation..."
    
    if ! command -v nginx &> /dev/null; then
        error_exit "Nginx installation verification failed"
    fi
    
    local version=$(nginx -v 2>&1 | cut -d'/' -f2)
    log_success "Nginx version: ${version}"
}

# ================================================================================
# Nginx Service Management Functions
# ================================================================================

start_nginx_service() {
    log_step "Step 4/7: Starting Nginx service..."
    
    if sudo systemctl is-active --quiet nginx; then
        log_warning "Nginx is already running"
    else
        if sudo systemctl start nginx; then
            log_success "Nginx started successfully"
        else
            error_exit "Failed to start Nginx"
        fi
    fi
}

enable_nginx_service() {
    log_info "Enabling Nginx at boot..."
    
    if sudo systemctl is-enabled --quiet nginx; then
        log_warning "Nginx already enabled at boot"
    else
        if sudo systemctl enable nginx; then
            log_success "Nginx enabled for auto-start on boot"
        else
            log_warning "Failed to enable Nginx auto-start"
        fi
    fi
}

verify_nginx_status() {
    log_step "Step 5/7: Checking Nginx status..."
    
    if sudo systemctl is-active --quiet nginx; then
        log_success "Nginx is running"
        echo ""
        log_info "Nginx status:"
        sudo systemctl status nginx --no-pager | head -10
    else
        error_exit "Nginx is not running"
    fi
}

# ================================================================================
# Firewall Configuration Functions
# ================================================================================

configure_firewall() {
    log_step "Step 6/7: Configuring firewall..."
    
    if ! command -v ufw &> /dev/null; then
        log_info "UFW not installed, skipping firewall configuration"
        return 0
    fi
    
    if ! sudo ufw status | grep -q "Status: active"; then
        log_info "UFW is inactive, skipping firewall rules"
        return 0
    fi
    
    log_info "Configuring UFW rules for Nginx..."
    
    if sudo ufw allow 'Nginx Full'; then
        log_success "Firewall rules added for Nginx (HTTP + HTTPS)"
        echo ""
        log_info "Current UFW status:"
        sudo ufw status | grep -i nginx
    else
        log_warning "Failed to add firewall rules (may need manual configuration)"
    fi
}

# ================================================================================
# Configuration Test Functions
# ================================================================================

test_nginx_config() {
    log_step "Step 7/7: Testing Nginx configuration..."
    
    if nginx -t 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Nginx configuration test passed"
    else
        error_exit "Nginx configuration test failed"
    fi
}

# ================================================================================
# Display Functions
# ================================================================================

display_summary() {
    local public_ip
    public_ip=$(hostname -I | awk '{print $1}')
    echo ""
    echo "========================================"
    log_info "Nginx installation completed successfully!"
    echo "========================================"
    echo ""
    
    echo "📁 Important Nginx directories:"
    echo "  - Config files: /etc/nginx/"
    echo "  - Site configs: /etc/nginx/sites-available/"
    echo "  - Enabled sites: /etc/nginx/sites-enabled/"
    echo "  - Default web root: /var/www/html/"
    echo "  - Logs: /var/log/nginx/"
    echo ""
    
    echo "📝 Useful commands:"
    echo "  - Test config: sudo nginx -t"
    echo "  - Reload: sudo systemctl reload nginx"
    echo "  - Restart: sudo systemctl restart nginx"
    echo "  - Status: sudo systemctl status nginx"
    echo ""
    
    echo "📊 Installation log: ${LOG_FILE}"
    echo ""
    
    local server_ip=$(hostname -I | awk '{print $1}')
    if [[ -n "${server_ip}" ]]; then
        echo "🌐 Access default site at: http://${server_ip}"
    fi
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    log_info "Starting Nginx installation script..."
    log_info "Timestamp: $(date)"
    echo ""
    
    # Pre-flight checks
    check_root
    check_package_manager
    
    # System updates
    update_packages
    
    # Install Nginx
    install_nginx
    verify_installation
    
    # Service management
    start_nginx_service
    enable_nginx_service
    verify_nginx_status
    
    # Firewall configuration
    configure_firewall
    
    # Configuration test
    test_nginx_config
    
    # Display summary
    display_summary
    
    log_success "Script execution completed successfully"
}

# ================================================================================
# Script Entry Point
# ================================================================================

main "$@"
