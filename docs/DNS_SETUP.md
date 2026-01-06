# DNS Configuration Guide

## Domain Options for This Project

This project works with **ANY domain type**. Choose what works best for you:

### Option 1: Traditional Domain with Subdomains (Recommended)
If you own a domain like `example.com`:
- Create subdomains: `www.example.com` and `blog.example.com`
- Or: `site1.example.com` and `site2.example.com`
- Both point to the **same server IP**
- Nginx routes them to **different website directories**

### Option 2: DuckDNS (Free)
DuckDNS provides free subdomains under `duckdns.org`:
- **Limitation**: Cannot create subdomains of DuckDNS domains
- **Solution**: Register 2 separate DuckDNS domains
- Example: `myportfolio.duckdns.org` and `myshop.duckdns.org`
- Both point to the same server IP

### Option 3: Other Dynamic DNS Providers
- No-IP, FreeDNS, Dynu, etc.
- Follow same principle as DuckDNS

### Option 4: Multiple Root Domains
- If you own multiple domains: `example.com` and `mystore.com`
- Each can be hosted on the same server
- Great for completely separate projects

## DNS Setup Steps by Provider

### For Traditional Domains (GoDaddy, Namecheap, Cloudflare, etc.)

1. **Log into your DNS provider**
2. **Create A records** for both subdomains:
   - Name: `www` → Points to: `YOUR_SERVER_IP`
   - Name: `blog` → Points to: `YOUR_SERVER_IP`
3. **Wait for DNS propagation** (5 mins - 48 hours)
4. **Verify with**: `nslookup www.example.com` or `dig www.example.com`

### For DuckDNS

1. **Create DuckDNS Account**
   - Visit https://www.duckdns.org
   - Sign in with GitHub, Google, etc.
   - Get your unique token

2. **Create Two Domains**
   - Add first domain (e.g., `myportfolio`)
   - Add second domain (e.g., `myshop`)
   - Results: `myportfolio.duckdns.org` and `myshop.duckdns.org`

3. **Point to Your Server**
   - Enter your server's public IP for both
   - A records created automatically
   - Optional: Set up auto-update for dynamic IPs

### For Cloudflare (with CDN benefits)

1. **Transfer nameservers** to Cloudflare (or add domain)
2. **Create DNS records**:
   - Type: A, Name: www, Content: YOUR_IP, Proxy: Optional
   - Type: A, Name: blog, Content: YOUR_IP, Proxy: Optional
3. **Benefits**: Free SSL, CDN, DDoS protection

## SSL Certificate Options

### Standard SSL (Per-Domain)
- Easiest approach
- Separate certificate for each domain
- Works with HTTP-01 challenge
- No DNS API token needed

### Wildcard SSL (All Subdomains)
- One certificate for `*.example.com`
- Requires DNS-01 challenge
- Needs DNS provider API token
- More complex but cleaner

## Configuration Examples

### Example 1: Traditional Domain
```bash
DOMAIN1="www.example.com"
DOMAIN2="blog.example.com"
SERVER_PUBLIC_IP="203.0.113.10"
SSL_EMAIL="admin@example.com"
```

### Example 2: DuckDNS
```bash
DOMAIN1="myportfolio.duckdns.org"
DOMAIN2="myshop.duckdns.org"
DUCKDNS_TOKEN="abc123-def456-ghi789"  # For DNS-01 challenge
SERVER_PUBLIC_IP="203.0.113.10"
SSL_EMAIL="youremail@example.com"
```

### Example 3: Multiple Root Domains
```bash
DOMAIN1="example.com"
DOMAIN2="mystore.net"
SERVER_PUBLIC_IP="203.0.113.10"
SSL_EMAIL="admin@example.com"
```

## DNS Propagation Check

After setting up DNS, verify it's working:

```bash
# Check if DNS is resolving
nslookup your-domain.com

# Or use dig for more details
dig your-domain.com

# Check from multiple locations
https://www.whatsmydns.net/
```

## Next Steps
1. Choose your domain provider
2. Register or use existing domains
3. Create DNS A records pointing to your server IP
4. Wait for DNS propagation
5. Verify DNS resolution
6. Update config.sh with your domain names
7. Proceed with Nginx installation
