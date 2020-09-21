# SelfService_RBAC_Restore
If you perform any operation on your Azure Subscription which causes it to switch AAD tenants, you will lose all RBAC role assignments during the transfer.  The most common ways this occurs is via [Subsription ownership transfers](https://docs.microsoft.com/en-us/azure/cost-management-billing/manage/billing-subscription-transfer) or Subscription owner's choosing ["Change Directory" on the subscription](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-subscriptions-associated-directory#associate-a-subscription-to-a-directory).  The only way to restore them is to transfer your subscription back to the original AAD tenant and then re-create the role assignments again.  

This script will help you achieve this via parsing the Azure Activity Logs which have logs for each role assignment deleted during the original transfer.

## Prerequisites

1. Ensure you have Azure PowerShell installed: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps
2. Download [SelfService_RBAC_Restore.ps1](https://github.com/jasonfritts/SelfService_RBAC_Restore/blob/master/SelfService_RBAC_Restore.ps1) and then update the following to match your subscription ID
Connect-AzAccount -Subscription "00000000-0000-0000-0000-000000000000"

3. Next confirm the general timeframe your subscription was transferred, so the Azure Activity Logs can be parsed for deleted role assignments in that timeframe and update the following lines from the script: $fromDate = "2020-09-21T10:00"
$toDate = "2020-09-21T19:00"

4. Finally, run the script and sign in with the subscription's current Owner\ Service Admin account.  This script will parse your subscription's activity log and restore all deleted role assignments
