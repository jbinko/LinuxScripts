 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$webProxy,
	 [Parameter(Mandatory=$True,Position=2)]
	 [string]$domainName,
	 [Parameter(Mandatory=$True,Position=3)]
	 [string]$domainNetbiosName,
	 [Parameter(Mandatory=$True,Position=4)]
	 [string]$adPasswordText
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

$adPassword = ConvertTo-SecureString $adPasswordText -AsPlainText -Force
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "F:\Windows\NTDS" -DomainMode "Win2012R2" -DomainName $domainName -DomainNetbiosName $domainNetbiosName -ForestMode "Win2012R2" -InstallDns:$true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "F:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword $adPassword
