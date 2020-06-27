function Download-AzureCert {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string] $vaultName,
    [Parameter(Mandatory)]
    [string] $certName,
    [Parameter()]
    [string] $pfxName=$certName,
    [Parameter()]
    [string] $password
  )
  Write-Host "Downloading [${vaultName}]->[${certName}]"
  $cert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certName
  $secret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $cert.Name
  $secretByte = [Convert]::FromBase64String($secret.SecretValueText)
  $x509Cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
  $x509Cert.Import($secretByte, "", "Exportable,PersistKeySet")
  $type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
  $pfxFileByte = $x509Cert.Export($type, $password)

  # Write to a file
  Write-Host "Writing to file [${pfxName}.pfx]"
  [System.IO.File]::WriteAllBytes("${pfxName}.pfx", $pfxFileByte)
}