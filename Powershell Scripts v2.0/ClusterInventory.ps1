#Name:  ClusterInventory.ps1
#Version:  1.0
#Created By: Troy Thompson
#troy.thompson@nutanix.com
#Created - 06-December-2021

#Utilize Nutanix Cmdlets v2.0
#Utilize Nutanix APIs v2.0 (PE) and v3.0 (PC)

# Setup Parameters
Param(
    [Parameter(Mandatory = $true)][string]$PCvIP
)

#Setup Basic Header Info
$headers=@{}
$headers.Add("content-type", "application/json")

#Establish Prism Central Credentials
Clear-Host
$Credential = Get-Credential

#Gather Base Information on Clusters, Hosts and VMs

#Get List of Clusters Registered to the Prism Central Instance
$URI = "https://" + $PCvIP + ":9440/api/nutanix/v3/clusters/list"
$Clusters = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"cluster"}'

#Get list of Hosts managed by the Prism Central Instance
$URI = "https://" + $PCvIP + ":9440/api/nutanix/v3/hosts/list"
$Hosts = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"host"}'

#Get List of VMs managed by the Prsim Central Instance
$URI = "https://" + $PCvIP + ":9440/api/nutanix/v3/vms/list"
$VMS = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{
    "kind":"vm",
    "offset": 0,
    "length": 2500
}'


#Main Program
#Step 1 - Collect and Report Cluster Information
$ClusterFullReport = @()
Foreach ($entity in $Clusters.entities) {
    $props = [ordered]@{
    "Cluster Name"                          = $entity.status.name
    "Cluster uuid"                          = $entity.metadata.uuid
    "NOS Version"                           = $entity.status.resources.config.software_map.NOS.version
    "Redundancy Factor"                     = $entity.status.resources.config.redundancy_factor
    "Domain Awareness Level"                = $entity.status.resources.config.domain_awareness_level
    "Long Term Support"                     = $entity.status.resources.config.build.is_long_term_support
    "Timezone"                              = $entity.status.resources.config.timezone
    "External Ip"                           = $entity.status.resources.network.external_ip
    "Hypervisor"                            = $entity.status.resources.nodes.hypervisor_server_list.type | Select-Object -Unique
    }
    $ClusterReportobject = New-Object PSObject -Property $props
    $Clusterfullreport += $ClusterReportobject
}
$ClusterCsvFile = "c:\TEMP\Clusters_$(Get-Date -UFormat "%Y_%m_%d_%H_%M_").csv"
$Clusterfullreport | Export-Csv -Path $ClusterCsvFile -NoTypeInformation -UseCulture -verbose:$false

#Step 2 - Collect and Report Host Information

$HostsFullReport = @()
Foreach ($entity in $Hosts.entities) {
    $props = [ordered]@{
    "Host Name"                     =$entity.status.name
    "Host uuid"                     =$entity.metadata.uuid
    "State"                         =$entity.status.state
    "Serial Number"                 =$entity.status.resources.serial_number
    "IP"                            =$entity.status.resources.ipmi.ip
    "Host Type"                     =$entity.status.resources.host_type
    "CPU Model"                     =$entity.status.resources.cpu_model 
    "Number of CPU Sockets"         =$entity.status.resources.num_cpu_sockets 
    "Number of CPU Cores"           =$entity.status.resources.num_cpu_cores 
    "Rackable Unit Ref uuid"        =$entity.status.resources.rackable_unit_reference.uuid
    "Cluster Kind"                  =$entity.status.cluster_reference.kind 
    "Cluster uuid"                  =$entity.status.cluster_reference.uuid
    "CVM Oplog Disk Size"           =$entity.spec.resources.controller_vm.oplog_usage.oplog_disk_size
    }
    $HostsReportobject = New-Object PSObject -Property $props
    $Hostsfullreport += $HostsReportobject
}
$HostCsvFile = "c:\TEMP\Hosts_$(Get-Date -UFormat "%Y_%m_%d_%H_%M_").csv"
$Hostsfullreport | Export-Csv -Path $HostCsvFile -NoTypeInformation -UseCulture -verbose:$false

#Step 3 - Collect and Report VM Information

$VMInventory = @()
foreach ($vm in $VMS.entities) {
        $URIVM = "https://" + $PCvIP + ":9440/api/nutanix/v3/vms/$($vm.metadata.uuid)"
        Invoke-RestMethod -Uri $URIVM -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method GET -Headers $headers
        $myvmdetails = Invoke-RestMethod -Uri $URIVM -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method GET -Headers $headers
        if ($null -eq ($myvmdetails.status.resources.host_reference.uuid)) {
            $hostname = ""
            }
            else {
                $URIHOST = "https://" + $PCvIP + ":9440/api/nutanix/v3/hosts/$($myvmdetails.status.resources.host_reference.uuid)"
                $myhostdetails = Invoke-RestMethod -Uri $URIHOST -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method GET -Headers $headers
                $hostname = $myhostdetails.status.name
            }        
$props = [ordered]@{
"VM Name"                       = $vm.spec.Name
"VM uuid"                       = $vm.metadata.uuid
"VM Host"                       = $hostname
"VM Host uuid"                  = $myvmdetails.status.resources.host_reference.uuid
"Cluster Name"                  = $myvmdetails.status.cluster_reference.name
"Cluster UUID"                  = $myvmdetails.spec.cluster_reference.uuid
"Power State"                   = $myvmdetails.status.resources.power_state
"Network Name"                  = $myvmdetails.status.resources.nic_list.subnet_reference.name
"IP Address(es)"                = $myvmdetails.status.resources.nic_list.ip_endpoint_list.ip -join ", "
"Number of Cores"               = $myvmdetails.spec.resources.num_sockets
"Number of vCPUs per core"      = $myvmdetails.spec.resources.num_vcpus_per_socket
"VM Time Zone"                  = $myvmdetails.spec.resources.hardware_clock_timezone
} #End properties
$Reportobject = New-Object PSObject -Property $props
$VMInventory += $Reportobject
}
$VMInventory | Export-Csv -Path "c:\Temp\VMInventory$(Get-Date -UFormat "%Y_%m_%d_%H_%M_").csv" -NoTypeInformation -UseCulture -verbose:$false



