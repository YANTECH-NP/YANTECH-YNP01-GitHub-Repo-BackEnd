@echo off
REM Generate CloudWatch metrics for ALB dashboard
REM This script sends periodic requests to both ALBs to generate metrics data

set CLIENT_ALB=YANTECH-requester-alb-dev-1265507803.us-east-1.elb.amazonaws.com
set ADMIN_ALB=YANTECH-admin-alb-dev-271808247.us-east-1.elb.amazonaws.com

echo 🚀 Starting ALB metrics generation...
echo 📊 This will send requests every 30 seconds to generate CloudWatch data
echo ⏱️  Metrics typically appear in CloudWatch within 5-15 minutes
echo 🛑 Press Ctrl+C to stop
echo.

set counter=1
:loop
echo [%counter%] %date% %time%: Sending requests to ALBs...

REM Send requests to client ALB
echo   → Client ALB health check...
curl -s "http://%CLIENT_ALB%/health" > nul

REM Send requests to admin ALB  
echo   → Admin ALB health check...
curl -s "http://%ADMIN_ALB%/health" > nul

REM Send a few more requests to generate more data points
curl -s "http://%CLIENT_ALB%/health" > nul
curl -s "http://%ADMIN_ALB%/health" > nul

echo   ✅ Requests completed
echo.

set /a counter+=1
timeout /t 30 /nobreak > nul
goto loop