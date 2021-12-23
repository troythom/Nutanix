#Create a New VM on Connected Cluster
#Utilize Nutanix Cmdlets v2.0
#Assumes user has already connected to the proper Prism Central Instance using Connect-PrismCentral

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 03-December-2021

clear

#Prompt for VM Details
$Name = Read-Host -Prompt 'Input New VM Name'
$Desc = Read-Host -Prompt "Enter the New VM Description Can Be Blank"
$vCPU = Read-Host -Prompt "Enter the number of vCPUs for the New VM"
$Mem = Read-Host -Prompt "Enter the amount of memory in GB for the new VM"

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
clear
$Clusters | ForEach-Object -Process {Write-Host $_.ClusterName}
$DeployTo = Read-Host -Prompt "Copy the Desired Cluster Name and input"

#Print Out List of Images and Prompt for UUID
clear
$Images | ForEach-Object -Process {Write-Host $_.uuid $_.name}
$ImageUUID = Read-Host -Prompt "Copy the UUID of the desired image and input"

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
clear
$Networks | ForEach-Object -Process {Write-Host $_.UUID $_.vlan_id $_.name}
$Net = Read-Host -Prompt "Copy the UUID of the desired network and input"

# Set NIC for VM on Requested vlan 
$nic = New-NutanixObject VMNicSpec
$nic.network_uuid = $Net
$nic.is_connected = $true

#Create the VM
clear
New-VM -ClusterName $DeployTo -Name $Name -NumVcpus $vCPU -Description $Desc -MemoryMb $MemMB -VMDisks $vmDisk -VmNics $nic | Wait-Task

#Find the VM ID and Power On

$vm = Get-VM | where {$_.vmName -eq $Name}
$vmID = $vm.uuid 

Start-VM $vmID | Wait-Task