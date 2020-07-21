# AzDataFactory
Azure Data Factory information

## Export Azure Data Factory information to files
### Download the script
Get the script from the following link.

https://github.com/techtalkcorner/AzDataFactory/blob/master/Scripts/PowerShell/ExportAzureDataFactoryDocumentation.ps1

### Pre-requirements 

Before you can run the script, you need to download the Az Module and log into the Azure tenant. 

Install-Module -Name Az 

Connect-AzAccount 

### EXECUTE SCRIPT 
The script only has 1 parameter (TenantId). To execute the script, run the following command: 

.\ExportAzureDataFactoryDocumentation.ps1 -TenantId XXXXX-XXXXX-XXXXX-XXXXX -OutputFolder "C:\SampleFolder\"
