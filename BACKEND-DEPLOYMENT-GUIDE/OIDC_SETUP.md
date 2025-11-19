# 🔐 AWS OIDC Setup for GitHub Actions

## Step 1: Create OIDC Identity Provider

### AWS Console:
1. Go to **IAM** → **Identity providers** → **Add provider**
2. Select **OpenID Connect**
3. Set:
   - **Provider URL**: `https://token.actions.githubusercontent.com`
   - **Audience**: `sts.amazonaws.com`
4. Click **Add provider**

### AWS CLI:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

## Step 2: Create IAM Role

### Trust Policy (replace YOUR_GITHUB_USERNAME/YOUR_REPO):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

### Permissions Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ],
      "Resource": "*"
    }
  ]
}
```

## Step 3: Create Role via AWS CLI

```bash
# Create role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Attach permissions
aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsPolicy \
  --policy-document file://permissions-policy.json
```

## Step 4: Get Role ARN

```bash
aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text
```

Copy this ARN to GitHub Secrets as `AWS_ROLE_ARN`

## How OIDC Works

1. **GitHub generates JWT token** with repo/branch info
2. **AWS STS validates token** against OIDC provider
3. **Temporary credentials issued** (15 min - 12 hours)
4. **GitHub Actions uses credentials** for AWS API calls
5. **No long-term access keys stored** in GitHub

## Benefits vs Access Keys

✅ **OIDC**: Temporary, auto-rotating, scoped to specific repos/branches
❌ **Access Keys**: Permanent, manual rotation, broader permissions