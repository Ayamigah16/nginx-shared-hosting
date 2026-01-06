# 🌐 Nginx Virtual Hosts - Multi-Site Hosting Project

> **Production-ready deployment system for hosting multiple static websites on a single server using Nginx Virtual Hosts with Let's Encrypt SSL certificates.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Nginx](https://img.shields.io/badge/Nginx-1.18+-009639?logo=nginx)](https://nginx.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04+-E95420?logo=ubuntu)](https://ubuntu.com)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Configuration](#configuration)
- [Deployment Scripts](#deployment-scripts)
- [Support & Troubleshooting](#support--troubleshooting)
- [Contributing](#contributing)

---

## 🎯 Overview

This project provides a **complete, automated deployment system** for hosting multiple static websites on a single Nginx server with professional-grade features:

- ✅ **Automated deployment scripts** with fail-safe mechanisms
- ✅ **Multiple domain support** (traditional, DuckDNS, Cloudflare, No-IP, etc.)
- ✅ **SSL/TLS certificates** via Let's Encrypt
- ✅ **Template-based configuration** for easy customization
- ✅ **Comprehensive logging** and backup systems
- ✅ **Production-ready** security configurations

**Perfect for:**
- 🎓 Learning Nginx virtual hosts and SSL configuration
- 🚀 Deploying portfolio and project websites
- 💼 Hosting multiple client sites on one server
- 🔧 Understanding DevOps automation practices

---

## ✨ Features

### Core Capabilities

| Feature | Description |
|---------|-------------|
| **🌍 Multi-Domain Hosting** | Host unlimited websites on a single server with virtual hosts |
| **🔐 SSL/TLS Encryption** | Automatic Let's Encrypt certificates with auto-renewal |
| **🎨 Website Templates** | Pre-built responsive HTML/CSS templates included |
| **⚙️ Automated Deployment** | One-command deployment with comprehensive validation |
| **📊 Organized Logging** | Timestamped logs for every operation with rotation |
| **💾 Automatic Backups** | Configuration and website backups before changes |
| **🛡️ Security Hardened** | Modern TLS, security headers, and best practices |
| **📱 Any DNS Provider** | Works with Cloudflare, DuckDNS, traditional domains, etc. |

### Technical Features

- **Fail-Safe Scripting**: Set -euo pipefail, error trapping, validation at every step
- **Function-Based Architecture**: 57+ modular functions across all scripts
- **Template System**: Pre-configured Nginx configs with placeholder replacement
- **DNS Verification**: Checks DNS propagation before certificate requests
- **Rollback Capability**: Automatic backups with restoration instructions
- **Health Checks**: Post-deployment validation and SSL testing

---

## 📁 Project Structure

```
nginx-shared-hosting/
├── 📄 README.md                      # This file - project overview
├── 📄 QUICK_START.md                 # Fast deployment guide
├── ⚙️ config.sh                      # Main configuration file
├── 🚫 .gitignore                     # Git ignore rules
│
├── 📂 scripts/                       # Deployment automation
│   ├── 00-check-requirements.sh     # Pre-flight validation
│   ├── 01-install-nginx.sh          # Nginx installation (19 functions)
│   ├── 02-deploy-websites.sh        # Website deployment (15 functions)
│   ├── 03-configure-virtual-hosts.sh # Nginx configuration
│   ├── 04-setup-ssl.sh              # SSL certificate setup (template-based)
│   ├── 05-validate-ssl.sh           # SSL validation
│   └── deploy-all.sh                # Master deployment script
│
├── 📂 websites/                      # Website source files
│   ├── site1/                       # Portfolio template (purple/blue)
│   │   ├── index.html
│   │   ├── style.css
│   │   └── README.md
│   └── site2/                       # E-commerce template (orange/green)
│       ├── index.html
│       ├── style.css
│       └── README.md
│
├── 📂 nginx-configs/                 # Nginx configuration templates
│   ├── site1.conf                   # HTTP configuration
│   ├── site1-ssl.conf               # HTTPS configuration
│   ├── site2.conf                   # HTTP configuration
│   └── site2-ssl.conf               # HTTPS configuration
│
├── 📂 docs/                          # Comprehensive documentation
│   ├── ARCHITECTURE.md              # System design & technical overview
│   ├── DEPLOYMENT_GUIDE.md          # Detailed deployment walkthrough
│   ├── DNS_SETUP.md                 # DNS configuration all providers
│   ├── QUICK_REFERENCE.md           # Command cheat sheet
│   ├── SCRIPT_IMPROVEMENTS.md       # Technical implementation details
│   └── CHANGELOG.md                 # Project history & improvements
│
├── 📂 logs/                          # Automatic execution logs
│   ├── README.md                    # Log management guide
│   └── *.log                        # Timestamped execution logs (auto-generated)
│
└── 📂 backups/                       # Automatic backups
    ├── README.md                    # Backup & restore guide
    ├── nginx-configs/               # Nginx config backups (auto-generated)
    ├── site1-*/                     # Website backups (auto-generated)
    └── site2-*/                     # Website backups (auto-generated)
```

**Total:** 7 deployment scripts • 2 website templates • 4 Nginx configs • 6 documentation files

---

## 🔧 Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04+ or Debian 10+ (64-bit)
- **RAM**: 512MB minimum (1GB+ recommended)
- **Disk Space**: 2GB minimum
- **Network**: Public IP address with ports 80/443 accessible

### Required Software

The deployment scripts automatically install these, but you need:

- **Root/Sudo Access**: For system-level operations
- **Internet Connection**: For package installation and DNS resolution

### Domain Requirements

You need **2 domain names** (or subdomains). Works with:

| DNS Provider | Example | Cost | Setup Time |
|-------------|---------|------|------------|
| **DuckDNS** (Free) | mysite.duckdns.org | Free | 5 mins |
| **Cloudflare** | site1.example.com | Free DNS | 10 mins |
| **Traditional Domain** | www.example.com | $10/year | 30 mins |
| **No-IP** (Free) | mysite.no-ip.org | Free | 5 mins |
| **Multiple Domains** | example.com, another.com | Varies | 30 mins |

### Knowledge Level

- ✅ Basic Linux command line usage
- ✅ SSH access to your server
- ✅ Understanding of domains and DNS (helpful)
- ❌ No coding experience required

---

## 🚀 Quick Start

### 1. Clone or Download Project

```bash
# Clone the repository
cd /your/projects/directory
git clone <repository-url> nginx-shared-hosting
cd nginx-shared-hosting

# Or download and extract if you have the ZIP
```

### 2. Configure Your Domains

Edit [`config.sh`](config.sh) with your domain information:

```bash
nano config.sh
```

```bash
# Update these values with YOUR domains
export DOMAIN1="site1.example.com"
export DOMAIN2="site2.example.com"
export SERVER_PUBLIC_IP="YOUR.SERVER.IP.ADDRESS"
export SSL_EMAIL="your-email@example.com"
```

### 3. Set Up DNS

Point your domains to your server IP. See [DNS_SETUP.md](docs/DNS_SETUP.md) for provider-specific instructions.

**Quick DNS Check:**
```bash
nslookup site1.example.com
nslookup site2.example.com
```

### 4. Deploy Everything

```bash
cd scripts/
sudo ./deploy-all.sh
```

This runs all deployment steps with pauses for verification. See [QUICK_START.md](QUICK_START.md) for detailed deployment guide.

### 5. Access Your Sites

After deployment:
- **HTTP**: http://site1.example.com, http://site2.example.com
- **HTTPS**: https://site1.example.com, https://site2.example.com

---

## 📚 Documentation

### Getting Started

| Document | Description | When to Read |
|----------|-------------|--------------|
| [QUICK_START.md](QUICK_START.md) | Fast deployment walkthrough | **Start here** for deployment |
| [DNS_SETUP.md](docs/DNS_SETUP.md) | DNS configuration all providers | Before running scripts |
| [config.sh](config.sh) | Configuration file | **Must edit** before deployment |

### Technical Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design & components | Developers |
| [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Detailed deployment steps | All users |
| [SCRIPT_IMPROVEMENTS.md](docs/SCRIPT_IMPROVEMENTS.md) | Script implementation details | Advanced users |
| [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) | Command cheat sheet | All users |

### Operational Guides

| Document | Description | Purpose |
|----------|-------------|---------|
| [logs/README.md](logs/README.md) | Log file management | Troubleshooting |
| [backups/README.md](backups/README.md) | Backup & restore procedures | Recovery |
| [CHANGELOG.md](docs/CHANGELOG.md) | Project history | Version tracking |

---

## ⚙️ Configuration

### Main Configuration File

Edit [`config.sh`](config.sh) before deployment:

```bash
# ========================================
# Domain Configuration
# ========================================
export DOMAIN1="site1.example.com"      # First website domain
export DOMAIN2="site2.example.com"      # Second website domain

# ========================================
# Server Configuration
# ========================================
export SERVER_PUBLIC_IP="203.0.113.45"  # Your server's public IP

# ========================================
# SSL Configuration
# ========================================
export SSL_EMAIL="admin@example.com"     # Let's Encrypt notifications

# ========================================
# Auto-Generated Paths (don't edit)
# ========================================
export SITE1_ROOT="/var/www/$(echo ${DOMAIN1} | tr '.' '_')"
export SITE2_ROOT="/var/www/$(echo ${DOMAIN2} | tr '.' '_')"
```

### Website Customization

Customize the included website templates:

```bash
# Edit Site 1 (Portfolio theme)
nano websites/site1/index.html
nano websites/site1/style.css

# Edit Site 2 (E-commerce theme)
nano websites/site2/index.html
nano websites/site2/style.css
```

### Nginx Configuration

Pre-configured templates in [`nginx-configs/`](nginx-configs/):

- **site1.conf / site2.conf**: HTTP configurations
- **site1-ssl.conf / site2-ssl.conf**: HTTPS configurations with security headers

Templates use placeholders automatically replaced during deployment.

---

## 🤖 Deployment Scripts

### Individual Scripts

| Script | Purpose | Functions | When to Use |
|--------|---------|-----------|-------------|
| `00-check-requirements.sh` | Pre-flight validation | System checks | Before deployment |
| `01-install-nginx.sh` | Install & configure Nginx | 19 functions | Fresh server |
| `02-deploy-websites.sh` | Deploy website files | 15 functions | Update websites |
| `03-configure-virtual-hosts.sh` | Configure Nginx hosts | 10 functions | Add/modify sites |
| `04-setup-ssl.sh` | Get SSL certificates | 12 functions | Enable HTTPS |
| `05-validate-ssl.sh` | Verify SSL setup | 5 functions | Test SSL |
| `deploy-all.sh` | Run all scripts | Orchestration | Full deployment |

### Running Scripts

```bash
cd scripts/

# Run all steps (recommended for first deployment)
sudo ./deploy-all.sh

# Or run individual scripts
sudo ./01-install-nginx.sh
sudo ./02-deploy-websites.sh
sudo ./03-configure-virtual-hosts.sh
sudo ./04-setup-ssl.sh
sudo ./05-validate-ssl.sh
```

### Script Features

✅ **Fail-Safe**: `set -euo pipefail`, error trapping, line number reporting  
✅ **Validation**: Checks at every step before proceeding  
✅ **Logging**: Timestamped logs in `logs/` directory  
✅ **Backups**: Automatic backups before changes  
✅ **Rollback**: Instructions provided on failure  
✅ **Idempotent**: Safe to re-run without issues  

---

## 🆘 Support & Troubleshooting

### Common Issues

**DNS not resolving?**
```bash
# Wait 5-10 minutes for propagation, then check:
nslookup your-domain.com
host your-domain.com
```

**Certificate acquisition fails?**
- Ensure DNS is fully propagated
- Check firewall allows ports 80/443
- Verify email address in config.sh

**Nginx won't start?**
```bash
# Check configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

### Getting Help

1. **Check Logs**: All operations logged to `logs/` directory
2. **Read Documentation**: See [docs/](docs/) directory
3. **Review Scripts**: Scripts include detailed comments
4. **Search Issues**: Check existing GitHub issues
5. **Create Issue**: Provide logs and configuration (redact sensitive data)

### Useful Commands

```bash
# Test Nginx configuration
sudo nginx -t

# Reload Nginx (after config changes)
sudo systemctl reload nginx

# Check Nginx status
sudo systemctl status nginx

# View logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Test SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Check certificate expiry
sudo certbot certificates
```

See [QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md) for complete command reference.

---

## 🤝 Contributing

Contributions are welcome! This project is designed for learning and practical use.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Areas for Contribution

- 🎨 Additional website templates
- 🌍 More DNS provider examples
- 📝 Documentation improvements
- 🐛 Bug fixes and optimizations
- 🔧 Additional deployment scripts
- 🌐 Internationalization

---

## 🎓 Learning Path

**Beginner Path:**
1. Read [QUICK_START.md](QUICK_START.md)
2. Configure [config.sh](config.sh)
3. Run `deploy-all.sh`
4. Explore deployed websites
5. Review logs to understand what happened

**Intermediate Path:**
1. Study [ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. Run scripts individually
3. Customize website templates
4. Modify Nginx configurations
5. Understand SSL certificate process

**Advanced Path:**
1. Review [SCRIPT_IMPROVEMENTS.md](docs/SCRIPT_IMPROVEMENTS.md)
2. Study script source code
3. Customize deployment scripts
4. Add additional websites
5. Implement custom features

---

## 🌟 Project Stats

- **Total Scripts**: 7 deployment scripts
- **Functions**: 57+ modular functions
- **Lines of Code**: 1,500+ lines of bash
- **Documentation**: 6 comprehensive guides
- **Templates**: 2 responsive website templates
- **Configurations**: 4 Nginx config templates
- **Automation Level**: ~95% automated deployment

---

**Made with ❤️ for learning and deploying modern web infrastructure**

*Last Updated: January 6, 2026*
