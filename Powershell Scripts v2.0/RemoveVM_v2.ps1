#Remove a VM 
#Utilize Nutanix Cmdlets v2.0

#Created by Troy Thompson
#troy.thompson@nutanix.com
#Created - 03-December-2021

Clear-Host

#Establish Prism Central Credentials
$Credential = Get-Credential

#Connect to prism Central
Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600

#Prompt for VM Details
$Name = Read-Host -Prompt 'Input Name of VM to be Removed'

#Find the VM ID and Remove

$vm = Get-VM | where {$_.vmName -eq $Name}
$vmID = $vm.uuid 

Remove-VM $vmID | Wait-Task

Disconnect-PrismCentral -Servers *
