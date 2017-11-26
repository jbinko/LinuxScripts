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

		Script AddADDSFeature{
			SetScript = {

				# DisableFW
				Set-NetFirewallProfile -Profile Domain, Private -Enabled False

				# Prepare AD Data Disk
				Get-Disk -Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "ActiveDirectoryDataDisk" -Force -Confirm:$false

				# Install CA
				# http://www.aventistech.com/2016/06/05/powershell-install-certificate-authority-ca/
				# https://blogs.msdn.microsoft.com/microsoftrservertigerteam/2017/04/10/step-by-step-guide-to-setup-ldaps-on-windows-server/
				#Install-WindowsFeature AD-Certificate -IncludeManagementTools 
				#Install-AdcsCertificationAuthority -CACommonName $env:computername -CAType StandaloneRootCA -HashAlgorithmName SHA256 -KeyLength 2048 -ValidityPeriod Years -ValidityPeriodUnits 5 -Force

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

		xWaitForADDomain DscForestWait
		{
			DomainName = $domainName
			DomainUserCredential = $domainCred
			RetryCount = 20
			RetryIntervalSec = 30
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
			DependsOn = "[xWaitForADDomain]DscForestWait"
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

		xADOrganizationalUnit HDIOU
		{
			Name = 'AzureHDInsight'
			Path = $ouPath
			ProtectedFromAccidentalDeletion = $False
			Ensure = 'Present'
			DependsOn = "[xWaitForADDomain]DscForestWait"
		}
		
		Script ADRefreshCerts
		{
			SetScript = {
				
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
			}
			
			GetScript =  { @{} }
			TestScript = { $false}
			DependsOn = "[xWaitForADDomain]DscForestWait"
		}
		
		xDnsServerADZone addReverseADZone
		{
			Name = $dnsServerZone
			DynamicUpdate = 'Secure'
			ReplicationScope = 'Forest'
			Ensure = 'Present'
			DependsOn = "[Script]ADRefreshCerts"
		}
	}
}
