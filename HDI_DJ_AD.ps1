# Publish-AzureRmVMDscConfiguration ".\HDI_DJ_AD.ps1" -OutputArchivePath ".\HDI_DJ_AD.ps1.zip" -Force
# Testing:
#	1. Extract zip
#	2. Add to the .\HDI_DJ_AD.ps1 at the end command HDI_DJ_AD
#	3. Run the script .\HDI_DJ_AD.ps1
#	4. Start-DscConfiguration -Path "HDI_DJ_AD" -Wait -Force -Verbose -ComputerName localhost

Configuration HDI_DJ_AD
{
	param
	(
		[Parameter(Mandatory)]
		[string]$domainName,
		[Parameter(Mandatory)]
		[string]$domainNetbiosName,
		[Parameter(Mandatory)]
		[string]$ouPath,
		[Parameter(Mandatory)]
		[string]$dnsServerZone,
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$adminCred,
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$hdinsightCred
	)
	
	Import-DscResource -ModuleName xActiveDirectory, xNetworking, xDnsServer, PSDesiredStateConfiguration

	[System.Management.Automation.PSCredential]$domainCred = New-Object System.Management.Automation.PSCredential("${$domainName}\$($adminCred.UserName)", $adminCred.Password)

	[String[]]$groupMembers = $hdinsightCred.UserName

	$Interface = Get-NetAdapter | Where Name -Like "Ethernet*" | Select-Object -First 1
	$InterfaceAlias = $($Interface.Name)
	
	Node localhost
	{
		LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyOnly'
			RebootNodeIfNeeded = $true
		}

		Script AddADDSFeature {
			SetScript = {

				# DisableFW
				Set-NetFirewallProfile -Profile Domain, Private -Enabled False

				# Prepare AD Data Disk
				Get-Disk -Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "ActiveDirectoryDataDisk" -Force -Confirm:$false

				# Install AD
				Install-WindowsFeature DNS
				Install-WindowsFeature AD-Domain-Services
				Install-WindowsFeature RSAT-AD-Tools
				Install-WindowsFeature RSAT-ADDS
				Install-WindowsFeature RSAT-DNS-Server

				# Configure DNS
				Set-DnsServerDiagnostics -All $true

				# Store some variables to use later
				$destination = "C:\Windows\Temp\AddADDSFeature.txt"
				ConvertTo-Json -Compress @{DomainName=$using:domainName;OUPath=$using:ouPath;DNSHDIZone=$using:dnsServerZone;HDIUserName=$using:hdinsightCred.UserName} | Set-Content -Path $destination
			}
			GetScript = { @{} }
			TestScript =
			{
				$destination = "C:\Windows\Temp\AddADDSFeature.txt"
				return Test-Path -Path $destination
			}
		}
		
		xDnsServerAddress DnsServerAddress
		{
			Address = '127.0.0.1'
			InterfaceAlias = $InterfaceAlias
			AddressFamily = 'IPv4'
			DependsOn = "[Script]AddADDSFeature"
        }

		xADDomain FirstDS
		{
			DomainName = $domainName
			DomainNetBIOSName = $domainNetBIOSName
			DomainAdministratorCredential = $domainCred
			SafemodeAdministratorPassword = $domainCred
			DatabasePath = "F:\NTDS"
			LogPath = "F:\NTDS"
			SysvolPath = "F:\SYSVOL"
			DependsOn = "[xDnsServerAddress]DnsServerAddress"
		}

		Script AddCAFeature {
			SetScript = {

				# Install CA
				# http://www.aventistech.com/2016/06/05/powershell-install-certificate-authority-ca/
				# https://blogs.msdn.microsoft.com/microsoftrservertigerteam/2017/04/10/step-by-step-guide-to-setup-ldaps-on-windows-server/
				Install-WindowsFeature AD-Certificate -IncludeManagementTools 
				Install-AdcsCertificationAuthority -CACommonName $env:computername -CAType EnterpriseRootCa -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years -ValidityPeriodUnits 5 -Force

				$destination = "C:\Windows\Temp\AddCAFeature.txt"
				New-Item -Force -Path $destination
			}
			GetScript = { @{} }
			TestScript =
			{
				$destination = "C:\Windows\Temp\AddCAFeature.txt"
				return Test-Path -Path $destination
			}
			DependsOn = "[xADDomain]FirstDS"
		}

		xADOrganizationalUnit HDIOU
		{
			Name = 'AzureHDInsight'
			Path = $ouPath
			ProtectedFromAccidentalDeletion = $False
			Ensure = 'Present'
			DependsOn = "[xADDomain]FirstDS"
		}

		xADUser HDIUsrSvc
		{
			DomainName = $domainName
			DomainAdministratorCredential = $domainCred
			UserName = $hdinsightCred.UserName
			Password = $hdinsightCred
			UserPrincipalName = -join($hdinsightCred.UserName, "@", $domainName)
			Enabled = $True
			PasswordNeverExpires = $True
			Ensure = "Present"
			DependsOn = "[xADOrganizationalUnit]HDIOU"
		}

		xADGroup HDIGroup
		{
			GroupName = 'hdinsightusers'
			GroupScope = 'Global'
			Category = 'Security'
			Members = $groupMembers
			Ensure = 'Present'
			DependsOn = "[xADUser]HDIUsrSvc"
		}

		Script PostConfiguration {
			SetScript = {

				# Get state to workaround $using with PsDscRunAsCredential
				$json = Get-Content -Raw -Path "C:\Windows\Temp\AddADDSFeature.txt" | ConvertFrom-Json

				# Ser required permissions for hdinsight svc account
				# https://stackoverflow.com/questions/28864220/join-domain-rights-using-powershell
				Import-Module ActiveDirectory
				
				$userGuid = [GUID]::Parse('bf967aba-0de6-11d0-a285-00aa003049e2')
				$computerGuid = [GUID]::Parse('bf967a86-0de6-11d0-a285-00aa003049e2')
				$accountGuid = [GUID]::Parse('2628a46a-a6ad-4ae0-b854-2b12d9fe6f9e')
				$accountRestrictionsGuid = [GUID]::Parse('4c164200-20c0-11d0-a768-00aa006e0529')
				$resetPasswordGuid = [GUID]::Parse('00299570-246d-11d0-a768-00aa006e0529')
				$dnsHostWrite = [GUID]::Parse('72e39547-7b18-11d1-adef-00c04fd8d5cd')
				$spnWrite = [GUID]::Parse('f3a64788-5306-11d1-a9c5-0000f80367c1')
				
				$ouPath = $json.OUPath
				$ou = "OU=AzureHDInsight,$ouPath"
				$acl = Get-Acl -Path "AD:\$ou"
				
				$adAccount = New-Object System.Security.Principal.NTAccount $json.DomainName, $json.HDIUserName

				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'GenericAll','Allow',$userGuid,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'GenericAll','Allow',$computerGuid,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'GenericAll','Allow',$accountGuid,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'ReadProperty,WriteProperty','Allow',$accountRestrictionsGuid,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'Self','Allow',$dnsHostWrite,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $adAccount,'Self','Allow',$spnWrite,'None'))
				$acl.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $adAccount,'Allow',$resetPasswordGuid,'None'))
				
				Set-ACl -Path "AD:\$ou" -AclObject $acl

				# Add permisions to create reverse DNS proxy rules
				Add-ADGroupMember DnsUpdateProxy $json.HDIUserName

				# Move AD Objects
				Get-ADUser $json.HDIUserName | Move-ADObject -TargetPath $ou
				Get-ADGroup 'hdinsightusers' | Move-ADObject -TargetPath $ou

				# Add Reverse AD Zone
				Add-DnsServerPrimaryZone -DynamicUpdate 'Secure' -NetworkId $json.DNSHDIZone -ReplicationScope 'Forest'

				$destination = "C:\Windows\Temp\PostConfiguration.txt"
				New-Item -Force -Path $destination
			}
			GetScript = { @{} }
			TestScript =
			{
				$destination = "C:\Windows\Temp\PostConfiguration.txt"
				return Test-Path -Path $destination
			}
			PsDscRunAsCredential = $domainCred
			DependsOn = "[xADGroup]HDIGroup"
		}
	}
}
