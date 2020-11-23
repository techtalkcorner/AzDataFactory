# This scripts returns the Azure Data Factory managed identity to give access to other Azure service
# Install module Azure if it is not available
# Install-module Az
# Pre-requisite, connect to your Azure account
# Connect-AzAccount
$AzureDataFactoryName = ""
$ResourceGroupName = ""

$TenantId= (Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName  -Name $AzureDataFactoryName).Identity.TenantId
$PrincipalId= (Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName  -Name $AzureDataFactoryName).Identity.PrincipalId
$ApplicationId = Get-AzADServicePrincipal -ObjectId $PrincipalId
$ApplicationId =($ApplicationId).ApplicationId

write-host "The application Id is: " $ApplicationId
write-host "The object Id is: " $PrincipalId

# Copy the following user and give it access in Azure Analysis Services
write-host "If giving access this service to your Azure Analysis Services, copy the following string:"
Write-Host "app:$ApplicationId@$TenantId"
