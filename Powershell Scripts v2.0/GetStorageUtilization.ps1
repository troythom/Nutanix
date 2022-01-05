#Retrieve Container Utilization Statistics (Derive "Allocated" Space)
#Utilize Nutanix Cmdlets v2.0 and Rest API v3.0 (Prism Central) and v2.0 (Prism Element)

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 07-December-2021
#Updated - 05-January-2022

#Setup Mandatory Parameters
param (
    [Parameter(Mandatory=$true)][string]$PCvIP
    #[Parameter(Mandatory=$true)][string]$TargetCluster
)

#Setup Basic Header Info
$headers=@{}
$headers.Add("content-type", "application/json")

#Establish Prism Central Credentials
Clear-Host
$Credential = Get-Credential

#Get List of Clusters
$URI = "https://" + $PCvIP + ":9440/api/nutanix/v3/clusters/list"
$Clusters = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"cluster"}'

$ClusterVips = Write-Output -InputObject $Clusters.entities.spec.resources.network.external_ip

Clear-Host
Write-Host "List of Cluster Virtual IP Addresses"
Write-Output -InputObject $ClusterVips
$TargetCluster = Read-Host -Prompt "Enter the Prism Element Cluster vIP to Analyze"

#Get list of Storage Containers
$PEURI = "https://" + $TargetCluster + ":9440/PrismGateway/services/rest/v2.0/storage_containers"
$ContanierResponse = Invoke-RestMethod -Uri $PEURI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method GET 

#Place the results of each desired value into an array
[array]$ContName = $ContanierResponse.entities.name
[array]$MaxCap = $ContanierResponse.entities.max_capacity
[array]$LogicalUsed = $ContanierResponse.entities.usage_stats."storage.user_unreserved_own_usage_bytes"
[array]$TotalReduce = $ContanierResponse.entities.usage_stats."data_reduction.overall.user_saved_bytes"

#Cleanup any old files
$fileToCheck = "c:\TEMP\$targetCluster.csv"
        if (Test-Path $fileToCheck -PathType leaf)
        {
            Remove-Item $fileToCheck
        }

#Export the contents of each array into a custom object and then export to CSV with individual rows
0..($ContName.Count-1) | ForEach-Object {
    [pscustomobject]  @{
        "Container_Name" = $ContName[$_]
        "Maximum_Capacity" = $MaxCap[$_]
        "Logical_Space_Used" = $LogicalUsed[$_]
        "Total_Reduction" = $TotalReduce[$_]
    }
} | Export-Csv -Path c:\TEMP\$TargetCluster.csv -NoTypeInformation
