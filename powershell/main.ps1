Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

. .\scriptblock.ps1
. .\nx.ps1
function  Credential-Object {
    param (
        [string]$user,
        [string]$pass

    )
$pass = ConvertTo-SecureString $pass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
return $cred

}



#Send-JsonPayload -Url $targetUrl -Payload $payload
