#!/bin/bash
# Site 4 Local Validation Script
# Tests that all pages and assets exist

echo "==================================="
echo "Site 4 - Local Validation"
echo "==================================="
echo ""

ERRORS=0

# Check main pages
echo "Checking main pages..."
for page in index.html about/index.html services/index.html solutions/index.html resources/index.html contact/index.html; do
    if [ -f "$page" ]; then
        echo "✓ $page"
    else
        echo "✗ $page - MISSING"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "Checking assets..."

# Check CSS
if [ -f "css/main.css" ]; then
    echo "✓ css/main.css"
else
    echo "✗ css/main.css - MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check JS
if [ -f "js/main.js" ]; then
    echo "✓ js/main.js"
else
    echo "✗ js/main.js - MISSING"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking intentional test files..."

# Check backup file
if [ -f "backup.bak" ]; then
    echo "✓ backup.bak (intentionally exposed)"
else
    echo "✗ backup.bak - MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check old site
if [ -f "old-site/index.html" ]; then
    echo "✓ old-site/index.html"
else
    echo "✗ old-site/index.html - MISSING"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Checking configuration..."

# Check nginx config
if [ -f "nginx.conf" ]; then
    echo "✓ nginx.conf"
else
    echo "✗ nginx.conf - MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check expected findings
if [ -f "expected.yaml" ]; then
    echo "✓ expected.yaml"
else
    echo "✗ expected.yaml - MISSING"
    ERRORS=$((ERRORS + 1))
fi

# Check README
if [ -f "README.md" ]; then
    echo "✓ README.md"
else
    echo "✗ README.md - MISSING"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "==================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All files present"
    echo "==================================="
    echo ""
    echo "Site 4 is ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Deploy AWS EC2 instance"
    echo "2. Configure DNS records"
    echo "3. Install and configure Nginx"
    echo "4. Set up TLS certificate"
    echo "5. Configure security group (allow 80, 443, 3389)"
    echo "6. Run Paleon scanner validation"
    exit 0
else
    echo "✗ $ERRORS file(s) missing"
    echo "==================================="
    exit 1
fi
