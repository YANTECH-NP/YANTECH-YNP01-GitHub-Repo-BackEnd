# 🚀 GitHub Actions Deployment Guide

## Overview
This workflow automatically builds and deploys your 3 microservices (admin, requestor, worker) to AWS ECS Fargate across multiple environments.

## 📋 Prerequisites Setup

### 1. GitHub Secrets (Required)
Add this secret in GitHub Settings → Secrets and variables → Actions:

```
AWS_ROLE_ARN = arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
```

### 2. AWS Resources (Required)

#### ECR Repositories
Create 9 ECR repositories (3 services × 3 environments):
```
admin-prod, admin-staging, admin-dev
requestor-prod, requestor-staging, requestor-dev  
worker-prod, worker-staging, worker-dev
```

#### ECS Clusters
Create 3 ECS clusters:
```
notifications-prod
notifications-staging
notifications-dev
```

#### ECS Services
Create 9 ECS services (3 per cluster):
```
admin-prod, requestor-prod, worker-prod
admin-staging, requestor-staging, worker-staging
admin-dev, requestor-dev, worker-dev
```

#### IAM Role for GitHub Actions
Create role `GitHubActionsRole` with:
- Trust policy for GitHub OIDC
- Permissions: ECR (push/pull), ECS (update services)

## 🔄 Workflow Sections Explained

### 1. **Trigger Section**
```yaml
on:
  push:
    branches: [main, staging, develop]
```
**What it does:** Triggers workflow on push to specific branches
**Environment mapping:**
- `main` → production
- `staging` → staging  
- `develop` → development

### 2. **Environment Detection**
```yaml
- name: Set environment
  run: |
    if [[ "${{ github.ref_name }}" == "main" ]]; then
      echo "ENVIRONMENT=prod" >> $GITHUB_ENV
```
**What it does:** Sets environment variable based on branch name

### 3. **AWS Authentication**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}  # ⚠️ ADD YOUR ROLE ARN HERE
```
**What it does:** Authenticates with AWS using OIDC (no access keys)
**Required:** Set `AWS_ROLE_ARN` secret with your IAM role ARN

### 4. **ECR Login**
```yaml
- name: Login to ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```
**What it does:** Gets temporary ECR login credentials

### 5. **Build & Push Images**
```yaml
docker build -t $ECR_REGISTRY/admin-$ENVIRONMENT:$IMAGE_TAG ./admin
docker push $ECR_REGISTRY/admin-$ENVIRONMENT:$IMAGE_TAG
```
**What it does:** 
- Builds Docker images for all 3 services
- Tags with git commit SHA
- Pushes to environment-specific ECR repos

### 6. **Deploy to ECS**
```yaml
aws ecs update-service --cluster notifications-$ENVIRONMENT --service admin-$ENVIRONMENT --force-new-deployment
```
**What it does:** Forces ECS to pull new images and redeploy services

## 🎯 Deployment Flow

1. **Push code** to `main`, `staging`, or `develop`
2. **Environment detected** automatically
3. **Docker images built** for all 3 services
4. **Images pushed** to ECR repos (e.g., `admin-prod:abc123`)
5. **ECS services updated** to use new images
6. **Services redeployed** with zero downtime

## ⚙️ Configuration Checklist

- [ ] Set `AWS_ROLE_ARN` GitHub secret
- [ ] Create 9 ECR repositories
- [ ] Create 3 ECS clusters  
- [ ] Create 9 ECS services
- [ ] Configure IAM role with proper permissions
- [ ] Test with push to `develop` branch first

## 🔍 Monitoring

Check deployment status in:
- GitHub Actions tab
- AWS ECS Console → Services
- CloudWatch logs for application logs