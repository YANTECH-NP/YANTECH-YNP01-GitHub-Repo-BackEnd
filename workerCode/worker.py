import boto3
import json
import os
import time
from botocore.exceptions import ClientError

# SQS configuration
QUEUE_URL = os.getenv("SQS_QUEUE_URL")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

# AWS clients
sqs = boto3.client('sqs', region_name=AWS_REGION)
sns = boto3.client('sns', region_name=AWS_REGION)
ses = boto3.client('ses', region_name=AWS_REGION)


# Polling interval (in seconds)
POLL_INTERVAL = 5

def process_message(message_body):
    """
    Handles logic to route notifications to Email (SES) or SMS/Push (SNS).
    """
    try:
        payload = json.loads(message_body)

        output_type = payload.get("OutputType")
        recipient = payload.get("Recipient")
        subject = payload.get("Subject")
        message = payload.get("Message")

        if output_type.lower() == "email":
            # Send via SES
            response = ses.send_email(
                Source=os.getenv("SES_FROM_ADDRESS"),
                Destination={'ToAddresses': [recipient]},
                Message={
                    'Subject': {'Data': subject},
                    'Body': {
                        'Text': {'Data': message}
                    }
                }
            )
            print(f"Email sent to {recipient}, MessageId: {response['MessageId']}")

        elif output_type.lower() in ["sms", "push"]:
            # Publish via SNS
            response = sns.publish(
                PhoneNumber=recipient if output_type.lower() == "sms" else None,
                Message=message,
                Subject=subject if output_type.lower() == "push" else None
                # For push, could also target a TopicArn or ApplicationArn
            )
            print(f"{output_type.upper()} sent to {recipient}, MessageId: {response['MessageId']}")
        else:
            print(f"Unsupported OutputType: {output_type}")
    
    except ClientError as e:
        print(f"AWS error: {e.response['Error']['Message']}")
    except Exception as e:
        print(f"General error while processing message: {str(e)}")


def poll_queue():
    """
    Continuously poll the SQS queue and process new messages.
    """
    print("Worker started. Polling for messages...")
    while True:
        try:
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=10  # Long polling
            )

            messages = response.get('Messages', [])

            for message in messages:
                print("Received message:", message['MessageId'])

                # Process and route the notification
                process_message(message['Body'])

                # Delete message after successful processing
                sqs.delete_message(
                    QueueUrl=QUEUE_URL,
                    ReceiptHandle=message['ReceiptHandle']
                )
                print(f"Deleted message {message['MessageId']}")

        except Exception as e:
            print(f"Error polling queue: {str(e)}")

        # Wait before polling again
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    poll_queue()
