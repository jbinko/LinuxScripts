# Publish-AzureRmVMDscConfiguration ".\HDI_DJ_AD.ps1" -OutputArchivePath ".\HDI_DJ_AD.ps1.zip" -Force

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
		[System.Management.Automation.PSCredential]$adminCred,
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$hdinsightCred
	)
	
	Import-DscResource -ModuleName xActiveDirectory, PSDesiredStateConfiguration

	[System.Management.Automation.PSCredential]$domainCred = New-Object System.Management.Automation.PSCredential("${$domainName}\$($adminCred.UserName)", $adminCred.Password)

	[String[]]$groupMembers = $hdinsightCred.UserName
	
	Node localhost
	{
		ScriptAddADDSFeature{
			SetScript = {

				# DisableFW
				Set-NetFirewallProfile -Profile Domain, Private -Enabled False

				# Prepare AD Data Disk
				Get-Disk-Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "ActiveDirectoryDataDisk" -Force -Confirm:$false

				#Create and trust Certificate
				$certFile = "MyLdapsCert.pfx"
				$certName = "*." + $domainName
				$cert = New-SelfSignedCertificate -DnsName $certName -CertStoreLocation cert:\LocalMachine\My
				$certThumbprint = $cert.Thumbprint
				$cert = (Get-ChildItem -Path cert:\LocalMachine\My\$certThumbprint)
				$certPasswordSecureString = $adminCred.Password
				Export-PfxCertificate -Cert $cert -FilePath $certFile -Password $certPasswordSecureString
				Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\My-Password $certPasswordSecureString
				Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root-Password $certPasswordSecureString

				# Install AD
				Install-WindowsFeature DNS
				Install-WindowsFeature AD-Domain-Services
				Install-WindowsFeature RSAT-AD-Tools
				Install-WindowsFeature RSAT-ADDS
				Install-WindowsFeature RSAT-DNS-Server

				# Configure DNS
				Set-DnsServerDiagnostics -All $true
			}
			GetScript = { @{} }
			TestScript = { $false }
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
			GroupName = hdinsightusers
			GroupScope = Global
			Category = Security
			Members = $groupMembers
			Ensure = 'Present'
			DependsOn = "[xADUser]HDIUsrSvc"
		}

		xADOrganizationalUnit HDIOU
		{
			Name = AzureHDInsight
			Path = $ouPath
			ProtectedFromAccidentalDeletion = $False
			Ensure = 'Present'
			DependsOn = "[xWaitForADDomain]DscForestWait"
		}
	}
}
