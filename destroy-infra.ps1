# Set the environment name
$EnvName = "photo-share"
$Region = "ap-northeast-1"

Write-Host "Starting infrastructure destruction for environment: $EnvName" -ForegroundColor Yellow

# Function to empty and delete an S3 bucket
function Remove-S3Bucket {
    param ($StackName, $LogicalId)
    
    $BucketName = aws cloudformation describe-stack-resource --stack-name $StackName --logical-resource-id $LogicalId --query "StackResourceDetail.PhysicalResourceId" --output text 2>$null
    
    if ($LASTEXITCODE -eq 0 -and $BucketName) {
        Write-Host "Emptying bucket: $BucketName"
        aws s3 rm s3://$BucketName --recursive
        if ($LASTEXITCODE -ne 0) { Write-Host "Failed to empty bucket $BucketName" -ForegroundColor Red }
    }
}

# 1. Empty S3 Buckets (required before stack deletion)
Write-Host "Step 1: Emptying S3 Buckets..."
Remove-S3Bucket -StackName "$EnvName-s3" -LogicalId "FrontendBucket"
Remove-S3Bucket -StackName "$EnvName-s3" -LogicalId "DataBucket"

# 2. Clear ECR Repository (required before stack deletion)
Write-Host "Step 2: Clearing ECR Repository..."
$RepoName = "photo-share-backend"
Write-Host "Deleting repository $RepoName (force)..."
aws ecr delete-repository --repository-name $RepoName --force --region $Region 2>$null

# 3. Delete Stacks in reverse dependency order
$Stacks = @(
    "$EnvName-cloudfront",
    "$EnvName-ecs",
    "$EnvName-alb",
    "$EnvName-ecr",
    "$EnvName-dynamodb",
    "$EnvName-s3",
    "$EnvName-vpc"
)

foreach ($Stack in $Stacks) {
    Write-Host "Deleting stack: $Stack"
    aws cloudformation delete-stack --stack-name $Stack --region $Region
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deletion initiated for $Stack. Waiting for completion..."
        aws cloudformation wait stack-delete-complete --stack-name $Stack --region $Region
        Write-Host "$Stack deleted successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Failed to initiate deletion for $Stack" -ForegroundColor Red
    }
}

Write-Host "Infrastructure destruction completed." -ForegroundColor Green
