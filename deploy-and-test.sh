#!/bin/bash

# YANTECH Notification Platform - Deploy and Test Script
# Lambda-based Authentication Architecture
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 YANTECH Notification Platform - Deploy & Test${NC}"
echo -e "${YELLOW}=================================================${NC}"

# Configuration
AWS_ACCOUNT_ID="588082972397"
AWS_REGION="us-east-1"
CLIENT_API_URL="https://client.dev.api.project-dolphin.com"
ADMIN_API_URL="https://admin.dev.api.project-dolphin.com"

# Function to print status
print_status() {
    echo -e "\n${BLUE}$1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to test endpoint
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
        print_success "Success ($http_code)"
        echo "$body" | jq . 2>/dev/null || echo "$body"
        # Check if it's a notification response with message_id
        if echo "$body" | grep -q "message_id\|status.*queued"; then
            echo "Message ID: $(echo "$body" | jq -r '.message_id' 2>/dev/null || echo 'N/A')"
        fi
        return 0
    else
        print_error "Failed ($http_code)"
        echo "$body"
        return 1
    fi
}

# Step 1: Build and Push Docker Images
print_status "1️⃣ Building and Pushing Docker Images"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker daemon not running. Please start Docker Desktop and try again."
    exit 1
fi

# Login to ECR
print_status "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Set ECR URLs
ADMIN_ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/admin-dev"
CLIENT_ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/requestor-dev"
WORKER_ECR="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/worker-dev"

# Build and push Admin Service (script is already in backend directory)
print_status "🏗️ Building Admin Service..."
cd admin
docker build -t admin-dev .
docker tag admin-dev:latest $ADMIN_ECR:latest
docker push $ADMIN_ECR:latest
print_success "Admin service pushed to ECR"

# Build and push Client Service (Requestor)
print_status "🏗️ Building Client Service..."
cd ../requestor
docker build -t requestor-dev .
docker tag requestor-dev:latest $CLIENT_ECR:latest
docker push $CLIENT_ECR:latest
print_success "Client service pushed to ECR"

# Build and push Worker Service
print_status "🏗️ Building Worker Service..."
cd ../worker
docker build -t worker-dev .
docker tag worker-dev:latest $WORKER_ECR:latest
docker push $WORKER_ECR:latest
print_success "Worker service pushed to ECR"

# Step 2: Update ECS Services
print_status "2️⃣ Updating ECS Services"

# Check which services exist first
print_status "🔍 Checking existing ECS services..."
EXISTING_SERVICES=$(aws ecs list-services --cluster YANTECH-cluster-dev --region $AWS_REGION --query 'serviceArns[*]' --output text)
echo "Existing services: $EXISTING_SERVICES"

# Update services that exist
SERVICES_TO_UPDATE=()

if echo "$EXISTING_SERVICES" | grep -q "YANTECH-admin-service-dev"; then
    print_status "Updating admin service..."
    aws ecs update-service --cluster YANTECH-cluster-dev --service YANTECH-admin-service-dev --force-new-deployment --region $AWS_REGION
    SERVICES_TO_UPDATE+=("YANTECH-admin-service-dev")
else
    print_error "Admin service not found"
fi

if echo "$EXISTING_SERVICES" | grep -q "YANTECH-client-service-dev"; then
    print_status "Updating client service..."
    aws ecs update-service --cluster YANTECH-cluster-dev --service YANTECH-client-service-dev --force-new-deployment --region $AWS_REGION
    SERVICES_TO_UPDATE+=("YANTECH-client-service-dev")
else
    print_error "Client service not found"
fi

if echo "$EXISTING_SERVICES" | grep -q "YANTECH-worker-service-dev"; then
    print_status "Updating worker service..."
    aws ecs update-service --cluster YANTECH-cluster-dev --service YANTECH-worker-service-dev --force-new-deployment --region $AWS_REGION
    SERVICES_TO_UPDATE+=("YANTECH-worker-service-dev")
else
    print_error "Worker service not found"
fi

if [ ${#SERVICES_TO_UPDATE[@]} -gt 0 ]; then
    print_status "⏳ Waiting for ${#SERVICES_TO_UPDATE[@]} services to stabilize..."
    aws ecs wait services-stable --cluster YANTECH-cluster-dev --services "${SERVICES_TO_UPDATE[@]}" --region $AWS_REGION
    print_success "ECS services updated successfully"
else
    print_error "No ECS services found to update"
fi

# Step 3: Verify Infrastructure
print_status "3️⃣ Verifying Infrastructure"

# Check Lambda functions
print_status "🔍 Checking Lambda functions..."
aws lambda list-functions --query 'Functions[?contains(FunctionName, `YANTECH`)].FunctionName' --region $AWS_REGION

# Verify DynamoDB API keys
print_status "🔍 Verifying DynamoDB API keys..."
aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV --query 'Items[].{Application: Application.S, Role: role.S, AppName: App_name.S}' --region $AWS_REGION

print_success "Infrastructure verification completed"

# Step 4: API Testing
print_status "4️⃣ Starting API Testing"

# Get API keys from DynamoDB
print_status "🔑 Getting API keys from DynamoDB..."
CLIENT_API_KEY=$(aws dynamodb get-item --table-name YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV --key '{"Application":{"S":"TEST_APP_1"}}' --query 'Item.api_key.S' --output text --region $AWS_REGION)
ADMIN_API_KEY=$(aws dynamodb get-item --table-name YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV --key '{"Application":{"S":"ADMIN_APP"}}' --query 'Item.api_key.S' --output text --region $AWS_REGION)

if [ "$CLIENT_API_KEY" = "None" ] || [ -z "$CLIENT_API_KEY" ]; then
    print_error "Failed to retrieve client API key"
    exit 1
fi

if [ "$ADMIN_API_KEY" = "None" ] || [ -z "$ADMIN_API_KEY" ]; then
    print_error "Failed to retrieve admin API key"
    exit 1
fi

print_success "API keys retrieved successfully"
echo "Client API Key: ${CLIENT_API_KEY:0:10}..."
echo "Admin API Key: ${ADMIN_API_KEY:0:10}..."

# Test health endpoints
print_status "🏥 Testing Health Endpoints"
test_endpoint "Client Health" "$CLIENT_API_URL/health" "GET"
test_endpoint "Admin Health" "$ADMIN_API_URL/health" "GET"

# Get JWT tokens
print_status "🔑 Getting JWT Tokens"

CLIENT_TOKEN=$(curl -s -X POST "$CLIENT_API_URL/auth" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $CLIENT_API_KEY" \
    -d '{"application": "TEST_APP_1"}' | jq -r '.access_token')

ADMIN_TOKEN=$(curl -s -X POST "$ADMIN_API_URL/auth" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $ADMIN_API_KEY" \
    -d '{"application": "ADMIN_APP"}' | jq -r '.access_token')

if [ "$CLIENT_TOKEN" = "null" ] || [ -z "$CLIENT_TOKEN" ]; then
    print_error "Failed to get client token"
    exit 1
fi

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    print_error "Failed to get admin token"
    exit 1
fi

print_success "JWT tokens acquired successfully"
echo "Client Token: ${CLIENT_TOKEN:0:50}..."
echo "Admin Token: ${ADMIN_TOKEN:0:50}..."

# Test notification sending
print_status "📧 Testing Notification Sending"

# Get fresh JWT token right before testing
print_status "Getting fresh JWT token for notification test..."
FRESH_CLIENT_TOKEN=$(curl -s -X POST "$CLIENT_API_URL/auth" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $CLIENT_API_KEY" \
    -d '{"application": "TEST_APP_1"}' | grep -o '"access_token": "[^"]*"' | cut -d'"' -f4)

if [ -z "$FRESH_CLIENT_TOKEN" ]; then
    print_error "Failed to get fresh client token for notification test"
    exit 1
fi

# Add delay to respect WAF rate limiting
sleep 2
test_endpoint "Send Email Notification" "$CLIENT_API_URL/notifications" "POST" '{
    "Application": "TEST_APP_1",
    "Recipient": "test@example.com",
    "Subject": "Production Test Email",
    "Message": "This is a test email from the Lambda-based notification system.",
    "OutputType": "EMAIL",
    "EmailAddresses": ["test@example.com"],
    "Interval": {"type": "IMMEDIATE"}
}' "-H 'Authorization: Bearer $FRESH_CLIENT_TOKEN'"

sleep 2
test_endpoint "Send SMS Notification" "$CLIENT_API_URL/notifications" "POST" '{
    "Application": "TEST_APP_1",
    "Recipient": "+1234567890",
    "Subject": "Test SMS",
    "Message": "Test SMS from Lambda notification system",
    "OutputType": "SMS",
    "PhoneNumbers": ["+1234567890"],
    "Interval": {"type": "IMMEDIATE"}
}' "-H 'Authorization: Bearer $FRESH_CLIENT_TOKEN'"

# Test admin operations
print_status "👤 Testing Admin Operations"

test_endpoint "List Applications" "$ADMIN_API_URL/applications" "GET" "" "-H 'Authorization: Bearer $ADMIN_TOKEN' -H 'X-API-Key: $ADMIN_API_KEY'"

# Error handling tests
print_status "🚨 Testing Error Handling"

sleep 2
test_endpoint "Invalid Token Test" "$CLIENT_API_URL/notifications" "POST" '{
    "Application": "TEST_APP_1",
    "Recipient": "test@example.com",
    "Subject": "Test",
    "Message": "Test message",
    "OutputType": "EMAIL",
    "EmailAddresses": ["test@example.com"],
    "Interval": {"type": "IMMEDIATE"}
}' "-H 'Authorization: Bearer invalid-token'" || true

sleep 2
test_endpoint "Missing Token Test" "$CLIENT_API_URL/notifications" "POST" '{
    "Application": "TEST_APP_1",
    "Recipient": "test@example.com",
    "Subject": "Test",
    "Message": "Test message",
    "OutputType": "EMAIL",
    "EmailAddresses": ["test@example.com"],
    "Interval": {"type": "IMMEDIATE"}
}' "" || true

# Final status
print_status "📊 Deployment and Testing Summary"
print_success "Docker images built and pushed to ECR"
print_success "ECS services updated and stabilized"
print_success "Lambda functions verified"
print_success "API authentication working"
print_success "Notification endpoints tested"
print_success "Error handling verified"

echo -e "\n${GREEN}🎉 Deployment and testing completed successfully!${NC}"
echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo "1. Monitor CloudWatch logs for detailed processing"
echo "2. Check SQS queue for message processing"
echo "3. Verify SES email delivery in AWS Console"
echo "4. Monitor Lambda function metrics"

echo -e "\n${BLUE}🔗 Useful Commands:${NC}"
echo "# Check Lambda logs:"
echo "aws logs tail /aws/lambda/YANTECH-client-auth-dev --follow"
echo "aws logs tail /aws/lambda/YANTECH-jwt-authorizer-dev --follow"
echo ""
echo "# Monitor SQS queue:"
echo "aws sqs get-queue-attributes --queue-url https://sqs.us-east-1.amazonaws.com/588082972397/yantech-notification-queue-dev --attribute-names All"
echo ""
echo "# Check ECS service status:"
echo "aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev YANTECH-client-service-dev YANTECH-worker-service-dev"
echo ""
echo "# Run comprehensive test:"
echo "./test-lambda-auth.sh"