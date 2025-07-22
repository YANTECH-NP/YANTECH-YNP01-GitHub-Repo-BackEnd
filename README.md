# 📦 YANTECH Notification Platform (LocalStack Dev Environment)

This project runs the complete Yantech notification platform locally using Docker and LocalStack.

## Project Structure

```bash
yantech_localstack_services/
├── admin/
│   ├── admin.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
├── requestor/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
├── worker/
│   ├── worker.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
├── docker-compose.yml
├── README.md

```

## 📁 Services

| Service     | Port  | Description                              |
|-------------|-------|------------------------------------------|
| `admin`     | 5001  | Admin API to register apps + setup SES/SNS |
| `requestor` | 5000  | Receives /notify POSTs, pushes to SQS     |
| `worker`    | —     | Polls SQS, looks up app, sends message    |
| `localstack`| 4566  | Mocks AWS (SQS, SES, SNS, DynamoDB)       |

---

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/YANTECH-NP/YANTECH-YNP01-GitHub-Repo-BackEnd.git
cd yantech_localstack_services
```

### 2. Start the stack

```bash
docker-compose up --build
```

LocalStack will automatically initialize resources via `/localstack/init/init.sh`.

---

## 🧪 Testing the API

### 1. Register an Application

```bash
curl -X POST http://localhost:5001/app   -H "Content-Type: application/json"   -d '{
    "App name": "CHA",
    "ApplicationID": "App1",
    "Email": "no-reply@cha.com",
    "Domain": "cha.com"
  }'
```

### 2. Send a Notification

```bash
curl -X POST http://localhost:5000/notify   -H "Content-Type: application/json"   -d '{
    "Application": "App1",
    "Recipient": "test@cha.com",
    "Subject": "Test",
    "Message": "Test message body",
    "OutputType": "Email",
    "Date": "2025-07-10",
    "Time": "12:00",
    "Interval": {
      "Type": "Days",
      "Values": [1]
    }
  }'
```

---

## ✅ LocalStack Initialization Script

Create `/localstack/init/init.sh` with:

```bash
#!/bin/bash
awslocal sqs create-queue --queue-name notification-queue
awslocal dynamodb create-table \
  --table-name AppTable \
  --attribute-definitions AttributeName=ApplicationID,AttributeType=S \
  --key-schema AttributeName=ApplicationID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

Make sure it's executable:
```bash
chmod +x localstack/init/init.sh
```

---

## 🧼 Clean Up

```bash
docker-compose down -v
```

---

Need help with ECS deployment or GitHub Actions CI/CD? Open an issue or contact the team.
