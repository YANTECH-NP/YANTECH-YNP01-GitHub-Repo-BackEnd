# Simple health check for worker service
import json
import time
from datetime import datetime

class HealthChecker:
    def __init__(self):
        self.start_time = datetime.utcnow()
        self.last_message_processed = None
        self.messages_processed = 0
        self.errors_count = 0
        self.dlq_messages_count = 0
    
    def record_message_processed(self):
        self.last_message_processed = datetime.utcnow()
        self.messages_processed += 1
    
    def record_error(self):
        self.errors_count += 1
    
    def record_dlq_message(self):
        self.dlq_messages_count += 1
    
    def get_status(self):
        uptime = (datetime.utcnow() - self.start_time).total_seconds()
        return {
            "status": "healthy",
            "uptime_seconds": uptime,
            "messages_processed": self.messages_processed,
            "errors_count": self.errors_count,
            "dlq_messages_count": self.dlq_messages_count,
            "last_message_processed": self.last_message_processed.isoformat() if self.last_message_processed else None,
            "timestamp": datetime.utcnow().isoformat()
        }

# Global health checker instance
health_checker = HealthChecker()