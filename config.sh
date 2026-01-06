# Configuration File
# Fill this out with your actual values
# Works with ANY domain provider: Traditional domains, DuckDNS, No-IP, etc.

# Domain Configuration
# Examples:
#   Traditional: DOMAIN1="blog.example.com" DOMAIN2="shop.example.com"
#   DuckDNS: DOMAIN1="mysite.duckdns.org" DOMAIN2="myshop.duckdns.org"
#   Subdomains: DOMAIN1="www.example.com" DOMAIN2="api.example.com"
export DOMAIN1="site1.example.com"
export DOMAIN2="site2.example.com"

# Server Configuration
export SERVER_PUBLIC_IP="0.0.0.0"

# Website Directories (will be created under /var/www/)
export SITE1_ROOT="/var/www/$(echo ${DOMAIN1} | tr '.' '_')"
export SITE2_ROOT="/var/www/$(echo ${DOMAIN2} | tr '.' '_')"

# SSL Configuration
export SSL_EMAIL="your-email@example.com"

# Optional: DNS Provider specific settings (if needed)
# For DuckDNS:
export DUCKDNS_TOKEN="your-token-here"  # Only needed if using DuckDNS with Let's Encrypt DNS challenge

# For Cloudflare:
export CLOUDFLARE_API_TOKEN="your-token-here"  # Only needed if using Cloudflare DNS challenge

# Display current configuration
echo "Current Configuration:"
echo "====================="
echo "Domain 1: ${DOMAIN1}"
echo "Domain 2: ${DOMAIN2}"
echo "Server IP: ${SERVER_PUBLIC_IP}"
echo "Site 1 Root: ${SITE1_ROOT}"
echo "Site 2 Root: ${SITE2_ROOT}"
echo "SSL Email: ${SSL_EMAIL}"
