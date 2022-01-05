#Connect to Prism Central
#Utilize Nutanix Cmdlets v2.0

#Prompt for Environment Inputs
#$PC = Read-Host -Prompt 'Input FQDN or IP Address of the target Prism Central Instance'

#Setup Mandatory Parameters
param (
    [Parameter(Mandatory=$true)][string]$PCvIP
)

#Set the Credentials
$Credential = Get-Credential

#Connect to prism Central
Connect-PrismCentral -Server $PCvIP -AcceptInvalidSSLCerts -Credential $credential -ForcedConnection -SessionTimeoutSeconds 3600
