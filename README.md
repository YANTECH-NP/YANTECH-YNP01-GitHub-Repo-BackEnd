# 🚀 Notifications Platform (Admin, Requestor, Worker)

This project includes three microservices:

- **Admin**: Manages SQS/SNS/SES/DynamoDB resources.
- **Requestor**: Sends notification requests to SQS.
- **Worker**: Polls SQS and delivers messages using SES (email), SNS (SMS, push), and logs status in DynamoDB.

All services are containerized and designed to run in **AWS ECS (Fargate)** with IAM via **OIDC authentication** — no access keys required.

---

## 🛠 Project Structure

```bash
.
├── docker-compose.yml
├── admin/
│   ├── Dockerfile
│   └── .env
├── requestor/
│   ├── Dockerfile
│   └── .env
├── worker/
│   ├── Dockerfile
│   └── .env

```

## ☁️ Deployment to AWS ECS (Fargate)

### 1. 🔧 Prerequisites

- AWS CLI installed & configured

- Docker installed

- IAM role with OIDC for ECR + ECS deploy

- ECR repositories created: admin, requestor, worker

- ECS cluster created

### 2. 🚀 Create ECS Services

Use either the AWS Console or IaC (e.g., Terraform) to create 3 ECS services using:

- Fargate launch type

- Same ECS cluster

- ECR image URLs above

- Expose ports 8000 (requestor) and 8001 (admin)

- Assign IAM roles with permissions to use:

  -> SQS

  -> SES

  -> SNS

  -> DynamoDB

## 🔒 Environment Variables

Each service uses a .env file:

```bash
# admin/.env
AWS_REGION=us-east-1
TABLE_NAME=Applications
SNS_TOPIC_ARN=...
SES_IDENTITY=...

# requestor/.env
AWS_REGION=us-east-1
QUEUE_URL=...

# worker/.env
AWS_REGION=us-east-1
QUEUE_URL=...
TABLE_NAME=Applications
```