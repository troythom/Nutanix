#Get Stats on a Storage Container
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
Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600

#Get List of Clusters
$URI = "https://" + $PC + ":9440/api/nutanix/v3/clusters/list"
$Clusters = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"cluster"}'

$ClusterVips = Write-Output -InputObject $Clusters.entities.spec.resources.network.external_ip

$ClusterVips

