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

Overview
The Administrator Service is a core component of the Yantech Notification Platform. It is responsible for:

Registering new applications

Creating verified SES domains for email delivery

Creating SNS topics for SMS and push notifications

Storing app configurations in a DynamoDB table for downstream use by the requestor and worker services

This service is exposed via a single API endpoint:
POST /app


⚙️ Features
✅ Create SES Domain Identities
✅ Create SNS Topics for each application
✅ Persist configuration in DynamoDB (AppTable)
✅ Expose a RESTful API via Flask
✅ Designed for deployment on AWS ECS or Lambda

📦 Tech Stack
Python 3.11

Flask (REST API)

Boto3 (AWS SDK)

Gunicorn (Production WSGI server)

DynamoDB, SNS, SES (AWS Services)

🛠️ Installation
🔁 Clone the Repo
bash
Copy
Edit
git clone https://github.com/YANTECH/notification-platform.git
cd notification-platform/administrator
📦 Install Dependencies
Create a virtual environment (optional but recommended):

bash
Copy
Edit
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
🚀 Running Locally (for testing)
✅ Add a .env file
env
Copy
Edit
AWS_REGION=us-east-1
APP_TABLE_NAME=AppTable
You do not need to set endpoint_url unless using LocalStack.

▶️ Run with Flask (local dev)
bash
Copy
Edit
python admin.py
Flask will run at: http://localhost:5001

🐳 Running in Production with Docker
📁 Dockerfile is already provided
Build and run:

bash
Copy
Edit
docker build -t yantech-admin-api .
docker run -p 5001:5001 --env-file .env yantech-admin-api
🖥️ Production Command (runs via Gunicorn)
Dockerfile
Copy
Edit
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5001", "admin:app"]
📬 API Usage
POST /app
Registers a new application, configures SES + SNS, and stores info in DynamoDB.

✅ Request Body
json
Copy
Edit
{
  "App name": "CHA - Student Platform",
  "ApplicationID": "App1",
  "Email": "no-reply@cha.com",
  "Domain": "cha.com"
}
✅ Response
json
Copy
Edit
{
  "message": "Application registered successfully.",
  "ApplicationID": "App1",
  "SES-Domain-ARN": "arn:aws:ses:...",
  "SNS-Topic-ARN": "arn:aws:sns:..."
}

