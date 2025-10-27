# Test Scripts Update Summary

## Changes Made for REST API Gateway v1 + WAF Architecture

### 1. **production-test.sh** ✅ UPDATED
- Fixed API URLs to match new REST API Gateway domains
- Changed `/notify` endpoints to `/notifications`
- Added WAF rate limiting delays (2-second intervals)
- Updated domain patterns for dev environment

### 2. **curl-tests.sh** ✅ UPDATED
- Updated local notification endpoints from `/notify` to `/notifications`
- Maintained localhost testing for Docker Compose

### 3. **test-all-services.js** ✅ UPDATED
- Fixed notification endpoint path
- Added clarifying comments about local vs production testing

### 4. **deploy-and-test.sh** ✅ UPDATED
- Added WAF rate limiting delays between API calls
- Updated notification endpoint paths

### 5. **pre-deployment-check.sh** ✅ UPDATED
- Changed terraform directory from `monolithic-terraform` to `modular-terraform`
- Updated infrastructure validation paths

### 6. **test-waf-rate-limits.sh** ✅ NEW SCRIPT
- **NEW**: Comprehensive WAF testing script
- Tests client API rate limiting (2000/min)
- Tests admin API rate limiting (1000/min)
- Tests AWS managed rules for malicious patterns
- Provides detailed monitoring commands

## Key Architecture Changes Addressed

### API Gateway Migration
- **Before**: HTTP API Gateway v2 (no WAF support)
- **After**: REST API Gateway v1 with full WAF protection

### Security Enhancements
- **WAF Rate Limiting**: Client API (2000/min), Admin API (1000/min)
- **AWS Managed Rules**: OWASP protection, known bad inputs
- **NLB Integration**: Private connectivity via VPC Links

### Endpoint Changes
- **Notification endpoint**: `/notify` → `/notifications`
- **Domain structure**: Maintained existing patterns
- **Authentication**: No changes to JWT/API key flow

## Testing Recommendations

### 1. Local Development
```bash
# Test Docker Compose setup
./BACKEND-DEPLOYMENT-GUIDE/curl-tests.sh
node ./BACKEND-DEPLOYMENT-GUIDE/test-all-services.js
```

### 2. Production Testing
```bash
# Test production APIs with WAF
./BACKEND-DEPLOYMENT-GUIDE/production-test.sh

# Test WAF rate limiting specifically
./BACKEND-DEPLOYMENT-GUIDE/test-waf-rate-limits.sh
```

### 3. Pre-Deployment Validation
```bash
# Validate infrastructure before deployment
./BACKEND-DEPLOYMENT-GUIDE/pre-deployment-check.sh
```

## WAF Considerations for Testing

### Rate Limiting
- **Client API**: 2000 requests/minute (33/second)
- **Admin API**: 1000 requests/minute (16/second)
- **Test scripts now include delays** to respect these limits

### Monitoring
- WAF logs available in CloudWatch
- API Gateway execution logs for detailed analysis
- Rate limiting metrics in WAF dashboard

## No Changes Required

### Scripts that remain unchanged:
- `test-admin-registration.sh` - Already uses correct endpoints
- `test-email-notifications.sh` - Already uses correct endpoints
- Individual notification test scripts - Already correct

### Application Code
- No backend service code changes required
- Existing FastAPI endpoints remain the same
- Authentication flow unchanged

## Summary
✅ **6 scripts updated/created** to support new architecture
✅ **WAF rate limiting** properly handled in test scripts  
✅ **New comprehensive WAF testing** script added
✅ **All endpoint paths** corrected for REST API Gateway v1
✅ **Infrastructure validation** updated for modular terraform

Your test scripts are now fully compatible with the new REST API Gateway v1 + WAF + NLB architecture.