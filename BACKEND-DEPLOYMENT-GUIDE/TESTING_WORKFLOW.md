# YANTECH Testing Workflow

## Quick Testing Commands

### 1. Pre-Deployment Check
```bash
# Run comprehensive pre-deployment verification
bash pre-deployment-check.sh
```

### 2. Local Development Testing
```bash
# Start services
docker-compose up -d

# Wait for services to be ready
sleep 10

# Run local tests
bash curl-tests.sh

# Or run Node.js tests
node test-all-services.js

# Check logs
docker-compose logs admin
docker-compose logs requestor
docker-compose logs worker
```

### 3. Production Testing
```bash
# Test production endpoints
bash production-test.sh

# Monitor SQS queue
aws sqs get-queue-attributes --queue-url $(terraform output -raw sqs_queue_url) --attribute-names ApproximateNumberOfMessages

# Check ECS service health
aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev YANTECH-client-service-dev YANTECH-worker-service-dev
```

## Expected Test Results

### Local Testing (Docker Compose)
- **Admin Health**: `{"status": "ok"}`
- **Requestor Health**: `{"status": "ok"}`
- **Admin Auth**: JWT token returned
- **Client Auth**: JWT token returned
- **Notifications**: `{"message_id": "...", "status": "queued"}`

### Production Testing
- **Health Checks**: HTTP 200 with `{"status": "ok"}`
- **Authentication**: JWT tokens with 24h expiry
- **Notifications**: Messages queued in SQS
- **Admin Operations**: Applications registered in DynamoDB

## Troubleshooting

### Common Issues
1. **Docker services not starting**: Check `.env` files and AWS credentials
2. **Authentication failures**: Verify JWT secrets in Parameter Store
3. **SQS permission errors**: Check ECS task IAM roles
4. **SES delivery failures**: Verify email identity in SES console

### Debug Commands
```bash
# Check container logs
docker-compose logs -f [service_name]

# Verify AWS credentials
aws sts get-caller-identity

# Check parameter store values
aws ssm get-parameter --name "/yantech/dev/jwt-secret" --with-decryption
aws ssm get-parameter --name "/yantech/dev/api-keys/sample-app" --with-decryption

# Monitor SQS queue
aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)

# Check DynamoDB records
aws dynamodb scan --table-name Applications --limit 5
```

## GitHub Actions Deployment

### Before Triggering Deployment
1. ✅ All local tests pass
2. ✅ Production health checks return 200
3. ✅ Pre-deployment check passes
4. ✅ Environment variables configured
5. ✅ AWS resources exist and accessible

### Deployment Process
1. Push code to main branch
2. GitHub Actions builds and pushes Docker images
3. ECS services update with new images
4. Run production tests to verify deployment
5. Monitor CloudWatch logs for any issues

### Post-Deployment Verification
```bash
# Quick health check
curl -s https://admin.api.project-dolphin.com/health
curl -s https://requester.api.project-dolphin.com/health

# Full production test
bash production-test.sh
```

## Test Data

### Sample Application Registration
```json
{
  "App_name": "TestApp",
  "Application": "test-app-001",
  "Email": "test@example.com",
  "Domain": "example.com"
}
```

### Sample Email Notification
```json
{
  "Application": "test-app-001",
  "Recipient": "test-user",
  "Subject": "Test Email",
  "Message": "Test email message",
  "OutputType": "EMAIL",
  "EmailAddresses": ["test@example.com"],
  "Interval": {"Once": true}
}
```

### Sample SMS Notification
```json
{
  "Application": "test-app-001",
  "Recipient": "test-user",
  "Message": "Test SMS message",
  "OutputType": "SMS",
  "PhoneNumber": "+1234567890",
  "Interval": {"Once": true}
}
```