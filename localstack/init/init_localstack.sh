#!/bin/bash
set -e

echo "⏳ Bootstrapping AWS services in LocalStack..."

# Create SQS queue
awslocal --endpoint-url=http://localstack:4566 sqs create-queue --queue-name notifications-queue

# Create DynamoDB Applications table
awslocal dynamodb create-table \
  --table-name Application\
  --attribute-definitions AttributeName=Application,AttributeType=S \
  --key-schema AttributeName=Application,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Create DynamoDB RequestLogs table
awslocal dynamodb create-table \
  --table-name RequestLogs \
  --attribute-definitions AttributeName=ApplicationID,AttributeType=S \
  --key-schema AttributeName=Application,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Insert application config into Applications table
awslocal dynamodb put-item \
  --table-name Application \
  --item '{
    "ApplicationID": {"S": "App2"},
    "App name": {"S": "CHA - Student Platform"},
    "Email": {"S": "no-reply@cha.com"},
    "Domain": {"S": "cha.com"},
    "SES-Domain-ARN": {"S": "arn:aws:ses:us-east-1:000000000000:identity/cha.com"},
    "SNS-Topic-ARN": {"S": "arn:aws:sns:us-east-1:000000000000:cha-app-push"}
  }'

echo "✅ LocalStack bootstrap complete."

