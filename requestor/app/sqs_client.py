"""SQS client operations for requestor service."""
import boto3
import json
from typing import Dict, Any
from .config import settings

def get_sqs_client() -> Any:
    """Get SQS client."""
    return boto3.client(
        "sqs",
        region_name=settings.AWS_REGION
    )

def send_message_to_queue(message: Dict[str, Any]) -> Dict[str, Any]:
    """Send message to SQS queue."""
    if not message or not isinstance(message, dict):
        raise ValueError("message must be a non-empty dictionary")
    
    try:
        sqs = get_sqs_client()
        response = sqs.send_message(
            QueueUrl=settings.SQS_QUEUE_URL,
            MessageBody=json.dumps(message)
        )
        return response
    except Exception as e:
        raise RuntimeError(f"Failed to send message to SQS: {str(e)}")
