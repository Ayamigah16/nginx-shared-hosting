#!/bin/bash

# Script to validate SSL certificates using OpenSSL and other tools

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"

echo "=================================="
echo "SSL Certificate Validation"
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_section() {
    echo -e "${CYAN}[SECTION]${NC} $1"
}

validate_domain() {
    local domain=$1
    
    echo ""
    print_section "Validating SSL for: ${domain}"
    echo "======================================"
    
    # Check if SSL is responding
    print_info "1. Testing SSL connection..."
    if timeout 5 openssl s_client -connect ${domain}:443 -servername ${domain} </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
        echo "   ✓ SSL connection successful"
    else
        echo "   ✗ SSL connection failed or certificate invalid"
    fi
    
    # Get certificate details
    print_info "2. Certificate details:"
    echo ""
    openssl s_client -connect ${domain}:443 -servername ${domain} </dev/null 2>/dev/null | openssl x509 -noout -text | grep -E "Subject:|Issuer:|Not Before|Not After"
    
    # Check certificate chain
    print_info "3. Certificate chain:"
    openssl s_client -connect ${domain}:443 -servername ${domain} -showcerts </dev/null 2>/dev/null | grep -E "subject=|issuer="
    
    # Check expiry date
    print_info "4. Days until expiration:"
    openssl s_client -connect ${domain}:443 -servername ${domain} </dev/null 2>/dev/null | openssl x509 -noout -dates | grep "notAfter" | cut -d= -f2 | xargs -I {} date -d {} "+%Y-%m-%d %H:%M:%S"
    
    # Check supported protocols
    print_info "5. Supported SSL/TLS versions:"
    for version in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
        if timeout 2 openssl s_client -connect ${domain}:443 -${version} </dev/null 2>&1 | grep -q "Protocol.*TLS"; then
            echo "   ✓ ${version}"
        fi
    done
    
    # Check cipher suites
    print_info "6. Cipher suite:"
    openssl s_client -connect ${domain}:443 -servername ${domain} </dev/null 2>/dev/null | grep "Cipher" | head -1
    
    echo ""
}

# Validate both domains
validate_domain ${DOMAIN1}
validate_domain ${DOMAIN2}

echo ""
print_section "Additional Validation Options"
echo "======================================"
echo ""
echo "Online SSL test tools:"
echo "  1. SSL Labs: https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN1}"
echo "  2. SSL Labs: https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN2}"
echo ""
echo "Command-line tests:"
echo "  # Check certificate expiry"
echo "  echo | openssl s_client -servername ${DOMAIN1} -connect ${DOMAIN1}:443 2>/dev/null | openssl x509 -noout -dates"
echo ""
echo "  # Check certificate issuer"
echo "  echo | openssl s_client -servername ${DOMAIN1} -connect ${DOMAIN1}:443 2>/dev/null | openssl x509 -noout -issuer"
echo ""
echo "  # Test specific TLS version"
echo "  openssl s_client -connect ${DOMAIN1}:443 -tls1_3"
echo ""
echo "  # Check using curl"
echo "  curl -vI https://${DOMAIN1}"
echo ""

print_info "Validation complete!"
