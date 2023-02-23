param (
	[Parameter(Mandatory=$true)]
	[string]$Server,

	[Parameter(Mandatory=$true)]
	[string]$User,

	[Parameter(Mandatory=$false)]
	[int]$Port=3389,

	[Parameter(Mandatory=$false)]
	[switch]$UseAllMonitors=$false
)

# print banner
Write-Host @"
#########################
#  RDP helper for xrdp  #
#########################

[*] Connection details:
      user = ${User}
    server = ${Server}
      port = ${Port}
"@

# flag for multiple monitors
if ($UseAllMonitors) { $multiMonFlag = "/multimon" } else { $multiMonFlag = "" }

# cmdkey key
$keyName = "TERMSRV/${Server}"	

# prompt for creds
$cred = Get-Credential -Credential $User
$username = $cred.GetNetworkCredential().username
$passwd = $cred.GetNetworkCredential().password

# wrap in try-finally to always clear cmdkey
try
{
	# cache creds
	cmdkey /generic:$keyName /user:$user /pass:$passwd
	
	# connect to rdp using chached creds
	mstsc /v:"${Server}:${Port}" $multiMonFlag

	# wait before clearing creds so mstsc.exe has time to use them
	Start-Sleep -s 10
}
finally
{
	# always clear creds from cache
	cmdkey /delete:$keyName
}