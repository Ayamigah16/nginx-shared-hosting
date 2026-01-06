# Architecture & How It Works

## 🏗️ System Architecture

```
                                    INTERNET
                                       │
                                       │
                            DNS Resolution (DuckDNS)
                                       │
                           ┌───────────┴───────────┐
                           │                       │
                    site1.duckdns.org      site2.duckdns.org
                           │                       │
                           └───────────┬───────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  Server IP      │
                              │  (Your Server)  │
                              └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │  Nginx Process  │
                              │  Port 80 (HTTP) │
                              │  Port 443(HTTPS)│
                              └────────┬────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │                           │
                         ▼                           ▼
              ┌──────────────────┐        ┌──────────────────┐
              │  Virtual Host 1  │        │  Virtual Host 2  │
              │  site1.conf      │        │  site2.conf      │
              └────────┬─────────┘        └────────┬─────────┘
                       │                           │
                       ▼                           ▼
              ┌──────────────────┐        ┌──────────────────┐
              │  /var/www/site1/ │        │  /var/www/site2/ │
              │  - index.html    │        │  - index.html    │
              │  - style.css     │        │  - style.css     │
              │  (Portfolio)     │        │  (Store)         │
              └──────────────────┘        └──────────────────┘
```

## 🔄 Request Flow

### Example: User visits site1.duckdns.org

```
1. User types: https://site1.duckdns.org
   │
   ▼
2. Browser → DNS (DuckDNS)
   Query: "What's the IP for site1.duckdns.org?"
   Response: "123.45.67.89"
   │
   ▼
3. Browser → Server (123.45.67.89:443)
   Request Headers:
   ┌─────────────────────────────────┐
   │ GET / HTTP/1.1                  │
   │ Host: site1.duckdns.org         │ ← This is KEY!
   │ ...                             │
   └─────────────────────────────────┘
   │
   ▼
4. Nginx receives request
   - Checks port (443 = HTTPS)
   - Reads "Host" header
   - Matches against server_name in configs
   │
   ▼
5. Nginx matches site1.conf
   ┌─────────────────────────────────┐
   │ server {                        │
   │   listen 443 ssl;               │
   │   server_name site1.duckdns.org;│ ← MATCH!
   │   root /var/www/site1/;         │
   │ }                               │
   └─────────────────────────────────┘
   │
   ▼
6. Nginx serves files from /var/www/site1/
   - Reads index.html
   - Applies SSL certificate
   - Sends response to browser
   │
   ▼
7. Browser displays Site 1 (Portfolio theme)
```

## 🎯 Virtual Host Decision Process

```
                    ┌─────────────────┐
                    │  Request Arrives│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Read Host Header│
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐         ┌─────────────────┐
    │ site1.duckdns.org│        │site2.duckdns.org│
    │ in Host header? │        │ in Host header? │
    └────────┬────────┘         └────────┬────────┘
             │ YES                       │ YES
             ▼                           ▼
    ┌─────────────────┐         ┌─────────────────┐
    │ Use site1.conf  │         │ Use site2.conf  │
    │ Serve from      │         │ Serve from      │
    │ /var/www/site1/ │         │ /var/www/site2/ │
    └─────────────────┘         └─────────────────┘
```

## 🔐 SSL/TLS Flow

```
┌──────────────────────────────────────────────────────────┐
│                     HTTPS Request                         │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│  1. Client Hello                                         │
│     "I want to connect securely"                         │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│  2. Server Hello + Certificate                           │
│     Nginx sends: /etc/letsencrypt/live/site1/cert.pem   │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│  3. Certificate Verification                             │
│     Browser checks:                                      │
│     - Issued by Let's Encrypt? ✓                        │
│     - Domain matches? ✓                                 │
│     - Not expired? ✓                                    │
│     - Valid signature? ✓                                │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│  4. Encrypted Connection Established                     │
│     🔒 All traffic now encrypted                        │
└─────────────────────┬────────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────┐
│  5. Normal HTTP traffic (but encrypted)                  │
│     GET /index.html, etc.                                │
└──────────────────────────────────────────────────────────┘
```

## 📂 File System Layout

```
/
├── etc/
│   ├── nginx/
│   │   ├── nginx.conf                    # Main Nginx config
│   │   ├── sites-available/
│   │   │   ├── site1                     # Site 1 config
│   │   │   └── site2                     # Site 2 config
│   │   └── sites-enabled/
│   │       ├── site1 → ../sites-available/site1  # Symlink
│   │       └── site2 → ../sites-available/site2  # Symlink
│   │
│   └── letsencrypt/
│       └── live/
│           ├── site1.duckdns.org/
│           │   ├── fullchain.pem         # Public certificate
│           │   ├── privkey.pem           # Private key
│           │   └── chain.pem             # Certificate chain
│           └── site2.duckdns.org/
│               ├── fullchain.pem
│               ├── privkey.pem
│               └── chain.pem
│
├── var/
│   ├── www/
│   │   ├── site1/
│   │   │   ├── index.html                # Site 1 homepage
│   │   │   └── style.css                 # Site 1 styles
│   │   └── site2/
│   │       ├── index.html                # Site 2 homepage
│   │       └── style.css                 # Site 2 styles
│   │
│   └── log/
│       └── nginx/
│           ├── site1-access.log          # Site 1 access logs
│           ├── site1-error.log           # Site 1 error logs
│           ├── site2-access.log          # Site 2 access logs
│           └── site2-error.log           # Site 2 error logs
│
└── root/
    └── .secrets/
        └── duckdns.ini                   # DuckDNS API token
```

## 🔍 How Nginx Decides Which Site to Serve

### Configuration in site1.conf:
```nginx
server {
    listen 443 ssl;
    server_name site1.duckdns.org;  # ← This is the matcher
    root /var/www/site1;
    # ...
}
```

### Configuration in site2.conf:
```nginx
server {
    listen 443 ssl;
    server_name site2.duckdns.org;  # ← This is the matcher
    root /var/www/site2;
    # ...
}
```

### Decision Logic:
```
If Host header = "site1.duckdns.org" → Use site1 config → Serve /var/www/site1/
If Host header = "site2.duckdns.org" → Use site2 config → Serve /var/www/site2/
Otherwise → 404 Not Found
```

## 🔄 HTTP to HTTPS Redirect

```
User enters: http://site1.duckdns.org
                    │
                    ▼
        ┌───────────────────────┐
        │ Nginx Port 80 (HTTP)  │
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │ server {              │
        │   listen 80;          │
        │   server_name site1   │
        │   return 301 https... │ ← Redirect instruction
        │ }                     │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────────┐
        │ HTTP 301 Moved Permanently│
        │ Location: https://site1...│
        └───────────┬───────────────┘
                    │
                    ▼
        Browser automatically requests HTTPS version
```

## ⚙️ Certificate Renewal Process

```
        ┌─────────────────────────────┐
        │  Certbot Timer (systemd)    │
        │  Runs twice daily           │
        └─────────────┬───────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │ Check certificate expiry    │
        │ (30 days before expiration) │
        └─────────────┬───────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │ Need renewal?               │
        └────────┬─────────┬──────────┘
                 │ YES     │ NO
                 ▼         ▼
    ┌─────────────────┐  ┌──────────┐
    │ Run DNS-01      │  │ Skip     │
    │ Challenge via   │  └──────────┘
    │ DuckDNS API     │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Let's Encrypt   │
    │ verifies DNS    │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Issues new cert │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Nginx auto-     │
    │ reloads config  │
    └─────────────────┘
```

## 🎓 Key Concepts Explained

### 1. Virtual Hosts
- **What:** Multiple websites on one server
- **How:** Nginx reads `Host` header and routes to correct directory
- **Why:** Cost-effective, efficient resource usage

### 2. DNS (Domain Name System)
- **What:** Translates domains to IP addresses
- **How:** DuckDNS stores: site1.duckdns.org → 123.45.67.89
- **Why:** Humans remember names better than IP addresses

### 3. SSL/TLS Certificates
- **What:** Digital certificates proving site identity
- **How:** Let's Encrypt validates domain ownership via DNS
- **Why:** Encrypted communication, browser trust indicators

### 4. Server Blocks (Nginx term for Virtual Hosts)
- **What:** Configuration sections defining site behavior
- **How:** Each `server {}` block = one website
- **Why:** Modular, maintainable configuration

## 📊 Performance & Scalability

### Current Setup:
```
Single Server (1 Nginx instance)
    │
    ├── Site 1 (static HTML/CSS)
    └── Site 2 (static HTML/CSS)

Resource Usage: Very Low
Max Concurrent Users: ~10,000+ (static content)
```

### Scaling Options:
```
1. Add More Sites
   └── Just add more server {} blocks

2. Add Caching Layer
   └── Nginx FastCGI cache / Varnish

3. Load Balancer + Multiple Servers
   └── Distribute across multiple backend servers

4. CDN Integration
   └── Cloudflare, AWS CloudFront, etc.
```

## 🔐 Security Layers

```
Layer 1: Firewall (UFW)
    ↓ Only ports 80, 443 open
Layer 2: Nginx
    ↓ Virtual host isolation
    ↓ Security headers
    ↓ Hidden file protection
Layer 3: SSL/TLS
    ↓ Encrypted communication
    ↓ Certificate validation
Layer 4: File Permissions
    ↓ www-data user limited access
    ↓ 755 directory permissions
```

## 💡 Real-World Applications

This exact setup is used for:
- **Shared Hosting Providers** (like Bluehost, HostGator)
- **Personal Project Portfolios**
- **Multiple Client Websites** on one VPS
- **Staging + Production Environments**
- **Multi-tenant SaaS Applications**
