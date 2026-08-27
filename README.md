# Site 4 - Northbridge Business Services

**Paleon Cybersecurity Scanner Validation Laboratory**

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

### Website Stack

- **Frontend:** HTML5, CSS3, vanilla JavaScript
- **Web Server:** Nginx on Ubuntu
- **Hosting:** AWS EC2
- **Structure:** Static site with directory-based clean URLs

### Infrastructure

```
Internet
    │
    ▼
AWS EC2 Instance
    │
    ├── Nginx (port 80, 443)
    ├── RDP (port 3389) - INTENTIONALLY EXPOSED
    │
    └── Static HTML/CSS/JS
```

### URL Structure

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
- **Status:** Certificate will expire after deployment
- **Observable:** Real expired certificate condition
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

### 7. RDP Port Exposed ⚠️ HIGH

- **Detection:** TCP port scan
- **Configuration:** AWS Security Group allows TCP 3389 from 0.0.0.0/0
- **Observable:** Port 3389 responds to connections
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
- **Configuration:** Nginx configured to expose version number
- **Observable:** Server header reveals outdated version
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
- **Access Control:** RDP exposed to internet
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

**Note:** Local testing won't replicate security findings (no TLS, no DNS, etc.)

## Deployment

### AWS Infrastructure Required

- **EC2 Instance:** Ubuntu 22.04 LTS or similar
- **Instance Type:** t3.small or larger
- **Elastic IP:** Static IP address
- **Security Group:**
  - TCP 80 (HTTP) - 0.0.0.0/0
  - TCP 443 (HTTPS) - 0.0.0.0/0
  - TCP 3389 (RDP) - 0.0.0.0/0 ⚠️ Intentional

### DNS Configuration Required

Configure at your domain registrar or DNS provider:

```
# A Records
paleon-lab-sme.co.uk                 → [EC2 Elastic IP]
old.paleon-lab-sme.co.uk             → [EC2 Elastic IP or separate host]

# SPF Record (TXT)
paleon-lab-sme.co.uk                 → "v=spf1 include:_spf.google.com ~all"

# DMARC Record (TXT)
_dmarc.paleon-lab-sme.co.uk          → "v=DMARC1; p=none; rua=mailto:dmarc@paleon-lab-sme.co.uk"

# DNSSEC: DO NOT ENABLE (intentionally missing)
```

### TLS Certificate Setup

**Strategy:** Use Let's Encrypt with short-lived certificate

```bash
# Install certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot certonly --nginx -d paleon-lab-sme.co.uk -d www.paleon-lab-sme.co.uk

# DO NOT enable auto-renewal
# Certificate will expire after 90 days naturally
sudo systemctl stop certbot.timer
sudo systemctl disable certbot.timer
```

**Certificate Expiry Plan:**
1. Deploy with valid certificate
2. Disable auto-renewal
3. Allow natural expiry after 90 days
4. Scanner will observe expired state

⚠️ Never use production certificate infrastructure for this test site.

### Nginx Installation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install nginx
sudo apt install nginx -y

# Enable version disclosure (for outdated component test)
sudo nano /etc/nginx/nginx.conf
# Comment out or remove: server_tokens off;
# This exposes the nginx version in Server header

# Copy site files
sudo mkdir -p /var/www/paleon-lab-sme
sudo cp -r * /var/www/paleon-lab-sme/

# Copy old site
sudo mkdir -p /var/www/paleon-lab-sme-old
sudo cp -r old-site/* /var/www/paleon-lab-sme-old/

# Copy nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/paleon-lab-sme
sudo ln -s /etc/nginx/sites-available/paleon-lab-sme /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
```

### RDP Setup (Windows Server on same EC2)

If using Windows Server:

```powershell
# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Allow RDP through firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

Or deploy Linux and document that port 3389 is open but service may not respond (still detectable via port scan).

### Post-Deployment Checklist

- [ ] Website loads at paleon-lab-sme.co.uk
- [ ] HTTPS works with valid certificate
- [ ] All routes work (/about, /services, etc.)
- [ ] Direct requests and refreshes work
- [ ] backup.bak file accessible at root
- [ ] Port 3389 open and reachable
- [ ] old.paleon-lab-sme.co.uk resolves and loads
- [ ] HSTS header missing (verify with curl)
- [ ] CSP header missing (verify with curl)
- [ ] SPF and DMARC records configured
- [ ] Server version disclosed in headers

## Verification Commands

```bash
# Check site loads
curl -I https://paleon-lab-sme.co.uk

# Verify missing HSTS
curl -I https://paleon-lab-sme.co.uk | grep -i strict

# Verify missing CSP
curl -I https://paleon-lab-sme.co.uk | grep -i content-security

# Check backup file accessible
curl https://paleon-lab-sme.co.uk/backup.bak

# Check RDP port
nmap -p 3389 paleon-lab-sme.co.uk

# Check DNS records
dig paleon-lab-sme.co.uk TXT
dig _dmarc.paleon-lab-sme.co.uk TXT

# Check old subdomain
curl -I https://old.paleon-lab-sme.co.uk
```

## Reset/Rebuild Process

### Full Rebuild

```bash
# On EC2 instance
sudo systemctl stop nginx
sudo rm -rf /var/www/paleon-lab-sme
sudo rm -rf /var/www/paleon-lab-sme-old

# Re-deploy from repository
cd /path/to/repo
sudo mkdir -p /var/www/paleon-lab-sme
sudo cp -r index.html about services solutions resources contact css js images backup.bak /var/www/paleon-lab-sme/

sudo mkdir -p /var/www/paleon-lab-sme-old
sudo cp -r old-site/* /var/www/paleon-lab-sme-old/

sudo systemctl start nginx
```

### Update Content Only

```bash
# Update specific files
sudo cp index.html /var/www/paleon-lab-sme/
sudo systemctl reload nginx
```

## AWS Permissions Required

To deploy this site, you'll need AWS permissions for:

- EC2 instance creation and management
- Security group creation and modification
- Elastic IP allocation and association
- SSH key pair management

**IAM Policy Example:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AllocateAddress",
        "ec2:AssociateAddress"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "eu-west-2"
        }
      }
    }
  ]
}
```

⚠️ **Important:** This instance should be isolated from production Paleon infrastructure.

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
│   └── main.js               # JavaScript (mobile nav, etc.)
├── images/                    # Image assets (if any)
├── backup.bak                 # INTENTIONALLY EXPOSED (fake data)
├── old-site/
│   └── index.html            # Legacy subdomain content
├── nginx.conf                 # Nginx configuration
├── expected.yaml              # Expected findings documentation
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## What NOT to Add

- Real credentials or secrets
- Real customer data
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

1. Discover both main domain and old subdomain
2. Detect expired TLS certificate via handshake
3. Observe missing HSTS and CSP headers
4. Query and analyze SPF/DMARC records
5. Detect open RDP port via TCP connect
6. Find backup.bak through path enumeration
7. Detect outdated server version from headers
8. Report findings with appropriate severity
9. Classify findings with correct claim strength
10. Generate Cyber Essentials readiness assessment

## Definition of Done

Site 4 deployment is complete when:

- [x] Website built and all pages created
- [x] Clean URLs implemented with directory structure
- [x] Mobile responsive design complete
- [x] Nginx configuration created
- [x] backup.bak file created with fake data
- [x] old subdomain content created
- [x] expected.yaml documented
- [x] README completed
- [ ] DNS records configured (pending)
- [ ] AWS EC2 deployed (pending)
- [ ] TLS certificate installed (pending)
- [ ] Security group configured (pending)
- [ ] RDP exposure configured (pending)
- [ ] All routes verified working (pending)
- [ ] Scanner validation run (pending)

## Contact

For questions about this test environment:

- Refer to expected.yaml for detailed finding specifications
- All findings are intentional and documented
- This is a controlled Paleon test environment

---

**Last Updated:** 2026-08-27  
**Site Version:** 1.0  
**Status:** Ready for deployment
