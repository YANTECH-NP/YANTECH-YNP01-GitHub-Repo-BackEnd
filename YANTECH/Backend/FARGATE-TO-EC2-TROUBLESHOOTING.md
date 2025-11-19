# 🚀 YANTECH Project Architecture Updates & Troubleshooting Guide

## Major Architecture Changes Implemented

### 1. **Admin Service Complete Rewrite**
- **Database Migration**: SQLite → DynamoDB
- **Port Change**: 5001 → 8001
- **Authentication**: Built-in API key system (no JWT tokens)
- **Endpoints**: `/applications` → `/app` and `/apps`
- **New Features**: API key generation, verification, management

### 2. **DynamoDB Tables Structure**
```
Applications Table: YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV
├── Primary Key: Application (String)
├── Attributes: App_name, Email, Domain, api_key, role, Status
└── Purpose: Store registered applications

API Keys Table: YANTECH-YNP01-AWS-DYNAMODB-API-KEYS-DEV (NEW)
├── Primary Key: key_hash (String)
├── GSI: AppIdIndex (app_id)
├── Attributes: id, app_id, key_hash, name, created_at, expires_at, is_active
└── Purpose: Secure API key management with SHA-256 hashing

Requests Table: YANTECH-YNP01-AWS-DYNAMODB-REQUESTS-DEV
├── Primary Key: Application + RecordID
├── GSI: OutputTypeIndex, RecipientIndex, StatusIndex
└── Purpose: Track notification requests and delivery status
```

### 3. **Infrastructure Updates**
- **ECS Task Definitions**: Updated admin service environment variables
- **IAM Policies**: Added API keys table permissions
- **Load Balancer**: Updated target groups to port 8001
- **API Gateway**: Removed Lambda JWT authorizers for admin endpoints
- **S3 Frontend**: Created `yantech-ynp456-frontend-dolphin` bucket

### 4. **Service Ports & Endpoints**
```
Requestor Service: Port 8000
├── /health
├── /auth (JWT tokens)
└── /notifications

Admin Service: Port 8001 (UPDATED)
├── /health
├── / (root status)
├── /app (create application)
├── /apps (list applications)
├── /app/{id}/api-key (generate API key)
├── /protected (API key required)
└── /verify-key (API key validation)

Worker Service: Background processing
├── SQS message polling
├── SES/SNS delivery
└── DynamoDB logging
```

### 5. **Authentication Flow Changes**
**Admin Service (NEW):**
- Public endpoints: `/`, `/health`, `/app`, `/apps`
- Protected endpoints: `/protected`, `/verify-key` (require `X-API-Key` header)
- API keys stored as SHA-256 hashes in DynamoDB
- No JWT tokens required

**Requestor Service (UNCHANGED):**
- JWT token authentication via `/auth` endpoint
- Bearer token required for `/notifications`

### 6. **CORS Configuration**
- **Frontend S3 Bucket**: `https://yantech-ynp456-frontend-dolphin.s3.amazonaws.com`
- **Admin Service**: Configured to accept requests from S3 frontend only
- **Security**: Removed wildcard (*) CORS for production security

## Deployment & Testing

### 1. **Updated Test Scripts**
All test scripts updated for new architecture:
- `test-admin-simple.sh` - Uses `/app` and `/apps` endpoints
- `test-email-notifications.sh` - Updated API key retrieval
- `curl-tests.sh` - New admin endpoints
- `production-test.sh` - Removed JWT auth for admin
- `test-all-services.js` - API key generation tests

### 2. **Infrastructure Deployment**
```bash
# Deploy new DynamoDB API keys table
cd modular-terraform
terraform apply -target=aws_dynamodb_table.api_keys

# Update ECS services with new environment variables
terraform apply -target=module.ecs

# Update load balancer target groups
terraform apply -target=module.load_balancer
```

### 3. **Service Deployment**
```bash
# Deploy updated admin service
aws ecs update-service --cluster YANTECH-cluster-dev --service YANTECH-admin-service-dev --force-new-deployment

# Monitor deployment
aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev
```

## Testing & Validation

### 1. **Admin Service Testing**
```bash
# Test health endpoint
curl https://admin.dev.api.project-dolphin.com/health

# Create application
curl -X POST https://admin.dev.api.project-dolphin.com/app \
  -H "Content-Type: application/json" \
  -d '{"App_name":"TestApp","Application":"test-001","Email":"test@example.com","Domain":"example.com"}'

# List applications
curl https://admin.dev.api.project-dolphin.com/apps

# Generate API key (replace {app_id})
curl -X POST https://admin.dev.api.project-dolphin.com/app/{app_id}/api-key \
  -H "Content-Type: application/json" \
  -d '{"name":"Test API Key"}'
```

### 2. **DynamoDB Verification**
```bash
# Check applications table
aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-APPLICATIONS-DEV --limit 5

# Check API keys table
aws dynamodb scan --table-name YANTECH-YNP01-AWS-DYNAMODB-API-KEYS-DEV --limit 5

# Verify API key hash storage
aws dynamodb get-item --table-name YANTECH-YNP01-AWS-DYNAMODB-API-KEYS-DEV --key '{"key_hash":{"S":"your-hash-here"}}'
```

### 3. **Service Monitoring**
```bash
# Watch admin service status
watch -n 10 'aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev --query "services[0].{Running:runningCount,Desired:desiredCount,Port:loadBalancers[0].containerPort}"'

# Check admin target group health (port 8001)
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/YANTECH-admin-ec2-tg-dev/XXXXXXXXX

# View admin service logs
aws logs tail /ecs/YANTECH-admin-dev --follow
```

## Troubleshooting Common Issues

### 1. **Admin Service Issues**
**Symptoms**: 500 errors, DynamoDB access denied
```bash
# Check IAM permissions
aws iam get-role-policy --role-name YANTECH-AWS-Sec-IAM-Role-Admin-ECS-dev --policy-name YANTECH-AWS-Sec-IAM-Policy-Admin-ECS-dev

# Verify environment variables
aws ecs describe-task-definition --task-definition YANTECH-admin-dev --query 'taskDefinition.containerDefinitions[0].environment'
```

### 2. **API Key Issues**
**Symptoms**: 401 Unauthorized, invalid API key
```bash
# Test API key verification
curl -X POST https://admin.dev.api.project-dolphin.com/verify-key \
  -H "X-API-Key: your-api-key-here"

# Check API key in DynamoDB
echo -n "your-api-key" | sha256sum  # Get hash
aws dynamodb get-item --table-name YANTECH-YNP01-AWS-DYNAMODB-API-KEYS-DEV --key '{"key_hash":{"S":"hash-result"}}'
```

### 3. **CORS Issues**
**Symptoms**: Frontend can't connect to admin API
```bash
# Check CORS configuration
curl -H "Origin: https://yantech-ynp456-frontend-dolphin.s3.amazonaws.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS https://admin.dev.api.project-dolphin.com/app
```

### 4. **Port Configuration Issues**
**Symptoms**: Connection refused, target group unhealthy
- Verify admin service runs on port 8001
- Check security group allows port 8001 from ALB
- Confirm target group points to port 8001

### Success Indicators
- ✅ Admin service responding on port 8001
- ✅ DynamoDB tables accessible (applications + api_keys)
- ✅ API key generation and verification working
- ✅ CORS allowing S3 frontend requests
- ✅ All test scripts passing with new endpoints
- ✅ No SQLite references remaining in codebase

### Migration Checklist
- ✅ Admin service rewritten with DynamoDB
- ✅ API keys table created and configured
- ✅ Port changed from 5001 to 8001
- ✅ Endpoints updated (/applications → /app, /apps)
- ✅ IAM permissions updated for new table
- ✅ Test scripts updated for new architecture
- ✅ S3 frontend bucket created and CORS configured
- ✅ All SQLite dependencies removed