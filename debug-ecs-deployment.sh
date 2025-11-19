#!/bin/bash

# Debug ECS Deployment Issues After Fargate to EC2 Migration
# Usage: ./debug-ecs-deployment.sh <environment>

ENVIRONMENT=${1:-dev}
CLUSTER_NAME="YANTECH-cluster-${ENVIRONMENT}"
SERVICES=("admin" "requestor" "worker")

echo "🔍 Debugging ECS deployment for environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER_NAME"
echo "=========================================="

# Check cluster status
echo "📋 Cluster Status:"
aws ecs describe-clusters --clusters $CLUSTER_NAME --query 'clusters[0].{Status:status,ActiveServices:activeServicesCount,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount}' --output table

# Check EC2 instances in cluster
echo -e "\n🖥️  EC2 Instances in Cluster:"
aws ecs list-container-instances --cluster $CLUSTER_NAME --query 'containerInstanceArns' --output text | while read instance_arn; do
    if [ ! -z "$instance_arn" ]; then
        aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $instance_arn --query 'containerInstances[0].{EC2InstanceId:ec2InstanceId,Status:status,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount,AgentConnected:agentConnected}' --output table
    fi
done

# Check each service
for SERVICE in "${SERVICES[@]}"; do
    SERVICE_NAME="YANTECH-${SERVICE}-service-${ENVIRONMENT}"
    echo -e "\n🔧 Service: $SERVICE_NAME"
    
    # Service status
    aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' --output table
    
    # Recent events
    echo "📝 Recent Events:"
    aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].events[:3].{Time:createdAt,Message:message}' --output table
    
    # Task definition details
    TASK_DEF_ARN=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].taskDefinition' --output text)
    echo "📄 Task Definition: $TASK_DEF_ARN"
    
    # Check running tasks
    echo "🏃 Running Tasks:"
    aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --query 'taskArns' --output text | while read task_arn; do
        if [ ! -z "$task_arn" ]; then
            aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $task_arn --query 'tasks[0].{TaskArn:taskArn,LastStatus:lastStatus,HealthStatus:healthStatus,CreatedAt:createdAt}' --output table
            
            # Container status
            echo "📦 Container Status:"
            aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $task_arn --query 'tasks[0].containers[0].{Name:name,LastStatus:lastStatus,HealthStatus:healthStatus,ExitCode:exitCode,Reason:reason}' --output table
        fi
    done
    
    # Check stopped tasks for errors
    echo "❌ Recent Stopped Tasks (last 5):"
    aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --desired-status STOPPED --max-items 5 --query 'taskArns' --output text | while read task_arn; do
        if [ ! -z "$task_arn" ]; then
            echo "Task: $task_arn"
            aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $task_arn --query 'tasks[0].{StoppedReason:stoppedReason,StoppedAt:stoppedAt}' --output table
            aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $task_arn --query 'tasks[0].containers[0].{ExitCode:exitCode,Reason:reason}' --output table
        fi
    done
done

# Check ALB target groups health
echo -e "\n🎯 ALB Target Group Health:"
for SERVICE in "requestor" "admin"; do
    TG_NAME="YANTECH-${SERVICE}-ec2-tg-${ENVIRONMENT}"
    TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    
    if [ "$TG_ARN" != "None" ] && [ ! -z "$TG_ARN" ]; then
        echo "Target Group: $TG_NAME"
        aws elbv2 describe-target-health --target-group-arn $TG_ARN --query 'TargetHealthDescriptions[].{TargetId:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason}' --output table
    fi
done

echo -e "\n✅ Debug complete. Check the output above for issues."
echo "Common issues after Fargate to EC2 migration:"
echo "1. EC2 instances not registered with ECS cluster"
echo "2. Security group blocking container ports"
echo "3. Health check failures due to port mapping changes"
echo "4. Insufficient EC2 instance capacity"
echo "5. Container startup failures due to environment variables"