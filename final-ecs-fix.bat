@echo off
echo Final ECS Registration Fix - Following Checklist
echo ===============================================

echo Getting current instance ID...
for /f %%i in ('aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names YANTECH-ecs-asg-dev --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text') do set INSTANCE_ID=%%i
echo Instance ID: %INSTANCE_ID%

echo 1. Checking ECS agent and restarting if needed...
aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters commands="sudo systemctl stop ecs && sudo rm -rf /var/lib/ecs/data/* && echo 'ECS_CLUSTER=YANTECH-cluster-dev' | sudo tee /etc/ecs/ecs.config && sudo systemctl start ecs && sudo systemctl enable ecs" --comment "Fix ECS agent"

echo 2. Waiting 60 seconds for ECS agent to register...
timeout /t 60 /nobreak

echo 3. Checking registration...
for /f %%i in ('aws ecs describe-clusters --clusters YANTECH-cluster-dev --query "clusters[0].registeredContainerInstancesCount" --output text') do set REGISTERED=%%i
echo Registered instances: %REGISTERED%

if "%REGISTERED%"=="0" (
    echo ECS agent fix didn't work. Trying reboot...
    aws ec2 reboot-instances --instance-ids %INSTANCE_ID%
    echo Waiting 3 minutes for reboot and registration...
    timeout /t 180 /nobreak
    
    for /f %%i in ('aws ecs describe-clusters --clusters YANTECH-cluster-dev --query "clusters[0].registeredContainerInstancesCount" --output text') do set REGISTERED=%%i
    echo After reboot - Registered instances: %REGISTERED%
)

if "%REGISTERED%"=="0" (
    echo Reboot didn't work. Forcing new instance launch...
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name YANTECH-ecs-asg-dev --min-size 0 --desired-capacity 0
    timeout /t 30 /nobreak
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name YANTECH-ecs-asg-dev --min-size 1 --desired-capacity 1
    echo Waiting 5 minutes for new instance...
    timeout /t 300 /nobreak
    
    for /f %%i in ('aws ecs describe-clusters --clusters YANTECH-cluster-dev --query "clusters[0].registeredContainerInstancesCount" --output text') do set REGISTERED=%%i
    echo After new instance - Registered instances: %REGISTERED%
)

if "%REGISTERED%" GTR "0" (
    echo ✅ SUCCESS! %REGISTERED% instance(s) registered with ECS
    echo Checking services...
    aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev YANTECH-requestor-service-dev YANTECH-worker-service-dev --query "services[].{ServiceName:serviceName,Running:runningCount,Desired:desiredCount}" --output table
    echo.
    echo You can now retry your GitHub Actions deployment!
) else (
    echo ❌ FAILED: Still no instances registered. Manual investigation needed.
    echo Check:
    echo 1. VPC endpoints for ECS
    echo 2. Security groups allowing outbound HTTPS
    echo 3. IAM role permissions
    echo 4. AMI compatibility
)

pause