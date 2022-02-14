Param(
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$website_name,
    [parameter(Mandatory = $true)]
    [string]$user_id,
    [parameter(Mandatory = $true)]
    [SecureString]$password,
    [parameter(Mandatory = $true)]
    [string]$cert_path
)

$display_action = 'IIS Website Status'
$display_action_past_tense = "$display_action$past_tense Returned"

Write-Output $display_action

$credential = [PSCredential]::new($user_id, $password)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

if ($cert_path.Length -gt 0) {
    Write-Output "Importing remote server cert..."
    Import-Certificate -Filepath $cert_path -CertStoreLocation 'Cert:\LocalMachine\Root'
}

$script = {
    # Relies on WebAdministration Module being installed on the remote server
    # This should be pre-installed on Windows 2012 R2 and later
    # https://docs.microsoft.com/en-us/powershell/module/?term=webadministration

    $website = Get-IISSite -Name $Using:website_name
    if (!$website) {
        Return 1
        Exit
    }

    Return $($website.State)
}

$script_result = Invoke-Command -ComputerName $server `
    -Credential $credential `
    -UseSSL `
    -SessionOption $so `
    -ScriptBlock $script

If ($script_result -and $script_result -eq 1) {
    Write-Output "IIS Site Status Error"
    Write-Output "::set-output name=website-status::IIS Site Status Error"
    Exit 1
}
else {
    Write-Output "$display_action_past_tense."
    Write-Output "::set-output name=website-status::$script_result"
}