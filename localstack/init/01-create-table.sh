#!/bin/bash
echo "⏳ Creating DynamoDB table AppTable..."

awslocal dynamodb create-table   --table-name AppTable   --attribute-definitions AttributeName=ApplicationID,AttributeType=S   --key-schema AttributeName=ApplicationID,KeyType=HASH   --billing-mode PAYPER_REQUEST   --region us-east-1