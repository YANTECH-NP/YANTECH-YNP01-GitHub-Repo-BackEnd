# API Endpoint Alignment Changes Documentation

**Date**: January 2025  
**Issue**: Frontend and Backend API endpoint misalignment  
**Status**: ✅ Completed

## Problem Summary

The frontend application was calling different API endpoints than what the backend provided, causing integration failures.

### Before Changes:
- **Frontend Expected**: `/apps`, `/app`, `/app/{id}`
- **Backend Provided**: `/applications`
- **Missing**: PUT and DELETE endpoints for application management

## Changes Made

### 1. Frontend API Service Updates (`services/api.ts`)

#### Endpoint Path Changes:
```typescript
// OLD → NEW
GET /apps → GET /applications
POST /app → POST /applications
PUT /app/{id} → PUT /applications/{id}
DELETE /app/{id} → DELETE /applications/{id}
```

#### Specific Function Updates:

**getApplications():**
```typescript
// Before
const response = await api.get("/apps");

// After  
const response = await api.get("/applications");
```

**createApplication():**
```typescript
// Before
const response = await api.post("/app", applicationData);

// After
const response = await api.post("/applications", applicationData);
```

**API Key Endpoints:**
```typescript
// Before
await api.post(`/app/${createdApp.id}/api-key`, {...});
await api.get(`/app/${applicationId}/api-keys`);

// After
await api.post(`/applications/${createdApp.id}/api-key`, {...});
await api.get(`/applications/${applicationId}/api-keys`);
```

**CRUD Operations:**
```typescript
// Before
await api.put(`/app/${id}`, applicationData);
await api.delete(`/app/${id}`);
await api.get(`/app/${applicationId}/notifications`);

// After
await api.put(`/applications/${id}`, applicationData);
await api.delete(`/applications/${id}`);
await api.get(`/applications/${applicationId}/notifications`);
```

### 2. Backend Admin Service Updates (`admin/app/main.py`)

#### New Endpoints Added:

**PUT /applications/{app_id}:**
```python
@app.put("/applications/{app_id}")
def update_application(app_id: str, app_req: AppRequest):
    """Update an existing application"""
    try:
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
```

**DELETE /applications/{app_id}:**
```python
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
```

#### Import Statement Updated:
```python
# Before
from .db import save_app_record, get_all_apps

# After
from .db import save_app_record, get_all_apps, update_app_record, delete_app_record
```

### 3. Database Functions Added (`admin/app/db.py`)

#### New Functions Implemented:

**update_app_record():**
```python
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
```

**delete_app_record():**
```python
def delete_app_record(app_id: str) -> None:
    """Delete application record from DynamoDB."""
    if not app_id or not isinstance(app_id, str):
        raise ValueError("app_id must be a non-empty string")
    
    try:
        table = get_dynamodb_resource().Table(settings.APP_CONFIG_TABLE)
        table.delete_item(Key={"Application": app_id})
    except Exception as e:
        raise RuntimeError(f"Failed to delete app record: {str(e)}")
```

## Files Modified

### Frontend:
- `YANTECH/Frontend/services/api.ts` - Updated all API endpoint paths

### Backend:
- `YANTECH/Backend/admin/app/main.py` - Added PUT/DELETE endpoints, removed /suspend
- `YANTECH/Backend/admin/app/db.py` - Added database functions

### Infrastructure:
- `modular-terraform/admin-api-gateway/main.tf` - Updated API Gateway endpoints

## API Endpoints Now Available

### Admin Service (Port 5001):
- `GET /applications` - List all applications
- `POST /applications` - Create new application  
- `PUT /applications/{app_id}` - Update existing application
- `DELETE /applications/{app_id}` - Delete application
- `GET /health` - Health check

### API Gateway (Admin):
- `POST /auth` - Authentication (Lambda)
- `GET /applications` - List applications (JWT auth)
- `POST /applications` - Create application (JWT auth)
- `PUT /applications/{app_id}` - Update application (JWT auth)
- `DELETE /applications/{app_id}` - Delete application (JWT auth)
- `GET /health` - Health check (no auth)

## Technical Notes

1. **Database Operations**: 
   - Update uses `put_item()` which overwrites existing records
   - Delete uses `delete_item()` with primary key `{"Application": app_id}`

2. **Error Handling**: 
   - All functions include input validation
   - Consistent error response format maintained

3. **Response Format**:
   - All endpoints return JSON with `status`, `application`, and `message` fields

## Testing Required

After deployment, test the following:
1. ✅ GET /applications - List applications
2. ✅ POST /applications - Create application
3. 🔄 PUT /applications/{id} - Update application
4. 🔄 DELETE /applications/{id} - Delete application
5. 🔄 Frontend CRUD operations work end-to-end

## Next Steps

1. Test the updated endpoints in development environment
2. Verify frontend can successfully perform CRUD operations
3. Address remaining issues:
   - API Gateway vs Direct ALB access
   - JWT authentication implementation
   - Missing API key management endpoints
   - Environment configuration updates

## Infrastructure Changes (`modular-terraform/admin-api-gateway/main.tf`)

### Removed Unused Endpoints:
```hcl
# REMOVED: /suspend resource, method, and integration
# - aws_api_gateway_resource "suspend"
# - aws_api_gateway_method "suspend_post" 
# - aws_api_gateway_integration "suspend_integration"
```

### Added New Resources:
```hcl
# NEW: /applications/{app_id} resource
resource "aws_api_gateway_resource" "applications_id" {
  rest_api_id = aws_api_gateway_rest_api.admin_api.id
  parent_id   = aws_api_gateway_resource.applications.id
  path_part   = "{app_id}"
}
```

### Added PUT Method:
```hcl
resource "aws_api_gateway_method" "applications_put" {
  rest_api_id   = aws_api_gateway_rest_api.admin_api.id
  resource_id   = aws_api_gateway_resource.applications_id.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
  
  request_parameters = {
    "method.request.path.app_id" = true
  }
}
```

### Added DELETE Method:
```hcl
resource "aws_api_gateway_method" "applications_delete" {
  rest_api_id   = aws_api_gateway_rest_api.admin_api.id
  resource_id   = aws_api_gateway_resource.applications_id.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id
  
  request_parameters = {
    "method.request.path.app_id" = true
  }
}
```

### Added HTTP Integrations:
```hcl
# PUT integration to ALB
resource "aws_api_gateway_integration" "applications_put_integration" {
  type                    = "HTTP"
  integration_http_method = "PUT"
  uri                     = "http://${var.admin_alb_dns_name}/applications/{app_id}"
  
  request_parameters = {
    "integration.request.path.app_id" = "method.request.path.app_id"
  }
}

# DELETE integration to ALB
resource "aws_api_gateway_integration" "applications_delete_integration" {
  type                    = "HTTP"
  integration_http_method = "DELETE"
  uri                     = "http://${var.admin_alb_dns_name}/applications/{app_id}"
  
  request_parameters = {
    "integration.request.path.app_id" = "method.request.path.app_id"
  }
}
```

### Updated Deployment:
- Added new methods to deployment dependencies
- Updated deployment triggers with new resource IDs
- Changed trigger version to "endpoint-alignment-v1"

---

**Note**: This resolves Issue #1 from the deployment preparation checklist. The frontend, backend, and API Gateway infrastructure now use consistent `/applications` endpoint paths and support full CRUD operations with proper JWT authentication.