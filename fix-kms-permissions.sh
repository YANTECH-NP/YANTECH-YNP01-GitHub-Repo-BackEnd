#!/bin/bash

# Quick fix for KMS permissions issue
set -e

echo "🔧 Fixing KMS Permissions for SQS Encryption"
echo "============================================="

# Get the KMS key ARN
KMS_KEY_ARN=$(aws kms list-keys --query 'Keys[0].KeyId' --output text)
FULL_KMS_ARN="arn:aws:kms:us-east-1:588082972397:key/$KMS_KEY_ARN"

echo "KMS Key ARN: $FULL_KMS_ARN"

# Update the client ECS policy to include KMS permissions
echo "Updating client ECS IAM policy..."

aws iam create-policy-version \
    --policy-arn arn:aws:iam::588082972397:policy/YANTECH-AWS-Sec-IAM-Policy-Client-ECS-dev \
    --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"logs:CreateLogGroup\",
                    \"logs:CreateLogStream\",
                    \"logs:PutLogEvents\"
                ],
                \"Resource\": \"arn:aws:logs:*:*:*\"
            },
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"sqs:SendMessage\",
                    \"sqs:GetQueueAttributes\"
                ],
                \"Resource\": \"arn:aws:sqs:us-east-1:588082972397:yantech-notification-queue-dev\"
            },
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"kms:Decrypt\",
                    \"kms:GenerateDataKey\"
                ],
                \"Resource\": \"$FULL_KMS_ARN\"
            }
        ]
    }" \
    --set-as-default

echo "✅ KMS permissions updated successfully!"
echo ""
echo "🔄 Restarting ECS service to pick up new permissions..."

aws ecs update-service \
    --cluster YANTECH-cluster-dev \
    --service YANTECH-client-service-dev \
    --force-new-deployment

echo "✅ ECS service restart initiated"
echo ""
echo "⏳ Wait 2-3 minutes for the service to restart, then test again"
echo ""
echo "🧪 Test command:"
echo "./test-lambda-auth.sh"