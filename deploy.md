# Deployment Guide

This guide describes how to deploy the infrastructure and application.

## Prerequisites
- AWS CLI installed and configured.
- **GitHub Repository Secrets**:
    - `AWS_ACCESS_KEY_ID`: Your AWS Access Key.
    - `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Key.
    - `FRONTEND_BUCKET_NAME`: The S3 Bucket name for the frontend (Get this from script output or CloudFormation).
    - `CLOUDFRONT_DISTRIBUTION_ID`: The ID of your CloudFront distribution (Get this from script output or CloudFormation).

## 1. Initial Infrastructure Deployment
The initial base stacks (VPC, S3, DynamoDB, ECR) are deployed automatically by the `Infrastructure Deploy` workflow when files in `infra/` are pushed.
Ensure these are deployed before proceeding.

## 2. Parameter Update & Component Deployment
The remaining components (ALB, ECS, CloudFront) depend on IDs from the initial deployment.
We have provided a helper script to automatically fetch these IDs and update your local YAML files.

### Step 2.1: Run the Helper Script
Open a terminal in the project root and run:
```powershell
powershell -ExecutionPolicy Bypass -File ./update-infra-params.ps1
```
This script will:
1.  Fetch VPC ID, Subnets, Bucket Names, and Repository URI from your AWS account.
2.  Update `infra/alb.yml`, `infra/ecs.yml`, and `infra/cloudfront.yml` with these values.

### Step 2.2: Deploy ALB
1.  Check the changes in `infra/alb.yml`.
2.  Commit and push:
    ```bash
    git add infra/alb.yml
    git commit -m "Configure ALB parameters"
    git push
    ```
3.  Wait for the `Infrastructure Deploy` action to complete.

### Step 2.3: Update ECS Parameters (Target Group)
The script needs to run **again** after ALB deployment to fetch the new `TargetGroupArn`.
1.  Run the script again:
    ```powershell
    ./update-infra-params.ps1
    ```
2.  Check changes in `infra/ecs.yml`.
3.  Commit and push:
    ```bash
    git add infra/ecs.yml
    git commit -m "Configure ECS parameters"
    git push
    ```

### Step 2.4: Deploy CloudFront
1.  The script should have already updated `infra/cloudfront.yml`.
2.  Commit and push:
    ```bash
    git add infra/cloudfront.yml
    git commit -m "Configure CloudFront parameters"
    git push
    ```

## 3. Application Deployment
- **Backend**: Pushing changes to `backend/` triggers build, docker push, and ECS service update.
- **Frontend**: Pushing changes to `frontend/` triggers build and S3 sync.
