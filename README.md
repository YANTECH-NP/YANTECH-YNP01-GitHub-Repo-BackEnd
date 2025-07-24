# 🛠️ YANTECH Notification Platform: LocalStack Setup on Ubuntu 24.04 LTS

This guide walks you through setting up LocalStack and running the `admin.py`, `app.py`, and `worker.py` services on Ubuntu 24.04 using Docker Compose.

---

## ✅ Prerequisites

```bash
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io

# Install Docker Compose plugin
sudo apt install -y docker-compose-plugin

# Install Python 3 and pip
sudo apt install -y python3 python3-pip python3-venv

# Allow Docker usage without sudo
sudo usermod -aG docker $USER
newgrp docker
```

---

## 📁 Project Structure

```
.
├── docker-compose.yml
├── admin/
│   ├── admin.py
│   ├── requirements.txt
│   └── .env.example
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── .env.example
├── worker/
│   ├── worker.py
│   ├── requirements.txt
│   └── .env.example
└── localstack/
    └── init/
        └── 01-create-table.sh
```

---

## ⚙️ Configuration

Each service (`admin`, `app`, `worker`) should use the `.env.example` for environment variables. Example:

```env
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_REGION=us-east-1
LOCALSTACK_ENDPOINT=http://localstack:4566
SQS_QUEUE_URL=http://localstack:4566/000000000000/notification-queue
APP_TABLE_NAME=AppTable
```

---

## 🚀 Run the Stack

```bash
# Make sure init script is executable
chmod +x localstack/init/01-create-table.sh

# Build and start all services
docker compose up --build -d
```

Check LocalStack health:

```bash
curl http://localhost:4566/_localstack/health
```

You should see `"dynamodb": "available"`, `"sqs": "available"`, etc.

---

## 🧪 Test Admin API

```bash
curl -X POST http://localhost:5001/app   -H "Content-Type: application/json"   -d '{
    "App name": "CHA",
    "ApplicationID": "App1",
    "Email": "no-reply@cha.com",
    "Domain": "cha.com"
  }'
```

---

## 🐛 Troubleshooting

- **LocalStack not starting?** Check Docker logs: `docker compose logs localstack`
- **DNS issues?** Make sure services are in the same Docker network.
- **Credential errors?** Use dummy credentials in `.env.example` files.

---

## ✅ Cleanup

```bash
docker compose down -v
docker system prune -af
```

---

© YANTECH Notification Platform







['Application', 'Recipient', 'Subject', 'Message', 'OutputType', 'Date', 'Time', 'Interval']

curl -X POST http://localhost:5001/notify   -H "Content-Type: application/json"   -d '{
    "Application": "App1",
    "Recipient": "no-reply@cha.com",
    "Subject": "test message",
    "Message": "this is a test",
    "OutputType": "Email",
    "Date": "2025-07-10",
    "Time": "12:00",
    "Interval": [1]
  }'



  curl -X POST http://localhost:5001/app   -H "Content-Type: application/json"   -d '{
    "App name": "CHA",
    "ApplicationID": "App1",
    "Email": "no-reply@cha.com",
    "Domain": "cha.com"
  }'
