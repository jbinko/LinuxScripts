 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$webProxy,
	 [Parameter(Mandatory=$True,Position=2)]
	 [string]$domainName,
	 [Parameter(Mandatory=$True,Position=3)]
	 [string]$domainNetbiosName,
	 [Parameter(Mandatory=$True,Position=4)]
	 [string]$adPasswordText,
	 [Parameter(Mandatory=$True,Position=5)]
	 [string]$certPassword
 )

# Set proxy				
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxySettingsPerUser /t REG_DWORD /d 0 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyEnable /t REG_DWORD /d 1 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyServer /t REG_SZ /d $webProxy /f
netsh winhttp set proxy $webProxy

# Disable FW
Set-NetFirewallProfile -Profile Domain,Private -Enabled False

# Prepare AD Data Disk
Get-Disk -Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "Active Directory Data Disk" -Force -Confirm:$false

# Install and configure AD
Install-WindowsFeature AD-Domain-Services
Install-WindowsFeature RSAT-AD-Tools
Install-WindowsFeature RSAT-ADDS
Install-WindowsFeature RSAT-DNS-Server

# Create and trust Certificate
$certFile = "MyLdapsCert.pfx"
$certName = "*." + $domainName
$lifetime=Get-Date
$cert = New-SelfSignedCertificate -DnsName $certName -CertStoreLocation cert:\LocalMachine\My
$cert
$certThumbprint = $cert.Thumbprint
$cert = (Get-ChildItem -Path cert:\LocalMachine\My\$certThumbprint)
$certPasswordSecureString = ConvertTo-SecureString $certPassword -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $certFile -Password $certPasswordSecureString
Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\My -Password $certPasswordSecureString
Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root -Password $certPasswordSecureString

$adPassword = ConvertTo-SecureString $adPasswordText -AsPlainText -Force
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "F:\NTDS" -DomainMode "Win2012R2" -DomainName $domainName -DomainNetbiosName $domainNetbiosName -ForestMode "Win2012R2" -InstallDns:$true -LogPath "F:\NTDS" -NoRebootOnCompletion:$False -SysvolPath "F:\SYSVOL" -Force:$true -SafeModeAdministratorPassword $adPassword

Restart-Computer
