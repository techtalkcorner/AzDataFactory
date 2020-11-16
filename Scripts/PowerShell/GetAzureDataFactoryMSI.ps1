# This scripts returns the Azure Data Factory MSI to give access to your service
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

# Copy the following user and give it access in Azure Analysis Services
Write-Host "app:$ApplicationId@$TenantId"