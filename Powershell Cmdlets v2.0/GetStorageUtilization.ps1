#Retrieve Container Utilization Statistics (Derive "Allocated" Space)
#Utilize Nutanix Cmdlets v2.0 and Rest API v2.0

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 07-December-2021

Clear-Host

#Prompt for Environment Info
$PC = Read-Host -Prompt "Enter the FQDN or IP Address of the Prism Central Instance"

#Setup Basic Header Info
$headers=@{}
$headers.Add("content-type", "application/json")

#Establish Prism Central Credentials
$Credential = Get-Credential

#Connect to prism Central
#Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600

#Get List of Clusters
$URI = "https://" + $PC + ":9440/api/nutanix/v3/clusters/list"
$Clusters = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"cluster"}'

$ClusterVips = Write-Output -InputObject $Clusters.entities.spec.resources.network.external_ip

Clear-Host
Write-Host "List of Cluster Virtual IP Addresses"
Write-Output -InputObject $ClusterVips
$TargetCluster = Read-Host -Prompt "Enter the Cluster vIP to Analyze"

#Get list of Storage Containers
$PEURI = "https://" + $TargetCluster + ":9440/PrismGateway/services/rest/v2.0/storage_containers"
$ContanierResponse = Invoke-RestMethod -Uri $PEURI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method GET 


$Metrics = foreach ($temp in $ContanierResponse) {
    [pscustomobject] @{
        Container_Name = $temp.entities.name -join ', '
        Max_Capacity = $temp.entities.max_capacity -join ', '
        Logical_Used_Bytes = $temp.entities.usage_stats."storage.user_unreserved_own_usage_bytes" -join ', '
        Total_Reduction_Bytes = $temp.entities.usage_stats."data_reduction.overall.user_saved_bytes" -join ', '
    } | Select-Object -Property Container_Name, Max_Capacity, Logical_Used_Bytes, Total_Reduction_Bytes 
}

# Working in Progress export to CSV or TXT File

$fileToCheck = "c:\TEMP\metrics.csv"
        if (Test-Path $fileToCheck -PathType leaf)
        {
            Remove-Item $fileToCheck
        }

Export-Csv -InputObject $Metrics -Path c:\TEMP\metrics.csv  


#Invoke-Item c:\TEMP\metrics.csv


