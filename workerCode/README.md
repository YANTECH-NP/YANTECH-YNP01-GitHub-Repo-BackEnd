✅ Responsibilities of the Worker:
Poll SQS for messages that the API enqueues.

Parse the message and extract the notification details.

Dispatch the notification to the correct channel:

Email → SES

SMS or Push → SNS

Log success or failure (for monitoring/debugging).

🧱 Assumptions:
Worker will be run in ECS Fargate with appropriate IAM permissions.

SQS Queue, SES, and SNS are already configured.

Push notifications will be treated as SNS messages with an ApplicationArn (can be extended per requirement).

Messages are already validated at the API level.

📁 Project Layout:
/worker
├── worker.py
├── requirements.txt
└── Dockerfile

🔐 Required Environment Variables

| Variable           | Description                           |
| ------------------ | ------------------------------------- |
| `SQS_QUEUE_URL`    | URL of the SQS queue                  |
| `AWS_REGION`       | AWS Region (default is `us-east-1`)   |
| `SES_FROM_ADDRESS` | Verified "From" email address for SES |


📘 IAM Permissions (ECS Task Role)

{
  "Effect": "Allow",
  "Action": [
    "sqs:ReceiveMessage",
    "sqs:DeleteMessage",
    "sqs:GetQueueAttributes",
    "ses:SendEmail",
    "sns:Publish"
  ],
  "Resource": "*"
}

