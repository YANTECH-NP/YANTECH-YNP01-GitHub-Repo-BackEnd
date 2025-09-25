import boto3
from datetime import datetime
from . import config

dynamodb = boto3.resource(
    "dynamodb",
    region_name=config.AWS_REGION
)

def log_request(app_id, message, status, error=""):
    table = dynamodb.Table(config.REQUEST_LOG_TABLE)
    table.put_item(Item={
        "Application": app_id,
        "Timestamp": datetime.utcnow().isoformat(),
        "Status": status,
        "Payload": message,
        "Error": error
    })

