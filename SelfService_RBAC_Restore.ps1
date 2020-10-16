# Pre-requisites
# Verify subscription has been transferred back to it's original AAD tenant\directory before attempting to restore role assignments
# Verify you have installed the Az PowerShell module  (https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)

# REPLACE the subscriptionID with your own subscription ID, and then login with AAD credentials for Subscription Admin (Owner \ Service Admin)
$AzureSub = "f2ceb5da-e353-42f5-9a84-070cf6a78a9b"

# REPLACE with the timeframe that your role assignments were deleted
$fromDate = "2020-10-16"
$toDate = "2020-10-17"






###################################
#### DO NOT MODIFY BELOW LINES ####
###################################

Write-Host -ForegroundColor Yellow "Sign in with your subscription's current Owner"

$ctx=Get-AzContext
if ($ctx.Account -eq $null) {
    Connect-AzAccount -Subscription $AzureSub
}
if ($ctx.SubscriptionName -ne $AzureSub) {
    Set-AzContext -Subscription $AzureSub
}

$ctx=Get-AzContext

#force context to grab a token for graph
Get-AzAdUser -UserPrincipalName $ctx.Account.Id

$cache = $ctx.TokenCache
$cacheItems = $cache.ReadItems()

$token = ($cacheItems | where { $_.Resource -eq "https://management.core.windows.net/" })
if ($token.ExpiresOn -le [System.DateTime]::UtcNow) {
    $ac = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new("$($ctx.Environment.ActiveDirectoryAuthority)$($ctx.Tenant.Id)",$token)
    $token = $ac.AcquireTokenByRefreshToken($token.RefreshToken, "1950a258-227b-4e31-a9cf-717495945fc2", "https://management.core.windows.net")
}


# Get access token to management.azure.com API
$tenant = $ctx.Tenant.Id
$token = $token | ? {($_.Authority -eq "https://login.windows.net/$tenant/") -and ($_.TenantId -eq $tenant)}

#Get deleted role assignments from management API
$url1 = "https://management.azure.com/subscriptions/$AzureSub/providers/microsoft.insights/eventtypes/management/values?api-version=2017-03-01-preview&"
$myfilter = "eventTimestamp ge $fromDate and eventTimestamp le $toDate and operations eq Microsoft.Authorization/roleAssignments/delete"
$url = $url1+'$filter='+$myfilter
$deletedRoleAssignmentLogs = Invoke-RestMethod -Headers @{Authorization = "Bearer $($token.AccessToken)"} -Uri $url -Method Get
$deletedRoleAssignmentLogs = $deletedRoleAssignmentLogs.value


$total = $deletedRoleAssignmentLogs.count
$count = 0

Write-Host -ForegroundColor Yellow "Found $total log entries for operation Delete role assignments on subscription $subscriptionID between $fromDate and $toDate"
Write-Host -ForegroundColor Yellow "Checking each log found for valid role assignment information.  Some deleted assignments in logs may be system role assignments only, so should be ignored.  This may take 5-10 minutes.  Please wait....."

$deletedAssignments = @()

foreach($log in $deletedRoleAssignmentLogs){

  
    
    $assignment = $log.Properties

    Write-Host -ForegroundColor Yellow "Checking log $count of $total for valid information.  Most deleted assignments will be system only, and can be ignored.  This may take 5-10 minutes. Please wait...."
    
    $count++

    $ErrorActionPreference = 'silentlycontinue'
    if(Get-AzRoleDefinition -Id ([guid]$assignment.roleDefinitionId)){
         write-host -ForegroundColor Green "Valid role assignment $assignment found"
         $deletedAssignment = New-Object -TypeName psobject 
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name PrincipalId -Value ([guid]$assignment.principalId)
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name RoleDefinitionId -Value ([guid]$assignment.roleDefinitionId)
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name Scope -Value ($assignment.scope)
         $deletedAssignments += $deletedAssignment
    }


   }


  $ErrorActionPreference = 'silentlycontinue'

  $count = 0
  $total = $deletedAssignments.count

  $deletedAssignments | Out-GridView -Title "Found $total valid role assignments to restore. See below"

  $response = Read-Host "Proceed with restoring the displayed assignments? (Y\N): "

  if($response -match "Y"){
    foreach($da in $deletedAssignments){
        $count++
        Write-Host -ForegroundColor Yellow "Restoring role assignment $count of $total ...."
        New-AzRoleAssignment -ObjectId $da.PrincipalId -Scope $da.Scope -RoleDefinitionId $da.RoleDefinitionId
        }


  Write-Host -ForegroundColor Green "Role assignment restoration has completed for $subscriptionId"
  }
  
  Read-Host “Press ENTER to quit...” -



