# Site 4 Deployment Guide

**Updated:** 2026-08-28  
**Architecture:** Minimal EC2 with Nginx + Dummy TCP Listener

## Overview

This guide covers the complete deployment of Site 4 to AWS infrastructure. The deployment uses a single minimal EC2 instance (t4g.nano) running Ubuntu 24.04 LTS ARM64.

## Prerequisites

- AWS account with console/CLI access
- Domain registered: paleon-lab-sme.co.uk
- DNS provider access (for A and TXT records)
- Local git repository with Site 4 code
- SSH client
- Admin IP address (for SSH security group rule)

## Architecture Summary

```
Internet
    │
    ▼
AWS Elastic IP
    │
    ▼
AWS Security Group (80, 443, 3389, SSH)
    │
    ▼
EC2 t4g.nano (Ubuntu 24.04 LTS ARM64)
    │
    ├── Nginx
    │   ├── paleon-lab-sme.co.uk (main site)
    │   ├── www.paleon-lab-sme.co.uk (main site)
    │   └── old.paleon-lab-sme.co.uk (old subdomain)
    │
    ├── Self-signed expired TLS certificate
    │
    └── Dummy TCP listener on port 3389 (socat)
```

## Step 1: Launch EC2 Instance

### 1.1 Create Security Group

```bash
# Using AWS CLI (or use console)
aws ec2 create-security-group \
  --group-name paleon-site4-sg \
  --description "Security group for Paleon Site 4 test environment" \
  --region eu-west-2

# Note the GroupId from output
SGID="sg-xxxxxxxxx"

# Add inbound rules
# HTTP
aws ec2 authorize-security-group-ingress \
  --group-id $SGID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --region eu-west-2

# HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $SGID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --region eu-west-2

# Port 3389 (INTENTIONAL - for testing)
aws ec2 authorize-security-group-ingress \
  --group-id $SGID \
  --protocol tcp \
  --port 3389 \
  --cidr 0.0.0.0/0 \
  --region eu-west-2

# SSH (restrict to your IP)
aws ec2 authorize-security-group-ingress \
  --group-id $SGID \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_ADMIN_IP/32 \
  --region eu-west-2
```

### 1.2 Launch Instance

```bash
# Find ARM64 Ubuntu 24.04 LTS AMI
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-arm64-server-*" \
  --query 'Images[0].ImageId' \
  --region eu-west-2 \
  --output text

# Launch t4g.nano instance
aws ec2 run-instances \
  --image-id ami-xxxxxxxxx \
  --instance-type t4g.nano \
  --key-name YOUR_KEY_NAME \
  --security-group-ids $SGID \
  --region eu-west-2 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=paleon-site4}]'

# Note the InstanceId from output
INSTANCE_ID="i-xxxxxxxxx"
```

### 1.3 Allocate and Associate Elastic IP

```bash
# Allocate Elastic IP
aws ec2 allocate-address \
  --domain vpc \
  --region eu-west-2

# Note the AllocationId and PublicIp
ALLOC_ID="eipalloc-xxxxxxxxx"
ELASTIC_IP="xx.xx.xx.xx"

# Associate with instance
aws ec2 associate-address \
  --instance-id $INSTANCE_ID \
  --allocation-id $ALLOC_ID \
  --region eu-west-2
```

## Step 2: Configure DNS

Configure these records at your DNS provider:

```dns
# A Records
paleon-lab-sme.co.uk          IN A    [ELASTIC_IP]
www.paleon-lab-sme.co.uk      IN A    [ELASTIC_IP]
old.paleon-lab-sme.co.uk      IN A    [ELASTIC_IP]

# SPF Record (weak - intentional)
paleon-lab-sme.co.uk          IN TXT  "v=spf1 include:_spf.google.com ~all"

# DMARC Record (p=none - intentional)
_dmarc.paleon-lab-sme.co.uk   IN TXT  "v=DMARC1; p=none; rua=mailto:dmarc@paleon-lab-sme.co.uk"
```

**Important:** Do NOT enable DNSSEC (intentional omission for testing).

Wait for DNS propagation (5-30 minutes):

```bash
# Check propagation
dig paleon-lab-sme.co.uk +short
dig old.paleon-lab-sme.co.uk +short
dig paleon-lab-sme.co.uk TXT +short
dig _dmarc.paleon-lab-sme.co.uk TXT +short
```

## Step 3: Initial Server Setup

### 3.1 Connect to Instance

```bash
ssh -i ~/.ssh/YOUR_KEY.pem ubuntu@[ELASTIC_IP]
```

### 3.2 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 3.3 Install Required Packages

```bash
# Install Nginx
sudo apt install -y nginx

# Install Nginx headers-more module (for custom Server header)
# On Ubuntu 24.04 LTS, nginx-extras is replaced by individual module packages
sudo apt install -y libnginx-mod-http-headers-more

# Install socat (for dummy TCP listener)
sudo apt install -y socat

# Install OpenSSL (for certificate generation)
sudo apt install -y openssl

# Install git (for deploying site)
sudo apt install -y git
```

## Step 4: Create Self-Signed Expired Certificate

```bash
# Generate self-signed certificate valid for 1 day
sudo openssl req -x509 \
  -newkey rsa:2048 \
  -keyout /etc/ssl/private/paleon-lab-sme.key \
  -out /etc/ssl/certs/paleon-lab-sme.crt \
  -days 1 \
  -nodes \
  -subj "/C=GB/ST=Greater Manchester/L=Manchester/O=Northbridge Business Services/CN=paleon-lab-sme.co.uk" \
  -addext "subjectAltName=DNS:paleon-lab-sme.co.uk,DNS:www.paleon-lab-sme.co.uk,DNS:old.paleon-lab-sme.co.uk"

# Set permissions
sudo chmod 600 /etc/ssl/private/paleon-lab-sme.key
sudo chmod 644 /etc/ssl/certs/paleon-lab-sme.crt

# Verify certificate
sudo openssl x509 -in /etc/ssl/certs/paleon-lab-sme.crt -text -noout | grep "Not After"
```

**Note:** Wait 2 days for certificate to expire naturally, or deploy immediately and test in 2 days.

## Step 5: Deploy Website Files

### 5.1 Clone Repository

```bash
# Clone to temporary location
cd /tmp
git clone [YOUR_REPO_URL] site4
cd site4
```

### 5.2 Copy Files to Web Root

```bash
# Create directories
sudo mkdir -p /var/www/paleon-lab-sme
sudo mkdir -p /var/www/paleon-lab-sme-old

# Copy main site
sudo cp -r index.html about/ services/ solutions/ resources/ contact/ css/ js/ images/ backup.bak /var/www/paleon-lab-sme/

# Copy old subdomain site
sudo cp -r old-site/* /var/www/paleon-lab-sme-old/

# Set permissions
sudo chown -R www-data:www-data /var/www/paleon-lab-sme
sudo chown -R www-data:www-data /var/www/paleon-lab-sme-old
sudo chmod -R 755 /var/www/paleon-lab-sme
sudo chmod -R 755 /var/www/paleon-lab-sme-old
```

### 5.3 Verify Files

```bash
ls -la /var/www/paleon-lab-sme/
ls -la /var/www/paleon-lab-sme/backup.bak  # Must exist
ls -la /var/www/paleon-lab-sme-old/
```

## Step 6: Configure Nginx

### 6.1 Deploy Nginx Configuration

```bash
# Copy nginx config
sudo cp /tmp/site4/nginx.conf /etc/nginx/sites-available/paleon-lab-sme

# Create symlink
sudo ln -s /etc/nginx/sites-available/paleon-lab-sme /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default
```

### 6.2 Test Configuration

```bash
sudo nginx -t
```

Expected output: `syntax is ok` and `test is successful`

### 6.3 Restart Nginx

```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

## Step 7: Configure Dummy TCP Listener on Port 3389

### 7.1 Create Systemd Service

```bash
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
```

### 7.2 Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable dummy-rdp
sudo systemctl start dummy-rdp
sudo systemctl status dummy-rdp
```

### 7.3 Verify Listener

```bash
# Check port is listening
sudo netstat -tlnp | grep 3389

# Or use ss
sudo ss -tlnp | grep 3389
```

## Step 8: Verification

### 8.1 Test from Server

```bash
# Test HTTP redirect to HTTPS
curl -I http://paleon-lab-sme.co.uk

# Test HTTPS (will show certificate error - expected)
curl -Ik https://paleon-lab-sme.co.uk

# Verify missing HSTS
curl -Ik https://paleon-lab-sme.co.uk | grep -i strict
# Should return nothing

# Verify missing CSP
curl -Ik https://paleon-lab-sme.co.uk | grep -i content-security
# Should return nothing

# Verify Server header shows old version
curl -Ik https://paleon-lab-sme.co.uk | grep -i server
# Should show: Server: nginx/1.14.0

# Verify backup.bak accessible
curl https://paleon-lab-sme.co.uk/backup.bak
# Should return file contents

# Verify old subdomain
curl -Ik https://old.paleon-lab-sme.co.uk
```

### 8.2 Test from External Machine

```bash
# Test port 3389 reachability
nmap -p 3389 paleon-lab-sme.co.uk
# Should show: 3389/tcp open

# Or use nc
nc -zv paleon-lab-sme.co.uk 3389
# Should show: succeeded

# Test certificate expiry
echo | openssl s_client -connect paleon-lab-sme.co.uk:443 2>/dev/null | openssl x509 -noout -dates
```

### 8.3 Test All Routes

```bash
# Test main site routes
curl -Ik https://paleon-lab-sme.co.uk/
curl -Ik https://paleon-lab-sme.co.uk/about
curl -Ik https://paleon-lab-sme.co.uk/services
curl -Ik https://paleon-lab-sme.co.uk/solutions
curl -Ik https://paleon-lab-sme.co.uk/resources
curl -Ik https://paleon-lab-sme.co.uk/contact

# All should return 200 OK
```

## Step 9: Final Checklist

- [ ] EC2 instance running in eu-west-2
- [ ] Elastic IP associated
- [ ] Security group configured (80, 443, 3389, SSH)
- [ ] DNS A records propagated (main, www, old)
- [ ] DNS TXT records configured (SPF, DMARC)
- [ ] DNSSEC NOT enabled
- [ ] Nginx installed with headers-more module
- [ ] Website files deployed to /var/www/paleon-lab-sme/
- [ ] Old site deployed to /var/www/paleon-lab-sme-old/
- [ ] backup.bak file accessible at root
- [ ] Self-signed certificate created and expired (or will expire in 2 days)
- [ ] Nginx configuration deployed
- [ ] HSTS header missing (verified)
- [ ] CSP header missing (verified)
- [ ] Server header shows nginx/1.14.0
- [ ] Dummy TCP listener on port 3389 running
- [ ] Port 3389 externally reachable (verified)
- [ ] All routes working (/, /about, /services, etc.)
- [ ] old.paleon-lab-sme.co.uk resolves and loads

## Maintenance

### Update Website Content

```bash
# SSH to server
ssh -i ~/.ssh/YOUR_KEY.pem ubuntu@[ELASTIC_IP]

# Pull latest changes
cd /tmp
git clone [YOUR_REPO_URL] site4-update
cd site4-update

# Backup current site
sudo cp -r /var/www/paleon-lab-sme /var/www/paleon-lab-sme.backup

# Deploy updates
sudo cp -r index.html about/ services/ solutions/ resources/ contact/ css/ js/ images/ backup.bak /var/www/paleon-lab-sme/

# Test
curl -I https://paleon-lab-sme.co.uk

# Reload Nginx
sudo systemctl reload nginx
```

### Reset to Clean State

```bash
# Stop services
sudo systemctl stop nginx dummy-rdp

# Clear websites
sudo rm -rf /var/www/paleon-lab-sme/*
sudo rm -rf /var/www/paleon-lab-sme-old/*

# Redeploy (follow Step 5)

# Start services
sudo systemctl start nginx dummy-rdp
```

### Check Service Status

```bash
# Check Nginx
sudo systemctl status nginx

# Check dummy RDP listener
sudo systemctl status dummy-rdp

# Check listening ports
sudo netstat -tlnp | grep -E ':(80|443|3389)'
```

### View Logs

```bash
# Nginx access logs
sudo tail -f /var/log/nginx/paleon-lab-sme-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/paleon-lab-sme-error.log

# System logs
sudo journalctl -u nginx -f
sudo journalctl -u dummy-rdp -f
```

## Troubleshooting

### Issue: Port 3389 not reachable

```bash
# Check service running
sudo systemctl status dummy-rdp

# Check port listening
sudo netstat -tlnp | grep 3389

# Check security group allows 3389 from 0.0.0.0/0
# Check from AWS console

# Test locally first
nc -zv localhost 3389
```

### Issue: Certificate not expired

```bash
# Check current status
openssl x509 -in /etc/ssl/certs/paleon-lab-sme.crt -noout -dates

# If still valid, wait for expiry or regenerate with very short validity
```

### Issue: Routes return 404

```bash
# Check Nginx config
sudo nginx -t

# Check file permissions
ls -la /var/www/paleon-lab-sme/

# Check Nginx error log
sudo tail -n 50 /var/log/nginx/paleon-lab-sme-error.log
```

### Issue: Missing headers not working

```bash
# Verify headers-more module installed
dpkg -l | grep libnginx-mod-http-headers-more

# Check Nginx config includes more_set_headers
grep more_set_headers /etc/nginx/sites-enabled/paleon-lab-sme

# Reload Nginx
sudo systemctl reload nginx
```

## Teardown

To completely remove the infrastructure:

```bash
# From AWS CLI
# Disassociate Elastic IP
aws ec2 disassociate-address --association-id eipassoc-xxxxxxxxx --region eu-west-2

# Release Elastic IP
aws ec2 release-address --allocation-id $ALLOC_ID --region eu-west-2

# Terminate instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region eu-west-2

# Delete security group (after instance terminates)
aws ec2 delete-security-group --group-id $SGID --region eu-west-2
```

Remove DNS records from your DNS provider.

## Cost Estimate

- **t4g.nano:** ~$3/month
- **Elastic IP (associated):** $0
- **8GB gp3 storage:** ~$0.80/month
- **Data transfer:** ~$1-2/month

**Total:** ~$5-6/month

## Security Notes

- This is a TEST ENVIRONMENT with INTENTIONAL security weaknesses
- Do NOT use for real traffic or real data
- Port 3389 listener provides no actual remote access
- All credentials in backup.bak are FAKE
- Certificate is self-signed for testing only
- Isolated from production Paleon infrastructure

---

**Deployment Status:** Ready for implementation  
**Estimated Time:** 2-3 hours  
**Infrastructure:** Minimal (single t4g.nano)
