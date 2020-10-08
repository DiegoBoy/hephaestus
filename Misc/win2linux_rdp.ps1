function cacheCredsPromptUI {
	param (
		[Parameter(Mandatory=$true)]
		[string]$CmdKeyName,

		[Parameter(Mandatory=$false)]
		[string]$DefaultUser
	)

	# prompt creds
	$cred = Get-Credential -Credential "$DefaultUser"
	$user = $cred.GetNetworkCredential().username
	$passwd = $cred.GetNetworkCredential().password

	# cache creds
	cmdkey /generic:$CmdKeyName /user:$user /pass:$passwd
}

function cacheCredsPromptTextOnly {
	param (
		[Parameter(Mandatory=$true)]
		[string]$CmdKeyName,

		[Parameter(Mandatory=$false)]
		[string]$DefaultUser
	)

	# prompt and cache creds
	if (($user = Read-Host "username [$DefaultUser]") -eq '') { $user = $DefaultUser }
	cmdkey /generic:$CmdKeyName /user:$user /pass
}

Write-Host "#########################"
Write-Host "#  RDP helper for xrdp  #"
Write-Host "#########################"
Write-Host

# prompt for RDP settings and creds
$server = Read-Host "Hostname or IP"
if (($port = Read-Host "Port [3389]") -eq '') { $port = 3389 }
if (($multiMon = Read-Host "Use all monitors [false]") -ne '') { $multiMon = "/multimon" }

try
{
	# cache creds
	$keyName = "TERMSRV/$server"
	#cacheCredsPromptTextOnly -CmdKeyName $keyName -DefaultUser "db"
	cacheCredsPromptUI -CmdKeyName $keyName -DefaultUser "db"

	# remote-in using chached creds
	mstsc /v:"${server}:${port}" $multiMon

	# wait before clearing creds so mstsc.exe has time to use them
	Start-Sleep -s 10
}
finally
{
	# always clear creds from cache
	cmdkey /delete:$keyName
}