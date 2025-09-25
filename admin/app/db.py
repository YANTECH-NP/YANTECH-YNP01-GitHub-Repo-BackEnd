import boto3
from .config import settings

def get_dynamodb_resource():
    return boto3.resource(
        "dynamodb",
        region_name=settings.AWS_REGION
    )

def save_app_record(app_record: dict):
    table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
    table.put_item(Item=app_record)

def get_all_apps():
    table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
    response = table.scan()
    return response.get("Items", [])
