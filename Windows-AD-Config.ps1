 Param(
	 [Parameter(Mandatory=$True,Position=1)]
	 [string]$ouPath,
	 [Parameter(Mandatory=$True,Position=2)]
	 [string]$accountName,
	 [Parameter(Mandatory=$True,Position=3)]
	 [string]$upn,
	 [Parameter(Mandatory=$True,Position=4)]
	 [string]$password,
	 [Parameter(Mandatory=$True,Position=5)]
	 [string]$groupName
 )

# Create new OU
New-ADOrganizationalUnit -Name AzureHDInsight -Path $ouPath -PassThru

# Create User and group
New-ADUser -Name $accountName -UserPrincipalName $upn -AccountPassword (ConvertTo-SecureString $password -AsPlainText -force) -PassThru -Enabled $True -PasswordNeverExpires $True
New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -PassThru
Add-ADGroupMember -Identity $groupName -Member $accountName -PassThru
