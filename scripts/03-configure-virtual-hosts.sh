#!/bin/bash

# Script to configure Nginx virtual hosts for both sites
# Run this after deploying the websites

# Fail-safe settings
set -euo pipefail
IFS=$'\n\t'

# Script directory and log setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/03-configure-virtual-hosts-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="${SCRIPT_DIR}/../backups/nginx-configs"

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
echo "Nginx Virtual Hosts Configuration"
echo "=================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo"
   exit 1
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    print_error "Nginx is not installed. Run 01-install-nginx.sh first"
    exit 1
fi

print_info "Configuring virtual hosts for:"
echo "  Domain 1: $DOMAIN1"
echo "  Domain 2: $DOMAIN2"
echo ""

# Create temporary config files with actual values
print_info "Creating Site 1 configuration..."
sed -e "s|DOMAIN1_PLACEHOLDER|$DOMAIN1|g" \
    -e "s|SITE1_DIR|$(basename $SITE1_ROOT)|g" \
    ../nginx-configs/site1.conf > /etc/nginx/sites-available/$DUCKDNS_DOMAIN1

print_info "Creating Site 2 configuration..."
sed -e "s|DOMAIN2_PLACEHOLDER|$DOMAIN2|g" \
    -e "s|SITE2_DIR|$(basename $SITE2_ROOT)|g" \
    ../nginx-configs/site2.conf > /etc/nginx/sites-available/$DUCKDNS_DOMAIN2

# Enable sites by creating symbolic links
print_info "Enabling Site 1..."
ln -sf /etc/nginx/sites-available/$DUCKDNS_DOMAIN1 /etc/nginx/sites-enabled/

print_info "Enabling Site 2..."
ln -sf /etc/nginx/sites-available/$DUCKDNS_DOMAIN2 /etc/nginx/sites-enabled/

# Remove default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    print_info "Removing default Nginx site..."
    rm /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
print_info "Testing Nginx configuration..."
if nginx -t; then
    print_info "Nginx configuration is valid!"
    
    # Reload Nginx
    print_info "Reloading Nginx..."
    systemctl reload nginx
    
    echo ""
    print_info "Virtual hosts configured successfully!"
    echo ""
    echo "Your sites should now be accessible at:"
    echo "  http://$DOMAIN1"
    echo "  http://$DOMAIN2"
    echo ""
    print_warning "Make sure your DNS records point to: $SERVER_PUBLIC_IP"
else
    print_error "Nginx configuration test failed!"
    exit 1
fi
