@echo off
echo Running ECS Diagnostics for dev environment...
echo ================================================

REM Make sure you have AWS CLI configured and proper permissions
aws sts get-caller-identity

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: AWS CLI not configured or no permissions
    pause
    exit /b 1
)

REM Run the diagnostic script
bash debug-ecs-deployment.sh dev

echo.
echo Diagnostics completed. Check output above for issues.
pause