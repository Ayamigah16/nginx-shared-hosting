# Complete Deployment Guide

## 🎯 Overview
This guide walks you through deploying two static websites on a single server using Nginx Virtual Hosts with SSL certificates.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] Linux server (Ubuntu 20.04+ or Debian 11+ recommended)
- [ ] Root or sudo access to the server
- [ ] Server public IP address
- [ ] 2 DuckDNS domains registered at https://www.duckdns.org
- [ ] DuckDNS token (found on DuckDNS dashboard)
- [ ] Email address for SSL certificate notifications

---

## 🚀 Deployment Steps

### **Step 0: Prepare Configuration**

1. Open [config.sh](../config.sh) and fill in your details:

```bash
# Edit config.sh with your actual values
export DUCKDNS_TOKEN="your-actual-token-from-duckdns"
export DUCKDNS_DOMAIN1="yoursite1"  # without .duckdns.org
export DUCKDNS_DOMAIN2="yoursite2"  # without .duckdns.org
export SERVER_PUBLIC_IP="123.45.67.89"  # your server's IP
export SSL_EMAIL="your-email@example.com"
```

2. Source the configuration:
```bash
source config.sh
```

---

### **Step 1: Install Nginx**

**What it does:** Installs and configures Nginx web server

```bash
cd scripts
sudo bash 01-install-nginx.sh
```

**Expected output:**
- Nginx installed and running
- Firewall configured (if UFW is active)
- Service enabled to start on boot

**Verify:** Visit `http://YOUR_SERVER_IP` - you should see the default Nginx page

**Learning Note:** Nginx is now listening on port 80 (HTTP) and ready to serve websites.

---

### **Step 2: Deploy Website Files**

**What it does:** Copies website files to `/var/www/` directories

```bash
sudo bash 02-deploy-websites.sh
```

**Expected output:**
- Site 1 files copied to `/var/www/site1/`
- Site 2 files copied to `/var/www/site2/`
- Proper permissions set (www-data user)

**Learning Note:** Each website now has its own directory with separate HTML/CSS files.

---

### **Step 3: Configure Virtual Hosts**

**What it does:** Creates Nginx server blocks for each domain

```bash
sudo bash 03-configure-virtual-hosts.sh
```

**Expected output:**
- Configuration files created in `/etc/nginx/sites-available/`
- Symbolic links created in `/etc/nginx/sites-enabled/`
- Nginx configuration tested successfully
- Nginx reloaded

**Learning Note:** Nginx now knows to route requests for domain1.duckdns.org to site1 and domain2.duckdns.org to site2.

**Verify:** 
```bash
# Check configurations
ls -la /etc/nginx/sites-enabled/
sudo nginx -t
```

---

### **Step 4: Configure DNS (DuckDNS)**

**Manual step - Do this via DuckDNS web interface:**

1. Go to https://www.duckdns.org
2. Log in
3. For **both** domains you created, update the IP address to your server's public IP
4. Wait 1-2 minutes for DNS propagation

**Verify DNS:**
```bash
# Check if DNS is resolving correctly
nslookup yoursite1.duckdns.org
nslookup yoursite2.duckdns.org

# Or use dig
dig yoursite1.duckdns.org +short
dig yoursite2.duckdns.org +short
```

Both should return your server's IP address.

**Test HTTP access:**
```bash
curl -I http://yoursite1.duckdns.org
curl -I http://yoursite2.duckdns.org
```

You should see `HTTP/1.1 200 OK` responses.

**Verify in browser:** Open `http://yoursite1.duckdns.org` and `http://yoursite2.duckdns.org`

---

### **Step 5: Obtain SSL Certificates**

**What it does:** Gets free SSL certificates from Let's Encrypt using Certbot

**Important:** Make sure DNS is working before running this!

```bash
sudo bash 04-obtain-ssl-certificates.sh
```

**Expected output:**
- Certbot installed
- DuckDNS plugin installed
- Certificates obtained for both domains
- Certificates saved in `/etc/letsencrypt/live/`

**This takes:** ~2-3 minutes (includes DNS propagation wait)

**Learning Note:** Let's Encrypt uses DNS challenge to verify you own the domains. The certbot-dns-duckdns plugin automates this using your DuckDNS token.

---

### **Step 6: Configure SSL on Nginx**

**What it does:** Updates Nginx configurations to use SSL certificates

```bash
sudo bash 05-configure-ssl.sh
```

**Expected output:**
- SSL configurations created
- HTTP to HTTPS redirects enabled
- Nginx reloaded
- Auto-renewal timer activated

**Learning Note:** Your sites now:
- Accept HTTPS connections on port 443
- Redirect all HTTP traffic to HTTPS
- Use modern, secure TLS configuration

**Verify in browser:** 
- Visit `http://yoursite1.duckdns.org` → Should redirect to HTTPS
- Visit `https://yoursite1.duckdns.org` → Should show secure padlock icon

---

### **Step 7: Validate SSL Setup**

**What it does:** Tests SSL certificates using OpenSSL commands

```bash
sudo bash 06-validate-ssl.sh
```

**Expected output:**
- Certificate details for both sites
- Expiration dates
- TLS protocol versions
- HTTPS connection tests

**Learning Note:** This script shows you how to inspect SSL certificates from command line - useful for troubleshooting.

---

## ✅ Verification Checklist

After completing all steps:

- [ ] Both sites accessible via HTTP (redirect to HTTPS)
- [ ] Both sites accessible via HTTPS with valid certificates
- [ ] Browser shows padlock icon (secure connection)
- [ ] Each site displays its unique design/content
- [ ] Footer shows correct domain name dynamically
- [ ] No certificate warnings or errors

---

## 🎓 Key Learning Concepts Demonstrated

### 1. **Virtual Hosts (Server Blocks)**
- Single Nginx instance serving multiple domains
- Domain-based request routing
- Separate configuration files per site

### 2. **DNS Configuration**
- A records pointing domains to server IP
- DNS propagation and verification
- DuckDNS free dynamic DNS service

### 3. **SSL/TLS Certificates**
- Let's Encrypt free certificates
- DNS-01 challenge method
- Automatic certificate renewal
- HTTP to HTTPS redirection
- Modern TLS configuration

### 4. **Nginx Best Practices**
- Security headers (HSTS, XSS, etc.)
- Static asset caching
- Proper logging
- Configuration testing before reload

---

## 🔧 Useful Commands

### Nginx Management
```bash
# Test configuration
sudo nginx -t

# Reload configuration (no downtime)
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log
```

### SSL Certificate Management
```bash
# List all certificates
sudo certbot certificates

# Manually renew certificates
sudo certbot renew

# Check renewal timer
sudo systemctl status certbot.timer

# Test renewal (dry run)
sudo certbot renew --dry-run
```

### Troubleshooting
```bash
# Check DNS resolution
dig yourdomain.duckdns.org +short

# Test HTTP connection
curl -I http://yourdomain.duckdns.org

# Test HTTPS connection
curl -I https://yourdomain.duckdns.org

# Check SSL certificate expiry
echo | openssl s_client -connect yourdomain.duckdns.org:443 2>/dev/null | openssl x509 -noout -dates

# View site access logs
sudo tail -f /var/log/nginx/site1-access.log
```

---

## 🐛 Common Issues & Solutions

### Issue: DNS not resolving
**Solution:** 
- Check DuckDNS dashboard - IP address correct?
- Wait 2-5 minutes for DNS propagation
- Clear local DNS cache: `sudo systemd-resolve --flush-caches`

### Issue: Certificate verification failed
**Solution:**
- Ensure DNS is working first (`dig yourdomain.duckdns.org`)
- Check DuckDNS token is correct in config.sh
- Wait for DNS propagation before running SSL script

### Issue: "Connection refused" or "Could not connect"
**Solution:**
- Check firewall: `sudo ufw status`
- Allow ports: `sudo ufw allow 80/tcp` and `sudo ufw allow 443/tcp`
- Check Nginx is running: `sudo systemctl status nginx`

### Issue: Wrong site displaying
**Solution:**
- Check server_name in Nginx configs
- Verify DNS points to correct IP
- Clear browser cache
- Test with: `curl -H "Host: yourdomain.duckdns.org" http://SERVER_IP`

---

## 📚 Additional Resources

- Nginx Documentation: https://nginx.org/en/docs/
- Let's Encrypt: https://letsencrypt.org/
- DuckDNS: https://www.duckdns.org/
- SSL Labs Test: https://www.ssllabs.com/ssltest/

---

## 🎉 Congratulations!

You've successfully:
- Deployed multiple websites on a single server
- Configured Nginx virtual hosts
- Set up DNS with DuckDNS
- Secured your sites with SSL/TLS
- Learned production-ready web hosting skills

This setup is similar to what real hosting companies use!
