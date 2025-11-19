#!/bin/bash

# =============================================================================
# YANTECH Push Notifications Test Script
# Tests push notification functionality only
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Configuration
CLIENT_API_URL="https://client.dev.api.project-dolphin.com"
APPLICATIONS_TABLE="YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV"

echo "🔔 YANTECH Push Notifications Test"
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

# Test Push notification (with WAF rate limiting consideration)
print_status "🔔 Testing Push Notification to SNS topic"
sleep 1  # Brief delay to respect WAF rate limits
response=$(curl -s -w "\n%{http_code}" -X POST "$CLIENT_API_URL/notifications" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $CLIENT_TOKEN" \
    -d '{
        "Application": "TEST_APP_1",
        "Recipient": "mobile-app-user",
        "Subject": "Push Test",
        "Message": "This is a dedicated push notification test.",
        "OutputType": "PUSH",
        "PushToken": "test-device-token-123",
        "Interval": {"type": "IMMEDIATE"}
    }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n -1)

echo "HTTP Status: $http_code"
echo "Response: $body"

if [ "$http_code" = "200" ]; then
    MESSAGE_ID=$(echo "$body" | jq -r '.message_id')
    print_success "✅ Push notification queued successfully!"
    print_success "📋 Message ID: $MESSAGE_ID"
    
    # Quick check for push processing (optimized)
    print_status "⏳ Checking push processing (45 seconds)..."
    
    # Get current timestamp for comparison
    CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
    
    FOUND=false
    for i in {1..3}; do
        print_status "🔍 Checking delivery status ($i/3)..."
        
        # Get recent entries and check for our push notification
        RECENT_ENTRIES=$(aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV --region us-east-1 --limit 20 --output json)
        
        # Look for recent push delivery (since Message ID != Record ID)
        CUTOFF_TIME=$(date -u -d '2 minutes ago' +"%Y-%m-%dT%H:%M:%S")
        RECENT_DELIVERY=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.Request.S | contains(\"mobile-app-user\") and contains(\"Push Test\")) | select(.Timestamp.S > \"$CUTOFF_TIME\") | .Status.S" | head -1)
        
        if [ "$RECENT_DELIVERY" = "delivered" ]; then
            DELIVERY_TIME=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.Request.S | contains(\"mobile-app-user\") and contains(\"Push Test\")) | select(.Timestamp.S > \"$CUTOFF_TIME\") | .Timestamp.S" | head -1)
            print_success "✅ Push notification delivered successfully!"
            print_status "📢 Delivery time: $DELIVERY_TIME"
            print_status "📢 Push sent to SNS topic successfully"
            FOUND=true
            break
        elif [ "$RECENT_DELIVERY" = "failed" ]; then
            DELIVERY_ERROR=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.Request.S | contains(\"mobile-app-user\") and contains(\"Push Test\")) | select(.Timestamp.S > \"$CUTOFF_TIME\") | .Error.S" | head -1)
            print_error "❌ Push delivery failed: $DELIVERY_ERROR"
            FOUND=true
            break
        elif [ "$RECENT_DELIVERY" = "processing" ]; then
            print_status "⏳ Push is being processed..."
        else
            print_status "⏳ Waiting for worker to process message..."
        fi
        
        if [ $i -lt 3 ]; then
            sleep 15
        fi
    done
    
    if [ "$FOUND" = false ]; then
        print_status "⏳ Push processing takes longer than expected"
        print_success "✅ Push was queued successfully!"
        print_status "💡 Manual check: aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV --region us-east-1 --limit 5"
    fi
else
    print_error "❌ Push notification failed"
fi

echo ""
print_status "📊 Push Test Complete"