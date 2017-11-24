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
	 [string]$ouPath,
	 [Parameter(Mandatory=$True,Position=6)]
	 [string]$accountName,
	 [Parameter(Mandatory=$True,Position=7)]
	 [string]$upn,
	 [Parameter(Mandatory=$True,Position=8)]
	 [string]$password,
	 [Parameter(Mandatory=$True,Position=9)]
	 [string]$groupName,
	 [Parameter(Mandatory=$True,Position=10)]
	 [string]$certPassword
 )

# Set proxy				
reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxySettingsPerUser /t REG_DWORD /d 0 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyEnable /t REG_DWORD /d 1 /f
reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings' /v ProxyServer /t REG_SZ /d $webProxy /f
netsh winhttp set proxy $webProxy

# Prepare AD Data Disk
Get-Disk -Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "Active Directory Data Disk" -Force -Confirm:$false

# Install and configure AD
Install-WindowsFeature AD-Domain-Services
Install-WindowsFeature RSAT-AD-Tools
Install-WindowsFeature RSAT-ADDS
Install-WindowsFeature RSAT-DNS-Server

$adPassword = ConvertTo-SecureString $adPasswordText -AsPlainText -Force
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "F:\NTDS" -DomainMode "Win2012R2" -DomainName $domainName -DomainNetbiosName $domainNetbiosName -ForestMode "Win2012R2" -InstallDns:$true -LogPath "F:\NTDS" -NoRebootOnCompletion:$false -SysvolPath "F:\SYSVOL" -Force:$true -SafeModeAdministratorPassword $adPassword
Set-DnsServerDiagnostics -All $true

# Create new OU
New-ADOrganizationalUnit -Name AzureHDInsight -Path $ouPath

# Create User and group
New-ADUser -Name $accountName -UserPrincipalName $upn -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) -PassThru -Enabled $True -PasswordNeverExpires $True
New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -PassThru
Add-ADGroupMember -Identity $groupName -Member $accountName

# Create and trust Certificate
$certFile = "MyLdapsCert.pfx"
$certName = "*." + $domainName
$lifetime=Get-Date
$cert = New-SelfSignedCertificate -Subject $certName -NotAfter $lifetime.AddDays(2*365) -KeyUsage DigitalSignature, KeyEncipherment -Type SSLServerAuthentication -DnsName $certName
$certThumbprint = $cert.Thumbprint
$cert = (Get-ChildItem -Path cert:\LocalMachine\My\$certThumbprint)
$certPasswordSecureString = ConvertTo-SecureString $certPassword -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $certFile -Password $certPasswordSecureString
Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\My -Password $certPassword
Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root -Password $certPassword

# LDAPS protocol
Add-Type -AssemblyName System.DirectoryServices.Protocols
$directoryId = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier("", 389)
$conn = New-Object System.DirectoryServices.Protocols.LdapConnection($directoryId)

$attrMod = New-Object System.DirectoryServices.Protocols.DirectoryAttributeModification
$attrMod.Name = "renewServerCertificate"
$attrMod.Operation = 0
$index = $attrMod.Add(1)

$modifyRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest
$modifyRequest.DistinguishedName = $null
$index = $modifyRequest.Modifications.Add($attrMod)

$response = $conn.SendRequest($modifyRequest)
