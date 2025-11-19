#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== YANTECH Pre-Deployment Checklist ===${NC}"
echo -e "${BLUE}Verifying all requirements before GitHub Actions deployment${NC}"

# Track overall status
OVERALL_STATUS=0

# Check function
check_requirement() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    echo -e "\n${YELLOW}Checking: $name${NC}"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name - OK${NC}"
        return 0
    else
        echo -e "${RED}✗ $name - FAILED${NC}"
        if [ -n "$expected" ]; then
            echo -e "${YELLOW}Expected: $expected${NC}"
        fi
        OVERALL_STATUS=1
        return 1
    fi
}

# AWS CLI and Credentials
echo -e "\n${BLUE}=== AWS ENVIRONMENT ===${NC}"
check_requirement "AWS CLI installed" "aws --version"
check_requirement "AWS credentials configured" "aws sts get-caller-identity"
check_requirement "Correct AWS region" "aws configure get region | grep -q us-east-1"

# Terraform Infrastructure
echo -e "\n${BLUE}=== TERRAFORM INFRASTRUCTURE ===${NC}"
check_requirement "Terraform installed" "terraform --version"

# Check if we're in the right directory for terraform commands
if [ -d "d:/YANTECH PROJECT/YANTECH-YNP01-GitHub-Repo-Infra-Dolphin/modular-terraform" ]; then
    cd "d:/YANTECH PROJECT/YANTECH-YNP01-GitHub-Repo-Infra-Dolphin/modular-terraform"
    check_requirement "Terraform state exists" "terraform show > /dev/null"
    check_requirement "ECR repositories exist" "terraform output admin_ecr_repository_url > /dev/null"
    check_requirement "ECS cluster exists" "terraform output ecs_cluster_name > /dev/null"
    check_requirement "ALB exists" "terraform output admin_api_gateway_url > /dev/null"
    cd - > /dev/null
else
    echo -e "${RED}✗ Modular terraform directory not found${NC}"
    OVERALL_STATUS=1
fi

# AWS Resources
echo -e "\n${BLUE}=== AWS RESOURCES ===${NC}"
check_requirement "SQS queue exists" "aws sqs get-queue-url --queue-name YANTECH-queue-dev"
check_requirement "DynamoDB table exists" "aws dynamodb describe-table --table-name Applications"
check_requirement "SES identity verified" "aws ses get-identity-verification-attributes --identities notifications@project-dolphin.com | grep -q Success"
check_requirement "SNS topic exists" "aws sns list-topics | grep -q YANTECH"

# Parameter Store
echo -e "\n${BLUE}=== PARAMETER STORE ===${NC}"
check_requirement "JWT secret exists" "aws ssm get-parameter --name '/yantech/dev/jwt-secret' --with-decryption"
check_requirement "API key exists" "aws ssm get-parameter --name '/yantech/dev/api-keys/sample-app' --with-decryption"

# Docker and Local Testing
echo -e "\n${BLUE}=== DOCKER ENVIRONMENT ===${NC}"
check_requirement "Docker installed" "docker --version"
check_requirement "Docker Compose installed" "docker-compose --version"

# Check if services can be built
echo -e "\n${BLUE}=== DOCKER BUILDS ===${NC}"
cd "d:/YANTECH PROJECT/YANTECH-YNP01-GitHub-Repo-BackEnd"

check_requirement "Admin service builds" "docker build -t test-admin ./admin"
check_requirement "Requestor service builds" "docker build -t test-requestor ./requestor"  
check_requirement "Worker service builds" "docker build -t test-worker ./worker"

# Clean up test images
docker rmi test-admin test-requestor test-worker > /dev/null 2>&1 || true

# Environment Files
echo -e "\n${BLUE}=== ENVIRONMENT FILES ===${NC}"
check_requirement "Admin .env exists" "[ -f ./admin/.env ]"
check_requirement "Requestor .env exists" "[ -f ./requestor/.env ]"
check_requirement "Worker .env exists" "[ -f ./worker/.env ]"

# Test Scripts
echo -e "\n${BLUE}=== TEST SCRIPTS ===${NC}"
check_requirement "Local test script exists" "[ -f ./curl-tests.sh ]"
check_requirement "Production test script exists" "[ -f ./production-test.sh ]"
check_requirement "Node.js test script exists" "[ -f ./test-all-services.js ]"

# GitHub Actions
echo -e "\n${BLUE}=== GITHUB ACTIONS ===${NC}"
check_requirement "GitHub Actions workflow exists" "[ -f ./.github/workflows/deploy.yml ]"

# Network Connectivity
echo -e "\n${BLUE}=== NETWORK CONNECTIVITY ===${NC}"
check_requirement "Can reach AWS ECR" "curl -s https://588082972397.dkr.ecr.us-east-1.amazonaws.com > /dev/null"
check_requirement "Can reach GitHub" "curl -s https://api.github.com > /dev/null"

# Final Status
echo -e "\n${BLUE}=== DEPLOYMENT READINESS ===${NC}"
if [ $OVERALL_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Ready for GitHub Actions deployment${NC}"
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Run local tests: bash curl-tests.sh"
    echo -e "2. Test production endpoints: bash production-test.sh"
    echo -e "3. Commit and push to trigger GitHub Actions"
    echo -e "4. Monitor deployment in GitHub Actions tab"
else
    echo -e "${RED}✗ Some checks failed. Please fix issues before deployment${NC}"
    exit 1
fi

cd - > /dev/null