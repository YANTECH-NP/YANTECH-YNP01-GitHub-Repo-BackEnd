import boto3
import os
import json
import time
from dotenv import load_dotenv

load_dotenv()

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
APP_TABLE = os.getenv("APP_TABLE_NAME", "AppTable")
FROM_ADDRESS = os.getenv("SES_FROM_ADDRESS", "no-reply@yantech.com")
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", 5))

sqs = boto3.client('sqs', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
ses = boto3.client('ses', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
sns = boto3.client('sns', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
dynamodb = boto3.resource('dynamodb', region_name=AWS_REGION, endpoint_url="http://localstack:4566")
table = dynamodb.Table(APP_TABLE)

def process_message(message):
    body = json.loads(message['Body'])
    app_id = body['Application']
    response = table.get_item(Key={"ApplicationID": app_id})
    item = response.get("Item", {})

    output_type = body['OutputType']
    recipient = body['Recipient']
    subject = body['Subject']
    message_body = body['Message']

    if output_type == "Email":
        ses.send_email(
            Source=FROM_ADDRESS,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': message_body}}
            }
        )
    elif output_type == "SMS":
        sns.publish(PhoneNumber=recipient, Message=message_body)
    elif output_type == "Push":
        sns.publish(TopicArn=item.get("SNS-Topic-ARN"), Message=message_body)

def poll_queue():
    print("Worker started. Polling for messages...")
    while True:
        try:
            messages = sqs.receive_message(QueueUrl=QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=10)
            for msg in messages.get("Messages", []):
                process_message(msg)
                sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
        except Exception as e:
            print("Error polling queue:", str(e))
        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    poll_queue()
