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
    # Case 1: Default already exists
    $patternExists = "(?s)(${ParamName}:\s*\n\s*Type:.*?\n\s*)Default:.*"
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
$DataBucketName = Get-StackOutput -StackName "photo-share-s3" -OutputKey "DataBucketName"
$RepositoryUri = Get-StackOutput -StackName "photo-share-ecr" -OutputKey "RepositoryUri"

# Fetch ALB Output (might fail if not deployed yet)
$TargetGroupArn = Get-StackOutput -StackName "photo-share-alb" -OutputKey "TargetGroupArn"

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

Write-Host "Done!" -ForegroundColor Cyan
