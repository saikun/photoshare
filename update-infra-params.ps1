# Script to fetch CloudFormation outputs and update infra params
$ErrorActionPreference = "Stop"

function Get-StackOutput {
    param (
        [string]$StackName,
        [string]$OutputKey
    )
    try {
        $outputs = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs" | ConvertFrom-Json
        $item = $outputs | Where-Object { $_.OutputKey -eq $OutputKey }
        if ($item) { return $item.OutputValue }
    }
    catch {
        Write-Host "Stack $StackName not found or error fetching outputs." -ForegroundColor Yellow
    }
    return $null
}

function Update-YamlParam {
    param (
        [string]$FilePath,
        [string]$ParamName,
        [string]$NewValue
    )
    if (-not (Test-Path $FilePath)) { return }
    if ([string]::IsNullOrEmpty($NewValue)) { return }

    $content = Get-Content $FilePath -Raw
    
    # Pattern to find the parameter definition and insert/update Default
    # Case 1: Default already exists - use non-greedy matching for the value
    # Fixed regex to not cross newlines into other parameters (Type:[^\n]*)
    $patternExists = "(?s)(${ParamName}:\s*\n\s*Type:[^\n]*\n\s*)Default:[^\r\n]*"
    if ($content -match $patternExists) {
        $content = $content -replace $patternExists, "`$1Default: $NewValue"
        Write-Host "Updated $ParamName in $FilePath" -ForegroundColor Green
    }
    else {
        # Case 2: Default does not exist, append it after Type
        $patternMissing = "(?s)(${ParamName}:\s*\n\s*Type: [^\n\r]+)"
        if ($content -match $patternMissing) {
            $content = $content -replace $patternMissing, "`$1`n    Default: $NewValue"
            Write-Host "Added $ParamName in $FilePath" -ForegroundColor Green
        }
        else {
            Write-Host "Could not find parameter block for $ParamName in $FilePath" -ForegroundColor Red
        }
    }
    Set-Content $FilePath $content -NoNewline
}

Write-Host "Fetching AWS CloudFormation Outputs..." -ForegroundColor Cyan

# Fetch Base Outputs
$VpcId = Get-StackOutput -StackName "photo-share-vpc" -OutputKey "VPC"
$PublicSubnets = Get-StackOutput -StackName "photo-share-vpc" -OutputKey "PublicSubnets"
$FrontendBucketUrl = Get-StackOutput -StackName "photo-share-s3" -OutputKey "FrontendBucketWebsiteURL"
$FrontendBucketName = Get-StackOutput -StackName "photo-share-s3" -OutputKey "FrontendBucketName"
$DataBucketName = Get-StackOutput -StackName "photo-share-s3" -OutputKey "DataBucketName"
$RepositoryUri = Get-StackOutput -StackName "photo-share-ecr" -OutputKey "RepositoryUri"

# Fetch ALB Output (might fail if not deployed yet)
$TargetGroupArn = Get-StackOutput -StackName "photo-share-alb" -OutputKey "TargetGroupArn"
$BackendALBDNS = Get-StackOutput -StackName "photo-share-alb" -OutputKey "LoadBalancerDNS"

# Update alb.yml
Update-YamlParam "infra/alb.yml" "VpcId" $VpcId
Update-YamlParam "infra/alb.yml" "PublicSubnets" $PublicSubnets

# Update ecs.yml
Update-YamlParam "infra/ecs.yml" "VpcId" $VpcId
Update-YamlParam "infra/ecs.yml" "PublicSubnets" $PublicSubnets
Update-YamlParam "infra/ecs.yml" "RepositoryUri" $RepositoryUri
Update-YamlParam "infra/ecs.yml" "DataBucketName" $DataBucketName
Update-YamlParam "infra/ecs.yml" "TargetGroupArn" $TargetGroupArn

# Update cloudfront.yml
Update-YamlParam "infra/cloudfront.yml" "FrontendBucketWebsiteURL" $FrontendBucketUrl
Update-YamlParam "infra/cloudfront.yml" "FrontendBucketName" $FrontendBucketName
Update-YamlParam "infra/cloudfront.yml" "BackendALBDNS" $BackendALBDNS

Write-Host "Done updating YAML files!" -ForegroundColor Cyan

# Fetch additional outputs for GitHub Secrets
$CloudFrontDistId = Get-StackOutput -StackName "photo-share-cloudfront" -OutputKey "DistributionId"

Write-Host "`n--------------------------------------------------" -ForegroundColor White
Write-Host "REQUIRED GITHUB SECRETS" -ForegroundColor Yellow
Write-Host "Please add the following secrets to your GitHub Repository:" -ForegroundColor White
if ($FrontendBucketName) {
    Write-Host "FRONTEND_BUCKET_NAME: $FrontendBucketName" -ForegroundColor Green
}
else {
    Write-Host "FRONTEND_BUCKET_NAME: (Deploy 'Infra' first to get this)" -ForegroundColor Gray
}
if ($CloudFrontDistId) {
    Write-Host "CLOUDFRONT_DISTRIBUTION_ID: $CloudFrontDistId" -ForegroundColor Green
}
else {
    Write-Host "CLOUDFRONT_DISTRIBUTION_ID: (Deploy 'CloudFront' first to get this)" -ForegroundColor Gray
}
Write-Host "--------------------------------------------------`n" -ForegroundColor White
