#Remove a VM from Connected Cluster
#Utilize Nutanix Cmdlets v2.0
#Assumes user has already connected to the proper Prism Central Instance using Connect-PrismCentral

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 03-December-2021

clear

#Prompt for VM Details
$Name = Read-Host -Prompt 'Input Name of VM to be Removed'

#Find the VM ID and Remove

$vm = Get-VM | where {$_.vmName -eq $Name}
$vmID = $vm.uuid 

Remove-VM $vmID | Wait-Task
