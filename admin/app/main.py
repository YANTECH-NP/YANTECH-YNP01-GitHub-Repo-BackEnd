from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from fastapi.middleware.cors import CORSMiddleware
from .aws import setup_app_services
from .db import save_app_record, get_all_apps

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
        config = setup_app_services(app_req)
        save_app_record(config)
        return {"status": "created", "application": config}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/applications")
def list_registered_apps():
    try:
        return get_all_apps()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/suspend")
def suspend_application(suspend_req: dict):
    """Suspend an application"""
    try:
        application_id = suspend_req.get("Application")
        reason = suspend_req.get("reason", "No reason provided")
        
        if not application_id:
            raise HTTPException(status_code=400, detail="Application ID required")
        
        # Here you would implement the suspension logic
        # For now, just return success
        return {
            "status": "suspended",
            "application": application_id,
            "reason": reason
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

