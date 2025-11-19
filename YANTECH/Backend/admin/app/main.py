from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from fastapi.middleware.cors import CORSMiddleware
import secrets
import string
from datetime import datetime, timezone
# Removed AWS services import - admin only handles app registration
from .db import save_app_record, get_all_apps, update_app_record, delete_app_record

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AppRequest(BaseModel):
    App_name: str
    Application: str
    Email: EmailStr
    Domain: str

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "admin"}



@app.post("/applications")
def register_application(app_req: AppRequest):
    try:
        # Generate API key for the new application
        import secrets
        import string
        alphabet = string.ascii_letters + string.digits + "_-"
        api_key = ''.join(secrets.choice(alphabet) for _ in range(32))
        
        # Create application record
        app_record = {
            "Application": app_req.Application,
            "App_name": app_req.App_name,
            "Email": app_req.Email,
            "Domain": app_req.Domain,
            "api_key": api_key,
            "role": "client",
            "Status": "ACTIVE"
        }
        
        save_app_record(app_record)
        
        # Return without exposing the API key
        return {
            "status": "created", 
            "application": app_req.Application,
            "message": "Application registered successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/applications")
def list_registered_apps():
    try:
        return get_all_apps()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/applications/{app_id}")
def update_application(app_id: str, app_req: AppRequest):
    """Update an existing application"""
    try:
        # Create updated application record
        app_record = {
            "Application": app_id,
            "App_name": app_req.App_name,
            "Email": app_req.Email,
            "Domain": app_req.Domain,
            "Status": "ACTIVE"
        }
        
        update_app_record(app_id, app_record)
        
        return {
            "status": "updated", 
            "application": app_id,
            "message": "Application updated successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/applications/{app_id}")
def delete_application(app_id: str):
    """Delete an application"""
    try:
        delete_app_record(app_id)
        
        return {
            "status": "deleted",
            "application": app_id,
            "message": "Application deleted successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# API key management endpoints removed - not implemented yet



