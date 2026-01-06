#!/bin/bash

# Pre-deployment checklist script
# Validates that all requirements are met before deployment

echo "╔═══════════════════════════════════════════════╗"
echo "║   Pre-Deployment Checklist                   ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
WARN="${YELLOW}!${NC}"

# Track overall status
ALL_GOOD=true

echo "Checking requirements..."
echo ""

# 1. Check if config.sh exists
if [ -f "../config.sh" ]; then
    echo -e "$PASS config.sh file exists"
    source ../config.sh
else
    echo -e "$FAIL config.sh file not found"
    ALL_GOOD=false
fi

# 2. Check if DuckDNS token is set
if [ ! -z "$DUCKDNS_TOKEN" ] && [ "$DUCKDNS_TOKEN" != "your-duckdns-token-here" ]; then
    echo -e "$PASS DuckDNS token configured"
else
    echo -e "$FAIL DuckDNS token not configured in config.sh"
    ALL_GOOD=false
fi

# 3. Check if domains are set
if [ ! -z "$DUCKDNS_DOMAIN1" ] && [ "$DUCKDNS_DOMAIN1" != "site1" ]; then
    echo -e "$PASS Domain 1 configured: $DOMAIN1"
else
    echo -e "$WARN Domain 1 using default value (site1)"
fi

if [ ! -z "$DUCKDNS_DOMAIN2" ] && [ "$DUCKDNS_DOMAIN2" != "site2" ]; then
    echo -e "$PASS Domain 2 configured: $DOMAIN2"
else
    echo -e "$WARN Domain 2 using default value (site2)"
fi

# 4. Check if IP is set
if [ ! -z "$SERVER_PUBLIC_IP" ] && [ "$SERVER_PUBLIC_IP" != "0.0.0.0" ]; then
    echo -e "$PASS Server IP configured: $SERVER_PUBLIC_IP"
else
    echo -e "$FAIL Server IP not configured in config.sh"
    ALL_GOOD=false
fi

# 5. Check if email is set
if [ ! -z "$SSL_EMAIL" ] && [ "$SSL_EMAIL" != "your-email@example.com" ]; then
    echo -e "$PASS SSL email configured: $SSL_EMAIL"
else
    echo -e "$FAIL SSL email not configured in config.sh"
    ALL_GOOD=false
fi

# 6. Check if running on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "$PASS Running on Linux"
else
    echo -e "$WARN Not running on Linux (OS: $OSTYPE)"
fi

# 7. Check if scripts are executable
if [ -x "./01-install-nginx.sh" ]; then
    echo -e "$PASS Deployment scripts are executable"
else
    echo -e "$WARN Scripts may not be executable (run: chmod +x *.sh)"
fi

# 8. Check website files exist
if [ -f "../websites/site1/index.html" ] && [ -f "../websites/site2/index.html" ]; then
    echo -e "$PASS Website files present"
else
    echo -e "$FAIL Website files missing"
    ALL_GOOD=false
fi

# 9. Check nginx config files exist
if [ -f "../nginx-configs/site1.conf" ] && [ -f "../nginx-configs/site2.conf" ]; then
    echo -e "$PASS Nginx config files present"
else
    echo -e "$FAIL Nginx config files missing"
    ALL_GOOD=false
fi

# 10. Check internet connectivity (optional)
if ping -c 1 google.com &> /dev/null; then
    echo -e "$PASS Internet connectivity"
else
    echo -e "$WARN No internet connectivity detected"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✓ All critical requirements met!${NC}"
    echo ""
    echo "You're ready to deploy. Run:"
    echo "  sudo ./deploy-all.sh"
    echo ""
    echo "Or run scripts individually:"
    echo "  sudo ./01-install-nginx.sh"
    echo "  sudo ./02-deploy-websites.sh"
    echo "  sudo ./03-configure-virtual-hosts.sh"
    echo "  (Update DuckDNS manually)"
    echo "  sudo ./04-obtain-ssl-certificates.sh"
    echo "  sudo ./05-configure-ssl.sh"
    echo "  sudo ./06-validate-ssl.sh"
else
    echo -e "${RED}✗ Some requirements are not met${NC}"
    echo ""
    echo "Please address the issues above before deploying."
    echo ""
    echo "Common fixes:"
    echo "  1. Edit config.sh and fill in your values"
    echo "  2. Get DuckDNS token from https://www.duckdns.org"
    echo "  3. Register 2 DuckDNS domains"
    echo "  4. Provision a Linux server and note its IP"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration Summary:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Domain 1:     $DOMAIN1"
echo "Domain 2:     $DOMAIN2"
echo "Server IP:    $SERVER_PUBLIC_IP"
echo "SSL Email:    $SSL_EMAIL"
echo "Site 1 Root:  $SITE1_ROOT"
echo "Site 2 Root:  $SITE2_ROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
