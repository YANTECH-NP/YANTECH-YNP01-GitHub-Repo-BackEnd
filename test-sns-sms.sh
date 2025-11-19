#!/bin/bash

# =============================================================================
# YANTECH SNS SMS Test Script
# Tests SMS notifications via SNS topic
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

echo "📱 YANTECH SNS SMS Test"
echo "========================"

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

# =============================================================================
# SMS TEST (COMMENTED OUT - WAITING FOR SCP POLICY ADJUSTMENT)
# =============================================================================
print_status "⚠️  SMS testing disabled - waiting for SCP policy adjustment"
print_status "💡 Uncomment the section below once SCP policy allows SMS operations"

# Uncomment this section once SCP policy is fixed:
# print_status "📱 Testing SMS Notification to +237675362377"
# response=$(curl -s -w "\n%{http_code}" -X POST "$CLIENT_API_URL/notifications" \
#     -H "Content-Type: application/json" \
#     -H "Authorization: Bearer $CLIENT_TOKEN" \
#     -d '{
#         "Application": "TEST_APP_1",
#         "Recipient": "+237675362377",
#         "Subject": "SMS Test",
#         "Message": "This is a dedicated SMS test message.",
#         "OutputType": "SMS",
#         "PhoneNumber": "+237675362377",
#         "Interval": {"type": "IMMEDIATE"}
#     }')
# 
# http_code=$(echo "$response" | tail -n1)
# body=$(echo "$response" | head -n -1)
# 
# echo "HTTP Status: $http_code"
# echo "Response: $body"
# 
# if [ "$http_code" = "200" ]; then
#     MESSAGE_ID=$(echo "$body" | jq -r '.message_id')
#     print_success "✅ SMS notification queued successfully!"
#     print_success "📋 Message ID: $MESSAGE_ID"
#     
#     # Quick check for SMS processing
#     print_status "⏳ Checking SMS processing (45 seconds)..."
#     
#     FOUND=false
#     for i in {1..3}; do
#         print_status "🔍 Checking delivery status ($i/3)..."
#         
#         # Get recent entries and filter for our message ID
#         RECENT_ENTRIES=$(aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV --region us-east-1 --limit 50 --output json)
#         
#         # Check if our message ID exists in the results
#         if echo "$RECENT_ENTRIES" | jq -e ".Items[] | select(.RecordID.S == \"$MESSAGE_ID\")" > /dev/null 2>&1; then
#             STATUS=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.RecordID.S == \"$MESSAGE_ID\") | .Status.S")
#             ERROR=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.RecordID.S == \"$MESSAGE_ID\") | .Error.S")
#             TIMESTAMP=$(echo "$RECENT_ENTRIES" | jq -r ".Items[] | select(.RecordID.S == \"$MESSAGE_ID\") | .Timestamp.S")
#             
#             echo "Status: $STATUS, Error: $ERROR, Time: $TIMESTAMP"
#             
#             if [ "$STATUS" = "delivered" ]; then
#                 print_success "✅ SMS delivered successfully!"
#                 print_status "📱 SMS sent to +237675362377 via SNS"
#                 FOUND=true
#                 break
#             elif [ "$STATUS" = "failed" ]; then
#                 print_error "❌ SMS delivery failed: $ERROR"
#                 FOUND=true
#                 break
#             fi
#         fi
#         
#         if [ $i -lt 3 ]; then
#             sleep 15
#         fi
#     done
#     
#     if [ "$FOUND" = false ]; then
#         print_status "⏳ SMS processing takes longer than expected"
#         print_success "✅ SMS was queued successfully!"
#         print_status "💡 Manual check: aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV --region us-east-1 --limit 5"
#     fi
# else
#     print_error "❌ SMS notification failed"
# fi

echo ""
print_status "📊 SMS Test Complete (Currently disabled - awaiting SCP policy fix)"