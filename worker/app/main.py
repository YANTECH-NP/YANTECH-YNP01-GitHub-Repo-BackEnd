import json
import time
from . import sqs_client, dynamodb_client, notifier, logger
from .health import health_checker


def _process_message(msg):
    """Process a single SQS message. Returns True if successful, False otherwise."""
    body = None
    try:
        body = json.loads(msg["Body"])
        app_id = body["Application"]
        logger.log(f"Processing message for application: {app_id}")
        cfg = dynamodb_client.get_application_config(app_id)
        if not cfg:
            raise Exception("App config not found")

        output = body.get("OutputType")
        if output == "EMAIL":
            notifier.send_email(cfg["SES-Domain-ARN"], body["EmailAddresses"], body["Subject"], body["Message"])
            logger.log(f"Email sent to {body['EmailAddresses']}")
        elif output in ["SMS", "PUSH"]:
            notifier.send_sns(cfg["SNS-Topic-ARN"], body["Message"])
            logger.log(f"Notification sent via {output} to {body['PhoneNumber'] or body['PushToken']}")
        else:
            raise Exception("Unsupported OutputType")

        dynamodb_client.log_request(app_id, body, "delivered")
        logger.log(f"Message processed successfully: {body}")
        health_checker.record_message_processed()
        return True
    except Exception as e:
        # Log the error
        dynamodb_client.log_request(body.get("Application", "unknown") if body else "unknown", body, "failed", str(e))
        logger.log(f"Error processing message: {e}")
        health_checker.record_error()
        # Don't delete the message - let it retry or go to DLQ
        logger.log(f"Message will be retried or sent to DLQ after max attempts")
        return False


def run_worker():
    logger.log("Worker started polling SQS...")
    backoff_delay = 1  # Initial backoff delay in seconds
    max_backoff = 60   # Maximum backoff delay in seconds
    
    while True:
        try:
            messages = sqs_client.poll_messages()
            # Reset backoff delay after successful API call
            backoff_delay = 1
        except Exception as e:
            logger.log(f"Error polling SQS: {e}")
            logger.log(f"Backing off for {backoff_delay} seconds")
            health_checker.record_error()
            time.sleep(backoff_delay)
            # Double the backoff delay for next attempt, up to maximum
            backoff_delay = min(backoff_delay * 2, max_backoff)
            continue
        
        if not messages:
            time.sleep(1)  # Short sleep when no messages
            continue
            
        for msg in messages:
            if _process_message(msg):
                # Only delete message if processing was successful
                sqs_client.delete_message(msg["ReceiptHandle"])
                logger.log("Message deleted from SQS")

if __name__ == "__main__":
    run_worker()

