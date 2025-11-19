#!/bin/bash

# =============================================================================
# YANTECH WAF Rate Limiting Test Script
# Tests WAF rate limiting functionality for REST API Gateway v1
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }

# Configuration
CLIENT_API_URL="https://client.dev.api.project-dolphin.com"
ADMIN_API_URL="https://admin.dev.api.project-dolphin.com"
APPLICATIONS_TABLE="YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV"

echo "🛡️ YANTECH WAF Rate Limiting Test"
echo "=================================="

# Get API key and authenticate
print_status "🔑 Getting API key and authenticating..."
CLIENT_API_KEY=$(aws dynamodb get-item --table-name $APPLICATIONS_TABLE --key '{"Application":{"S":"TEST_APP_1"}}' --query 'Item.api_key.S' --output text)

CLIENT_AUTH_RESPONSE=$(curl -s -X POST "$CLIENT_API_URL/auth" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $CLIENT_API_KEY" \
    -d '{"application": "TEST_APP_1"}')

CLIENT_TOKEN=$(echo "$CLIENT_AUTH_RESPONSE" | jq -r '.access_token')

if [ "$CLIENT_TOKEN" = "null" ]; then
    print_error "❌ Authentication failed"
    exit 1
fi

print_success "✅ Authenticated successfully"

# Test WAF rate limiting - Client API (2000/min = ~33/sec)
print_status "🚨 Testing Client API WAF Rate Limiting (2000/min)"
print_warning "Sending 40 requests rapidly to trigger rate limiting..."

BLOCKED_COUNT=0
SUCCESS_COUNT=0

for i in {1..40}; do
    response=$(curl -s -w "\n%{http_code}" -X POST "$CLIENT_API_URL/notifications" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $CLIENT_TOKEN" \
        -d '{
            "Application": "TEST_APP_1",
            "Recipient": "rate-test@example.com",
            "Subject": "Rate Limit Test '$i'",
            "Message": "Testing WAF rate limiting",
            "OutputType": "EMAIL",
            "EmailAddresses": ["rate-test@example.com"],
            "Interval": {"type": "IMMEDIATE"}
        }')
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "429" ] || [ "$http_code" = "403" ]; then
        BLOCKED_COUNT=$((BLOCKED_COUNT + 1))
        echo -n "🚫"
    elif [ "$http_code" = "200" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        echo -n "✅"
    else
        echo -n "❓($http_code)"
    fi
    
    # Small delay to avoid overwhelming
    sleep 0.1
done

echo ""
print_status "📊 Client API Rate Limiting Results:"
echo "✅ Successful requests: $SUCCESS_COUNT"
echo "🚫 Blocked requests: $BLOCKED_COUNT"

if [ $BLOCKED_COUNT -gt 0 ]; then
    print_success "✅ WAF rate limiting is working on Client API"
else
    print_warning "⚠️ No requests were blocked - rate limit may not be triggered yet"
fi

# Test Admin API rate limiting (1000/min = ~16/sec)
print_status "🚨 Testing Admin API WAF Rate Limiting (1000/min)"

ADMIN_API_KEY=$(aws dynamodb get-item --table-name $APPLICATIONS_TABLE --key '{"Application":{"S":"ADMIN_APP"}}' --query 'Item.api_key.S' --output text)

ADMIN_AUTH_RESPONSE=$(curl -s -X POST "$ADMIN_API_URL/auth" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ADMIN_API_KEY" \
    -d '{"application": "ADMIN_APP"}')

ADMIN_TOKEN=$(echo "$ADMIN_AUTH_RESPONSE" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" = "null" ]; then
    print_error "❌ Admin authentication failed"
    exit 1
fi

print_warning "Sending 25 requests rapidly to admin API..."

ADMIN_BLOCKED_COUNT=0
ADMIN_SUCCESS_COUNT=0

for i in {1..25}; do
    response=$(curl -s -w "\n%{http_code}" -X GET "$ADMIN_API_URL/applications" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "429" ] || [ "$http_code" = "403" ]; then
        ADMIN_BLOCKED_COUNT=$((ADMIN_BLOCKED_COUNT + 1))
        echo -n "🚫"
    elif [ "$http_code" = "200" ]; then
        ADMIN_SUCCESS_COUNT=$((ADMIN_SUCCESS_COUNT + 1))
        echo -n "✅"
    else
        echo -n "❓($http_code)"
    fi
    
    sleep 0.1
done

echo ""
print_status "📊 Admin API Rate Limiting Results:"
echo "✅ Successful requests: $ADMIN_SUCCESS_COUNT"
echo "🚫 Blocked requests: $ADMIN_BLOCKED_COUNT"

if [ $ADMIN_BLOCKED_COUNT -gt 0 ]; then
    print_success "✅ WAF rate limiting is working on Admin API"
else
    print_warning "⚠️ No admin requests were blocked - rate limit may not be triggered yet"
fi

# Test malicious patterns (should be blocked by AWS managed rules)
print_status "🚨 Testing AWS Managed Rules (Malicious Patterns)"

print_warning "Testing SQL injection pattern..."
response=$(curl -s -w "\n%{http_code}" -X POST "$CLIENT_API_URL/notifications" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -d '{
        "Application": "TEST_APP_1",
        "Recipient": "test@example.com",
        "Subject": "Test",
        "Message": "SELECT * FROM users WHERE id=1 OR 1=1",
        "OutputType": "EMAIL",
        "EmailAddresses": ["test@example.com"],
        "Interval": {"type": "IMMEDIATE"}
    }')

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "403" ]; then
    print_success "✅ SQL injection pattern blocked by WAF"
else
    print_warning "⚠️ SQL injection pattern not blocked (HTTP $http_code)"
fi

# Summary
echo ""
print_status "📋 WAF Testing Summary"
print_success "✅ Client API rate limiting tested (2000/min limit)"
print_success "✅ Admin API rate limiting tested (1000/min limit)"
print_success "✅ AWS managed rules tested"

if [ $BLOCKED_COUNT -gt 0 ] || [ $ADMIN_BLOCKED_COUNT -gt 0 ]; then
    print_success "🛡️ WAF protection is actively working!"
else
    print_warning "⚠️ Rate limits may need more aggressive testing to trigger"
fi

echo ""
print_status "💡 Monitoring Commands:"
echo "# Check WAF logs:"
echo "aws logs tail /aws/wafv2/YANTECH-client-api-waf-dev --follow"
echo "aws logs tail /aws/wafv2/YANTECH-admin-api-waf-dev --follow"
echo ""
echo "# Check API Gateway logs:"
echo "aws logs tail API-Gateway-Execution-Logs_<api-id>/dev --follow"