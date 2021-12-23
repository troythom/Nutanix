#Create a New VM on Connected Cluster
#Utilize Nutanix Cmdlets v2.0 and Invoke-Restmethod

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 06-December-2021

Clear-Host

#Prompt for VM Details
#$PC = Read-Host -Prompt "Input the FQDN or IP Address for Prism Central"
#$Name = Read-Host -Prompt 'Input New VM Name'
#$Desc = Read-Host -Prompt "Enter the New VM Description Can Be Blank"
#$vCPU = Read-Host -Prompt "Enter the number of vCPUs for the New VM"
#$Mem = Read-Host -Prompt "Enter the amount of memory in GB for the new VM"

$PC = "10.42.157.42"
$Name = "test"
$Desc = "test"
$vCPU = "2"
$Mem = "4"

Clear-Host 

#Establish Prism Central Credentials
$Credential = Get-Credential

#Connect to prism Central
#Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600

#Setup Basic Header Info
$headers=@{}
$headers.Add("content-type", "application/json")
#$headers.Add("authorization", "Basic $Credential")

#Get List of Clusters
$URI = "https://" + $pc + ":9440/api/nutanix/v3/clusters/list"
$Clusters = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Authentication Basic -Credential $Credential -Method POST -Headers $headers -Body '{"kind":"cluster"}'

#Get List of Available Images
$URI = "https://" + $pc + ":9440/api/nutanix/v3/images/list"
$Images = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Method POST -Headers $headers -Authentication Basic -Credential $Credential -Body '{"kind":"image"}'

#Get List of Available Networks
$URI = "https://" + $pc + ":9440/api/nutanix/v3/subnets/list"
$Networks = Invoke-RestMethod -Uri $URI -SkipCertificateCheck -Method POST -Headers $headers -Authentication Basic -Credential $Credential -Body '{"kind":"subnet"}'

#Convert GB to MB
$Integer = [int]$Mem
$MemMB = $Integer*1024

#Print Out List of Clusters and Prompt for Cluster Name
Clear-Host
Write-Host "List of Available Clusters"
Write-Output -InputObject $Clusters.entities.spec.name
$DeployTo = Read-Host -Prompt "Input the Cluster Name where the VM will be deployed"

#Print Out List of Images and Prompt for UUID
Clear-Host
Write-Host "List of Available Images"
$Images | ForEach-Object -Process {Write-Output $_.entities.spec.name}
$ImageName = Read-Host -Prompt "Enter the name of the desired image"
$ImageUUID = Write-Output -InputObject $Images.entities.spec.
pause
$ImageUUID = Read-Host -Prompt "Copy the UUID of the desired image and input"

pause

#Get the Disk ID of the Image
$ImageInfo = Get-Image -ImageId $ImageUUID -IncludeVmDiskId
$ImageDiskID = $ImageInfo.vm_disk_id

#Create the New VM Disk Address
$cloneDiskAddress = New-NutanixObject VMDiskAddress
$cloneDiskAddress.vmdisk_uuid = $ImageDiskID

#Create the VM Disk Spec Clone
$vmDiskClone = New-NutanixObject VMDiskSpecClone
$vmDiskClone.disk_address = $cloneDiskAddress

#Create VMDisk Object
$vmDisk = New-NutanixObject VMDisk
$vmDisk.is_cdrom = $false
$vmDisk.vm_disk_clone=$vmDiskClone


#Print Out List of Networks and Prompt for UUID
Clear-Host
$Networks | ForEach-Object -Process {Write-Host $_.UUID $_.vlan_id $_.name}
$Net = Read-Host -Prompt "Copy the UUID of the desired network and input"

# Set NIC for VM on Requested vlan 
$nic = New-NutanixObject VMNicSpec
$nic.network_uuid = $Net
$nic.is_connected = $true

#Create the VM
Clear-Host
New-VM -ClusterName $DeployTo -Name $Name -NumVcpus $vCPU -Description $Desc -MemoryMb $MemMB -VMDisks $vmDisk -VmNics $nic | Wait-Task

#Find the VM ID and Power On

$vm = Get-VM | Where-Object {$_.vmName -eq $Name}
$vmID = $vm.uuid 

Start-VM $vmID | Wait-Task