#Connect to Prism Central
#Utilize Nutanix Cmdlets v2.0

#Prompt for Environment Inputs
$PC = Read-Host -Prompt 'Input FQDN or IP Address of the target Prism Central Instance'
$PCUser = Read-Host -Prompt 'Input PC User ID'
$Password = Read-Host -Prompt 'Input PC User Password'

#Set the Credentials
$SecurePW = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($PCUser, $SecurePW);

#Connect
Connect-PrismCentral -Server $PC -AcceptInvalidSSLCerts -Credential $Credential -ForcedConnection -SessionTimeoutSeconds 3600


