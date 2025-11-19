#!/bin/bash

# Fix Common EC2 ECS Issues After Fargate Migration
# Usage: ./fix-ec2-ecs-issues.sh <environment>

ENVIRONMENT=${1:-dev}
CLUSTER_NAME="YANTECH-cluster-${ENVIRONMENT}"

echo "🔧 Fixing common EC2 ECS issues for environment: $ENVIRONMENT"
echo "=========================================="

# 1. Check and restart ECS agent on EC2 instances
echo "1️⃣ Checking ECS Agent on EC2 instances..."
aws ecs list-container-instances --cluster $CLUSTER_NAME --query 'containerInstanceArns' --output text | while read instance_arn; do
    if [ ! -z "$instance_arn" ]; then
        EC2_ID=$(aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $instance_arn --query 'containerInstances[0].ec2InstanceId' --output text)
        AGENT_CONNECTED=$(aws ecs describe-container-instances --cluster $CLUSTER_NAME --container-instances $instance_arn --query 'containerInstances[0].agentConnected' --output text)
        
        echo "EC2 Instance: $EC2_ID, Agent Connected: $AGENT_CONNECTED"
        
        if [ "$AGENT_CONNECTED" = "false" ]; then
            echo "⚠️ Restarting ECS agent on $EC2_ID..."
            aws ssm send-command \
                --instance-ids $EC2_ID \
                --document-name "AWS-RunShellScript" \
                --parameters 'commands=["sudo systemctl restart ecs", "sudo systemctl status ecs"]' \
                --comment "Restart ECS agent" || echo "❌ Failed to restart ECS agent (SSM may not be available)"
        fi
    fi
done

# 2. Scale services to ensure they restart
echo -e "\n2️⃣ Restarting services by scaling down and up..."
SERVICES=("admin" "requestor" "worker")

for SERVICE in "${SERVICES[@]}"; do
    SERVICE_NAME="YANTECH-${SERVICE}-service-${ENVIRONMENT}"
    
    echo "🔄 Restarting service: $SERVICE_NAME"
    
    # Get current desired count
    DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query 'services[0].desiredCount' --output text 2>/dev/null)
    
    if [ "$DESIRED_COUNT" != "None" ] && [ ! -z "$DESIRED_COUNT" ]; then
        echo "Current desired count: $DESIRED_COUNT"
        
        # Scale to 0 first
        echo "Scaling down to 0..."
        aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count 0 --no-cli-pager
        
        # Wait a moment
        sleep 10
        
        # Scale back to original count
        echo "Scaling back to $DESIRED_COUNT..."
        aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --desired-count $DESIRED_COUNT --no-cli-pager
        
        echo "✅ Service $SERVICE_NAME restarted"
    else
        echo "❌ Service $SERVICE_NAME not found"
    fi
done

# 3. Check security groups for container ports
echo -e "\n3️⃣ Checking security group rules..."
SG_ID=$(aws ecs describe-clusters --clusters $CLUSTER_NAME --query 'clusters[0].tags[?key==`SecurityGroup`].value' --output text)

if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
    echo "Security Group: $SG_ID"
    
    # Check if dynamic port range is open
    DYNAMIC_PORTS=$(aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`32768` && ToPort==`65535`]' --output text)
    
    if [ -z "$DYNAMIC_PORTS" ]; then
        echo "⚠️ Dynamic port range (32768-65535) not found in security group"
        echo "This is required for ECS EC2 launch type with dynamic port mapping"
    else
        echo "✅ Dynamic port range is configured"
    fi
else
    echo "⚠️ Could not find security group information"
fi

# 4. Check ALB target group health
echo -e "\n4️⃣ Checking ALB target group health..."
for SERVICE in "requestor" "admin"; do
    TG_NAME="YANTECH-${SERVICE}-ec2-tg-${ENVIRONMENT}"
    TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    
    if [ "$TG_ARN" != "None" ] && [ ! -z "$TG_ARN" ]; then
        echo "Checking target group: $TG_NAME"
        
        # Show current health
        aws elbv2 describe-target-health --target-group-arn $TG_ARN --query 'TargetHealthDescriptions[].{TargetId:Target.Id,Port:Target.Port,Health:TargetHealth.State,Reason:TargetHealth.Reason}' --output table
        
        # Check health check settings
        HEALTH_PATH=$(aws elbv2 describe-target-groups --target-group-arns $TG_ARN --query 'TargetGroups[0].HealthCheckPath' --output text)
        HEALTH_PORT=$(aws elbv2 describe-target-groups --target-group-arns $TG_ARN --query 'TargetGroups[0].HealthCheckPort' --output text)
        
        echo "Health check: $HEALTH_PATH on port $HEALTH_PORT"
    fi
done

# 5. Force new deployment
echo -e "\n5️⃣ Forcing new deployment for all services..."
for SERVICE in "${SERVICES[@]}"; do
    SERVICE_NAME="YANTECH-${SERVICE}-service-${ENVIRONMENT}"
    echo "🚀 Forcing new deployment: $SERVICE_NAME"
    
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --no-cli-pager && echo "✅ Deployment initiated for $SERVICE_NAME" || echo "❌ Failed to deploy $SERVICE_NAME"
done

echo -e "\n✅ Fix script completed!"
echo "📋 Next steps:"
echo "1. Wait 5-10 minutes for services to stabilize"
echo "2. Run ./debug-ecs-deployment.sh $ENVIRONMENT to check status"
echo "3. Check CloudWatch logs for container startup issues"
echo "4. Verify health check endpoints are responding"