✅ Python Flask + Boto3 Administrator Code
📁 Structure
bash
Copy
Edit
/administrator
├── admin.py
├── requirements.txt
├── Dockerfile
└── .env


#########################################################################
.env Example

AWS_REGION=us-east-1
LOCALSTACK_ENDPOINT=http://localhost:4566
APP_TABLE_NAME=AppTable

#######################################################################

Testing the Administrator Endpoint
Once running on port 5001, test with:

curl -X POST http://localhost:5001/app \
  -H "Content-Type: application/json" \
  -d '{
    "App name": "CHA - Student Platform",
    "ApplicationID": "App1",
    "Email": "no-reply@cha.com",
    "Domain": "cha.com"
  }'


Expected output

{
  "message": "Application registered successfully.",
  "ApplicationID": "App1",
  "SES-Domain-ARN": "arn:aws:ses:...",
  "SNS-Topic-ARN": "arn:aws:sns:..."
}
##########################################################################
