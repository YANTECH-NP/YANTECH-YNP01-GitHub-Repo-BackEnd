# 🚨 Fargate to EC2 Migration Troubleshooting Guide

## Issue: ECS Services Not Stabilizing After Migration

### Root Causes & Solutions

#### 1. **EC2 Instances Not Registered**
```bash
# Check if EC2 instances are registered with ECS cluster
aws ecs describe-clusters --clusters YANTECH-cluster-dev --query 'clusters[0].registeredContainerInstancesCount'

# If 0, check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names YANTECH-ecs-asg-dev
```

**Fix:**
- Ensure ECS-optimized AMI is used
- Verify ECS agent is running: `sudo systemctl status ecs`
- Check cluster name in user data script

#### 2. **Security Group Issues**
EC2 launch type requires dynamic port range (32768-65535) to be open.

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx --query 'SecurityGroups[0].IpPermissions[?FromPort==`32768`]'
```

**Fix:** Add rule allowing ports 32768-65535 from ALB security group.

#### 3. **Health Check Failures**
Target groups using `traffic-port` with dynamic port mapping can cause issues.

**Symptoms:**
- Targets showing as "unhealthy"
- Services stuck in "pending" state

**Fix:** Updated health check timeouts and thresholds in `elb.tf`.

#### 4. **Container Startup Issues**
Containers may fail to start due to resource constraints or environment variables.

```bash
# Check stopped tasks
aws ecs list-tasks --cluster YANTECH-cluster-dev --service-name YANTECH-requestor-service-dev --desired-status STOPPED
```

#### 5. **Port Mapping Configuration**
EC2 launch type uses dynamic port mapping (hostPort = 0).

**Verify in task definition:**
```json
"portMappings": [
  {
    "containerPort": 8000,
    "hostPort": 0,  // Dynamic port assignment
    "protocol": "tcp"
  }
]
```

### Immediate Actions

1. **Run diagnostic script:**
   ```bash
   ./debug-ecs-deployment.sh dev
   ```

2. **Apply fixes:**
   ```bash
   ./fix-ec2-ecs-issues.sh dev
   ```

3. **Update infrastructure:**
   ```bash
   cd modular-terraform
   terraform apply -target=module.load_balancer
   ```

4. **Redeploy services:**
   ```bash
   # Trigger GitHub Actions or run manually:
   aws ecs update-service --cluster YANTECH-cluster-dev --service YANTECH-requestor-service-dev --force-new-deployment
   ```

### Monitoring Commands

```bash
# Watch service status
watch -n 10 'aws ecs describe-services --cluster YANTECH-cluster-dev --services YANTECH-requestor-service-dev --query "services[0].{Running:runningCount,Desired:desiredCount,Pending:pendingCount}"'

# Check target group health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/YANTECH-requester-ec2-tg-dev/XXXXXXXXX

# View container logs
aws logs tail /ecs/YANTECH-requestor-dev --follow
```

### Expected Timeline
- **EC2 instances**: 2-3 minutes to register
- **Container startup**: 1-2 minutes
- **Health checks**: 2-3 minutes to pass
- **Total stabilization**: 5-10 minutes

### Success Indicators
- ✅ EC2 instances registered in cluster
- ✅ Services showing desired count = running count
- ✅ Target groups showing healthy targets
- ✅ Health check endpoints responding (200 OK)
- ✅ No error logs in CloudWatch

### If Still Failing
1. Check CloudWatch logs for container errors
2. Verify environment variables are set correctly
3. Test health endpoints manually on EC2 instances
4. Consider scaling up EC2 instance size if resource constrained
5. Temporarily increase health check grace period