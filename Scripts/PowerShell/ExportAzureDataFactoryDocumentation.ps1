<#
.History
   21/07/2020 - 1.0 - Initial release - David Alzamendi
.Synopsis
   Export Azure Data Factory V2 information using Power Shell cmdlets
.DESCRIPTION
    This script export the Azure Data factory V2 information using the following cmdlets
    Pre-requirements:
                    AzModule ----> Install-Module -Name Az 
                    Be connected to Azure ----> Connect-AzAccount 
    APIs documentation is available in https://docs.microsoft.com/en-us/powershell/module/az.datafactory/?view=azps-4.2.0#data_factories
    Module descriptions are in https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.commands.datafactoryv2.models?view=azurerm-ps

.EXAMPLE
   ExportAzureDataFactoryDocumentation -TenantId "XXXXXX-XXXXXX-XXXXXX-XXXXXX"
#>
    Param
    (
        # Tenant Id
        [Parameter(Mandatory=$true)]
        $TenantId,
        # Define folder name
        [Parameter(Mandatory=$true)]
        $OutputFolder
    )

    Begin
    {
        write-host "Starting tenant" $TenantId

        # Define file names
        $ADFOutputFile = $OutputFolder + "ADF_$(get-date -f yyyyMMdd).csv"
        $ADFDataflowOutputFile = $OutputFolder + "ADF_Dataflows_$(get-date -f yyyyMMdd).csv"
        $ADFDatasetsOutputFile = $OutputFolder + "ADF_Datasets_$(get-date -f yyyyMMdd).csv"
        $ADFLinkedServiceOutputFile = $OutputFolder + "ADF_LinkedServices_$(get-date -f yyyyMMdd).csv"
        $ADFPipelineOutputFile = $OutputFolder + "ADF_Pipelines_$(get-date -f yyyyMMdd).csv"
        $ADFTriggerOutputFile = $OutputFolder + "ADF_Triggers_$(get-date -f yyyyMMdd).csv"
        $ADFIntegrationRuntimeOutputFile = $OutputFolder + "ADF_IntegrationRuntimes_$(get-date -f yyyyMMdd).csv"
        $ADFIntegrationRuntimeMetricOutputFile = $OutputFolder + "ADF_IntegrationRuntimeMetrics_$(get-date -f yyyyMMdd).csv"
        $ADFIntegrationRuntimeNodeOutputFile = $OutputFolder + "ADF_IntegrationRuntimeNodes_$(get-date -f yyyyMMdd).csv"

        # Connect to Azure
        # Connect-AzAccount -Tenant $TenandId

        $adflist = Get-AzDataFactoryV2 

        # Define function for hash tables like tags or nodes
         function Resolve-Hashtable {
                param (
                    $Collection
                )
                if($Collection.Keys -gt 0) {
                    $KeyArray = @()
                    $Collection.Keys | ForEach-Object {
                        $KeyArray += "[$_ | $($Collection[$_])] "
                    }
                } else {
                    $KeyArray = ''
                }
                [string]$KeyArray
            }
         # Define function for pipelines parameters hash table
         function Resolve-Hashtable-Pipelines {
                param (
                    $Collection
                )
                if($Collection.Keys -gt 0) {
                    $KeyArray = @()
                    $Collection.Keys | ForEach-Object {
                        $KeyArray += "[$_] "
                    }
                } else {
                    $KeyArray = ''
                }
                [string]$KeyArray
            }

        # Define function for pipeline lists 
         function Resolve-List-Pipelines {
                param (
                    $List
                )
                if($List.Count -gt 0) {
                    for ($i = 0; $i -lt $List.Count; $i++)
                    { 
                                                                 
                        $KeyString += "["+ $List.Item($i).Name + " | " + $List.Item($i) + " | "  + $List.Item($i).Description + "]"
                                                  
                        $KeyString = $KeyString.replace("Microsoft.Azure.Management.DataFactory.Models.","")

                    }

                    
                } else {
                    $KeyString = ''
                }
                [string]$KeyString
            }

    }
    Process
    {
      
        # Start
        foreach ($adfname in $adflist)

        {

            Write-host "Starting data factory"  $adfname.DataFactoryName
            # Get-AzDataFactoryV2	
            # Gets information about Data Factory.
            Get-AzDataFactoryV2 -ResourceGroupName $adfname.ResourceGroupName -Name $adfname.DataFactoryName `
            | Select-Object  ResourceGroupName,DataFactoryName,Location,@{Name = 'Tags'; Expression = {Resolve-Hashtable($_.Tags)}} `
            | Export-Csv -Append -Path  $ADFOutputFile -NoTypeInformation

    

            # Get-AzDataFactoryV2DataFlow	
            # Gets information about data flows in Data Factory.
            # 21/07/2020 Mapping Data Flows are not available for factories in the following regions: West Central US, Australia Southeast. 
            # To use this feature, please create a factory in a supported region.
            Write-host "Exporting" $adfname.DataFactoryName "Data flows"

            try 
            {
                Get-AzDataFactoryV2DataFlow -ErrorAction Stop -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName `
                | Select-Object ResourceGroupName,DataFactoryName,@{L=’DataFlowName’;E={$_.Name}}, @{L=’DataFlowType’;E={$_.Properties -replace "Microsoft.Azure.Management.DataFactory.Models.",""}}   `
                | Export-Csv -Append -Path $ADFDataflowOutputFile -NoTypeInformation -ErrorAction Stop
            }
            catch
            {
                Write-host "Data Flows are not available for factories in the following regions: West Central US, Australia Southeast."
            }
    
            # Get-AzDataFactoryV2Dataset	
            # Gets information about datasets in Data Factory.
            Write-host "Exporting" $adfname.DataFactoryName "Data sets"

            Get-AzDataFactoryV2Dataset -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName `
            | Select-Object  ResourceGroupName,DataFactoryName,@{L=’DatasetName’;E={$_.Name}}, @{L=’DatasetType’;E={$_.Properties -replace "Microsoft.Azure.Management.DataFactory.Models.",""}}  `
            | Export-Csv -Append -Path $ADFDatasetsOutputFile  -NoTypeInformation


            # Get-AzDataFactoryV2IntegrationRuntime	
            # Gets information about integration runtime resources.
            # Nodes column is available, but they are not being populated
            Write-host "Exporting" $adfname.DataFactoryName "Integration runtimes"

            Get-AzDataFactoryV2IntegrationRuntime  -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName -Status `
            | Select-Object ResourceGroupName,DataFactoryName,@{L=’IntegrationRuntimeName’;E={$_.Name}},@{L=’IntegrationRuntimeType’;E={$_.Type}},Description,State,CreateTime,AutoUpdate,ScheduledUpdateDate,Version,VersionStatus,LatestVersion,PushedVersion `
            | Export-Csv -Append -Path $ADFIntegrationRuntimeOutputFile -NoTypeInformation

            $irlist = Get-AzDataFactoryV2IntegrationRuntime -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName
    
            foreach ($irname in $irlist)
            {
                # Integration Runtime needs to be online to capture further information
                if($irname.state -eq "Online" -or $irname.state -eq "Starting" -or $irname.Type -eq "SelfHosted")
                      {
                        # Get-AzDataFactoryV2IntegrationRuntimeMetric	
                        # Gets information about integration runtime metrics.
                        Write-host "Exporting" $adfname.DataFactoryName "Integration runtime metrics" $irname.Name 
                 
                        Get-AzDataFactoryV2IntegrationRuntimeMetric -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName $irname.Name `
                        | Select-Object ResourceGroupName,DataFactoryName,@{Name = 'Nodes'; Expression = {Resolve-Hashtable($_.Nodes) }} `
                        | Export-Csv -Append -Path $ADFIntegrationRuntimeMetricOutputFile -NoTypeInformation 
    
                
                        $metrics = Get-AzDataFactoryV2IntegrationRuntimeMetric -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName $irname.Name

                            foreach ($metricname in $irname.Nodes)
                            {
        
                               try 
                               {
                                        # Get-AzDataFactoryV2IntegrationRuntimeNode	
                                        # Gets an integration runtime node information.
                                        Write-host "Exporting" $adfname.DataFactoryName "Integration runtime" $irname.Name " node" $metricname.NodeName

                                        Get-AzDataFactoryV2IntegrationRuntimeNode -ErrorAction Stop -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName -IntegrationRuntimeName $irname.Name -IpAddress -Name $metricname.NodeName `
                                        | Select-Object ResourceGroupName,DataFactoryName, IntegrationRuntimeName,@{L=’NodeName’;E={$_.Name}},Status,MachineName,VersionStatus,Version,IPAddress,ConcurrentJobsLimit `
                                        | Export-Csv -Append -Path $ADFIntegrationRuntimeNodeOutputFile -NoTypeInformation 
                                        }
                                catch
                                {
                                    write-host "Impossible to retrieve information from" $metricname.NodeName
                                    # Add-Content -Path -Append $ADFIntegrationRuntimeNodeOutputFile -NoTypeInformation -Value "$adfname.ResourceGroupName,$adfname.DataFactoryName,$irname.Name,$metricname.NodeName,Unreachable"
                                    $Unreachable = "{0},{1},{2},{3},{4}" -f $adfname.ResourceGroupName,$adfname.DataFactoryName,$irname.Name,$metricname.NodeName,"Unreachable"
                                    $Unreachable | add-content -path $ADFIntegrationRuntimeNodeOutputFile

                                }

                            }
                        }

           }
       

            # Get-AzDataFactoryV2LinkedService	
            # Gets information about linked services in Data Factory.
            Write-host "Exporting" $adfname.DataFactoryName "Linked services"

            Get-AzDataFactoryV2LinkedService -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName  `
            | Select-Object ResourceGroupName,DataFactoryName,@{L=’LinkedServiceName’;E={$_.Name}}, @{L=’LinkedServiceType’;E={$_.Properties -replace "Microsoft.Azure.Management.DataFactory.Models.",""}} `
            | Export-Csv -Append -Path $ADFLinkedServiceOutputFile -NoTypeInformation
    

            # Get-AzDataFactoryV2Pipeline	
            # Gets information about pipelines in Data Factory.
            Write-host "Exporting" $adfname.DataFactoryName "Pipelines"

            Get-AzDataFactoryV2Pipeline -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName `
            | Select-Object ResourceGroupName,DataFactoryName,@{L=’PipelineName’;E={$_.Name}}, @{Name = 'Activities'; Expression = {Resolve-List-Pipelines($_.Activities)}} , @{Name = 'Parameters'; Expression = {Resolve-Hashtable-Pipelines($_.Parameters)} } `
            | Export-Csv -Append -Path $ADFPipelineOutputFile -NoTypeInformation
            
        

            # Get-AzDataFactoryV2Trigger	
            # Gets information about triggers in a data factory.
            Write-host "Exporting" $adfname.DataFactoryName "Triggers"

            Get-AzDataFactoryV2Trigger -ResourceGroupName $adfname.ResourceGroupName -DataFactoryName $adfname.DataFactoryName `
            | Select-Object ResourceGroupName,DataFactoryName,@{L=’TriggerName’;E={$_.Name}}, @{L=’TriggerType’;E={$_.Properties -replace "Microsoft.Azure.Management.DataFactory.Models.",""}},@{L=’TriggerStatus’;E={$_.RuntimeState}} `
            |  Export-Csv -Append -Path $ADFTriggerOutputFile -NoTypeInformation
          
           
        }
        # End

    }
    End
    {
        write-host "Finish tenant" $TenantId
    }
