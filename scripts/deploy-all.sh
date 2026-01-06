#!/bin/bash

# Master deployment script - runs all steps in sequence
# This is a guided walkthrough with pauses between steps

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

pause() {
    echo ""
    read -p "Press Enter to continue or Ctrl+C to exit..."
    echo ""
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo"
   exit 1
fi

# ASCII Art
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║   Nginx Virtual Hosts - Complete Setup       ║"
echo "║   Multiple Sites on Single Server            ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Check if config is filled
source ../config.sh

if [ "$DUCKDNS_TOKEN" = "your-duckdns-token-here" ]; then
    print_error "Configuration not complete!"
    echo ""
    echo "Please edit config.sh and fill in:"
    echo "  - DUCKDNS_TOKEN"
    echo "  - DUCKDNS_DOMAIN1"
    echo "  - DUCKDNS_DOMAIN2"
    echo "  - SERVER_PUBLIC_IP"
    echo "  - SSL_EMAIL"
    exit 1
fi

print_info "Configuration loaded:"
echo "  Domain 1: $DOMAIN1"
echo "  Domain 2: $DOMAIN2"
echo "  Server IP: $SERVER_PUBLIC_IP"
echo ""

print_warning "This script will set up Nginx, deploy websites, and configure SSL."
print_warning "Ensure you have DuckDNS domains ready to point to this server."
pause

# Step 1: Install Nginx
print_step "STEP 1/7: Installing Nginx"
print_info "Installing Nginx web server..."
./01-install-nginx.sh
print_info "✅ Nginx installed successfully!"
pause

# Step 2: Deploy websites
print_step "STEP 2/7: Deploying Websites"
print_info "Copying website files to server..."
./02-deploy-websites.sh
print_info "✅ Websites deployed successfully!"
pause

# Step 3: Configure virtual hosts
print_step "STEP 3/7: Configuring Virtual Hosts"
print_info "Setting up Nginx server blocks..."
./03-configure-virtual-hosts.sh
print_info "✅ Virtual hosts configured successfully!"
echo ""
print_info "Your sites should now be accessible at:"
echo "  http://$DOMAIN1"
echo "  http://$DOMAIN2"
echo ""
print_warning "IMPORTANT: Make sure your DuckDNS domains point to $SERVER_PUBLIC_IP"
echo ""
echo "To configure DuckDNS:"
echo "1. Go to https://www.duckdns.org"
echo "2. Log in"
echo "3. Update both domains to point to: $SERVER_PUBLIC_IP"
echo "4. Wait 1-2 minutes for DNS to propagate"
echo ""
print_info "Test DNS with: dig $DOMAIN1 +short"
pause

# Step 4: Test DNS and HTTP
print_step "STEP 4/7: Verifying DNS and HTTP"
print_info "Testing DNS resolution..."

DNS_IP=$(dig +short $DOMAIN1 | tail -n1)
if [ "$DNS_IP" = "$SERVER_PUBLIC_IP" ]; then
    print_info "✅ DNS for $DOMAIN1 is correct!"
else
    print_warning "DNS for $DOMAIN1 returns: $DNS_IP (expected: $SERVER_PUBLIC_IP)"
    print_warning "Please wait for DNS propagation or check DuckDNS configuration"
    print_warning "You can continue, but SSL setup may fail if DNS is not ready"
fi

DNS_IP2=$(dig +short $DOMAIN2 | tail -n1)
if [ "$DNS_IP2" = "$SERVER_PUBLIC_IP" ]; then
    print_info "✅ DNS for $DOMAIN2 is correct!"
else
    print_warning "DNS for $DOMAIN2 returns: $DNS_IP2 (expected: $SERVER_PUBLIC_IP)"
fi

pause

# Step 5: Obtain SSL certificates
print_step "STEP 5/7: Obtaining SSL Certificates"
print_info "Getting free SSL certificates from Let's Encrypt..."
print_warning "This requires DNS to be working correctly!"
./04-obtain-ssl-certificates.sh
print_info "✅ SSL certificates obtained successfully!"
pause

# Step 6: Configure SSL
print_step "STEP 6/7: Configuring HTTPS"
print_info "Enabling SSL on Nginx..."
./05-configure-ssl.sh
print_info "✅ HTTPS configured successfully!"
echo ""
print_info "Your sites are now secured with SSL:"
echo "  https://$DOMAIN1"
echo "  https://$DOMAIN2"
pause

# Step 7: Validate SSL
print_step "STEP 7/7: Validating SSL Setup"
print_info "Testing SSL certificates..."
./06-validate-ssl.sh
print_info "✅ SSL validation complete!"
echo ""

# Final summary
print_step "🎉 DEPLOYMENT COMPLETE! 🎉"
echo ""
print_info "Summary of what was configured:"
echo ""
echo "  ✅ Nginx web server installed and running"
echo "  ✅ Two websites deployed with unique designs"
echo "  ✅ Virtual hosts configured for domain routing"
echo "  ✅ SSL certificates obtained from Let's Encrypt"
echo "  ✅ HTTPS enabled with automatic HTTP redirect"
echo "  ✅ Certificate auto-renewal configured"
echo ""
print_info "Your websites:"
echo ""
echo "  🌐 Site 1 (Portfolio): https://$DOMAIN1"
echo "  🌐 Site 2 (Store):     https://$DOMAIN2"
echo ""
print_info "Next steps:"
echo "  - Visit your sites in a browser"
echo "  - Check for the padlock icon (secure)"
echo "  - Verify each site shows different content"
echo "  - Customize the HTML/CSS files in /var/www/"
echo ""
print_info "Useful commands:"
echo "  - Test Nginx: sudo nginx -t"
echo "  - Reload Nginx: sudo systemctl reload nginx"
echo "  - Check certs: sudo certbot certificates"
echo "  - View logs: sudo tail -f /var/log/nginx/site1-access.log"
echo ""
print_info "Documentation:"
echo "  - Full guide: docs/DEPLOYMENT_GUIDE.md"
echo "  - Quick ref: docs/QUICK_REFERENCE.md"
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║  🎓 Congratulations on completing this       ║"
echo "║     Nginx virtual hosting project!            ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
