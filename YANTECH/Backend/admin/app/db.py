"""Database operations for admin service."""
import boto3
from typing import Dict, List, Any
from .config import settings

def get_dynamodb_resource() -> Any:
    """Get DynamoDB resource client."""
    return boto3.resource(
        "dynamodb",
        region_name=settings.AWS_REGION
    )

def save_app_record(app_record: Dict[str, Any]) -> None:
    """Save application record to DynamoDB."""
    if not app_record or not isinstance(app_record, dict):
        raise ValueError("Invalid app_record: must be a non-empty dictionary")
    
    try:
        table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
        table.put_item(Item=app_record)
    except Exception as e:
        raise RuntimeError(f"Failed to save app record: {str(e)}")

def get_all_apps() -> List[Dict[str, Any]]:
    """Retrieve all application records from DynamoDB."""
    try:
        table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
        response = table.scan()
        return response.get("Items", [])
    except Exception as e:
        raise RuntimeError(f"Failed to retrieve apps: {str(e)}")

def update_app_record(app_id: str, app_record: Dict[str, Any]) -> None:
    """Update application record in DynamoDB."""
    if not app_id or not isinstance(app_id, str):
        raise ValueError("app_id must be a non-empty string")
    if not app_record or not isinstance(app_record, dict):
        raise ValueError("Invalid app_record: must be a non-empty dictionary")
    
    try:
        table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
        table.put_item(Item=app_record)
    except Exception as e:
        raise RuntimeError(f"Failed to update app record: {str(e)}")

def delete_app_record(app_id: str) -> None:
    """Delete application record from DynamoDB."""
    if not app_id or not isinstance(app_id, str):
        raise ValueError("app_id must be a non-empty string")
    
    try:
        table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
        table.delete_item(Key={"Application": app_id})
    except Exception as e:
        raise RuntimeError(f"Failed to delete app record: {str(e)}")
