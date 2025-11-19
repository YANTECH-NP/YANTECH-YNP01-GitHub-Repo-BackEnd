#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== YANTECH Local Development Testing ===${NC}"
echo -e "${BLUE}Testing services on localhost (Docker Compose)${NC}"

# Test function
test_local_endpoint() {
    local name="$1"
    local url="$2"
    local method="$3"
    local data="$4"
    
    echo -e "\n${YELLOW}$name${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ Success ($http_code)${NC}"
        echo "$body" | jq . 2>/dev/null || echo "$body"
    else
        echo -e "${RED}✗ Failed ($http_code)${NC}"
        echo "$body"
    fi
}

echo -e "\n${BLUE}=== ADMIN SERVICE TESTS (Port 8001) ===${NC}"

test_local_endpoint "1. Health Check" "http://localhost:8001/health" "GET"

test_local_endpoint "2. Admin Authentication" "http://localhost:8001/admin/auth" "POST" '{
  "username": "admin",
  "role": "admin"
}'

# Get admin token for subsequent requests
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8001/admin/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "role": "admin"}' | jq -r '.access_token' 2>/dev/null || echo "")

test_local_endpoint "3. Register Application" "http://localhost:8001/admin/applications" "POST" '{
  "App_name": "TestApp",
  "Application": "test-app-001",
  "Email": "test@example.com",
  "Domain": "example.com"
}'

test_local_endpoint "4. List Applications" "http://localhost:8001/admin/applications" "GET"

echo -e "\n${BLUE}=== REQUESTOR SERVICE TESTS (Port 8000) ===${NC}"

test_local_endpoint "1. Health Check" "http://localhost:8000/health" "GET"

test_local_endpoint "2. Generate Auth Token" "http://localhost:8000/auth" "POST" '{
  "username": "client",
  "role": "client"
}'

# Get client token for subsequent requests
CLIENT_TOKEN=$(curl -s -X POST http://localhost:8000/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "client", "role": "client"}' | jq -r '.access_token' 2>/dev/null || echo "")

test_local_endpoint "3. Send Email Notification" "http://localhost:8000/notifications" "POST" '{
  "Application": "test-app-001",
  "Recipient": "test-user",
  "Subject": "Test Email",
  "Message": "Test email message",
  "OutputType": "EMAIL",
  "EmailAddresses": ["test@example.com"],
  "Interval": {"Once": true}
}'

test_local_endpoint "4. Send SMS Notification" "http://localhost:8000/notifications" "POST" '{
  "Application": "test-app-001",
  "Recipient": "test-user",
  "Message": "Test SMS message",
  "OutputType": "SMS",
  "PhoneNumber": "+1234567890",
  "Interval": {"Once": true}
}'

test_local_endpoint "5. Send PUSH Notification" "http://localhost:8000/notifications" "POST" '{
  "Application": "test-app-001",
  "Recipient": "test-user",
  "Message": "Test push message",
  "OutputType": "PUSH",
  "PushToken": "sample-push-token-12345",
  "Interval": {"Once": true}
}'

echo -e "\n${BLUE}=== WORKER SERVICE ===${NC}"
echo -e "${YELLOW}Worker service runs in background - no HTTP endpoints${NC}"
echo -e "${YELLOW}Check Docker logs: docker-compose logs worker${NC}"

echo -e "\n${GREEN}=== Local testing completed! ===${NC}"
echo -e "${YELLOW}Check SQS messages and worker logs for processing status${NC}"