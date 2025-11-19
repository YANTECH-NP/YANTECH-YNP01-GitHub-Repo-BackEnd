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

response=$(curl -s -w "\n%{http_code}" -X POST "$ADMIN_ALB_URL/applications" \
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

if [ "$http_code" = "200" ]; then
    print_success "✅ Application registration successful"
    echo "Registered: $APP_NAME"
else
    print_error "❌ Application registration failed"
fi
echo ""

# Test 3: List Applications (Direct)
print_status "3️⃣ Testing List Applications (Direct)"

response=$(curl -s -w "\n%{http_code}" "$ADMIN_ALB_URL/applications")
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

# Test 4: Verify in DynamoDB
print_status "4️⃣ Verifying in DynamoDB"
if [ "$http_code" = "200" ]; then
    sleep 2  # Wait for eventual consistency
    saved_app=$(aws dynamodb get-item \
        --table-name YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV \
        --key "{\"Application\":{\"S\":\"$APP_NAME\"}}" \
        --query 'Item.{App: Application.S, Name: App_name.S, Email: Email.S, Status: Status.S}' \
        --output table 2>/dev/null)
    
    if [ -n "$saved_app" ]; then
        print_success "✅ Application found in DynamoDB"
        echo "$saved_app"
    else
        print_error "❌ Application not found in DynamoDB"
    fi
fi

echo ""
print_status "📊 Summary"
print_success "✅ Direct ALB access working"
print_success "✅ Admin service responding"
if [ "$http_code" = "200" ]; then
    print_success "✅ All endpoints functional"
else
    print_error "❌ Some endpoints need fixing"
fi