#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== YANTECH Production API Testing ===${NC}"

# Setup - Updated for REST API Gateway v1
export ADMIN_API_URL="https://admin.dev.api.project-dolphin.com"
export CLIENT_API_URL="https://client.dev.api.project-dolphin.com"

# Get API key from AWS Parameter Store
echo -e "${BLUE}Getting API key from Parameter Store...${NC}"
export API_KEY=$(aws ssm get-parameter --name "/yantech/dev/api-keys/sample-app" --with-decryption --query 'Parameter.Value' --output text)

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Failed to retrieve API key${NC}"
    exit 1
fi

echo -e "${GREEN}API Key retrieved successfully${NC}"

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="$3"
    local data="$4"
    local headers="$5"
    
    echo -e "\n${YELLOW}Testing: $name${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" $headers "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" $headers -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ Success ($http_code)${NC}"
        echo "$body" | jq . 2>/dev/null || echo "$body"
        return 0
    else
        echo -e "${RED}✗ Failed ($http_code)${NC}"
        echo "$body"
        return 1
    fi
}

# Health checks
echo -e "\n${BLUE}=== HEALTH CHECKS ===${NC}"
test_endpoint "Admin Health" "$ADMIN_API_URL/health" "GET"
test_endpoint "Client Health" "$CLIENT_API_URL/health" "GET"

# Authentication
echo -e "\n${BLUE}=== AUTHENTICATION ===${NC}"
CLIENT_TOKEN=$(curl -s -X POST "$CLIENT_API_URL/auth" \
    -H "Content-Type: application/json" \
    -d '{"username": "prod-client", "role": "client"}' | jq -r '.access_token')

ADMIN_TOKEN=$(curl -s -X POST "$ADMIN_API_URL/admin/auth" \
    -H "Content-Type: application/json" \
    -d '{"username": "prod-admin", "role": "admin"}' | jq -r '.access_token')

if [ "$CLIENT_TOKEN" = "null" ] || [ -z "$CLIENT_TOKEN" ]; then
    echo -e "${RED}Failed to get client token${NC}"
    exit 1
fi

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo -e "${RED}Failed to get admin token${NC}"
    exit 1
fi

echo -e "${GREEN}Tokens acquired successfully${NC}"
echo -e "Client Token: ${CLIENT_TOKEN:0:50}..."
echo -e "Admin Token: ${ADMIN_TOKEN:0:50}..."

# Admin Operations
echo -e "\n${BLUE}=== ADMIN OPERATIONS ===${NC}"
test_endpoint "Register Application" "$ADMIN_API_URL/admin/applications" "POST" '{
  "App_name": "ProductionTestApp",
  "Application": "prod-test-app-001",
  "Email": "admin@project-dolphin.com",
  "Domain": "project-dolphin.com"
}' "-H 'Authorization: Bearer $ADMIN_TOKEN' -H 'X-API-Key: $API_KEY'"

test_endpoint "List Applications" "$ADMIN_API_URL/admin/applications" "GET" "" "-H 'Authorization: Bearer $ADMIN_TOKEN' -H 'X-API-Key: $API_KEY'"

# Client Notifications
echo -e "\n${BLUE}=== NOTIFICATION TESTING ===${NC}"
# Add delay between requests to respect WAF rate limiting (2000/min = ~33/sec)
sleep 2
test_endpoint "Send Email Notification" "$CLIENT_API_URL/notifications" "POST" '{
  "Application": "sample-app",
  "Recipient": "production-user",
  "Subject": "Production Test Email",
  "Message": "This is a production test email message",
  "OutputType": "EMAIL",
  "EmailAddresses": ["notifications@project-dolphin.com"],
  "Interval": {"Once": true}
}' "-H 'Authorization: Bearer $CLIENT_TOKEN' -H 'X-API-Key: $API_KEY'"

sleep 2
test_endpoint "Send SMS Notification" "$CLIENT_API_URL/notifications" "POST" '{
  "Application": "sample-app",
  "Recipient": "production-user",
  "Message": "Production SMS test message",
  "OutputType": "SMS",
  "PhoneNumber": "+1234567890",
  "Interval": {"Once": true}
}' "-H 'Authorization: Bearer $CLIENT_TOKEN' -H 'X-API-Key: $API_KEY'"

sleep 2
test_endpoint "Send PUSH Notification" "$CLIENT_API_URL/notifications" "POST" '{
  "Application": "sample-app",
  "Recipient": "production-user",
  "Message": "Production push test message",
  "OutputType": "PUSH",
  "PushToken": "sample-push-token-12345",
  "Interval": {"Once": true}
}' "-H 'Authorization: Bearer $CLIENT_TOKEN' -H 'X-API-Key: $API_KEY'"

# Error Testing
echo -e "\n${BLUE}=== ERROR HANDLING TESTS ===${NC}"
test_endpoint "Invalid Token Test" "$CLIENT_API_URL/notifications" "POST" '{
  "Application": "sample-app",
  "Recipient": "test-user",
  "Message": "Test message",
  "OutputType": "EMAIL",
  "EmailAddresses": ["test@example.com"],
  "Interval": {"Once": true}
}' "-H 'Authorization: Bearer invalid-token' -H 'X-API-Key: $API_KEY'" || true

test_endpoint "Missing API Key Test" "$CLIENT_API_URL/notifications" "POST" '{
  "Application": "sample-app",
  "Recipient": "test-user",
  "Message": "Test message",
  "OutputType": "EMAIL",
  "EmailAddresses": ["test@example.com"],
  "Interval": {"Once": true}
}' "-H 'Authorization: Bearer $CLIENT_TOKEN'" || true

echo -e "\n${GREEN}=== Production testing completed! ===${NC}"
echo -e "${YELLOW}Check AWS CloudWatch logs for detailed processing information${NC}"
echo -e "${YELLOW}Monitor SQS queue for message processing${NC}"