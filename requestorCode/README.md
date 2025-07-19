📦 Project Structure

/notification_api
├── app.py
├── requirements.txt
└── Dockerfile

🔁 Interval Conversion Rule
For payloads like:

"Interval": {
  "Type": "Weeks",
  "Values": [1, 2, 4]
}


🚀 ECS Environment Variables (example)
| Variable        | Description                                 |
| --------------- | ------------------------------------------- |
| `SQS_QUEUE_URL` | Full SQS queue URL                          |
| `AWS_REGION`    | (Optional) AWS region (default `us-east-1`) |

🔍 Example Payload
{
  "Application": "App1",
  "Recipient": "user@example.com",
  "Subject": "Welcome!",
  "Message": "Thanks for signing up.",
  "OutputType": "Email",
  "Date": "2025-07-10",
  "Time": "14:00",
  "Interval": {
    "Type": "Weeks",
    "Values": [1, 2]
  }
}
