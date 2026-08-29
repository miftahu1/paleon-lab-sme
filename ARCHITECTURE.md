# Site 4 - Revised Architecture

**Updated:** 2026-08-28  
**Status:** Technical Alignment Update

## Executive Summary

This document describes the **minimal architecture** required for Site 4 based on latest engineering guidance. The previous architecture assumed all components needed EC2/Nginx. This revision identifies what can be handled by static hosting + DNS vs. what genuinely requires infrastructure.

## Key Changes from Previous Architecture

1. **Static hosting replaces EC2 for main website** - Most findings don't require a server
2. **No real RDP service** - Dummy TCP listener on port 3389 only
3. **Simplified certificate expiry strategy** - Self-signed expired cert instead of 90-day wait
4. **Minimal infrastructure footprint** - Only deploy what's actually needed

## Architectural Analysis

### What Does NOT Require EC2/Nginx

These findings are achievable without running a server:

✅ **Weak SPF** - DNS TXT record only  
✅ **DMARC p=none** - DNS TXT record only  
✅ **DNSSEC disabled** - DNS configuration only  
✅ **Subdomain discovery (old.paleon-lab-sme.co.uk)** - Can use same static host or separate endpoint

### What DOES Require HTTP/HTTPS Infrastructure

These findings need an actual HTTP(S) endpoint:

⚠️ **Missing HSTS header** - Requires HTTP response headers  
⚠️ **Missing CSP header** - Requires HTTP response headers  
⚠️ **Exposed /backup.bak** - Requires file serving  
⚠️ **Outdated server version disclosure** - Requires Server header  
⚠️ **Expired TLS certificate** - Requires TLS endpoint

### What Requires TCP Listener

⚠️ **Port 3389 reachable** - Requires TCP listener (NOT full RDP service)

## Recommended Minimal Architecture

### Option A: Hybrid Approach (RECOMMENDED)

```
Main Website & Old Subdomain:
┌─────────────────────────────────┐
│  Static Hosting (S3 + CloudFront│
│  OR Netlify/Vercel/CloudFlare)  │
│  - Serves HTML/CSS/JS            │
│  - Serves backup.bak             │
│  - Custom headers configured     │
│  - Custom TLS certificate        │
└─────────────────────────────────┘
              ↑
              │
         DNS Records
              │
┌─────────────────────────────────┐
│  Minimal EC2 t4g.nano (optional)│
│  - Dummy TCP listener :3389      │
│  - Only if static host can't     │
│    expose arbitrary ports        │
└─────────────────────────────────┘
```

**Benefits:**
- Zero ongoing server maintenance for website
- Minimal cost (static hosting is cheap/free)
- Only pay for t4g.nano if needed for port 3389
- Fast, CDN-backed website delivery
- Easy reset/rebuild

**Drawbacks:**
- May need to configure custom headers on static platform
- TLS certificate handling varies by platform
- Port 3389 may require small EC2 instance

### Option B: Minimal EC2 Only

```
Single t4g.nano EC2 Instance:
┌─────────────────────────────────┐
│  Nginx (minimal)                 │
│  - Serves static files           │
│  - Custom headers configured     │
│  - backup.bak exposed            │
│  - Version disclosure enabled    │
│  - Expired TLS cert              │
│                                  │
│  Dummy TCP listener              │
│  - Port 3389 (nc or socat)       │
└─────────────────────────────────┘
```

**Benefits:**
- Single point of configuration
- Full control over headers and TLS
- No platform limitations
- Can easily expose port 3389

**Drawbacks:**
- Requires EC2 instance (small cost)
- Needs system updates/maintenance
- Single point of failure

## Selected Architecture: Option B (Minimal EC2)

**Rationale:** While hybrid is elegant, having full control over HTTP headers, TLS configuration, Server version disclosure, and port 3389 in one place is simpler for a test lab. A single t4g.nano instance in eu-west-2 costs ~$3/month.

## Infrastructure Components

### AWS EC2 Instance

- **Instance Type:** t4g.nano (2 vCPU, 0.5GB RAM) - smallest ARM instance
- **AMI:** Ubuntu 24.04 LTS ARM64
- **Region:** eu-west-2 (London)
- **Storage:** 8GB gp3 (minimum)
- **Elastic IP:** Yes (static IP required for DNS)

### Security Group

```
Inbound Rules:
- TCP 80 from 0.0.0.0/0 (HTTP)
- TCP 443 from 0.0.0.0/0 (HTTPS)
- TCP 3389 from 0.0.0.0/0 (dummy listener - INTENTIONAL)
- TCP 22 from <admin IP> (SSH for management - restrict to known IP)

Outbound Rules:
- All traffic (for package updates)
```

**Important:** Port 22 (SSH) should be restricted to administrator IP only, NOT open to 0.0.0.0/0.

### Software Stack

- **Web Server:** Nginx (minimal installation)
- **TLS:** Self-signed expired certificate (see below)
- **Port 3389 Listener:** `socat` or `nc` dummy listener

## Revised TLS Certificate Strategy

### Problem with Previous Approach

The original plan required:
1. Deploy with valid Let's Encrypt certificate
2. Disable auto-renewal
3. Wait 90 days for natural expiry
4. Scanner observes expired state

**Issues:**
- 90-day wait is impractical for lab setup
- Not quickly reproducible
- Ties testing to time-based decay

### New Approach: Self-Signed Expired Certificate

Create a self-signed certificate with past expiry date:

```bash
# Generate self-signed certificate that expired yesterday
openssl req -x509 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/paleon-lab-sme.key \
  -out /etc/ssl/certs/paleon-lab-sme.crt \
  -days 1 \
  -nodes \
  -subj "/C=GB/ST=Greater Manchester/L=Manchester/O=Northbridge Business Services/CN=paleon-lab-sme.co.uk" \
  -addext "subjectAltName=DNS:paleon-lab-sme.co.uk,DNS:www.paleon-lab-sme.co.uk,DNS:old.paleon-lab-sme.co.uk"

# Backdate the certificate (if needed - requires faketime or manual editing)
# Or simply wait 2 days after generation
```

**Benefits:**
- Immediately testable (or within 2 days)
- Fully reproducible
- Complete control over expiry
- No waiting period
- No Let's Encrypt rate limits

**Security:**
- Self-signed cert never trusted by browsers anyway
- Private key stays on test instance only
- Not used for real traffic
- Can be regenerated anytime

## Port 3389 Dummy Listener

### What It Does

Opens TCP port 3389 and accepts connections but provides **no actual RDP functionality**.

### Implementation Option 1: socat

```bash
# Install socat
sudo apt install socat

# Create systemd service for dummy listener
sudo tee /etc/systemd/system/dummy-rdp.service << 'EOF'
[Unit]
Description=Dummy TCP Listener on Port 3389
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:3389,reuseaddr,fork EXEC:/bin/cat
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable dummy-rdp
sudo systemctl start dummy-rdp
```

### Implementation Option 2: netcat

```bash
# Simple loop-based listener
while true; do nc -l -p 3389; done
```

### What Scanner Sees

- TCP connection to port 3389 succeeds
- Port appears "open"
- No RDP protocol negotiation occurs
- Scanner reports port 3389 reachable

### Security

- No authentication mechanism
- No remote execution capability
- No RDP protocol implementation
- Simply accepts and closes connections
- Runs as unprivileged user (nobody)

## Outdated Component Disclosure

### Current Implementation

Nginx with `server_tokens on` exposes version in Server header.

### Issues

- Nginx version depends on Ubuntu repo version
- Not guaranteed to be "outdated" when deployed
- May need manual verification

### Recommended Approach

**Option 1:** Use specific old Nginx version

Install specific old version from archive:
```bash
# Example: Install nginx 1.18.0 (EOL)
# Would need to compile from source or use old package
```

**Option 2:** Use custom Server header

Configure Nginx to report specific old version:
```nginx
more_set_headers 'Server: nginx/1.14.0';
```

**Option 3:** Use Python/Node simple server instead of Nginx

Deploy a simple Python HTTP server that reports old version:
```python
# Custom server with old version string
Server: Python/2.7.18  # EOL version
```

**SELECTED: Option 2** - Custom Nginx header is simplest and most controllable.

Requires `libnginx-mod-http-headers-more` package for `more_set_headers` directive
(available on Ubuntu 24.04 LTS; replaces the old `nginx-extras` meta-package).

## DNS Configuration

All DNS records required (configure at domain registrar):

```dns
# A Records
paleon-lab-sme.co.uk          IN A    [EC2-ELASTIC-IP]
www.paleon-lab-sme.co.uk      IN A    [EC2-ELASTIC-IP]
old.paleon-lab-sme.co.uk      IN A    [EC2-ELASTIC-IP]

# SPF (weak - intentional)
paleon-lab-sme.co.uk          IN TXT  "v=spf1 include:_spf.google.com ~all"

# DMARC (none policy - intentional)
_dmarc.paleon-lab-sme.co.uk   IN TXT  "v=DMARC1; p=none; rua=mailto:dmarc@paleon-lab-sme.co.uk"

# DNSSEC: DO NOT ENABLE (intentional)
```

## File Structure on EC2

```
/var/www/paleon-lab-sme/
├── index.html
├── about/
│   └── index.html
├── services/
│   └── index.html
├── solutions/
│   └── index.html
├── resources/
│   └── index.html
├── contact/
│   └── index.html
├── css/
│   └── main.css
├── js/
│   └── main.js
├── backup.bak              # INTENTIONALLY EXPOSED
└── [other assets]

/var/www/paleon-lab-sme-old/
└── index.html              # Legacy subdomain content
```

## Deployment Checklist

### Pre-Deployment
- [ ] Domain registered (paleon-lab-sme.co.uk)
- [ ] AWS account access confirmed
- [ ] Region selected (eu-west-2)
- [ ] Admin IP identified for SSH access

### Infrastructure Setup
- [ ] Launch t4g.nano Ubuntu 24.04 LTS instance
- [ ] Allocate and associate Elastic IP
- [ ] Configure security group (80, 443, 3389, SSH from admin IP)
- [ ] SSH access verified

### DNS Configuration
- [ ] A records configured (main, www, old subdomain)
- [ ] SPF TXT record configured (weak ~all)
- [ ] DMARC TXT record configured (p=none)
- [ ] DNSSEC disabled confirmed
- [ ] DNS propagation verified

### Web Server Setup
- [ ] Nginx installed
- [ ] libnginx-mod-http-headers-more installed (for more_set_headers)
- [ ] Website files deployed to /var/www/paleon-lab-sme/
- [ ] Old site deployed to /var/www/paleon-lab-sme-old/
- [ ] backup.bak file present and accessible
- [ ] Nginx config deployed (missing HSTS/CSP)
- [ ] Custom Server header configured (old version)
- [ ] server_tokens enabled (or custom header set)

### TLS Configuration
- [ ] Self-signed certificate generated
- [ ] Certificate expiry set to past date (or 1 day, then wait)
- [ ] Certificate configured in Nginx
- [ ] HTTPS working (with expired cert warning)
- [ ] TLS handshake exposes expired certificate

### Port 3389 Listener
- [ ] socat installed
- [ ] dummy-rdp.service created
- [ ] Service enabled and started
- [ ] Port 3389 externally reachable confirmed

### Verification
- [ ] Website loads at https://paleon-lab-sme.co.uk
- [ ] All routes work (/about, /services, etc.)
- [ ] backup.bak accessible
- [ ] HSTS header missing (curl verification)
- [ ] CSP header missing (curl verification)
- [ ] Server header shows old version
- [ ] TLS certificate expired (openssl verification)
- [ ] Port 3389 responds to TCP connect
- [ ] old.paleon-lab-sme.co.uk resolves and loads
- [ ] DNS records propagated (SPF, DMARC)

## Cost Estimate

### Monthly Costs (eu-west-2)
- **t4g.nano instance:** ~$3.00/month
- **Elastic IP (attached):** $0
- **8GB gp3 storage:** ~$0.80/month
- **Data transfer:** ~$1-2/month (minimal)

**Total:** ~$5-6/month

### One-Time Costs
- **Domain registration:** ~£10-15/year (paleon-lab-sme.co.uk)

## Maintenance

### Regular Tasks
- Security updates: Monthly
- Certificate expiry check: Quarterly (ensure it stays expired)
- Service health check: Weekly

### Reset Procedure
```bash
# Stop services
sudo systemctl stop nginx dummy-rdp

# Clear website
sudo rm -rf /var/www/paleon-lab-sme/*
sudo rm -rf /var/www/paleon-lab-sme-old/*

# Redeploy from git
cd /tmp
git clone [repo-url]
sudo cp -r sme/* /var/www/paleon-lab-sme/
sudo cp -r sme/old-site/* /var/www/paleon-lab-sme-old/

# Restart services
sudo systemctl start nginx dummy-rdp

# Verify
curl -I https://paleon-lab-sme.co.uk
nc -zv paleon-lab-sme.co.uk 3389
```

## Security Boundaries

### What This Environment Contains
- Test website with fake company data
- Dummy TCP listener on port 3389
- Self-signed expired certificate
- Intentionally misconfigured security headers
- Exposed test backup file

### What This Environment Does NOT Contain
- Real customer data
- Real credentials
- Real RDP access
- Real remote execution capability
- Production secrets
- Access to Paleon production systems

### Isolation
- Dedicated AWS account or isolated VPC recommended
- No access to production Paleon infrastructure
- No real authentication mechanisms
- All data synthetic

## Comparison: Before vs After

### Before
- Full EC2 with Nginx required for entire site
- Real RDP service or xrdp mentioned
- Let's Encrypt certificate with 90-day wait
- Assumed all components need server

### After
- Minimal t4g.nano EC2 only where needed
- Dummy TCP listener (no RDP service)
- Self-signed expired certificate (immediate)
- Clear separation of DNS vs infrastructure needs

---

**Architecture Status:** ✅ Defined  
**Deployment Status:** ⏳ Awaiting implementation  
**Estimated Setup Time:** 2-3 hours  
**Monthly Cost:** ~$5-6
