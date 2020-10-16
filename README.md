# Self Service RBAC Restore
If you perform any operation on your Azure Subscription which causes it to switch AAD tenants, you will lose all RBAC role assignments during the transfer.  The most common ways this occurs is via [Subsription ownership transfers](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/billing-subscription-transfer) or Subscription owner's choosing ["Change Directory" on the subscription](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-subscriptions-associated-directory#associate-a-subscription-to-a-directory).  The only way to restore them is to transfer your subscription back to the original AAD tenant and then re-create the role assignments again.  

This script will help you achieve this via parsing the Azure Activity Logs of your Subscription which have logs for each role assignment deleted during the original transfer.

## Prerequisites

1. Ensure you have transferred your Azure subscription back to it's original Azure AD tenant \ Owner, otherwise no role assignments can be restored.  Depending on how your subscription was originally transferred, follow [Subsription ownership transfers](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/billing-subscription-transfer) or  ["Change Directory" on the subscription](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-subscriptions-associated-directory#associate-a-subscription-to-a-directory) to transfer the subscription back to it's original directory \ owner.
2. Ensure you have Azure PowerShell installed: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps

## Restore Steps
1. Download [SelfService_RBAC_Restore.ps1](https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/SelfService_RBAC_Restore.ps1) locally to your workstation

2. Open PowerShell ISE and edit SelfService_RBAC_Restore.ps1
3. Update the line 6 to reflect your subscription ID.  Example: $AzureSubId = "f2ceb5da-e353-42f5-9a84-070cf6a78a9b"
4. Next confirm the general timeframe your subscription was transferred or role assignments were deleted by reviewing your subscription logs in the Azure Activity Log portal for your subscription (https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/activityLog)  and filtering by Subscription=SubscriptionID and by adding the new filter Operation=Delete role assignment)  Find the Timestamp listed as when the role assignments were deleted

Example of Azure Monitor Filter Parameters:
<img src="https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/Example_AzureMonitor_DeleteRoleAssignment.png">

Example of Azure Monitor Deleted Role Assignment -> JSON details
<img src="https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/Example_AzureMonitor_DeletedRoleAssignmentDetails.png">

5. Update line 9 and 10 from the script to reflect timeframe that role assignments were deleted.  Example: $fromDate = "2020-10-16" and $toDate = "2020-10-17".  

        
6. Finally, run the script and sign in with the subscription's current Owner\ Service Admin account.  This script will parse your subscription's activity log and restore all deleted role assignments found in the specified time period

7. Each restored role assignment will be output to the screen.  Depending on the number of role assignments it may take 5-10 minutes to complete.

Example of succesfull output:
<img src="https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/Example_RestoredRoleAssignment.png">

Example of restored role assignments after restoration:
<img src="https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/Example_RestoredRoleAssignments.png">

