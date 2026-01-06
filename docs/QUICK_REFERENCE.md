# Quick Reference Guide

## 📁 Project Structure
```
nginx-shared-hosting/
├── README.md                          # Project overview
├── PROJECT_PLAN.md                    # Initial planning document
├── config.sh                          # ⚠️ EDIT THIS FIRST with your details
│
├── docs/
│   ├── DEPLOYMENT_GUIDE.md            # Complete step-by-step guide
│   └── DUCKDNS_SETUP.md              # DuckDNS setup instructions
│
├── websites/
│   ├── site1/                         # Portfolio website (purple theme)
│   │   ├── index.html
│   │   ├── style.css
│   │   └── README.md
│   └── site2/                         # E-commerce website (orange theme)
│       ├── index.html
│       ├── style.css
│       └── README.md
│
├── nginx-configs/
│   ├── site1.conf                     # HTTP config for site 1
│   ├── site2.conf                     # HTTP config for site 2
│   ├── site1-ssl.conf                 # HTTPS config for site 1
│   └── site2-ssl.conf                 # HTTPS config for site 2
│
└── scripts/
    ├── 01-install-nginx.sh            # Step 1: Install Nginx
    ├── 02-deploy-websites.sh          # Step 2: Deploy website files
    ├── 03-configure-virtual-hosts.sh  # Step 3: Configure Nginx
    ├── 04-obtain-ssl-certificates.sh  # Step 4: Get SSL certificates
    ├── 05-configure-ssl.sh            # Step 5: Enable HTTPS
    └── 06-validate-ssl.sh             # Step 6: Verify SSL setup
```

## ⚡ Quick Start

### 1. Edit Configuration (REQUIRED)
```bash
nano config.sh
```
Update these values:
- `DUCKDNS_TOKEN` - from https://www.duckdns.org
- `DUCKDNS_DOMAIN1` - your first domain (without .duckdns.org)
- `DUCKDNS_DOMAIN2` - your second domain (without .duckdns.org)
- `SERVER_PUBLIC_IP` - your server's public IP
- `SSL_EMAIL` - your email for Let's Encrypt

### 2. Run Scripts in Order
```bash
cd scripts

# Step 1: Install Nginx
sudo ./01-install-nginx.sh

# Step 2: Deploy websites
sudo ./02-deploy-websites.sh

# Step 3: Configure virtual hosts
sudo ./03-configure-virtual-hosts.sh

# Step 4: Update DuckDNS (manual - see below)

# Step 5: Get SSL certificates
sudo ./04-obtain-ssl-certificates.sh

# Step 6: Enable HTTPS
sudo ./05-configure-ssl.sh

# Step 7: Validate SSL
sudo ./06-validate-ssl.sh
```

### 3. DuckDNS Configuration (Manual)
1. Go to https://www.duckdns.org
2. Log in
3. Update both domains to point to your server's IP
4. Wait 1-2 minutes for DNS propagation

## 🔍 Testing Commands

### Test Nginx
```bash
# Check syntax
sudo nginx -t

# View status
sudo systemctl status nginx

# Restart
sudo systemctl restart nginx
```

### Test DNS
```bash
# Check if domains resolve
dig site1.duckdns.org +short
dig site2.duckdns.org +short
```

### Test HTTP/HTTPS
```bash
# Test HTTP
curl -I http://site1.duckdns.org

# Test HTTPS
curl -I https://site1.duckdns.org

# Test SSL certificate
openssl s_client -connect site1.duckdns.org:443 -servername site1.duckdns.org
```

## 🎯 Key Nginx Locations

```bash
# Configuration files
/etc/nginx/nginx.conf                  # Main config
/etc/nginx/sites-available/            # Available sites
/etc/nginx/sites-enabled/              # Enabled sites (symlinks)

# Website content
/var/www/site1/                        # Site 1 files
/var/www/site2/                        # Site 2 files

# Logs
/var/log/nginx/access.log              # Main access log
/var/log/nginx/error.log               # Main error log
/var/log/nginx/site1-access.log        # Site 1 access log
/var/log/nginx/site2-access.log        # Site 2 access log

# SSL Certificates
/etc/letsencrypt/live/site1.duckdns.org/   # Site 1 certs
/etc/letsencrypt/live/site2.duckdns.org/   # Site 2 certs
```

## 🐛 Troubleshooting Quick Fixes

### Nginx won't start
```bash
# Check for syntax errors
sudo nginx -t

# Check error log
sudo tail -20 /var/log/nginx/error.log

# Check if port is in use
sudo netstat -tlnp | grep :80
```

### Site shows wrong content
```bash
# Clear Nginx cache
sudo systemctl restart nginx

# Check which config is active
ls -la /etc/nginx/sites-enabled/

# Test with specific host header
curl -H "Host: site1.duckdns.org" http://YOUR_IP
```

### DNS not resolving
```bash
# Flush local DNS cache
sudo systemd-resolve --flush-caches

# Test with Google DNS
dig @8.8.8.8 site1.duckdns.org

# Wait and retry (DNS propagation takes time)
```

### SSL certificate issues
```bash
# Check certificate status
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Check DuckDNS token
cat /root/.secrets/duckdns.ini
```

## 📊 Monitoring Commands

```bash
# Watch access logs live
sudo tail -f /var/log/nginx/site1-access.log

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Monitor Nginx process
htop -p $(pgrep nginx)

# Check SSL expiry
sudo certbot certificates | grep -A 1 "Expiry Date"
```

## 🔄 Maintenance Tasks

### Update website content
```bash
# Edit files
sudo nano /var/www/site1/index.html

# No Nginx restart needed for static files!
```

### Renew SSL certificates
```bash
# Automatic renewal is configured
# Check timer status
sudo systemctl status certbot.timer

# Manual renewal (if needed)
sudo certbot renew
```

### Backup
```bash
# Backup website files
sudo tar -czf websites-backup.tar.gz /var/www/site1 /var/www/site2

# Backup Nginx configs
sudo tar -czf nginx-configs-backup.tar.gz /etc/nginx/sites-available/

# Backup SSL certificates
sudo tar -czf ssl-backup.tar.gz /etc/letsencrypt/
```

## 🎓 Understanding Virtual Hosts

### How it works:
1. Browser requests `http://site1.duckdns.org`
2. DNS resolves to your server's IP
3. Request reaches Nginx on port 80
4. Nginx reads the `Host` header: `site1.duckdns.org`
5. Nginx matches this to server block configuration
6. Nginx serves files from `/var/www/site1/`

### Testing virtual host routing:
```bash
# Force specific host header (even with wrong IP)
curl -H "Host: site1.duckdns.org" http://127.0.0.1

# Should serve site1 content
```

## 📈 Performance Tuning (Optional)

### Enable Gzip compression
```nginx
# Add to /etc/nginx/nginx.conf
gzip on;
gzip_types text/css application/javascript;
```

### Increase file upload limit
```nginx
# Add to server block
client_max_body_size 10M;
```

### Enable caching
```nginx
# Add to location block
expires 7d;
add_header Cache-Control "public, immutable";
```

## 🔐 Security Checklist

- [ ] SSL certificates installed and valid
- [ ] HTTP redirects to HTTPS
- [ ] Security headers enabled (HSTS, etc.)
- [ ] Hidden files (.git, .env) blocked
- [ ] Firewall configured (UFW)
- [ ] Regular updates: `sudo apt update && sudo apt upgrade`
- [ ] Monitor access logs for suspicious activity

## 📞 Need Help?

1. Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed steps
2. Review [DUCKDNS_SETUP.md](DUCKDNS_SETUP.md) for DNS issues
3. Check Nginx error logs: `sudo tail -20 /var/log/nginx/error.log`
4. Test configuration: `sudo nginx -t`

## 🎉 Success Indicators

✅ Both sites load in browser  
✅ Padlock icon shows in address bar  
✅ Each site shows unique content  
✅ HTTP redirects to HTTPS automatically  
✅ Footer displays correct domain name  
✅ No browser warnings or errors  
