#Create a New VM on Connected Cluster
#Utilize Nutanix Cmdlets v2.0

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 03-December-2021

Clear-Host

#Prompt for VM Details
$PC = Read-Host -Prompt "Enter the FQDN or IP Address of the Prism Central Instance"
$Name = Read-Host -Prompt 'Input New VM Name'
$Desc = Read-Host -Prompt "Enter the New VM Description Can Be Blank"
$vCPU = Read-Host -Prompt "Enter the number of vCPUs for the New VM"
$Mem = Read-Host -Prompt "Enter the amount of memory in GB for the new VM"

#Establish Prism Central Credentials
$Credential = Get-Credential

#Connect to prism Central
Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600

#Get List of Clusters
$Clusters = Get-Cluster

#Get List of Available Images
$Images = Get-Image

#Get List of Available Networks
$Networks = Get-Network

#Convert GB to MB
$Integer = [int]$Mem
$MemMB = $Integer*1024

#Print Out List of Clusters and Prompt for Cluster Name
Clear-Host
$Clusters | ForEach-Object -Process {Write-Host $_.ClusterName}
$DeployTo = Read-Host -Prompt "Enter the cluster name where you will deploy the new VM"

#Print Out List of Images and Prompt for UUID
Clear-Host
$Images | ForEach-Object -Process {Write-Host $_.uuid $_.name}
$ImageUUID = Read-Host -Prompt "Copy and enter the UUID of the desired image"

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

Disconnect-PrismCentral -Servers *






