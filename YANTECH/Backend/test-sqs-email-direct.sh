#!/bin/bash

# =============================================================================
# YANTECH Direct SQS Email Test Script
# Tests email functionality by sending directly to SQS queue
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
QUEUE_URL="https://sqs.us-east-1.amazonaws.com/588082972397/yantech-notification-queue-dev"
REQUESTS_TABLE="YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV"

echo "📧 YANTECH Direct SQS Email Test"
echo "================================="

# Generate a unique message ID
MESSAGE_ID=$(uuidgen 2>/dev/null || echo "test-$(date +%s)")

print_status "🔄 Sending email notification directly to SQS queue..."

# Send message directly to SQS
aws sqs send-message \
    --queue-url "$QUEUE_URL" \
    --message-body '{
        "RecordID": "'$MESSAGE_ID'",
        "Application": "TEST_APP_1",
        "Recipient": "bemnjichiella@gmail.com",
        "Subject": "Direct SQS Test - YANTECH Notification Platform",
        "Message": "This is a direct SQS test email from your YANTECH notification system. The worker should process this message and send via SES!",
        "OutputType": "EMAIL",
        "EmailAddresses": ["bemnjichiella@gmail.com"],
        "Interval": {"type": "IMMEDIATE"},
        "Timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
    }' \
    --region us-east-1

if [ $? -eq 0 ]; then
    print_success "✅ Message sent to SQS successfully!"
    print_success "📋 Message ID: $MESSAGE_ID"
    
    print_status "⏳ Waiting for worker to process the message (60 seconds)..."
    
    FOUND=false
    for i in {1..4}; do
        print_status "🔍 Checking processing status ($i/4)..."
        
        # Check DynamoDB for the processed message
        RESULT=$(aws dynamodb get-item \
            --table-name "$REQUESTS_TABLE" \
            --key '{"RecordID":{"S":"'$MESSAGE_ID'"}}' \
            --region us-east-1 \
            --output json 2>/dev/null || echo '{}')
        
        if echo "$RESULT" | jq -e '.Item' > /dev/null 2>&1; then
            STATUS=$(echo "$RESULT" | jq -r '.Item.Status.S // "unknown"')
            ERROR=$(echo "$RESULT" | jq -r '.Item.Error.S // "none"')
            TIMESTAMP=$(echo "$RESULT" | jq -r '.Item.Timestamp.S // "unknown"')
            
            print_status "📊 Status: $STATUS, Error: $ERROR, Time: $TIMESTAMP"
            
            if [ "$STATUS" = "delivered" ]; then
                print_success "✅ Email delivered successfully!"
                print_success "📬 Check bemnjichiella@gmail.com inbox for the email"
                FOUND=true
                break
            elif [ "$STATUS" = "failed" ]; then
                print_error "❌ Email delivery failed: $ERROR"
                FOUND=true
                break
            elif [ "$STATUS" = "processing" ]; then
                print_status "⏳ Email is being processed..."
            fi
        else
            print_status "⏳ Message not yet processed by worker..."
        fi
        
        if [ $i -lt 4 ]; then
            sleep 15
        fi
    done
    
    if [ "$FOUND" = false ]; then
        print_status "⏳ Email processing takes longer than expected"
        print_status "💡 Manual check: aws dynamodb get-item --table-name $REQUESTS_TABLE --key '{\"RecordID\":{\"S\":\"$MESSAGE_ID\"}}' --region us-east-1"
        print_status "💡 Check worker logs: aws logs tail /ecs/YANTECH-worker-dev --region us-east-1 --since 5m"
    fi
else
    print_error "❌ Failed to send message to SQS"
fi

echo ""
print_status "📊 Direct SQS Email Test Complete"