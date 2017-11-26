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
	
	Import-DscResource -ModuleName xActiveDirectory, xDnsServer, PSDesiredStateConfiguration

	[System.Management.Automation.PSCredential]$domainCred = New-Object System.Management.Automation.PSCredential("${$domainName}\$($adminCred.UserName)", $adminCred.Password)

	[String[]]$groupMembers = $hdinsightCred.UserName
	
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

				$destination = "C:\Windows\Temp\AddADDSFeature.txt"
				New-Item -Force -Path $destination
			}
			GetScript = { @{} }
			TestScript =
			{
				$destination = "C:\Windows\Temp\AddADDSFeature.txt"
				return Test-Path -Path $destination
			}
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
			DependsOn = "[Script]AddADDSFeature"
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

		Script MoveADObjects {
			SetScript = {

				$ou = "OU=AzureHDInsight,$using:ouPath"
				Get-ADUser $using:hdinsightCred.UserName -Credential $using:domainCred | Move-ADObject -TargetPath $ou -Credential $using:domainCred
				Get-ADGroup 'hdinsightusers' -Credential $using:domainCred | Move-ADObject -TargetPath $ou -Credential $using:domainCred

				$destination = "C:\Windows\Temp\MoveADObjects.txt"
				New-Item -Force -Path $destination
			}
			GetScript = { @{} }
			TestScript =
			{
				$destination = "C:\Windows\Temp\MoveADObjects.txt"
				return Test-Path -Path $destination
			}
			DependsOn = "[xADGroup]HDIGroup"
		}

		#xDnsServerADZone addReverseADZone
		#{
		#	Name = $dnsServerZone
		#	DynamicUpdate = 'Secure'
		#	ReplicationScope = 'Forest'
		#	Ensure = 'Present'
		#	DependsOn = "[Script]AddCAFeature"
		#}
	}
}
