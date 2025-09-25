import json
import boto3
from . import config

session = boto3.session.Session(    
    region_name=config.AWS_REGION
)

sqs = session.client("sqs")

def poll_messages(max_messages=5, wait_time=10):
    response = sqs.receive_message(
        QueueUrl=config.SQS_QUEUE_URL,
        MaxNumberOfMessages=max_messages,
        WaitTimeSeconds=wait_time
    )
    return response.get("Messages", [])

def delete_message(receipt_handle):
    sqs.delete_message(
        QueueUrl=config.SQS_QUEUE_URL,
        ReceiptHandle=receipt_handle
    )

