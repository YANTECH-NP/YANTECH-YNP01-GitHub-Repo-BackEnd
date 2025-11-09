@echo off
echo ========================================
echo ECS Quick Diagnosis for dev environment
echo ========================================

echo.
echo 1. Checking cluster status...
aws ecs describe-clusters --clusters YANTECH-cluster-dev --query "clusters[0].{Status:status,ActiveServices:activeServicesCount,RunningTasks:runningTasksCount,RegisteredInstances:registeredContainerInstancesCount}" --output table

echo.
echo 2. Checking services status...
aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev YANTECH-requestor-service-dev YANTECH-worker-service-dev --query "services[].{ServiceName:serviceName,Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}" --output table

echo.
echo 3. Checking recent service events...
aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-admin-service-dev --query "services[0].events[:3].{Time:createdAt,Message:message}" --output table

echo.
echo 4. Checking target group health...
aws elbv2 describe-target-groups --names YANTECH-requester-ec2-tg-dev YANTECH-admin-ec2-tg-dev --query "TargetGroups[].{Name:TargetGroupName,HealthyCount:HealthyHostCount,UnhealthyCount:UnhealthyHostCount}" --output table

echo.
echo 5. Checking stopped tasks (last 3)...
aws ecs list-tasks --cluster YANTECH-cluster-dev --service-name YANTECH-requestor-service-dev --desired-status STOPPED --max-items 3 --query "taskArns[0]" --output text > temp_task.txt
set /p TASK_ARN=<temp_task.txt
if not "%TASK_ARN%"=="None" (
    aws ecs describe-tasks --cluster YANTECH-cluster-dev --tasks %TASK_ARN% --query "tasks[0].{StoppedReason:stoppedReason,ExitCode:containers[0].exitCode,ContainerReason:containers[0].reason}" --output table
)
del temp_task.txt

echo.
echo ========================================
echo Diagnosis complete. Look for:
echo - RegisteredInstances should be ^> 0
echo - Services should have Running = Desired
echo - Target groups should have healthy targets
echo - Check stopped task reasons for errors
echo ========================================
pause