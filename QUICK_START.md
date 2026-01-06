# 🚀 Quick Start Guide

## Prerequisites
- Linux server (Ubuntu/Debian recommended)
- Root or sudo access
- 2 domain names (any DNS provider)
- Domains pointing to your server IP

## Step 1: Configure Your Domains

Edit [config.sh](config.sh) with your actual values:

```bash
# Example for traditional domains
export DOMAIN1="www.example.com"
export DOMAIN2="blog.example.com"
export SERVER_PUBLIC_IP="203.0.113.10"
export SSL_EMAIL="admin@example.com"
```

Or for DuckDNS/other free DNS:
```bash
export DOMAIN1="mysite.duckdns.org"
export DOMAIN2="myshop.duckdns.org"
export SERVER_PUBLIC_IP="203.0.113.10"
export SSL_EMAIL="youremail@example.com"
```

## Step 2: Run Preflight Check

```bash
./scripts/00-check-requirements.sh
```

This verifies your system is ready.

## Step 3: Deploy Everything

### Option A: Automated (Recommended)
```bash
sudo ./scripts/deploy-all.sh
```

### Option B: Step-by-Step (For Learning)

**Install Nginx:**
```bash
sudo ./scripts/01-install-nginx.sh
```

**Deploy website files:**
```bash
sudo ./scripts/02-deploy-websites.sh
```

**Configure virtual hosts:**
```bash
sudo ./scripts/03-configure-virtual-hosts.sh
```

**Set up DNS** (see [DNS_SETUP.md](docs/DNS_SETUP.md))

**Install SSL certificates:**
```bash
sudo ./scripts/04-setup-ssl.sh
```

**Validate SSL:**
```bash
./scripts/05-validate-ssl.sh
```

## Step 4: Access Your Sites

Open in browser:
- https://your-domain1.com
- https://your-domain2.com

## Troubleshooting

**Sites not accessible?**
- Check DNS: `nslookup your-domain.com`
- Check Nginx: `sudo systemctl status nginx`
- Check logs: `sudo tail -f /var/log/nginx/error.log`

**SSL not working?**
- Verify DNS propagation
- Check ports 80/443 are open
- Review certbot logs: `sudo journalctl -u certbot`

**Need help?**
- Review [README.md](README.md)
- Check [DNS_SETUP.md](docs/DNS_SETUP.md)

## Commands Cheat Sheet

```bash
# Check Nginx status
sudo systemctl status nginx

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# View access logs
sudo tail -f /var/log/nginx/your-domain_access.log

# View error logs
sudo tail -f /var/log/nginx/your-domain_error.log

# Check SSL certificate expiry
sudo certbot certificates

# Renew SSL certificates
sudo certbot renew --dry-run

# Test SSL
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## Learning Checkpoints

After each step, verify you understand:
- ✅ How Nginx routes different domains
- ✅ Where configuration files are located
- ✅ How SSL certificates work
- ✅ How to troubleshoot issues

## Next Steps

Once everything works:
1. Customize the website content in `websites/site1/` and `websites/site2/`
2. Experiment with Nginx configuration
3. Add more domains
4. Set up monitoring and backups

Happy learning! 🎓
