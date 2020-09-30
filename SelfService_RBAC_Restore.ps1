# Pre-requisites
# Verify subscription has been transferred back to it's original AAD tenant\directory before attempting to restore role assignments
# Verify you have installed the Az PowerShell module  (https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)

# Replace the subscriptionID with your own subscription ID, and then login with AAD credentials for Subscription Admin (Owner \ Service Admin)
$subscriptionID = "f2ceb5da-e353-42f5-9a84-070cf6a78a9b"

# Replace the fromDate and toDate strings to include the timeframe that the roleassignments were deleted
# If you do not know this timeframe, you can use Azure Portal to find
# 1. Browse to the https://portal.azure.com/#blade/Microsoft_Azure_ActivityLog/ActivityLogBlade
# 2. Change "Subscription" filter to include your Azure Subscription that lost role assignments, Add a new filter type for "Operation" and choose "Delete role assignment"
# 3. Consult the returned logs to determine the timeframe of role assignment deletion

$fromDate = "2020-09-30T10:32"
$toDate = "2020-09-30T10:40"



###################################
#### DO NOT MODIFY BELOW LINES ####
###################################

Connect-AzAccount -Subscription $subscriptionID

# Parse Azure Activity Logs for Subscription to find all operations where RBAC role assignments were deleted
$deletedRoleAssignmentLogs = Get-AzLog -StartTime ([datetime]$fromdate) -EndTime ([datetime]$toDate) | ? {($_.OperationName.Value -eq "Microsoft.Authorization/roleAssignments/delete") -and ($_.Status.Value -eq "Succeeded")}
$total = $deletedRoleAssignmentLogs.count

 Write-Host -ForegroundColor Yellow "Found $total log entries for operation Delete role assignments on subscription $subscriptionID between $fromDate and $toDate"
 Write-Host -ForegroundColor Yellow "Checking each log found for valid role assignment information.  This may take 5-10 minutes.  Please wait....."

$deletedAssignments = @()

# Create a PowerShell object containing all the necessary data (PrincipalId, RoleDefinitionId, Scope) from parsed logs to restore role assignments
foreach($log in $deletedRoleAssignmentLogs){
   
    
    if($log.Properties.Content.roleDefinitionId){$assignment = $log.Properties.Content}
    if($log.Properties.Content.responseBody){
        $assignment = $log.Properties.Content.responseBody | ConvertFrom-Json
        $assignment = $assignment.properties
        $assignment.roleDefinitionId = $assignment.roleDefinitionId.Substring($assignment.roleDefinitionId.Length - 36)

        }

    

    $ErrorActionPreference = 'silentlycontinue'
    if(Get-AzRoleDefinition -Id ([guid]$assignment.roleDefinitionId)){
         $deletedAssignment = New-Object -TypeName psobject 
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name PrincipalId -Value ([guid]$assignment.principalId)
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name RoleDefinitionId -Value ([guid]$assignment.roleDefinitionId)
         $deletedAssignment | Add-Member -MemberType NoteProperty -Name Scope -Value ($assignment.scope)
         $deletedAssignments += $deletedAssignment
    }


   }


# The Azure Activity logs will have reference to a number of role definitions which are system roles and cannot be assigned by customer themselves.
# These roles can be skipped as they are automatically re-assigned after subscription transfer, they will cause errors to be displayed such as
# "The specified role definition with ID '6efa92ca-56b6-40af-a468-5e3d2b5232f0' does not exist."  Where 6efa92ca-56b6-40af-a468-5e3d2b5232f0
# Is a system role that cannot be assigned by customers.

# The remaining roles will be listed via the output of the below command as being succesfully re-assigned

  $ErrorActionPreference = 'silentlycontinue'

  $count = 0
  $total = $deletedAssignments.count

  Write-Host -ForegroundColor Yellow "Found $total valid role assignments to restore."

    foreach($da in $deletedAssignments){
        $count++
        Write-Host -ForegroundColor Yellow "Restoring role assignment $count of $total ...."
        New-AzRoleAssignment -ObjectId $da.PrincipalId -Scope $da.Scope -RoleDefinitionId $da.RoleDefinitionId
        }


  Write-Host -ForegroundColor Yellow "Role assignment restoration has completed for $subscriptionId"
  Read-Host “Press ENTER to continue...”
