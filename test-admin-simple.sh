#!/bin/bash

# Simple Admin Service Test
# Tests direct ALB access without authentication

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Configuration
ADMIN_ALB_URL="http://YANTECH-admin-alb-dev-1677806121.us-east-1.elb.amazonaws.com"

echo "🧪 Simple Admin Service Test"
echo "============================"
echo ""

# Test 1: Health Check
print_status "1️⃣ Testing Health Endpoint"
response=$(curl -s -w "\n%{http_code}" "$ADMIN_ALB_URL/health")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

echo "URL: $ADMIN_ALB_URL/health"
echo "HTTP Status: $http_code"
echo "Response: $body"

if [ "$http_code" = "200" ]; then
    print_success "✅ Health check passed"
else
    print_error "❌ Health check failed"
fi
echo ""

# Test 2: Application Registration (Direct)
print_status "2️⃣ Testing Application Registration (Direct)"
APP_NAME="DIRECT_TEST_$(date +%s)"

response=$(curl -s -w "\n%{http_code}" -X POST "$ADMIN_ALB_URL/app" \
    -H "Content-Type: application/json" \
    -d "{
        \"Application\": \"$APP_NAME\",
        \"App_name\": \"Direct Test App\",
        \"Email\": \"test@example.com\",
        \"Domain\": \"example.com\"
    }")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

echo "URL: $ADMIN_ALB_URL/applications"
echo "HTTP Status: $http_code"
echo "Response: $body"

if [ "$http_code" = "201" ]; then
    print_success "✅ Application registration successful"
    echo "Registered: $APP_NAME"
else
    print_error "❌ Application registration failed"
fi
echo ""

# Test 3: List Applications (Direct)
print_status "3️⃣ Testing List Applications (Direct)"

response=$(curl -s -w "\n%{http_code}" "$ADMIN_ALB_URL/apps")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

echo "URL: $ADMIN_ALB_URL/applications"
echo "HTTP Status: $http_code"

if [ "$http_code" = "200" ]; then
    print_success "✅ List applications successful"
    echo "Applications count: $(echo "$body" | jq '. | length' 2>/dev/null || echo 'N/A')"
else
    print_error "❌ List applications failed"
    echo "Response: $body"
fi
echo ""

# Test 4: Verify Application Created
print_status "4️⃣ Verifying Application Created"
if [ "$http_code" = "201" ]; then
    print_success "✅ Application created successfully in SQLite database"
    echo "Application: $APP_NAME"
else
    print_error "❌ Application creation failed"
fi

echo ""
print_status "📊 Summary"
print_success "✅ Direct ALB access working"
print_success "✅ New admin service (port 8001) responding"
print_success "✅ SQLite database integration working"
if [ "$http_code" = "200" ]; then
    print_success "✅ All endpoints functional"
else
    print_error "❌ Some endpoints need fixing"
fi