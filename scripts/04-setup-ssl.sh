#!/bin/bash
set -euo pipefail

# ================================================================================
# SSL Certificate Setup Script
# Obtains Let's Encrypt certificates and applies SSL configuration templates
# ================================================================================

# Script directory and log setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/04-setup-ssl-$(date +%Y%m%d-%H%M%S).log"
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

echo "================================================================================"
echo "                        SSL Certificate Setup Script"
echo "================================================================================"
echo "Log file: ${LOG_FILE}"
echo "Started: $(date)"
echo "================================================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_question() {
    echo -e "${CYAN}[?]${NC} $1"
}

error_exit() {
    log_error "$1"
    log_error "SSL setup failed. Check log: ${LOG_FILE}"
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

check_nginx() {
    if ! command -v nginx &> /dev/null; then
        error_exit "Nginx is not installed"
    fi
    
    if ! systemctl is-active --quiet nginx; then
        error_exit "Nginx is not running"
    fi
    
    log_info "Nginx is installed and running"
}

validate_email() {
    if [[ -z "${SSL_EMAIL:-}" ]] || [[ ! "${SSL_EMAIL}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error_exit "Invalid or missing SSL_EMAIL in config.sh"
    fi
    log_info "Email validated: ${SSL_EMAIL}"
}

check_dns_resolution() {
    local domain=$1
    
    log_info "Checking DNS resolution for ${domain}..."
    
    if host "${domain}" &> /dev/null; then
        local resolved_ip=$(host "${domain}" | grep "has address" | awk '{print $4}' | head -1)
        if [[ -n "${resolved_ip}" ]]; then
            log_success "✓ ${domain} resolves to: ${resolved_ip}"
            return 0
        fi
    fi
    
    log_error "✗ ${domain} does not resolve"
    return 1
}

verify_dns_setup() {
    log_step "Step 1/6: Verifying DNS setup..."
    
    local dns_errors=0
    
    if ! check_dns_resolution "${DOMAIN1}"; then
        ((dns_errors++))
    fi
    
    if ! check_dns_resolution "${DOMAIN2}"; then
        ((dns_errors++))
    fi
    
    if [[ $dns_errors -gt 0 ]]; then
        log_error "DNS verification failed for $dns_errors domain(s)"
        log_error "SSL certificates require working DNS"
        return 1
    fi
    
    log_success "DNS verification passed for all domains"
    return 0
}

check_ssl_templates() {
    log_info "Checking SSL configuration templates..."
    
    if [[ ! -f "${SCRIPT_DIR}/../nginx-configs/site1-ssl.conf" ]]; then
        error_exit "SSL template not found: nginx-configs/site1-ssl.conf"
    fi
    
    if [[ ! -f "${SCRIPT_DIR}/../nginx-configs/site2-ssl.conf" ]]; then
        error_exit "SSL template not found: nginx-configs/site2-ssl.conf"
    fi
    
    log_success "SSL templates verified"
}

# ================================================================================
# Certbot Installation Functions
# ================================================================================

install_certbot() {
    log_step "Step 2/6: Checking Certbot installation..."
    
    if command -v certbot &> /dev/null; then
        local version=$(certbot --version 2>&1 | awk '{print $2}')
        log_info "Certbot is already installed (version: ${version})"
        return 0
    fi
    
    log_info "Installing Certbot..."
    
    if sudo apt update && sudo apt install -y certbot; then
        log_success "Certbot installed successfully"
    else
        error_exit "Failed to install Certbot"
    fi
}

# ================================================================================
# Certificate Acquisition Functions
# ================================================================================

obtain_certificate() {
    local domain=$1
    
    log_info "Obtaining SSL certificate for ${domain}..."
    
    # Use certbot certonly to get cert without modifying nginx configs
    if certbot certonly \
        --webroot \
        -w "/var/www/$(echo ${domain} | tr '.' '_')" \
        -d "${domain}" \
        --non-interactive \
        --agree-tos \
        --email "${SSL_EMAIL}" \
        --keep-until-expiring 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "✓ Certificate obtained for ${domain}"
        return 0
    else
        log_error "Failed to obtain certificate for ${domain}"
        return 1
    fi
}

obtain_certificates() {
    log_step "Step 3/6: Obtaining SSL certificates..."
    echo ""
    
    # Obtain certificate for domain 1
    if ! obtain_certificate "${DOMAIN1}"; then
        error_exit "Failed to obtain certificate for ${DOMAIN1}"
    fi
    
    echo ""
    
    # Obtain certificate for domain 2
    if ! obtain_certificate "${DOMAIN2}"; then
        error_exit "Failed to obtain certificate for ${DOMAIN2}"
    fi
    
    echo ""
    log_success "All SSL certificates obtained successfully!"
}

verify_certificates() {
    log_info "Verifying certificate files..."
    
    local errors=0
    
    # Check certificate files for domain 1
    if [[ ! -f "/etc/letsencrypt/live/${DOMAIN1}/fullchain.pem" ]] || \
       [[ ! -f "/etc/letsencrypt/live/${DOMAIN1}/privkey.pem" ]]; then
        log_error "Certificate files missing for ${DOMAIN1}"
        ((errors++))
    else
        log_success "✓ Certificate files present for ${DOMAIN1}"
    fi
    
    # Check certificate files for domain 2
    if [[ ! -f "/etc/letsencrypt/live/${DOMAIN2}/fullchain.pem" ]] || \
       [[ ! -f "/etc/letsencrypt/live/${DOMAIN2}/privkey.pem" ]]; then
        log_error "Certificate files missing for ${DOMAIN2}"
        ((errors++))
    else
        log_success "✓ Certificate files present for ${DOMAIN2}"
    fi
    
    if [[ $errors -gt 0 ]]; then
        error_exit "Certificate verification failed"
    fi
}

# ================================================================================
# Nginx Configuration Functions
# ================================================================================

backup_http_config() {
    local config_name=$1
    
    if [[ -f "/etc/nginx/sites-available/${config_name}" ]]; then
        local backup_path="${BACKUP_DIR}/http-${config_name}-$(date +%Y%m%d-%H%M%S)"
        cp "/etc/nginx/sites-available/${config_name}" "${backup_path}"
        log_info "Backed up HTTP config to: ${backup_path}"
    fi
}

apply_ssl_config() {
    local site_num=$1
    local domain=$2
    local site_dir=$3
    local template_file=$4
    local config_name=$5
    
    log_info "Applying SSL configuration for ${domain}..."
    
    # Backup existing HTTP config
    backup_http_config "${config_name}"
    
    # Generate SSL config from template
    local temp_config="/tmp/nginx-${config_name}-ssl.conf"
    
    if [[ $site_num -eq 1 ]]; then
        sed -e "s|DOMAIN1_PLACEHOLDER|${domain}|g" \
            -e "s|SITE1_DIR|$(basename ${site_dir})|g" \
            "${template_file}" > "${temp_config}"
    else
        sed -e "s|DOMAIN2_PLACEHOLDER|${domain}|g" \
            -e "s|SITE2_DIR|$(basename ${site_dir})|g" \
            "${template_file}" > "${temp_config}"
    fi
    
    # Validate generated config
    if [[ ! -s "${temp_config}" ]]; then
        error_exit "Failed to generate SSL config for ${domain}"
    fi
    
    # Replace HTTP config with SSL config
    if mv "${temp_config}" "/etc/nginx/sites-available/${config_name}"; then
        log_success "✓ SSL configuration applied for ${domain}"
    else
        error_exit "Failed to apply SSL configuration for ${domain}"
    fi
}

apply_ssl_configs() {
    log_step "Step 4/6: Applying SSL configurations..."
    echo ""
    
    apply_ssl_config 1 "${DOMAIN1}" "${SITE1_ROOT}" \
        "${SCRIPT_DIR}/../nginx-configs/site1-ssl.conf" "${DUCKDNS_DOMAIN1}"
    
    apply_ssl_config 2 "${DOMAIN2}" "${SITE2_ROOT}" \
        "${SCRIPT_DIR}/../nginx-configs/site2-ssl.conf" "${DUCKDNS_DOMAIN2}"
    
    log_success "All SSL configurations applied"
}

test_nginx_config() {
    log_step "Step 5/6: Testing Nginx configuration..."
    
    if nginx -t 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Nginx configuration test passed"
    else
        error_exit "Nginx configuration test failed"
    fi
}

reload_nginx() {
    log_info "Reloading Nginx..."
    
    if systemctl reload nginx; then
        log_success "Nginx reloaded successfully"
    else
        error_exit "Failed to reload Nginx"
    fi
}

# ================================================================================
# Auto-Renewal Configuration
# ================================================================================

configure_auto_renewal() {
    log_step "Step 6/6: Configuring automatic certificate renewal..."
    
    # Check if certbot timer is active
    if systemctl is-active --quiet certbot.timer; then
        log_success "Certbot auto-renewal timer is active"
    else
        log_warning "Certbot timer not active, attempting to enable..."
        if systemctl enable --now certbot.timer 2>/dev/null; then
            log_success "Certbot timer enabled"
        else
            log_warning "Could not enable timer automatically"
        fi
    fi
    
    # Test renewal process
    log_info "Testing renewal process (dry-run)..."
    if certbot renew --dry-run 2>&1 | tee -a "${LOG_FILE}"; then
        log_success "Renewal test passed"
    else
        log_warning "Renewal test had issues (check logs)"
    fi
}

# ================================================================================
# Display Functions
# ================================================================================

display_certificate_info() {
    echo ""
    echo "📜 Certificate information:"
    echo ""
    
    if [[ -f "/etc/letsencrypt/live/${DOMAIN1}/cert.pem" ]]; then
        log_info "Certificate for ${DOMAIN1}:"
        openssl x509 -in "/etc/letsencrypt/live/${DOMAIN1}/cert.pem" -noout -dates 2>/dev/null || true
    fi
    
    echo ""
    
    if [[ -f "/etc/letsencrypt/live/${DOMAIN2}/cert.pem" ]]; then
        log_info "Certificate for ${DOMAIN2}:"
        openssl x509 -in "/etc/letsencrypt/live/${DOMAIN2}/cert.pem" -noout -dates 2>/dev/null || true
    fi
}

display_summary() {
    echo ""
    echo "================================================================================"
    log_success "SSL Setup Complete!"
    echo "================================================================================"
    echo ""
    
    echo "📊 What was done:"
    echo "  ✓ DNS resolution verified"
    echo "  ✓ Certbot installed/verified"
    echo "  ✓ SSL certificates obtained"
    echo "  ✓ HTTP configs backed up"
    echo "  ✓ SSL configs applied from templates"
    echo "  ✓ Nginx configuration tested"
    echo "  ✓ Nginx reloaded"
    echo "  ✓ Auto-renewal configured"
    echo ""
    
    echo "🔐 Your sites are now available with HTTPS:"
    echo "   - https://${DOMAIN1}"
    echo "   - https://${DOMAIN2}"
    echo ""
    
    echo "📁 Certificate locations:"
    echo "   - /etc/letsencrypt/live/${DOMAIN1}/"
    echo "   - /etc/letsencrypt/live/${DOMAIN2}/"
    echo ""
    
    echo "📝 Configuration files:"
    echo "   - /etc/nginx/sites-available/${DUCKDNS_DOMAIN1} (now with SSL)"
    echo "   - /etc/nginx/sites-available/${DUCKDNS_DOMAIN2} (now with SSL)"
    echo ""
    
    echo "🔄 Auto-renewal:"
    echo "   - Status: systemctl status certbot.timer"
    echo "   - Test: certbot renew --dry-run"
    echo "   - Force renewal: certbot renew --force-renewal"
    echo ""
    
    echo "💾 HTTP config backups: ${BACKUP_DIR}"
    echo "📊 Setup log: ${LOG_FILE}"
    echo ""
    
    echo "✅ Next step: Validate SSL setup"
    echo "   Run: sudo ./05-validate-ssl.sh"
    echo ""
    echo "================================================================================"
}

# ================================================================================
# Wildcard Certificate Info
# ================================================================================

show_wildcard_info() {
    log_step "Wildcard Certificate Setup (Advanced)"
    echo ""
    
    log_warning "Wildcard certificates require DNS-01 challenge"
    log_warning "You need DNS API credentials for your provider"
    echo ""
    
    # Extract root domain
    local root_domain=$(echo "${DOMAIN1}" | awk -F. '{print $(NF-1)"."$NF}')
    
    log_info "Detected root domain: ${root_domain}"
    echo ""
    
    echo "📋 Supported DNS providers and plugins:"
    echo "  • Cloudflare: python3-certbot-dns-cloudflare"
    echo "  • DigitalOcean: python3-certbot-dns-digitalocean"
    echo "  • AWS Route53: python3-certbot-dns-route53"
    echo "  • Google Cloud DNS: python3-certbot-dns-google"
    echo ""
    
    echo "📝 Wildcard certificate command example (Cloudflare):"
    echo "  1. Install plugin: apt install python3-certbot-dns-cloudflare"
    echo "  2. Create credentials file: ~/.secrets/cloudflare.ini"
    echo "  3. Run: certbot certonly --dns-cloudflare \\"
    echo "     --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \\"
    echo "     -d *.${root_domain} -d ${root_domain} \\"
    echo "     --email ${SSL_EMAIL}"
    echo ""
    
    log_info "After obtaining wildcard certificate, manually update SSL config templates"
    log_info "with the wildcard certificate path and re-run this script"
}

# ================================================================================
# Main Function
# ================================================================================

main() {
    log_info "Starting SSL certificate setup..."
    log_info "Timestamp: $(date)"
    echo ""
    
    # Pre-flight checks
    check_root
    check_nginx
    validate_email
    check_ssl_templates
    
    # Ask user about DNS readiness
    echo ""
    log_warning "⚠️  IMPORTANT: DNS Setup Required ⚠️"
    echo ""
    echo "Before proceeding, ensure:"
    echo "  1. Your domains are pointing to this server's IP"
    echo "  2. DNS has propagated (can take up to 48 hours)"
    echo "  3. Test with: nslookup ${DOMAIN1}"
    echo ""
    
    # Verify DNS
    if ! verify_dns_setup; then
        log_error "DNS is not properly configured"
        echo ""
        log_warning "Please configure DNS first:"
        echo "  1. Add A records for ${DOMAIN1} and ${DOMAIN2}"
        echo "  2. Point them to: ${SERVER_PUBLIC_IP}"
        echo "  3. Wait for DNS propagation"
        echo "  4. Test: nslookup ${DOMAIN1}"
        echo "  5. Re-run this script"
        exit 1
    fi
    
    echo ""
    log_step "SSL Certificate Options:"
    echo "  1. Individual certificates (Recommended - Uses pre-configured templates)"
    echo "  2. Wildcard certificate info (Advanced - Manual setup required)"
    echo ""
    
    read -p "Choose option (1 or 2): " SSL_OPTION
    
    case "${SSL_OPTION}" in
        1)
            # Install certbot
            install_certbot
            
            # Obtain certificates
            obtain_certificates
            verify_certificates
            
            # Apply SSL configs from templates
            apply_ssl_configs
            
            # Test and reload
            test_nginx_config
            reload_nginx
            
            # Configure auto-renewal
            configure_auto_renewal
            
            # Display certificate info
            display_certificate_info
            
            # Display summary
            display_summary
            ;;
        2)
            show_wildcard_info
            ;;
        *)
            error_exit "Invalid option. Please run the script again."
            ;;
    esac
    
    log_success "Script execution completed successfully"
}

# ================================================================================
# Script Entry Point
# ================================================================================

main "$@"
