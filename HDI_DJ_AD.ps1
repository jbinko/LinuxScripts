Configuration HDI_DJ_AD 
{
	param
	(
		[Parameter(Mandatory=$True)]
		[string]$domainName,
		[Parameter(Mandatory=$True)]
		[string]$domainNetbiosName,
		[Parameter(Mandatory=$True)]
		[string]$adPasswordText
	)
	
	Import-DscResource -ModuleName xActiveDirectory
	
	Node localhost
	{
		Script AddADDSFeature {
			SetScript = {
				# Disable FW
				Set-NetFirewallProfile -Profile Domain,Private -Enabled False

				# Prepare AD Data Disk
				Get-Disk -Number 2 | Initialize-Disk -Passthru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -NewFileSystemLabel "Active Directory Data Disk" -Force -Confirm:$false

				# Create and trust Certificate
				$certFile = "MyLdapsCert.pfx"
				$certName = "*." + $domainName
				$lifetime=Get-Date
				$cert = New-SelfSignedCertificate -DnsName $certName -CertStoreLocation cert:\LocalMachine\My
				$cert
				$certThumbprint = $cert.Thumbprint
				$cert = (Get-ChildItem -Path cert:\LocalMachine\My\$certThumbprint)
				$certPasswordSecureString = ConvertTo-SecureString $adPasswordText -AsPlainText -Force
				Export-PfxCertificate -Cert $cert -FilePath $certFile -Password $certPasswordSecureString
				Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\My -Password $certPasswordSecureString
				Import-PfxCertificate -FilePath $certFile -CertStoreLocation Cert:\LocalMachine\Root -Password $certPasswordSecureString

				# Install AD
				Install-WindowsFeature AD-Domain-Services
				Install-WindowsFeature RSAT-AD-Tools
				Install-WindowsFeature RSAT-ADDS
				Install-WindowsFeature RSAT-DNS-Server

				# Configure AD
				$adPassword = ConvertTo-SecureString $adPasswordText -AsPlainText -Force
				Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "F:\NTDS" -DomainMode "Win2012R2" -DomainName $domainName -DomainNetbiosName $domainNetbiosName -ForestMode "Win2012R2" -InstallDns:$true -LogPath "F:\NTDS" -NoRebootOnCompletion:$False -SysvolPath "F:\SYSVOL" -Force:$true -SafeModeAdministratorPassword $adPassword
			}
			GetScript =  { @{} }
			TestScript = { $false }
		}
	}
}
