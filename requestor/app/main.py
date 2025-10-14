"""Main FastAPI application for requestor service."""
from fastapi import FastAPI, HTTPException
from typing import Dict, Any
from .models import NotificationRequest
from .sqs_client import send_message_to_queue
import logging
import boto3
import os
import time

app = FastAPI()

class AppState:
    """Application state container."""
    def __init__(self) -> None:
        self.ready = False

app_state = AppState()

@app.on_event("startup")
async def startup_event() -> None:
    """Initialize application on startup."""
    # Small delay to ensure full initialization
    time.sleep(5)
    
    # Test SQS connectivity
    try:
        sqs = boto3.client('sqs', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))
        queue_url = os.getenv('SQS_QUEUE_URL')
        if queue_url:
            sqs.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['QueueArn'])
            logging.info("SQS connectivity verified")
        app_state.ready = True
    except Exception as e:
        logging.error(f"SQS connectivity failed: {e}")
        app_state.ready = False

@app.get("/health")
def health_check() -> Dict[str, Any]:
    """Health check endpoint."""
    if not app_state.ready:
        raise HTTPException(status_code=503, detail="Service not ready")
    return {"status": "ok", "service": "requestor", "ready": True}

@app.post("/notifications")
def notify(req: NotificationRequest) -> Dict[str, Any]:
    """Send notification request to SQS queue. JWT validation handled by API Gateway."""
    try:
        response = send_message_to_queue(req.dict())
        logging.info(f"NotificationRequest queued: {response.get('MessageId')}")
        
        return {
            "message_id": response.get("MessageId"),
            "status": "queued"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
