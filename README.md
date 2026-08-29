# Site 4 - Northbridge Business Services

**Paleon Cybersecurity Scanner Validation Laboratory**

**Updated:** 2026-08-28  
**Architecture:** Minimal EC2 + Dummy TCP Listener

## Overview

Site 4 is a fictional UK small-medium enterprise (SME) website designed to test whether Paleon's external scanner correctly detects a known set of externally observable security weaknesses commonly found in UK businesses.

**Company:** Northbridge Business Services (fictional)  
**Domain:** paleon-lab-sme.co.uk  
**Type:** Business technology services provider  
**Purpose:** Generic UK SME with intentional security posture weaknesses

## Important Notes

⚠️ **This is a controlled test environment**

- All company information is fictional
- All credentials and data are fake
- No real customer information exists
- No exploitation is required or should be attempted
- Only scan systems owned or authorized by Paleon

## Fictional Company Details

**Northbridge Business Services**  
Practical technology and business support for growing UK companies.

- Founded: 2014 (fictional)
- Location: Manchester, United Kingdom
- Services: IT support, infrastructure, cloud services, business applications, consulting
- Website: Professional UK SME business site

All names, addresses, testimonials, and business details are completely fictional.

## Architecture

### Minimal Infrastructure Approach

Site 4 uses **minimal infrastructure** - only deploying what's genuinely needed for externally observable test conditions.

```
AWS EC2 t4g.nano (eu-west-2)
│
├── Nginx (ports 80, 443)
│   ├── Static website files
│   ├── Missing HSTS header (intentional)
│   ├── Missing CSP header (intentional)
│   ├── Custom Server header (old version)
│   ├── Exposed backup.bak file
│   └── Self-signed expired TLS certificate
│
└── Dummy TCP Listener (port 3389)
    └── socat - accepts connections, no RDP functionality

DNS Configuration (external):
├── A records (main, www, old subdomain)
├── Weak SPF record (~all)
├── DMARC p=none
└── DNSSEC disabled (intentional)
```

### What Does NOT Require Infrastructure

These findings are DNS-only:
- ✅ Weak SPF configuration
- ✅ DMARC policy p=none
- ✅ DNSSEC not enabled

### What Requires Infrastructure

These findings need the EC2 instance:
- ⚠️ Missing HSTS/CSP headers (Nginx configuration)
- ⚠️ Exposed /backup.bak file (web server)
- ⚠️ Outdated server version disclosure (Nginx header)
- ⚠️ Expired TLS certificate (self-signed)
- ⚠️ TCP port 3389 reachable (dummy listener)
- ⚠️ Subdomain discovery (old.paleon-lab-sme.co.uk)

## URL Structure

The site uses directory-based routing with `index.html` files:

```
/                    → /index.html
/about               → /about/index.html
/services            → /services/index.html
/solutions           → /solutions/index.html
/resources           → /resources/index.html
/contact             → /contact/index.html
```

No `.html` extensions appear in public URLs.  
Direct requests and page refreshes work correctly.

## Intentional Security Weaknesses

Site 4 contains **10 deliberately planted weaknesses** for scanner validation.

### 1. Expired TLS Certificate ⚠️ HIGH

- **Detection:** TLS handshake inspection
- **Implementation:** Self-signed certificate with past expiry date
- **Observable:** Real expired certificate condition during TLS handshake
- **Claim:** `observed`

### 2. Missing HSTS Header 🔶 MEDIUM

- **Detection:** HTTP header analysis
- **Configuration:** Nginx intentionally omits `Strict-Transport-Security`
- **Observable:** Header absent from HTTPS responses
- **Claim:** `observed`

### 3. Missing CSP Header 🔶 MEDIUM

- **Detection:** HTTP header analysis
- **Configuration:** Nginx intentionally omits `Content-Security-Policy`
- **Observable:** Header absent from responses
- **Claim:** `observed`

### 4. Weak SPF Configuration 🔶 MEDIUM

- **Detection:** DNS TXT query
- **Configuration:** `v=spf1 include:_spf.google.com ~all`
- **Issue:** Uses `~all` (soft fail) instead of `-all` (hard fail)
- **Observable:** DNS record query
- **Claim:** `observed`

### 5. DMARC Policy p=none 🔶 MEDIUM

- **Detection:** DNS TXT query
- **Configuration:** `v=DMARC1; p=none; rua=mailto:dmarc@paleon-lab-sme.co.uk`
- **Issue:** Policy set to none (monitoring only, no enforcement)
- **Observable:** DNS record query
- **Claim:** `observed`

### 6. DNSSEC Not Enabled 🔵 LOW

- **Detection:** DNSSEC validation query
- **Configuration:** DNSSEC intentionally not configured
- **Observable:** No DNSSEC signatures present
- **Claim:** `observed`

### 7. TCP Port 3389 Exposed ⚠️ HIGH

- **Detection:** TCP port scan
- **Configuration:** Dummy TCP listener on port 3389
- **Observable:** Port 3389 responds to TCP connection attempts
- **Important:** Uses dummy listener, NOT real RDP service
- **Claim:** `observed`
- **Compliance:** Fails Cyber Essentials

### 8. Exposed Backup File 🔶 MEDIUM

- **Detection:** HTTP path enumeration
- **File:** `/backup.bak`
- **Contents:** Fictional test configuration and credentials
- **Observable:** File returns 200 OK when requested
- **Claim:** `observed`

### 9. Outdated Server Version 🔶 MEDIUM

- **Detection:** HTTP Server header analysis
- **Configuration:** Nginx configured with custom Server header showing old version
- **Observable:** Server header reveals nginx/1.14.0
- **Claim:** `inferred` (indicates outdated component, not confirmed exploitation)

### 10. Forgotten Old Subdomain 🔵 LOW

- **Detection:** Subdomain enumeration
- **Subdomain:** `old.paleon-lab-sme.co.uk`
- **Content:** Old version of company website (2018 style)
- **Observable:** DNS resolves, site responds
- **Claim:** `observed`

## Pages and Routes

### Main Site

- **/** - Home page with hero, services overview, company info
- **/about** - Company history, mission, values, team
- **/services** - Detailed service descriptions (5 services)
- **/solutions** - Common business technology challenges and approaches
- **/resources** - 4 detailed articles on technology topics
- **/contact** - Contact information and form

### Old Subdomain

- **old.paleon-lab-sme.co.uk** - Legacy site from 2018

All pages are mobile responsive with professional UK business design.

## Expected Findings

See `expected.yaml` for complete expected findings documentation.

**Expected Security Score:** 40-55%  
**Cyber Essentials Ready:** No  
**Major Issues:** 2 high, 5 medium, 3 low severity

## Cyber Essentials Impact

Site 4 tests Cyber Essentials-related failures:

- **Secure Configuration:** Missing security headers, outdated software
- **Access Control:** TCP port 3389 exposed to internet
- **Malware Protection:** Weak email security (phishing risk)

## Local Development

### Prerequisites

- Git
- Web server (Python SimpleHTTPServer, live-server, etc.)
- Modern web browser

### Run Locally

```bash
# Clone or navigate to directory
cd sme

# Option 1: Python 3
python -m http.server 8000

# Option 2: Node live-server (if installed)
npx live-server

# Open browser
# Navigate to http://localhost:8000
```

**Note:** Local testing won't replicate security findings (no TLS, no DNS, no port 3389, etc.)

## Deployment

### Quick Start

See `DEPLOYMENT.md` for complete step-by-step deployment guide.

### Summary

1. **Launch EC2:** t4g.nano Ubuntu 24.04 LTS ARM64 in eu-west-2
2. **Configure Security Group:** Allow 80, 443, 3389 from 0.0.0.0/0; SSH from admin IP only
3. **Allocate Elastic IP:** Associate with instance
4. **Configure DNS:** A records for main/www/old subdomain; SPF and DMARC TXT records
5. **Install Software:** nginx, libnginx-mod-http-headers-more, socat, openssl
6. **Create Certificate:** Self-signed with 1-day validity (wait 2 days for expiry)
7. **Deploy Website:** Copy files to /var/www/paleon-lab-sme/
8. **Configure Nginx:** Deploy config with missing headers and custom Server version
9. **Start Dummy Listener:** systemd service for socat on port 3389
10. **Verify:** Test all routes, headers, certificate, and port 3389

### Infrastructure Requirements

- **Instance:** AWS EC2 t4g.nano (2 vCPU, 0.5GB RAM)
- **Region:** eu-west-2 (London)
- **Elastic IP:** Required for stable DNS
- **Monthly Cost:** ~$5-6

### DNS Configuration

Configure at your domain registrar:

```dns
# A Records
paleon-lab-sme.co.uk          IN A    [EC2-ELASTIC-IP]
www.paleon-lab-sme.co.uk      IN A    [EC2-ELASTIC-IP]
old.paleon-lab-sme.co.uk      IN A    [EC2-ELASTIC-IP]

# SPF Record (weak - intentional)
paleon-lab-sme.co.uk          IN TXT  "v=spf1 include:_spf.google.com ~all"

# DMARC Record (p=none - intentional)
_dmarc.paleon-lab-sme.co.uk   IN TXT  "v=DMARC1; p=none; rua=mailto:dmarc@paleon-lab-sme.co.uk"

# DNSSEC: DO NOT ENABLE (intentional)
```

### TLS Certificate Strategy

**Self-signed expired certificate approach:**

```bash
# Generate certificate with 1-day validity
openssl req -x509 -newkey rsa:2048 \
  -keyout /etc/ssl/private/paleon-lab-sme.key \
  -out /etc/ssl/certs/paleon-lab-sme.crt \
  -days 1 -nodes \
  -subj "/C=GB/ST=Greater Manchester/L=Manchester/O=Northbridge Business Services/CN=paleon-lab-sme.co.uk" \
  -addext "subjectAltName=DNS:paleon-lab-sme.co.uk,DNS:www.paleon-lab-sme.co.uk,DNS:old.paleon-lab-sme.co.uk"

# Wait 2 days for natural expiry
```

**Benefits:**
- No 90-day wait required
- Immediately reproducible
- Full control over expiry
- No Let's Encrypt rate limits or dependencies

### Port 3389 Dummy Listener

**Important:** This is NOT a real RDP service.

A simple TCP listener that accepts connections but provides no remote access functionality:

```bash
# Systemd service using socat
sudo tee /etc/systemd/system/dummy-rdp.service << 'EOF'
[Unit]
Description=Dummy TCP Listener on Port 3389 for Paleon Testing
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:3389,reuseaddr,fork EXEC:/bin/cat
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now dummy-rdp
```

**Security:** Runs as unprivileged user, no RDP protocol implementation, no authentication, no remote execution capability.

## Verification Commands

### Test from External Machine

```bash
# Check website loads
curl -I https://paleon-lab-sme.co.uk

# Verify missing HSTS
curl -I https://paleon-lab-sme.co.uk | grep -i strict
# Should return nothing

# Verify missing CSP
curl -I https://paleon-lab-sme.co.uk | grep -i content-security
# Should return nothing

# Verify Server header shows old version
curl -I https://paleon-lab-sme.co.uk | grep -i server
# Should show: Server: nginx/1.14.0

# Check backup file accessible
curl https://paleon-lab-sme.co.uk/backup.bak

# Check port 3389 reachable
nmap -p 3389 paleon-lab-sme.co.uk
# Should show: 3389/tcp open

# Or use netcat
nc -zv paleon-lab-sme.co.uk 3389

# Verify certificate expired
echo | openssl s_client -connect paleon-lab-sme.co.uk:443 2>/dev/null | openssl x509 -noout -dates

# Check DNS records
dig paleon-lab-sme.co.uk TXT
dig _dmarc.paleon-lab-sme.co.uk TXT
dig old.paleon-lab-sme.co.uk
```

## File Structure

```
sme/
├── index.html                 # Home page
├── about/
│   └── index.html            # About page
├── services/
│   └── index.html            # Services page
├── solutions/
│   └── index.html            # Solutions page
├── resources/
│   └── index.html            # Resources page
├── contact/
│   └── index.html            # Contact page
├── css/
│   └── main.css              # Main stylesheet
├── js/
│   └── main.js               # JavaScript
├── images/                    # Image assets
├── backup.bak                 # INTENTIONALLY EXPOSED (fake data)
├── old-site/
│   └── index.html            # Legacy subdomain content
├── nginx.conf                 # Nginx configuration
├── expected.yaml              # Expected findings documentation
├── ARCHITECTURE.md            # Architecture details
├── DEPLOYMENT.md              # Step-by-step deployment guide
├── REDESIGN.md                # UI redesign documentation
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## What NOT to Add

- Real credentials or secrets
- Real customer data
- Real RDP service or xrdp
- Windows Remote Desktop
- Database
- Authentication system
- Payment processing
- Redis/caching
- Unnecessary frameworks
- Real partnerships or certifications
- Production Paleon credentials

## Safety and Scope

### Authorization Boundary

This environment MUST ONLY be used to scan:
- paleon-lab-sme.co.uk
- www.paleon-lab-sme.co.uk
- old.paleon-lab-sme.co.uk
- The specific EC2 instance deployed for this purpose

### Scanning Safety

All findings are designed to be:
- **Observable** through non-intrusive methods
- **Non-exploitable** conditions
- **Benign** test scenarios

The scanner should:
- ✅ Fetch pages via HTTP/HTTPS
- ✅ Perform TLS handshakes
- ✅ Query DNS records
- ✅ Perform TCP port scans
- ✅ Inspect HTTP headers
- ❌ NOT attempt exploitation
- ❌ NOT perform SQL injection
- ❌ NOT perform XSS attacks
- ❌ NOT brute force credentials
- ❌ NOT modify any data

## Expected Scanner Behavior

The Paleon scanner should:

1. Discover main domain and old subdomain
2. Detect expired TLS certificate via handshake
3. Observe missing HSTS and CSP headers
4. Query and analyze SPF/DMARC records
5. Detect open TCP port 3389 via connect scan
6. Find backup.bak through path enumeration
7. Detect outdated server version from headers
8. Report findings with appropriate severity
9. Classify findings with correct claim strength
10. Generate Cyber Essentials readiness assessment

## Key Changes from Previous Architecture

### Before
- Assumed full EC2 with Nginx required for everything
- Mentioned real RDP service or xrdp
- Let's Encrypt certificate with 90-day wait
- Unclear separation between DNS and infrastructure needs

### After
- Minimal t4g.nano EC2 only where genuinely needed
- Dummy TCP listener (no RDP service)
- Self-signed expired certificate (immediate/reproducible)
- Clear architecture documentation (see ARCHITECTURE.md)
- Detailed deployment guide (see DEPLOYMENT.md)

## Documentation

- **README.md** (this file) - Project overview
- **ARCHITECTURE.md** - Detailed architecture decisions and rationale
- **DEPLOYMENT.md** - Complete step-by-step deployment guide
- **expected.yaml** - Authoritative expected findings specification
- **REDESIGN.md** - UI redesign documentation
- **nginx.conf** - Web server configuration
- **validate.sh** - Local validation script

## Reproducibility

### Reset Website

```bash
# SSH to server
cd /tmp && git clone [repo] site4-new
sudo rm -rf /var/www/paleon-lab-sme/*
sudo cp -r site4-new/* /var/www/paleon-lab-sme/
sudo systemctl reload nginx
```

### Complete Reset

See DEPLOYMENT.md for full reset procedure including certificate regeneration.

## Cost Estimate

### Monthly Costs (eu-west-2)
- **t4g.nano instance:** ~$3.00/month
- **Elastic IP (attached):** $0
- **8GB gp3 storage:** ~$0.80/month
- **Data transfer:** ~$1-2/month (minimal)

**Total:** ~$5-6/month

### One-Time Costs
- **Domain registration:** ~£10-15/year (paleon-lab-sme.co.uk)

## Definition of Done

Site 4 deployment is complete when:

### Code/Content
- [x] Website built and all pages created
- [x] Clean URLs implemented with directory structure
- [x] Mobile responsive design complete
- [x] backup.bak created with fake data
- [x] old subdomain content created
- [x] expected.yaml documented
- [x] README completed

### Infrastructure (Pending Deployment)
- [ ] Domain registered
- [ ] EC2 t4g.nano launched in eu-west-2
- [ ] Elastic IP allocated and associated
- [ ] Security group configured (80, 443, 3389, SSH restricted)
- [ ] DNS A records configured and propagated
- [ ] DNS TXT records configured (SPF, DMARC)
- [ ] DNSSEC disabled confirmed
- [ ] Nginx installed with headers-more module
- [ ] Website files deployed
- [ ] Self-signed expired certificate created
- [ ] Nginx configured (missing HSTS/CSP, custom Server header)
- [ ] Dummy TCP listener on port 3389 running
- [ ] All routes verified working
- [ ] All 10 security conditions verified externally observable
- [ ] Paleon scanner validation run

## Contact

For questions about this test environment:

- Refer to expected.yaml for detailed finding specifications
- See ARCHITECTURE.md for architecture decisions
- See DEPLOYMENT.md for deployment instructions
- All findings are intentional and documented
- This is a controlled Paleon test environment

---

**Last Updated:** 2026-08-28  
**Site Version:** 1.0  
**Architecture:** Minimal EC2 + Dummy TCP Listener  
**Status:** Ready for deployment
