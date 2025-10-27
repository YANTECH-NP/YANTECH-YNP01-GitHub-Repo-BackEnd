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
    startup_start = time.time()
    logging.info("🚀 Starting requestor service initialization...")
    
    # REMOVED: 5-second blocking sleep that was causing latency
    # time.sleep(5)  # ← This was the performance killer!
    
    # Test SQS connectivity with timing
    sqs_start = time.time()
    try:
        sqs = boto3.client('sqs', region_name=os.getenv('AWS_DEFAULT_REGION', 'us-east-1'))
        queue_url = os.getenv('SQS_QUEUE_URL')
        if queue_url:
            sqs.get_queue_attributes(QueueUrl=queue_url, AttributeNames=['QueueArn'])
            sqs_time = time.time() - sqs_start
            logging.info(f"✅ SQS connectivity verified in {sqs_time:.3f}s")
        app_state.ready = True
    except Exception as e:
        sqs_time = time.time() - sqs_start
        logging.error(f"❌ SQS connectivity failed in {sqs_time:.3f}s: {e}")
        app_state.ready = False
    
    total_startup = time.time() - startup_start
    logging.info(f"🎯 Startup completed in {total_startup:.3f}s")

@app.get("/health")
def health_check() -> Dict[str, Any]:
    """Health check endpoint."""
    health_start = time.time()
    
    if not app_state.ready:
        health_time = time.time() - health_start
        logging.warning(f"⚠️ Health check failed in {health_time:.3f}s - service not ready")
        raise HTTPException(status_code=503, detail="Service not ready")
    
    health_time = time.time() - health_start
    logging.info(f"✅ Health check passed in {health_time:.3f}s")
    return {"status": "ok", "service": "requestor", "ready": True}

@app.post("/notifications")
def notify(req: NotificationRequest) -> Dict[str, Any]:
    """Send notification request to SQS queue. JWT validation handled by API Gateway."""
    request_start = time.time()
    logging.info(f"📨 Processing notification request...")
    
    try:
        # Time Pydantic validation
        validation_start = time.time()
        request_dict = req.dict()
        validation_time = time.time() - validation_start
        logging.info(f"✅ Pydantic validation completed in {validation_time:.3f}s")
        
        # Time SQS operation
        sqs_start = time.time()
        response = send_message_to_queue(request_dict)
        sqs_time = time.time() - sqs_start
        logging.info(f"✅ SQS message sent in {sqs_time:.3f}s")
        
        total_time = time.time() - request_start
        logging.info(f"🎯 Total request processed in {total_time:.3f}s - MessageId: {response.get('MessageId')}")
        
        return {
            "message_id": response.get("MessageId"),
            "status": "queued",
            "processing_time_ms": round(total_time * 1000, 2)
        }
    except Exception as e:
        error_time = time.time() - request_start
        logging.error(f"❌ Request failed in {error_time:.3f}s: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
