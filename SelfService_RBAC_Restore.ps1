# Pre-requisites
# Verify subscription has been transferred back to it's original AAD tenant\directory before attempting to restore role assignments
# Verify you have installed the Az PowerShell module  (https://docs.microsoft.com/en-us/powershell/azure/install-az-ps)

# Replace the subscriptionID with your own subscription ID, and then login with AAD credentials for Subscription Admin (Owner \ Service Admin)
Connect-AzAccount -Subscription "f2ceb5da-e353-42f5-9a84-070cf6a78a9b"

# Replace the fromDate and toDate strings to include the timeframe that the roleassignments were deleted
# If you do not know this timeframe, you can use Azure Portal to find
# 1. Browse to the https://portal.azure.com/#blade/Microsoft_Azure_ActivityLog/ActivityLogBlade
# 2. Change "Subscription" filter to include your Azure Subscription that lost role assignments, Add a new filter type for "Operation" and choose "Delete role assignment"
# 3. Consult the returned logs to determine the timeframe of role assignment deletion

$fromDate = "2020-09-21T10:00"
$toDate = "2020-09-21T19:00"



###################################
#### DO NOT MODIFY BELOW LINES ####
###################################

# Parse Azure Activity Logs for Subscription to find all operations where RBAC role assignments were deleted
$deletedRoleAssignmentLogs = Get-AzLog -StartTime ([datetime]$fromdate) -EndTime ([datetime]$toDate) | ? {$_.OperationName.Value -eq "Microsoft.Authorization/roleAssignments/delete"}
$deletedAssignments = @()

# Create a PowerShell object containing all the necessary data (PrincipalId, RoleDefinitionId, Scope) from parsed logs to restore role assignments
foreach($log in $deletedRoleAssignmentLogs){
   
    $assignment = $log.Properties.Content

    $deletedAssignment = New-Object -TypeName psobject 
    $deletedAssignment| Add-Member -MemberType NoteProperty -Name RoleAssignmentId -Value  ([guid]$assignment.id)
    $deletedAssignment | Add-Member -MemberType NoteProperty -Name PrincipalId -Value ([guid]$assignment.principalId)
    $deletedAssignment | Add-Member -MemberType NoteProperty -Name RoleDefinitionId -Value ([guid]$assignment.roleDefinitionId)
    $deletedAssignment | Add-Member -MemberType NoteProperty -Name Scope -Value ($assignment.scope)


    $deletedAssignments += $deletedAssignment


   }


    # The Azure Activity logs will have reference to a number of role definitions which are system roles and cannot be assigned by customer themselves.
    # These roles can be skipped as they are automatically re-assigned after subscription transfer, they will cause errors to be displayed such as
    # "The specified role definition with ID '6efa92ca-56b6-40af-a468-5e3d2b5232f0' does not exist."  Where 6efa92ca-56b6-40af-a468-5e3d2b5232f0
    # Is a system role that cannot be assigned by customers.

    # The remaining roles will be listed via the output of the below command as being succesfully re-assigned

    $PrevErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'silentlycontinue'

    foreach($da in $deletedAssignments){
        New-AzRoleAssignment -ObjectId $da.PrincipalId -Scope $da.Scope -RoleDefinitionId $da.RoleDefinitionId
        }


